local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local ObjectShowHide = {};
-----------------------------------------------------------------------------------------------------------------------------------
ObjectShowHide.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

ObjectShowHide.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)--PlotHelper.GetObject(self.Cutscene,self.ObjectName)

    if self.TargetObject then
        self.TargetObject:SetActive(self.Active)
    end

    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
ObjectShowHide.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return ObjectShowHide;