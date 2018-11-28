local springfestivalmanager = require"ui.activity.springfestival.springfestivalmanager"
local BonusManager = require("item.bonusmanager")
local UIManager = require("uimanager")
local EventHelper               = UIEventListenerHelper

local name, gameObject, fields



local function SetActivityItem(uiItem, activityItem)
    uiItem:SetText("UILabel_Level", LocalString.JDKARDNAME)
    uiItem:SetText("UILabel_Level01", LocalString.JDKARDVALUE)
    if activityItem then
        uiItem:SetText("UILabel_Account", LocalString.JDACCOUNT .. activityItem.id)
        uiItem:SetText("UILabel_Password", LocalString.JDPASSWARD .. activityItem.passwd)
    else
        uiItem:SetText("UILabel_Account", LocalString.JDACCOUNT_NOT)
        uiItem:SetText("UILabel_Password", LocalString.JDPASSWARD_NOT)
    end
end

local function refresh(params)
    local KardsDataList = springfestivalmanager.getKardsDataList()
    if KardsDataList == nil then
        KardsDataList = {}
    end

    local activityNum = #KardsDataList
    if activityNum > 0 then
        UIHelper.ResetItemNumberOfUIList(fields.UIList_ActivityRewards, activityNum)
        for i =1, activityNum do
            local uiItem = fields.UIList_ActivityRewards:GetItemByIndex(i-1)
            local activityItem = KardsDataList[i]
            SetActivityItem(uiItem, activityItem)
        end
    else
        UIHelper.ResetItemNumberOfUIList(fields.UIList_ActivityRewards, 1)
        local uiItem = fields.UIList_ActivityRewards:GetItemByIndex(0)
        SetActivityItem(uiItem)
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