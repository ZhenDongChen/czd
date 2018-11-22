local UIManager = require("uimanager")


local PlotUI = Class:new()

function PlotUI:__new(cutscene, config)
    self.m_Cutscene = cutscene
    self.m_Config = config
end

function PlotUI:ShowMain()
    if self.m_Config.hideUI == true then
        UIManager.showdialog("plot.dlgplotmain",{isSkippable = self.m_Config.isSkippable})
    else
        UIManager.show("plot.dlgplotmain",{isSkippable = self.m_Config.isSkippable})
    end
end

function PlotUI:HideMain()
    if self.m_Config.hideUI == true then
        UIManager.hidedialog("plot.dlgplotmain")
    else
        UIManager.hide("plot.dlgplotmain")
    end
end
function PlotUI:SetMainSkip()
    if UIManager.isshow("plot.dlgplotmain") then
        UIManager.call("plot.dlgplotmain","SetSkippable")   
    end
end

--=================================================================================
function PlotUI:IsReady()
    if self.m_Config.hideUI == true then
        return UIManager.isshow("plot.dlgplotmain")
    else
        return true
    end
end
--=================================================================================

function PlotUI:SetTalk(mode, content)
    local dlgplotmain = require("ui.plot.dlgplotmain")
    dlgplotmain.SetTalk("Show",content)
end

function PlotUI:ShowEffect(params)
    UIManager.call("plot.dlgplotmain", "SetScreenWords", {
        mode        = "Show", 
        effectType  = params.effectType, 
        cutscene    = params.cutscene, 
        index       = params.index, 
        position    = params.position,
        duration    = params.duration,
    })
end

function PlotUI:HideEffect(params)
    UIManager.call("plot.dlgplotmain", "SetScreenWords", {
        mode        = "Hide", 
        effectType  = params.effectType, 
        cutscene    = params.cutscene, 
        index       = params.index, 
        position    = params.position,
        duration    = params.duration,
    })
end

function PlotUI:ShowQTE(params)
    UIManager.show("plot.dlgplotqte",{
        effectType  = params.effectType, 
        cutscene    = params.cutscene,
        index       = params.index, 
        position    = params.position,
        duration    = params.duration,
    })
end

function PlotUI:HideQTE(params)
    if UIManager.isshow("plot.dlgplotqte") then
        UIManager.hide("plot.dlgplotqte")
    end
end

function PlotUI:ShowChapterUI(params)
    UIManager.show("plot.dlgchapterui", params)
end

function PlotUI:HideChapterUI(params)
    if UIManager.isshow("plot.dlgchapterui") then
        UIManager.hide("plot.dlgchapterui")
    end
end

--=================================================================================

function PlotUI:OnStart()
    if self.m_Config.hideUI == true then
      --  UIManager.showdialog("plot.dlgplothide")
        local list = UIManager.GetDlgsShow()
        for _, name in pairs(list) do
            if name ~="plot.dlgplotmain" and name ~= "dlgdialog" then
                UIManager.hideimmediate(name)
            end
        end
        UIManager.SetLock(true)
    end
end

function PlotUI:OnEnd()
    if self.m_Config.hideUI == true then
        --UIManager.hidedialog("plot.dlgplotmain")
        UIManager.SetLock(false)
    end
    self:HideMain()    
    self:HideQTE()
end

return PlotUI