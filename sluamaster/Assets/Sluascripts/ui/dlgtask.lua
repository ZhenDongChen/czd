local unpack = unpack
local print = print
local format = string.format
local EventHelper = UIEventListenerHelper
local uimanager = require "uimanager"
local configmanager = require "cfg.configmanager"
local network = require "network"
local BonusManager = require("item.bonusmanager")
--local EctypeDlgManager   = require "ui.ectype.storyectype.ectypedlgmanager"
local ItemManager        = require "item.itemmanager"
local VipChargeManager   = require "ui.vipcharge.vipchargemanager"

local create_datastream = create_datastream

local gameObject
local name

local fields

local taskmanager = require "taskmanager"
local charactermanager = require "character.charactermanager"
local itemmanager = require "item.itemmanager"
local PlayerRole = require "character.playerrole"

local defineenum = require "defineenum"
local TaskType   = defineenum.TaskType
local TaskStatusType = defineenum.TaskStatusType

local SetTargetCtrl
local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")


local UILabel_AcceptNum = nil
local UILabel_Description = nil
local UILabel_Target = nil
local UIButton_Quit = nil
local UIButton_Go = nil
local UILabel_Go = nil
local UIList_Task = nil
local UIList_Reward = nil
local UIWidget_Check = nil

local curSelectedTask = nil

local listTaskMap = {}

local isScenarioMode = true
local acceptTaskNum = 0

local refreshIntervalTime = 0.0

-- 最大接取任务数量
local MAX_ACCEPT_TASK_NUM = 6


local function GetRewardData(index)
    local itmeTable = {}
    local player = PlayerRole:Instance()
    local lv =  player.m_Level
    local configData = configmanager.getConfigData("familytaskspecreward",lv).specbonuslist[index+1].bonus
    return configData
end  

local function SetFamilyTaskWeekCountProgress()
    local totalLength  = fields.UISlider_Completeness:GetComponent("UISprite").width

    if taskmanager.GetWeekFinishedFamilyTaskCount() == 0 then
        fields.UISprite_Foreground.gameObject:SetActive(false)
    else
        fields.UISprite_Foreground.gameObject:SetActive(true)
    end

    local curLength    = totalLength *(taskmanager.GetWeekFinishedFamilyTaskCount()/taskmanager.GetWeekSpecialRewardFamilyTaskCount())
    if curLength > totalLength then
        curLength = totalLength
    end

    fields.UISprite_Foreground:GetComponent("UISprite").width = curLength
    fields.UILabel_Times.text = taskmanager.GetWeekFinishedFamilyTaskCount()
end


local function UpdateFamilyTaskCaseStatus()
    if isScenarioMode then
        return
    end

    local finishedCount = taskmanager.GetWeekFinishedFamilyTaskCount()
    if finishedCount >= 20 then 
        local item = fields.UIList_StarAmount:GetItemByIndex(0)
        item.Controls["UITexture_Case1"].gameObject:SetActive(true)
        item.Controls["UITexture_Case1"].shader = activeShader
        item.Controls["UITexture_Grey1"].gameObject:SetActive(false)
        item.Controls["UIGroup_Tween_Play_01"].gameObject:SetActive(true)
        if taskmanager.IsGetFamilyWeekSpecialReward(0) then 
            item.Controls["UITexture_Grey1"].shader = inactiveShader
            item.Controls["UITexture_Case1"].gameObject:SetActive(false)
            item.Controls["UITexture_Grey1"].gameObject:SetActive(true)
            item.Controls["UIGroup_Tween_Play_01"].gameObject:SetActive(false)
        end
    else
        local item = fields.UIList_StarAmount:GetItemByIndex(0)
        item.Controls["UITexture_Case1"].gameObject:SetActive(false)
        item.Controls["UITexture_Grey1"].gameObject:SetActive(true)
        item.Controls["UIGroup_Tween_Play_01"].gameObject:SetActive(false)
    end

    if finishedCount >= 40 then 
        local item = fields.UIList_StarAmount:GetItemByIndex(1)
        item.Controls["UITexture_Case2"].gameObject:SetActive(true)
        item.Controls["UITexture_Case2"].shader = activeShader
        item.Controls["UITexture_Grey2"].gameObject:SetActive(false)
        item.Controls["UIGroup_Tween_Play_02"].gameObject:SetActive(true)
        if  taskmanager.IsGetFamilyWeekSpecialReward(1) then 
            item.Controls["UITexture_Grey2"].shader = inactiveShader
            item.Controls["UITexture_Case2"].gameObject:SetActive(false)
            item.Controls["UITexture_Grey2"].gameObject:SetActive(true)
            item.Controls["UIGroup_Tween_Play_02"].gameObject:SetActive(false)
        end
    else
        local item = fields.UIList_StarAmount:GetItemByIndex(1)
        item.Controls["UITexture_Case2"].gameObject:SetActive(false)
        item.Controls["UITexture_Grey2"].gameObject:SetActive(true)
        item.Controls["UIGroup_Tween_Play_02"].gameObject:SetActive(false)
    end

    if finishedCount >= 70 then 
        local item = fields.UIList_StarAmount:GetItemByIndex(2)
        item.Controls["UITexture_Case3"].gameObject:SetActive(true)
        item.Controls["UITexture_Case3"].shader = activeShader
        item.Controls["UITexture_Grey3"].gameObject:SetActive(false)
        item.Controls["UIGroup_Tween_Play_03"].gameObject:SetActive(true)
        if taskmanager.IsGetFamilyWeekSpecialReward(2) then 
            item.Controls["UITexture_Grey3"].shader = inactiveShader
            item.Controls["UITexture_Case3"].gameObject:SetActive(false)
            item.Controls["UITexture_Grey3"].gameObject:SetActive(true)
            item.Controls["UIGroup_Tween_Play_03"].gameObject:SetActive(false)
        end
    else
        local item = fields.UIList_StarAmount:GetItemByIndex(2)
        item.Controls["UITexture_Case3"].gameObject:SetActive(false)
        item.Controls["UITexture_Grey3"].gameObject:SetActive(true)
        item.Controls["UIGroup_Tween_Play_03"].gameObject:SetActive(false)
    end
