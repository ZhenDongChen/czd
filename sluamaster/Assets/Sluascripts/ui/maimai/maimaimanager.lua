local MaimaiInfo    = require("ui.maimai.base.maimaiinfo")
local MaimaiMap     = require("ui.maimai.base.maimaimap")
local RoleInfo      = require("ui.maimai.base.roleinfo")



local Network       = require("network")
local UIManager     = require("uimanager")
--local FriendManager = require("ui.friend.friendmanager")
local MaimaiSync    = require("ui.maimai.base.maimaimanager_sync")





local MaimaiData = {
    m_IsAllowFriendCheck = true,
    m_IsAllowStrangerCheck = false,
    m_PlayerRoleMaimaiInfo = nil,
    m_LastCheckedMaimaiInfo = nil,
    m_CurrentCheckedMaimaiInfo = nil,
}


local function InitMaimaiInfo(msg)

    MaimaiData.m_IsAllowFriendCheck     = (((msg.allowfriendgetmm == 1) and true) or false)
    MaimaiData.m_IsAllowStrangerCheck   = (((msg.allowstrangergetmm == 1) and true) or false)
    MaimaiData.m_PlayerRoleMaimaiInfo   = MaimaiInfo:new(RoleInfo:CreateFromRole(),msg.relations)
    MaimaiData.m_CurrentCheckedMaimaiInfo = MaimaiData.m_PlayerRoleMaimaiInfo
end

local function GetMaimaiInfo()
    return MaimaiData.m_PlayerRoleMaimaiInfo
end

--请求加脉脉（roleId：对方角色ID，maimaiType：加脉脉的类型）
local function RequestMaimai(roleId,relation)
    MaimaiSync.RequestMaimai(roleId,relation)
end

local function AddNewMaimaiInfo(roleid, msgmmInfo)
   -- printyellow("MaimaiData.m_CurrentCheckedMaimaiInfo", MaimaiData.m_CurrentCheckedMaimaiInfo,MaimaiData.m_PlayerRoleMaimaiInfo)

    MaimaiData.m_LastCheckedMaimaiInfo = MaimaiData.m_CurrentCheckedMaimaiInfo
    local lastmmInfo = MaimaiData.m_LastCheckedMaimaiInfo ~= nil and MaimaiData.m_LastCheckedMaimaiInfo:GetById(roleid) or nil
    --printyellow()

    if lastmmInfo == nil then
        if Local.LogModuals.Maimai == true then
            logError("找不到角色：", roleid)
        end
        return nil
    end
    MaimaiData.m_CurrentCheckedMaimaiInfo = MaimaiInfo:new(lastmmInfo.m_Role, msgmmInfo)
    return MaimaiData.m_CurrentCheckedMaimaiInfo
end

local function SetCurrentMaimaiInfo(mmInfo)
    MaimaiData.m_CurrentCheckedMaimaiInfo = mmInfo
end

local function GetLastMaimaiInfo()
    return MaimaiData.m_LastCheckedMaimaiInfo
end

--显示脉脉界面
local function ShowMaimaiDialog(roleId)
    if roleId == nil or roleId == PlayerRole:Instance().m_Id then
        UIManager.showdialog("maimai.tabmaimai")
    else
        MaimaiSync.GetMaimaiInfo(roleId)
    end
end

--删除脉脉
local function DeleteMaimai(roleId,relation)
    MaimaiSync.DeleteMaimai(roleId,relation)
end

--修改好友及陌生人查看权限
local function SetMMAuthorization(allowFriendCheck,allowStrangeCheck)
    MaimaiSync.SetMMAuthorization(allowFriendCheck,allowStrangeCheck)
end
local function GetMMAuthorization()
    return MaimaiData.m_IsAllowFriendCheck, MaimaiData.m_IsAllowStrangerCheck
end



--获取脉脉关系
local function GetMaimaiRelation(roleId)
    return  MaimaiData.m_PlayerRoleMaimaiInfo~=nil and  MaimaiData.m_PlayerRoleMaimaiInfo:GetRelation(roleId) or nil
end

--初始化
local function init()
    MaimaiSync.init()
end

local function UnRead()
    return false
end

return {
    init                    = init,
    InitMaimaiInfo          = InitMaimaiInfo,
    GetMaimaiInfo           = GetMaimaiInfo,
    AddNewMaimaiInfo        = AddNewMaimaiInfo,
    SetCurrentMaimaiInfo    = SetCurrentMaimaiInfo,
    GetLastMaimaiInfo       = GetLastMaimaiInfo,
    SetMMAuthorization      = SetMMAuthorization,
    GetMMAuthorization      = GetMMAuthorization,

    MaimaiData              = MaimaiData,

    ShowMaimaiDialog        = ShowMaimaiDialog,
    RequestMaimai           = RequestMaimai,
    DeleteMaimai            = DeleteMaimai,
    GetMaimaiRelation       = GetMaimaiRelation,
    UnRead                  = UnRead,
}
