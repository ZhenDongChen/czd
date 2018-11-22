local name, gameObject, fields
local UIManager = require("uimanager")


local function update()
    
end

local function refresh()

end

local function hide()

end

local function show(params)

end

local function init(nameIn, gameObjectIn, fieldsIn)
    name, gameObject, fields = nameIn, gameObjectIn, fieldsIn
end

return {
    init    = init,
    show    = show,
    hide    = hide,
    update  = update,
    refresh = refresh,
}