local StoryEctype = require"ectype.story"
local network = require"network"
local gameevent = require "gameevent"
local CharacterManager = require"character.charactermanager"
local Tower = require"ectype.tower"
local PlayerRole = require"character.playerrole"
local ConfigManager = require"cfg.configmanager"
local SceneManager = require"scenemanager"
local uimanager = require"uimanager"
local Daily = require"ectype.daily"
local Arena = require "ectype.arena"
local PersonalBoss = require "ectype.personalboss"
local TeamFight = require "ectype.teamfight"
local HeroBook = require "ectype.herobook"
local GuardTower = require "ectype.guardtower"
local FamilyEctype = require "ectype.familyectype"
local TeamSpeed = require"ectype.teamspeed"
local AttackCity = require"ectype.attackcity"
local MaiMai = require"ectype.maimai"
local RoleSkill     = require "character.skill.roleskill"
local AudioManager = require"audiomanager"
local EctypeOthersManager =  require("ectype.ectypeothersmanager")
local FamilyWar         = require"ectype.FamilyWar"
local EctypesInfo
local TeamCurrency = require("ectype.teamcurrency")
local FamilyRoundRobin = require("ectype.familyroundrobin")
local TeamSpeedManager  = require"ectype.teamspeedmanager"
local FamilyCastle    =  require("ectype.familycastle")

local CurrentEctype = nil
local CurrentTower = nil
local Characters = {}
local lateTime = nil
local StarInfo
local ElapsedTime
local msgEnd
local bSignTeamSpeed
local illegalTime
local enterDialog
local enterDialogTab
local leaveInfo
local enterUI

local tinsert           = table.insert

EctypeEntries = {
    [cfg.ectype.EctypeType.CLIMB_TOWER] 	= {dlg="ectype.dlgentrance_copy",tab=4},
    [cfg.ectype.EctypeType.CURRENCY] 		= {dlg="ectype.dlgentrance_copy",tab=2,param={ index = 1}},
    [cfg.ectype.EctypeType.EXP] 			= {dlg="ectype.dlgentrance_copy",tab=2,param={ index = 2}},
    [cfg.ectype.EctypeType.YUPEI] 			= {dlg="ectype.dlgentrance_copy",tab=2,param={ index = 4}},
    [cfg.ectype.EctypeType.HUFU] 			= {dlg="ectype.dlgentrance_copy",tab=2,param={ index = 3}},
    [cfg.ectype.EctypeType.PERSONAL_BOSS] 	= {dlg="ectype.dlgentrance_copy",tab=2,param={ index = 5}},
    [cfg.ectype.EctypeType.HEROES] 			= {dlg="ectype.dlgentrance_copy",tab=2,param={ index = 6}},
    [cfg.ectype.EctypeType.STORY] 			= {dlg="ectype.dlgentrance_copy",tab=1},
    [cfg.ectype.EctypeType.ARENA] 			= {dlg="arena.dlgarena",tab=1},
    [cfg.ectype.EctypeType.GUARDTOWER] 		= {dlg="activity.dlgactivity",tab=1,param={ index = 3}},
    [cfg.ectype.EctypeType.TEAMFIGHT] 		= {dlg="activity.dlgactivity",tab=2,param={ index = 1}},
    [cfg.ectype.EctypeType.TEAM_SPEED] 		= {dlg="arena.dlgarena",tab=2},
    [cfg.ectype.EctypeType.MULTI_STORY]		= {dlg="ectype.dlgentrance_copy",tab=3},
    [cfg.ectype.EctypeType.CURRENCY_ACTIVITY] ={dlg="activity.dlgactivity",tab=4,param={index = 2}},
}

local function BackUpEnterUI()
    if CurrentEctype then return end
    enterUI = uimanager.currentdialogname()
end

local function GetEctypeType(ectypeid)
	local cfgEctype = ConfigManager.getConfigData("ectypebasic",ectypeid)
	return cfgEctype.type
end

local function GetEctypeLeaveInfo()
	if CurrentEctype then
		local type = GetEctypeType(CurrentEctype.m_ID)
		return EctypeEntries[type]
	end
	return nil
end

local function GetEctypeTypeById(ectypeid)
	local ectypebasic = ConfigManager.getConfig("ectypebasic")
	for _,ectypedata in pairs(ectypebasic) do
		if ectypedata.id == ectypeid then
			return ectypedata.type
		end
	end
	return nil
end

