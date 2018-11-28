--[[TabRadio]]
local unpack, print 	= unpack, print
local UIManager 	    = require "uimanager"
local EventHelper 	    = UIEventListenerHelper
local CgManager         = require("ui.cg.cgmanager")

local name
local gameObject
local fields

local function refresh(params)

end

local function destroy()

end



local function show(params)
    EventHelper.SetClick(fields.UIButton_Challenge, function()
        CgManager.PlayCG("chengzhan.mp4",nil, cfg.ectype.VedioControlMode.CANCELONINPUT)
    end)
    
end

local function hide()

end

local function update()
 
end

local function init(params)
    name, gameObject, fields = unpack(params)

    
end

local function uishowtype()
    return UIShowType.Refresh
end


return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
}
