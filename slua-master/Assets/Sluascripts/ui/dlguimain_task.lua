local unpack            = unpack
local print             = print
local format            = string.format
local math              = math
local EventHelper       = UIEventListenerHelper
local gameevent         = require"gameevent"
local network           = require"network"
local defineenum        = require"defineenum"
local format            = string.format
local math              = math

local uimanager         = require"uimanager"
local taskmanager       = require"taskmanager"
local miningmanager     = require"miningmanager"
local charactermanager  = require"character.charactermanager"

local CharacterType     = defineenum.CharacterType
local NpcStatusType     = defineenum.NpcStatusType
local TaskType          = defineenum.TaskType
local TaskStatusType    = defineenum.TaskStatusType

local name
local gameObject
local fields

local PlayerRole

local UILabel_MainlineTaskTitle = nil
local UILabel_BranchTaskTitle = nil
local UILabel_FamilyTaskTitle = nil

local UIListItem_MainlineTask = nil
local UIListItem_BranchTask = nil
local UIListItem_FamilyTask = nil

local isDelayRefreshTaskList = false
local refreshIntervalTime = 0
local refreshNpcTalkTime = 0


local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
end

local function hide()
    -- print(name, "hide")
end

local function UpdateTaskListItem(task, tasktype)
    local taskStatus = TaskStatusType.None

    local lineText = ""
    if tasktype == TaskType.Mainline then
        lineText = LocalString.Task_Mainline
    elseif tasktype == TaskType.Branch then
        lineText = LocalString.Task_Branch
    elseif tasktype == TaskType.Family then
        lineText = LocalString.Task_Family
    end

    if tasktype == TaskType.Family and taskmanager.GetDayFinishedFamilyTaskCount() == taskmanager.GetMaxDayFamilyTaskCount() then
        UILabel_FamilyTaskTitle.text = "[FF5FF9]【" .. lineText .. "】[-]" .. LocalString.Task_FinishCountLimit
        return
    end

    if task then
        taskStatus = taskmanager.GetTaskStatus(task.id)
    else
        if tasktype == TaskType.Mainline then
            UILabel_MainlineTaskTitle.text = "[B7F244]【" .. lineText .. "】[-]" .. LocalString.Task_NoTaskCanDo
        elseif tasktype == TaskType.Branch then
            UILabel_BranchTaskTitle.text = "[4EDDF7]【" .. lineText .. "】[-]" .. LocalString.Task_NoTaskCanDo
        elseif tasktype == TaskType.Family then
            local familymgr = require("family.familymanager")
            if taskmanager.IsCancelFamilyTask() then
                return
            end

            local desc = "[FF5FF9]【" .. lineText .. "】[-]"
            if PlayerRole:Instance().m_RealLevel < taskmanager.GetFamilyTaskOpenLevel() then
                desc = desc .. LocalString.Task_NoTaskCanDo
            elseif not familymgr.InFamily() then
                desc = desc .. LocalString.Task_NeedAddInFamily
            elseif taskmanager.GetDayFinishedFamilyTaskCount() == taskmanager.GetClearFamilyTaskRingCount() then
                desc = desc .. LocalString.Task_FinishedHighRewardFamilyTaskHint
            else
                desc = desc .. LocalString.Task_GetTaskFromFamilyNPC
            end
            UILabel_FamilyTaskTitle.text = desc
        end
        return
    end

    if task and task.basic.hints then
        local desc = ""
        if taskStatus == TaskStatusType.UnCommitted then
            desc = "[00FF66]【" .. lineText .. "】"
            desc = desc .. task.basic.name .. "\n" .. taskmanager.ReplaceWildcard(task.basic.hints.acceptedhint)
            local killMonsterDesc = taskmanager.GetKilledMonsterDesc(task, taskStatus)
            if killMonsterDesc and string.len(killMonsterDesc) > 0 then
                desc = desc .. "\n   " .. killMonsterDesc
            end

            local digMineDesc = taskmanager.GetDiggedMineDesc(task, taskStatus)
            if digMineDesc and string.len(digMineDesc) > 0 then
                desc = desc .. "\n   " .. digMineDesc
            end

            desc = desc .. "[-]"
        else
            if tasktype == TaskType.Mainline then
                desc = "[B7F244]【" .. lineText .. "】[-]"
            elseif tasktype == TaskType.Branch then
                desc = "[4EDDF7]【" .. lineText .. "】[-]"
            elseif tasktype == TaskType.Family then
                desc = "[FF5FF9]【" .. lineText .. "】[-]"
            end

            desc = desc .. task.basic.name .. "\n"

            if (taskStatus == TaskStatusType.None) then
                desc = desc .. taskmanager.ReplaceWildcard(task.basic.hints.unacceptedhint)
            else
                desc = desc .. taskmanager.ReplaceWildcard(task.basic.hints.acceptedhint)
            end

            if taskStatus == TaskStatusType.Doing then
                local killMonsterDesc = taskmanager.GetKilledMonsterDesc(task, taskStatus)
                if killMonsterDesc and string.len(killMonsterDesc) > 0 then
                    desc = desc .. "\n" .. killMonsterDesc
                end

                local digMineDesc = taskmanager.GetDiggedMineDesc(task, taskStatus)
                if digMineDesc and string.len(digMineDesc) > 0 then
                    desc = desc .. "\n   " .. digMineDesc
                end
            end
        end

        if task.basic.tasktype == TaskType.Mainline then
            UILabel_MainlineTaskTitle.text = desc
        elseif task.basic.tasktype == TaskType.Branch then
            UILabel_BranchTaskTitle.text = desc
        elseif task.basic.tasktype == TaskType.Family then
            UILabel_FamilyTaskTitle.text = desc
        end
    end
