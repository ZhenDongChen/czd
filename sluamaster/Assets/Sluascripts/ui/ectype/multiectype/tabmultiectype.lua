local Unpack = unpack
local string = string
local table = table
local EventHelper = UIEventListenerHelper
local ConfigManager = require("cfg.configmanager")
local UIManager = require("uimanager")
local BonusManager = require("item.bonusmanager")
local MultiEctypeManager=require"ui.ectype.multiectype.multiectypemanager"
local PlayerRole = require "character.playerrole"
local TeamManager = require "ui.team.teammanager"
local ItemManager = require "item.itemmanager"
local network = require "network"
local gameObject
local name
local fields

local EctypeDataManager
local EctypeDlgManager
local cur_section
local num_star

local function NumToCharacter(num)
    if num == 1 then
		-- printyellow(num)
        return "简单"
    elseif num == 2 then
        return "普通"
    elseif num == 3 then
        return "困难"
	else
		return ""
	end
end


local function destroy()
end

local function show(params)
	local matchinglefttime = MultiEctypeManager.GetStoryEctypeLeftTime()

	if matchinglefttime and matchinglefttime ~= 0  then
		UIManager.show("ectype.multiectype.dlgmultiectypematching",{lefttime = MultiEctypeManager.GetStoryEctypeLeftTime() , roleinfos = MultiEctypeManager.GetRoleInfos() ,title = MultiEctypeManager.GetTitle()})

	end

	if params and params.matchingbutton then
		fields.UIList_Level:SetSelectedIndex(params.index)

	end
end

local function hide()
	
end

local function ShowNotLeader()
	
end

local function SetSectionStars(num)--设置当前选中章节的星的个数
	local index
	fields.UIList_Star:Clear()
	for index = 1, num do
		fields.UIList_Star:AddListItem()
	end
	for index = num + 1, 3 do
		local listItem = fields.UIList_Star:AddListItem()
		listItem.Controls["UISprite_Star01"].gameObject:SetActive(false)
	end
end

local function SetStars(list,num)  --设置左边每一小节的三星个数
	list:Clear()
	local index
	for  index = 1, num do
		list:AddListItem()
	end
	for  index = num + 1 ,3 do
		local listItem = list:AddListItem()
		listItem.Controls["UISprite_Star01"].gameObject:SetActive(false)
	end

end


local function GetLimitTime(section)

	return section.daylimit.num

end

local function SingleSignUp(params)
	MultiEctypeManager.SendCLeaveTeamAndEnrollSingle(params.id)
end

local function GetEctypeById(id)
	if not id then
		return nil
	end
	local teamconfig = ConfigManager.getConfig("teamstoryectype")
	for _,ectype in pairs(teamconfig) do
		if ectype.id == id then
			return ectype
		end
	end
	return nil
end





local function CanSendScroll(section)
		if PlayerRole:Instance().m_Level < section.openlevel.level  then    --等级不够
			UIManager.show("dlgalert_reminder_singlebutton",{content = string.format(LocalString.MultiEctype_LessLevel,section.openlevel.level)})
			return false
		end

--		if MultiEctypeManager.GetRestTime(section) == 0 then  
--			UIManager.show("dlgalert_reminder_singlebutton",{content = LocalString.MultiEctype_UseTimeExpire})
--			return 	false
--		end

		local starMatrix = MultiEctypeManager.GetStarMatrix()
		local prevEctype = GetEctypeById(section.preectypeid)  --前置副本未完成

		if not prevEctype or starMatrix[prevEctype.groupid] and starMatrix[prevEctype.groupid][prevEctype.sectionid] then --没有前置关或前置关已经完成
			return true
		else
			local content = string.format(LocalString.MultiEctype_NeedToComplete,prevEctype.storyname .."·"..NumToCharacter(prevEctype.difficulty))

			UIManager.show("dlgalert_reminder_singlebutton",{content = content})
			return false
		end
		return true
end

