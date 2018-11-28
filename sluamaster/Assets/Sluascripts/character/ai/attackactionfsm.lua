local Fsm          = require "character.ai.fsm"
local event        = require "character.event.event"
local SkillManager = require "character.skill.skillmanager"
local defineenum   = require "defineenum"
local SkillType    = defineenum.SkillType
local WorkType     = defineenum.WorkType


local AttackActionFsm = Class:new(Fsm)
function AttackActionFsm:__new(character)
    self:reset()
    self.Attacker = character
end

AttackActionFsm.FsmState = enum{
    "None",
    "BeforeAttackAction",
    "Attacking",
    "AfterAttackAction",
}

function AttackActionFsm:reset()
    Fsm.reset(self)
    self:ResetData()
end

function AttackActionFsm:ResetData()
    self.StartAttackingTime   = 0
    self.EndAttackingTime     = 0
    self.AttackFreezeTime     = 0
    self.AttackFreeze         = false
    self.bCastCallBackSkill   = false
    self.CurrentSkill         = nil     --skill
    self.SkillData            = nil     --skilldata ：法宝技能类型对应的是角色的动作
    self.CurrentHitPointIndex = 1       --当前打击点
    self:SetState(self.FsmState.None)
    if self.Attacker then
        self.Attacker:HideSkillRange()
    end
end


function AttackActionFsm:SetAttackAction(skillId)
    self:reset()
    self.skillId = skillId

    self.CurrentSkill = SkillManager.GetSkill(self.skillId)


    self.bCastCallBackSkill = self.CurrentSkill:GetActionType() == cfg.skill.ActionType.QTE

    if self.CurrentSkill:GetActionType() == cfg.skill.ActionType.TALISMAN then
        self.SkillData = self.Attacker:GetTalismanAction()
    else
        self.SkillData = self.CurrentSkill:GetAction(self.Attacker)
    end

    if self.CurrentSkill == nil or self.SkillData == nil then
        return
    end

    self.StartTime = Time.time
    self.StartAttackingTime = 0
    self.EndAttackingTime = self.SkillData.endattackingtime

    self:Start()
end


function AttackActionFsm:SetState(state)
    if Local.LogModuals.Skill then
        printyellow("AttackActionFsm:SetState(state)",utils.getenumname(self.FsmState,state),Time.time)
    end
    self.CurrentState = state
end

function AttackActionFsm:Start()

    Fsm.Start(self)

    self:SetState(self.FsmState.BeforeAttackAction)

end

function AttackActionFsm:Update()
    Fsm.Update(self)

    if self.CurrentState == self.FsmState.BeforeAttackAction then
        self:UpdateBeforeAttackState()
    elseif self.CurrentState == self.FsmState.Attacking then
        self:UpdateAttackingState()
    elseif self.CurrentState == self.FsmState.AfterAttackAction then
        self:UpdateAfterAttackState()
    end
end



function AttackActionFsm:UpdateBeforeAttackState()
    if self.elapsedTime >= self.StartAttackingTime then
        self:SetState(self.FsmState.Attacking)
    end
end

function AttackActionFsm:UpdateAttackingState()
    if self.elapsedTime > self.EndAttackingTime+ self.AttackFreezeTime then
        if Local.LogModuals.Skill then
            printyellow("self.elapsedTime",self.elapsedTime,"Time.time",Time.time,"self.StartTime ",self.StartTime,"self.EndAttackingTime",self.EndAttackingTime )
        end
        self:OnEndAttacking()
        return
    end
end

function AttackActionFsm:UpdateAfterAttackState()

    if self.Attacker.WorkMgr:IsWorkingSkill() then
        if self.Attacker:IsMoving() then
            self.Attacker.WorkMgr:StopSkillWork()
        else
            self:ResetElapsedTime()
        end
    else
        self:SetState(self.FsmState.None)
    end
end

function AttackActionFsm:OnEndAttacking()
    self:SetState(self.FsmState.AfterAttackAction)

    if self.Attacker then
        self.Attacker:HideSkillRange()
    end


    self.Attacker:NotifyAttackComplete(self.CurrentSkill.skillid,self.bCastCallBackSkill)

end

--根据协议打断技能
function AttackActionFsm:BreakSkill(skillid)
    if self.CurrentSkill and self.CurrentSkill.skillid == skillid then
        self:BreakCurrentSkill()
    end
end

--打断当前技能（包括主动打断和被动打断）
function AttackActionFsm:BreakCurrentSkill()
    if self.Attacker then
        local interrupt = self.CurrentState == self.FsmState.BeforeAttackAction or self.CurrentState == self.FsmState.Attacking
        if self.Attacker.WorkMgr and self.Attacker.WorkMgr:IsWorkingSkill() then
            self.Attacker.WorkMgr:BreakSkillWork(interrupt)
        end
        if self.CurrentSkill and interrupt then
            self.Attacker:NotifyAttackBeBroken(self.CurrentSkill.skillid)
        end
    end

    self:ResetData()
end



function AttackActionFsm:CanMove()
    if self.CurrentState == self.FsmState.None or self.CurrentState == self.FsmState.AfterAttackAction then
        return true
    end
    if self.SkillData then
        if Local.LogModuals.Skill then
            printyellow("AttackActionFsm:CanMove()")
        end
        return self.SkillData.canmove and (self.elapsedTime > self.SkillData.startmovetime and self.elapsedTime <self.SkillData.endmovetime )
    end
    return false
end


function AttackActionFsm:CanRotate()
    if self.CurrentState == self.FsmState.None or self.CurrentState == self.FsmState.AfterAttackAction then
        return true
    end
    if self.SkillData then
        return self.SkillData.canrotate
    end
    return false
end




return AttackActionFsm
