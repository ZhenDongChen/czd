local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local ScriptLoadDestroy = {};
-----------------------------------------------------------------------------------------------------------------------------------
ScriptLoadDestroy.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

ScriptLoadDestroy.StartFunction = function(self)

    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
ScriptLoadDestroy.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return ScriptLoadDestroy;
