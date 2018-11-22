local os            = require "common.octets"
local UIManager     = require("uimanager")
local Network       = require("network")
local RankData		= require("ui.rank.info.arenadata")
local EventHelper   = UIEventListenerHelper
local Player		= require("character.player")
local ArenaManager  = require("ui.arena.single.arenamanager")
local Define        = require("define")
local ConfigManager = require("cfg.configmanager")
local HelpInfo      = require("ui.helpinfo.helpinfo")


local name, gameObject, fields
local listenerIds

local ArenaRanks = {}
local ArenaTopRoles = {}
local MyRank = nil


local function CheckIsReady()
	local notFinfish = false
	for i = 1, 3 do
		if ArenaTopRoles[i].m_Role == nil then
			notFinfish = true
		end
	end
	return (not notFinfish)
end

local function GetRoleInfo(roleId)
--	printyellow("GetRoleInfo", roleId)

	local re = lx.gs.role.msg.CGetRoleInfo( { roleid = roleId })
	Network.send(re)
end

local function OnMsgSGetRank(msg)
    -- printyellow(msg)
	local datastream = os.new(msg.data)
	local ranks = os.pop_list(datastream, "lx_gs_rank_msg_GeneralRankInfo")
	for rankIndex, rankData in ipairs(ranks) do
--		printyellow("rankIndex",rankIndex)
		ArenaRanks[rankIndex] = RankData:new(rankData.roleid, rankData.name, rankData.level, rankData.value)
	end

	if msg.mycurrank >= 1 then
		MyRank = msg.mycurrank
	else
		MyRank = nil
	end

	for i = 1, 3 do
		local arenaData = ArenaRanks[i]
		if arenaData then
			ArenaTopRoles[i] = { m_Id = arenaData:GetId(), m_Role = nil }
			GetRoleInfo(arenaData:GetId())
		end
	end
end

