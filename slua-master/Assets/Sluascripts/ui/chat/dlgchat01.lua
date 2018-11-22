local unpack = unpack
local print = print
local table = table
--local insert = table.insert
local math = math
local string = string
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local login = require("login")

local Player = require"character.player"
local ConfigManager = require "cfg.configmanager"
local CharacterManager = require "character.charactermanager"
local octets        = require "common.octets"
local define = require "defineenum"
local PlayerRole = require "character.playerrole"
local BagManager = require "character.bagmanager"
local FamilyManager = require "family.familymanager"
local SettingManager = require("character.settingmanager")
local ItemIntroduction = require("item.itemintroduction")
local MultiEctypeManager = require("ui.ectype.multiectype.multiectypemanager")
local EctypeManager = require("ectype.ectypemanager")
local ItemEnum = require("item.itemenum")
--local EmojiText = require("ui.chat.emojitext")
--local HugeScroll = require("ui.chat.hugescroll")

local TeamManager = require "ui.team.teammanager"
local ItemManager = require("item.itemmanager")
local itemnum     = require("item.itemenum")
local chatmanager = require("ui.chat.chatmanager")
local jubaomanager= require("ui.chat.jubaomanager")

local Command = require("assistant.command.commandmanager")
local ChatEmoji = require("ui.chat.chatemoji")
local ChatFormat = require("ui.chat.chatformat")
--local ChatFriend = require("ui.chat.chatfriend")

-- 全局变量
local curFaceName
local UIList_ChatArea
local UIList_Friend
local UIListItems = {}

--local voiceListItemInfo = {}
--local emojitext
local hugescroll
local isBrowsing = false
-- 背包信息
local gSelectedBagType
local gSelectedItem = nil

local BAG_TYPE ={
	ITEM = 1,  --物品（包括碎片）
	EQUIP = 2, --普通装备
	ACCESSORY = 3, --首饰
	TALISMAN = 4, --法宝
}
local BAG_SELECT_TABS = {
	[cfg.bag.BagType.ITEM] = 2,
	[cfg.bag.BagType.EQUIP] = 0,
	[cfg.bag.BagType.FRAGMENT] = 1,
	[cfg.bag.BagType.TALISMAN] = 3,
	[cfg.bag.BagType.EQUIP_BODY] = 4,
	--[cfg.bag.BagType.PET] = 2,
}

local gameObject
local name
local fields

local CHANNEL = {
    WORLD   = cfg.chat.ChannelType.WORLD,      --世界频道
    PRIVATE = cfg.chat.ChannelType.PRIVATE,    --私人频道
    TEAM    = cfg.chat.ChannelType.TEAM,       --队伍频道
    FAMILY  = cfg.chat.ChannelType.FAMILY,     --家族频道
    SYSTEM  = cfg.chat.ChannelType.SYSTEM,     --系统频道
	INVITE  = cfg.chat.ChannelType.INVITE,     --组队频道
	TOP     = cfg.chat.ChannelType.TOP,
}


local ChatItem                --发送消息的内容
local BagEquip
local FriendList      = {}
local EmojiTableChat  = {}
local ItemTableChat ={}

local INIT_LENGTH = 80   --语音条的最大长度
local PER_LENGTH =  4	 --平均每秒的语音条长度

local EmojiTable      = {}
local offSet = 0


local function RefreshChatTitle()
	if chatmanager.GetCurChannel() ~= CHANNEL.PRIVATE then
		fields.UILabel_Chat.text = LocalString.Chat_ChatTitle 
	else
		local tempstring = chatmanager.GetCurPrivateChatName()
		if chatmanager.GetCurPrivateChatName() then
			fields.UILabel_Chat.text = string.format(LocalString.Chat_PrivateChatName,chatmanager.GetCurPrivateChatName()) 
		else
			fields.UILabel_Chat.text = ""
		end
	end
end

local function GetTickAndPrayValue(index)
	if index >= 1 and index <= 8 then
		if fields["UIToggle_CheckBox0"..index].gameObject.activeSelf then
			return false,fields["UIToggle_CheckBox0"..index].value
		else
			return true,fields["UIToggle_CheckBoxPray0"..index].value
		end
	else
		return true,true
	end
end

local function GetCurTable()
	local curTable = {}
	local pray,value 
    local v1 = { "isPray", "isTick"}


	curTable[cfg.chat.ChannelType.WORLD]    = {}
    curTable[cfg.chat.ChannelType.PRIVATE]  = {}
    curTable[cfg.chat.ChannelType.FAMILY]   = {}
    curTable[cfg.chat.ChannelType.TEAM]     = {}
    curTable[cfg.chat.ChannelType.SYSTEM]   = {}
    curTable[6]   = {}
    curTable[7]   = {}
	curTable[8] = {}

	for i = 1, 8 do
		pray,value = GetTickAndPrayValue(i)
		curTable[i].isPray   =   pray
		curTable[i].isTick   =   value
	end
	print(curTable)
	return curTable
end

local function SetUIToggle()

	local CurSettingTable = SettingManager.GetSettingTableByChannel(chatmanager.GetCurChannel())
	assert(CurSettingTable)
	for i = 1, 8 do
		if CurSettingTable[i].isPray == true then
		    fields["UIToggle_CheckBox0"..i].gameObject:SetActive(false)
		    fields["UIToggle_CheckBoxPray0"..i].gameObject:SetActive(true)
		    if CurSettingTable[i].isTick == true then
		        fields["UIToggle_CheckBoxPray0"..i].value = true
		    else
		        fields["UIToggle_CheckBoxPray0"..i].value = false
		    end
		else
		    fields["UIToggle_CheckBox0"..i].gameObject:SetActive(true)
		    fields["UIToggle_CheckBoxPray0"..i].gameObject:SetActive(false)
		    if CurSettingTable[i].isTick == true then
		        fields["UIToggle_CheckBox0"..i].value = true
		    else
		        fields["UIToggle_CheckBox0"..i].value = false
		    end
		end
	end

end



local function destroy()
  --print(name, "destroy")
end

local function SetChatChannelTag(channel)
	if channel == cfg.chat.ChannelType.WORLD then
		fields.UILabel_Channel01.text = "[FFE383]#世界"
	elseif channel == cfg.chat.ChannelType.PRIVATE then
		fields.UILabel_Channel01.text = "[F5A7FE]#私聊"	
	elseif channel == cfg.chat.ChannelType.TEAM then
        fields.UILabel_Channel01.text = "[86D6FF]#队伍"
	elseif channel == cfg.chat.ChannelType.FAMILY then
		fields.UILabel_Channel01.text = "[AAE987]#仙府"
	elseif channel == cfg.chat.ChannelType.SYSTEM then
        fields.UILabel_Channel01.text = "[FF8F79]#系统"
	elseif channel == cfg.chat.ChannelType.INVITE then
		fields.UILabel_Channel01.text = "[FF8F79]#副本"
	elseif channel == cfg.chat.ChannelType.TOP then
		fields.UILabel_Channel01.text = "[FF8F79]#置顶"
	else
		error("Channel doesnot exit")
	end	
end


local function DisplayPrivateMessage(friendname,index)
		local listitem = fields.UIList_Channel:GetItemByIndex(1)
		listitem.Checkbox.startsActive = false
		--printyellow("DisplayPrivateMessage = ",index)
		fields.UIList_Channel:SetSelectedIndex(index)
		fields.UIButton_Arrows.gameObject:SetActive(true)	
		chatmanager.SetCurChannel(CHANNEL.PRIVATE)  
		SetChatChannelTag(CHANNEL.PRIVATE)	
		RefreshChatTitle()
end



local function hide()	
	if fields.UIGroup_Settings.gameObject.activeSelf == true then
		SettingManager.SetSettingTableByChannel(chatmanager.GetCurChannel(),GetCurTable())
	end 
	SettingManager.SendCSetConfigureChat()
end


local function update()

end

-- 计算两次单击之间的角度
local function CalcAngle()
    local controlDir = (endMousePoint - startMousePoint).normalized
    local angle = Vector2.Angle(Vector2.up, controlDir)
    if controlDir.x < 0 then
        angle = 360 - angle
    end

    local tAngle = angle
    local hDegree = 22.5
    local vDegree = 22.5
    local dDegree = 22.5
    if tAngle < 0 + hDegree or tAngle >= 360.0 - hDegree then
        angle = 0
    elseif tAngle >= 45 - dDegree and tAngle < 45 + dDegree then
        angle = 45
    elseif tAngle >= 90 - vDegree and tAngle < 90 + vDegree then
        angle = 90
    elseif tAngle >= 135 - dDegree and tAngle < 135 + dDegree then
        angle = 135
    elseif tAngle >= 180 - hDegree and tAngle < 180 + hDegree then
        angle = 180
    elseif tAngle >= 225 - dDegree and tAngle < 225 + dDegree then
        angle = 225
    elseif tAngle >= 270 - vDegree and tAngle < 270 + vDegree then
        angle = 270
    elseif tAngle >= 315 - hDegree and tAngle < 315 + hDegree then
        angle = 315
    end

    return angle
end



local function GetVoiceLength(seconds)
	return INIT_LENGTH + PER_LENGTH * seconds
end


local function ShowBagInfo(item)

	if item:GetBaseType() == ItemEnum.ItemBaseType.Talisman then
		uimanager.show("dlgalert_talisman",{ item = item ,showButton = false})
	else
	 ItemIntroduction.DisplayItem( {
		item = item ,
		variableNum = false,
		buttons =
		{
		    { display = false, text = "", callFunc = nil },
		    { display = false, text = "", callFunc = nil },
		    { display = false, text = "", callFunc = nil }
		}})
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




local function ShowPiPeiIcon(ectypeid,roleid)
	if roleid == PlayerRole:Instance().m_Id then
		return 
	else
        EctypeManager.SendScroll(ectypeid)
--		if EctypeManager.CanSendScroll(ectypeid) then
--			MultiEctypeManager.SendCEnrollMultiStoryEctype( lx.gs.map.msg.CEnrollMultiStoryEctype.SINGLE,section.id)
--		end
	end 
end

local function SetActiveOtherBG(b)
	if b == false and fields.UIGroup_Settings.gameObject.activeSelf == true then
		SettingManager.SetSettingTableByChannel(chatmanager.GetCurChannel(),GetCurTable()) 
	end
	if b == false and fields.UIGroup_Emoji.gameObject.activeSelf == true then
		--TODO执行时间不够没执行完对象就被屏蔽
		--fields.UIList_Button_Emoji:SetUnSelectedIndex(0) 
		fields.UIGroup_Emoji.gameObject:SetActive(b)
	end
	fields.UIGroup_Settings.gameObject:SetActive(b)
	fields.UIGroup_Friend.gameObject:SetActive(b)
	fields.UIGroup_Bag.gameObject:SetActive(b)
end

local function ShowRoleInfoDetails(roleId)
	SetActiveOtherBG(false)
	uimanager.showdialog("otherplayer.dlgotherroledetails", {roleId = roleId,buttons = {
		[1]={name = LocalString.Chat_Jubao ,action = function()
--			printyellow("jubaomanager.GetLevelLowestJubao()",jubaomanager.GetLevelLowestJubao())
			if PlayerRole:Instance().m_Level >= jubaomanager.GetLevelLowestJubao() then
				if jubaomanager.GetLeftReportTime() > 0 then
					jubaomanager.SendCReportPlayer(roleId)
				else
					uimanager.ShowSystemFlyText(LocalString.Chat_Jubao_UsedUp)
				end
			else 
				uimanager.ShowSystemFlyText(string.format(LocalString.Chat_LessLevel_Jubao,jubaomanager.GetLevelLowestJubao()))
			end 
		end 
		}}})
