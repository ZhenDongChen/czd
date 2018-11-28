local OperationActivityManager  = require("ui.operationactivity.operationactivitymanager")
local UIManager                 = require("uimanager")
local BonusManager              = require("item.bonusmanager")
local EventHelper               = UIEventListenerHelper
local ColorUtil                 = require("common.colorutil")


local name, gameObject, fields
local currentGroupId

--==================================================================================================
local function ShowRewards(rewardsList ,activityItem)
    local fullItems = activityItem:GetRewards()
    local rewards = {}
    for i, item in ipairs(fullItems) do
        if i <= 4 then
            table.insert( rewards, item )
        end
    end

    UIHelper.ResetItemNumberOfUIList(rewardsList, #rewards)
    for i, reward in ipairs(rewards) do
        local subUiItem = rewardsList:GetItemByIndex(i-1)
        BonusManager.SetRewardItem(subUiItem, reward)
    end
end

local function ShowButton(uiButton, uiLabel, activityGroup, activityItem)
    if activityItem:IsMatchCondition() then
        uiButton.isEnabled = true
        EventHelper.SetClick(uiButton, function()
            OperationActivityManager.ReceiveActivityBonus(activityGroup:GetId(), activityItem:GetId())
        end)
    else
        uiButton.isEnabled = false
        EventHelper.SetClick(uiButton, function()

        end)
    end
    if activityItem:IsFinish() then
        uiLabel.text = activityGroup:GetFinishedLabel()
    else
        uiLabel.text = activityGroup:GetUnFinishLabel()
    end
end


--==================================================================================================
local function SetActivity_Collection(uiItem, activityGroup, activityItem)
    local condition = activityItem:GetCondition()
    local items = condition:GetCollectionItems()

    local collectionList = uiItem.Controls["UIList_CollectionItem"]
    local itemNum = #items
    UIHelper.ResetItemNumberOfUIList(collectionList, itemNum)
    --if true then return end
    for i, item in ipairs(items) do
        local subUiItem = collectionList:GetItemByIndex(i-1)
        local spriteAdd = subUiItem.Controls["UISprite_Add"]
        local textureIcon = subUiItem.Controls["UITexture_Icon"]
        local labelNumber = subUiItem.Controls["UILabel_Amount"]
        if condition:ExistItem(item) then
            BonusManager.SetRewardItem(subUiItem, item, {showRedMask = false})
            if labelNumber then
                local num1,num2 = condition:GetItemNumber(item)
                labelNumber.text = string.format( "%d/%d", num1, num2)
                --ColorUtil.SetLabelColorText(labelNumber,ColorUtil.ColorType.Green_Remind, string.format( "%d/%d", num1, num2))
            end
        else
            BonusManager.SetRewardItem(subUiItem, item, {showRedMask = false, setGray = true})
            if labelNumber then
                local num1,num2 = condition:GetItemNumber(item)
                labelNumber.text = string.format( "%d/%d", num1, num2)
                --ColorUtil.SetLabelColorText(labelNumber,ColorUtil.ColorType.Green_Remind, string.format( "%d/%d", num1, num2))
            end
        end
        if i == itemNum then
            spriteAdd.gameObject:SetActive(false)
        else
            spriteAdd.gameObject:SetActive(true)
        end
    end

    uiItem:SetText("UILabel_CollectionTimes", condition:GetDayTimes())
    uiItem:SetText("UILabel_AllCollectionTimes", condition:GetAllTimes())

    ShowRewards(uiItem.Controls["UIList_CollectionRewards"], activityItem)
    ShowButton(uiItem.Controls["UIButton_CollectionExchange"], uiItem.Controls["UILabel_CollectionExchangeLabel"], activityGroup, activityItem)
end

--==================================================================================================
local function SetActive_Upgrade(uiItem, activityGroup, activityItem)
    local condition = activityItem:GetCondition()

    uiItem:SetText("UILabel_Level", condition:GetConditionText())
    uiItem:SetText("UILabel_Level01", condition:GetConditionText2())

    ShowRewards(uiItem.Controls["UIList_UpgradeRewards"], activityItem)
    ShowButton(uiItem.Controls["UIButton_UpgradeReceive"], uiItem.Controls["UILabel_UpgradeReceive"], activityGroup, activityItem)
end

--==================================================================================================
local function SetActive_GiftBag(uiItem, activityGroup, activityItem)
    local condition = activityItem:GetCondition()

    uiItem:SetText("UILabel_Introduction01",condition:GetConditionText())
    --uiItem:SetText("", condition:GetConditionText2())
    --local aa = condition:GetDayTimes()
    local uiLabelLimit1 = uiItem.Controls["UILabel_Introduction02"]
    local uiLabelLimit2 = uiItem.Controls["UILabel_Introduction03"]
    if condition:ShowDayLimit() then
        if uiLabelLimit1 then
            uiLabelLimit1.gameObject:SetActive(true)
        end
        uiItem:SetText("UILabel_GiftBagDayLimit", condition:GetDayTimes())
    else
        if uiLabelLimit1 then
            uiLabelLimit1.gameObject:SetActive(false)
        end
    end
    if condition:ShowTotalLimit() then
        if uiLabelLimit2 then
            uiLabelLimit2.gameObject:SetActive(true)
        end
        uiItem:SetText("UILabel_GiftBagTotalLimit", condition:GetTotalTimes())
    else
        if uiLabelLimit2 then
            uiLabelLimit2.gameObject:SetActive(false)
        end
    end

    local uiVipGroup = uiItem.Controls["UILabel_VIPLimit"]
    local uiVipLabel = uiItem.Controls["UILabel_VIPLimitNum"]
    if uiVipGroup and uiVipLabel then
        local vipLimitLv = condition:GetVipLimit()
        if vipLimitLv and vipLimitLv > 0 and shouldHideVip() ~= true then
            uiVipGroup.gameObject:SetActive(true)
            uiVipLabel.text = tostring(vipLimitLv)
        else
            uiVipGroup.gameObject:SetActive(false)
        end
    end


    local originalPriceSprite = uiItem.Controls["UISprite_OrigSprite"]
    local currentPriceSprite = uiItem.Controls["UISprite_PresSprite"]
    --originalPriceSprite.spriteName = condition:GetSpriteName()
    --currentPriceSprite.spriteName = condition:GetSpriteName()
    uiItem:SetText("UILabel_OrigPrice01", "[s]" .. tostring(condition:GetOriginalPrice()) .. "[/s]")
    uiItem:SetText("UILabel_PresPrice02", condition:GetCurrentPrice())

    ShowRewards(uiItem.Controls["UIList_GiftBag"], activityItem)
    ShowButton(uiItem.Controls["UIButton_Buy"], uiItem.Controls["UILabel_Buy"], activityGroup, activityItem)
end

--==================================================================================================
local function SetActive_ChargeRewards(uiItem, activityGroup, activityItem)
    local condition = activityItem:GetCondition()

    uiItem:SetText("UILabel_Name", activityItem:GetItemName())
    uiItem:SetText("UILabel_Discription", activityItem:GetItemDiscription())
    local sprite = uiItem.Controls["UISprite_IntegralIcon"]
    --sprite.spriteName = condition:GetSpriteName()
    uiItem:SetText("UILabel_Integral", condition:GetCurrencyCount())

    local dayLimit = condition:GetDayTimes()
    local totalLimit = condition:GetAllTimes()
    uiItem:SetText("UILabel_Times", tostring(dayLimit))
    uiItem:SetText("UILabel_AllTimes", tostring(totalLimit))
    local uiLabelAll = uiItem.Controls["UILabel_AllExchange"]
    uiLabelAll.gameObject:SetActive(false)
    ShowRewards(uiItem.Controls["UIList_ChargeItems"], activityItem)
    ShowButton(uiItem.Controls["UIButton_Exchange"], uiItem.Controls["UILabel_ChargeExchange"], activityGroup, activityItem)
end

--==================================================================================================
local function SetActive_UpgradeParams(uiItem, activityGroup, activityItem)
    local condition = activityItem:GetCondition()

    uiItem:SetText("UILabel_ParamsLevel", condition:GetConditionText())
    uiItem:SetText("UILabel_ParamsLevel01", condition:GetConditionText2())

    ShowRewards(uiItem.Controls["UIList_UpgradeParamsRewards"], activityItem)
    ShowButton(uiItem.Controls["UIButton_UpgradeParamsReceive"], uiItem.Controls["UILabel_UpgradeParamsReceive"], activityGroup, activityItem)
end
--==================================================================================================
local ItemShowFunction = {
    ["upgrade"]         = SetActive_Upgrade,
    ["collection"]      = SetActivity_Collection,
    ["chargereward"]    = SetActive_ChargeRewards,
    ["giftbag"]         = SetActive_GiftBag,
    ["upgradeparams"]   = SetActive_UpgradeParams,
}

--==================================================================================================
local function SetGroupItem(uiItem, currnetGroup, activityItem)
    local groups = {}
    groups["upgrade"]      = uiItem.Controls["UIGroup_Upgrade"]
    groups["collection"]   = uiItem.Controls["UIGroup_Collection"]
    groups["chargereward"] = uiItem.Controls["UIGroup_ChargeReward"]
    groups["giftbag"]      = uiItem.Controls["UIGroup_GiftBag"]
    groups["upgradeparams"]      = uiItem.Controls["UIGroup_UpgradeParams"]
    local showGroupName = activityItem:GetShowGroup()
    for key, group in pairs(groups) do
        if key == showGroupName then
            group.gameObject:SetActive(true)
        else
            group.gameObject:SetActive(false)
        end
    end
    local itemShowFunc = ItemShowFunction[showGroupName]
    if itemShowFunc then
        itemShowFunc(uiItem, currnetGroup, activityItem)
    end
end

local function SetGroupHead(group)
    fields.UILabel_ActivityName.text = group:GetTitle()

    fields.UILabel_Time.gameObject:SetActive(group:IsShowTime())

    fields.UILabel_Time01.text = group:GetStartTimeStr()
    fields.UILabel_Time02.text = group:GetEndTimeStr()
    fields.UILabel_ActicityContent.text = group:GetContent()
    local currencyName = group:GetCurrencyName()
    if currencyName == nil or currencyName == "" then
        fields.UIGroup_MyIntegral.gameObject:SetActive(false)
    else
        fields.UIGroup_MyIntegral.gameObject:SetActive(true)
        fields.UILabel_MyIntegralName.text = currencyName
        fields.UILabel_MyIntegral.text = tostring(group:GetCurrencyCount())
    end

    fields.UITexture_ActivityBg:SetIconTexture(group:GetTexture())
end

local function SetGroupTab(uiItem, group)
    local uiLabel = uiItem.Controls["UILabel_ActivityTypeName"]
    local uiSprite = uiItem.Controls["UISprite_Warning"]
    local uiSprite2 = uiItem.Controls["UISprite_Status"]
    uiLabel.text = group:GetTitle()
    uiSprite.gameObject:SetActive(group:UnRead())
    uiSprite2.gameObject:SetActive(group:AllComplete())

end

local function SortFunc(itemA, itemB)
    if itemA:IsComplete() == true and itemB:IsComplete() == false then
        return true
    end
    if itemA:IsComplete() == false and itemB:IsComplete() == true then
        return false
    end
    if itemA:IsFinish() == false and itemB:IsFinish() == true then
        return true
    end
    if itemA:IsFinish() == true and itemB:IsFinish() == false then
        return false
    end
    if itemA:GetId() < itemB:GetId() then
        return true
    end
    return false
end

local function GroupSortFunc(groupA,groupB)
    if groupA:GetDisplayOrder() < groupB:GetDisplayOrder() then
        return true
    end
    return false
end

local function refresh(params)
    local groupList = OperationActivityManager.GetActivityGroupList()
    local groups = {}
    for i, group in ipairs(groupList) do
        if group:IsShow() == true then
            table.insert( groups, groupList[i] )
        end
    end

    table.sort( groups, GroupSortFunc )
    if #groups <= 0 then
        fields.UIGroup_GiftBagBG.gameObject:SetActive(false)
        fields.UIGroup_GiftBagBGEmpty.gameObject:SetActive(true)
    else
        fields.UIGroup_GiftBagBG.gameObject:SetActive(true)
        fields.UIGroup_GiftBagBGEmpty.gameObject:SetActive(false)
    end
    UIHelper.ResetItemNumberOfUIList(fields.UIList_ActivityTab, #groups)

    if params and type(params) == "table" and params.tabindex2 and groups[params.tabindex2] then
        local currentSelectIndex = fields.UIList_ActivityTab:GetSelectedIndex()
        fields.UIList_ActivityTab:SetUnSelectedIndex(currentSelectIndex)
        fields.UIList_ActivityTab:SetSelectedIndex(params.tabindex2-1,false)
        currentGroupId = groups[params.tabindex2]:GetId()
    elseif currentGroupId == nil and groups[1] then
        currentGroupId = groups[1]:GetId()
    end

    for i = 1, #groups do
        local uiItem = fields.UIList_ActivityTab:GetItemByIndex(i-1)
        local group = groups[i]
        uiItem.Id = group:GetId()
        SetGroupTab(uiItem, group)
    end



    if currentGroupId ~= nil then
        local currnetGroup = OperationActivityManager.GetActivityGroup(currentGroupId)
        if currnetGroup ~= nil then

            SetGroupHead(currnetGroup)
            local activityItems = currnetGroup:GetActivityItems()

            local newList = {}
            for i, value in pairs(activityItems) do
                newList[i] = value
            end

            UIHelper.ResetItemNumberOfUIList(fields.UIList_ActivityRewards, #newList)
        --  currnetGroup:Sort(newList)
            if currnetGroup:IsNeedSort() then
                utils.table_sort( newList, SortFunc )
            end

           for i = 1, #newList do
               local uiItem = fields.UIList_ActivityRewards:GetItemByIndex(i-1)
               local activityItem = newList[i]
               SetGroupItem(uiItem, currnetGroup, activityItem)
           end

        end
    end
end
local defaultGroupId = nil

local function show(params)
    if params and type(params) == "table" and params.tabindex2 then
        defaultGroupId = params.tabindex2
    end
    EventHelper.SetListSelect(fields.UIList_ActivityTab, function(uiItem)
        if defaultGroupId then
            currentGroupId = defaultGroupId
            defaultGroupId = nil
            fields.UIList_ActivityRewards:Clear()
            UIManager.refresh(name,params)
        else
            currentGroupId = uiItem.Id
            local group = OperationActivityManager.GetActivityGroup(currentGroupId)
            if group and group:NeedMsgParams() then
                OperationActivityManager.GetActivityParams(group:GetId())
            end
            fields.UIList_ActivityRewards:Clear()
            UIManager.refresh(name)
        end

    end)

    OperationActivityManager.GetAllActivityParams()
end

local function init(params)
    name, gameObject, fields    = unpack(params)
end
local function update()

end

local function destroy()

end

local function hide()

end
local function UnRead()
    return OperationActivityManager.UnRead()
end
return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    refresh = refresh,
    destroy = destroy,
    UnRead = UnRead,
}