end

-- 任务目标
local function ShowTaskDestion(task, taskStatus)
    UILabel_Target.text = ""
    if task and taskStatus then
        if taskStatus == TaskStatusType.None or taskStatus == TaskStatusType.Accepted then
            local npc = nil
            if isScenarioMode then
                npc = taskmanager.GetNpcData(task.accept.npcid)
            else
                npc = taskmanager.GetNpcData(taskmanager.GetFamilyNPC(task.id,true))
            end

            if npc and npc.name then
                UILabel_Target.text = LocalString.Task_FindNPC .."[FF6600]" .. npc.name .. "[-]" .. LocalString.Task_AcceptTask
            else
                UILabel_Target.text = "   "..LocalString.Task_CompleteTask
            end
        elseif taskStatus == TaskStatusType.Doing then
            local desc = ""
            -- 杀怪
            local killMonsterDesc = taskmanager.GetKilledMonsterDesc(task, taskStatus)
            if killMonsterDesc and string.len(killMonsterDesc) > 0  then
                desc = "   " .. killMonsterDesc
            end

            -- 采矿
            local digMineDesc = taskmanager.GetDiggedMineDesc(task, taskStatus)
            if digMineDesc and string.len(digMineDesc) > 0 then
                if desc == "" then
                    desc = "   " .. digMineDesc
                else
                    desc = desc .. "\n   " .. digMineDesc
                end
            end

            -- 其他事件
            for _, item in pairs(task.complete.finishspecialevent) do
                if item then
                    local eventDesc = ""
                    if item.eventtype == cfg.task.EFinishSpecialEventType.USING_SKILL then
                        eventDesc = LocalString.Task_UseSkill
                    elseif item.eventtype == cfg.task.EFinishSpecialEventType.PLAYING_CG then
                        eventDesc = LocalString.Task_PlayCG
                    elseif item.eventtype == cfg.task.EFinishSpecialEventType.DOING_ECTYPE then
                        eventDesc = LocalString.Task_CompleteEctype
                    end

                    if desc == "" then
                        desc = "   " .. eventDesc
                    else
                        desc = desc .. "\n   " .. eventDesc
                    end
                end
            end

            -- 到达指定地点
            if task.complete.location.worldmapid > 0  then
                local mapInfo = configmanager.getConfigData("worldmap",task.complete.location.worldmapid)
                if mapInfo.scenename ~= nil and mapInfo.scenename ~= "" then
                    local locationDesc = LocalString.Task_GoToLocation ..":" .. mapInfo.mapname .. LocalString.Task_Map
                    locationDesc = locationDesc .. " "..LocalString.Task_Min.."(" .. task.complete.location.minx .. ",".. task.complete.location.miny .. "),"
                    locationDesc = locationDesc .. " "..LocalString.Task_Max.."(" .. task.complete.location.maxx .. ",".. task.complete.location.maxy .. ")"

                    if desc == "" then
                        desc = "   " .. locationDesc
                    else
                        desc = desc .. "\n   " .. locationDesc
                    end
                end
            end

            -- 护送NPC
            if task.complete.npclocation.worldmapid > 0  then
                local mapInfo = configmanager.getConfigData("worldmap",task.complete.npclocation.worldmapid)
                if mapInfo.scenename ~= nil and mapInfo.scenename ~= "" then
                    local locationDesc = LocalString.Task_GoToNPCLocation ..":"  .. mapInfo.mapname .. LocalString.Task_Map
                    locationDesc = locationDesc .. " "..LocalString.Task_Min.."(" .. task.complete.npclocation.minx .. ",".. task.complete.npclocation.miny .. "),"
                    locationDesc = locationDesc .. " "..LocalString.Task_Max.."(" .. task.complete.npclocation.maxx .. ",".. task.complete.npclocation.maxy .. ")"

                    if desc == "" then
                        desc = "   " .. locationDesc
                    else
                        desc = desc .. "\n   " .. locationDesc
                    end
                end
            end
            if string.len(desc) > 0 then
                UILabel_Target.text = desc
            else
                UILabel_Target.text = "   "..LocalString.Task_CompleteTask
            end
        elseif taskStatus == TaskStatusType.UnCommitted then
            local npc = taskmanager.GetNpcData(task.complete.npcid)
            if npc and npc.name then
                UILabel_Target.text = LocalString.Task_FindNPC .."[FF6600]" .. npc.name .. "[-]" .. LocalString.Task_CommitTask
            else
                UILabel_Target.text = "   "..LocalString.Task_CompleteTask
            end
        elseif taskStatus == TaskStatusType.Completed then
            UILabel_Target.text = LocalString.Task_Finished
        end
    end
end

