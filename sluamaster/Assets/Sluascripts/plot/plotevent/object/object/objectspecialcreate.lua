local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")
local Define     = require("define")

local ObjectSpecialCreate = {};
-----------------------------------------------------------------------------------------------------------------------------------
ObjectSpecialCreate.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
ObjectSpecialCreate.ObjectSet = function(self)
    if not self.TargetObject then
        return
    end
    if self.SetParent then
        local objectParent = PlotHelper.GetObject(self.Cutscene,self.ParentName)
        if objectParent then
            self.TargetObject.transform.parent = objectParent.transform
        end
    end
    self.TargetObject:SetActive(self.Active);
    if self.SetTrans then
		self.TargetObject.transform.localScale = self.LocalScale;
        self.TargetObject.transform.position = self.Position;
        self.TargetObject.transform.rotation = Quaternion.Euler(self.Rotation.x, self.Rotation.y, self.Rotation.z);
    end
    self.LoadFinished = true
end

ObjectSpecialCreate.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Spawn(self.IndexName,self.ObjectName,self.Active)
    self:ObjectSet()
   
    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
ObjectSpecialCreate.EndFunction = function(self)

end
-----------------------------------------------------------------------------------------------------------------------------------
return ObjectSpecialCreate;
