local ConfigManager = require("cfg.configmanager")
local QteButton     = require("ui.plot.plotqte.qtebutton")


local QteList = Class:new()

function QteList:__new(index)
    local qteCfg = ConfigManager.getConfigData("plotqte", index)
    self.m_Buttons = {}
    for i, buttonCfg in ipairs(qteCfg.buttons) do
        self.m_Buttons[i] = QteButton:new(buttonCfg, buttonCfg.number)
    end
end

function QteList:GetButton(i)
    return self.m_Buttons[i]
end

function QteList:Remove(pos)
    table.remove( self.m_Buttons, pos )
end

function QteList:Count()
    return #self.m_Buttons
end

function QteList:Update()
    for i, buttonInfo in pairs(self.m_Buttons) do
        if buttonInfo:IsFinish() == false then
            buttonInfo:Update()
        end
    end
end

return QteList