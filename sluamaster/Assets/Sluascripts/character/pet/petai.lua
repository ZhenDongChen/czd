local print=print
local require=require

local Fsm = require "character.ai.fsm"
local event = require "character.event.event"
local charactermanager
local mathutils = require "common.mathutils"
local ConfigManager = require"cfg.configmanager"
local defineenum = require"defineenum"
local CharacterType = defineenum.CharacterType
local PetManager = require"character.pet.petmanager"
local AttackActionFSM = require "character.ai.attackactionfsm"
local OutFightingTime = 5

local PetAI = Class:new(Fsm)

function PetAI:__new(pet)

      self.m_Pet                        = pet
      self.m_Type                       = CharacterType.RolePet
      self.m_Master                     = PlayerRole.Instance()
      self.m_OffsetDegree               = 0
      self.m_OffsetDistance             = 3
      self.m_PositionCheckElapsedTime   = 0
      self.m_AttackCheckElapsedTime     = 0
      self.m_FollowTarget               = nil
      self.m_PetConfig = ConfigManager.getConfig("petconfig")
      self.m_CfgPetAI                   = ConfigManager.getConfigData("petai",self.m_Pet.m_Data.ai)
      self.m_CfgPetSkill                = ConfigManager.getConfigData("petskill",self.m_Pet.m_CsvId)
      self.m_SkillWeightMap             = {}
      self:Init()
end

PetAI.FsmState = enum{
    "NONE = 0",
    "BORN = 1",
    "IDLE",
    "FREEACTION",
    "FOLLOW",
    "TRANSMIT",
    "FIGHTING",
}

PetAI.FightingState = enum{
    "NONE = 0",
    "CHOOSESKILL = 1",
    "WALKTOTARGET = 2",
    "ATTACKING = 3",
    "WAITFORNEXTSKILL = 4",
}

function PetAI:ResetConfig(count,index)
    local amountConfig = self.m_PetConfig.follow[count]
    local followinfo = amountConfig.followlist[index]
    self.m_OffsetDegree = followinfo.degree
    self.m_OffsetDistance = followinfo.distance
    self.m_IdleCheckTime = 5
end
function PetAI:GetTargetPosition()
    local vec = Quaternion.AngleAxis(self.m_OffsetDegree,Vector3.up) *(self.m_Pet.m_Master.m_Object.transform.forward)
    local tmpTargetPos = vec.normalized * self.m_OffsetDistance + self.m_Master:GetPos()
    local ret,hit = UnityEngine.NavMesh.Raycast(self.m_Master:GetPos(),tmpTargetPos,nil,UnityEngine.NavMesh.AllAreas)
    if ret then
        return hit.position
    else
        return tmpTargetPos
    end
end

function PetAI:Reset(num)
    Fsm.reset(self)
    self:ResetSkill()
end

function PetAI:ResetSkill()
    self.m_SelectedSkillData = nil
    self:SetPetFightingState(PetAI.FightingState.NONE)
    self.m_NoTargetElapsedTime = 0
end

function PetAI:Init()
    self:Reset()
    self.m_NearRadius           = self.m_PetConfig.follownearradius
    self.m_FarRadius            = self.m_PetConfig.followfarradius
    self.m_GuardRadius          = self.m_PetConfig.guardradius
    self.m_AttackCD             = self.m_PetConfig.attackcd
    self.m_SpaceDistance        = self.m_PetConfig.distancespace
    self.m_SpaceAttack          = self.m_PetConfig.attackspace
    self.m_SpaceIdle            = self.m_PetConfig.idlespace
    self.m_DistanceElapsedTime  = 0
    self.m_AttackElapsedTime    = 0
    self.m_IdleElapsedTime      = 0
    self.m_SelectedSkillData        = nil
    self.m_FollowTarget         = nil
    for i=3,#self.m_CfgPetSkill.skilllist do
        local skillid = self.m_CfgPetSkill.skilllist[i]
        local weight = self.m_CfgPetAI.ai[i-2]
        self.m_SkillWeightMap[skillid] = weight
    end
    self:SetPetState(PetAI.FsmState.NONE)
end

function PetAI:SetPetIdleState()
    self.m_IdleElapsedTime = 0
    self:SetPetState(PetAI.FsmState.IDLE)
end

function PetAI:SetPetState(state)
    self.m_CurrentPetState = state
end

function PetAI:CheckPetState(state)
    return self.m_CurrentPetState == state
end

function PetAI:UpdatePetBornState()
    self:SetPetIdleState()
end

function PetAI:UpdatePetIdleState()
    self.m_IdleElapsedTime = self.m_IdleElapsedTime + Time.deltaTime
end

function PetAI:SetPetAttackState()
    self:SetPetState(PetAI.FsmState.FIGHTING)
    self:ResetSkill()
end

