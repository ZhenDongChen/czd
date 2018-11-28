local NetWork = require("network")
local UIManager = require("uimanager")
local ConfigManager = require("cfg.configmanager")
local CharacterManager = require("character.charactermanager")
local HeroChallengeManager
local PlayerRole
local MathUtils = require("common.mathutils")
local Utils = require("common.utils")
local GameEvent = gameevent
local Format = string.format
local Math = math

local ResetTime = cfg.team.team.ReFollowTime
local ADJUSTFREQTIMES = 3  --获取队长位置相同次数
local BIG_RESETTIME = 1.5    --获取队长位置时间间隔

local m_Team
local m_FollowTarget = nil
local m_FollowResetTime = ResetTime
local m_FollowDistance = cfg.team.team.FollowDistance
local m_InviteList = {}
local m_ApplyList = {}
local m_FirstHeroFollow = false
local m_Times = 0


local function RefreshDlg()
    if UIManager.isshow("team.tabteam") then
        local TabTeam = require("ui.team.tabteam")
        TabTeam.OnMsg_LoadTeamInfo()
    end
    if UIManager.isshow("dlguimain") then
        local DlgUIMain_Team = require("ui.dlguimain_team")
        DlgUIMain_Team.RefreshTeamInfo()        
    end
end

local function ClearDlgApplyInfo()
    local InfoManager = require("assistant.infomanager")
    for id,infoId in pairs(m_ApplyList) do
        InfoManager.DelNormalInfo(infoId)
    end
end

local function OnTeamMemChange(roleId,isJoin)
    if roleId and roleId ~= PlayerRole:Instance():GetId() then
        local char = CharacterManager.GetCharacter(roleId)
        if char then
            char:OnTeamChanged(isJoin)
        end
    end
end

local function OnTeamAnyChange()
    if UIManager.isshow("activity.maimai.tabmaimaiectype") then
        UIManager.call("activity.maimai.tabmaimaiectype","refresh")
    end
end

local function SendGetPlayerLocation(id, type)
    local followType = type or 0
    local message = lx.gs.map.msg.CGetPlayerLocation({roleid = id, positiontype = followType})
    NetWork.send(message)
end

local function SendGetLeaderLocation()
    local EctypeManager = require("ectype.ectypemanager")
    if EctypeManager.IsInEctype() then
        return
    end
    local leaderId = m_Team.leaderid
    SendGetPlayerLocation(leaderId)
end

local function SendUnFollowLeader(teamid)
    local message = lx.gs.team.msg.CUnFollowLeader({teamid = teamid})
    NetWork.send(message)
end

local function SendCBreakUpTeam()
    if m_Team and m_Team.leaderid == PlayerRole:Instance():GetId() then
        local message = lx.gs.team.msg.CBreakupTeam({})
        NetWork.send(message) 
    end
end

local function SendFollowLeader(teamId)
    local message = lx.gs.team.msg.CFollowLeader({teamid = teamId})
    NetWork.send(message)
end

local function SendMoveToLeader(mapId,pos)
    local message = lx.gs.team.msg.CMoveToLeader({worldid = mapId,position = pos})
    NetWork.send(message)
end

local function SetAutoFollow()
    --自动跟随
    PlayerRole:Instance().m_Follow = true
    m_FollowResetTime = ResetTime 
    SendGetPlayerLocation(m_Team.leaderid,0)
end

local function SetFollowState()
    if m_Team.leaderid ~= PlayerRole:Instance():GetId() then
        for _,member in pairs(m_Team.members) do
            if member.roleid == PlayerRole:Instance():GetId() then
                member.follow = 1
                RefreshDlg()
                break
            end
        end
        --自动跟随
        SetAutoFollow()   
        if UIManager.isshow("dlguimain") then
            local DlgUIMain_Combat = require("ui.dlguimain_combat")
            if DlgUIMain_Combat.IsAutoFight() == true then
                DlgUIMain_Combat.SwitchAutoFight(false)
                UIManager.ShowSystemFlyText(LocalString.Team_InterruptAutoFight)
            end
        end   
    end
