local ConfigManager = require("cfg.configmanager")
local PlotConfig = Class:new()

function PlotConfig:__new()    
    self.m_Profession = PlayerRole:Instance().m_Profession
    self.m_Gender = PlayerRole:Instance().m_Gender

    self.m_Config = ConfigManager.getConfig("plotconfig")
    self.m_ProfessionConfig = self.m_Config.professtionconfig[self.m_Profession]
    self.m_GenderConfig = self.m_ProfessionConfig.genderconfig[self.m_Gender]
end

function PlotConfig:GetProfessionDeviation()
    local deviation = self.m_GenderConfig.cameradeviation
    return Vector3(deviation.x, deviation.y, deviation.z)
end

function PlotConfig:ProfessionHandIndex()
    local rolehandlename = self.m_GenderConfig.rolehandlename
    return rolehandlename
end

function PlotConfig:GetRoleModelName()
    return self.m_GenderConfig.rolemodelname
end


return PlotConfig

--return Config



