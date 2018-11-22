local ConfigMgr 	  = require "cfg.configmanager"
local ItemManager	  = require("item.itemmanager")
local UIManager 		= require("uimanager")
local gameevent         = require "gameevent"
local PlayerRole=require("character.playerrole")
local ActivityTipMgr
local PrologueManager

--base
local m_TournamentCfg
local m_termid
local m_stage
local m_roundindex
local m_roundstage
local m_opentime
local m_guessroleid
local m_guessendtime
local m_hasenroll

--role current round
local m_RoleRound
local m_RoleRoundBeginTime  --round prepare time
local m_RoleRoundOpponent
local m_RoleRoundOpponentStrength

--ectype
local m_HuiwuID
local m_EctypeID
local m_EctypeState
local m_EctypeFightRemainTime  --round fight time

--ectype statistic
local m_SelfDamage
local m_FoeDamage

--schedule
local m_HasNewSchedule

local function HasNewSchedule()
    return m_HasNewSchedule
end

local function SetNewSchedule(value)
    --printyellow("[TournamentInfo:SetNewSchedule] set m_HasNewSchedule:", value)
    m_HasNewSchedule = value
end

local function ClearStatistic()
    m_SelfDamage = 0
    m_FoeDamage = 0

    if UIManager.isshow("activity.tournament.dlgtournament") then
       UIManager.call("activity.tournament.dlgtournament","UpdateDamage")
    end
end

local function Clear()
    m_termid       		    = 0
	m_stage				    = 0
    m_roundindex            = 0
	m_roundstage			= -1
	m_opentime		        = 0
	m_guessroleid		    = 0
	m_hasenroll	            = false

    m_RoleRound                 = 0
    m_RoleRoundBeginTime        = 0
    m_RoleRoundOpponent         = nil
    m_RoleRoundOpponentStrength = 0

    --ectype
    m_HuiwuID               = 0
    m_EctypeID              = 0
    m_EctypeState           = 0
    m_EctypeFightRemainTime = 0

    --ectype statistic
    ClearStatistic()
    
    --schedule
    SetNewSchedule(false)
end

local function GetCurrentTerm()
    return m_termid
end

local function GetCurrentStage()
   -- printyellow("[TournamentInfo:GetCurrentStage] m_stage =", m_stage)
    return m_stage
end

local function GetCurrentLevel()
    return PlayerRole:Instance().m_RealLevel and PlayerRole:Instance().m_RealLevel or PlayerRole:Instance().m_Level
end

local function CanEnroll()
    --printyellow(string.format("[TournamentInfo:CanEnroll] m_TournamentCfg.requirelevel =%s, GetCurrentLevel()=%s.", m_TournamentCfg.requirelevel.level, GetCurrentLevel()))
    return GetCurrentStage() == cfg.huiwu.Stage.BEGIN_ENROLL and m_TournamentCfg.requirelevel.level<=GetCurrentLevel()--PlayerRole:Instance().m_Level--
end

local function GetCurrentRound()
    return m_roundindex
end

local function GetCurrentRoundStage()
    return m_roundstage
end

local function GetRoleRound()
    return m_RoleRound
end

local function GetRoleRoundBeginTime()
    if m_RoleRoundBeginTime and m_RoleRoundBeginTime>0 then
        return m_RoleRoundBeginTime
    else
        return 0
    end
end

local function GetRoleRoundOpponent()
    return m_RoleRoundOpponent
end

local function GetRoleRoundOpponentStrength()
    return m_RoleRoundOpponentStrength
end

local function GetRoleRoundEctypeID()
    return m_EctypeID
end

local function GetRoleRoundEctypeState()
    return m_EctypeState
end

local function GetRoleRoundEctypeFightRemainTime()
    if m_EctypeFightRemainTime and m_EctypeFightRemainTime>0 then
        return m_EctypeFightRemainTime
    else
        return 0
    end
end

local function GetRemainGuessTime()
    if m_guessendtime and m_guessendtime>0 then
        return m_guessendtime
    else
        return 0
    end
end

local function GetSelfDamage()
    return m_SelfDamage
