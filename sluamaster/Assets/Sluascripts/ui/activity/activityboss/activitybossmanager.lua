local NetWork = require("network")
local ConfigManager = require("cfg.configmanager")
local UIManager = require("uimanager")
local ActivityManager = require("ui.activity.activitytipmanager")

local m_Data
local m_BossStatus = {}
 
local function GetRefreshTimeList(id)
    return m_Data[id].openrange
end

local function GetData()
    for _,info in pairs(m_Data) do
        return info
    end
end

local function OnMsg_SWorldBoss2(msg)
    m_BossStatus[msg.activityid] = msg.openboss
    if UIManager.isshow("activity.activityboss.tabactivityboss") then
        UIManager.refresh("activity.activityboss.tabactivityboss")
    end
    if msg.openboss == 1 then
        ActivityManager.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.ACTIVITYBOSS, nil, function()
            UIManager.showdialog("activity.dlgactivity",{index = 1},4)
        end) 
    end
end

local function GetBossStatus(id)
    return m_BossStatus[id]
end

local function OnMsg_SCloseActivity(msg)
    if m_BossStatus[msg.id] ~= nil then
        m_BossStatus[msg.id] = nil
        if (ActivityManager.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.ACTIVITYBOSS)) then
            ActivityManager.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.ACTIVITYBOSS)
        end
    end
    if UIManager.isshow("activity.activityboss.tabactivityboss") then
        UIManager.refresh("activity.activityboss.tabactivityboss")
    end
end

local function init()
    m_Data = ConfigManager.getConfig("worldboss2")
    NetWork.add_listeners({
        {"lx.gs.activity.worldboss.msg.SWorldBoss2",OnMsg_SWorldBoss2},
        {"lx.gs.activity.msg.SCloseActivity",OnMsg_SCloseActivity},
    })
end

return
{
    init = init,
    GetRefreshTimeList = GetRefreshTimeList,
    GetData = GetData,
    GetBossStatus = GetBossStatus,
}