local Network       = require("network")
local UIManager     = require("uimanager")
--local MaimaiInfo    = require("ui.maimai.base.maimaiinfo")

local MaimaiHelper  = require("ui.maimai.base.maimaihelper")


--================================================================================
--获取他人的脉脉信息
local function GetMaimaiInfo(roleId)
    --printyellowmodule(Local.LogModuals.Maimai,roleId)
    local re = lx.gs.friend.msg.CGetMaimaiInfo({roleid = roleId})
    Network.send(re)
end

local function OnMsgSGetMaimaiInfo(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)
    
    local MaimaiManager = require("ui.maimai.maimaimanager")
    local mmInfo = MaimaiManager.AddNewMaimaiInfo(msg.roleid, msg.mminfo)
    if mmInfo ~= nil then
        UIManager.refresh("maimai.tabmaimai",{maimaiInfo = mmInfo})
    end
end

--================================================================================
--请求加脉脉
local function RequestMaimai(roleId,relationship)
    --printyellowmodule(Local.LogModuals.Maimai,roleId,relationship)
    local re = lx.gs.friend.msg.CRequestMM({roleid = roleId, mmtype = relationship})
    Network.send(re)
end
local function OnMsgSRequestMaimai(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)
end

--================================================================================
--接受脉脉
local function AcceptMaimai(roleId,reqMaimaiType,maimaiType)
    --printyellowmodule(Local.LogModuals.Maimai,roleId,relationship)
    local re = lx.gs.friend.msg.CAcceptMM({roleid = roleId, reqmmtype = reqMaimaiType, mmtype = maimaiType})
    Network.send(re)
end
local function OnMsgSAcceptMaimai(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)
    local MaimaiManager = require("ui.maimai.maimaimanager")
    local RoleInfo      = require("ui.maimai.base.roleinfo")

    local mmInfo = MaimaiManager.GetMaimaiInfo()
    mmInfo:Add(msg.mmtype, RoleInfo:new(msg.mmroleinfo))

    UIManager.refresh("maimai.tabmaimai")
end

--================================================================================
--拒绝脉脉
local function RejectMaimai(roleId,maimaiType)
    --printyellowmodule(Local.LogModuals.Maimai,roleId,maimaiType)
    local re = lx.gs.friend.msg.CRejectMM({roleid = roleId, mmtype = maimaiType})
    Network.send(re)
end
local function OnMsgRejectMaimai(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)
    UIManager.refresh("maimai.tabmaimai")
end

--================================================================================
--删除脉脉
local function DeleteMaimai(roleId,maimaiType)
    --printyellowmodule(Local.LogModuals.Maimai,roleId,maimaiType)
    local re = lx.gs.friend.msg.CDeleteMM({roleid = roleId, mmtype = maimaiType})
    Network.send(re)
end
local function OnMsgDeleteMaimai(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)
    local MaimaiManager = require("ui.maimai.maimaimanager")
    local mmInfo = MaimaiManager.GetMaimaiInfo()
    mmInfo:Remove(msg.mmtype, msg.roleid)
    UIManager.refresh("maimai.tabmaimai")
end

--================================================================================
--别人申请加脉脉的通知
local function OnMsgSRequestMMNotify(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)
    local MaimaiHelper  = require("ui.maimai.base.maimaihelper")

    local notifyContent = string.format(LocalString.Maimai.Apply,
                                        msg.mmroleinfo.rolename,
                                        LocalString.Maimai.GenderCall[msg.mmroleinfo.gender+1],
                                        MaimaiHelper.GetRelationName(msg.mmtype))

    UIManager.ShowAlertDlg({title = LocalString.TipText, content = notifyContent,sureText = LocalString.AcceptText, cancelText = LocalString.RejectText,
        callBackFunc = function()
            AcceptMaimai(msg.mmroleinfo.roleid,msg.reqmmtype ,msg.mmtype)
        end,
        callBackFunc1 = function()
            RejectMaimai(msg.mmroleinfo.roleid, msg.mmtype)
        end,
    })

end

--================================================================================
--别人接受我为脉脉关系的通知
local function OnMsgSAcceptMMNotify(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)
    
    local MaimaiManager = require("ui.maimai.maimaimanager")
    local RoleInfo      = require("ui.maimai.base.roleinfo")
    local MaimaiHelper  = require("ui.maimai.base.maimaihelper")

    local mmInfo = MaimaiManager.GetMaimaiInfo()
    if mmInfo then
        mmInfo:Add(msg.mmtype, RoleInfo:new(msg.mmroleinfo))
    end
    if msg.mmtype ~= cfg.friend.MaimaiRelationshipType.BanLvNv and msg.mmtype ~= cfg.friend.MaimaiRelationshipType.BanLvNan then
        local notifyContent = string.format(LocalString.Maimai.Accept, msg.mmroleinfo.rolename, MaimaiHelper.GetRelationName(msg.mmtype))
    
        UIManager.ShowSingleAlertDlg({title = LocalString.TipText, content = notifyContent, buttonText = LocalString.KnowText})
    end
    UIManager.refresh("maimai.tabmaimai")
end

--================================================================================
--别人拒绝我的脉脉申请的通知
local function OnMsgSRejectMMNotify(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)
    local MaimaiHelper  = require("ui.maimai.base.maimaihelper")
    
    local notifyContent = string.format(LocalString.Maimai.Reject, msg.rolename,MaimaiHelper.GetRelationName(msg.mmtype))
    UIManager.ShowSingleAlertDlg({title = LocalString.TipText, content = notifyContent,buttonText = LocalString.KnowText})
end

