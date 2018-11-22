local PlayerRole 			= require "character.playerrole"
local network 				= require "network"

local UIManager 			= require("uimanager")

local MaimaiManager 		= require("ui.maimai.maimaimanager")
local LimitManager          = require"limittimemanager"
local maimaiList = {}
local friendTimes = nil
local function getConfigData()
	local maimaiData = ConfigManager.getConfig("mmectype")
	return maimaiData
end

local function getMMLeftTimes(num)
    local mtype = num or 0;
	local msg = lx.gs.map.msg.CGetMMLeftTimes({mmtype = mtype})
    network.send(msg)
end

local function begainFight(num)
    local mtype = num or 0;
    local msg = lx.gs.map.msg.COpenMMEctype({mmtype = mtype})
    network.send(msg)
end

local  function getFriendTimes()
    return friendTimes
end

local function OnMsg_SGetMMLeftTimes(msg)
	friendTimes = msg.roleid2times
    if UIManager.isshow("common.dlgdialogbox_listfriend") then
        UIManager.call("common.dlgdialogbox_listfriend","refresh")
    end
end

local function init()
	network.add_listeners({
        {"lx.gs.map.msg.SGetMMLeftTimes",OnMsg_SGetMMLeftTimes},
    })
end

local function getMaimaiData()
    local mmInfo = MaimaiManager.GetMaimaiInfo()
    maimaiList = {}
    if mmInfo and mmInfo.m_MaimaiMap and mmInfo.m_MaimaiMap.m_MaimaiInfos then
        for relation, roleInfoList  in pairs(mmInfo.m_MaimaiMap.m_MaimaiInfos) do
            if relation ~= cfg.friend.MaimaiRelationshipType.SuDi then
                for _,playerInfo in ipairs(roleInfoList) do
                    local playerData = {}
                    playerData.relation = relation
                    playerData.playerInfo = playerInfo
                    if friendTimes then
                        playerData.friendTimes = friendTimes[playerInfo:GetRole():GetId()]
                    end
                    table.insert(maimaiList,playerData)
                end
            end
        end
    end
    if friendTimes then
        table.sort(maimaiList,function (a,b) 
            if a.friendTimes > 0 and b.friendTimes > 0 then
                if a.playerInfo:GetRole().m_Online and b.playerInfo:GetRole().m_Online then
                    return a.playerInfo:GetRole().m_Power > b.playerInfo:GetRole().m_Power
                elseif a.playerInfo:GetRole().m_Online or b.playerInfo:GetRole().m_Online then
                    return a.playerInfo:GetRole().m_Online
                else
                    return a.playerInfo:GetRole().m_Power > b.playerInfo:GetRole().m_Power
                end
            elseif (a.friendTimes > 0) or (b.friendTimes > 0) then
                return (0 < a.friendTimes) and true or false
            else
                if a.playerInfo:GetRole().m_Online and b.playerInfo:GetRole().m_Online then
                    return a.playerInfo:GetRole().m_Power > b.playerInfo:GetRole().m_Power
                elseif a.playerInfo:GetRole().m_Online or b.playerInfo:GetRole().m_Online then
                    return a.playerInfo:GetRole().m_Online
                else
                    return a.playerInfo:GetRole().m_Power > b.playerInfo:GetRole().m_Power
                end
            end
        end)
    end
    
    return maimaiList
end

local function UnRead(index)
	local result = false
    local localData = getConfigData()
    if index == 4 then
        local maimaiData = localData[cfg.ectype.MMEctype.SPRING_ID]
        local times = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.MM_ECTYPE_CHRISMAS,0)
        if maimaiData.openlevel <= PlayerRole:Instance():GetLevel() then
            local num = maimaiData.dailyrewardtime.num - times
            if num > 0 then
                result = true
            end
        end
    elseif index== 1 then
        local maimaiData = localData[cfg.ectype.MMEctype.MM_ID]
        local times = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.MM_ECTYPE,0)
        if maimaiData.openlevel <= PlayerRole:Instance():GetLevel() then
            local num = maimaiData.dailyrewardtime.num - times
            if num > 0 then
                result = true
            end
        end
    else
		printyellow("��ʱ��������ʥ��������С�����Ĺ���")
      --[[  local maimaiData = localData[cfg.ectype.MMEctype.SPRING_ID]
        local times = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.MM_ECTYPE_CHRISMAS,0)
        if maimaiData.openlevel <= PlayerRole:Instance():GetLevel() then
            local num = maimaiData.dailyrewardtime.num - times
            if num > 0 then
                result = true
            end
        end
        local maimaiData = localData[cfg.ectype.MMEctype.MM_ID]
        local times = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.MM_ECTYPE,0)
        if maimaiData.openlevel <= PlayerRole:Instance():GetLevel() then
            local num = maimaiData.dailyrewardtime.num - times
            if num > 0 then
                result = true
            end
        end--]]

    end
	return result
end

return {
	init = init,
	refresh = refresh,
	getConfigData = getConfigData,
	getMaimaiData = getMaimaiData,
	UnRead = UnRead,
	getMMLeftTimes = getMMLeftTimes,
    getFriendTimes = getFriendTimes,
    begainFight    = begainFight,
}	