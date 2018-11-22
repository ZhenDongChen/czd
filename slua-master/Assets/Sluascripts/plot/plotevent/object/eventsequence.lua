local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local EventSequence = {};
-----------------------------------------------------------------------------------------------------------------------------------
EventSequence.LoadFunction = function(self)
    local PlotEvents = require("plot.plotevent.plotevents")
    for _, element in pairs(self.Events) do
        element.Cutscene = self.Cutscene
        element.CurrentState = PlotDefine.ElementState.Loaded
        setmetatable(element, {__index = PlotEvents[element.Type]})
        if element.LoadFunction ~= nil then
            element:LoadFunction()
        end
    end
    self.CurrentTime = 0
	self.CurrentState = PlotDefine.ElementState.Loaded;
end
-----------------------------------------------------------------------------------------------------------------------------------

EventSequence.StartFunction = function(self)
    if self.Mode == "Parallel" then
        for _, element in pairs(self.Events) do
            if element.StartFunction then
                element:StartFunction()
            end
        end
    elseif self.Mode == "Serial" then
        self.CurrentElement = 1
    end
    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
EventSequence.LoopFunction = function(self, deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime
    if self.Mode == "Parallel" then
        for _, element in pairs(self.Events) do
            if element.LoopFunction and element.CurrentState >= PlotDefine.ElementState.Started and element.CurrentState < PlotDefine.ElementState.Ended and element.CurrentTime < element.Duration then
                element:LoopFunction(deltaTime)
            elseif element.CurrentState < PlotDefine.ElementState.Ended and element.EndTime < self.CurrentTime then
                element:EndFunction();
            end
        end
    elseif self.Mode == "Serial" then
        if self.Events[self.CurrentElement] then
            local element = self.Events[self.CurrentElement]
            if element.StartFunction and element.CurrentState < PlotDefine.ElementState.Started then
                element:StartFunction()
            end
            if element.LoopFunction and
                element.CurrentState >= PlotDefine.ElementState.Started
                    and element.CurrentState < PlotDefine.ElementState.Ended
                        and element.CurrentTime < element.Duration then
                element:LoopFunction(deltaTime)
            end
            if element.CurrentState < PlotDefine.ElementState.Ended and element.EndTime < self.CurrentTime then
                element:EndFunction()
            end
            if element.EndTime < self.CurrentTime or element.CurrentState >= PlotDefine.ElementState.Ended then
                self.CurrentElement = self.CurrentElement + 1
            end
        end
    end
end
-----------------------------------------------------------------------------------------------------------------------------------
EventSequence.EndFunction = function(self)
    for _, element in pairs(self.Events) do
        if element.EndFunction ~= nil and element.CurrentState < PlotDefine.ElementState.Ended then
            element:EndFunction();
        end
    end
end
EventSequence.DestroyFunction = function(self)
    if self.CurrentState < PlotDefine.ElementState.Ended then
        self:EndFunction();
    end
    for _, element in pairs(self.Events) do
        if element.DestroyFunction ~= nil then
            element:DestroyFunction();
        end
    end
	self.CurrentState = PlotDefine.ElementState.Destroyed;
end
-----------------------------------------------------------------------------------------------------------------------------------
EventSequence.SampleFunction = function(self,time)
    if self.Mode == "Parallel" then
        for _, elmt in pairs(self.Events) do
            if elmt.SampleFunction ~= nil then
                elmt:SampleFunction(self,time - elmt.StartTime);
            end
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------------------
return EventSequence;
