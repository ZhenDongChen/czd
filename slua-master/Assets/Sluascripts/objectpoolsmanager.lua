local print = print
local require = require
local isInited = false
local pools = {
    "character.footinfo.shadowobjmanager",
}

local function IsInited()
    return isInited
end

local function init()
    isInited = true
    for _,v in pairs(pools) do
        local mgr = require(v)
        mgr.init()
    end
end

return {
    init = init,
    IsInited = IsInited,
}
