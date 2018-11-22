local require          = require
local unpack           = unpack
local print            = print
local format           = string.format
local UIManager        = require("uimanager")
local network          = require("network")
local BonusManager     = require("item.bonusmanager")
local ItemManager      = require("item.itemmanager")
local ItemIntroduct    = require("item.itemintroduction")
local ItemEnum         = require("item.itemenum")
local ConfigManager    = require("cfg.configmanager")
local WelfareManager   = require("ui.welfare.welfaremanager")
local PlayerRole = require "character.playerrole"
local configManager = require "cfg.configmanager"
local VipChargeManager = require "ui.vipcharge.vipchargemanager"
local EventHelper      = UIEventListenerHelper

local gameObject
local name
local fields
local MONTH_CARD_DAYS = 30


local function GetCurVipData()
	local vipdata = configManager.getConfig("vipbonus")
	for _,data in pairs(vipdata) do
		if data.viplevel == PlayerRole:Instance().m_VipLevel + 1 then
			return data
		end
	end
	return nil
end

local function GetTheMoneyNeedToCharge(curvipdata) --所需要的钱和比例

	local curTotalCharge = VipChargeManager.GetTotalCharge()/ 100 --这个地方还要改回来

	local vipNeedToCharge = curvipdata.needcharge
	--	if curTotalCharge >= vipNeedToCharge then
	--		return 0,1
	--	else
	return (vipNeedToCharge - curTotalCharge),curTotalCharge/vipNeedToCharge
	--	end