end

local function SelectShowLabelRight(listItem,a,b,c,d,e,f,g)
	listItem.Controls["UILabel_Content02"].gameObject:SetActive(a)
	listItem.Controls["UILabel_Name02"].gameObject:SetActive(b)
	listItem.Controls["UILabel_SpeakTO_02"].gameObject:SetActive(c)
	listItem.Controls["UILabel_Content02_Face"].gameObject:SetActive(false)
	listItem.Controls["UISprite_ContentBG04"].gameObject:SetActive(e)
	listItem.Controls["UISprite_ContentBG_Face05"].gameObject:SetActive(f)
	listItem.Controls["UILabel_Content02_emoji"].gameObject:SetActive(g)
--	listItem.Controls["UISprite_ContentBG_Face02"].gameObject:SetActive(false)
end

local function SelectShowLabelLeft(listItem,a,b,c,d,e,f,g)
	listItem.Controls["UILabel_Content01"].gameObject:SetActive(a)
	listItem.Controls["UILabel_Name01"].gameObject:SetActive(b)
	listItem.Controls["UILabel_SpeakTO_01"].gameObject:SetActive(false)
	listItem.Controls["UILabel_Content01_Face"].gameObject:SetActive(false)
	listItem.Controls["UISprite_ContentBG03"].gameObject:SetActive(e)
	listItem.Controls["UISprite_ContentBG_Face06"].gameObject:SetActive(f)	
	listItem.Controls["UILabel_Content01_emoji"].gameObject:SetActive(g)
--	listItem.Controls["UISprite_ContentBG_Face01"].gameObject:SetActive(false)
end

local function AddMessageEmoji(isSend, list_item, ChatData, icon)

	if isSend then
		list_item = UIList_ChatArea:AddListItem(UIListItems[2])   --UIGroup_1Right
		
		
		
		if ChatData.channel == CHANNEL.PRIVATE then 
			SelectShowLabelRight(list_item,false,false,true,true,false,false,true)
			list_item.Controls["UILabel_SpeakTOName02"].text = ChatData.receivername
		else
			SelectShowLabelRight(list_item,false,true,false,true,false,false,true)
			list_item.Controls["UILabel_Name02"].text = chatmanager.GetChannelTag(ChatData.channel)..LocalString.Chat_Channel_Me
		end 
		list_item.Controls["UISprite_HeadRight"].spriteName = icon --character:GetHeadIcon()
		list_item.Controls["UILabel_Content02_emoji"].text = ChatData.text

	else
		list_item = UIList_ChatArea:AddListItem(UIListItems[3])   --UIGroup_1Right
		SelectShowLabelLeft(list_item,false,true,false,false,false,false,true)
        list_item.Controls["UILabel_Name01"].text = chatmanager.GetChannelTag(ChatData.channel).. ChatData.sendername
		list_item.Controls["UISprite_HeadLeft"].spriteName = icon			--character:getheadicon()
		list_item.Controls["UILabel_Content01_emoji"].text = 	ChatData.text	
		EventHelper.SetClick(list_item.Controls["UISprite_HeadLeft"],function()  --点击头像弹出个人信息界面
			ShowRoleInfoDetails(ChatData.senderid)
		end)
	end

end

local function AddMessageVoice(isSend,list_item,ChatData,icon)  --增加语音条


                if isSend == true then                --【发送】
					list_item = UIList_ChatArea:AddListItem(UIListItems[2])  --UIGroup_4VoiceRight
                    list_item.Data = ChatData.voiceid
					chatmanager.SetServerInfoByVoiceId(ChatData.voiceid, ChatData.voice)
					if ChatData.channel == CHANNEL.PRIVATE then 
						SelectShowLabelRight(list_item,false,false,true,false,true,false,false)
						list_item.Controls["UILabel_SpeakTOName02"].text = ChatData.receivername
					else
						SelectShowLabelRight(list_item,false,true,false,false,true,false,false)
						list_item.Controls["UILabel_Name02"].text =  chatmanager.GetChannelTag(ChatData.channel)..LocalString.Chat_Channel_Me
					end 
 
					list_item.Controls["UISprite_HeadRight"].spriteName = icon  --character:GetHeadIcon()
					list_item.Controls["UILabel_Time04"].text = math.ceil(ChatData["voiceduration"]/1000) .."\""
					list_item.Controls["UILabel_SpeechContent04"].text = ChatData["text"]
					list_item.Controls["UILabel_SpeechContent04"].gameObject:SetActive(true)
                    sprite_voice = list_item.Controls["UISprite_ContentBG04"]
                    --sprite_voice.width = GetVoiceLength(ChatData["voiceduration"]/1000)
					chatmanager.AddVoiceListItemInfo(ChatData.voiceid,list_item)
--					local SettingChat = SettingManager.GetSettingTableByChannel(chatmanager.GetCurChannel())
--					print("dlgchat01 = ",SettingChat[7].isTick)
--					print("dlgchat01 voiceid = ",chatmanager.GetCurPlayingVoiceId())
--					print("dlgchat01 list_item.Data = ",list_item.Data)
--					if SettingChat[7].isTick and chatmanager.GetCurPlayingVoiceId() == list_item.Data then
----						if chatmanager.IsStartPlay() == false then
--							chatmanager.SetCurListItemVoice(list_item)
----						else 
----							chatmanager.SetCurListItemVoice1(list_item)	
----						end	
--					end

					 local button = sprite_voice.gameObject:GetComponent(UIButton)
					 EventHelper.SetClick(button,function()   

						if chatmanager.IsStartPlay() == false then
							chatmanager.SetCurListItemVoice(list_item.Data)
						else 
							chatmanager.SetCurListItemVoice1(list_item.Data)	
						end					 
						chatmanager.ResetVoiceAnimationData(0,10)
						 --如果语音含有敏感字就不让播放
						 if string.find(ChatData["text"],'*') then
							 return
						 end

						chatmanager.StartPlayVoice(list_item.Data)
					 end )

                else                                  -- 【接收】
                    list_item = UIList_ChatArea:AddListItem(UIListItems[3])  --UIGroup_3VoiceLeft

--					list_item.Controls["UITexture_Thumbnail_03"].gameObject:SetActive(false)
                    list_item.Data = ChatData.voiceid
					chatmanager.SetServerInfoByVoiceId(ChatData.voiceid, ChatData.voice)
					if chatmanager.GetRedInfoByVoiceId(list_item.Data) then
						list_item.Controls["UISprite_Unread"].gameObject:SetActive(false)						
					end 
					SelectShowLabelLeft(list_item,false,true,false,false,true,false,false)
                    list_item.Controls["UILabel_Name01"].text =  chatmanager.GetChannelTag(ChatData.channel)..ChatData.sendername
					list_item.Controls["UISprite_HeadLeft"].spriteName = icon  --character:GetHeadIcon()
					list_item.Controls["UILabel_Time03"].text = math.ceil(ChatData["voiceduration"]/1000) .."\""
					list_item.Controls["UILabel_SpeechContent03"].gameObject:SetActive(true)
					list_item.Controls["UILabel_SpeechContent03"].text =chatmanager.GetChannelContent(ChatData.channel,ChatData["text"])
                    sprite_voice = list_item.Controls["UISprite_ContentBG03"]
                    --sprite_voice.width = GetVoiceLength(ChatData["voiceduration"]/1000)
					chatmanager.AddVoiceListItemInfo(ChatData.voiceid,list_item)

					EventHelper.SetClick(list_item.Controls["UISprite_HeadLeft"],function()  --点击头像弹出个人信息界面
--						local friendname = list_item.Controls["UILabel_Name03"].text
--						DisplayPrivateMessage(friendnasme,1)
						ShowRoleInfoDetails(ChatData.senderid)
					end)

                local button = sprite_voice.gameObject:GetComponent(UIButton)



                EventHelper.SetClick(button,function()   --点击语音条进行播放（如果是第一次点，则取消红点）
					if chatmanager.IsStartPlay() == false then
						chatmanager.SetCurListItemVoice(list_item.Data)
					else 
						chatmanager.SetCurListItemVoice1(list_item.Data)
					end	
					chatmanager.ResetVoiceAnimationData(0,10)

					if not chatmanager.GetRedInfoByVoiceId(list_item.Data)  then
						chatmanager.SetRedInfoByVoiceId(list_item.Data,true)
						list_item.Controls["UISprite_Unread"].gameObject:SetActive(false) --去掉红点
					end

					--如果语音含有敏感字就不让播放
					if string.find(ChatData["text"],'*') then
						return
					end

					chatmanager.StartPlayVoice(list_item.Data)
                end )
                end
end

local function AddMessageText(isSend,list_item,ChatData,icon)
--		printyellow("AddMessageText")
        if  ChatData.channel == CHANNEL.SYSTEM or ChatData.invitechannel == CHANNEL.WORLD or ChatData.invitechannel == CHANNEL.FAMILY then  --发文字，需要解析【无头像】

				
			list_item = UIList_ChatArea:AddListItem(UIListItems[1])  -- UIGroup_0CIContent

            if ChatData.channel == CHANNEL.INVITE then
				list_item.Controls["UILabel_Name_sys"].text = chatmanager.GetChannelTag(CHANNEL.SYSTEM)..LocalString.ChatSystemName
				list_item.Controls["UILabel_Content"].text = chatmanager.GetChannelContent(CHANNEL.SYSTEM,ChatData.text)
                --list_item.Controls["UILabel_Content"].text = chatmanager.GetChannelTag(CHANNEL.INVITE)..ChatData.text

            elseif ChatData.channel == CHANNEL.SYSTEM then
				list_item.Controls["UILabel_Name_sys"].text = chatmanager.GetChannelTag(CHANNEL.SYSTEM)..LocalString.ChatSystemName
				list_item.Controls["UILabel_Content"].text = chatmanager.GetChannelContent(CHANNEL.SYSTEM,ChatData.text)
                --list_item.Controls["UILabel_Content"].text = chatmanager.GetChannelTag(CHANNEL.SYSTEM)..ChatData.text

            elseif ChatData.invitechannel == CHANNEL.WORLD then
				list_item.Controls["UILabel_Name_sys"].text = chatmanager.GetChannelTag(CHANNEL.WORLD)..LocalString.ChatSystemName
				list_item.Controls["UILabel_Content"].text = chatmanager.GetChannelContent(CHANNEL.WORLD,ChatData.name..":\n"..ChatData.text)
                --list_item.Controls["UILabel_Content"].text = chatmanager.GetChannelTag(CHANNEL.WORLD)..ChatData.name..":\n"..ChatData.text
						EventHelper.SetClick(list_item.Controls["UILabel_Content"],function()
						uimanager.ShowAlertDlg({
						immediate       = true,
						content         = string.format(LocalString.PIPEI_Tip[1], ChatData.name),
						callBackFunc    = function()
							ShowPiPeiIcon(ChatData.ectypeid,ChatData.roleid)
						end,
						})
						--ShowPiPeiIcon(ChatData.ectypeid,ChatData.roleid)
						end)
			elseif ChatData.invitechannel == CHANNEL.FAMILY then
				list_item.Controls["UILabel_Name_sys"].text = chatmanager.GetChannelTag(CHANNEL.FAMILY)..LocalString.ChatSystemName
				list_item.Controls["UILabel_Content"].text = chatmanager.GetChannelContent(CHANNEL.FAMILY,ChatData.name..":\n"..ChatData.text)
                --list_item.Controls["UILabel_Content"].text = chatmanager.GetChannelTag(CHANNEL.FAMILY)..ChatData.name..":\n"..ChatData.text
				EventHelper.SetClick(list_item.Controls["UILabel_Content"],function()
					
						uimanager.ShowAlertDlg({
						immediate       = true,
						content         = string.format(LocalString.PIPEI_Tip[1], ChatData.name),
						callBackFunc    = function()
							ShowPiPeiIcon(ChatData.ectypeid,ChatData.roleid)
						end,
						})
						
							--ShowPiPeiIcon(ChatData.ectypeid,ChatData.roleid)
				end)
			else

			end

        else
