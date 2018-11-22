local HumanoidAvatar         = require "character.avatar.humanoidavatar"

local CharacterShapeShift = Class:new()

function CharacterShapeShift:__new(character)
    self.m_Character = character
    self.m_BakModelData = nil
    self.m_ShapeShiftLife = -1
    self.m_NeedResumeShape = false
    self.m_IsResuming = false
    self.m_ResumeLeftTime = 0
end

function CharacterShapeShift:IsShapeShift()
    return self.m_BakModelData ~= nil
end

function CharacterShapeShift:IsResuming()
    return self.m_IsResuming
end

function CharacterShapeShift:RefreshBakModelData(modeldata)
    self.m_BakModelData = modeldata
end  

function CharacterShapeShift:ShapeShift(modelname,life)
    local modelData = ConfigManager.getConfigData("model",modelname)
    if modelData == nil then 
        return 
    end
    if not self:IsShapeShift() then 
        self.m_BakModelData = self.m_Character.m_ModelData
    end
    self.m_NeedResumeShape = false
    self.m_IsResuming = false
    self.m_ShapeShiftLife = life or -1
    if self.m_Character:IsAttacking() then
        self.m_Character.AttackActionFsm:BreakCurrentSkill()
    end
    if self.m_Character:IsPlayer() then 
        self.m_Character.m_Avatar:UnEquip(HumanoidAvatar.EquipType.WEAPON)
    end 
    self.m_Character:CriticalLoadModel({modelData,modelData,true})
end

function CharacterShapeShift:ResumeShape()
    if self:IsShapeShift() and not self.m_NeedResumeShape then
        self.m_NeedResumeShape = true
    end
end

function CharacterShapeShift:ResumeShapeNow()
    if self:IsShapeShift() then 
        local modelData = self.m_BakModelData
        self.m_BakModelData = nil
        self.m_Character:CriticalLoadModel({modelData,modelData,true})
        if self.m_Character:IsPlayer() then 
            self.m_Character:LoadWeapon()
        end
        if self.m_Character:IsRole() then 
            local RoleSkill = require "character.skill.roleskill"
            RoleSkill.RefreshEquipedSkills()
        end 
    end 
end 

function CharacterShapeShift:AddTransformEffect(effectid,life)
    local effectData = ConfigManager.getConfigData("effect",effectid)
     if effectData and not self.m_Character:IsDead() then
        local modelname = effectData.model
        if self.m_Character:IsPlayer() and not self.m_Character:IsMale() then 
            modelname = effectData.model2
        end
        self:ShapeShift(modelname,life)
        if self.m_Character:IsRole() then 
            local RoleSkill = require "character.skill.roleskill"
            RoleSkill.RefreshTransformSkills(effectData.skilllist)
        end 
    end
end 


function CharacterShapeShift:RemoveTransformEffect()
    if self:IsShapeShift() then
        self:ResumeShape()
    end
end 

function CharacterShapeShift:OnReset()
    self.m_BakModelData = nil
end

function CharacterShapeShift:OnDestroy()
end

function CharacterShapeShift:OnUpdate()
    if self:IsShapeShift() then 
        if self.m_ShapeShiftLife>0 then 
            self.m_ShapeShiftLife = self.m_ShapeShiftLife - Time.deltaTime
            if self.m_ShapeShiftLife<0 then 
                self:ResumeShape()
            end 
        end 
        if self.m_NeedResumeShape and not self.m_Character:IsAttacking() then
            self.m_NeedResumeShape = false
            if self.m_Character:IsDead() and not self.m_Character:IsRelive() then 
                return 
            end
            local resumeaction = self.m_Character:GetAction(cfg.skill.AnimType.TransformEnd)
            if resumeaction then 
                self.m_IsResuming = true
                self.m_ResumeLeftTime = resumeaction.endattackingtime
                self.m_Character:PlayAction(cfg.skill.AnimType.TransformEnd)
            else 
                self:ResumeShapeNow()
            end 
        end

        if self.m_IsResuming then 
            if self.m_ResumeLeftTime>0 then 
                self.m_ResumeLeftTime = self.m_ResumeLeftTime - Time.deltaTime
            else 
                self.m_IsResuming = false
                if self.m_Character:IsDead() and not self.m_Character:IsRelive() then 
                    return 
                end
                self:ResumeShapeNow()
            end 
        end 
    end 
end

function CharacterShapeShift:OnDeath()
end 

function CharacterShapeShift:OnRevive()
    if self:IsShapeShift() then
        self:ResumeShapeNow()
    end 
end




return CharacterShapeShift