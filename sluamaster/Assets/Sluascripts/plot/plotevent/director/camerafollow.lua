local PlotDefine = require("plot.base.plotdefine");
--local PlotConfig = require("plot.base.plotconfig")
local PlotHelper = require("plot.plothelper")


local CameraFollow = { }

CameraFollow.LoadFunction = function(self)
    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Loaded
end

CameraFollow.StartFunction = function(self)
  --  local cameraObj = UnityEngine.Camera.main.gameObject
    self.TargetObject = self.Cutscene.m_Camera:GetControllerObject()
    self.FollowObject = self.Cutscene.m_Pool:Get(self.ObjectName)
    
    self.CurrentState = PlotDefine.ElementState.Started
end

CameraFollow.SetPositionOfTime = function(self)
	if self.TargetObject == nil or self.FollowObject == nil then
		return;
	end

    if self.PositionFollow then
        local targetPos = self.FollowObject.transform.position + self.RelativePosition
        if self.PositionFollowFactor > 0 then
            self.TargetObject.transform.position = Vector3.Lerp(self.TargetObject.transform.position,targetPos,Time.deltaTime * self.PositionFollowFactor);
        else
            self.TargetObject.transform.position = targetPos
        end
    end
    if self.RotationFollow then
        local targetRot = self.FollowObject.transform.rotation.eulerAngles + self.RelativeRotation
        if self.RotationFollowFactor > 0 then
            self.TargetObject.transform.rotation = Quaternion.Slerp(self.TargetObject.transform.rotation,Quaternion.Euler(targetRot.x,targetRot.y,targetRot.z),Time.deltaTime * self.RotationFollowFactor)
        else
            self.TargetObject.transform.rotation = Quaternion.Euler(targetRot.x,targetRot.y,targetRot.z)
        end
    end
end

CameraFollow.LoopFunction = function(self,deltaTime)
	self.CurrentTime = self.CurrentTime + deltaTime;
    self:SetPositionOfTime()
end

CameraFollow.SampleFunction = function(self,time)
    self.CurrentTime = time
    if self.TargetObject == nil then
   --    self.TargetObject = cameraObj.transform.parent.gameObject
    end
    self:SetPositionOfTime()
end

return CameraFollow
