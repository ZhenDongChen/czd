local unpack = unpack
local print = print
local uimanager = require("uimanager")

local defineenum=require("defineenum")

local network = require "network"
local gameObject
local name
local fields
local uiFadeIn,uiFadeOut
local ElapsedTime
local EventHelper = UIEventListenerHelper
local octets = require("common.octets")
local login = require("login")

local function destroy()
end

local function update()

end

local function show(params)
  
end

local function hide()

end

local function refresh(params)

end

local function onmsg_SWorldMessage(d)

local content = d.content

-- fields.UIInput_Name.value = content.text


end

function Split(szFullString, szSeparator)
local nFindStartIndex = 1
local nSplitIndex = 1
local nSplitArray = {}
while true do
   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
   if not nFindLastIndex then
    nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
    break
   end
   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
   nFindStartIndex = nFindLastIndex + string.len(szSeparator)
   nSplitIndex = nSplitIndex + 1
end
return nSplitArray
end

---Util.Log("testx 1")
local function process_ClientCmd(txt)
	local cmd=Split(txt, ' ')
	if cmd and #cmd>0 then 
		local nm=cmd[1]
	   local fnc=g_clientCmdList[nm]
	   if fnc then
			if fnc(cmd) then
			end
			return true;
	   end
	end
	return false
end

--process_ClientCmd("\talisman 1 2 3")

local function processChat(fields)
		token = Game.Platform.Interface.Instance:GetToken();
		local inputvalue = fields.UIInput_Name.value

		local rolesID = login.get_loginrole()
	
		--if string.sub(inputvalue,1,1) == "/" then 
			if process_ClientCmd(inputvalue) then
			  return 
			end
		--end
		
			local re = lx.gs.chat.msg.CChat(
			{	
			 channel=0,
			 receiver= rolesID,
			 text=inputvalue,
			 bagtype=3,
			 pos=6,
			 invitechannel=7,
			 voice=token,
			 voiceduration=5,	
			}) 	
			network.send(re)
end

local function init(params)
    name, gameObject, fields = unpack(params)

	
	network.add_listener("lx.gs.chat.msg.SWorldMessage",onmsg_SWorldMessage)
	EventHelper.SetClick(fields.UIButton_Sure,function()
		processChat(fields)
	end)
	
	EventHelper.SetClick(fields.UIButton_Back,function()
		uimanager.destroy(name)
	end)
	EventHelper.SetClick(fields.UIButton_BackLogin,function()
		local login = require"login"
	    login.Game_logout(login.LogoutType.to_login)
		--login.logout(login.LogoutType.to_choose_player)
	end)
	EventHelper.SetClick(fields.UIToggle_Normal,function()
		setShowMsg(fields.UIToggle_Normal.value)
	end)
	
	local CharacterManager = require("character.charactermanager")
	for _,character in pairs(CharacterManager.GetCharacters()) do
       
		--fields.UILabel_Characters.text = 
		print(character.m_Name)
    end
	fields.UIToggle_Normal.value = needShowMsg()
end


return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
