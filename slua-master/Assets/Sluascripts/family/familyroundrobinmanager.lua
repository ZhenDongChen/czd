local ConfigManager = require("cfg.configmanager")
local BonusManager = require("item.bonusmanager")
local Utils = require("common.utils")
local TimeUtils = require("common.timeutils")
local NetWork = require("network")
local UIManager = require("uimanager")
local FamilyManager = require("family.familymanager")
local EctypeManager = require("ectype.ectypemanager")
local ActivityManager = require("ui.activity.activitytipmanager")
local GameEvent = require("gameevent")
local Format = string.format

local m_GroupType   --组别
local m_MatchInfo   --对阵信息
local m_GroupRank = {}  --家族联赛排名
local m_FamilyRank  --家族成员贡献排名
local m_ServerRank  --全服贡献排名
local m_RemainBonus  --剩余未分配奖励
local m_BattleInfo = {}  --战场信息
local m_AnimalInfo = {}  --神兽信息
local m_CurGame     --当前比赛
local m_Data
local m_FirstEnter = true  --刚开启

local function GetRuleByType(type)
    local text = ""
    if type == 1 then
        text = m_Data.decs1
    elseif type == 2 then
        text = m_Data.decs2
    elseif type == 3 then
        text = m_Data.decs3
    elseif type == 4 then
        text = m_Data.decs4
    end
    return text
end

---------------------------------
--获取家族对阵表
---------------------------------
local function GetSchedule()
    return m_MatchInfo
end

local function GetOwnGroup()
    return m_GroupType
end

local function CompareTime(date1,date2)
    local result = false
    if date1.hour > date2.hour then
        result = true
    elseif date1.hour == date2.hour then
        if date1.min >= date2.minute then
            result = true
        end
    end
    return result
end

local function IsInTimePeriod(weekRangeTime)
    local result = false
    local nowTime = TimeUtils.TimeNow()
    if CompareTime(nowTime,weekRangeTime.begintime) == true and CompareTime(nowTime,weekRangeTime.endtime) == false then
        result = true
    end
    return result
end

local function IsInActivityTime(week)
    local result = false
    if week == tonumber(os.date("%w")) then
        for _,weekRangeTime in pairs(m_Data.battletime) do
            if weekRangeTime.begintime.weekday == week then
                result = IsInTimePeriod(weekRangeTime)
                break
            end
        end
    end
    return result
end

local function GetBattleTime(time)
    local curDate = TimeUtils.getDate()
    local dif = time - os.date("%w")
    local day = os.date("%d") + dif
    local timeOfDay   
    for _,weekRangeTime in pairs(m_Data.battletime) do
        if weekRangeTime.begintime.weekday == time then
            timeOfDay = weekRangeTime.begintime
            break
        end
    end
    return Format(LocalString.FamilyRoundRobin_BattleTime,os.date("%Y"),os.date("%m"),day,timeOfDay.hour,timeOfDay.minute)
end

---------------------------------
--获取当前组对应的排名表
---------------------------------
local function GetRankListByGroup(group)
    return m_GroupRank[group]
end

local function GetRankBonus()   
    local allReward = m_Data.familyrankingaward
    Utils.table_sort(allReward,function(a,b)
        return a.id < b.id
    end)
    return allReward
end

---------------------------------
--获取家族成员贡献列表
---------------------------------
local function GetFamilyContributionList()
    return m_FamilyRank
end

local function GetPersonalRewardList()
    local rewardList = m_Data.leaguemvps
    Utils.table_sort(rewardList,function(a,b)
        return a.id < b.id
    end)
    return rewardList
end

---------------------------------
--获取全服个人贡献列表
---------------------------------
local function GetAllContributionList()
    return m_ServerRank
end

local function SetFamilyRank(familyRank)
    m_FamilyRank = {}
    for roleId,familyInfo in pairs(familyRank) do
        familyInfo.roleid = roleId
        table.insert(m_FamilyRank,familyInfo)
    end
    Utils.table_sort(m_FamilyRank,function(a,b)
        if (a.contribute > b.contribute) then
            return true
        end
        return false
    end)
