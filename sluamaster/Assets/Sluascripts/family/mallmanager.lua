local network = require("network")
local uimanager = require("uimanager")

local m_IsReady = false
local m_Goods

local function IsReady()
    return m_IsReady
end

local function GetReady(callback)
end

local function Release()
    m_IsReady = false
end

local function Goods()
    -- printyellow("on get familygoods")
    -- printt(m_Goods)
    return m_Goods
end

local function GetGood(id)
    return m_Goods[id]
end

local m_LevelupMallCallback
local function LevelupMall(callback)
    m_LevelupMallCallback = callback
    network.send(lx.gs.family.msg.CUpLevelMall())
end

local m_BuyCallback
local m_ItemIDClaim = -1
local function Buy(itemid, callback)
    m_BuyCallback = callback
    m_ItemIDClaim = itemid
    network.send(lx.gs.cmd.msg.CCommand({moduleid = cfg.cmd.ConfigId.MALL, cmdid = itemid, num = 1}))
end

local function init()
    network.add_listeners({
        {"lx.gs.family.msg.SUpLevelMall", function(msg)
             if m_LevelupMallCallback then
                 m_LevelupMallCallback()
             end
        end},
        {"lx.gs.cmd.msg.SCommand", function(msg)
             if msg.moduleid == cfg.cmd.ConfigId.MALL and m_ItemIDClaim == msg.cmdid then
                 m_ItemIDClaim = -1
                 if m_BuyCallback then
                     m_BuyCallback()
                 end
             end
        end},
    },"mallmanager")

    -- mall init
    m_Goods = {}
    local datamall = ConfigManager.getConfig("mall")
    for id,item in pairs(datamall) do
        if item.class == "cfg.mall.FamilyMall" then
            m_Goods[id] = item
        end
    end
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    Goods               = Goods,
    LevelupMall         = LevelupMall,
    Buy                 = Buy,
    GetGood             = GetGood,
}
