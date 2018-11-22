local unpack            = unpack
local print             = print
local UIManager         = require("uimanager")
local FriendManager     = require("ui.friend.friendmanager")
local EventHelper       = UIEventListenerHelper
local ItemIntroduction  = require("item.itemintroduction")
local BonusManager      = require("item.bonusmanager")
------------------------------------------------------------------------------------------------------
local name,gameObject,fields
local CurrentIdolIndex = 1


local function RefreshRewards(uiItem,reward,idol,trueIndex )
    uiItem:SetText("UILabel_FavorDegree","" .. reward.m_FriendDgree .. LocalString.IdolRewards[1])
    local itemNum = #reward.Items
    local UIList_Rewards = uiItem.Controls["UIList_Rewards"]
    UIHelper.ResetItemNumberOfUIList(UIList_Rewards,itemNum)
    for i = 1, itemNum do
        local uiItem = UIList_Rewards:GetItemByIndex(i-1)
        BonusManager.SetRewardItem(uiItem,reward.Items[i],{notShowAmount = false})
    end

    local labelDescription =  uiItem.Controls["UILabel_Description"]
    labelDescription.text = reward.m_Introduction or ""

    local button = uiItem.Controls["UIButton_Receive01"]
    if idol.m_FriendDegree >= reward.m_FriendDgree then
        if reward.m_Received then
            button.isEnabled = false
            uiItem:SetText("UILabel_Receive",LocalString.IdolRewards[2])
            EventHelper.SetClick(button, function()

            end)
        else
            button.isEnabled = true
            uiItem:SetText("UILabel_Receive",LocalString.IdolRewards[3])
            EventHelper.SetClick(button, function()
                FriendManager.ClaimIdolAward(idol:GetId(),trueIndex)
            end)
        end
    else
        uiItem:SetText("UILabel_Receive",LocalString.IdolRewards[3])
        button.isEnabled = false
        EventHelper.SetClick(button, function()

        end)
    end
end



local function RefreshIdolBonusList(idol)
    local rewardsNum = #idol.m_BonusList
    local wrapList = fields.UIList_RewardsBag.gameObject:GetComponent("UIWrapContentList")
    EventHelper.SetWrapListRefresh(wrapList,function(uiItem, index, realIndex)
        RefreshRewards(uiItem,idol.m_BonusList[realIndex],idol,realIndex)
    end)
    wrapList:SetDataCount(rewardsNum)
    wrapList:CenterOnIndex(0)

end

local function refresh(params)
    if CurrentIdolIndex <=0 or CurrentIdolIndex> FriendManager.FriendsInfo.idolList:GetCount() then
        return
    end
    local idol = FriendManager.FriendsInfo.idolList:GetByIndex(CurrentIdolIndex)
    RefreshIdolBonusList(idol)
end

local function destroy()

end

local function show(params)
    local idolNum = FriendManager.FriendsInfo.idolList:GetCount()  
    UIHelper.ResetItemNumberOfUIList(fields.UIList_IdolTab,idolNum)
    fields.UIList_IdolTab:SetSelectedIndex(0)
    CurrentIdolIndex = 1
    for i, idol in ipairs(FriendManager.FriendsInfo.idolList:GetList()) do

        local item = fields.UIList_IdolTab:GetItemByIndex(i-1)
        item:SetText("UILabel_WelfareTypeName",idol.m_Name)
        local toggle = item.gameObject:GetComponent("UIToggle")
        local redDot = item.Controls["UISprite_Warning"]
        if redDot then
            if idol:ShowRedDot() then
                redDot.gameObject:SetActive(true)
            else
                redDot.gameObject:SetActive(false)
            end
        end
        EventHelper.SetClick(toggle,function()
            CurrentIdolIndex = i

            UIManager.refresh("friend.dlgidolrewards")
        end)
    end
end

local function hide()

end

local function update()


end

local function init(params)

   	name, gameObject, fields = unpack(params)

	EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide("friend.dlgidolrewards")
    end)

end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
}