end

local function CancelFollowing()
    PlayerRole:Instance():CancelFollowing()
    if m_Team and m_Team.teamid then
        SendUnFollowLeader(m_Team.teamid)
    end
end

local function RequestCancelFollowing(immediate)
    if PlayerRole:Instance():IsFollowing() and m_Team then
        if immediate == true then
            CancelFollowing()
            UIManager.ShowSystemFlyText(LocalString.Team_InterruptAutoFollow)
        else
            if not (UIManager.isshow("dlgalert.dlgalert_reminderimportant") or UIManager.isshow("dlgalert.dlgalert_reminder")) then
				if PlayerRole:Instance():IsFollowing() then
					
					UIManager.show("dlgalert_reminderimportant",{immediate = true,content = LocalString.Team_IsUnFollow,
						callBackFunc = function()
							CancelFollowing()
						end,

					})
--[[					UIManager.ShowAlertDlg({immediate = true,content = LocalString.Team_IsUnFollow,
						callBackFunc = function()
						CancelFollowing()
						
					end,})
					--]]
--[[				UIManager.ShowAlertDlg({
				immediate = true,content = LocalString.Team_IsUnFollow,			
                callBackFunc    = function()

                end,
                callBackFunc1 = function()
					CancelFollowing()
                end,})--]]
				end
            end
        end
    end
end

local function OnMsg_SInitTeam(msg)
    gTeamManagerListState.autoAcceptInvite = msg.roleteaminfo.autoacceptinvite
    gTeamManagerListState.autoAcceptRequest = msg.roleteaminfo.autoacceptrequest
    if (msg.team) and msg.team.teamid ~= 0 then
        m_Team = msg.team
    else
        m_Team = nil
    end
    RefreshDlg()
    OnTeamAnyChange()
end

local function OnMsg_SSyncTeam(msg)
    m_Team = msg.team
    RefreshDlg()
    if m_Team and m_Team.members then
        for _,member in pairs(m_Team.members) do
            OnTeamMemChange(member.roleid,true) 
        end    
    end     
    OnTeamAnyChange()
end

--解散队伍处理函数
local function BreakupTeamHandle()
    if PlayerRole:Instance():IsFollowing() == true then
        PlayerRole:Instance():CancelFollowing()
    end
    m_Team = nil
    RefreshDlg()    
    ClearDlgApplyInfo()
    OnTeamAnyChange()
end

local function OnMsg_SBreakupTeam(msg)
    BreakupTeamHandle()
end

local function OnMsg_SBreakupTeamNotify(msg)
    BreakupTeamHandle()
end

local function SendAcceptInvite(roleId)          
    local message = lx.gs.team.msg.CAcceptInvite({inviteroleid = roleId})
    NetWork.send(message)
    m_InviteList[roleId] = nil
end

local function OnMsg_SInviteJoinTeam(msg)
    --邀请提示
    local roleName = msg.rolename
    local content = ""
   content = Format(LocalString.Team_InvitedJoinTeamNotify,PlayerRole:Instance():GetName(),roleName)
    if m_InviteList[msg.roleid] == nil then        
        local infoId = UIManager.ShowAlertDlg({content = content,callBackFunc = function()
            SendAcceptInvite(msg.roleid)
        end,
        callBackFunc1 = function()
            m_InviteList[msg.roleid] = nil
        end,
        sureText = LocalString.Team_Accept,cancelText = LocalString.Team_Reject})
        if infoId and infoId > 0 then
            UIManager.ShowSystemFlyText(content)
        end
    else
        UIManager.ShowSystemFlyText(content)
    end
    m_InviteList[msg.roleid] = true
    OnTeamAnyChange()
end

local function QuitOrKickedOutTeamHandle()
    if PlayerRole:Instance():IsFollowing() == true then
        PlayerRole:Instance():CancelFollowing()
    end
    local memberList = {}
    if m_Team and m_Team.members then
        for _,member in pairs(m_Team.members) do
            table.insert(memberList,member.roleid)
        end
    end
    m_Team = nil
    for _,id in pairs(memberList) do
        OnTeamMemChange(id,false) 
    end 
    RefreshDlg()
    ClearDlgApplyInfo()