end

local function GetFoeDamage()
    return m_FoeDamage
end

local function NeedShowDlgTournament() 
    if PrologueManager.IsInPrologue() then
        return false
    else
        return m_stage == cfg.huiwu.Stage.END_PRESELECT2
            or (m_stage == cfg.huiwu.Stage.BEGIN_BATTLE and m_roundstage>=0 and m_roundstage ~= cfg.huiwu.RoundStage.ROUND_REST)
    end
end

local function UpdateDlgTournament()
    --printyellow("[TournamentInfo:UpdateDlgTournament] try showing tournament Entrance!")
    if NeedShowDlgTournament() and UIManager.isshow("dlguimain") then
        if UIManager.isshow("activity.tournament.dlgtournament") then
            -- printyellow("[TournamentInfo:UpdateDlgTournament] update dlgtournament!")
            UIManager.call("activity.tournament.dlgtournament","UpdateDlg")
        else
            -- printyellow("[TournamentInfo:UpdateDlgTournament] show dlgtournament!")
            UIManager.show("activity.tournament.dlgtournament")
        end
        
        --uimain next button
        UIManager.call("dlguimain","setNxtFunIsShow", false)
        return true
    else
        --local log = string.format("[TournamentInfo:UpdateDlgTournament] show entrance failed! m_stage = %s, dlguimain isshow = %s", m_stage, UIManager.isshow("dlguimain"))
        -- printyellow(log)
        if UIManager.isshow("activity.tournament.dlgtournament") then
            -- printyellow("[TournamentInfo:UpdateDlgTournament] hide dlgtournament!")
            UIManager.hide("activity.tournament.dlgtournament")
        end

        --uimain next button
        if UIManager.isshow("dlguimain") then
            UIManager.call("dlguimain","setNxtFunIsShow", true)
        end
        return false
    end
end

local function HasEnroll()
	--printyellow("[TournamentInfo:HasEnroll] m_hasenroll = ",m_hasenroll)
    return m_hasenroll
end

local function GetGuessRoleid()
    --printyellow("[TournamentInfo:GetCurrentStage] m_stage =", m_stage)
    return m_guessroleid
end

local function CheckUnregisterActivityTip()
    if (m_stage ~= cfg.huiwu.Stage.BEGIN_ENROLL or true==HasEnroll()) and true==ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.QiMaiHuiWu) then  
        --printyellow("[TournamentInfo:CheckUnregisterActivityTip] unregister tourament activity tip!")      
        ActivityTipMgr.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.QiMaiHuiWu)
    end 
end

local function OnStageChange(oldstage, newstage)
    --printyellow(string.format("[TournamentInfo:OnStageChange] oldstage=[%s], newstage=[%s]", oldstage, newstage))
    --schedule
    if newstage==cfg.huiwu.Stage.BEFORE_ENROLL then
        SetNewSchedule(false)
    elseif newstage~=oldstage and HasEnroll() and 
        (newstage==cfg.huiwu.Stage.BEGIN_ENROLL 
        or newstage==cfg.huiwu.Stage.BEGIN_PRESELECT1 
        or newstage==cfg.huiwu.Stage.BEGIN_PRESELECT2) then
        SetNewSchedule(true)
    end
end

local function SetTermInfo(msg)
    printyellow("[TournamentInfo.SetTermInfo] set Term stage:", msg.stage)
	printyellow("[TournamentInfo.SetTermInfo] set Term roundindex:", msg.roundindex)
	printyellow("[TournamentInfo.SetTermInfo] set Term hasenroll:", msg.hasenroll)
	printyellow("[TournamentInfo.SetTermInfo] set Term m_termid:", msg.termid)
    OnStageChange(m_stage, msg.stage)

    m_termid       		    = msg.termid
	m_stage				    = msg.stage
	m_roundindex			= msg.roundindex
    if m_stage~=cfg.huiwu.Stage.BEGIN_BATTLE then
        m_roundstage = -1
    else
	    m_roundstage			= msg.roundstage
    end
	m_opentime		        = msg.opentime
	m_guessroleid		    = msg.guessroleid
	m_hasenroll	            = (msg.hasenroll>0)
   -- printyellow("[TournamentInfo.SetTermInfo] m_hasenroll =", m_hasenroll)

    m_guessendtime          = msg.guessendtime/1000 - timeutils.GetServerTime()
   -- printyellow(string.format("[TournamentInfo:SetTermInfo] msg.guessendtime=%s, m_guessendtime=%s!", timeutils.TimeStr(msg.guessendtime/1000), timeutils.getDateTimeString(m_guessendtime, "hh:mm:ss")))

    if UIManager.isshow("activity.tournament.tabtournament") then
        UIManager.call("activity.tournament.tabtournament","UpdateEnrollInfo")
    end
    
    CheckUnregisterActivityTip()
    UpdateDlgTournament()
