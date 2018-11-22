local require          = require
local unpack           = unpack
local print            = print
local format           = string.format
local logError         = logError
local math             = math
local UIManager        = require("uimanager")
local network          = require("network")
local Player           = require("character.player")
local PlayerRole       = require("character.playerrole")
local ConfigManager    = require("cfg.configmanager")
local DefineEnum       = require("defineenum")
local HumanoidAvatar   = require "character.avatar.humanoidavatar"
local ItemManager      = require("item.itemmanager")
local ItemIntroduct    = require("item.itemintroduction")
local BonusManager     = require("item.bonusmanager")
local LimitTimeManager = require("limittimemanager")
local gameevent		   = require("gameevent")
local RankManager      = require("ui.rank.rankmanager")
local TimeUtils		   = require("common.timeutils")
local EventHelper      = UIEventListenerHelper


-- 仅用于Rank List Type选择
local INDEX2TYPE =
{
	[0] = cfg.bonus.RankType.COMBAT_POWER,
	[1] = cfg.bonus.RankType.LEVEL,
	[2] = cfg.bonus.RankType.PET,
	[3] = cfg.bonus.RankType.FABAO,
	[4] = cfg.bonus.RankType.FAMILY,
	[5] = cfg.bonus.RankType.XUNIBI,
	[6] = cfg.bonus.RankType.CLIMB_TOWER,
	[7] = cfg.bonus.RankType.FLOWER,
    [8] = cfg.bonus.RankType.WEEK_FLOWER,
}

local TYPE2INDEX = 
{
	[cfg.bonus.RankType.COMBAT_POWER] = 0,
	[cfg.bonus.RankType.LEVEL]		  = 1,
	[cfg.bonus.RankType.PET]		  = 2,
	[cfg.bonus.RankType.FABAO]		  = 3,
	[cfg.bonus.RankType.FAMILY]		  = 4,
	[cfg.bonus.RankType.XUNIBI]		  = 5,
	[cfg.bonus.RankType.CLIMB_TOWER]  = 6,
	[cfg.bonus.RankType.FLOWER]		  = 7,
    [cfg.bonus.RankType.WEEK_FLOWER]  = 8,
}


local ranksData = { }

local name
local gameObject
local fields

local g_Player
local g_SelectedRankType
local g_SelectedPlayer
local g_EvnetId

local listenerIds

