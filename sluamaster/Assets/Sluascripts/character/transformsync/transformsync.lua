local defineenum        = require("defineenum")
local WorkType          = defineenum.WorkType
local mathutils = require("common.mathutils")
local TransformSync = Class:new()

function TransformSync:__new(character)
    self.m_Character = character
end

function TransformSync:SyncMoveTo(msg)
    local msgTarget = Vector3(msg.target.x,msg.target.y,msg.target.z)
    local msgPos = Vector3(msg.position.x,msg.position.y,msg.position.z)
  
    local deviation = mathutils.DistanceOfXoY(self.m_Character:GetRefPos(), msgPos)
    if deviation > 2*SCALE_XY then
        self.m_Character:SetPos(msgPos)
    end
    if msg.isplayercontrol == -1 then
        self.m_Character:MoveTo(msgTarget)
    else
        local deviation2 = mathutils.DistanceOfXoY(self.m_Character:GetRefPos(), msgTarget)
        if deviation2 > 0.3*SCALE_XY then
            self.m_Character:MoveTo(msgTarget)
        end
    end
end

function TransformSync:SyncStop(msg)
    local msgPos = Vector3(msg.position.x,msg.position.y,msg.position.z)
    --local msgPos = Vector3(msg.position.x,msg.position.y,0)
    local msgOrient = msg.orient
    
  	local deviation = mathutils.DistanceOfXoY(self.m_Character:GetRefPos(), msgPos)

    if deviation > 2*SCALE_XY then
        self.m_Character:SetPos(msgPos)
        if msg.isplayercontrol ~= -1 then
            self.m_Character:SetEulerAngle(msgOrient)
        end
    end
    self.m_Character.WorkMgr:StopWork(WorkType.Move)
end

function TransformSync:SyncOrient(msg)
    local msgOrient = msg.orient
    self.m_Character:SetEulerAngle(msgOrient)
end


function TransformSync:LateUpdate()

end


return TransformSync