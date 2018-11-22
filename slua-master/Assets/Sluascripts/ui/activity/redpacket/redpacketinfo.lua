local ConfigMgr 	  = require "cfg.configmanager"
local UIManager 		= require("uimanager")
local gameevent         = require "gameevent"
local PlayerRole = require "character.playerrole"
local LimitTimeManager       = require("limittimemanager")
local VipChargeManager=require"ui.vipcharge.vipchargemanager"
local ItemManager = require("item.itemmanager")
local WelfareManager = require("ui.welfare.welfaremanager")
local BagManager = require"character.bagmanager"
local timeutils = timeutils

local m_RedPacketCfg
local m_redpkgValideTime = 300 --5分钟

local m_UnfetchedPacketCount
local m_UnfetchedPackets

local Update_Interval = 5
local m_LastUpdateTime = 0

local function CompareInt(a, b)
    local result = 0
    if a and b then
        if a>b then
            result = 1
        elseif a<b then
            result = -1
        else
            result = 0
        end
    end
    --printyellow(string.format("[lotteryfragmentmanager:CompareInt] a=[%s], b=[%s], result=[%s].", a, b, result))
    return result
end

--[[
--cfgdatetime:
<struct name="DateTime" delimiter=":|-">��ʽ  yyyy:mm:dd-hh:mm:ss
	<field name="year" type="int"/>
	<field name="month" type="int"/>
	<field name="day" type="int"/>
	<field name="hour" type="int"/>
	<field name="minute" type="int"/>
	<field name="second" type="int"/>		
</struct>

localdatetime:
year (four digits), month (1--12), day (1--31), 
hour (0--23), min (0--59), sec (0--61), 
wday (weekday, Sunday is 1), yday (day of the year), 
isdst (daylight saving flag, a boolean).
--]]
local function CompareDateTime(cfgdatetime, localdatetime)    
    --[[
    printyellow("[redpacketinfo:CompareDateTime] cfgdatetime:")
    printt(cfgdatetime)
    printyellow("[redpacketinfo:CompareDateTime] localdatetime:")
    printt(localdatetime)
    --]]

    local result = 0
    if cfgdatetime and localdatetime then  
        --year
        result = CompareInt(cfgdatetime.year, localdatetime.year)
        if 0~=result then
            return result
        end

        --month
        result = CompareInt(cfgdatetime.month, localdatetime.month)
        if 0~=result then
            return result
        end

        --day
        result = CompareInt(cfgdatetime.day, localdatetime.day)
        if 0~=result then
            return result
        end
        
        --hour
        result = CompareInt(cfgdatetime.hour, localdatetime.hour)
        if 0~=result then
            return result
        end
        
        --minute
        result = CompareInt(cfgdatetime.minute, localdatetime.min)
        if 0~=result then
            return result
        end
        
        --second
        result = CompareInt(cfgdatetime.second, localdatetime.sec)
    else
        if nil==cfgdatetime then
            print("[ERROR][redpacketinfo:CompareDateTime] cfgdatetime nil!")
        end
        if nil==localdatetime then
            print("[ERROR][redpacketinfo:CompareDateTime] localdatetime nil!")
        end
    end
    return result    
end

local function IsActivityOpen()
    ---[[
    if m_RedPacketCfg then
        local localdatetime = timeutils.TimeNow()
        if -1==CompareDateTime(m_RedPacketCfg.datetime.begintime, localdatetime) and 1==CompareDateTime(m_RedPacketCfg.datetime.endtime, localdatetime) then
            --printyellow(string.format("[redpacketinfo:IsLotteryOpen] lottery [%s] open = true!", m_RedPacketCfg.figureshow.petName))
            return true
        else
            --printyellow(string.format("[redpacketinfo:IsLotteryOpen] lottery [%s] open = false!", m_RedPacketCfg.figureshow.petName))
            return false
        end
    else
        print("[ERROR][redpacketinfo:IsLotteryOpen] m_RedPacketCfg nil!")
    end
    --]]

    --test
    --return true
end

local function GetAllRedPacketInfo()
    return m_RedPacketCfg and m_RedPacketCfg.redpacketinfo or nil
end

local function GetRedPacketInfo(packettype)
    local packetinfo = nil
    if m_RedPacketCfg then
        for _,packet in ipairs(m_RedPacketCfg.redpacketinfo) do
            if packet.id==packettype then
                packetinfo = packet
                break
            end
        end    
    end
    return packetinfo
end

local function IsNormalRedPacket(packettype)
    local result = false
    if m_RedPacketCfg and m_RedPacketCfg.redpacketinfo then
        result = packettype==m_RedPacketCfg.redpacketinfo[1].id
    end
    return result
end

local function GetSendCount()
    local usedcount = LimitTimeManager.GetDayLimitTime(cfg.cmd.ConfigId.SEND_RED_PACKAGE, 0)
    return usedcount and usedcount or 0
end

local function GetSendLimit()
    return m_RedPacketCfg and m_RedPacketCfg.givelimit.num or 0
end

local function GetReceiveCount()
    local usedcount = LimitTimeManager.GetDayLimitTime(cfg.cmd.ConfigId.SEND_RED_PACKAGE, 1)
    return usedcount and usedcount or 0
