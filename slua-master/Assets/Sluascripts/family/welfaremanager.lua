local network = require("network")
local uimanager = require("uimanager")

local modset = {"family.mallmanager",
                --"family.skillmanager",    --���߻�Ҫ�����Ƚ����弼�ܽ���
                "family.levelwelfaremanager",}

local m_IsReady = false

local function IsReady()
    return m_IsReady
end

local function GetReady(callback)
   -- if m_IsReady then
        callback()
   -- else
    --    m_Callback = callback
    --    network.send(lx.gs.family.msg.CGetFamilyWelfareInfo())
   -- end
end

local function Release()
    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.Release then
            mod.Release()
        end
    end
    m_IsReady = false
end

local function UnRead()
    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.UnRead and mod.UnRead() then
            return true
        end
    end
    return false
end

local function init()
    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.init then
            mod.init()
        end
    end

    network.add_listeners({
        {"lx.gs.family.msg.SGetFamilyWelfareInfo", function(msg)
             m_IsReady = true
             if m_Callback then
                 m_Callback()
                 m_Callback = nil
             end
        end},
    })
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    UnRead              = UnRead,
}
