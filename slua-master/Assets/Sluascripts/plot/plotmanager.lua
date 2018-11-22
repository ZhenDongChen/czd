local ConfigManager = require("cfg.configmanager")
local PlotEvents    = require("plot.plotevent.plotevents")
local PlotHelper    = require("plot.plothelper")
local GameEvent     = require("gameevent")
local ConfigManager = require("cfg.configmanager")
local UIManager     = require("uimanager")
local PlotDirector  = require("plot.base.plotdirector")
local PlotState = {
    IsPlotPlay = false
}
--================================================================================================
local Cutscene = {}
local Plot = {}
--================================================================================================
--开始播放剧情片段

--空的调用函数
local function EmptyFunc()

end

local function SkipCutscene(plotCfg, scriptname, onStart, onEnd)
    if onStart then
        onStart()
    end
    if onEnd then
        onEnd()
    end
end


--直接开始播放片段
Cutscene.DirectPlay = function(plotCfg, scriptname, onStart, onEnd)
    --printyellow("DirectPlay",scriptname)
    if not PlayerRole:Instance():IsDead() then
        PlotDirector.PlayCutscene(scriptname, plotCfg, onStart, onEnd)
    else
        SkipCutscene(plotCfg, scriptname, onStart, onEnd)
    end
    --PlotDirector.Instance:CutscenePlay(scriptname, onStart or EmptyFunc, onEnd or EmptyFunc)
end


--开始播放片段
Cutscene.Play = function(plotCfg, cutsceneConfig, onStart, onEnd)
    if cutsceneConfig.playmode == cfg.plot.PlayMode.Normal then
        Cutscene.DirectPlay(plotCfg, cutsceneConfig.scriptname, onStart or EmptyFunc, onEnd or EmptyFunc)
        --PlotDirector.Instance:CutscenePlay(cutsceneConfig.scriptname, onStart or EmptyFunc, onEnd or EmptyFunc)
    elseif cutsceneConfig.playmode == cfg.plot.PlayMode.AfterChangeMap then
        local sceneManager = require("scenemanager")
        sceneManager.SetChangeMapCutscene(cutsceneConfig.scriptname)
    elseif cutsceneConfig.playmode == cfg.plot.PlayMode.IndexPlay then
        Plot.Play(cutsceneConfig.scriptname, {onStart = onStart, onEnd = onEnd} )
    end
end

--暂停播放剧情片段
Cutscene.Pause = function(scriptname)
    PlotDirector.PauseCutscene()
    --PlotDirector.Instance:CutscenePause(scriptname)
end
--终止播放剧情片段
Cutscene.Stop = function(scriptname)
    PlotDirector.StopCutscene()
    --PlotDirector.Instance:CutsceneStop(scriptname)
end


--================================================================================================
--检查并加载配置
Plot.LoadConfig = function(plotIndex, params)
    local plotInfo = ConfigManager.getConfigData("plotindex",plotIndex)
    return plotInfo, params
end
Plot.PlayFunc = {
    [cfg.plot.CutsceneGroupMode.Single] = function(plotInfo, onStart, onEnd, num)
        if plotInfo.cutscenegroup.cutscenes[1] then
            Cutscene.Play(plotInfo, plotInfo.cutscenegroup.cutscenes[1], onStart, onEnd)
        end
    end,
    [cfg.plot.CutsceneGroupMode.Parallel] = function(plotInfo, onStart, onEnd, num)
        if plotInfo.cutscenegroup.cutscenes[1] then
            Cutscene.Play(plotInfo, plotInfo.cutscenegroup.cutscenes[1], onStart, onEnd)
        end
        for ki = 2, #plotInfo.cutscenegroup.cutscenes do
            Cutscene.Play(plotInfo, plotInfo.cutscenegroup.cutscenes[ki], nil, nil)
        end
    end,
    [cfg.plot.CutsceneGroupMode.Sequence] = function(plotInfo, onStart, onEnd, num)
        if plotInfo.cutscenegroup.cutscenes[num + 1] then
            Cutscene.Play(plotInfo, plotInfo.cutscenegroup.cutscenes[num], onStart, function()
                Plot.PlayFunc[cfg.plot.CutsceneGroupMode.Sequence](plotInfo, onStart, onEnd, num + 1)
            end)
        else
            Cutscene.Play(plotInfo, plotInfo.cutscenegroup.cutscenes[num], onStart, onEnd)
        end
    end,
}

