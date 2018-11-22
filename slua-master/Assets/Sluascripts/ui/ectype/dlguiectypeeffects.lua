local unpack                = unpack
local print                 = print
local math                  = math
local EventHelper           = UIEventListenerHelper
local uimanager             = require("uimanager")
local PlayerRole
local gameObject
local name
local fields

local function destroy()

end

local function show(params)
   local isEnter = params and params.isEnter
    if isEnter then
        uimanager.PlayUIParticleSystem(fields.UIGroup_EnterEctype.gameObject,
        function()
            uimanager.hide(name)
        end)
    else
        uimanager.PlayUIParticleSystem(fields.UIGroup_LeaveEctype.gameObject,function()
            uimanager.hide(name)
        end)
    end
end

local function hide()
end

local function late_udpate()

end

local function update()

end

local function refresh(params)

end

local function init(params)
    name,gameObject,fields  = unpack(params)
end



return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    late_update = late_udpate,
    destroy = destroy,
    refresh = refresh,
}
