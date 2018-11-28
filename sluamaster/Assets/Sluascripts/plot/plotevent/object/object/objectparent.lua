local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local ObjectParent = {};
-----------------------------------------------------------------------------------------------------------------------------------
ObjectParent.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

ObjectParent.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)
    
    self.ParentObject = self.Cutscene.m_Pool:Get(self.ParentName) --PlotHelper.GetObject(self.Cutscene,self.ParentName)
    
    if self.TargetObject and self.ParentObject then
        self.TargetObject.transform.parent = self.ParentObject.transform
    end
    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
ObjectParent.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return ObjectParent;