end

local function OnMsg_SQuitTeam(msg)
    --退出队伍提示  Dlg_Flytext
    if msg.memberid ~= PlayerRole:Instance():GetId() then
        local content = ""
        if m_Team and m_Team.members[msg.memberid] then
            local roleName = ""
            roleName = m_Team.members[msg.memberid].roleinfo.name
            if m_Team.leaderid == msg.memberid then
                content = Format(LocalString.Team_LeaderQuitTeamNotify,roleName)
            else
                content = Format(LocalString.Team_NormalPlayerQuitTeamNotify,roleName)               
            end   
            m_Team.members[msg.memberid] = nil    
            RefreshDlg()
            UIManager.ShowSystemFlyText(content)
            OnTeamMemChange(msg.memberid,false)     
        end        
    else
        QuitOrKickedOutTeamHandle()
    end
    OnTeamAnyChange()
end

local function OnMsg_SFollowLeader(msg)
    if msg.result == lx.gs.team.msg.SFollowLeader.RES_OK then
        SetFollowState()
    end
end

local function OnMsg_SFollowTeamMemberNotify(msg)
    for _,member in pairs(m_Team.members) do
        if member.roleid == msg.followmemberid then
            member.follow = 1
            RefreshDlg()
            break
        end
    end
end

--申请加入队伍通知
local function OnMsg_SRequestJoinTeam(msg)   
    local roleName = msg.requestrole.name
    local content = Format(LocalString.Team_ApplyJoinTeamNotify,roleName)
    if m_ApplyList[msg.requestrole.roleid] == nil then
        local infoId = UIManager.ShowAlertDlg({content = content,callBackFunc = function()
            local message = lx.gs.team.msg.CAgreeJoin({roleid = msg.requestrole.roleid})
            NetWork.send(message)
            m_ApplyList[msg.requestrole.roleid] = nil
        end,
        callBackFunc1 = function()
            m_ApplyList[msg.requestrole.roleid] = nil
        end,
        sureText = LocalString.Team_Accept,cancelText = LocalString.Team_Reject})
        if infoId and infoId > 0 then
            m_ApplyList[msg.requestrole.roleid] = infoId
            UIManager.ShowSystemFlyText(content)
        end
    else
        UIManager.ShowSystemFlyText(content)
    end
    OnTeamAnyChange()
end

local function OnMsg_FindTeams(msg)
    if UIManager.isshow("team.tabothers") then
        UIManager.call("team.tabothers","RefreshNormalTeams",msg)
    end
end

local function OnMsg_FindPlayers(msg)
    if UIManager.isshow("team.tabothers") then
        UIManager.call("team.tabothers","RefreshPlayers",msg)
    end 
end

local function GetNewLeaderName(id)
    local name = ""
    for _,member in pairs(m_Team.members) do
        if member.roleid == id then
            name = member.roleinfo.name
            break
        end
    end
    return name
end

--转移队长通知
local function OnMsg_STransferLeader(msg)
    if m_Team then
        m_Team.leaderid = msg.newleaderid
        RefreshDlg()
        local content = ""
        if msg.newleaderid == PlayerRole:Instance():GetId() then
            content = LocalString.Team_TransferLeaderNotify
        else
            local newLeaderName = GetNewLeaderName(msg.newleaderid)
            content = Format(LocalString.Team_TransferLeaderNotifyOthers,newLeaderName)
        end
        if PlayerRole:Instance():IsFollowing() == true then
            PlayerRole:Instance():CancelFollowing()
        end
        UIManager.ShowSystemFlyText(content)
    end
    OnTeamAnyChange()
end

local function OnMsg_SInviteFollowNotify(msg)
    local roleName = PlayerRole:Instance().m_Name
    local leaderName = msg.leader.roleinfo.name
    local content = Format(LocalString.Team_InviteFollowNotify,roleName,leaderName)
    UIManager.ShowAlertDlg({content = content,callBackFunc = function()         
            SendFollowLeader(m_Team.teamid)
        end,sureText = LocalString.Team_Accept,cancelText=LocalString.Team_Reject})