-- 任务奖励
local function ShowTaskReward(task)
    UIList_Reward:Clear()
    if task and task.reward then
        if task.basic.tasktype == TaskType.Family then
            local familyReward = configmanager.getConfig("familytaskreward")
            local familyConfig = configmanager.getConfig("familytaskconfig")
            local roleLevel = PlayerRole:Instance().m_RealLevel
            local levelReward = familyReward[roleLevel]
            local curRingCount = taskmanager.GetFamilyTaskRingCount()

            local curGroupCount = math.ceil(taskmanager.GetDayFinishedFamilyTaskCount() / taskmanager.GetMaxFamilyTaskRingCount())
            if curGroupCount == 0 then
                curGroupCount = 1
            elseif curGroupCount * taskmanager.GetMaxFamilyTaskRingCount() == taskmanager.GetDayFinishedFamilyTaskCount() then
                curGroupCount = curGroupCount + 1
            end

            if familyConfig and levelReward and curRingCount > 0 and familyConfig.taskbonusrate[curRingCount] and familyConfig.circlebonusrate[curGroupCount] then
                local rate = familyConfig.taskbonusrate[curRingCount] * familyConfig.circlebonusrate[curGroupCount]
                -- exp
                local itemdata = itemmanager.GetItemData(cfg.currency.CurrencyType.JingYan)
                if itemdata then
                    local listitem = UIList_Reward:AddListItem()
                    local labelAmount = listitem.Controls["UILabel_Amount"]
                    labelAmount.gameObject:SetActive(true)
                    labelAmount.text = tostring( math.floor(rate * levelReward.exp))
                    local itemtex = listitem.Controls["UITexture_Icon"]
                    if itemtex then
                        itemtex:SetIconTexture(itemdata.icon)
                    end
                    local iconUnknow = listitem.Controls["UISprite_Unknow"]
                    if iconUnknow then
                        iconUnknow.gameObject:SetActive(false)
                    end
                end

                -- 金币
                itemdata = itemmanager.GetItemData(cfg.currency.CurrencyType.XuNiBi)
                if itemdata then
                    local listitem = UIList_Reward:AddListItem()
                    local labelAmount = listitem.Controls["UILabel_Amount"]
                    labelAmount.gameObject:SetActive(true)
                    labelAmount.text = tostring( math.floor(rate * levelReward.gold))
                    local itemtex = listitem.Controls["UITexture_Icon"]
                    if itemtex then
                        itemtex:SetIconTexture(itemdata.icon)
                    end
                    local iconUnknow = listitem.Controls["UISprite_Unknow"]
                    if iconUnknow then
                        iconUnknow.gameObject:SetActive(false)
                    end
                end
            end
        else
            -- exp
            if task.reward.exp > 0 then
                local itemdata = itemmanager.GetItemData(cfg.currency.CurrencyType.JingYan)
                if itemdata then
                    local listitem = UIList_Reward:AddListItem()
                    local labelAmount = listitem.Controls["UILabel_Amount"]
                    labelAmount.gameObject:SetActive(true)
                    labelAmount.text = tostring(task.reward.exp)
                    local itemtex = listitem.Controls["UITexture_Icon"]
                    if itemtex then
                        itemtex:SetIconTexture(itemdata.icon)
                    end
                    local iconUnknow = listitem.Controls["UISprite_Unknow"]
                    if iconUnknow then
                        iconUnknow.gameObject:SetActive(false)
                    end
                end
            end

            -- 金币
            if task.reward.money > 0 then
                local itemdata = itemmanager.GetItemData(cfg.currency.CurrencyType.XuNiBi)
                if itemdata then
                    local listitem = UIList_Reward:AddListItem()
                    local labelAmount = listitem.Controls["UILabel_Amount"]
                    labelAmount.gameObject:SetActive(true)
                    labelAmount.text = tostring(task.reward.money)
                    local itemtex = listitem.Controls["UITexture_Icon"]
                    if itemtex then
                        itemtex:SetIconTexture(itemdata.icon)
                    end
                    local iconUnknow = listitem.Controls["UISprite_Unknow"]
                    if iconUnknow then
                        iconUnknow.gameObject:SetActive(false)
                    end
                end
            end

            -- 元宝
            if task.reward.ingot > 0 then
                local itemdata = itemmanager.GetItemData(cfg.currency.CurrencyType.YuanBao)
                if itemdata then
                    local listitem = UIList_Reward:AddListItem()
                    local labelAmount = listitem.Controls["UILabel_Amount"]
                    labelAmount.gameObject:SetActive(true)
                    labelAmount.text = tostring(task.reward.ingot)
                    local itemtex = listitem.Controls["UITexture_Icon"]
                    if itemtex then
                        itemtex:SetIconTexture(itemdata.icon)
                    end

                    local iconUnknow = listitem.Controls["UISprite_Unknow"]
                    if iconUnknow then
                        iconUnknow.gameObject:SetActive(false)
                    end
                end
            end

            -- 奖励物品
            if task.reward.rewarditem and table.getn(task.reward.rewarditem.itemid) > 0 then
                local len = table.getn(task.reward.rewarditem.itemid)
                for i = 1, len do
                    local id = task.reward.rewarditem.itemid[i]
                    local count = task.reward.rewarditem.itemcount[i]
                    if id > 0 and count > 0 then
                        local itemdata = itemmanager.GetItemData(id)
                        if itemdata then
                            local listitem = UIList_Reward:AddListItem()
                            local labelAmount = listitem.Controls["UILabel_Amount"]
                            labelAmount.gameObject:SetActive(true)
                            labelAmount.text = tostring(count)
                            local itemtex = listitem.Controls["UITexture_Icon"]
                            if itemtex then
                                itemtex:SetIconTexture(itemdata.icon)
                            end

                            local spriteQuality = listitem.Controls["UISprite_Quality"]
                            if spriteQuality then
                                spriteQuality.spriteName = colorutil.GetQualitySprite(itemdata.quality)
                            end

                            local iconUnknow = listitem.Controls["UISprite_Unknow"]
                            if len > 1 then
                                iconUnknow.gameObject:SetActive(true)
                            else
                                iconUnknow.gameObject:SetActive(false)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function ShowSelectedItemInfo(task, listitem)
    if task and listitem then
        local taskStatus = taskmanager.GetTaskStatus(task.id)

        listitem:SetText("UILabel_Text", "  " .. task.basic.name)
        if taskStatus == TaskStatusType.None then
            UILabel_Description.text = taskmanager.ReplaceWildcard(task.basic.hints.unacceptedhint)
        else
            UILabel_Description.text = taskmanager.ReplaceWildcard(task.basic.hints.acceptedhint)
        end

        local getRewardSprit = listitem.Controls["UISprite_GetReward"]
        if getRewardSprit then
            if taskStatus == TaskStatusType.UnCommitted then
                getRewardSprit.gameObject:SetActive(true)
            else
                getRewardSprit.gameObject:SetActive(false)
            end
        else
        end

        if taskStatus == TaskStatusType.UnCommitted then
            UILabel_Go.text = LocalString.Task_GetReward
        else
            UILabel_Go.text = LocalString.Task_Go
        end

        ShowTaskDestion(task, taskStatus)
        ShowTaskReward(task)
    end
