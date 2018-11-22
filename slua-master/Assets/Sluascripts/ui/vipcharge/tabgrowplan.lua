local require        = require
local unpack         = unpack
local print          = print
local format		 = string.format
local UIManager      = require("uimanager")
local network        = require("network")
local BonusManager   = require("item.bonusmanager")
local ItemIntroduct  = require("item.itemintroduction")
local ItemEnum       = require("item.itemenum")
local CheckCmd       = require("common.checkcmd")
local ConfigManager  = require("cfg.configmanager")
local WelfareManager = require("ui.welfare.welfaremanager")
local VipChargeManager = require ("ui.vipcharge.vipchargemanager")
local EventHelper    = UIEventListenerHelper

local gameObject
local name
local fields
local g_curPageIdx = 0

local function RefreshRedDot()
	local UnRead_GrowPlanPage0 = WelfareManager.UnRead_GrowPlanPage0
    local UnRead_WholeWelfare = WelfareManager.UnRead_WholeWelfare
	local listItem = fields.UIList_RadioButton:GetItemByIndex(0)
	listItem.Controls["UISprite_Warning"].gameObject:SetActive(UnRead_GrowPlanPage0())
	listItem = fields.UIList_RadioButton:GetItemByIndex(1)
	listItem.Controls["UISprite_Warning"].gameObject:SetActive(UnRead_WholeWelfare())
    -- 红点刷新
	if UIManager.needrefresh("dlgdialog") then
		UIManager.call("dlgdialog","RefreshRedDot","vipcharge.dlgrecharge")
	end
end

