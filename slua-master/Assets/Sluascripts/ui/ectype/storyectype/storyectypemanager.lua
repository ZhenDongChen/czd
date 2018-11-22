local network = require "network"
local uimanager = require "uimanager"
local ConfigManager = require "cfg.configmanager"
local LimitManager = require "limittimemanager"
local chapters
local changestars
local starMatrix = {}
local obtainRewardMatrix = {}
local cur_chapter
local SweepReward
local BonusManager = require("item.bonusmanager")

local function GetChangeStars()
	return changestars
end

local function GetStarMatrix()
	return starMatrix
end

local function GetSectionStars(chapterid,sectionid)
	if starMatrix and starMatrix[chapterid] then
		return starMatrix[chapterid][sectionid] or 0
	end
	return 0
end

local function GetSweepReward()
	return SweepReward
end

local function GetCurChapter()
	return cur_chapter
end

local function SetCurChapter(chapter)
	cur_chapter = chapter
end

local function GetTotalStarsByChapterId(chapterid)
	local num = 0
	local starMatrix = GetStarMatrix()
	--printyellow("GetTotalStarsByChapterId")
	--printt(starMatrix)
	if starMatrix and #starMatrix ~= 0 and starMatrix[chapterid] then
		for k,v in pairs(starMatrix[chapterid]) do
			num = num + v
		end
	end
	return num
end

local function GetRewardListByChapter(chapterid)
	local ChapterCfg = ConfigManager.getConfig("chapter")
	return ChapterCfg[chapterid]
end

local function GetRewardListByBoxNo(cur_chapter,box_no)
	local ChapterReward = GetRewardListByChapter(cur_chapter)
	if ChapterReward then
		local ChapterAllAwards = ChapterReward.bonus
		return ChapterAllAwards[box_no]
	end
	return nil
end

local function GetRequireStarByBoxNo(cur_chapter,box_no)
	local ChapterReward = GetRewardListByChapter(cur_chapter)
	if ChapterReward then
		local ChapterAllAwards = ChapterReward.bonus
		return ChapterAllAwards[box_no].requirestar
	end
	return 0
end

--进入副本 
local function onmsg_SEctypeInfo(d)
	chapters = d.chapters
	for chapterid,v in ipairs(chapters) do
			starMatrix[chapterid] = {}
		for sectionid,value in ipairs (v.sectionstars) do
			starMatrix[chapterid][sectionid] = value
		end
	end
	printyellow("onmsg_SEctypeInfo")
--	printt(chapters)
--	printt(starMatrix)
	for chapterid,v in ipairs(chapters) do
			obtainRewardMatrix[chapterid] = {}
		for _,value in ipairs (v.obtainrewardindexs) do
			obtainRewardMatrix[chapterid][value] = true
		end
	end
	
end

local function GetObtainRewardMatrix()
	return obtainRewardMatrix
end

local function  SetObtainRewardMatrix(chapterid,rewardid)
	if not obtainRewardMatrix[chapterid] then
	
		obtainRewardMatrix[chapterid] = {}	
	end
	obtainRewardMatrix[chapterid][rewardid] = true
end



local function SetStarMatrix(chapterid,sectionid,star_num)
--	printt(starMatrix)
--	printyellow(chapterid,sectionid,star_num)
--	printyellow("starMatrix[chapterid]",starMatrix[chapterid])
	if not starMatrix[chapterid] then
		--printyellow("This is {}")
		starMatrix[chapterid] = {}	
	end
	starMatrix[chapterid][sectionid] = star_num 
	printt(starMatrix)
end

local function GetChapterInfo(ectypeData)  --���°���Ϣ���з���
	print("GetChapterInfo")
	local ChaptersInfo = {}
	for id,ectypedata in pairs (ectypeData) do
		if not ChaptersInfo[ectypedata.chapter] then
			ChaptersInfo[ectypedata.chapter] = {}
		end  
		ectypedata.ectypeid = id 
		ChaptersInfo[ectypedata.chapter][ectypedata.section] = ectypedata 
	end 
	return ChaptersInfo
end

local function IsUnLocked(chapterdata,chapternum)
	if chapterdata[1].chapter == 1 then return true end 
--	if chapterdata[1].chapter == chapternum then return false end -- ����һ�¡������ڴ���
    local ectypeData  = ConfigManager.getConfig("storyectype")
	local ChaptersInfo = GetChapterInfo(ectypeData)
	local curchapterid = chapterdata[1].chapter  --��ǰ�½�id
	local prechapterid = curchapterid - 1        --��ǰ�½�ǰһ�ڵ�id 
	local pre_chapter_section_num= #ChaptersInfo[prechapterid]  --��ǰ�½�ǰһ�¹ؿ�������
	local starmatrix   = GetStarMatrix()
	if starmatrix[prechapterid] and starmatrix[prechapterid][pre_chapter_section_num] then	--�ж�����һ�عؿ��Ƿ�ͨ��
		return true
	else
		return false 
	end 	
end

local function SendCObtainChapterReward(params)
	local msg = lx.gs.map.msg.CObtainChapterReward({chapterid = params.chapterid,rewardindex = params.rewardindex})
	network.send(msg)	
end


local function onmsg_SChangeSection(d)
	changestars = d
--	printyellow("onmsg_SChangeSection")
--	printt(changestars)
	SetStarMatrix(changestars.chapterid,changestars.sectionid,changestars.star)
end

