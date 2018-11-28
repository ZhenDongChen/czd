local gameevent = require "gameevent"
local network = require "network"
local uimanager = require("uimanager")
local ItemManager = require("item.itemmanager")
local ConfigManager = require("cfg.configmanager")
local SettingManager = require("character.settingmanager")
local FriendManager = require("ui.friend.friendmanager")
local PlayerRole = require ("character.playerrole")
--MultiEctypeManager = require("ui.ectype.multiectype.multiectypemanager")
EctypeManager = require("ectype.ectypemanager")
AudioManager = require("audiomanager")
SceneManager = require("scenemanager")
--charactermanager = require("character.charactermanager")

local octets        = require("common.octets")

--[[自动播放start]]--
local autoPlayVoiceData = {}      --语音信息（自动播放时使用）
local voiceListItemInfo = {}

--local isAutoPlay = true           --是否自动播放
local VoiceMsgQueue = Queue:new()
local cur_Voice_Message
local isAutoPlay = true
local isPlayNext = true   -- original false
--[[置顶频道]]--
local last_TM_Time
local cur_TM_Message
local is_TM_ShowWarning
local isTopMessageWarningDuration
local priorityMap
--[[自动播放end]]--

local FaceBuy = {}
local CurChannel          --当前频道
local CurChannelMainScreen
local isVoiceFromMainScreen
local MAX_LINE = 50
local totalUnRead = 0
local isTipShow = false
--local hugescroll
local curPrivateChatName  --私聊频道当前的speaker
local curPrivateChatPlayerId

local WorldMessage   = {}
local PrivateMessage = {}
local FamilyMessage  = {}
local TeamMessage    = {}
local SystemMessage  = {}
local InviteMessage  = {}
local TopMessage     = {}

local WorldTable   = {}
local PrivateTable = {}
local FamilyTable  = {}
local TeamTable    = {}
local SystemTable  = {}

local recentSpeakerList  = {}
local friendList ={}

--local imageid
--local image   -- 大图

--[[语音相关]]--
local redDotInfo	  		= {}         --未读语音条的红点信息
local voiceInfo       		= {}		   --[voiceid , strFileStr]
local voiceServerInfo       = {}		   --[voiceid , ServerstrFileStr]

local strRecFileName  = nil

local isStartRecord = false
local isRecord = false
local isUpdateRecord = false;

local isPlaying = false

local isStopBgMusicWhenRecord = false

local playVoiceId = 0
local isStartPlay = false
local playTime = 0
local playVoiceLength = 0
local stopBgMusicTimeWhenRecord = 0

local oldPlayingVoiceId = 0
local curPlayingVoiceId = 0
local curPlayingVoiceId1 = 0
local curVoiceDataDir = nil


local curVolumIconIndex = 0
local startMousePoint
local endMousePoint

local recordTime = 0;
-- 录音50秒时倒计时
local alarmRecTime = 50
-- 录音60秒时结束
local maxRecTime = 60

local RecordVoiceProc
local StopRecord
local PlayVoiceProc
local StopPlayVoice

local count_voice_effect
local count_tag

local music = 0
local musiceffect = 0

local isFriendList
local isRefreshPrivateListFunc

local function SetVoiceFromMainScreen(b)
	isVoiceFromMainScreen = b
end

local function SetMainScreenCurChannel(channel)
	CurChannelMainScreen = channel
end

local function GetOnlineStatusByName(name)
	for _,item in ipairs(recentSpeakerList) do
		if name == item.name then
			return item.isOnline
		end
	end

	for _,item in ipairs(friendList) do
		if name == item.name then
			return item.isOnline
		end
	end
	return 1
end

local function AddVoiceListItemInfo(voiceid,listitem)
	voiceListItemInfo[voiceid] = listitem
end

local function GetCurPlayingVoiceId()
	return curPlayingVoiceId
end

local function SetAutoPlayIndex(curIndex)
	autoPlayIndex = curIndex
end

local function SetAutoPlay(b)
	isAutoPlay = b
end

local function IsRefreshPrivateListFunc()
	return isRefreshPrivateListFunc
end

--设置私人聊天的列表函数
local function SetRefreshPrivateListFunc(b)
	isRefreshPrivateListFunc = b
end


local function IsFriend(relation)
	if relation >= 1 and relation <= 10 or relation == 1000 then
		return true
	else
		return false
	end
end



local function IsTipMessageShow()
	return isTipShow
end

local function GetTotalUnRead()
	return totalUnRead
end

local function GetIsFriendList()
	return isFriendList
end

local function SetIsFriendList(b)
	isFriendList = b
end

local function GetCurPrivateChatPlayerId()
	return curPrivateChatPlayerId
end

local function SetCurPrivateChatPlayerId(id)
	curPrivateChatPlayerId = id
end

local function GetCurSpeakerIdByName(name)
	if isFriendList then
		for _,friend in ipairs(friendList) do
			if name == friend.name then
				return friend.id
			end
		end
	else
		for _,speaker in ipairs(recentSpeakerList) do
			if name == speaker.name then
				return speaker.id
			end
		end
	end
	return nil
end

local function GetFriendOnlineStatus(id)
	local friendinfo = FriendManager.GetFriendById(id)
	if friendinfo and friendinfo.m_Online then
		return 1
	else
		return 0
	end
end


local function RefreshAllRecentSpeakerData() -- refresh online status
	if #recentSpeakerList == 0 then
		return
	end
	local roles = {}
	for _,recent in ipairs(recentSpeakerList) do
		table.insert(roles,recent.id)
	end
	local msg = lx.gs.chat.msg.CGetRoleChatShowInfos({roles = roles})
	network.send(msg)
end



local function GetPrivateChatList()
	if isFriendList then
		return friendList
	else
		return recentSpeakerList
	end
end

local function GetFriendList()
	return friendList
end

local function GetRecentSpeakerList()
	return recentSpeakerList
end


local function ResetVoiceAnimationData(a,b)
	count_voice_effect = a
	count_tag = b
end

local function IsStartPlay()
	return isStartPlay
end

local function SetCurListItemVoice(voiceid)
	curPlayingVoiceId = voiceid

end

local function SetCurListItemVoice1(voiceid)
	curPlayingVoiceId1 = voiceid
end

local function CanPlayVoiceAnimation()
	if  not voiceListItemInfo[curPlayingVoiceId] then
		return false
	end
	if  uimanager.isshow("chat.dlgchat01") then
			print("canplayvoiceanimation isShowDlgChat01")
		return true
	else
			print("canplayvoiceanimation not isShowDlgChat01")
		return false
	end