local function InitGrowPlanList(planLevel)
    if fields.UIList_GrowPlan.Count == 0 then
		local growPlanData = WelfareManager.GetGrowPlanData()
        local growPlanConfigData = ConfigManager.getConfig("growplan")
		--购买当前成长计划时候登陆的天数
		local startDayIndex = 1
		local daycount = 0
		for chargeId, chargeData in pairs(growPlanData.ChargeProductList) do
			if chargeData.growplantype == planLevel then 
				daycount = chargeData.totalday
				startDayIndex = chargeData.startdayindex
			end
		end

		local bAllReceived = true
		for day = 1,daycount do
			if growPlanData.bReceivedDays[startDayIndex + day - 1] == false then
				bAllReceived = false
				break
			end
		end
		if bAllReceived then 
			planLevel = planLevel + 1
			if planLevel <= growPlanData.MaxGrowPlanLevel then 
				
				for chargeId, chargeData in pairs(growPlanData.ChargeProductList) do
					if chargeData.growplantype == planLevel then 
						daycount = chargeData.totalday
						startDayIndex = chargeData.startdayindex
						break
					end
				end
			else 
				-- 全部档成长计划均领取完毕,依然显示最后的成长
				planLevel = growPlanData.MaxGrowPlanLevel
			end
		end
		-- 初始化成长计划标题
		if planLevel <= growPlanData.MaxGrowPlanLevel then
			-- fields.UILabel_GrowPlanStatus.text = LocalString.Welfare_GrowPlan_PlanNames[planLevel]
			fields.UILabel_GrowPlanStatus.text = ""
		end

		for day = 1,daycount do
			local listItem = fields.UIList_GrowPlan:AddListItem()

			local items = BonusManager.GetItemsOfBonus( { bonustype = "cfg.bonus.GrowPlan", csvid = (startDayIndex + day - 1) })
            local curGrowPlanConfigData = growPlanConfigData[startDayIndex + day - 1]
			-- 初始化数据
			local dayGiftList = listItem.Controls["UIList_GrowPlanDayGifts"]
			for i = 1, #items do
				local dayGiftListItem = dayGiftList:AddListItem()
				dayGiftListItem:SetIconTexture(items[i]:GetTextureName())
				dayGiftListItem.Controls["UILabel_Amount"].text = items[i]:GetNumber()
				dayGiftListItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(items[i]:GetQuality())
				dayGiftListItem.Controls["UISprite_Fragment"].gameObject:SetActive(items[i]:GetBaseType() == ItemEnum.ItemBaseType.Fragment)
				dayGiftListItem.Controls["UISprite_Get"].gameObject:SetActive(false)
				dayGiftListItem.Data = items[i]
			end

			listItem:SetText("UILabel_GrowPlanLevel", format(LocalString.Welfare_GrowPlan_RequireLevel, curGrowPlanConfigData.requirelvl.level))
			listItem:SetText("UILabel_WholeWelfare1", "");
			listItem:SetText("UILabel_WholeWelfare2", "");
			local buttonReceive = listItem.Controls["UIButton_Receive"]

            local bValidated = CheckCmd.CheckData({ data = curGrowPlanConfigData.requirelvl,showsysteminfo = false, num = 1 })
			-- 已经购买当前级别成长计划
			if growPlanData.CurGrowPlanLevel == planLevel then
				-- 领取过，关闭领取按钮
				if growPlanData.bReceivedDays[startDayIndex + day - 1] then
					buttonReceive.isEnabled = false
					listItem:SetText("UILabel_Receive", LocalString.Welfare_ButtonStatus_HasReceived)
					-- 设置为已经领取状态
					for i = 1,dayGiftList.Count do
						local dayGiftListItem = dayGiftList:GetItemByIndex(i-1)
						dayGiftListItem.Controls["UISprite_Get"].gameObject:SetActive(true)
					end
				else
					-- 没领取过
					listItem:SetText("UILabel_Receive", LocalString.Welfare_ButtonStatus_NotReceived)
					-- 已购买且达到领取等级要求 
					buttonReceive.isEnabled = true
				end
				local PlayerRole=  require "character.playerrole"
				if PlayerRole:Instance():GetLevel() < curGrowPlanConfigData.requirelvl.level then 
					buttonReceive.isEnabled = false
				end
			else
				-- 未购买当前级别成长计划
				listItem:SetText("UILabel_Receive", LocalString.Welfare_ButtonStatus_NotReceived)
				buttonReceive.isEnabled = false
			end

			EventHelper.SetClick(buttonReceive, function()
				local planLevel = (WelfareManager.GetGrowPlanData()).CurGrowPlanLevel
                local bValidated = CheckCmd.CheckData({ data = curGrowPlanConfigData.requirelvl,showsysteminfo = true, num = 1 })

				if planLevel ~= 0 and bValidated then 
					local msg = lx.gs.bonus.msg.CGetGrowPlanGift( { growplantype = planLevel,giftindx = (startDayIndex + day - 1) })
					network.send(msg)
				end
			end )

			EventHelper.SetListClick(dayGiftList, function(listItem)
				ItemIntroduct.DisplayBriefItem( {item = listItem.Data} )
			end )
		end
		return bAllReceived
	end
end

-- 成长计划界面
local function RefreshGrowPlan()
	fields.UITexture_Bg:SetIconTexture("ICON_Activity_BG15")
    local growPlanData = WelfareManager.GetGrowPlanData()
	local planLevel = growPlanData.CurGrowPlanLevel
	local bonusConfig = ConfigManager.getConfig("bonusconfig")

	fields.UIList_GrowPlan:Clear()
	local bAllReceived = InitGrowPlanList(planLevel)

	if bAllReceived then
		if planLevel >= growPlanData.MaxGrowPlanLevel then
			fields.UIButton_BuyGrowPlan.gameObject:SetActive(false)
		else
			planLevel = planLevel + 1
			fields.UIButton_BuyGrowPlan.gameObject:SetActive(true)

		end
	else 
		fields.UIButton_BuyGrowPlan.gameObject:SetActive(false)
	end
	local chargeData = nil
	for chargeId, data in pairs(growPlanData.ChargeProductList) do
		if data.growplantype == planLevel then 
			chargeData = data
			break
		end
	end

	if chargeData then
		fields.UIButton_BuyGrowPlan.isEnabled = true
	else
		--全部档位成长计划购买完毕
		fields.UIButton_BuyGrowPlan.isEnabled = false
	end
	
	EventHelper.SetClick(fields.UIButton_BuyGrowPlan, function()
		if chargeData then 
			VipChargeManager.SendCGetApporder(chargeData.chargeid)
		end
    end)
