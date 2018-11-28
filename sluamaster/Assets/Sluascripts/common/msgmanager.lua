local gameevent = require "gameevent"
local MsgDefaultInterval = 0.2
local MsgCustomIntervals =
{    
	["gnet.KeepAlive"] = 1,
	["map.msg.CMove"] = 0.0,
    ["map.msg.CSkillPerform"] = 0.0,
	["lx.gs.chat.msg.CChat"] = 1,
    ["lx.gs.team.msg.CCreateTeam"] = 1,
    ["lx.gs.role.msg.CGetRoleInfo"] = 0,
    ["lx.gs.family.msg.CFindFamily"] = 0.0,
    ["lx.gs.talisman.CAddNormalExp"] = 0.2,
	["map.msg.CClientActionEnd"] = 0,
	["map.msg.CCloseLayout"] = 1,
	["map.msg.COpenLayout"] = 1,
    ["lx.gs.task.msg.CAcceptTask"] = 1,
    ["lx.gs.task.msg.CAcceptFamilyTask"] = 1,
	["lx.gs.activity.huiwu.msg.CGetBattleRound"] = 0.0,
	["map.msg.CClientActionEnd"] = 0.0,
    ["map.msg.CPraiseMember"] = 1.5,
	["lx.gs.skill.msg.CEvolveSkill"] = 1,
	["lx.gs.skill.msg.CUpgradeSkill"] = 0.5,
	["lx.gs.cmd.msg.CCommand"] = 0.5,
	["lx.gs.pickcard.msg.CPickCardByType"] = 0.5,
	["lx.gs.map.msg.CGetDailyBestRecord"] = 0,
	["map.msg.CEatRune"] = 0,
	["map.msg.CTransferWorld"] = 1,
	["lx.gs.map.msg.CEnterWorld"] = 1,
}

local m_MsgRecord = {}

local moveMsgCount = 0

local function GetMsgCfgInterval(msg)
    return MsgCustomIntervals[msg._name] or MsgDefaultInterval
end

local function GetMsgLastSendTime(msg)
    return m_MsgRecord[msg._name] or 0
end

local function CheckMsg(msg)
    if msg then
        if Local.MoveCheck then
            if msg._name == "map.msg.CMove" then
                moveMsgCount = moveMsgCount + 1
            end
        end
        local lastsendtime = GetMsgLastSendTime(msg)
        if lastsendtime and Time.time-lastsendtime < GetMsgCfgInterval(msg) then
            return false
        else
            m_MsgRecord[msg._name] = Time.time
            return true
        end

    else
        return false
    end
end

local function second_update()
    if Local.MoveCheck then
        moveMsgCount = 0
    end
end



local function init()
    gameevent.evt_second_update:add(second_update)
end

return
{
    init        = init,
    CheckMsg    = CheckMsg,
}
