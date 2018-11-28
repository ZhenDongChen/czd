local defineenum          = require "defineenum"
local WorkType            = defineenum.WorkType
local Work                = require "character.work.work"
local mathutils           = require "common.mathutils"
local EffectManager       = require "effect.effectmanager"
local AttackActionFsm     = require "character.ai.attackactionfsm"
local FlyingWeaponManager = require "character.skill.traceweapon.flyingweaponmanager"
local BombManager         = require "character.skill.traceweapon.bombmanager"

---------------------------------------------------------------------
--SkillMove
---------------------------------------------------------------------
local SkillMove = Class:new()
function SkillMove:__new(MovementList,Attacker,Target)
    self.MovementList         = MovementList
    self.ElapsedTime          = 0
    self.deltaTime            = 0
    self.CurrentMovement      = nil
    self.CurrentMovementIndex = 0
    self.Attacker             = Attacker
    self.StartPos             = Attacker:GetPos()
    if self.Attacker:HasTarget() then 
        self.Target = self.Attacker:GetTarget()
    end
    
    self:GetNextMovement()
end

function SkillMove:GetNextMovement()
    self.CurrentMovementIndex = self.CurrentMovementIndex +1
    self.CurrentMovement = nil
    if #self.MovementList >=self.CurrentMovementIndex then
        self.CurrentMovement = self.MovementList[self.CurrentMovementIndex]
    end
end
function SkillMove:Update()
	
    if self.CurrentMovement then
        --printyellow("SkillMove:Update()")
        --printt(self.CurrentMovement)
        --print("self.ElapsedTime " .. tostring(self.ElapsedTime))
        if self.ElapsedTime >self.CurrentMovement.timeline then
            if self.ElapsedTime >self.CurrentMovement.timeline + self.CurrentMovement.duration then
                 local fTime = self.deltaTime - (self.ElapsedTime - self.CurrentMovement.timeline - self.CurrentMovement.duration)
                 self:ApplyMove(fTime)
                 self:GetNextMovement()
            else
                 local fTime = math.min(self.deltaTime, self.ElapsedTime - self.CurrentMovement.timeline)
                 self:ApplyMove(fTime)
            end
        
        end
    end
	
    self.ElapsedTime = self.ElapsedTime + Time.deltaTime
    self.deltaTime = Time.deltaTime
end

function SkillMove:MoveInDirection(dis)
    return self.Attacker:GetRefPos() + mathutils.createOrient(self.Attacker.m_Object.transform.eulerAngles.z) * dis
end 

function SkillMove:MoveToTarget(dis) 
    if self.Target ==nil then
        return self.Attacker:GetRefPos() + mathutils.createOrient(self.Attacker.m_Object.transform.eulerAngles.z) * dis
    end 
    local distance = mathutils.DistanceOfXoY(self.Attacker:GetRefPos(),self.Target:GetRefPos())
    if distance>self.Target:GetBodyRadius() then 
        self.Attacker:LookAt(self.Target:GetRefPos())
        if dis > distance - self.Target:GetBodyRadius() then 
            dis = distance - self.Target:GetBodyRadius()
        end  
        return self.Attacker:GetRefPos() + mathutils.createOrient(self.Attacker.m_Object.transform.eulerAngles.z) * dis
    end 
	
    return self.Attacker:GetRefPos()
end 


function SkillMove:MoveBack(dis)
    local distance = mathutils.DistanceOfXoY(self.Attacker:GetRefPos(),self.StartPos)
    if distance>0 then 
        self.Attacker:LookAt(self.StartPos)
        if dis > distance then 
            dis = distance
        end  
        return self.Attacker:GetRefPos() + mathutils.createOrient(self.Attacker.m_Object.transform.eulerAngles.z) * dis
    end
    return self.Attacker:GetRefPos()
end 

function SkillMove:ApplyMove(fTime)
    --printyellow("SkillMove:ApplyMove(fTime)" .. tostring(fTime))
    if fTime < 0 then
        return
    end
    local distance = self.CurrentMovement.speed * fTime
    local targetpos = self.Attacker:GetRefPos()
    if self.CurrentMovement.type == cfg.skill.Movement.MoveInDirection then 
        targetpos = self:MoveInDirection(distance)
    elseif self.CurrentMovement.type == cfg.skill.Movement.MoveToTarget then 
        targetpos = self:MoveToTarget(distance) 
    elseif self.CurrentMovement.type == cfg.skill.Movement.MoveBack then
        targetpos = self:MoveBack(distance) 
    end 

    if self.Attacker:CanMoveTo(targetpos) then 
        self.Attacker:SetPos( targetpos)
    end
end

---------------------------------------------------------------------
--SkillWork
---------------------------------------------------------------------
local SkillWork = Class:new(Work)

function SkillWork:__new()
    Work.__new(self)
    self:reset()
    self.type = WorkType.NormalSkill
end