local function CanReceiveInviteMessage(ectypeid)  --��������ֵ [bool,string] bool�Ƿ��ܽ��գ�string�Ƿ��ص���Ϣ����
	local ectypeType = GetEctypeTypeById(ectypeid)
	if ectypeType == cfg.ectype.EctypeType.MULTI_STORY then
		local MultiEctypeManger = require("ui.ectype.multiectype.multiectypemanager")
		return MultiEctypeManger.CanReceiveInviteMessage(ectypeid)
	elseif ectypeType == cfg.ectype.EctypeType.GUARDTOWER then
        local guardtowermanager = require "ui.ectype.guardtower.guardtowermanager"
        return guardtowermanager.CanReceiveInviteMessage(ectypeid)
			--������������
	end
    return false
end

local function SendScroll(ectypeid)
	local ectypeType = GetEctypeTypeById(ectypeid)
	if ectypeType == cfg.ectype.EctypeType.MULTI_STORY then
		local MultiEctypeManger = require("ui.ectype.multiectype.multiectypemanager")
		MultiEctypeManger.SendScroll(ectypeid)
    elseif ectypeType == cfg.ectype.EctypeType.GUARDTOWER then
        local guardtowermanager = require "ui.ectype.guardtower.guardtowermanager"
        guardtowermanager.SendScroll(ectypeid)
	else
        --������������
	end
end

local function CheckPosition(position)
    if CurrentEctype then
        local a = CurrentEctype:CheckPosition(position/100)
        return  a
    else
        return true
    end

end

local function RequestLeaveEctype()
    local re = lx.gs.map.msg.CLeaveMap({})
    network.send(re)
end

local function AlterNeedLoad(b)
    NeedLoad = b
end

local function EndEctype(msg)
    msgEnd = msg
    ElapsedTime = CurrentEctype.m_BasicEctypeInfo.endofftime
end

local function FuncEnd()
    if CurrentEctype then
        CurrentEctype:OnEnd(msgEnd)
    end
end

local function IsFinished()
    if CurrentEctype and ElapsedTime~=nil then
        return true
    end
    return false
end

local function OnLeave()
	if leaveInfo then
		uimanager.showdialog(leaveInfo.dlg,leaveInfo.param,leaveInfo.tab)
		leaveInfo = nil
	end
end

local function RoleEnterEctype()
    if CurrentEctype then
        CurrentEctype:RoleEnterEctype()
    end
end

local function Update()
    if CurrentEctype then
        CurrentEctype:Update()
        if ElapsedTime then
            ElapsedTime = ElapsedTime - Time.deltaTime
            if ElapsedTime<0 then
                AudioManager.StopBackgroundMusic()
                ElapsedTime = nil
                CurrentEctype:OnEnd(msgEnd)
            end
        end
    end
end

local function late_update()
    if CurrentEctype then
        CurrentEctype:late_update()
    end
end

local function GetEctype()
    return CurrentEctype
end

local function IsBattleEctype()
    if not CurrentEctype then return false end
    if CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.TEAMFIGHT
    or CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.FAMILYWAR then
        return true
    end
    return false
end

local function ShowTasks(b)
    if CurrentEctype then
        CurrentEctype:ShowTasks(b)
    end
end

local function onmsg_ChangeClimbTower(msg)
    PlayerRole.Instance().m_ClimbTowerInfo[msg.ectypeid] = msg.info
end

local function onmsg_OpenLayout(msg)
    if CurrentEctype then
        CurrentEctype:OpenLayout(msg)
    end
end

local function onmsg_CloseLayout(msg)
    if CurrentEctype then
        CurrentEctype:CloseLayout(msg)
    end
end

local function onmsg_ChangeEntry(msg)
    if CurrentEctype then
        CurrentEctype:ChangeEntry(msg)
    end
end

local function onmsg_ChangeExit(msg)
    if CurrentEctype then
        CurrentEctype:ChangeExit(msg)
    end
end

local function onmsg_ChangeEnviroment(msg)
    if CurrentEctype then
        CurrentEctype:ChangeEnviroment(msg)
    end
end

local function onmsg_CompleteLayout(msg)
    if CurrentEctype then
        CurrentEctype:CompleteLayout(msg)
    end
end

