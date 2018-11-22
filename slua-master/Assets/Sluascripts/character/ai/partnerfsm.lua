local print=print
local require=require
local defineenum    = require"defineenum"
local ConfigManager = require"cfg.configmanager"
local Fsm           = require"character.ai.fsm"
local WorkType      = defineenum.WorkType
local PartnerFsm    = Class:new(Fsm)
local Partner
local PlayerRole
local CharacterManager

PartnerFsm.PartnerStates = enum{
    "IDLE=0",
    "BORN",
    "BORNING",
    "MOVE",
    "PLAY",
    "TRANSMIT",
    "BATTLE",
}

PartnerFsm.PartnerBattleState = enum{
    "FINDTARGET",
    "MOVETOTARGET",
    "ATTACK",
    "DETERMINSKILL",
}

function PartnerFsm:__new(id,pet,master)
    CharacterManager                = require"character.charactermanager"
    -- Partner                         = require"character.pet.partner"
    PlayerRole                      = require"character.playerrole"
    self.m_Range1                   = cfg.pet.PetAi.PET_CHECK_AREA_1
    self.m_Range2                   = cfg.pet.PetAi.PET_CHECK_AREA_2
    self.m_AttackRange              = cfg.pet.PetAi.PET_ATK_AREA
    self.m_CurrentState             = PartnerFsm.PartnerStates.BORN
    self.m_PlayerCheckTime          = cfg.pet.PetAi.PET_CHECK_TERMINAL
    self.m_AttackTime               = cfg.pet.PetAi.PET_ATK_CHECK_TERMINAL
    self.m_IdleTime                 = 10
    self.m_Partner                  = pet
    self.m_Player                   = master
    self.m_CurrentAnimation         = nil
    self.m_NeedMoveToDefaultPosition= false
    self.m_AttackState              = nil
    self.m_SkillManager             = {}
    self.m_SkillMap                 = {}
    self.m_LastSkill                = nil
    self.m_LastSkillTime            = 0
    math.randomseed(os.time())
    self:init(id)
end

function PartnerFsm:InsertIntoSkillMap(weight,totalWeight,skill,currentWeight)
    table.insert(self.m_SkillMap,{weight=(weight+currentWeight)/totalWeight,skill=skill})
    return currentWeight+weight
end

function PartnerFsm:CheckCD(skill)
    return self.m_SkillManager[v.skill].isReady
end

