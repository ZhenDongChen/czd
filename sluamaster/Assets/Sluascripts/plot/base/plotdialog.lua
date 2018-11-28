local ConfigManager = require("cfg.configmanager")

local PlotDialog = Class:new()

function PlotDialog:__new(cutscene, config)
    self.m_Cutscene = cutscene
    self.m_Config = config
end


--替换控制字符
function PlotDialog:ReplaceControlStr(str)
    
    local playerTitle = (( PlayerRole:Instance().m_Title == nil) and  "") or PlayerRole:Instance().m_Title:GetName()
	str = string.gsub( str,"{%s*PlayerRoleName%s*}",PlayerRole:Instance().m_Name )
	str = string.gsub( str,"{%s*PlayerRoleTitle%s*}",playerTitle )

	local num
	local st,ed = string.find(str,"{%s*Sex%s*=%s*%d%s*}")

	if st ~= nil and ed ~= nil then
		local cmdstr = string.sub(str,st+1,ed-1)
		local cmdstr = string.gsub(cmdstr," ","")
		local st2,ed2 = string.find(cmdstr,"=%d")


		local numstr = string.sub(cmdstr,st2+1,ed2)
		num = loadstring("return " .. numstr)()
	end


	if num ~= nil then
		local key = ((PlayerRole:Instance().m_Gender == DefineEnum.GenderType.Male) and "Male") or "Female"
		local replaceStrList = ConfigManager.getConfigData("plotcall",key)
		local replaceStr = replaceStrList.calls[num]
		str = string.gsub(str,"{%s*Sex%s*=%s*%d%s*}",replaceStr)
	end
	return str
end
--获取对话数据
function PlotDialog:GetTalkData(talkData,talk)
	local Talk = {}

	Talk.m_DialogType 		= dlgType[talkData.talktype+1]
    Talk.m_NameFontSize 	= ((talkData.namefontsize > 0) and talkData.namefontsize) or nil
    Talk.m_ContentFontSize 	= ((talkData.contentfontsize > 0) and talkData.contentfontsize) or nil
    --printyellow(Talk.m_NameFontSize,Talk.m_ContentFontSize)
	Talk.m_TalkPerson = talk.talkperson
	Talk.m_TalkContent = talk.talkcontent
	Talk.m_Picture = talk.picture
	Talk.m_SoundPath = talk.sound
	Talk.m_StartTime = talk.start
	Talk.m_Duration = talk.duration
    Talk.m_Position = Vector2(talk.positionx,talk.positiony)
	return Talk
end
--获取对话数据
function PlotDialog:GetPlotDialog(id)

	local dialogData = ConfigManager.getConfigData("plottalk",id)

	local Talk = {}
	if dialogData ~= nil then
		--Talk.m_DlgType = dialogData.talktype
		if dialogData.branch == true then
			local profnum = PlayerRole:Instance().m_Profession + 1
			Talk = GetTalkData(dialogData,dialogData.talks[profnum])
		else
			Talk = GetTalkData(dialogData,dialogData.talk)
		end
	end

	return Talk
end


function PlotDialog:Show(dialogSystem, params)
    local content = self:ReplaceControlStr(params.m_TalkContent)
    self.m_Cutscene.m_UI:SetTalk("Show",content)
end

function PlotDialog:Hide(dialogSystem, params)
    self.m_Cutscene.m_UI:SetTalk("Hide", "")
end




return PlotDialog