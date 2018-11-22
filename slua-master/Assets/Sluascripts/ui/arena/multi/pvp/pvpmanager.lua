--local PVPSync       = require("ui.arena.multi.pvp.pvpsync")
local UIManager     = require("uimanager")
local ConfigManager = require("cfg.configmanager")
local Network       = require("network")
local RoleInfo      = require("ui.arena.multi.pvp.roleinfo")
local ErrrorManager = require("assistant.errormanager")
local ActivityTipManager = require("ui.activity.activitytipmanager")
local GameEvent     = require("gameevent")

local TeamFightData = {
    m_IsMatching            = false,
    m_MatchEnable           = true,
    m_NextMatchTime         = 0,

    m_WeekScore             = 0,
    m_TodayWinNumber        = 0,
    m_ObtainTodayWinReward  = false,
    m_TodayFightNumber      = 0,
    m_ObtainScoreRewards    = {},
    
    m_ConfigData            = nil,
    
    m_DayWinTimes           = 1,
    
    m_DayBonus              = nil,
    m_ScoreBonus            = {},
    
    m_WeekScoreMax          = 1,

    m_FirstRedDot           = true,

    m_IsRegistTip           = false,
}

--==========================================================================================================
local function IsMatching()
    return TeamFightData.m_IsMatching
end

local function GetMatchEnable()
    return TeamFightData.m_NextMatchTime <= timeutils.GetServerTime()
end
--[[
    .value = FCondition.checkA(roleid, CfgMgr.teamfight.extrabonustimes, 1, By.Team_Fight_Result, Const.NULL, CmdId.TEAM_FIGHT_BONUS).ok());
]]
local function GetMaxExtraBonusTimes()
    if TeamFightData.m_ConfigData and TeamFightData.m_ConfigData.extrabonustimes then
     --   printyellow("============================ 1")
        return TeamFightData.m_ConfigData.extrabonustimes.num
    end
  --  printyellow("============================ 2")
  --  printyellow(TeamFightData.m_ConfigData)
  --  printyellow(TeamFightData.m_ConfigData.extrabonustimes)
    return 0
end

local function GetMatchTime()
    return TeamFightData.m_NextMatchTime - timeutils.GetServerTime()
end

local function ShowFirstRedDot()
    return TeamFightData.m_FirstRedDot
end

local function SetFirstRedDot(value)
    TeamFightData.m_FirstRedDot = value
end

local function GetWinTimes()
    return TeamFightData.m_TodayWinNumber, TeamFightData.m_DayWinTimes
end

local function GetScore()
    return TeamFightData.m_WeekScore, TeamFightData.m_WeekScoreMax
end

local function GetScoreBonus()
    return TeamFightData.m_ScoreBonus
end

local function GetDayBonus()
    return TeamFightData.m_DayBonus
end

local function SetUIMainMatchingIcon(isshow)
    local uiMain = require("ui.dlguimain")
   -- uiMain.SetMatching({matching = isshow, matchmode = "teamfight"})
end

