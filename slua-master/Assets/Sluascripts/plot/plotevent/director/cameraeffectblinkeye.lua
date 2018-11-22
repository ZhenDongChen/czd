local PlotDefine = require("plot.base.plotdefine");

local BlinkEyes = {};
-----------------------------------------------------------------------------------------------------------------------------------
BlinkEyes.LoadFunction = function(self)
    self.TargettScript = nil
end;
-----------------------------------------------------------------------------------------------------------------------------------
BlinkEyes.StartFunction = function(self)

    self.ParameterCurveList[1].Curve = UnityEngine.AnimationCurve()
    for _,key in pairs(self.ParameterCurveList[1].KeyList) do
        self.ParameterCurveList[1].Curve:AddKey(key)
    end
    local currentCamera = self.Cutscene.m_Camera:GetCamera()
    self.TargettScript = currentCamera:GetComponent("BlinkBlur")
    if self.TargettScript == nil then
        self.TargettScript = currentCamera.gameObject:AddComponent("BlinkBlur")
    end
    
    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
BlinkEyes.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime;
    
    if self.TargettScript ~= nil then
        self.TargettScript.Time = self.ParameterCurveList[1].Curve:Evaluate(self.CurrentTime)
    end
end
-----------------------------------------------------------------------------------------------------------------------------------
BlinkEyes.EndFunction  = function(self)

    if self.TargettScript ~= nil then
        Object.Destroy(self.TargettScript)
        self.TargettScript = nil
    end
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
BlinkEyes.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
BlinkEyes.SampleFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
return BlinkEyes;