--isSend = false

            if isSend == true then                     --【发送】
--				printyellow("UIListItems[2]",UIListItems[2])
				list_item = UIList_ChatArea:AddListItem(UIListItems[2])   --UIGroup_1Right

				if ChatData.channel == CHANNEL.PRIVATE then 
					SelectShowLabelRight(list_item,true,false,true,false,false,false,false)
					list_item.Controls["UILabel_SpeakTOName02"].text = ChatData.receivername
				else
					SelectShowLabelRight(list_item,true,true,false,false,false,false,false)
					list_item.Controls["UILabel_Name02"].text = chatmanager.GetChannelTag(ChatData.channel)..LocalString.Chat_Channel_Me
				end 
				list_item.Controls["UISprite_HeadRight"].spriteName = icon --character:GetHeadIcon()


--				emojitext:Parse(ChatData.text,false)
--				printt(emojitext)
--				printyellow("emojitext.emj","#"..emojitext.emjresult.txt.."#")
--				printyellow("emojitext.txt","#"..emojitext.txtresult.txt.."#")

--				list_item.Controls["UILabel_Content02_Face"].text = emojitext.emjresult.txt
--				list_item.Controls["UILabel_Content02"].text = emojitext.txtresult.txt

				list_item.Controls["UILabel_Content02"].text = ChatData.text


            else                                       --【接受】

                list_item = UIList_ChatArea:AddListItem(UIListItems[3])   --UIGroup_2Left
--				list_item.Data = bagInfo
				SelectShowLabelLeft(list_item,true,true,false,true,false,false,false)	
                list_item.Controls["UILabel_Name01"].text = chatmanager.GetChannelTag(ChatData.channel).. ChatData.sendername
				list_item.Controls["UISprite_HeadLeft"].spriteName = icon			--character:getheadicon()
--				emojitext:Parse(ChatData.text,false)			
--				list_item.Controls["UILabel_Content01_Face"].text = emojitext.emjresult.txt
--				list_item.Controls["UILabel_Content01"].text = emojitext.txtresult.txt

				--list_item.Controls["UILabel_Content01"].text = ChatData.text
				list_item.Controls["UILabel_Content01"].text =chatmanager.GetChannelContent(ChatData.channel,ChatData.text)

				EventHelper.SetClick(list_item.Controls["UISprite_HeadLeft"],function()  --点击头像弹出个人信息界面
						ShowRoleInfoDetails(ChatData.senderid)
				end)

            end       
	    
	    
	     end
end 

local function AddMessageBag(isSend,list_item,ChatData,bagInfo,icon)
--	printyellow("AddMessageBag")

	if isSend == true then                     --【发送】
	
		list_item = UIList_ChatArea:AddListItem(UIListItems[2])   --UIGroup_1Right
		list_item.Data = bagInfo
		if ChatData.channel == CHANNEL.PRIVATE then 
			SelectShowLabelRight(list_item,true,false,true,false,false,false,false)
			list_item.Controls["UILabel_SpeakTOName02"].text = ChatData.receivername
		else
			SelectShowLabelRight(list_item,true,true,false,false,false,false,false)
			list_item.Controls["UILabel_Name02"].text = chatmanager.GetChannelTag(ChatData.channel)..LocalString.Chat_Channel_Me
		end 
		
		list_item.Controls["UISprite_HeadRight"].spriteName = icon --character:GetHeadIcon()

		list_item.Controls["UILabel_Content02"].effectStyle = 3
		list_item.Controls["UILabel_Content02"].color = Color(1,1,1,1) 
		--list_item.Controls["UILabel_Content02"].spriteName = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
	
		colorutil.SetQualityColorText(list_item.Controls["UILabel_Content02"],bagInfo:GetQuality(),string.sub(ChatData.text,8))
--		list_item.Controls["UILabel_Content02"].text = colorutil.GetQualityColorText(bagInfo:GetQuality(),string.sub(ChatData.text,9))
	
	
		EventHelper.SetClick(list_item.Controls["UISprite_ContentBG02"],function()
			printyellow("wanglie")
			if fields.UIGroup_Bag.gameObject.activeInHierarchy == true then
			    fields.UIGroup_Bag.gameObject:SetActive(false)
			end
			if bagInfo then  ShowBagInfo(list_item.Data) end 
		end)
	
	else                                       --【接受】
	
	    list_item = UIList_ChatArea:AddListItem(UIListItems[3])   --UIGroup_2Left
		list_item.Data = bagInfo
		SelectShowLabelLeft(list_item,true,true,false,true,false,false,false)	
	    list_item.Controls["UILabel_Name01"].text = chatmanager.GetChannelTag(ChatData.channel).. ChatData.sendername
		list_item.Controls["UISprite_HeadLeft"].spriteName = icon			--character:getheadicon()
		list_item.Controls["UILabel_Content01"].effectStyle = 3
		list_item.Controls["UILabel_Content01"].color = Color(1,1,1,1) 
		colorutil.SetQualityColorText(list_item.Controls["UILabel_Content01"],bagInfo:GetQuality(),string.sub(ChatData.text,8))
	
		EventHelper.SetClick(list_item.Controls["UISprite_HeadLeft"],function()  --点击头像弹出个人信息界面
			local friendname = list_item.Controls["UILabel_Name01"].text
			DisplayPrivateMessage(friendname,2)
				ShowRoleInfoDetails(ChatData.senderid)
		end)
		EventHelper.SetClick(list_item.Controls["UISprite_ContentBG01"],function()
--				printyellow(list_item.Data)
				if fields.UIGroup_Bag.gameObject.activeInHierarchy == true then
				    fields.UIGroup_Bag.gameObject:SetActive(false)
				end
--				local selectedItem = GetItemInfoToShow(list_item.Data) 
				if bagInfo then  ShowBagInfo(list_item.Data) end 
	
		end)
	end

end
--local function AddMessageImage(isSend, list_item, ChatData, icon)
--	print("[dlgchat01:AddMessageImage] AddMessageImage, imageid=", ChatData.imageid)
--		if isSend == true then                     --【发送】
--			list_item = UIList_ChatArea:AddListItem(UIListItems[2])   --UIGroup_1Right
--			list_item.Data = ChatData.imageid
--			list_item.Controls["UILabel_Name02"].text =  chatmanager.GetChannelTag(ChatData.channel)..ChatData.sendername
--			list_item.Controls["UILabel_SpeakTO_02"].gameObject:SetActive(false)
--			list_item.Controls["UISprite_HeadRight"].spriteName = icon --character:GetHeadIcon()
--			list_item.Controls["UITexture_Thumbnail_02"].gameObject:SetActive(true)
--			list_item.Controls["UITexture_Thumbnail_02"]:SetByteTexture(ChatData.thumbnail.ByteArray)
--			sprite_image = list_item.Controls["UITexture_Thumbnail_02"]
--        else                                       --【接受】
--			list_item = UIList_ChatArea:AddListItem(UIListItems[3])
--			list_item.Data = ChatData.imageid
--            list_item.Controls["UILabel_Name01"].text =  chatmanager.GetChannelTag(ChatData.channel)..ChatData.sendername
--			list_item.Controls["UILabel_SpeakTO_01"].gameObject:SetActive(false)
--			list_item.Controls["UISprite_HeadLeft"].spriteName = icon--character:GetHeadIcon()
--			list_item.Controls["UITexture_Thumbnail_01"].gameObject:SetActive(true)
--			list_item.Controls["UITexture_Thumbnail_01"]:SetByteTexture(ChatData.thumbnail.ByteArray)
--			sprite_image = list_item.Controls["UITexture_Thumbnail_01"]
--			EventHelper.SetClick(list_item.Controls["UISprite_HeadLeft"],function()  --点击头像弹出个人信息界面
----				local friendname = list_item.Controls["UILabel_Name01"].text
----				DisplayPrivateMessage(friendname,1)
--						ShowRoleInfoDetails(ChatData.senderid)
--			end)
--        end

--		local button = sprite_voice.gameObject:GetComponent(UITexture)


----		printt(ChatData)
--        EventHelper.SetClick(button,function()     --点击缩略图图片放大

----            StartPlayVoice(voiceInfo[list_item.Data],list_item.Data)
--			if  imageInfo[list_item.Data] then
--				-- 放大图片	
--			else

--				chatmanager.SendCGetImage(ChatData.imageid)
--			end

--        end )
--end

local function AddMessageInviteMessage(list_item,ChatData)
	list_item = UIList_ChatArea:AddListItem(UIListItems[1])
	list_item.Controls["UILabel_Content"].text = chatmanager.GetChannelTag(CHANNEL.INVITE)..ChatData.name..":\n"..ChatData.text
	printyellow("AddMessageInviteMessage")
	EventHelper.SetClick(list_item.Controls["UILabel_Content"],function()
		printyellow("xxxx")
		ShowPiPeiIcon(ChatData.ectypeid,ChatData.roleid)
	end)
   
end

local function AddMessageFaceMessage(isSend, list_item, ChatData, icon)

	if isSend then
		list_item = UIList_ChatArea:AddListItem(UIListItems[2])   --UIGroup_1Right

		if ChatData.channel == CHANNEL.PRIVATE then 
			SelectShowLabelRight(list_item,false,false,true,false,false,true,false)
			list_item.Controls["UILabel_SpeakTOName02"].text = ChatData.receivername
		else
			SelectShowLabelRight(list_item,false,true,false,false,false,true,false)
			list_item.Controls["UILabel_Name02"].text = chatmanager.GetChannelTag(ChatData.channel)..LocalString.Chat_Channel_Me
		end 
		list_item.Controls["UISprite_HeadRight"].spriteName = icon --character:GetHeadIcon()
		list_item.Controls["UISprite_Face05"].spriteName = 	ChatData.text

	else
		list_item = UIList_ChatArea:AddListItem(UIListItems[3])   --UIGroup_1Right
		SelectShowLabelLeft(list_item,false,true,false,false,false,true,false)
        list_item.Controls["UILabel_Name01"].text = chatmanager.GetChannelTag(ChatData.channel).. ChatData.sendername
		list_item.Controls["UISprite_HeadLeft"].spriteName = icon			--character:getheadicon()
		list_item.Controls["UISprite_Face06"].spriteName = 	ChatData.text	
		EventHelper.SetClick(list_item.Controls["UISprite_HeadLeft"],function()  --点击头像弹出个人信息界面
			ShowRoleInfoDetails(ChatData.senderid)
		end)
	end
