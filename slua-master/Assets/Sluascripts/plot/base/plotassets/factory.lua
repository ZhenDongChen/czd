local ConfigManager = require("cfg.configmanager")
local ResourceManager   = require("resource.resourcemanager")

local PlotAssets = {
    [cfg.plot.PlotAssetType.Model]      = require("plot.base.plotassets.model"),
    [cfg.plot.PlotAssetType.Audio]      = require("plot.base.plotassets.audio"),
    [cfg.plot.PlotAssetType.Special]    = require("plot.base.plotassets.special"),
}

local function CreateAsset(parentObject, index, cutscene)
    local config = ConfigManager.getConfigData("plotassets",index)
    if config == nil then
        logError("PlotAssets中找不到资源："..  index)
    end
    return PlotAssets[config.assettype]:new(index,config, parentObject,cutscene)
end

local function RecycleAsset(asset)
    asset:Destroy()
end

local function DestroyObject(obj)
    ResourceManager.Destroy(obj)
end


return {
    CreateAsset = CreateAsset,
    RecycleAsset = RecycleAsset,
}