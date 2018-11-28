local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local AnimatorCurve = {};
-----------------------------------------------------------------------------------------------------------------------------------
AnimatorCurve.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

AnimatorCurve.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)
    self.Animator = self.Cutscene.m_Animator:GetAnimator(self.TargetObject)

    self.Curve.Curve = UnityEngine.AnimationCurve()
    for i, key in ipairs(self.Curve.KeyList) do
        self.Curve.Curve:AddKey(key)
    end

    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
AnimatorCurve.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime

    if self.Animator == nil then
        return
    end
    local value = self.Curve.Curve:Evaluate(self.CurrentTime)
    self.Cutscene.m_Animator:SetFloat(self.Animator, self.Curve.Name, value)
end

AnimatorCurve.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return AnimatorCurve;
