local network = require("network")
local uimanager = require("uimanager")
local mgr = require("family.familymanager")
local player = require("character.playerrole"):Instance()

local m_IsReady = false
local m_Callback
local m_JobInfo
local m_Members

local function IsReady()
    return m_IsReady and mgr.IsReady()
end

local function GetReady(callback)
    mgr.GetReady(function()
        if not m_IsReady then
            m_Callback = callback
            network.send(lx.gs.family.msg.CGetFamilyMembersInfo())
        else
            callback()
        end
    end)
end

local function Release()
    m_IsReady = false
end

local function JobId2Str(jobid)
    local datajob = ConfigManager.getConfigData("familyjob", jobid)
    if datajob then
        return datajob.displayname
    elseif jobid == cfg.family.FamilyJobEnum.MEMBER then
        return cfg.family.FamilyInfo.FAMILY_MEMBER_STR
    else
        return ""
    end
end

local function HasEnrollPerm(jobid)
    local datajob = ConfigManager.getConfigData("familyjob", jobid)
    if datajob then
        return datajob.enrollperm
    else
        return false
    end
end

local function IsJobVacant(jobid)
    if jobid == cfg.family.FamilyJobEnum.MEMBER then
        return true
    end
    local level = mgr.Info().flevel
    local datajob = ConfigManager.getConfigData("familyjob", jobid)
    if jobid == cfg.family.FamilyJobEnum.JING_YING and m_JobInfo[jobid] == nil then --处理老家族第一次服务器没有这个职位的bug
        m_JobInfo[jobid] = {}
        return true
    end
    if datajob.amount[level] and m_JobInfo[jobid]  then
        return getn(m_JobInfo[jobid]) < datajob.amount[level]
    else
        return false
    end
end

local function Members()
    return m_Members
end

local function JobInfo()
    return m_JobInfo
end

local m_KickoutCallback
local function Kickout(roleid, callback)
    m_KickoutCallback = callback
    network.send(lx.gs.family.msg.CKickoutFamilyMember(){memberid=roleid})
end

local m_AppointCallback
local function Appoint(roleid, jobid, callback)
    m_AppointCallback = callback
    network.send(lx.gs.family.msg.CAppointJob(){memberid=roleid,jobid=jobid})
end

local m_TransferChiefCallback
local function TransferChief(roleid, callback)
    m_TransferChiefCallback = callback
    network.send(lx.gs.family.msg.CTransferChief(){memberid=roleid})
end

local function changeJob(roleid, jobid)
    if m_Members[roleid].familyjob ~= cfg.family.FamilyJobEnum.MEMBER then
        m_JobInfo[m_Members[roleid].familyjob][roleid] = nil
    end
    if jobid ~= cfg.family.FamilyJobEnum.MEMBER then
        m_JobInfo[jobid][roleid] = true
    end
end

local function OnLogout()
	m_Members = nil
end

local function init()
    network.add_listeners({
        {"lx.gs.family.msg.SGetFamilyMembersInfo", function(msg)
             m_Members          = msg.members
             mgr.Info().membernum = #keys(m_Members)
             m_JobInfo = {}
             for id,list in pairs(msg.jobinfo) do
                 m_JobInfo[id] = utils.array_to_set(list.staffs)
             end
             m_IsReady = true
             if m_Callback then
                 m_Callback()
                 m_Callback = nil
             end
        end},
        {"lx.gs.family.msg.SKickoutFamilyMember", function(msg)
             changeJob(msg.memberid, cfg.family.FamilyJobEnum.MEMBER)
             m_Members[msg.memberid] = nil
             mgr.Info().membernum = mgr.Info().membernum-1  
             mgr.Info().membernum = mgr.Info().membernum-1  
             if m_KickoutCallback or m_KickoutCallback ~= nil then
                 m_KickoutCallback()
             end
        end},
        {"lx.gs.family.msg.SAppointJob", function(msg)
             changeJob(msg.member.roleid, msg.jobid)
             m_Members[msg.member.roleid].familyjob = msg.jobid
             if m_AppointCallback then
                 m_AppointCallback(msg.jobid)
             end
        end},
        {"lx.gs.family.msg.STransferChief", function(msg)
             changeJob(player:GetId(), cfg.family.FamilyJobEnum.MEMBER)
             changeJob(msg.member.roleid, cfg.family.FamilyJobEnum.CHIEF)
             m_Members[msg.member.roleid] = msg.member
             m_Members[player:GetId()].familyjob = cfg.family.FamilyJobEnum.MEMBER
             if m_TransferChiefCallback then
                 m_TransferChiefCallback()
             end
        end},

        -- notify
        {"lx.gs.family.msg.SAppointJobNotify", function(msg)
             if msg.member.roleid == player:GetId() then
                 if msg.jobid == cfg.family.FamilyJobEnum.MEMBER then
                     uimanager.ShowSystemFlyText(string.format(LocalString.Family.HintBeenRelieve, JobId2Str(mgr.RoleMember().familyjob)))
                 else
                     uimanager.ShowSystemFlyText(string.format(LocalString.Family.HintBeenAppoint, JobId2Str(msg.jobid)))
                 end
             end
             if m_IsReady then
                 if m_Members[msg.member.roleid] then
                     m_Members[msg.member.roleid].familyjob = msg.jobid
                 end
             end
        end},
        {"lx.gs.family.msg.SAcceptRequestJofinFNotify", function(msg)
             if m_IsReady then
                 m_Members[msg.member.roleid] = msg.member
             end
        end},
        {"lx.gs.family.msg.STransferChiefNotify", function(msg)
             if msg.member.roleid == player:GetId() then
                 uimanager.ShowSystemFlyText(string.format(LocalString.Family.HintBeenAppoint, JobId2Str(cfg.family.FamilyJobEnum.CHIEF)))
             end
             if m_IsReady then
                 if m_Members[msg.operator.roleid] then
                     m_Members[msg.operator.roleid].familyjob = cfg.family.FamilyJobEnum.MEMBER
                 end
                 if m_Members[msg.member.roleid] then
                     m_Members[msg.member.roleid].familyjob = msg.jobid
                 end
             end
        end},
        {"lx.gs.family.msg.SQuitFamilyNotify", function(msg)
             if m_IsReady then
                 m_Members[msg.memberid] = nil                
             end
             mgr.Info().membernum = mgr.Info().membernum-1
        end},
        {"lx.gs.family.msg.SKickoutFamilyMemberNotify", function(msg)
             if m_IsReady then
                 m_Members[msg.memberid] = nil
             end
        end}
    },"membermanager")
	gameevent.evt_system_message:add("logout", OnLogout)
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    JobId2Str           = JobId2Str,
    HasEnrollPerm       = HasEnrollPerm,
    IsJobVacant         = IsJobVacant,
    Appoint             = Appoint,
    TransferChief       = TransferChief,
    Members             = Members,
    JobInfo             = JobInfo,
    Kickout             = Kickout,
}
