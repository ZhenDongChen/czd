

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
end

local function show(params)
    time = params
end

local function hide()
end

local function update()
    if time>0 then
        time = time- Time.deltaTime
        if time<= 0 then
            time = 0
        end
        fields.UILabel_Time.text = tostring(math.floor(time))
    else
        uimanager.destroy(name)
        local tabsettingsystem = require("ui.setting.tabsettingsystem")
        tabsettingsystem.setLastUnlockTime(UnityEngine.Time.time)
        if PlayerRole:Instance():IsDead() == false then
            uimanager.call("dlguimain","SwitchAutoFight",false)
            PlayerRole:Instance():StopNavigate()
            local msg = map.msg.CReturnToRevivePos({})
            network.send(msg)
        end
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
