local Network           = require("network") 
local HeroEctypeGroup   = require("ui.activity.herobook.heroectypegroup")
local ConfigManager     = require("cfg.configmanager")
local UIManager         = require("uimanager")

local HeroBookData = {
    m_CurrentGroup = 0,
    m_CurrentEctype = 0,
    
    m_Groups = {},
}







local function RefreshUI()
    if UIManager.isshow("activity.herobook.tabherobook") then
        UIManager.refresh("activity.herobook.tabherobook")
    end
end

local function GetCurrentGroup()
    return HeroBookData.m_Groups[HeroBookData.m_CurrentGroup]
end

local function SetCurrentGroup(index)
    if index > 0 and index <= #HeroBookData.m_Groups then
        HeroBookData.m_CurrentGroup = index
        RefreshUI()
    end
end

local function LoadConfig()
    local herosets = ConfigManager.getConfig("herosets")
    for i, value in pairs(herosets.ectypemsg) do
        HeroBookData.m_Groups[i] = HeroEctypeGroup:new(value.id, value.defaultid, 0 )
    end
    HeroBookData.m_CurrentGroup = 1
end

local function NextGroup()
    if HeroBookData.m_CurrentGroup < #HeroBookData.m_Groups then
        HeroBookData.m_CurrentGroup = HeroBookData.m_CurrentGroup + 1
        RefreshUI()
    end
end

local function LastGroup()
    if HeroBookData.m_CurrentGroup > 1 then
        HeroBookData.m_CurrentGroup = HeroBookData.m_CurrentGroup - 1
        RefreshUI()
    end
end

local function GetGroup(index)
    return HeroBookData.m_Groups[index]
end

local function GetGroupNumber()
    return #HeroBookData.m_Groups
end

local function GetCurrentGroupIndex()
    return HeroBookData.m_CurrentGroup
end



--===================================================================
--同步英雄录副本信息
local function GetHeroEctypeInfo()
    printyellow( "GetHeroEctypeInfo")
    local re = lx.gs.map.msg.CGetHeroEctypeInfo({})
    Network.send(re)
end

local function OnMsgSGetHeroEctypeInfo(msg)
    printyellow( "OnMsgSGetHeroEctypeInfo")
    for key, value in pairs(msg.herogroups) do
        HeroBookData.m_Groups[key]:ResetServerInfo(value.id, value.ectypeid, value.refreshtime)
    --    HeroBookData.m_Groups[key] = HeroEctypeGroup:new(value.id, value.ectypeid, value.refreshtime)
    end
    RefreshUI()
end

local function OnMsgSHeroGroupSyncInfo(msg)
   -- printyellowmodule(Local.LogModuals.HeroBook, msg)
    local group = HeroBookData.m_Groups[msg.groupid]
    if group then
        group:ResetServerInfo(msg.groupid, msg.groupinfo.ectypeid, msg.groupinfo.refreshtime)
    end
    RefreshUI()
end

--===================================================================
--修改当前组的选择副本
local function HeroChangeEctype(groupId)
    --printyellowmodule(Local.LogModuals.HeroBook, "HeroChangeEctype")
    local re = lx.gs.map.msg.CHeroChangeEctype({groupid = groupId})
    Network.send(re)
end

local function OnMsgSHeroChangeEctype(msg)
    --printyellowmodule(Local.LogModuals.HeroBook, msg)
    HeroBookData.m_CurrentGroup = msg.groupid
    
    local group = HeroBookData.m_Groups[msg.groupid]
    --printyellow(msg.groupid,group)
    if group then
        group:ResetServerInfo(msg.groupid, msg.ectypeid, nil)
        group:AddRefreshTimes()
        local currentEctype = group:GetCurrentHeroEctype()
        if currentEctype then
            UIManager.ShowSystemFlyText(currentEctype:GetRefreshText())
        end
    end
    
    
    RefreshUI()
end

--===================================================================
--开启副本
local function OpenHeroEctype(groupId, ectypeId)
    --printyellowmodule(Local.LogModuals.HeroBook, "COpenHeroEctype",groupId, ectypeId)
    local re = lx.gs.map.msg.COpenHeroEctype({groupid = groupId, ectypeid = ectypeId})
    Network.send(re)
end

local function SweepHeroEctype(groupId, ectypeId)
    local re = lx.gs.map.msg.CSweepHeroEctype({groupid = groupId, ectypeid = ectypeId})
    Network.send(re)

end

local function UnRead()
    local result = false
    for i, group in pairs(HeroBookData.m_Groups) do
        if group:CanChallenge() == true then
            result = true
        end
    end
    return result
end


local function Start()
    GetHeroEctypeInfo()
end



local function init()
    Network.add_listeners( {
	    { "lx.gs.map.msg.SGetHeroEctypeInfo",     OnMsgSGetHeroEctypeInfo   },
	    { "lx.gs.map.msg.SHeroGroupSyncInfo",     OnMsgSHeroGroupSyncInfo   },
        { "lx.gs.map.msg.SHeroChangeEctype",      OnMsgSHeroChangeEctype    },
	} )
    LoadConfig()
end

return {
    init = init,
    Start = Start,
    LastGroup = LastGroup,
    NextGroup = NextGroup,
    GetGroup = GetGroup,
    GetGroupNumber = GetGroupNumber,
    GetCurrentGroupIndex = GetCurrentGroupIndex,
    SetCurrentGroup = SetCurrentGroup,
    GetCurrentGroup = GetCurrentGroup,
    HeroChangeEctype = HeroChangeEctype,
    OpenHeroEctype = OpenHeroEctype,
	SweepHeroEctype = SweepHeroEctype,
    UnRead = UnRead,
}