end

local function AdjustTaskListItemPosition()
    local itemDistance = 40
    local uiWidget_MainlineListItem = UIListItem_MainlineTask.gameObject:GetComponent("UIWidget")
    local uiWidget_BranchListItem = UIListItem_BranchTask.gameObject:GetComponent("UIWidget")
    local uiWidget_FamilyListItem = UIListItem_FamilyTask.gameObject:GetComponent("UIWidget")

    uiWidget_MainlineListItem.height = UILabel_MainlineTaskTitle.printedSize.y
    uiWidget_BranchListItem.height = UILabel_BranchTaskTitle.printedSize.y
    uiWidget_FamilyListItem.height = UILabel_FamilyTaskTitle.printedSize.y

    local pos = UIListItem_MainlineTask.gameObject.transform.localPosition
    UIListItem_BranchTask.gameObject.transform.localPosition = Vector3(pos.x, pos.y - uiWidget_MainlineListItem.height - itemDistance, pos.z)
    UIListItem_FamilyTask.gameObject.transform.localPosition = Vector3(pos.x, pos.y - uiWidget_MainlineListItem.height - uiWidget_BranchListItem.height - 2 * itemDistance, pos.z)
end

local function RefreshTaskList()
    -- 先刷新item
    UpdateTaskListItem(taskmanager.GetCurTask(TaskType.Mainline), TaskType.Mainline)
    UpdateTaskListItem(taskmanager.GetGuideBranchTask(), TaskType.Branch)
    UpdateTaskListItem(taskmanager.GetCurTask(TaskType.Family), TaskType.Family)

    -- 再调整item行高
    AdjustTaskListItemPosition()
end


local function UpdateNpcTalk()
    -- NPC气泡喊话,每30秒一次
    if refreshNpcTalkTime > 0 and os.time() - refreshNpcTalkTime >= 30 then
        refreshNpcTalkTime = os.time()

        local npcs = nil
        local count = 0
        npcs, count = charactermanager.GetAllNearbyNpcs()
        if npcs and count > 0 then
            local npcindex = 1
            if count > 1 then
                local seed = tonumber(tostring(os.time()):reverse():sub(1, 6))
                math.randomseed(seed)
                npcindex = math.random(1, count)
            end

            local character = npcs[npcindex]
            if not character.m_HasLoaded then return end
            local npcinfo = taskmanager.GetNpcData(character.m_CsvId)
            if npcinfo.opentext and table.getn(npcinfo.opentext) > 0 then
                local opentextindex = 1
                local opentextcount = table.getn(npcinfo.opentext)
                if opentextcount > 1 then
                    local seed = tonumber(tostring(os.time()):reverse():sub(1, 6))
                    math.randomseed(seed)
                    opentextindex = math.random(1, opentextcount)
                end
                local opentext = taskmanager.ReplaceWildcard(npcinfo.opentext[opentextindex])
                if opentext and string.len(opentext) > 0 then
                    -- character:SetTalkContent(opentext)
                    uimanager.call("dlgheadtalking","Add",{content=opentext,target=character})
                end
            end
        end
    end
end

