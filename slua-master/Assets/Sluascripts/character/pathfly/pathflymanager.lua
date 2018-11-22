local PathCurve = require("character.pathfly.info.pathcurve")
local ConfigManager = require("cfg.configmanager")



local function GetPathCurve(id)
    return PathCurve:new(id)
end

local function LoadAerocraft(character, callback)
    local Areocraft = require("character.pathfly.areocraft")
    local areocraft = Areocraft:new()
    areocraft:RegisterOnLoaded(function(asset_obj)
        if callback then
            callback(asset_obj)
        end
    end)
    areocraft:init(character, callback)
    return areocraft
end





return {
    GetPathCurve = GetPathCurve,
    LoadAerocraft = LoadAerocraft,
}