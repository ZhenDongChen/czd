local NetWork           = require("network")
local Player            = require("character.player")
local Define            = require("define")
local UIManager         = require("uimanager")
local CharacterFactory  = require("character.factory.factory")

local EquipPage         = require("ui.otherplayer.pages.equippage")
local RoleInfoPage      = require("ui.otherplayer.pages.roleinfopage")

local name,gameObject,fields
local listenerIds = nil
local buttonInfo = nil
local otherPlayer = nil
local roleInfo = nil


local function refresh(params)
	print("----------------------------------------------------------------------------dlgotherroledetails refresh")
    if params and params.roleId and params.roleInfo and params.player and params.buttons then
        EquipPage.refresh(params.roleInfo.roleid, params.roleInfo, params.player)
        RoleInfoPage.refresh(params.roleInfo.roleid, params.roleInfo, params.player, params.buttons)
    else
        EquipPage.refresh(roleInfo.roleid, roleInfo, otherPlayer)
        RoleInfoPage.refresh(roleInfo.roleid, roleInfo, otherPlayer, buttonInfo)
    end
end

local function show(params)

    if params and params.roleInfo and params.player then
        EquipPage.show(params.roleInfo.roleid, params.roleInfo, params.player)
        RoleInfoPage.show(params.roleInfo.roleid, params.roleInfo, params.player, params.buttons)
        roleInfo = params.roleInfo
        otherPlayer = params.player
        buttonInfo = params.buttons
    end
end

--==========================================================================================================
local function OnMsgSGetRoleInfo(msg)
     printyellow("OnMsgSGetRoleInfo")
    if otherPlayer then
        otherPlayer:release()
        otherPlayer = nil
    end
    msg.roleinfo.equipsdetail = {}
    for i, equipMsg in pairs(msg.roleinfo.equips) do
        msg.roleinfo.equipsdetail[i] = lx.gs.equip.Equip({
					equipid		= 0,
					modelid		= equipMsg.modelid,
					position	= 0,
					expiretime	= 0,
					isbind		= 1,
					normalequip = equipMsg.normalequip,
					accessory	= equipMsg.accessory,
					})
    end
    for i, equipMsg in pairs(msg.roleinfo.equips) do
        msg.roleinfo.equips[i] = map.msg.EquipBrief({equipkey = equipMsg.modelid, anneallevel = equipMsg.normalequip.anneallevel,perfuselevel = equipMsg.normalequip.perfuselevel})
    end
    otherPlayer = CharacterFactory.CreatePlayerForUIByMsg("RoleShowInfo5", msg.roleinfo, function(other, go)
        UIManager.show( "otherplayer.dlgotherroledetails", {
                        roleId      = msg.roleinfo.roleid,
                        roleInfo    = msg.roleinfo,
                        player      = other,
                        buttons     = buttonInfo})
    end, 0.75)
end
--==========================================================================================================
--[[    params.roleId   ]]
local function showdialog(params)
    printyellow("showdialog")
    listenerIds = NetWork.add_listeners({{"lx.gs.role.msg.SGetRoleInfo",OnMsgSGetRoleInfo},})
    NetWork.create_and_send("lx.gs.role.msg.CGetRoleInfo", {roleid = params.roleId})
    buttonInfo = params.buttons
end

local function hide()
    NetWork.remove_listeners(listenerIds)
    if otherPlayer then
        CharacterFactory.DestroyCharacterForUI(otherPlayer)
        otherPlayer = nil
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)
    EquipPage.init(name, gameObject, fields)
    RoleInfoPage.init(name, gameObject, fields)
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    showdialog = showdialog,
    --uishowtype = uishowtype,
}