end

local function OnMsg_SUnFollowTeamMemberNotify(msg)
    for _,memberInfo in pairs(m_Team.members) do
        if memberInfo.roleid == msg.memberid then
            memberInfo.follow = 0
            RefreshDlg()
            break
        end
    end
end

local function OnMsg_SUnFollowLeader(msg)
    if msg.teamid == m_Team.teamid then
        for _,memberInfo in pairs(m_Team.members) do
            if memberInfo.roleid == PlayerRole:Instance():GetId() then
                memberInfo.follow = 0
				PlayerRole:Instance():StopNavigate()
				PlayerRole:Instance().m_Follow = false
                RefreshDlg()
                break
            end
        end
    end
end

local function OnMsg_SJoinTeamNotify(msg)
    local content = ""
    if msg.member.roleid == PlayerRole:Instance():GetId() then
        content=LocalString.Team_SelfJoinTeamNotify
    else
        local roleName = msg.member.roleinfo.name
        content=Format(LocalString.Team_JoinTeamNotify,roleName)
    end
    UIManager.ShowSystemFlyText(content)
    m_Team.members[msg.member.roleid] = msg.member
    OnTeamMemChange(msg.member.roleid,true)
    RefreshDlg()
    OnTeamAnyChange()
end

local function OnMsg_SSetAutoSetting(msg)
	
	
    if msg.opttype == lx.gs.team.msg.CSetAutoSetting.AUTO_ACCEPT_INVITE then
		printyellow("TeamManager.ListState.autoAcceptInvite: "..tostring(msg.cfgvalue) )
        gTeamManagerListState.autoAcceptInvite = msg.cfgvalue
    elseif msg.opttype == lx.gs.team.msg.CSetAutoSetting.AUTO_ACCEPT_REQUEST then
		printyellow("TeamManager.ListState.autoAcceptRequest: "..tostring(msg.cfgvalue) )
        gTeamManagerListState.autoAcceptRequest = msg.cfgvalue
    end
end

local function OnMsg_SKickoutMember(msg)
    if msg.memberid == PlayerRole:Instance():GetId() then             
        QuitOrKickedOutTeamHandle()
        UIManager.ShowSystemFlyText(LocalString.Team_KickedOut)
    else
        if m_Team.members[msg.memberid] then
            local name = m_Team.members[msg.memberid].roleinfo.name
            UIManager.ShowSystemFlyText(Format(LocalString.Team_KickedOutNotify,name))
        end
        m_Team.members[msg.memberid] = nil
        RefreshDlg()
        OnTeamMemChange(msg.memberid,false)
    end
    OnTeamAnyChange()
end

local function GetTeamInfo()
    return m_Team
end

local function IsTeamMate(roleId)
    local isMate=false
    if m_Team and roleId ~= PlayerRole:Instance():GetId() then
        for _,member in pairs(m_Team.members) do
            if member.roleid == roleId then
                isMate = true
                break
            end
        end
    end
    return isMate
end

local function IsInTeam()
    return m_Team ~= nil
end

local function IsLeader(id)
    local isLeader = false
    if m_Team then
        if m_Team.leaderid == id then
            isLeader=true
        end
    end
    return isLeader
end

local function SendCreateTeam()
    local message = lx.gs.team.msg.CCreateTeam()
    NetWork.send(message)
end

local function SendInviteJoinTeam(id)
    if IsTeamMate(id) ~= true then
        local message = lx.gs.team.msg.CInviteJoinTeam({roleid = id})
        NetWork.send(message)
    end
end

local function SendInviteFollow(roleId)
    local message = lx.gs.team.msg.CInviteFollow( { roleid = roleId })
    NetWork.send(message)
end

local function SendQuitTeam()
    local message = lx.gs.team.msg.CQuitTeam( { })
    NetWork.send(message)
end

local function SendKickOut(id)
    local message = lx.gs.team.msg.CKickoutMember({memberid = id})
    NetWork.send(message)
end

