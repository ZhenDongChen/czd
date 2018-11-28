
local print=print
local require=require

local Fsm = require "character.ai.fsm"
local AttackActionFSM
local event = require "character.event.event"
local charactermanager
local mathutils = require "common.mathutils"

local PetFSM = Class:new(Fsm)

function PetFSM:__new()

  self:reset()
  charactermanager = require "character.charactermanager"
  AttackActionFSM = require "character.ai.attackactionfsm"
  Pet = require"character.pet"
  self.Pet = Pet.Instance()
end

PetFSM.FSMState = enum
{
    "None = 0",
    "Born = 1",
    "Idle",
    "Action",
--    "Wait",
--    "Dead",
--    "BeAttacked",
    "DirectMove",
}
PetFSM.ActionState = enum
{
    "None=0",
    "UseSkill",
    "Rest",
    "Move",
    "Complete"
}



function PetFSM:reset()
  Fsm.reset(self)
  self:SetState(self.FSMState.Born)
  self.CurrentActionState = PetFSM.ActionState.None

  self.PetData = nil
  self.CurrentSkill = nil
  self.CandidateTargets={}
  self.CurrTarget= nil
  self.IsSuperSkill = false
  self:ResetElapsedTime();
end

function PetFSM:init()
    self.PetData= DataPetManager.Instance():GetDataByID(self.Pet.m_Id)
    self.CurrentState = PetFSM.FSMState.Born
    self.CandidateTargets={}
    self.CurrTarget=nil
    self.IsSuperSkill=false
    self:ResetElapsedTime();
end

function PetFSM:Update()
  --  if not self.Pet then return end
  self.Pet = Pet.Instance()
 -- printyellow("master"..tostring(self.Pet.master.AttackActionFsm.CurrentState))
 -- printyellow(self.CurrentState)
    if self.CurrentState == PetFSM.FSMState.Born then
    self:UpdatePetBornState()
    elseif self.CurrentState == PetFSM.FSMState.Idle then
    self:UpdatePetIdleState()
    elseif self.CurrentState == PetFSM.FSMState.Action then
    self:UpdatePetActionState()

    elseif self.CurrentState == PetFSM.FSMState.DirectMove then
    self:UpdatePetDirectMoveState()
    end
    self.elapsedTime = self.elapsedTime+Time.deltaTime
 --   if self.Pet and self.Pet.IsDead() then
 --   self.CurrentState = PetFSM.FSMState.Dead
 --   end
end

function PetFSM:IsMasterAttacking()
 --   local a = self.Pet.master
  --  return false
    return self.Pet.master:IsAttacking()
end


function PetFSM:IsMasterBeAttacked()
    return self.Pet.master:IsBeAttacked()
end

function PetFSM:IsMasterBattling()
    return self:IsMasterAttacking() or self:IsMasterBeAttacked()
end

function PetFSM:FollowMaster()
    if self.Pet.m_Object then
        self.Pet.m_Object.SetActive(self.Pet.m_Object,true)
        master = self.Pet.master
        if master then
            distance = mathutils.DistanceOfXoY(self.Pet:GetRefPos(),master:GetRefPos())
         --   printyellow(distance,self.Pet.m_Id)
            if distance > 60 then
                self.Pet:move(master)
            end
        end
    end
end

function PetFSM:UpdatePetBornState()
    self.CurrentState = PetFSM.FSMState.Idle
end

function PetFSM:UpdatePetIdleState()
    if not self.Pet:CanAttack() then return end
    if self:IsMasterBattling() then self:SwitchToActionState()
    else self:FollowMaster()
    end
end

function PetFSM:UpdateFollowState()
    if self:IsMasterBattling() then self:SwitchToActionState()
    else self:FollowMaster() end
end

function PetFSM:UpdatePetActionState()

        local target
        if not self.Pet.m_TargetId or self.Pet.m_TargetId==0 then
        self.Pet.m_TargetId = self.Pet.master.m_TargetId
        end
        if self.Pet.m_TargetId and self.Pet.m_TargetId~=0 then target= charactermanager.GetCharacter(self.Pet.targetid)
        else target=nil end
        if target then
            self.Pet:Attack(target)
        end
        if not self:IsMasterBattling() then self:SwitchToIdleState() end
