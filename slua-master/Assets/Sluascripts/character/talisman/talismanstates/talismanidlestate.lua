local defineenum=require("defineenum")
local TalismanConfig = require("character.talisman.talismanconfig")
local StateType = TalismanConfig.StateType

local MoveStateType = { Null = 0,  Idle = 1,  Locus1 = 3,  Locus2 = 4,  Locus3 = 5,  Locus4 = 6,  Locus5 = 7,  Locus6 = 8, }

local TalismanIdleState = Class:new()

function TalismanIdleState:__new()
    self.m_IsStart = false
    self.m_Controller = nil
    self.m_Ticks = 0
    self.m_State = MoveStateType.Idle
    self.m_StateTime = 0
    self.m_RadSpeed = 1
    self.m_OffsetY = 0.5
    self.m_Rad = 0
    self.m_lastH = 0.5
    self.m_lastRad = 0
    self.m_MoveSpeed = 0
end

function TalismanIdleState:Start(controller)
    self.m_IsStart = true
    self.m_IsEnd = false
    self.m_Controller = controller
    self.m_LastState = MoveStateType.Idle

    self.SpeedMax = 5
    self.SpeedMin = 1
    self.m_MoveSpeed = 0
    self.m_Acceleration = 2
    self.m_TargetPos = self.m_Controller:GetPos()
    self.curRadSpeed = 0
    self:SetMotionState(true)
end


function TalismanIdleState:SetMotionState(skip)
    if self.m_Ticks < self.m_StateTime and skip == nil then
        return
    end
    self.m_Ticks = 0
    self.m_lastRad = self.m_Controller.m_CharacterState.m_Rotation.eulerAngles.y
    self.m_LastPos = self.m_Controller:GetPos()
    self.m_lastH = self.m_Controller:GetPos().y - self.m_Controller.m_CharacterState.m_Position.y

    if self.m_State == MoveStateType.Idle then
        self.m_State = math.random(MoveStateType.Locus1, MoveStateType.Locus6)

        self.m_StateTime = math.random(4, 5)
        self.m_RadSpeed = math.random(3, 5) * 5

        self.m_Rad = self.m_RadSpeed * self.m_StateTime
        self.m_OffsetY = math.random(3,18)/10

    else
        self.m_State = MoveStateType.Idle
        self.m_RadSpeed = 0
        self.m_StateTime = math.random(1, 2)/2
    end
end


function TalismanIdleState:IsStart()
    return self.m_IsStart
end

function TalismanIdleState:Update(deltaTime)
    self.m_Ticks = self.m_Ticks + deltaTime
    local curPos = self.m_Controller:GetPos()
    local masterPos = self.m_Controller.m_CharacterState.m_Position
    local accceleration = self.m_Controller.m_Acceleration
    self:SetMotionState()
    if self.m_State == MoveStateType.Idle then
        return
    end

    local rad = 0
    local h = self.m_lastH + (self.m_OffsetY - self.m_lastH) *  self.m_Ticks / self.m_StateTime

    if self.m_State == MoveStateType.Locus1 then
        rad = self.m_Ticks * self.m_RadSpeed
        h = self.m_Ticks * 0.1 + 0.6
    elseif self.m_State == MoveStateType.Locus2 then
        rad = self.m_Ticks * self.m_RadSpeed
        h = self.m_Ticks * 0.2
    elseif self.m_State == MoveStateType.Locus3 then
        rad = self.m_Ticks * self.m_RadSpeed
        h = 0.5
    elseif self.m_State == MoveStateType.Locus4 then
        rad = 0
        h = self.m_Ticks * 0.1 + 0.6
    elseif self.m_State == MoveStateType.Locus5 then
        rad = 0 - self.m_Ticks * self.m_RadSpeed
        h = self.m_Ticks * 0.2
    elseif self.m_State == MoveStateType.Locus6 then
        rad = 0 - self.m_Ticks * self.m_RadSpeed
        h = 0.5
    end

    if self.curRadSpeed < self.m_RadSpeed then
        self.curRadSpeed = self.curRadSpeed + deltaTime * 5
    elseif self.curRadSpeed > 1.5 * self.m_RadSpeed then
        self.curRadSpeed = self.curRadSpeed - deltaTime * 5
    end

    local radSpeed = self.curRadSpeed

    local vec = self.m_LastPos - masterPos
    vec.y = 0
    self.m_TargetPos = masterPos + Quaternion.Euler(0, rad, 0) * vec.normalized * TalismanConfig.DefaultPos.x
    self.m_TargetPos.y = masterPos.y + h

    local dir = self.m_TargetPos - curPos
    local distance = dir.magnitude


    if distance > 0.3 then

        if self.m_MoveSpeed < self.SpeedMax then
            self.m_MoveSpeed = self.m_MoveSpeed + self.m_Acceleration * deltaTime
        end
    elseif distance > 0.1*self.m_MoveSpeed * deltaTime then
        if self.m_MoveSpeed > self.SpeedMin then
            self.m_MoveSpeed = self.m_MoveSpeed - self.m_Acceleration * deltaTime
        end
        if self.m_MoveSpeed < self.SpeedMin then
            self.m_MoveSpeed = self.SpeedMin
        end
        if self.m_MoveSpeed < distance then
            self.m_MoveSpeed = distance
        end
    elseif distance > 0.05 * self.m_MoveSpeed * deltaTime then
        self.m_MoveSpeed = 0
        self.m_Controller:SetPos(self.m_TargetPos)
        --dir = self:.m_Controller:Get.eulerAngles
        if self.m_State ~= MoveStateType.Idle then
            self:SetMotionState()
        end
    end

    if self.m_MoveSpeed > SCALE_XY then
        self.m_MoveSpeed = 0
    end
    if dir.x > SCALE_XY then
        dir.x = 0
    end
    if dir.y > SCALE_XY then
        dir.y = 0
    end
    if dir.z > SCALE_XY then
        dir.z = 0
    end


    self.m_Controller:SetRotation(Quaternion.Euler(0,dir.y,0))

    if dir.magnitude > self.m_MoveSpeed * deltaTime then
        self.m_Controller:SetPos(curPos + dir.normalized * self.m_MoveSpeed * deltaTime)
    else
        self.m_Controller:SetPos(curPos + dir)
    end
end

function TalismanIdleState:End()
    self.m_IsStart = false
    self.m_IsEnd = true
    self.m_Ticks = 0
end



function TalismanIdleState:Transitions()
    local result = nil
    if self.m_Controller.m_CharacterState.m_IsMoving then
        result = StateType.Follow
    else
        result = nil
    end
    return self.m_Controller:GlobalTransitions() or result
end



return TalismanIdleState
