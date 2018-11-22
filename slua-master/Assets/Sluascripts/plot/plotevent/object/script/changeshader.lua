local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local ChangeShader = {};
-----------------------------------------------------------------------------------------------------------------------------------
ChangeShader.LoadFunction = nil;

ChangeShader.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)

    if self.TargetObject == nil then
        self.CurrentState = PlotDefine.ElementState.Ended
        return;
    end

    self.Script = self.TargetObject:GetComponent("CgChangeShader")

    if self.Script ~= nil then
        self.Script:ChangeShaderByName(self.ShowState, self.Duration)
    else
        logError("加载脚本失败：CgChangeShader")
    end

    self.CurrentState = PlotDefine.ElementState.Started;
    self.CurrentTime = 0
end

ChangeShader.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime
end
-----------------------------------------------------------------------------------------------------------------------------------
ChangeShader.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return ChangeShader;



