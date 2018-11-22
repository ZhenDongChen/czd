local Work = require "character.work.work"
local DefineEnum = require "defineenum"
local mathutils = require "common.mathutils"
local WorkType = DefineEnum.WorkType


local AnimFsmState = enum
{
    "None",
    "PathFlyStart",
    "PathFlyLoop",
    "PathFlyEnd",
}

local PathFsmState = enum {
    "None",
    "PathFlyBefore",
    "PathFlyStart",
    "PathFlying",
    "PathFlyEnd",
    "PathFlyAfter",
}

local PathFlyWork = Class:new(Work)

function PathFlyWork:__new()
    Work.__new(self)
    self:reset()
    self.type = WorkType.PathFly
end

function PathFlyWork:reset()
    Work.reset(self)
    self.PathCurve = nil
    self.EndPosition = nil
    self.AnimUpdateNextFrame = false
    self.ElapseTime = 0
    self.StateTime = 0
    self:SetAnimState(AnimFsmState.None)
    self:SetState(PathFsmState.None)
end


function PathFlyWork:OnStart()
    Work.OnStart(self)   
    self.Character:OnPathFlyStart()
    self.ElapseTime = 0
    self.StateTime = 0
    
    self:StartAnimation()
    self:StartTransform()
end

function PathFlyWork:OnEnd()
    Work.OnEnd(self)   
    self.Character:OnPathFlyEnd()
    self:EndAnimation()
    self:EndTransform()
end

function PathFlyWork:SetAnimState(state)
    self.AnimState = state
    self.AnimUpdateNextFrame = true
end

function PathFlyWork:SetState(state)
    self.PathState = state
    self.StateTime = 0
end

function PathFlyWork:OnUpdate()
    Work.OnUpdate(self)
    self:UpdateTransform()
    self:UpdateAnimation()
    self.ElapseTime = self.ElapseTime + Time.deltaTime
    self.StateTime = self.StateTime + Time.deltaTime
end
--============================================================================================================================
--[[
    动画更新
]]

function PathFlyWork:StartAnimation()
   -- self:SwitchToAnimStart()
end

function PathFlyWork:EndAnimation()
    
end

function PathFlyWork:UpdateAnimation()
    if self.AnimUpdateNextFrame == true then
        self.AnimUpdateNextFrame = false
        return
    end
    if self.AnimState == AnimFsmState.PathFlyStart then
        if not self.Character:IsPlayingPathFlyStart() then
            self:SwitchToAnimLoop()
        end
    elseif self.AnimState == AnimFsmState.PathFlyLoop then
     --   if not self.Character:IsPlayingPathFlyLoop() then
       --     self:SwitchToAnimEnd()
     --   end
    elseif self.AnimState == AnimFsmState.PathFlyEnd then
        if not self.Character:IsPlayingPathFlyEnd() then
            self:End()
        end
    end
end


function PathFlyWork:SwitchToAnimStart()
    self.Character:PlayAction(cfg.skill.AnimType.PathFlyStart)
    
    self:SetAnimState(AnimFsmState.PathFlyStart)
end

function PathFlyWork:SwitchToAnimLoop()
    self.Character:PlayLoopAction(cfg.skill.AnimType.PathFlyLoop)
    
    self:SetAnimState(AnimFsmState.PathFlyLoop)
end

function PathFlyWork:SwitchToAnimEnd()
    self.Character:PlayAction(cfg.skill.AnimType.PathFlyEnd)
    
    self:SetAnimState(AnimFsmState.PathFlyEnd)
end



--============================================================================================================================
--[[
    位置更新
]]
function PathFlyWork:StartTransform()
    local playerposition = self:GetCharacterPosition()
    self.PathCurve:SetStartPos(playerposition)
    self.PathCurve:SetEndPos(self.EndPosition)
    self:SetState(PathFsmState.PathFlyBefore)
    --printyellow("StartTransform")
end

function PathFlyWork:EndTransform()
    --printyellow("EndTransform")
    self:SetCharacterPosition(self.EndPosition)
end

function PathFlyWork:UpdateTransform()
    --printyellow("UpdateTransform")
    
    if self.PathState == PathFsmState.PathFlyBefore then
        self:UpdateTransformBefore()
    elseif self.PathState == PathFsmState.PathFlyStart then
        self:UpdateTransformStart()
    elseif self.PathState == PathFsmState.PathFlying then
        self:UpdateTransformLoop()
    elseif self.PathState == PathFsmState.PathFlyEnd then
        self:UpdateTransformEnd()
    elseif self.PathState == PathFsmState.PathFlyAfter then
        self:UpdateTransformAfter()
    end
end

function PathFlyWork:UpdateTransformBefore()
    self:SwitchToAnimStart()
    self:SetState(PathFsmState.PathFlyStart)
end

function PathFlyWork:UpdateTransformStart()
    local playerposition = self:GetCharacterPosition()
    local position = self.PathCurve:GetPosOfStartPath(self.StateTime)
    --printyellow("SetStartPos",self.StateTime,position)
    local direction = position - playerposition
    if self.PathCurve:ReachFirstPos(playerposition) then
        self:SetState(PathFsmState.PathFlying)
    else
        self:SetCharacterPosition(position)
        self:SetCharacterRotation(mathutils.PosGetAngle(direction))
    end
end

function PathFlyWork:UpdateTransformLoop()
    local playerposition = self:GetCharacterPosition()
    local position = self.PathCurve:GetPosOfCurvePath(self.StateTime)
    local direction = Vector3(0,0,1)
    if self.PathCurve:IsRotationVary() == false then
        direction = position - playerposition
    else
        local rotation = self.PathCurve:GetRotation(self.StateTime)
        direction = rotation * Vector3(0,0,1)
    end
    
    local direction = position - playerposition
    if self.PathCurve:ReachLastPos(playerposition) then
        self:SetState(PathFsmState.PathFlyEnd)
    else
        self:SetCharacterPosition(position)
        self:SetCharacterRotation(mathutils.PosGetAngle(direction))    
    end
end

function PathFlyWork:UpdateTransformEnd()
    local playerposition = self:GetCharacterPosition()
    local position = self.PathCurve:GetPosOfEndPath(self.StateTime)
    local direction = position - playerposition
    
	
    self:SetCharacterPosition(position)
    self:SetCharacterRotation(mathutils.PosGetAngle(direction))
    self:SetState(PathFsmState.PathFlyAfter)
    --[[if self.PathCurve:ReachEndPos(playerposition) then
        self:SetState(PathFsmState.PathFlyAfter)
    else
        self:SetCharacterPosition(position)
        self:SetCharacterRotation(mathutils.PosGetAngle(direction))
    end]]
end

function PathFlyWork:UpdateTransformAfter()
    --self:End()
    self:SwitchToAnimEnd()
    self:SetState(PathFsmState.None)
end


function PathFlyWork:GetCharacterPosition()
    return self.Character:GetPos()
end

function PathFlyWork:SetCharacterPosition(pos)
    self.Character:SetPos(pos)
end

function PathFlyWork:SetCharacterRotation(vec)
    self.Character:SetEulerAngle(vec)
end

return PathFlyWork