end

function PetFSM:UpdatePetWaitState()
    local AIWaitTime= 200
    if self.elapsedTime>AIWaitTime*0.001 then
        self:SwitchToActionState()
    end
end


function PetFSM:IsValidTarget(target)
    return target and not target.IsDead() and target~= self.Pet
end

function PetFSM:SelectTargetFromCandidates(candidates)
    return candidates[0]
end


function PetFSM:GetTargetMasterAttacking()
    if AttackActionFSM.FsmState.None ~= self.Pet.master.AttackActionFsm.CurrentState then
        self.CandidateTargets={}
        self.Pet.master.AttackActionFsm.GetInAttackRangeChrList(self.CandidateTargets) -------
        if self.CandidateTargets.Count >0 then
            return SelectTargetFromCandidates(self.CandidateTargets) -----------
        end
    end
    return nil
end

function PetFSM:GetTargetAttackingMaster()
    return false
    -------------------------------------temporary
    -- return self.Pet.master.BeAttackedActionFSM.Attacker
end
--[[
function PetFSM:GetTargetNearestMonsterInPetEyeSlot()
    local result = nil
    local eyeslotX,eyeslotY
    eyeslotX,eyeslotY = 3,5
 --   charactermanager.Instance().GetCharacterByRange(self.Pet:GetPos(),eyeslotX/2,eyeslotY/2,ref self.CandidateTargets)
                                ----------------------
    local minDist = 10000
    for i,c in self.CandidateTargets do
        local dist = Vector3.Distance(c:GetPos(),self.Pet:GetPos)
        if dist<minDist and c.IsMonster() then
            minDist = dist
            result = c
        end
    end
    return result

end]]--


function PetFSM:DetermineTarget()
    --[[self.CurrTarget=nil
    self.CurrTarget = self:GetTargetMasterAttacking()
    if IsValidTarget(self.CurrTarget) then return true end
    self.CurrTarget = self:GetTargetAttackingMaster()
    if IsValidTarget(self.CurrTarget) then return true end ]]--
    if self.Pet.master.m_TargetId then return true end

--[[    initative = true
    if initative then
        self.CurrTarget = GetTargetNearestMonsterInPetEyeSlot();
        if IsValidTarget(self.CurrTarget) then return true end
    end]]--
    return false
end


function PetFSM:DetermineBehaviour()

----------------------------
end

function PetFSM:SwitchToIdleState()
    self.CurrentState = PetFSM.FSMState.Idle
    self.CurrentActionState = PetFSM.ActionState.None
end

function PetFSM:SwitchToActionState()
    self.CurrentState = PetFSM.FSMState.Action
    self.CurrentActionState = PetFSM.ActionState.None
    self.Pet.m_Object:SetActive(true)
    if self:DetermineBehaviour() then self:ResetElapsedTime()
    else self:SwitchToWaitState() end
end

function PetFSM:SwitchToWaitState()
  --  self.Pet.ShowHp = true
  --  self:ResetElapsedTime()
    if self.Pet.WorkMgr:IsWorking(defineenum.WorkType.Move) then
        self.Pet.WorkMgr:StopWork(defineenum.WorkType.Move)
        self.currStatus = self.FSMState.Wait
    end
end

