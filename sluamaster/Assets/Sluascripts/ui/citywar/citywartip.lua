

local CitywarTip = Class:new()

function CitywarTip:__new(cfg)
    self.m_Config = cfg
end

function CitywarTip:GetStage()
    return self.m_Config.stage
end

function CitywarTip:GetContent()
    return self.m_Config.content
end

return CitywarTip