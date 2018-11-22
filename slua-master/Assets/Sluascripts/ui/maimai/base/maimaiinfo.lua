local MaimaiMap     = require("ui.maimai.base.maimaimap")
local RoleInfo      = require("ui.maimai.base.roleinfo")


local MaimaiInfo = Class:new()

function MaimaiInfo:__new(role,serverInfo)
  --  printyellow("MaimaiInfo:__new",role,serverInfo)
    self.m_Role         = role or nil
    
    self.m_MaimaiMap    = MaimaiMap:new(self, serverInfo)
    self.m_Parent       = nil
end

function MaimaiInfo:GetRole()
    return self.m_Role
end
function MaimaiInfo:GetId()
    if self.m_Role then
        return self.m_Role:GetId()
    else
        return -1
    end
end


function MaimaiInfo:IsPlayer()
    return (self.m_Role:GetId() == PlayerRole:Instance().m_Id) and true or false
end

function MaimaiInfo:IsFriend()
    return self.m_MaimaiMap:Exist(PlayerRole:Instance().m_Id)
end
function MaimaiInfo:Get(relation, num)
    if relation == -1 then
        return self
    end
 --   printyellow("Geting ... ...",relation, num)
    
    return self.m_MaimaiMap:Get(relation, num)
end

function MaimaiInfo:GetById(roleid)
    if self:GetId() == roleid then
        return self
    end
 --   printyellow("GetById", roleid)
    return self.m_MaimaiMap:GetById(roleid)
end

function MaimaiInfo:GetRelation(roleid)
    return self.m_MaimaiMap:GetRelation(roleid)
end

function MaimaiInfo:GetIndex(roleid)
    return self.m_MaimaiMap:GetIndex(roleid)
end



function MaimaiInfo:Add(relation,role)
    local mmInfo = MaimaiInfo:new(role, nil)
    mmInfo.m_Parent = self
    self.m_MaimaiMap:Add(relation,mmInfo)
end

function MaimaiInfo:ResetMapInfo(serverInfo)
    self.m_MaimaiMap = MaimaiMap:new(self, serverInfo)
end


function MaimaiInfo:Remove(relation, id)
    self.m_MaimaiMap:Remove(relation, id)
end


return MaimaiInfo