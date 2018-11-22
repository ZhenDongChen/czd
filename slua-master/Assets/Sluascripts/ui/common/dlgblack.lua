local fields
local name
local gameObject

local function registereventhandler()
    --printyellow("[dlgblack:registereventhandler]dlgblack registereventhandler!")
end

local function init(params)
    --printyellow("[dlgblack:init]dlgblack init!")
    name, gameObject, fields    = unpack(params)
    registereventhandler()
end

local function update()
    --printyellow("[dlgblack:update] update!")
end


local function refresh()
    --printyellow("[dlgblack:refresh]dlgblack refresh!")
end

local function initpanels()
    --printyellow("[dlgblack:initpanels]dlgblack initpanels!")
end

local function show()
    --printyellow("[dlgblack:show]dlgblack show!")
end

local function hide()
    -- printyellow("[dlgblack:hide]dlgblack hide!")
end

local function uishowtype()
    return UIShowType.Refresh
end

return{
    show=show,
    hide=hide,
    init=init,
    refresh=refresh,
    update = update,
    uishowtype=uishowtype,
}
