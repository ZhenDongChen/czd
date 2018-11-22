local defineenum        = require "defineenum"
local WorkType          = defineenum.WorkType
local IdleWork          = require "character.work.idlework"
local MoveWork          = require "character.work.movework"
local SkillWork         = require "character.work.skillwork"
local TalismanSkillWork = require "character.work.talismanskillwork"
local BeAttackedWork    = require "character.work.beattackedwork"
local DeadWork          = require "character.work.deadwork"
local ReviveWork        = require "character.work.revivework"
local FreeActionWork    = require "character.work.freeactionwork"
local PathFlyWork       = require "character.work.pathflywork"


local WorkManager = Class:new()
function WorkManager:__new(character)
    self:reset(character)
end

function WorkManager:reset(character)
    self.m_Works = { }
    self.Character = character
    self:Init(self.Character)
    self:SetJudgeNeedIdle(true)
end

function WorkManager:Init(character)
    self.Character = character
    for type, value in pairs(WorkType) do
        local work = self:CreateWork(value)
        if work then
            work.Character = self.Character
            work:End()
            self.m_Works[value] = work
        end
    end
end

function WorkManager:CreateWork(workType)
    local work = nil

    if workType == WorkType.Idle then
        work = IdleWork:new()
    elseif workType == WorkType.Move then
        work = MoveWork:new()
    elseif workType == WorkType.NormalSkill then
        work = SkillWork:new()
    elseif workType == WorkType.TalismanSkill then
        work = TalismanSkillWork:new()
    elseif workType == WorkType.BeAttacked then
        work = BeAttackedWork:new()
    elseif workType == WorkType.Dead then
        work = DeadWork:new()
    elseif workType == WorkType.Relive then
        work = ReviveWork:new()
    elseif workType == WorkType.FreeAction then
        work = FreeActionWork:new()
    elseif workType == WorkType.PathFly then
        work = PathFlyWork:new()
    end

    return work
end

function WorkManager:GetWork(workType)
    if self.m_Works[workType] then
        return self.m_Works[workType]
    end
    return nil
end

function WorkManager:IsWorking(workType)
    local work = self:GetWork(workType)
    if work then
        return not work:GetFinished()
    else
        return false
    end
end 

function WorkManager:StopWork(workType)
    if self:IsWorking(workType) then
        self.m_Works[workType]:End()
    end
end

function WorkManager:DelayStopWork(workType)
    if self:IsWorking(workType) then
        self.m_Works[workType].delayStop = true
    end
end

function WorkManager:Revive()
    self:StopWork(WorkType.Dead)
end

function WorkManager:IsWorkingSkill()
    return self:IsWorking(WorkType.NormalSkill) or self:IsWorking(WorkType.TalismanSkill)
end

function WorkManager:StopSkillWork()
    self:StopWork(WorkType.NormalSkill)
    self:StopWork(WorkType.TalismanSkill)
end

function WorkManager:GetSkillWork() 
    if self:IsWorking(WorkType.NormalSkill) then 
        return self.m_Works[WorkType.NormalSkill]
    elseif self:IsWorking(WorkType.TalismanSkill) then 
        return self.m_Works[WorkType.TalismanSkill]
    end
end


function WorkManager:Update()   
    for type, work in pairs(self.m_Works) do
        work:Update()
        if work.delayStop~=nil and work.delayStop then
            work:End()
        end
    end
    self:UpdateJudgeNeedIdle()
end

function WorkManager:UpdateJudgeNeedIdle()
    if self.JudgeNeedIdle  then
        local needIdle = true
        for type, work in pairs(self.m_Works) do
           if work:GetWorkType() ~= WorkType.Idle and not work:GetFinished() then
                needIdle = false
                break
            end
        end

        if needIdle then
            if self.m_Works[WorkType.Idle]:GetFinished() then
                self.m_Works[WorkType.Idle]:Start()
            end
        else
            if not self.m_Works[WorkType.Idle]:GetFinished() then
                self.m_Works[WorkType.Idle]:End()
            end
        end
    end
end

function WorkManager:Release()
    for type, work in pairs(self.m_Works) do
        work:Release()
    end
end

function WorkManager:BreakSkillWork(interrupt)
    local skillwork = self:GetSkillWork()
    if skillwork and interrupt then 
        skillwork:OnBreakSkillWork()
    end 
    self:StopSkillWork()
end

function WorkManager:SetJudgeNeedIdle(needIdle)
    if not needIdle then 
        
    end 
    self.JudgeNeedIdle = needIdle
end 

function WorkManager:ResumeWork() 
    for _, work in pairs(self.m_Works) do
        if not work:GetFinished() then 
            work:ResumeWork()
        end 
    end
end 

function WorkManager:ShutAllWorks()
    for _, v in pairs(WorkType) do
        self:StopWork(v)
    end
    self:SetJudgeNeedIdle(false)
end

function WorkManager:ReStartWorks()
    self:Init(self.Character)
    self:SetJudgeNeedIdle(true)
end

return WorkManager