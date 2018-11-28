local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local PlayerRole=require"character.playerrole"
local ConfigManager=require"cfg.configmanager"
local EctypeManager = require"ectype.ectypemanager"
local charactermanager = require"character.charactermanager"
local InputController = require"input.inputcontroller"
local gameObject
local name
local fields
local Alternate
local HideMode = false
local hideTimer = 0
local freeTouchTime1
local freeTouchTime2
local BattlePets
local uilistPets = {}
local UIAreaConfig
local inputController
local bChangeMode
local FirstPayObj
local AllGroupObjects


local function ClickOnCharacter(position)
    local ray = Camera:ScreenPointToRay(position)
    local ret , hit
    ret , hit = Physics.Raycast(ray,hit)
    if ret and hit and hit.collider and hit.transform then
        local obj = hit.collider.gameObject
        local characters = charactermanager.GetCharacters()
        for i,v in pairs(characters) do
            if v.m_Object and v.m_Object==obj then
                return true
            end
        end
    end
    return false
end

--获取主界面所有的对象
local function GetMainObjects()
	print("隐藏主界面")
    AllGroupObjects = {}
    AllGroupObjects[cfg.ui.UIMainAreaType.HEAD] = {obj={fields.UIWidget_TopLeft.gameObject,fields.UIWidget_TopCenter.gameObject},particles={FirstPayObj}}
    AllGroupObjects[cfg.ui.UIMainAreaType.FUNCTION] = {obj={fields.UIWidget_TopRight.gameObject},particles={}}
    AllGroupObjects[cfg.ui.UIMainAreaType.TASK] = {obj={fields.UIWidget_Left.gameObject},particles={}}
    AllGroupObjects[cfg.ui.UIMainAreaType.SKILL] = {obj={fields.UIWidget_BottomRight.gameObject},particles={}}
    AllGroupObjects[cfg.ui.UIMainAreaType.CHAT] = {obj={fields.UIWidget_BottomCenter.gameObject},particles={}}
    local uiJoystick = require"ui.dlgjoystick"
    AllGroupObjects[cfg.ui.UIMainAreaType.JOYSTICK] = {obj={uiJoystick.GetJoyStickObject(),fields.UIWidget_BottomLeft.gameObject},particles={}}
    for _,group in pairs(AllGroupObjects) do
        for _,obj in pairs(group.obj) do
            local comp = obj:GetComponent(TweenAlpha)
            if not comp then
                obj:AddComponent(TweenAlpha)
            end
        end
    end
end


local function ShowGroup(type,time,target)
    if type then
        for _,obj in pairs(AllGroupObjects[type].obj) do
            TweenAlpha.Begin(obj,time,target)
        end
        for _,particle in pairs(AllGroupObjects[type].particles) do
            particle:SetActive(target==1)
        end
    else
        for _,group in pairs(AllGroupObjects) do
            for _,obj in pairs(group.obj) do
                TweenAlpha.Begin(obj,time,target)
            end
            for _,particle in pairs(group.particles) do
                particle:SetActive(target==1)
            end
        end
    end
end

local function ChangeHideUIMode(b)
    HideMode = b
    if b then
        uimanager.ShowSystemFlyText(LocalString.HideUIText)
    end
    if HideMode then
        hideTimer = nil
        fields.UISprite_HideMode.spriteName = "IconFunction_HiddenUI"
        ShowGroup(nil,1,0)
    else
        fields.UISprite_HideMode.spriteName = "IconFunction_HiddenUI_Disable"
        ShowGroup(nil,1,1)
    end
end

local function showAllGroupUIObjects()
    ShowGroup(nil,1,1)
end

local function DragingJoystick()
    if HideMode then
        hideTimer = 0
    end
end

local function IsHideGroupsUpdate()
    local area = nil
    local areapos = nil
    local width = UnityEngine.Screen.width
    local height = UnityEngine.Screen.height
    local clicks = inputController:GetCurrentClicks()
    if Input.touchCount==1 then
        local touch = Input.GetTouch(0)
        if clicks[touch.fingerId] then
            if not LuaHelper.IsTouchedUI(0) then
                local position = touch.position
                if ClickOnCharacter(position) then return end
                local ratioX = (position.x)/width
                local ratioY = (position.y)/height
                local pos = Vector2(ratioX,ratioY)
                for i,v in pairs(UIAreaConfig) do
                    if pos.x>= v.posleftbuttom.x and pos.y>=v.posleftbuttom.y
                    and pos.x<=v.posrightup.x and pos.y<=v.posrightup.y then
                        area = v.areatype
                        break
                    end
                end
                freeTouchTime1 = freeTouchTime2
                freeTouchTime2 = Time.time
            end
        end
    end
    if freeTouchTime2 and freeTouchTime1 and freeTouchTime2-freeTouchTime1<0.5 then
        showAllGroupUIObjects()
        freeTouchTime2 = nil
        freeTouchTime1 = nil
        hideTimer = 0
    elseif area then
        ShowGroup(area,1,1)
        hideTimer = 0
    end
end
--

local function destroy()
  --print(name, "destroy")
end

local function show(params)
    fields.UISprite_HideMode.spriteName = "IconFunction_HiddenUI_Disable"
    freeTouchTime1 = nil
    freeTouchTime2 = nil
    hideTimer = 0
    HideMode = false
    bChangeMode = false
    inputController = InputController.Instance()
    GetMainObjects()
    showAllGroupUIObjects()
end

local function hide()
  --print(name, "hide")
end

local function late_update()
    if bChangeMode then
        bChangeMode = false
        return
    end
    IsHideGroupsUpdate()
    for i =0,Input.touchCount-1 do
        if LuaHelper.IsTouchedUI(i) then
            hideTimer = 0
            break
        end
    end
    if hideTimer and HideMode then
        hideTimer = hideTimer + Time.deltaTime
        if hideTimer>5 then
            ShowGroup(nil,1,0)
            hideTimer = nil
        end
    end
end

local function refresh(params)

end

local function update()

end

local function init(n,g,f)
  name, gameObject, fields = n,g,f

  UIAreaConfig = ConfigManager.getConfig("uiarea")
--todo:�׳���Ч��ʱ����
  ---FirstPayObj = fields.UISprite_FirstOfCharge.transform:Find("uifx_firstpay").gameObject
  EventHelper.SetClick(fields.UISprite_HideUI,function()
      fields.UISprite_Warning.gameObject:SetActive(false)
      HideMode = not HideMode
      ChangeHideUIMode(HideMode)
      bChangeMode = true
  end)
end

local function ChangeHideMode()
    fields.UISprite_Warning.gameObject:SetActive(false)
    HideMode = false
    showAllGroupUIObjects()
end

return {
  init = init,
  show = show,
  hide = hide,
  late_update = late_update,
  destroy = destroy,
  update = update,
  refresh = refresh,
  showAllGroupUIObjects = showAllGroupUIObjects,
  DragingJoystick = DragingJoystick,
  ClickOnCharacter = ClickOnCharacter,
  ChangeHideMode = ChangeHideMode,
  ChangeHideUIMode = ChangeHideUIMode,
}
