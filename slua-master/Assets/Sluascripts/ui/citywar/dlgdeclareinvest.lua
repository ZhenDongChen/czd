local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local define = require "define"
local citywarmanager 	  = require "ui.citywar.citywarmanager"
local citywarinfo 	  = require "ui.citywar.citywarinfo"
local FamilyManager = require("family.familymanager")

--ui
local fields
local gameObject
local name

local m_CityData

local function OnUIButton_Left()
    uimanager.hide("common.dlgdialogbox_input")
end

local function OnUIButton_Close()
    uimanager.hide("common.dlgdialogbox_input")
end

local function show(citydata)
	printyellow("show citydata")
    m_CityData = citydata
    uimanager.show("common.dlgdialogbox_input", {callBackFunc=function(fields)
        fields.UIGroup_Button_Mid.gameObject:SetActive(false)
        fields.UIGroup_Button_Norm.gameObject:SetActive(true)
        fields.UIGroup_Resource.gameObject:SetActive(false)
        fields.UIInput_Input.gameObject:SetActive(true)
        fields.UIInput_Input_Large.gameObject:SetActive(false)
        fields.UIGroup_Select.gameObject:SetActive(false)
        fields.UIGroup_Clan.gameObject:SetActive(true)
        fields.UIGroup_Rename.gameObject:SetActive(false)
        fields.UIGroup_Slider.gameObject:SetActive(false)
        fields.UIGroup_Delete.gameObject:SetActive(false)
        fields.UIGroup_Describe.gameObject:SetActive(true)
        fields.UIButton_Close.gameObject:SetActive(true)
        fields.UIGroup_CityWar.gameObject:SetActive(true)
		
        EventHelper.SetClick(fields.UIButton_Left, OnUIButton_Left)
        EventHelper.SetClick(fields.UIButton_Right, function()
            if citywarinfo.GetDeclareWarFamilyLevel()>FamilyManager.Info().flevel then
                local params = {}
                params.title = LocalString.TipText
		        params.content = string.format(LocalString.City_War_Family_Level,citywarinfo.GetDeclareWarFamilyLevel())
		        uimanager.ShowAlertDlg(params)
            else
                local money = tonumber(fields.UILabel_Input.text)
                if m_CityData and money then
                    printyellow("[dlgdeclareinvest:OnUIButton_Right] money:", money)
                    citywarmanager.send_CDeclare(m_CityData:GetCityId(), money)  
                else  
                    print("[ERROR][dlgdeclareinvest:OnUIButton_Right] m_CityData or money invalid!")  
                end
            end
        end)
        EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)

        fields.UILabel_Title.text = LocalString.City_War_Declare_Invest_Title
        fields.UILabel_Input.text = string.format(LocalString.City_War_Declare_Invest_Default, m_CityData:GetMinDeclareInvest(), m_CityData:GetDeclareMaxInvest())
        fields.UILabel_ClanWarning.text = string.format("%s-%s", m_CityData:GetCityLevelText(), m_CityData:GetCityColorName())
        fields.UILabel_Describe.text = string.format(LocalString.City_War_Declare_Invest_Current, citywarinfo.GetFamilyDeclareMoney())
        fields.UILabel_CityWar.text = LocalString.City_War_Invest_Tip
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
