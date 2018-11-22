

local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local login = require("login")
local BagManager = require"character.bagmanager"
local EctypeManager = require"ectype.ectypemanager"
local CameraManager = require"cameramanager"


local gameObject
local name
local fields

local total
local current

local function destroy()
end

local function show(params)
    fields.UILabel_Title.text = params.name
    fields.UILabel_SystemDes.text = params.name
    fields.UILabel_Des2.text = params.coniddesc
    fields.UILabel_Des3.text = params.functiondesc
    fields.UISprite_SystemPic.spriteName = params.icon

end

local function hide()
end

local function update()

end

local function refresh(params)

end


local function init(params)
    name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_Close, function()
        uimanager.hide(name)
    end)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
