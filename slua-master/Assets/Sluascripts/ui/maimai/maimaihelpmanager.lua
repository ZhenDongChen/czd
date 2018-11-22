local network 				= require "network"
local ConfigMgr 			= require "cfg.configmanager"
local UIManager 			= require("uimanager")
local PlayerRole            = require "character.playerrole"
local helpDataList = {}
local isNotice = true
local function onmsg_BeKillByOther(msg)
    if isNotice and msg.defencer ~= PlayerRole:Instance().m_Id and msg.attackername ~= PlayerRole:Instance().m_Name then
        table.insert(helpDataList,msg) 
        if UIManager.isshow("dlguimain") then
            UIManager.call("dlguimain","RefreshMaimaiHelpIcon")
        end
    end
end

local function changeNoticeState()
    if isNotice then
        printyellow("changeNoticeState is false")
        isNotice = false
        helpDataList = {}
        if UIManager.isshow("dlguimain") then
            UIManager.call("dlguimain","RefreshMaimaiHelpIcon")
        end
    else
        printyellow("changeNoticeState is true")
        isNotice = true
    end
end

local function removeEndHelpData()
    table.remove(helpDataList,#helpDataList)
end

local function getHelpData()
    return helpDataList
end

local function refresh()
end

local function init()
	network.add_listeners({
       { "lx.gs.map.msg.SBekillByOther", onmsg_BeKillByOther},
    })
end

return {
	init = init,
	refresh = refresh,
    removeEndHelpData = removeEndHelpData,
    changeNoticeState = changeNoticeState,
    getHelpData = getHelpData,
}	