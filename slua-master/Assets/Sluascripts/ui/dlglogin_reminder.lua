local unpack = unpack
local print = print
local uimanager = require("uimanager")
local gameObject
local name
local fields
local uiFadeIn,uiFadeOut
local ElapsedTime

local function destroy()
end

local function update()
    if ElapsedTime then
        if ElapsedTime > 0 then
            ElapsedTime = ElapsedTime - Time.deltaTime
        else
            uimanager.hide(name)
            uimanager.show("dlglogin")
            ElapsedTime = nil
        end
    end
end

local function show(params)
    ElapsedTime = 3
end

local function hide()

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