end
local function InitUIs()
	local VipChargeManager = require "ui.vipcharge.vipchargemanager"

	local monthCardData = WelfareManager.GetMonthCardData()
	local bReceivedDays = { }
	for day = 1, MONTH_CARD_DAYS do
		bReceivedDays[day] = false
	end

	-- 标注已领取奖励的天
	for _, day in pairs(monthCardData.ReceivedDays) do
		bReceivedDays[day] = true
	end

	local today = 1
	if monthCardData.LeftDayNum > 0 then
		if math.fmod(monthCardData.LeftDayNum, MONTH_CARD_DAYS) == 0 then
			today = 1
		else
			today = MONTH_CARD_DAYS - math.fmod(monthCardData.LeftDayNum, MONTH_CARD_DAYS) + 1
		end
	end
	-- 剩余天数
	fields.UILabel_RemainDay.text = string.format(LocalString.Welfare_MonthCard_RemainDays, monthCardData.LeftDayNum)

	-- 月卡描述
	local productCfg = VipChargeManager.GetProductCfgData(1)
	local money1 = BonusManager.GetItemsOfSingleBonus(productCfg.getyuanbao)
	local money2 = BonusManager.GetItemsOfSingleBonus(productCfg.getbindyuanbao)
	fields.UILabel_DescMonth.text = string.format(LocalString.Welfare_MonthCard_PageDesc, money1[1]:GetNumber(), money2[1]:GetNumber())
	fields.UILabel_BuyMonth.text = tostring(productCfg.price/100)..LocalString.VipCharge_Yuan..LocalString.Welfare_MonthCard_Buy

	-- 至尊卡描述
	productCfg = VipChargeManager.GetProductCfgData(12)
	money1 = BonusManager.GetItemsOfSingleBonus(productCfg.getyuanbao)
	money2 = BonusManager.GetItemsOfSingleBonus(productCfg.getbindyuanbao)
	fields.UILabel_DescSupreme.text = string.format(LocalString.Welfare_SupremeCard_PageDesc, money1[1]:GetNumber(), money2[1]:GetNumber())
	fields.UILabel_BuySupreme.text = tostring(productCfg.price/100)..LocalString.VipCharge_Yuan..LocalString.Welfare_MonthCard_Buy

	EventHelper.SetClick(fields.UIButton_BuyMonth, function()
		VipChargeManager.SendCGetApporder(1)

		-- local strTitle = LocalString.Welfare_MonthCard_Tip_Renewal
		-- local strBtn = LocalString.Welfare_MonthCard_Tip_Renewal
		-- if monthCardData.bBoughtCard then
		-- 	strTitle = LocalString.Welfare_MonthCard_Tip_BuyMonthCard
		-- 	strBtn = LocalString.Welfare_MonthCard_Buy
		-- end
		-- UIManager.ShowSingleAlertDlg({
		-- 	title = strTitle,
		-- 	content = LocalString.Welfare_MonthCard_Content,
		-- 	-- 调用续期界
		-- 	callBackFunc = function()
		-- 		UIManager.hidedialog("vipcharge.dlgrecharge")
		-- 		VipchargeManager.ShowVipChargeDialog()
		-- 	end,
		-- 	buttonText = strBtn
		-- })
	end)
	-- 月卡奖励内容
	local items = BonusManager.GetItemsOfBonus( { bonustype = "cfg.bonus.MonthlyCard", csvid = today })
	fields.UIGroup_MonthGift.transform:Find("UITexture_DayGift_Icon").gameObject:GetComponent("UITexture"):SetIconTexture(items[1]:GetTextureName())
	fields.UIGroup_MonthGift.transform:Find("UISprite_DayGift_Quality").gameObject:GetComponent("UISprite").spriteName = colorutil.GetQualitySprite(items[1]:GetQuality())
	fields.UIGroup_MonthGift.transform:Find("UILabel_DayGift_Amount").gameObject:GetComponent("UILabel").text = items[1]:GetNumber()
	local btnMonthGitf = fields.UIGroup_MonthGift.transform:Find("UIButton_MonthGiftIcon").gameObject:GetComponent("UISprite")
	EventHelper.SetClick(btnMonthGitf,function()
		local params={item=items[1],buttons={{display=false,text="",callFunc=nil},{display=false,text="",callFunc=nil}}}
		ItemIntroduct.DisplayBriefItem(params)
	end)

	-- 至尊卡奖励内容
	local supremeDailyNum = VipChargeManager.GetSupremeDailyGitfNum()
	local items = BonusManager.GetItemsOfServerBonus({bindtype=0, items={[10200003]=supremeDailyNum}})
	if #items > 0 then
		fields.UIGroup_SupremeGift.transform:Find("UITexture_DayGift_Icon").gameObject:GetComponent("UITexture"):SetIconTexture(items[1]:GetTextureName())
		fields.UIGroup_SupremeGift.transform:Find("UISprite_DayGift_Quality").gameObject:GetComponent("UISprite").spriteName = colorutil.GetQualitySprite(items[1]:GetQuality())
		fields.UIGroup_SupremeGift.transform:Find("UILabel_DayGift_Amount").gameObject:GetComponent("UILabel").text = items[1]:GetNumber()
		-- labelstring = string.format(LocalString.Red_Packet_Fetch_Info, items[1]:GetNumber(), items[1]:GetName())
		local btnSupremeGitf = fields.UIGroup_SupremeGift.transform:Find("UIButton_SupremeGiftIcon").gameObject:GetComponent("UISprite")
        EventHelper.SetClick(btnSupremeGitf,function()
            local params={item=items[1],buttons={{display=false,text="",callFunc=nil},{display=false,text="",callFunc=nil}}}
            ItemIntroduct.DisplayBriefItem(params)
        end)
	end
	-- fields.UITexture_DayGift_Icon:SetIconTexture(items[2]:GetTextureName())
	-- fields.UISprite_DayGift_Quality.spriteName = colorutil.GetQualitySprite(items[2]:GetQuality())
	-- fields.UILabel_DayGift_Amount.text = items[2]:GetNumber()

	EventHelper.SetClick(fields.UIButton_BuySupreme, function()
		-- UIManager.ShowSingleAlertDlg({
		-- 	title = LocalString.Welfare_SupremeCard_Tip_BuySupremeCard,
		-- 	content = LocalString.Welfare_SupremeCard_Content,
		-- 	-- 调用续期界
		-- 	callBackFunc = function()
		-- 		UIManager.hidedialog("vipcharge.dlgrecharge")
		-- 		VipchargeManager.ShowVipChargeDialog()
		-- 	end,
		-- 	buttonText = LocalString.Welfare_MonthCard_Buy
		-- })
		VipChargeManager.SendCGetApporder(12)
	end)
	EventHelper.SetClick(fields.UIButton_GetMonthGift, function()
		if monthCardData.LeftDayNum > 0 and(not bReceivedDays[today]) then
			local msg = lx.gs.bonus.msg.CGetMonthCardGift( { date = today })
			network.send(msg)
		end
	end)
	EventHelper.SetClick(fields.UIButton_GetSupremeGift, function()
		network.create_and_send("lx.gs.bonus.msg.CGetSupremeCardGift", {date=1})
	end)

	if monthCardData.bBoughtCard then
		-- 月卡用户
		if bReceivedDays[today] then
			fields.UILabel_GetMonthGift.text = LocalString.Welfare_ButtonStatus_HasReceived
			fields.UIButton_GetMonthGift.isEnabled = false
		else
			fields.UILabel_GetMonthGift.text = LocalString.Welfare_ButtonStatus_NotReceived
			fields.UIButton_GetMonthGift.isEnabled = true
		end
		-- 续期
		--fields.UILabel_BuyMonth.text = LocalString.Welfare_MonthCard_Button_Renewal
		fields.UILabel_RemainDay.gameObject:SetActive(true)
		fields.UILabel_NotOwnedMonth.gameObject:SetActive(false)
	else
		-- 非月卡用户
		fields.UILabel_GetMonthGift.text = LocalString.Welfare_ButtonStatus_Text001--"未购买"
		fields.UIButton_GetMonthGift.isEnabled = false
		-- 充值
		--fields.UILabel_BuyMonth.text = LocalString.Welfare_MonthCard_Button_Recharge
		fields.UILabel_RemainDay.gameObject:SetActive(false)
		fields.UILabel_NotOwnedMonth.gameObject:SetActive(true)
	end

	local supremeCard = WelfareManager.GetSupremeCardData()
	if supremeCard.HasCard then
		if supremeCard.TodayRecv then
			fields.UILabel_GetSupremeGift.text = LocalString.Welfare_ButtonStatus_HasReceived
			fields.UIButton_GetSupremeGift.isEnabled = false
		else
			fields.UILabel_GetSupremeGift.text = LocalString.Welfare_ButtonStatus_NotReceived
			fields.UIButton_GetSupremeGift.isEnabled = true
		end
		fields.UIButton_BuySupreme.isEnabled = false
		fields.UILabel_OwnedSupreme.gameObject:SetActive(true)
		fields.UILabel_NotOwnedSupreme.gameObject:SetActive(false)
	else
		fields.UILabel_GetSupremeGift.text = LocalString.Welfare_ButtonStatus_Text001--"未购买"
		fields.UIButton_GetSupremeGift.isEnabled = false
		fields.UIButton_BuySupreme.isEnabled = true
		fields.UILabel_OwnedSupreme.gameObject:SetActive(false)
		fields.UILabel_NotOwnedSupreme.gameObject:SetActive(true)
	end
	--vip
	fields.UILabel_VIPNext.text = PlayerRole:Instance().m_VipLevel or 0						--角色当前vip值
	local curvipdata = GetCurVipData()
	--fields.UILabel_VIPNext.text = curvipdata.viplevel										--下一个VIP等级
	local moneyneedtocharge
	local value
	local firstcharge = configManager.getConfig("firstcharge")
	local rate = firstcharge.rmbtojifen

	moneyneedtocharge,value = GetTheMoneyNeedToCharge(curvipdata)
	local moneyneedtocharge1 = math.ceil(moneyneedtocharge)
	fields.UILabel_Recharge_Title.text = string.format(LocalString.Welfare_MonthCard_TitleRecharge,moneyneedtocharge1 * rate, curvipdata.viplevel)
	fields.UILabel_TheMoneyNeedToCharge.text = (curvipdata.needcharge * rate - moneyneedtocharge1 * rate) .."/"..curvipdata.needcharge * rate
	fields.UISlider_Recharge.value = value                         -- 黄条比例
	EventHelper.SetClick(fields.UIButton_GVIP, function()
		UIManager.hidedialog("vipcharge.dlgrecharge")
		UIManager.showdialog("vipcharge.dlgprivilege_vip")
	end)
	EventHelper.SetClick(fields.UIButton_GRECH, function()
		UIManager.hidedialog("vipcharge.dlgrecharge")
		UIManager.showdialog("vipcharge.dlgrecharge")
	end)
