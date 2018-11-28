local modset = {"guide.livenessmanager",
                "guide.reclaimmanager",
}

local function init()
    -- printyellow("family manager init")
    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.init then
            mod.init()
        end
    end
end

return {
    init = init,
}
