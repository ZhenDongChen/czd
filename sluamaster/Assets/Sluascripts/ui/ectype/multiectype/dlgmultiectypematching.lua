local print = print
local printyellow = printyellow
local require = require
local math = math
local string = string

local unpack = unpack
local MultiEctypeManager=require("ui.ectype.multiectype.multiectypemanager")
local CharacterManager = require ("character.charactermanager")
local ChatManager =  require("ui.chat.chatmanager")
local UIManager = require ("uimanager")
local EventHelper = UIEventListenerHelper
local PlayerRole = require ("character.playerrole")
local FamilyManager = require ("family.familymanager")
local TeamManager = require ("ui.team.teammanager")
local LimitTimeManager = require ("limittimemanager")
local ConfigManager = require ("cfg.configmanager")
local name
local gameObject
local fields

local lefttime
local cur_ectypeid

local NUM_PLAYER_MATCHING = 3
local SECONDS_PER_MINITE = 60

local function hide(name)
end

local function GetHeadIconByGenderAndProfession(gender, profession)
    local professionInfo = ConfigManager.getConfigData("profession",profession)
    local modelname = cfg.role.GenderType.MALE == gender and professionInfo.modelname or professionInfo.modelname2
    local icon = ConfigManager.getConfigData("model",modelname).headicon
	return icon
end

local function RefreshHeadIcon(roleinfos)
	fields.UIList_Head:Clear()
--	printyellow("RefreshHeadIcon")
--	printt(roleinfos)
	local index  = 1
	for _,roleinfo in pairs(roleinfos) do
		local listItem = fields.UIList_Head:AddListItem()
		local HeadIcon = GetHeadIconByGenderAndProfession(roleinfo.gender,roleinfo.profession)
--		printyellow(HeadIcon)
		listItem.Controls["UITexture_01"]:SetIconTexture(HeadIcon)
		index = index + 1
	end
	local num
	for num = index, NUM_PLAYER_MATCHING do
		local listItem = fields.UIList_Head:AddListItem()
		listItem.Controls["UITexture_01"]:SetIconTexture("")
	end
end

local function RefreshTime(msg)
	fields.UILabel_Time.text = LocalString.CancelText .. "  ".. msg.lefttime .."s"
	if msg.lefttime == 0 then
		UIManager.hide(name)
		if UIManager.isshow("common.dlgdialogbox_common") then
			UIManager.hide("common.dlgdialogbox_common")
		end
	end
end

local function ShowFlyTextRestTime()
	local lefttime = LimitTimeManager.GetLeftTime(cfg.cmd.ConfigId.CHAT,cfg.chat.ChannelType.INVITE)
	lefttime = math.ceil(lefttime)
		-- printyellow("lefttime",lefttime)
	local minite = math.ceil(lefttime / SECONDS_PER_MINITE)
	local second = math.ceil(lefttime % SECONDS_PER_MINITE)
	if minite < 10 then minite = "0"..minite end
	if second < 10 then second = "0"..second end
	UIManager.ShowSystemFlyText(string.format(LocalString.MultiEctype_CoolDown_Time,minite,second))
end

