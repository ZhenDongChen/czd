local require          = require
local unpack           = unpack
local print            = print
local format           = string.format
local ItemEnum 		   = require("item.itemenum")
local UIManager        = require("uimanager")
local network          = require("network")
local ConfigManager    = require("cfg.configmanager")
local ItemManager      = require("item.itemmanager")
local PlayerRole       = require("character.playerrole")
local StoryNoteManager = require("ui.playerrole.storynote.storynotemanager")
local PetManager       = require("character.pet.petmanager")
local Utils            = require("common.utils")
local GameEvent        = require("gameevent")
local BagManager       = require("character.bagmanager")
local EventHelper      = UIEventListenerHelper

local gameObject
local name
local fields


-- 全局变量
local g_ChapterId
local g_bPreActivated
local g_OriPosX
local g_ItemWidth

local function RefreshChapterList()
	local chaptersData = StoryNoteManager.GetChaptersData()
	for chapterId, chapterData in ipairs(chaptersData) do

		local listItem = fields.UIList_Chapters:GetItemByIndex(chapterId - 1)
		local uiPlayTweens = listItem.gameObject:GetComponent("UIPlayTweens")

		listItem:SetIconTexture(chapterData.chapterbgicon)
		if PlayerRole:Instance().m_Level >= chapterData.openlevel.level then

			listItem.Controls["UILabel_LVLimit"].gameObject:SetActive(false)
			listItem.Controls["UILabel_NoteActivateProgress"].gameObject:SetActive(true)
			local progressText = ""
			local activatedNoteNum = StoryNoteManager.GetActivatedNoteNum(chapterId)
			local totalNoteNum = StoryNoteManager.GetNoteNum(chapterId)
			local bChapterActivated = StoryNoteManager.IsChapterActivated(chapterId)

			if bChapterActivated then
				uiPlayTweens.enabled = true
				if activatedNoteNum < totalNoteNum then
					progressText = activatedNoteNum .. "/" .. totalNoteNum
					
				else
					progressText = colorutil.GetColorStr(colorutil.ColorType.Green_Tip,LocalString.StoryNote_AllNoteActivated)
				end

			else
				uiPlayTweens.enabled = false
				progressText = colorutil.GetColorStr(colorutil.ColorType.Red,LocalString.StoryNote_NeedActivateAll)
			end
			listItem:SetText("UILabel_NoteActivateProgress", progressText)
		else
			-- 等级不够
			uiPlayTweens.enabled = false
			listItem.Controls["UILabel_LVLimit"].gameObject:SetActive(true)
			listItem:SetText("UILabel_LVLimit", format(LocalString.StoryNote_LevelLimit, chapterData.openlevel.level))
			listItem.Controls["UILabel_NoteActivateProgress"].gameObject:SetActive(false)
		end
		-- 红点提示
		local bUnReadChapter = StoryNoteManager.UnReadChapter(chapterId)
		listItem.Controls["UISprite_Warning"].gameObject:SetActive(bUnReadChapter)
	end
end

