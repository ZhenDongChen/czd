local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local AnimatorCurveMulti = {};
-----------------------------------------------------------------------------------------------------------------------------------
AnimatorCurveMulti.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

AnimatorCurveMulti.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)--PlotHelper.GetObject(self.Cutscene,self.ObjectName)
    self.Animator = self.Cutscene.m_Animator:GetAnimator(self.TargetObject)

    for i,cureInfo in ipairs(self.CurveList) do
        cureInfo.Curve = UnityEngine.AnimationCurve()
        for i, key in ipairs(cureInfo.KeyList) do
             cureInfo.Curve:AddKey(key)
        end
    end
    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
AnimatorCurveMulti.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime
    if self.Animator == nil then
        return
    end
    for i,cureInfo in ipairs(self.CurveList) do
        local value = cureInfo.Curve:Evaluate(self.CurrentTime)
        self.Animator:SetFloat(cureInfo.Name,value)
    end
end

AnimatorCurveMulti.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return AnimatorCurveMulti;