end

local function ShowScenarioTaskList()
    local itemcount = 0
    -- 主线
    local mainlineTask = taskmanager.GetCurTask(TaskType.Mainline)
    local mainlineTaskStatus = TaskStatusType.None
    local mainlineTaskItem = nil
    if mainlineTask then
        mainlineTaskStatus = taskmanager.GetTaskStatus(mainlineTask.id)
        mainlineTaskItem = UIList_Task:GetItemByIndex(itemcount)
        if mainlineTaskItem == nil then
            mainlineTaskItem = UIList_Task:AddListItem()
        end
        mainlineTaskItem:SetText("UILabel_Text", "  " .. mainlineTask.basic.name)

        local getRewardSprit = mainlineTaskItem.Controls["UISprite_GetReward"]
        if getRewardSprit then
            if mainlineTaskStatus == TaskStatusType.UnCommitted then
                getRewardSprit.gameObject:SetActive(true)
            else
                getRewardSprit.gameObject:SetActive(false)
            end
        end

        local mainlineSprite = mainlineTaskItem.Controls["UISprite_TypeIconMain"]
        if mainlineSprite then
            mainlineSprite.gameObject:SetActive(true)
        end

        local branchSprite = mainlineTaskItem.Controls["UISprite_TypeIconBranch"]
        if branchSprite then
            branchSprite.gameObject:SetActive(false)
        end

        itemcount = itemcount + 1
        listTaskMap[itemcount] = mainlineTask.id
        if mainlineTaskStatus ~= TaskStatusType.None then
            acceptTaskNum = acceptTaskNum + 1
        end
    end

    -- 已接取支线
    local allDoingBranchTask = taskmanager.GetCurTask(TaskType.Branch)
    if allDoingBranchTask and next(allDoingBranchTask) ~= nil then
        for id, branchTask in pairs(allDoingBranchTask) do
            if branchTask then
                local status = taskmanager.GetTaskStatus(branchTask.id)
                if status ~= TaskStatusType.None then
                    acceptTaskNum = acceptTaskNum + 1
                    local branchTaskItem = UIList_Task:GetItemByIndex(itemcount)
                    if branchTaskItem == nil then
                        branchTaskItem = UIList_Task:AddListItem()
                    end
                    branchTaskItem:SetText("UILabel_Text", "  " .. branchTask.basic.name)

                    local getRewardSprit = branchTaskItem.Controls["UISprite_GetReward"]
                    if getRewardSprit then
                        if status == TaskStatusType.UnCommitted then
                            getRewardSprit.gameObject:SetActive(true)
                        else
                            getRewardSprit.gameObject:SetActive(false)
                        end
                    end

                    local mainlineSprite = branchTaskItem.Controls["UISprite_TypeIconMain"]
                    if mainlineSprite then
                        mainlineSprite.gameObject:SetActive(false)
                    end

                    local branchSprite = branchTaskItem.Controls["UISprite_TypeIconBranch"]
                    if branchSprite then
                        branchSprite.gameObject:SetActive(true)
                    end

                    itemcount = itemcount + 1
                    listTaskMap[itemcount] = branchTask.id
                end
            end
        end
    end


    -- 达到接取条件但尚未接取的支线任务
    local canAcceptBranchTask = taskmanager.GetCanAcceptTask(TaskType.Branch)
    if canAcceptBranchTask and next(canAcceptBranchTask) ~= nil then
        for _, id in pairs(canAcceptBranchTask) do
            local branchTask = taskmanager.GetTask(id)
            if branchTask then
                local branchTaskItem = UIList_Task:GetItemByIndex(itemcount)
                if branchTaskItem == nil then
                     branchTaskItem = UIList_Task:AddListItem()
                end
                branchTaskItem:SetText("UILabel_Text", "  " .. branchTask.basic.name)

                local getRewardSprit = branchTaskItem.Controls["UISprite_GetReward"]
                if getRewardSprit then
                    getRewardSprit.gameObject:SetActive(false)
                end

                local mainlineSprite = branchTaskItem.Controls["UISprite_TypeIconMain"]
                if mainlineSprite then
                    mainlineSprite.gameObject:SetActive(false)
                end

                local branchSprite = branchTaskItem.Controls["UISprite_TypeIconBranch"]
                if branchSprite then
                    branchSprite.gameObject:SetActive(true)
                end

                itemcount = itemcount + 1
                listTaskMap[itemcount] = branchTask.id
            end
        end
    end

    local otherItem = UIList_Task:GetItemByIndex(itemcount)
    while otherItem do
        UIList_Task:DelListItem(otherItem)
        otherItem = UIList_Task:GetItemByIndex(itemcount)
    end

    UILabel_AcceptNum.text = LocalString.Task_AcceptTaskNum .. "：" .. acceptTaskNum .. "/" .. MAX_ACCEPT_TASK_NUM

    -- 默认展示主线内容
    if mainlineTaskItem then
        if curSelectedTask == nil then
            curSelectedTask = mainlineTask
            UIList_Task:SetSelectedIndex(0)
            ShowSelectedItemInfo(curSelectedTask, mainlineTaskItem)
        else
            for index,id in pairs(listTaskMap) do
                if id == curSelectedTask.id then
                    UIList_Task:SetSelectedIndex(index-1)
                    ShowSelectedItemInfo(curSelectedTask, UIList_Task:GetItemByIndex(index-1))
                    break
                end
            end
        end
    end
