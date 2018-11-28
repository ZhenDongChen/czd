local network = require("network")
local player = require("character.playerrole"):Instance()
local uimanager = require("uimanager")
local BonusManager = require("item.bonusmanager")

local m_IsReady = false
local m_Callback

local m_Score
local m_EventMap
local m_BonusGot

local modset = {"guide.reclaimmanager",}

local function IsReady()
    return m_IsReady
end

local function GetReady(callback)
    if not m_IsReady then
        m_Callback = callback
        network.send(lx.gs.dailyactivity.msg.CGetActiveInfo())
    else
        callback() 
    end
end

local function Release()
    m_IsReady = false
    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.Release then
            mod.Release()
        end
    end
end

local function OnLogout()
    Release()
end

local function Score()
    return m_Score
end

local function EventCount(id)
    return m_EventMap[id] or 0
end

local function BonusGot(id)
        return m_BonusGot[id] or false
end

local m_GetBonusCallback
local function GetBonus(id, callback)
    m_GetBonusCallback = callback
    network.send(lx.gs.dailyactivity.msg.CGetActiveBonus(){bonustype=id})
end

local function OnShowRewardInfo(msg)
    local bonusItems = BonusManager.GetItemsOfServerBonus(msg.bonus)
    -- ������������Ʈ�� 
    for i = 1, #bonusItems do
	    uimanager.ShowSystemFlyText( string.format(LocalString.FlyText_Reward,bonusItems[i]:GetNumber(),bonusItems[i]:GetName()))
    end        
    -- ˢ�º�����ʾ
    --uimanager.call("guide.tabliveness", "RefreshRedDot")
end

local m_bonuskeys
local function CanReceiveBox()
    if m_IsReady then
        for i,key in pairs(m_bonuskeys) do
            if not BonusGot(key) and  m_Score >= key then
                return true
            end  
        end
    end
    return false
end

local function UnReadSingle() 
    if CanReceiveBox() then
        return true
    end
    return false
end

local function UnRead() 
    if CanReceiveBox() then
        return true
    end

    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.UnRead and mod.UnRead() then
            return true
        end
    end
    return false
end

local function init()
    local datas = ConfigManager.getConfig("activebonus")
    m_bonuskeys = keys(datas)

    gameevent.evt_system_message:add("logout", OnLogout)

    network.add_listeners({
	
        {"lx.gs.dailyactivity.msg.SGetActiveInfo", function(msg)
			printyellow("SGetActiveInfo")
             m_Score = msg.scores
             m_EventMap = msg.activetimes
             m_BonusGot = utils.array_to_set(msg.receivedbonus)
             m_IsReady = true
             if m_Callback then
                 m_Callback()
                 m_Callback = nil
             end
        end},
        {"lx.gs.dailyactivity.msg.SGetActiveBonus", function(msg)
			printyellow("SGetActiveBonus")
             m_BonusGot[msg.bonustype] = true
             if m_GetBonusCallback then
                 m_GetBonusCallback(msg.bonustype)
             end
             --OnShowRewardInfo(msg)
        end},
        {"lx.gs.role.msg.SDayOver", function(msg)
			printyellow("SDayOver")
             Release()
        end},

        -- notify
        {"lx.gs.dailyactivity.msg.SActiveInfoChangeNotify", function(msg)
             if m_IsReady then
                 m_Score = msg.scores
                 for id,s in pairs(msg.changeactivetimes) do
                     m_EventMap[id] = s
                 end
             end
        end},
    })
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    Score               = Score,
    EventCount          = EventCount,
    BonusGot            = BonusGot,
    GetBonus            = GetBonus,
    UnRead              = UnRead,
    UnReadSingle        = UnReadSingle,
}