end


local function StartPlaying(curlistitemvoice)
	if not curlistitemvoice then
		return
	end

	curlistitemvoice.Controls["UISprite_Unread"].gameObject:SetActive(false)
	if count_tag == 10 then
		if count_voice_effect == 0 then
			curlistitemvoice.Controls["UISprite_Voice_02"].gameObject:SetActive(false)
			curlistitemvoice.Controls["UISprite_Voice_03"].gameObject:SetActive(false)
		else
			curlistitemvoice.Controls["UISprite_Voice_0".. (count_voice_effect + 1)].gameObject:SetActive(true)
		end
		count_voice_effect = count_voice_effect + 1
		if count_voice_effect == 3 then count_voice_effect = 0 end
		count_tag = 0
	else
		count_tag = count_tag + 1
	end
end

local function StopPlaying(curlistitemvoice)
	if not curlistitemvoice then
		return
	end
	curlistitemvoice.Controls["UISprite_Voice_02"].gameObject:SetActive(true)
	curlistitemvoice.Controls["UISprite_Voice_03"].gameObject:SetActive(true)
	count_voice_effect = 0
	count_tag = 10
end



local function IsTextMsg(ChatData)
	return ChatData.text and ChatData.text ~= ""
end

local function IsEmojiMsg(ChatData)
	return string.len(ChatData.text) >= 6 and string.sub(ChatData.text,1,6) == "emoji_"
end

local function IsBigFaceMsg(ChatData)
	return string.len(ChatData.text) >= 5 and string.sub(ChatData.text,1,5) == "Face_"
end

local function IsBagMsg(ChatData)
--	printyellow("string.sub(ChatData.text,1,7)",string.sub(ChatData.text,1,7))
	return string.len(ChatData.text) >= 7 and string.sub(ChatData.text,1,7) == "BagMsg_"
end

local function IsInviteMsg(ChatData)
	return ChatData.channel == cfg.chat.ChannelType.INVITE
end

local function IsVoiceMsg(ChatData)
	return ChatData.voice and ChatData.voice ~= ""
end



local function CheckFileNameByVoiceId(voiceid)
	if voiceInfo[voiceid] == nil then
		voiceInfo[voiceid] = curVoiceDataDir..os.time()..".dat";
	end
	return voiceInfo[voiceid]
end



local function GetServerInfoByVoiceId(voiceid)
	return voiceServerInfo[voiceid]
end

local function SetServerInfoByVoiceId(voiceid, ServerInfo)
	voiceServerInfo[voiceid] = ServerInfo
end


local function GetCurChannel()
	return CurChannel
end

local function SetCurChannel(channel)
	CurChannel = channel
end

local function SetCurPrivateChatName(friendname)
	curPrivateChatName = friendname
end

local function GetCurPrivateChatName()
	return curPrivateChatName
end

local function GetrecentSpeakerList()
	return recentSpeakerList
end

local function SendCChat(item)
	print("SendCChat")
    local msg = lx.gs.chat.msg.CChat( 
		{ channel = item.channel, 
		  receiver = item.receiver, 
		  text = item.text, 
		  bagtype = item.bagtype, 
		  pos = item.pos,
		  invitechannel = item.invitechannel,
		  voice = item.voice, 
		  voiceduration = item.voiceduration ,
		  isinbag = item.isinbag
		} )
    network.send(msg)
end


local function MuteGameAudio(ismute)
    print("MuteGameAudio:"..tostring(ismute))

    local systemSetting = SettingManager.GetSettingSystem()
    if ismute then
        music = systemSetting["Music"]
        musiceffect = systemSetting["MusicEffect"]
        systemSetting["Music"] = 0
        systemSetting["MusicEffect"]  = 0
		SettingManager.SetSettingSystem(systemSetting)
    else
        systemSetting["Music"] = music
        systemSetting["MusicEffect"]  = musiceffect
        SettingManager.SetSettingSystem(systemSetting)
    end

    SceneManager.MuteAudioInScene(ismute)
    AudioManager.SetMuteBackgroundMusic(ismute)
end

local function StartRecordVoice() -- 开始录音
    print("StartRecordVoice")

    isStartRecord = true
    isStopBgMusicWhenRecord = false
	isUpdateRecord = false
end



RecordVoiceProc = function()
    if isPlaying then
        StopPlayVoice()
        return
    elseif not isStopBgMusicWhenRecord then
        -- 关闭背景音乐
        MuteGameAudio(true)
        isStopBgMusicWhenRecord = true
        stopBgMusicTimeWhenRecord = Time.time
        return
    end

    if Time.time - stopBgMusicTimeWhenRecord > 0.3 then
        if isRecord then
            --[[ 向上滑动取消发送
            if micIconName == uiBehaviour.m_Sprite_UndoSend.spriteName then
                endMousePoint.x = Input.mousePosition.y
                endMousePoint.y = Input.mousePosition.x
                local angle = 0
                if math.abs(endMousePoint.x - startMousePoint.x) >= 60 and
                    math.abs(endMousePoint.y - startMousePoint.y) <= 200 then
                    -- 两次点击位置纵向幅度过小时或者横向幅度过大时忽略
                    angle = CalcAngle()
                end

                if angle >= 45 and angle <= 135 then

                    uiBehaviour.m_Sprite_UndoSend.SetSprite(recordCancelIconName)
                    uiBehaviour.m_Sprite_Volume.SetVisible(false)
                end
            end
            --]]

            local currTime = os.time() - recordTime;
            if currTime >= alarmRecTime and currTime <= maxRecTime then
                -- RecordMic_Label.SetText("倒计时："..(maxRecTime - currTime));
            end

            if currTime >= maxRecTime then
                StopRecord()
            end
        else
            strRecFileName = curVoiceDataDir .. os.time() .. ".dat";
            local ret = Game.Platform.Interface.Instance:Voice_Start(true, strRecFileName,"")
            if ret then
                isRecord = true
            else
                print("start record failed")
                strRecFileName = nil
            end

            recordTime = os.time()
            return
        end
    end
end

StopRecord = function()
    print("stop record")
    isStartRecord = false
    if isRecord then
        isRecord = false
        Game.Platform.Interface.Instance:Voice_Stop()
		isUpdateRecord = true;
    end

    -- 打开背景音乐
    MuteGameAudio(false)
