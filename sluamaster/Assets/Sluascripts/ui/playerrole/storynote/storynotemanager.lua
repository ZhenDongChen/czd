local print            = print
local require          = require
local format           = string.format
local gameevent        = require "gameevent"
local network          = require "network"
local ConfigManager    = require("cfg.configmanager")
local UIManager        = require("uimanager")
local PlayerRole       = require("character.playerrole")
local ItemManager      = require("item.itemmanager")
local PetManager       = require("character.pet.petmanager")
local BagManager       = require("character.bagmanager")
local ItemEnum 		   = require("item.itemenum")


-- 记录某chapter某note是否被激活
local g_bActivated = { }
local g_ChaptersData

local function IsNoteActivated(chapterId,noteId)
	return g_bActivated[chapterId][noteId]
end

local function GetChaptersData()
	return g_ChaptersData
end

local function GetActivatedData()
	return g_bActivated
end

local function GetChapterOpenLevel(chapterId)
	return g_ChaptersData[chapterId].openlevel.level
end

local function GetNoteData(chapterId,noteId)
	return g_ChaptersData[chapterId].noteinfo[noteId]
end

local function GetNoteNum(chapterId)
	return #(g_ChaptersData[chapterId].noteinfo)
end

local function GetActivatedNoteNum(chapterId)
	local activatedNoteNum = 0
	for noteId,bActivated in pairs(g_bActivated[chapterId]) do
		if bActivated then
			activatedNoteNum = activatedNoteNum + 1
		end
	end
	return activatedNoteNum
end
-- 相应章节是否开启
local function IsChapterActivated(chapterId)
	local chapterOpenLevel = GetChapterOpenLevel(chapterId)
	if PlayerRole:Instance().m_Level >= chapterOpenLevel then

		local activatedNoteNum = GetActivatedNoteNum(chapterId)
		local totalNoteNum = GetNoteNum(chapterId)

		if chapterId == 1 then
			-- 第一章
			return true
		elseif chapterId > 1 then 
			-- 后续的章节
			local preActivatedNoteNum = GetActivatedNoteNum(chapterId - 1)
			local preTotalNoteNum = GetNoteNum(chapterId - 1)
			if preActivatedNoteNum < preTotalNoteNum then
				return false
			else
				return true
			end
		end
	else
		return false
	end
end
-- region msg
local function OnMsg_SActiveNote(msg)
	g_bActivated[msg.chapterid][msg.noteid] = true
	UIManager.refresh("playerrole.storynote.tabstorynote")
end

local function OnMsg_SInfo(msg)
	for chapterId, chapterData in pairs(msg.chapters) do
		for _, noteId in pairs(chapterData.notes) do
			g_bActivated[chapterId][noteId] = true
		end
	end
end
-- endregion msg

local function update()
end

local function Release()
	-- 初始化数据
	g_bActivated = { }
	g_ChaptersData = ConfigManager.getConfig("storynote")
	for chapterId,chapterData in pairs(g_ChaptersData) do
		if not g_bActivated[chapterId] then
			g_bActivated[chapterId] = { }
		end
		for _, noteData in pairs(chapterData.noteinfo) do
			g_bActivated[chapterId][noteData.noteid] = false
		end
	end
end

local function OnLogout()
	Release()
end

local function init()
	-- gameevent.evt_update:add(Update)
	-- 初始化数据
	g_ChaptersData = ConfigManager.getConfig("storynote")
	for chapterId,chapterData in pairs(g_ChaptersData) do
		if not g_bActivated[chapterId] then
			g_bActivated[chapterId] = { }
		end
		for _, noteData in pairs(chapterData.noteinfo) do
			g_bActivated[chapterId][noteData.noteid] = false
		end
	end


	network.add_listeners( {
		{ "lx.gs.storynote.msg.SActiveNote", OnMsg_SActiveNote },
		{ "lx.gs.storynote.msg.SInfo", OnMsg_SInfo },

	} )
	gameevent.evt_system_message:add("logout", OnLogout)
end

local function UnReadChapter(chapterId)
	local bChapterActivated = IsChapterActivated(chapterId)
	if not bChapterActivated then return false end 

	local noteList =  g_ChaptersData[chapterId].noteinfo
	for _, noteData in ipairs(noteList) do
		local itemList = noteData.requireitemlist.items
		local bFragNumNotEnough = false
		for _,item in ipairs(itemList) do
			local frag = ItemManager.CreateItemBaseById(item.itemid, nil, item.amount)
			local fragType = frag:GetDetailType()
			local fragNum = 0
			if fragType == ItemEnum.FragType.Common then 
				fragNum = BagManager.GetItemNumById(frag:GetConfigId(),cfg.bag.BagType.FRAGMENT)
			elseif fragType == ItemEnum.FragType.Pet then 
				fragNum = PetManager.GetFragmentNum(frag:GetConfigId())
			else
				logError("[tabstorynote]:Frag Type Error(CSV Data may be wrong)")
			end 

			if fragNum < frag:GetNumber() then 
				bFragNumNotEnough = true
				break
			end
		end
		local bActived = IsNoteActivated(chapterId,noteData.noteid)
		if not bActived and not bFragNumNotEnough then 
			return true
		end
	end
	return false
end

local function UnRead()
	for chapterId in ipairs(g_ChaptersData) do
		local bUnReadChapter = UnReadChapter(chapterId)
		if bUnReadChapter then
			return true
		end
	end
	return false
end

return {
	init                = init,
	UnRead              = UnRead,
	UnReadChapter		= UnReadChapter,
	GetChaptersData     = GetChaptersData,
	GetActivatedData	= GetActivatedData,
	IsChapterActivated	= IsChapterActivated,
	IsNoteActivated     = IsNoteActivated,
	GetNoteData         = GetNoteData,
	GetNoteNum          = GetNoteNum,
	GetActivatedNoteNum = GetActivatedNoteNum,
	GetChapterOpenLevel = GetChapterOpenLevel,
}