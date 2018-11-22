local PlotDefine = require("plot.base.plotdefine");

local PlotElement = {}

PlotElement.New = function(self)
    local element = {};
    element.base = PlotElement
    setmetatable( element, { __index = PlotElement } )
    return element
end

-----------------------------------------------------------------------------------------------------------------------------------
PlotElement.LoadFunction = function(self,container,cutscene)
    self.CurrentState = PlotDefine.ElementState.Loaded;
end
-----------------------------------------------------------------------------------------------------------------------------------
PlotElement.StartFunction = function(self,container,cutscene)
    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
PlotElement.LoopFunction = function(self,container,cutscene)
    self.CurrentState = PlotDefine.ElementState.Looping;
end
-----------------------------------------------------------------------------------------------------------------------------------
PlotElement.EndFunction = function(self,container,cutscene)
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
PlotElement.DestroyFunction = function(self,container,cutscene)
    self.CurrentState = PlotDefine.ElementState.Destroyed;
end
-----------------------------------------------------------------------------------------------------------------------------------
PlotElement.SampleFunction = function(self,time,container,cutscene)

end
-----------------------------------------------------------------------------------------------------------------------------------
PlotElement.Pause = function(self)

end
-----------------------------------------------------------------------------------------------------------------------------------
PlotElement.Stop = function(self)

end
-----------------------------------------------------------------------------------------------------------------------------------
return PlotElement
