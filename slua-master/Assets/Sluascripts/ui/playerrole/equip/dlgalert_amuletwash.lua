local require           = require
local unpack            = unpack
local print             = print
local format            = string.format
local UIManager         = require("uimanager")
local network           = require("network")
local SkillManager      = require("character.skill.skillmanager")
local ConfigManager     = require("cfg.configmanager")
local BagManager        = require("character.bagmanager")
local CheckCmd          = require("common.checkcmd")
local ItemManager       = require("item.itemmanager")
local PlayerRole        = require("character.playerrole")
local EventHelper       = UIEventListenerHelper
local AmuletManager     = require("ui.playerrole.equip.amuletmanager")
local LimitTimeManager  = require("limittimemanager")


local gameObject
local name
local fields

local g_SelectedPageIndex = 1
local g_PagesInfo
local g_WashedSkillList

local LEVEL2QUALITY = 
{
	[1] = cfg.item.EItemColor.GREEN,
	[2] = cfg.item.EItemColor.BLUE,
	[3] = cfg.item.EItemColor.PURPLE,
	[4] = cfg.item.EItemColor.ORANGE,
	[5] = cfg.item.EItemColor.RED,
}

local function InitOriginalSkillList()
	if fields.UIList_OriginalSkills.Count == 0 then
		-- 目前6个技能属性
		for i = 1, 6 do
			local listItem = fields.UIList_OriginalSkills:AddListItem()
		end
	end
end

local function InitRandomSkillList()
	if fields.UIList_RandomSkills.Count == 0 then
		-- 目前6个技能属性
		for i = 1, 6 do
			local listItem = fields.UIList_RandomSkills:AddListItem()
			-- skill 特效
			local skillEffectObj = GameObject.Instantiate(fields.UIGroup_AmuletWash.gameObject)
			local point = listItem.gameObject.transform:Find("ParticleSystem_MountPoint")
			skillEffectObj.transform.parent = point.transform
			skillEffectObj.transform.localScale = Vector3.one
			skillEffectObj.transform.localPosition = Vector3.zero
		end
	end
end

local function ResetOriginalSkillList(pageIndex)
	local pageData = g_PagesInfo[pageIndex]
	for i = 1, 6 do
		local skillData = pageData.SkillAttrs[i]
		local listItem = fields.UIList_OriginalSkills:GetItemByIndex(i - 1)
		-- 本门派品质颜色字体
		if PlayerRole:Instance().m_Profession == skillData.profession then
			colorutil.SetQualityColorText(listItem.Controls["UILabel_OriginalSkillName"],LEVEL2QUALITY[skillData.addLevel],(skillData.data):GetSkillName())
			colorutil.SetQualityColorText(listItem.Controls["UILabel_OriginalSkillLV"],LEVEL2QUALITY[skillData.addLevel],"LV+" .. skillData.addLevel)
		else
			-- 其他门派灰色字体
			colorutil.SetTextColor2Gray(listItem.Controls["UILabel_OriginalSkillName"],(skillData.data):GetSkillName())
			colorutil.SetTextColor2Gray(listItem.Controls["UILabel_OriginalSkillLV"],"LV+" .. skillData.addLevel)
		end
		if skillData.bLocked then
			fields.UIList_OriginalSkills:SetSelectedIndex(i - 1)
		else
			fields.UIList_OriginalSkills:SetUnSelectedIndex(i - 1)
		end
	end
end

local function ResetRandomSkillList(skillList)
	for i = 1, 6 do
		local skillData = skillList[i]
		local listItem = fields.UIList_RandomSkills:GetItemByIndex(i - 1)
		if not skillData.bLocked then 
			local skillEffectObj = listItem.gameObject.transform:Find("ParticleSystem_MountPoint/UIGroup_AmuletWash(Clone)")
			UIManager.PlayUIParticleSystem(skillEffectObj.gameObject)
		end

		-- 本门派品质颜色字体
		if PlayerRole:Instance().m_Profession == skillData.profession then
			colorutil.SetQualityColorText(listItem.Controls["UILabel_RandomSkillName"],LEVEL2QUALITY[skillData.addLevel],(skillData.data):GetSkillName())
			colorutil.SetQualityColorText(listItem.Controls["UILabel_RandomSkillLV"],LEVEL2QUALITY[skillData.addLevel],"LV+" .. skillData.addLevel)
		else
			-- 其他门派灰色字体
			colorutil.SetTextColor2Gray(listItem.Controls["UILabel_RandomSkillName"],(skillData.data):GetSkillName())
			colorutil.SetTextColor2Gray(listItem.Controls["UILabel_RandomSkillLV"],"LV+" .. skillData.addLevel)
		end
	end

