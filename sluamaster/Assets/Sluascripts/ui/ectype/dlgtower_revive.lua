

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
local PlayerRole = require "character.playerrole"


local gameObject
local name
local fields

local total
local current
local time

local function destroy()
    LuaHelper.CameraGrayEffect(false)
end

local function show(params)
    time = params
    LuaHelper.CameraGrayEffect(true)
end

local function hide()
    LuaHelper.CameraGrayEffect(false)
end

local function update()
    if time>0 and PlayerRole:Instance():IsDead() then
        time = time- Time.deltaTime
        if time<= 0 then
            time = 0
        end
        fields.UILabel_Time.text = tostring(math.floor(time))
    else
        if EctypeManager.Revive() then
            EctypeManager.SendRevive()
        end
        uimanager.destroy(name)

    end
end

local function refresh(params)

end


local function init(params)
    name, gameObject, fields = unpack(params)

end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