function PetFSM:UpdateActionUseSkillState()
    if self.CurrTarget and self.CurrTarget.IsDead() then
        self.CurrentActionState = PetFSM.ActionState.Complete
        return
    end
    if Vector3.Distance(self.Pet:GetRefPos(),self.vDestPos)<= 0.1 then
        if self.Pet.WorkMgr.IsWorking(definenum.WorkType.Move) then
            self.Pet.WorkMgr.StopWork(definenum.WorkType.Move)
        end
        self.Pet.SetFaceDirection(self.CurrTarget:GetRefPos().x,self.Pet:GetRefPos().x)
        if self.fSkillWaitTime - Time.deltaTime > 0 then
            self.fSkillWaitTime = self.fSkillWaitTime - Time.deltaTime
        else
            self.fSkillWaitTime = 0
        end
        if self.fSkillWaitTime>0 then return end
        self.Pet.AttackActionFSM.SetAttackAction(self.CurrSkill.Data.Action,self.CurrSkill.Data.SkillID,self.CurrSkill.Data.Level)
        self.Pet.AttackaActionFSM:Start()
        if self.IsSuperSkill then self.Pet.BeginSuperSkillCoolDown() end
        self.CurrActionState = ActionState.Complete
    end
end

function PetFSM:UpdateActionRestState()
    if self.elapsedTime>self.fRestTime then
    self.CurrActionState = ActionState.Complete
    end
end

function PetFSM:UpdateActionMoveState()
    if Vector3.Distance(self.Pet:GetRefPos(),self.vDestPos)<=0 or self.elapsedTime>=self.fMoveTime then
        self,CurrActionState = ActionState.Complete
    end
end

function PetFSM:UpdateActionCompleteState()
    if self.Pet.AttackActionFSM.CurrentState ~= AttackActionFSM.FSMState.None then return end
    self:SwitchToWaitState()
end

function PetFSM:UpdatePetDeadState()
    self.Pet.ShowHp = false
end

--[[function PetFSM:UpdatePetBeAttackedState()
    self.Pet.ShowHp = true
    local ResistTime = 500
    if self.elapsedTime < ResistTime*0.001 then return end

    if self.Pet.BeAttackedActionFSM.CurrentState ~= BeAttackedActionFSM.FsmState.None then return end

    self:SwitchToWaitState();
end
]]--
-----------------------------------------------------------------------------------------------------
function PetFSM:UpdatePetDirectMoveState()
    self:SwitchToWaitState()
    if not self.Pet or self.Pet.AttackActionFSM == nil then return end
    if self.Pet.AttackActionFSM.CurrentState ~= AttackActionFSM.FsmState.None then return end
    if not self.HaveMoveto then
        self.Pet:MoveTo(Vector3(self.vDirectMoveTargetX,0,self.vDirectMoveTargetZ))
        self.HaveMoveto = true
    end
    if Vector3.Distance(Vector3(self.Pet:GetRefPos().x,0,self.Pet:GetRefPos().z),Vector3(self.vDirectMoveTargetX,0,self.vDirectMoveTargetZ))<0.1 then
    self:SwitchToWaitState()
    self.vDirectMoveTargetX = self.Pet:GetRefPos().x
    self.vDirectMoveTargetZ = self.Pet:GetRefPos().z
    end
end
--[[
function PetFSM:DetermineAIAction()
    local id =4
    local dataTemplate = AITemplateManager.Instance().GetAITemplate(id,self.Pet.Hp/self.Pet.HpMax,
    math.abs(self.CurrTarget:GetPos().x-self.Pet:GetPos().x),math.abs(self.CurrTarget:GetPos().z-self.Pet:GetPos().z))
    if not dataTemplate then return nil end
    local action = DataAiactionManager.Instance().GetDataByActionID(dataTemplate.Action1)
    return action
end]]--


