local require = require
local print = print
local printt = printt
local network = require "network"
local mathutils = require "common.mathutils"
local gameevent = require "gameevent"
local define = require"define"

local Mount
local SceneManager = require "scenemanager"
local uimanager = require"uimanager"
local CameraShakeManager = require "effect.camerashakemanager"
local PlayerRole

local CameraAssist
local CameraMode
local CameraIsControl=false
local CameraModeType = {ThirdPerson = 0,FirstPerson =1,StoryMotion=2}
local CAMERAPOS_MAX = 10000
local CameraDefaultZ = -1000

local LastCameraPos
local LastGameCameraPos = Vector3.zero

local NeedSetupDistance
local NeedSetupCamera

local DefaultFixedDeltaTime = 0.033
local EndSlowMotionTime

local isStop = true
local isNew = false

local OnReset

local resolution
local resolutionCoeff


local isLogin
local LoginAssist
local loginElapsedTime
local loginPushOrPull
local loginDeltaSpeed
local loginDlg

local m_MapSize = nil;
local m_CameraRect = nil;
local m_CameraHalfWidth = 0;
local m_CameraHalfHeight = 0;
local touches = {}

local autoai

local function release()
    GameObject.Destroy(CameraAssist)
    CameraAssist = nil
end


local function EndSlowMotion()
    EndSlowMotionTime = 0
    Time.timeScale = 1.0
    Time.fixedDeltaTime = DefaultFixedDeltaTime * Time.timeScale
    NeedSetupDistance = true
end

local function SetBornParams()
    setDistance(8.5)
    SetRotation(21,123)
end

local function reset()
	local mapid = PlayerRole:Instance():GetMapId() or 100
	local mapInfo = ConfigManager.getConfigData("worldmap",mapid)
	CameraMode = CameraModeType.ThirdPerson
	m_MapSize = nil;
	m_CameraRect = nil;
	
	m_CameraHalfWidth = 0;
	m_CameraHalfHeight = 0;
	EndSlowMotionTime = 0
	NeedSetupCamera = true
	EndSlowMotion()
	isStop = false
	local PrologueManager = require"prologue.prologuemanager"
	if isNew then
		SetBornParams()
		isNew = false
	end
	
	if OnReset then
		OnReset()
		OnReset = nil
	end
	
	NeedSetupDistance = true
end

local function stop()
    isStop = true
end


local function MainCamera()
    return Camera
end



local function Restore()
    NeedSetupCamera = true
    NeedSetupDistance = true
end

local function CameraControl(state)

    if state=="Obtain" then
        CameraIsControl=true
    elseif state=="Release" then
        CameraIsControl=false
    end
    return mainCamera
end


local function CreatLoginAssist()
    if not LoginAssist then
        LoginAssist = GameObject("LoginAssist")
    end
    LoginAssist.transform.localRotation = Quaternion.Euler(0,180,0)
    LoginAssist.transform.position = Vector3(0, -3.3, 5)
end

local function DestroyLoginAssist()
    if LoginAssist then
        cameraTransform:SetParent(nil)
		GameObject.DontDestroyOnLoad(cameraObject)
        GameObject.Destroy(LoginAssist)
        LoginAssist = nil
    end
end

local function LoginUpdate()
    loginElapsedTime = loginElapsedTime + Time.deltaTime
    local factor = loginElapsedTime/1
    if factor>1 then
        factor=1
        if LoginAssist then
            cameraTransform:SetParent(LoginAssist.transform);
        end
        loginPushOrPull = false
        isLogin = false
        if loginDeltaSpeed>0 then
            uimanager.hide(loginDlg)
            uimanager.show("dlglogin")
        else

        end
        if loginDlg then
            if uimanager.hasloaded(loginDlg) then
                uimanager.call(loginDlg,"show_UIs")
                loginDlg = nil
            end
        end
    end
	
end


local function SetCameraPos(pos)
    if CameraAssist then
		LastGameCameraPos = Vector3(pos.x, pos.y, CameraDefaultZ)
        CameraAssist.transform.position = Vector3(pos.x * SCALE_XY_FRACTION, pos.y * SCALE_XY_FRACTION, CameraDefaultZ)
    end
end


