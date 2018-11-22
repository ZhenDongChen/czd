local configmanager = require "cfg.configmanager"
local network = require "network"
local uimanager = require "uimanager"
local charactermanager = require "character.charactermanager"
local defineenum = require "defineenum"
local gameevent = require "gameevent"
local effectmanager = require "effect.effectmanager"
local ectypemanager = require "ectype.ectypemanager"
local modulelockmanager=require"ui.modulelock.modulelockmanager"
local scenemanager = require "scenemanager"
local timeutils = require  "common.timeutils"
local TaskType = defineenum.TaskType
local TaskNavModeType = defineenum.TaskNavModeType
local TaskStatusType = defineenum.TaskStatusType
local NpcStatusType = defineenum.NpcStatusType
local CharacterType = defineenum.CharacterType
local NoviceGuideTrigger=require"noviceguide.noviceguide_trigger"

local PlayerRole

local GetTask
local GetTaskType
local GetNextTask
local AllTaskTaskStatus
local SetTaskStatus
local GetTaskStatus
local CompleteTask
local NavigateToRewardNPC
local GetTaskFromHistory
local GetCanAcceptTask
local AutoFinishTask
local SetFamilyTaskRingCount
local GetFamilyTaskRingCount
local GetMaxFamilyTaskRingCount
local SetFamilyNPC
local GetFamilyNPC
local SetDayFinishedFamilyTaskCount
local GetDayFinishedFamilyTaskCount
local SetWeekFinishedFamilyTaskCount
local GetWeekFinishedFamilyTaskCount
local GetFamilyTaskOpenLevel
local GetFamilyAdminNpcId
local GetFamilyTaskRefreshTime
local GetClearFamilyTaskRingCount
local GetUseYuanBaoCompleteFamilyTaskCost
local SetGuideBranchTaskID
local DoTaskWhenUnCommitted
local GetCancelFamilyTaskStartTime
local IsCancelFamilyTask
local ResetCancelFamilyTaskStatus
local SetShoutDialogue
local IsGetFamilyWeekSpecialReward
local GetNavMode
local GetDialogueAudioClipId
local LeaveFamilyStationProc


local allTaskData = nil
local historyTask = nil
local allTaskStatus = { }

local npcdata = nil
local monsterdata = nil
local wildcardsexdata = nil
local wildcardprofessiondata = nil

local npcStatusData = {}

local curExecutingTaskID=0
local firstMainlineTaskID = 0
local curMainlineTaskID = 0
local curFamilyTaskID = 0
local curBranchTaskIDs = {}
local curFamilyTaskGroup = {}

local familyNPC = {}
local curFamilyTaskRingCount = 0
local maxFamilyTaskRingCount = 5
local dayFinishedFamilyTaskCount = 0
local maxDayFamilyTaskCount = 20
local weekSpecialRewardFamilyTaskCount = 70
local weekFinishedFamilyTaskCount = 0

local familyTaskOpenLevel = 30
local familyAdminNpcId    = 0
local familyTaskRefreshTime = 90
local useYuanBaoCompleteFamilyTaskCost = 10
local clearFamilyTaskRingCount = 10

local isCancelFamilyTask = false
local cancelFamilyTaskStartTime = 0

local familyWeekSpecialRewardHistroy = {}


