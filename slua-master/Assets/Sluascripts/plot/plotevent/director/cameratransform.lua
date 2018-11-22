local PlotDefine = require("plot.base.plotdefine");


local CameraTransform = { }

CameraTransform.LoadFunction = function(self)
    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Loaded
end
CameraTransform.SetTransform = function(self)
    if self.TargetObject == nil then
        return
    end
	
    if self.ScaleVary then
        self.TargetObject.transform.localScale = self.LocalScale
    end
	
    if self.PositionVary then
        self.TargetObject.transform.position = self.Position
        if self.ProfessionDeviation then
            --local profession = PlayerRole:Instance().m_Profession
            --local gender = PlayerRole:Instance().m_Gender
            local deviation = self.Cutscene.m_Config:GetProfessionDeviation()
            self.TargetObject.transform.position = self.TargetObject.transform.position + deviation
        end
    end
    if self.RotationVary then
        self.TargetObject.transform.rotation = Quaternion.Euler(self.Rotation.x,self.Rotation.y,self.Rotation.z)
    end
end
CameraTransform.StartFunction = function(self)
    
    
    --local cameraObj = UnityEngine.Camera.main.gameObject
    self.TargetObject = self.Cutscene.m_Camera:GetControllerObject() --cameraObj.transform.parent.gameObject
    
    self:SetTransform()

    self.CurrentState = PlotDefine.ElementState.Started;
end
CameraTransform.SampleFunction = function(self,time)
    self.CurrentTime = time
   -- local cameraObj = UnityEngine.Camera.main.gameObject
    self.TargetObject = self.Cutscene.m_Camera:GetControllerObject()--cameraObj.transform.parent.gameObject
    if self.CurrentTime >= 0 and self.CurrentTime < self.Duration then
        self:SetTransform()
    end
end
return CameraTransform