local function GetPlayerPos()

    if PlayerRole:Instance().m_Mount and PlayerRole:Instance().m_Mount:IsAttach() then
        local OffsetPlayer = Vector3.up * 0---0.1 * PlayerRole:Instance().m_Height
	
        local pos= PlayerRole:Instance().m_Mount:GetRefPos() 
		pos=pos+ OffsetPlayer 
		local hei=PlayerRole:Instance().m_Mount.m_PropData.ridingheight
		pos=pos+ Vector3.up * PlayerRole:Instance().m_Mount.m_PropData.ridingheight
		return pos
    else
        return PlayerRole:Instance():GetPos()
    end
end

local function GetCameraBasicPos()
    local pos
    if CameraMode == CameraModeType.ThirdPerson then
        pos = GetPlayerPos()
    elseif CameraMode == CameraModeType.StoryMotion then

    end
	
	if m_CameraHalfWidth + pos.x > m_MapSize.x then
		pos.x = pos.x - (m_CameraHalfWidth + pos.x - m_MapSize.x)
	end
	
	if m_CameraHalfHeight + pos.y > m_MapSize.y then
		pos.y = m_MapSize.y - m_CameraHalfHeight
	end
	
	if m_CameraHalfWidth > pos.x then
		pos.x = m_CameraHalfWidth;
	end
	
	if m_CameraHalfHeight > pos.y then
		pos.y = m_CameraHalfHeight;
	end
--[[	
	
	if offsetX > 0 then
		local MaxX = offsetX + CameraRect.xMax;
		if MaxX > SceneManager.GetSceneSize().x then
			pos.x = pos.x - offsetX - (MaxX - SceneManager.GetSceneSize().x)
		end
	else
		local MinX = CameraRect.xMin + offsetX;
		if MinX < 0 then
			pos.x = pos.x - MinX
		end
	end
	
	if offsetY > 0 then
		local MaxY = offsetY + CameraRect.yMax;
		if MaxY > SceneManager.GetSceneSize().y then
			pos.y = pos.y - (MaxY - SceneManager.GetSceneSize().y )
			printyellow("off " ..pos.y .. "   max " .. MaxY);
		end
	else
		local MinY = CameraRect.yMin + offsetY;
		if MinY < 0 then
			pos.y = pos.y - MinY
		end
	end]]
	
    SetCameraPos(pos)
end


local function setup()
    NeedSetupCamera = false
    CameraAssist.transform.position = Vector3.zero
    cameraTransform:SetParent(CameraAssist.transform)

    LastCameraPos = CameraAssist.transform.position
	LastGameCameraPos = Vector3.zero
    GetCameraBasicPos()
end

local function GetCameraPosByShake()
    local pos = CameraAssist.transform.position
    local offset = CameraShakeManager.GetOffset()
    pos = pos + Vector3.Normalize(CameraAssist.transform.right) * offset.x
	pos.x = pos.x * SCALE_XY;
    pos.y =(pos.y+ offset.y)*SCALE_XY
    SetCameraPos(pos)
end


local function updateTouches()
    if touchCount ~= Input.touchCount then
        touchCount = Input.touchCount
        for i=0,touchCount-1 do
            local curTouch = Input.GetTouch(i)  -- no prob
            if curTouch.phase == TouchPhase.Began then
                if LuaHelper.IsTouchedUI(i) then
                    touches[curTouch.fingerId] = 0 -- on ui
                else
                    touches[curTouch.fingerId] = 1 -- not on ui
                end
            elseif curTouch.phase == TouchPhase.Ended
                or curTouch.phase == TouchPhase.Canceled then
                touches[i] = nil
            end
        end
    end
end


