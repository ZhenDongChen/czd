local ConfigManager = require("cfg.configmanager")
local UIManager = require("uimanager")
local DlgDialogBox_Complex = require("ui.common.dlgdialogbox_complex")


local function DlgTextRefreshFunc(params, fields, helpinfo)
    fields.UILabel_Title.text = helpinfo.title
    fields.UILabel_Content_Single.text = helpinfo.content
end

local function ShowDialogText(helpinfo)
    UIManager.show( "common.dlgdialogbox_complex", { 
                    type = Dlg_Complex_Type.UIGROUP_BILLIONOFWORDS,
                    callBackFunc = function(params,fields)
                        DlgTextRefreshFunc(params,fields,helpinfo)
                    end })
end


local function ShowHelpInfo(modelname, index)
    local helpInfoCfg = ConfigManager.getConfigData("modulehelpinfo",modelname)
    if helpInfoCfg then
        local helpinfo = helpInfoCfg.infos[index]
        if helpinfo then
            ShowDialogText(helpinfo)
        end
    end
end

return {
    ShowHelpInfo = ShowHelpInfo,
}