end

local function OnMsg_SFamilyRoundInfo(msg)
    m_GroupType = msg.grouptype
    m_MatchInfo = msg.matchinfo
    m_GroupRank = msg.grouprank
    SetFamilyRank(msg.familyrank)
    m_ServerRank = msg.serverrank
    m_RemainBonus = msg.extrabonus
end

local function OnMsg_SGetFamilyRoundMatchStatus(msg)
    local info = {}
    info.result = msg.result
    info.status1 = msg.status1
    info.status2 = msg.status2
    info.remaintime = msg.remaintime
    info.animal1id = msg.animal1id
    info.animal1level = msg.animal1level
    info.animal2id = msg.animal2id
    info.animal2level = msg.animal2level
    m_AnimalInfo.animal1id = msg.animal1id
    m_AnimalInfo.animal1level = msg.animal1level
    m_AnimalInfo.animal2id = msg.animal2id
    m_AnimalInfo.animal2level = msg.animal2level
    m_BattleInfo[msg.battleid] = info
    local TabFaDetail = require("ui.family.tabfadetail")
    if UIManager.isshow("family.tabfadetail") then
        UIManager.refresh("family.tabfadetail")
    else
        UIManager.showdialog("family.tabfadetail",{type = TabFaDetail.DlgType.RoundRobin})
    end
end

local function GetAnimalInfo()
    return m_AnimalInfo
end

local function GetRoundRobinStatus(battleId)
    return m_BattleInfo[battleId]
end

local function SetCurBattleInfoRemaintime(battleId,remainTime)
    local info = m_BattleInfo[battleId]
    if info then
        info.remaintime = remainTime
    end
end

local function SetCurGame(game)
    m_CurGame = game
end

local function GetCurGame()
    return m_CurGame
end

local function OnMsg_SFamilyRoundDailyEnd(msg)
    m_GroupRank = msg.grouprank
    m_ServerRank = msg.serverrank
end

local function SendCGetFamilyRoundMatchStatus()
    local msg = lx.gs.family.msg.roundmatch.CGetFamilyRoundMatchStatus({})
    NetWork.send(msg)
end

local function SendCEnterFamilyRoundMatch(battleId)
    local msg = lx.gs.family.msg.roundmatch.CEnterFamilyRoundMatch({battleid = battleId})
    NetWork.send(msg)
end

local function OnMsg_SEndFamilyRoundMatchNotify(msg)
    for week,info in pairs(m_MatchInfo) do
        if msg.weekday == week then
            if (FamilyManager.Info().familyid) == info.family1info.fid then
                info.result = msg.result
            else
                info.result = -(msg.result)
            end
        end
    end
    for id,newcontribution in pairs(msg.newcontribute) do
        for _,info in pairs(m_FamilyRank) do
            if info.roleid == id then
                info.contribute = newcontribution
                break
            end
        end
    end
    Utils.table_sort(m_FamilyRank,function(a,b)
        if (a.contribute > b.contribute) then
            return true
        end
        return false
    end)
end

local function SendCGetAllocLog()
    local msg = lx.gs.family.msg.roundmatch.CGetAllocLog({})
    NetWork.send(msg)
end

local function OnMsg_SGetAllocLog(msg)
    if UIManager.isshow("citywar.tabworldterritoryrewarddistribution") then
        UIManager.call("citywar.tabworldterritoryrewarddistribution","refresh", msg)
    end
end

local function OnMsg_SSeasonEnd(msg)
    m_RemainBonus = msg.familyextrabonus
end

local function HasRemainFamilyRoundRobinBonus()
    local bonus
    if m_RemainBonus then
        bonus = BonusManager.GetItemsOfServerBonus(m_RemainBonus)
    end
    return bonus and table.getn(bonus) > 0
end

local function GetRemainBonus()
    return m_RemainBonus
end

local function SendCAllocBonus(roleId,bonus)
    local msg = lx.gs.family.msg.roundmatch.CAllocBonus({memberid = roleId,bonus = bonus})
    NetWork.send(msg)