local function NoteListItemRefresh(listItem,realIndex)
	local chapterId = g_ChapterId
	local noteInfo = StoryNoteManager.GetNoteData(chapterId, realIndex)
	local noteId = noteInfo.noteid

	-- 是否被激活
	local bNoteActivated = StoryNoteManager.IsNoteActivated(chapterId, noteId)

	local fragList = listItem.Controls["UIList_PartnerFrags"]
	local frags = { }
	local fragNumNotEnough = false

	for itemIdx = 1, fragList.Count do
		local fragListItem = fragList:GetItemByIndex(itemIdx - 1)
		local item = noteInfo.requireitemlist.items[itemIdx]
		if item then
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
			fragListItem.gameObject:SetActive(true)
			fragListItem:SetText("UILabel_PartnerName", frag:GetName())
			fragListItem:SetIconTexture(frag:GetTextureName())
			fragListItem.Controls["UISprite_Fragment"].gameObject:SetActive(true)
			fragListItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(frag:GetQuality())
			if not bNoteActivated then
				fragListItem.Controls["UILabel_Amount"].gameObject:SetActive(true)
				if fragNum >= frag:GetNumber() then
					-- 绿色 
					fragListItem:SetText("UILabel_Amount", colorutil.GetColorStr(colorutil.ColorType.Green_Tip, fragNum .. "/" .. frag:GetNumber()))
				else
					-- 红色
					fragNumNotEnough = true
					fragListItem:SetText("UILabel_Amount", colorutil.GetColorStr(colorutil.ColorType.Red, fragNum .. "/" .. frag:GetNumber()))
				end
			else
				fragListItem.Controls["UILabel_Amount"].gameObject:SetActive(false)
				fragListItem:SetText("UILabel_Amount", "0")
			end
		else
			-- 隐藏多余的list item
			fragListItem.gameObject:SetActive(false)
		end
	end

	listItem.Controls["UISprite_Warning"].gameObject:SetActive(not fragNumNotEnough)


	local activateButton = listItem.Controls["UIButton_ActivateAttr"]
	activateButton.gameObject:SetActive(not bNoteActivated)
	listItem.Controls["UILabel_AlreadyActivated"].gameObject:SetActive(bNoteActivated)
	-- 播放UI特效
	if bNoteActivated == true and g_bPreActivated[chapterId][noteId] == false then

		g_bPreActivated[chapterId][noteId] = true
		-- 播放激活按钮特效
		local uiButtonEffectObj = GameObject.Instantiate(fields.UIGroup_ActivateAttrs_Fx.gameObject)
		uiButtonEffectObj.transform.parent = listItem.Controls["UILabel_AlreadyActivated"].transform
		uiButtonEffectObj.transform.localPosition = Vector3.zero
		uiButtonEffectObj.transform.localScale = Vector3.one
		local uiPlaySound = uiButtonEffectObj:GetComponent("UIPlaySound")
		-- 播放音效
		uiPlaySound:Play()
		-- 播放特效
		UIManager.PlayUIParticleSystem(uiButtonEffectObj)
		local uiPanel = fields.UIScrollView_NoteList.panel
		local uiButtonEffectTrans = uiButtonEffectObj.transform

		-- UI特效播完后释放资源
		local buttonEffect_EventId = 0
		buttonEffect_EventId = GameEvent.evt_update:add( function()
			if not uiPanel:IsVisible(uiButtonEffectTrans.position) then 
				UIManager.StopUIParticleSystem(uiButtonEffectObj)
			end
			if not UIManager.IsPlaying(uiButtonEffectObj) then
				GameEvent.evt_update:remove(buttonEffect_EventId)
				GameObject.Destroy(uiButtonEffectObj)
			end
		end )
		-- 播放伙伴图标上的特效
		for itemIdx = 1, fragList.Count do
			local fragListItem = fragList:GetItemByIndex(itemIdx - 1)
			local item = noteInfo.requireitemlist.items[itemIdx]
			if item then
				local uiIconEffectObj = GameObject.Instantiate(fields.UIGroup_UI_Cube.gameObject)
				uiIconEffectObj.transform.parent = fragListItem.transform
				local uiWidget_Com = fragListItem.gameObject:GetComponent("UIWidget")
				uiIconEffectObj.transform.localPosition = Vector3(uiWidget_Com.width / 2, - uiWidget_Com.height / 2, 0)
				uiIconEffectObj.transform.localScale = Vector3.one
				-- 播放cube特效
				UIManager.PlayUIParticleSystem(uiIconEffectObj)
				local uiIconEffectTrans = uiIconEffectObj.transform
				-- 播放完毕后释放资源
				local iconEffect_EventId = 0
				iconEffect_EventId = GameEvent.evt_update:add( function()
					if not uiPanel:IsVisible(uiIconEffectTrans.position) then 
						UIManager.StopUIParticleSystem(uiIconEffectObj)
					end
					if not UIManager.IsPlaying(uiIconEffectObj) then
						GameEvent.evt_update:remove(iconEffect_EventId)
						GameObject.Destroy(uiIconEffectObj)
					end
				end )
			end
		end
	end
	-- 设置属性值信息
	local attrText = ItemManager.GetAttrText(noteInfo.addproperty.propertytype, noteInfo.addproperty.value, true)
	if bNoteActivated then
		attrText = tostring(LocalString.PartnerText.NativeColor..attrText) 
	else
		attrText = tostring(LocalString.PartnerText.NoNativeColor..attrText)
	end
	listItem:SetText("UILabel_AttrInfo", attrText)

	EventHelper.SetClick(activateButton, function()
		-- 校验伙伴碎片是否足够
		for _, fragData in pairs(noteInfo.requireitemlist.items) do
			local frag = ItemManager.CreateItemBaseById(fragData.itemid, nil, fragData.amount)
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
				UIManager.ShowSystemFlyText(format(LocalString.StoryNote_FragNotEnough, frag:GetName()))
				ItemManager.GetSource(frag:GetConfigId(),"playerrole.dlgplayerrole")
				return
			end
		end
		print("chapterid .. 11 ")
		print(chapterid)
		local msg = lx.gs.storynote.msg.CActiveNote( { chapterid = chapterId, noteid = noteId })
		network.send(msg)
	end )