end

--至尊卡领取结果
local function OnMsgSupremeCardGift(msg)
	fields.UIButton_GetSupremeGift.isEnabled = false
	fields.UILabel_GetSupremeGift.text = LocalString.Welfare_ButtonStatus_HasReceived
	-- 刷新红点
	if UIManager.isshow("dlgdialog") then 
		UIManager.call("dlgdialog","RefreshRedDot","vipcharge.dlgrecharge")
	end
end

--月卡领取结果
local function OnMsgMonthCardGift(msg)
	fields.UIButton_GetMonthGift.isEnabled = false
	fields.UILabel_GetMonthGift.text = LocalString.Welfare_ButtonStatus_HasReceived
	-- 刷新红点
	if UIManager.isshow("dlgdialog") then 
		UIManager.call("dlgdialog","RefreshRedDot","vipcharge.dlgrecharge")
	end
end

local function destroy()
	-- print(name, "destroy")
end

local function show(params)
	-- print(name, "show")
end

local function hide()
	-- print(name, "hide")
end

local function refresh(params)
	-- print(name, "refresh")
	InitUIs()
	-- 刷新红点
	if UIManager.isshow("dlgdialog") then 
		UIManager.call("dlgdialog","RefreshRedDot","vipcharge.dlgrecharge")
	end