--播放剧情
Plot.Play = function(index, params)
    local plotInfo, params = Plot.LoadConfig(index, params)
    if plotInfo == nil then
        logError("无法找到剧情配置，Index: ".. tostring(index))
        return
    end
    printyellow("Plot.Play",plotInfo.cutscenegroup.mode,plotInfo.index,params.onStart,params.onEnd)
    Plot.PlayFunc[plotInfo.cutscenegroup.mode](plotInfo,params.onStart,params.onEnd,1 )
end

Plot.Stop = function(index)
    local plotInfo, params = Plot.LoadConfig(index, {})
    for ki = 1, #plotInfo.cutscenegroup.cutscenes do
        Cutscene.Stop(plotInfo.cutscenegroup.cutscenes[ki].scriptname)
    end
end

Plot.Pause = function(index)
    local plotInfo, params = Plot.LoadConfig(index, {})
    for ki = 1, #plotInfo.cutscenegroup.cutscenes do
        Cutscene.Pause(plotInfo.cutscenegroup.cutscenes[ki].scriptname)
    end
end


local function NotifyLoadSceneStart()
    if PlotDirector.IsPlayingCutscene() then
        PlotDirector.StopCutscene()
    end
end

local function NotifyLoadSceneEnd()
    -- body
end
--=======================================================================================================================
--以下为调用接口
--=======================================================================================================================
--通过Id查找索引名称
local function GetPlotIndex(id)
    local plotIndexs = ConfigManager.getConfig("plotindex")
    for i,info in pairs(plotIndexs) do
        if info.id == id then
            return info.index
        end
    end
end
--通过索引调用播放CG
--onStart（function）, CG开始播放时调用
--onEnd（function），CG结束播放时调用
local function CutscenePlay(index,onEnd,onStart)
    Plot.Play(index, {onEnd = onEnd,onStart = onStart})
end

--通过Id调用播放CG
local function CutscenePlayById(id, onEnd, onStart)
	print("无法找到剧情配置"..id)
    local index = GetPlotIndex(id)
    if index then
        Plot.Play(index, {onEnd = onEnd,onStart = onStart})
    else
        logError("无法找到剧情配置,ID: ".. tostring(id))
    end
end

local function IsPlayingCutscene()
    return PlotDirector.IsPlayingCutscene()
end

local function init()
    local plotDirector = require("plot.base.plotdirector")
    plotDirector.init()
    GameEvent.evt_notify:add("loadscene_start",NotifyLoadSceneStart)
    GameEvent.evt_notify:add("loadscene_end",NotifyLoadSceneEnd)
end
local function CutscenePlayTest(key)
    local plotDirector = require("plot.base.plotdirector")
    plotDirector.PlayCutscene(key)
end
local function DirectPlayCutscene(scriptname, onStart, onEnd)
    local plotInfo, params = Plot.LoadConfig(scriptname, params)
    Cutscene.DirectPlay(plotInfo, scriptname, onStart, onEnd)
end

return {
    init = init,
    PlotState = PlotState,
    DirectPlayCutscene = DirectPlayCutscene,

    CutscenePause = Plot.Pause,
    CutsceneStop = Cutscene.Stop,
    --NotifyLoadSceneStart = NotifyLoadSceneStart,
    --NotifyLoadSceneEnd = NotifyLoadSceneEnd,
    --CutsceneLoad = Plot.Load,
    --======================================================
    --以下为CG播放调用接口
    CutscenePlayTest = CutscenePlayTest,
    CutscenePlayById = CutscenePlayById,
    CutscenePlay = CutscenePlay,
    IsPlayingCutscene = IsPlayingCutscene,
}
