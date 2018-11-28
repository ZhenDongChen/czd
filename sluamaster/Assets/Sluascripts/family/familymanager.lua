local network = require("network")
local player = require("character.playerrole"):Instance()
local uimanager = require("uimanager")
local configmanager = require("cfg.configmanager")
local scenemanager = require "scenemanager"
local DeclareWarManager = require("family.declarewarmanager")

local modset = {"family.searchmanager",
                "family.membermanager",
                "family.applymanager",
                "family.welfaremanager",
                "family.activitymanager",}

local uimodset = {"family.tabbasic",
                "family.tabmember",
                "family.tabwelfare",
                "family.tabactivity",
                "family.tabapply",}

local m_IsReady = false
local m_Callback
local m_Info
local m_RoleMember
local m_DataJob
local m_InitFundingID
local m_bInStation
local m_curEnterType
local m_cost

local EnterType = enum
{
    "OnlyEnter = 0",
    "PartyManagerNPC",
    "BlackMarketNPC",
    "FamilyTaskNPC",
    "GOD_ANIMAL",
}
local s_PartyManagerNPCID = 23000384
local s_BlackMarketNPCID  = 23000385
local s_FamilyTaskNPCID   = 23000100

local function CheckAllFamilyDlgHide() --处理手机上快速切换页签可能导致的界面未关闭
    for _,dlg in ipairs(uimodset) do
        if uimanager.isshow(dlg) then
            uimanager.hide(dlg)
        end
    end
end

local function IsReady()
    return m_IsReady
end

local function GetFamilyNPCID(enterType)
    local npcID = nil
    if enterType == EnterType.PartyManagerNPC then
        npcID = s_PartyManagerNPCID
    elseif enterType == EnterType.BlackMarketNPC then
        npcID = s_BlackMarketNPCID
    elseif enterType == EnterType.FamilyTaskNPC then
        npcID = s_FamilyTaskNPCID
    elseif enterType == EnterType.GOD_ANIMAL then  --神兽导航目标点需要特殊处理
        npcID = s_BlackMarketNPCID
    end

    return npcID
end

local function GetReady(callback)
    if not m_IsReady then
        m_Callback = callback
        network.send(lx.gs.family.msg.CGetFamilyInfo())
    else
        callback()
    end
end

---
--修改名字请求
local function RequestChangeFamilyName(name)
    network.send(lx.gs.family.msg.CChangeFamilyName{familyname = name})
end

----
--修改名字回调
local function onmsg_SChangeFamilyName(msg)
    m_Info.familyname = msg.familyname
    if uimanager.isshow("family.tabbasic") then
        uimanager.refresh("family.tabbasic")
    end
    uimanager.ShowSingleAlertDlg{content=LocalString.Family.ChangeNameSucc}
end

local function onmsg_SChangeFamilyNameNeedYuanbao(msg)
    m_cost = msg.needyuanbao
    uimanager.call("family.tabbasic","openChange",msg)
end

local function getCost()
    return m_cost
end

local function Release()
    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.Release then
            mod.Release()
        end
    end
    m_IsReady = false
    m_bInStation = false
end

local function OpenDlg()
    -- printyellow("on open dlgfamily")
    -- printt(m_InfoInfo)
    -- printt(m_RoleMember)
    GetReady(function()
        if m_Info.familyid == 0 then
            uimanager.showdialog("family.dlgfamily_apply")
        else
            uimanager.showdialog("family.dlgfamily")
        end
    end)
end

local function GetFamilyId()
    if m_Info then
        return m_Info.familyid 
    else
        return nil
    end   
end

local function InFamily()
	--printyellow(">>>>>>>>>m_Info.familyid",m_Info.familyid)
      return m_Info and (m_Info.familyid ~= 0) or false
end

local function UnRead()
    if not InFamily() then return false end

    for _,mod in ipairs(modset) do
        local modFile = require(mod)
        if modFile and modFile.UnRead and modFile.UnRead() then
            return true
        end
    end
    return false
end
local function Info()
    return m_Info
end

local function RoleMember()
    return m_RoleMember
end

local function HasInitFunding()
    return m_InitFundingID > 0
end

