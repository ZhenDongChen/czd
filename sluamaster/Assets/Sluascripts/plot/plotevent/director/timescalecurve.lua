local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local TimeScaleCurve = {};
-----------------------------------------------------------------------------------------------------------------------------------
TimeScaleCurve.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

TimeScaleCurve.StartFunction = function(self)

    self.Curve.Curve = AnimationCurve()
    for i, key in ipairs(self.Curve.KeyList) do
        self.Curve.Curve:AddKey(key)
    end

    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
TimeScaleCurve.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime

    local value = self.Curve.Curve:Evaluate(self.CurrentTime)
    UnityEngine.Time.timeScale = value * self.Cutscene.PlayRate
end

TimeScaleCurve.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end
TimeScaleCurve.DestroyFunction = function(self)
    UnityEngine.Time.timeScale = 1 * self.Cutscene.PlayRate
    self.CurrentState = PlotDefine.ElementState.Destroyed;
end
-----------------------------------------------------------------------------------------------------------------------------------
return TimeScaleCurve;
