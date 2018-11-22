local unpack        = unpack
local print 		= print
local UIManager 	= require "uimanager"
local ArenaManager  = require "ui.arena.single.arenamanager"
local EventHelper 	= UIEventListenerHelper
local ArenaData     = ArenaManager.ArenaData
local BonusManager  = require("item.bonusmanager")

local name
local fields
local gameObject
---------------------------------------------------------------


local function RefreshRewards(uiItem,item)
    --printyellow("NM",uiItem,item)
    BonusManager.SetRewardItem(uiItem,item,{ notSetClick = false, notShowAmount = false })
end
local function RefreshRewardList(uiItem,rewardsInfo)
    uiItem:SetText("UILabel_RewardsText",rewardsInfo:TextString())
    local playerInfo = ArenaManager.GetPlayerInfo()
    --fields.UILabel_WinTimes.text = ""
    fields.UILabel_WinTimes.text = tostring(playerInfo.m_SuccessCount)

    local UIList_Items = uiItem.Controls["UIList_Items"]
    local itemNum = #rewardsInfo.m_Items
    
    UIHelper.ResetItemNumberOfUIList(UIList_Items,itemNum)

    for i = 1,itemNum do
        --printyellow("Item ",i,rewardsInfo.m_Items[i])
        --printt(rewardsInfo.m_Items[i])
        local uiItem = UIList_Items:GetItemByIndex(i-1)
        RefreshRewards(uiItem,rewardsInfo.m_Items[i])
    end

    local UILabel_Receive1 = uiItem.Controls["UILabel_Receive"]
    local UILabel_Receive2 = uiItem.Controls["UILabel_Received"]
    local UIButton_Receive = uiItem.Controls["UIButton_Receive"]
    if rewardsInfo.m_IsReceived == false then
        UILabel_Receive1.gameObject:SetActive(true)
        UILabel_Receive2.gameObject:SetActive(false)
    else
        UILabel_Receive1.gameObject:SetActive(false)
        UILabel_Receive2.gameObject:SetActive(true)
    end

    if playerInfo.m_SuccessCount >= rewardsInfo.m_Times and rewardsInfo.m_IsReceived == false then
        UIButton_Receive.isEnabled = true
    else
        UIButton_Receive.isEnabled = false
    end 

    EventHelper.SetClick(UIButton_Receive, function()
        ArenaManager.ObtainDailySuccReward(rewardsInfo.m_Times)
    end)
end



local function refresh(params)
    

    local rewardsListCount = #ArenaData.RewardsList
    
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Rewards,rewardsListCount)
    for i = 1,rewardsListCount do
        local item = fields.UIList_Rewards:GetItemByIndex(i-1)
        local rewardsInfo = ArenaData.RewardsList[i]
        RefreshRewardList(item,rewardsInfo)
    end
end

local function destroy()

end

local function show(params)

end

local function hide()

end

local function update()

end

local function init(params)
    name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_CloseRewards, function()
        UIManager.hide(name)
	end)
    gameObject.transform.position = Vector3(0,0,-500)
end
return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