local function SendCResetStoryEctypeOpenCount(ectypeid)
	local msg = lx.gs.map.msg.CResetStoryEctypeOpenCount({ ectypeid = ectypeid })
	network.send(msg)
end




local function onmsg_SResetDailyEctypeOpenCount(d)
		local ectypeData  = ConfigManager.getConfig("storyectype")
		
		local SectionData = ectypeData[d.ectypetype]
--		printyellow("onmsg_SResetDailyEctypeOpenCount")
--		printt(ectypeData)
		if uimanager.isshow("ectype.dlgstorydungeonsub") then
			uimanager.call("ectype.dlgstorydungeonsub","RefreshTimes",SectionData)
			uimanager.call("ectype.dlgstorydungeonsub","RefreshRightButton",SectionData)
		end
end

local function onmsg_SSweepStoryEctype(msg)
    --printt(msg)
    SweepReward = msg.bonus
	local DlgDialog = require "ui.dlgdialog"
	local PlayerRole = require "character.playerrole"
	DlgDialog.RefreshCurrency(PlayerRole:Instance())

end

local function ShowBonusEffect(chapterid,rewardindex)
	local Award = GetRewardListByBoxNo(chapterid,rewardindex)
	local items = BonusManager.GetItemsOfSingleBonus(Award.award)
	uimanager.show("common.dlgdialogbox_itemshow", {itemList = items})
end

local function onmsg_SObtainChapterReward(msg)
--	printyellow("onmsg_SObtainChapterReward")
--	printyellow(msg.chapterid)
--	printyellow(msg.rewardindex)
	SetObtainRewardMatrix(msg.chapterid,msg.rewardindex)
	ShowBonusEffect(msg.chapterid,msg.rewardindex)
	if uimanager.isshow("common.dlgdialogbox_reward") then
		uimanager.hide("common.dlgdialogbox_reward")
	end
	if uimanager.isshow("ectype.dlgstorydungeonsub") then
		uimanager.call("ectype.dlgstorydungeonsub","RefreshBoxEffect",{cur_chapter = cur_chapter})
	end



end

local function HasEnoughStarNum(curchapter,box_no)	

	if GetTotalStarsByChapterId(curchapter) < GetRequireStarByBoxNo(curchapter,box_no) then
		return false
	else
		return true
	end
end

local function HasObtainedReward(curchapter,box_no)
	local obtainRewardMatrix = GetObtainRewardMatrix()	
	if obtainRewardMatrix[curchapter] and obtainRewardMatrix[curchapter][box_no] then
--		SetBoxGray(box_no)
		return true
	else

		return false
	end
end

local function UnRead()
    local ectypeData  = ConfigManager.getConfig("storyectype")
	local ChaptersInfo = GetChapterInfo(ectypeData)
	for index = 1 ,#ChaptersInfo  do
		local chapterdata = ChaptersInfo[index]
		if IsUnLocked(chapterdata) then
			for box_no = 1 , 3 do
				if HasEnoughStarNum(index ,box_no) and not HasObtainedReward(index, box_no) then
					printyellow("reddot storyectype",index .. "===" ..box_no)
					return true
				end
			end
			--是否有挑战次数
			for key,var in pairs(chapterdata) do
				local limit_time =  LimitManager.GetLimitTime(cfg.cmd.ConfigId.STORY_ECTYPE,var.id) --挑战次数
				local m_Num = limit_time and limit_time[cfg.cmd.condition.LimitType.DAY] or 0
				if var.daylimit.num > m_Num then
					return true
				end
			end
		else
			return false
		end 
	end

	return false
end

local function Release()
	chapters = nil
	changestars = nil
	starMatrix = {}
	obtainRewardMatrix = {}
	cur_chapter = nil
	SweepReward = nil
end

local function OnLogout()
	Release()
end

local function init()
	gameevent.evt_system_message:add("logout", OnLogout)
    network.add_listeners( {
    
        { "lx.gs.map.msg.SChangeSection", onmsg_SChangeSection },
        { "lx.gs.map.msg.SEctypeInfo", onmsg_SEctypeInfo },
		{"lx.gs.map.msg.SResetDailyEctypeOpenCount",onmsg_SResetDailyEctypeOpenCount},
	    { "lx.gs.map.msg.SSweepStoryEctype",onmsg_SSweepStoryEctype},
		{ "lx.gs.map.msg.SObtainChapterReward",onmsg_SObtainChapterReward},	

		
    } )
	
	
end

return {

    init    = init,
    SetStarMatrix = SetStarMatrix,
	GetStarMatrix = GetStarMatrix,
	GetCurChapter = GetCurChapter,
	SetCurChapter = SetCurChapter,
	GetChangeStars = GetChangeStars,
	GetSectionStars = GetSectionStars,
	SendCResetStoryEctypeOpenCount = SendCResetStoryEctypeOpenCount,
	GetObtainRewardMatrix = GetObtainRewardMatrix,
	SetObtainRewardMatrix = SetObtainRewardMatrix,
	SendCObtainChapterReward = SendCObtainChapterReward,
	GetTotalStarsByChapterId = GetTotalStarsByChapterId,
	GetRewardListByChapter = GetRewardListByChapter,
	GetRewardListByBoxNo = GetRewardListByBoxNo,
	GetRequireStarByBoxNo = GetRequireStarByBoxNo,
	UnRead = UnRead,
	IsUnLocked = IsUnLocked,
	GetChapterInfo = GetChapterInfo,
	HasEnoughStarNum = HasEnoughStarNum,
	HasObtainedReward = HasObtainedReward,
	
}