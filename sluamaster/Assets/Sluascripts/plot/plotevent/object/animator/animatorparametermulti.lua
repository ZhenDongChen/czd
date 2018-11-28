local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local AniamtorParameterMulti = {};
-----------------------------------------------------------------------------------------------------------------------------------
AniamtorParameterMulti.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

AniamtorParameterMulti.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)--PlotHelper.GetObject(self.Cutscene,self.ObjectName)
    self.Animator = self.Cutscene.m_Animator:GetAnimator(self.TargetObject)
    if self.Animator then
        for i, para in ipairs(self.ParameterList) do
            if para.Type == "Float" then
                self.Animator:SetFloat(self.Parameter.Name, self.Parameter.DefaultFloat)
            elseif para.Type == "Int" then
                self.Animator:SetInteger(self.Parameter.Name, self.Parameter.DefaultInt)
            elseif para.Type == "Bool" then
                self.Animator:SetBool(self.Parameter.Name, self.Parameter.DefaultBool)
            elseif para.Type == "Trigger" then
                self.Animator:SetTrigger(self.Parameter.Name)
            end
        end
    end
    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
AniamtorParameterMulti.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return AniamtorParameterMulti;
