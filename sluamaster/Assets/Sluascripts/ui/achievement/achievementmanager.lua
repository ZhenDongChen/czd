--local achievementmanager = require "ui.achievement.achievementmanager"
local network                   = require "network"
local uimanager                 = require "uimanager"
local gameevent                 = require "gameevent"
local titlemanager              = require "ui.title.titlemanager"


local achievements      = {} --所有成就 achievement.xlsx
local titleevolves      = {} --成就所需点数 titleevolve.xlsx
local allachievement    = {} --所有的成就 --Map(achievementtype,List(achievement))
local allachievementtypename = {} --成就类型名称
local achievementstates = {} --成就状态
local counters          = {} --成就计数

local AchievementStateOrder =
{
    [cfg.achievement.Status.COMPLETED]       = 0,
    [cfg.achievement.Status.NOTCOMPLETED]    = 1,
    [cfg.achievement.Status.GETREWARD]       = 2,
}

--获取成就配置
local function GetAchievementById(achievementid)
    return achievements[achievementid]
end

--获取成就状态
local function GetStateById(achievementid)
    return mathutils.TernaryOperation( achievementstates[achievementid] ,achievementstates[achievementid] ,cfg.achievement.Status.NOTCOMPLETED)
end

--获取成就总计数
local function GetTotalCountById(achievementid)

    local achievenment = GetAchievementById(achievementid)
    if achievenment then
        --printyellow("GetTotalCountById(achievementid)",achievementid,mathutils.TernaryOperation( achievenment.isamount ,achievenment.value ,1))
        return mathutils.TernaryOperation( achievenment.isamount ,achievenment.value ,1)
    end
    return 1
end

local function CanGetReward(achievementtype) 
    return achievementtype ~= cfg.achievement.AchievementType.ARENATITLE and 
           achievementtype ~= cfg.achievement.AchievementType.TEAMFIGHTTITLE and
           not(achievementtype == cfg.achievement.AchievementType.WEALTH and shouldHideVip())
end 



--获取成就当前计数
local function GetCountById(achievementid)
    local achievenment = GetAchievementById(achievementid)
    local state        = GetStateById(achievementid)

    if achievenment then
        local currentcount = mathutils.TernaryOperation( counters[achievenment.type] ,counters[achievenment.type] ,0)
        if state == cfg.achievement.Status.NOTCOMPLETED then
            return mathutils.TernaryOperation( achievenment.isamount ,currentcount ,0)
        else
            return GetTotalCountById(achievementid)
        end
    end
    return 0
end

--获取成就总计数
local function GetTotalSum()
    return getn(achievements)
end

--获得成就进阶所需成就点
local function GetAchievementEvolveNeedValue(titleid)
    if titleevolves[titleid] then return titleevolves[titleid].needvalue.amount end
    return 0
end



--获取成就当前计数
local function GetSum()
    local completednum = 0;
    for id,_ in pairs(achievements) do
        if GetStateById(id) == cfg.achievement.Status.GETREWARD then
            completednum = completednum + 1
        end
    end
    return completednum
end

--获取所有成就
local function GetAllAchievement()
    return allachievement
end

--获取成就类型名称
local function GetAchievementTypeName(achievementtype)
    return allachievementtypename[achievementtype]
end

local function CompareAchievement(a,b)
    if AchievementStateOrder[GetStateById(a.id)] ~= AchievementStateOrder[GetStateById(b.id)] then
        return AchievementStateOrder[GetStateById(a.id)] < AchievementStateOrder[GetStateById(b.id)]
    end
    return a.id<b.id
end


local function RefreshAchievements()
    for _,achievementlist in pairs(allachievement) do
        table.sort(achievementlist,CompareAchievement)
    end

    uimanager.refresh("achievement.tabachievement")
    uimanager.refresh("achievement.tabachievementtitle")
    uimanager.refresh("title.dlgachievementtitle")
    uimanager.RefreshRedDot()
end

local function InitAchievements()
    allachievement = {}
    achievements = ConfigManager.getConfig("achievement")
    titleevolves = ConfigManager.getConfig("titleevolve")
    for _,achievement in pairs(achievements) do
        if allachievement[achievement.achievementtype] == nil then
            allachievement[achievement.achievementtype] = {}
        end
        if allachievementtypename[achievement.achievementtype] == nil then
            allachievementtypename[achievement.achievementtype] = achievement.achievementtypename
        end
        table.insert(allachievement[achievement.achievementtype] ,achievement)
    end
    RefreshAchievements()
    --printyellow("InitAchievements")
    --printt(allachievement)