local m_UpdateCallback
local function UpdateDeclaration(text, callback)
    m_UpdateCallback = callback
    network.send(lx.gs.family.msg.CUpdateDeclarationOrPublic(){
        updatetype=lx.gs.family.msg.CUpdateDeclarationOrPublic.UPDATE_DECLARATION,
        newtext = text})
end

local function UpdatePublicinfo(text, callback)
    m_UpdateCallback = callback
    network.send(lx.gs.family.msg.CUpdateDeclarationOrPublic(){
        updatetype=lx.gs.family.msg.CUpdateDeclarationOrPublic.UPDATE_PUBLIC,
        newtext = text})
end

local m_QuitFamilyCallback
local function QuitFamily(callback)
    m_QuitFamilyCallback = callback
    network.send(lx.gs.family.msg.CQuitFamily())
end

local function refreshDataJob()
    m_DataJob          = configmanager.getConfigData("familyjob", m_RoleMember.familyjob)
end

local function CanAppoint(targetjobid)
    return m_DataJob and m_DataJob.appointjobs[targetjobid]
        or false
end

local function SelfDataJob()
    return m_DataJob
end

local function CanAppointJobs()
    return m_DataJob and m_DataJob.appointjobs or {}
end

local function CanKickout(targetjobid)
    return m_DataJob.kickoutperm and targetjobid == cfg.family.FamilyJobEnum.MEMBER
        or CanAppoint(targetjobid)
end

local function CanInviteFamily()
    return m_RoleMember and m_RoleMember.familyjob ~= cfg.family.FamilyJobEnum.MEMBER or false
end

local function CanSeeApply()
    return m_RoleMember and m_RoleMember.familyjob ~= cfg.family.FamilyJobEnum.MEMBER or false
end

local m_callBackEnterFamilyStation
local function NavigateToFamilyNPC(enterType)
    local npcID = GetFamilyNPCID(enterType)
    if npcID then
        local worldmapid
        local pos
        local direction
        local charactermanager = require"character.charactermanager"
        local CharacterType = defineenum.CharacterType
        worldmapid, pos, direction = charactermanager.GetAgentPositionInCSV(npcID, CharacterType.Npc)
        if enterType == EnterType.GOD_ANIMAL then --神兽导航目标点需要特殊处理
            local familyStationConfig = configmanager.getConfig("familystation")
            pos.x = familyStationConfig.godanimalposition.x
            pos.y = familyStationConfig.godanimalposition.y
        end
        PlayerRole:Instance():navigateTo( {
            targetPos = pos,
            roleId = npcID,
            mapId = worldmapid,
            eulerAnglesOfRole = direction,
            newStopLength = 1*SCALE_SPEED,
            isAdjustByRideState = true,
            callback = function()
                if m_callBackEnterFamilyStation then
                   m_callBackEnterFamilyStation()
               end
               m_callBackEnterFamilyStation = nil
          end
        } )
    end
end


local function CEnterFamilyStation(enterType, callBack)
    if m_bInStation then
        m_curEnterType = enterType
        m_callBackEnterFamilyStation = callBack
        NavigateToFamilyNPC(enterType)
    else
        local TeamManager = require("ui.team.teammanager")
        if enterType == EnterType.FamilyTaskNPC then
                uimanager.ShowAlertDlg({
                    title        = LocalString.Family.Party.TitleMission,
                    content      = LocalString.Family.Party.MissionEnter,
                    callBackFunc = function()
                        m_curEnterType = enterType
                        m_callBackEnterFamilyStation = callBack
                        network.send(lx.gs.family.msg.CEnterFamilyStation(){ isopenparty = enterType })
                    end,
                    immediate = true,
                })
            else
                m_curEnterType = enterType
                m_callBackEnterFamilyStation = callBack
                network.send(lx.gs.family.msg.CEnterFamilyStation(){ isopenparty = enterType })
            end
    end
end

local function CLeaveFamilyStation(callBack)
    PlayerRole:Instance().m_MapInfo:RegCallback(callBack)
    network.send(lx.gs.map.msg.CLeaveMap({}))
end

local function IsChief()
    return m_RoleMember and m_RoleMember.familyjob == cfg.family.FamilyJobEnum.CHIEF or false
end