end

local function SetGuessRoleid(roleid)
    --printyellow("[TournamentInfo:GetCurrentStage] m_stage =", m_stage)
    m_guessroleid = roleid
end

local function SetEnroll(value)
    -- printyellow("[TournamentInfo.SetEnroll] Set Enroll:", value)
    m_hasenroll = value
    CheckUnregisterActivityTip()
end

local function GetCfgGuessTime()
    local guesstime = 0
    guesstime = guesstime + (m_TournamentCfg.battleopen.weekday - m_TournamentCfg.preselectend2.weekday)*86400
    guesstime = guesstime + (m_TournamentCfg.battleopen.hour - m_TournamentCfg.preselectend2.hour)*3600
    guesstime = guesstime + (m_TournamentCfg.battleopen.minute - m_TournamentCfg.preselectend2.minute)*60
    guesstime = guesstime + (m_TournamentCfg.battleopen.second - m_TournamentCfg.preselectend2.second)

    -- printyellow("[TournamentInfo.GetCfgGuessTime] GetCfgGuessTime:", guesstime)
    return guesstime
end

local function SetStageInfo(msg)
    --printyellow("[TournamentInfo.SetStageInfo] set Stage Info:", msg)
    
    OnStageChange(m_stage, msg.stage)

    m_termid       		    = msg.termid
	m_stage				    = msg.stage
    CheckUnregisterActivityTip()

    if m_stage~=cfg.huiwu.Stage.BEGIN_BATTLE then
        m_roundstage = -1
    end

    if m_stage == cfg.huiwu.Stage.END_PRESELECT2 then
        --printyellow(string.format("[TournamentInfo.SetStageInfo] set m_guessendtime = GetCfgGuessTime()[%s].", GetCfgGuessTime()))
        m_guessendtime = GetCfgGuessTime()
    else
        --printyellow("[TournamentInfo.SetStageInfo] set m_guessendtime = 0.")
        m_guessendtime = 0
    end

    if UIManager.isshow("activity.tournament.tabtournament") then
        UIManager.call("activity.tournament.tabtournament","UpdateEnrollInfo")
    end

    UpdateDlgTournament()
end

local function SetRoundStageInfo(msg)
    --printyellow("[TournamentInfo.SetRoundStageInfo] set RoundStage Info:", msg)

    m_termid = msg.termid
    m_roundindex = msg.round
    m_roundstage = msg.roundstage

    --ectype statistic
    ClearStatistic()

    if m_roundstage == cfg.huiwu.RoundStage.ROUND_FIGHT then
        m_RoleRoundBeginTime = 0
    elseif m_roundstage == cfg.huiwu.RoundStage.ROUND_REST then
        --role current round
        --m_RoleRound = 0
        m_RoleRoundBeginTime = 0
        m_RoleRoundOpponent = nil
        m_RoleRoundOpponentStrength = 0

        --ectype
        m_HuiwuID = 0
        m_EctypeID = 0
        m_EctypeState = 0
        m_EctypeFightRemainTime = 0
    end

    UpdateDlgTournament()
end

local function OnRoleRoundChange(oldroleround, newroleround)    
    --printyellow(string.format("[TournamentInfo:OnRoleRoundChange] oldroleround=[%s], newroleround=[%s]", oldroleround, newroleround))
    --schedule
    if oldroleround~=newroleround and HasEnroll() then
        SetNewSchedule(true)
    end