local function SendTransferLeader(memberId)
    local message = lx.gs.team.msg.CTransferLeader({memberid = memberId})
    NetWork.send(message)
end

local function SendFindNearByTeam()
    local msg = map.msg.CFindNearbyTeam({})
    NetWork.send(msg)
end

local function SendFindNearByRole()
    local message = map.msg.CFindNearbyRole({})
    NetWork.send(message)
end

local function SendAutoSetting(type,value)
    local message = lx.gs.team.msg.CSetAutoSetting({opttype = type,cfgvalue = value})
    NetWork.send(message)
end

local function SendRequestJoinTeam(teamId)
    local message = lx.gs.team.msg.CRequestJoinTeam({teamid = teamId})
    NetWork.send(message)
end

local function update()
    if not PlayerRole:Instance():IsFollowing() then
        return
    end
    m_FollowResetTime = m_FollowResetTime - Time.deltaTime
    if m_FollowResetTime < 0 then
        if m_Times >= ADJUSTFREQTIMES then
            m_FollowResetTime = BIG_RESETTIME
        else
            m_FollowResetTime = ResetTime
        end
        SendGetLeaderLocation()
    end
end

local function SetFollowTarget(msg)
    m_FollowTarget = {}
    m_FollowTarget.mapType = msg.maptype
    m_FollowTarget.mapId = msg.worldid
    m_FollowTarget.lineId = msg.lineid
    m_FollowTarget.position = msg.position
end

local function OnMsg_SInviteFollow(msg)
    if msg.result == 0 then
        UIManager.ShowSystemFlyText(LocalString.Team_AlreadySendInviteFollow)
    end
end

local function IsNeedReNavigate(msg)
    local lineId
    lineId = PlayerRole:Instance():GetLineId()
	--(or PlayerRole:Instance():IsFlyNavigating())
    if PlayerRole:Instance():IsNavigating()  or ((PlayerRole:Instance():GetMapId() == msg.worldid) and (lineId == msg.lineid) and (MathUtils.DistanceOfXoY(PlayerRole:Instance():GetRefPos(),msg.position) <= m_FollowDistance)) then
        return false
    end
    return true
end

local function OnMsg_SGetPlayerLocation(msg)   
    if msg.roleid ~= PlayerRole:Instance():GetId() then
        if UIManager.isshow("map.tabarea") then
            UIManager.call("map.tabarea","RefreshTeamMemberLocation",{info = msg})
            if not (PlayerRole:Instance():IsFollowing() == true) then
                return
            end           
        end
        if m_FirstHeroFollow == true then
            m_FirstHeroFollow = false
            SendMoveToLeader(msg.worldid,msg.position)
        end
    end 
    if m_FollowTarget == nil then
        SetFollowTarget(msg)
    else
        --判断当前导航目的地址是否与新的地址一样
        if((m_FollowTarget.mapType == msg.maptype) and (m_FollowTarget.mapId == msg.worldid) and (m_FollowTarget.lineId == msg.lineid) and (MathUtils.DistanceOfXoY(m_FollowTarget.position,msg.position) <= m_FollowDistance)) then
            m_Times = m_Times + 1
            if IsNeedReNavigate(msg) == false then
                return
            else
                SetFollowTarget(msg)
            end
        else
            m_Times = 0
            SetFollowTarget(msg)
        end
    end
    local EctypeManager = require("ectype.ectypemanager")
    if EctypeManager.IsInEctype() then
        return
    end
    if msg.worldid == PlayerRole:Instance():GetMapId() then     
        local lineId = nil
        if PlayerRole:Instance().m_MapInfo then
            lineId=PlayerRole:Instance().m_MapInfo:GetLineId()
        end
        if lineId and msg.lineid ~= lineId then
            local MapManager = require("map.mapmanager")
            MapManager.EnterMap(PlayerRole:Instance():GetMapId(),msg.lineid)
            return       
        else
            PlayerRole:Instance():navigateTo({
                targetPos = Vector3(msg.position.x,msg.position.y,msg.position.z),
                lineId = msg.lineid,
                newStopLength = m_FollowDistance})
            return
        end
    else
        local mapData = ConfigManager.getConfigData("worldmap",msg.worldid)
        if mapData then
            if mapData.openlevel <= PlayerRole:Instance().m_Level and (msg.maptype == 1) then
                PlayerRole:Instance():navigateTo({
                    targetPos = Vector3(msg.position.x,msg.position.y,msg.position.z),
                    newStopLength = m_FollowDistance,
                    mapId = msg.worldid,
                    lineId = msg.lineid,
                    navMode = 2,
                    isShowAlert = false})
                return
            end
        end
    end   
    if m_Team then
        CancelFollowing()
        UIManager.ShowSystemFlyText(LocalString.Team_FollowFail)
    end
