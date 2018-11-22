local network = require "network"
local PlayerRole = require"character.playerrole"
local uimanager      = require("uimanager")
local TeamManager=require"ui.team.teammanager"
local EctypeManager

local ismatching = false
local nextmatchtime = 0
local matchinfo = nil
local lasttime = 0
local minpower = 0
local hard = 0 -- 0��ͨ

local FsmState = enum{
    "UnReady",
    "Ready",
    --"WalkToTarget",
    "Matching",
    "Matched",
}

local currentstate = FsmState.UnReady

local HardState = enum{
    "Easy",
    "Hard",
}

local currenthardstate = HardState.Easy




local function GetCurrentEctype()
    local currentectype = EctypeManager.GetEctype()
    if currentectype ~=nil and currentectype.m_EctypeType == cfg.ectype.EctypeType.GUARDTOWER then
        return currentectype
    end
    return nil
end

local function GetGuardTower()
    return ConfigManager.getConfig("guardtower")
end

local function IsMatching()
    return currentstate == FsmState.Matching
end

local function IsMatched()
    return currentstate == FsmState.Matched
end

local function IsReady()
    return currentstate == FsmState.Ready
end

local function IsUnReady()
    return currentstate == FsmState.UnReady
end

local function GetLimitLevel(hardstate)
    local guardtower = GetGuardTower()
    if hardstate == HardState.Easy then 
        return guardtower.lvlimit.level
    else 
        return guardtower.hardlvlimit.level 
    end 
end 

local function RoleLevelAchieve(hardstate)
    local limitlevel = GetLimitLevel(hardstate)
    local playerlevel = tonumber(PlayerRole:Instance().m_Level)
    return limitlevel <= playerlevel
end

local function GetLastTimes(hardstate)
    local guardtower = GetGuardTower()
    local LimitManager = require "limittimemanager"
    -- printt(guardtower.dailylimit.entertimes)
    --printyellow("GetLastTimes",guardtower.dailylimit.entertimes[PlayerRole:Instance().m_VipLevel],PlayerRole:Instance().m_VipLevel)
	local viplevel  =0
	if PlayerRole:Instance().m_VipLevel+1 >= 15 then
		viplevel = 15
	else
		viplevel = PlayerRole:Instance().m_VipLevel+1
	end
    return guardtower.dailylimit.entertimes[viplevel] - LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.GUARD_TOWER_ECTYPE,hardstate)
end

local function TimeLimitOk()
    local guardtower = GetGuardTower()
    local start_time = timeutils.getSeconds({hours = guardtower.opentime.hour,minutes=guardtower.opentime.minute,seconds=guardtower.opentime.second})
    local end_time = start_time + guardtower.last
    local now = timeutils.TimeNow()
    local time_now = timeutils.getSeconds({hours = now.hour,minutes=now.min,seconds=now.sec})
    return time_now>start_time and time_now < end_time
end

local function CanMatch(hardstate)
    return  RoleLevelAchieve(hardstate) and IsReady() and GetLastTimes()>0 and TimeLimitOk()
end


local function EnableMatch()
    return nextmatchtime <= timeutils.GetServerTime()
end

local function GetLastMatchTime()
    return nextmatchtime - timeutils.GetServerTime()
end

local function GetMatchInfo()
    return matchinfo
end

local function GetLastTime()
    return lasttime
end


local function GetMinPower()
    return minpower
end

local function GetTeamMinCombatPower()
    local min = PlayerRole:Instance().m_Power
    local team = TeamManager.GetTeamInfo()
    if team~=nil then
        for _,member in pairs(team.members) do
            if member.roleinfo.combatpower <min then
                min = member.roleinfo.combatpower
            end
        end
    end
    return min
end

local function SetMinPower(imp,callback)
    local mp = tonumber(imp)
    if mp == nil then
        uimanager.ShowSystemFlyText(LocalString.GuardTower.SettingInputDefault) --temp code
        return
    end
    if mp > GetTeamMinCombatPower()  then
        uimanager.ShowSystemFlyText(LocalString.GuardTower.MinPower)
        return
    end
    --printyellow("minpower",minpower)
    minpower = mp
    callback()