function PetAI:CheckAttackState(b)
    if b then
        if self.m_Pet:HasTarget() then
            self:SetPetAttackState()
            return true
        elseif self.m_Master:HasTarget() then
            local targetid = self.m_Master:GetTargetId()
            self.m_Pet:SetTargetId(targetid)
            self:SetPetAttackState()
            return true
        elseif self.m_Master:GetAttacker() then
            local attacker = self.m_Master:GetAttacker()
            if attacker then
                self.m_Pet:SetTargetId(attacker.m_Id)
                self:SetPetAttackState()
                return true
            end
        end
    end
    return false
end

function PetAI:CheckState()
    local bCheckDistance = false
    local bCheckAttack = false
    if self.m_DistanceElapsedTime > self.m_SpaceDistance then
        bCheckDistance = true
        self.m_DistanceElapsedTime = self.m_DistanceElapsedTime - self.m_SpaceDistance
    end
    if self.m_AttackElapsedTime > self.m_SpaceAttack then
        bCheckAttack = true
        self.m_AttackElapsedTime = self.m_AttackElapsedTime - self.m_SpaceAttack
    end
    if bCheckDistance then
        local dist = mathutils.DistanceOfXoY(self.m_Pet:GetPos(),self.m_Master:GetPos())
        if dist>self.m_FarRadius then
            self:SetPetState(PetAI.FsmState.TRANSMIT)
            return
        else
            if self:CheckAttackState(bCheckAttack) then --[[ printyellow("self.m_FightingState 177",self.m_FightingState)]] return end
            if dist> self.m_NearRadius then
                self:SetPetState(PetAI.FsmState.FOLLOW)
            end
        end
    end
    if self:CheckAttackState(bCheckAttack) then --[[printyellow("self.m_FightingState 183",self.m_FightingState)]] return end
end

function PetAI:navigateTo(params)
    self.m_RoleSkillFsm:reset()
    self.m_Navigation:StartNavigate(params)
end

function PetAI:Update()
    self.m_DistanceElapsedTime = self.m_DistanceElapsedTime + Time.deltaTime
    self.m_AttackElapsedTime = self.m_AttackElapsedTime + Time.deltaTime
    self:CheckState()
    if self:CheckPetState(PetAI.FsmState.NONE) then
        self:UpdatePetInitState()
    elseif self:CheckPetState(PetAI.FsmState.BORN) then
        self:UpdatePetBornState()
    elseif self:CheckPetState(PetAI.FsmState.IDLE) then
        self:UpdatePetIdleState()
    elseif self:CheckPetState(PetAI.FsmState.FREEACTION) then
        -- printyellow("PetAI.FsmState.FREEACTION")
        self:UpdatePetFreeAction()
    elseif self:CheckPetState(PetAI.FsmState.FOLLOW) then
        -- printyellow("PetAI.FsmState.FOLLOW")
        self:UpdatePetFollow()
    elseif self:CheckPetState(PetAI.FsmState.TRANSMIT) then
        -- printyellow("PetAI.FsmState.TRANSMIT")
        self:UpdatePetTransmit()
    elseif self:CheckPetState(PetAI.FsmState.FIGHTING) then
        -- printyellow("PetAI.FsmState.FIGHTING")
        self:UpdatePetFightingState()
        -- printyellow("UpdatePetFightingState",self.m_FightingState)
    end
end

function PetAI:UpdatePetInitState()
    if self.m_Object then
        self.m_Pet:PlayAction(cfg.skill.AnimType.Born)
        self:SetPetState(PetAI.FsmState.BORN)

    end
end

function PetAI:UpdatePetBornState()
    if not self.m_Pet:IsPlayingAction(cfg.skill.AnimType.Born) then
        self:SetPetIdleState()
    end
end

function PetAI:UpdatePetIdleState()
    self.m_IdleElapsedTime = self.m_IdleElapsedTime + Time.deltaTime
    if self.m_IdleElapsedTime > self.m_SpaceIdle then
        self.m_Pet:PlayAction(cfg.skill.AnimType.Idle)
        self:SetPetState(PetAI.FsmState.FREEACTION)
    end
end

function PetAI:UpdatePetFreeAction()
    if not self.m_Pet:IsPlayingAction(cfg.skill.AnimType.Idle) then
        self:SetPetIdleState()
    end
end

function PetAI:UpdatePetFollow()
    if self.m_FollowTarget then
        -- printyellow("folloing",self.m_FollowTarget)
        local distToTarget = mathutils.DistanceOfXoY(self.m_FollowTarget,self.m_Pet:GetPos())
        if distToTarget<90 then
            local newTarget = self:GetTargetPosition()
            local distToNewTarget = mathutils.DistanceOfXoY(self.m_Pet:GetPos(),newTarget)
            if distToNewTarget> 180 then
                self.m_FollowTarget = newTarget
                self.m_Pet:navigateTo({
                    targetPos = newTarget,
                    callback = function()
                        self:SetPetIdleState()
                        self.m_FollowTarget = nil
                    end ,
                })
            end
        end
    else
        self.m_FollowTarget = self:GetTargetPosition()
        -- printyellow("start follow",self.m_FollowTarget)
        self.m_Pet:navigateTo({
            targetPos = self.m_FollowTarget ,
            callback = function()
                self:SetPetIdleState()
                self.m_FollowTarget = nil
            end ,

        })
    end