-- 所有支线任务(第一个任务）ID
local allFirstBranchTaskIDs = {}
-- 能接的支线任务（未接）
local canAcceptBranchTaskIDs = {}
-- 主城任务列表界面显示的支线任务（指引）
local guideBranchTaskID = 0

local taskProgressCounter = {}
local isGetHistroyTaskFromServer = false

local isAutoAcceptTask = false
local autoAcceptTaskId = 0
local isNeedToNavigateToFamilyAdmin = false
local startTime = 0.0
local totalTime = 1.5

local gotoLocationTaskId = 0

local curCancelTaskId = 0

local npcShowHideInfo = {}
local hideMines = {}

local isStartShoutOrPlayCG = false

local cancelTaskCallback = nil
local clearFamilyTaskCallback = nil
local getFamilyWeekSpecialRewardCallback = nil

-- 播放喊话对白
local isStartShout = false;
local shoutDialogTaskId = 0;
local shoutDialogIndex = 0;
local startTimeShout = 0;
local totalTimeShout = 0
local shoutDialogCallback = nil

-- 找怪/矿物延时查找附近的
local delayFindAgentId = 0
local delayFindAgentStartTime = -1

-- 通配符替换
-- 此通配符以两个$符号括起来为准，如$S1000$、$P2000$($S..$表示性别类，$P..$表示职业类）
local function ReplaceWildcard(srcContent)
    local content = srcContent
    while true do
        local str1 = string.match(content, "%$.%d+%$")
        if not str1 then
            break
        end

        local index1 = 0
        local index2 = 0
        local str2 = nil
        local str3 = nil
        index1, index2, str2, str3 = string.find(content, "%$(.)(%d+)%$")
        if not str2 then
            break
        end

        -- printyellow("ReplaceWildcard",str1,index1,index2,str2,str3)

        -- 默认值，仅供出错情况下（未找到配置表里面的数据）
        local replaceinfo = " "..LocalString.Task_Wildcard_Unknow.." "

        if str2 == "S" or str2 == "s" then
            if wildcardsexdata then
                local info = wildcardsexdata[tonumber(str3)]
                if info then
                    local gender = PlayerRole:Instance().m_Gender
                    if gender == defineenum.GenderType.Male then
                        replaceinfo = info.male
                    else
                        replaceinfo = info.female
                    end
                end
            end
        elseif str2 == "P" or str2 == "p" then
            if wildcardprofessiondata then
                local info = wildcardprofessiondata[tonumber(str3)]
                if info then
                    local profession = PlayerRole:Instance().m_Profession
                    if profession == cfg.role.EProfessionType.QINGYUNMEN then
                        replaceinfo = info.qingyun
                    elseif profession == cfg.role.EProfessionType.TIANYINSI then
                        replaceinfo = info.tianyin
                    elseif profession == cfg.role.EProfessionType.GUIWANGZONG then
                        replaceinfo = info.guiwang
                    elseif profession == cfg.role.EProfessionType.HEHUANPAI then
                        replaceinfo = info.hehuan
                    end
                end
            end
        else
            -- printyellow("ReplaceWildcard:format error")
            break
        end

        if replaceinfo then
            local str4 = nil
            local str5 = nil
            str4, str5 = string.gsub(content, "%$" .. str2 .. str3 .. "%$", replaceinfo)
            -- printyellow("ReplaceWildcard result",replaceinfo,str4,str5)

            if str4 == content then
                -- printyellow("ReplaceWildcard:replace text error")
                break
            end

            content = str4
        else
            -- printyellow("ReplaceWildcard:can't find wildcard")
            break
        end
    end

    -- printyellow("ReplaceWildcard result:"..content)
    return content
end

-- NPC显隐
local function RefreshNPCShowHide(task)
    if task and task.basic.npcshowhide and table.getn(task.basic.npcshowhide.showhide) > 0 then
        local status = GetTaskStatus(task.id)
        for _, item in pairs(task.basic.npcshowhide.showhide) do
            for _, npcid in pairs(item.allid) do
                if status == TaskStatusType.Accepted or status == TaskStatusType.Doing then
                    npcShowHideInfo[npcid] = item.showhideaccept
                elseif status == TaskStatusType.UnCommitted then
                    npcShowHideInfo[npcid] = item.showhidecomplete
                elseif status == TaskStatusType.Completed then
                    npcShowHideInfo[npcid] = item.showhidefinish
                elseif status == TaskStatusType.None then
                    npcShowHideInfo[npcid] = item.showhidefail
                end

                if scenemanager.GetCurMapId() == task.basic.npcshowhide.worldmapid then
                    local character = charactermanager.GetCharacterByCsvId(npcid)
                    if character then
                        if npcShowHideInfo[npcid] then
                            character:Show()
                        else
                            character:Hide()
                        end
                    end
                end
            end
        end
    end
end

GetNavMode = function(taskid)
    local task = GetTask(taskid)
    if task then
        local navMode = 2
        if task.basic.navmode <= 0 or task.basic.navmode == TaskNavModeType.Default then
            navMode = (task.basic.tasktype == TaskType.Family) and 1 or 2
        else
            navMode = (task.basic.navmode == TaskNavModeType.DirectTransfer) and 1 or 2
        end

        local isShowAlert = true
        --[[
        if tasktype == TaskType.Family then
            isShowAlert = false
        end
        --]]
        return navMode, isShowAlert
    end
end

local function  IsMineNeedHide(mineid)
    return hideMines[mineid]
end


local function ShowDlgTask(isshow)
    if isshow then
        if uimanager.isshow("dlgtask") == false then
            uimanager.showdialog("dlgtask")
        end
    else
        if uimanager.isshow("dlgtask") == true then
            uimanager.hidedialog("dlgtask")
        end
    end
end

local function SetNpcFaceToRole(npcid)
    local character = charactermanager.GetCharacterByCsvId(npcid)
    if character then
		local Angle = mathutils.PosGetAngle(PlayerRole:Instance():GetPos(), character:GetPos());
		character:SetEulerAngle(Angle)
    end
end

local function SetNpcStatus(npcid,status)
    if npcid < 1 then
        return
    end

    local info = npcStatusData[npcid]
    if info then
        if status.npcstatus == NpcStatusType.None then
            info[status.taskid] = nil
        else
            info[status.taskid] = status.npcstatus
        end
    else
        info = {}
        info[status.taskid] = status.npcstatus
        npcStatusData[npcid] = info
    end
end

local function GetNpcStatus(npcid)
    local status = NpcStatusType.None
    local info = npcStatusData[npcid]
    if info then
        for _, value in pairs(info) do
            status = value
            -- 可交任务状态优先
            if value == NpcStatusType.CanCommitTask then
                break
            end
        end
    end

    return status
end

local function GetAllNpcStatus(npcid)
    return npcStatusData[npcid]
end

local function GetNpcData(npcid)
    if npcdata then
        return npcdata[npcid]
    end
end


local function GetMonsterData(monsterid)
    if monsterdata then
        return monsterdata[monsterid]
    end
end

local function GetTaskProgressCount(taskid, id)
    local count = 0
    local counter = taskProgressCounter[taskid]
    -- printyellow("GetTaskProgressCount:",tostring(taskid))
    -- printt(taskProgressCounter)
    if counter and counter[id] then
        count = counter[id]
    end
    return count
end

GetTask = function (id)
    if allTaskData then
        return allTaskData[id]
    end
end

GetTaskType = function(id)
    local task = GetTask(id)
    if task then
        return task.basic.tasktype
    end
end

GetMaxFamilyTaskRingCount = function ()
    return maxFamilyTaskRingCount
end

SetFamilyTaskRingCount = function (count)
    if count >= 0 and count <= maxFamilyTaskRingCount then
        curFamilyTaskRingCount = count
    end
end

GetFamilyTaskRingCount = function ()
    return curFamilyTaskRingCount
end

SetFamilyNPC = function (taskid,acceptDialogue_npc_id,npc_id)
    if taskid > 0 and acceptDialogue_npc_id > 0 and npc_id > 0 then
        familyNPC[taskid] = {acceptDialogueNpcId = acceptDialogue_npc_id,npcid = npc_id}
    end
end

GetFamilyNPC = function(taskid, isAcceptDialogueNpc)
    if familyNPC[taskid] then
        if isAcceptDialogueNpc then
            return familyNPC[taskid].acceptDialogueNpcId
        else
            return familyNPC[taskid].npcid
        end
    end
end


SetDayFinishedFamilyTaskCount = function (count)
    if count >= 0 and count <= maxDayFamilyTaskCount then
        dayFinishedFamilyTaskCount = count
    end
end

GetDayFinishedFamilyTaskCount  = function ()
    return dayFinishedFamilyTaskCount
end


SetWeekFinishedFamilyTaskCount = function (count)
    if count >= 0 then
        weekFinishedFamilyTaskCount = count
    end
end

GetWeekFinishedFamilyTaskCount  = function ()
    return weekFinishedFamilyTaskCount
end

GetFamilyTaskOpenLevel = function ()
    return familyTaskOpenLevel
end

GetFamilyAdminNpcId = function ()
    return familyAdminNpcId
end

GetFamilyTaskRefreshTime = function ()
    return familyTaskRefreshTime
end

GetClearFamilyTaskRingCount = function ()
    return clearFamilyTaskRingCount
end

GetMaxDayFamilyTaskCount = function ()
    return maxDayFamilyTaskCount
end

GetWeekSpecialRewardFamilyTaskCount = function ()
    return weekSpecialRewardFamilyTaskCount
end


GetUseYuanBaoCompleteFamilyTaskCost = function ()
    return useYuanBaoCompleteFamilyTaskCost
end

local function GetAllTaskStatus()
    return allTaskStatus
end

GetTaskStatus = function (taskid)
    local status = TaskStatusType.None
    if allTaskStatus[taskid] then
        status = allTaskStatus[taskid]
    end
    return status
end

-- 自动完成任务
AutoFinishTask = function (taskid)
    local task = GetTask(taskid)
    if task.basic.autofinish then
        -- printyellow("AutoFinishTask:"..taskid)
        local completeNpcId = task.complete.npcid
        if task.basic.tasktype == TaskType.Family then
            completeNpcId = GetFamilyNPC(taskid,false)
        end

        if completeNpcId > 0 then
			if  curExecutingTaskID == taskid and ectypemanager.IsInEctype() == false then
				NavigateToRewardNPC(completeNpcId, taskid)
			end
        else
            CompleteTask(task.complete.npcid, taskid)
        end
    end
end

local function SetCurTask(taskid)
    local task = GetTask(taskid)
    if not task then
        return
    end

    if task.basic.tasktype == TaskType.Mainline then
        curMainlineTaskID = taskid
    elseif task.basic.tasktype == TaskType.Branch then
        if curBranchTaskIDs[taskid] ~= nil then
            return
        end

        if next(task.accept.pretaskid) ~= nil then
            -- 先清除父任务
            for _, preid in pairs(task.accept.pretaskid) do
                if preid and curBranchTaskIDs[preid] then
                    curBranchTaskIDs[preid] = nil
                    break
                end
            end
        end
        curBranchTaskIDs[taskid] = taskid

        if guideBranchTaskID == 0 then
            SetGuideBranchTaskID(taskid)
        end
    elseif task.basic.tasktype == TaskType.Family then
        curFamilyTaskID = taskid
    end
	local status = GetTaskStatus(taskid);
	if status == TaskStatusType.Doing then
		if task.complete.location.worldmapid > 0 then
			gotoLocationTaskId = task.id
		end
	end
end

local function GetCurTask(tasktype)
    -- 需等待服务器返回历史任务
    if isGetHistroyTaskFromServer == false then
        return
    end

    if tasktype == TaskType.Mainline then
        local task = GetTask(curMainlineTaskID)
        if not task then
            task = GetTask(firstMainlineTaskID)
        end

        if task then
            local taskStatus = GetTaskStatus(task.id)
            if taskStatus == TaskStatusType.Completed then
                local nexttask = GetNextTask(task.id, TaskType.Mainline)
                if nexttask then
					while GetTaskStatus(nexttask.id) ~= TaskStatusType.None do
						nexttask = GetNextTask(nexttask.id, tasktype)
					end
					if GetTaskStatus(nexttask.id) == TaskStatusType.None then
						task = nexttask
						SetTaskStatus(task.id, TaskStatusType.None)
						SetCurTask(task.id)
					end
                end
            end
        end

        return task
    elseif tasktype == TaskType.Branch then
        local branchTasks = { }
        for _, id in pairs(curBranchTaskIDs) do
            local task = GetTask(id)
            if task then
                local taskStatus = GetTaskStatus(task.id)
                if taskStatus == TaskStatusType.Completed then
                    local nexttask = GetNextTask(task.id, TaskType.Branch)
                    if nexttask then
                        task = nexttask
                        SetTaskStatus(task.id, TaskStatusType.None)
                        SetCurTask(task.id)

                        if guideBranchTaskID == id then
                            SetGuideBranchTaskID(task.id)
                        end

                        branchTasks[id] = task
                    end
                else
                    branchTasks[id] = task
                end
            end
        end
        return branchTasks
    elseif tasktype == TaskType.Family then
        local familymgr = require("family.familymanager") 
        if not familymgr.InFamily() then
            return nil
        end

        local task = GetTask(curFamilyTaskID)
        if task then
            local taskStatus = GetTaskStatus(task.id)
            if taskStatus == TaskStatusType.Completed then
                local nexttask = GetNextTask(task.id, TaskType.Family)
                if nexttask then
                    task = nexttask
                    SetTaskStatus(task.id, TaskStatusType.None)
                    SetCurTask(task.id)
                else
                    task = nil
                end
            end
        end

        return task
    end
end

local function SetExecutingTask(id)
    curExecutingTaskID=id
end

local function GetExecutingTask()
	return curExecutingTaskID
end

SetGuideBranchTaskID = function (taskid)
    guideBranchTaskID = taskid

    local re = lx.gs.task.msg.CChooseShowBranchTask( { guidebranchtaskid = taskid })
    network.send(re)
    -- printyellow("send CChooseShowBranchTask:" .. taskid)
end

local function GetGuideBranchTaskID()
    return guideBranchTaskID
end

local function GetGuideBranchTask()
    local task = GetTask(guideBranchTaskID)
    if task then
        local taskStatus = GetTaskStatus(task.id)
        if taskStatus == TaskStatusType.Completed then
            local nexttask = GetNextTask(task.id, TaskType.Branch)
            if nexttask then
                task = nexttask
                SetTaskStatus(task.id, TaskStatusType.None)
                SetGuideBranchTaskID(task.id)
                SetCurTask(task.id)
            else
                task = nil
            end
        end
    end

    if task then
        return task
    else
        -- 从当前正在做的任务中找
        for _, id in pairs(curBranchTaskIDs) do
            if id ~= guideBranchTaskID then
                task = GetTask(id)
                if task then
                    local taskStatus = GetTaskStatus(task.id)
                    if taskStatus == TaskStatusType.Completed then
                        local nexttask = GetNextTask(task.id, TaskType.Branch)
                        if nexttask then
                            SetGuideBranchTaskID(nexttask.id)
                            return nexttask
                        end
                    else
                        SetGuideBranchTaskID(id)
                        return task
                    end
                end
            end
        end

        -- 再从可接任务中找
        local canAcceptBranchTask = GetCanAcceptTask(TaskType.Branch)
        if canAcceptBranchTask and next(canAcceptBranchTask) ~= nil then
            for _, id in pairs(canAcceptBranchTask) do
                local branchTask = GetTask(id)
                if branchTask then
                    SetGuideBranchTaskID(id)
                    return branchTask
                end
            end
        end
    end
end

local function IsMainlineTask(id)
    local task = GetTask(id)
    if task and task.basic.tasktype == TaskType.Mainline then
        return true
    else
        return false
    end
end


AllTaskTaskStatus = function(taskid, status)
    allTaskStatus[taskid] = status
end

SetTaskStatus = function(taskid, status, not_refresh, not_refresh_npcshowhide)
    allTaskStatus[taskid] = status

    local task = GetTask(taskid)
    if not task then
        return
    end

    if not_refresh then
        return
    end

    -- 刷新NPC显隐信息
    if not not_refresh_npcshowhide then
        if task.basic.tasktype ~= TaskType.Family then
            RefreshNPCShowHide(task)
        end
    end

    -- 更新NPC头顶状态
    if status == TaskStatusType.UnCommitted then
        if task.accept.npcid ~= task.complete.npcid then
            SetNpcStatus(task.accept.npcid,{taskid=task.id, npcstatus=NpcStatusType.None})
        end

        SetNpcStatus(task.complete.npcid,{taskid=task.id, npcstatus=NpcStatusType.CanCommitTask})
    elseif status ~= TaskStatusType.Accepted and status ~= TaskStatusType.Doing then
        if status == TaskStatusType.Completed then
            SetNpcStatus(task.complete.npcid,{taskid=task.id, npcstatus=NpcStatusType.None})
            task = GetNextTask(task.id,task.basic.tasktype)
        end

        if task then
            SetNpcStatus(task.accept.npcid,{taskid=task.id, npcstatus=NpcStatusType.CanAcceptTask})
        end
    end

    ----printt(npcStatusData)
end

-- 下一个任务
GetNextTask = function (id,tasktype)
    if tasktype == TaskType.Family then
        local curOrder = GetFamilyTaskRingCount()
        if curOrder >= 0 and  curOrder < GetMaxFamilyTaskRingCount() then
            return GetTask(curFamilyTaskGroup[curOrder+1])
        else
            return nil
        end
    end

    for _, taskdata in pairs(allTaskData) do
        if taskdata and taskdata.basic.tasktype == tasktype then
            for _, preid in pairs(taskdata.accept.pretaskid) do
                if preid == id and GetTaskType(preid) == tasktype then
                    return taskdata
                end
            end
        end
    end
end

GetTaskFromHistory = function (tasktype)
    local hasCompletedTask = false
    local branchTasks = {}
    for id, status in pairs(allTaskStatus) do
        if status == TaskStatusType.Completed and GetTaskType(id) == tasktype then
            hasCompletedTask = true
            local nexttask = GetNextTask(id, tasktype)
            if nexttask and GetTaskStatus(nexttask.id) ~= TaskStatusType.Completed then
                if tasktype == TaskType.Branch then
                    branchTasks[nexttask.id] = nexttask
                else
                    return nexttask
                end
            end
        end
    end

    if tasktype == TaskType.Branch then
         return branchTasks
    end

    if hasCompletedTask == false and tasktype == TaskType.Mainline and firstMainlineTaskID > 0 then
        local firsttask = GetTask(firstMainlineTaskID)
        return firsttask
    end
end

local function SetAutoAcceptTask(taskid)
    local isGuide = false-- noviceguidemanager.IsGuiding()
    if not isGuide then
        autoAcceptTaskId = taskid
        startTime = Time.time
        isAutoAcceptTask = true
    end
end

SetShoutDialogue = function(taskid, callback)
    shoutDialogTaskId = taskid
    startTimeShout = Time.time
    shoutDialogIndex = 1
    totalTimeShout = 0
    shoutDialogCallback = callback
    isStartShout = true
end

local function PlayCG(task, cgtype, callback)
	printyellow("taskmanager")
    local plotmanager = require "plot.plotmanager"
    if task and table.getn(task.complete.finishspecialevent) > 0 then
        for _, item in pairs(task.complete.finishspecialevent) do
            if item and item.eventtype == cfg.task.EFinishSpecialEventType.PLAYING_CG and item.playcgtype == cgtype and item.id > 0 then
                plotmanager.CutscenePlayById(item.id, callback)
                return
            end
        end
    end

    -- 不管有没有CG播放callback必须回调
    if callback then
        callback()
    end
end

local function NavigateToTarget(character)
    if character then
        if character.m_Type == CharacterType.Monster then
            PlayerRole:Instance():navigateTo( {
                targetPos = character:GetPos(),
                roleId = character.id,
                eulerAnglesOfRole = character.m_Rotation,
                newStopLength = 64,
                isAdjustByRideState = true,
                callback = function()
                    -- 自动杀怪
                    uimanager.call("dlguimain","SwitchAutoFight",true)
                end
            } )
        elseif character.m_Type == CharacterType.Mineral then
            -- 自动采矿
            local miningmanager = require "miningmanager"
            miningmanager.NavigateToMine(character.m_Id, character:GetPos())
        end
    end
end

local function FindAgent(agent_id, agent_type, task_id)
    -- printyellow("FindAgent")
    ShowDlgTask(false)

    delayFindAgentId = 0
    delayFindAgentStartTime = -1

    LeaveFamilyStationProc( function()
        -- 先找附近的
        local character = charactermanager.GetNearestCharacterByCsvId(agent_id)
        if character then
            NavigateToTarget(character)
            return
        end

        -- 再从配置数据里找
        local worldmapid
        local pos
        local direction
        worldmapid, pos, direction = charactermanager.GetAgentPositionInCSV(agent_id, agent_type)
        if worldmapid and pos then
            local mode = 2
            local showalert = true
            mode, showalert = GetNavMode(task_id)
            local stoplength = 5*SCALE_SPEED --600
            PlayerRole:Instance():navigateTo( {
                navMode = mode,
                isShowAlert = showalert,
                targetPos = pos,
                roleId = agent_id,
                mapId = worldmapid,
                eulerAnglesOfRole = direction,
                newStopLength = stoplength,
                isAdjustByRideState = true,
                callback = function()
                    character = charactermanager.GetNearestCharacterByCsvId(agent_id)
                    if character then
                        -- 再次导航
                        NavigateToTarget(character)
                    else
                        printyellow("FindAgent:cann't find nearest character by csvId.stopLength=" .. stoplength)
                        -- 没找到，缩小newstoplength再导航一次
                        stoplength = 2*SCALE_SPEED --120
                        PlayerRole:Instance():navigateTo( {
                            navMode = mode,
                            isShowAlert = showalert,
                            targetPos = pos,
                            roleId = agent_id,
                            mapId = worldmapid,
                            eulerAnglesOfRole = direction,
                            newStopLength = stoplength,
                            isAdjustByRideState = true,
                            callback = function()
                                character = charactermanager.GetNearestCharacterByCsvId(agent_id)
                                if character then
                                    -- 再次导航
                                    NavigateToTarget(character)
                                else
                                    -- 仍然找不到，需要延时查找（可能是怪物/矿物还未刷新）
                                    delayFindAgentId = agent_id 
                                    delayFindAgentStartTime = Time.time
                                end
                            end
                        } )
                    end

                end
            } )
        end
    end )
end

local function DoEctype(task_id, ectype_id, location)
    if ectype_id > 0 and location then
        LeaveFamilyStationProc( function()
            local pos = Vector3(location.x, location.y, location.z)
            ShowDlgTask(false)
            local mode = 2
            local showalert = true
            mode, showalert = GetNavMode(task_id)
            PlayerRole:Instance():navigateTo( {
                navMode = mode,
                isShowAlert = showalert,
                targetPos = pos,
                mapId = location.worldmapid,
                callback = function()
                    local re = lx.gs.task.msg.COpenTaskEctype( { taskid = task_id })
                    network.send(re)
                end
            } )
        end )
    end
end


local function NavigateToLocation(taskid, worldmapid, pos, portalid)
    -- printyellow("Navigate to location")

    if PlayerRole:Instance():IsNavigating() then
        return
    end

    ShowDlgTask(false)

    if worldmapid and pos then
        LeaveFamilyStationProc( function()
            local mode = 2
            local showalert = true
            mode, showalert = GetNavMode(taskid)
            PlayerRole:Instance():navigateTo( {
                navMode = mode,
                isShowAlert = showalert,
                targetPos = pos,
                mapId = worldmapid,
				neednavportal = portalid,
                callback = function()
                    -- to do...
                end
            } )
        end )
    end
end

local function DoTask(taskid)
    local task = GetTask(taskid)
    if task then
		SetExecutingTask(taskid);
        local monsterid = 0;
        if table.getn(task.complete.killmonster) > 0 then
            for _, item in pairs(task.complete.killmonster) do
                if item and item.monsterid > 0 and item.monstercount > 0 then
                    monsterid = item.monsterid
                    break
                end
            end
        end

        local mineid = 0;
        if table.getn(task.complete.finishspecialevent) > 0 then
            for _, item in pairs(task.complete.finishspecialevent) do
                if item and item.id > 0 and item.eventtype == cfg.task.EFinishSpecialEventType.MINING then
                    mineid = item.id
                    break
                end
            end
        end

        local ectypeid = 0
        local doEctypeLocation = nil
        if table.getn(task.complete.finishspecialevent) > 0 then
            for _, item in pairs(task.complete.finishspecialevent) do
                if item and item.id > 0 and item.eventtype == cfg.task.EFinishSpecialEventType.DOING_ECTYPE then
                    ectypeid = item.id
                    doEctypeLocation = item.location
                    break
                end
            end
        end

        if monsterid > 0 then
            uimanager.call("dlguimain","RefreshTaskList")
            FindAgent(monsterid, CharacterType.Monster,taskid)
        elseif mineid > 0 then
            uimanager.call("dlguimain","RefreshTaskList")
            FindAgent(mineid, CharacterType.Mineral,taskid)
        elseif ectypeid > 0 then
            uimanager.call("dlguimain","RefreshTaskList")
            curEctypeId = 0
            if doEctypeLocation and doEctypeLocation.worldmapid > 0 then
                DoEctype(task.id, ectypeid, doEctypeLocation)
            end
        elseif task.complete.location.worldmapid > 0 then
            local x =(task.complete.location.minx + task.complete.location.maxx) / 2
            local y =(task.complete.location.miny + task.complete.location.maxy) / 2
            local pos = Vector3(x, y, 0)
            gotoLocationTaskId = task.id
            NavigateToLocation(task.id,task.complete.location.worldmapid, pos, task.complete.location.neednavportal)
        else
            SetTaskStatus(task.id, TaskStatusType.UnCommitted)
            uimanager.call("dlguimain","RefreshTaskList")
            -- 喊话
            isStartShoutOrPlayCG = true
            SetShoutDialogue(task.id, function()
                PlayCG(GetTask(task.id), cfg.task.EPlayingCGType.WHEN_UNCOMMITTED, function()
                    isStartShoutOrPlayCG = false
                    AutoFinishTask(task.id)
                end )
            end )
        end
    end
end

local function IsCanAcceptTask(taskid)
    local task = GetTask(taskid)
    if task and task.accept then
        local roleinfo = PlayerRole:Instance()
        if task.accept.rolelevelmin > 0 and roleinfo.m_RealLevel < task.accept.rolelevelmin then
            return false
        end

        if task.accept.rolelevelmax > 0 and roleinfo.m_RealLevel > task.accept.rolelevelmax then
            return false
        end

        if task.accept.factionlevelmin > 0 and roleinfo.m_Factionlevel < task.accept.factionlevelmin then
            return false
        end

        if task.accept.factionlevelmax > 0 and roleinfo.m_Factionlevel > task.accept.factionlevelmax then
            return false
        end

        if table.getn(task.accept.professionid) > 0 then
            if roleinfo.m_ProfessionData.id <= 0 then
                return false
            end
            local isFind = false
            for _, item in pairs(task.accept.professionid) do
                if item == roleinfo.m_ProfessionData.id then
                    isFind = true
                end
            end
            if not isFind then
                return false
            end
        end

        -- 互斥任务
        if table.getn(task.accept.mutextaskid) > 0 then
            for _, item in pairs(task.accept.mutextaskid) do
                local status = GetTaskStatus(item)
                if status == TaskStatusType.Accepted or status == TaskStatusType.Doing or status == TaskStatusType.UnCommitted then
                    return false
                end
            end
        end

        -- 前提任务
        local hasCompletedPreTask = false
        for _, preid in pairs(task.accept.pretaskid) do
            local status = GetTaskStatus(preid)
            if status == TaskStatusType.Completed then
                hasCompletedPreTask = true
            elseif task.accept.finishanyonepretask == false then
                return false
            end
        end
        if next(task.accept.pretaskid) ~= nil and  hasCompletedPreTask == false then
            return false
        end
    end

    return true
end

GetCanAcceptTask = function(tasktype)
    local canAcceptTask = { }
    if tasktype == TaskType.Branch then
        for _, id in pairs(canAcceptBranchTaskIDs) do
            local status = GetTaskStatus(id)
            if status == TaskStatusType.None then
                canAcceptTask[id] = id
            end
        end
    end
    return canAcceptTask
end

local function IsTaskCanBeUncommited(taskid)
    local task = GetTask(taskid)
    if task then
        if  table.getn(task.complete.killmonster) > 0 then
            local finishKillMonster = true
            local hasKillMonster = false
            for _, item in pairs(task.complete.killmonster) do
                -- 杀怪
                if item and item.monsterid > 0 and item.monstercount > 0 then
                    -- 若有收集掉落物品则以它的计数为准
                    if item.dropitemid > 0 and item.dropitemcount > 0 then
                        local collectedCount = GetTaskProgressCount(task.id, item.dropitemid)
                        if hasKillMonster == false and collectedCount > 0 then
                            hasKillMonster = true
                        end
                        if collectedCount < item.dropitemcount then
                            finishKillMonster = false
                            break
                        end
                    else
                        local killedCount = GetTaskProgressCount(task.id, item.monsterid)
                        if hasKillMonster == false and killedCount > 0 then
                            hasKillMonster = true
                        end
                        if killedCount < item.monstercount then
                            finishKillMonster = false
                            break
                        end
                    end
                end
            end
            if hasKillMonster == false then
                finishKillMonster = false
            end
            return finishKillMonster, hasKillMonster
        elseif table.getn(task.complete.finishspecialevent) > 0 then
            -- 事件
            local finishDoEvent = true
            local hasDoEvent = false
            for _, item in pairs(task.complete.finishspecialevent) do
                if item then
                    if (item.eventtype == cfg.task.EFinishSpecialEventType.MINING or item.eventtype == cfg.task.EFinishSpecialEventType.DOING_ECTYPE) and finishDoEvent == true then
                        -- 采矿
                        local count = GetTaskProgressCount(task.id, item.id)
                        if hasDoEvent == false and count > 0 then
                            hasDoEvent = true
                        end
                        if count < item.count then
                            finishDoEvent = false
                            break
                        end
                    end
                end
            end
            if hasDoEvent == false then
                finishDoEvent = false
            end
            return finishDoEvent, hasDoEvent
        end
    end
    return false, false
end

local function GetFamilyTaskFromAdmin()
    local npc_id = GetFamilyAdminNpcId()
    -- printyellow("GetFamilyTaskFromAdmin:" .. npc_id)

    if PlayerRole:Instance():IsDead() then
        -- printyellow("GetFamilyTaskFromAdmin:role is dead")
        return
    end

    if PlayerRole:Instance():IsNavigating()  or isStartShoutOrPlayCG then
        -- printyellow("GetFamilyTaskFromAdmin exit")
        return
    end

    ShowDlgTask(false)

    isNeedToNavigateToFamilyAdmin = true
    --提前发协议
    local re = lx.gs.task.msg.CGetFamilyTask( { npcid = npc_id })
    -- printt(re)
    network.send(re)
    -- 进入家族驻地
    local familymgr = require "family.familymanager"
    if familymgr.InFamily() then
        familymgr.CEnterFamilyStation(familymgr.EnterType.FamilyTaskNPC,function()
                isNeedToNavigateToFamilyAdmin = false
            end)
    end

    --[[
    -- 寻径到NPC
    local worldmapid
    local pos
    local direction
    worldmapid, pos, direction = charactermanager.GetAgentPositionInCSV(npc_id, CharacterType.Npc)
    if worldmapid and pos then
        isNeedToNavigateToFamilyAdmin = true
        --提前发协议
        local re = lx.gs.task.msg.CGetFamilyTask( { npcid = npc_id })
        --printt(re)
        network.send(re)

        printyellow("role is navigating:worldmapid:" .. worldmapid)
        local mode = 1
        local showalert = true
        PlayerRole:Instance():navigateTo( {
            navMode = mode,
            isShowAlert = showalert,
            targetPos = pos,
            roleId = npc_id,
            mapId = worldmapid,
            eulerAnglesOfRole = direction,
            newStopLength = 1.5*SCALE_SPEED --90,
            isAdjustByRideState = true,
            callback = function()
                SetNpcFaceToRole(npc_id)
                isNeedToNavigateToFamilyAdmin = false
            end
        } )
    else
        printyellow("GetFamilyTaskFromAdmin: error to get NPC position in csv:", tostring(npc_id))
    end
    --]]
end

local function AcceptTask(npc_id, task_id)
    if PlayerRole:Instance():IsDead() then
        return
    end

    if PlayerRole:Instance():IsNavigating() or isStartShoutOrPlayCG then
        return
    end

    local tasktype = GetTaskType(task_id)
    if tasktype == TaskType.Family then
        local familymgr = require("family.familymanager")
        if not familymgr.InFamily() then
            return
        end
        npc_id = GetFamilyNPC(task_id, true)
    end

    isAutoAcceptTask = false
    ShowDlgTask(false)

    local status = GetTaskStatus(task_id)
    if status == TaskStatusType.Accepted then
        if npc_id > 0 then
            if npc_id == GetFamilyAdminNpcId() then
                local familymgr = require "family.familymanager"
                if familymgr.InFamily() then
                    familymgr.CEnterFamilyStation(familymgr.EnterType.FamilyTaskNPC, function()
                        -- 接任务
                        if not PlayerRole:Instance():IsDead() then
                            SetCurTask(task_id)
                            if uimanager.isshow("dlgdialogbox_disconnetion") == false then
                                uimanager.showdialog("dlgtasktalk", { taskid = task_id })
                            end
                        end
                    end )
                end
            else
                LeaveFamilyStationProc( function()
                    -- 寻径到NPC
                    local worldmapid
                    local pos
                    local direction
                    worldmapid, pos, direction = charactermanager.GetAgentPositionInCSV(npc_id, CharacterType.Npc)
                    if worldmapid and pos then
                        -- printt(pos)
                        -- printyellow("role is navigating:worldmapid:" .. worldmapid)
                        local mode = 2
                        local showalert = true
                        mode, showalert = GetNavMode(task_id)
                        PlayerRole:Instance():navigateTo( {
                            navMode = mode,
                            isShowAlert = showalert,
                            targetPos = pos,
                            roleId = npc_id,
                            mapId = worldmapid,
                            eulerAnglesOfRole = direction,
                            newStopLength = 120,
                            isAdjustByRideState = true,
                            callback = function()
                                if not PlayerRole:Instance():IsDead() then
                                    SetNpcFaceToRole(npc_id)
                                    -- 接任务
                                    SetCurTask(task_id)
                                    if uimanager.isshow("dlgdialogbox_disconnetion") == false then
                                        uimanager.showdialog("dlgtasktalk", { taskid = task_id })
                                    end
                                end
                            end
                        } )
                    else
                        -- printyellow("AcceptTask:error to GetAgentPositionInCSV:", tostring(npc_id))
                    end
                end )
            end
        else
            -- 没有NPC，直接做任务
            -- printyellow("DoTask")
            SetTaskStatus(task_id, TaskStatusType.Doing)
            -- 喊话
            isStartShoutOrPlayCG = true
            SetShoutDialogue(task_id, function()
                -- 播放CG
                PlayCG(GetTask(task_id), cfg.task.EPlayingCGType.WHEN_ACCEPTING, function()
                    -- 执行任务
                    isStartShoutOrPlayCG = false
                    DoTask(task_id)
                end )
            end )
        end
    elseif status == TaskStatusType.Doing then
        DoTask(task_id)
    else
        -- 环任务
        if tasktype == TaskType.Family then
            npc_id = GetFamilyNPC(task_id, false)
            local re = lx.gs.task.msg.CAcceptFamilyTask( { npcid = npc_id, taskid = task_id })
            --printt(re)
            network.send(re)
        else
            -- 主线或支线任务
            if IsCanAcceptTask(task_id) then
                local re = lx.gs.task.msg.CAcceptTask( { npcid = npc_id, taskid = task_id })
                --printt(re)
                network.send(re)
            else
                uimanager.showdialog("welfare.dlgwelfaremain",nil,4)
            end

        end

    end

end

local function EndTask(task_id)
    local task = GetTask(task_id)
    -- 播放喊话
    isStartShoutOrPlayCG = true
    SetShoutDialogue(task_id, function()
        -- 播放完成任务CG动画
        PlayCG(task, cfg.task.EPlayingCGType.WHEN_COMPLETING, function()
            effectmanager.PlayEffect { id = 51016, casterId = PlayerRole:Instance():GetId(), targetId = PlayerRole:Instance():GetId(), targetPos = PlayerRole:Instance():GetPos(), bSkill = false }

            isStartShoutOrPlayCG = false
            modulelockmanager.OnCompleteTask(task_id)
			SetExecutingTask(0)
            NoviceGuideTrigger.CompleteTask(task_id)
            -- 自动接取下一个任务
			local tasktype = GetTaskType(task_id);
            local nextTask = GetNextTask(task_id, tasktype)
            if nextTask then
				while GetTaskStatus(nextTask.id) ~= TaskStatusType.None do
					nextTask = GetNextTask(nextTask.id, tasktype)
				end
				
				if GetTaskStatus(nextTask.id) == TaskStatusType.None then
					SetAutoAcceptTask(nextTask.id)
					SetExecutingTask(nextTask.id)
					isNeedToNavigateToFamilyAdmin = false
				end
                
            end
        end )
    end )
end

CompleteTask = function(npc_id, task_id)
     printyellow("CompleteTask id:" .. task_id)
    if GetTaskStatus(task_id) == TaskStatusType.Completed then
        EndTask(task_id)
    else
        local tasktype = GetTaskType(task_id)
        if tasktype == TaskType.Family then
            local familymgr = require "family.familymanager"
            if not familymgr.InFamily() then
                return
            end

            npc_id = GetFamilyNPC(task_id,false)
            local curRingCount =  GetFamilyTaskRingCount()

            local re = lx.gs.task.msg.CCompleteFamilyTask( { npcid = npc_id, taskid = task_id, curtaskorder = curRingCount })
            --printt(re)
            network.send(re)
        else
            local re = lx.gs.task.msg.CCompleteTask( { npcid = npc_id, taskid = task_id })
            --printt(re)
            network.send(re)
        end
    end
end

local function CancelTask(task_id,callback)
    local status = GetTaskStatus(task_id)
    if status ~= TaskStatusType.Completed and status ~= TaskStatusType.None then
        cancelTaskCallback = callback
        local tasktype = GetTaskType(task_id)
        if tasktype == TaskType.Family then
            local curRingCount =  GetFamilyTaskRingCount()
            local re = lx.gs.task.msg.CCancelFamilyTask( { taskid = task_id,curtaskorder = curRingCount})
            --printt(re)
            network.send(re)
        else
            local re = lx.gs.task.msg.CCancelTask( { taskid = task_id })
            --printt(re)
            network.send(re)
        end
    end
end

LeaveFamilyStationProc = function(callback)
    callback()
end

NavigateToRewardNPC = function(npc_id, task_id)
    -- printyellow("NavigateToRewardNPC:" .. npc_id)

    if PlayerRole:Instance():IsDead() then
        -- printyellow("NavigateToRewardNPC:role is dead")
        return
    end

    if PlayerRole:Instance():IsNavigating() or isStartShoutOrPlayCG then
        PlayerRole:Instance():stop()
    end

    if PlayerRole:Instance():IsAttacking() then
        PlayerRole:Instance():stop()
    end

    ShowDlgTask(false)

    local familymgr = require("family.familymanager")
    local tasktype = GetTaskType(task_id)
    if tasktype == TaskType.Family then
        if not familymgr.InFamily() then
            return
        end
        npc_id = GetFamilyNPC(task_id, false)
    end

    -- 没有配NPC
    if npc_id <= 0 then
        CompleteTask(-1, task_id)
        return
    end

    if task_id > 0 then
        if npc_id == GetFamilyAdminNpcId() then
            if familymgr.InFamily() then
                familymgr.CEnterFamilyStation(familymgr.EnterType.FamilyTaskNPC, function()
                    -- 环任务特殊处理
                    if not PlayerRole:Instance():IsDead() then
                        if uimanager.isshow("dlgdialogbox_disconnetion") == false then
                            uimanager.showdialog("dlgtasktalk", { taskid = task_id })
                        end
                    end
                end )
            end
        else
            LeaveFamilyStationProc(function()
                -- 寻径到NPC
                local worldmapid
                local pos
                local direction
                worldmapid, pos, direction = charactermanager.GetAgentPositionInCSV(npc_id, CharacterType.Npc)
                if worldmapid and pos then
                    -- printyellow("role is navigating")
                        -- printt(pos)

                    local mode = 2
                    local showalert = true
                    mode, showalert = GetNavMode(task_id)
                    PlayerRole:Instance():navigateTo( {
                        navMode = mode,
                        isShowAlert = showalert,
                        targetPos = pos,
                        roleId = npc_id,
                        mapId = worldmapid,
                        eulerAnglesOfRole = direction,
                        newStopLength = 120,
                        isAdjustByRideState = true,
                        callback = function()
                            if not PlayerRole:Instance():IsDead() then
                                SetNpcFaceToRole(npc_id)
                                if tasktype == TaskType.Family then
                                    -- 环任务特殊处理
                                    if uimanager.isshow("dlgdialogbox_disconnetion") == false then
                                        uimanager.showdialog("dlgtasktalk", { taskid = task_id })
                                    end
                                else
                                    -- 领奖
                                    if uimanager.isshow("dlgdialogbox_disconnetion") == false then
                                        uimanager.showdialog("dlgtaskreward", { taskid = task_id })
                                    end
                                end
                            end
                        end
                    } )
                else
                    -- printyellow("NavigateToRewardNPC:error to GetAgentPositionInCSV:", tostring(npc_id))
                end

            end )
        end
    end
end


local function IsGetFamilyWeekSpecialReward(index)
    if familyWeekSpecialRewardHistroy and familyWeekSpecialRewardHistroy[index] then
        return true
    end

    return false
end


local function OnMsgSHistroyTask(msg)
    printyellow("OnMsgSHistroyTask")
    printt(msg)
    historyTask = msg

    npcShowHideInfo = { }
    hideMines = { }
    curFamilyTaskGroup = { }

    for _, bonuslvl in pairs(msg.receivedweekbonus) do
        familyWeekSpecialRewardHistroy[bonuslvl] = true
    end

    -- 服务器给过来的历史任务
    for _, id in pairs(historyTask.allcandobranch) do
         if id then
            canAcceptBranchTaskIDs[id] = id
         end
    end

    if historyTask.guidebranchtaskid > 0 and canAcceptBranchTaskIDs[historyTask.guidebranchtaskid] then
        guideBranchTaskID = historyTask.guidebranchtaskid
    end

    if historyTask.iscanclefamtask and historyTask.lastgiveuofamtime > 0 then
        local curTime = timeutils.GetServerTime()*1000
        --printyellow("local time:"..curTime.."  server time:"..historyTask.lastgiveuofamtime)
        if curTime > historyTask.lastgiveuofamtime then
            local pastTime = math.floor((curTime - historyTask.lastgiveuofamtime)/1000)
            -- printyellow("pastTime:"..pastTime)
            if pastTime < GetFamilyTaskRefreshTime() then
                cancelFamilyTaskStartTime = os.time() - pastTime
                isCancelFamilyTask = true
            end
        end
    end

    -- 环任务
    SetDayFinishedFamilyTaskCount(historyTask.comdaycycle * maxFamilyTaskRingCount + historyTask.completefamtasknum)
    SetWeekFinishedFamilyTaskCount(historyTask.comweeksmallcycle)

    local index = 1
    local lastTaskNpcId = GetFamilyAdminNpcId()
    for _, familytaskinfo in pairs(historyTask.curfamtasks) do
        if index <= GetMaxFamilyTaskRingCount() then
            curFamilyTaskGroup[index] = familytaskinfo.taskid
            SetFamilyNPC(familytaskinfo.taskid,lastTaskNpcId,familytaskinfo.npcid)
            lastTaskNpcId = familytaskinfo.npcid
            if index <= historyTask.completefamtasknum then
                SetTaskStatus(familytaskinfo.taskid, TaskStatusType.Completed, true)
            end
        else
            break
        end
        index = index + 1
    end

    -- 已完成任务
	for taskid, value in pairs(historyTask.allcompletehistory) do
        if taskid and taskid > 0 then
            AllTaskTaskStatus(taskid, TaskStatusType.Completed)
		end
	end
	
    for taskid, value in pairs(historyTask.completehistory) do
        if taskid and taskid > 0 then
            SetTaskStatus(taskid, TaskStatusType.Completed, true)
            local tasktype = GetTaskType(taskid)
            local nexttask = GetNextTask(taskid, tasktype)
            if nexttask then
				while GetTaskStatus(nexttask.id) ~= TaskStatusType.None do
					nexttask = GetNextTask(nexttask.id, tasktype)
				end
				if GetTaskStatus(nexttask.id) == TaskStatusType.None then
					SetCurTask(nexttask.id)
				end
            elseif nexttask == nil and tasktype ~= TaskType.Branch then
                -- 本条线做完了，保留任务（支线除外）
                SetCurTask(taskid)
            end
        end
    end

    -- 已接任务
    local isAcceptFamilyTask = false
    for _, taskinfo in pairs(historyTask.acceptedtasks) do
        if taskinfo and taskinfo.taskid ~= 0 then
            taskProgressCounter[taskinfo.taskid] = taskinfo.counter
            local isFinished = false
            local isDoing = false
            isFinished, isDoing = IsTaskCanBeUncommited(taskinfo.taskid)
            if isFinished then
                DoTaskWhenUnCommitted(taskinfo.taskid)
            else
                SetTaskStatus(taskinfo.taskid, TaskStatusType.Doing)
                --[[
                elseif isDoing then
                    SetTaskStatus(taskinfo.taskid, TaskStatusType.Doing)
                else
                    SetTaskStatus(taskinfo.taskid, TaskStatusType.Accepted)
                --]]
            end

            SetCurTask(taskinfo.taskid)
            if GetTaskType(taskinfo.taskid) == TaskType.Family then
                local ringCount = historyTask.completefamtasknum + 1
                SetFamilyTaskRingCount(ringCount)
                isAcceptFamilyTask = true
            end
        end
    end

    -- 环任务已获取但未接时
    if not isAcceptFamilyTask and historyTask.completefamtasknum >= 0 and table.getn(historyTask.curfamtasks) >  historyTask.completefamtasknum then
        SetFamilyTaskRingCount(historyTask.completefamtasknum)
        SetCurTask(historyTask.curfamtasks[historyTask.completefamtasknum+1].taskid)
    end

    -- 专有NPC显隐记录
    for _, npcid in pairs(historyTask.shownpcs) do
        if npcid and npcid > 0 then
            npcShowHideInfo[npcid] = true
            local character = charactermanager.GetCharacterByCsvId(npcid)
            if character then
                character:Show()
            end
        end
    end


    -- 任务矿隐藏记录
    for _, mineid in pairs(historyTask.hidemines) do
        if mineid and mineid > 0 then
            hideMines[mineid] = true
        end
    end

    isGetHistroyTaskFromServer = true

    if uimanager.hasloaded("dlguimain") then
        uimanager.call("dlguimain","RefreshTaskList")
    end

    if uimanager.hasloaded("dlgtask") then
        uimanager.call("dlgtask","UpdateFamilyTaskCaseStatus")
    end
end

local function OnMsgSAcceptTask(msg)
    if PlayerRole:Instance():IsNavigating() then
        return
    end

    if msg and msg.taskid > 0 then
        local npcid = msg.npcid
        local tasktype = GetTaskType(msg.taskid)
        if tasktype == TaskType.Family then
            npcid = GetFamilyNPC(msg.taskid, true)
        end

        local oldTaskStatus = GetTaskStatus(msg.taskid)

        if npcid > 0 then
            SetTaskStatus(msg.taskid, TaskStatusType.Accepted,false,true)
        else
            SetTaskStatus(msg.taskid, TaskStatusType.Accepted)
        end

        SetCurTask(msg.taskid)

        if GetTaskType(msg.taskid) == TaskType.Family and oldTaskStatus == TaskStatusType.None then
            local curOrder = GetFamilyTaskRingCount()
            if curOrder < GetMaxFamilyTaskRingCount() then
                curOrder = curOrder + 1
            else
                curOrder = 1
            end
            SetFamilyTaskRingCount(curOrder)
        end

        ShowDlgTask(false)

        if npcid > 0 then
            if npcid == GetFamilyAdminNpcId() then
                local familymgr = require "family.familymanager"
                if familymgr.InFamily() then
                    familymgr.CEnterFamilyStation(familymgr.EnterType.FamilyTaskNPC, function()
                        -- 接任务
                        if not PlayerRole:Instance():IsDead() then
                            uimanager.showdialog("dlgtasktalk", { taskid = msg.taskid })
                        end
                    end )
                end
            else
                LeaveFamilyStationProc( function()
                    -- 寻径到NPC
                    local worldmapid
                    local pos
                    local direction
                    worldmapid, pos, direction = charactermanager.GetAgentPositionInCSV(npcid, CharacterType.Npc)
                    if worldmapid and pos then
                        -- printt(pos)
                        -- printyellow("role is navigating:worldmapid:" .. worldmapid)

                        local mode = 2
                        local showalert = true
                        mode, showalert = GetNavMode(msg.taskid)
                        PlayerRole:Instance():navigateTo( {
                            navMode = mode,
                            isShowAlert = showalert,
                            targetPos = pos,
                            roleId = npcid,
                            mapId = worldmapid,
                            eulerAnglesOfRole = direction,
                            newStopLength = 120,
                            isAdjustByRideState = true,
                            callback = function()
                                if not PlayerRole:Instance():IsDead() then
                                    SetNpcFaceToRole(npcid)
                                    -- 接任务
                                    uimanager.showdialog("dlgtasktalk", { taskid = msg.taskid })
                                end
                            end
                        } )
                    else
                        RefreshNPCShowHide(GetTask(msg.taskid))
                    end
                end )
            end
        else
            -- 不导航，直接做任务
            SetTaskStatus(msg.taskid, TaskStatusType.Doing)
            -- 喊话
            isStartShoutOrPlayCG = true
            SetShoutDialogue(msg.taskid, function()
                -- 播放CG
                PlayCG(GetTask(msg.taskid), cfg.task.EPlayingCGType.WHEN_ACCEPTING, function()
                    -- 执行任务
                    isStartShoutOrPlayCG = false
                    DoTask(msg.taskid)
                end )
            end )
        end

        uimanager.call("dlguimain","RefreshTaskList")
    end
end

local function OnMsgSGetFamilyTask(msg)
    -- printyellow("OnMsgSGetFamilyTask")
    -- printt(msg)

    if msg.taskinfo and msg.taskinfo.taskid > 0 and msg.taskinfo.npcid > 0 then
        local curOrder = GetFamilyTaskRingCount()
        if curOrder == GetMaxFamilyTaskRingCount() then
            SetFamilyTaskRingCount(0)
            curFamilyTaskGroup = { }
            curOrder = 0
        end
        curFamilyTaskGroup[curOrder + 1] = msg.taskinfo.taskid
        SetFamilyNPC(msg.taskinfo.taskid,GetFamilyAdminNpcId(),msg.taskinfo.npcid)
        SetCurTask(msg.taskinfo.taskid)
        SetAutoAcceptTask(msg.taskinfo.taskid)

        uimanager.call("dlguimain","RefreshTaskList")
    end

end

local function OnMsgSCompleteTask(msg)
    -- printyellow("OnMsgSCompleteTask")
    -- printt(msg)
    SetTaskStatus(msg.taskid, TaskStatusType.Completed)
    uimanager.call("dlguimain","RefreshTaskList")
    EndTask(msg.taskid)
end


local function OnMsgSCompleteFamilyTask(msg)
    -- printyellow("OnMsgSCompleteFamilyTask")
    -- printt(msg)

    SetDayFinishedFamilyTaskCount(msg.comdaycycle*maxFamilyTaskRingCount+msg.completefamtasknum)
    SetWeekFinishedFamilyTaskCount(msg.comweeksmallcycle)

    if msg.nextfamtask and msg.nextfamtask.taskid > 0 and msg.nextfamtask.npcid > 0 and msg.curtaskorder > 0 and msg.curtaskorder < GetMaxFamilyTaskRingCount() then
        curFamilyTaskGroup[msg.curtaskorder+1] = msg.nextfamtask.taskid
        SetFamilyNPC(msg.nextfamtask.taskid,GetFamilyNPC(msg.taskid,false),msg.nextfamtask.npcid)
        SetFamilyTaskRingCount(msg.curtaskorder)
    elseif msg.curtaskorder == GetMaxFamilyTaskRingCount() then
        curFamilyTaskID = 0
        SetFamilyTaskRingCount(0)
        curFamilyTaskGroup = {}
    end

    SetTaskStatus(msg.taskid, TaskStatusType.Completed)
    uimanager.call("dlguimain","RefreshTaskList")
    if uimanager.isshow("dlgtask") then
        uimanager.call("dlgtask","UpdateFamilyTaskCaseStatus")
    end
    EndTask(msg.taskid)
end

local function ShowMineral(taskid)
    local task = GetTask(taskid)
    if task and table.getn(task.complete.finishspecialevent) > 0 then
        for _, item in pairs(task.complete.finishspecialevent) do
            if item and item.eventtype == cfg.task.EFinishSpecialEventType.MINING then
                charactermanager.HideNearestCharacterByCsvId(item.id,false)
            end
        end
    end
end

local function OnMsgSCancelTask(msg)
    -- printyellow("OnMsgSCancelTask")
    -- printt(msg)

    delayFindAgentId = 0
    delayFindAgentStartTime = -1
    uimanager.call("dlguimain","SwitchAutoFight",false)
    if gotoLocationTaskId == msg.taskid then
        curCancelTaskId = msg.taskid
    else
        curCancelTaskId = 0
        SetTaskStatus(msg.taskid, TaskStatusType.None)
    end

    ShowMineral(msg.taskid)
    uimanager.call("dlguimain","RefreshTaskList")

    if cancelTaskCallback then
        cancelTaskCallback(msg.taskid)
        cancelTaskCallback = nil
    end

end


local function OnMsgSCancelFamilyTask(msg)
    -- printyellow("OnMsgSCancelFamilyTask")
    -- printt(msg)

    delayFindAgentId = 0
    delayFindAgentStartTime = -1
    uimanager.call("dlguimain","SwitchAutoFight",false)

    if gotoLocationTaskId == msg.taskid then
        curCancelTaskId = msg.taskid
    else
        curCancelTaskId = 0
        SetTaskStatus(msg.taskid, TaskStatusType.None)
    end

    curFamilyTaskID = 0
    if msg.curtaskorder > 0 then
        curFamilyTaskGroup[msg.curtaskorder] = nil
        SetFamilyTaskRingCount(msg.curtaskorder-1)
    end

    ShowMineral(msg.taskid)
    uimanager.call("dlguimain","RefreshTaskList")

    cancelFamilyTaskStartTime = os.time()
    isCancelFamilyTask = true
    if cancelTaskCallback then
        cancelTaskCallback(msg.taskid)
        cancelTaskCallback = nil
    end
end

GetCancelFamilyTaskStartTime =  function ()
    return cancelFamilyTaskStartTime
end

IsCancelFamilyTask = function ()
    return isCancelFamilyTask
end

ResetCancelFamilyTaskStatus = function ()
     isCancelFamilyTask = false
     cancelFamilyTaskStartTime = 0
end


local function QuickCompleteFamilyTask()
    local curOrder = GetFamilyTaskRingCount()
    -- printyellow("QuickCompleteFamilyTask:"..curOrder)
    ShowDlgTask(false)
    local re = lx.gs.task.msg.CCompleteFamTaskWithYuanbao( { curtaskorder = curOrder})
    network.send(re)
end

local function ClearFamilyTask(callback)
    -- printyellow("ClearFamilyTask")
    clearFamilyTaskCallback = callback
    local re = lx.gs.task.msg.CClearFamTask()
    network.send(re)
end

local function GetFamilyWeekSpecialReward(index,callback)
    -- printyellow("GetFamilyWeekSpecialReward")
    getFamilyWeekSpecialRewardCallback = callback
    local re = lx.gs.task.msg.CGetWeekCompleteBonus({ bonuslvl = index })
    network.send(re)
end

local function OnMsgSCompleteFamTaskWithYuanbao(msg)
    -- printyellow("OnMsgSCompleteFamTaskWithYuanbao")
    -- printt(msg)
    if msg.curtaskorder and curFamilyTaskGroup[msg.curtaskorder] then
        --[[test code
        local taskid = curFamilyTaskGroup[msg.curtaskorder]
        local npcid = GetFamilyNPC(taskid,false)
        CompleteTask(npcid, taskid)
        --]]
        DoTaskWhenUnCommitted(curFamilyTaskGroup[msg.curtaskorder],true)
        uimanager.call("dlguimain","RefreshTaskList")
    end
end

local function OnMsgSClearFamTask(msg)
    -- printyellow("OnMsgSClearFamTask")
    -- printt(msg)

    SetDayFinishedFamilyTaskCount(msg.comdaycycle*maxFamilyTaskRingCount)
    SetWeekFinishedFamilyTaskCount(msg.comweeksmallcycle)

    if curFamilyTaskID > 0 then
        SetTaskStatus(curFamilyTaskID, TaskStatusType.Completed)
        curFamilyTaskID = 0
        SetFamilyTaskRingCount(0)
        curFamilyTaskGroup = {}
    end

    uimanager.call("dlguimain","RefreshTaskList")

    if clearFamilyTaskCallback then
        clearFamilyTaskCallback()
    end
end

local function OnMsgSDailyResetFamTaskNotify(msg)
    -- printyellow("OnMsgSDailyResetFamTaskNotify")
    -- printt(msg)

    curFamilyTaskID = 0
    SetFamilyTaskRingCount(0)
    curFamilyTaskGroup = {}
    SetDayFinishedFamilyTaskCount(0)
    SetWeekFinishedFamilyTaskCount(msg.comweeksmallcycle)
    uimanager.call("dlguimain","RefreshTaskList")
end

local function OnMsgSChooseShowBranchTask(msg)
    -- printyellow("OnMsgSChooseShowBranchTask")
    -- printt(msg)
end

local function  OnMsgSAddNewBranchTaskNotify(msg)
    -- printyellow("OnMsgSAddNewBranchTaskNotify")
    -- printt(msg)
    for _, id in pairs(msg.newtask) do
         if id then
            canAcceptBranchTaskIDs[id] = id
         end
    end
    uimanager.call("dlguimain","RefreshTaskList")
end

local function  OnMsgSCancelHideMinesNotify(msg)
    -- printyellow("OnMsgSCancelHideMinesNotify")
    -- printt(msg)

    for _, mineid in pairs(msg.unhideminse) do
        if mineid and mineid > 0 then
            hideMines[mineid] = nil
            charactermanager.ShowCharactersByCsvId(mineid)
        end
    end
end


local function OnMsgSGetWeekCompleteBonus(msg)
    -- printyellow("OnMsgSGetWeekCompleteBonus")
    -- printt(msg)
    familyWeekSpecialRewardHistroy[msg.bonuslvl] = true
    if getFamilyWeekSpecialRewardCallback then
        getFamilyWeekSpecialRewardCallback(msg.bonus)
    end
    if uimanager.hasloaded("dlgtask") then
        uimanager.call("dlgtask","UpdateFamilyTaskCaseStatus")
    end
end

local function OnMsgSOpenTaskEctype(msg)
    -- printyellow("OnMsgSOpenTaskEctype")
    -- printt(msg)
end


DoTaskWhenUnCommitted = function(taskid,forceFinishTask)
    -- printyellow("DoTaskWhenUnCommitted")
    local task = GetTask(taskid)
    if not task then
        return
    end

    SetTaskStatus(taskid, TaskStatusType.UnCommitted)

    -- 需要隐藏未采的矿物
    if table.getn(task.complete.finishspecialevent) > 0 then
        for _, item in pairs(task.complete.finishspecialevent) do
            if item and item.eventtype == cfg.task.EFinishSpecialEventType.MINING then
                hideMines[item.id] = true
            end
        end
    end

    -- 喊话
    if isGetHistroyTaskFromServer then
        isStartShoutOrPlayCG = true
        SetShoutDialogue(taskid, function()
            -- 播放CG动画
            PlayCG(task, cfg.task.EPlayingCGType.WHEN_UNCOMMITTED, function()
                isStartShoutOrPlayCG = false
                local familyTaskNpc = GetFamilyNPC(taskid,false)
                if forceFinishTask and familyTaskNpc and familyTaskNpc > 0 then
                    NavigateToRewardNPC(familyTaskNpc,taskid)
                else
                    AutoFinishTask(taskid)
                end
            end )
        end )
    end
end

local function OnMsgSChangeTask(msg)
    -- printyellow("OnMsgSChangeTask")
    -- printt(msg)
    if msg.task then
        taskProgressCounter[msg.task.taskid] = msg.task.counter

        -- 判断任务是否可交（后续需要完善）
        -- 当杀怪或采矿任务时才需要，对话任务需等待对话结束（会自动设置任务状态）
        local isFinished = false
        local isDoing = false
        isFinished, isDoing = IsTaskCanBeUncommited(msg.task.taskid)
        local task = GetTask(msg.task.taskid)
        if isFinished then
            if task and table.getn(task.complete.killmonster) > 0 then
                uimanager.call("dlguimain", "SwitchAutoFight", false)
            end

            DoTaskWhenUnCommitted(msg.task.taskid)
        elseif isDoing then
            -- 继续自动采矿
            if task and table.getn(task.complete.finishspecialevent) > 0 then
                local mineid = 0;
                for _, item in pairs(task.complete.finishspecialevent) do
                    if item and item.id > 0 and item.eventtype == cfg.task.EFinishSpecialEventType.MINING then
                        mineid = item.id
                        break
                    end
                end
                if mineid > 0 then
                    FindAgent(mineid,CharacterType.Mineral,task.id)
                end
            end
        end

        uimanager.call("dlguimain","RefreshTaskList")
    end
end

local function GetKilledMonsterDesc(task, taskStatus)
    if not task or not taskStatus then
        return nil
    end

    local itemmanager = require "item.itemmanager"
    local desc = ""
    if taskStatus ~= TaskStatusType.None and table.getn(task.complete.killmonster) > 0 then
        for _, item in pairs(task.complete.killmonster) do
            if item then
                -- 若有收集掉落物品则以它的计数为准
                if item.dropitemid > 0 and item.dropitemcount > 0 then
                    local itemdata = itemmanager.GetItemData(item.dropitemid)
                    if itemdata then
                        if desc ~= "" then
                            desc = desc .. "\n   "
                        end
                        if taskStatus == TaskStatusType.UnCommitted or taskStatus == TaskStatusType.Completed then
                            desc = desc .. itemdata.name .. "(" .. item.dropitemcount .. "/" .. item.dropitemcount .. ")"
                        else
                            local collectedCount = GetTaskProgressCount(task.id, item.dropitemid)
                            collectedCount =(collectedCount > item.dropitemcount) and item.dropitemcount or collectedCount
                            desc = desc .. itemdata.name .. "(" .. collectedCount .. "/" .. item.dropitemcount .. ")"
                        end
                    end
                elseif item.monsterid > 0 and item.monstercount > 0 then
                    local monster = GetMonsterData(item.monsterid)
                    if monster then
                        if desc ~= "" then
                            desc = desc .. "\n   "
                        end
                        if taskStatus == TaskStatusType.UnCommitted or taskStatus == TaskStatusType.Completed then
                            desc = desc .. monster.name .. "(" .. item.monstercount .. "/" .. item.monstercount .. ")"
                        else
                            local killedCount = GetTaskProgressCount(task.id, item.monsterid)
                            killedCount =(killedCount > item.monstercount) and item.monstercount or killedCount
                            desc = desc .. monster.name .. "(" .. killedCount .. "/" .. item.monstercount .. ")"
                        end
                    end
                end
            end
        end
    end
    return desc
end

local function GetDiggedMineDesc(task, taskStatus)
    if not task or not taskStatus then
        return nil
    end

    local itemmanager = require "item.itemmanager"
    local desc = ""
    if taskStatus ~= TaskStatusType.None and table.getn(task.complete.finishspecialevent) > 0 then
        local miningmanager = require "miningmanager"
        for _, item in pairs(task.complete.finishspecialevent) do
            if item and item.eventtype == cfg.task.EFinishSpecialEventType.MINING then
                local mine = miningmanager.GetMineralData(item.id)
                if mine then
                    if desc ~= "" then
                        desc = desc .. "\n   "
                    end
                    if taskStatus == TaskStatusType.UnCommitted or taskStatus == TaskStatusType.Completed then
                        desc = desc .. mine.name .. "(" .. item.count .. "/" .. item.count .. ")"
                    else
                        local diggedCount = GetTaskProgressCount(task.id, item.id)
                        diggedCount =(diggedCount > item.count) and item.count or diggedCount
                        desc = desc .. mine.name .. "(" .. diggedCount .. "/" .. item.count .. ")"
                    end
                end
            end
        end
    end
    return desc
end


local function update()
    -- printyellow("update")

    --延时找怪/矿物
    if delayFindAgentStartTime > 0 and (Time.time - delayFindAgentStartTime) >= 2 then
        character = charactermanager.GetNearestCharacterByCsvId(delayFindAgentId)
        if character then
            delayFindAgentId = 0
            delayFindAgentStartTime = -1
            NavigateToTarget(character)
        elseif (Time.time - delayFindAgentStartTime) >= 6 then
            delayFindAgentId = 0
            delayFindAgentStartTime = -1
        end
    end

    -- 自动接取任务
    if isAutoAcceptTask and(Time.time - startTime >= totalTime) then
        if not isNeedToNavigateToFamilyAdmin then
            local task = GetTask(autoAcceptTaskId)
            if task and GetTaskStatus(taskid) == TaskStatusType.None then
                isAutoAcceptTask = false
                startTime = 0.0
                AcceptTask(task.accept.npcid, task.id)
            end
        elseif Time.time - startTime >= 300 then
            isAutoAcceptTask = false
            startTime = 0.0
            isNeedToNavigateToFamilyAdmin = false
        end
    end

    -- 喊话逻辑
    if isStartShout and(Time.time - startTimeShout >= totalTimeShout) and ectypemanager.IsInEctype() == false then
        startTimeShout = Time.time
        if uimanager.isshow("dlgstorycopy_talk") then
            uimanager.hide("dlgstorycopy_talk")
        end

        local task = GetTask(shoutDialogTaskId)
        if task and shoutDialogIndex > 0 then
            local dialoginfo = nil
            local status = GetTaskStatus(shoutDialogTaskId)
            if (status == TaskStatusType.Accepted or status == TaskStatusType.Doing) and table.getn(task.basic.shoutaccepted) >= shoutDialogIndex then
                dialoginfo = task.basic.shoutaccepted[shoutDialogIndex]
                shoutDialogIndex = shoutDialogIndex + 1
            elseif status == TaskStatusType.UnCommitted and table.getn(task.basic.shoutuncommitted) >= shoutDialogIndex then
                dialoginfo = task.basic.shoutuncommitted[shoutDialogIndex]
                shoutDialogIndex = shoutDialogIndex + 1
            elseif status == TaskStatusType.Completed and table.getn(task.basic.shoutcompleted) >= shoutDialogIndex then
                dialoginfo = task.basic.shoutcompleted[shoutDialogIndex]
                shoutDialogIndex = shoutDialogIndex + 1
            end

            if dialoginfo then
                totalTimeShout =(dialoginfo.delay >= 2) and dialoginfo.delay or 2

                local charactername = nil
                local characterimage = nil
                local characterside =(dialoginfo.pos == cfg.task.EDialoguePosType.LEFT) and 0 or 1
                if dialoginfo.role == cfg.task.EDialogueRoleType.NPC then
                    local npc = GetNpcData(dialoginfo.npcid)
                    if npc then
                        charactername = npc.name
                        local modeldata = configmanager.getConfigData("model", npc.modelname)
                        if modeldata then
                            characterimage = modeldata.headicon
                        end
                    end
                else
                    charactername = PlayerRole:Instance().m_Name
                    characterimage = PlayerRole:Instance():GetHeadIcon()
                end

                local audioid = nil
                if dialoginfo.voiceid > 0 then
                    audioid = GetDialogueAudioClipId(dialoginfo.voiceid)
                end

                uimanager.show("dlgstorycopy_talk", { name = charactername, frameid = dialoginfo.dialogframetype, content = ReplaceWildcard(dialoginfo.dialogcontent), icon = characterimage,audioclipid = audioid })
            else
                -- 结束喊话播放
                isStartShout = false
                if uimanager.isshow("dlgstorycopy_talk") then
                    uimanager.hide("dlgstorycopy_talk")
                end
                if shoutDialogCallback then
                    shoutDialogCallback()
                end
            end
        else
            isStartShout = false
            if shoutDialogCallback then
                shoutDialogCallback()
            end
        end
    end

    -- 到达指定地点判定
    if PlayerRole:Instance():IsNavigating() == false and gotoLocationTaskId > 0 then
        if curCancelTaskId == gotoLocationTaskId then
            SetTaskStatus(gotoLocationTaskId, TaskStatusType.None)
            curCancelTaskId = 0
            gotoLocationTaskId = 0
        else
            local task = GetTask(gotoLocationTaskId)
            if task then
                local status = GetTaskStatus(gotoLocationTaskId)
                if status ~= TaskStatusType.Completed then
                    if scenemanager.GetCurMapId() == task.complete.location.worldmapid then
                        local characterPos = PlayerRole:Instance():GetRefPos()
                        -- printt(characterPos)
                        if (characterPos.x >= task.complete.location.minx and characterPos.x <= task.complete.location.maxx and
                            characterPos.y >= task.complete.location.miny and characterPos.y <= task.complete.location.maxy) then
                            if status ~= TaskStatusType.UnCommitted then
                                SetTaskStatus(gotoLocationTaskId, TaskStatusType.UnCommitted)
                                -- 喊话
                                isStartShoutOrPlayCG = true
                                SetShoutDialogue(gotoLocationTaskId, function()
                                    PlayCG(GetTask(gotoLocationTaskId), cfg.task.EPlayingCGType.WHEN_UNCOMMITTED, function()
                                        isStartShoutOrPlayCG = false
                                        AutoFinishTask(gotoLocationTaskId)
                                    end )
                                end )
                            end
                        else
                            SetTaskStatus(gotoLocationTaskId, TaskStatusType.Doing)
							--DoTask(gotoLocationTaskId)
                        end
                    else
                        SetTaskStatus(gotoLocationTaskId, TaskStatusType.Doing)
                    end
                else
                    gotoLocationTaskId = 0
                end
            end
        end
    end
end

-- 专有NPC是否显隐
local function IsExclusiveNpcShowHide(npcid)
   if npcShowHideInfo[npcid] then
        return true
   else
        return false
   end
end

GetDialogueAudioClipId = function (voiceid)
    local dialogsounddata = configmanager.getConfigData("dialogsound", voiceid)
    if dialogsounddata then
        local audioid = 0
        if dialogsounddata.isplayer then
            local gender = PlayerRole:Instance().m_Gender
            local profession = PlayerRole:Instance().m_Profession
            if gender == defineenum.GenderType.Male then
                if profession == cfg.role.EProfessionType.TIANYINSI then
                    audioid = dialogsounddata.boyaudio
                else
                    audioid = dialogsounddata.maleaudio
                end
            else
                if profession == cfg.role.EProfessionType.TIANYINSI then
                    audioid = dialogsounddata.girlaudio
                else
                    audioid = dialogsounddata.femaleaudio
                end
            end
        else
            audioid = dialogsounddata.npcaudio
        end

        if audioid > 0 then
            return audioid
        end
    end
end


local function DoExecutingTask()
	--------------------------------------------------
	if EctypeManager.IsInEctype() == false and curExecutingTaskID > 0 then
		local task = GetTask(curExecutingTaskID)
		if task then
			local taskStatus = GetTaskStatus(task.id)
			if task and taskStatus ~= TaskStatusType.Completed then
				if taskStatus == TaskStatusType.UnCommitted then
					NavigateToRewardNPC(task.complete.npcid, task.id)
				else
					AcceptTask(task.accept.npcid, task.id)
				end
			end
		end
	end
	--------------------------------------------------
end

local function OnMsgSDayOver(msg)
	-- 清空家族环
	dayFinishedFamilyTaskCount = 0
    curFamilyTaskRingCount = 0
    curFamilyTaskID = 0
end


local function OnLogout()
    curExecutingTaskID = 0
    guideBranchTaskID = 0
    isGetHistroyTaskFromServer = false

    isAutoAcceptTask = false
    gotoLocationTaskId = 0
    curCancelTaskId = 0
    isStartShoutOrPlayCG = false


    dayFinishedFamilyTaskCount = 0
    weekFinishedFamilyTaskCount = 0
    curFamilyTaskRingCount = 0
    allTaskStatus = {}
    curBranchTaskIDs = {}
    familyWeekSpecialRewardHistroy = {}

    delayFindAgentId = 0
    delayFindAgentStartTime = -1
    canAcceptBranchTaskIDs = {}
    curMainlineTaskID  = 0
    curFamilyTaskID = 0
end

local function init()
    -- printyellow("taskmanager init")
    PlayerRole = require "character.playerrole"

    gameevent.evt_update:add(update)
    gameevent.evt_system_message:add("logout", OnLogout)

    npcdata = configmanager.getConfig("npc")
    monsterdata = configmanager.getConfig("monster")
    allTaskData = configmanager.getConfig("task")
    wildcardsexdata = configmanager.getConfig("wildcardsex")
    wildcardprofessiondata = configmanager.getConfig("wildcardprofession")

    local familyConfig = configmanager.getConfig("familytaskconfig")
    if familyConfig then
        maxFamilyTaskRingCount = familyConfig.circletaskamount
        maxDayFamilyTaskCount =  maxFamilyTaskRingCount * familyConfig.daycirclelimit.num
        weekSpecialRewardFamilyTaskCount = familyConfig.weekbonus

        familyTaskOpenLevel = familyConfig.openlevel
        familyAdminNpcId    = familyConfig.npcid
        familyTaskRefreshTime = familyConfig.refreshtime
        useYuanBaoCompleteFamilyTaskCost = familyConfig.completecost.amount
        clearFamilyTaskRingCount = familyConfig.simpleclearamount
    end

    network.add_listeners( {
        { "lx.gs.task.msg.STask", OnMsgSHistroyTask },
        { "lx.gs.task.msg.SAcceptTask", OnMsgSAcceptTask },
        { "lx.gs.task.msg.SCompleteTask", OnMsgSCompleteTask },
        { "lx.gs.task.msg.SCancelTask", OnMsgSCancelTask },
        { "lx.gs.task.msg.SChangeTask", OnMsgSChangeTask },

        { "lx.gs.task.msg.SOpenTaskEctype", OnMsgSOpenTaskEctype },


        { "lx.gs.task.msg.SGetFamilyTask", OnMsgSGetFamilyTask },
        { "lx.gs.task.msg.SAcceptFamilyTask", OnMsgSAcceptTask },
        { "lx.gs.task.msg.SCompleteFamilyTask", OnMsgSCompleteFamilyTask },
        { "lx.gs.task.msg.SCancelFamilyTask", OnMsgSCancelFamilyTask },
        { "lx.gs.task.msg.SCompleteFamTaskWithYuanbao", OnMsgSCompleteFamTaskWithYuanbao },
        { "lx.gs.task.msg.SClearFamTask", OnMsgSClearFamTask },
        { "lx.gs.task.msg.SDailyResetFamTaskNotify", OnMsgSDailyResetFamTaskNotify },
        { "lx.gs.task.msg.SGetWeekCompleteBonus", OnMsgSGetWeekCompleteBonus },


        { "lx.gs.task.msg.SChooseShowBranchTask", OnMsgSChooseShowBranchTask },
        { "lx.gs.task.msg.SAddNewBranchTaskNotify", OnMsgSAddNewBranchTaskNotify },
        { "lx.gs.task.msg.SCancelHideMinesNotify", OnMsgSCancelHideMinesNotify },

        { "lx.gs.role.msg.SDayOver", OnMsgSDayOver },


    } )

    for _, taskdata in pairs(allTaskData) do
        if taskdata then
            if taskdata.basic.tasktype == TaskType.Mainline and next(taskdata.accept.pretaskid) == nil then
                firstMainlineTaskID = taskdata.id
            elseif taskdata.basic.tasktype == TaskType.Branch then
                if next(taskdata.accept.pretaskid) == nil then
                    allFirstBranchTaskIDs[taskdata.id] = taskdata.id
                else
                    local hasBranchTask = false
                    for _, preid in pairs(taskdata.accept.pretaskid) do
                        if GetTaskType(preid) == TaskType.Branch then
                            hasBranchTask = true
                            break
                        end
                    end
                    if hasBranchTask == false then
                        allFirstBranchTaskIDs[taskdata.id] = taskdata.id
                    end
                end
            end
        end
    end
end

return {
    init = init,
    GetTask = GetTask,
    GetNpcData = GetNpcData,
    GetMonsterData = GetMonsterData,
    GetTaskProgressCount = GetTaskProgressCount,
    IsMainlineTask = IsMainlineTask,
    SetTaskStatus = SetTaskStatus,
	AllTaskTaskStatus = AllTaskTaskStatus,
    GetAllTaskStatus = GetAllTaskStatus,
    GetTaskStatus = GetTaskStatus,
    GetTaskType = GetTaskType,
    GetCurTask = GetCurTask,
    IsCanAcceptTask = IsCanAcceptTask,
    GetCanAcceptTask = GetCanAcceptTask,
    SetGuideBranchTaskID = SetGuideBranchTaskID,
    GetGuideBranchTask = GetGuideBranchTask,
    GetGuideBranchTaskID = GetGuideBranchTaskID,
    AcceptTask = AcceptTask,
    CompleteTask = CompleteTask,
    CancelTask = CancelTask,
    GetFamilyTaskFromAdmin = GetFamilyTaskFromAdmin,
    NavigateToRewardNPC = NavigateToRewardNPC,
    FindAgent = FindAgent,
    SetAutoAcceptTask = SetAutoAcceptTask,
    DoTask = DoTask,
    GetKilledMonsterDesc = GetKilledMonsterDesc,
    GetDiggedMineDesc = GetDiggedMineDesc,
    PlayCG = PlayCG,
    SetShoutDialogue = SetShoutDialogue,
    ReplaceWildcard = ReplaceWildcard,
    IsExclusiveNpcShowHide = IsExclusiveNpcShowHide,
    SetNpcStatus = SetNpcStatus,
    GetNpcStatus = GetNpcStatus,
    GetAllNpcStatus = GetAllNpcStatus,

    RefreshNPCShowHide = RefreshNPCShowHide,

    SetFamilyTaskRingCount = SetFamilyTaskRingCount,
    GetFamilyTaskRingCount = GetFamilyTaskRingCount,
    GetMaxFamilyTaskRingCount = GetMaxFamilyTaskRingCount,
    GetFamilyNPC = GetFamilyNPC,
    GetDayFinishedFamilyTaskCount = GetDayFinishedFamilyTaskCount,
    GetWeekFinishedFamilyTaskCount = GetWeekFinishedFamilyTaskCount,
    GetFamilyTaskOpenLevel = GetFamilyTaskOpenLevel,
    GetFamilyAdminNpcId = GetFamilyAdminNpcId,
    GetFamilyTaskRefreshTime = GetFamilyTaskRefreshTime,
    GetClearFamilyTaskRingCount = GetClearFamilyTaskRingCount,
    GetMaxDayFamilyTaskCount = GetMaxDayFamilyTaskCount,
    GetWeekSpecialRewardFamilyTaskCount = GetWeekSpecialRewardFamilyTaskCount,
    GetUseYuanBaoCompleteFamilyTaskCost = GetUseYuanBaoCompleteFamilyTaskCost,
    QuickCompleteFamilyTask = QuickCompleteFamilyTask,
    ClearFamilyTask = ClearFamilyTask,
    GetCancelFamilyTaskStartTime = GetCancelFamilyTaskStartTime,
    IsCancelFamilyTask = IsCancelFamilyTask ,
    ResetCancelFamilyTaskStatus = ResetCancelFamilyTaskStatus,
    IsGetFamilyWeekSpecialReward = IsGetFamilyWeekSpecialReward,
    GetFamilyWeekSpecialReward = GetFamilyWeekSpecialReward,

    GetDialogueAudioClipId = GetDialogueAudioClipId,

    IsMineNeedHide = IsMineNeedHide,
    SetExecutingTask = SetExecutingTask,
	GetExecutingTask = GetExecutingTask,
	DoExecutingTask = DoExecutingTask,
}