local function late_update()
	if SceneManager.IsLoadingScene() then return end
    if isLogin and loginPushOrPull then
        LoginUpdate()
        return
    end
	
	if isLogin or loginPushOrPull then return end
	
    if isStop then 
		return
	end
	
	if CameraIsControl==true then
        return
    end
    if not Camera then
        return
    end
	
	if PlayerRole:Instance():IsLoadingModel() then
		return 
	end
	if not PlayerRole:Instance().m_Object then 
		return 
	end
	
	if m_MapSize == nil then
		m_MapSize = Game.SceneMgr.Instance:GetMapSize();
		m_CameraRect = Game.SceneMgr.Instance:GetCameraRect();
		m_CameraHalfWidth = m_CameraRect.width * 0.5
		m_CameraHalfHeight =  m_CameraRect.height * 0.5
	end
	
	--[[local TempCameraRect = Game.SceneMgr.Instance:GetCameraRect();
	if math.abs( m_CameraRect.width - TempCameraRect.width ) > 1 then
		m_CameraRect = TempCameraRect; 
		m_CameraHalfWidth = m_CameraRect.width * 0.5
		m_CameraHalfHeight =  m_CameraRect.height * 0.5
	end
	
	if math.abs( m_CameraRect.height - TempCameraRect.height ) > 1 then
		m_CameraRect = TempCameraRect;
		m_CameraHalfWidth = m_CameraRect.width * 0.5
		m_CameraHalfHeight =  m_CameraRect.height * 0.5
	end]]
		
    GetCameraBasicPos()
	
	local playerrole = PlayerRole:Instance().m_Object
		if playerrole then
			
		if LuaHelper.IsWindowsEditor() or Application.platform == UnityEngine.RuntimePlatform.WindowsPlayer then
            if autoai.IsRunning()then
                local InputController = require"input.inputcontroller"
                local inputinst = InputController.Instance()
                local clicks = inputinst:GetCurrentClicks()
                if clicks[0] then
					print("GetCurrentClicks")
                    autoai.ToNormalMode()
                end
            end
        end

		
		 if not LuaHelper.IsWindowsEditor() and Application.platform ~= UnityEngine.RuntimePlatform.WindowsPlayer then
			if autoai.IsRunning() then
				if Input.touchCount > 0 then
					autoai.ToNormalMode()
				end
			end
		 end
		updateTouches()
		local UITouchCount = 0
		for i=0,touchCount-1 do
			local curTouch = Input.GetTouch(i)
			if touches[curTouch.fingerId] == 0 then
				UITouchCount = UITouchCount + 1
			end
		end
		local actTouchCount = touchCount - UITouchCount
		if actTouchCount == 0 then
			-- do nothing
		elseif actTouchCount == 1 then
			--TouchCameraAngleManager()
		elseif actTouchCount == 2 then
			--TouchDistanceManager()
		end
	end
	
	if 0 ~= EndSlowMotionTime and Time.realtimeSinceStartup > EndSlowMotionTime then
        EndSlowMotion()
    end

    if  NeedSetupCamera then
        setup()
    end
	
	if PlayerRole:Instance().m_Object then
        GetCameraPosByShake()
    end
  --todo?IsNavigating mount
end



local function ToLoginMode(param)
    cameraTransform:SetParent(nil)
    isLogin = true
    loginPushOrPull = true
    loginElapsedTime = 0
	
    loginDlg = param
end

local function LoginPush(param)
    ToLoginMode(param)
    loginDeltaSpeed = 1
end

local function LoginPull(param)
    ToLoginMode(param)
    loginDeltaSpeed = -1
end


local function NotifySceneLoginLoaded()
    local pos = Vector3(0,0,0)
    cameraTransform:SetParent(nil)
    cameraTransform.position = pos
    cameraTransform.localRotation = Quaternion.Euler(0,0,0)
    isLogin = true
end


local function init()
	local eid = gameevent.evt_late_update:add(late_update)
    

    Mount=require "character.mount"
	CameraAssist = GameObject("CameraController")
    CharacterManager = require"character.charactermanager"
	PlayerRole = require "character.playerrole"
    Camera = mainCamera
	
	
	resolution = UnityEngine.Screen.currentResolution
    resolutionCoeff = {}
    resolutionCoeff.x = 1
    resolutionCoeff.y = 1
    if Application.platform == UnityEngine.RuntimePlatform.IPhonePlayer then
        resolutionCoeff.x = 1/8
        resolutionCoeff.y = 1/8
    end
	
	GameObject.DontDestroyOnLoad(CameraAssist.gameObject)
    if Camera then
        reset()
    end
    isStop = true
	
    autoai = require "character.ai.autoai"
end

return {
    init = init,
	stop = stop,
    MainCamera = MainCamera,
	CreatLoginAssist = CreatLoginAssist,
    DestroyLoginAssist = DestroyLoginAssist,
	LoginPush = LoginPush,
    LoginPull = LoginPull,
	reset = reset,
	NotifySceneLoginLoaded = NotifySceneLoginLoaded,
	CameraControl = CameraControl,
	Restore = Restore,
	
}
