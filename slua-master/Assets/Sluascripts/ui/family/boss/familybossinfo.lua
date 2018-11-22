local ConfigMgr 	  = require "cfg.configmanager"
local UIManager 		= require("uimanager")
local gameevent         = require "gameevent"
local timeutils         = timeutils

local m_BossTimeCfg
local m_FamilyBossMap
local m_FamilyBossOpenTime --second
local m_FamilyBossChallengeTime --second

local function GetBossInfo(id)
    return m_FamilyBossMap[id]
end

local function SetBossInfo(msg)
    if msg and msg.animal then
        m_FamilyBossMap[msg.animal.animalid] = msg.animal
    end
end

local function update()
    --open time
    if m_FamilyBossOpenTime>0 then
        m_FamilyBossOpenTime = m_FamilyBossOpenTime - Time.deltaTime
        if m_FamilyBossOpenTime < 0 then
            m_FamilyBossOpenTime = 0
        end
    end
    
    --challenge time
    if m_FamilyBossChallengeTime>0 then
        m_FamilyBossChallengeTime = m_FamilyBossChallengeTime - Time.deltaTime
        if m_FamilyBossChallengeTime < 0 then
            m_FamilyBossChallengeTime = 0
        end
    end
end

local function GetBossOpenTime()
    if m_FamilyBossOpenTime>=0 then
        return m_FamilyBossOpenTime
    else
        return 0
    end
end

local function SetFamilyBossTime(msg)
    --challenge time
    if msg.family.godanimalstarttime>0 then
        m_FamilyBossOpenTime = msg.family.godanimalstarttime/1000 - timeutils.GetServerTime()
    else
        m_FamilyBossOpenTime = 0
    end

    --challenge time
    if msg.family.godanimalendtime>0 then
        m_FamilyBossChallengeTime = msg.family.godanimalendtime/1000 - timeutils.GetServerTime()
    else
        m_FamilyBossChallengeTime = 0
    end
    --printyellow(string.format("[FamilyBossInfo:SetFamilyBossTime] msg.family.godanimalstarttime=%s, msg.family.godanimalendtime=%s!", msg.family.godanimalstarttime, msg.family.godanimalendtime))  
    --printyellow(string.format("[FamilyBossInfo:SetFamilyBossTime] msg.family.godanimalstarttime=%s, msg.family.godanimalendtime=%s!", timeutils.TimeStr(msg.family.godanimalstarttime), timeutils.TimeStr(msg.family.godanimalendtime)))    
    --printyellow(string.format("[FamilyBossInfo:SetFamilyBossTime] m_FamilyBossOpenTime=%s, m_FamilyBossChallengeTime=%s!",timeutils.getDateTimeString(m_FamilyBossOpenTime, "dd�� hh:mm:ss"), timeutils.getDateTimeString(m_FamilyBossChallengeTime, "dd�� hh:mm:ss")))    
end

local function SetFamilyBossInfo(msg)
    m_FamilyBossMap = msg.activity.godanimalinfo
end

local function SetBossOpenTime(opentime)
    --m_FamilyBossOpenTime = msg.starttime/1000
    m_FamilyBossOpenTime = opentime/1000 - timeutils.GetServerTime()
    --printyellow(string.format("[FamilyBossInfo:SetBossOpenTime] m_FamilyBossOpenTime=%s, opentime=%s!",timeutils.getDateTimeString(m_FamilyBossOpenTime, "dd�� hh:mm:ss"), timeutils.TimeStr(opentime/1000)))    
end

local function GetBossChallengeTime()
    if m_FamilyBossChallengeTime>=0 then
        return m_FamilyBossChallengeTime
    else
        return 0
    end
end

local function SetBossChallengeTime(value)
    --printyellow(string.format("[FamilyBossInfo:SetBossChallengeTime] set m_FamilyBossChallengeTime=%s!", value))
    m_FamilyBossChallengeTime = value
end

local function IsBetweenInterval(timenow, opentime, battletime)
    local result = false
    if timenow and opentime and battletime then
        local curweekday = timenow.wday
        --sunday is the first day
        if curweekday == 1 then
            curweekday = 7
        else
            curweekday = curweekday -1
        end

        if curweekday ==opentime.day then
            local starttime = opentime.hour*60*60 + opentime.minute*60
            local endtime = starttime + battletime
            local curtime = timenow.hour*60*60 + timenow.min*60 + timenow.sec
            return curtime>=starttime and curtime<=endtime
        end
    end
    return result
end

local function CanChallenge()
    local result = false
    if m_BossTimeCfg then
        local timenow = timeutils.TimeNow()
        --printyellow(string.format("[FamilyBossInfo:CanChallenge] get servertime:[%s].", dump_table(timenow) ))
        if m_BossTimeCfg.opentime and table.getn(m_BossTimeCfg.opentime)>0 then
            for index,opentime in ipairs(m_BossTimeCfg.opentime) do
                if IsBetweenInterval(timenow, opentime, m_BossTimeCfg.battletime) then
                    result = true
                    --printyellow(string.format("[FamilyBossInfo:CanChallenge] boss [%s] is open.", index))
                    break
                end
            end
        else
            print("[FamilyBossInfo:CanChallenge] m_BossTimeCfg.opentime empty!") 
        end
    else
        print("[FamilyBossInfo:CanChallenge] bossconfig nil, return true!") 
        result = true
    end
    return result
end

local function init()
    --printyellow("[FamilyBossInfo:init] TournamentInfo init!")    
	gameevent.evt_update:add(update)
    
    m_BossTimeCfg  = ConfigManager.getConfig("bossconfig")
    if m_BossTimeCfg == nil then
        print("[ERROR][FamilyBossInfo:init] m_BossTimeCfg null!")
    end

    m_FamilyBossOpenTime = 0
    m_FamilyBossChallengeTime = 0
end

return
{
    init=init,
    SetFamilyBossInfo = SetFamilyBossInfo,
    SetFamilyBossTime = SetFamilyBossTime,
    SetBossOpenTime = SetBossOpenTime,
    SetBossInfo = SetBossInfo,
    
    GetBossInfo = GetBossInfo,
    GetBossOpenTime = GetBossOpenTime,
    GetBossChallengeTime = GetBossChallengeTime,
    SetBossChallengeTime = SetBossChallengeTime,
    CanChallenge = CanChallenge,
}