SkillWork.AnimType = enum
{
    "None",
    "ForeAction",
    "Action",
    "SuccAction",
}

function SkillWork:reset()
    Work.reset(self)
    self:ResetData()
end

function SkillWork:ResetData()
    self.Skill                = nil
    self.Action               = nil
    self.SkillEffectId        = -1
    self.ListHideDlgs         = nil
    self.ListHiddenMonsters   = nil
    self.ListBombWeapon       = nil
    self.ListFlyWeapon        = nil
    self.SkillMove            = nil
    self.UpdateStateNextFrame = false
    self:SetState(SkillWork.AnimType.None)
end 

function SkillWork:PlaySkillEffect()
    self.SkillEffectId = SkillManager.PlaySkillEffect(self.Action,
                                                    self.Character.m_Id,
                                                    self.Character:GetTargetId(),
                                                    self.Character:GetPos(),
                                                    defineenum.AudioPriority.Attack)
end

function SkillWork:InitSkillMove()
    if #self.Action.MovementList>0 then
        self.SkillMove = SkillMove:new(self.Action.MovementList,self.Character)
    end
end



function SkillWork:OnStart()
    Work.OnStart(self)
    --printyellow("SkillWork OnStart")
    self:PlaySkillEffect()
    self:InitSkillMove()
    self:SwitchToForeActionState()
    FlyingWeaponManager.AddWeaponObjects(self.Character,  self.TargetId,  self.Skill)
    BombManager.AddBombs(self.Character,  self.TargetId,  self.Skill)
end

function SkillWork:OnEnd()
    Work.OnEnd(self)
    self:SetState(SkillWork.AnimType.None)
 --   printyellow("SkillWork OnEnd")

end


function SkillWork:OnUpdate()
    Work.OnUpdate(self)
    if --[[self.Character.AttackActionFsm == nil or]] 
        self.Character.AttackActionFsm.CurrentState == AttackActionFsm.FsmState.None or
        self.Character:IsDead() then
        self:End()
    end
    
    self:UpdateSkillMove()
    self:UpdateAnimState()

end

function SkillWork:UpdateSkillMove()
    if self.Character == nil or 
       --self.AttackFreeze or
       self.Skill == nil  then
       return 
    end
    if self.SkillMove then
        self.SkillMove:Update()
    end
    
    
end





function SkillWork:SetState(state)
    if Local.LogModuals.Skill then
    printyellow("SkillWork:SetState(state)",utils.getenumname(SkillWork.AnimType,state),Time.time)
    end
    self.CurrentState = state
    self.UpdateStateNextFrame = true
end

function SkillWork:UpdateAnimState()
    if self.UpdateStateNextFrame then
        self.UpdateStateNextFrame = false
        return
    end
    --ForeAction
    if self.CurrentState == SkillWork.AnimType.ForeAction then
        self:UpdateForeActionState()
        --Action
    elseif self.CurrentState == SkillWork.AnimType.Action then
        self:UpdateActionState()
        --SuccAction
    elseif self.CurrentState == SkillWork.AnimType.SuccAction then
        self:UpdateSuccActionState()
    end
end

function SkillWork:UpdateForeActionState()
    if not self:IsPlayingForeAction() then
        self:SwitchToActionState()
    end
end

function SkillWork:UpdateActionState()
    --if not self.Action.loopplay then
        if not self:IsPlayingSkill() then
            self:SwitchToSuccActionState()
        end
    --end
end

function SkillWork:UpdateSuccActionState()
    if not self:IsPlayingSuccAction() then
        self:End()
    end
end

function SkillWork:SwitchToForeActionState()
    if self:PlayForeAction() then
        self:SetState(SkillWork.AnimType.ForeAction)
    else
        self:SwitchToActionState()
    end
end

function SkillWork:SwitchToActionState()
    self:PlaySkillAction()
    self:SetState(SkillWork.AnimType.Action)
end

function SkillWork:SwitchToSuccActionState()
    if self:PlaySuccAction() then
        self:SetState(SkillWork.AnimType.SuccAction)
    else
        self:End()
    end
end

function SkillWork:IsPlayingSkill()
    return self.Character:IsPlayingSkill(self.Action.actionname)
end

function SkillWork:PlaySkillAction()
    self.Character:PlayActionWithOutEffect(self.Action.actionname)
end 

function SkillWork:IsPlayingForeAction()
    return self.Character:IsPlayingForeAction(self.Action.actionname)
end

function SkillWork:PlayForeAction() --前摇
    return self.Character:PlayForeAction(self.Action.actionname)
end

function SkillWork:IsPlayingSuccAction()
    return self.Character:IsPlayingSuccAction(self.Action.actionname)
end

function SkillWork:PlaySuccAction() --后摇
    return self.Character:PlaySuccAction(self.Action.actionname)
end


function SkillWork:OnBreakSkillWork()
    if self.SkillEffectId > 0 then 
        EffectManager.StopEffect(self.SkillEffectId)
    end 
end 

return SkillWork
