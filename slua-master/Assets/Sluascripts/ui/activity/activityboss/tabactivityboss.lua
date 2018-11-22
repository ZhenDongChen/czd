local EventHelper = UIEventListenerHelper
local Unpack = unpack
local Format = string.format
local ItemManager = require("item.itemmanager")
local BonusManager = require("item.bonusmanager")
local ActivityBossManager = require("ui.activity.activityboss.activitybossmanager")
local PlayerRole = require("character.playerrole"):Instance()
local UIManager = require("uimanager")

local m_Fields
local m_Name
local m_GameObject

local function destroy()
end

local function DisplayBonus(rewards)
    m_Fields.UIList_Rewards:Clear()
    for _,id in pairs(rewards.items) do
        local item=ItemManager.CreateItemBaseById(id)
        local rewardItem=m_Fields.UIList_Rewards:AddListItem()
        BonusManager.SetRewardItem(rewardItem,item)       
    end
end

local function DisplayRefreshTime(openTimes)
    local openTimeText = ""
    for _,timeInfo in pairs(openTimes) do
        if openTimeText~="" then
            openTimeText=openTimeText.."/"..(timeInfo.hour)..":"..(Format("%02d",timeInfo.minute))
        else
            openTimeText=(timeInfo.hour)..":"..(Format("%02d",timeInfo.minute))
        end
    end
    m_Fields.UILabel_OpenTime.text=openTimeText
end

local function show()  
end

local function hide()
end

local function update()
end

local function refresh()
    local activityBossData = ActivityBossManager.GetData()
    m_Fields.UITexture_ActivityBG:SetIconTexture(activityBossData.backgroundpic)   --背景图
    m_Fields.UILabel_RegisterTime.text = activityBossData.description  --活动描述
    DisplayRefreshTime(activityBossData.opentimes)
    DisplayBonus(activityBossData.showbonusitems)   --显示奖励
    local status = ActivityBossManager.GetBossStatus(activityBossData.id)
    if status == 1 then
        m_Fields.UIButton_RegisterOrJoinIn.isEnabled = true
        EventHelper.SetClick(m_Fields.UIButton_RegisterOrJoinIn,function()          
            PlayerRole:navigateTo({targetPos=Vector3(activityBossData.position.x,0,activityBossData.position.y),mapId=activityBossData.worldmapid})
            UIManager.hidedialog("activity.dlgactivity")
        end)
    else
        m_Fields.UIButton_RegisterOrJoinIn.isEnabled = false
    end
end

local function init(params)
    m_Name,m_GameObject,m_Fields = Unpack(params)
end

local function uishowtype()
    return UIShowType.Refresh
end

return
{
    init = init,
    hide = hide,
    show = show,
    refresh = refresh,
    update = update,
    destroy = destroy,
    uishowtype = uishowtype,
}