end

local function OnMsg_SAllocBonus(msg)
    m_RemainBonus = msg.remainbonus
    if UIManager.isshow("citywar.dlgsendawards") then
        UIManager.call("citywar.dlgsendawards","refresh")
    end
end

local function second_update()
    if m_MatchInfo then
        for week,info in pairs(m_MatchInfo) do
            if (week == tonumber(os.date("%w"))) then
                if info.result == -2 then
                    for _,weekRangeTime in pairs(m_Data.battletime) do
                        if weekRangeTime.begintime.weekday == week then   
                            if IsInTimePeriod(weekRangeTime) then
                                if m_FirstEnter == true then
                                    m_FirstEnter = false
                                    if EctypeManager.IsInEctype() ~= true then
                                        UIManager.ShowAlertDlg({immediate = true,content = LocalString.FamilyRoundRobin_IsEnterBattle,callBackFunc = function()
                                            UIManager.showdialog("family.dlgfamilycupwar")
                                        end})
                                    end
                                    ActivityManager.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.FAMILYROUNDROBIN, nil, function()
                                        UIManager.showdialog("family.dlgfamilycupwar")
                                    end)   
                                    if UIManager.isshow("family.dlgfamilycupwar") then
                                        UIManager.refresh("family.dlgfamilycupwar")
                                    end           
                                end
                            else
                                m_FirstEnter = true
                                if (ActivityManager.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.FAMILYROUNDROBIN)) then
                                    ActivityManager.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.FAMILYROUNDROBIN)
                                end
                            end
                        end
                    end
                end
                break
            end
        end
    end
end

local function init()
    m_Data = ConfigManager.getConfig("familyleague")
    GameEvent.evt_second_update:add(second_update)
    NetWork.add_listeners({
        {"lx.gs.family.msg.roundmatch.SFamilyRoundInfo", OnMsg_SFamilyRoundInfo},
        {"lx.gs.family.msg.roundmatch.SGetFamilyRoundMatchStatus",OnMsg_SGetFamilyRoundMatchStatus},
        {"lx.gs.family.msg.roundmatch.SFamilyRoundDailyEnd",OnMsg_SFamilyRoundDailyEnd},
        {"lx.gs.family.msg.roundmatch.SEndFamilyRoundMatchNotify",OnMsg_SEndFamilyRoundMatchNotify},
        {"lx.gs.family.msg.roundmatch.SGetAllocLog",OnMsg_SGetAllocLog},
        {"lx.gs.family.msg.roundmatch.SAllocBonus",OnMsg_SAllocBonus},
        {"lx.gs.family.msg.roundmatch.SSeasonEnd",OnMsg_SSeasonEnd},
    },"familyroundrobinmanager")
end

return
{
    init = init,
    second_update = second_update,
    GetRuleByType = GetRuleByType,
    GetSchedule = GetSchedule,
    GetOwnGroup = GetOwnGroup,
    GetRankListByGroup = GetRankListByGroup,
    GetRankBonus = GetRankBonus,
    GetFamilyContributionList = GetFamilyContributionList,
    GetPersonalRewardList = GetPersonalRewardList,
    GetAllContributionList = GetAllContributionList,
    IsInActivityTime = IsInActivityTime,
    GetBattleTime = GetBattleTime,
    SendCGetFamilyRoundMatchStatus = SendCGetFamilyRoundMatchStatus,
    GetRoundRobinStatus = GetRoundRobinStatus,
    SetCurBattleInfoRemaintime = SetCurBattleInfoRemaintime,
    SetCurGame = SetCurGame,
    GetCurGame = GetCurGame,
    HasRemainFamilyRoundRobinBonus = HasRemainFamilyRoundRobinBonus,
    GetRemainBonus = GetRemainBonus,
    GetAnimalInfo = GetAnimalInfo,
    SendCEnterFamilyRoundMatch = SendCEnterFamilyRoundMatch,
    SendCGetAllocLog = SendCGetAllocLog,
    SendCAllocBonus = SendCAllocBonus,
}