end


local function GetHeadIcon(profession,gender)
    local professionData = ConfigManager.getConfigData("profession",profession)
    local model
    if professionData then
        local modelName = ""
        if gender == cfg.role.GenderType.MALE then
            modelName = professionData.modelname
        elseif gender == cfg.role.GenderType.FEMALE then
            modelName = professionData.modelname2
        end
        model = ConfigManager.getConfigData("model",modelName)
    end
    return model and model.headicon or ""
end

local function IsFull(teamInfo)
    if teamInfo and (teamInfo.membernum) then
        local teamConfig = ConfigManager.getConfig("team")
        local maxCount = 0
        if teamConfig and teamConfig.teammembermaxcount then
            maxCount = teamConfig.teammembermaxcount
        end
        return (teamInfo.membernum == maxCount)
   end
   return false
end

local function IsOwnTeamFull()
    return IsFull(m_Team)
end

local function RefreshFriendInfo()
    if UIManager.isshow("team.tabothers") then
        UIManager.call("team.tabothers","RefreshFriendInfo")
    end
end

--是否同一家族：true:在同一家族；    false：不同家族
local function IsInSameFamily()
    local result = true
    local familyId = nil
    if m_Team and m_Team.members then
        for _,member in pairs(m_Team.members) do
            if familyId == nil then
                familyId = member.roleinfo.familyid
            end
            if member.roleinfo.familyid ~= familyId then
                result = false
                break
            end
        end  
    else
        result = false  
    end
    return result
end

local function GetAverageLevel()
    local level = 0
    local memberNum = 0
    if m_Team and m_Team.members then
        for _,member in pairs(m_Team.members) do
            level = level + member.roleinfo.level
            memberNum = memberNum + 1
        end   
        return Math.floor(level / memberNum)
    else
        return PlayerRole:Instance():GetLevel()
    end
end

local function GetTeamMemberNum()
    local num=0
    if m_Team and m_Team.members then
        for _,member in pairs(m_Team.members) do
            num = num + 1
        end
    end
    return num
end

local function GetTeamMembers()
    local memberList = {}
    if m_Team and m_Team.members then
        for _,member in pairs(m_Team.members) do
            if member.roleid ~= PlayerRole:Instance():GetId() then
                table.insert(memberList,member.roleid)
            end
        end
    end
    return memberList
end

local function IsForcedFollow()
    local result = false
    return result
end

local function IsInSameLevel()
    local result = true
    if m_Team and m_Team.members then
        local openLevel,stage = HeroChallengeManager.GetStageByLevel()
        for _,member in pairs(m_Team.members) do
            if member.roleid ~= PlayerRole:Instance():GetId() then
                local openLevel,otherStage = HeroChallengeManager.GetStageByLevel(member.roleinfo.level)
                if otherStage ~= stage then
                    result = false
                    break
                end
            end
        end
    end
    return result
end

local function ClearData()
    m_Team = nil
    GTeamManagerListState = {}
    gTeamManagerListState.autoAcceptInvite = 0
    gTeamManagerListState.autoAcceptRequest = 0
    gTeamManagerListState.isInvitedFollow = false
    m_FollowTarget = nil
    m_FollowResetTime = ResetTime
    m_FollowDistance = cfg.team.team.FollowDistance
    PlayerRole:Instance():CancelFollowing()
    Utils.clear_table(m_InviteList)
    Utils.clear_table(m_ApplyList)
