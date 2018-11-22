

local ArenaData = Class:new()

function ArenaData:__new(id, name, level, value, chiefId)
	self.m_RoleId = id
	self.m_RoleName = name
	self.m_RoleLevel = level
	self.m_RankValue = value
	self.m_ChiefId = chiefId
end

function ArenaData:GetId()
    return self.m_RoleId
end

function ArenaData:GetName()
	return self.m_RoleName
end

return ArenaData
