local AssetBase = require("plot.base.plotassets.base")

local AssetAudio = Class:new(AssetBase)

function AssetAudio:__new(index,config,parentObject,cutscene)
    AssetBase.__new(self, index,config,parentObject,cutscene)

end

return AssetAudio