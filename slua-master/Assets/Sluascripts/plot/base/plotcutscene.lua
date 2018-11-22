local PlotDefine    = require("plot.base.plotdefine")
local PlotPool      = require("plot.base.plotpool")
local PlotFade      = require("plot.base.plotfade")
local PlotUtil      = require("plot.base.plotutil")
local PlotUI        = require("plot.base.plotui")
local PlotCamera    = require("plot.base.plotcamera")
local PlotAudio     = require("plot.base.plotaudio")
local PlotDialog    = require("plot.base.plotdialog")
local PlotConfig    = require("plot.base.plotconfig")
local PlotAnimator  = require("plot.base.plotanimator")
local UIManager     = require("uimanager")


local PlotCutscene  = Class:new()


function PlotCutscene:__new(plotCfg, script, name, onStart, onEnd)
    self.m_Name         = name
    self.m_Script       = nil
    self.m_Cutscene     = nil
    self.m_CsvConfig    = plotCfg
    self.m_GameObject   = UnityEngine.GameObject(self.m_Name)
    
    self.m_CurrentTime  = 0

    self.m_PlayState    = PlotDefine.PlayStateType.Stop
    
    self.m_IsFinished   = false
    
    self.m_OnStart      = onStart or function() end
    self.m_OnEnd        = onEnd or function() end
    
    self.m_State        = PlotDefine.StateType.Create
    self:Init()
end

function PlotCutscene:Init()

--[[	
	local temptargetstring = "plot.plotscript." .. self.m_Name
	assert(temptargetstring)
	print(temptargetstring)
	local tempCutscene = require(temptargetstring)
    self.m_Cutscene     = tempCutscene
--]]
	self.m_Cutscene     = LuaHelper.DoFile("plot.plotscript." .. self.m_Name)
	assert(self.m_Cutscene)
 --   self.m_Config       = 
    self.m_Duration     = self.m_Cutscene.Duration
    
    self.m_LoadingTime  = 0

    self.m_Config       = PlotConfig:new(self, self.m_Cutscene.config)
    self.m_UI           = PlotUI:new(self, self.m_Cutscene.config)
    self.m_Fade         = PlotFade:new(self, self.m_Cutscene.config)
    self.m_Pool         = PlotPool:new(self, self.m_Cutscene.config)
    self.m_Util         = PlotUtil:new(self, self.m_Cutscene.config)
    self.m_Audio        = PlotAudio:new(self, self.m_Cutscene.config)
    self.m_Camera       = PlotCamera:new(self, self.m_Cutscene.config)
    self.m_Dialog       = PlotDialog:new(self, self.m_Cutscene.config)
    self.m_Animator     = PlotAnimator:new(self, self.m_Cutscene.config)

    self.m_UI:ShowMain()
    self.m_State        = PlotDefine.StateType.Init
end

---------------------------------------------------------------------------------------------

function PlotCutscene:Load()
    
    self.m_Pool:Load()
    
    self.m_Cutscene.Object = self.m_GameObject
    self.m_Cutscene.m_Config  = self.m_Config
    self.m_Cutscene.m_Pool = self.m_Pool
    self.m_Cutscene.m_Audio = self.m_Audio
    self.m_Cutscene.m_Camera = self.m_Camera
    self.m_Cutscene.m_UI = self.m_UI
    self.m_Cutscene.m_Dialog = self.m_Dialog
    self.m_Cutscene.m_Fade = self.m_Fade
    self.m_Cutscene.m_Animator  = self.m_Animator

    self.m_Cutscene:LoadFunction()
    
    self.m_State        = PlotDefine.StateType.Load
end

function PlotCutscene:IsReady()
    return self.m_Pool:IsReady()
end

function PlotCutscene:GetAssetsState()
    return self.m_Pool:GetAssetsState()
end

function PlotCutscene:Start()
    printyellow("Start")
    self.m_OnStart()
    
    self.m_UI:OnStart()
    self.m_Pool:OnStart()
    self.m_Util:OnStart()
    self.m_Audio:OnStart()
    self.m_Camera:OnStart()
    self.m_Animator:OnStart()

    self.m_CurrentTime = 0
    self.m_Cutscene:StartFunction()
    self.m_State = PlotDefine.StateType.Loop
end

function PlotCutscene:Loop()
  --  printyellow("Loop")
    self.m_Cutscene:LoopFunction(Time.deltaTime)
end

