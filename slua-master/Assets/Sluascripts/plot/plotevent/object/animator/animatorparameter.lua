local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local AniamtorParameter = {};
-----------------------------------------------------------------------------------------------------------------------------------
AniamtorParameter.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

AniamtorParameter.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)
    self.Animator = self.Cutscene.m_Animator:GetAnimator(self.TargetObject)
    if self.Animator then
        if self.Parameter.Type == "Float" then
            self.Cutscene.m_Animator:SetFloat(self.Animator, self.Parameter.Name, self.Parameter.DefaultFloat)
        elseif self.Parameter.Type == "Int" then
            self.Cutscene.m_Animator:SetInteger(self.Animator, self.Parameter.Name, self.Parameter.DefaultInt)
        elseif self.Parameter.Type == "Bool" then
            self.Cutscene.m_Animator:SetBool(self.Animator, self.Parameter.Name, self.Parameter.DefaultBool)
        elseif self.Parameter.Type == "Trigger" then
            self.Cutscene.m_Animator:SetTrigger(self.Animator, self.Parameter.Name)
        end
    end
    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
AniamtorParameter.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return AniamtorParameter;
