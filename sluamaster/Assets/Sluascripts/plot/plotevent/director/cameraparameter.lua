local PlotDefine = require("plot.base.plotdefine");

local CameraParameter = {};
-----------------------------------------------------------------------------------------------------------------------------------
CameraParameter.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CameraParameter.StartFunction = function(self)
    self.TargetScript = self.Cutscene.m_Camera:GetCamera()--UnityEngine.Camera.main;
    self.ParameterCurveList[1].Curve = UnityEngine.AnimationCurve()
    for _,key in pairs(self.ParameterCurveList[1].KeyList) do
        self.ParameterCurveList[1].Curve:AddKey(key)
    end
    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraParameter.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime;
    self.TargetScript.fieldOfView = self.ParameterCurveList[1].Curve:Evaluate(self.CurrentTime)
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraParameter.EndFunction  = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraParameter.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CameraParameter.SampleFunction = function(self,time)
    self.CurrentTime = time
    self.TargetScript = UnityEngine.Camera.main;
    
    if self.CurrentTime >= 0 and self.CurrentTime < self.Duration then
        if self.CurrentState < PlotDefine.ElementState.Started then
            self:StartFunction()
        end
        self.TargetScript.fieldOfView = self.ParameterCurveList[1].Curve:Evaluate(self.CurrentTime)
    end
end
-----------------------------------------------------------------------------------------------------------------------------------
return CameraParameter;