local function IsViceChief()
    return m_RoleMember and m_RoleMember.familyjob == cfg.family.FamilyJobEnum.VICE_CHIEF or false
end

local function IsInStation()
    return m_bInStation
end

local function IsInBlackMarketTime()
    local blackmarketInfo = configmanager.getConfig("blackmarket")
    local timeNow = timeutils.TimeNow()
	local nowSecsDay = timeutils.getSeconds({days = 0, hours = timeNow.hour ,minutes = timeNow.min,seconds = timeNow.sec})

    local beginSecsDay1 = timeutils.getSeconds({days = 0, hours = blackmarketInfo.opentime[1].starthour,
        minutes =  blackmarketInfo.opentime[1].startminute, seconds = 0})
    local endSecsDay1 = timeutils.getSeconds({days = 0, hours = blackmarketInfo.opentime[1].endhour,
        minutes = blackmarketInfo.opentime[1].endminute, seconds = 0})
    local beginSecsDay2 = timeutils.getSeconds({days = 0, hours = blackmarketInfo.opentime[2].starthour,
        minutes = blackmarketInfo.opentime[2].startminute, seconds = 0})
    local endSecsDay2 = timeutils.getSeconds({days = 0, hours = blackmarketInfo.opentime[2].endhour,
        minutes = blackmarketInfo.opentime[2].endminute, seconds = 0})

    local bInOpenTime = false
    if (beginSecsDay1 < nowSecsDay and nowSecsDay < endSecsDay1) or (beginSecsDay2 < nowSecsDay and nowSecsDay < endSecsDay2) then
        bInOpenTime = true
    end

    return bInOpenTime
end

local function CGetFamilyLog()
    if InFamily() then
        network.send(lx.gs.family.msg.CGetFamilyLog({ familyid = m_Info.familyid }))
    end
end

local function CGetFamilyDepotLog()
    if InFamily() then
        network.send(lx.gs.family.msg.CGetFamilyDepotLog({ familyid = m_Info.familyid }))
    end
end

local function OpenFamilyLog(msg)
    local DlgFamilyLog = require("ui.family.dlgfamilylog")
    local params = {}
    params.msg = msg
	-- 选择UIGroup_log = 3
	params.type = 3
	params.callBackFunc = function(p, f) DlgFamilyLog.init(f); DlgFamilyLog.show(p) end
	uimanager.show("common.dlgdialogbox_complex", params)
end

--开始神兽挑战,每周两次，通知全族人员
local function on_SLaunchGodAnimalActivityNotify(msg)
    --printyellow("[familymanager:on_SLaunchGodAnimalActivityNotify] receive:", msg)
    if m_IsReady then
        m_Info.godanimalstarttime = msg.starttime
    end
end

local function Logout()
    Release()
end