local function GetLevelRegion()
    local lowerLevel = 1
    local higherLevel = 10
    if TeamFightData.m_ConfigData == nil then
        local level = PlayerRole:Instance().m_Level
        local levelRegion = math.floor((level - 1)/10) * 10
        lowerLevel = levelRegion + 1
        higherLevel = levelRegion + 10
    else
        for i, levelgroup in pairs(TeamFightData.m_ConfigData.levelgroups) do
            if PlayerRole:Instance().m_Level >= levelgroup.level then
                lowerLevel = levelgroup.level
            end
            if PlayerRole:Instance().m_Level < levelgroup.level then
                higherLevel = levelgroup.level
                break
            end
        end
        local highestLevelGroup = TeamFightData.m_ConfigData.levelgroups[#TeamFightData.m_ConfigData.levelgroups]
        
        if PlayerRole:Instance().m_Level >= highestLevelGroup.level then
            lowerLevel = highestLevelGroup.level
            higherLevel = nil
        end
    end
    return lowerLevel, higherLevel
end

local function IsDayBonusReceive()
    return TeamFightData.m_ObtainTodayWinReward
end

local function IsWeekBonusReceive(num)
    return TeamFightData.m_ObtainScoreRewards[num]
end


local function RefreshUI()
    if UIManager.isshow("arena.multi.pvp.tabarenamultipvp") then
        UIManager.refresh("arena.multi.pvp.tabarenamultipvp")
    end
end

--==========================================================================================================
--基本信息更新
local function SetMatchInfo(matchtype, nextmatchtime)
    if matchtype == cfg.ectype.MatchType.TEAM_FIGHT then
        TeamFightData.m_IsMatching = true
    else
        TeamFightData.m_IsMatching = false
    end
    TeamFightData.m_NextMatchTime = nextmatchtime
    if nextmatchtime <= timeutils.GetServerTime() then
        TeamFightData.m_MatchEnable = true
    else
        TeamFightData.m_MatchEnable = false
    end
end

local function SetTeamFightData(msgData)
    if msgData == nil then
        return
    end
    
    TeamFightData.m_WeekScore = msgData.weekscore
    TeamFightData.m_TodayWinNumber = msgData.todaywinnum
    TeamFightData.m_ObtainTodayWinReward = (msgData.obtaintodaywinreward == 1) and true or false
    TeamFightData.m_TodayFightNumber = msgData.todayfightnum
    
    TeamFightData.m_ObtainScoreRewards = {}
    for i, key in pairs(msgData.obtainscorerewards) do
        TeamFightData.m_ObtainScoreRewards[key+1] = true
    end
        
end




local function OnMsgSEctypeInfo(msg)
    printyellowmodule(Local.LogModuals.TeamFight ,msg)
    SetTeamFightData(msg.teamfight)
    SetMatchInfo(msg.matchtype, msg.nextmatchtime/1000)
    RefreshUI()
end

local function OnMsgSChangeTeamFight(msg)
    printyellowmodule(Local.LogModuals.TeamFight, msg)
    SetTeamFightData(msg.info)
    RefreshUI()
end

local function OnMsgSChangeMatch(msg)
    printyellowmodule(Local.LogModuals.TeamFight, msg)
    SetMatchInfo(msg.matchtype, msg.nextmatchtime/1000)
    RefreshUI()
end

local function LoadConfigData()
    TeamFightData.m_ConfigData = ConfigManager.getConfig("teamfight")
    if TeamFightData.m_ConfigData ~= nil then
        TeamFightData.m_DayWinTimes = TeamFightData.m_ConfigData.dailywintimes
        TeamFightData.m_DayBonus = TeamFightData.m_ConfigData.dailywinbonus
        TeamFightData.m_ScoreBonus = TeamFightData.m_ConfigData.weekscorebonus
        TeamFightData.m_WeekScoreMax = TeamFightData.m_ScoreBonus[#TeamFightData.m_ScoreBonus].grade
    end
    
end

--==========================================================================================================
--开始匹配

local function BeginMatchTeamFight()
    printyellowmodule(Local.LogModuals.TeamFight ,"Start Matching ...")
    local re = lx.gs.map.msg.CBeginMatchTeamFight({}) 
    Network.send(re)
end

local function OnMsgSBeginMatchTeamFight(msg)
    printyellowmodule(Local.LogModuals.TeamFight ,msg)
    if msg.errcode and msg.errcode == 0 then
        TeamFightData.m_IsMatching = true
        SetUIMainMatchingIcon(true)
        UIManager.ShowSingleAlertDlg({content = LocalString.TeamFight.SuccessMatching})
    else
        if msg.errcode then
            ErrrorManager.ShowError(msg.errcode)
        end
        SetUIMainMatchingIcon(false)
        TeamFightData.m_IsMatching = false
    end
    RefreshUI()
   
end

--==========================================================================================================
--取消匹配
local function CancelMatchTeamFight()
    printyellowmodule(Local.LogModuals.TeamFight ,"Cancel Matching !")
    local re = lx.gs.map.msg.CCancelMatchTeamFight({})
    Network.send(re)
end

local function OnMsgSCancelMatchTeamFight(msg)
    printyellowmodule(Local.LogModuals.TeamFight ,msg)
    TeamFightData.m_IsMatching = false
    RefreshUI()
    SetUIMainMatchingIcon(false)
end

--==========================================================================================================
--领取日奖励

local function ObtainTeamFightDayReward()
    printyellowmodule(Local.LogModuals.TeamFight ,"Obtain TeamFight Day Reward.")
    local re = lx.gs.map.msg.CObtainTeamFightDayReward({})
    Network.send(re)
end
local function OnMsgSObtainTeamFightDayReward(msg)
    printyellowmodule(Local.LogModuals.TeamFight ,msg)
    TeamFightData.m_ObtainTodayWinReward = true
    RefreshUI()
end

--==========================================================================================================
--领取积分奖励

local function ObtainTeamFightWeekReward(rewardId)
    printyellowmodule(Local.LogModuals.TeamFight, "Obtain TeamFight WeekReward:" .. tostring(rewardId))
    local re = lx.gs.map.msg.CObtainTeamFightWeekReward({rewardid = (rewardId-1)})
    Network.send(re)
end
local function OnMsgSObtainTeamFightWeekReward(msg)
    printyellowmodule(Local.LogModuals.TeamFight ,msg)
    TeamFightData.m_ObtainScoreRewards[msg.rewardid+1] = true
    RefreshUI()
end

--==========================================================================================================
--匹配成功
local function OnMsgSMatchTeamFightSucc(msg)
    printyellowmodule(Local.LogModuals.TeamFight ,msg)
    
    TeamFightData.m_IsMatching = false
    
    local friendlyRoleList = {}
    local enemyRoleList = {}
    
    for i, msgRoleInfo in pairs(msg.team1.members) do
        table.insert( friendlyRoleList, RoleInfo:new(msgRoleInfo) )
    end
    
    for i, msgRoleInfo in pairs(msg.team2.members) do
        table.insert( enemyRoleList, RoleInfo:new(msgRoleInfo) )    
    end
    
    UIManager.showdialog("arena.multi.pvp.dlgarenamultipvpmatching", 
                        {friendlyList   = friendlyRoleList, 
                         enemyList      = enemyRoleList, 
                         remainingTime  = msg.countdown})
    
    local dlgUIMain = require("ui.dlguimain")
    dlgUIMain.SetMatching({matching = false, matchmode="teamfight"})
end


local function IsInTimeRange()
    local isInTime = false

    local teamfightCfg = ConfigManager.getConfig("teamfight")
    local curTime = timeutils.GetServerTime()
    local curData = os.date("*t", curTime)
    for i, opentime in ipairs(teamfightCfg.opentimes) do
        local begintime = os.time({ 
                            year    = curData.year, 
                            month   = curData.month, 
                            day     = curData.day, 
                            hour    = opentime.begintime.hour, 
                            min     = opentime.begintime.minute, 
                            sec     = opentime.begintime.second,
                        })
        local endtime = os.time({
                            year    = curData.year, 
                            month   = curData.month, 
                            day     = curData.day, 
                            hour    = opentime.endtime.hour, 
                            min     = opentime.endtime.minute, 
                            sec     = opentime.endtime.second,
                        })
        if curTime > begintime and curTime < endtime then
            isInTime = true
        end
    end
    return isInTime
end

local function ReachDayWinBonusTime()
    local winTimes, totalTimes = GetWinTimes()
    --local isReceived = IsDayBonusReceive()
    local canReceive = (winTimes >= totalTimes)
    
    return canReceive
end


local function second_update()
    if PlayerRole:Instance().m_RealLevel == nil then
        return
    end
    if TeamFightData.m_IsRegistTip == false then
        if IsInTimeRange() and not IsDayBonusReceive() then
            local teamfightCfg = ConfigManager.getConfig("teamfight")
            local matchLevel = false
            if teamfightCfg and PlayerRole:Instance().m_RealLevel >= teamfightCfg.levellimit then
                matchLevel = true
            end
            if matchLevel and not ReachDayWinBonusTime() then 
                ActivityTipManager.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.TianXiaHuiWu, nil, function()
                    UIManager.showdialog("activity.dlgactivity",nil,2 )
                end)
                TeamFightData.m_IsRegistTip = true
            end
        end
    else
        if not IsInTimeRange() or IsDayBonusReceive() then
            ActivityTipManager.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.TianXiaHuiWu)
            TeamFightData.m_IsRegistTip = false
        end
    end