end

local function SetState(state)
    --printyellow("guardtowermanager:SetState(state)",utils.getenumname(FsmState,state),Time.time)
    currentstate = state
    uimanager.refresh("activity.multipve.tabmultipve")
    if state == FsmState.Matching or state == FsmState.Matched then
        uimanager.showorrefresh("ectype.guardtower.dlgguardtower_matching")
    else
        uimanager.refresh("ectype.guardtower.dlgguardtower_matching")
    end

--    if state == FsmState.Ready then
--        minpower = 0
--    end
end

local function ChangeState()
    if ismatching then
        SetState(FsmState.Matching)
    elseif not EnableMatch() then
        SetState(FsmState.UnReady)
    else
        SetState(FsmState.Ready)
    end

end

local function SetHardState(state)
    --printyellow("guardtowermanager:SetHardState(state)",utils.getenumname(HardState,state),Time.time)
    currenthardstate = state
    uimanager.refresh("activity.multipve.tabmultipve")
end

local function GetHardState()
    return currenthardstate
end 


local function GetRuneBuffs()
    local buffs = {}
    local guardtower = GetGuardTower()
    for _,runeinfo in pairs(guardtower.spellmsg.runeinfo) do
        local rune = ConfigManager.getConfigData("rune",runeinfo.runeid)
        if rune then
            local buffinfo = ConfigManager.getConfigData("buff",rune.buffid)
            local effect = buffinfo.effects[1]
            if effect then
                local effectinfo = ConfigManager.getConfigData("effect",effect.effectid)
                if effectinfo then
                    buffs[effectinfo.id] ={Rune = rune,Buff = buffinfo,Effect = effectinfo,Num = 0}
                end

            end
        end
    end

    return buffs
end

local function GetEctypeInfo()
    local guardtower = GetGuardTower()
    local minzone = nil
    for _,zone in pairs(guardtower.zones) do
        validate = checkcmd.CheckData( { data = zone.levellimit, num = 1, showsysteminfo = false })
        if validate then
            return zone
        end
        if minzone == nil or minzone.levellimit.min> zone.levellimit.min then
            minzone = zone
        end
    end
    if minzone == nil then
        logError("guardtower config error please check!!!")
    end
    return minzone
end

local function GetShowBonusId() 
    local info = GetEctypeInfo()
    if currenthardstate == HardState.Easy then 
        return info.showbonusid
    elseif currenthardstate == HardState.Hard then
        return info.hardshowbonusid
    end 
end 

local function GetHardInfo() 
    --printyellow(LocalString.GuardTower.HardInfo,cfg.ectype.GuardTower.easy)
    local guardtower = GetGuardTower()
    if currenthardstate == HardState.Easy then 
        return guardtower.ease
    elseif currenthardstate == HardState.Hard then
        return guardtower.hard
    end 
end 

local function GetHardTexture() 
    --printyellow(LocalString.GuardTower.HardInfo,cfg.ectype.GuardTower.easy)
    local guardtower = GetGuardTower()
    if currenthardstate == HardState.Easy then 
        return guardtower.easetexture
    elseif currenthardstate == HardState.Hard then
        return guardtower.hardtexture
    end 
end 

local function GetLevelInfo() 
    local info = GetEctypeInfo()
    return string.format("%s-%s",info.levellimit.min,info.levellimit.max)
end 

local function GetOpenTimeInfo()
    local guardtower = GetGuardTower()
    local start_time = timeutils.getSeconds({hours = guardtower.opentime.hour,minutes=guardtower.opentime.minute,seconds=guardtower.opentime.second})
    local end_time = start_time + guardtower.last
    return  string.format(LocalString.GuardTower.OpenTime,
                        timeutils.getDateTimeString(start_time,"hh:mm"),
                        timeutils.getDateTimeString(end_time,"hh:mm"))
end 

local function EatRune(id)
    local re = map.msg.CEatRune({ runeagentid = id})
    network.send(re)
end

local function MatchStart(hardstate)
    local re = lx.gs.map.msg.CGuardTowerMatchStart({ minpower = minpower,ishard = hardstate})
    network.send(re)
