local ConfigManager = require("cfg.configmanager")
local GameEvent     = require("gameevent")
local PlotDefine    = require("plot.base.plotdefine")
local PlotCutscene  = require("plot.base.plotcutscene")
local UIManager     = require("uimanager")


local PlotCutscenes = {}

local gameObject = nil
local CurrentCutscene = nil

local function StopCutscene()
    if CurrentCutscene then
        CurrentCutscene:End()
        CurrentCutscene:Destroy()
    end
    CurrentCutscene = nil
end

local function PauseCutscene()
    CurrentCutscene.m_PlayState = PlotDefine.PlayStateType.Pause
end

local function GetCutsceneTime()
    if CurrentCutscene then
        return CurrentCutscene.m_CurrentTime
    else
        return 0
    end
end

local function GetCutsceneState()
    if CurrentCutscene then
        return CurrentCutscene.m_PlayState
    else
        return 0
    end
end

local function PlayCutscene(name, plotCfg, onStart, onEnd)
    if gameObject == nil then
        gameObject = UnityEngine.GameObject("PlotDirector")
        GameObject.DontDestroyOnLoad(gameObject)
    end

    if CurrentCutscene ~= nil then
        if CurrentCutscene.m_Name ~= name then
            StopCutscene()
        else
            CurrentCutscene.m_PlayState = PlotDefine.PlayStateType.Play
            return
        end
    end

    --local script = require("plot.plotscript." .. name)
    CurrentCutscene = PlotCutscene:new(plotCfg, nil, name, onStart,onEnd)
    CurrentCutscene.m_GameObject.transform.parent = gameObject.transform

    
    CurrentCutscene.m_PlayState = PlotDefine.PlayStateType.Play
end

local function update()
    if CurrentCutscene == nil then
        return
    end

    CurrentCutscene:Update()
    
    if CurrentCutscene:IsFinished() then
        CurrentCutscene:Destroy()
        CurrentCutscene = nil
    end
end

local function IsPlayingCutscene()
    if CurrentCutscene then
        if CurrentCutscene.m_PlayState == PlotDefine.PlayStateType.Play then
            return true
        end
    end
    return false
end

local function init()
    GameEvent.evt_update:add(update)
    local idx = ConfigManager.getConfig("plotindex")
end


return {
    init            = init,
    PlayCutscene    = PlayCutscene,
    StopCutscene    = StopCutscene,
    PauseCutscene   = PauseCutscene,
    GetCutsceneTime = GetCutsceneTime,
    GetCutsceneState = GetCutsceneState,
    IsPlayingCutscene = IsPlayingCutscene,
}