end

--==========================================================================================================
local function init()
    Network.add_listeners({
		--3v3竞技场信息
		{ "lx.gs.map.msg.SEctypeInfo",                  OnMsgSEctypeInfo				},
		{ "lx.gs.map.msg.SChangeTeamFight", 		    OnMsgSChangeTeamFight			},
          
		{ "lx.gs.map.msg.SBeginMatchTeamFight", 	    OnMsgSBeginMatchTeamFight		},
		{ "lx.gs.map.msg.SCancelMatchTeamFight", 	    OnMsgSCancelMatchTeamFight		},
		{ "lx.gs.map.msg.SObtainTeamFightDayReward", 	OnMsgSObtainTeamFightDayReward	},
		{ "lx.gs.map.msg.SObtainTeamFightWeekReward", 	OnMsgSObtainTeamFightWeekReward	},
        { "lx.gs.map.msg.SMatchTeamFightSucc", 	        OnMsgSMatchTeamFightSucc        },
        { "lx.gs.map.msg.SChangeMatch",                 OnMsgSChangeMatch               },

	})
    LoadConfigData()
    SetFirstRedDot(true)

    GameEvent.evt_second_update:add(second_update)
end

local function CanReceiveDayBonus()
    local winTimes, totalTimes = GetWinTimes()
    local resetedWinTimes = (((winTimes < totalTimes) and winTimes) or totalTimes)    
    local isReceived = IsDayBonusReceive()
    local canReceive = (winTimes >= totalTimes)
    if isReceived == false and canReceive == true then
        return true
    end
    return false
