local CameraManager     = require("cameramanager");

local PlotCamera = Class:new()

function PlotCamera:__new(cutscene, config)
    self.m_Cutscene = cutscene
    self.m_Config = config
	self.m_RecordInfo = {
        CameraParentPos = Vector3(0,0,0),
        CameraParentRot = Quaternion.identity,

        CameraLocalPos = Vector3(0,0,12),
        CameraLocalRot = Quaternion.identity,
    }
end

function PlotCamera:OnStart()
    if self.m_Config.mainCameraControl == false then
        return
    end
    CameraManager.CameraControl("Obtain");
    local curCamera = UnityEngine.Camera.main
    if not IsNull(curCamera.gameObject.transform.parent) then
        self.m_RecordInfo.CameraParentPos = curCamera.gameObject.transform.parent.position
        self.m_RecordInfo.CameraParentRot = curCamera.gameObject.transform.parent.rotation

        self.m_RecordInfo.CameraLocalPos = curCamera.gameObject.transform.localPosition
        self.m_RecordInfo.CameraLocalRot = curCamera.gameObject.transform.localRotation

        curCamera.gameObject.transform.parent.position = curCamera.gameObject.transform.position
        curCamera.gameObject.transform.parent.rotation = curCamera.gameObject.transform.rotation
        curCamera.gameObject.transform.localPosition = Vector3(0,0,0)
        curCamera.gameObject.transform.localRotation = Quaternion.identity
    end
end

function PlotCamera:OnEnd()
    if self.m_Config.mainCameraControl == false then
        return
    end
    local curCamera = UnityEngine.Camera.main
    if not IsNull(curCamera.gameObject.transform.parent) then

        curCamera.gameObject.transform.parent.position = self.m_RecordInfo.CameraParentPos
        curCamera.gameObject.transform.parent.rotation = self.m_RecordInfo.CameraParentRot

        curCamera.gameObject.transform.localPosition = self.m_RecordInfo.CameraLocalPos
        curCamera.gameObject.transform.localRotation = self.m_RecordInfo.CameraLocalRot

    end
    CameraManager.CameraControl("Release");

    -- CameraManager.reset()
   CameraManager.Restore()
end

function PlotCamera:GetMainCameraPosition()
    local curCamera = UnityEngine.Camera.main
    return curCamera.transform.position
end

function PlotCamera:GetCamera()
    return UnityEngine.Camera.main
end

function PlotCamera:GetCameraObject()
    return UnityEngine.Camera.main.gameObject
end

function PlotCamera:GetCameraTransform()
    local cameraObj = self:GetCameraObject()
    return cameraObj.transform
end
function PlotCamera:GetControllerObject()
    local cameraObj = self:GetCameraObject()
    return cameraObj.transform.parent.gameObject
end

function PlotCamera:GetControllerTransform()
    local cameraObj = self:GetCameraObject()
    return cameraObj.transform.parent
end

return PlotCamera