end

local function onmsg_SGuardTowerMatchStart(msg)
    local guardtower = GetGuardTower()
    lasttime = guardtower.matchtimeout
end

local function MatchCancel()
    local re = lx.gs.map.msg.CGuardTowerMatchCancel()
    network.send(re)
end

local function onmsg_SGuardTowerMatchCancel(msg)
    if uimanager.isshow("ectype.guardtower.dlgguardtower_matching") then
         uimanager.hide("ectype.guardtower.dlgguardtower_matching")
    end
end

local function onmsg_SGuardTowerMatchError(msg)
    uimanager.ShowSystemFlyText(LocalString.GuardTower.MatchError)
    if uimanager.isshow("ectype.guardtower.dlgguardtower_matching") then
         uimanager.hide("ectype.guardtower.dlgguardtower_matching")
    end
end

local function onmsg_SGuardTowerMatcherUpdate(msg)
    matchinfo = msg
    if matchinfo.matched == 1 then
        lasttime = matchinfo.countdown
        SetState(FsmState.Matched)
    end
end

local function onmsg_SGuardTowerMatchMemberOut(msg)
    if matchinfo then
        for i,palyerinfo in pairs(matchinfo.teaminfo.members) do
            if palyerinfo.roleid == msg.roleid then
                table.remove(matchinfo.teaminfo.members,i)
                break
            end
        end
    end
    uimanager.refresh("ectype.guardtower.dlgguardtower_matching")
end

local function onmsg_SEnterGuardTower(msg)
    ChangeState()
end



local function onmsg_SEctypeInfo(msg)
    -- printyellow("onmsg_SEctypeInfo")
    ismatching = msg.matchtype == cfg.ectype.MatchType.GUARD_TOWER
    nextmatchtime = math.floor(msg.nextmatchtime/1000)
    if currentstate ~= FsmState.Matched then
        ChangeState()
    end
end

local function onmsg_SChangeMatch(msg)
    ismatching = msg.matchtype == cfg.ectype.MatchType.GUARD_TOWER
    nextmatchtime = math.floor(msg.nextmatchtime/1000)
    if currentstate ~= FsmState.Matched then
        ChangeState()
    end
end


local function onmsg_SEatRune(msg)
    local CurrentEctype= GetCurrentEctype()
    if  CurrentEctype then
        if msg.result == 1 then
            CurrentEctype:EatRune(msg.runeid)
        end
    end
end

local function onmsg_SNewWaveOpen(msg)
    local CurrentEctype= GetCurrentEctype()
    if CurrentEctype then
        CurrentEctype:NewWaveOpen(msg.waveid)
    end
end


local function onmsg_AddEffect(msg)
    local CurrentEctype= GetCurrentEctype()
    if CurrentEctype then
        CurrentEctype:AddEffect(msg.effect)
    end
end

local function onmsg_RemoveEffect(msg)
    local CurrentEctype= GetCurrentEctype()
    if CurrentEctype then
        CurrentEctype:RemoveEffect(msg.id)
    end
end


local function onmsg_RemoveEffect(msg)
    local CurrentEctype= GetCurrentEctype()
    if CurrentEctype then
        CurrentEctype:RemoveEffect(msg.id)
    end
end

local function UnRead_HardState(hardstate) 
    return GetLastTimes(hardstate)>0 and RoleLevelAchieve(hardstate) and TimeLimitOk()
end 

local function UnRead()
    return UnRead_HardState(HardState.Easy) or UnRead_HardState(HardState.Hard)
end

local function Invitation()
    local DlgMultiEctypeMatching = require"ui.ectype.multiectype.dlgmultiectypematching" 
    local ectypeinfo = GetEctypeInfo() 
    if ectypeinfo then 
        uimanager.show("common.dlgdialogbox_common",{cur_ectypeid = GetHardState() == HardState.Easy and ectypeinfo.ectypeid or ectypeinfo.hardectypeid, callBackFunc = DlgMultiEctypeMatching.ShowInviteButton})
    end 
end