end
-- 全民福利界面
local function RefreshWholeWelfare()
	fields.UITexture_Bg:SetIconTexture("ICON_Activity_BG16")
	fields.UIButton_BuyGrowPlan.gameObject:SetActive(false)
    local wholeWelfareData = WelfareManager.GetWholeWelfareData()
	fields.UIList_GrowPlan:Clear()
	local wholeWelfareCfg = ConfigManager.getConfig("wholepeoplebonus")

	fields.UILabel_GrowPlanStatus.text = format(LocalString.Welfare_WholeWelfare_HasBought, wholeWelfareData.ChargeNum)
	for day, it in pairs(wholeWelfareCfg) do
		local listItem = fields.UIList_GrowPlan:AddListItem()
		local bonusInfo = BonusManager.GetItemsOfSingleBonus(it.bonus)
		-- 初始化数据
		local dayGiftList = listItem.Controls["UIList_GrowPlanDayGifts"]
		for i, item in pairs(bonusInfo) do
			local dayGiftListItem = dayGiftList:AddListItem()
			dayGiftListItem:SetIconTexture(item:GetTextureName())
			dayGiftListItem.Controls["UILabel_Amount"].text = item:GetNumber()
			dayGiftListItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(item:GetQuality())
			dayGiftListItem.Controls["UISprite_Fragment"].gameObject:SetActive(item:GetBaseType() == ItemEnum.ItemBaseType.Fragment)
			dayGiftListItem.Controls["UISprite_Get"].gameObject:SetActive(wholeWelfareData.bReceivedDays[day])
			dayGiftListItem.Data = item
		end

		listItem:SetText("UILabel_GrowPlanLevel", "")
		listItem:SetText("UILabel_WholeWelfare1", format(LocalString.Welfare_WholeWelfare_NeedNum, it.num))
		listItem:SetText("UILabel_WholeWelfare2", format(LocalString.Welfare_GrowPlan_RequireLevel, it.levellimmit))
		local buttonReceive = listItem.Controls["UIButton_Receive"]
		if wholeWelfareData.bReceivedDays[day] then
			-- 领取过，关闭领取按钮
			buttonReceive.isEnabled = false
			listItem:SetText("UILabel_Receive", LocalString.Welfare_ButtonStatus_HasReceived)
		else
			-- 没领取过
			listItem:SetText("UILabel_Receive", LocalString.Welfare_ButtonStatus_NotReceived)
			local PlayerRole=  require "character.playerrole"
			if PlayerRole:Instance():GetLevel() < it.levellimmit
			    or wholeWelfareData.ChargeNum < it.num then
				buttonReceive.isEnabled = false
			else
				buttonReceive.isEnabled = true
			end
		end
		EventHelper.SetClick(buttonReceive, function()
			local PlayerRole=  require "character.playerrole"
			local bValidated = true
			if PlayerRole:Instance():GetLevel() < it.levellimmit then
				bValidated = false
			end
			if bValidated then 
				local msg = lx.gs.bonus.msg.CGetWholePeopleBonus( { bonusid = day })
				network.send(msg)
			end
		end)

		EventHelper.SetListClick(dayGiftList, function(listItem)
			ItemIntroduct.DisplayBriefItem( {item = listItem.Data} )
		end )
	end
end