local function OnMsgSGetRoleInfo(msg)
--	printyellow("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
 --   printyellow(msg)
--	printyellow(ArenaTopRoles[1].m_Id,ArenaTopRoles[2].m_Id,ArenaTopRoles[3].m_Id)

	for i = 1, 3 do
		if ArenaTopRoles[i].m_Id == msg.roleinfo.roleid then
			local player = Player:new(nil)
			player.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
			ArenaTopRoles[i].m_Msg = msg.roleinfo
			--player:init()
			ArenaTopRoles[i].m_Role = player
		end
	end

	--printyellow(ArenaTopRoles[1].m_Role,ArenaTopRoles[2].m_Role,ArenaTopRoles[3].m_Role)
	--printyellow(CheckIsReady())

	if CheckIsReady() == true then
		--printyellow("[[[[[[[[[[[[[[]]]]]]]]]]]]]]")
		--printyellow(name)
		Network.remove_listeners(listenerIds)
		UIManager.show("rank.dlgarenarank")
	end
end







--===========================================================================================================
--[[]]
local function RefreshLeftItem(uiItem,index,realIndex)
	local arenaData = ArenaRanks[realIndex]

	local spriteNo1 = uiItem.Controls["UISprite_NO1"]
	local spriteNo2 = uiItem.Controls["UISprite_NO2"]
	local spriteNo3 = uiItem.Controls["UISprite_NO3"]
	local rankLabel = uiItem.Controls["UILabel_Ranking"]


	if realIndex == 1 then
		spriteNo1.gameObject:SetActive(true)
		spriteNo2.gameObject:SetActive(false)
		spriteNo3.gameObject:SetActive(false)
		rankLabel.gameObject:SetActive(false)
	elseif realIndex == 2 then
		spriteNo1.gameObject:SetActive(false)
		spriteNo2.gameObject:SetActive(true)
		spriteNo3.gameObject:SetActive(false)
		rankLabel.gameObject:SetActive(false)
	elseif realIndex == 3 then
		spriteNo1.gameObject:SetActive(false)
		spriteNo2.gameObject:SetActive(false)
		spriteNo3.gameObject:SetActive(true)
		rankLabel.gameObject:SetActive(false)
	else
		spriteNo1.gameObject:SetActive(false)
		spriteNo2.gameObject:SetActive(false)
		spriteNo3.gameObject:SetActive(false)
		rankLabel.gameObject:SetActive(true)
		rankLabel.text = tostring(realIndex)
	end

	uiItem:SetText("UILabel_Name", arenaData.m_RoleName)
	uiItem:SetText("UILabel_RankValue", arenaData.m_RankValue)
	uiItem:SetText("UILabel_Speed", ArenaManager.GetReputationIncrease(realIndex))

	local lookButton = uiItem.Controls["UIButton_Look"]
	EventHelper.SetClick(lookButton, function()
		--printyellow("Check",arenaData:GetId())
		UIManager.showdialog("otherplayer.dlgotherroledetails",{roleId = arenaData:GetId()})
	end)


end

local function RefreshLeft()
	local rankNum = #ArenaRanks
    local wrapList = fields.UIList_Rank.gameObject:GetComponent("UIWrapContentList")
    EventHelper.SetWrapListRefresh(wrapList, RefreshLeftItem)
    wrapList:SetDataCount(rankNum)
    wrapList:CenterOnIndex(0)

	if MyRank then
		fields.UILabel_PlayerRank.text = tostring(MyRank)
	else
		fields.UILabel_PlayerRank.text = tostring(LocalString.Ranklist_NotInRanklist)
	end
	EventHelper.SetClick(fields.UIButton_GetRewards, function()
		local arenaCfg = ConfigManager.getConfig("arenaconfig")
		--UIManager.ShowSingleAlertDlg({content = arenaCfg.introduction})
		HelpInfo.ShowHelpInfo("pvparenarank","rankrole")
		--printyellow("AABBCCDD")
	end)
end

local function RefreshRight()
	for i = 1, 3 do
		local uiItem = fields.UIList_Player:GetItemByIndex(i-1)
		local playerData = ArenaTopRoles[i]
		local texture = uiItem.Controls["UITexture_PlayerModel"]
		local spriteNo1 = uiItem.Controls["UISprite_NO1"]
		local spriteNo2 = uiItem.Controls["UISprite_NO2"]
		local spriteNo3 = uiItem.Controls["UISprite_NO3"]

		local titleName = ""
		if i == 1 then
			spriteNo1.gameObject:SetActive(true)
			spriteNo2.gameObject:SetActive(false)
			spriteNo3.gameObject:SetActive(false)
			titleName = cfg.arena.ArenaConfig.firsttitle
		elseif i == 2 then
			spriteNo1.gameObject:SetActive(false)
			spriteNo2.gameObject:SetActive(true)
			spriteNo3.gameObject:SetActive(false)
			titleName = cfg.arena.ArenaConfig.secondtitle
		else
			spriteNo1.gameObject:SetActive(false)
			spriteNo2.gameObject:SetActive(false)
			spriteNo3.gameObject:SetActive(true)
			titleName = cfg.arena.ArenaConfig.thirdtitle
		end

		uiItem:SetText("UILabel_PlayTitle",titleName )


		uiItem:SetText("UILabel_PlayerName", playerData.m_Msg.name)

		uiItem:SetText("UILabel_CombatPower", playerData.m_Msg.combatpower)
		uiItem:SetText("UILabel_PlayerLV", playerData.m_Msg.level)

		playerData.m_Role:RegisterOnLoaded(function(obj)

			obj.transform.parent = texture.gameObject.transform
			ExtendedGameObject.SetLayerRecursively(obj, Define.Layer.LayerUICharacter)
			obj.transform.localPosition = Vector3(0,-1.50*SCALE_XY,-1*SCALE_XY)
			obj.transform.localRotation = Quaternion.Euler(-90,0,0)--Quaternion.identity
			playerData.m_Role:SetUIScale(220)
			--obj.transform.localScale = Vector3(230,230,230)
			--obj.transform.localRotation =
		end)
		local dressId = playerData.m_Msg.dressid
		local equips = {}
		for k, equipMsg in pairs(playerData.m_Msg.equips) do
			equips[k] = map.msg.EquipBrief({
								equipkey = equipMsg.modelid, 
								anneallevel = equipMsg.normalequip.anneallevel,
								perfuselevel = equipMsg.normalequip.perfuselevel})
		end
		playerData.m_Role:init(playerData.m_Id, playerData.m_Msg.profession ,playerData.m_Msg.gender, false, dressId, equips, false)

	end
end




local function showdialog(params)
	listenerIds = Network.add_listeners( {
		{ "lx.gs.rank.msg.SGetRank",        OnMsgSGetRank       },
		{ "lx.gs.role.msg.SGetRoleInfo",    OnMsgSGetRoleInfo   },
	} )

	local msg = lx.gs.rank.msg.CGetRank( { ranktype = cfg.bonus.RankType.ARENA, rankstart = 1, rankend = 100 })
	Network.send(msg)
end

--local springPanel

local function show(params)
	--printyellow("aaaaaaaaaaa")
	RefreshLeft()
	RefreshRight()

	--springPanel = fields.UIScrollView_Player.gameObject:GetComponent("SpringPanel")
	--if springPanel == nil then
		--springPanel = fields.UIScrollView_Player.gameObject:AddComponent("SpringPanel")
	--end
	--EventHelper.SetPress
   -- fields.UIScrollView_Layer.onStoppedMoving = function()
   --     LuaHelper.CenterOnIndex(fields.UIList_Layer,currentIndex)
   -- end
end

local function hide()
	--printyellow("[[[[[[[[[[[[]]]]]]]]]]]]")
    Network.remove_listeners(listenerIds)
	for i = 1, 3 do
		if ArenaTopRoles[i] and ArenaTopRoles[i].m_Role then
			ArenaTopRoles[i].m_Role:release()
		end
	end
end

local function refresh(params)

end

local function destroy()

end


local function update()
	for i = 1, 3 do
		if ArenaTopRoles[i] and ArenaTopRoles[i].m_Role then
			local role = ArenaTopRoles[i].m_Role
			if role.m_Object then
				role.m_Avatar:Update()
			end
		end
	end
	--if springPanel then
	--	local currentTarget = springPanel.target
	--	printyellow(currentTarget.y)
	--end
    fields.UIScrollView_Player.onStoppedMoving = function()
		local currentPos = 0 - LuaHelper.GetCenterOnIndex(fields.UIList_Player)
		--printyellow("currentPos",currentPos)
		--printyellow("currentIndex",currentIndex)
		local currentIndex = math.floor( currentPos + 0.5 )
		if currentIndex < 0 then
			currentIndex = 0
		end
		if currentIndex > 2 then
			currentIndex = 2
		end
		--printyellow("currentIndex2",currentIndex)
        LuaHelper.CenterOnIndex(fields.UIList_Player, currentIndex)
    end
	-- local currentPos = LuaHelper.GetCenterOnIndex(fields.UIList_Player)
	-- local currentIndex = math.floor(currentPos + 0.1)
	-- local deltaPos =  currentPos - currentIndex
	-- printyellow("currentPos ", currentPos)
	-- if deltaPos > 0.5 then
	-- 	LuaHelper.CenterOnIndex(fields.UIList_Player, currentIndex+1.5)
	-- else
	-- 	LuaHelper.CenterOnIndex(fields.UIList_Player, currentIndex+0.5)
	-- end
	--local currentIndex = fields.UIList_Player:GetMinCenterItemIndexVertical()
--	fields.UIList_Player:RecenterOnListItem(3)
--	printyellow("currentIndex ", currentIndex)


	--newIndex = math.floor(+0.5)
end

local function init(params)
	name, gameObject, fields = unpack(params)
    --fields.UIScrollView_Layer.onStoppedMoving = function()
    --    LuaHelper.CenterOnIndex(fields.UIList_Layer,currentIndex)
    --end
end

return {
	init 		= init,
	show 		= show,
	showdialog 	= showdialog,
	hide 		= hide,
	update 		= update,
	destroy 	= destroy,
	refresh 	= refresh,
}