end

local function ClearOriginalSkillList()
	fields.UIList_OriginalSkills:Clear()
end

local function ClearRandomSkillList()
	fields.UIList_RandomSkills:Clear()
end

local function RefreshLockCost()
	local lockCostList =(ConfigManager.getConfig("amuletconfig")).lockcost
	local selectedListItems = fields.UIList_OriginalSkills:GetSelectedItems()
	local costItemId =(ConfigManager.getConfig("amuletconfig")).lockitemid

	local costItemsInBag = BagManager.GetItemById(costItemId)
	local totalCostItemNumInBag = 0
	for _, item in ipairs(costItemsInBag) do
		totalCostItemNumInBag = totalCostItemNumInBag + item:GetNumber()
	end

	if selectedListItems.Length == 0 then
		fields.UILabel_TotalLockCost.text = totalCostItemNumInBag .. "/0"
	else
		local costItemNum = lockCostList[selectedListItems.Length].amount
		fields.UILabel_TotalLockCost.text = totalCostItemNumInBag .. "/" .. costItemNum
	end
end

local function RefreshWashCost()

	local limitInfo =(ConfigManager.getConfig("amuletconfig")).washcost
	if limitInfo.class ~= "cfg.cmd.condition.VipLimits2" then
		-- 设置默认信息
		local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.XuNiBi,nil,0)
		fields.UILabel_TotalWashCost.text = currency:GetNumber()
		fields.UISprite_WashCostMoneyIcon.spriteName = currency:GetIconName()
		logError("config class error!")
		return
	end
	local roleVipLevel = PlayerRole:Instance().m_VipLevel
	local idx = math.min(roleVipLevel+1,#(limitInfo.entertimes))
	local maxWashTime = limitInfo.entertimes[idx]
	local usedWashTime = LimitTimeManager.GetDayLimitTime(cfg.cmd.ConfigId.AMULET_WASH, 0)
	local nextWashTime = usedWashTime + 1

	if maxWashTime ~= cfg.Const.NULL and nextWashTime > maxWashTime then
	end
	local costIndex = math.min(#(limitInfo.costs),nextWashTime)
	
	local currency = ItemManager.GetCurrencyData(limitInfo.costs[costIndex])
	fields.UILabel_TotalWashCost.text = currency:GetNumber()
	fields.UISprite_WashCostMoneyIcon.spriteName = currency:GetIconName()
end

local function destroy()
	-- print(name, "destroy")
end

local function show(params)
	-- print(name, "show")
	g_PagesInfo = AmuletManager.GetPagesInfo()
	g_SelectedPageIndex = params.pageIndex
	g_WashedSkillList = params.washedSkillList

	-- 原属性列表
    InitOriginalSkillList()
    ResetOriginalSkillList(g_SelectedPageIndex)

	-- 洗炼后属性列表
    InitRandomSkillList()
    ResetRandomSkillList(g_WashedSkillList)
	RefreshLockCost()
	RefreshWashCost()
end

local function hide()
	-- print(name, "hide")
	ClearOriginalSkillList()
	ClearRandomSkillList()
end

local function refresh(params)
	-- print(name, "refresh")

	g_PagesInfo = AmuletManager.GetPagesInfo()
	g_SelectedPageIndex = params.pageIndex
	g_WashedSkillList = params.washedSkillList

	ResetRandomSkillList(g_WashedSkillList)
	RefreshLockCost()
	RefreshWashCost()
end

local function update()
	-- print(name, "update")
end

local function init(params)
	-- name, gameObject, fields = unpack(params)
	fields = params
	-- 技能加锁
    fields.UIList_OriginalSkills.IsMultiCheckBox = true

	EventHelper.SetClick(fields.UIButton_WashOneMoreTry, function()
		-- print("Button wash one more clicked")
		-- 检查消耗道具和钱币是否足够
		local lockCost = nil
		local washCost = nil

		local lockCostList =(ConfigManager.getConfig("amuletconfig")).lockcost
		local selectedListItems = fields.UIList_OriginalSkills:GetSelectedItems()
		if selectedListItems.Length ~= 0 then
			lockCost = lockCostList[selectedListItems.Length]
		end

		local washCost =(ConfigManager.getConfig("amuletconfig")).washcost

		local validate1,validate2 = true,true
		validate1 = CheckCmd.CheckData( { moduleid = cfg.cmd.ConfigId.AMULET_WASH ,cmdid = 0,data = washCost, num = 1, showsysteminfo = true })
		
		if lockCost then 
			validate2 = CheckCmd.CheckData( { moduleid = cfg.cmd.ConfigId.AMULET_WASH ,cmdid = 0,data = lockCost, num = 1, showsysteminfo = true })
		end

		if validate1 and validate2 then
			local msg = lx.gs.amulet.CWashAmulet( { pageid = g_SelectedPageIndex })
			network.send(msg)
		else
			if not validate1 then
				-- 钱币不足
				if washCost.class ~= "cfg.cmd.condition.VipLimits2" then
					return
				end
				local roleVipLevel = PlayerRole:Instance().m_VipLevel
				local idx = math.min(roleVipLevel+1,#(washCost.entertimes))
				local maxWashTime  = washCost.entertimes[idx]
				local usedWashTime = LimitTimeManager.GetDayLimitTime(cfg.cmd.ConfigId.AMULET_WASH, 0)
				local nextWashTime = usedWashTime + 1

				if maxWashTime ~= cfg.Const.NULL and nextWashTime > maxWashTime then
					return
				end
				local costIndex = math.min(#(washCost.costs),nextWashTime)
				local currency = ItemManager.GetCurrencyData(washCost.costs[costIndex])
				ItemManager.GetSource(currency:GetConfigId(),"common.dlgdialogbox_complex")
			elseif not validate2 and lockCost then 
				-- 培养丹不足
				ItemManager.GetSource(lockCost.itemid,"common.dlgdialogbox_complex")
			end
		end

	end )

	EventHelper.SetClick(fields.UIButton_Close, function()
		-- print("Button close clicked")
		-- 清除洗炼结果界面
		UIManager.ShowSystemFlyText(LocalString.AmuletWash_CancelWashResult)
		local msg = lx.gs.amulet.CCancelAmuletWashResult( { pageid = g_SelectedPageIndex })
		network.send(msg)
		UIManager.hide("dlgdialogbox_complex")
	end )

	EventHelper.SetClick(fields.UIButton_Cancel, function()
		-- print("Button cansel clicked")
		UIManager.ShowSystemFlyText(LocalString.AmuletWash_CancelWashResult)
		local msg = lx.gs.amulet.CCancelAmuletWashResult( { pageid = g_SelectedPageIndex })
		network.send(msg)
	end )

	EventHelper.SetClick(fields.UIButton_ConfirmWashResult, function()
		-- print("Button wash clicked")
		local msg = lx.gs.amulet.CApplyAmuletWashResult( { pageid = g_SelectedPageIndex })
		network.send(msg)
	end )

	EventHelper.SetListSelect(fields.UIList_OriginalSkills, function(listItem)
		-- print("original skill list clicked")
		local selectedItems = fields.UIList_OriginalSkills:GetSelectedItems()
		if selectedItems.Length > 5 then
			UIManager.ShowSystemFlyText(LocalString.AmuletWash_MaxLockSkillNum)
			fields.UIList_OriginalSkills:SetUnSelectedIndex(listItem.Index)
			return
		end
		RefreshLockCost()
		local msg = lx.gs.amulet.CLockAmulet( { pageid = g_SelectedPageIndex, amuletid = (listItem.Index + 1) })
		network.send(msg)
	end )

	EventHelper.SetListUnSelect(fields.UIList_OriginalSkills, function(listItem)
		-- print("original skill list unselected")
		RefreshLockCost()
		local msg = lx.gs.amulet.CUnLockAmulet( { pageid = g_SelectedPageIndex, amuletid = (listItem.Index + 1) })
		network.send(msg)
	end )

end

return {
	init    = init,
	show    = show,
	hide    = hide,
	update  = update,
	destroy = destroy,
	refresh = refresh,
}