local function pairsByRank(list)
	-- 默认降序
	local key = { }
	local map = { }
	for _, rank in pairs(list) do
		key[#key + 1] = rank.requirerank
		map[rank.requirerank] = rank.bonuslist
	end
	table.sort(key)
	local i = 0
	return function()
		i = i + 1
		return key[i], map[key[i]]
	end
end

local function RankListItemRefresh(listItem, wrapIndex, realIndex)
	listItem.Controls["UISprite_NO1"].gameObject:SetActive(realIndex == 1)
	listItem.Controls["UISprite_NO2"].gameObject:SetActive(realIndex == 2)
	listItem.Controls["UISprite_NO3"].gameObject:SetActive(realIndex == 3)

	listItem:SetText("UILabel_Ranking", realIndex)
	listItem:SetText("UILabel_Name", ranksData[g_SelectedRankType].m_Ranks[realIndex].m_RoleName)

	local rankValue1 = ranksData[g_SelectedRankType].m_Ranks[realIndex].m_RankValue1
	local rankValue2 = ranksData[g_SelectedRankType].m_Ranks[realIndex].m_RankValue2

	if g_SelectedRankType == cfg.bonus.RankType.CLIMB_TOWER then 
		local climbTime = TimeUtils.getDateTime(rankValue2)
		local rankText = format(LocalString.Ranklist_ClimbTowerValue,rankValue1,climbTime.minutes,climbTime.seconds)
		listItem:SetText("UILabel_RankValue", rankText)
	else 
		listItem:SetText("UILabel_RankValue", rankValue1)
	end

	EventHelper.SetClick(listItem, function()
		-- print(format("ListItem Index: %u click", realIndex))
		if ranksData[g_SelectedRankType] then
			local roleId =(ranksData[g_SelectedRankType].m_Ranks[realIndex]).m_RoleId
			if roleId then
				local msg = lx.gs.role.msg.CGetRoleInfo( { roleid = roleId })
				network.send(msg)
			end
		end
	end )
end


local function ShowRewardItems(params,fields)
    fields.UILabel_Title.text = format(LocalString.Ranklist_RewardTitle,LocalString.Ranklist_RankTypeName[g_SelectedRankType])
	local rankBonusData = ConfigManager.getConfigData("rankbonus", g_SelectedRankType)
	if not rankBonusData then 
		return 
	end
	local rankBonusList = rankBonusData.bonuslist
	fields.UIList_RewardGroups:ResetListCount(#rankBonusList)
	local preRank = 0
	local listIndex = 0
	for requireRank, itemList in pairsByRank(rankBonusList) do
		local listItem = fields.UIList_RewardGroups:GetItemByIndex(listIndex)
        listItem.Controls["UIGroup_Resource"].gameObject:SetActive(false)

		if (requireRank - preRank) == 1 then
			listItem.Controls["UILabel_Line1"].text = format(LocalString.Ranklist_Ranking, requireRank)
		elseif (requireRank - preRank) > 1 then
			listItem.Controls["UILabel_Line1"].text = format(LocalString.Ranklist_RankingInterval, preRank + 1, requireRank)
		end

		local rewardList = listItem.Controls["UIList_Rewards"]
		local bonusItems = BonusManager.GetItemsOfSingleBonus(itemList)
		rewardList:ResetListCount(#bonusItems)
		for itemIdx, bonusItem in ipairs(bonusItems) do
			local rewardListItem = rewardList:GetItemByIndex(itemIdx-1)
			rewardListItem.Controls["UILabel_ItemName"].text = bonusItem:GetName()
			BonusManager.SetRewardItem(rewardListItem,bonusItem)
		end
		listIndex = listIndex + 1
		preRank = requireRank
	end
	fields.UILabel_Desc.gameObject:SetActive(true)
    if g_SelectedRankType == cfg.bonus.RankType.WEEK_FLOWER then 
        fields.UILabel_Desc.text = LocalString.Ranklist_RankUpdateDesc_WeekFlower
    else
	    fields.UILabel_Desc.text = LocalString.Ranklist_RankUpdateDesc
    end
end

local function OnModelLoaded(go)
	if not g_Player and not g_Player.m_Object then return end

	local playerTrans = g_Player.m_Object.transform
	playerTrans.parent = fields.UITexture_PlayerModel.transform
	playerTrans.localScale = Vector3.one * 155
	playerTrans.localPosition = Vector3(-5, -200, -250)
	--playerTrans.localRotation = Vector3.up * 180
    playerTrans.localEulerAngles = Vector3(-90, 0, 0)
	ExtendedGameObject.SetLayerRecursively(g_Player.m_Object, define.Layer.LayerUICharacter)
end

local function RefreshModel(roleId, profession, gender, bShowHeadInfo, dress, equips,isPlayerRole)
	if g_Player then g_Player:release() end
	g_Player = Player:new(isPlayerRole)
	g_Player.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
	g_Player:RegisterOnLoaded(OnModelLoaded)
	g_Player:init(roleId, profession, gender,bShowHeadInfo,dress,equips,nil,0.8)
end

local function RefreshPlayerInfoText(level, name, combatPower)
	fields.UILabel_PlayerLV.text = level or 0
	fields.UILabel_PlayerName.text = name or ""
	fields.UILabel_CombatPower.text = combatPower or 0
end

-- 1.以今天排名为准来判断是否上榜
local function RefreshCurRank()
	local rankConfigData = ConfigManager.getConfigData("rank", g_SelectedRankType)
	if ranksData[g_SelectedRankType].m_CurRank > 0 and ranksData[g_SelectedRankType].m_CurRank <= rankConfigData.ranksize then
		-- 今天此时上榜
		fields.UILabel_PlayerRank.text = ranksData[g_SelectedRankType].m_CurRank
	else
		-- 今天此时未上榜
		fields.UILabel_PlayerRank.text = LocalString.Ranklist_NotInRanklist
	end
end
-- 2.以今天0时前(昨天最后排名)排名为准来判断是否可以领取奖励
local function RefreshRewardInfo()
	local rankConfigData = ConfigManager.getConfigData("rank", g_SelectedRankType)
	if ranksData[g_SelectedRankType].m_PreRank > 0 and ranksData[g_SelectedRankType].m_PreRank <= rankConfigData.ranksize then
		-- 昨天上榜
		local getRewardTime = LimitTimeManager.GetDayLimitTime(cfg.cmd.ConfigId.RANK, g_SelectedRankType)
		-- 即使上过榜，每天限制领取一次,有的榜单没有奖励，具体查看配置
		if getRewardTime == 0 then
			-- 未领取奖励
			local bonusItems = RankManager.GetGeneralRankBonus(g_SelectedRankType, ranksData[g_SelectedRankType].m_PreRank)
			fields.UIButton_GetRewards.isEnabled =(#bonusItems ~= 0)
		else 
			-- 领取过奖励
			fields.UIButton_GetRewards.isEnabled = false
		end
	else
		-- 昨天未上榜
		fields.UIButton_GetRewards.isEnabled = false
	end
end
-- 刷新当前选择的排行榜
local function RefreshRanklist()
	-- 重新获取全部排行榜数据
	ranksData = RankManager.GetRankData()

	local roleId = (ranksData[g_SelectedRankType].m_Ranks[1]) and (ranksData[g_SelectedRankType].m_Ranks[1]).m_RoleId
	if roleId then
		local msg = lx.gs.role.msg.CGetRoleInfo( { roleid = roleId })
		network.send(msg)
	else
		-- 默认没有信息
		if g_Player then 
			g_Player:release() 
			g_Player = nil
		end
		RefreshPlayerInfoText()
	end
	local wrapList = fields.UIList_Rank.gameObject:GetComponent("UIWrapContentList")
	EventHelper.SetWrapListRefresh(wrapList, RankListItemRefresh)
	wrapList:SetDataCount(getn(ranksData[g_SelectedRankType].m_Ranks) or 0)
	wrapList:CenterOnIndex(0)

	local rankConfigData = ConfigManager.getConfigData("rank", g_SelectedRankType)
	fields.UILabel_RankName.text = LocalString.Ranklist_RankName[g_SelectedRankType]
	fields.UILabel_RankPlayerName.text = LocalString.RankList_RankPlayerName[g_SelectedRankType]
	--设置排行榜刷新频率
	fields.UILabel_RankRefreshRate.text = format(LocalString.Ranklist_RefreshRate,rankConfigData.refreshrate/60)
end

local function OnMsg_SGetRoleInfo(msg)
	-- print("OnMsg_SGetRoleInfo")
	if not UIManager.isshow("rank.dlgranklist") then 
		return 
	end
	local roleEquips = { }
	-- 转换结构
	for _,equip in pairs(msg.roleinfo.equips) do
		local serverMsg = lx.gs.equip.Equip({
					equipid		= 0,
					modelid		= equip.modelid,
					position	= 0,
					expiretime	= 0,
					isbind		= 1,
					normalequip = equip.normalequip,
					accessory	= equip.accessory,
					})
		local tempEquip = ItemManager.CreateItemBaseById(equip.modelid,serverMsg,1)
		if tempEquip and tempEquip:IsMainEquip() then 
			roleEquips[#roleEquips + 1] = map.msg.EquipBrief({equipkey = tempEquip:GetConfigId(), anneallevel = tempEquip:GetAnnealLevel(),perfuselevel = tempEquip:GetPerfuseLevel()})
		end
	end
	RefreshModel(msg.roleinfo.roleid, msg.roleinfo.profession,msg.roleinfo.gender,false,msg.roleinfo.dressid,roleEquips,false)
	g_Player.m_Name             = msg.roleinfo.name
    g_Player.m_Level            = msg.roleinfo.level
    g_Player.m_VipLevel         = msg.roleinfo.viplevel
    g_Player.m_Power            = msg.roleinfo.combatpower
    g_Player.m_FamilyName       = msg.roleinfo.familyname
    g_Player.m_LoverName        = msg.roleinfo.lovername
	g_Player.m_FamilyJob        = msg.roleinfo.familyjob
    g_Player.m_FamilyLevel      = msg.roleinfo.familylevel
	g_Player.m_LastOnlineTime   = msg.roleinfo.lastonlinetime
	g_Player:ChangeAttr(msg.roleinfo.fightattrs)
    g_Player:ChangeTitle(msg.roleinfo.title)
	RefreshPlayerInfoText(g_Player:GetLevel(), g_Player:GetName(), g_Player:GetPower())
end
-- engregion onmsg

-- 刷新红点
local function RefreshRedDot()
    for rankType, tabIndex in pairs(TYPE2INDEX) do
        local listItem = fields.UIList_RankType:GetItemByIndex(tabIndex)
        listItem.Controls["UISprite_Warning"].gameObject:SetActive(RankManager.UnReadType(rankType))
    end
end
local function destroy()
	if g_Player then
		g_Player:release()
		g_Player = nil
	end
end

local function show(params)
	-- print(name, "show")
	listenerIds = network.add_listeners( {
		{ "lx.gs.role.msg.SGetRoleInfo", OnMsg_SGetRoleInfo },
	} )
	if params and params.rankType then
		g_SelectedRankType = params.rankType
	else
		g_SelectedRankType = cfg.bonus.RankType.COMBAT_POWER
	end

	fields.UIList_RankType:SetSelectedIndex(TYPE2INDEX[g_SelectedRankType])
	
	-- 增加回调事件
	g_EvnetId = gameevent.evt_limitchange:add(function()
		local getRewardTime = LimitTimeManager.GetDayLimitTime(cfg.cmd.ConfigId.RANK, g_SelectedRankType)
		-- 即使上过榜，每天限制领取一次
		if getRewardTime >= 1 then
			fields.UIButton_GetRewards.isEnabled = false
			RefreshRedDot()
		end
	end)
end

local function refresh(params)
	-- print(name, "refresh")
	RefreshRanklist()
	RefreshCurRank()
	RefreshRewardInfo()
	-- 刷新红点提示
	RefreshRedDot()
end

local function hide()
	-- print(name, "hide")
	network.remove_listeners(listenerIds)
	gameevent.evt_limitchange:remove(g_EvnetId)
	if g_Player then
		g_Player:release()
		g_Player = nil
	end
end

local function update()
	-- print(name, "update")
	if g_Player and g_Player.m_Object and g_Player.m_Avatar then
		g_Player.m_Avatar:Update()
	end
end

local function init(params)
	name, gameObject, fields = unpack(params)

	-- 初始化rank列表榜名
	for i = 0, fields.UIList_RankType.Count-1 do
		local listItem = fields.UIList_RankType:GetItemByIndex(i)
		listItem:SetText(format("UILabel_%02d",i+1), LocalString.Ranklist_RankTypeName[INDEX2TYPE[i]])
	end

	EventHelper.SetDrag(fields.UITexture_PlayerModel, function(go, delta)
		if g_Player and g_Player.m_Object then
			local vecRotate = Vector3(0, 0, -delta.x)
			g_Player.m_Object.transform.localEulerAngles = g_Player.m_Object.transform.localEulerAngles + vecRotate
		end
	end )

	EventHelper.SetListClick(fields.UIList_RankType, function(listItem)
		g_SelectedRankType = INDEX2TYPE[listItem.Index]
		refresh()
	end )
	EventHelper.SetClick(fields.UIButton_GetRewards, function()
		local bonusItems = { }
		bonusItems = RankManager.GetGeneralRankBonus(g_SelectedRankType, ranksData[g_SelectedRankType].m_PreRank)
		-- 确认领取按钮回调
		local ConfirmToGetRewardFunc = function()
			local msg = lx.gs.leaderboard.msg.CGetRankReward( { ranktype = g_SelectedRankType })
			network.send(msg)
			UIManager.hide("common.dlgdialogbox_reward")
		end
		local params = { }
		params.type = 1
		params.items = bonusItems
		params.title = format(LocalString.Ranklist_RankTitle, LocalString.Ranklist_RankName[g_SelectedRankType], ranksData[g_SelectedRankType].m_PreRank)
		params.buttons =
		{
			{ text = LocalString.Ranklist_ConfirmToGetRewards, callBackFunc = ConfirmToGetRewardFunc },

		}
		local DlgAlert_ShowRewards = require("ui.dlgalert_showrewards")
		params.callBackFunc = function(p, f) DlgAlert_ShowRewards.init(f); DlgAlert_ShowRewards.show(p) end
		UIManager.show("common.dlgdialogbox_reward", params)

	end )

	EventHelper.SetClick(fields.UIButton_CheckRoleDetails, function()
		-- print("UIButton_GetRewards cliked")
		if g_Player then
			UIManager.showdialog("otherplayer.dlgotherroledetails", { roleId = g_Player.m_Id })
		end
	end )

	EventHelper.SetClick(fields.UIButton_RewardIntroduction,function()
		local rankBonusData = ConfigManager.getConfigData("rankbonus", g_SelectedRankType)
		if not rankBonusData then 
			UIManager.ShowSystemFlyText(format(LocalString.Ranklist_NoReward,LocalString.Ranklist_RankTypeName[g_SelectedRankType]))
			return 
		end
		UIManager.show("common.dlgdialogbox_reward",{ type=0,callBackFunc = ShowRewardItems })
	end )
end

return {
	init              = init,
	show              = show,
	hide              = hide,
	update            = update,
	destroy           = destroy,
	refresh           = refresh,
	RefreshRanklist   = RefreshRanklist,
	RefreshCurRank    = RefreshCurRank,
	RefreshRewardInfo = RefreshRewardInfo,
}
