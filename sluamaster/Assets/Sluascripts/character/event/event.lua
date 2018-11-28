local defineenum = require "defineenum"
local EventType  = defineenum.EventType
local WorkType   = defineenum.WorkType
local SkillType  = defineenum.SkillType


------------------------------------------------------------------------------------------
-- class Event
------------------------------------------------------------------------------------------
local Event = Class:new()
function Event:__new(type,character)
    self.type         = type or EventType.None
    self.Character    = character
end

function Event:OnEvent()

end

function Event:GetEventType()
    return self.type
end

function Event:Set(character, params)
    self.Character = character
end

------------------------------------------------------------------------------------------
-- class MoveEvent
------------------------------------------------------------------------------------------

local MoveEvent = Class:new(Event)
function MoveEvent:__new(character,params)
    Event.__new(self, EventType.Move, character)
    self.TargetPos   = params.TargetPos or Vector3.zero
    self.SkillTarget = params.SkillTarget or nil
    self.ToCastSkill = params.ToCastSkill or nil
    self.NewSpeed    = params.Speed or nil
end

function MoveEvent:OnEvent()
    Event.OnEvent(self)
    local work = self.Character.WorkMgr:GetWork(WorkType.Move)
    if work then
        work.Target = self.TargetPos
        work.SkillTarget = self.SkillTarget
        work.ToCastSkill = self.ToCastSkill
        work.NewSpeed = self.NewSpeed
        work:Start()
    end
end

function MoveEvent:Set(character, targetPos, speed)
    Event.Set(self, character, nil)
    self.TargetPos   = targetPos or Vector3.zero
    self.SkillTarget = nil
    self.ToCastSkill = nil
    self.NewSpeed    = speed or nil
end


------------------------------------------------------------------------------------------
-- class PathFlyEvent
------------------------------------------------------------------------------------------
local PathFlyEvent = Class:new(Event)
function PathFlyEvent:__new(character,params)
    Event.__new(self, EventType.PathFly, character)
    self.PathCurve = params.PathCurve
    self.EndPosition = params.EndPosition
end

function PathFlyEvent:OnEvent()
    Event.OnEvent(self)
    local work = self.Character.WorkMgr:GetWork(WorkType.PathFly)
    work.PathCurve = self.PathCurve
    work.EndPosition = self.EndPosition

    if work then
        work:Start()
    end
end



------------------------------------------------------------------------------------------
-- class DeadEvent
------------------------------------------------------------------------------------------
local DeadEvent = Class:new(Event)
function DeadEvent:__new(character,params)
    Event.__new(self, EventType.Dead, character)
    self.m_bIsDead = params.isdead
end
function DeadEvent:OnEvent()
    Event.OnEvent(self)
    local work = self.Character.WorkMgr:GetWork(WorkType.Dead)
    if work then
        work.m_bIsDead = self.m_bIsDead
        work:Start()
    end
end


------------------------------------------------------------------------------------------
-- class ReviveEvent
------------------------------------------------------------------------------------------
local ReviveEvent = Class:new(Event)
function ReviveEvent:__new(character,params)
    Event.__new(self, EventType.Relive, character)
end
function ReviveEvent:OnEvent()
    Event.OnEvent(self)
    local work = self.Character.WorkMgr:GetWork(WorkType.Relive)
    if work then
        work:Start()
    end
end


------------------------------------------------------------------------------------------
-- class SkillEvent
------------------------------------------------------------------------------------------
local SkillEvent = Class:new(Event)
function SkillEvent:__new(character,params)
    Event.__new(self, EventType.Skill, character)
    self.Skill = params.Skill or nil
    if self.Skill then self.Action = self.Skill:GetAction(self.Character) end
end

function SkillEvent:OnEvent()
    Event.OnEvent(self)
    if self.Character == nil or self.Skill == nil or self.Action == nil or not self.Character:CanPlaySkill(self.Skill.skillid) then
        return
    end
    local work
    if Local.LogModuals.Skill then
    printyellow("SkillEvent:OnEvent()",self.Skill.skillid,self.Skill:GetActionType())
    end
    if self.Skill:GetActionType() == cfg.skill.ActionType.TALISMAN then
        work = self.Character.WorkMgr:GetWork(WorkType.TalismanSkill)
    else
        work = self.Character.WorkMgr:GetWork(WorkType.NormalSkill)
    end

    if work then
        if work:GetFinished() then
            work.Skill = self.Skill
            work.Action = self.Action
            work:Start()
        end
    end
end


