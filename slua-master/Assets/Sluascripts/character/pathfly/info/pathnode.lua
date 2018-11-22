

local PathNode = Class:new()


function PathNode:__new(config)
    self.m_Time = config.time
    self.m_Position = Vector3(config.position.x, config.position.y, config.position.z)
    self.m_Rotation = Vector3(config.rotation.x, config.rotation.y, config.rotation.z)
    self.m_Scale = Vector3(config.localscale.x, config.localscale.y, config.localscale.z)
    
    self.m_InTangent = Vector3(config.intangent.x, config.intangent.y, config.intangent.z)
    self.m_OutTangent = Vector3(config.outtangent.x, config.outtangent.y, config.outtangent.z)
    
end

function PathNode:GetTime()
    return self.m_Time
end

function PathNode:GetPos()
    return self.m_Position
end

function PathNode:GetRotation()
    return Quaternion.Euler(self.m_Rotation.x, self.m_Rotation.y, self.m_Rotation.z)
end

function PathNode:GetInTangent()
    return self.m_InTangent
end

function PathNode:GetOutTangent()
    return self.m_OutTangent
end

return PathNode