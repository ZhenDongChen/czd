local DayChargeManager = require("ui.vipcharge.daychargemanager")
local BonusManager = require("item.bonusmanager")
local UIManager = require("uimanager")
local EventHelper               = UIEventListenerHelper

local name, gameObject, fields



local function SetActivityItem(uiItem, activityItem)
   
    uiItem:SetText("UILabel_Level", activityItem.m_Description)
    uiItem:SetText("UILabel_Level01", tostring(activityItem.m_Number))
    
    local rewardsList = uiItem.Controls["UIList_UpgradeRewards"]
    local rewards = activityItem:GetRewards()
    local rewardNum = (#rewards > 5) and 5 or #rewards

    UIHelper.ResetItemNumberOfUIList(rewardsList, rewardNum)
    for i = 1, rewardNum do
        local reward = rewards[i]
        local subUiItem = rewardsList:GetItemByIndex(i-1)
        BonusManager.SetRewardItem(subUiItem, reward)
    end

    
    local uiButton = uiItem.Controls["UIButton_UpgradeReceive"]
    local uiLabel = uiItem.Controls["UILabel_UpgradeReceive"]
    if activityItem:IsMatchCondition() then
        uiButton.isEnabled = true
        EventHelper.SetClick(uiButton, function()
            DayChargeManager.ReceiveActivityBonus(activityItem:GetGroupId(), activityItem:GetItemId())
        end)
    else
        uiButton.isEnabled = false
        EventHelper.SetClick(uiButton, function()
        end)
    end
    if activityItem:IsFinish() then
        uiLabel.text = activityItem:GetFinishedLabel()
    else
        uiLabel.text = activityItem:GetUnFinishLabel()
    end
end

local function SortFunc(itemA, itemB)
    if itemA.m_Id < itemB.m_Id then
        return true
    end
    return false
end

local function refresh(params)
    local activityItems = DayChargeManager.GetActivityItems()

    utils.table_sort(activityItems,SortFunc)

    local activityNum = #activityItems
    UIHelper.ResetItemNumberOfUIList(fields.UIList_ActivityRewards, activityNum)
    for i =1, activityNum do
        local uiItem = fields.UIList_ActivityRewards:GetItemByIndex(i-1)
        local activityItem = activityItems[i]
        SetActivityItem(uiItem, activityItem)
    end
    if UIManager.isshow("dlgdialog") then
        UIManager.call("dlgdialog","RefreshRedDot","vipcharge.dlgrecharge")
    end
end

local function hide()

end

local function update()

end

local function destroy()

end

local function show(params)

end

local function UnRead()
    local activityItems = DayChargeManager.GetActivityItems()

    local activityNum = #activityItems
    for i =1, activityNum do
        local activityItem = activityItems[i]
        if activityItem:IsMatchCondition() then
            return true
        end
    end
    return false
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
    name, gameObject, fields = unpack(params)
end


return {
    init = init,
    show = show,
    refresh = refresh,
    update = update,
    hide = hide,
    uishowtype = uishowtype,
    destroy = destroy,
    UnRead = UnRead,
}