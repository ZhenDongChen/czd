local network = require"network"
local uimanager = require"uimanager"
local gameevent = require "gameevent"
local old_attr = {}
local new_attr = {}
local level			--当前升到的等级
local old_level		--原来的等级
local isUpgradeLevel = false
local isChangeAttr = false
local attrs ={}
local offsetAttrs = {}

local function GetFightAttributes()
	return attrs
end

local function GetOffsetAttributes()

	return offsetAttrs
end

local function Update()


		if isUpgradeLevel and isChangeAttr then

			isUpgradeLevel = false
			isChangAttr = false
			uimanager.show("updateattr.dlgupdateattribute",{old_attr = old_attr,new_attr = new_attr,level = level})
			--end
			local OperationActivityManager  = require("ui.operationactivity.operationactivitymanager")
			--运营冲级活动
			OperationActivityManager.CheckOperationActivity(102)
			old_attr = new_attr
		end

end

local function onmsg_SLevelChange(d)
--	printyellow("onmsg_SExpChange",d.level)

	if not old_level then
		old_level = level
	end
	level = d.level
	if old_level ~= d.level then
		old_level = d.level
		isUpgradeLevel = true
	else
		isUpgradeLevel = false
	end
	if uimanager.isshow("chat.dlgchat01") then
		uimanager.hidedialog("chat.dlgchat01")
	end
end


local function onmsg_SChangeEffectAttrs(d)
	printyellow(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>onmsg_SChangeEffectAttrs")
	offsetAttrs = d.attrs
	local TabRoleInfo = require"ui.playerrole.roleinfo.tabroleinfo"
	if uimanager.isshow("playerrole.roleinfo.tabroleinfo") then
		TabRoleInfo.refresh(offsetAttrs)
	end
	
end


local function onmsg_SChangeAttrs(d)

	attrs = d.attrs
	if next(old_attr) == nil then
		old_attr = d.attrs
	else

		new_attr = d.attrs
		isChangeAttr = true
	end
    local PlayerRole = require "character.playerrole"
    local MapManager=require"map.mapmanager"

    --if MapManager.IsFirstLogin()~=true then
        local DlgCombatPower = require "ui.dlgcombatpower"
        DlgCombatPower.showchange(PlayerRole:Instance().m_Power,d.combatpower)
   -- else
       -- MapManager.SetFirstLogin()
  --  end
    PlayerRole:Instance().m_Power = d.combatpower
	local DlgUIMain_RoleInfo = require "ui.dlguimain_roleinfo"
    DlgUIMain_RoleInfo.refresh()
	local TabRoleInfo = require"ui.playerrole.roleinfo.tabroleinfo"
	if uimanager.isshow("playerrole.roleinfo.tabroleinfo") then
		TabRoleInfo.refresh()
	end
	
	if uimanager.isshow("playerrole.roleinfo.tabroleinfo")  then
		uimanager.call("playerrole.roleinfo.tabroleinfo","RefreshLeftPage",attrs)
		uimanager.call("playerrole.roleinfo.tabroleinfo","RefreshRightPage",attrs)
	end

end

local function onmsg_SRoleLogin(d)
	-- printyellow("onmsg_SRoleLogin")
		-- printt(d.roledetail.attrs)
	attrs = d.roledetail.attrs
	old_attr = attrs 
end


local function Release()
	old_attr = {}
	new_attr = {}
	level	 = nil		--当前升到的等级
	old_level	= nil	--原来的等级
	isUpgradeLevel = false
	isChangeAttr = false
	attrs ={}	
	msgEnd = nil
end

local function OnLogout()
	Release()
end

local function init()
	gameevent.evt_system_message:add("logout", OnLogout)
	network.add_listeners({
--		{"lx.gs.login.SRoleLogin",onmsg_SRoleLogin},
		{"lx.gs.role.msg.SLevelChange",onmsg_SLevelChange},
		{"lx.gs.role.msg.SChangeAttrs",onmsg_SChangeAttrs},
		{"map.msg.SChangeEffectAttrs",onmsg_SChangeEffectAttrs},
		{"lx.gs.login.SRoleLogin",onmsg_SRoleLogin},
    })
	gameevent.evt_update:add(Update)
end

return {
	init = init,
	update = update,
	GetFightAttributes = GetFightAttributes,
	GetOffsetAttributes = GetOffsetAttributes,
}
