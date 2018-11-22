local ConfigManager = require("cfg.configmanager")
---------------------------------------------------------------------------------------------------------------------
--好友系统角色信息
local FriendInfo = Class:new()

function FriendInfo:__new(serverInfo)
    local showInfo = serverInfo.roleinfo
    
    self.m_RoleId       = showInfo.roleid     or 0         --角色ID
    self.m_Name         = showInfo.rolename   or "None"    --角色昵称
    self.m_Level        = showInfo.level      or 1         --角色等级
    self.m_VipLevel     = showInfo.viplevel   or 0         --VIP等级
    self.m_Profession   = showInfo.profession or 0         --角色职业
    self.m_Gender       = showInfo.gender     or 0         --性别
    self.m_Power        = showInfo.attackpower or 0         --战斗力
    self.m_Online       = (((showInfo.online == 1) and true) or false)     --是否在线
    self.m_Time         = showInfo.time/1000  or 0         --时间
    
    self.m_CharmDegree  = serverInfo.charmdegree or 0
    self.m_FriendDegree = serverInfo.frienddegree or 0
    
    self.m_Relation     = serverInfo.relation or 0
    
    self.m_AlertDlgId = nil
end

function FriendInfo:SetAlertDlgId(id)
    self.m_AlertDlgId = id
end
function FriendInfo:GetAlertDlgId()
    return self.m_AlertDlgId
end
function FriendInfo:GetId()
    return self.m_RoleId
end

function FriendInfo:IsOnline()
    return self.m_Online
end

function FriendInfo:SetOnline(isOnline)
    self.m_Online = isOnline
end


function FriendInfo:GetName()
    return self.m_Name
end

function FriendInfo:GetCharm()
    return self.m_CharmDegree
end
function FriendInfo:SetCharm(value)
    self.m_CharmDegree = value or 0
end
function FriendInfo:GetFriendDegree()
    return self.m_FriendDegree or 0
end

function FriendInfo:SetFriendDegree(frienddegree)
    self.m_FriendDegree = frienddegree
end

function FriendInfo:GetIcon()

    local professionData = ConfigManager.getConfigData("profession",self.m_Profession)
    local modelName = (self.m_Gender == cfg.role.GenderType.MALE) and professionData.modelname or professionData.modelname2
    local model = ConfigManager.getConfigData("model",modelName)
    return model.headicon or ""
end

function FriendInfo:GetRelation()
    local MaimaiManager = require("ui.maimai.maimaimanager")
    return MaimaiManager.GetMaimaiRelation(self.m_RoleId)
end

function FriendInfo:IsIdol()
    return false
end

function FriendInfo:GetSortValue()
    return self.m_RoleId
end

function FriendInfo:GetSortValueEx()
    return -1
end

function FriendInfo:IsFriend()
    return true
end

function FriendInfo:IsEnemy()
    return false
end

function FriendInfo:IsIdol()
    return false
end

return FriendInfo