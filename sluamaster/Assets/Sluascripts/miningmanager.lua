local configmanager = require "cfg.configmanager"
local network = require "network"
local uimanager = require "uimanager"
local charactermanager = require "character.charactermanager"
local defineenum = require "defineenum"
local gameevent = require "gameevent"
local taskmanager = require "taskmanager"
local TaskStatusType = defineenum.TaskStatusType
local WorkType          = defineenum.WorkType

local PlayerRole

local mineraldata = nil

local minestatus = { }
local curmineId = 0
local ismining = false
local startTime = 0.0
local startMiningTime = 0.0
local miningCostTime = -1.0
local isSetMineDeath = false

local needHideMineChar = nil

local function GetMineralData(mineid)
    if mineraldata then
        return mineraldata[mineid]
    end
end

local function GetCurMineID()
    return curmineId
end

local function StartMining(id)
    -- printyellow("StartMining:" .. id)
    local re = map.msg.CDigMineBegin( { mineagentid = id })
    network.send(re)
end


local function CancelMining(id)
    -- printyellow("CancelMining:" .. id)
    ismining = false
    local re = map.msg.CDigMineCancel( { mineagentid = id })
    network.send(re)
end

local function StopMining(id)
    -- printyellow("StopMining:" .. id)
    ismining = false
    startMiningTime = 0.0
    miningCostTime = -1.0
    local re = map.msg.CDigMineEnd( { mineagentid = id })
    network.send(re)
end


local function OnMsgSMineChange(msg)
    -- printyellow("OnMsgSMineChange:" .. msg.roleid .. "   state:" .. msg.state)
    minestatus[msg.roleid] = msg.state
end

local function ProgressbarCallback()
    PlayerRole:Instance().WorkMgr:StopWork(WorkType.FreeAction);
end

local function OnMsgSDigMineBegin(msg)
    -- printyellow("OnMsgSDigMineBegin:" .. msg.mineagentid)

    local character = charactermanager.GetCharacter(msg.mineagentid)
    if mineraldata and mineraldata[character.m_CsvId] then
        local waitTime = mineraldata[character.m_CsvId].costtime
        local params = { dur = waitTime, cb = ProgressbarCallback }

        --curmineId 可能是负数
        curmineId = msg.mineagentid
        PlayerRole:Instance():PlayFreeAction(cfg.skill.AnimType.Mining)
        startMiningTime = Time.time
        miningCostTime = waitTime
        uimanager.show("dlgprogressbar", params)
        ismining = true
    end
end

local function OnMsgSDigMineCancel(msg)
     -- printyellow("OnMsgSDigMineCancel:" .. msg.mineagentid)

end

local function OnMsgSDigMineEnd(msg)
    -- printyellow("OnMsgSDigMineEnd:" .. msg.mineagentid)
    local character = charactermanager.GetCharacter(msg.mineagentid)
    if character then
        character:SetDeath()
        startTime = Time.time
        isSetMineDeath = true

        if mineraldata and mineraldata[character.m_CsvId] and mineraldata[character.m_CsvId].requiretaskid > 0 then
            needHideMineChar = character
        end
    end

end


local function IsCanBeMined(id)
    if minestatus[id] and minestatus[id] ~= cfg.mine.MineState.NULL and minestatus[id] ~= cfg.mine.MineState.PROTECTED then
        return true
    elseif not minestatus[id] then
        local character = charactermanager.GetCharacter(id)
        --printyellow("mine state:", tostring(character.id), tostring(character.m_MineralState))
        if character and character.m_MineralState ~= cfg.mine.MineState.NULL and character.m_MineralState ~= cfg.mine.MineState.PROTECTED then
            return true
        end
    end
    return false
end

local function NavigateToMine(id, pos)
    if ismining then
        print("NavigateToMine error: it's mining now!")
        return
    end

    local character = charactermanager.GetCharacter(id)
    if mineraldata and mineraldata[character.m_CsvId] then
        --是否任务物品，且任务未完成
        local bCanCollect = true
        local nTaskId = mineraldata[character.m_CsvId].requiretaskid
        if nTaskId > 0 then
            local taskStatus = taskmanager.GetTaskStatus(nTaskId)
            if taskStatus == TaskStatusType.None or taskStatus == TaskStatusType.Completed or taskStatus == TaskStatusType.UnCommitted then
                bCanCollect = false
            end
        end
        if bCanCollect == false then
            uimanager.ShowSingleAlertDlg{content=LocalString.CanNotCollect}
        else
            local distance = 90
            PlayerRole:Instance():navigateTo( {
                targetPos = pos,
                roleId = id,
                newStopLength = distance,
                isAdjustByRideState = true,
                --eulerAnglesOfRole = character.m_Rotation,
                callback = function()
                    StartMining(id)
                end,
            } )

        end
    end
end




local function update()
    -- if PlayerRole:Instance():IsNavigating() and PlayerRole:Instance():IsAttacking() then
    --    PlayerRole:Instance():stop()
    -- end

    if ismining then
        if miningCostTime > 0.0 and (Time.time - startMiningTime >= miningCostTime) then
            StopMining(curmineId)
        elseif uimanager.isshow("dlgprogressbar") and (PlayerRole:Instance():IsAttacking() or PlayerRole:Instance():IsMoving()) then
            uimanager.destroy("dlgprogressbar")
            CancelMining(curmineId)
            curmineId = 0 
            startMiningTime = 0.0
            miningCostTime = -1.0
        end
    end

    if needHideMineChar and(Time.time - startTime >= 2) then
        needHideMineChar:Hide()

        if mineraldata and mineraldata[needHideMineChar.m_CsvId] then
            local status = taskmanager.GetTaskStatus(mineraldata[needHideMineChar.m_CsvId].requiretaskid)
            if status == TaskStatusType.UnCommitted or status == TaskStatusType.Completed then
                charactermanager.HideNearestCharacterByCsvId(needHideMineChar.m_CsvId, true)
            end
        end

        needHideMineChar = nil
    end
end

local function init()
    gameevent.evt_update:add(update)

    PlayerRole = require "character.playerrole"
    mineraldata = configmanager.getConfig("mineral")

    network.add_listeners( {
        { "map.msg.SMineChange", OnMsgSMineChange },
        { "map.msg.SDigMineBegin", OnMsgSDigMineBegin },
        { "map.msg.SDigMineCancel", OnMsgSDigMineCancel },
        { "map.msg.SDigMineEnd", OnMsgSDigMineEnd },

    } )

end

return {
    init = init,
    NavigateToMine = NavigateToMine,
    IsCanBeMined = IsCanBeMined,
    StartMining = StartMining,
    CancelMining = CancelMining,
    StopMining = StopMining,
    GetCurMineID = GetCurMineID,

    GetMineralData = GetMineralData,
}
