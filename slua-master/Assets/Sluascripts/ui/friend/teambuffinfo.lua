local UIManager = require("uimanager")
local DlgDialogBox_Complex = require("ui.common.dlgdialogbox_complex")


local function DlgTextRefreshFunc(params, fields, content)
    fields.UILabel_Title.text = LocalString.Friend.BuffInfoTitle
    fields.UILabel_Content_Single.text = content
end

local function ShowDialogText(content)
    UIManager.show( "common.dlgdialogbox_complex", {
                    type = Dlg_Complex_Type.UIGROUP_BILLIONOFWORDS,
                    callBackFunc = function(params,fields)
                        DlgTextRefreshFunc(params,fields,content)
                    end })
end

local function ShowBuffInfo()
    --printyellow("ShowBuffInfo")
    --friendbattleconfig
    local buffInfoCfg = ConfigManager.getConfig("friendbattleconfig")
    local content = ""
    if buffInfoCfg then
        for i, info in ipairs(buffInfoCfg.buffinfo) do
            content = content .. string.format(LocalString.Friend.BuffInfoContent, tostring(info.likability), info.buffname, info.introduction) .. "\n"
        end
    end
    --printyellow(content)
    ShowDialogText(content)
end

return {
    ShowBuffInfo = ShowBuffInfo,
}
