local unpack          = unpack
local print           = print
local uimanager       = require("uimanager")
local fields,gameObject,name
local begintime       = 0
local endtime         = 0
local m_beginshowtime = 0

local function destroy()
end

local function show(params)
    begintime       = params.begintime
    endtime         = params.endtime
    m_beginshowtime = Time.time
    fields.UISprite_Loading.gameObject:SetActive(false)
end

local function update()
   if Time.time-m_beginshowtime > endtime then 
        uimanager.hideloading()
   elseif Time.time - m_beginshowtime > begintime then 
        if not fields.UISprite_Loading.gameObject.activeSelf then 
            fields.UISprite_Loading.gameObject:SetActive(true)
        end
   end
end

local function refresh(params)
    begintime       = params.begintime
    endtime         = params.endtime
end

local function init(params)
    name, gameObject, fields = unpack(params)
end

local function hide()

end



return {
    init = init,
    show = show,
    update = update,
    destroy = destroy,
    refresh = refresh,
    hide = hide,
}
