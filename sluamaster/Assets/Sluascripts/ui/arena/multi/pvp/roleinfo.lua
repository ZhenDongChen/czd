
local RoleInfo = Class:new()

function RoleInfo:__new(msgInfo)
    self.m_Id = msgInfo.roleid or 0
    self.m_Name = msgInfo.name or ""
    self.m_Level = msgInfo.level or 1
    self.m_VipLevel = msgInfo.viplevel or 0
    self.m_Gender = msgInfo.gender or cfg.role.GenderType.MALE
    self.m_Profession = msgInfo.profession
    self.m_Power = msgInfo.combatpower or 0
end


function RoleInfo:GetIcon()
    local professionData = ConfigManager.getConfigData("profession",self.m_Profession)
    local modelName = (self.m_Gender == cfg.role.GenderType.MALE) and professionData.modelname or professionData.modelname2
    local model = ConfigManager.getConfigData("model",modelName)
    return model.headicon or ""
end

function RoleInfo:GetName()
    return self.m_Name
end

function RoleInfo:GetLevel()
    return self.m_Level
end

function RoleInfo:GetPower()
    return self.m_Power
end

return RoleInfo