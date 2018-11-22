local require        = require
local unpack         = unpack
local print          = print
local os             = os
local math           = math
local format         = string.format
local UIManager      = require("uimanager")
local network        = require("network")
local PlayerRole     = require("character.playerrole")
local ConfigManager  = require("cfg.configmanager")
local timeutils      = require("common.timeutils")
local ItemManager    = require("item.itemmanager")
local ItemIntroduct  = require("item.itemintroduction")
local ItemEnum       = require("item.itemenum")
local BonusManager   = require("item.bonusmanager")
local BagManager     = require("character.bagmanager")
local PetManager     = require("character.pet.petmanager")
local WelfareManager = require("ui.welfare.welfaremanager")
local CheckCmd       = require("common.checkcmd")
local EventHelper    = UIEventListenerHelper

local UIGROUP_COMS_NAME =
{
    [1] = "UIGroup_GiftBagBG",
    [2] = "UIGroup_MonthSignInBG",
    [3] = "UIGroup_ContinuousLogin",
    -- [4] = "UIGroup_OnlineBG",
    -- [5] = "UIGroup_WishingTree",
	 [4] = "UIGroup_AddStrength",
	 [5] = "UIGroup_ExchangeID",
	-- [7] = "UIGroup_RechargeReturn",
}

local ONLINE_GIFTBOX_NUM = 6

local gameObject
local name
local fields
local ShowPage

local indexToDay = {}

local g_LeftSecs = 0
local g_TabIndex = 0 

local function InitItemByBool(setReceive,bReceivedDays)
	local playerGiftData = WelfareManager.GetNewPlayerGiftData()
	for _, day in ipairs(playerGiftData.DayList) do
		if bReceivedDays[day] == setReceive then
           local listItem = fields.UIList_GiftBag:AddListItem()
            listItem:SetText("UILabel_Day", format(LocalString.Welfare_Day, day))
            local buttonReceive = listItem.Controls["UIButton_Receive01"]

            local items = BonusManager.GetItemsOfBonus( { bonustype = "cfg.bonus.BeginnerBonus", csvid = day })

            local dayGiftList = listItem.Controls["UIList_DayGifts"]

            for i = 1, #items do
                local dayGiftListItem = dayGiftList:AddListItem()

                dayGiftListItem:SetIconTexture(items[i]:GetTextureName())
                dayGiftListItem.Controls["UILabel_Amount"].text = items[i]:GetNumber()
				dayGiftListItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(items[i]:GetQuality())
				dayGiftListItem.Controls["UISprite_Fragment"].gameObject:SetActive(items[i]:GetBaseType() == ItemEnum.ItemBaseType.Fragment)
				dayGiftListItem.Controls["UISprite_Get"].gameObject:SetActive(false)
				dayGiftListItem.Controls["UISprite_Binding"].gameObject:SetActive(items[i]:IsBound())
                dayGiftListItem.Data = items[i]
            end
			
			--将对应指数和天数添加进列表
			indexToDay[fields.UIList_GiftBag.Count] = day

            EventHelper.SetClick(buttonReceive, function()
                local msg = lx.gs.bonus.msg.CNewGift( { newgiftid = day })
                network.send(msg)
				
            end )


            EventHelper.SetListClick(dayGiftList, function(listItem)
                ItemIntroduct.DisplayBriefItem( {item = listItem.Data} )
            end )
			
			
		end
    end
end

local function InitGiftBagList()
    fields.UILabel_Title.text = LocalString.Welfare_GiftBagTitle;
    if fields.UIList_GiftBag.Count == 0 then
		local playerGiftData = WelfareManager.GetNewPlayerGiftData()
		--设置已领取的天数列表
		local bReceivedDays = { }
        for _, day in pairs(playerGiftData.ReceivedDays) do
        bReceivedDays[day] = true
        end
		
		--先设置未领取的item
        InitItemByBool(nil,bReceivedDays)
		--设置领取的item
		InitItemByBool(true,bReceivedDays)

    end
end