function PartnerFsm:GetSkill(value)
    self.m_SkillMap = {}
    local availableSkills = {}
    local totalWeight = 0
    for i,v in pairs(self.m_SkillManager) do
        if v.isReady then
            totalWeight = totalWeight + v.weight
            availableSkills[#availableSkills+1] = v.skill
        end
    end
    if totalWeight>0 then
        local currentWeight = 0
        for i,v in pairs(availableSkills) do
            currentWeight = self:InsertIntoSkillMap(self.m_SkillManager[v].weight,totalWeight,v,currentWeight)
        end
        for i,v in pairs(self.m_SkillMap) do
            if v.weight>value then
                return v.skill
            end
        end
    else
        return nil
    end
end

function PartnerFsm:init(id)
    self.m_TimerIdle            = 0
    self.m_TimerAttack          = 0
    self.m_TimerPlayer          = 0
    local totalWeight = 0
    local petInfo = ConfigManager.getConfigData("petbasicstatus",id)
    local infoAi = ConfigManager.getConfigData("petai",petInfo.ai)
    local Skills = infoAi.ai_skill --get skills from BattlePets[i]
    for i,v in pairs(Skills) do
        totalWeight = totalWeight + v.weight
        self.m_SkillManager[v.skill] = {}
        self.m_SkillManager[v.skill].isReady = true
        self.m_SkillManager[v.skill].elapsedTime = 0
        self.m_SkillManager[v.skill].cd = v.cd
        self.m_SkillManager[v.skill].weight = v.weight
        self.m_SkillManager[v.skill].skill = v.skill
    end
end

function PartnerFsm:DisplaySkillsState()
    -- printyellow("DisplaySkillsState")
    -- for i,v in pairs(self.m_SkillManager) do
    --     if v.isReady then
    --         printyellow(v.skill, tostring(v.isReady))
    --     else
    --         printyellow(v.skill, tostring(v.isReady) , v.elapsedTime , v.cd)
    --     end
    -- end
end

function PartnerFsm:SkillsUpdate()
    if self.m_LastSkill then
        self.m_LastSkillTime = self.m_LastSkillTime + Time.deltaTime
    end
    for i,v in pairs(self.m_SkillManager) do
        if not v.isReady then
            v.elapsedTime = v.elapsedTime + Time.deltaTime
            if v.elapsedTime>v.cd then
                v.elapsedTime = 0
                v.isReady = true
            end
        end
    end
end

function PartnerFsm:ResetToIdleState()
    self.m_CurrentState = PartnerFsm.PartnerStates.IDLE
    self.m_Partner.WorkMgr:StopWork(WorkType.NormalSkill)
    self.m_Partner.WorkMgr:StopWork(WorkType.BeAttacked)
    self.m_Partner.WorkMgr:StopWork(WorkType.Move)
    self.m_TimerIdle    = 0
end

function PartnerFsm:IdleUpdate()

    if self.m_NeedMoveToDefaultPosition then
        self.m_CurrentState = PartnerFsm.PartnerStates.MOVE
        self.m_MoveTarget = self.m_Partner:GetInitPos()
        self.m_Partner:MoveTo(self.m_MoveTarget)
        return
    end
    if self.m_Player.m_IsFighting then
        self.m_CurrentState = PartnerFsm.PartnerStates.BATTLE
        self.m_AttackState = PartnerFsm.PartnerBattleState.FINDTARGET
        return
    end
    self.m_TimerIdle = self.m_TimerIdle + Time.deltaTime
    if self.m_TimerIdle > self.m_IdleTime then
        self.m_CurrentAnimation = "dying"  -- play animation
        self.m_CurrentState = PartnerFsm.PartnerStates.PLAY
        self.m_Partner:PlayFreeAction(self.m_CurrentAnimation)
    end

end

function PartnerFsm:MoveUpdate()
    if self.m_Partner:IsMoving() then
        local distToTarget = mathutils.DistanceOfXoY(self.m_Partner:GetRefPos(),self.m_MoveTarget)
        if distToTarget<30 then
            local newTarget= self.m_Partner:GetInitPos()
            local distToNewTarget = mathutils.DistanceOfXoY(self.m_Partner:GetRefPos(),newTarget)
            if distToNewTarget>150 then
                self.m_MoveTarget = newTarget
                self.m_Partner:MoveTo(newTarget)
            end
        end
    else
        self.m_NeedMoveToDefaultPosition = false
        self.m_MoveTarget = nil
        self:ResetToIdleState()
    end
end

function PartnerFsm:PlayUpdate()
    if not self.m_Partner:IsPlayingAction(self.m_CurrentAnimation) then
        self:ResetToIdleState()
        self.m_CurrentAnimation = nil
    end
end

function PartnerFsm:TransmitUpdate()
    self.m_Partner:SetPos(self.m_Player:GetRefPos())
    self:ResetToIdleState()
    -- send a protocol ?
end

function PartnerFsm:CheckState()
    if self.m_CurrentState == PartnerFsm.PartnerStates.BORN or
    self.m_CurrentState == PartnerFsm.PartnerStates.BORNING then
        return  end
    self.m_TimerPlayer = self.m_TimerPlayer + Time.deltaTime
    if self.m_TimerPlayer > self.m_PlayerCheckTime then
        self.m_TimerPlayer = 0
        self.m_DistToPlayer = mathutils.DistanceOfXoY(self.m_Player:GetRefPos(),self.m_Partner:GetRefPos())
        -- printyellow(self.m_Player:GetPos())
        -- printyellow(self.m_Partner:GetPos())
        -- printyellow("distance to player",self.m_DistToPlayer)
        if self.m_DistToPlayer > self.m_Range2 then
            self.m_CurrentState = PartnerFsm.PartnerStates.TRANSMIT
            return
        elseif self.m_DistToPlayer > self.m_Range1 then
            self.m_NeedMoveToDefaultPosition = true
            return
        else
        end
    end
end

function PartnerFsm:FindTargetUpdate()
    local target = CharacterManager.GetCharacter(self.m_Player.m_TargetId)
    if target and target.m_Object then
        self.m_Target = target
        self.m_Partner:MoveTo(target:GetRefPos())
        self.m_AttackState = PartnerFsm.PartnerBattleState.MOVETOTARGET
        return
    end
    if not self.m_Player.m_IsFighting then
        self.m_CurrentState = PartnerFsm.PartnerStates.IDLE
        return
    end
end

function PartnerFsm:GetDistanceToTarget()
    local distToTarget
    if self.m_Target and self.m_Target.m_Object then
        distToTarget = mathutils.DistanceOfXoY(self.m_Partner:GetRefPos(),self.m_Target:GetRefPos())
    end
    return distToTarget
end

function PartnerFsm:MoveToTargetUpdate()
    if self.m_Partner:IsMoving() then
        local distToTarget = mathutils.DistanceOfXoY(self.m_Partner:GetRefPos(),self.m_Target:GetRefPos())
        if distToTarget<60 then
            local newTarget= self.m_Target:GetRefPos()
            local distToNewTarget = mathutils.DistanceOfXoY(self.m_Partner:GetRefPos(),newTarget)
            if distToNewTarget>180 then
                self.m_MoveTarget = newTarget
                self.m_Partner:MoveTo(newTarget)
            end
        end
    else
        self.m_AttackState = PartnerFsm.PartnerBattleState.DETERMINSKILL
    end
end

function PartnerFsm:UseSkill(skill)
    self.m_SkillManager[skill].isReady = false
    self.m_SkillManager[skill].elapsedTime = 0
end

function PartnerFsm:DeterminSkillUpdate()
    local skill = self:GetSkill(math.random())
    if skill then
        -- if self.m_Partner:CanPlaySkill(skill) then
            -- printyellow("skill",skill)
            self.m_LastSkill = skill
            self.m_LastSkillTime = 0
            self:UseSkill(skill)
            self.m_Partner:SetTargetId(self.m_Target.id)
            self.m_Partner:PlaySkill(skill.skillid)
            self.m_AttackState= PartnerFsm.PartnerBattleState.ATTACK
        -- end
    end
end

function PartnerFsm:AttackUpdate()
    if not self.m_Target or not self.m_Target.m_Object then
        self.m_CurrentState = PartnerFsm.PartnerStates.IDLE
    else
        local currentDist = self:GetDistanceToTarget()
        -- printyellow(tostring(self.m_Partner.m_SkillEnd),self.m_LastSkill,self.m_LastSkillTime)
        if not self.m_Partner:IsAttacking() then
            if currentDist > 60 then
                self.m_Partner:MoveTo(self.m_Target:GetRefPos())
                self.m_AttackState = PartnerFsm.PartnerBattleState.MOVETOTARGET
            else
                self.m_AttackState = PartnerFsm.PartnerBattleState.DETERMINSKILL
            end
        end
    end
end

function PartnerFsm:BornUpdate()
    -- printyellow("self.m_Partner",self.m_Partner,"self.m_Player",self.m_Player)
    if not self.m_Partner.m_Object or not self.m_Player.m_Object then return end
    -- self.m_Partner.Object.transform.parent = self.m_Player.m_Object.transform
    self.m_Partner:SetPos(self.m_Player:GetRefPos())
    self.m_Partner.m_Object.transform.localRotation = Quaternion.identity
    -- if not self.m_Partner.AnimationMgr:IsPlaying() then
    self.m_Partner:PlayFreeAction(cfg.skill.AnimType.Hit)
    self.m_CurrentState = PartnerFsm.PartnerStates.BORNING
    -- end
end

function PartnerFsm:BorningUpdate()
    if not self.m_Partner:IsPlayingAction(cfg.skill.AnimType.Hit) then
        self.m_CurrentState = PartnerFsm.PartnerStates.IDLE
    end
end

-- for test
function PartnerFsm:PlaySkillManual(skill,targetid)
    -- printyellow("play skill",skill,"target",targetid)
    self:UseSkill(skill)
    self:SetTargetId(targetid)
    self.m_Partner:PlaySkill(skill)
    self.m_AttackState= PartnerFsm.PartnerBattleState.ATTACK
    self.m_CurrentState = PartnerFsm.PartnerStates.BATTLE
    self.m_AttackState = PartnerFsm.PartnerBattleState.ATTACK
end

function PartnerFsm:BattleUpdate()
    if self.m_AttackState ==PartnerFsm.PartnerBattleState.FINDTARGET then
        self:FindTargetUpdate()
    elseif self.m_AttackState == PartnerFsm.PartnerBattleState.MOVETOTARGET then
        self:MoveToTargetUpdate()
    elseif self.m_AttackState == PartnerFsm.PartnerBattleState.DETERMINSKILL then
        self:DeterminSkillUpdate()
    elseif self.m_AttackState == PartnerFsm.PartnerBattleState.ATTACK then
        self:AttackUpdate()
    end
end

function PartnerFsm:update()
    self:CheckState()
    self:SkillsUpdate()
    if self.m_CurrentState == PartnerFsm.PartnerStates.IDLE then
        self:IdleUpdate()
    elseif self.m_CurrentState == PartnerFsm.PartnerStates.BORN then
        self:BornUpdate()
    elseif self.m_CurrentState == PartnerFsm.PartnerStates.BORNING then
        self:BorningUpdate()
    elseif self.m_CurrentState == PartnerFsm.PartnerStates.MOVE then
        self:MoveUpdate()
    elseif self.m_CurrentState == PartnerFsm.PartnerStates.PLAY then
        self:PlayUpdate()
    elseif self.m_CurrentState == PartnerFsm.PartnerStates.TRANSMIT then
        self:TransmitUpdate()
    elseif self.m_CurrentState == PartnerFsm.PartnerStates.BATTLE then
        self:BattleUpdate()
    end
end




return PartnerFsm