end

local function StartPlayVoice(voiceid)
    print("StartPlayVoice")
    playVoiceId = voiceid
    isStartPlay = true

end

PlayVoiceProc = function ()
    if isPlaying then
    else
        ---[[关闭背景音乐
		MuteGameAudio(true)
        --]]

        print("start play")
        Game.Platform.Interface.Instance:Voice_Start(false, CheckFileNameByVoiceId(playVoiceId),GetServerInfoByVoiceId(playVoiceId))
        playTime = Time.time
        curPlayingVoiceId = playVoiceId
        isPlaying = true
    end

end

StopPlayVoice = function ()
    if isPlaying then
		Game.Platform.Interface.Instance:Voice_Stop()
		isStartPlay = false
		oldPlayingVoiceId = curPlayingVoiceId
		isPlaying = false
		if CanPlayVoiceAnimation() then
			StopPlaying(voiceListItemInfo[curPlayingVoiceId])  --播放动画的
			curPlayingVoiceId = 0
		end
		
		if isAutoPlay then
			print("play end one voice")
			VoiceMsgQueue:Pop()
            isPlayNext = true
		else
			-- 打开背景音乐
			MuteGameAudio(false)
		end
    end
end

local function NetWorkAndSettingStatusValid()
	local SettingChat = SettingManager.GetSettingTableByChannel(GetCurChannel())
	if UnityEngine.Application.internetReachability == 2 then  -- wifi status
		if SettingChat[7].isTick then
			return true
		else
			return false
		end
	else                                                       -- non wifi status
		if SettingChat[8].isTick then
			return true
		else
			return false
		end
	end
end

local function CanAutoPlay(msgvoice)
	if not NetWorkAndSettingStatusValid() then
		return false
	elseif redDotInfo[msgvoice.voiceid] then
		return false
	else
		return true
	end

end

local function update()

	if is_TM_ShowWarning then
		if isTopMessageWarningDuration then
			if timeutils.GetServerTime() - last_TM_Time > 3 then
				if uimanager.hasloaded("dlguimain") then
					uimanager.call("dlguimain","AddMainScreenMessage",{ isTopMessage = true ,str = cur_TM_Message})
				end
				isTopMessageWarningDuration = false
				last_TM_Time = timeutils.GetServerTime()
			end

		else
			if timeutils.GetServerTime() - last_TM_Time > 15 then
				if uimanager.hasloaded("dlguimain") then
					uimanager.call("dlguimain","AddMainScreenMessage",{ isTopMessage = true ,str = LocalString.Chat_TopWarningMessage})
				end
				isTopMessageWarningDuration = true
				last_TM_Time = timeutils.GetServerTime()
			end

		end
	end

    if isStartRecord then
        RecordVoiceProc()
    end

    if isStartPlay then
        PlayVoiceProc()
    end

    if isStartPlay then
		if CanPlayVoiceAnimation() then
			StartPlaying(voiceListItemInfo[curPlayingVoiceId]) --播放动画
		end
    end

	if isAutoPlay and isPlayNext then
		if (VoiceMsgQueue:IsEmpty()) then  --队列为空
		    return
		end
		cur_Voice_Message = VoiceMsgQueue:Last().value
		if CanAutoPlay(cur_Voice_Message) then
			isPlayNext = false
			--SendCGetVoice(cur_Voice_Message.voiceid)
		else
			VoiceMsgQueue:Pop()
		end

	end
end

local function GetFaceBuy()
	return FaceBuy
end

--获取角色的头像信息
local function GetHeadTexture(profession,gender)
	local professionInfo,icon
	if profession then professionInfo = ConfigManager.getConfigData("profession",profession) end
	if gender then modelname  = cfg.role.GenderType.MALE == gender and professionInfo.modelname or professionInfo.modelname2 end
	if modelname then icon  = ConfigManager.getConfigData("model",modelname).headicon end
	return icon
end



local function GetFriendPriority(relation)
	if not relation then
		return 1000
	else
		return priorityMap[relation] or 12
	end
end

local function GetPriorityRecentSpeaker(id)
	local friendinfo = FriendManager.GetFriendById(id)
	if friendinfo  then
		return GetFriendPriority(friendinfo:GetRelation())
	else
		return 1001
	end
end


--刷新好友的数据
local function RefreshFriendData()
         local tmpFriend = {}
--  加载好友信息，姓名，等级等
    for k,friendinfo in  pairs (FriendManager.GetFriends()) do
		local item = {}
