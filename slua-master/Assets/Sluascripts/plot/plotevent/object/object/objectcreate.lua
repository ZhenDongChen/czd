local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")
local Define     = require("define")
local ObjectCreate = {};
-----------------------------------------------------------------------------------------------------------------------------------
ObjectCreate.LoadFunction = function(self)

end
-----------------------------------------------------------------------------------------------------------------------------------
ObjectCreate.ObjectSet = function(self)
        
    if not self.TargetObject then
        return
    end
    if self.SetParent then
        local objectParent = self.Cutscene.m_Pool:Get(self.ParentName)
        if objectParent then
            self.TargetObject.transform.parent = objectParent.transform
        end
    end
    if self.AssetDetailType == "effect" and self.Active == true then
        --printyellow("Effect Set, " , self.TargetObject.name, self.TargetObject.activeSelf)
        --self.TargetObject:SetActive(false);
        ExtendedGameObject.SetActiveRecursely(self.TargetObject,true)
    else
        self.TargetObject:SetActive(self.Active);
    end
    if self.SetTrans then
		self.TargetObject.transform.localScale = self.LocalScale;
        self.TargetObject.transform.position = self.Position;
        self.TargetObject.transform.rotation = Quaternion.Euler(self.Rotation.x, self.Rotation.y, self.Rotation.z);
    end
    --self.LoadFinished = true
end

ObjectCreate.StartFunction = function(self)
      self.TargetObject = self.Cutscene.m_Pool:Spawn(self.IndexName,self.ObjectName,false)
      local baseType, detailType = self.Cutscene.m_Pool:GetAssetType(self.IndexName)
      self.AssetBaseType = baseType
      self.AssetDetailType = detailType
      --printyellow("self.IndexName",self.IndexName,self.AssetDetailType)
      self:ObjectSet()

    self.CurrentState = PlotDefine.ElementState.Started;
end
ObjectCreate.LoopFunction = function(self,deltaTime)

end
-----------------------------------------------------------------------------------------------------------------------------------
ObjectCreate.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return ObjectCreate;
