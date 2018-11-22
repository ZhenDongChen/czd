local CheckCmd = require("common.checkcmd")
local ConfigManager = require("cfg.configmanager")

local network = require "network"
local uimanager = require "uimanager"
local gameevent     = require "gameevent"
local starMatrix = {}
local PlayerRole = require"character.playerrole"
local  LimitManager = require"limittimemanager"

local storyectypelefttime
local roleinfos
local cur_section
local cur_ectypeid
local title
local maxLevelCanChallege
local isMatchingSuccessful = false
local canReceiveReward 


local function SetCurEctypeId(id)
	cur_ectypeid = id
end

local function GetCurEctypeId()
	return cur_ectypeid
end

local function update()
	if isMatchingSuccessful and uimanager.isshow("ectype.multiectype.dlgmultiectypematching")then
		uimanager.call("ectype.multiectype.dlgmultiectypematching","SetTwoButtonsEnabled",{isSuccessful = false})
	end
end

local function IsMatchingSuccessful()
	return isMatchingSuccessful
end

local function GetMaxLevelCanChallege()
	return maxLevelCanChallege
end

local function SetMaxLevelCanChallege(playerlevel)
	local MultiInfo = ConfigManager.getConfig("teamstoryectype")
	local sortMultiInfo = {}
	for key,section in pairs(MultiInfo) do
		table.insert(sortMultiInfo,section)
	end
	table.sort(sortMultiInfo, function(item1, item2) return(item1.id > item2.id) end)
	for _,info in ipairs(sortMultiInfo) do
		if info.openlevel.level <= playerlevel then
			maxLevelCanChallege = info.openlevel.level
			break
		end
	end
end

local function GetEctypeById(id)
	if not id then
		return nil
	end
	local teamconfig = ConfigManager.getConfig("teamstoryectype")
		return teamconfig[id]
end


local function GetStarMatrix()
	return starMatrix
end

local function GetLimitTime(section)
	return section.daylimit.num
end



local function GetRestTime(section)
	local limit_time =  LimitManager.GetLimitTime(cfg.cmd.ConfigId.MULTI_STORY_ECTYPE,section.id) --挑战次数
    local m_Num = limit_time and limit_time[cfg.cmd.condition.LimitType.DAY] or 0
	local limittime = GetLimitTime(section)
	printyellow("limittime = ",limittime)
	printyellow("m_Num = ",m_Num)
	return limittime - m_Num
end

local function GetCanReceiveReward()
	return canReceiveReward
end

local function SetCanReceiveReward(b)
	canReceiveReward = b
end

local function CanReceiveReward(ectypeid)
	local section = GetEctypeById(ectypeid)
	printyellow("GetRestTime(section)",GetRestTime(section))
	printt(section)
	if GetRestTime(section) > 0 then
		return true
	else
		return false
	end
end

local function NumToCharacter(num)
    if num == 1 then
		printyellow(num)
        return "简单"
    elseif num == 2 then
        return "普通"
    elseif num == 3 then
        return "困难"
	else
		return ""
	end
end


local function SendCEnrollMultiStoryEctype(enrolltype,ectypeid)
	local msg = lx.gs.map.msg.CEnrollMultiStoryEctype({enrolltype = enrolltype,ectypeid = ectypeid})
	network.send(msg)
end

local function CanReceiveInviteMessage(ectypeid)
	local teamectypeinfo = GetEctypeById(ectypeid) --得到该ectypeid的多人副本信息
	if PlayerRole:Instance().m_Level < teamectypeinfo.openlevel.level then
		return false,""
	end

	local usedtime = GetRestTime(teamectypeinfo)
	if  usedtime <= 0 then    --今日多人副本次数已用尽（后来改成了领取奖励的次数）
		return false,""
	end
	local str1 = string.format(LocalString.MultiEctype_Invite_Message1,teamectypeinfo.storyname.."("..teamectypeinfo.openlevel.level..LocalString.Level..NumToCharacter(teamectypeinfo.difficulty)..")")
	return true,str1 .. LocalString.MultiEctype_Invite_Message2