end

local function GetReceiveLimit()
    --return m_RedPacketCfg and m_RedPacketCfg.recievelimit.num or 0
    --红包取消限制
    return GetReceiveCount()+1
end

local function GetRedPacketCountById(redpacketid)
    local count = 0
    if redpacketid then
        count = BagManager.GetItemNumById(redpacketid)
    end
    return count
end

local function GetUnfetchedCount()
    return math.max(m_UnfetchedPacketCount, 0)
end

local function PopUnfetchedPacket(packetid)
    local packet = nil
    if m_UnfetchedPacketCount>0 then
        packet=m_UnfetchedPackets[m_UnfetchedPacketCount]
        for i,packetinfo in pairs(m_UnfetchedPackets) do
            m_UnfetchedPackets[i] = m_UnfetchedPackets[i+1]
        end
        m_UnfetchedPacketCount = m_UnfetchedPacketCount-1
    end

    --printyellow("[redpacketinfo:PopUnfetchedPacket] pop packet:")
    --printt(packet)
    
    --printyellow("[redpacketinfo:PopUnfetchedPacket] m_UnfetchedPackets:")
    --printt(m_UnfetchedPackets)

    return packet
end

local function PushUnfetchedPacket(packet)
    if packet then
        --printyellow("[redpacketinfo:PushUnfetchedPacket] push packet:")
        --printt(packet)
        packet.recvTime = timeutils.GetLocalTime()
        table.insert(m_UnfetchedPackets,packet)
        m_UnfetchedPacketCount = m_UnfetchedPacketCount+1
    end

    --cfg.redpacket.Redpacket.MAX_SHOW_NUM
    while m_UnfetchedPacketCount>100 do
        --printyellow("[redpacketinfo:PushUnfetchedPacket] pool full, pop packet!")
        PopUnfetchedPacket()
    end
    
    --printyellow("[redpacketinfo:PushUnfetchedPacket] m_UnfetchedPackets:")
    --printt(m_UnfetchedPackets)
end

local function GetUnfetchedPacket()
    local packet = nil
    if m_UnfetchedPacketCount>0 then
        for i=1,table.getn(m_UnfetchedPackets) do
            if m_UnfetchedPackets[i] then
                packet = m_UnfetchedPackets[i]
                break
            end
        end
    end
    
    --printyellow("[redpacketinfo:GetUnfetchedPacket] m_UnfetchedPackets:")
    --printt(m_UnfetchedPackets)

    return packet
end

local function GetBGOpen()
    return m_RedPacketCfg and m_RedPacketCfg.openpic or nil
end

local function GetBGSucc()
    return m_RedPacketCfg and m_RedPacketCfg.sucpic or nil
end

local function GetBGClose()
    return m_RedPacketCfg and m_RedPacketCfg.closepic or nil
end

local function update()
    --printyellow("[redpacketinfo:update] update!")
    if nil==m_LastUpdateTime or (Time.time-m_LastUpdateTime)>Update_Interval then    
        m_LastUpdateTime = Time.time
        local topPack = GetUnfetchedPacket()
        local locTime = timeutils.GetLocalTime()
        if topPack~=nil and locTime-topPack.recvTime>m_redpkgValideTime then
            PopUnfetchedPacket()
            printyellow("PopUnfetchedPacket() remain:"..m_UnfetchedPacketCount)
        end
    end
end

local function reset()
    m_LastUpdateTime = 0

    m_UnfetchedPacketCount = 0
    m_UnfetchedPackets = {}
end

local function OnLogout()
    reset()
end

local function init()
    printyellow("[redpacketinfo:init] init!")    
    reset()
    
    --get cfg
    -- 红包改版
    m_RedPacketCfg = nil
    local redpackCfg = ConfigManager.getConfig("redpacket")
    if redpackCfg == nil then
        printyellow("[ERROR][redpacketinfo:init] RedPacketCfg null!")
    else
        m_redpkgValideTime = redpackCfg.effectivetime*60
    end
	print("m_redpkgValideTime:"..m_redpkgValideTime)

    --others
	gameevent.evt_system_message:add("logout", OnLogout)
    gameevent.evt_update:add(update)
end

return
{
    init = init,
    IsActivityOpen = IsActivityOpen,
    GetAllRedPacketInfo = GetAllRedPacketInfo,
    GetRedPacketInfo = GetRedPacketInfo,
    IsNormalRedPacket = IsNormalRedPacket,
    GetSendCount = GetSendCount,
    GetReceiveCount = GetReceiveCount,
    GetSendLimit = GetSendLimit,
    GetReceiveLimit = GetReceiveLimit,
    GetRedPacketCountById = GetRedPacketCountById,
    GetUnfetchedCount = GetUnfetchedCount,
    PushUnfetchedPacket = PushUnfetchedPacket,
    PopUnfetchedPacket = PopUnfetchedPacket,
    GetUnfetchedPacket = GetUnfetchedPacket,
    
    GetBGOpen = GetBGOpen,
    GetBGSucc = GetBGSucc,
    GetBGClose = GetBGClose,
}