end

function PetAI:UpdatePetTransmit()
    local targetPos = self:GetTargetPosition()
    self.m_Pet:SendStop(targetPos)
    self:SetPetIdleState()
end

function PetAI:GetAvailableSkills()
    local itemPet = PetManager.IsAttainedPets(self.m_Pet.m_CsvId)
    local skills = itemPet.PetSkills
    local availableSkills = {}
    for skillid,level in pairs(skills) do
        -- printyellow("self.m_Pet.PlayerSkill",self.m_Pet.PlayerSkill)
        -- printyellow("self.m_Pet.PlayerSkill.GetPlayerSkill",self.m_Pet.PlayerSkill.GetPlayerSkill)
        -- printyellow("skillid",skillid)
        skilldata = self.m_Pet.PlayerSkill:GetPlayerSkill(skillid)
        if skilldata:CanAttack() then
            local tb = {}
            tb.skillid = skillid
            tb.roll = self.m_SkillWeightMap[skillid]
            tb.skilldata = skilldata
            table.insert(availableSkills,tb)
        end
    end
    return availableSkills
end

function PetAI:GetASkill(skills)
    for i=2,#skills do
        local currSkill = skills[i]
        local preSkill = skills[i-1]
        currSkill.roll = preSkill.roll + currSkill.roll
    end
    local totalRoll = skills[#skills].roll
    local randValue = math.random(totalRoll)
    for i=#skills,2,-1 do
        local skillInfo = skills[i]
        if skillInfo[i].roll >= randValue and skillInfo[i-1] < randValue then
            return skillInfo[i].skilldata
        end
    end
    return skills[1].skilldata
end

function PetAI:UpdateChooseSkillState()
    local skills = self:GetAvailableSkills()
    if #skills == 0 then
        self:ResetSkill()
    end
    self.m_SelectedSkillData = self:GetASkill(skills)
    self:SetPetFightingState(PetAI.FightingState.WALKTOTARGET)
end

function PetAI:Attack()
    if self.m_SelectedSkillData == nil or self.m_SelectedSkillData:GetCurrentSkill() == nil then
        self:ResetSkill()
        return
    end
    self.m_Pet:SendAttack(self.m_SelectedSkillData:GetCurrentSkill().skillid)
    self.m_SelectedSkillData:BeginCD()
    self:SetPetFightingState(PetAI.FightingState.ATTACKING)
end

function PetAI:UpdateWalkToTargetState()
    local attackTarget = self.m_Pet:GetTarget()
    if not attackTarget then
        self:ResetSkill()
        return
    end
    if mathutils.DistanceOfXoY(self.m_Pet:Instance().m_Pos,attackTarget.m_Pos) >
        self.m_SelectedSkillData:GetCurrentAction().attackrange then
        if not self.m_Pet:moveTo(attackTarget.m_Pos) then
            self:ResetSkill()
            return
        end
    else
        if self.m_Pet:IsMoving() then
            self.m_Pet:stop()
        end
        local dir = attackTarget.m_Pos - self.m_Pet.m_Pos
        dir.y = 0
        nDir = dir.normalized
        self.m_Pet:SetRotationImmediate(nDir)
        self:Attack()
    end
end

function PetAI:UpdateNoneState()
    if self.m_Pet:GetTarget() == nil then
        self.m_NoTargetElapsedTime = self.m_NoTargetElapsedTime + Time.deltaTime
        if self.m_NoTargetElapsedTime > OutFightTime then
            self:SetPetState(PetAI.FsmState.IDLE)
        end
    else
        self:SetPetFightingState(PetAI.FightingState.CHOOSESKILL)
    end
end

function PetAI:UpdateAttackState()

end

function PetAI:NotifyAttackComplete(bCastCallBackSkill)
    if self.m_SelectedSkillData == nil then
        return
    end
    self:ResetSkill()
end

function PetAI:CheckFightingState(state)
    return self.m_FightingState == state
end

function PetAI:SetPetFightingState(state)
    self.m_FightingState = state
end

function PetAI:UpdatePetFightingState()
    if self:CheckFightingState(PetAI.FightingState.NONE) then
        -- printyellow("PetAI.FightingState.NONE")
        self:UpdateNoneState()
    elseif self:CheckFightingState(PetAI.FightingState.CHOOSESKILL) then
        -- printyellow("PetAI.FightingState.CHOOSESKILL")
        self:UpdateChooseSkillState()
    elseif self:CheckFightingState(PetAI.FightingState.WALKTOTARGET) then
        -- printyellow("PetAI.FightingState.WALKTOTARGET")
        self:UpdateWalkToTargetState()
    elseif self:CheckFightingState(PetAI.FightingState.ATTACKING) then
        -- printyellow("PetAI.FightingState.ATTACKING")
        self:UpdateAttackState()
    end
end

return PetAI
