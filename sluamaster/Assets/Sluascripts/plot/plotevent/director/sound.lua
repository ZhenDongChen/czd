local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")
local BaseSound  = require("plot.plotevent.eventbase.sound")

local PlaySound = {};

setmetatable(PlaySound,{__index = BaseSound})

return PlaySound;