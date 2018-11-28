local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")
local SkillManager = require("character.skill.skillmanager")
--GetAnimatorStateName
local AniamtorPlay = {};
-----------------------------------------------------------------------------------------------------------------------------------
AniamtorPlay.LoadFunction = nil;

AniamtorPlay.PlayAnimation = function(self, animator, stateName)
    if self.Layer and self.NormalizedTime and (self.Layer ~= -1 or self.NormalizedTime ~= 0) then
        if self.IsCrossFade == true then
            self.Cutscene.m_Animator:CrossFade(animator, stateName, self.TransitionDuration, self.Layer, self.NormalizedTime);
        else
            self.Cutscene.m_Animator:Play(animator, stateName, self.Layer, self.NormalizedTime)
        end
    else
        if self.IsCrossFade == true then
            self.Cutscene.m_Animator:CrossFadeBase(animator, stateName, self.TransitionDuration)
        else
            self.Cutscene.m_Animator:PlayBase(animator, stateName)
        end    
    end
end

AniamtorPlay.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)

    if self.TargetObject == nil then
        self.CurrentState = PlotDefine.ElementState.Ended
        return;
    end

    self.Animator = self.Cutscene.m_Animator:GetAnimator(self.TargetObject)

    if not self.Animator then
        self.CurrentState = PlotDefine.ElementState.Ended
        return;
    end

    self:PlayAnimation( self.Animator, self.StateName)

    self.CurrentState = PlotDefine.ElementState.Started;
    self.CurrentTime = 0
end

AniamtorPlay.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime

end
-----------------------------------------------------------------------------------------------------------------------------------
AniamtorPlay.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return AniamtorPlay;
