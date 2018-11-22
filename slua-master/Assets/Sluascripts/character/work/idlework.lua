local defineenum = require "defineenum"
local WorkType = defineenum.WorkType
local Work = require "character.work.work"
local AniStatus = defineenum.AniStatus

local IdleWork = Class:new(Work)
function IdleWork:__new()
    Work.__new(self)
    self:reset()
    self.type = WorkType.Idle
    self.m_IsPlayingWeaponMotion = false
end


function IdleWork:ResetData()
    self.m_IsPlayingWeaponMotion = false
end 

function IdleWork:OnStart()
    Work.OnStart(self)
    if self:NeedPlayIdleAnimation() then
        self:PlayIdleAnimation()
    end
end

function IdleWork:PlayStandMotion() 
    if self.Character.m_IsFighting then
        self.Character:PlayLoopAction(cfg.skill.AnimType.StandFight)
    else 
        self.Character:PlayLoopAction(cfg.skill.AnimType.Stand)
    end 
end 

function IdleWork:PlaySwordMotion() 
    if self.Character and self.Character.AnimationMgr then
        if self.Character.m_IsFighting then 
            if self.Character:IsPlayingAction(cfg.skill.AnimType.Stand) then 
                self.Character:PlayAction(cfg.skill.AnimType.PullSword)
                self.m_IsPlayingWeaponMotion = true
            end 
        else 
            if self.Character:IsPlayingAction(cfg.skill.AnimType.StandFight) then
                self.Character:PlayAction(cfg.skill.AnimType.Inlayersword)
                self.m_IsPlayingWeaponMotion = true
            end
        end

        if not self.m_IsPlayingWeaponMotion then 
            if not self.Character:IsPlayingStand() then
                self:PlayStandMotion()
            end
        end 
    end
end 

function IdleWork:IsPlayingSwordMotion() 
    if self.Character and self.Character.AnimationMgr then
        return self.Character:IsPlayingAction(cfg.skill.AnimType.PullSword) or
           self.Character:IsPlayingAction(cfg.skill.AnimType.Inlayersword) 
    end
end 

function IdleWork:NeedPlayIdleAnimation() 
    if self.Character:IsPlayer() and not self.Character:IsRiding() then 
        if self.Character.m_IsFighting then 
            return not self.Character:IsPlayingAction(cfg.skill.AnimType.StandFight)
        else 
            return not self.Character:IsPlayingAction(cfg.skill.AnimType.Stand)
        end
    else 
        return not self.Character:IsPlayingStand()
    end  
end 

function IdleWork:PlayIdleAnimation()
    if self.Character and self.Character.AnimationMgr then
        
        if self.Character:IsNpc() then 
            if not self.Character:IsPlayingAction(self.Character:GetDefaultMotion()) then 
              self.Character:PlayLoopAction(self.Character:GetDefaultMotion())
            end 
        elseif self.Character:IsMount() then 
            self.Character:PlayIdleWithPlayer()
        elseif self.Character:IsPlayer() then 
            if not self.Character:IsRiding() then
                self:PlaySwordMotion()
            end
        elseif self.Character:IsPet() then
            if not self.Character:IsPlayingAction(cfg.skill.AnimType.FleshRecasting) then
                self:PlayStandMotion()
            end
        else 
            self:PlayStandMotion()
        end
    end
end

function IdleWork:OnUpdate()
    if self.m_IsPlayingWeaponMotion then 
        if not self:IsPlayingSwordMotion() then 
            self:PlayStandMotion()
            self.m_IsPlayingWeaponMotion = false
        end 
    end 
end 

function IdleWork:OnEnd()
    Work.OnEnd(self)
    self.Character.WorkMgr:SetJudgeNeedIdle(false)
end

function IdleWork:ResumeWork() 
    Work.ResumeWork(self)
    self:ResetData() 
    if self:NeedPlayIdleAnimation() then
        self:PlayIdleAnimation()
    end
end 

return IdleWork