local function init()
    -- printyellow("family manager init")
    m_bInStation = false

    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.init then
            mod.init()
        end
    end
    printyellow("lx.gs.family.msg.SGetFamilyInfo,init()")
    network.add_listeners({
        {"lx.gs.family.msg.SGetFamilyInfo", function(msg)
                printyellow("lx.gs.family.msg.SGetFamilyInfo")
             m_Info             = msg.family
             m_RoleMember       = msg.selfinfo
             m_InitFundingID    = msg.selfinitid
             refreshDataJob()
             m_IsReady = true
             if m_Callback then
                 m_Callback()
                 m_Callback = nil
             end
        end},
        {"lx.gs.family.msg.SUpdateDeclarationOrPublic", function(msg)
             if msg.updatetype == lx.gs.family.msg.CUpdateDeclarationOrPublic.UPDATE_DECLARATION then
                 m_Info.declaration = msg.newtext
             elseif msg.updatetype == lx.gs.family.msg.CUpdateDeclarationOrPublic.UPDATE_PUBLIC then
                 m_Info.publicinfo = msg.newtext
             end
             if m_UpdateCallback then
                 m_UpdateCallback(msg.newtext)
             end
        end},
        {"lx.gs.family.msg.SQuitFamily", function()
             Release()
             m_Info.familyid = 0
             m_IsReady = true
             if m_QuitFamilyCallback then
                 m_QuitFamilyCallback()
             end
             uimanager.call("dlguimain","OnQuitFamily")
        end},
        {"lx.gs.family.msg.SEnterFamilyStation", function()
        end},
        {"map.msg.SAfterEnterFamilyStation", function(msg)
            PlayerRole:Instance():sync_SEnterFamilyStation(msg)
             local partyInfo = configmanager.getConfig("familyparty")
             local ectypeInfo = configmanager.getConfigData("ectypebasic",partyInfo.familyectypeid)
             if ectypeInfo then
                --if  m_curEnterType == EnterType.FamilyTaskNPC then
                --    scenemanager.load(Local.MaincityDlgList, ectypeInfo.scenename, function() NavigateToFamilyNPC(EnterType.FamilyTaskNPC) end)
                --else
                    scenemanager.load(Local.MaincityDlgList, ectypeInfo.scenename, function()
                        network.send(map.msg.CReady({}))

                        local partymgr = require("family.partymanager")
                        if partymgr.IsOpening() then
                            partymgr.ShowPartySfx()
                        end

                        NavigateToFamilyNPC(m_curEnterType)
                    end)
               -- end

                m_bInStation = true
             end
        end},
        {"lx.gs.map.msg.SLeaveMap", function()
            if m_bInStation then
                m_bInStation = false

                local partymgr = require("family.partymanager")
                partymgr.DestoryPartySfx()
            end
        end},

        -- notify
        {"lx.gs.family.msg.STransferChiefNotify", function(msg)
             if msg.operator.roleid == m_RoleMember.roleid or msg.member.roleid == m_RoleMember.roleid then
                 -- Release()
                 if m_IsReady then
                     m_Info.chiefid = msg.member.roleid
                     m_Info.chiefname = msg.member.rolename
                     if msg.operator.roleid == m_RoleMember.roleid then
                         m_RoleMember.familyjob = cfg.family.FamilyJobEnum.MEMBER
                     elseif msg.member.roleid == m_RoleMember.roleid then
                         m_RoleMember.familyjob = cfg.family.FamilyJobEnum.CHIEF
                     end
                     refreshDataJob()
                 end
             end
        end},
        {"lx.gs.family.msg.SAppointJobNotify", function(msg)
             if m_IsReady then
                 if msg.member.roleid == m_RoleMember.roleid then
                     m_RoleMember.familyjob = msg.jobid
                     refreshDataJob()
                 end
             end
        end},
        {"lx.gs.family.msg.SKickoutFamilyMemberNotify", function(msg)
             if msg.memberid == player:GetId() then
                 if m_IsReady then
                     Release()
                     m_Info.familyid = 0
                     m_IsReady = true
                     uimanager.call("dlguimain","OnQuitFamily")
                 end
                 uimanager.ShowSystemFlyText(LocalString.Family.HintBeenKickout)
                 if uimanager.currentdialogname() == "family.dlgfamily" then
                     uimanager.hidecurrentdialog()
                 end
             else
                 m_Info.membernum = m_Info.membernum-1
             end
        end},
        {"lx.gs.family.msg.SAcceptRequestJoinFNotify", function(msg)
             if msg.member.roleid == player:GetId() then
                 uimanager.ShowSystemFlyText(string.format(LocalString.Family.HintApplyAccepted, msg.family.familyname))
                 Release()
                 GetReady(function()
                         if uimanager.currentdialogname() == "family.dlgfamily_apply" then
                             uimanager.showdialog("family.dlgfamily")
                         end
                         uimanager.call("dlguimain","RefreshTaskList")
                 end)
             else
                 m_Info.membernum = m_Info.membernum+1
             end
        end},
        {"lx.gs.family.msg.SUpLevelMallNotify", function(msg)
             if m_IsReady then
                 m_Info = msg.family
             end
        end},
        {"lx.gs.family.msg.SUpLevelFamilyNotify", function(msg)
             if m_IsReady then
                 m_Info = msg.family
             end
        end},
        {"lx.gs.family.msg.SFamilyInfoChangeNotify", function(msg)
             if m_IsReady then
                 m_Info.declaration = msg.declaration
                 m_Info.publicinfo = msg.publicinfo
                 m_Info.money = msg.money
                 m_Info.curlvlbuilddegree = msg.curlvlbuilddegree
                 m_Info.flevel = msg.flevel 
                 if msg.familyname then --- 判断名字是否有改变
                    m_Info.familyname =  msg.familyname
                 end
                 if uimanager.isshow("family.tabbasic") then
                     uimanager.refresh("family.tabbasic")
                 end
             end
        end},
        {"lx.gs.family.msg.SCrowdSuccessNotify", function(msg)
             uimanager.ShowSystemFlyText(string.format(LocalString.Family.Fund.HintSuccess, msg.family.familyname))
             Release()
             GetReady(function()
                     if uimanager.currentdialogname() == "family.dlgfamily_apply" then
                         uimanager.showdialog("family.dlgfamily")
                     end
                     uimanager.call("dlguimain","RefreshTaskList")
             end)
        end},
        {"lx.gs.family.msg.SCrowdFamFailNotify", function(msg)
             uimanager.ShowAlertDlg({title=LocalString.Family.TagWarn, content=LocalString.Family.Fund.HintFail})
        end},
        {"lx.gs.family.msg.SGetFamilyLog", function(msg)
             OpenFamilyLog(msg)
        end},
        {"lx.gs.family.msg.SGetFamilyDepotLog", function(msg)
             OpenFamilyLog(msg)
        end},

        -- sync
        {"lx.gs.family.msg.SCrowdFamily", function(msg)
             m_InitFundingID = msg.crowfamilyinfo.crowdfamilyid
        end},
        {"lx.gs.family.msg.SCancelCrowdFamily", function(msg)
             m_InitFundingID = 0
        end},

        --family boss start time
        {"lx.gs.family.msg.SLaunchGodAnimalActivityNotify",on_SLaunchGodAnimalActivityNotify},

        {"lx.gs.family.msg.SChangeFamilyName",onmsg_SChangeFamilyName},

        {"lx.gs.family.msg.SChangeFamilyNameNeedYuanbao",onmsg_SChangeFamilyNameNeedYuanbao}
    },"familymanager")

    DeclareWarManager.init()

    local gameevent = require "gameevent"
    gameevent.evt_system_message:add("logout", Logout)