local function onmsg_EnterEctype(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        local ectypeInfo = ConfigManager.getConfigData("ectypebasic",msg.ectypeid)
        local PlayerRole = require"character.playerrole"
        PlayerRole.Instance():SetTargetId(nil)

        CurrentEctype = StoryEctype:new(msg,cfg.ectype.EctypeType.STORY)
    elseif msg.id == CurrentEctype.m_EctypeID then
        CurrentEctype:SendReady()
        CurrentEctype:RefreshEctype(msg)
    else
        CurrentEctype:Release()
        CurrentEctype = StoryEctype:new(msg,1)
    end
end

local function onmsg_EnterMultiStoryEctype(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        local ectypeInfo = ConfigManager.getConfigData("ectypebasic",msg.ectypeid)
        local cm_sync = require"character.charactermanager_sync"
        local PlayerRole = require"character.playerrole"
        PlayerRole.Instance():SetTargetId(nil)

        CurrentEctype = StoryEctype:new(msg,2)
    else
        CurrentEctype:SendReady()
    end
end

local function onmsg_EnterTower(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = Tower:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function LeaveEctype(msg)
    if CurrentEctype then
        CurrentEctype:Release()
        CurrentEctype:LeaveEctype(msg)
        CurrentEctype = nil
        ElapsedTime = nil
    end
end

local function NotifySceneLoginLoaded()
    LeaveEctype()
end

local function onmsg_LeaveEctype(msg)
	print("onmsg_LeaveEctype")
    if CurrentEctype then
        if CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.PROLOGUE then
            RoleSkill.RefreshEquipedSkills()
            PlayerRole.Instance():ChangeTalisman(nil)
        end
        if CurrentEctype.m_EctypeType ~= cfg.ectype.EctypeType.STORY then
            leaveInfo = GetEctypeLeaveInfo()
        else
            if enterUI == "ectype.dlgstorydungeonsub" then
                leaveInfo = GetEctypeLeaveInfo()
            end
        end
        LeaveEctype()
    end
end

local function onmsg_GetNearestMonster(msg)
    if CurrentEctype then
        CurrentEctype:DirectingToTheMonster(msg.monsterid)
    end
end

local function onmsg_ActionEnd(msg)
    if CurrentEctype then
        CurrentEctype:RemoveAction(msg.actionid)
    end
end

local function RequestEnterTower(id)
    if not CurrentEctype then
        local re = lx.gs.map.msg.COpenClimbTowerEctype({ectypeid = id})
        network.send(re)
    end
end

local function RequestEnterEctype(ectypeid)
    if not CurrentEctype then
        local re = lx.gs.map.msg.COpenStoryEctype({ectypeid=ectypeid})
        network.send(re)
    end
end

local function RequestEnterDailyEctype(ectypeType)
    local msg=lx.gs.map.msg.COpenDailyEctype({ectypetype=ectypeType})
    network.send(msg)
end

local function RequestEnterTeamCurrency()
    local msg = lx.gs.map.msg.COpenChrisCurEctype({})
    network.send(msg)
end

local function onmsg_ActionBegin(msg)
    if CurrentEctype then
        CurrentEctype:AddAction(msg.actionid)
    end
end

local function onmsg_FindAgentByType(msg)
    if CurrentEctype and msg.errcode==0 then
        CurrentEctype:AddArrowTarget(msg.position)
    end
end

local function onmsg_BuyBuff(msg)
    if CurrentEctype then
        CurrentEctype:BuyBuff(msg)
    end
end

local function onmsg_ScoreChange(msg)
    if CurrentEctype then
        CurrentEctype:ChangeScore(msg.totalscore)
    end
end

local function onmsg_NewFloorOpen(msg)
    if CurrentEctype then
        CurrentEctype:NewFloorOpen(msg.floorid)
    end
end

local function onmsg_EnterDailyEctype(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        local ectype = ConfigManager.getConfigData("ectypebasic",msg.ectypeid)
        if ectype.type == cfg.ectype.EctypeType.CURRENCY_ACTIVITY then
            CurrentEctype = TeamCurrency:new(msg)           
        else
            CurrentEctype = Daily:new(msg)
        end
    else
        CurrentEctype:SendReady()
    end
end

--怪物的波次
local function onmsg_NewMonsterWave(msg)
    if CurrentEctype then
        CurrentEctype:NewMonsterWave(msg.waveindex)
    end
end

local function onmsg_SCurrencyGet(msg)
    if CurrentEctype and ((CurrentEctype.m_EctypeType==cfg.ectype.EctypeType.CURRENCY) or (CurrentEctype.m_EctypeType==cfg.ectype.EctypeType.CURRENCY_ACTIVITY)) then
        CurrentEctype:AddGold(msg.total)
    end
end

local function onmsg_EnterArenaEctype(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = Arena:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function onmsg_SBeginFight(msg)
    if CurrentEctype and CurrentEctype.BeginFight then
        CurrentEctype:BeginFight(msg)
    end
end

local function onmsg_CountDown(msg)
    if CurrentEctype and CurrentEctype.CountDown then
        CurrentEctype:CountDown(msg)
    end
end
--[[
    ����Boss
]]
local function onmsg_EnterPersonalBossEctype(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = PersonalBoss:new(msg)
    else
        CurrentEctype:SendReady()
    end
end
--[[
    ���»���
]]
local function onmsg_SEnterTeamFight(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = TeamFight:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function onmsg_SChangeTeamKillNum(msg)
    if CurrentEctype then
        CurrentEctype:ChangeTeamKillNum(msg)
    end
end

local function onmsg_SKillEvent(msg)
    if CurrentEctype and CurrentEctype.SKillEvent then
        CurrentEctype:SKillEvent(msg)
    end
end

--[[
    Ѫս����
]]

local function onmsg_SEnterGuardTower(msg)
    CharacterManager.ResetCharacterOutDated()
    --printyellow("========================================================================onmsg_SEnterGuardTower")
    if not CurrentEctype then
        CurrentEctype = GuardTower:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

--[[
    ���帱��
]]
local function onmsg_SEnterFamilyTeam(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = FamilyEctype:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function onmsg_SNewWaveOpen(msg)
    if CurrentEctype then
        CurrentEctype:NewMonsterWave(msg.waveindex)
    end
end

--[[
    ����Ӣ��¼
]]
local function onmsg_SEnterHeros(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = HeroBook:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function ommsg_SEctypeStatistic(msg)
    if CurrentEctype then
        CurrentEctype:EctypeStatistic(msg)
    end
end

local function EctypeFinish(msg)
    if CurrentEctype then
        CurrentEctype = nil
    end
end

local function RequestSweepStoryEctype(ectypeid)
    local re = lx.gs.map.msg.CSweepStoryEctype({ectypeid = ectypeid})
    network.send(re)
end

local function CurrentLayoutFinish()
    if CurrentEctype then
        local layoutID = CurrentEctype:GetLayoutID()
        if layoutID then
            local re = map.msg.COpenLayout({layoutid=layoutID})
            network.send(re)
        end
    end
end

local function IsInEctype()
    return CurrentEctype~=nil
end

local function IsInOneEctype(ectypeId)
    return (CurrentEctype~=nil) and (CurrentEctype.m_ID==ectypeId)
end

local function IsInDailyEctype()
    return CurrentEctype~=nil and ((CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.CURRENCY) or (CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.EXP))
end

local function IsInPersonalBoss()
    return CurrentEctype~=nil and CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.PERSONAL_BOSS
end

local function IsInStory()
    if CurrentEctype~=nil and (CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.STORY
    or CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.PERSONAL_BOSS
    or CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.ARENA
    or CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.PROLOGUE) then
        return true
    end
    return false
end

local function Revive()
    if CurrentEctype then
        return CurrentEctype:Revive()
    end
end

local function SendRevive()
    if CurrentEctype then
        CurrentEctype:SendRevive()
    end
end

local function GetPrologueLayoutIds()
    if CurrentEctype then
        if CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.PROLOGUE
        or CurrentEctype.m_EctypeType == cfg.ectype.EctypeType.STORY then
            return CurrentEctype:GetLayoutIds()
        end
    end
end



local function Dead()
    if CurrentEctype then
        local revivefunction = CurrentEctype:GetReviveFunction() -- 0 ���� 1 ����ʱ 2 ������
        if revivefunction == 0 then
            if CurrentEctype:CanRevive() then
                uimanager.show("ectype.dlgectype_revive",CurrentEctype:ReviveMsg())
            end
        elseif revivefunction == 1 then
            if CurrentEctype:CanRevive() then
                uimanager.show("ectype.dlgtower_revive",CurrentEctype:ReviveMsg())
            end
        end
    end
end

local function onmsg_SReady(msg)
    if CurrentEctype and CurrentEctype.OnMsgSReady then
        CurrentEctype:OnMsgSReady(msg)
        CharacterManager.ClearInvalidCharacter()
        --CharacterManager.ResetCharacterOutDated()
    end
end

local function onmsg_ApplyTeamSpeedSucc(msg)
    -- ChangeTeamSpeedSigned(true)
    if uimanager.isshow("arena.multi.speed.tabarenamultispeed") then
        uimanager.refresh("arena.multi.speed.tabarenamultispeed")
        uimanager.ShowSingleAlertDlg({content=LocalString.EctypeText.ApplySucc})
    end
    local DlgUIMain = require "ui.dlguimain"
    local params = {}
    params.matching = bSignTeamSpeed
    params.matchmode = "teamspeed"
    DlgUIMain.SetMatching(params)
end

local function onmsg_CancelApply(msg)
    -- ChangeTeamSpeedSigned(false)
    if uimanager.isshow("arena.multi.speed.tabarenamultispeed") then
        uimanager.refresh("arena.multi.speed.tabarenamultispeed")
    end
    local DlgUIMain = require "ui.dlguimain"
    local params = {}
    params.matching = bSignTeamSpeed
    params.matchmode = "teamspeed"
    DlgUIMain.SetMatching(params)
end

local function onmsg_EnterTeamSpeed(msg)
    CharacterManager.ResetCharacterOutDated()

    if not CurrentEctype then
        CurrentEctype = TeamSpeed:new(msg)
    else
        CurrentEctype:SendReady()
    end
    local DlgUIMain = require "ui.dlguimain"
    local params = {}
    params.matching = false
    params.matchmode = "teamspeed"
    DlgUIMain.SetMatching(params)
end

local function onmsg_SyncTeamSpeedScore(msg)
    if CurrentEctype then
        CurrentEctype:SyncTeamScore(msg)
    end
end

local function onmsg_SyncTeamSpeedDamager(msg)
    if CurrentEctype then
        CurrentEctype:SyncTeamDmg(msg)
    end
end

local function onmsg_BeginMatchTeamSpeed(msg)
    if msg.errcode>0 then
        local errMgr =  require"assistant.errormanager"
        uimanager.ShowSingleAlertDlg{content=(errMgr.GetErrorText(msg.errcode) or LocalString.EctypeText.ErrUnKnown)}
        TeamSpeedManager.OnSigned(false)
    else
        uimanager.ShowSingleAlertDlg{content=LocalString.EctypeText.ApplySucc}
        TeamSpeedManager.OnSigned(true)
    end
end

local function onmsg_CancelMatchTeamSpeed(msg)
    --if msg.errcode>0 then
    --    local errMgr =  require"assistant.errormanager"
    --    uimanager.ShowSingleAlertDlg{content=(errMgr.GetErrorText(msg.errcode) or LocalString.EctypeText.ErrUnKnown)}
    --else
        TeamSpeedManager.OnSigned(false)
    --end
end

local function onmsg_MatchTeamSpeedSucc(msg)
    TeamSpeedManager.OnSigned(false)

    local RoleInfo = require("ui.arena.multi.pvp.roleinfo")

    local friendlyRoleList = {}
    local enemyRoleList = {}

    for i, msgRoleInfo in pairs(msg.team1.members) do
        tinsert( friendlyRoleList, RoleInfo:new(msgRoleInfo) )
    end

    for i, msgRoleInfo in pairs(msg.team2.members) do
        tinsert( enemyRoleList, RoleInfo:new(msgRoleInfo) )
    end

    uimanager.showdialog("arena.multi.pvp.dlgarenamultipvpmatching",
                        {friendlyList   = friendlyRoleList,
                         enemyList      = enemyRoleList,
                         remainingTime  = msg.countdown})

    local dlgUIMain = require("ui.dlguimain")
    dlgUIMain.SetMatching({matching = false, matchmode="teamspeed"})
end

local function SetAirWallActive(active)
    local airwallroot = UnityEngine.GameObject.Find("airwalls")
    if airwallroot ~= nil then
        airwallroot:SetActive(active)
    end
end

--tournament
local function on_SEnterHuiWu(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = Tournament:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

-- attackcity
local function onmsg_SEnterAttackCity(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = AttackCity:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function onmsg_SEnterMMEctype(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = MaiMai:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function OnEndEctype(msg)
	
    if CurrentEctype then
        CurrentEctype:Release()
        EndEctype(msg)
		uimanager.call("dlguimain","SwitchAutoFight",false)
    end
end

local function onmsg_EndPlainStoryEctype(msg)
    if CurrentEctype then
        OnEndEctype(msg)
    end
end


local function CurrentEctypeId()
    if CurrentEctype then
        return CurrentEctype.m_EctypeID
    else
        return 0
    end
end

-- prologue
local function onmsg_SEnterPrologue(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = StoryEctype:new(msg)
    elseif CurrentEctype.m_EctypeID == msg.id then
        CurrentEctype:SendReady()
    else
        CurrentEctype:Release()
        CurrentEctype = StoryEctype:new(msg)
    end
end

local function onmsg_SEndPrologue(msg)
    local PrologueManager = require"prologue.prologuemanager"

    if msg.errcode ~= 0 then
        CurrentEctype:Release()
        CurrentEctype:LeaveEctype(msg)
        CurrentEctype = nil
        ElapsedTime = nil
    else
        OnEndEctype(msg)
    end
    PrologueManager.onmsg_SEndPrologue(msg)
end

local function onmsg_SEnterWorldMap()
    EctypeOthersManager.HideUI()
end
local function onmsg_SChangeMatch(msg)
    local DlgUIMain = require "ui.dlguimain"
	local params = {}
    if msg.matchtype == cfg.ectype.MatchType.GUARD_TOWER then
		params.matching = true
		params.callback = function() uimanager.showorrefresh("ectype.guardtower.dlgguardtower_matching") end
		DlgUIMain.SetMatching(params)
    elseif msg.matchtype == cfg.ectype.MatchType.TEAM_FIGHT then
        DlgUIMain.SetMatching({matching = true, matchmode = "teamfight"})
    elseif msg.matchtype == cfg.ectype.MatchType.MULTI_STORY then
	    DlgUIMain.SetMatching({matching = true, matchmode = "multistory"})
	else
		params.matching = false
        DlgUIMain.SetMatching(params)
    end
end

local function RequestSweepTower(ectypeid)
    network.send(lx.gs.map.msg.CSweepClimbTower{ectypeid=ectypeid})
end

local function onmsg_SEnterFamilyCityWar(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = FamilyCastle:new(msg)
    elseif CurrentEctype.m_EctypeID == msg.id then
        CurrentEctype:SendReady()
    else
        CurrentEctype:Release()
        CurrentEctype = FamilyCastle:new(msg)
    end
end

--约战的协议需要修改
local function onmsg_SFamilyWarScore(msg)
    -- if CurrentEctype then
    --     CurrentEctype:OnScore(msg)
    -- end
    if uimanager.isshow("ectype.dlgfamilyui") then
        uimanager.call("ectype.dlgfamilyui","OnScore",msg)
    end
end

local function onmsg_SFamilyCityWarScore(msg)
     if CurrentEctype then
         CurrentEctype:OnScore(msg)
     end
    if uimanager.isshow("ectype.dlgfamilywarui") then
        uimanager.call("ectype.dlgfamilywarui","OnScore",msg)
    end
end

local function onmsg_SEnterHeroNormal(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = HeroChallenge:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function onmsg_SEnterHeroCommmon(msg)
    CharacterManager.ResetCharacterOutDated()
    if not CurrentEctype then
        CurrentEctype = HeroChallenge:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function onmsg_SEndHeroTask(msg)
    if CurrentEctype then
        EndEctype(msg)
    end
end

local function onmsg_SweepTower(msg)
    if uimanager.isshow("ectype.tabtower") then
        uimanager.call("ectype.tabtower","OnSweep",msg)
    end
end

local function onmsg_SDeadCount(msg)
    if CurrentEctype then
        CurrentEctype:DeadCount(msg.count)
    end
end

local function onmsg_EnterFamilyWar(msg)
    if not CurrentEctype then
        CurrentEctype = FamilyWar:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function onmsg_FamilyWarStatus(msg)
    if CurrentEctype then
        CurrentEctype:OnWarStatus(msg)
    end
end

local function onmsg_SEnterFamilyRound(msg)
    if not CurrentEctype then
        CurrentEctype = FamilyRoundRobin:new(msg)
    else
        CurrentEctype:SendReady()
    end
end

local function onmsg_SEndFamilyRoundMatch(msg)
    if CurrentEctype then
        EndEctype(msg)
    end
end

local function onmsg_SNearbyPlayerEnter(msg)
    if CurrentEctype and CurrentEctype.m_ApertureManager then
        CurrentEctype.m_ApertureManager:Add(msg.roleid, msg.fightercommon.camp)
    end
end

local function onmsg_SNearbyPetEnter(msg)
    if CurrentEctype and CurrentEctype.m_ApertureManager then
        CurrentEctype.m_ApertureManager:Add(msg.roleid, msg.fightercommon.camp)
    end
end

local function onmsg_SNearbyAgentLeave(msg)
    if CurrentEctype and CurrentEctype.m_ApertureManager then
        CurrentEctype.m_ApertureManager:Remove(msg.roleid)
    end
end

local function Release()
	EctypesInfo = nil
	CurrentEctype = nil
	CurrentTower = nil
	Characters = {}
	lateTime = nil
	StarInfo = nil
	ElapsedTime = nil
	msgEnd = nil
	bSignTeamSpeed = false
end

local function OnLogout()
    if CurrentEctype then
        LeaveEctype()
    end
    TeamSpeedManager.OnSigned(false)
	Release()
end

local function second_update()
    --TeamSpeedManager.second_update()
    if CurrentEctype then
        CurrentEctype:second_update()
    end
end


--�жϸ���������
local ectype_protocols = {


     --manager
    { "lx.gs.map.msg.SChangeClimbTower",onmsg_ChangeClimbTower},
    --story
    { "map.msg.SEnterStoryEctype",onmsg_EnterEctype},
    { "lx.gs.map.msg.SLeaveMap",onmsg_LeaveEctype},
    { "map.msg.SOpenLayout",onmsg_OpenLayout},
    { "map.msg.SCloseLayout",onmsg_CloseLayout},
    { "map.msg.SChangeEntry",onmsg_ChangeEntry},
    { "map.msg.SChangeExit",onmsg_ChangeExit},
    { "map.msg.SChangeEnviroment",onmsg_ChangeEnviroment},
    { "map.msg.SCompleteLayout",onmsg_CompleteLayout},
    { "map.msg.SActionBegin",onmsg_ActionBegin},
    { "map.msg.SActionEnd", onmsg_ActionEnd},
    { "map.msg.SFindAgentByType",onmsg_FindAgentByType},
    { "map.msg.SEndStoryEctype",OnEndEctype},

    --tower
    { "map.msg.SEnterClimbTower",onmsg_EnterTower},
    { "map.msg.SBuyBuff",onmsg_BuyBuff},
    { "map.msg.SScoreChange",onmsg_ScoreChange},
    { "map.msg.SNewFloorOpen",onmsg_NewFloorOpen},
    { "map.msg.SEndClimbTowerEctype",OnEndEctype},

    -- daily
    { "map.msg.SEnterDailyEctype",onmsg_EnterDailyEctype},
    { "map.msg.SNewMonsterWave",onmsg_NewMonsterWave},
    { "map.msg.SCurrencyGet",onmsg_SCurrencyGet},
    { "map.msg.SEndDailyEctype",OnEndEctype},
    --personalboss
    { "map.msg.SEnterPersonalBossEctype",onmsg_EnterPersonalBossEctype},
    { "map.msg.SEndPersonalBossEctype",OnEndEctype},
    --arena
    { "map.msg.SEnterArenaEctype",onmsg_EnterArenaEctype},
    { "map.msg.SEndArenaEctype",OnEndEctype},


    --teamfight
    { "map.msg.SEnterTeamFight", onmsg_SEnterTeamFight},
    { "map.msg.SChangeTeamKillNum", onmsg_SChangeTeamKillNum},
    { "map.msg.SEndTeamFight", OnEndEctype},
    { "map.msg.SKillEvent", onmsg_SKillEvent },
   -- { ""}
    --herobook
    { "map.msg.SEnterHeroes", onmsg_SEnterHeros},
    { "map.msg.SEndHeroes", OnEndEctype},

    --family ectype
    { "map.msg.SEnterFamilyTeam", onmsg_SEnterFamilyTeam},
    { "map.msg.SNewWaveOpen", onmsg_SNewWaveOpen},
    { "map.msg.SEndFamilyTeam", OnEndEctype},


  --  { "lx.gs.map.msg.SHeroRefreshAward", onmsg_SHeroRefreshAward},
 --   { "map.msg.MEndHeroes"}

    { "map.msg.SEnterMultiStoryEctype",onmsg_EnterMultiStoryEctype},
    { "map.msg.SEndMultiStoryEctype",OnEndEctype},

    { "map.msg.SReady",onmsg_SReady},
    { "map.msg.SCountDown",onmsg_CountDown},
    { "map.msg.SBeginFight",onmsg_SBeginFight},

    { "map.msg.SEctypeStatistic", ommsg_SEctypeStatistic},

     --guardtower
    { "map.msg.SEnterGuardTower", onmsg_SEnterGuardTower},
    { "map.msg.SEndGuardTower", OnEndEctype},


    -- team speed
    { "lx.gs.map.msg.SApplyTeamSpeedSucc",onmsg_ApplyTeamSpeedSucc},
    { "lx.gs.map.msg.SCancelTeamSpeedApply",onmsg_CancelMatchTeamSpeed},
    --{ "lx.gs.map.msg.SCancelTeamSpeedApply",onmsg_CancelApply},
    { "map.msg.SEnterTeamSpeed",onmsg_EnterTeamSpeed},
    { "map.msg.SEndTeamSpeed",OnEndEctype},
    { "map.msg.SSyncTeamSpeedScore",onmsg_SyncTeamSpeedScore},
    { "map.msg.SSyncTeamSpeedBossDamage",onmsg_SyncTeamSpeedDamager},
    { "lx.gs.map.msg.SBeginMatchTeamSpeed",onmsg_BeginMatchTeamSpeed},
    { "lx.gs.map.msg.SMatchTeamSpeedSucc",onmsg_MatchTeamSpeedSucc},
    --{ "lx.gs.map.msg.SCancelMatchTeamSpeed", onmsg_CancelMatchTeamSpeed},

    --tournament
    {"map.msg.SEnterHuiWu",on_SEnterHuiWu},
    {"map.msg.SEndHuiWu",OnEndEctype},

    -- attackcity
    {"map.msg.SEnterAttackCity",onmsg_SEnterAttackCity},
    {"map.msg.SEndAttackCity",OnEndEctype},

    -- prologue
    {"map.msg.SEnterPrologue",onmsg_EnterEctype},
    {"map.msg.SEndPrologue",onmsg_SEndPrologue},

    { "lx.gs.map.msg.SChangeMatch",                 onmsg_SChangeMatch               },

    {"map.msg.SEnterPlainStoryEctype",onmsg_EnterEctype},
    {"map.msg.SEndPlainStoryEctype",onmsg_EndPlainStoryEctype},

    {"lx.gs.map.msg.SSweepClimbTower",onmsg_SweepTower},

    {"map.msg.SDeadCount",onmsg_SDeadCount},
    {"map.msg.SEnterMMEctype",onmsg_SEnterMMEctype},
    {"map.msg.SEndMMEctype",OnEndEctype},
    --
    { "map.msg.SEnterWorld",  onmsg_SEnterWorldMap                },

    { "map.msg.SEnterFamilyWar",        onmsg_EnterFamilyWar},
    { "map.msg.SEndFamilyWar",          OnEndEctype},
    { "map.msg.SFamilyWarStatus",       onmsg_FamilyWarStatus},
    
    -- familyroundrobin
    { "map.msg.SEnterFamilyRound",onmsg_SEnterFamilyRound},
    { "map.msg.SEndFamilyRoundMatch",onmsg_SEndFamilyRoundMatch},

    -- family city

    { "map.msg.SEnterFamilyCityWar",    onmsg_SEnterFamilyCityWar},
    { "map.msg.SFamilyCityWarScore",    onmsg_SFamilyCityWarScore},
    { "map.msg.SEndFamilyCityWar",      OnEndEctype},

    --hero challenge
    {"map.msg.SEnterHeroNormal", onmsg_SEnterHeroNormal},
    {"map.msg.SEnterHeroCommmon", onmsg_SEnterHeroCommmon},
    {"map.msg.SEndHeroTask",onmsg_SEndHeroTask},

    { "map.msg.SNearbyPlayerEnter",   onmsg_SNearbyPlayerEnter    },
    { "map.msg.SNearbyAgentLeave",    onmsg_SNearbyAgentLeave     },
    { "map.msg.SNearbyPetEnter",      onmsg_SNearbyPetEnter       },
    { "map.msg.SFamilyWarScore",      onmsg_SFamilyWarScore,      },
}


local function Init()
    CurrentEctype = nil
	leaveInfo = nil
    gameevent.evt_update:add(Update)
    gameevent.evt_late_update:add(late_update)
	gameevent.evt_system_message:add("logout", OnLogout)
    gameevent.evt_second_update:add(second_update)
--    TeamSpeedManager.Init()
    network.add_listeners(ectype_protocols,"ectypemanager")
end


return {
    init = Init,
    RequestEnterEctype          = RequestEnterEctype,
    RequestSweepTower           = RequestSweepTower,
    CheckPosition               = CheckPosition,
    RequestLeaveEctype          = RequestLeaveEctype,
    IsInEctype                  = IsInEctype,
    GetEctype                   = GetEctype,
    CurrentEctypeId             = CurrentEctypeId,
    IsInOneEctype               = IsInOneEctype,
    RequestEnterDailyEctype     = RequestEnterDailyEctype,
    RequestEnterTeamCurrency    = RequestEnterTeamCurrency,
    RequestEnterTower           = RequestEnterTower,
    RequestSweepStoryEctype     = RequestSweepStoryEctype,
    Revive                      = Revive,
    SendRevive                  = SendRevive,
    Dead                        = Dead,
    IsInDailyEctype             = IsInDailyEctype,
    IsInStory                   = IsInStory,
    IsInPersonalBoss            = IsInPersonalBoss,
    ShowTasks                   = ShowTasks,
    IsFinished                  = IsFinished,
    SetAirWallActive            = SetAirWallActive,
    LeaveEctype                 = LeaveEctype,
    FuncEnd                     = FuncEnd,
    NotifySceneLoginLoaded      = NotifySceneLoginLoaded,
	  GetEctypeTypeById         = GetEctypeTypeById,
	  CanReceiveInviteMessage   = CanReceiveInviteMessage,
	  SendScroll               	= SendScroll,
	  OnLeave					= OnLeave,
    BackUpEnterUI               = BackUpEnterUI,
    GetPrologueLayoutIds        = GetPrologueLayoutIds,
    IsBattleEctype              = IsBattleEctype,
    RoleEnterEctype             = RoleEnterEctype,
}