end

local function RePositionWhenNeeded()
	if not isBrowsing  then	
		local delayTimer = FrameTimer.New(function()                
			fields.UIScrollView_ChatArea:MoveToVerticalEnd()
		end, 2, 0)
		delayTimer:Start()  
	end
  
end


local function AddMessage(ChatData)
	print("[dlgchat01:AddMessage] AddMessage")

	printt(ChatData)
--	if chatmanager.GetCurChannel() ~= ChatData.channel then 
--		return
--	end
	local SettingTable = SettingManager.GetSettingTableByChannel(chatmanager.GetCurChannel())

	if not SettingTable then
		if chatmanager.GetCurChannel() ~= ChatData.channel then 
			return
		end
	end

	if SettingTable and not SettingTable[ChatData.channel].isTick then
		return 
	end

--	printyellow("SettingTable")
--	printyellow(chatmanager.GetCurChannel())
--	printyellow(ChatData.channel)
--	printyellow(SettingTable[ChatData.channel].isTick)

	if chatmanager.GetCurChannel() == CHANNEL.PRIVATE then
		if ChatData.senderid == PlayerRole:Instance().m_Id then
			if ChatData.receivername ~= chatmanager.GetCurPrivateChatName() then
				return 
			end
		else
			if ChatData.sendername ~= chatmanager.GetCurPrivateChatName() then
				return
			end
		end
	end

	if isBrowsing == true then
		fields.UIPanel_ShowChat.gameObject:SetActive(true)
	end

    local list_item
    local obj
    local sprite_voice
	local sprite_image
    local str
--	printyellow("dlgchat01 add messagexxx")
--	printt(ChatData)
	local isSend  = (ChatData.senderid == PlayerRole:Instance().m_Id )
--	local isSend  = (ChatData.sendername == PlayerRole:Instance().m_Name )
--	printyellow(ChatData.senderid)
--	printyellow(PlayerRole:Instance().m_Id)
	local professionInfo
	local modelname
	local icon
	if ChatData.senderprofession then professionInfo = ConfigManager.getConfigData("profession",ChatData.senderprofession) end
	if ChatData.sendergender then modelname      = cfg.role.GenderType.MALE == ChatData.sendergender and professionInfo.modelname or professionInfo.modelname2 end
	if modelname then icon           = ConfigManager.getConfigData("model",modelname).headicon end 
	local bagInfo 

	if  ChatData.item and ChatData.item ~="" then bagInfo = chatmanager.GetBagInfo(ChatData.bagtype,ChatData.item) end

	if  chatmanager.IsInviteMsg(ChatData) then       --发邀请信息
--		printyellow("invite message")
		AddMessageInviteMessage(list_item,ChatData)
--	elseif   ChatData.imageid and ChatData.imageid > 0 then        --发图片信息
--		AddMessageImage(isSend,list_item,ChatData,icon)			
	elseif  chatmanager.IsVoiceMsg(ChatData) then  		 --语音信息		
--		printyellow("voice message")													 --发语音信息
		AddMessageVoice(isSend,list_item,ChatData,icon)
    elseif chatmanager.IsBigFaceMsg(ChatData)  then	               --发大表情信息	
--		printyellow("big emoji message")											                          --发文字信息
		AddMessageFaceMessage(isSend,list_item,ChatData,icon)
	elseif chatmanager.IsEmojiMsg(ChatData) then
--		printyellow("small emoji message")	
		AddMessageEmoji(isSend,list_item,ChatData,icon)  --小表情
	elseif chatmanager.IsBagMsg(ChatData) then
--		printyellow("bag message")	
		AddMessageBag(isSend,list_item,ChatData,bagInfo,icon)          --发背包信息
	else
--		printyellow("text message")	
		AddMessageText(isSend,list_item,ChatData,icon)   --发普通文字信息（包括默认表情，背包信息）
    end
	UIList_ChatArea:Reposition()
	RePositionWhenNeeded()

end


local function ShowIconByNeed(a,b,c,d,e,f)
	fields.UISprite_Settings.gameObject:SetActive(a)
	fields.UIButton_BagIcon.gameObject:SetActive(b)
	fields.UIButton_Arrows.gameObject:SetActive(c)
	fields.UIGroup_Chat.gameObject:SetActive(d)
	fields.UIButton_Voice.gameObject:SetActive(e)
	if fields.UIButton_Expression.gameObject.activeSelf  == true and f == false then
		--fields.UIList_Button_Emoji:SetUnSelectedIndex(0)
	end
	fields.UIButton_Expression.gameObject:SetActive(f)

end

local function ResetMsgCountByIndex(index)
	local listitem = UIList_Friend:GetItemByIndex(index)
		listitem.Controls["UILabel_Unread"].text = string.format(LocalString.Chat_UnRead_Message,0)
end
local function SetFriendListIndex()
	if #chatmanager.GetRecentSpeakerList() ~= 0 then
--		printyellow("xxx")
		fields.UIList_FriendList:SetSelectedIndex(0)
		chatmanager.SetIsFriendList(false)
	else
		fields.UIList_FriendList:SetSelectedIndex(1)
--		printyellow("yyy")
		chatmanager.SetIsFriendList(true)
	end
end


local function RefreshPrivateChatList()
	UIList_Friend:Clear()
	chatmanager.SetRefreshPrivateListFunc(true)
	local list = chatmanager.GetPrivateChatList()
--	printyellow("RefreshPrivateChatList")
--	printt(list)  --- sort [1]
	for _,item in ipairs(list) do
		local listitem = UIList_Friend:AddListItem()
		listitem:SetText("UILabel_Level",item.level)
		listitem:SetText("UILabel_Name",item.name)

		listitem.Controls["UITexture_IdolHead"]:SetIconTexture(item.icon) 
		if  item.isOnline == 0 then
--			printyellow("off line")
			listitem.Controls["UILabel_Offlilne"].gameObject:SetActive(true)
			local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
			listitem.Controls["UITexture_IdolHead"].shader = inactiveShader
		end

		listitem.Controls["UILabel_VIP"].text = item.viplevel
		listitem.Controls["UILabel_FriendOrNot"].text = item.relationdes		
		if chatmanager.GetIsFriendList() then 
			listitem.Controls["UILabel_Unread"].gameObject:SetActive(false)
		else
			listitem.Controls["UILabel_Unread"].text = string.format(LocalString.Chat_UnRead_Message,item.count_msg or 0)	
		end 
		EventHelper.SetClick(listitem, function()
--			local name = listitem.Controls["UILabel_Name"]
			chatmanager.SetCurPrivateChatName(item.name)
			chatmanager.SetCurPrivateChatPlayerId(item.id)
			chatmanager.UpdateChatMessage(cfg.chat.ChannelType.PRIVATE,fields)
			chatmanager.ClearCountMsg(item.name) 
			if not chatmanager.GetIsFriendList() then 
				listitem.Controls["UILabel_Unread"].text = string.format(LocalString.Chat_UnRead_Message, 0)	
			end
			RefreshChatTitle()
		end)
		chatmanager.SetRefreshPrivateListFunc(false)
		UIList_Friend:Reposition()

	end	
end



local function ShowIconByChannel(channel)
	if channel == 7  then
		ShowIconByNeed(false,false,false,true,false,false)
	elseif channel == 6 then
		ShowIconByNeed(false,false,false,false,false,false)
	elseif channel == 5 then
		ShowIconByNeed(true,false,false,false,false,false)
	elseif channel == 2 then
		ShowIconByNeed(true,true,true,true,true,true)
	else
		ShowIconByNeed(true,true,false,true,true,true)
	end
end



local function show(params)
--	if uimanager.isshow("dlgdialog") then
--		local DlgDialog = require "ui.dlgdialog" 
--		DlgDialog.SetReturnButtonActive(false)
--	end 
    if params and params.index  then

--		printyellow("params.index = ",params.index)
		chatmanager.RefreshAllRecentSpeakerData()
		chatmanager.SetCurPrivateChatName(params.name)
		chatmanager.SetCurPrivateChatPlayerId(params.id)
--		printyellow("params.id = ",params.id)
		fields.UIList_Channel:SetUnSelectedIndex(0)
		fields.UIList_Channel:SetSelectedIndex(2)
		fields.UIGroup_Friend.gameObject:SetActive(true)
		if params.isShowTip then
			local list = chatmanager.GetRecentSpeakerList()
			chatmanager.ClearCountMsg(list[1].name)
			chatmanager.SetCurPrivateChatName(list[1].name)
			chatmanager.SetCurPrivateChatPlayerId(list[1].id)
		end
		SetFriendListIndex()
		RefreshPrivateChatList()
		ShowIconByNeed(true,true,true,true,true,true)
		DisplayPrivateMessage(params.name,params.index)	
--				printyellow("UpdateChatMessage_8")

    else
		chatmanager.RefreshAllRecentSpeakerData()
		local curchannel = chatmanager.GetCurChannel()
		chatmanager.SetCurChannel(curchannel)
		ShowIconByChannel(curchannel)
		fields.UIList_Channel:SetUnSelectedIndex(0)
		if curchannel == 2 then

				SetActiveOtherBG(false)
				fields.UIGroup_Friend.gameObject:SetActive(true)
				fields.UIPanel_ShowChat.gameObject:SetActive(false)
                chatmanager.SetCurChannel(CHANNEL.PRIVATE)  
				SetChatChannelTag(CHANNEL.PRIVATE)
				RefreshChatTitle()
				fields.UIList_Channel:SetSelectedIndex(2)

				chatmanager.ClearCountMsg(chatmanager.GetCurPrivateChatName())

				SetFriendListIndex()
				RefreshPrivateChatList()	

		elseif curchannel == 1 or curchannel>= 3 and curchannel <=6 then
			fields.UIList_Channel:SetSelectedIndex(chatmanager.GetCurChannel())
		else
			fields.UIList_Channel:SetSelectedIndex(0)
		end


	end
end

--local function SetUIGroupEmojiActive(b)
--	if b == false then 	fields.UIList_Button_Emoji:SetUnSelectedIndex(0) end
--	fields.UIGroup_Emoji.gameObject:SetActive(b)
--end


local function InitBagSlotList(bagType)
--	printyellow("InitBagSlotList",BagManager.GetTotalSize(bagType))
	if fields.UIList_Bag.Count == 0 then

		for i = 1, BagManager.GetTotalSize(bagType) do
			local bagItem = fields.UIList_Bag:AddListItem()
		end

	end
end

local function ClearBagSlotList()
	if fields.UIList_Bag.Count ~= 0 then
		fields.UIList_Bag:Clear()
	end
end

local function ResetBagSlotList(bagType)
	if fields.UIList_Bag.Count ~= 0 then

		local selectedListItems = fields.UIList_Bag:GetSelectedItems()

		if selectedListItems.Length ~= 0 then
			for i = 1, selectedListItems.Length  do
