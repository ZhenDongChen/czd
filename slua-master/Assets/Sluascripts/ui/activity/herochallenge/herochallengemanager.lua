local ConfigManager =require"cfg.configmanager"
local PlayerRole = require("character.playerrole"):Instance()
local ItemManager = require("item.itemmanager")
local MapManager = require("map.mapmanager")
local UIManager = require("uimanager")
local NetWork = require("network")
local MathUtils = require("common.mathutils")
local TeamManager
local CharacterManager
--local DlgDialogBox_Revive = require("ui.common.dlgdialogbox_revive")
local Insert = table.insert

local m_HeroTaskConfig = nil
local m_TaskId = nil

local function GetStageByLevel(level)
    local stage = 0
    local ownLevel = PlayerRole:GetLevel()
    if level then
        ownLevel = level
    end
    local openLevel = m_HeroTaskConfig.openlevel
    local stageLevel = m_HeroTaskConfig.unitylevel
    if ownLevel <openLevel then
        stage = 0
    else
        local curLevel = openLevel
        while(true) do
            if (ownLevel < (curLevel + stageLevel)) then
                stage = curLevel
                break
            end
            curLevel = curLevel + stageLevel
        end
    end
    return openLevel,stage,stageLevel
end

local function GetBonus()
    local rewardList = {}
    local bonus = m_HeroTaskConfig.displaybonus
    for _,id in pairs(bonus) do
        local item = ItemManager.CreateItemBaseById(id)
        Insert(rewardList,item)
    end
    return rewardList
end

local function GetNpcId()
    return m_HeroTaskConfig.npcid   
end

local function GetNpc(mapId,npcId)
    local landscapeId = MapManager.GetLandscapeId(mapId)
    local landscapedata = ConfigManager.getConfig("landscape")
    local npc
    for _, item in pairs(landscapedata) do
        if item.id == landscapeId then
            if item and item.controllers then
                for _, controller in pairs(item.controllers) do
                    if controller and controller.deployments then
                        for _, deployment in pairs(controller.deployments) do
                            if deployment and deployment.npcid then
                                if deployment.npcid == npcId then
                                    npc = { npcid = deployment.npcid, position = deployment.position, orientation = deployment.orientation }
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return npc
end

local function DisplayNpcTalk()
    if TeamManager.IsInTeam() ~= true then
        if (not UIManager.isshow("activity.herochallenge.dlgherotalk") and (not UIManager.isshow("common.dlgdialogbox_revive"))) then
            UIManager.showdialog("activity.herochallenge.dlgherotalk",{npcId = m_HeroTaskConfig.npcid,content = m_HeroTaskConfig.npctalk,callBackFunc = function()
                UIManager.show("common.dlgdialogbox_revive",{type = DlgDialogBox_Revive.AllDlgType.HeroChallengeTeam})   
            end})
        end
    else
        if (TeamManager.IsLeader(PlayerRole:GetId())) then
                UIManager.ShowSingleAlertDlg({content = LocalString.HeroChallenge_NotInSameLevel})
            else
                UIManager.ShowSystemFlyText(LocalString.HeroChallenge_TeamMemberCannotOperate)
            end
    end   
end

local function NavigateToOpenActivity()
    local mapId = m_HeroTaskConfig.mapid
    local npcId = m_HeroTaskConfig.npcid
    local npc = GetNpc(mapId,npcId)
    if npc then
        PlayerRole:navigateTo({
            mapId = mapId,
            navMode = 1,
            targetPos = Vector3(npc.position.x,npc.position.y,npc.position.z),
            roleId = npcId,
            newStopLength = 90,
            callback = DisplayNpcTalk,
        })
    end
end

local function GetCurTaskId()
    return m_TaskId
end

local function GetCurTaskData()
    local taskData = nil
    local openLevel,stage = GetStageByLevel()
    local allTaskData = ConfigManager.getConfig("herotasklib")
    for _,data in pairs(allTaskData) do
        if data.level == stage then
            for _ ,taskInfo in pairs(data.taskinfo) do
                if taskInfo.ident == m_TaskId then
                    taskData = taskInfo
                    break
                end
            end
        end
    end
    return taskData
end

local function GetCurTaskDescription()
    local description = ""    
    local taskData = GetCurTaskData()
    if taskData then
        description = taskData.introduction
    end
    return description
end

local function IsNeedShowNPC(id)
    local result = false
    if PlayerRole:GetMapId() == m_HeroTaskConfig.mapid then
        local taskData = GetCurTaskData()
        if taskData then
            if id == taskData.npcid then
                result = true
            end
        end
    end
    return result
end

local function GetCurTaskNpc()
    local npcId = 0
    local taskData = GetCurTaskData()
    if taskData then
        npcId = taskData.npcid
    end
    return npcId
