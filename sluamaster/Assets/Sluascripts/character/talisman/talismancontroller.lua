local UIManager                 = require("uimanager")
local TalismanModel             = require("character.talisman.talisman")
local TalismanConfig            = require("character.talisman.talismanconfig")

--local TalismanFightMoveState    = require("character.talisman.talismanstates.talismanfightmovestate")
local TalismanFightState        = require("character.talisman.talismanstates.talismanfightstate")
local TalismanFollowState       = require("character.talisman.talismanstates.talismanfollowstate")
local TalismanIdleState         = require("character.talisman.talismanstates.talismanidlestate")

local StateType                 = TalismanConfig.StateType

local TalismanController = Class:new()

function TalismanController:__new(character)
    self.m_Character = character
    self.m_Talisman = nil
    self.m_Model = nil
    
    self.m_Rotation = Quaternion.identity
    self.m_Position = Vector3(0,0,0)
    self.m_MoveSpeed = 0
    self.m_Acceleration = 0
    self.m_CurrentState = StateType.Idle
    self.m_CharacterState = {}
    self.m_PlaySkill = nil

    self.m_States = {
        [StateType.Idle]    = TalismanIdleState:new(),
        [StateType.Follow]  = TalismanFollowState:new(),
        [StateType.Fight]   = TalismanFightState:new(),
    }
end

function TalismanController:CheckTalisman(talisman)
    if self.m_Talisman ~= talisman then
        self.m_Talisman = talisman
        if self.m_Model ~= nil then
            self.m_Model:remove()
            self.m_Model = nil
        end
        if self.m_Talisman ~= nil then
            self.m_Model = TalismanModel:new()
            self.m_Model:init(self.m_Talisman, self.m_Character, self.m_Talisman.ID)
        end
        
        if self.m_Character:IsRole() then
            local skill = self:GetInitiativeSkill()
            local RoleSkill = require("character.skill.roleskill")
            
            if skill then
                RoleSkill.SetTalismanSkillId(skill:GetConfigId(),skill:GetLevel())
            else
                RoleSkill.SetTalismanSkillId(0,nil)
            end
--            local GameAI = require"character.ai.gameai"
--            GameAI.SetSkillChange(true)
            local autoai = require "character.ai.autoai"
            autoai.InitSkills()            
            UIManager.refresh("dlguimain")

        end
        
    end
    if self.m_Talisman ~= nil and self.m_Model ~= nil  then
        return true
    end
    return false
end

function TalismanController:GetCharacterState(character)
        return {
            m_IsMoving      = character:IsMoving(),
            m_IsFighting    = character.m_IsFighting,
            m_FightTarget   = character.m_TargetId,
            m_Position      = character:GetPos() or Vevtor3(0,0,0),
            m_Rotation      = character.m_Rotation or Quaternion.identity ,
            m_MoveSpeed     = character.m_Attributes[cfg.fight.AttrId.MOVE_SPEED] or (5*SCALE_SPEED),
        }
end

function TalismanController:SetPos(position)
    if self.m_Model then
        self.m_Model:SetPos(position)
    end
end

function TalismanController:GetPos(position)
    if self.m_Model then
        return self.m_Model:GetPos()
    end
    return Vector3(0,0,0)
end

function TalismanController:SetRotation(rotation,immadiate)
    if self.m_Model then
        if immadiate then
            self.m_Model:SetRotationImmadiate(rotation)
        else
            self.m_Model:SetRotation(rotation)
        end
    end
end

function TalismanController:ChangeState(state)
    self.m_CurrentState = state
    if self.m_Model then
        if state == StateType.Idle then
            self.m_Model:SwitchToIdle()
        elseif state == StateType.Follow then
            self.m_Model:SwitchToFollow()
        end
    end
end

function TalismanController:Update(talisman)
    local result = self:CheckTalisman(talisman)
    if talisman == nil then 
        return 
    end
    

    if TalismanConfig.LuaMode == false then
     --   status.BeginSample("CsMode")
    --    for i = 1, 100 do
        if TalismanConfig.LuaUpdate == true then
            if self.m_Model then
                self.m_Model:UpdateCsControl()
            end
        end
        if self.m_Model.m_Avatar then
            self.m_Model.m_Avatar:Update()
        end
     --   end
      --  status.EndSample()
        return
    end

    --status.BeginSample("LuaMode")
 --   for i = 1, 100 do
    self.m_CharacterState = self:GetCharacterState(self.m_Character)
    if result then
        if not self.m_States[self.m_CurrentState]:IsStart() then
            self.m_States[self.m_CurrentState]:Start(self)
        else
            self.m_States[self.m_CurrentState]:Update(Time.deltaTime)
            local result = self:GlobalTransitions() or self.m_States[self.m_CurrentState]:Transitions()
            if result and self.m_States[result] ~= nil and result ~= self.m_CurrentState then
                self.m_States[self.m_CurrentState]:End()
                self:ChangeState(result)
            end
        end
    end
    
    if self.m_Model then
        self.m_Model:update()
    end
 --   end
   -- status.EndSample()
end

function TalismanController:GlobalTransitions()
    local vec = self.m_CharacterState.m_Position - self:GetPos()
    if self.m_PlaySkill == true then
        return TalismanConfig.StateType.Fight
    end
    if vec.magnitude > TalismanConfig.FollowSetting.EffectDistance then
        return TalismanConfig.StateType.Follow
    end

    return nil
end
function TalismanController:IsTalsimanSkill(skillId)
    if self.m_Talisman ~= nil then
        local skill = self:GetInitiativeSkill()
        if skill then
            if skillId == skill:GetConfigId() then
                return true
            end
        end
    end
    return false
end
function TalismanController:StartSkill()
    if self.m_Model then
        self.m_Model:SetPlaySkill(true)
    end
    if self.m_Talisman then
        self.m_Talisman.NormalExp = self.m_Talisman.NormalExp + 1
    end
    self.m_PlaySkill = true
end
function TalismanController:EndSkill()
    if self.m_Model then
        self.m_Model:SetPlaySkill(false)
    end
    self.m_PlaySkill = false
end
function TalismanController:GetInitiativeSkill()
    return self.m_Talisman and self.m_Talisman:GetInitiativeSkill()
end


function TalismanController:OnTalismanChange(talisman)
    if self.m_Character and self.m_Character:IsRole() then
        local RoleSkill = require("character.skill.roleskill")
        RoleSkill.ResetTalismanCD()
    end
end
function TalismanController:OnDestroy()
    self.m_Character.m_Talisman = nil
    if self.m_Model ~= nil then
        self.m_Model:remove()
        self.m_Model = nil
    end
end

return TalismanController