local function InitMonthSignInList(dayNum)

    if fields.UIList_MonthSignIn.Count == 0 then
		local monthBonusDataList = ConfigManager.getConfig("monthbonus")
        for day = 1, dayNum do
            local items = BonusManager.GetItemsOfBonus( { bonustype = "cfg.bonus.MonthBonus", csvid = day })
            local listItem = fields.UIList_MonthSignIn:AddListItem()
            listItem:SetText("UILabel_DayCount", format(LocalString.Welfare_Day, day))
            listItem.Controls["UISprite_Select"].gameObject:SetActive(false)
            listItem:SetIconTexture(items[1]:GetTextureName())
			listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(items[1]:GetQuality())
			listItem.Controls["UISprite_Fragment"].gameObject:SetActive(items[1]:GetBaseType() == ItemEnum.ItemBaseType.Fragment)
			listItem:SetText("UILabel_Amount",items[1]:GetNumber())
			listItem.Controls["UISprite_Binding"].gameObject:SetActive(items[1]:IsBound())
			listItem.Data = items[1]
			-- vip图标，获得双倍道具
			-- local bValidated = CheckCmd.CheckData( { data = monthBonusDataList[day].requireviplevel,showsysteminfo = false })
			listItem.Controls["UILabel_VipLevel"].gameObject:SetActive(not shouldHideVip())
			listItem.Controls["UILabel_VipLevel"].text = format(LocalString.Welfare_MonthSignin_VipDay,monthBonusDataList[day].requireviplevel.level)
			local bShowEffect = monthBonusDataList[day].showeffect>0
			listItem.Controls["UIGroup_Effect"].gameObject:SetActive(bShowEffect)
        end

        EventHelper.SetListClick(fields.UIList_MonthSignIn, function(listItem)
			-- 以下bonus是多个物品的情况，需求更改，已注释
            -- local bonusItems = BonusManager.GetItemsOfBonus( { bonustype = "cfg.bonus.MonthBonus", csvid = (listItem.Index + 1) })
			--	local bIsVipDay = CheckCmd.CheckData( { data = monthBonusDataList[listItem.Index + 1].requireviplevel, showsysteminfo = true })
			--	if bIsVipDay and PlayerRole:Instance():GetVipLevel() > 0 then
			--		-- vip天展示双倍奖励,数量x2
			--		for _,bonusItem in ipairs(bonusItems) do
			--			local oriNum = bonusItem:GetNumber()
			--			bonusItem:AddNumber(oriNum)
			--		end
			--	end
			--  local params   = { }
			--  params.type    = 1
			--  params.items   = bonusItems
			--  params.title   = LocalString.Alert_RewardsList
			--  params.buttons =
			--  {
			--      { text = LocalString.SureText, callBackFunc = function() UIManager.hide("common.dlgdialogbox_reward") end },

			--  }
			--  local DlgAlert_ShowRewards = require("ui.dlgalert_showrewards")
			--  params.callBackFunc = function(p, f) DlgAlert_ShowRewards.init(f); DlgAlert_ShowRewards.show(p) end
			--  UIManager.show("common.dlgdialogbox_reward", params)
            ItemIntroduct.DisplayBriefItem( {item = listItem.Data} )

        end )
		EventHelper.SetClick(fields.UIButton_SignIn, function()
			-- 协议中signdate默认为0，需求不再改变后去除此字段
		    local dayInMonth = 0
		    local msg = lx.gs.bonus.msg.CSign( { signtype = cfg.bonus.SignType.NORMAL_SIGN, signdate = dayInMonth })
		    network.send(msg)
		end )
		-- 目前需求去掉补签功能
		-- EventHelper.SetClick(fields.UIButton_SignIn, function()
		--     local dayInMonth = tonumber(os.date("%d",timeutils.GetServerTime()))
		--     local msg = lx.gs.bonus.msg.CSign( { signtype = cfg.bonus.SignType.NORMAL_SIGN, signdate = dayInMonth })
		--     network.send(msg)
		-- end )

		-- EventHelper.SetClick(fields.UIButton_AddSignIn, function()
		--     local signInData = WelfareManager.GetSignInData()
		--     local signedList = signInData.SignedDays
		--     local firstUnSignedDay = 0

		--     for day, bSigned in ipairs(signInData.bSignedDays) do
		--         if bSigned then
		--             firstUnSignedDay = day
		--             break
		--         end
		--     end
		--     local msg = lx.gs.bonus.msg.CSign( { signtype = cfg.bonus.SignType.ADD_SIGN, signdate = firstUnSignedDay })
		--     network.send(msg)
		-- end )

    end
end

local function InitContinueLoginBoxList()
    if fields.UIList_GiftBox.Count == 0 then
        local loginData = WelfareManager.GetContinueLoginData()
        for i = 1, 8 do
            local listItem = fields.UIList_GiftBox:AddListItem()
            listItem:GetTexture("UITexture_GiftBox_Close").gameObject:SetActive(true)
			listItem:GetTexture("UITexture_GiftBox_Open").gameObject:SetActive(false)
			listItem.Controls["UISprite_Get"].gameObject:SetActive(false)
        end

        EventHelper.SetListClick(fields.UIList_GiftBox, function(listItem)

            if loginData.LeftGiftNum >= 1 then
                local msg = lx.gs.bonus.msg.CContinueLoginGift( { boxid = listItem.Index + 1 })
                network.send(msg)
            end
        end )
    end
end

local function InitWelfareTypeList()
    if fields.UIList_WelfareTab.Count == 0 then
		local hiddenTabs = WelfareManager.GetHiddenTabs()
        for i = 1, #UIGROUP_COMS_NAME do
            local listItem = fields.UIList_WelfareTab:AddListItem()
            listItem:SetText("UILabel_WelfareTypeName", LocalString.WelfareType[i])
            listItem.Controls["UISprite_Warning"].gameObject:SetActive(false)
            fields[UIGROUP_COMS_NAME[i]].gameObject:SetActive(false)
			if hiddenTabs[i] then 
				-- 去掉入口按钮
				listItem.gameObject:SetActive(false)
			end 
        end
    end