function PlotCutscene:End()
    printyellow("PlotCutscene End")
    --UnityEngine.Time.timeScale = 1
    self.m_CurrentTime = 0
    self.m_Cutscene:EndFunction()

    
    self.m_UI:OnEnd()
    self.m_Pool:OnEnd()
    self.m_Util:OnEnd()
    self.m_Camera:OnEnd()
    self.m_Audio:OnEnd()
    self.m_Animator:OnEnd()

    self.m_OnEnd()
    

    self.m_State = PlotDefine.StateType.Ended
    self.m_IsFinished = true
end

function PlotCutscene:Destroy()
    --printyellow("Destroy")
    self.m_Cutscene:DestroyFunction()
    if self.m_Pool then
        self.m_Pool:Destroy()
    end
    if self.m_GameObject then
        Util.Destroy(self.m_GameObject)
    end
end



function PlotCutscene:IsFinished()
    return self.m_IsFinished
end
---------------------------------------------------------------------------------------------

--主循环更细
function PlotCutscene:UpdateMain()

    if self.m_State == PlotDefine.StateType.Init then
        self:Load()
    elseif self.m_State == PlotDefine.StateType.Start then
        self:Start()
    elseif self.m_State == PlotDefine.StateType.Loop then
        self:Loop()
    elseif self.m_State == PlotDefine.StateType.End then
        self:End()
    elseif self.m_State == PlotDefine.StateType.Destroy then
        self:Destroy()
    end
end

function PlotCutscene:CutsceneError(errorInfo, directEnd)
    if errorInfo.message then
        logError(errorInfo.message)
    end
    if self.m_UI then
        self.m_UI:SetMainSkip()
    end
    if directEnd then
        self.m_State = PlotDefine.StateType.End
    end
end

--辅助循环更新
function PlotCutscene:UpdateAssist()
    if self.m_State == PlotDefine.StateType.Load then
        if self.m_CurrentTime <= self.m_Fade.m_Time then
            self.m_Fade:BlackCurtainFadeIn(self.m_CurrentTime/self.m_Fade.m_Time)
            self.m_Fade:BlackEdgeFadeIn(self.m_CurrentTime/self.m_Fade.m_Time)
        elseif (not self:IsReady()) then
            self.m_Fade:BlackCurtainKeep()
            self.m_LoadingTime = self.m_LoadingTime + Time.deltaTime
            if self:GetAssetsState() == PlotDefine.AssetState.Failed then
                self:CutsceneError({message = string.format("[Info]: Load resource failed. [Script]: %s", tostring(self.m_Name))}, true)
            end
            if cfg.plot.PlotAssets.maxloadtime and self.m_LoadingTime > cfg.plot.PlotAssets.maxloadtime then
                self:CutsceneError({message = string.format("[Info]: Loading cost too much time. [Script]: %s", tostring(self.m_Name))}, false)
            end
        else
            if self:GetAssetsState() == PlotDefine.AssetState.Failed then
                self:CutsceneError({message = string.format("[Info]: Load resource failed. [Script]: %s", tostring(self.m_Name)), true})
            end
            self.m_Fade:BlackEdgeFadeIn(1)
            self.m_Fade:BlackCurtainFadeIn(1)
            self.m_State = PlotDefine.StateType.Start
        end
    elseif self.m_State == PlotDefine.StateType.Loop then
        if self.m_CurrentTime < self.m_Fade.m_Time then
            self.m_Fade:BlackCurtainFadeOut(self.m_CurrentTime/self.m_Fade.m_Time)
        elseif self.m_CurrentTime < self.m_Duration and self.m_CurrentTime + self.m_Fade.m_Time >= self.m_Duration then
            self.m_Fade:BlackCurtainFadeIn((self.m_CurrentTime + self.m_Fade.m_Time - self.m_Duration)/self.m_Fade.m_Time )
        elseif self.m_CurrentTime >= self.m_Duration then
            self.m_State = PlotDefine.StateType.End
        end
    elseif self.m_State == PlotDefine.StateType.Ended then
        if self.m_CurrentTime <= self.m_Fade.m_Time then
            self.m_Fade:BlackCurtainFadeOut(self.m_CurrentTime/self.m_Fade.m_Time)
            self.m_Fade:BlackEdgeFadeOut(self.m_CurrentTime/self.m_Fade.m_Time)
        else
            self.m_State = PlotDefine.StateType.Destroy
        end
    end
end
--更新
function PlotCutscene:Update()

    if self.m_PlayState ~= PlotDefine.PlayStateType.Play then
        return
    end
    if self.m_UI:IsReady() == false then
        return
    end

    self:UpdateMain()
    self:UpdateAssist()
    self.m_CurrentTime = self.m_CurrentTime + Time.deltaTime

end

return PlotCutscene
