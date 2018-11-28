local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local ObjectDestroy = {};
-----------------------------------------------------------------------------------------------------------------------------------

ObjectDestroy.StartFunction = function(self)
    self.Cutscene.m_Pool:Despawn(self.ObjectName)

    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------
ObjectDestroy.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return ObjectDestroy;