end

local function ClearWelfareTypeList()
    if fields.UIList_WelfareTab.Count ~= 0 then
        fields.UIList_WelfareTab:Clear()
    end
end

local function RefreshRedDot()
    local UnReadPageList = WelfareManager.UnReadPageList
    for pageIndex = 1,fields.UIList_WelfareTab.Count do
		local listItem = fields.UIList_WelfareTab:GetItemByIndex(pageIndex - 1)
		local showRed = false
		if UnReadPageList[pageIndex]~=nil then
			showRed = UnReadPageList[pageIndex]()
		end
        listItem.Controls["UISprite_Warning"].gameObject:SetActive(showRed)
    end
    -- 红点刷新
	if UIManager.needrefresh("dlguimain") then
		UIManager.call("dlguimain","RefreshRedDotType",cfg.ui.FunctionList.WELFARE)
	end
	if UIManager.needrefresh("dlgdialog") then
		UIManager.call("dlgdialog","RefreshRedDot","welfare.dlgwelfaremain")
	end
end

--  新手礼包界面
local function ShowNewPlayerGift()
	--清空原list
	fields.UIList_GiftBag:Clear()
    InitGiftBagList()
    local playerGiftData = WelfareManager.GetNewPlayerGiftData()
    local bReceivedDays = { }
    for _, day in pairs(playerGiftData.ReceivedDays) do
        bReceivedDays[day] = true
    end

    for i = 1, fields.UIList_GiftBag.Count do
		local day = indexToDay[i]
		--local day = playerGiftData.DayList[i]
        local listItem = fields.UIList_GiftBag:GetItemByIndex(i - 1)
        local buttonReceive = listItem.Controls["UIButton_Receive01"]

        -- 判断可以领取新手奖励的天
        if day <= playerGiftData.LoginDays then
            -- UITools.SetButtonEnabled(buttonReceive,true)
			buttonReceive.isEnabled = true
        else
            -- UITools.SetButtonEnabled(buttonReceive,false)
			buttonReceive.isEnabled = false
        end
        -- 已经领取奖品的天
        if bReceivedDays[day] then
            -- UITools.SetButtonEnabled(buttonReceive,false)
			buttonReceive.gameObject:SetActive(false)
            listItem:SetText("UILabel_Receive", LocalString.Welfare_ButtonStatus_HasReceived)
			-- 显示已经领取图标
			local dayGiftList = listItem.Controls["UIList_DayGifts"]
            for i = 1, dayGiftList.Count do
                local dayGiftListItem = dayGiftList:GetItemByIndex(i-1)
				dayGiftListItem.Controls["UISprite_Get"].gameObject:SetActive(true)
            end
			--设置已领取图片
			listItem.Controls["UISprite_HasReceived"].gameObject:SetActive(true)
        end
    end
end


-- 每月签到界面
local function ShowSignInPage()
    local signInData = WelfareManager.GetSignInData()
    -- 初始化每日签到列表(固定是30天一循环)
    InitMonthSignInList(30)

    local bonusConfig = ConfigManager.getConfig("bonusconfig")
    -- local addSignLimitTime = bonusConfig.vipretroactive[PlayerRole:Instance().m_VipLevel + 1]
    -- 补签消耗
    -- local needDiamondNum = 0
	-- if addSignLimitTime > 0 then
	--     needDiamondNum = bonusConfig.retroactivecost[addSignLimitTime]
	-- end
    -- fields.UILabel_NeedDiamondNum.text = needDiamondNum
    -- 补签和签到天数
    -- fields.UILabel_AddSignTime.text = signInData.AddSignTime .. "/" .. addSignLimitTime
    local totalSignedDayNum = 0
    for day, bSigned in ipairs(signInData.bSignedDays) do
        if bSigned then
            totalSignedDayNum = totalSignedDayNum + 1
        end
    end
    fields.UILabel_TotalSigndedDays.text = totalSignedDayNum
	fields.UIButton_SignIn.isEnabled = (not signInData.bTodaySignedIn)

    for day, bSigned in ipairs(signInData.bSignedDays) do
        local listItem = fields.UIList_MonthSignIn:GetItemByIndex(day - 1)
        if bSigned then
            listItem.Controls["UISprite_Select"].gameObject:SetActive(true)
        else
            listItem.Controls["UISprite_Select"].gameObject:SetActive(false)
        end
    end

end

