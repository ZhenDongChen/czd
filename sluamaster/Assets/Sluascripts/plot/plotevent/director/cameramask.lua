local PlotDefine = require("plot.base.plotdefine");
local UIManager = require("uimanager")

local CameraMask = {};
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.LoadFunction = function(self)
    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Loaded
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Camera:GetCameraObject()
   
    if self.MaskName == "Blockbar" then
        if self.Mode == "FadeIn" then
            self.Cutscene.m_Fade:BlackEdgeFadeIn(0)
        elseif self.Mode == "FadeOut" then
            self.Cutscene.m_Fade:BlackEdgeFadeOut(0)
        else
            self.Cutscene.m_Fade:BlackEdgeFadeIn(1)
        end
    else
        if self.Mode == "FadeIn" then
            self.Cutscene.m_Fade:BlackCurtainFadeIn2(0)
        elseif self.Mode == "FadeOut" then
            self.Cutscene.m_Fade:BlackCurtainFadeOut2(0)
        else
            self.Cutscene.m_Fade:BlackCurtainKeep2()
        end
    end
    
--[[
    self.Script = self.TargetObject:AddComponent(LuaHelper.GetType("TransitionsDark"))

    if self.MaskName == "Back" then
        self.Script.Mask = 0
    else
        self.Script.Mask = 1
    end
    if self.Mode == "FadeIn" then
        self.Script.Mode = 0
    elseif self.Mode == "FadeOut" then
        self.Script.Mode = 1
    else
        self.Script.Mode = 2
    end
]]
    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.LoopFunction = function(self,deltaTime)
    self.CurrentTime=self.CurrentTime + deltaTime;
   -- if self.Script == nil then
   --     return
   -- end
    local timeIndex = self.CurrentTime/self.Duration
    local maxvalue = self.MaskValue or 1
    if self.MaskName == "Blockbar" then
        if self.Mode == "FadeIn" then
            self.Cutscene.m_Fade:BlackEdgeFadeIn(timeIndex * maxvalue)
        elseif self.Mode == "FadeOut" then
            self.Cutscene.m_Fade:BlackEdgeFadeOut(timeIndex * maxvalue)
        else
            self.Cutscene.m_Fade:BlackEdgeFadeIn(maxvalue)
        end
    else
        if self.Mode == "FadeIn" then
            self.Cutscene.m_Fade:BlackCurtainFadeIn2(timeIndex * maxvalue)
        elseif self.Mode == "FadeOut" then
            self.Cutscene.m_Fade:BlackCurtainFadeOut2(timeIndex * maxvalue)
        else
            self.Cutscene.m_Fade:BlackCurtainKeep2(maxvalue)
        end
    end
   -- self.Script.TimeIndex = timeIndex
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.EndFunction  = function(self)
    if self.MaskName == "Blockbar" then
        self.Cutscene.m_Fade:BlackEdgeFadeIn(0)
    else
        self.Cutscene.m_Fade:BlackCurtainFadeIn2(0)
    end
  --  if self.Script ~= nil then
  --      UnityEngine.Object.Destroy(self.Script)
  --  end
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CameraMask.SampleFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
return CameraMask;
