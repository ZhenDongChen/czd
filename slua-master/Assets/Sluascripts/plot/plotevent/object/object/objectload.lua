local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")
local Define     = require("define")

local ObjectLoad = {};
-----------------------------------------------------------------------------------------------------------------------------------
ObjectLoad.LoadFunction = function(self)

end
-----------------------------------------------------------------------------------------------------------------------------------

ObjectLoad.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Spawn(self.IndexName,self.ObjectName,true)
    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
ObjectLoad.EndFunction = function(self)

end

-----------------------------------------------------------------------------------------------------------------------------------
return ObjectLoad;