local function RefreshRightButton(section)
	EventHelper.SetClick(fields.UIButton_Challenge,function() --单人
		if not CanSendScroll(section) then
			return
		end
		
		if PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.TiLi) < section.costtili.amount and MultiEctypeManager.GetRestTime(section) ~= 0 then
			return  require "ui.ectype.storyectype.ectypedlgmanager".ShowReminderTiLi()
		end



		if TeamManager.IsInTeam() then									--玩家处于组队状态
			--您当前处于组队状态，单人报名会离开队伍，是否继续报名。（确定，取消）
			local starMatrix = MultiEctypeManager.GetStarMatrix()
			local prevEctype = GetEctypeById(section.preectypeid)
--			if not prevEctype or starMatrix[prevEctype.groupid] and starMatrix[prevEctype.groupid][prevEctype.sectionid] then --没有前置关或前置关已经完成
----				printyellow("TeamManager.IsInTeam()")
				UIManager.show("dlgalert_reminder",{content = LocalString.MultiEctype_TeamSignTip,callBackFunc = SingleSignUp,id = section.id})
--			else
--				local content = string.format(LocalString.MultiEctype_NeedToComplete,prevEctype.storyname .."·"..NumToCharacter(prevEctype.difficulty))
--				UIManager.show("dlgalert_reminder_singlebutton",{content = content})
--			end
		else
			--即给玩家匹配，匹配对应的玩家



				local roleinfos ={}
				local roleinfo = {}
				roleinfo.roleid = PlayerRole:Instance().m_Id
				table.insert(roleinfos,roleinfo)
				local title = cur_section.storyname .."·"..NumToCharacter(cur_section.difficulty)
				MultiEctypeManager.SendCEnrollMultiStoryEctype( lx.gs.map.msg.CEnrollMultiStoryEctype.SINGLE,section.id)



		end
	end)
	EventHelper.SetClick(fields.UIButton_SweepSixTime,function() --组队
		if not CanSendScroll(section) then
			return
		end
		if PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.TiLi) < section.costtili.amount and MultiEctypeManager.GetRestTime(section) ~= 0  then
			return  require "ui.ectype.storyectype.ectypedlgmanager".ShowReminderTiLi()
		end
		if TeamManager.IsInTeam() then   --玩家处于组队状态
			if TeamManager.IsLeader(PlayerRole:Instance().m_Id) then	--是队长，满足条件则可以报名
				MultiEctypeManager.SendCEnrollMultiStoryEctype(lx.gs.map.msg.CEnrollMultiStoryEctype.TEAM, section.id)
			else                                                    	 --您当前不是队长，不能报名
                local starMatrix = MultiEctypeManager.GetStarMatrix()
				local prevEctype = GetEctypeById(section.preectypeid)

					UIManager.show("dlgalert_reminder_singlebutton",{content = LocalString.MultiEctype_NotLeader})

			end
		else
				--您当前处于非组队状态，请单击“单人”报名
				UIManager.show("dlgalert_reminder_singlebutton",{content = LocalString.MultiEctype_SingleSignTip})
		end
	end)

end

local function DisplayOneItem(section)
	costNum = section.costtili.amount
	fields.UILabel_RecommendedFCNum.text = section.battlepower or 0        --推荐战力

	if tonumber(fields.UILabel_RecommendedFCNum.text) > PlayerRole:Instance().m_Power then
		fields.UILabel_MyFC.text = colorutil.GetColorStr(colorutil.ColorType.Red,"(" ..PlayerRole:Instance().m_Power ..")") --我方战力
	else
		fields.UILabel_MyFC.text = colorutil.GetColorStr(colorutil.ColorType.Green,"(" ..PlayerRole:Instance().m_Power ..")")
	end

	fields.UILabel_Time.text =  section.timelimit/60 ..LocalString.Time.Min
	local bonuslist = BonusManager.GetItemsByBonusConfig(section.starbonus)
	fields.UILabel_RewardsNum.text = bonuslist[1]:GetNumber() or 0               --三星奖励
	fields.UILabel_StaminaNum.text= (section.costtili.amount or 0)..LocalString.Ectype_Dot


