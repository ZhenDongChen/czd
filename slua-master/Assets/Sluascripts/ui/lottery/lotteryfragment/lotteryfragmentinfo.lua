local ConfigMgr 	  = require "cfg.configmanager"
local UIManager 		= require("uimanager")
local gameevent         = require "gameevent"
local PlayerRole = require "character.playerrole"
local LimitTimeManager       = require("limittimemanager")
--local VipChargeManager=require"ui.vipcharge.vipchargemanager"
local ItemManager = require("item.itemmanager")

local m_AllLotteryCfgs
local m_CurrentLotteryCfg
local m_ClaimedScoreList

local Update_Interval = 5
local m_LastUpdateTime = 0

local function GetCurrentLottery()
    --printyellow("[lotteryfragmentinfo:GetCurrentLottery] GetCurrentLottery:")
    --printt(m_CurrentLotteryCfg)
    return m_CurrentLotteryCfg
end

local function GetAllScoreBonus()
    return m_CurrentLotteryCfg and m_CurrentLotteryCfg.scoreexchange or nil
end

local function GetScoreBonus(score)
    local bonus
    if m_CurrentLotteryCfg and m_CurrentLotteryCfg.scoreexchange and #m_CurrentLotteryCfg.scoreexchange>0 then
        for index=1, #m_CurrentLotteryCfg.scoreexchange do
            local scoreexchange = m_CurrentLotteryCfg.scoreexchange[index]
            if scoreexchange.needscore == score then
                bonus = scoreexchange.bonus
                break          
            end
        end
    else
        print("[ERROR][lotteryfragmentinfo:GetScoreBonus] m_CurrentLotteryCfg nil or m_CurrentLotteryCfg.bonus empty!")
    end
    return bonus
end

local function GetLotteryBonusByIndex(index)
    return (m_CurrentLotteryCfg and index and m_CurrentLotteryCfg.bonus) and m_CurrentLotteryCfg.bonus[index] or nil
end

local function GetLotteryBonusCount()
    return (m_CurrentLotteryCfg and m_CurrentLotteryCfg.bonus) and #m_CurrentLotteryCfg.bonus or 0
end

local function GetTotalScore()
    if m_CurrentLotteryCfg and #m_CurrentLotteryCfg.scoreexchange>0 then
        return m_CurrentLotteryCfg.scoreexchange[#m_CurrentLotteryCfg.scoreexchange].needscore
    else
        return 0
    end
end

local function SyncScoreBonus(msg)
    m_ClaimedScoreList = msg.invalidscore
end

local function IsScoreAwardClaimed(score)
    local result = false
    if score and m_ClaimedScoreList and #m_ClaimedScoreList>0 then
        for _,value in ipairs(m_ClaimedScoreList) do
            if value==score then
                result = true
                break
            end
        end
    end
    return result
end

local function GetCurScore()
    --printyellow("[lotteryfragmentinfo:init] cfg.currency.CurrencyType.LotteryScore=", cfg.currency.CurrencyType.LotteryScore)
    return PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.LotteryScore] or 0
end

local function GetOneDrawCost()
    local onedrawcost
    if m_CurrentLotteryCfg then
        local currency = ItemManager.GetCurrencyData(m_CurrentLotteryCfg.costs)        
        onedrawcost = currency[1]:GetNumber()
        onedrawcost = math.max(onedrawcost, 0)
    end
    return onedrawcost
end

local function GetUsedFreeCount()
    local usedcount = LimitTimeManager.GetDayLimitTime(cfg.cmd.ConfigId.LOTTERY, 0)
    return usedcount and usedcount or 0
end

local function GetVipFreeCount()
	--TODO暂时屏蔽VIP的功能
    local totalfreecount
    if m_CurrentLotteryCfg then
        local viplevel = VipChargeManager.GetCurVipLevel()
        for i,vipfree in ipairs(m_CurrentLotteryCfg.vipfree) do
            if vipfree and vipfree.level==viplevel then
                totalfreecount = vipfree.limit.num
                --printyellow(string.format("[lotteryfragmentinfo:GetLeftFreeCount] viplevel[%s] turntime = [%s]!", viplevel, vipfree.limit.num))
                break
            end
        end    
    end
    return totalfreecount and totalfreecount or 0
	--return 0
end

local function GetLeftFreeCount()
    --used count
    local usedcount = GetUsedFreeCount()

    --total count
    local totalfreecount = GetVipFreeCount()

    --printyellow("[lotteryfragmentinfo:init] left free count=", math.max(0, totalfreecount-usedcount))
    return math.max(0, totalfreecount-usedcount)