------------------------------------------------------------------------------------------
-- class BeAttackInfo
------------------------------------------------------------------------------------------
local BeAttackInfo = Class:new()
function BeAttackInfo:__new()
    self.AttackerId = 0
    self.Skill = nil
    self.AttackPosition = Vector3.zero
    self.TargetAction = ""
    self.HurtRatio = 1
    self.CurveId = 1
    self.TargetActionFreezeTime = 0
    self.StartTime = 0
    self.EndTime = 0
    self.ContinuousHurt = false
    self.ContinuousHurtInterval = 0

end


------------------------------------------------------------------------------------------
-- class BeAttackedEvent
------------------------------------------------------------------------------------------
local BeAttackedEvent = Class:new(Event)
function BeAttackedEvent:__new(character,params)
    Event.__new(self,EventType.BeAttacked,character)
    self.info = params.info or nil
end

function BeAttackedEvent:OnEvent()
    Event.OnEvent(self)
    if self.Character == nil or self.info == nil then
        return
    end

    local work = self.Character.WorkMgr:GetWork(WorkType.BeAttacked)

    if work then
        work:Add(self.info)
        if work:GetFinished() then
            work:Start()
        end
    end
end

------------------------------------------------------------------------------------------
-- class FreeActionEvent
------------------------------------------------------------------------------------------
local FreeActionEvent = Class:new(Event)
function FreeActionEvent:__new(character,params)
    Event.__new(self,EventType.FreeAction,character)
    self.AnimName = params.AnimName or  ""
end

function FreeActionEvent:OnEvent()

    Event.OnEvent(self)
    local work = self.Character.WorkMgr:GetWork(WorkType.FreeAction)
    work.AnimName = self.AnimName
    if work and work.AnimName ~= nil then
        work:Start()
    end
end

--============================================================================================
--事件池
--============================================================================================
local MoveEventPool = Class:new()

function MoveEventPool:__new(maxnum)
    self.m_Events = { }
    self.m_EventCount = maxnum
    for i = 1, maxnum do
        table.insert( self.m_Events, MoveEvent:new(nil, {}) )
    end
end

function MoveEventPool:GetEvent(character, target, speed)
    if self.m_EventCount > 0 then
        local event = self.m_Events[self.m_EventCount]
        table.remove( self.m_Events, self.m_EventCount )
        self.m_EventCount = self.m_EventCount - 1
        event:Set(character, target, speed)
        return event
    end
    return MoveEvent:new(character, {TargetPos = target, Speed = speed})
end

function MoveEventPool:PushEvent(event)
    table.insert( self.m_Events, event )
    self.m_EventCount = self.m_EventCount + 1
end

local moveEventPoolInst = MoveEventPool:new(50)

local function GetMoveEvent(character, target, speed)
    return moveEventPoolInst:GetEvent(character, target, speed)
end

local function PushMoveEvent(event)
    moveEventPoolInst:PushEvent(event)
end
------------------------------------------------------------------------------------------
-- class EventQuene
------------------------------------------------------------------------------------------
local EventQuene = Class:new()
function EventQuene:__new(char)
    self.m_Character = char
    self.m_Events = {}
end

function EventQuene:Clear()
    if self.m_Events then
        for i, event in ipairs(self.m_Events) do
            if event:GetEventType() == EventType.MoveEvent then
                PushMoveEvent(event)
            end
        end
    end
    utils.clear_table(self.m_Events)
end

function EventQuene:Push(event)
    table.insert(self.m_Events, event)
end

function EventQuene:CreateMoveEvent(character, target, speed)
    local newEvent = GetMoveEvent(character, target, speed)
    table.insert( self.m_Events, newEvent )
end

function EventQuene:RemoveAllEvent(eventtype)
    for i = #self.m_Events, 1 do
        if self.m_Events[i]:GetEventType() == eventtype then
            
            if self.m_Events[i]:GetEventType() == EventType.MoveEvent then
                PushMoveEvent(self.m_Events[i])
            end

            table.remove(self.m_Events, i)
        end
    end
end

function EventQuene:Count()
    return #self.m_Events
end

function EventQuene:Update()
    for i = 1, #self.m_Events do
        self.m_Events[i]:OnEvent()
    end
    self:Clear()
end

--===============================================================================



return
{
    ReviveEvent = ReviveEvent,
    DeadEvent = DeadEvent,
    MoveEvent = MoveEvent,
    SkillEvent = SkillEvent,
    BeAttackInfo = BeAttackInfo,
    BeAttackedEvent = BeAttackedEvent,
    BeAttackInfo = BeAttackInfo,
    FreeActionEvent = FreeActionEvent,
	PathFlyEvent = PathFlyEvent,
    EventQuene = EventQuene,
}