--	local droplist = BonusManager.GetItemsOfSingleBonus(section.ectypedrop) --通关奖励
	local showaward = section.showaward        --展示的奖品
	fields.UIList_SweepAwards:Clear()
	for k,v in pairs (showaward) do
		local list_item = fields.UIList_SweepAwards:AddListItem()
		local item = ItemManager.CreateItemBaseById(v)
		BonusManager.SetRewardItem(list_item,item)
	end

    fields.UILabel_SweepedNum.text = MultiEctypeManager.GetRestTime(section) .. "/" .. GetLimitTime(section)
	fields.UITexture_Ectype:SetIconTexture(section.bgmpic) --背景图片
	fields.UILabel_StoryDungeonName.text = section.storyname --章节名字
	fields.UILabel_StoryDes.text = section.introduction     --章节介绍
	local starmatrix = MultiEctypeManager.GetStarMatrix()
	local num = 0
	if  starmatrix and  starmatrix[section.groupid] and starmatrix[section.groupid][section.sectionid]then
		num = starmatrix[section.groupid][section.sectionid]
	end
	SetSectionStars(num)   --星的个数
	RefreshRightButton(section)  --按钮
end

local function SetUnReadDot(listItem,section)

	if MultiEctypeManager.HasRedDot(section) then

		listItem.Controls["UISprite_Tip"].gameObject:SetActive(true)
	else

		listItem.Controls["UISprite_Tip"].gameObject:SetActive(false)
	end
end

local function DisplayAll()
	local MultiInfo = ConfigManager.getConfig("teamstoryectype")
--	printyellow("DisplayAll")
--	printt(MultiInfo)
	local sortMultiInfo = {}
	for key,section in pairs(MultiInfo) do
		table.insert(sortMultiInfo,section)
	end
	--table.sort(MultiInfo,sortEctypeIDAsc)
	table.sort(sortMultiInfo, function(item1, item2) return(item1.id < item2.id) end)
	fields.UIList_Level:Clear()
	for key,section in ipairs (sortMultiInfo) do
		local listItem = fields.UIList_Level:AddListItem()

		listItem.Controls["UILabel_Theme"].text = section.storyname .."·"..NumToCharacter(section.difficulty)
		local liststar = listItem.Controls["UIList_Star"]
		local starmatrix = MultiEctypeManager.GetStarMatrix()
		local num = 0
		if  starmatrix and  starmatrix[section.groupid] and starmatrix[section.groupid][section.sectionid]then
			num = starmatrix[section.groupid][section.sectionid]
		end
		SetStars(liststar,num)
		SetUnReadDot(listItem,section)
		EventHelper.SetClick(listItem,function()

			cur_section = section
			MultiEctypeManager.SetCurSection(cur_section)
			MultiEctypeManager.SetCurEctypeId(cur_section.id)
			DisplayOneItem(section)
		end)
	end

end

local function refresh(params)

	local MultiInfo = ConfigManager.getConfig("teamstoryectype")
--	printyellow("DisplayAll")
--	printt(MultiInfo)
	local sortMultiInfo = {}
	for key,section in pairs(MultiInfo) do
		table.insert(sortMultiInfo,section)
	end
	--table.sort(MultiInfo,sortEctypeIDAsc)
	table.sort(sortMultiInfo, function(item1, item2) return(item1.id < item2.id) end)
	for k,v in ipairs(sortMultiInfo) do
		cur_section = v
		MultiEctypeManager.SetCurSection(cur_section)
		MultiEctypeManager.SetCurEctypeId(cur_section.id)
		DisplayOneItem(v)

		break
	end

    DisplayAll()
end

local function update()
end



local function init(params)
    name, gameObject, fields = Unpack(params)
	EctypeDataManager = require "ui.ectype.storyectype.ectypedatamanager"
    EctypeDlgManager  = require"ui.ectype.storyectype.ectypedlgmanager"
--	printyellow("init tabmultiectype")

end

local function uishowtype()
    return UIShowType.DestroyWhenHide
end
return {
  uishowtype = uishowtype,
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,

}