function PetFSM:DetermineBehaviour()
    if self:DetermineTarget() then return false end
    local action = self:DetermineAIAction()
    if not action then return false end
    if action.ActionType == "UseSkill" then
        if self.Pet:IsSuperSkillEnabled() then
            self.CurrSkill  = self.Pet.SuperSkill
            self.IsSuperSkill = true
        else
            self.CurrSkill = SkillManager.Instance().GetSkill(action.Param1,action.Param2)
            self.IsSuperSkill = false
        end

        if not self.CurrSkill then return false end
        self.fSkillWaitTime = action.Param3*0.001
        if action.Param4 == 0 then
            self.vDestPos = self.Pet:GetPos()
        elseif action.Param4 ==1 then
            local minRange = self.CurrSkill.Data.RangeMin
            local maxRange = self.CurrSkill.Data.RangeMax
            if maxRange<minRange then maxRange = minRange end
            self.fCurrSkillRange = UnityEngine.RandomKillMonster.RandomRange(minRange,maxRange)
            local dist = Vector3.Distance(self.Pet:GetRefPos(),self.CurrTarget:GetRefPos())
            if dist<=self.fCurrSkillRnage then
                self.vDestPos = self.Pos:GetPos()
            else
                self.vDestPos= Interpolation(self.CurrTarget:GetRefPos(),self.Pet:GetRefPos(),self.fCurrSkillRange/dist)
                if Vector3.Distance(self.Pet:GetRefPos(),self.vDestPos)>0.1 then self.Pet:MoveTo(self.vDestPos) end
            end
        else return false
        end
        self.CurrActionState = ActionState.UseSkill
        return true
    elseif action.ActionType == "Rest" then
        self.fRestTime = action.Param1* Function.GetRatioByBias(action.Param2)*0.001
        self.CurrActionState = ActionState.Rest
        return true
    elseif action.ActionType == "Move" then
        local moveDir = Vector3.zero
        self.fMoveTime = action.Param2 * Function.GetRatioByBias(action.Param3)*0.001
        if action.Param1 ==1 then
            local theta = UnityEngine.RandomKillMonster.RandomRange(0,math.pi*2)
            moveDir = Vector3( math.cos(theta),0,0)
            self.vDestPos = self.Pet:GetRefPos()+moveDir*self.fMoveTime*self.Pet.m_Attributes[cfg.fight.AttrId.MOVE_SPEED]
        elseif action.Param1==2 then
            local ratio = (100-action.Param4)/100
            ratio = Mathf.Clamp(ratio,0,1)
            self.vDestPos = self.Pet:GetRefPos()+(self.CurrTarget:GetRefPos()-self.Pet:GetRefPos())*ratio
            if Vector3.Distance(self.CurrTarget:GetRefPos(),self.Pet:GetRefPos())<0.6 then return false end
        elseif action.Param1==3 then
            moveDir = (self.Pet:GetRefPos()-self.CurrTarget:GetRefPos()).normalized
            self.vDestPos = self.Pet:GetRefPos()+moveDir*self.fMoveTime*self.Pet.m_Attributes[cfg.fight.AttrId.MOVE_SPEED]
        else
            return false
        end
        self.vDestPos.x = Mathf.Clamp(self.vDestPos.x,SceneManager.Instance().CurrSceneMinX,SceneManager.Instance().CurrSceneMaxX)
        self.vDestPos.z = Mathf.Clamp(self.vDestPos.z,SceneManager.Instance().CurrSceneMinZ,SceneManager.Instance().CurrSceneMaxZ)
        if Vector3.Distance(self.Pet:GetRefPos(),self.vDestPos)>0.1 then self.Pet:MoveTo(self.vDestPos) end
        self.CurrActionState = ActionState.Move
        return true
    end
    return false
end

function PetFSM:Interpolation(vbegin,vend,ratio)
    return Vector3(ratio*(vend.x-vbegin.x)+vbegin.x,ratio*(vend.y-vbegin.y)+vbegin.y,ratio*(vend.z-vbegin.z)+vbegin.z)
end


function PetFSM:SetState(state)
  self.CurrentState = state
end

function PetFSM:Start()
  Fsm.Start(self)
  self:SetState(self.FsmState.None)
  self.animator = Pet.Instance().Object.GetComponent(Pet.Instance().Object,"Animator")
end

--[[function PetFSM:Update()
  Fsm.Update(self)
  if self.CurrentState == self.FsmState.None then
    self:UpdateToNone()
    end
  if self.CurrentState == self.FsmState.Run then
    self:UpdateToRun()
    end
  if self.CurrentState == self.FsmState.Tiaoxin then
    self.UpdateToTiaoxin()
  end
end]]--



return PetFSM
