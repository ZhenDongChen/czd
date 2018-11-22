ConfigManager = require("cfg.configmanager")
DefineEnum = require("defineenum")
local UIManager     = require("uimanager");
local dlgType       = {"DialogBox","MovieStyle","CenterAside"}
local dlgplotmain = require("ui.plot.dlgplotmain")

local ReplaceDict

local function init()

end
--替换控制字符
local function ReplaceControlStr(str)
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
local function GetTalkData(talkData,talk)
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
local function GetPlotDialog(id)


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
--显示对话
local function ShowDialogEx(Id,talkData)
    CurrentDialogId = Id
    local params 		= {
        DialogMode		= talkData.m_DialogType,
        Name			= ReplaceControlStr(talkData.m_TalkPerson),
        Picture			= talkData.m_Picture,
        Content			= ReplaceControlStr(talkData.m_TalkContent),
        NameFontSize 	= talkData.m_NameFontSize,
        ContentFontSize	= talkData.m_ContentFontSize,
        Position 		= talkData.m_Position
    }

	--printyellow("sssss")
	dlgplotmain.SetTalk("Show",params.Content)
   -- if UIManager.isshow("plot.dlgplot_talk") then
   --     UIManager.refresh("plot.dlgplot_talk",params);
   -- else
   --     UIManager.show("plot.dlgplot_talk",params);
   -- end

    if talkData.m_SoundPath ~= nil then

    end
    return Id
end

local function ShowDialog(Id)
	--DlgName = "dlgplot_talk"
	local talkData = GetPlotDialog(Id)
    ShowDialogEx(Id,talkData)
    return Id
end


local function HideDialog(Id)

    if  Id == CurrentDialogId then
		local dlgplotmain = require("ui.plot.dlgplotmain")
		dlgplotmain.SetTalk("Hide","")
       -- UIManager.hide("plot.dlgplot_talk")
    end
end
return {
	init = int,
	GetPlotDialog = GetPlotDialog,
    ShowDialog = ShowDialog,
    HideDialog = HideDialog,
    ShowDialogEx = ShowDialogEx,
}