--		item.time  = timeutils.GetServertime()
		item.id    = friendinfo.m_RoleId
		item.icon  = GetHeadTexture(friendinfo.m_Profession,friendinfo.m_Gender)
		item.level = friendinfo.m_Level
		item.name  = friendinfo.m_Name
		item.viplevel = friendinfo.m_VipLevel
		if friendinfo.m_Online then item.isOnline = 1 else item.isOnline = 0 end
		item.priority = GetFriendPriority(friendinfo:GetRelation())
		item.relationdes = LocalString.Friend_Priority[item.priority]
		tmpFriend[#tmpFriend + 1] = item
--		onlineinfo[item.name] = item.isOnline
    end
	table.sort(tmpFriend,function(item1,item2)
				if item1.isOnline == item2.isOnline then
					return (item1.priority < item2.priority)
				else
					return (item1.isOnline > item2.isOnline)
				end
			end )
    friendList = tmpFriend

end

local function GetRedInfoByVoiceId(voiceid)
	return redDotInfo[voiceid]
end

local function SetRedInfoByVoiceId(voiceid,b)
	redDotInfo[voiceid] = b
end


local function GetChannelContent(channel,content)
	local str
	if channel == cfg.chat.ChannelType.WORLD then
		str = colorutil.GetColorStr(colorutil.ColorType.Chat_World, content)
	elseif channel == cfg.chat.ChannelType.PRIVATE then
		str = colorutil.GetColorStr(colorutil.ColorType.Chat_Private, content)
	elseif channel == cfg.chat.ChannelType.FAMILY then
		str = colorutil.GetColorStr(colorutil.ColorType.Chat_Family,content)
	elseif channel == cfg.chat.ChannelType.TEAM then
		str = colorutil.GetColorStr(colorutil.ColorType.Chat_Team, content)
	elseif channel == cfg.chat.ChannelType.SYSTEM then
		str = colorutil.GetColorStr(colorutil.ColorType.Chat_System, content)
	elseif channel == cfg.chat.ChannelType.INVITE then
		str = colorutil.GetColorStr(colorutil.ColorType.Chat_World, content)
	elseif channel == cfg.chat.ChannelType.TOP then
		str = colorutil.GetColorStr(colorutil.ColorType.Chat_World, content)
	else
		error("This channel dose not exit")
	end

	return str
end


local function GetChannelTag(channel)
	local str
	if channel == cfg.chat.ChannelType.WORLD then
		str = LocalString.Chat_Channel_World
		--str = colorutil.GetColorStr(colorutil.ColorType.Orange_Chat, LocalString.Chat_Channel_World)
	elseif channel == cfg.chat.ChannelType.PRIVATE then
		str =  LocalString.Chat_Channel_Private
		--str = colorutil.GetColorStr(colorutil.ColorType.Pink_Chat, LocalString.Chat_Channel_Private)
	elseif channel == cfg.chat.ChannelType.FAMILY then
		str =  LocalString.Chat_Channel_Family
		--str = colorutil.GetColorStr(colorutil.ColorType.Blue_Chat, LocalString.Chat_Channel_Family)
	elseif channel == cfg.chat.ChannelType.TEAM then
		str = LocalString.Chat_Channel_Team
		--str = colorutil.GetColorStr(colorutil.ColorType.Green_Chat, LocalString.Chat_Channel_Team)
	elseif channel == cfg.chat.ChannelType.SYSTEM then
		str =  LocalString.Chat_Channel_System
		--str = colorutil.GetColorStr(colorutil.ColorType.Orange_Chat, LocalString.Chat_Channel_System)
	elseif channel == cfg.chat.ChannelType.INVITE then
		str =  LocalString.Chat_Channel_Invite
		--str = colorutil.GetColorStr(colorutil.ColorType.Orange_Chat, LocalString.Chat_Channel_Invite)
	elseif channel == cfg.chat.ChannelType.TOP then
		str =  LocalString.Chat_Channel_Top
		--str = colorutil.GetColorStr(colorutil.ColorType.Orange_Chat, LocalString.Chat_Channel_Top)
	else
		error("This channel dose not exit")
	end

	return str
end

local function GetWorldTable()
	return WorldTable
end

local function GetPrivateTable()
	return PrivateTable
end
local function GetFamilyTable()
	return FamilyTable
end
local function GetTeamTable()
	return TeamTable
end

local function GetSystemTable()
	return SystemTable
end

local function GetWorldMessage()
	return WorldMessage
end

local function GetPrivateMessage()
	return PrivateMessage
end

local function GetFamilyMessage()
	return FamilyMessage
end

local function GetTeamMessage()
	return TeamMessage
end

local function GetSystemMessage()
	return SystemMessage
end

local function GetInviteMessage()
	return InviteMessage
end

local function GetImage()
	return imageid,image
end

local function SendCBuyChatFace(name)
	local msg = lx.gs.chat.msg.CBuyChatFace({name = name})
	network.send(msg)
end





local function SendCGetImage(imageid)
    local msg = lx.gs.chat.msg.CGetImage( { imageid = imageid})
    network.send(msg)
end

local function onmsg_SError(d)
end

local function GetMessageHeight(ChatData)
	return 50
end



local function AddInfo(ChatData)




	if ChatData.channel == cfg.chat.ChannelType.INVITE then
		InviteMessage[#InviteMessage + 1] = ChatData
		return
	end

	if ChatData.channel == cfg.chat.ChannelType.TOP then
		TopMessage[#TopMessage + 1] = ChatData
		return
	end

	if IsVoiceMsg(ChatData) then
		local SettingChat = SettingManager.GetSettingTableByChannel(GetCurChannel())
		local isSend = (ChatData.senderid == PlayerRole:Instance().m_Id)
		if ChatData.channel == GetCurChannel() and ChatData.channel ~= cfg.chat.ChannelType.WORLD and SettingChat[ChatData.channel].isTick and not isSend  then  -- 加上不是自己发的限制，并且不是世界频道发来的
			VoiceMsgQueue:Push({voiceid = ChatData.voiceid,channel = ChatData.channel,isSend = isSend,channel = ChatData.channel})
		end
	end

	WorldTable   = SettingManager.GetSettingTableByChannel(cfg.chat.ChannelType.WORLD)
	PrivateTable = SettingManager.GetSettingTableByChannel(cfg.chat.ChannelType.PRIVATE)
	FamilyTable  = SettingManager.GetSettingTableByChannel(cfg.chat.ChannelType.FAMILY)
	TeamTable    = SettingManager.GetSettingTableByChannel(cfg.chat.ChannelType.TEAM)
	SystemTable  = SettingManager.GetSettingTableByChannel(cfg.chat.ChannelType.SYSTEM)

    if WorldTable[ChatData.channel].isTick == true then
			WorldMessage[#WorldMessage + 1] = ChatData
    end

    if PrivateTable[ChatData.channel].isTick == true then

        if ChatData.receivername and PrivateMessage[ChatData.receivername] == nil then
            PrivateMessage[ChatData.receivername] ={}
        end

        if ChatData.sendername and PrivateMessage[ChatData.sendername] == nil then
            PrivateMessage[ChatData.sendername] ={}
        end
		if ChatData.sendername or ChatData.receivername then
			if ChatData.senderid == PlayerRole:Instance().m_Id then
				PrivateMessage[ChatData.receivername][#PrivateMessage[ChatData.receivername] + 1] = ChatData
			else
				PrivateMessage[ChatData.sendername][#PrivateMessage[ChatData.sendername] + 1] = ChatData
			end
		end
    end

    if FamilyTable[ChatData.channel].isTick == true then
			FamilyMessage[#FamilyMessage + 1] = ChatData
    end

    if TeamTable[ChatData.channel].isTick == true then
			TeamMessage[#TeamMessage + 1] = ChatData
    end

    if SystemTable[ChatData.channel].isTick == true then
			SystemMessage[#SystemMessage + 1] = ChatData
    end

end



local function ClearCountMsg(name)
	if not name then return end
	for index,recent in pairs(recentSpeakerList) do
		if recent.name == name then
			local count = recentSpeakerList[index].count_msg
			if not count then count = 0 end
			totalUnRead = totalUnRead - count
			recentSpeakerList[index].count_msg = 0
			if uimanager.hasloaded("dlguimain") then
				uimanager.call("dlguimain","RefreshUnReadTip")
			end
			return
		end
	end

end


local function RecentSpeakerContains(id)
	for index,item in ipairs(recentSpeakerList) do
		if item.id == id then
			return index
		end
	end
	return nil
end

local function SortRecentListByOnlineAndTime()
	table.sort(recentSpeakerList, function(item1, item2)
			if item1.isOnline == item2.isOnline then
				return(item1.time > item2.time)
			else
				return item1.isOnline > item2.isOnline
			end
		end)
end


local function RefreshUnReadMessageById(index)
	local count = recentSpeakerList[index].count_msg
	if not count then count = 0 end

	count = count + 1
	recentSpeakerList[index].count_msg = count

end

local function RefreshTimeStampById(index)
	recentSpeakerList[index].time = timeutils.GetServerTime()
end

local function RefreshRecentSpeakerData(params)

	if params.content then
		local content = params.content
		local speakername
		local speakerid

		if content.senderid ~= PlayerRole:Instance().m_Id then
			speakername = content.sendername
			speakerid   = content.senderid
		else
			speakername = content.receivername
			speakerid   = content.receiverid
		end
		local index = RecentSpeakerContains(speakerid)

		if  index then
			if speakerid == GetCurPrivateChatPlayerId() and uimanager.isshow("chat.dlgchat01") and CurChannel == cfg.chat.ChannelType.PRIVATE  then

			else

				RefreshUnReadMessageById(index)
			end
			RefreshTimeStampById(index)
			SortRecentListByOnlineAndTime()
			if uimanager.isshow("chat.dlgchat01") then
				uimanager.call("chat.dlgchat01","RefreshPrivateChatList")
			end
		else
			local roles = {}
			table.insert(roles,speakerid)
			local msg = lx.gs.chat.msg.CGetRoleChatShowInfos({roles = roles})

			network.send(msg)
		end
	elseif params.isFriendRelation then
		for index ,recent in ipairs(recentSpeakerList) do
			for index1,friend in ipairs(friendList)do
				if recent.id == friend.id then
					recentSpeakerList[index].priority = friend.priority
				end
			end
		end
	end


end



local function NumToCharacter(num)
    if num == 1 then
--		printyellow(num)
        return "简单"
    elseif num == 2 then
        return "普通"
    elseif num == 3 then
        return "困难"
	else
		return ""
	end
end

local function GetBagInfo(bagtype,serializedData)

	local datastream = octets.new(serializedData)
--	printyellow("dlgchat01 getBagInfo length",octets.size(datastream))
	local item = { }
	if bagtype == cfg.bag.BagType.EQUIP
	    or bagtype == cfg.bag.BagType.EQUIP_BODY then
	    -- 装备
	    local itemData = octets.pop_lx_gs_equip_Equip(datastream)
	    item = ItemManager.CreateItemBaseById(itemData.modelid, itemData, 1)
	elseif bagtype == cfg.bag.BagType.ITEM then
	    -- 物品
	    local itemData = octets.pop_lx_gs_item_Item(datastream)
	    item = ItemManager.CreateItemBaseById(itemData.modelid, itemData, itemData.count)
	elseif bagtype == cfg.bag.BagType.FRAGMENT then
	    -- 碎片
	    local itemData = octets.pop_lx_gs_fragment_Fragment(datastream)
	    item = ItemManager.CreateItemBaseById(itemData.modelid, itemData, itemData.count)
	elseif bagtype == cfg.bag.BagType.TALISMAN
	    or bagtype == cfg.bag.BagType.TALISMAN_BODY then
	    -- 法宝
	    local itemData = octets.pop_lx_gs_talisman_Talisman(datastream)
	    item = ItemManager.CreateItemBaseById(itemData.modelid, itemData, 1)
	end
	return item
end




local function GetMainMessageContent(content)
	local str1
	local tag
	local speaker
	local str
	tag = GetChannelTag(content.channel)


	if content.sendername then
		if content.channel == cfg.chat.ChannelType.PRIVATE then
			if content.senderid ~= PlayerRole:Instance().m_Id then
				speaker = content.sendername.."："
			else
				speaker = "对" ..content.receivername.."："
			end
		else
			speaker = content.sendername.."："
		end
	end

	if IsTextMsg(content) then
		if IsBagMsg(content) then
			local bag = GetBagInfo(content.bagtype,content.item)
			str = colorutil.GetQualityColorText(bag:GetQuality(),string.sub(content.text,8))
		elseif IsBigFaceMsg(content)  or IsEmojiMsg(content) then
			str = "[表情]"
		else
--			printyellow("add",content.text)
			str = string.gsub(content.text,"%[%w%w%w%w%w%]","[表情]")
		end
	elseif IsVoiceMsg(content) then
		str = "[语音]"
	else
		str = "[系统消息]"
	end

	if speaker and tag and str then
		str1 = tag ..speaker.. str
	elseif tag and str then
		str1 = tag .. str
	else
		str1 = ""
	end

	return str1	
end

local function AddMessageInfo(content)

	AddInfo(content)

    if uimanager.isshow("chat.dlgchat01")  then
		uimanager.call("chat.dlgchat01","AddMessage",content)
	end



	if content.channel == cfg.chat.ChannelType.INVITE then
	elseif content.channel == cfg.chat.ChannelType.TOP then
		local str = GetMainMessageContent(content)
		cur_TM_Message = str
		last_TM_Time = timeutils.GetServerTime()
		isTopMessageWarningDuration = false
		if uimanager.hasloaded("dlguimain") then
			uimanager.call("dlguimain","AddMainScreenMessage",{isTopMessage = true, channel = content.channel ,str = str})
		end
	else
		local SettingChat = SettingManager.GetSettingTableByChannel(CurChannel)
		local str = GetMainMessageContent(content)
		if uimanager.hasloaded("dlguimain") then
			uimanager.call("dlguimain","AddMainScreenMessage",{ channel = content.channel ,str = str,SettingChat = SettingChat})
		end
	end

end
--得到消息
local function GetMessageTableByChannel(channel)
	if channel == cfg.chat.ChannelType.WORLD then
		return WorldMessage
	elseif channel == cfg.chat.ChannelType.PRIVATE then
		return PrivateMessage[curPrivateChatName] or {}
	elseif channel == cfg.chat.ChannelType.TEAM then
		return TeamMessage
	elseif channel == cfg.chat.ChannelType.FAMILY then
		return FamilyMessage
	elseif channel == cfg.chat.ChannelType.SYSTEM then
		return SystemMessage
	elseif channel == cfg.chat.ChannelType.INVITE then
		return InviteMessage
	elseif channel == cfg.chat.ChannelType.TOP then
		return TopMessage
	else
		return {}
	end
end



local function ReSendLastMessage(MessageTable)
	if not MessageTable then
		return
	end

	if #MessageTable <= MAX_LINE then

		local i = 1
		 for i,message in ipairs (MessageTable) do
			if uimanager.isshow("chat.dlgchat01")  then
				uimanager.call("chat.dlgchat01","AddMessage",message)
			end
		 end
	else
		while i <= #MessageTable do

			if uimanager.isshow("chat.dlgchat01")  then
				uimanager.call("chat.dlgchat01","AddMessage",MessageTable[i])
			end
			i = i + 1
		end
	end
end

local function UpdateChatMessage(channel,fields)  --change name
	fields.UIList_ChatArea:Clear()
	local MessageTable = GetMessageTableByChannel(channel)
	
		ReSendLastMessage(MessageTable)
	
	
end

local function ReSendLastMainScreenMessage(textList,MessageTable)
	printyellow("ReSendLastMainScreenMessage")
	if #MessageTable <= 5 then
		for i =1 , #MessageTable do
			if MessageTable[i].isinbag == 0 or MessageTable[i].isinbag == nil then
				local str = GetMainMessageContent(MessageTable[i])
				textList:Add(str)
			end
		end
	else
		for i = #MessageTable - 5,#MessageTable do
			if MessageTable[i].isinbag == 0 or MessageTable[i].isinbag == nil then
				local str = GetMainMessageContent(MessageTable[i])
				textList:Add(str)
			end
		end
	end
end

local function GetMainScreenMessageTableByChannel(channel)
	if channel == cfg.chat.ChannelType.TOP then
		return GetMessageTableByChannel(cfg.chat.ChannelType.WORLD)
	else
		return GetMessageTableByChannel(channel)
	end
end

local function UpdateMainScreenMesssage(channel,textList)
	textList:Clear()
	local MessageTable = GetMainScreenMessageTableByChannel(channel)
	
	ReSendLastMainScreenMessage(textList,MessageTable)

		
end

local function HasObtainedFace(name)
	for _,facename in pairs(FaceBuy) do
		if facename == name then
			return true
		end
	end
	return false
end

local function onmsg_SWorldMessage(d)     --世界频道

    local content = d.content
    content.channel = cfg.chat.ChannelType.WORLD
	AddMessageInfo(content)

end

local function RefreshTotalUnReadMessageNum(content)
	if content.senderid ~= PlayerRole:Instance().m_Id then
		if content.sendername ~= GetCurPrivateChatName()
			or not uimanager.isshow("chat.dlgchat01")
			or CurChannel ~= cfg.chat.ChannelType.PRIVATE  then
				totalUnRead = totalUnRead + 1
				if uimanager.hasloaded("dlguimain") then
					uimanager.call("dlguimain","RefreshUnReadTip")
				end
		end
	end
end

local function onmsg_SPrivateMessage(d)   --私聊频道
    print("onmsg_SPrivateMessage")
--	printt(d.content)
    local content = d.content
    content.channel = cfg.chat.ChannelType.PRIVATE
	RefreshTotalUnReadMessageNum(content)
	RefreshRecentSpeakerData({content = content})
	AddMessageInfo(content)
end

local function onmsg_STeamMessage(d)     --队伍频道
  print("onmsg_STeamMessage")
--	printt(d.content)

    local content = d.content
    content.channel = cfg.chat.ChannelType.TEAM
	AddMessageInfo(content)
end

local function onmsg_SFamilyMessage(d)    --家族频道
    print("onmsg_SFamilyMessage")

    local content = d.content
    content.channel = cfg.chat.ChannelType.FAMILY
	AddMessageInfo(content)

end



local function onmsg_SSystemMessage(d)  --系统频道
    print("onmsg_SSystemMessage")
    local content = d.content
	content.channel = cfg.chat.ChannelType.SYSTEM
	AddMessageInfo(content)
end

local function onmsg_STopMessage(d)
     print("onmsg_STopMessage")
	is_TM_ShowWarning = true
    local content = d.content
	content.channel = cfg.chat.ChannelType.TOP
	AddMessageInfo(content)
end



local function onmsg_SInviteMsg(d)
	printyellow("onmsg_SInviteMsg")
    local canreceive,text = EctypeManager.CanReceiveInviteMessage(d.ectypeid)
	if canreceive then
		local content = {}
		content.ectypeid = d.ectypeid
		content.roleid = d.roleid
		content.name = d.name
		content.channel = cfg.chat.ChannelType.INVITE
		content.text = text
		AddMessageInfo(content) --发给【副本】频道
			local content1 = {}
			content1.ectypeid = d.ectypeid
			content1.roleid = d.roleid
			content1.name = d.name
			content1.text = text
			content1.channel = d.channel
			content1.invitechannel = d.channel
			AddMessageInfo(content1) --发给【世界】或【家族】频道
	end

	if uimanager.isshow("common.dlgdialogbox_common") then
		uimanager.hide("common.dlgdialogbox_common")
	end	

end

local function CreateTextByBonus(info,index)
	local str

	local bonus = info.rolebonus.items
	local itemkey
	local itemvalue
	for key,value in pairs(bonus) do
		itemkey = key
		itemvalue = value
	end
	local item = ItemManager.CreateItemBaseById(itemkey)
	if index == 1 then
		str = string.format(LocalString.Chat_SKillGodAnimalNotify_01,info.rolename,item:GetName(),itemvalue)
	elseif index == 2 then
		str = string.format(LocalString.Chat_SKillGodAnimalNotify_02,info.rolename,item:GetName(),itemvalue)
	elseif index == 3 then
		str = string.format(LocalString.Chat_SKillGodAnimalNotify_03,info.rolename,item:GetName(),itemvalue)
	end
	return str
end

local function onmsg_SKillGodAnimalNotify(d)
	local membersbonus = d.membersbonus
	local lasthitbonus = d.lasthitbonus
	local luckybonus = d.luckybonus
	for _,info in pairs(membersbonus) do
		local content = {}
		content.channel = cfg.chat.ChannelType.SYSTEM
		content.text = CreateTextByBonus(info,1)
		AddMessageInfo(content)

	end

	for _,info in pairs(lasthitbonus) do
		local content = {}
		content.channel = cfg.chat.ChannelType.SYSTEM
		content.text = CreateTextByBonus(info,2)
		AddMessageInfo(content)
	end

	for _,info in pairs(luckybonus) do
		local content = {}
		content.channel = cfg.chat.ChannelType.SYSTEM
		content.text = CreateTextByBonus(info,3)
		AddMessageInfo(content)
	end
end


local function UpdateRecordSucess()
	isUpdateRecord = false
	local item = {}
	if isVoiceFromMainScreen then
		item.channel = CurChannelMainScreen
	else
		item.channel = GetCurChannel()
	end
    
	item.receiver = GetCurPrivateChatPlayerId()
	item.voice = Game.Platform.Interface.Instance:GetChatField()
	item.text = Game.Platform.Interface.Instance:GetSpeechToText()
	item.voiceduration = Game.Platform.Interface.Instance:GetRecordLength()
    SendCChat(item)
	if GetCurChannel() == cfg.chat.ChannelType.WORLD then
		local jubaomanager = require"ui.chat.jubaomanager"
		jubaomanager.SetRestTime(PlayerRole:Instance().m_Level,PlayerRole:Instance().m_VipLevel)
	end
end

local function UpdateRecordFaild()
	isUpdateRecord = false;
end


local function PlayRecordSucess()
	StopPlayVoice();
end

local function PlayRecordFaild()
	StopPlayVoice();
end

local function onmsg_SSyncChatFace(d)
--	printyellow("onmsg_SSyncChatFace")
	if 	uimanager.isshow("common.dlgdialogbox_common")	then
		uimanager.hide("common.dlgdialogbox_common")
		uimanager.ShowSystemFlyText(LocalString.Shop_BuySuccess)
	end
	FaceBuy = d.name

end



local function GetfriendList()
	return friendList
end







local function ContainOnlineId(onlineroles,id)
	for _,onlinerole in ipairs(onlineroles) do
		if onlinerole == id then
			return id
		end
	end
	return false
end


--收取服务端下发的获取角色聊天的信息
local function onmsg_SGetRoleChatShowInfos(d)
		local roles =  d.roles
	for roleid,roleinfo in pairs(roles) do
		local index = RecentSpeakerContains(roleid)
		if  index  then
		    recentSpeakerList[index].isOnline = roleinfo.isonline
			recentSpeakerList[index].icon = GetHeadTexture(roleinfo.profession,roleinfo.gender)
			recentSpeakerList[index].name = roleinfo.name
			recentSpeakerList[index].id = roleid
			recentSpeakerList[index].level = roleinfo.level
			recentSpeakerList[index].viplevel = roleinfo.viplevel
			recentSpeakerList[index].priorty = GetPriorityRecentSpeaker(roleid)
			recentSpeakerList[index].relationdes = LocalString.Friend_Priority[recentSpeakerList[index].priorty]
		else
			local item = {}
			item.isOnline = roleinfo.isonline
			item.icon = GetHeadTexture(roleinfo.profession,roleinfo.gender)
			item.name = roleinfo.name
			item.id = roleid
			item.level = roleinfo.level
			item.viplevel = roleinfo.viplevel
			item.priorty = GetPriorityRecentSpeaker(roleid)
			item.relationdes = LocalString.Friend_Priority[item.priorty]
			if item.id == GetCurPrivateChatPlayerId() and uimanager.isshow("chat.dlgchat01") and CurChannel == cfg.chat.ChannelType.PRIVATE  then
				printyellow("xxxxxxx")
			else
				printyellow("yyyyyyy")
				item.count_msg = 1
			end
			item.time = timeutils.GetServerTime()
			table.insert(recentSpeakerList,item)
		end
	end

	SortRecentListByOnlineAndTime()
	if isRefreshPrivateListFunc == false then
		if uimanager.isshow("chat.dlgchat01") then
			uimanager.call("chat.dlgchat01","RefreshPrivateChatList")
		end
	end
end


local function Release()
	isWorldCanSend = true
	WorldMessage   = {}
	PrivateMessage = {}
	FamilyMessage  = {}
	TeamMessage    = {}
	SystemMessage  = {}
	InviteMessage  = {}
	TopMessage     = {}

	WorldTable   = {}
	PrivateTable = {}
	FamilyTable  = {}
	TeamTable    = {}
	SystemTable  = {}

	recentSpeakerList ={}
	friendList ={}

	last_TM_Time				= nil
	cur_TM_Message				= nil
	is_TM_ShowWarning			= nil
	isTopMessageWarningDuration = nil

	CurChannel = cfg.chat.ChannelType.WORLD
	 curPrivateChatName  =  nil
	 curPrivateChatPlayerId = nil
	uimanager.call("dlguimain","ClearChatArea")
end

local function OnLogout()
	Release()
end


local function Friend_Add()
	RefreshFriendData()
--	RefreshRecentSpeakerData({isFriendRelation = true})
	if uimanager.isshow("chat.dlgchat01") and isFriendList then
		uimanager.call("chat.dlgchat01","RefreshPrivateChatList")
	end

end

local function Friend_Delete()
	RefreshFriendData()
	if uimanager.isshow("chat.dlgchat01")  and isFriendList then
		uimanager.call("chat.dlgchat01","RefreshPrivateChatList")
	end
end

local function OnMsgSFriendOnlineNotify(msg)
	RefreshFriendData()
end



local function init()

--	gameevent.evt_system_message:add(MsgSelectPhoto, OnMsgSelectPhoto)
	isAutoPlay = false
	isPlayNext = true   -- original false
	CurChannel = cfg.chat.ChannelType.WORLD
	CurChannelMainScreen = cfg.chat.ChannelType.FAMILY
	gameevent.evt_update:add(update)
	gameevent.evt_system_message:add("logout", OnLogout)
	gameevent.evt_notify:add("friends_add",Friend_Add)
	gameevent.evt_notify:add("friends_delete",Friend_Delete)

    if LuaHelper.IsWindowsEditor() or Application.platform == UnityEngine.RuntimePlatform.WindowsPlayer then
        curVoiceDataDir = Application.dataPath .."/temp/"
    else
        curVoiceDataDir = Application.temporaryCachePath .."/"
    end

	priorityMap = {
		[cfg.friend.MaimaiRelationshipType.BanLvNan] = 1,
		[cfg.friend.MaimaiRelationshipType.BanLvNv]  = 2,
		[cfg.friend.MaimaiRelationshipType.YiXiong]  = 5,
		[cfg.friend.MaimaiRelationshipType.YiJie]  	 = 6,
		[cfg.friend.MaimaiRelationshipType.YiDi]  	 = 7,
		[cfg.friend.MaimaiRelationshipType.YiMei]    = 8,
		[cfg.friend.MaimaiRelationshipType.LanYan]   = 4,
		[cfg.friend.MaimaiRelationshipType.HongYan]  = 3,
		[cfg.friend.MaimaiRelationshipType.XiongDi]  = 10,
		[cfg.friend.MaimaiRelationshipType.GuiMi]    = 9,
		[cfg.friend.MaimaiRelationshipType.SuDi]     = 11,
	}

    network.add_listeners( {
       { "lx.gs.chat.msg.SError", onmsg_SError },

       { "lx.gs.chat.msg.SPrivateMessage", onmsg_SPrivateMessage },
       { "lx.gs.chat.msg.STeamMessage", onmsg_STeamMessage },
       { "lx.gs.chat.msg.SFamilyMessage", onmsg_SFamilyMessage },
       { "lx.gs.chat.msg.SWorldMessage", onmsg_SWorldMessage },
       { "lx.gs.chat.msg.SSystemMessage", onmsg_SSystemMessage },
       { "lx.gs.chat.msg.STopMessage", onmsg_STopMessage },
       { "lx.gs.chat.msg.SInviteMsg", onmsg_SInviteMsg },
	   { "map.msg.SKillGodAnimalNotify",onmsg_SKillGodAnimalNotify},

	   { "lx.gs.chat.msg.SSyncChatFace",onmsg_SSyncChatFace},

        { "lx.gs.friend.msg.SFriendOnlineNotify",   OnMsgSFriendOnlineNotify   },
		{"lx.gs.chat.msg.SGetRoleChatShowInfos",onmsg_SGetRoleChatShowInfos},


    } )
	
	
    gameevent.evt_system_message:add("upvoicedone", UpdateRecordSucess)
	gameevent.evt_system_message:add("upvoiceerror", UpdateRecordFaild)
	
	gameevent.evt_system_message:add("playvoicedone", PlayRecordSucess)
	gameevent.evt_system_message:add("playvoiceerror", PlayRecordFaild)


end

return {

    init = init,
    SendCChat = SendCChat,
	SendCGetImage = SendCGetImage,
    SelectPhoto = SelectPhoto,
	GetImage = GetImage,
	GetWorldMessage = GetWorldMessage,
	GetPrivateMessage = GetPrivateMessage,
	GetFamilyMessage = GetFamilyMessage,
	GetTeamMessage = GetTeamMessage,
	GetSystemMessage = GetSystemMessage,
	GetInviteMessage = GetInviteMessage,
	GetWorldTable = GetWorldTable,
	GetPrivateTable = GetPrivateTable,
	GetFamilyTable = GetFamilyTable,
	GetTeamTable = GetTeamTable,
	GetSystemTable = GetSystemTable,
	GetRecentSpeakerList = GetRecentSpeakerList,
	AddInfo = AddInfo,
	RefreshRecentSpeakerData = RefreshRecentSpeakerData,
	GetRestTime = GetRestTime,
	SendCBuyChatFace = SendCBuyChatFace,
	GetIsWorldCanSend = GetIsWorldCanSend,
	SetIsWorldCanSend = SetIsWorldCanSend,
	GetRedInfoByVoiceId = GetRedInfoByVoiceId,
	SetRedInfoByVoiceId = SetRedInfoByVoiceId,
	GetBagInfo = GetBagInfo,
	AddMessageInfo = AddMessageInfo,
	GetCurChannel = GetCurChannel,
	SetCurChannel = SetCurChannel,
	GetCurPrivateChatName = GetCurPrivateChatName,
	SetCurPrivateChatName = SetCurPrivateChatName,
	GetFriendList = GetFriendList,
	RefreshFriendData = RefreshFriendData,
	UpdateChatMessage = UpdateChatMessage,
	GetChannelTag = GetChannelTag,
	HasObtainedFace = HasObtainedFace,
	StartPlayVoice = StartPlayVoice,
	StartRecordVoice = StartRecordVoice,
	StopRecord = StopRecord,
	CheckFileNameByVoiceId = CheckFileNameByVoiceId,
	GetServerInfoByVoiceId = GetServerInfoByVoiceId,
	SetServerInfoByVoiceId = SetServerInfoByVoiceId,
	EngFontWidthFunc = EngFontWidthFunc,
	IsBigFaceMsg = IsBigFaceMsg,
	IsBagMsg = IsBagMsg,
	IsInviteMsg = IsInviteMsg,
	IsVoiceMsg = IsVoiceMsg,
	IsEmojiMsg = IsEmojiMsg,
	SetCurListItemVoice = SetCurListItemVoice,
	SetCurListItemVoice1 = SetCurListItemVoice1,
	GetCurListItemVoice = GetCurListItemVoice,
	IsStartPlay = IsStartPlay,
	ResetVoiceAnimationData = ResetVoiceAnimationData,
	GetPrivateChatList = GetPrivateChatList,
	SetIsFriendList = SetIsFriendList,
	GetCurSpeakerIdByName = GetCurSpeakerIdByName,
	ClearCountMsg = ClearCountMsg,
	GetIsFriendList = GetIsFriendList,
	GetFriendList = GetFriendList,
	GetTotalUnRead = GetTotalUnRead,
	IsTipMessageShow = IsTipMessageShow,
	SetCurPrivateChatPlayerId = SetCurPrivateChatPlayerId,
	GetCurPrivateChatPlayerId = GetCurPrivateChatPlayerId,
	SetRefreshPrivateListFunc = SetRefreshPrivateListFunc,
	GetRefreshPrivateListFunc = GetRefreshPrivateListFunc,
	RefreshAllRecentSpeakerData = RefreshAllRecentSpeakerData,
	SetAutoPlay = SetAutoPlay,
	SetAutoPlayIndex = SetAutoPlayIndex,
	UpdateMainScreenMesssage = UpdateMainScreenMesssage,
	GetCurPlayingVoiceId = GetCurPlayingVoiceId,
	AddVoiceListItemInfo = AddVoiceListItemInfo,
	GetOnlineStatusByName = GetOnlineStatusByName,
	SetVoiceFromMainScreen = SetVoiceFromMainScreen,
	SetMainScreenCurChannel = SetMainScreenCurChannel,
	GetChannelContent = GetChannelContent,

}