local function GetHardStateByEctypeId(ectypeid)
    local ectypeinfo = GetEctypeInfo() 
    if ectypeinfo and ectypeinfo.ectypeid == ectypeid then 
        return HardState.Easy
    else 
        return HardState.Hard
    end
end 



local function CanReceiveInviteMessage(ectypeid) 
    local ectypeinfo = GetEctypeInfo() 
    local hardstate = GetHardStateByEctypeId(ectypeid)
    if ectypeinfo and UnRead_HardState(hardstate) then 
        return true,string.format(LocalString.GuardTower.SendMsg,GetHardInfo(),ectypeinfo.levellimit.min,ectypeinfo.levellimit.max)
    end 
    return false,""
end 


local function SendScroll(ectypeid)
    local hardstate = GetHardStateByEctypeId(ectypeid)
    if not IsReady() then 
        uimanager.show("dlgalert_reminder_singlebutton",{content = LocalString.GuardTower.SendError_MatchingState})
    elseif GetLastTimes(hardstate)<=0 then  
        uimanager.show("dlgalert_reminder_singlebutton",{content = LocalString.GuardTower.SendError_Times})
    else 
        MatchStart(hardstate)
    end 
end 







local function second_update(now)
    if lasttime > 0 then lasttime = lasttime -1 end
    if IsUnReady() then
        if lasttime <=0 then
            SetState(FsmState.Ready)
        end
    end
end

local function init()
    EctypeManager =require"ectype.ectypemanager"
    gameevent.evt_second_update:add(second_update)
   network.add_listeners( {
        { "lx.gs.map.msg.SGuardTowerMatchStart", onmsg_SGuardTowerMatchStart},
        { "lx.gs.map.msg.SGuardTowerMatchCancel", onmsg_SGuardTowerMatchCancel},
        { "lx.gs.map.msg.SGuardTowerMatchError", onmsg_SGuardTowerMatchError},
        { "lx.gs.map.msg.SGuardTowerMatcherUpdate", onmsg_SGuardTowerMatcherUpdate},
        { "lx.gs.map.msg.SGuardTowerMatchMemberOut", onmsg_SGuardTowerMatchMemberOut},

        { "lx.gs.map.msg.SEctypeInfo",  onmsg_SEctypeInfo},
        { "lx.gs.map.msg.SChangeMatch", onmsg_SChangeMatch},

        { "map.msg.SEnterGuardTower", onmsg_SEnterGuardTower},

        { "map.msg.SEatRune", onmsg_SEatRune},
        { "map.msg.SNewWaveOpen", onmsg_SNewWaveOpen},
        { "map.msg.SAddEffect",           onmsg_AddEffect             },
        { "map.msg.SRemoveEffect",        onmsg_RemoveEffect          },

    } )

    --UISprite_Matching
end

return{
    init = init,
    GetGuardTower = GetGuardTower,
    GetEctypeInfo = GetEctypeInfo,
    GetRuneBuffs =  GetRuneBuffs,
    GetMatchInfo = GetMatchInfo,
    GetLastTime = GetLastTime,
    GetLastMatchTime = GetLastMatchTime,
    GetMinPower = GetMinPower,
    SetMinPower = SetMinPower,
    EatRune = EatRune,
    MatchStart = MatchStart,
    MatchCancel = MatchCancel,
    EnableMatch = EnableMatch,

    IsMatching = IsMatching,
    IsMatched = IsMatched,
    IsReady = IsReady,
    IsUnReady = IsUnReady,
    RoleLevelAchieve = RoleLevelAchieve,
    CanMatch = CanMatch,
    UnRead = UnRead,
    GetLastTimes = GetLastTimes,
    Invitation = Invitation,
    CanReceiveInviteMessage = CanReceiveInviteMessage,
    SendScroll= SendScroll,
    SetHardState = SetHardState,
    GetHardState = GetHardState,
    GetShowBonusId = GetShowBonusId,
    GetHardInfo = GetHardInfo,
    GetHardTexture = GetHardTexture,
    GetLevelInfo = GetLevelInfo,
    GetOpenTimeInfo = GetOpenTimeInfo,
    GetLimitLevel = GetLimitLevel,
    UnRead_HardState = UnRead_HardState,

}