end

local function CanSendScroll(ectypeid)
		local section = GetEctypeById(ectypeid)
		local starMatrix = GetStarMatrix()
		local prevEctype = GetEctypeById(section.preectypeid)
	    if not prevEctype or starMatrix[prevEctype.groupid] and starMatrix[prevEctype.groupid][prevEctype.sectionid] then --没有前置关或前置关已经完成 
			return true
		else
			return false
		end
end

local function SendScroll(ectypeid)

		if CanSendScroll(ectypeid) then --没有前置关或前置关已经完成 
			SendCEnrollMultiStoryEctype( lx.gs.map.msg.CEnrollMultiStoryEctype.SINGLE,ectypeid)
		else
			local content = string.format(LocalString.MultiEctype_NeedToComplete,prevEctype.storyname .."·"..NumToCharacter(prevEctype.difficulty))
			uimanager.show("dlgalert_reminder_singlebutton",{content = content})			
		end
	
end

local function NumToCharacter(num)
    if num == 1 then
		-- printyellow(num)
        return LocalString.MultiEctype_Easy
    elseif num == 2 then
        return LocalString.MultiEctype_Normal
    elseif num == 3 then
        return LocalString.MultiEctype_Hard
	else
		return ""
	end
end

local function GetCurSection()
	return cur_section
end

local function SetCurSection(cur)
	cur_section = cur
end

local function GetRoleInfos()
	return roleinfos
end

local function SetRoleInfos(infos)
	roleinfos = infos
end

local function GetTitle()
	return title
end

local function GetStoryEctypeLeftTime()
	return storyectypelefttime
end

local function SetStoryEctypeLeftTime(time)
	storyectypelefttime = time
end

local function HasOpened(preEctype,openLevel)
    local isOpen=false
    local result,info=CheckCmd.CheckData({data=openLevel})
    if result and (preEctype) then
        isOpen=true
    end
    return isOpen
end

local function SendCLeaveTeamAndEnrollSingle(ectypeid)
	local msg = lx.gs.map.msg.CLeaveTeamAndEnrollSingle({ectypeid = ectypeid})
	network.send(msg)
end



local function SendCCancelEnrollMultiStoryEctype()
	local msg = lx.gs.map.msg.CCancelEnrollMultiStoryEctype()
	network.send(msg)
end

local function GetEctypeName(id)
    local name=""
    local ectypeData=ConfigManager.getConfigData("ectypebasic",id)
    if ectypeData then
        name=ectypeData.ectypename
    end
    return name
end

local function IsSigning()
end

local function SetStarMatrix(groupid,sectionid,star_num)
	--	printt(starMatrix)
	--printyellow(chapterid,sectionid,star_num)
	--printyellow("starMatrix[chapterid]",starMatrix[chapterid])

	if not starMatrix[groupid] then
		starMatrix[groupid] = {}
		starMatrix[groupid][sectionid] = star_num
	else
		if not starMatrix[groupid][sectionid] then
			starMatrix[groupid][sectionid] = star_num
		else
			if starMatrix[groupid][sectionid] < star_num then
				starMatrix[groupid][sectionid] = star_num
			end
		end
	end
--	printt(starMatrix)
end

local function onmsg_SEctypeInfo(d)
--	printyellow("onmsg_SEctypeInfo complete complete")
	if d and d.multistory then
		local SectionStars = d.multistory
--		printt(d.multistory)
		local MultiInfo = ConfigManager.getConfig("teamstoryectype")
--		printt(MultiInfo)
		for ectypeid,stars in pairs(SectionStars) do
--			printyellow("ectypeid",ectypeid)
--			printt(stars)
			if MultiInfo[ectypeid] then