end

local function RefreshNotelist()
	local listItem = fields.UIList_Chapters:GetItemByIndex(g_ChapterId - 1)
	local noteList = fields.UIList_Notes
	local uiPlayTweens = listItem.gameObject:GetComponent("UIPlayTweens")
	local chapterOpenLevel = StoryNoteManager.GetChapterOpenLevel(g_ChapterId)
	if PlayerRole:Instance().m_Level >= chapterOpenLevel then

		listItem.Controls["UILabel_LVLimit"].gameObject:SetActive(false)
		listItem.Controls["UILabel_NoteActivateProgress"].gameObject:SetActive(true)
		local progressText = ""
		local activatedNoteNum = StoryNoteManager.GetActivatedNoteNum(g_ChapterId)
		local totalNoteNum = StoryNoteManager.GetNoteNum(g_ChapterId)
		local bChapterActivated = StoryNoteManager.IsChapterActivated(g_ChapterId)

		if bChapterActivated then
			uiPlayTweens.enabled = true
			if activatedNoteNum < totalNoteNum then
				progressText = activatedNoteNum .. "/" .. totalNoteNum
			else
				progressText = colorutil.GetColorStr(colorutil.ColorType.Green_Tip,LocalString.StoryNote_AllNoteActivated)
			end

		else
			uiPlayTweens.enabled = false
			progressText = colorutil.GetColorStr(colorutil.ColorType.Red,LocalString.StoryNote_NeedActivateAll)
		end

		listItem:SetText("UILabel_NoteActivateProgress", progressText)
	else
		uiPlayTweens.enabled = false
		listItem.Controls["UILabel_LVLimit"].gameObject:SetActive(true)
		listItem:SetText("UILabel_LVLimit", format(LocalString.StoryNote_LevelLimit, chapterOpenLevel))
		listItem.Controls["UILabel_NoteActivateProgress"].gameObject:SetActive(false)
	end
	noteList:ResetListCount(StoryNoteManager.GetNoteNum(g_ChapterId))
	for listIndex = 0,(noteList.Count-1) do
		local noteListItem = noteList:GetItemByIndex(listIndex)
		NoteListItemRefresh(noteListItem,listIndex+1)
	end
end

local function ResetNoteListPosition()
	fields.UIList_Notes:Refresh()
end

