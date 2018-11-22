local network = require("network")
local uimanager = require("uimanager")

local m_IsReady = false
local m_Callback
local m_Applys

local function IsReady()
    return m_IsReady
end

local function GetReady(callback)
    if not m_IsReady then
        m_Callback = callback
        network.send(lx.gs.family.msg.CGetFamilyRequestingInfo())
    else
        callback()
    end
end

local m_UnRead = false
local function Release()
    m_UnRead  = m_Applys and (getn(m_Applys) > 0) or false
    m_IsReady = false
end

local function UnRead()
    return m_IsReady and getn(m_Applys) > 0 or m_UnRead
end

local function Applys()
    return m_Applys
end

local m_AcceptApplyCallback
local function AcceptApply(roleid, callback)
    m_AcceptApplyCallback = callback
    m_UnRead = false
    network.send(lx.gs.family.msg.CAcceptRequestJoinF(){memberid=roleid})
	network.send(lx.gs.family.msg.CGetFamilyMembersInfo())
end

local m_RejectApplyCallback
local function RejectApply(roleid, callback)
    m_RejectApplyCallback = callback
    m_UnRead = false
    network.send(lx.gs.family.msg.CRejectRequestJoinF(){memberid=roleid})
end

local m_InviteFamilyCallback
local function InviteFamily(roleid, callback)
    m_InviteFamilyCallback = callback
    network.send(lx.gs.family.msg.CInviteJoinFamily(){beinviteroieid=roleid})
end

local m_ResponseInviteCallback
local function ResponseInvite( cresult, cfamilyid, cinviteroleid, callback) --�ظ����룬0�ܾ���1ͬ��
    m_ResponseInviteCallback = callback
    network.send(lx.gs.family.msg.CResponseInvite(){result=cresult,familyid =cfamilyid, inviteroleid = cinviteroleid })
end

local function HasJoinedOtherApplyErr()
    return m_Applys
end

local function init()
    network.add_listeners({
        {"lx.gs.family.msg.SGetFamilyRequestingInfo", function(msg)
             m_Applys           = msg.requestinglist
             m_IsReady = true
             if m_Callback then
                 m_Callback()
                 m_Callback = nil
             end
        end},
        {"lx.gs.family.msg.SAcceptRequestJoinF", function(msg)
             m_Applys[msg.member.roleid] = nil
             if m_AcceptApplyCallback then
                 m_AcceptApplyCallback(msg.member.roleid)
             end
        end},
        {"lx.gs.family.msg.SRejectRequestJoinF", function(msg)
             m_Applys[msg.memberid] = nil
             if m_RejectApplyCallback then
                 m_RejectApplyCallback(msg.memberid)
             end
        end},
        {"lx.gs.family.msg.SAcceptFailNotify", function(msg)            
             m_Applys[msg.acceptid] = nil
             uimanager.refresh("family.tabapply")
             uimanager.ShowSingleAlertDlg({content=LocalString.Family.HasJoinOtherFamily})
        end},
        {"lx.gs.family.msg.SInviteJoinFamily", function(msg)
            uimanager.ShowSystemFlyText(LocalString.Family.SendInviteFamily)
            if m_InviteFamilyCallback then
                 m_InviteFamilyCallback()
             end
        end},
        {"lx.gs.family.msg.SResponseInvite", function(msg)
            if m_ResponseInviteCallback then
                 m_ResponseInviteCallback()
             end
        end},

        -- init m_UnRead
        {"lx.gs.family.msg.SGetFamilyInfo", function(msg)
             m_UnRead = msg.family.familyrequestinfo > 0 and ConfigManager.getConfigData("familyjob", msg.selfinfo.familyjob).enrollperm
        end},

        -- notify
        {"lx.gs.family.msg.SRequestJoinFamilyNotify", function(msg)
             m_UnRead = true
             require("ui.dlguimain").RefreshRedDotType(cfg.ui.FunctionList.FAMILY)
             if m_IsReady then
                 m_Applys[msg.roleinfo.roleid] = msg.roleinfo
             end
        end},
        {"lx.gs.family.msg.SAcceptRequestJofinFNotify", function(msg)
             if m_IsReady then
                 m_Applys[msg.member.roleid] = nil
             end
        end},
        {"lx.gs.family.msg.SRejectRequestJofinFNotify", function(msg)
             if m_IsReady then
                 m_Applys[msg.memberid] = nil
             end
        end},
        {"lx.gs.family.msg.SInviteJoinNotify", function(msg)
            uimanager.ShowAlertDlg({
                    content      = string.format(LocalString.Family.ReceiveInviteFamily, msg.inviterolename, msg.familyname),
                    sureText     = LocalString.Marriage.DivorceAgree,
                    cancelText   = LocalString.Marriage.DivorceRefuse,   
                    callBackFunc = function()
                        ResponseInvite(1, msg.familyid, msg.inviteroleid, 
                            function()
                                uimanager.ShowSystemFlyText(string.format(LocalString.Family.ResponseInviteFamilySuccess, msg.familyname))
                            end)
                    end,
                    callBackFunc1 = function()
                        ResponseInvite(0, msg.familyid, msg.inviteroleid)
                    end,
                })
        end},
        {"lx.gs.family.msg.SResponseNotify", function(msg)
             if msg.result == 0 then --�ܾ���1ͬ��
                 uimanager.ShowSystemFlyText(string.format(LocalString.Family.ResponseInviteFamilyFailed, msg.responserolename))
             else
                uimanager.ShowSystemFlyText(string.format(LocalString.Family.ResponseInviteFamilyOk, msg.responserolename))
             end
        end},
    },"applymanager")
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    Applys              = Applys,
    AcceptApply         = AcceptApply,
    RejectApply         = RejectApply,
    UnRead              = UnRead,
    InviteFamily        = InviteFamily,
}