end

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
    printyellow("[lotteryfragmentinfo:CompareDateTime] cfgdatetime:")
    printt(cfgdatetime)
    printyellow("[lotteryfragmentinfo:CompareDateTime] localdatetime:")
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
            print("[ERROR][lotteryfragmentinfo:CompareDateTime] cfgdatetime nil!")
        end
        if nil==localdatetime then
            print("[ERROR][lotteryfragmentinfo:CompareDateTime] localdatetime nil!")
        end
    end
    return result    
end

local function IsLotteryOpen(lotterycfg)
 
    if lotterycfg then
        local localdatetime = timeutils.TimeNow()
        if -1==CompareDateTime(lotterycfg.datetime.begintime, localdatetime) and 1==CompareDateTime(lotterycfg.datetime.endtime, localdatetime) then
            --printyellow(string.format("[lotteryfragmentinfo:IsLotteryOpen] lottery [%s] open = true!", lotterycfg.figureshow.petName))
            return true
        else
            --printyellow(string.format("[lotteryfragmentinfo:IsLotteryOpen] lottery [%s] open = false!", lotterycfg.figureshow.petName))
            return false
        end
    else
        print("[ERROR][lotteryfragmentinfo:IsLotteryOpen] lotterycfg nil!")
    end


    --test
    --return true
end

local function UpdateActiveLottery()
    if m_AllLotteryCfgs == nil then
        print("[ERROR][lotteryfragmentinfo:UpdateActiveLottery] m_CurrentLotteryCfg null!")
        m_CurrentLotteryCfg = nil
        return
    else
        --get new lottery
        local newlotterycfg = nil
        for _, lotterycfg in ipairs(m_AllLotteryCfgs) do
            if IsLotteryOpen(lotterycfg) then
                newlotterycfg = lotterycfg
                break
            end
        end

        --set current lottery
        if m_CurrentLotteryCfg == newlotterycfg then
            --printyellow("[lotteryfragmentinfo:UpdateActiveLottery] no cfg updated, current cfg:", m_CurrentLotteryCfg and m_CurrentLotteryCfg.figureshow.petName or nil)
            return
        else
            --printyellow("[lotteryfragmentinfo:UpdateActiveLottery] updated new cfg:", newlotterycfg and newlotterycfg.figureshow.petName or nil)
            --printt(newlotterycfg)
            m_CurrentLotteryCfg = newlotterycfg

            --���³齱����
	        if UIManager.isshow("lottery.lotteryfragment.dlglotteryfragment") then
		        UIManager.refresh("lottery.lotteryfragment.dlglotteryfragment")
	        end
        end
    end
end

local function update()
    --printyellow("[lotteryfragmentinfo:update] update!")
    -- if nil==m_LastUpdateTime or (Time.time-m_LastUpdateTime)>Update_Interval then    
    --     m_LastUpdateTime = Time.time
    --     UpdateActiveLottery()    
    -- end
end

local function OnLogout()
	m_ClaimedScoreList = nil
end

local function init()
    --printyellow("[lotteryfragmentinfo:init] lotteryfragment init!")    

    --get current lottery
    m_AllLotteryCfgs = ConfigManager.getConfig("timelottery")
    m_CurrentLotteryCfg = nil
    if m_AllLotteryCfgs == nil then
        print("[ERROR][lotteryfragmentinfo:init] m_AllLotteryCfgs null!")
    else
        UpdateActiveLottery()
    end
    m_LastUpdateTime = 0

    --score award
    m_ClaimedScoreList = nil

    --others
	gameevent.evt_system_message:add("logout", OnLogout)
	gameevent.evt_update:add(update)
end

return
{
    init=init,
    GetCurrentLottery = GetCurrentLottery,
    GetAllScoreBonus = GetAllScoreBonus,
    GetLotteryBonusCount = GetLotteryBonusCount,
    GetScoreBonus = GetScoreBonus,
    GetLotteryBonusByIndex = GetLotteryBonusByIndex,
    GetCurScore = GetCurScore,  
    GetTotalScore = GetTotalScore,
    SyncScoreBonus = SyncScoreBonus,
    IsScoreAwardClaimed = IsScoreAwardClaimed,
    GetOneDrawCost = GetOneDrawCost,
    GetLeftFreeCount = GetLeftFreeCount,
    GetVipFreeCount = GetVipFreeCount,
}