--				printyellow("stars.beststar",stars.beststar)
				SetStarMatrix(MultiInfo[ectypeid].groupid,MultiInfo[ectypeid].sectionid,stars.beststar)
			end
		end
	end
end





local function second_update()
--	printyellow("storyectypelefttime",storyectypelefttime)
	if storyectypelefttime and storyectypelefttime > 0 then
		storyectypelefttime = storyectypelefttime - 1

		local dlgmultimatching = "ectype.multiectype.dlgmultiectypematching"
		if uimanager.isshow(dlgmultimatching) then
			uimanager.call(dlgmultimatching,"RefreshTime",{lefttime = storyectypelefttime})

		end

	end
end

local function onmsg_SEnrollMultiStoryEctypeSuccessNotify(d) -- ƥ���ɹ�
    storyectypelefttime = d.lefttime
	roleinfos = d.roleinfos

	title = cur_section.storyname ..LocalString.MultiEctype_Dot..NumToCharacter(cur_section.difficulty)

	if uimanager.isshow("common.dlgdialogbox_common") then
		uimanager.hide("common.dlgdialogbox_common")
	end 
	isMatchingSuccessful = true
	if uimanager.isshow("ectype.multiectype.dlgmultiectypematching")  then
		uimanager.refresh("ectype.multiectype.dlgmultiectypematching",{lefttime = storyectypelefttime , roleinfos = roleinfos,title = title, is
 = true})
	else
		uimanager.show("ectype.multiectype.dlgmultiectypematching",{lefttime = storyectypelefttime , roleinfos = roleinfos ,title = title, isSuccessful = true})
	end
	--MultiEctypeManager.SendCEnrollMultiStoryEctype( lx.gs.map.msg.CEnrollMultiStoryEctype.SINGLE,Section.id)


end

local function onmsg_SStartEnrollMultiStoryNotify(d) -- individula and team 
	printyellow("onmsg_SStartEnrollMultiStoryNotify")
	cur_ectypeid = d.ectypeid
	SetCanReceiveReward(CanReceiveReward(cur_ectypeid))
	roleinfos = d.roleinfos
	local MultiInfo = ConfigManager.getConfig("teamstoryectype")
	cur_section = MultiInfo[d.ectypeid]
	title = cur_section.storyname ..LocalString.MultiEctype_Dot..NumToCharacter(cur_section.difficulty)
	storyectypelefttime = 60
	printyellow("onmsg_SStartEnrollMultiStoryNotify")
	isMatchingSuccessful = false
	uimanager.show("ectype.multiectype.dlgmultiectypematching",{lefttime = storyectypelefttime , roleinfos = roleinfos ,title = title,ectypeid = d.ectypeid })


end

local function onmsg_SCancelEnrollMultiStorySuccessNotify(d)
		if uimanager.isshow("ectype.multiectype.dlgmultiectypematching") then
			uimanager.hide("ectype.multiectype.dlgmultiectypematching")
		end
		storyectypelefttime = 0
end

local function onmsg_SLeaveTeamAndEnrollSingle(d)
	
	
end

local function onmsg_SEnrollMultiStoryEctype(d)
	
	roleinfos = d.roleinfos
	
end

local function onmsg_SPrepareMultiStoryEctypeFailNotify(d)

	uimanager.show("dlgalert_reminder_singlebutton",{content = d.reason})
end

local function onmsg_SEndMultiStoryEctype(d)
	local MultiInfo = ConfigManager.getConfig("teamstoryectype")
	local groupid = MultiInfo[d.ectypeid].groupid
	local sectionid = MultiInfo[d.ectypeid].sectionid

	SetStarMatrix(groupid,sectionid,d.star)

end

local function Release()
	starMatrix = {}
	maxLevelCanChallege = nil
	storyectypelefttime = nil
	isMatchingSuccessful = false
	roleinfos = nil
	cur_section = nil
	title = nil
end

local function OnLogout()
	Release()
end

