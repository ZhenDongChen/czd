local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")
local TimeScaleSet = {};
-----------------------------------------------------------------------------------------------------------------------------------
TimeScaleSet.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
TimeScaleSet.StartFunction = function(self)
    UnityEngine.Time.timeScale = self.TimeScaleValue * self.Cutscene.PlayRate

    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
TimeScaleSet.EndFunction = function(self)
    if self.Mode == "Event" then
        UnityEngine.Time.timeScale = 1 * self.Cutscene.PlayRate
    end
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
TimeScaleSet.DestroyFunction = function(self)
    UnityEngine.Time.timeScale = 1
    self.CurrentState = PlotDefine.ElementState.Destroyed;
end
-----------------------------------------------------------------------------------------------------------------------------------
TimeScaleSet.SampleFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
return TimeScaleSet;
