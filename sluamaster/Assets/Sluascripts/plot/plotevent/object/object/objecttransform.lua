local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local ObjectTransform = {};
-----------------------------------------------------------------------------------------------------------------------------------
ObjectTransform.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

ObjectTransform.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)-- PlotHelper.GetObject(self.Cutscene,self.ObjectName)

    if self.TargetObject then
		self.TargetObject.transform.localScale = self.LocalScale;
        self.TargetObject.transform.position = self.Position;
        self.TargetObject.transform.rotation = Quaternion.Euler(self.Rotation.x, self.Rotation.y, self.Rotation.z);
    end

    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
ObjectTransform.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end
ObjectTransform.SampleFunction = function(self, time)
    self.CurrentTime = time
    
    if self.CurrentTime >= 0 and self.CurrentTime <= self.Duration then
        self:StartFunction()
    end
    
end

-----------------------------------------------------------------------------------------------------------------------------------
return ObjectTransform;