-- 连续登陆界面
local function ShowContinueLoginPage()
    InitContinueLoginBoxList()
    local loginData = WelfareManager.GetContinueLoginData()
    fields.UILabel_ContinuousLoginDays.text = loginData.LoginDayNum
    fields.UILabel_RestGiftBoxNum.text = loginData.LeftGiftNum
	
	fields.UILabel_Deactive.gameObject:SetActive(not (loginData.LeftGiftNum > 0))
	fields.UILabel_Active.gameObject:SetActive(loginData.LeftGiftNum > 0)

	for i = 1,fields.UIList_GiftBox.Count do
	    local listItem = fields.UIList_GiftBox:GetItemByIndex(i - 1)
		listItem:GetTexture("UITexture_GiftBox_Open").gameObject:SetActive(loginData.bReceivedIds[i])
		listItem:GetTexture("UITexture_GiftBox_Close").gameObject:SetActive(not loginData.bReceivedIds[i])
		colorutil.SetTextureColorGray(listItem:GetTexture("UITexture_GiftBox_Close"),((not loginData.bReceivedIds[i]) and (loginData.LeftGiftNum == 0)))
		listItem.Controls["UISprite_Get"].gameObject:SetActive(loginData.bReceivedIds[i])
		--listItem.Controls["UIGroup_Tween_StandBy"].gameObject:SetActive(loginData.bReceivedIds[i])
	end

end