end

local function ShowClanTaskList()
    local itemcount = 0
    local familyTask = taskmanager.GetCurTask(TaskType.Family)
    local familyTaskStatus = TaskStatusType.None
    local familyTaskItem = nil
    if familyTask and taskmanager.GetDayFinishedFamilyTaskCount() < taskmanager.GetMaxDayFamilyTaskCount() then
        familyTaskStatus = taskmanager.GetTaskStatus(familyTask.id)
        familyTaskItem = UIList_Task:GetItemByIndex(itemcount)
        if familyTaskItem == nil then
            familyTaskItem = UIList_Task:AddListItem()
        end
        familyTaskItem:SetText("UILabel_Text", "  " .. familyTask.basic.name)
        itemcount = itemcount + 1
        listTaskMap[itemcount] = familyTask.id
        if taskmanager.GetDayFinishedFamilyTaskCount() ~= 0  and taskmanager.GetDayFinishedFamilyTaskCount() < taskmanager.GetClearFamilyTaskRingCount() then
            fields.UIButton_ClanClear.gameObject:SetActive(true)
        else
            fields.UIButton_ClanClear.gameObject:SetActive(false)
        end

        fields.UIButton_ClanFinished.gameObject:SetActive(true)

        UIButton_Quit.gameObject:SetActive(true)

        local curOrder = taskmanager.GetFamilyTaskRingCount()
        UILabel_AcceptNum.text = LocalString.Task_FamilyTask .."："..curOrder.."/"..taskmanager.GetMaxFamilyTaskRingCount()

        curSelectedTask = familyTask
        UIList_Task:SetSelectedIndex(0)
        ShowSelectedItemInfo(curSelectedTask, familyTaskItem)
    else
        local listItem = UIList_Task:GetItemByIndex(0)
        if listItem then
            UIList_Task:DelListItem(listItem)
        end

        UILabel_Description.text = LocalString.Task_AcceptFamilyTask
        UILabel_Target.text = LocalString.Task_TalkWithFamilyNPC
        UILabel_Go.text = LocalString.Task_Go

        UIList_Reward:Clear()

        fields.UIButton_ClanClear.gameObject:SetActive(false)
        fields.UIButton_ClanFinished.gameObject:SetActive(false)
        UIButton_Quit.gameObject:SetActive(false)

        UILabel_AcceptNum.text = LocalString.Task_FamilyTask .."：0/"..taskmanager.GetMaxFamilyTaskRingCount()

        if taskmanager.GetDayFinishedFamilyTaskCount() == taskmanager.GetMaxDayFamilyTaskCount() then
            UILabel_Description.text = LocalString.Task_FinishCountLimit
            UILabel_Target.text =  ""
        end
    end

    UIButton_Go.isEnabled = true

    SetFamilyTaskWeekCountProgress()
    UpdateFamilyTaskCaseStatus()
end


local function ShowTaskInfo()
    listTaskMap = {}
    acceptTaskNum = 0
    if isScenarioMode then
        if UIWidget_Check then
            UIWidget_Check.gameObject:SetActive(false)
        end
        ShowScenarioTaskList()
    else
        ShowClanTaskList()
    end
end

local function RefreshCurrency()
    local player = PlayerRole:Instance()
	local currencyType = cfg.currency.CurrencyType
	fields.UILabel_Gold.text = player.m_Currencys[currencyType.XuNiBi] or 0
	fields.UILabel_Diamond.text = player.m_Currencys[currencyType.YuanBao] or 0
	fields.UILabel_BindingDiamond.text = player.m_Currencys[currencyType.BindYuanBao] or 0

	local max_TiLi = configmanager.getConfig("roleconfig").maxtili                      --最大体力
	local cur_TiLi = player.m_Currencys[currencyType.TiLi] or 0                         --当前体力

	local percent = cur_TiLi/max_TiLi

	if percent > 1 then percent = 1 end
	fields.UILabel_Energy.text = cur_TiLi .. "/".. max_TiLi
end

local function destroy()
   
end

