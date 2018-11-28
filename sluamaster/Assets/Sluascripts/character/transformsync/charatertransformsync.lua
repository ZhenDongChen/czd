local TransformSync = require("character.transformsync.transformsync")
local defineenum        = require("defineenum")
local WorkType          = defineenum.WorkType

local CharacterTransformSync = Class:new(TransformSync)


function CharacterTransformSync:SyncMoveTo(msg)
    local msgTarget = Vector3(msg.target.x,msg.target.y,msg.target.z)
    local msgPos = Vector3(msg.position.x,msg.position.y,msg.position.z)
    local rolePos = self.m_Character:GetPos()
    local positionDeviation = mathutils.DistanceOfXoY(rolePos, msgPos)
    local targetDeviation = mathutils.DistanceOfXoY(rolePos, msgTarget)

    if positionDeviation > 200 then
        if targetDeviation > 200 then
            self.m_Character:SetPos(msgPos)
        end
    end
    if msg.isplayercontrol == -1 then
        self.m_Character:MoveTo(msgTarget)
    else
        if targetDeviation > 30 then
            self.m_Character:MoveTo(msgTarget)
        end
    end
end

function CharacterTransformSync:SyncStop(msg)
    local msgPos = Vector3(msg.position.x,msg.position.y,msg.position.z)
    local msgOrient = msg.orient
    local rolePos = self.m_Character:GetPos()
  	local deviation = mathutils.DistanceOfXoY(rolePos, msgPos)
    
    if deviation > 200 then
        self.m_Character:SetPos(msgPos)
        self.m_Character:SetEulerAngle(msgOrient)
    elseif deviation > 30 then
        if self.m_Character and self.m_Character.m_Object and msg.isplayercontrol ~= -1 then
            local curDir = self.m_Character.m_Object.transform.forward
            local movDir = msgPos - rolePos
            local angle = math.abs(mathutils.AngleOfXoY(curDir, movDir))
            if deviation < 25 then
                if angle < 70 then
                    self.m_Character:MoveTo(msgPos)
                end
            else
                if angle < 45 then
                    self.m_Character:MoveTo(msgPos)
                end
            end
        end
    
    end
    self.m_Character.WorkMgr:StopWork(WorkType.Move)
end



return CharacterTransformSync