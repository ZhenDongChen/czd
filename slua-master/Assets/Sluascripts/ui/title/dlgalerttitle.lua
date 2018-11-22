local UIManager = require("uimanager")
local EventHelper   = UIEventListenerHelper

local currentTitleInfo = nil

local function ShowAlert(cfields,titleInfo)
    cfields.UILabel_Title.text = titleInfo:GetName()
    cfields.UIGroup_ItemUse.gameObject:SetActive(true)
    if cfields.UIItem_ItemUseBox then
        cfields.UIItem_ItemUseBox.gameObject:SetActive(false)
    end
    cfields.UIGroup_Button_1.gameObject:SetActive(true)
    cfields.UIGroup_Button_2.gameObject:SetActive(false)

    titleInfo:SetTitleShow(cfields.UITexture_TitleIconName, cfields.UISprite_TitleIconName, cfields.UILabel_TitleIconName)

    cfields.UILabel_ItemUse_Name.text = LocalString.TitleSystem.TitleName .. titleInfo:GetName()

    local timeInfoText = ""

    if titleInfo.m_IsActive == true and titleInfo:GetRestTime() and titleInfo:GetRestTime() > 0 then
        timeInfoText = LocalString.TitleSystem.RestTime .. titleInfo:GetRestTimeString()
    end

    cfields.UILabel_ItemUse_Describe.text = LocalString.TitleSystem.Describe .. titleInfo:GetDescription() .. "\n"
                                            .. LocalString.TitleSystem.Condition .. titleInfo:GetCondition() .. "\n"
                                            .. timeInfoText

    EventHelper.SetClick(cfields.UIButton_1,function()
        UIManager.hide("common.dlgdialogbox_common")
    end)

    cfields.UILabel_Button_1.text    = LocalString.SureText
end

local function SecondUpdate(titleInfo,cfields)
    local timeInfoText = ""

    if titleInfo.m_IsActive == true and titleInfo:GetRestTime() and titleInfo:GetRestTime() > 0 then
        timeInfoText = LocalString.TitleSystem.RestTime .. titleInfo:GetRestTimeString()
    end

    cfields.UILabel_ItemUse_Describe.text = LocalString.TitleSystem.Describe .. titleInfo:GetDescription() .. "\n"
                                            .. LocalString.TitleSystem.Condition .. titleInfo:GetCondition() .. "\n"
                                            .. timeInfoText
end


local function Show(titleInfo)
    currentTitleInfo = titleInfo
    UIManager.show("common.dlgdialogbox_common",{
        type = 5,
        callBackFunc = function(fields)
            ShowAlert(fields,titleInfo)
        end,
        secondUpdateDelegate = function(fields, name)
            SecondUpdate(titleInfo,fields)
        end,
    })
end



return {
    Show = Show,
}