--================================================================================
--别人删除我脉脉的通知
local function OnMsgSDeleteMMNotify(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)

    local MaimaiManager = require("ui.maimai.maimaimanager")
    local MaimaiHelper  = require("ui.maimai.base.maimaihelper")
    local mmInfo = MaimaiManager.GetMaimaiInfo()
    if mmInfo then
        if msg.mmtype ~= cfg.friend.MaimaiRelationshipType.BanLvNv and msg.mmtype ~= cfg.friend.MaimaiRelationshipType.BanLvNan then
            mmInfo:Remove(msg.mmtype, msg.roleid)
            local notifyContent = string.format(LocalString.Maimai.DeleteReject,msg.rolename,MaimaiHelper.GetRelationName(msg.mmtype))
            UIManager.ShowSingleAlertDlg({title = LocalString.TipText, content = notifyContent,buttonText = LocalString.KnowText})
        else
            mmInfo:Remove(msg.mmtype, nil)
        end
    end
    UIManager.refresh("maimai.tabmaimai")
end
--别人删除我脉脉的通知(不弹窗)
local function OnMsgSDeleteMMForProposeNotify(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)

    local MaimaiManager = require("ui.maimai.maimaimanager")
    local MaimaiHelper  = require("ui.maimai.base.maimaihelper")
    local mmInfo = MaimaiManager.GetMaimaiInfo()
    if mmInfo then
        if msg.mmtype ~= cfg.friend.MaimaiRelationshipType.BanLvNv and msg.mmtype ~= cfg.friend.MaimaiRelationshipType.BanLvNan then
            mmInfo:Remove(msg.mmtype, msg.roleid)
        else
            mmInfo:Remove(msg.mmtype, nil)
        end
    end
    UIManager.refresh("maimai.tabmaimai")
end


--================================================================================
--设置查看权限
local function SetMMAuthorization(allowFriendCheck,allowStrangeCheck)
    --printyellowmodule(Local.LogModuals.Maimai,tostring(allowFriendCheck) .. " - " .. tostring(allowFriendCheck))
    local re = lx.gs.friend.msg.CSetMMAuthorization({allowfriendgetmm = (((allowFriendCheck == true) and 1) or 0) , allowstrangergetmm = (((allowStrangeCheck == true) and 1) or 0)})
    Network.send(re)
end

--================================================================================
--设置查看权限
local function OnMsgSSetMMAuthorization(msg)
    --printyellowmodule(Local.LogModuals.Maimai,msg)
    local MaimaiManager = require("ui.maimai.maimaimanager")
    
    MaimaiManager.MaimaiData.m_IsAllowFriendCheck = (((msg.allowfriendgetmm == 1) and true) or false)
    MaimaiManager.MaimaiData.m_IsAllowStrangerCheck = (((msg.allowstrangergetmm == 1) and true) or false)
    
    
    if UIManager.isshow("maimai.tabmaimai") then
        UIManager.call( "maimai.tabmaimai", "ResetAllowToggle",
                        {allowFriend = MaimaiManager.MaimaiData.m_IsAllowFriendCheck,
                         allowStrange = MaimaiManager.MaimaiData.m_IsAllowStrangerCheck} )
    end
end
--================================================================================
--脉脉好友被杀
local function OnMsgBeKillByOther(msg)
    local ChatManager = require("ui.chat.chatmanager")
    if msg and msg.defencer then
        local MaimaiManager = require("ui.maimai.maimaimanager")
        local relation = MaimaiManager.GetMaimaiRelation(msg.defencer)
        local mmInfo = MaimaiManager.GetMaimaiInfo()
        if relation ~= nil and mmInfo ~= nil then
            local playerMmInfo = mmInfo:GetById(msg.defencer)
            local relationName = MaimaiHelper.GetRelationName(relation)
            if playerMmInfo ~= nil and relationName ~= nil and relationName ~= "" then
                local content = string.format( LocalString.Maimai.MaimaiBeKilled, tostring(relationName),tostring(playerMmInfo:GetRole():GetName()), tostring(msg.attackername) )
                UIManager.ShowSystemFlyText(content)
                ChatManager.AddMessageInfo({channel = cfg.chat.ChannelType.SYSTEM,text = content})
            end
        end
    end
end

local function init()
    Network.add_listeners( {

        { "lx.gs.friend.msg.SGetMaimaiInfo",        OnMsgSGetMaimaiInfo         },
        { "lx.gs.friend.msg.SRequestMM",            OnMsgSRequestMaimai         },
        { "lx.gs.friend.msg.SAcceptMM",             OnMsgSAcceptMaimai          },
        { "lx.gs.friend.msg.SRejectMM",             OnMsgRejectMaimai           },
        { "lx.gs.friend.msg.SDeleteMM",             OnMsgDeleteMaimai           },

        { "lx.gs.friend.msg.SRequestMMNotify",      OnMsgSRequestMMNotify       },
        { "lx.gs.friend.msg.SAcceptMMNotify",       OnMsgSAcceptMMNotify        },
        { "lx.gs.friend.msg.SRejectMMNotify",       OnMsgSRejectMMNotify        },
        { "lx.gs.friend.msg.SDeleteMMNotify",       OnMsgSDeleteMMNotify        },
        { "lx.gs.friend.msg.SDeleteMMForProposeNotify", OnMsgSDeleteMMForProposeNotify },
        { "lx.gs.friend.msg.SSetMMAuthorization",   OnMsgSSetMMAuthorization    },

        { "lx.gs.map.msg.SBekillByOther",     OnMsgBeKillByOther},

    } )
end

return {
    init                = init,
    GetMaimaiInfo       = GetMaimaiInfo,
    RequestMaimai       = RequestMaimai,
    AcceptMaimai        = AcceptMaimai,
    RejectMaimai        = RejectMaimai,
    DeleteMaimai        = DeleteMaimai,
    SetMMAuthorization  = SetMMAuthorization,
}
