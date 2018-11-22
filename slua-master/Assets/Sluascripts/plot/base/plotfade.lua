local UIManager = require("uimanager")

local PlotFade = Class:new()

function PlotFade:__new(cutscene, config)
    self.m_Cutscene = cutscene
    self.m_Time = config.fadeInOutTime
    self.m_CurrentTime = 0
    self.m_Config = config
    --self.m_FadeState = 0
end
--[[
    	config = {
		isLooping = false,
		isSkippable = true,
		independentMusic = true,
		hideUI = true,
		hideCharacter = true,
		showBorder = true,
        showCurtain = true,
		fadeInOutTime = 0.7,
		mainCameraControl = true,
		previewMode = false,
	},
]]

function PlotFade:BlackCurtainFadeIn(valueIn)
    --if true then return end
    if self.m_Config.showCurtain == false then
        return
    end
    if UIManager.isshow("plot.dlgplotmain") then
        UIManager.call("plot.dlgplotmain","SetFadeInOutCurtain",{mode = "In", value = valueIn or 0})
    end
end

function PlotFade:BlackCurtainKeep()
 --if true then return end
    if self.m_Config.showCurtain == false then
        return
    end
    if UIManager.isshow("plot.dlgplotmain") then
        UIManager.call("plot.dlgplotmain","SetFadeInOutCurtain",{mode = "In", value = 1})
    end
end

function PlotFade:BlackCurtainFadeOut(valueIn)
 --if true then return end
    if self.m_Config.showCurtain == false then
        return
    end
    if UIManager.isshow("plot.dlgplotmain") then
        UIManager.call("plot.dlgplotmain","SetFadeInOutCurtain",{mode = "Out", value = valueIn or 0})
    end
end

function PlotFade:BlackEdgeFadeIn(valueIn)
    if self.m_Config.showBorder == false then
        return
    end
    if UIManager.isshow("plot.dlgplotmain") then
        UIManager.call("plot.dlgplotmain","SetFadeInOutEdge",{mode = "In", value = valueIn or 0})
    end
end

function PlotFade:BlackEdgeFadeOut(valueIn)
    if self.m_Config.showBorder == false then
        return
    end
    if UIManager.isshow("plot.dlgplotmain") then
        UIManager.call("plot.dlgplotmain","SetFadeInOutEdge",{mode = "Out", value = valueIn or 0})
    end
end

function PlotFade:BlackCurtainFadeIn2(valueIn)
    --if true then return end
  --  if self.m_Config.showBorder == false then
  --      return
  --  end
    if UIManager.isshow("plot.dlgplotmain") then
        UIManager.call("plot.dlgplotmain","SetFadeInOutCurtain2",{mode = "In", value = valueIn or 0})
    end
end

function PlotFade:BlackCurtainKeep2(valueIn)
 --if true then return end
  --  if self.m_Config.showBorder == false then
  --      return
 --   end
    if UIManager.isshow("plot.dlgplotmain") then
        UIManager.call("plot.dlgplotmain","SetFadeInOutCurtain2",{mode = "In", value = valueIn or 1})
    end
end

function PlotFade:BlackCurtainFadeOut2(valueIn)
 --if true then return end
 --   if self.m_Config.showBorder == false then
 --       return
 --   end
    if UIManager.isshow("plot.dlgplotmain") then
        UIManager.call("plot.dlgplotmain","SetFadeInOutCurtain2",{mode = "Out", value = valueIn or 0})
    end
end



function PlotFade:FadeIn()

end

function PlotFade:FadeOut()

end



return PlotFade
