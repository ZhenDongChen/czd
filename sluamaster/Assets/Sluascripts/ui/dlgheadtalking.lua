local unpack                = unpack
local print                 = print
local math                  = math
local EventHelper           = UIEventListenerHelper
local uimanager             = require("uimanager")
local HeadTalkingManager    = require"character.headinfo.headtalking"
local PlayerRole
local gameObject
local name
local fields

local headTalkingManager

local function Add(params)
    local content   = params.content
    local time      = params.time or 4
    local target    = params.target
    headTalkingManager:Add(content,target,time)
end

local function destroy()

end

local function show(params)

end

local function hide()

end

local function late_udpate()

end

local function update()
    headTalkingManager:Update()
end

local function refresh(params)

end

local function init(params)
    name,gameObject,fields  = unpack(params)
    headTalkingManager      = HeadTalkingManager:new(fields.UIList_TalkContent)
end



return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    late_update = late_udpate,
    destroy = destroy,
    refresh = refresh,
    Add = Add,
}
