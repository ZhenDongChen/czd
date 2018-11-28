local unpack 		= unpack
local print 		= print
local UIManager 	= require("uimanager")
local FriendManager = require("ui.friend.friendmanager")
local ConfigManager = require("cfg.configmanager")
local EventHelper 	= UIEventListenerHelper

------------------------------------------------------------------------------------------------------
local name, gameObject, fields



local function refresh(params)

end

local function destroy()

end

local function show(params)
    if params and params.idolId then
        local idolCfg = ConfigManager.getConfigData("idol", params.idolId)
        if idolCfg then
            fields.UITexture_Figure:SetIconTexture(idolCfg.image)
            fields.UILabel_Figure.text = tostring(idolCfg.guardtalk)
        end
    end
    EventHelper.SetClick(fields.UIButton_Skip, function()
        UIManager.hidedialog(name)
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
