
local PlotDefine = require("plot.base.plotdefine");
local UIManager = require("uimanager")

local CameraMask = {};
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.LoadFunction = function(self)
    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Loaded
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.StartFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Started;
    if self.CommandMode == "LuaScript" then
        self.LuaScriptCmd = (loadstring(self.CommandInfo))()
        if self.LuaScriptCmd.StartFunction then
            self.LuaScriptCmd.StartFunction(self)
        end
    end
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.LoopFunction = function(self,deltaTime)
    self.CurrentTime=self.CurrentTime + deltaTime;
    if self.LuaScriptCmd and self.LuaScriptCmd.LoopFunction then
        self.LuaScriptCmd.StartFunction(self)
    end
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.EndFunction  = function(self)
    if self.LuaScriptCmd and self.LuaScriptCmd.EndFunction then
        self.LuaScriptCmd.EndFunction(self)
    end
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.SampleFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
return CameraMask;
