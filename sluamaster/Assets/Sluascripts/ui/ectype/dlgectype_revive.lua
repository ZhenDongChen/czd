

local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local login = require("login")
local BagManager = require"character.bagmanager"
local EctypeManager = require"ectype.ectypemanager"

local gameObject
local name
local fields

local total
local current

local function destroy()

end

local function show(params)
    current = params[1]
    total = params[2]
    local text
    text = '('..tostring(current)..'/'..tostring(total)..')'
    fields.UILabel_Times.text = LocalString.EctypeText.ReviveTime..text
end

local function hide()

end

local function update()

end

local function refresh(params)

end


local function init(params)
    name, gameObject, fields = unpack(params)

    EventHelper.SetClick(fields.UIButton_StwpResurrection,function()
        if EctypeManager.Revive() then
            EctypeManager.SendRevive()
            --network.send(lx.gs.map.msg.CReviveStory({}))
        end
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