--				printyellow("selectedListItems[i].Index",selectedListItems[i].Index)
				fields.UIList_Bag:SetUnSelectedIndex(selectedListItems[i].Index)
			end
		end

		for i = 1, fields.UIList_Bag.Count do
			local listItem = fields.UIList_Bag:GetItemByIndex(i - 1)
			listItem:SetIconTexture("null")
			listItem:SetText("UILabel_Amount", 0)
			listItem.Controls["UISprite_Quality"].spriteName = ""
			listItem:SetText("UILabel_AnnealLevel", "+0")
			listItem.Data = nil

			ExtendedGameObject.SetActiveRecursely(listItem.Controls["UIGroup_Slots"].gameObject, false)
			listItem.Controls["UIGroup_Slots"].gameObject:SetActive(true)
			if i > BagManager.GetUnLockedSize(bagType) then
				listItem.Controls["UISprite_Lock"].gameObject:SetActive(true)
			else
				listItem.Controls["UISprite_Lock"].gameObject:SetActive(false)
			end
		end
	end
end

local function SetBagSlot(listItem, item, bagType)
    listItem.Id=item:GetConfigId()
    listItem.Controls["UIGroup_Slots"].gameObject:SetActive(true)

    if bagType == cfg.bag.BagType.ITEM then

        listItem.Controls["UISprite_AmountBG"].gameObject:SetActive(true)
        listItem.Controls["UILabel_Amount"].gameObject:SetActive(true)
        listItem:SetText("UILabel_Amount", item:GetNumber())
        if item:GetDetailType() == ItemEnum.ItemType.Medicine then
            local cdData = item:GetCDData()
			listItem.Controls["UISprite_CD"].gameObject:SetActive(true)
            listItem.Data = cdData
        end

    elseif bagType == cfg.bag.BagType.FRAGMENT then

        listItem.Controls["UISprite_AmountBG"].gameObject:SetActive(true)
        listItem.Controls["UILabel_Amount"].gameObject:SetActive(true)
        -- 物品数量大于等于合成要求数量，字体为绿色显示
        if item:GetConvertNumber() <= item:GetNumber() then
            listItem:SetText("UILabel_Amount", "[00FF66]" .. item:GetNumber() .. "/" .. item:GetConvertNumber() .. "[-]")
        else
            listItem:SetText("UILabel_Amount", item:GetNumber() .. "/" .. item:GetConvertNumber())
        end
        listItem.Controls["UISprite_Fragment"].gameObject:SetActive(true)
        -- 装备和碎片显示遮盖
        if item:GetProfessionLimit() ~= cfg.Const.NULL and item:GetProfessionLimit() ~= PlayerRole:Instance().m_Profession then
            listItem.Controls["UISprite_RedMask"].gameObject:SetActive(true)
        end

    elseif bagType == cfg.bag.BagType.EQUIP or bagType == cfg.bag.BagType.EQUIP_BODY then
		if item:IsMainEquip() and item:GetAnnealLevel() ~= 0  then
			listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(true)
			listItem.Controls["UISprite_AnnealLevel"].gameObject:SetActive(true)
			listItem:SetText("UILabel_AnnealLevel", "+" .. item:GetAnnealLevel())
		else
			listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
			listItem.Controls["UISprite_AnnealLevel"].gameObject:SetActive(true)
			listItem:SetText("UILabel_AnnealLevel", "+0")
		end
        -- 装备和碎片显示遮盖
        if item:GetProfessionLimit() ~= cfg.Const.NULL and item:GetProfessionLimit() ~= PlayerRole:Instance().m_Profession then
            listItem.Controls["UISprite_RedMask"].gameObject:SetActive(true)
        end
    elseif bagType == cfg.bag.BagType.TALISMAN then

    else
        logError("Bag type error!")
    end
    -- icon
    listItem.Controls["UITexture_Icon"].gameObject:SetActive(true)
    listItem:SetIconTexture(item:GetTextureName())
    -- 品质
    listItem.Controls["UISprite_Quality"].gameObject:SetActive(true)
    listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(item:GetQuality())
   -- listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
	-- 绑定
    listItem.Controls["UISprite_Binding"].gameObject:SetActive(item:IsBound())

    if item.bNewAdded then
        listItem.Controls["UISprite_New"].gameObject:SetActive(true)
    else
        listItem.Controls["UISprite_New"].gameObject:SetActive(false)
    end
end

local function ShowBagInfo(bagType)

	local itemList = fields.UIList_Bag

	local bagItems = BagManager.GetItems(bagType)
	local itemCount = BagManager.GetItemSlotsNum(bagType)

	for _, item in pairs(bagItems) do
		if item ~= nil then
			local listItem = itemList:GetItemByIndex(item.BagPos - 1)
			SetBagSlot(listItem, item, bagType)
		end
	end

	fields.UILabel_BagItemAmount.text = itemCount .. "/" .. BagManager.GetTotalSize(bagType)
end



local function refresh(params)

    if params and params.index  then
		chatmanager.UpdateChatMessage(CHANNEL.PRIVATE,fields)
    else
		chatmanager.UpdateChatMessage(chatmanager.GetCurChannel(),fields)
	end

	--fields.UIList_Button_Emoji:SetUnSelectedIndex(0)
end

local function IsShowFriend()

     if fields.UIGroup_Friend.gameObject.activeSelf == true then
        return true
     else
        return false
     end
end




--local function OnUIButton_PhotoClicked()
--    print("[dlgchat01:OnUIButton_PhotoClicked] UIButton_Photo Clicked!")
--    local receiver
--    if chatmanager.GetCurChannel() == CHANNEL.PRIVATE then   --私聊的时侯需要指出receiver
--	    local FriendIdList = chatmanager.GetFriendIdList()
--        receiver  = FriendIdList[GetFriendName()]
--    end
--    chatmanager.SelectPhoto(chatmanager.GetCurChannel(), receiver)
--end

local function ShowTopMessage(dlgfields,name,params)
	dlgfields.UIGroup_Content_Three.gameObject:SetActive(false)
	dlgfields.UIGroup_TextWarp.gameObject:SetActive(false)
	dlgfields.UIGroup_Compare.gameObject:SetActive(false)
	dlgfields.UIGroup_TextWarp2.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_1.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(true)
	dlgfields.UIGroup_Resource.gameObject:SetActive(false)
	dlgfields.UIGroup_Revive.gameObject:SetActive(false)
	dlgfields.UIGroup_Reminder_Full.gameObject:SetActive(true)
	dlgfields.UIGroup_ItemUse.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single2.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single3.gameObject:SetActive(false)
	dlgfields.UILabel_Title.text           = LocalString.TipText --"购买表情"


	dlgfields.UILabel_Content_Single1.text = LocalString.Chat_Top_MessageTip
	dlgfields.UILabel_Return.text          =  LocalString.CancelText
	dlgfields.UILabel_Sure.text            =  LocalString.SureText

	EventHelper.SetClick(dlgfields.UIButton_Return,function ()
		uimanager.hide("common.dlgdialogbox_common")

	end)

	EventHelper.SetClick(dlgfields.UIButton_Sure,function ()
		--		printyellow("PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.YuanBao] = ",PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.YuanBao])
		--		printyellow("cfg.chat.Const.TOP_CHANNEL_PRICE = ",cfg.chat.Const.TOP_CHANNEL_PRICE)
		if PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.YuanBao] < cfg.chat.Const.TOP_CHANNEL_PRICE then
			uimanager.ShowSystemFlyText(LocalString.Exchange_YuanBaoNotEnough)
		else
			chatmanager.SendCChat({channel = cfg.chat.ChannelType.TOP,text = fields.UIInput_Chat.value})
			uimanager.hide("common.dlgdialogbox_common")
			fields.UIInput_Chat.value = ""
		end
	end)
end



local function CanSend()
	if chatmanager.GetCurChannel() == CHANNEL.WORLD then --在世界频道发送，要检查是否处于禁止发送时间
		if jubaomanager.IsBeSilentNotify() > 0 then
			uimanager.ShowSystemFlyText(string.format(LocalString.Chat_EndSilentTime,jubaomanager.IsBeSilentNotify()))
			return false
		end
		printyellow("jubaomanager.GetLevelLowestFayan()",jubaomanager.GetLevelLowestFayan())
		--if  PlayerRole:Instance().m_Level < jubaomanager.GetLevelLowestFayan() then
		--	uimanager.ShowSystemFlyText(string.format(LocalString.Chat_LessLevel,jubaomanager.GetLevelLowestFayan()))
		--	return false
		--end 
		if jubaomanager.GetRestTime()~= 0 then
			uimanager.ShowSystemFlyText(string.format(LocalString.Chat_RestTimeNotZero,jubaomanager.GetRestTime()))
			return false
		end 
	elseif  chatmanager.GetCurChannel() == CHANNEL.PRIVATE then  --如果在“私聊”频道中，没有选定好友或者没有好友则不能发送消息
			local ret = string.find(fields.UIInput_Chat.value,"\\switchtes")
			if ret == 1 then
				Util.SwitchTest()
			end
			if  not chatmanager.GetCurPrivateChatName()  or chatmanager.GetCurPrivateChatName() == "" then
				uimanager.ShowSystemFlyText(LocalString.Chat_NotFriend)
				return false
			end
			if chatmanager.GetOnlineStatusByName(chatmanager.GetCurPrivateChatName()) == 0 then
				uimanager.ShowSystemFlyText(LocalString.Chat_NotOnline)
				return false
			end
	
	elseif  chatmanager.GetCurChannel() == CHANNEL.TEAM and not TeamManager.IsInTeam()then  --如果在“队伍”频道中，玩家不是组队状态，则不能发送消息
				uimanager.ShowSystemFlyText(LocalString.Chat_NotInTeam)
				return false
	elseif  chatmanager.GetCurChannel() == CHANNEL.FAMILY and not FamilyManager.InFamily() then   --如果在“家族”频道中，玩家不在任何家族，则不能发送消息
				uimanager.ShowSystemFlyText(LocalString.Chat_NotInFamily)
				return false
	elseif  chatmanager.GetCurChannel() == CHANNEL.TOP then
				uimanager.show("common.dlgdialogbox_common",{callBackFunc = ShowTopMessage})
				return false
	else
	end
	
	return true

end

local function GetNessessoryBagInfo(Type,selectedItem)
	local iteminfo = {}
	if Type == cfg.bag.BagType.ITEM or Type == cfg.bag.BagType.FRAGMENT then  --物品和碎片 
		iteminfo.Type = BAG_TYPE.ITEM 
		iteminfo.configId = selectedItem:GetConfigId()
	elseif Type == cfg.bag.BagType.EQUIP or Type == cfg.bag.BagType.EQUIP_BODY then --装备和身上 
		if selectedItem:IsMainEquip() then  --是主要装备
			iteminfo.Type = BAG_TYPE.EQUIP 
			iteminfo.configId = selectedItem:GetConfigId()
			iteminfo.isBound = selectedItem:IsBound()
			iteminfo.annealLevel = selectedItem:GetAnnealLevel()
			iteminfo.perfuseLevel = selectedItem:GetPerfuseLevel()
		else                                --是饰品
			iteminfo.Type = BAG_TYPE.ACCESSORY
			iteminfo.configId = selectedItem:GetConfigId()
			iteminfo.accMainAttributes = selectedItem:GetAccMainAttributes()
			iteminfo.accExtraAttributes = selectedItem:GetAccExtraAttributes()	
		end 

	elseif Type == cfg.bag.BagType.TALISMAN then  --法宝
		   iteminfo.Type = BAG_TYPE.TALISMAN
			iteminfo.configId = selectedItem:GetConfigId()
		
	end 
	return iteminfo