local function update()
    -- print(name, "update")

    if isDelayRefreshTaskList then
        isDelayRefreshTaskList = false
        RefreshTaskList()
    end

    if refreshIntervalTime > 0 and os.time() - refreshIntervalTime >= 1 then
        refreshIntervalTime = os.time()

        if taskmanager.IsCancelFamilyTask() then
            local pastTime = os.time() - taskmanager.GetCancelFamilyTaskStartTime()
            if pastTime < taskmanager.GetFamilyTaskRefreshTime() then
                if fields.UIGroup_ItemTask.gameObject and fields.UIGroup_ItemTask.gameObject.activeSelf then
                    local remain = taskmanager.GetFamilyTaskRefreshTime() - pastTime
                    local min = math.floor(remain / 60)
                    local second = math.floor(remain % 60)
                    local info = string.format(LocalString.Task_WaitWhenCancelFamilyTask, min, second)
                    UILabel_FamilyTaskTitle.text = "[FF6600]【" .. LocalString.Task_Family .. "】[-]" .. info
                end
            else
                taskmanager.ResetCancelFamilyTaskStatus()

                if fields.UIGroup_ItemTask.gameObject and fields.UIGroup_ItemTask.gameObject.activeSelf then
                    local desc = nil
                    local familymgr = require("family.familymanager")
                    if PlayerRole:Instance().m_RealLevel < taskmanager.GetFamilyTaskOpenLevel() then
                        desc = "[FF6600]【" .. LocalString.Task_Family .. "】[-]" .. LocalString.Task_NoTaskCanDo
                    elseif not familymgr.InFamily() then
                        desc = "[FF6600]【" .. LocalString.Task_Family .. "】[-]" .. LocalString.Task_NeedAddInFamily
                    elseif taskmanager.GetDayFinishedFamilyTaskCount() == taskmanager.GetClearFamilyTaskRingCount() then
                        desc = "[FF6600]【" .. LocalString.Task_Family .. "】[-]" .. LocalString.Task_FinishedHighRewardFamilyTaskHint
                    else
                        desc = "[FF6600]【" .. LocalString.Task_Family .. "】[-]" .. LocalString.Task_GetTaskFromFamilyNPC
                    end

                    if desc then
                        UILabel_FamilyTaskTitle.text = desc
                    end
                end
            end
        end
    end

    UpdateNpcTalk()
end


local function refresh()
    --printyellow(name, "refresh")
	---fields.UIList_TaskShow.transform:GetComponent("UIGrid").enabled = true
end

local function init(iName,iGameObject,iFields)
    name            = iName
    gameObject      = iGameObject
    fields          = iFields

    PlayerRole = require "character.playerrole"

    -- 加载任务
    local taskNum = 3
    for i = 1, taskNum do
        local item = fields.UIList_TaskShow:AddListItem()
        if i == 1 then
            UILabel_MainlineTaskTitle = item.Controls["UILabel_TaskTitle"]
            UIListItem_MainlineTask = item
		
        elseif i == 2 then
            UILabel_BranchTaskTitle = item.Controls["UILabel_TaskTitle"]
            UIListItem_BranchTask = item

        elseif i == 3 then
            UILabel_FamilyTaskTitle = item.Controls["UILabel_TaskTitle"]
            UIListItem_FamilyTask = item
            --UIListItem_FamilyTask.gameObject:SetActive(false)

        end
    end
	
    isDelayRefreshTaskList = true
    refreshIntervalTime = os.time()
    refreshNpcTalkTime = os.time()

    EventHelper.SetListClick(fields.UIList_TaskShow, function(list_item)

        local task = nil
        local familymgr = require("family.familymanager")
        if list_item.Index == 0 then
            -- 主线任务
            task = taskmanager.GetCurTask(TaskType.Mainline)
        elseif list_item.Index == 1 then
            -- 支线任务
            task = taskmanager.GetGuideBranchTask()
        elseif list_item.Index == 2 then
            -- 环任务
            if familymgr.InFamily() then
                task = taskmanager.GetCurTask(TaskType.Family)
            end
        end

        if task then
            local taskStatus = taskmanager.GetTaskStatus(task.id)
            if task and taskStatus ~= TaskStatusType.Completed then
                if taskStatus == TaskStatusType.UnCommitted then
                    taskmanager.NavigateToRewardNPC(task.complete.npcid, task.id)
                else
                    taskmanager.AcceptTask(task.accept.npcid, task.id)
                end
            end
        elseif list_item.Index == 2 and not taskmanager.IsCancelFamilyTask() then
            -- 环任务
            if PlayerRole:Instance().m_RealLevel < taskmanager.GetFamilyTaskOpenLevel() or familymgr.InFamily() == false then
                return
            end

            if taskmanager.GetDayFinishedFamilyTaskCount() < taskmanager.GetMaxDayFamilyTaskCount() then
                taskmanager.GetFamilyTaskFromAdmin()
            else
            end
        end

    end )
	--fields.UIList_TaskShow.transform:GetComponent("UIGrid").enabled = true
end



return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    RefreshTaskList = RefreshTaskList,
}
