local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")
local BaseSound  = require("plot.plotevent.eventbase.sound")

local BackMusic = {};

setmetatable(BackMusic,{__index = BaseSound})

return BackMusic;