local function GetChallengeTime(section)
	local limit_time =  LimitManager.GetLimitTime(cfg.cmd.ConfigId.MULTI_STORY_ECTYPE,section.id) --挑战次数
	local m_Num = limit_time and limit_time[cfg.cmd.condition.LimitType.DAY] or 0
	return m_Num
end




local function HasRedDot(section)
--	printyellow("maxLevelCanChallege",maxLevelCanChallege)
	if not maxLevelCanChallege then
		SetMaxLevelCanChallege(PlayerRole:Instance().m_Level)
	end
	
	
	
	if section.openlevel.level > maxLevelCanChallege or GetChallengeTime(section) >= 2 then
		return false
	else
		return true 
	end
end

local function UnRead()
	local MultiInfo = ConfigManager.getConfig("teamstoryectype")
	for _,section in pairs(MultiInfo) do
		if HasRedDot(section) then
			return true
		end
	end
	return false
end


local function init()
	canReceiveReward = true
	gameevent.evt_system_message:add("logout", OnLogout)
   network.add_listeners( {

        { "lx.gs.map.msg.SEctypeInfo", onmsg_SEctypeInfo },
        { "lx.gs.map.msg.SEnrollMultiStoryEctypeSuccessNotify", onmsg_SEnrollMultiStoryEctypeSuccessNotify },
		{ "lx.gs.map.msg.SCancelEnrollMultiStorySuccessNotify",onmsg_SCancelEnrollMultiStorySuccessNotify },
		{ "lx.gs.map.msg.SLeaveTeamAndEnrollSingle",onmsg_SLeaveTeamAndEnrollSingle },
		{ "lx.gs.map.msg.SEnrollMultiStoryEctype",onmsg_SEnrollMultiStoryEctype },
        { "lx.gs.map.msg.SPrepareMultiStoryEctypeFailNotify",onmsg_SPrepareMultiStoryEctypeFailNotify},
		{ "lx.gs.map.msg.SStartEnrollMultiStoryNotify",onmsg_SStartEnrollMultiStoryNotify},
		{ "map.msg.SEndMultiStoryEctype",onmsg_SEndMultiStoryEctype},


    } )
	gameevent.evt_second_update:add(second_update)
	gameevent.evt_update:add(update)
end

return{
    init = init,
    HasOpened = HasOpened,
    GetEctypeName = GetEctypeName,
    IsSigning=IsSigning,
	GetStarMatrix = GetStarMatrix,
	SendCLeaveTeamAndEnrollSingle = SendCLeaveTeamAndEnrollSingle,
	SendCEnrollMultiStoryEctype = SendCEnrollMultiStoryEctype,
	SendCCancelEnrollMultiStoryEctype = SendCCancelEnrollMultiStoryEctype,
	SetStarMatrix = SetStarMatrix,
	GetStoryEctypeLeftTime		= GetStoryEctypeLeftTime,
	SetStoryEctypeLeftTime		= SetStoryEctypeLeftTime,
	GetRoleInfos = GetRoleInfos,
	SetRoleInfos = SetRoleInfos,
	SetCurSection = SetCurSection,
	GetTitle = GetTitle,
	CanReceiveInviteMessage = CanReceiveInviteMessage,
	GetEctypeById = GetEctypeById,
	SendScroll = SendScroll,
	UnRead = UnRead,
	HasRedDot = HasRedDot,
	GetRestTime = GetRestTime,
	GetChallengeTime = GetChallengeTime,
	GetMaxLevelCanChallege = GetMaxLevelCanChallege,
	SetMaxLevelCanChallege = SetMaxLevelCanChallege,
	IsMatchingSuccessful = IsMatchingSuccessful,
	CanReceiveReward = CanReceiveReward,
	SetCanReceiveReward = SetCanReceiveReward,
	GetCanReceiveReward = GetCanReceiveReward,
	GetCurSection = GetCurSection,
	SetCurEctypeId = SetCurEctypeId,
	GetCurEctypeId = GetCurEctypeId,



}