local function InitChapterList()
	if fields.UIList_Chapters.Count == 0 then
		local chaptersData = StoryNoteManager.GetChaptersData()
		local uiTweenPos = fields.UIList_Chapters.gameObject:GetComponent("TweenPosition")
		for chapterId, chapterData in ipairs(chaptersData) do
			local listItem = fields.UIList_Chapters:AddListItem()
			local uiPlayTweens = LuaHelper.GetComponent(listItem.gameObject, "UIPlayTweens")
			local uiTweenScale = LuaHelper.GetComponentInChildren(listItem.gameObject, "TweenScale")
			EventHelper.AddToggle(listItem.Checkbox, function(toggle)
				-- local uiTweenPos = fields.UIList_Chapters.gameObject:GetComponent("TweenPosition")

				if toggle.value then
					local bActivated = StoryNoteManager.IsChapterActivated(listItem.Index + 1)
					if not bActivated then
						-- 因为每个list item的group都设置为0，所以无法将list里的其他toggle设置为false
						-- 因此将没有激活的章节在点击时对应toggle再次设置为false
						listItem.Checked = false
						return
					end

					g_ChapterId = listItem.Index + 1

					local curPosX = fields.UIScrollView_StoryNote.transform.localPosition.x
					local offsetX =(curPosX - g_OriPosX)

					-- 设置List移动距离
					uiTweenPos.from = Vector3.zero
					uiTweenPos.to = Vector3(- g_ItemWidth * listItem.Index + math.abs(offsetX), 0, 0)

					RefreshNotelist()
					-- list位置置顶
					ResetNoteListPosition()

					fields.TweenScale_ActivateAttrs.delay = 0.1 *(math.abs(- listItem.Index + math.abs(offsetX / g_ItemWidth)))
					uiTweenScale.delay = 0.1 *(math.abs(- listItem.Index + math.abs(offsetX / g_ItemWidth)))
					uiTweenPos.delay = 0
					uiTweenPos.duration = 0.1 *(math.abs(- listItem.Index + math.abs(offsetX / g_ItemWidth)))
					-- 禁止拖拽和点击
					listItem.gameObject:GetComponent("UIDragScrollView").enabled = false
					for index = 0,(fields.UIList_Chapters.Count - 1) do
						if index ~= listItem.Index then
					 		fields.UIList_Chapters:GetItemByIndex(index).gameObject:GetComponent("BoxCollider").enabled = false
						end
					end

				else
					fields.TweenScale_ActivateAttrs.delay = 0
					uiTweenScale.delay = 0
					uiTweenPos.delay = uiTweenScale.duration
					-- 恢复拖拽和点击
					listItem.gameObject:GetComponent("UIDragScrollView").enabled = true
					for index = 0,(fields.UIList_Chapters.Count - 1) do
						if index ~= listItem.Index then
					 		fields.UIList_Chapters:GetItemByIndex(index).gameObject:GetComponent("BoxCollider").enabled = true
						end
					end
				end
			end )


		end
	end
	fields.UIList_Chapters.gameObject:GetComponent("UITable").repositionNow = true
end

local function destroy()
	-- print(name, "destroy")
end

local function show(params)
	-- print(name, "show")
	g_ChapterId = g_ChapterId or 1
	g_bPreActivated = Utils.copy_table(StoryNoteManager.GetActivatedData())
end

local function hide()
	-- print(name, "hide")
end

local function refresh(params)
	-- print(name, "refresh")
	-- 刷新单章节所有note信息
	RefreshNotelist()
	-- 刷新所有章节信息
	RefreshChapterList()
	UIManager.call("dlgdialog","RefreshRedDot","playerrole.dlgplayerrole")
end

local function update()
	-- print(name, "update")
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
	name, gameObject, fields = unpack(params)

	g_OriPosX = fields.UIScrollView_StoryNote.transform.localPosition.x
	g_ItemWidth =(fields.UIList_Chapters.m_prefabListItem.gameObject:GetComponent("UIWidget")).width

	InitChapterList()
end

return {
	init       = init,
	show       = show,
	hide       = hide,
	update     = update,
	destroy    = destroy,
	refresh    = refresh,
	uishowtype = uishowtype,
}