end

local function GetNearestSpeakerToMe()
	local PrivateMessage = chatmanager.GetPrivateMessage()
	local name 
	local i = #PrivateMessage
	while i >= 1 do
		if PrivateMessage[i].sendername ~= PlayerRole:Instance().m_Name then
			break
		else  
			i = i - 1
		end 
	end 
	return name 
end

local function ShowLockPanel(index)
	if true then return end
	if index == 0 then
--		printyellow("HasObtainedFace ",chatmanager.HasObtainedFace("BY"))
		if chatmanager.HasObtainedFace("ZXF") then
			fields.UIPanel_Lock.gameObject:SetActive(false)
		else
			fields.UIPanel_Lock.gameObject:SetActive(true)
		end
	elseif index == 1 then
		if chatmanager.HasObtainedFace("BY") then
			fields.UIPanel_Lock.gameObject:SetActive(false)
		else
			fields.UIPanel_Lock.gameObject:SetActive(true)
		end
	elseif index == 2 then
		if chatmanager.HasObtainedFace("LXQ") then
			fields.UIPanel_Lock.gameObject:SetActive(false)
		else
			fields.UIPanel_Lock.gameObject:SetActive(true)
		end
	elseif index == 3 then
		fields.UIPanel_Lock.gameObject:SetActive(false)
	end 
end

local function ShowBuyFace(dlgfields,name,params)
	dlgfields.UIGroup_Content_Three.gameObject:SetActive(false)
	dlgfields.UIGroup_TextWarp.gameObject:SetActive(false)
	dlgfields.UIGroup_Compare.gameObject:SetActive(false)
	dlgfields.UIGroup_TextWarp2.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_1.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(true)
	dlgfields.UIGroup_Resource.gameObject:SetActive(false)
	dlgfields.UIGroup_Revive.gameObject:SetActive(false)
	dlgfields.UIGroup_Reminder_Full.gameObject:SetActive(true)
	dlgfields.UIGroup_ItemUse.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single2.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single3.gameObject:SetActive(false)
	dlgfields.UILabel_Title.text           = LocalString.Chat_Face_Purchase --"购买表情"
	local str1
--	if  shouldHideVip() then 
--		str1 = ""  
--		dlgfields.UIGroup_Button_2.gameObject:SetActive(false) 
--    else 
		str1 = string.format(LocalString.Chat_Face_YuanBao,cfg.chat.Const.FACE_PRICE) 
--	end
	dlgfields.UILabel_Content_Single1.text = str1
	dlgfields.UILabel_Return.text          =  LocalString.ImmediateRecharge
	dlgfields.UILabel_Sure.text            =  LocalString.Exchange_Buy

	EventHelper.SetClick(dlgfields.UIButton_Return,function ()
		uimanager.hide("common.dlgdialogbox_common")
		fields.UIList_Button_Emoji:SetUnSelectedIndex(0) 
		fields.UIGroup_Emoji.gameObject:SetActive(false)
		local VipChargeManager = require"ui.vipcharge.vipchargemanager"
		VipChargeManager.ShowVipChargeDialog()
	end)

	EventHelper.SetClick(dlgfields.UIButton_Sure,function ()
		uimanager.hide("common.dlgdialogbox_common")
		if  PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.YuanBao] < cfg.chat.Const.FACE_PRICE then
			uimanager.ShowSystemFlyText(LocalString.Chat_Face_YuanBaoLessThan)
		else
--			printyellow("curFaceName",curFaceName)
			chatmanager.SendCBuyChatFace(curFaceName)
			fields.UIList_Button_Emoji:SetUnSelectedIndex(0)
			fields.UIGroup_Emoji.gameObject:SetActive(false)
		end 
	end)
end




local function init(params)
    name, gameObject, fields = unpack(params)
    local CountVoice = 0

--	printyellow("NetworkReachability.ReachableViaLocalAreaNetwork",NetworkReachability.ReachableViaLocalAreaNetwork)

	chatmanager.RefreshFriendData()

    UIList_ChatArea = fields.UIList_ChatArea
	UIList_Friend   = fields.UIList_Friend

--	local item01 = UIList_ChatArea.transform:Find("MessageFadeItem/UIGroup_0CIContent")
--	local item02 = UIList_ChatArea.transform:Find("MessageFadeItem/UIGroup_1Right")
--	local item03 = UIList_ChatArea.transform:Find("MessageFadeItem/UIGroup_2Left")

	local item01 = UIList_ChatArea.transform:Find("MessageFadeItem/UIGroup_0CIContent")
	local item02 = UIList_ChatArea.transform:Find("MessageFadeItem/UIGroup_1Right")
	local item03 = UIList_ChatArea.transform:Find("MessageFadeItem/UIGroup_2Left")
	UIListItems[1] = fields.UIGroup_0CIContent.gameObject
	UIListItems[2] = fields.UIGroup_1Right.gameObject
	UIListItems[3] = fields.UIGroup_2Left.gameObject

    local EmojiBackground = fields.UIGroup_Emoji
	local SettingBackground = fields.UIGroup_Settings

	UIScrollView_ChatArea = fields.UIScrollView_ChatArea
	UIScrollView_ChatArea.onStoppedMoving = function () 
		local delayTimer = FrameTimer.New(function()                
			local panel = UIScrollView_ChatArea.gameObject:GetComponent(UIPanel)
			local panelHeight = panel:GetViewSize().y
			local panelOffset = panel:GetClipOffsetY()
			local maxHeight = UIList_ChatArea.gameObject:GetComponent(UITable):GetTotalHeight()
			
			isBrowsing  = maxHeight - panelHeight > math.abs(panelOffset) --printyellow("isBrowsing",isBrowsing)
			--TODO聊天触底临时解决方案，需要后面做优化
		local tempoffsety = maxHeight - panelHeight
	--[[		if tempoffsety < 0  then
				if  panel:GetComponent(SpringPanel) == nil then
					panel.gameObject:AddComponent(SpringPanel)
					panel:GetComponent(SpringPanel).enabled = false
					panel:GetComponent(SpringPanel).target = Vector3(-237,250,10)
					panel:GetComponent(SpringPanel).enabled = true
				else
					panel:GetComponent(SpringPanel).enabled = false
					panel:GetComponent(SpringPanel).target = Vector3(-237,250,10)
					panel:GetComponent(SpringPanel).enabled = true
				end
			end--]]
		end, 2, 0)
		delayTimer:Start()

	end
	UIScrollView_ChatArea.onDragFinished = function()
		local panel = UIScrollView_ChatArea.gameObject:GetComponent(UIPanel)
		local panelHeight = panel:GetViewSize().y
		local panelOffset = panel:GetClipOffsetY()
		local maxHeight = UIList_ChatArea.gameObject:GetComponent(UITable):GetTotalHeight()
		
	end
	
	fields.UIGroup_Friend.gameObject:SetActive(false)
	fields.UIPanel_ShowChat.gameObject:SetActive(false)
	fields.UIGroup_Emoji.gameObject:SetActive(false)
	SettingBackground.gameObject:SetActive(false)
	fields.UILabel_SpeakTO.gameObject:SetActive(false)
    fields.UIButton_MixingDevice.gameObject:SetActive(false)
	fields.UIButton_BatchSell.gameObject:SetActive(false)
	fields.UIButton_ClearUp.gameObject:SetActive(false)
    fields.UIButton_Arrows.gameObject:SetActive(false)
    fields.UISprite_Press.gameObject:SetActive(false) 
    fields.UISprite_Loosen.gameObject:SetActive(false)
    fields.UISprite_Key.gameObject:SetActive(false)
    fields.UISprite_Voice.gameObject:SetActive(true)
    fields.UIButton_VoiceButton.gameObject:SetActive(false)
    fields.UIGroup_Bag.gameObject:SetActive(false)
	SetChatChannelTag(chatmanager.GetCurChannel())
	fields.UILabel_Name.text = ""


	EventHelper.SetListClick(fields.UIList_RadioButton, function(listItem)
		local index = listItem.Index
		if listItem.Index == BAG_SELECT_TABS[cfg.bag.BagType.EQUIP] then
			gSelectedBagType = cfg.bag.BagType.EQUIP
			ResetBagSlotList(gSelectedBagType)
			ShowBagInfo(gSelectedBagType)
		elseif listItem.Index == BAG_SELECT_TABS[cfg.bag.BagType.FRAGMENT] then
			gSelectedBagType = cfg.bag.BagType.FRAGMENT
			ResetBagSlotList(gSelectedBagType)
			ShowBagInfo(gSelectedBagType)
		elseif listItem.Index == BAG_SELECT_TABS[cfg.bag.BagType.ITEM]  then
			gSelectedBagType = cfg.bag.BagType.ITEM
			ResetBagSlotList(gSelectedBagType)
			ShowBagInfo(gSelectedBagType)
		elseif listItem.Index == BAG_SELECT_TABS[cfg.bag.BagType.TALISMAN]  then
			gSelectedBagType = cfg.bag.BagType.TALISMAN
			ResetBagSlotList(gSelectedBagType)
			ShowBagInfo(gSelectedBagType)
		elseif listItem.Index == BAG_SELECT_TABS[cfg.bag.BagType.EQUIP_BODY] then
			gSelectedBagType = cfg.bag.BagType.EQUIP_BODY
			ResetBagSlotList(gSelectedBagType)
			ShowBagInfo(gSelectedBagType)
		end
	end )


    EventHelper.SetListClick(fields.UIList_Emoji, function(list_item) -- 表情包

--        local EmojiName = EmojiTable[list_item.Index + 1]
--		fields.UIInput_Chat.value = fields.UIInput_Chat.value .. "["..EmojiName.."]"

			local EmojiName = EmojiTable[list_item.Index + 1]
			local item = {}
			item.channel = chatmanager.GetCurChannel()
			item.text = "emoji_"..EmojiName
			item.receiver = chatmanager.GetCurPrivateChatPlayerId()
			if CanSend() then
				chatmanager.SendCChat(item) 
				if chatmanager.GetCurChannel() == CHANNEL.WORLD then
					jubaomanager.SetRestTime(PlayerRole:Instance().m_Level,PlayerRole:Instance().m_VipLevel)
				end 
			end 	

    end)

    EventHelper.SetListClick(fields.UIList_EmojiBig, function(list_item) -- 表情包

        local EmojiName = EmojiTable[list_item.Index + 1]

			local item = {}
			item.channel = chatmanager.GetCurChannel()
			item.text = EmojiName
			item.receiver = chatmanager.GetCurPrivateChatPlayerId()
			if CanSend() then
				chatmanager.SendCChat(item) 
				if chatmanager.GetCurChannel() == CHANNEL.WORLD then
					jubaomanager.SetRestTime(PlayerRole:Instance().m_Level,PlayerRole:Instance().m_VipLevel)
				end 
			end 

    end)

