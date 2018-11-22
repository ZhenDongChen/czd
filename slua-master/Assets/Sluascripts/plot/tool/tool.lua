local PlotDirector = require("plot.base.plotdirector")
--[[
    C#调用接口
]]
local function PlayCutscene(name)
    return PlotDirector.PlayCutscene(name, { id=0, index=name })
end

local function PauseCutscene(name)
    return PlotDirector.PauseCutscene()
end

local function StopCutscene(name)
    return PlotDirector.StopCutscene()
end

local function GetCutsceneTime()
    return PlotDirector.GetCutsceneTime()
end

local function GetCutsceneState()
    return PlotDirector.GetCutsceneState()
end




return {
    PlayCutscene = PlayCutscene,
    PauseCutscene = PauseCutscene,
    StopCutscene = StopCutscene,
    GetCutsceneTime = GetCutsceneTime,
    GetCutsceneState = GetCutsceneState,
}
