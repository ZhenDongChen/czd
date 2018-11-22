
local network                = require("network")
local uimanager              = require("uimanager")
--local lotterymanager         = require "ui.lottery.lotterymanager"
local gameevent              = require "gameevent"

local limitsInfo             = { } -- type:map {key=id,value=typenums}
local cooldownInfo           = { } --type:map {key= id,value = expiretime }

local m_LimitChangeCallbacks = { }
local cooldowntip            = false

local function GetCoolDownTip()
	return cooldowntip 
end

local function SetCoolDownTip(d)
	cooldowntip = d
end

local function GetLimitId(configId,csvId)
    return configId*2^32+csvId
end

local function GetLimitsInfo()
    return limitsInfo
end

local function GetLimitTime(configId,csvId)
	--printyellow(GetLimitId(configId,csvId))
    return limitsInfo[GetLimitId(configId,csvId)]
end

local function GetDayLimitTime(configId,csvId)
    local limits = GetLimitTime(configId,csvId)
    if limits and limits[cfg.cmd.condition.LimitType.DAY] then
        return limits[cfg.cmd.condition.LimitType.DAY]
    else
        return 0
    end
end

local function GetWeekLimitTime(configId,csvId)
    local limits = GetLimitTime(configId,csvId)
    if limits and limits[cfg.cmd.condition.LimitType.WEEK] then
        return limits[cfg.cmd.condition.LimitType.WEEK]
    else
        return 0
    end
end

local function GetMonthLimitTime(configId,csvId)
    local limits = GetLimitTime(configId,csvId)
    if limits and limits[cfg.cmd.condition.LimitType.MONTH] then
        return limits[cfg.cmd.condition.LimitType.MONTH]
    else
        return 0
    end
end

local function GetLifelongLimitTime(configId,csvId)
    local limits = GetLimitTime(configId,csvId)
    if limits and limits[cfg.cmd.condition.LimitType.LIFELONG] then
        return limits[cfg.cmd.condition.LimitType.LIFELONG]
    else
        return 0
    end
end

--CD结束时间
local function GetExpireTime(configId,csvId)
    local cooldown =  cooldownInfo[GetLimitId(configId,csvId)]
    return cooldown
end
--CD is ready
local function IsReady(configId,csvId)
    local expiretime = GetExpireTime(configId,csvId)
    return expiretime == nil or expiretime<timeutils.GetServerTime()*1000
end

--返回cd剩余时间（s）
local function GetLeftTime(configId,csvId)
    if IsReady(configId,csvId) then
        return 0
    else
        local expiretime = GetExpireTime(configId,csvId)
        return math.ceil(expiretime/1000) - timeutils.GetServerTime()
    end
end

local function GetDayLimitTotal(limits)
    for t,value in pairs(limits) do
        if t == cfg.cmd.condition.LimitType.DAY then
            return value.num
        end
    end
    return -1
end

local function GetWeekLimitTotal(limits)
    for t,num in pairs(limits) do
        if t == cfg.cmd.condition.LimitType.WEEK then
            return num
        end
    end
    return -1
end

local function GetMonthLimitTotal(limits)
    for t,num in pairs(limits) do
        if t == cfg.cmd.condition.LimitType.MONTH then
            return num
        end
    end
    return -1
end

local function GetLifelongLimitTotal(limits)
    for t,num in pairs(limits) do
        if t == cfg.cmd.condition.LimitType.LIFELONG then
            return num
        end
    end
    return -1
end

local function onmsg_SLimitChange(msg)
    if msg.changelimits ~= nil and #(msg.changelimits) ~= 0 then
        for _, newLimit in pairs(msg.changelimits) do
              limitsInfo[newLimit.id] = newLimit.typenums
        end
    end

    if msg.removelimits ~= nil and #(msg.removelimits) ~= 0 then
        for _, removeId in pairs(msg.removelimits) do
            if limitsInfo[removeId] then
                limitsInfo[removeId]=nil
            end
        end
    end
    if uimanager.isshow("ectype.dlgstorydungeonsub") then 
		uimanager.refresh("ectype.dlgstorydungeonsub")
	end
   -- lotterymanager.Refresh()
	-- limitchange回调
	gameevent.evt_limitchange:trigger()

    if m_LimitChangeCallbacks and #m_LimitChangeCallbacks>0 then
        for i=1, #m_LimitChangeCallbacks do
            if m_LimitChangeCallbacks[i] then
                m_LimitChangeCallbacks[i]()
            end
        end        
    end
end

local function onmsg_SCoolDownChange(msg)
    if cooldownInfo then
        cooldownInfo[msg.id] = msg.expiretime
    end
	-- id为CD组id或者物品id
	cooldowntip = true
	local id = bit.band(msg.id,0xFFFFFFFF)
	local moduleid = (msg.id-id)/2^32
	local expiretime = math.ceil(msg.expiretime/1000)
	gameevent.evt_cdchange:trigger({id,moduleid,expiretime})
    --lotterymanager.Refresh()