end


local function CGetReward(achievementid)
    local re = lx.gs.achievement.msg.CGetReward({achievementid = achievementid})
    network.send(re)
end

local function CEvolveTitle(titleid)
    local validate, info = checkcmd.CheckData( { data = titleevolves[titleid], num = 1, showsysteminfo = true })
    if validate then
        local re = lx.gs.achievement.msg.CEvolveTitle({titleid = titleid})
        network.send(re)
    end

end

local function RefreshMoney()
    if uimanager.needrefresh("achievement.tabachievement") then
        uimanager.call("achievement.tabachievement","RefreshMoney")
    end

    if uimanager.needrefresh("achievement.tabachievementtitle") then
        uimanager.call("achievement.tabachievementtitle","RefreshMoney")
    end

end

local function onmsg_SInfo(msg)
    -- printyellow("achievement onmsg_SInfo")
    achievementstates = msg.achievementstates
    counters          = msg.counters
    RefreshAchievements()
end

local function onmsg_SCounterChange(msg)
    counters[msg.countertype] = msg.value
end

local function onmsg_SComplete(msg)
    achievementstates[msg.achievementid] =  cfg.achievement.Status.COMPLETED
    RefreshAchievements()
end

local function onmsg_SGetReward(msg)
    achievementstates[msg.achievementid] =  cfg.achievement.Status.GETREWARD
    uimanager.ShowSystemFlyText(LocalString.DlgAchievement_GetrewardSuccess) --temp code
    RefreshAchievements()
end

local function onmsg_SEvolveTitle(msg)
    uimanager.ShowSystemFlyText(LocalString.DlgAchievement_EvolvetitleSuccess) --temp code
    RefreshAchievements()
    local title = titlemanager.GetTitleById(msg.titleid)
    uimanager.showorrefresh("dlgtweenset",{
        tweenfield = "UIPlayTweens_Achievement",
        fieldparams = {texture = title and title:GetTexturePath() or "" }
    })
end


local function UnRead_Achievement()
    if achievementstates then
        for achievementid,state in pairs(achievementstates) do
            if achievements[achievementid] and CanGetReward(achievements[achievementid].achievementtype) and 
               state == cfg.achievement.Status.COMPLETED then
                return true
            end
        end
    end
    return false
end

local function UnRead_AchievementTitle()
    local titlegroup = titlemanager.GetTitleGroup(cfg.role.TitleType.ACHIEVEMENT)
    if titlegroup then
        local nexttitle                  = titlegroup:GetNextTitle()
        if nexttitle then
            local validate, info = checkcmd.CheckData( { data = titleevolves[nexttitle.m_Id], num = 1, showsysteminfo = false })
            return validate
        end
    end
    return false
end

local function UnRead()
    return UnRead_Achievement() or UnRead_AchievementTitle()
end



local function init()
    InitAchievements()
    network.add_listeners({
        {"lx.gs.achievement.msg.SInfo", onmsg_SInfo},
        {"lx.gs.achievement.msg.SCounterChange", onmsg_SCounterChange},
        {"lx.gs.achievement.msg.SComplete", onmsg_SComplete},
        {"lx.gs.achievement.msg.SGetReward", onmsg_SGetReward},
        {"lx.gs.achievement.msg.SEvolveTitle", onmsg_SEvolveTitle},

    })



end

return {
    init                          = init,
    GetAchievementById            = GetAchievementById,
    GetCountById                  = GetCountById,
    GetTotalCountById             = GetTotalCountById,
    GetStateById                  = GetStateById,
    GetAllAchievement             = GetAllAchievement,
    CGetReward                    = CGetReward,
    CEvolveTitle                  = CEvolveTitle,
    GetTotalSum                   = GetTotalSum,
    GetSum                        = GetSum,
    GetAchievementEvolveNeedValue = GetAchievementEvolveNeedValue,
    RefreshMoney                  = RefreshMoney,
    UnRead                        = UnRead,
    UnRead_Achievement            = UnRead_Achievement,
    UnRead_AchievementTitle       = UnRead_AchievementTitle,
    GetAchievementTypeName        = GetAchievementTypeName,
    CanGetReward                  = CanGetReward,
}