end

local function SetRoleRoundInfo(msg)
    --printyellow("[TournamentInfo.SetRoleRoundInfo] set RoleRound Info:", msg)
    OnRoleRoundChange(m_RoleRound, msg.round)    

    m_RoleRound = msg.round
    --m_RoleRoundBeginTime = msg.battlebegintime/1000
    m_RoleRoundBeginTime          = msg.battlebegintime/1000 - timeutils.GetServerTime()
    m_RoleRoundOpponent = msg.opponent
    m_RoleRoundOpponentStrength = msg.opponentcombatpower
    -- printyellow(string.format("[TournamentInfo:SetRoleRoundInfo] msg.battlebegintime=%s, m_RoleRoundBeginTime=%s!", timeutils.TimeStr(msg.battlebegintime/1000), timeutils.getDateTimeString(m_RoleRoundBeginTime, "dd�� hh:mm:ss")))

    UpdateDlgTournament()
end

local function SetHuiwuEctypeInfo(msg)
    -- printyellow("[TournamentInfo.SetHuiwuEctypeInfo] set HuiwuEctype Info:", msg)

    m_HuiwuID = msg.id
    m_EctypeID = msg.ectypeid
    m_EctypeState = msg.state
    m_EctypeFightRemainTime = msg.remaintime/1000
    -- printyellow(string.format("[TournamentInfo:SetHuiwuEctypeInfo] msg.remaintime=%s, m_EctypeFightRemainTime=%s!", timeutils.TimeStr(msg.remaintime/1000), timeutils.getDateTimeString(m_EctypeFightRemainTime, "dd�� hh:mm:ss")))

    UpdateDlgTournament()
end

local function GetWeekTimeSeconds(weektime)
    local seconds = 0

    local curweekday = 0
    local curhour = 0
    local curminite = 0
    local cursecond = 0
    if weektime then
        --printyellow("[TournamentInfo:GetWeekTimeSeconds] weektime:")
        --printt(weektime)
        curweekday = weektime.weekday and weektime.weekday or curweekday
        curhour = weektime.hour and weektime.hour or curhour
        curminite = weektime.minute and weektime.minute or curminite
        cursecond = weektime.second and weektime.second or cursecond
    else
        local timenow= timeutils.TimeNow()
        --printyellow("[TournamentInfo:GetWeekTimeSeconds] timeutils.TimeNow():")
        --printt(timenow)
        curweekday = timenow.wday and timenow.wday or curweekday
        curhour = timenow.hour and timenow.hour or curhour
        curminite = timenow.min and timenow.min or curminite
        cursecond = timenow.sec and timenow.sec or cursecond
        --sunday is the first day
        if curweekday == 1 then
            curweekday = 7
        else
            curweekday = curweekday -1
        end
    end
    --printyellow(string.format("[TournamentInfo:GetWeekTimeSeconds] curweekday=%s, curhour=%s, curminite=%s, cursecond=%s!", curweekday, curhour, curminite, cursecond))
    seconds = seconds + (curweekday-1)*86400
    seconds = seconds + curhour*3600
    seconds = seconds + curminite*60
    seconds = seconds + cursecond

    return seconds
end

local function OnTournamentTipClicked()
    --printyellow("[TournamentInfo:OnTournamentTipClicked] On Tournament activityTip Clicked!")
    local params = {}
    params.tabindex2 = 1
    UIManager.showdialog("activity.dlgactivity", params, 3)
end