end

local function update()
	-- print(name, "update")
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
	name, gameObject, fields = unpack(params)
	InitUIs()
end

return {
	init               = init,
	show               = show,
	hide               = hide,
	update             = update,
	destroy            = destroy,
	refresh            = refresh,
	uishowtype         = uishowtype,
	OnMsgMonthCardGift = OnMsgMonthCardGift,
	OnMsgSupremeCardGift = OnMsgSupremeCardGift,
}


--[[  以下为旧版本
local MONTH_CARD_DAYS = 30


local function InitMonthCardList()
	if fields.UIList_MonthCard.Count == 0 then
		for day = 1, MONTH_CARD_DAYS do
			-- 365天，待定
			local items = BonusManager.GetItemsOfBonus( { bonustype = "cfg.bonus.MonthlyCard", csvid = day })
			local listItem = fields.UIList_MonthCard:AddListItem()
			listItem:SetText("UILabel_MonthCard_DayCount", format(LocalString.Welfare_Day, day))
			listItem.Controls["UISprite_Select"].gameObject:SetActive(false)
			listItem:SetIconTexture(items[1]:GetTextureName())
			listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(items[1]:GetQuality())
			listItem.Controls["UISprite_Fragment"].gameObject:SetActive(items[1]:GetBaseType() == ItemEnum.ItemBaseType.Fragment)
			listItem.Controls["UILabel_Amount"].text = items[1]:GetNumber()
			listItem.Data = items[1]
		end

		EventHelper.SetListClick(fields.UIList_MonthCard, function(listItem)
			ItemIntroduct.DisplayBriefItem( { item = listItem.Data })
		end )
	end
end

local function RefreshMonthCard()

	local monthCardData = WelfareManager.GetMonthCardData()
	local bReceivedDays = { }
	for day = 1, MONTH_CARD_DAYS do
		bReceivedDays[day] = false
	end

	-- 标注已领取奖励的天
	for _, day in pairs(monthCardData.ReceivedDays) do
		bReceivedDays[day] = true
		local listItem = fields.UIList_MonthCard:GetItemByIndex(day - 1)
		listItem.Controls["UISprite_Select"].gameObject:SetActive(true)
	end

	local today = 1
	if monthCardData.LeftDayNum > 0 then
		if math.fmod(monthCardData.LeftDayNum, MONTH_CARD_DAYS) == 0 then
			today = 1
		else
			today = MONTH_CARD_DAYS - math.fmod(monthCardData.LeftDayNum, MONTH_CARD_DAYS) + 1
		end
	end
	-- 剩余天数
	fields.UILabel_MonthCard_LeftDays.text = monthCardData.LeftDayNum
	-- 奖励内容
	local items = BonusManager.GetItemsOfBonus( { bonustype = "cfg.bonus.MonthlyCard", csvid = today })
	fields.UITexture_DayGift_Icon:SetIconTexture(items[2]:GetTextureName())
	fields.UISprite_DayGift_Quality.spriteName = colorutil.GetQualitySprite(items[2]:GetQuality())
	fields.UILabel_DayGift_Amount.text = items[2]:GetNumber()
	-- 标题
	fields.UILabel_MonthCard_Title.text = format(LocalString.Welfare_MonthCard_Title, MONTH_CARD_DAYS, MONTH_CARD_DAYS *(items[2]:GetNumber()))

	if monthCardData.bBoughtCard then
		-- 月卡用户
		if bReceivedDays[today] then
			-- UITools.SetButtonEnabled(fields.UIButton_Receive ,false)
			fields.UIButton_Receive.isEnabled = false
			fields.UIGroup_uifx_kuang01.gameObject:SetActive(false)
			fields.UILabel_Receive.text = LocalString.Welfare_ButtonStatus_HasReceived
		else
			-- UITools.SetButtonEnabled(fields.UIButton_Receive ,true)
			fields.UIButton_Receive.isEnabled = true
			fields.UIGroup_uifx_kuang01.gameObject:SetActive(true)
			fields.UILabel_Receive.text = LocalString.Welfare_ButtonStatus_NotReceived
		end
		fields.UILabel_Renewal.text = LocalString.Welfare_MonthCard_Button_Renewal

		EventHelper.SetClick(fields.UIButton_Renewal, function()
			UIManager.ShowSingleAlertDlg(
			{
				title = LocalString.Welfare_MonthCard_Tip_Renewal,
				content = LocalString.Welfare_MonthCard_Content,
				-- 调用续期界
				callBackFunc = function()
					UIManager.hidedialog("vipcharge.dlgrecharge")
					local VipchargeManager = require "ui.vipcharge.vipchargemanager"
					VipchargeManager.ShowVipChargeDialog()
				end,
				buttonText = LocalString.Welfare_MonthCard_Tip_Renewal
			} )
		end )
	else
		-- 非月卡用户
		-- UITools.SetButtonEnabled(fields.UIButton_Receive ,false)
		fields.UIButton_Receive.isEnabled = false
		fields.UIGroup_uifx_kuang01.gameObject:SetActive(false)
		fields.UILabel_Receive.text = LocalString.Welfare_ButtonStatus_NotReceived
		fields.UILabel_Renewal.text = LocalString.Welfare_MonthCard_Button_Recharge

		EventHelper.SetClick(fields.UIButton_Renewal, function()

			-- UIManager.ShowSingleAlertDlg(
			-- {
			-- 	title = LocalString.Welfare_MonthCard_Tip_BuyMonthCard,
			-- 	content = LocalString.Welfare_MonthCard_Content,
			-- 	-- 调用充值界面
			-- 	callBackFunc = function()
			-- 		UIManager.hidedialog("vipcharge.dlgrecharge")
			-- 		local VipchargeManager = require "ui.vipcharge.vipchargemanager"
			-- 		VipchargeManager.ShowVipChargeDialog()
			-- 	end,
			-- 	buttonText = LocalString.Welfare_MonthCard_Buy
			-- } )
		end )
	end

	EventHelper.SetClick(fields.UIButton_Receive, function()

		if monthCardData.LeftDayNum > 0 and(not bReceivedDays[today]) then
			local msg = lx.gs.bonus.msg.CGetMonthCardGift( { date = today })
			network.send(msg)
		end
	end )

	EventHelper.SetClick(fields.UIButton_DayGiftBox, function()
		ItemIntroduct.DisplayBriefItem( { item = items[2] })
	end )

end

local function OnGetMonthCardGift(params)
	local listItem = fields.UIList_MonthCard:GetItemByIndex(params.date - 1)
	listItem.Controls["UISprite_Select"].gameObject:SetActive(true)
	-- UITools.SetButtonEnabled(fields.UIButton_Receive,false)
	fields.UIButton_Receive.isEnabled = false
	fields.UIGroup_uifx_kuang01.gameObject:SetActive(false)
	fields.UILabel_Receive.text = LocalString.Welfare_ButtonStatus_HasReceived
	-- 刷新红点
	if UIManager.isshow("dlgdialog") then 
		UIManager.call("dlgdialog","RefreshRedDot","vipcharge.dlgrecharge")
	end
end

local function destroy()
	-- print(name, "destroy")
end

local function show(params)
	-- print(name, "show")
end

local function hide()
	-- print(name, "hide")
end

local function refresh(params)
	-- print(name, "refresh")
	RefreshMonthCard()
	-- 刷新红点
	if UIManager.isshow("dlgdialog") then 
		UIManager.call("dlgdialog","RefreshRedDot","vipcharge.dlgrecharge")
	end
end

local function update()
	-- print(name, "update")
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
	name, gameObject, fields = unpack(params)
	InitMonthCardList()
end

return {
	init               = init,
	show               = show,
	hide               = hide,
	update             = update,
	destroy            = destroy,
	refresh            = refresh,
	uishowtype         = uishowtype,
	OnGetMonthCardGift = OnGetMonthCardGift,
}
]]
