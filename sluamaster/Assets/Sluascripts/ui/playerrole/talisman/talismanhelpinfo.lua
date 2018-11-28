local UIManager = require("uimanager")
local ConfigManager = require("cfg.configmanager")


function ShowInfo(index)
    local helpInfos = ConfigManager.getConfigData("talismanhelpinfo",index)
    UIManager.ShowSingleAlertDlg({title = LocalString.TipText, content = helpInfos.helpinfo, buttonText = LocalString.Talisman.GetInfo})
end



return {
    ShowInfo = ShowInfo,   
}