local function update()
    --round prepare time
    if m_RoleRoundBeginTime and m_RoleRoundBeginTime>0 and m_roundstage == cfg.huiwu.RoundStage.ROUND_PREPARE then
        m_RoleRoundBeginTime = m_RoleRoundBeginTime - Time.deltaTime
        if m_RoleRoundBeginTime <= 0 then
            m_RoleRoundBeginTime = 0
        end
    end

    --round fight time
    if m_EctypeFightRemainTime and m_EctypeFightRemainTime>0 and m_roundstage == cfg.huiwu.RoundStage.ROUND_FIGHT then
        m_EctypeFightRemainTime = m_EctypeFightRemainTime - Time.deltaTime
        if m_EctypeFightRemainTime <= 0 then
            m_EctypeFightRemainTime = 0
        end
    end

    --guess time
    if m_stage == cfg.huiwu.Stage.END_PRESELECT2 and m_guessendtime and m_guessendtime>0 then
        m_guessendtime = m_guessendtime - Time.deltaTime
        if m_guessendtime <= 0 then
            m_guessendtime = 0
        end
    end    
        
    --activity tip
    --printyellow(string.format("[TournamentInfo:update] m_stage=%s, HasEnroll()=%s, ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.QiMaiHuiWu)=%s!", m_stage, HasEnroll(), ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.QiMaiHuiWu)))
    if m_stage == cfg.huiwu.Stage.BEGIN_ENROLL and false==HasEnroll() and CanEnroll() and false==ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.QiMaiHuiWu) then
        local endenrooltime = GetWeekTimeSeconds(m_TournamentCfg.enrollend)
        local curweektime = GetWeekTimeSeconds()
        local timediff = endenrooltime-curweektime

        --test
        --timediff = 10

        if timediff and timediff>0 and timediff<=(30*60) then
            --printyellow("[TournamentInfo:update] register Tournament activityTip!")
            ActivityTipMgr.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.QiMaiHuiWu, nil, OnTournamentTipClicked)
        end
    end    
end

local function SetStatistic(selfdmg, foedmg)
    m_SelfDamage = m_SelfDamage + selfdmg
    m_FoeDamage = m_FoeDamage + foedmg

    if UIManager.isshow("activity.tournament.dlgtournament") then
       UIManager.call("activity.tournament.dlgtournament","UpdateDamage")
    end
end

local function init()
    --printyellow("[TournamentInfo:init] TournamentInfo init!")
    ActivityTipMgr           = require("ui.activity.activitytipmanager")
    PrologueManager = require"prologue.prologuemanager"
    
    m_TournamentCfg  = ConfigManager.getConfig("huiwu")
    if m_TournamentCfg == nil then
        printyellow("[tabtournament:init] m_TournamentCfg null!")
    end
	gameevent.evt_update:add(update)
    Clear()
end

return
{
    init=init,
    SetTermInfo = SetTermInfo,
    SetEnroll = SetEnroll,
    SetStageInfo = SetStageInfo,
    SetRoundStageInfo = SetRoundStageInfo,
    SetRoleRoundInfo = SetRoleRoundInfo,
    SetHuiwuEctypeInfo = SetHuiwuEctypeInfo,
    SetGuessRoleid = SetGuessRoleid,
    SetStatistic = SetStatistic,
    GetCurrentLevel = GetCurrentLevel,

    GetCurrentTerm = GetCurrentTerm,
    GetCurrentStage = GetCurrentStage,
    GetCurrentRound = GetCurrentRound,
    GetCurrentRoundStage = GetCurrentRoundStage,
    GetGuessRoleid = GetGuessRoleid,
    GetRemainGuessTime = GetRemainGuessTime,

    GetRoleRound = GetRoleRound,
    GetRoleRoundBeginTime = GetRoleRoundBeginTime,
    GetRoleRoundOpponent = GetRoleRoundOpponent,
    GetRoleRoundOpponentStrength = GetRoleRoundOpponentStrength,

    GetRoleRoundEctypeID = GetRoleRoundEctypeID,
    GetRoleRoundEctypeState = GetRoleRoundEctypeState,
    GetRoleRoundEctypeFightRemainTime = GetRoleRoundEctypeFightRemainTime,

    GetSelfDamage = GetSelfDamage,
    GetFoeDamage = GetFoeDamage,

    HasEnroll = HasEnroll,
    NeedShowDlgTournament = NeedShowDlgTournament,
    UpdateDlgTournament = UpdateDlgTournament,
    ClearStatistic = ClearStatistic,
    CanEnroll = CanEnroll,

    --schedule
    HasNewSchedule = HasNewSchedule,
    SetNewSchedule = SetNewSchedule,
}