end

local function onmsg_SLimit(msg)
    if msg.limits then
        limitsInfo = { }
        for _, limit in pairs(msg.limits) do
            limitsInfo[limit.id] = limit.typenums
        end
    end
    if msg.cooldowns then
         cooldownInfo = {} --type:map {key= id,value = expiretime }
         for _,cooldown in pairs(msg.cooldowns) do
            cooldownInfo[cooldown.id] = cooldown.expiretime
         end
    end
end

local function update()

end

local function AddLimitChangeCallback(callback)
    if m_LimitChangeCallbacks and #m_LimitChangeCallbacks>0 then
        for i=1, #m_LimitChangeCallbacks do
            if m_LimitChangeCallbacks[i] == callback then
                return
            end
        end        
    end
    m_LimitChangeCallbacks[#m_LimitChangeCallbacks+1] = callback
end

local function Release()
	limitsInfo = { } 
	cooldownInfo = { } 
	
	m_LimitChangeCallbacks = { }
	cooldowntip = false
end

local function OnLogout()
    Release()
end

local function init()
    m_LimitChangeCallbacks = {}
	gameevent.evt_system_message:add("logout", OnLogout)
    network.add_listeners( {
        { "lx.gs.limit.msg.SLimitChange", onmsg_SLimitChange },
        { "lx.gs.limit.msg.SLimit", onmsg_SLimit },
        { "lx.gs.limit.msg.SCoolDownChange", onmsg_SCoolDownChange },
    } )
end


return {
    init                   = init,
    GetLimitsInfo          = GetLimitsInfo,
    GetLimitTime           = GetLimitTime,
    GetLimitId             = GetLimitId,
    GetDayLimitTime        = GetDayLimitTime,
    GetWeekLimitTime       = GetWeekLimitTime,
    GetMonthLimitTime      = GetmonthLimitTime,
    GetLifelongLimitTime   = GetLifelongLimitTime,
    GetExpireTime          = GetExpireTime, --冷却结束时间点
    IsReady                = IsReady,--冷却时间结束
    GetLeftTime            = GetLeftTime, --冷却剩余时间
    GetDayLimitTotal       = GetDayLimitTotal,
    GetWeekLimitTotal      = GetWeekLimitTotal,
    GetMonthLimitTotal     = GetMonthLimitTotal,
    GetLifelongLimitTotal  = GetLifelongLimitTotal,

    AddLimitChangeCallback = AddLimitChangeCallback,
	GetCoolDownTip         = GetCoolDownTip,
	SetCoolDownTip         = SetCoolDownTip,
}



--[[
local m_LimitChangeCallbacks = { }
local cooldowntip            = false

local function GetCoolDownTip()
	return cooldowntip 
end

local function SetCoolDownTip(d)
	cooldowntip = d
end

local function GetLimitId(configId,csvId)
    return configId*2^32+csvId
end

local function GetLimitsInfo()
    return limitsInfo
end

local function GetLimitTime(configId,csvId)
    return limitsInfo[GetLimitId(configId,csvId)]
end

local function GetDayLimitTime(configId,csvId)
    local limits = GetLimitTime(configId,csvId)
    if limits and limits[cfg.cmd.condition.LimitType.DAY] then
        return limits[cfg.cmd.condition.LimitType.DAY]
    else
        return 0
    end
end

local function GetWeekLimitTime(configId,csvId)
    local limits = GetLimitTime(configId,csvId)
    if limits and limits[cfg.cmd.condition.LimitType.WEEK] then
        return limits[cfg.cmd.condition.LimitType.WEEK]
    else
        return 0
    end
end

local function GetMonthLimitTime(configId,csvId)
    local limits = GetLimitTime(configId,csvId)
    if limits and limits[cfg.cmd.condition.LimitType.MONTH] then
        return limits[cfg.cmd.condition.LimitType.MONTH]
    else
        return 0
    end
end

local function GetLifelongLimitTime(configId,csvId)
    local limits = GetLimitTime(configId,csvId)
    if limits and limits[cfg.cmd.condition.LimitType.LIFELONG] then
        return limits[cfg.cmd.condition.LimitType.LIFELONG]
    else
        return 0
    end
end

--CD结束时间
local function GetExpireTime(configId,csvId)
    local cooldown =  cooldownInfo[GetLimitId(configId,csvId)]
    return cooldown
end
--CD is ready
local function IsReady(configId,csvId)
    local expiretime = GetExpireTime(configId,csvId)
    return expiretime == nil or expiretime<timeutils.GetServerTime()*1000
end

--返回cd剩余时间（s）
local function GetLeftTime(configId,csvId)
    if IsReady(configId,csvId) then
        return 0
    else
        local expiretime = GetExpireTime(configId,csvId)
        return math.ceil(expiretime/1000) - timeutils.GetServerTime()
    end
end

local function GetDayLimitTotal(limits)
    for t,value in pairs(limits) do
        if t == cfg.cmd.condition.LimitType.DAY then
            return value.num
        end
    end
    return -1
end

local function GetWeekLimitTotal(limits)
    for t,num in pairs(limits) do
        if t == cfg.cmd.condition.LimitType.WEEK then
            return num
        end
    end
    return -1
end

local function GetMonthLimitTotal(limits)
    for t,num in pairs(limits) do
        if t == cfg.cmd.condition.LimitType.MONTH then
            return num
        end
    end
    return -1
end

local function GetLifelongLimitTotal(limits)
    for t,num in pairs(limits) do
        if t == cfg.cmd.condition.LimitType.LIFELONG then
            return num
        end
    end
    return -1
end

local function onmsg_SLimitChange(msg)
    if msg.changelimits ~= nil and #(msg.changelimits) ~= 0 then
        for _, newLimit in pairs(msg.changelimits) do
              limitsInfo[newLimit.id] = newLimit.typenums
        end
    end

    if msg.removelimits ~= nil and #(msg.removelimits) ~= 0 then
        for _, removeId in pairs(msg.removelimits) do
            if limitsInfo[removeId] then
                limitsInfo[removeId]=nil
            end
        end
    end
    if uimanager.isshow("ectype.dlgstorydungeonsub") then 
		uimanager.refresh("ectype.dlgstorydungeonsub")
	end
    lotterymanager.Refresh()
	-- limitchange回调
	gameevent.evt_limitchange:trigger()

    if m_LimitChangeCallbacks and #m_LimitChangeCallbacks>0 then
        for i=1, #m_LimitChangeCallbacks do
            if m_LimitChangeCallbacks[i] then
                m_LimitChangeCallbacks[i]()
            end
        end        
    end
end

local function onmsg_SCoolDownChange(msg)
    if cooldownInfo then
        cooldownInfo[msg.id] = msg.expiretime
    end
	-- id为CD组id或者物品id
	cooldowntip = true
	local id = bit.band(msg.id,0xFFFFFFFF)
	local moduleid = (msg.id-id)/2^32
	local expiretime = math.ceil(msg.expiretime/1000)
	gameevent.evt_cdchange:trigger({id,moduleid,expiretime})
    lotterymanager.Refresh()
end

local function onmsg_SLimit(msg)
    if msg.limits then
        limitsInfo = { }
        for _, limit in pairs(msg.limits) do
            limitsInfo[limit.id] = limit.typenums
        end
    end
    if msg.cooldowns then
         cooldownInfo = {} --type:map {key= id,value = expiretime }
         for _,cooldown in pairs(msg.cooldowns) do
            cooldownInfo[cooldown.id] = cooldown.expiretime
         end
    end
end

local function update()

end

local function AddLimitChangeCallback(callback)
    if m_LimitChangeCallbacks and #m_LimitChangeCallbacks>0 then
        for i=1, #m_LimitChangeCallbacks do
            if m_LimitChangeCallbacks[i] == callback then
                return
            end
        end        
    end
    m_LimitChangeCallbacks[#m_LimitChangeCallbacks+1] = callback
end

local function Release()
	limitsInfo = { } 
	cooldownInfo = { } 
	
	m_LimitChangeCallbacks = { }
	cooldowntip = false
end

local function OnLogout()
    Release()
end

local function init()
    m_LimitChangeCallbacks = {}
	gameevent.evt_system_message:add("logout", OnLogout)
    network.add_listeners( {
        { "lx.gs.limit.msg.SLimitChange", onmsg_SLimitChange },
        { "lx.gs.limit.msg.SLimit", onmsg_SLimit },
        { "lx.gs.limit.msg.SCoolDownChange", onmsg_SCoolDownChange },
    } )
end


return {
    init                   = init,
    GetLimitsInfo          = GetLimitsInfo,
    GetLimitTime           = GetLimitTime,
    GetLimitId             = GetLimitId,
    GetDayLimitTime        = GetDayLimitTime,
    GetWeekLimitTime       = GetWeekLimitTime,
    GetMonthLimitTime      = GetmonthLimitTime,
    GetLifelongLimitTime   = GetLifelongLimitTime,
    GetExpireTime          = GetExpireTime, --冷却结束时间点
    IsReady                = IsReady,--冷却时间结束
    GetLeftTime            = GetLeftTime, --冷却剩余时间
    GetDayLimitTotal       = GetDayLimitTotal,
    GetWeekLimitTotal      = GetWeekLimitTotal,
    GetMonthLimitTotal     = GetMonthLimitTotal,
    GetLifelongLimitTotal  = GetLifelongLimitTotal,

    AddLimitChangeCallback = AddLimitChangeCallback,
	GetCoolDownTip         = GetCoolDownTip,
	SetCoolDownTip         = SetCoolDownTip,
}

--]]