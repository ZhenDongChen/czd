local PlotDefine    = require("plot.base.plotdefine");
local UIManager     = require("uimanager");
local CameraManager = require("cameramanager");
--local PlotUtil      = require("plot.plotutil")
local PlotEvents    = require("plot.plotevent.plotevents")
local PlotPool      = require("plot.base.plotpool")

local PlotCutscene = {};
-----------------------------------------------------------------------------------------------------------------------------------
PlotCutscene.LoadFunction = function(self)

    for _, element in pairs(self.PlotElements) do
        element.Cutscene = self
        element.CurrentState = PlotDefine.ElementState.Loaded
        setmetatable(element, { __index = PlotEvents[element.Type]})
        element.CurrentTime = 0
        element.CurrentState = PlotDefine.ElementState.Loaded;
        if element.LoadFunction ~= nil then
            element:LoadFunction()
        end
    end
    self.CurrentTime = 0
    self.CurrentCamera = UnityEngine.Camera.main
	self.CurrentState = PlotDefine.ElementState.Loaded;

end
------------------------------------------------------------------------------------------------------------------------------------
PlotCutscene.StartFunction = function(self)
    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
PlotCutscene.LoopFunction = function(self,deltatime)
    self.CurrentTime = self.CurrentTime + deltatime;
    for i, element in ipairs(self.PlotElements) do
        if element.CurrentState >= PlotDefine.ElementState.Started
                and element.CurrentState < PlotDefine.ElementState.Ended 
                and self.CurrentTime >= element.EndTime 
                and element.EndFunction ~= nil then
            element:EndFunction()
        end
    end

    for i, element in ipairs(self.PlotElements) do
        if element.CurrentState < PlotDefine.ElementState.Ended then
            if element.CurrentState < PlotDefine.ElementState.Started and self.CurrentTime >= element.StartTime and element.StartFunction ~= nil then
                element:StartFunction()
            elseif self.CurrentTime > element.StartTime and self.CurrentTime < element.EndTime and element.LoopFunction ~= nil  then
                element:LoopFunction(deltatime);
            end
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------------------
PlotCutscene.EndFunction = function(self)
    for _, element in pairs(self.PlotElements) do
        if element.CurrentState < PlotDefine.ElementState.Ended  and element.EndFunction ~= nil then
            element:EndFunction();
        end
    end
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
PlotCutscene.DestroyFunction = function(self)
    if self.CurrentState < PlotDefine.ElementState.Ended then
        self:EndFunction();
    end
    for _, element in pairs(self.PlotElements) do
        if element.DestroyFunction ~= nil then
            element:DestroyFunction();
        end
    end
	self.CurrentState = PlotDefine.ElementState.Destroyed;
end
-----------------------------------------------------------------------------------------------------------------------------------
PlotCutscene.ResetFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Started;
    self.CurrentTime = 0
    for _, element in pairs(self.PlotElements) do
        if element.ResetFunction ~= nil then
            element:ResetFunction();
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------------------
return PlotCutscene;