local function show(params)
    isScenarioMode = true
    local familymgr = require("family.familymanager")
    if PlayerRole:Instance().m_RealLevel < taskmanager.GetFamilyTaskOpenLevel() or familymgr.InFamily() == false then
        UITools.SetButtonEnabled(fields.UIButton_Clan, false)
        fields.UISprite_Lock.gameObject:SetActive(true)
    else    
        fields.UISprite_Lock.gameObject:SetActive(false)
        UITools.SetButtonEnabled(fields.UIButton_Clan,true)
    end

    if  params and params.isShowFamilyInfo  then 
        fields.UIGroup_Clan.gameObject:SetActive(true) 
        fields.UIGroup_Scenario.gameObject:SetActive(false)
        fields.UIButton_Scenario.gameObject.transform:Find("Scenario_Animation").gameObject:SetActive(false)
        fields.UIButton_Clan.gameObject.transform:Find("Clan_Animation").gameObject:SetActive(true)
        isScenarioMode = false
    else
        fields.UIGroup_Clan.gameObject:SetActive(false) 
        fields.UIGroup_Scenario.gameObject:SetActive(true)
        fields.UIButton_Scenario.gameObject.transform:Find("Scenario_Animation").gameObject:SetActive(true)
        fields.UIButton_Clan.gameObject.transform:Find("Clan_Animation").gameObject:SetActive(false)
        isScenarioMode = true
    end
    
    SetTargetCtrl(isScenarioMode)
    fields.UISprite_Buy1.gameObject:SetActive(isScenarioMode)
    fields.UISprite_Sell1.gameObject:SetActive(not isScenarioMode)
    curSelectedTask = nil
    ShowTaskInfo()
end

local function hide()
end

local function UnRead()
    local isRed = false
    for i=0,2 do
        local item = fields.UIList_StarAmount:GetItemByIndex(0)
        if item ~= nil then
            local finishedCount = taskmanager.GetWeekFinishedFamilyTaskCount()
            if i == 0 and finishedCount >= 20 and taskmanager.IsGetFamilyWeekSpecialReward(i) == false then
                isRed = true
            end
            if i == 1 and finishedCount >= 40 and taskmanager.IsGetFamilyWeekSpecialReward(i) == false then
                isRed = true
            end
            if i == 2 and finishedCount >= 70 and taskmanager.IsGetFamilyWeekSpecialReward(i) == false then
                isRed = true
            end
        end
    end
    fields.UIButton_Clan.gameObject.transform:Find("UISprite_Warning").gameObject:SetActive(isRed)

end

local function refresh(params)
    UnRead()
end

local function update()
    if taskmanager.IsCancelFamilyTask() then
        local pastTime = os.time() - taskmanager.GetCancelFamilyTaskStartTime()
        if pastTime < taskmanager.GetFamilyTaskRefreshTime() then
            if not isScenarioMode then
                local remain = taskmanager.GetFamilyTaskRefreshTime() - pastTime
                local min = math.floor(remain / 60)
                local second = math.floor(remain % 60)
                local desc = string.format("[FF0000]%02d:%02d[-]", min, second)
                UILabel_Go.text = desc
                UIButton_Go.isEnabled = false
            end
        else
            if not isScenarioMode then
                UILabel_Go.text = LocalString.Task_Go
                UIButton_Go.isEnabled = true
            end
            taskmanager.ResetCancelFamilyTaskStatus()
        end
    end

    if Time.time - refreshIntervalTime >= 0.5 and uimanager.isshow("dlgtask") then
        refreshIntervalTime = Time.time
        RefreshCurrency()
    end
end

local function OnButtonGo()
    PlayerRole:Instance():stop()
    if curSelectedTask then
        local taskStatus = taskmanager.GetTaskStatus(curSelectedTask.id)
        if taskStatus == TaskStatusType.UnCommitted then
            taskmanager.NavigateToRewardNPC(curSelectedTask.complete.npcid, curSelectedTask.id)
        elseif taskStatus ~= TaskStatusType.Completed then
            taskmanager.AcceptTask(curSelectedTask.accept.npcid, curSelectedTask.id)
        end
    elseif taskmanager.GetDayFinishedFamilyTaskCount() < taskmanager.GetMaxDayFamilyTaskCount() then
       taskmanager.GetFamilyTaskFromAdmin()
    end
end

local function CancelTaskCallback(taskid)
    if curSelectedTask and curSelectedTask.id == taskid then
        ShowTaskInfo()
    elseif isScenarioMode and acceptTaskNum > 0 then
        acceptTaskNum = acceptTaskNum - 1
        UILabel_AcceptNum.text = LocalString.Task_AcceptTaskNum .. "：" .. acceptTaskNum .. "/" .. MAX_ACCEPT_TASK_NUM
    end
end

local function OnButtonQuit()
    if curSelectedTask then
        PlayerRole:Instance():stop()
        local taskStatus = taskmanager.GetTaskStatus(curSelectedTask.id)
        if taskStatus ~= TaskStatusType.Completed then
            if isScenarioMode then
                taskmanager.CancelTask(curSelectedTask.id, CancelTaskCallback)
            else
                local min = math.floor(taskmanager.GetFamilyTaskRefreshTime()/60)
                local second = taskmanager.GetFamilyTaskRefreshTime()%60
                local info = string.format(LocalString.Task_CancelFamilyTaskWarning, min,second)
                uimanager.ShowAlertDlg( {
                    title = LocalString.Task_FamilyTask,
                    content = info,
                    callBackFunc = function()
                        taskmanager.CancelTask(curSelectedTask.id, CancelTaskCallback)
                    end,
                    immediate = true,
                } )
            end
        end
    end
end

