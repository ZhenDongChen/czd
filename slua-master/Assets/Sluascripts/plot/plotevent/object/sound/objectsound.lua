
local BaseSound  = require("plot.plotevent.eventbase.sound")

local ObjectSound = {};

setmetatable(ObjectSound,{__index = BaseSound})
return ObjectSound