local function OnGetGrowPlanGift(params)
    local growPlanData = WelfareManager.GetGrowPlanData()
	if growPlanData.CurGrowPlanLevel == params.growplantype then
		local totalDayCount = 0
		local startDayIndex = 1
		for chargeId, chargeData in pairs(growPlanData.ChargeProductList) do
			if chargeData.growplantype == growPlanData.CurGrowPlanLevel then 
				totalDayCount = chargeData.totalday
				startDayIndex = chargeData.startdayindex
			end
		end 

        local listItem = fields.UIList_GrowPlan:GetItemByIndex(params.giftindx - startDayIndex)
        local buttonReceive = listItem.Controls["UIButton_Receive"]
		buttonReceive.isEnabled = false
		local dayGiftList = listItem.Controls["UIList_GrowPlanDayGifts"]
						
		for i = 1,dayGiftList.Count do
			local dayGiftListItem = dayGiftList:GetItemByIndex(i-1)
			dayGiftListItem.Controls["UISprite_Get"].gameObject:SetActive(true)
		end
        listItem:SetText("UILabel_Receive", LocalString.Welfare_ButtonStatus_HasReceived)

		local bAllReceived = true
		for day = 1,totalDayCount do
			if growPlanData.bReceivedDays[startDayIndex + day - 1] == false then
				bAllReceived = false
				break
			end
		end
		if bAllReceived then 
			if growPlanData.CurGrowPlanLevel < growPlanData.MaxGrowPlanLevel then
				RefreshGrowPlan()
			end 
		end
		RefreshRedDot()
	end
end

local function OnGetWholeWelfareGift(msg)
	if g_curPageIdx~=1 then
		return
	end

	local lstIdx = msg.bonusid-1
	if lstIdx<0 or lstIdx>=fields.UIList_GrowPlan.Count then
		return
	end

	local listItem = fields.UIList_GrowPlan:GetItemByIndex(lstIdx)
	local buttonReceive = listItem.Controls["UIButton_Receive"]
	buttonReceive.isEnabled = false
	local dayGiftList = listItem.Controls["UIList_GrowPlanDayGifts"]
	for i = 1,dayGiftList.Count do
		local dayGiftListItem = dayGiftList:GetItemByIndex(i-1)
		dayGiftListItem.Controls["UISprite_Get"].gameObject:SetActive(true)
	end
	listItem:SetText("UILabel_Receive", LocalString.Welfare_ButtonStatus_HasReceived)
	RefreshRedDot()
end

local function SetPage(pageIdx)
	g_curPageIdx = pageIdx
	fields.UIList_RadioButton:SetSelectedIndex(pageIdx)
	if pageIdx==0 then
		RefreshGrowPlan()
	elseif pageIdx==1 then
		RefreshWholeWelfare()
	end
end

local function destroy()

end

local function show(params)

	local msg = lx.gs.bonus.msg.CGrowplanBuyNum({})
	network.send(msg)
end

local function hide()

end

local function refresh(params)

	fields.UIList_RadioButton:Clear()
	local listItem = fields.UIList_RadioButton:AddListItem()
	local labelPage = listItem.Controls["UILabel_Promotion"]
	labelPage.text = LocalString.Welfare_GrowPlan_Page1
	EventHelper.SetClick(listItem, function()
		SetPage(0)
	end)

	listItem = fields.UIList_RadioButton:AddListItem()
	labelPage = listItem.Controls["UILabel_Promotion"]
	labelPage.text = LocalString.Welfare_GrowPlan_Page2
	EventHelper.SetClick(listItem, function()
		SetPage(1)
	end)
	SetPage(0)

	RefreshRedDot()
end

local function update()
	
end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
  name, gameObject, fields = unpack(params)

end

return {
  init              = init,
  show              = show,
  hide              = hide,
  update            = update,
  destroy           = destroy,
  refresh           = refresh,
  uishowtype        = uishowtype,
  OnGetGrowPlanGift = OnGetGrowPlanGift,
  OnGetWholeWelfareGift = OnGetWholeWelfareGift,
  RefreshRedDot		= RefreshRedDot,
}