end

local function CanReceiveWeekBonus()
    local result = false
    local curScore, maxScore = GetScore()
    local bonusConfig = GetScoreBonus()
        
    for i = 1, #bonusConfig do
        local isReceived = IsWeekBonusReceive(i)
        local canReceive = (curScore >= bonusConfig[i].grade)
        if isReceived == false and canReceive == true then
            result = true
        end
    end
    return result
end
local function CanReceiveTitle()
    local result = false
    local AchievementManager = require("ui.achievement.achievementmanager")
    local TitleManager
    local allachieves = AchievementManager.GetAllAchievement()
    local achievements = allachieves[cfg.achievement.AchievementType.TEAMFIGHTTITLE]
    for i, achievement in pairs(achievements) do
        local state = AchievementManager.GetStateById(achievement.id)
        if state ~= cfg.achievement.Status.GETREWARD and state ~= cfg.achievement.Status.NOTCOMPLETED then
            result = true
        end
    end
    return result
end

local function GetDuration()
    local ectypeId = TeamFightData.m_ConfigData.id
    local ectypeCfg = ConfigManager.getConfigData("ectypebasic", ectypeId)
    if ectypeCfg then
        return ectypeCfg.totaltime
    end
    logError("找不到副本配置：" .. tostring(ectypeId))
    return 0
end

local function GetTimeStr(daytime)
    return string.format( "%02d:%02d", daytime.hour, daytime.minute )
end

local function GetOpenTimeStrs()
    local teamfightCfg = ConfigManager.getConfig("teamfight")
    local opentimeStrs = {}
    for i, opentime in ipairs(teamfightCfg.opentimes) do
        local strs = string.format( "%s-%s",GetTimeStr(opentime.begintime),GetTimeStr(opentime.endtime) )
        table.insert( opentimeStrs, strs )
    end
    return opentimeStrs
end




local function UnRead()
    return CanReceiveDayBonus() or CanReceiveWeekBonus()
end

return {
    init                        = init,
    IsMatching                  = IsMatching, 
    GetMatchEnable              = GetMatchEnable,
    GetMatchTime                = GetMatchTime,
    GetWinTimes                 = GetWinTimes,
    GetScore                    = GetScore,
    GetDayBonus                 = GetDayBonus,
    GetScoreBonus               = GetScoreBonus,
    GetLevelRegion              = GetLevelRegion,
    IsDayBonusReceive           = IsDayBonusReceive,
    IsWeekBonusReceive          = IsWeekBonusReceive,
    
    BeginMatchTeamFight         = BeginMatchTeamFight,
    CancelMatchTeamFight        = CancelMatchTeamFight,
    ObtainTeamFightDayReward    = ObtainTeamFightDayReward,
    ObtainTeamFightWeekReward   = ObtainTeamFightWeekReward,
    OnMsgSMatchTeamFightSucc    = OnMsgSMatchTeamFightSucc,

    GetDuration                 = GetDuration,

    UnRead                      = UnRead,
    GetOpenTimeStrs             = GetOpenTimeStrs,
    ShowFirstRedDot             = ShowFirstRedDot,
    SetFirstRedDot              = SetFirstRedDot,
    IsInTimeRange               = IsInTimeRange,
    GetMaxExtraBonusTimes       = GetMaxExtraBonusTimes,

}