--	EventHelper.SetClick(fields.UIButton_Photo, OnUIButton_PhotoClicked)

	EventHelper.SetClick(fields.UIButton_Arrows, function ()

		if IsShowFriend() == true then
			fields.UIGroup_Friend.gameObject:SetActive(false)
		else
		    if SettingBackground.gameObject.activeSelf == true then
				SettingBackground.gameObject:SetActive(false)
		    end
				fields.UIGroup_Friend.gameObject:SetActive(true)
		end

    end)

	EventHelper.SetClick(fields.UIButton_ShowChat, function()
		isBrowsing = false
		fields.UIPanel_ShowChat.gameObject:SetActive(false)
		RePositionWhenNeeded()
	end)


    EventHelper.SetListClick(fields.UIList_Channel, function(list_item)
--		printyellow("SetListSelect")
		if list_item.Index == 0 then
             if IsShowFriend() == true then
                 fields.UIGroup_Friend.gameObject:SetActive(false)
             end
				ShowIconByNeed(false,false,false,true,false,false)

             if chatmanager.GetCurChannel() ~= CHANNEL.TOP then
				 SetActiveOtherBG(false)
				 fields.UIPanel_ShowChat.gameObject:SetActive(false)
				 chatmanager.SetCurChannel(CHANNEL.TOP)
				 SetChatChannelTag(CHANNEL.TOP)
				 RefreshChatTitle()
				 chatmanager.UpdateChatMessage(CHANNEL.TOP,fields)
				 if CountVoice == 1 then
					 fields.UIButton_VoiceButton.gameObject:SetActive(false)
					 fields.UIInput_Chat.gameObject:SetActive(true)
					 fields.UIButton_Expression.gameObject:SetActive(true)
					 fields.UIButton_Send.gameObject:SetActive(true)
					 fields.UISprite_Press.gameObject:SetActive(false)
					 fields.UISprite_Key.gameObject:SetActive(false)
					 fields.UISprite_Voice.gameObject:SetActive(true)
					 fields.UILabel_Channel01.gameObject:SetActive(true)
					 --			if chatmanager.GetCurChannel() == CHANNEL.PRIVATE then
					 --				fields.UILabel_SpeakTO.gameObject:SetActive(true)
					 --			end
					 CountVoice = ( CountVoice + 1 ) % 2
				 end

             end

        elseif list_item.Index == 1 then
--			SetActiveVoiceFace(false)


             if IsShowFriend() == true then
                 fields.UIGroup_Friend.gameObject:SetActive(false)
             end
				ShowIconByNeed(true,true,false,true,true,true)

             if chatmanager.GetCurChannel() ~= CHANNEL.WORLD then
				 SetActiveOtherBG(false)
				 fields.UIPanel_ShowChat.gameObject:SetActive(false)
				 chatmanager.SetCurChannel(CHANNEL.WORLD)
				 SetChatChannelTag(CHANNEL.WORLD)
				 RefreshChatTitle()
				 chatmanager.UpdateChatMessage(CHANNEL.WORLD,fields)

             end
--             SetUIToggle()
        elseif list_item.Index == 2 then
             if fields.UILabel_Channel01.gameObject.activeSelf  == false then
                fields.UILabel_Channel01.gameObject:SetActive(true)
             end

				ShowIconByNeed(true,true,true,true,true,true)

             if chatmanager.GetCurChannel() ~= CHANNEL.PRIVATE then
                --textList:ChatFunction.Clear(fields)
				SetActiveOtherBG(false)
				fields.UIGroup_Friend.gameObject:SetActive(true)
				fields.UIPanel_ShowChat.gameObject:SetActive(false)		
                chatmanager.SetCurChannel(CHANNEL.PRIVATE)  
				SetChatChannelTag(CHANNEL.PRIVATE)
				RefreshChatTitle()
                chatmanager.UpdateChatMessage(CHANNEL.PRIVATE,fields)
				chatmanager.ClearCountMsg(chatmanager.GetCurPrivateChatName())
--				ResetMsgCountByIndex(0)
				chatmanager.RefreshAllRecentSpeakerData()
				SetFriendListIndex()
				RefreshPrivateChatList()
            end


--            SetUIToggle()
        elseif list_item.Index == 3 then
--				SetActiveVoiceFace(true)


             if IsShowFriend() == true then
                 fields.UIGroup_Friend.gameObject:SetActive(false)
             end

				ShowIconByNeed(true,true,false,true,true,true)

            if chatmanager.GetCurChannel() ~= CHANNEL.FAMILY then
				SetActiveOtherBG(false)
				fields.UIPanel_ShowChat.gameObject:SetActive(false)
                chatmanager.SetCurChannel(CHANNEL.FAMILY)  
				SetChatChannelTag(CHANNEL.FAMILY)
				RefreshChatTitle()
                chatmanager.UpdateChatMessage(CHANNEL.FAMILY,fields)
            end


        elseif list_item.Index == 4 then
--			SetActiveVoiceFace(true)

              if IsShowFriend() == true then
                 fields.UIGroup_Friend.gameObject:SetActive(false)
             end
				ShowIconByNeed(true,true,false,true,true,true)

            if chatmanager.GetCurChannel() ~= CHANNEL.TEAM then
				SetActiveOtherBG(false)
				fields.UIPanel_ShowChat.gameObject:SetActive(false)
                chatmanager.SetCurChannel(CHANNEL.TEAM)  
				SetChatChannelTag(CHANNEL.TEAM)
				RefreshChatTitle()
                chatmanager.UpdateChatMessage(CHANNEL.TEAM,fields)
            end



        elseif list_item.Index == 5 then
--			SetActiveVoiceFace(false)
             fields.UILabel_Channel01.text = "[FF8F79]#系统"

            if IsShowFriend() == true then
                fields.UIGroup_Friend.gameObject:SetActive(false)
            end

			ShowIconByNeed(true,false,false,false,false,false)

            if chatmanager.GetCurChannel() ~= CHANNEL.SYSTEM then
                --textList:ChatFunction.Clear(fields)
				SetActiveOtherBG(false)
				fields.UIPanel_ShowChat.gameObject:SetActive(false)
                chatmanager.SetCurChannel(CHANNEL.SYSTEM) 
				SetChatChannelTag(CHANNEL.SYSTEM)
				RefreshChatTitle()
                chatmanager.UpdateChatMessage(CHANNEL.SYSTEM,fields)
            end
        else


            if IsShowFriend() == true then
                fields.UIGroup_Friend.gameObject:SetActive(false)
            end


			ShowIconByNeed(false,false,false,false,false,false)

            if chatmanager.GetCurChannel() ~= CHANNEL.INVITE then
                --textList:ChatFunction.Clear(fields)
				SetActiveOtherBG(false)
                chatmanager.SetCurChannel(CHANNEL.INVITE)  
				SetChatChannelTag(CHANNEL.INVITE)
				RefreshChatTitle()
                chatmanager.UpdateChatMessage(CHANNEL.INVITE,fields)

            end
		end 
    end)


	EventHelper.SetClick(fields.UIButton_Send, function ()   --按“发送”按钮


        local item = {}  
		if chatmanager.GetCurChannel() == CHANNEL.TOP then
			if fields.UIInput_Chat.value ~= "" then
				printyellow("deguowansui")
				uimanager.show("common.dlgdialogbox_common",{callBackFunc = ShowTopMessage})
			end		
			return 
		end

		if not CanSend() then
			return 
		end 
		if fields.UIGroup_Emoji.gameObject.activeSelf == true then	
			fields.UIList_Button_Emoji:SetUnSelectedIndex(0) 
			fields.UIGroup_Emoji.gameObject:SetActive(false)
		end 

        if fields.UIInput_Chat.value ~= "" then
            local cmdI, cmdJ, cmdLabel = Command.GetCommandTitle()
            if string.sub(fields.UIInput_Chat.value,cmdI,cmdJ) == cmdLabel then
                local re = Command.Command(fields.UIInput_Chat.value,chatmanager.GetCurChannel())
                fields.UIInput_Chat.value = ""
                return
            end
			item.channel  = chatmanager.GetCurChannel()
			local str1 = string.gsub(fields.UIInput_Chat.value,"\n","")
			str1 = string.gsub(str1,"%[%a%]","")
			str1 = string.gsub(str1,"%[%a%a%]","")
			str1 = string.gsub(str1,"%[%x%x%x%x%x%x%]","")
			item.text = str1
            if chatmanager.GetCurChannel() == CHANNEL.PRIVATE then                                         --私聊的时侯需要指出receiver
                item.receiver  = chatmanager.GetCurPrivateChatPlayerId()
            end
            chatmanager.SendCChat(item)
			if chatmanager.GetCurChannel() == CHANNEL.WORLD then
				jubaomanager.SetRestTime(PlayerRole:Instance().m_Level,PlayerRole:Instance().m_VipLevel)
			end 
        else
--			UIList_ChatArea:DelListItem(UIList_ChatArea:GetItemByIndex(7))  
	
		end

        fields.UIInput_Chat.value = ""

    end)



    EventHelper.SetClick(fields.UISprite_Settings, function ()

--		printyellow("fields.UISprite_Settings")
--		printt(CurSettingTable)
		if SettingBackground.gameObject.activeSelf == true then

			SettingManager.SetSettingTableByChannel(chatmanager.GetCurChannel(),GetCurTable()) 

		    SettingBackground.gameObject:SetActive(false)
			
		else
		     if IsShowFriend() then
				fields.UIGroup_Friend.gameObject:SetActive(false)
			 end

			if fields.UIGroup_Emoji.gameObject.activeSelf == true then
				fields.UIGroup_Emoji.gameObject:SetActive(false)
			end
		
		    SettingBackground.gameObject:SetActive(true)
			SetUIToggle()
		end
    end)

    EventHelper.SetClick(fields.UIButton_BagIcon, function ()

        if fields.UIGroup_Bag.gameObject.activeInHierarchy == false then
			if EmojiBackground.gameObject.activeInHierarchy == true then
					fields.UIList_Button_Emoji:SetUnSelectedIndex(0)
					fields.UIGroup_Emoji.gameObject:SetActive(false)
			end

            fields.UIGroup_Bag.gameObject:SetActive(true)
			gSelectedBagType = cfg.bag.BagType.EQUIP
			fields.UIList_RadioButton:SetSelectedIndex(BAG_SELECT_TABS[gSelectedBagType])
			InitBagSlotList(gSelectedBagType)
			ResetBagSlotList(gSelectedBagType)
			ShowBagInfo(gSelectedBagType)
        else
            fields.UIGroup_Bag.gameObject:SetActive(false)
        end

    end)

    EventHelper.SetClick(fields.UIButton_Expression, function ()
--		printyellow("fields.UIButton_Expression")
        if EmojiBackground.gameObject.activeSelf == false then
			EmojiBackground.gameObject:SetActive(true)

			if SettingBackground.gameObject.activeSelf == true then
				SettingBackground.gameObject:SetActive(false)
			end

			if fields.UIGroup_Bag.gameObject.activeInHierarchy == true then
				fields.UIGroup_Bag.gameObject:SetActive(false)
			end
			fields.UIGroup_Emoji.gameObject:SetActive(true)
			fields.UIScrollView_Emoji.gameObject:SetActive(true)
			fields.UIScrollView_EmojiBig.gameObject:SetActive(false)
			
			local currentIndex = fields.UIList_Button_Emoji:GetSelectedIndex()
			fields.UIList_Button_Emoji:SetUnSelectedIndex(currentIndex)
			fields.UIList_Button_Emoji:SetSelectedIndex(0, true)


			EmojiTable = ChatEmoji.InitEmojiSprite(fields,3)
			ShowLockPanel(0)
			curFaceName = "ZXF"
--			printyellow("aaaaaaaaaaaa")
        else
			--fields.UIList_Button_Emoji:SetUnSelectedIndex(0) 
			--fields.UIGroup_Emoji.gameObject:SetActive(false)
			EmojiBackground.gameObject:SetActive(false)
        end

    end)

    EventHelper.SetClick(fields.UIButton_Voice, function ()
        if CountVoice == 0 then
            fields.UIButton_VoiceButton.gameObject:SetActive(true)
            fields.UIInput_Chat.gameObject:SetActive(false)
            fields.UIButton_Expression.gameObject:SetActive(false)
            fields.UIButton_Send.gameObject:SetActive(false)
            fields.UISprite_Press.gameObject:SetActive(true)
            fields.UISprite_Key.gameObject:SetActive(true)
            fields.UISprite_Voice.gameObject:SetActive(false)
            fields.UILabel_Channel01.gameObject:SetActive(false)
--            fields.UILabel_SpeakTO.gameObject:SetActive(false)
        else
            fields.UIButton_VoiceButton.gameObject:SetActive(false)
            fields.UIInput_Chat.gameObject:SetActive(true)
            fields.UIButton_Expression.gameObject:SetActive(true)
            fields.UIButton_Send.gameObject:SetActive(true)
            fields.UISprite_Press.gameObject:SetActive(false)
            fields.UISprite_Key.gameObject:SetActive(false)
            fields.UISprite_Voice.gameObject:SetActive(true)
            fields.UILabel_Channel01.gameObject:SetActive(true)
--			if chatmanager.GetCurChannel() == CHANNEL.PRIVATE then
--				fields.UILabel_SpeakTO.gameObject:SetActive(true)	
--			end 
        end
        CountVoice = ( CountVoice + 1 ) % 2
    end)