local function pairsByTimeType(list)
    local key = { }
    local map = { }

    for timeType, bonusData in pairs(list) do
        key[#key + 1] = timeType
        map[timeType] = BonusManager.GetItemsOfSingleBonus(bonusData.bonuslist)
    end
    -- 默认升序
    table.sort(key)
    local i = 0
    return function()
        i = i + 1
        return key[i], map[key[i]]
    end
end
-- 每日在线界面
local function ShowDailyOnlinePage(d)
    local dailyOnlineData = WelfareManager.GetDailyOnlineData()
    local onlineBonus = ConfigManager.getConfig("onlinetimebonus")
    local listIndex = 0
    local bonusItems = { }
    -- UITools.SetButtonEnabled(fields.UIButton_Receive02 ,false)
	fields.UIButton_Receive02.isEnabled = false

    for timeType, bonusItemList in pairsByTimeType(onlineBonus) do
        bonusItems[#bonusItems + 1] = bonusItemList

        local listItem = fields.UIList_Online:GetItemByIndex(listIndex)
        listItem:SetText("UILabel_Minute", format(LocalString.Welfare_Online_Minute, timeType / 60))

        listItem:SetIconTexture(bonusItemList[1]:GetTextureName())
		listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(bonusItemList[1]:GetQuality())
		listItem.Controls["UISprite_Fragment"].gameObject:SetActive(bonusItemList[1]:GetBaseType() == ItemEnum.ItemBaseType.Fragment)
		listItem.Controls["UISprite_Binding"].gameObject:SetActive(bonusItemList[1]:IsBound())
		listItem.Controls["UILabel_Amount"].text = bonusItemList[1]:GetNumber()
        if not dailyOnlineData.bReceivedGift[timeType] then
            listItem:SetText("UILabel_ReceiveStatus", LocalString.Welfare_Online_NotReceived)
            listItem.Controls["UISprite_Select"].gameObject:SetActive(false)
            if dailyOnlineData.DailyOnlineSeconds >= timeType then
                -- UITools.SetButtonEnabled(fields.UIButton_Receive02 ,true)
				fields.UIButton_Receive02.isEnabled = true
            end
        else
            listItem:SetText("UILabel_ReceiveStatus", LocalString.Welfare_Online_HasReceived)
            listItem.Controls["UISprite_Select"].gameObject:SetActive(true)
        end
        listIndex = listIndex + 1
    end

    EventHelper.SetClick(fields.UIButton_Receive02, function()
        local times = { }
        local timeTypeList = dailyOnlineData.TimeTypeList
        for i = 1, #timeTypeList do
            if not dailyOnlineData.bReceivedGift[timeTypeList[i]] and dailyOnlineData.DailyOnlineSeconds >= timeTypeList[i] then
                times[#times + 1] = timeTypeList[i]
            end
        end

        if #times ~= 0 then
            local msg = lx.gs.bonus.msg.CGetOnlineGift( { gifttimetype = times })
            network.send(msg)
        end
    end )

	-- 需求更改，虽然配成随进奖励，但仅显示奖励列表里的第一个物品
	-- 配成随机奖励策划认为奖励需求会再更改回随机奖励
	-- 目前以随机奖励来展示单个Item形式
    -- 随机奖品展示
	--    EventHelper.SetListClick(fields.UIList_Online, function(listItem)

	--        local params   = { }
	--        params.type    = 1
	--        params.items   = bonusItems[listItem.Index + 1]
	--        params.title   = LocalString.Alert_RewardsList
	--        params.buttons =
	--        {
	--            { text = LocalString.SureText, callBackFunc = function() UIManager.hide("common.dlgdialogbox_reward") end },

	--        }
	--        local DlgAlert_ShowRewards = require("ui.dlgalert_showrewards")
	--        params.callBackFunc = function(p, f) DlgAlert_ShowRewards.init(f); DlgAlert_ShowRewards.show(p) end
	--        UIManager.show("common.dlgdialogbox_reward", params)
	--    end )
	-- 显示随机奖励里的单个物品
	EventHelper.SetListClick(fields.UIList_Online, function(listItem)
		ItemIntroduct.DisplayBriefItem( {item = bonusItems[listItem.Index + 1][1]} )
	end )
end

-- 许愿界面
local function ShowWishPage()
	fields.UILabel_WishDesc.gameObject:SetActive(not shouldHideVip())
    fields.UILabel_WishDesc.text = LocalString.Welfare_WishDescTxt1
    local wishData = WelfareManager.GetWishData()

    local bonusConfig = ConfigManager.getConfig("bonusconfig")
    local vipWishLimitNum = bonusConfig.viptimes[PlayerRole:Instance().m_VipLevel + 1]

    local leftWishPropNum = BagManager.GetItemNumById(bonusConfig.vowitem)
	local wishProp = ItemManager.CreateItemBaseById(bonusConfig.vowitem,nil,leftWishPropNum)
	-- 设置许愿道具信息
	fields.UITexture_WishPropIcon:SetIconTexture(wishProp:GetTextureName())
	fields.UILabel_LeftWishPropNum.text = wishProp:GetNumber()
	fields.UISprite_WishPropQuality.spriteName = colorutil.GetQualitySprite(wishProp:GetQuality())

    if wishData.SelectedPet then
        fields.UITexture_PartnerIcon:SetIconTexture(wishData.SelectedPet:GetTextureName())
		fields.UISprite_PartnerQuality.spriteName = colorutil.GetQualitySprite(wishData.SelectedPet:GetQuality())
    else
        fields.UITexture_PartnerIcon:SetIconTexture("null")
		fields.UISprite_PartnerQuality.spriteName = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
    end

    fields.UILabel_VipWishLimit.text = wishData.UsedWishTime .. "/" .. vipWishLimitNum

	EventHelper.SetClick(fields.UITexture_WishPropIcon,function()
		ItemIntroduct.DisplayBriefItem({ item = wishProp })
	end)

    EventHelper.SetClick(fields.UIButton_WishingTree, function()
        if vipWishLimitNum then
            if wishData.SelectedPet then
                    if wishProp:GetNumber() <= 0 then
                        UIManager.ShowSystemFlyText(format(LocalString.Welfare_WishPropNotEnough,wishProp:GetName()))
						ItemManager.GetSource(wishProp:GetConfigId(),"welfare.dlgwelfare")
                    else
                        if wishData.UsedWishTime < vipWishLimitNum then
                            local msg = lx.gs.bonus.msg.CGetWishGift( { petid = wishData.SelectedPet:GetConfigId() })
                            network.send(msg)
                        else
                            UIManager.ShowSystemFlyText(LocalString.Welfare_VipUpperLimitWishTime)
                        end
                    end
            else
                -- 提示选择伙伴
                UIManager.ShowSystemFlyText(LocalString.Welfare_WishingTree_NoPet)
            end
		else
			logError(format("No Vip:%s wish limit time data",PlayerRole:Instance().m_VipLevel))
        end
    end )

    EventHelper.SetClick(fields.UIButton_Partner, function()
        local bagPets = PetManager.GetSortedAttainedPets()
        if getn(bagPets) ~= 0 then
            local DlgDialogBox_ItemList = require("ui.common.dlgdialogbox_itemlist")
			UIManager.show("common.dlgdialogbox_itemlist", { type = DlgDialogBox_ItemList.DlgType.WelfarePets})
        else
            -- 提示背包中无伙伴
            UIManager.ShowSystemFlyText(LocalString.Welfare_WishingTree_PetEmpty)
        end
    end )

end

-- 吃包子界面
local function ShowAddStrengthPage()
	local addStrengthData = ConfigManager.getConfig("baozi")
	local lunchData = addStrengthData[cfg.bonus.MealType.LUNCH]
	local dinnerData = addStrengthData[cfg.bonus.MealType.DINNER]

	--local timeNow =os.date("*t", timeutils.GetServerTime()-3*3600) 
	local timeNow = timeutils.TimeNow()
	local nowSecs = timeutils.getSeconds({days = 0,hours = timeNow.hour ,minutes = timeNow.min,seconds = timeNow.sec})
	g_LeftSecs = 0 
	for mealType,mealData in ipairs(addStrengthData) do
		local mealSecs = timeutils.getSeconds({ days = 0,hours = mealData.starthour ,minutes = mealData.startminute,seconds = 0})
		if nowSecs < mealSecs then 
			g_LeftSecs = mealSecs - nowSecs
			break
		end 
	end
	
	-- fields.UIGroup_NextMealTime.gameObject:SetActive(g_LeftSecs > 0)
	-- if g_LeftSecs > 0 then 
	-- 	local leftTime = timeutils.getDateTime(g_LeftSecs)	
	-- 	fields.UILabel_NextMealOpeningTime.text = format(LocalString.Welfare_AddStrength_NextMealOpenTime,leftTime.hours,leftTime.minutes,leftTime.seconds)			
	-- end
	
	local lunchStartSecs  = timeutils.getSeconds({ days = 0,hours = lunchData.starthour ,minutes = lunchData.startminute,seconds = 0})
	local lunchEndSecs    = timeutils.getSeconds({ days = 0,hours = lunchData.endhour ,minutes = endminute,seconds = 0})
	local dinnerStartSecs = timeutils.getSeconds({ days = 0,hours = dinnerData.starthour ,minutes = dinnerData.startminute,seconds = 0})
	local dinnerEndSecs   = timeutils.getSeconds({ days = 0,hours = dinnerData.endhour ,minutes = dinnerData.endminute,seconds = 0})
	local dayEndSecs      = timeutils.getSeconds({ days = 0,hours = 23 ,minutes = 59,seconds = 59 })
	-- 午餐和晚餐是否都在准备中
	-- fields.UILabel_MealInCooking.gameObject:SetActive(nowSecs < lunchStartSecs)
	local uiButtonLunch = fields.UIButton_EatLunch.gameObject:GetComponent("UIButton")
	local uiButtonDinner = fields.UIButton_EatDinner.gameObject:GetComponent("UIButton")
	fields.UIButton_EatLunch.gameObject:SetActive(true)
	fields.UIButton_EatDinner.gameObject:SetActive(true)
	--Label_AddStrengNum1 领取的体力值
	--Label_AddStrengNum2 领取的体力值

	local mealData = WelfareManager.GetAddStrengthData()
	-- 午餐
	if not mealData.bHasAteLunch then
		fields.UISprite_Recv1.gameObject:SetActive(false)
		if nowSecs >= lunchStartSecs and nowSecs <= lunchEndSecs then
			-- 午餐时间
			fields.UILabel_LunchStatus.text = LocalString.Welfare_AddStrength_EatLunch
			fields.UISprite_EatLunch_Cost.gameObject:SetActive(false)
			uiButtonLunch.isEnabled = true
		elseif nowSecs > lunchEndSecs and nowSecs <= dayEndSecs then
			-- 补餐时间
			fields.UILabel_LunchStatus.text = LocalString.Welfare_AddStrength_EatLunchLater
			fields.UISprite_EatLunch_Cost.gameObject:SetActive(true)
			uiButtonLunch.isEnabled = true
			-- 补餐花费
			local currency = ItemManager.GetCurrencyData(lunchData.requireyuanbao)
			fields.UISprite_EatLunch_CurrencyIcon.spriteName = currency:GetIconName()
			fields.UILabel_EatLunch_CurrencyCost.text = currency:GetNumber()
			WelfareManager.GetAddStrengthData().bYuanbaoLess = true
			RefreshRedDot()
		else
			fields.UILabel_LunchStatus.text = LocalString.Welfare_AddStrength_EatLunch
			uiButtonLunch.isEnabled = false
		end
	else
		fields.UISprite_Recv1.gameObject:SetActive(nowSecs >= lunchStartSecs)
		fields.UILabel_LunchStatus.text = LocalString.Welfare_AddStrength_EatLunch
		uiButtonLunch.isEnabled = false
		fields.UISprite_EatLunch_Cost.gameObject:SetActive(false)
	end

	-- 晚餐
	if not mealData.bHasAteDinner then
		fields.UISprite_Recv2.gameObject:SetActive(false) 
		fields.UILabel_DinnerStatus.text = LocalString.Welfare_AddStrength_EatDinner
		if nowSecs >= dinnerStartSecs and nowSecs <= dinnerEndSecs then
			-- 晚餐时间
			fields.UISprite_EatDinner_Cost.gameObject:SetActive(false)
			uiButtonDinner.isEnabled = true
		elseif nowSecs > dinnerEndSecs and nowSecs <= dayEndSecs then
			-- 补餐时间
			fields.UILabel_DinnerStatus.text = LocalString.Welfare_AddStrength_EatDinnerLater
			fields.UISprite_EatDinner_Cost.gameObject:SetActive(true)
			--fields.UISprite_DinnerNotOpening.gameObject:SetActive(false)

			-- 补餐花费
			local currency = ItemManager.GetCurrencyData(dinnerData.requireyuanbao)
			fields.UISprite_EatDinner_CurrencyIcon.spriteName = currency:GetIconName()
			fields.UILabel_EatDinner_CurrencyCost.text = currency:GetNumber()
			uiButtonDinner.isEnabled = true
			WelfareManager.GetAddStrengthData().bYuanbaoLess = true
			RefreshRedDot()
		elseif nowSecs < lunchStartSecs then
			-- 中餐前不显示晚餐准备中状态
			--fields.UISprite_DinnerNotOpening.gameObject:SetActive(false)
			uiButtonDinner.isEnabled = false
		else
			-- 中餐开始时间到晚餐开始时间这个时间段内，为晚餐准备中状态 
			--fields.UISprite_DinnerNotOpening.gameObject:SetActive(true)
			uiButtonDinner.isEnabled = false
		end
	else
		-- fields.UISprite_DinnerAlreadyAte.gameObject:SetActive(nowSecs >= dinnerStartSecs)
		fields.UISprite_Recv2.gameObject:SetActive(nowSecs >= dinnerStartSecs)
		--fields.UISprite_DinnerNotOpening.gameObject:SetActive(false)
		uiButtonDinner.isEnabled = false
		fields.UILabel_DinnerStatus.text = LocalString.Welfare_AddStrength_EatDinner
		fields.UISprite_EatDinner_Cost.gameObject:SetActive(false)
	end
	
	-- 午餐
	EventHelper.SetClick(fields.UIButton_EatLunch,function()
		local timeNow = timeutils.TimeNow()
		local nowSecs = timeutils.getSeconds({days = 0,hours = timeNow.hour ,minutes = timeNow.min,seconds = timeNow.sec})
		local mealData = WelfareManager.GetAddStrengthData()
		if nowSecs >= lunchStartSecs and nowSecs <= lunchEndSecs and not mealData.bHasAteLunch then
			--正常吃
			local msg = lx.gs.bonus.msg.CEatBaozi{ eattype = lx.gs.bonus.msg.CEatBaozi.EAT_LUNCH }
			network.send(msg)
		elseif nowSecs > lunchEndSecs and nowSecs <= dayEndSecs and not mealData.bHasAteLunch then
			--补餐
			--校验补餐花费
			
			local currency_validate = CheckCmd.CheckData({ data = lunchData.requireyuanbao, num = 1, showsysteminfo = true })
			if currency_validate then
				local msg = lx.gs.bonus.msg.CEatBaozi{ eattype = lx.gs.bonus.msg.CEatBaozi.RE_EAT_LUNCH }
				network.send(msg)
			else
				local currency = ItemManager.GetCurrencyData(lunchData.requireyuanbao)
				ItemManager.GetSource(currency:GetConfigId(),"welfare.dlgwelfare")
			end
		end
	
	end)

	-- 晚餐
	EventHelper.SetClick(fields.UIButton_EatDinner,function()
		
		if nowSecs >= dinnerStartSecs and nowSecs <= dinnerEndSecs and not mealData.bHasAteDinner then
			--正常吃
			local msg = lx.gs.bonus.msg.CEatBaozi{ eattype = lx.gs.bonus.msg.CEatBaozi.EAT_DINNER }
			network.send(msg)
		elseif nowSecs > dinnerEndSecs and nowSecs <= dayEndSecs and not mealData.bHasAteDinner then 
			--补餐
			--校验补餐花费
			
			local currency_validate = CheckCmd.CheckData({ data = dinnerData.requireyuanbao, num = 1, showsysteminfo = true })
			if currency_validate then
				local msg = lx.gs.bonus.msg.CEatBaozi{ eattype = lx.gs.bonus.msg.CEatBaozi.RE_EAT_DINNER }
				network.send(msg)
			else
				local currency = ItemManager.GetCurrencyData(dinnerData.requireyuanbao)
				ItemManager.GetSource(currency:GetConfigId(),"welfare.dlgwelfare")
			end
		end
	end)

end

-- 兑换码界面
local function ShowExchangeIDPage()
	EventHelper.SetClick(fields.UIButton_ExchangeID,function()
		local exchangeId = fields.UIInput_ExchangeID.value
		if trim(exchangeId) ~= "" then 
			local msg = lx.gs.role.msg.CUseCode{ code = exchangeId }
			network.send(msg)	
		else
			UIManager.ShowSystemFlyText(LocalString.Welfare_ExchangeId_NoId)
		end
	end)
end

-- 封测充值返还界面
local function ShowRechargeReturnPage()
	local payReturnData = WelfareManager.GetPayReturnData()
	UITools.SetButtonEnabled(fields.UIButton_GetRechargeBonus,(not (payReturnData.VipPointNum > 0 and payReturnData.bHasGotPayReturn)))
	EventHelper.SetClick(fields.UIButton_GetRechargeBonus,function()
		local bHasRecharged = (payReturnData.VipPointNum > 0) and true or false
		if not bHasRecharged then 
			UIManager.ShowSingleAlertDlg(
			{
                title = LocalString.TipText,
				content = LocalString.Welfare_RechargeReturn_NoReturn,
            } )
		else
			-- 未领取
			if not payReturnData.bHasGotPayReturn then 
				network.create_and_send("lx.gs.pay.CGetPayReturn")
			end
		end
	end)
end

local function OnGetPayReturn()
	UITools.SetButtonEnabled(fields.UIButton_GetRechargeBonus,false)
end

local function OnGetContinueLoginGift(params)
	local loginData = WelfareManager.GetContinueLoginData()
    fields.UILabel_ContinuousLoginDays.text = loginData.LoginDayNum
    fields.UILabel_RestGiftBoxNum.text = loginData.LeftGiftNum
	
	fields.UILabel_Deactive.gameObject:SetActive(not (loginData.LeftGiftNum > 0))
	fields.UILabel_Active.gameObject:SetActive(loginData.LeftGiftNum > 0)

	-- 其余未打开宝箱全部置灰色
	if not (loginData.LeftGiftNum > 0) then 
		for boxId = 1,fields.UIList_GiftBox.Count do
			if not loginData.bReceivedIds[boxId] then
				local listItem = fields.UIList_GiftBox:GetItemByIndex(boxId - 1)
				colorutil.SetTextureColorGray(listItem:GetTexture("UITexture_GiftBox_Close"),true)
			end
		end
	end

	local listItem = fields.UIList_GiftBox:GetItemByIndex(params.boxid - 1)
	local tweenScale = listItem:GetTexture("UITexture_GiftBox_Open").gameObject:GetComponent(TweenScale)
	listItem:GetTexture("UITexture_GiftBox_Open").gameObject:SetActive(true)
	tweenScale.enabled = true
	listItem:GetTexture("UITexture_GiftBox_Close").gameObject:SetActive(false)
	listItem.Controls["UISprite_Get"].gameObject:SetActive(true)
	--listItem.Controls["UIGroup_Tween_StandBy"].gameObject:SetActive(true)
end

ShowPage =
{
    [1] = ShowNewPlayerGift,
    [2] = ShowSignInPage,
    [3] = ShowContinueLoginPage,
    -- [4] = ShowDailyOnlinePage,
    -- [5] = ShowWishPage,
	 [4] = ShowAddStrengthPage,
	 [5] = ShowExchangeIDPage,
	 [6] = ShowRechargeReturnPage,
}

-- endregion

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
    --设置福利界面领取按钮回调函数ShowNewPlayerGift
end

local function hide()
    -- print(name, "hide")
end

local function refresh(params)
    -- print(name, "refresh")
	if params and type(params) == "table" and params.tabindex2 then 
		g_TabIndex = params.tabindex2-1
	end
	fields.UIList_WelfareTab:SetUnSelectedIndex(g_TabIndex)
	fields.UIList_WelfareTab:SetSelectedIndex(g_TabIndex)
    RefreshRedDot()
end

local function update()
    -- print(name, "update")
end

local function second_update(now)
    -- print(name, "second_update")
    -- 判断每日在线是否可以领取奖励
    local dailyOnlineData = WelfareManager.GetDailyOnlineData()
    local timeTypeList = dailyOnlineData.TimeTypeList
    for i = 1, #timeTypeList do
        if not dailyOnlineData.bReceivedGift[timeTypeList[i]] and dailyOnlineData.DailyOnlineSeconds >= timeTypeList[i] then
            -- UITools.SetButtonEnabled(fields.UIButton_Receive02,true)
			fields.UIButton_Receive02.isEnabled = true
        end
    end
    -- 显示每日在线数据
    local dateTime = timeutils.getDateTime(dailyOnlineData.DailyOnlineSeconds)
    fields.UILabel_OnlineTime.text = format(LocalString.Welfare_OnlineTime, dateTime.hours, dateTime.minutes, dateTime.seconds)
	-- 显示距离下次吃包子时间
	if g_LeftSecs > 0 then
		g_LeftSecs = g_LeftSecs - 1
		--local leftTime = timeutils.getDateTime(g_LeftSecs)	
		--fields.UILabel_NextMealOpeningTime.text = format(LocalString.Welfare_AddStrength_NextMealOpenTime,leftTime.hours,leftTime.minutes,leftTime.seconds)			
	else
		-- 剩余时间为0
		if fields.UIGroup_AddStrength.gameObject.activeSelf then
			-- if fields.UIGroup_NextMealTime.gameObject .activeSelf then
			-- 	fields.UIGroup_NextMealTime.gameObject:SetActive(false)
			-- end
			-- 刷新界面
			ShowAddStrengthPage()
		end
	end
end

local function init(params)
    name, gameObject, fields = unpack(params)

    InitWelfareTypeList()

    EventHelper.SetListSelect(fields.UIList_WelfareTab, function(listItem)
        fields[UIGROUP_COMS_NAME[listItem.Index + 1]].gameObject:SetActive(true)
		g_TabIndex = listItem.Index
        ShowPage[listItem.Index + 1]()
    end )

    EventHelper.SetListUnSelect(fields.UIList_WelfareTab, function(listItem)
        fields[UIGROUP_COMS_NAME[listItem.Index + 1]].gameObject:SetActive(false)
    end )

end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    init                      = init,
    show                      = show,
    hide                      = hide,
    update                    = update,
    second_update             = second_update,
    destroy                   = destroy,
    refresh                   = refresh,
    ShowNewPlayerGift         = ShowNewPlayerGift,
    ShowSignInPage            = ShowSignInPage,
    ShowContinueLoginPage     = ShowContinueLoginPage,
    ShowDailyOnlinePage       = ShowDailyOnlinePage,
    ShowWishPage              = ShowWishPage,
	ShowAddStrengthPage	      = ShowAddStrengthPage,
    RefreshRedDot             = RefreshRedDot,
	OnGetPayReturn			  = OnGetPayReturn,
	OnGetContinueLoginGift	  = OnGetContinueLoginGift,
    uishowtype                = uishowtype,
}