SetTargetCtrl = function (isscenario)
    if isscenario then
        UILabel_AcceptNum = fields.UILabel_ScenarioAcceptNum
        UILabel_Description = fields.UILabel_ScenarioDescription
        UILabel_Target = fields.UILabel_ScenarioObjective
        UIButton_Quit = fields.UIButton_ScenarioQuit
        UIButton_Go = fields.UIButton_ScenarioGo
        UILabel_Go = fields.UILabel_ScenarioGo
        UIList_Task = fields.UIList_ScenarioTask
        UIList_Reward = fields.UIList_ScenarioReward
        UIWidget_Check = fields.UIWidget_Check
    else
        UILabel_AcceptNum = fields.UILabel_ClanAcceptNum
        UILabel_Description = fields.UILabel_ClanDescription
        UILabel_Target = fields.UILabel_ClanObjective
        UIButton_Quit = fields.UIButton_ClanQuit
        UIButton_Go = fields.UIButton_ClanGo
        UILabel_Go = fields.UILabel_ClanGo
        UIList_Task = fields.UIList_ClanTask
        UIList_Reward = fields.UIList_ClanReward
    end
end

local function  OnQuitFamily()
    local familymgr = require("family.familymanager")
    if PlayerRole:Instance().m_RealLevel < taskmanager.GetFamilyTaskOpenLevel() or familymgr.InFamily() == false then
        fields.UISprite_Lock.gameObject:SetActive(false)
        UITools.SetButtonEnabled(fields.UIButton_Clan, false)
        if not isScenarioMode then
            fields.UIGroup_Clan.gameObject:SetActive(false)
            fields.UIGroup_Scenario.gameObject:SetActive(true)
            fields.UIButton_Scenario.gameObject.transform:Find("Scenario_Animation").gameObject:SetActive(true)
        fields.UIButton_Clan.gameObject.transform:Find("Clan_Animation").gameObject:SetActive(false)
            isScenarioMode = true
        end
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)

    isScenarioMode = true
    SetTargetCtrl(true)
    -- 主线支线屏蔽放弃任务
    fields.UIButton_ScenarioQuit.gameObject:SetActive(false)

    EventHelper.SetClick(fields.UIButton_RechargeDiamond, function()
        VipChargeManager.ShowVipChargeDialog()
    end)

    EventHelper.SetClick(fields.UIButton_RechargeBindingDiamond, function()
        VipChargeManager.ShowVipChargeDialog()
    end)

    EventHelper.SetClick(fields.UIButton_RechargeGold, function()
        ItemManager.GetSource(cfg.currency.CurrencyType.XuNiBi,"dlgtask")
    end)

    EventHelper.SetClick(fields.UIButton_Energy, function()
        EctypeDlgManager.ShowReminderTiLi()
    end)

    EventHelper.SetClick(fields.UIButton_Scenario, function()
        fields.UIGroup_Clan.gameObject:SetActive(false)
        fields.UIGroup_Scenario.gameObject:SetActive(true)
        fields.UIButton_Scenario.gameObject.transform:Find("Scenario_Animation").gameObject:SetActive(true)
        fields.UIButton_Clan.gameObject.transform:Find("Clan_Animation").gameObject:SetActive(false)
        fields.UISprite_Buy1.gameObject:SetActive(true)
        fields.UISprite_Sell1.gameObject:SetActive(false)
        if isScenarioMode == false then
            isScenarioMode = true
            curSelectedTask = nil
            listTaskMap = {}
            SetTargetCtrl(true)

            ShowTaskInfo()
        end
    end )

    EventHelper.SetClick(fields.UIButton_Clan, function()
        fields.UIGroup_Scenario.gameObject:SetActive(false)
        fields.UIButton_Scenario.gameObject.transform:Find("Scenario_Animation").gameObject:SetActive(false)
        fields.UIButton_Clan.gameObject.transform:Find("Clan_Animation").gameObject:SetActive(true)
        fields.UIGroup_Clan.gameObject:SetActive(true)
        fields.UISprite_Buy1.gameObject:SetActive(false)
        fields.UISprite_Sell1.gameObject:SetActive(true)
        if isScenarioMode == true then
            isScenarioMode = false
            curSelectedTask = nil
            listTaskMap = {}
            SetTargetCtrl(false)
            ShowTaskInfo()
        end
    end )

    EventHelper.SetClick(fields.UIWidget_Check, function()
        local UIToggle_Check = UIWidget_Check.transform:GetComponent("UIToggle")
        if curSelectedTask then
            taskmanager.SetGuideBranchTaskID(curSelectedTask.id)
            uimanager.call("dlguimain","RefreshTaskList")
        end
    end )

    EventHelper.SetClick(fields.UIButton_ScenarioGo, OnButtonGo)
    EventHelper.SetClick(fields.UIButton_ClanGo, OnButtonGo)

    EventHelper.SetClick(fields.UIButton_ScenarioQuit, OnButtonQuit)
    EventHelper.SetClick(fields.UIButton_ClanQuit, OnButtonQuit)


    EventHelper.SetClick(fields.UIButton_Return, function()
        uimanager.hidedialog("dlgtask")
    end )

    EventHelper.SetListClick(fields.UIList_ScenarioTask, function(list_item)
        -- printyellow(format("ListItem Index: %u click", list_item.Index))
        local taskid = listTaskMap[list_item.Index+1]
        if taskid and taskid > 0 and (curSelectedTask == nil or curSelectedTask.id ~= taskid)then
            curSelectedTask = taskmanager.GetTask(taskid)
            ShowSelectedItemInfo(curSelectedTask, list_item)
            if UIWidget_Check then
                if list_item.Index == 0 then
                    UIWidget_Check.gameObject:SetActive(false)
                else
                    local UIToggle_Check = UIWidget_Check.transform:GetComponent("UIToggle")
                    if UIToggle_Check then
                        if taskmanager.GetGuideBranchTaskID() == taskid then
                            UIToggle_Check.value = true
                        else
                            UIToggle_Check.value = false
                        end
                    end
                    UIWidget_Check.gameObject:SetActive(true)
                end
            end
        end
    end )

    EventHelper.SetListClick(fields.UIList_ClanTask, function(list_item)
        local taskid = listTaskMap[list_item.Index+1]
        if taskid and taskid > 0 and (curSelectedTask == nil or curSelectedTask.id ~= taskid)then
            curSelectedTask = taskmanager.GetTask(taskid)
            ShowSelectedItemInfo(curSelectedTask, list_item)
        end
    end )

    -- 快速完成
    EventHelper.SetClick(fields.UIButton_ClanFinished, function()
        if isScenarioMode or not curSelectedTask then
            return
        end

        local status = taskmanager.GetTaskStatus(curSelectedTask.id)
        if status == TaskStatusType.UnCommitted or status ==  TaskStatusType.Completed then
            return
        end

        PlayerRole:Instance():stop()

        local info = string.format(LocalString.Task_QuickFinishFamilyTaskCost,taskmanager.GetUseYuanBaoCompleteFamilyTaskCost())
        uimanager.ShowAlertDlg({title    = LocalString.Task_FamilyTask,
                                content      = info,
                                callBackFunc = function()
                                    taskmanager.QuickCompleteFamilyTask()
                                end,
                                immediate = true,})
    end )


    -- 一键清环
    EventHelper.SetClick(fields.UIButton_ClanClear, function()
        if isScenarioMode or not curSelectedTask or taskmanager.GetDayFinishedFamilyTaskCount() >= taskmanager.GetClearFamilyTaskRingCount() then
            return
        end
        PlayerRole:Instance():stop()
        local remain = taskmanager.GetClearFamilyTaskRingCount() - taskmanager.GetDayFinishedFamilyTaskCount()
        local info = string.format(LocalString.Task_ClearFamilyTaskCost,remain,remain*taskmanager.GetUseYuanBaoCompleteFamilyTaskCost())
        uimanager.ShowAlertDlg({title        = LocalString.Task_FamilyTask,
                                content      = info,
                                callBackFunc = function()
                                    taskmanager.ClearFamilyTask(function()
                                        curSelectedTask = nil
                                        ShowClanTaskList()
                                    end)
                                end,
                                immediate = true,})
    end )


    EventHelper.SetListClick(fields.UIList_StarAmount,function(list_item)
        local finishedCount = taskmanager.GetWeekFinishedFamilyTaskCount()
		if (list_item.Index == 0 and finishedCount < 20) or (list_item.Index == 1 and finishedCount < 40) or (list_item.Index == 2 and finishedCount < 70) then
            local params   = {}
            params.type    = 1
            params.items   = BonusManager.GetItemsOfSingleBonus(GetRewardData(list_item.Index))
            params.title   = LocalString.Alert_RewardsList
            local text = LocalString.Task_GetReward
            -- params.buttons =
            -- {
            --     { 
            --         text = text,
            --         Enable = (ExpMonsterManager.GetKillMonsterNum() >= monsterbonus[i].killnum and ExpMonsterManager.isReceived(monsterbonus[i].killnum)),                
            --         callBackFunc = function() 
            --             UIManager.hide("common.dlgdialogbox_reward")
            --             ExpMonsterManager.sendGetReward(monsterbonus[i].killnum) 
            --             local expMonsterData=ConfigManager.getConfig("expmonster")  
            --             if killNum >= monsterbonus[i].killnum then 
            --                 local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
            --                 fields["UITexture_Grey_"..i].shader= inactiveShader
            --             end
            --         end 
            --     },
            -- }
            local DlgAlert_ShowRewards = require("ui.dlgalert_showrewards")
            params.callBackFunc = function(p, f) 
                DlgAlert_ShowRewards.init(f)
                DlgAlert_ShowRewards.show(p) 
            end
            uimanager.show("common.dlgdialogbox_reward", params) 
            return
        end
        if taskmanager.IsGetFamilyWeekSpecialReward(list_item.Index) then
            return
        end

        if list_item.Index == 0 then
            local item = fields.UIList_StarAmount:GetItemByIndex(0)
            item.Controls["UITexture_Case1"].gameObject:SetActive(false)
            item.Controls["UITexture_Grey1"].gameObject:SetActive(true)
        elseif list_item.Index == 1 then
            local item = fields.UIList_StarAmount:GetItemByIndex(1)
            item.Controls["UITexture_Case2"].gameObject:SetActive(false)
            item.Controls["UITexture_Grey2"].gameObject:SetActive(true)
        elseif list_item.Index == 2 then
            local item = fields.UIList_StarAmount:GetItemByIndex(2)
            item.Controls["UITexture_Case3"].gameObject:SetActive(false)
            item.Controls["UITexture_Grey3"].gameObject:SetActive(true)
        end
        taskmanager.GetFamilyWeekSpecialReward(list_item.Index, function(bouns)
            UnRead()
        end)
	end)



end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    UnRead = UnRead,
    refresh = refresh,
    UpdateFamilyTaskCaseStatus = UpdateFamilyTaskCaseStatus,
    OnQuitFamily = OnQuitFamily,
}
