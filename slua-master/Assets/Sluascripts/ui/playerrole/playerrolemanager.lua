local network = require"network"
local changenametimes 
--local BagManager         = require("character.bagmanager")
--local StoryNoteManager   = require("ui.playerrole.storynote.storynotemanager")

local function PageRoleUnRead()
    return false
end

local function PageBagUnRead()
    return false
end

local function PageTalismanUnRead()
    return false
end

local function PahePetUnRead()

    return false
end

local function GetChangeNameTimes()
	return changenametimes or 0
end

local function SetChangeNameTimes(times)
	changenametimes = times 
end

local function onmsg_SRoleLogin(msg)
	changenametimes = msg.roledetail.changenametimes or 0 
--	printyellow("onmsg_SRoleLogin",changenametimes)
end

local function UnRead()
    --local page_bagRunRead = BagManager.UnRead
    --local page_TalismanUnRead = require("ui.playerrole.talisman.tabtalisman").UnRead
    --local page_StoryUnRead = StoryNoteManager.UnRead
    --return page_bagRunRead() or page_TalismanUnRead() or  page_StoryUnRead()
	return false
end
local function init()
	network.add_listeners({

		{"lx.gs.login.SRoleLogin",onmsg_SRoleLogin},

	})
end

return {
	init                = init,
    UnRead              = UnRead,
    PageRoleUnRead      = PageRoleUnRead,
    PageBagUnRead       = PageBagUnRead,
    PageTalismanUnRead  = PageTalismanUnRead,
    PahePetUnRead       = PahePetUnRead,
	GetChangeNameTimes  = GetChangeNameTimes,
	SetChangeNameTimes  = SetChangeNameTimes,
}