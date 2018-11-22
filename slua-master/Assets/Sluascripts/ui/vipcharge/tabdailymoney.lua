local require          = require
local unpack           = unpack
local print            = print
local colorutil        = colorutil
local format           = string.format
local UIManager        = require("uimanager")
local network          = require("network")
local BonusManager     = require("item.bonusmanager")
local ItemIntroduct    = require("item.itemintroduction")
local ItemEnum         = require("item.itemenum")
local ConfigManager    = require("cfg.configmanager")
local ItemManager      = require("item.itemmanager")
local CheckCmd         = require("common.checkcmd")
local VipChargeManager = require"ui.vipcharge.vipchargemanager"
local EventHelper      = UIEventListenerHelper

local gameObject
local name
local fields
local dailyMoneyData

local function SetRewardList(parentListItem,items)
    if not parentListItem or not items then 
        return 
    end
    local rewardList = parentListItem.Controls["UIList_Rewards"]
    if rewardList.Count ~= 0 then 
        return 
    end
	for i = 1, #items do 
		local listItem = rewardList:AddListItem()
		local baseType = items[i]:GetBaseType()
		local itemName = items[i]:GetName()
		local quality  = items[i]:GetQuality()
		listItem.Data  = items[i]
		listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(quality)
		listItem.Controls["UISprite_Fragment"].gameObject:SetActive(baseType == ItemEnum.ItemBaseType.Fragment)
		listItem.Controls["UISprite_Binding"].gameObject:SetActive(items[i]:IsBound())
        listItem.Controls["UILabel_Amount"].gameObject:SetActive(true)
		listItem.Controls["UILabel_Amount"].text = items[i]:GetNumber()
		listItem:SetIconTexture(items[i]:GetTextureName())
	end
	EventHelper.SetListClick(rewardList, function(listItem)
		ItemIntroduct.DisplayBriefItem( {item = listItem.Data} )
	end )
end

local function sort(data1,data2)
 	if (not data1) or (not data2) then
		return true
	end
	return (data1.day < data2.day)   
end

local function InitDailyMoneyList()
    if fields.UIList_DailyMoney.Count == 0 then 
        local data = ConfigManager.getConfig("activechargebonus")
        local rewardList = { }
        for _,configData in pairs(data) do
            rewardList[#rewardList + 1] = configData
        end
        utils.table_sort(rewardList,sort)
        -- 界面中list的item数量=购买项(1个)+奖品展示项
        local listCount = #rewardList + 1
        for i = 1,listCount do
            local listItem = fields.UIList_DailyMoney:AddListItem()
            -- 第一项为购买项
            if i == 1 then
	            local bonusItems = BonusManager.GetItemsOfSingleBonus(dailyMoneyData.clientshowitem)
                SetRewardList(listItem,bonusItems)

				listItem.Controls["UILabel_Desc3"].gameObject:SetActive(true)
				listItem.Controls["UILabel_Desc"] .text = LocalString.Charge_DailyMoney_HasBoughtDayNum1
				listItem.Controls["UILabel_Desc3"] .text = format(LocalString.Charge_DailyMoney_HasBoughtDayNum2,VipChargeManager.GetTotalDailyMoneyPayTime())
                listItem.Controls["UILabel_Desc2"].gameObject:SetActive(false) 
               	EventHelper.SetClick(listItem.Controls["UIButton_Buy"],function()
	                local params = { }
                    params.title = LocalString.TipText
		            params.content = format(LocalString.Charge_DailyMoney_Rewards,bonusItems[1]:GetNumber(),bonusItems[1]:GetName(),bonusItems[2]:GetNumber(),bonusItems[2]:GetName(),bonusItems[3]:GetNumber(),bonusItems[3]:GetName())
                    params.callBackFunc = function() 
			            --local validated = CheckCmd.Check( { moduleid = cfg.cmd.ConfigId.ACTIVE_PAY, cmdid = dailyMoneyData.chargeid, num = 1, showsysteminfo = true })
			            local validated = (VipChargeManager.GetDailyMoneyPayTime() < dailyMoneyData.daylimit.num)
			            if validated then 
                            VipChargeManager.SendCGetApporder(dailyMoneyData.chargeid)
			            else
				            UIManager.ShowSystemFlyText(format(LocalString.CheckConditionInfo[dailyMoneyData.daylimit.class],dailyMoneyData.daylimit.num))
			            end
		            end
                    UIManager.ShowSingleAlertDlg(params)
	            end) 
            else
               -- 其他项为奖品展示项
                local bonusItems = BonusManager.GetItemsOfSingleBonus(rewardList[i-1].bonus)
                SetRewardList(listItem,bonusItems)

				listItem.Controls["UILabel_Desc3"].gameObject:SetActive(false)
                listItem.Controls["UILabel_Desc"] .text = format(LocalString.Charge_DailyMoney_TotalDayNum,rewardList[i-1].day)
 
                listItem.Controls["UIButton_Buy"].gameObject:SetActive(false) 
            end
        end
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
	local validated = (VipChargeManager.GetDailyMoneyPayTime() < dailyMoneyData.daylimit.num)
    local listItem = fields.UIList_DailyMoney:GetItemByIndex(0)
    listItem.Controls["UILabel_Desc"] .text =LocalString.Charge_DailyMoney_HasBoughtDayNum1
	listItem.Controls["UILabel_Desc3"] .text = format(LocalString.Charge_DailyMoney_HasBoughtDayNum2,VipChargeManager.GetTotalDailyMoneyPayTime())
	listItem.Controls["UILabel_Desc3"].gameObject:SetActive(true)
	if validated then 
		UITools.SetButtonEnabled(listItem.Controls["UIButton_Buy"] ,true)
	else
		UITools.SetButtonEnabled(listItem.Controls["UIButton_Buy"] ,false)
	end
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
	local chargeData = ConfigManager.getConfig("charge")
	dailyMoneyData = nil
	for chargeId, data in pairs(chargeData) do
		if data.class == "cfg.pay.ActiveCharge" then
			dailyMoneyData = data
			break
		end
	end
    InitDailyMoneyList()
    fields.UILabel_VIP.gameObject:SetActive(not shouldHideVip()) 
end

return {
	init       = init,
	show       = show,
	hide       = hide,
	update     = update,
	destroy    = destroy,
	refresh    = refresh,
	uishowtype = uishowtype,
}
