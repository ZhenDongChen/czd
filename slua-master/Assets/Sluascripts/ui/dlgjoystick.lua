local unpack = unpack
local print = print
local printt = printt
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local scenemanager = require("scenemanager")
local EctypeManager = require"ectype.ectypemanager"
local OperationActivityManager = require("ui.operationactivity.operationactivitymanager")
local gameObject
local name

local fields



local function destroy()
	-- printyellow(name, "destroy joystick")
end

local function show(params)
	if OperationActivityManager.NeedShowRecommend() then
		uimanager.showdialog("activity.dlgactivityrecommend")
	else
		uimanager.show("dlguimain")
	end
	uimanager.show("dlgflytext")
	uimanager.show("dlgheadtalking")
	uimanager.show("dlgdynamicflyitem")
	-- if EctypeManager.IsInEctype() and not uimanager.isshow("ectype.dlguiectype") then
	-- 	uimanager.show("ectype.dlguiectype")
	-- end
end

local function hide()
	uimanager.hide("dlguimain")
	--uimanager.hide("dlgdynamicflyitem")
	-- if EctypeManager.IsInEctype() and uimanager.isshow("ectype.dlguiectype") then
	-- 	uimanager.hide("ectype.dlguiectype")
	-- end
end

local function refresh(params)
  --print(name, "refresh")
end

local function update()
	--print(name, "update")
	Game.JoyStickManager.singleton:Update()
end

local function CloseRideButton(close)
    local DlgUIMain=require"ui.dlguimain"
    DlgUIMain.HideRideButton(close)
end

local function init(params)
	name, gameObject, fields = unpack(params)
	local widget = fields.UIGroup_BottomLeft.gameObject:GetComponent("UIWidget")
	uimanager.SetAnchor(widget)
	
	EventHelper.SetPress(fields.UISprite_Mask, function (go,isPressed)
		Game.JoyStickManager.singleton:OnPressed(isPressed)
    CloseRideButton(isPressed)
	end)
	
	EventHelper.SetDrag(fields.UISprite_Mask, function (go,delta)
    Game.JoyStickManager.singleton:OnDraged(delta)
	--uimanager.call("dlguimain","DragingJoystick")

	end)
  Game.JoyStickManager.singleton:UseStick(LuaHelper.GetJoyStickFixedMode())


end

local function SetJoyStickEnable(b)
	fields.UISprite_Mask.enabled = b
end

local function GetJoyStickObject()
	local obj = GameObject.Find("dlgjoystick")
	return obj
end

local function SetVisiable(isVisiable)
  NGUITools.SetActive(fields.UISprite_Joy.gameObject,isVisiable)
  NGUITools.SetActive(fields.UISprite_BG.gameObject,isVisiable)
end

local function Get_UISprite_Joy()
  return fields.UISprite_Joy.gameObject.transform
end

local function Get_UISprite_BG()
  return fields.UISprite_BG.gameObject.transform
end

local function Get_UISprite_Mask()
  return fields.UISprite_Mask.gameObject.transform
end

local function JoyStickEnable(b)
	fields.UISprite_Mask.enabled = b
end



-- 暴露给c#的接口
DlgJoyStick_SetVisiable = SetVisiable
DlgJoyStick_Get_UISprite_Joy = Get_UISprite_Joy
DlgJoyStick_Get_UISprite_BG = Get_UISprite_BG
DlgJoyStick_Get_UISprite_Mask = Get_UISprite_Mask


return {
	init = init,
	show = show,
	hide = hide,
	update = update,
	destroy = destroy,
	refresh = refresh,
	GetJoyStickObject = GetJoyStickObject,
	SetJoyStickEnable = SetJoyStickEnable,
	JoyStickEnable	= JoyStickEnable,
}
