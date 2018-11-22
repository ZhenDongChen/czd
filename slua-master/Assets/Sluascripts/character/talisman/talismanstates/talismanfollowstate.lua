local TalismanConfig = require("character.talisman.talismanconfig")
local StateType = TalismanConfig.StateType


local TalismanFollowState = Class:new()

function TalismanFollowState:__new()
    self.m_IsStart = false
    self.m_Controller = nil
    self.m_MoveSpeed = 0
    self.m_LastSpeed = 0
end

function TalismanFollowState:Start(controller)
    self.m_IsStart = true
    self.m_IsEnd = false
    self.m_Controller = controller
    self.m_MoveSpeed = 0
    
end

function TalismanFollowState:IsStart()
    return self.m_IsStart
end

function TalismanFollowState:GetSpeed(newSpeed)
    local speed = newSpeed
    if self.m_LastSpeed ~= nil then
         speed = (self.m_LastSpeed + speed)/2
    end
    self.m_LastSpeed = newSpeed
    return speed
end

function TalismanFollowState:StrategyOne(deltaTime)

    local masterPos = self.m_Controller.m_CharacterState.m_Position
    local masterRot = self.m_Controller.m_CharacterState.m_Rotation
    local masterSpd = self.m_Controller.m_CharacterState.m_MoveSpeed
    local curPos = self.m_Controller:GetPos()

    
    local targetPos = masterPos + masterRot * TalismanConfig.DefaultPos
    
    local maxSpeed = masterSpd
    local minSpeed = TalismanConfig.MinMoveSpeed
    local minSpeed = TalismanConfig.MinMoveSpeed
    local accceleration = TalismanConfig.FollowSetting.DefaultAcceleration
   
    local vec = targetPos - self.m_Controller:GetPos()
    local dir = vec.normalized
    local distance = vec.magnitude
    deltaTime = Time.deltaTime

    if distance > 3 then
        self.m_MoveSpeed = maxSpeed
    elseif distance > 1 then
        if self.m_MoveSpeed < maxSpeed then
            self.m_MoveSpeed = self.m_MoveSpeed + accceleration * deltaTime
        else
            self.m_MoveSpeed = maxSpeed
        end
    elseif distance > 0.5 then
        self.m_MoveSpeed = self.m_MoveSpeed
    elseif distance > 0.2 then
        if self.m_Controller.m_CharacterState.m_IsMoving then
            self.m_MoveSpeed = self.m_MoveSpeed
        else
            if self.m_MoveSpeed > minSpeed then
                self.m_MoveSpeed = self.m_MoveSpeed - accceleration * deltaTime
            end
            if self.m_MoveSpeed < minSpeed then
                self.m_MoveSpeed = minSpeed
            end
        end
    elseif distance < 0.05 then
        if self.m_Controller.m_CharacterState.m_IsMoving then
            self.m_MoveSpeed = self.m_MoveSpeed
        else
            self.m_MoveSpeed = 0
        end
    end

    self.m_MoveSpeed = self:GetSpeed(self.m_MoveSpeed)
    --设置位置、方向
    if distance > TalismanConfig.FollowSetting.BlinkDistance then
        self.m_Controller:SetRotation(Quaternion.LookRotation(dir),false)
        self.m_Controller:SetPos(targetPos - dir * TalismanConfig.FollowSetting.BlinkTargetDistance)
    elseif distance > TalismanConfig.FollowSetting.StopDistance then
        self.m_Controller:SetRotation(Quaternion.LookRotation(dir),false)
        local vecPos = Vector3.zero
        if distance < self.m_MoveSpeed * deltaTime then
            vecPos = Vector3(targetPos.x, targetPos.y, targetPos.z)
            self:End()
        else
            vecPos = curPos + dir * self.m_MoveSpeed * deltaTime
        end
        self.m_Controller:SetPos( vecPos)
    else
        self:End()
    end
    if distance < 0.1 then
        self:End()
    end
end

function TalismanFollowState:StrategyTwo(deltaTime)
    local masterPos = self.m_Controller.m_CharacterState.m_Position
    local masterRot = self.m_Controller.m_CharacterState.m_Rotation
    local masterSpd = self.m_Controller.m_CharacterState.m_MoveSpeed
    local targetPos = masterPos + masterRot * TalismanConfig.DefaultPos
    
    local vec = targetPos - self.m_Controller:GetPos()
    local dir = vec.normalized
    local distance = vec.magnitude
    deltaTime = Time.deltaTime
    
    if self.m_LastDistance == nil then
        self.m_LastDistance = distance
    end
    if self.AllDisCount == nil then
        self.AllDisCount = 0
    end
    self.AllDisCount = self.AllDisCount + 1
    if self.m_AllDistance == nil or self.AllDisCount >=10 then
        self.m_AllDistance = distance
        self.AllDisCount = 0
    else
        self.m_AllDistance = self.m_AllDistance + distance
    end

    local speed = distance * 1 + (distance - self.m_LastDistance) * 0.1 + self.AllDisCount * 0.1
    self.m_LastDistance = distance


    local vecPos = self.m_Controller:GetPos() + dir * speed * deltaTime
    
    if distance > TalismanConfig.FollowSetting.BlinkDistance then
        self.m_Controller:SetRotation(Quaternion.LookRotation(dir),false)
        self.m_Controller:SetPos(targetPos - dir * TalismanConfig.FollowSetting.BlinkTargetDistance)
    elseif distance > 0.1 then
        self.m_Controller:SetPos(vecPos)
    else
        self:End()
    end

end

function TalismanFollowState:Update(deltaTime)
    self:StrategyOne(deltaTime)
    --self:StrategyTwo(deltaTime)
end

function TalismanFollowState:End()
    self.m_IsStart = false
    self.m_IsEnd = true
end

function TalismanFollowState:Reset()
    self.m_IsStart = false
    self.m_IsEnd = true
end

function TalismanFollowState:Transitions()
    local result = nil
    if self.m_Controller.m_CharacterState.m_IsMoving then
        result = StateType.Follow
    elseif self.m_IsEnd then
        result = StateType.Idle
    else
        result = nil
    end
    return self.m_Controller:GlobalTransitions() or result
end

return TalismanFollowState
