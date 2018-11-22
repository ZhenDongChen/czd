local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local define = require "define"
local citywarinfo 	  = require "ui.citywar.citywarinfo"
local citywarmanager 	  = require "ui.citywar.citywarmanager"

--ui
local fields
local gameObject
local name

local Max_Logo_Name_Length = 1

local function OnUIButton_Left()
    uimanager.hide("common.dlgdialogbox_input")
end

local function OnUIButton_Close()
    uimanager.hide("common.dlgdialogbox_input")
end

local function show()
    uimanager.show("common.dlgdialogbox_input", {callBackFunc=function(fields)
        fields.UIGroup_Button_Mid.gameObject:SetActive(false)
        fields.UIGroup_Button_Norm.gameObject:SetActive(true)
        fields.UIGroup_Resource.gameObject:SetActive(false)
        fields.UIInput_Input.gameObject:SetActive(true)
        fields.UIInput_Input_Large.gameObject:SetActive(false)
        fields.UIGroup_Select.gameObject:SetActive(false)
        fields.UIGroup_Clan.gameObject:SetActive(false)
        fields.UIGroup_Rename.gameObject:SetActive(false)
        fields.UIGroup_Slider.gameObject:SetActive(false)
        fields.UIGroup_Delete.gameObject:SetActive(false)
        fields.UIGroup_Describe.gameObject:SetActive(false)
        fields.UIButton_Close.gameObject:SetActive(true)
		fields.UILabel_changelogoNameTip.gameObject:SetActive(true)
        EventHelper.SetClick(fields.UIButton_Left, OnUIButton_Left)
        EventHelper.SetClick(fields.UIButton_Right, function()
            local _,stringlen = string.gsub(fields.UILabel_Input.text, "[^\128-\193]", "")
            if stringlen>Max_Logo_Name_Length then
                uimanager.ShowSingleAlertDlg({content=string.format(LocalString.City_War_Logo_Name_Max_Length, Max_Logo_Name_Length)})
            else
                citywarmanager.send_CChangeLogoName(fields.UILabel_Input.text)
            end
        end)
        EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)

        fields.UILabel_Title.text = LocalString.City_War_Change_Logo_Name
        fields.UILabel_Input.text = LocalString.City_War_Lucky_Rename_Default
        fields.UILabel_Input_Large.text = ""
        fields.UILabel_Button_Left.text = LocalString.City_War_Declare_Invest_Cancel
        fields.UILabel_Button_Right.text = LocalString.City_War_Declare_Invest_Confirm
    end})
end

local function destroy()
end

local function hide()
    uimanager.hide("common.dlgdialogbox_input")
end

local function refresh()
end

local function update()
end

local function init(params)
    name, gameObject, fields = unpack(params)
    
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
}
