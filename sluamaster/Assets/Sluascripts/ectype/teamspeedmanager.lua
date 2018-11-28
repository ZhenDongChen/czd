local ConfigManager     = require("cfg.configmanager")
local LimitManager
local uimanager 	    = require "uimanager"
local network           = require"network"
local EctypeManager
local CheckCmd          = require"common.checkcmd"
local TimeUtils         = require"common.timeutils"
local serverTime
local currFloorId
local ConfigSpeed
local bActive
local bSigned
local signCountDown
local ActivityManager
local canEnter
-- local ConfigSpeed       = ConfigManager.getConfig("teamspeed")

local function OnSigned(b)
    bSigned = b
    if uimanager.isshow"arena.multi.speed.tabarenamultispeed" then
        uimanager.refresh("arena.multi.speed.tabarenamultispeed")
    end
end

local function IsSigned()
    return bSigned
end

local function GoToTeamSpeed()
    uimanager.showdialog("activity.dlgactivity",{tabindex2=2},2)
end

local function IsInActive()
    local serverDayTime = serverTime % (24*60*60)
    for i,timeinfo in ipairs(ConfigSpeed.timeinfo) do
        local beginTime     = timeinfo.begintime
        local endTime       = timeinfo.endtime
        local beginSeconds = TimeUtils.getSeconds({days=0,hours=beginTime.hour,minutes=beginTime.minute,seconds=beginTime.second})
        local endSeconds = TimeUtils.getSeconds({days=0,hours=endTime.hour,minutes=endTime.minute,seconds=endTime.second})
        if serverDayTime<endSeconds and serverDayTime >= beginSeconds then return i end
    end
    return nil
end


local function CheckFloorId()
    currFloorId = nil
    for id,v in pairs(ConfigSpeed.lvmsg) do
        local val,info = CheckCmd.CheckData({data=v.lv})
        if val then
            currFloorId = id
            break
        end
    end
end

local function IsOpen()
    return currFloorId
end

local function CheckEnterTime()
    return ConfigSpeed.dailylimit.entertimes[PlayerRole.Instance().m_VipLevel+1] > LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.TEAM_SPEED,0)
end

local function ChangeState(type,timeinfoIndex)
    if currState == type then return end
    if type == cfg.dailyactivity.ActivityTipEnum.HongMengZhengBa_Enroll then
        if ActivityManager.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.HongMengZhengBa_Countdown) then
            ActivityManager.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.HongMengZhengBa_Countdown)
        end
        ActivityManager.RegisterActivity(type, nil, GoToTeamSpeed)
    else
        if ActivityManager.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.HongMengZhengBa_Enroll) then
            ActivityManager.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.HongMengZhengBa_Enroll)
        end
    end
    currState = type
end

local function second_update()
        serverTime  = TimeUtils.GetServerTime() + 8*3600
        if PlayerRole.Instance() and PlayerRole.Instance().m_Object then
            CheckFloorId()
            if IsOpen() then
                local timeinfoIndex = IsInActive()
                if timeinfoIndex then
                    if CheckEnterTime() then
                        ChangeState(cfg.dailyactivity.ActivityTipEnum.HongMengZhengBa_Enroll)
                    else
                        ChangeState(nil)
                    end
                else
                    ChangeState(nil)
                end
            else
                ChangeState(nil)
            end
        end
end

local function Init()
    currFloorId = nil
    bActive     = false
    bSigned     = false
    signCountDown = nil
    canEnter    = false
    currState   = nil
    -- EctypeManager = require"ectype.ectypemanager"
    LimitManager      = require"limittimemanager"
    ConfigSpeed = ConfigManager.getConfig("teamspeed")
    ActivityManager = require"ui.activity.activitytipmanager"
    gameevent.evt_limitchange:add(OnLimitChange)
end

return {
    Init = Init,
    second_update = second_update,
    ChangeSignedState = ChangeSignedState,
    OnSigned = OnSigned,
    IsSigned = IsSigned,
}