local function ShowInviteButton(dlgfields,name,params)

	dlgfields.UIGroup_ItemUse.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(false)
	dlgfields.UIGroup_Title.gameObject:SetActive(false)
	dlgfields.UIGroup_Revive.gameObject:SetActive(true)
	dlgfields.UIGroup_Message.gameObject:SetActive(false)
	dlgfields.UILabel_SituResurrection.text = LocalString.MultiEctype_Invite_World
	dlgfields.UILabel_StwpResurrection.text = LocalString.MultiEctype_Invite_Family


	EventHelper.SetClick(dlgfields.UIButton_SituResurrection,function() --发送到世界频道和副本频道
		 printyellow("LimitTimeManager.GetLeftTime(cfg.cmd.ConfigId.CHAT,cfg.chat.ChannelType.INVITE)",LimitTimeManager.GetLeftTime(cfg.cmd.ConfigId.CHAT,cfg.chat.ChannelType.INVITE))
		if LimitTimeManager.IsReady(cfg.cmd.ConfigId.CHAT,cfg.chat.ChannelType.INVITE) then
			local item ={}
			item.channel = cfg.chat.ChannelType.INVITE
			item.invitechannel = cfg.chat.ChannelType.WORLD
			item.text = params.cur_ectypeid
			if item.text and item.text ~= "" then
				ChatManager.SendCChat(item)
			end
		else
			ShowFlyTextRestTime()
		end


	end)

	
		EventHelper.SetClick(dlgfields.UIButton_StwpResurrection,function() --发送到家族频道和副本频道
			if FamilyManager.InFamily() then
				if LimitTimeManager.IsReady(cfg.cmd.ConfigId.CHAT,cfg.chat.ChannelType.INVITE) then
					local item ={}
					item.channel = cfg.chat.ChannelType.INVITE
					item.invitechannel = cfg.chat.ChannelType.FAMILY
					item.text = params.cur_ectypeid
					if item.text and item.text ~= "" then
						ChatManager.SendCChat(item)
					end
				else
					ShowFlyTextRestTime()
				end
			else
				UITools.SetButtonEnabled(dlgfields.UIButton_StwpResurrection,false)
				UIManager.ShowSystemFlyText(LocalString.Open_Need_Family)
			end
		end)

end

local function show(params)
	  cur_ectypeid = MultiEctypeManager.GetCurEctypeId()
end

local function destroy()
end

local function SetTwoButtonsEnabled(item)
	  UITools.SetButtonEnabled(fields.UIButton_Cancel,item.isSuccessful)
	  UITools.SetButtonEnabled(fields.UIButton_Team,item.isSuccessful)
end

local function refresh(params)
	local roleinfos = MultiEctypeManager.GetRoleInfos()
	fields.UILabel_Title.text = string.format(LocalString.MultiEctype_Title,MultiEctypeManager.GetTitle())
	if roleinfos then RefreshHeadIcon(roleinfos) end
		EventHelper.SetClick(fields.UIButton_Cancel,function()
			if not TeamManager.IsInTeam() then  --不是组队状态下取消报名
				MultiEctypeManager.SendCCancelEnrollMultiStoryEctype() --取消匹配
				MultiEctypeManager.SetStoryEctypeLeftTime(0)
				UIManager.hide(name)
				return
			end
			if TeamManager.IsInTeam() and TeamManager.IsLeader(PlayerRole:Instance().m_Id) then
				MultiEctypeManager.SendCCancelEnrollMultiStoryEctype() --取消匹配
				MultiEctypeManager.SetStoryEctypeLeftTime(0)
				UIManager.hide(name)
			else
				 --不是队长不能取消报名
			end
		end )

		EventHelper.SetClick(fields.UIButton_Team,function()
			UIManager.show("common.dlgdialogbox_common",{cur_ectypeid = cur_ectypeid,callBackFunc = ShowInviteButton})
		end)

		EventHelper.SetClick(fields.UISprite_Black,function() --黑色背景
			if  not MultiEctypeManager.IsMatchingSuccessful() then
				UIManager.hidedialog("ectype.dlgentrance_copy")
				UIManager.hide(name)

				UIManager.show("dlguimain")
				UIManager.call("dlguimain","SetMatching",{matching = true,callBack = Func,matchmode = "multistory"})
			end
		end)
end

local function init(params)
	name, gameObject, fields = unpack(params)
end

return {
	show = show,
	hide = hide,
	init = init,
	destroy = destroy,
	refresh = refresh,
	RefreshTime = RefreshTime,
	ShowInviteButton = ShowInviteButton,
	SetTwoButtonsEnabled = SetTwoButtonsEnabled,
}
