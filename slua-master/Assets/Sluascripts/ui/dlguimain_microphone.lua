local unpack            = unpack
local print             = print
local format            = string.format
local math              = math
local EventHelper       = UIEventListenerHelper
local gameevent         = require"gameevent"
local uimanager        = require("uimanager")
local network           = require("network")
local FamilyManager = require "family.familymanager"
local TeamManager = require "ui.team.teammanager"
local chatmanager = require("ui.chat.chatmanager")



local gameObject
local name
local fields
local count_channel = 0
local cur_channel 

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
end

local function hide()
    -- print(name, "hide")
end

local function update()

end


local function refresh()
--	printyellow("refresh the icon")

end

local function RefreshIcon(params)
--	printyellow("refresh the  Refresh Icon icon")

end

local function CanSend()

	if not cur_channel then cur_channel =  cfg.chat.ChannelType.FAMILY end 
	if cur_channel == cfg.chat.ChannelType.TEAM and not TeamManager.IsInTeam()then  --如果在“队伍”频道中，玩家不是组队状态，则不能发送消息
		uimanager.ShowSystemFlyText(LocalString.Chat_NotInTeam)
		return false
	end

	if cur_channel == cfg.chat.ChannelType.FAMILY  and not FamilyManager.InFamily() then   --如果在“家族”频道中，玩家不在任何家族，则不能发送消息
		uimanager.ShowSystemFlyText(LocalString.Chat_NotInFamily)
		return false
	end
	return true
end

local function init(iName,iGameObject,iFields)
    name            = iName
    gameObject      = iGameObject
    fields          = iFields
	cur_channel = cfg.chat.ChannelType.FAMILY
	EventHelper.SetClick(fields.UIButton_MicroPhone,function()
--		local pao = require"paomadeng.paomadengmanager"
--		pao.SetFullMessage()

        if count_channel == 0 then
            fields.UILabel_Channel.text = "[B89CCE][队伍]"
            cur_channel = cfg.chat.ChannelType.TEAM
			chatmanager.SetMainScreenCurChannel(cfg.chat.ChannelType.TEAM)

        else
			fields.UILabel_Channel.text = "[B89CCE][家族]"
            cur_channel = cfg.chat.ChannelType.FAMILY
			chatmanager.SetMainScreenCurChannel(cfg.chat.ChannelType.FAMILY)
		end

        count_channel = (count_channel + 1) % 2

	end)

	EventHelper.SetPress(fields.UIButton_MicroPhone,function(go, bPress)
        -- printyellow("SetPress")
		if not CanSend() then
			return
		end
		
        if bPress == true then
			uimanager.show("chat.dlgdialogbox_speak")
			chatmanager.SetVoiceFromMainScreen(true)			
            chatmanager.StartRecordVoice()                     --开始录音
        else
			uimanager.hide("chat.dlgdialogbox_speak")
            chatmanager.StopRecord()                           --结束录音
			chatmanager.SetVoiceFromMainScreen(false)
        end

	end)



end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,

}