end

local function init()
    HeroChallengeManager = require("ui.activity.herochallenge.herochallengemanager")
    PlayerRole = require("character.playerrole")
    GameEvent.evt_system_message:add("logout",ClearData)
    GameEvent.evt_update:add(update)
    NetWork.add_listeners({
        {"lx.gs.team.msg.SInitTeam",OnMsg_SInitTeam},--保存自动接收他人的邀请和自动接收
        {"lx.gs.team.msg.SSyncTeam",OnMsg_SSyncTeam},
        {"lx.gs.team.msg.SInviteJoinTeam",OnMsg_SInviteJoinTeam},
        {"lx.gs.team.msg.SBreakupTeam",OnMsg_SBreakupTeam},
        {"lx.gs.team.msg.SBreakupTeamNotify",OnMsg_SBreakupTeamNotify},
        {"lx.gs.team.msg.SQuitTeam",OnMsg_SQuitTeam},
        {"lx.gs.team.msg.SFollowLeader",OnMsg_SFollowLeader},
        {"lx.gs.team.msg.SInviteFollowNotify",OnMsg_SInviteFollowNotify},
        {"lx.gs.team.msg.SInviteFollow",OnMsg_SInviteFollow},
        {"lx.gs.team.msg.SUnFollowTeamMemberNotify",OnMsg_SUnFollowTeamMemberNotify},
        {"lx.gs.team.msg.SJoinTeamNotify",OnMsg_SJoinTeamNotify},
        {"lx.gs.team.msg.SSetAutoSetting",OnMsg_SSetAutoSetting},
        {"lx.gs.team.msg.STransferLeader",OnMsg_STransferLeader},
        {"lx.gs.team.msg.SRequestJoinTeam",OnMsg_SRequestJoinTeam},
        {"lx.gs.team.msg.SKickoutMember",OnMsg_SKickoutMember},
        {"lx.gs.team.msg.SUnFollowLeader",OnMsg_SUnFollowLeader},
        {"lx.gs.map.msg.SGetPlayerLocation",OnMsg_SGetPlayerLocation},
        {"lx.gs.map.msg.SFollowTeamMemberNotify",OnMsg_SFollowTeamMemberNotify},    
        {"map.msg.SFindNearbyTeam",OnMsg_FindTeams},
        {"map.msg.SFindNearbyRole",OnMsg_FindPlayers},           
    })
	
	
end

return{
    init = init,
    update = update,
    GetTeamInfo = GetTeamInfo,
    SendCreateTeam = SendCreateTeam,
    SendCBreakUpTeam = SendCBreakUpTeam,
    SendUnFollowLeader = SendUnFollowLeader,
    SendFollowLeader = SendFollowLeader,
    SendInviteFollow = SendInviteFollow,
    SendQuitTeam = SendQuitTeam,
    SendInviteJoinTeam = SendInviteJoinTeam,
    SendKickOut = SendKickOut,
    SendTransferLeader = SendTransferLeader,
    SendGetPlayerLocation = SendGetPlayerLocation,
    IsTeamMate = IsTeamMate,
    IsLeader = IsLeader,
    SendFindNearByRole = SendFindNearByRole,
    SendFindNearByTeam = SendFindNearByTeam,
    SendAutoSetting = SendAutoSetting,
    SendRequestJoinTeam = SendRequestJoinTeam,
    CancelFollowing = CancelFollowing,
    RequestCancelFollowing = RequestCancelFollowing,
    IsInTeam = IsInTeam,
    GetHeadIcon = GetHeadIcon,
    IsFull = IsFull,
    IsOwnTeamFull = IsOwnTeamFull,
    RefreshFriendInfo = RefreshFriendInfo,
    IsInSameFamily = IsInSameFamily,
    GetAverageLevel = GetAverageLevel,
    GetTeamMemberNum = GetTeamMemberNum,
    GetTeamMembers = GetTeamMembers,
    IsForcedFollow = IsForcedFollow,
    IsInSameLevel = IsInSameLevel,
}