end

local function GetEctypeDescriptionByType(type)
    return m_HeroTaskConfig.descriptions[type - 1]  
end

local function GetCurTaskEctypeType(ectypeId)
    local type = nil
    local taskData = GetCurTaskData()
    if taskData then
        type = taskData.challengetype
    else
        local openLevel,stage = GetStageByLevel()
        local taskData = ConfigManager.getConfig("herotasklib")
        for _ ,task in pairs(taskData) do
            if task.level == stage then
                for _,info in pairs(task.taskinfo) do
                    if info.ectypeid == ectypeId then
                        type = info.challengetype
                        break
                    end
                end
                break
            end
        end
    end
    return type
end

local function SetCurTaskId(id)
    m_TaskId = id
    if UIManager.isshow("dlguimain") then
        local DlgUIMain_HeroChallenge = require("ui.dlguimain_herochallenge")
        DlgUIMain_HeroChallenge.RefreshHeroTaskPanel()
        DlgUIMain_HeroChallenge.SetHeroTaskPanel(true)
    end
end

local function OnMsg_SSyncNextHeroTask(msg)
    m_TaskId = msg.nexttaskid
    if UIManager.isshow("dlguimain") then
        local DlgUIMain_HeroChallenge = require("ui.dlguimain_herochallenge")
        DlgUIMain_HeroChallenge.RefreshHeroTaskPanel()
    end
end

local function CanOpenTask(npcPos,distance)
    local result = true
    result = false
    return result
end

local function SendOpenHeroTask()
    local message = lx.gs.team.msg.COpenHeroTask({})
    NetWork.send(message)
end

local function ExecuteTask()
    local taskData = GetCurTaskData()
    if taskData then
        local npcId = taskData.npcid
        local mapId = m_HeroTaskConfig.mapid
        local npc = GetNpc(mapId,npcId)
        if npc then
            PlayerRole:navigateTo({
                navMode = 1,
                mapId = mapId,
                targetPos = Vector3(npc.position.x,npc.position.y,npc.position.z),
                roleId = npcId,
                newStopLength = 90,
                callback = function()
                    if CanOpenTask(npc.position,m_HeroTaskConfig.beginreg) == true then
                        UIManager.showdialog("activity.herochallenge.dlgherotalk",{content = taskData.npcdialogue,npcId = npcId,callBackFunc = SendOpenHeroTask})                              
                    end
                end
            })
        end
    end
end

local function OpenTask()
    if TeamManager.IsLeader(PlayerRole:GetId()) then
        local taskData = GetCurTaskData()
        if taskData then
            local npcId = taskData.npcid
            local mapId = m_HeroTaskConfig.mapid
            local npc = GetNpc(mapId,npcId)
            if (mapId == PlayerRole:GetMapId()) and MathUtils.DistanceOfXoY(npc.position,PlayerRole:GetRefPos()) <= m_HeroTaskConfig.beginreg then  --距离在可开启范围内
                if CanOpenTask(npc.position,m_HeroTaskConfig.beginreg) == true then                   
                    UIManager.showdialog("activity.herochallenge.dlgherotalk",{content = taskData.npcdialogue,npcId = npcId,callBackFunc = SendOpenHeroTask})             
                end           
            else
                if TeamManager.GetTeamMemberNum() < 2 then
                    UIManager.ShowSystemFlyText(LocalString.HeroChallenge_NeedOtherMember)
                end
                ExecuteTask()            
            end
        end
    end
end

local function GetMaxBonusCount()
    return m_HeroTaskConfig.maxbonustimes.num
end

local function init()
    TeamManager = require("ui.team.teammanager")
    CharacterManager = require("character.charactermanager")
    m_HeroTaskConfig = ConfigManager.getConfig("herotaskconfig")
    NetWork.add_listeners({
       {"lx.gs.team.msg.SSyncNextHeroTask",OnMsg_SSyncNextHeroTask}, 
    })
end

return
{
    init = init,
    GetStageByLevel = GetStageByLevel,
    GetBonus = GetBonus,
    NavigateToOpenActivity = NavigateToOpenActivity,
    GetNpcId = GetNpcId,
    GetCurTaskId = GetCurTaskId,
    SetCurTaskId = SetCurTaskId,
    GetCurTaskDescription = GetCurTaskDescription,
    OpenTask = OpenTask,
    IsNeedShowNPC = IsNeedShowNPC,
    GetCurTaskNpc = GetCurTaskNpc,
    DisplayNpcTalk = DisplayNpcTalk,
    GetCurTaskEctypeType = GetCurTaskEctypeType,
    GetEctypeDescriptionByType = GetEctypeDescriptionByType,
    GetMaxBonusCount = GetMaxBonusCount,
}