end

local function IsInWarState(familyId)
    return DeclareWarManager.IsInWarState(familyId)
end

local function IsDeclaredWar(familyId)
    return DeclareWarManager.IsDeclaredWar(familyId)
end

local function CanChangeWarState()
    return IsChief() or IsViceChief()
end

local function DeclareWar(familyId)
    return DeclareWarManager.DeclareWar(familyId)
end

local function CancelWar(familyId)
    return DeclareWarManager.CancelWar(familyId)
end


return{
    EnterType           = EnterType,
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    InFamily            = InFamily,
    GetFamilyId         = GetFamilyId,
    HasInitFunding      = HasInitFunding,
    Info                = Info,
    OpenDlg             = OpenDlg,
    RoleMember          = RoleMember,
    UpdateDeclaration   = UpdateDeclaration,
    UpdatePublicinfo    = UpdatePublicinfo,
    QuitFamily          = QuitFamily,
    CanAppoint          = CanAppoint,
    IsChief             = IsChief,
    CanKickout          = CanKickout,
    CanAppointJobs      = CanAppointJobs,
    UnRead              = UnRead,
    SelfDataJob         = SelfDataJob,
    CEnterFamilyStation = CEnterFamilyStation,
    CLeaveFamilyStation = CLeaveFamilyStation,
    IsViceChief         = IsViceChief,
    IsInStation         = IsInStation,
    CGetFamilyLog       = CGetFamilyLog,
    CGetFamilyDepotLog  = CGetFamilyDepotLog,
    IsInBlackMarketTime = IsInBlackMarketTime,
    CheckAllFamilyDlgHide = CheckAllFamilyDlgHide,
    CanInviteFamily     = CanInviteFamily,
    CanSeeApply         = CanSeeApply,

    IsInWarState        = IsInWarState,
    IsDeclaredWar       = IsDeclaredWar,
    DeclareWar          = DeclareWar,
    CancelWar           = CancelWar,
    CanChangeWarState   = CanChangeWarState,
    getCost             = getCost,
    RequestChangeFamilyName = RequestChangeFamilyName,
}
