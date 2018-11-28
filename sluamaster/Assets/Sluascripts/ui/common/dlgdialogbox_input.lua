local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")


local name
local gameObject
local fields

local SettingAutoFight = {}
local cur_Type
Dlg_Input_Type={
    UIGROUP_SLIDER=0,
    UIGROUP_DELETE=1,
    UIGROUP_RENAME=2,
    UIGROUP_CLAN=3,
    UIGROUP_SELECT=4,
}
----------------------------
--显示功能所需的Group，关闭无关的Group
-----------------------------
local function DisplayGroupByType(type)
    fields.UIGroup_Slider.gameObject:SetActive(type==Dlg_Input_Type.UIGROUP_SLIDER)
    fields.UIGroup_Delete.gameObject:SetActive(type==Dlg_Input_Type.UIGROUP_DELETE)
    fields.UIGroup_Rename.gameObject:SetActive(type==Dlg_Input_Type.UIGROUP_RENAME)
    fields.UIGroup_Clan.gameObject:SetActive(type==Dlg_Input_Type.UIGROUP_CLAN)
    fields.UIGroup_Select.gameObject:SetActive(type==Dlg_Input_Type.UIGROUP_SELECT)
end

local function refresh(params)
	--printyellow("dlgdialogbox_input",params)
	
    if params then
        if params.type then
            DisplayGroupByType(params.type)
        end
        if params.callBackFunc then
            params.callBackFunc(fields)
        end
    end 
end

local function update()
end

local function destroy()
end

local function GetSettingPickUp()
	return SettingAutoFight
end

local function hide()
	if  cur_Type == Dlg_Input_Type.UIGROUP_SELECT then
		local SettingManager = require "character.settingmanager"
		local SettingAutoFight = SettingManager.GetSettingAutoFight() 
		SettingAutoFight["White"]  = fields.UIToggle_White.value
		SettingAutoFight["Green"]  = fields.UIToggle_Green.value
		SettingAutoFight["Blue"]   = fields.UIToggle_Blue.value
		SettingAutoFight["Purple"] = fields.UIToggle_Purple.value
		SettingAutoFight["Orange"] = fields.UIToggle_Orange.value
		SettingAutoFight["Red"]    = fields.UIToggle_Red.value
		SettingManager.SetSettingAutoFight(SettingAutoFight)

	end
end
---------------------------------------
--调用接口 
--参数释义({type:功能类型，见Dlg_Input_Type;callBackFunc:回调函数，实现个人所需功能})
---------------------------------------
local function show(params)
	print("dlgdialogbox_input show")
    if params then
        if params.type then
            DisplayGroupByType(params.type)
			cur_Type = params.type
        end
        if params.callBackFunc then
			print("callBackFunc__dlgdialogbox_input")
            params.callBackFunc(fields)
        end
    end   
end

local function uishowtype()
	return UIShowType.DestroyWhenHide
end

local function init(params)
	print("dlgdialogbox_input init")
    name,gameObject,fields=Unpack(params)
    EventHelper.SetClick(fields.UIButton_Close,function()
        UIManager.hide(name)
    end)
end

return{
    show = show,
    init = init,
    update = update,
	destroy = destroy,
    refresh = refresh,
	hide = hide,
	GetSettingPickUp = GetSettingPickUp,
	uishowtype = uishowtype,
}