--	printyellow("setclick7")

    EventHelper.SetPress(fields.UIButton_VoiceButton, function(go, bPress) --发送语音小纸条
        --printyellow("SetPress")
--		if chatmanager.GetCurChannel() == CHANNEL.WORLD then
--			uimanager.ShowSystemFlyText(LocalString.Chat_CannotSendVoiceOnWorldChannel)
--			return
--		end

		if not CanSend() then
			return 
		end

        if bPress == true then
			
			if chatmanager.isUpdateRecord == true then
				return
			end
			
            isPress = true
			uimanager.show("chat.dlgdialogbox_speak")
            fields.UISprite_Press.gameObject:SetActive(false)
            fields.UISprite_Loosen.gameObject:SetActive(true)
            chatmanager.StartRecordVoice()                     --开始录音
        else
			uimanager.hide("chat.dlgdialogbox_speak")
            fields.UISprite_Press.gameObject:SetActive(true)
            fields.UISprite_Loosen.gameObject:SetActive(false)

            chatmanager.StopRecord()                           --结束录音

        end
    end)

    EventHelper.SetDrag(fields.UIButton_VoiceButton, function(o,delta) --发送语音小纸条
--        printyellow("SetDrag")
        if delta.y > 0 then
            fields.UISprite_Press.gameObject:SetActive(true)
            fields.UISprite_Loosen.gameObject:SetActive(false)
        end

    end)


	EventHelper.SetListClick(fields.UIList_Bag, function(listItem)
		local item = {}

		if gSelectedBagType == cfg.bag.BagType.ITEM then            --物品
			local selectedItem = BagManager.GetItemBySlot(gSelectedBagType, listItem.Index + 1)
			--selectedItem.BagPos
--			printyellow("selectedItem:GetBagPos()",selectedItem:GetBagPos())
			if selectedItem ~= nil then

					item.channel = chatmanager.GetCurChannel()
					item.text = "BagMsg_" .."【" ..selectedItem:GetName().."】"
					item.receiver = chatmanager.GetCurPrivateChatPlayerId()

					item.bagtype = cfg.bag.BagType.ITEM
					item.pos = selectedItem:GetBagPos()
					item.isinbag = gSelectedBagType+1

					if CanSend() then chatmanager.SendCChat(item) if chatmanager.GetCurChannel() == CHANNEL.WORLD then  				jubaomanager.SetRestTime(PlayerRole:Instance().m_Level,PlayerRole:Instance().m_VipLevel) end  end 
			end
		elseif gSelectedBagType == cfg.bag.BagType.FRAGMENT then   --碎片 

			local selectedItem = BagManager.GetItemBySlot(gSelectedBagType, listItem.Index + 1)
			if selectedItem ~= nil then

					item.channel = chatmanager.GetCurChannel()
					item.text = "BagMsg_".."【" ..selectedItem:GetName().."】"
					item.receiver = chatmanager.GetCurPrivateChatPlayerId()
					item.bagtype = cfg.bag.BagType.FRAGMENT
					item.pos = selectedItem:GetBagPos()
					item.isinbag = gSelectedBagType+1
					if CanSend() then chatmanager.SendCChat(item) if chatmanager.GetCurChannel() == CHANNEL.WORLD then  				jubaomanager.SetRestTime(PlayerRole:Instance().m_Level,PlayerRole:Instance().m_VipLevel) end end 
			end
		elseif gSelectedBagType == cfg.bag.BagType.EQUIP or gSelectedBagType == cfg.bag.BagType.EQUIP_BODY then  --身上和装备
			print("点击装备"..gSelectedBagType)
			local selectedItem = BagManager.GetItemBySlot(gSelectedBagType, listItem.Index + 1)
			if selectedItem ~= nil then
	
					item.channel = chatmanager.GetCurChannel()
					item.text = "BagMsg_".."【" ..selectedItem:GetName().."】"
					if selectedItem:IsMainEquip() then
						 if selectedItem:GetAnnealLevel()~= 0 or selectedItem:GetPerfuseLevel() ~= 0 then 
							item.text = item.text .."+"..selectedItem:GetAnnealLevel() .." +"..selectedItem:GetPerfuseLevel()
						end 
					end
					item.receiver = chatmanager.GetCurPrivateChatPlayerId()
					item.bagtype = gSelectedBagType
					item.pos = selectedItem:GetBagPos()
					item.isinbag = gSelectedBagType+1
					if CanSend() then chatmanager.SendCChat(item) if chatmanager.GetCurChannel() == CHANNEL.WORLD then  				jubaomanager.SetRestTime(PlayerRole:Instance().m_Level,PlayerRole:Instance().m_VipLevel) end end 

			end

		elseif gSelectedBagType == cfg.bag.BagType.TALISMAN then   --法宝
			local selectedItem = BagManager.GetItemBySlot(gSelectedBagType, listItem.Index + 1)
			if selectedItem ~= nil then

					item.channel = chatmanager.GetCurChannel()
--					item.text = "[item]"..GetNessessoryBagInfo(cfg.bag.BagType.TALISMAN,selectedItem)..ChatFormat.GetColorCode(selectedItem:GetQuality()) .."【" ..selectedItem:GetName().."】[-]"
					item.text = "BagMsg_" .."【" ..selectedItem:GetName().."】"
					item.receiver = chatmanager.GetCurPrivateChatPlayerId()
					item.bagtype = cfg.bag.BagType.TALISMAN
					item.pos = selectedItem:GetBagPos()
					item.isinbag = gSelectedBagType+1
					if CanSend() then chatmanager.SendCChat(item) if chatmanager.GetCurChannel() == CHANNEL.WORLD then jubaomanager.SetRestTime(PlayerRole:Instance().m_Level,PlayerRole:Instance().m_VipLevel) end end 
			end
		else
			logError("Selected bag type error")
		end
	end )

--	EventHelper.SetClick(fields.UIToggle_CheckBoxPray01,function()
--		fields.UIToggle_CheckBoxPray01.value = true
--	end)

	EventHelper.SetClick(fields.UIToggle_CheckBoxPray02,function()
		fields.UIToggle_CheckBoxPray02.value = true
	end)

	EventHelper.SetClick(fields.UIToggle_CheckBoxPray03,function()
		fields.UIToggle_CheckBoxPray03.value = true
	end)

	EventHelper.SetClick(fields.UIToggle_CheckBoxPray04,function()
		fields.UIToggle_CheckBoxPray04.value = true
	end)

	EventHelper.SetClick(fields.UIToggle_CheckBoxPray05,function()
		fields.UIToggle_CheckBoxPray05.value = true
	end)

	EventHelper.SetClick(fields.UIToggle_CheckBoxPray06,function()
		fields.UIToggle_CheckBoxPray06.value = false
	end)

	fields.UIList_Button_Emoji:SetUnSelectedIndex(0)
	EventHelper.SetListSelect(fields.UIList_Button_Emoji,function(list_item)

		--if list_item.Index == 0 then
		--	fields.UIScrollView_EmojiBig.gameObject:SetActive(true)
		--	fields.UIScrollView_Emoji.gameObject:SetActive(false)
		--	curFaceName = "ZXF"
		--	ShowLockPanel(0)
		--	EmojiTable = ChatEmoji.InitEmojiSprite(fields,0)
		--elseif list_item.Index == 1 then
		--	fields.UIScrollView_EmojiBig.gameObject:SetActive(true)
		--	fields.UIScrollView_Emoji.gameObject:SetActive(false)
		--	curFaceName = "BY"
		--	ShowLockPanel(1)
		--	EmojiTable = ChatEmoji.InitEmojiSprite(fields,1)
		--elseif list_item.Index == 2 then
		--	fields.UIScrollView_EmojiBig.gameObject:SetActive(true)
		--	fields.UIScrollView_Emoji.gameObject:SetActive(false)
		--	curFaceName = "LXQ"
		--	ShowLockPanel(2)
		--	EmojiTable = ChatEmoji.InitEmojiSprite(fields,2)
		--elseif list_item.Index == 3 then
        --
		--	fields.UIScrollView_EmojiBig.gameObject:SetActive(false)
		--	fields.UIScrollView_Emoji.gameObject:SetActive(true)
		--	curFaceName = nil
		--	ShowLockPanel(3)
		--	EmojiTable = ChatEmoji.InitEmojiSprite(fields,3)
		--end

		fields.UIScrollView_EmojiBig.gameObject:SetActive(false)
		fields.UIScrollView_Emoji.gameObject:SetActive(true)
		curFaceName = nil
		ShowLockPanel(3)
		EmojiTable = ChatEmoji.InitEmojiSprite(fields,3)

	end)

	EventHelper.SetClick(fields.UISprite_EmojiBlock,function()
		uimanager.show("common.dlgdialogbox_common",{curFaceName = curFaceName ,callBackFunc = ShowBuyFace})
	end)

	fields.UIList_FriendList:SetUnSelectedIndex(0)
	EventHelper.SetListSelect(fields.UIList_FriendList,function (listitem)
		if listitem.Index == 0 then
			chatmanager.SetIsFriendList(false)
		else
			chatmanager.SetIsFriendList(true)
		end
		chatmanager.RefreshAllRecentSpeakerData()
		RefreshPrivateChatList()
	end)

	gameevent.evt_system_message:add("logout",function()
		uimanager.destroy("chat.dlgchat01")
	end)

end

local function uishowtype()
    return UIShowType.DestroyWhenHide
end

return {
--	uishowtype = uishowtype,
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
	SetFriendName = SetFriendName,
	AddMessage = AddMessage,
	RefreshChatTitle = RefreshChatTitle,
	RefreshPrivateChatList = RefreshPrivateChatList,

}
