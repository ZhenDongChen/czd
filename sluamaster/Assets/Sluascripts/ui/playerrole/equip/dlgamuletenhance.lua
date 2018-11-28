local require            = require
local unpack             = unpack
local print              = print
local format             = string.format
local UIManager          = require("uimanager")
local network            = require("network")
local SkillManager       = require("character.skill.skillmanager")
local LimitTimeManager   = require("limittimemanager")
local BagManager         = require("character.bagmanager")
local CheckCmd           = require("common.checkcmd")
local ItemManager        = require("item.itemmanager")
local ConfigManager      = require("cfg.configmanager")
local EventHelper        = UIEventListenerHelper
local PlayerRole         = require("character.playerrole")
local AmuletManager      = require("ui.playerrole.equip.amuletmanager")
local SkillData          = AmuletManager.SkillData
local AmuletPageData     = AmuletManager.AmuletPageData

local gameObject
local name
local fields
local listenerIds

local g_PagesInfo
local g_SelectedPageIndex = 1

local LEVEL2QUALITY = 
{
	[1] = cfg.item.EItemColor.GREEN,
	[2] = cfg.item.EItemColor.BLUE,
	[3] = cfg.item.EItemColor.PURPLE,
	[4] = cfg.item.EItemColor.ORANGE,
	[5] = cfg.item.EItemColor.RED,
}

local function SetPageTabList()
	if fields.UIList_PageTab.Count ~= 0 then 
		for i = 1,fields.UIList_PageTab.Count do
			local listItem = fields.UIList_PageTab:GetItemByIndex(i-1)
			local pageOpenLevel =(ConfigManager.getConfig("amuletconfig")).expandlevel
			local bPageOpened = (PlayerRole:Instance():GetLevel() >= pageOpenLevel[i])
			listItem.Controls["UISprite_Lock"].gameObject:SetActive(not bPageOpened)
			local toggle = listItem.transform:GetComponent(UIToggle)
			toggle.enabled = bPageOpened
		end
	end 
end

local function InitSkillList()
	if fields.UIList_AllSkills.Count == 0 then
		-- 目前6个技能属性
		for i = 1, 6 do
			local listItem = fields.UIList_AllSkills:AddListItem()
		end
	end
end

local function InitAmuletSkillAttrList()
	if fields.UIList_SkillLV.Count == 0 then
		-- 各个页的技能累加
		local skillAttrs = { }
		for pageIndex = 1, #g_PagesInfo do
			local pageData = g_PagesInfo[pageIndex]
			for _, skill in ipairs(pageData.SkillAttrs) do
				if not skillAttrs[skill.skillId] then
					skillAttrs[skill.skillId] = SkillData:new(skill.skillId, skill.profession, skill.addLevel, skill.bLocked)
				else
					skillAttrs[skill.skillId].addLevel = skillAttrs[skill.skillId].addLevel + skill.addLevel
				end
			end
		end
		for i = 1, getn(skillAttrs) do
			local listItem = fields.UIList_SkillLV:AddListItem()
		end
	end
end

local function ResetSkillList(pageIndex)
	local pageData = g_PagesInfo[pageIndex]

	for i = 1, 6 do
		local skillData = pageData.SkillAttrs[i]
		local listItem = fields.UIList_AllSkills:GetItemByIndex(i - 1)
		listItem:SetIconTexture((skillData.data):GetSkillIcon())

		if PlayerRole:Instance().m_Profession == skillData.profession then
			colorutil.SetQualityColorText(listItem.Controls["UILabel_SkillName"],LEVEL2QUALITY[skillData.addLevel],(skillData.data):GetSkillName())
			colorutil.SetQualityColorText(listItem.Controls["UILabel_SkillLV"],LEVEL2QUALITY[skillData.addLevel],LocalString.ChineseLVPlus .. skillData.addLevel)
		else
			-- 其他门派灰色字体
			colorutil.SetTextColor2Gray(listItem.Controls["UILabel_SkillName"],(skillData.data):GetSkillName())
			colorutil.SetTextColor2Gray(listItem.Controls["UILabel_SkillLV"],LocalString.ChineseLVPlus .. skillData.addLevel)
		end

		if skillData.bLocked then
			fields.UIList_AllSkills:SetSelectedIndex(i - 1)
		else
			fields.UIList_AllSkills:SetUnSelectedIndex(i - 1)
		end

	end
end

local function ResetAmuletSkillAttrList()
	local tempSkillAttrs = { }
	for pageIndex = 1, #g_PagesInfo do
		local pageData = g_PagesInfo[pageIndex]
		for _, skill in ipairs(pageData.SkillAttrs) do
			if not tempSkillAttrs[skill.skillId] then
				tempSkillAttrs[skill.skillId] = SkillData:new(skill.skillId, skill.profession, skill.addLevel, skill.bLocked)
			else
				tempSkillAttrs[skill.skillId].addLevel = tempSkillAttrs[skill.skillId].addLevel + skill.addLevel
			end
		end
	end
	local skillAttrs = { }
	-- 其他门派技能属性
	local otherSkillAttrs = { }

	for _, skillData in pairs(tempSkillAttrs) do
		if skillData.profession == PlayerRole:Instance().m_Profession then
			skillAttrs[#skillAttrs + 1] = skillData
		else
			otherSkillAttrs[#otherSkillAttrs + 1] = skillData
		end
	end
	for _, skillData in ipairs(otherSkillAttrs) do
		skillAttrs[#skillAttrs + 1] = skillData
	end
	-- 调整属性列表数目
	if #skillAttrs < fields.UIList_SkillLV.Count then
		-- 属性减少，减少listitem数量
		for i = fields.UIList_SkillLV.Count,(#skillAttrs + 1), -1 do
			local listItem = fields.UIList_SkillLV:GetItemByIndex(i - 1)
			fields.UIList_SkillLV:DelListItem(listItem)
		end
	else
		-- 属性增多，增加listitem数量
		for i = fields.UIList_SkillLV.Count,(#skillAttrs - 1) do
			fields.UIList_SkillLV:AddListItem()
		end
	end

	for index, skillData in ipairs(skillAttrs) do
		local listItem = fields.UIList_SkillLV:GetItemByIndex(index - 1)


		-- 本门派白色字体
		if PlayerRole:Instance().m_Profession == skillData.profession then
			-- colorutil.SetLabelColorText(listItem.Controls["UILabel_SkillName"],colorutil.ColorType.White,(skillData.data):GetSkillName())
			-- colorutil.SetLabelColorText(listItem.Controls["UILabel_SkillLV"],colorutil.ColorType.White,"LV+" .. skillData.addLevel)
			listItem.Controls["UILabel_SkillName"].text = (skillData.data):GetSkillName()
			listItem.Controls["UILabel_SkillLV"].text = (LocalString.ChineseLVPlus .. skillData.addLevel)
		 else
		 	-- 其他门派灰色字体
		 	-- colorutil.SetLabelColorText(listItem.Controls["UILabel_SkillName"],colorutil.ColorType.Gray,(skillData.data):GetSkillName())
		 	-- colorutil.SetLabelColorText(listItem.Controls["UILabel_SkillLV"],colorutil.ColorType.Gray,"LV+" .. skillData.addLevel)

		 	listItem.Controls["UILabel_SkillName"].text = (skillData.data):GetSkillName()
			listItem.Controls["UILabel_SkillLV"].text = (LocalString.ChineseLVPlus .. skillData.addLevel)
		 end
	end
end

local function ClearSkillList()
	fields.UIList_AllSkills:Clear()
end

local function ClearAmuletSkillAttrList()
	fields.UIList_SkillLV:Clear()
end

local function RefreshLockCost()
	local lockCostList =(ConfigManager.getConfig("amuletconfig")).lockcost
	local selectedListItems = fields.UIList_AllSkills:GetSelectedItems()
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
-- 获取本门派所有技能等级加成(不包括其他门派)
local function GetTotalAddedLevelOfCurSkillAttrs()
	local totalAddedLevel = 0
	for pageIndex = 1, #g_PagesInfo do
		local pageData = g_PagesInfo[pageIndex]
		for _, skillData in ipairs(pageData.SkillAttrs) do
			-- 本门派技能求和
			if PlayerRole:Instance().m_Profession == skillData.profession then
				totalAddedLevel = totalAddedLevel + skillData.addLevel
			end
		end
	end
	return totalAddedLevel

end
-- 根据本门派所有技能等级加成,来判断护符icon资源
local function GetAmuletIconByTotalAddedLevel()
	local totalAddedLevel = GetTotalAddedLevelOfCurSkillAttrs()

	local qualityList = ConfigManager.getConfig("amuletconfig").qualityjudge
	local iconList = ConfigManager.getConfig("amuletconfig").icon
	if totalAddedLevel >= qualityList[#qualityList] then

		return iconList[#qualityList]
	else
		local preLevel = 0
		for qualityIndex, curLevel in ipairs(qualityList) do
			if totalAddedLevel >= preLevel and totalAddedLevel < curLevel then
			
				return iconList[qualityIndex]
			end
			preLevel = curLevel
		end
	end
end
local function destroy()
	-- print(name, "destroy")
end

local function refresh(params)
	-- print(name, "refresh")
	SetPageTabList()

	local amuletIcon = GetAmuletIconByTotalAddedLevel()
	fields.UITexture_AmuletIcon:SetIconTexture(amuletIcon)
	fields.UILabel_AmuletName.text = ""
	ResetAmuletSkillAttrList()
	ResetSkillList(g_SelectedPageIndex)
	RefreshLockCost()
	RefreshWashCost()
end

-- region msg
local function onmsg_SWashAmulet(msg)
	-- print("onmsg_SWashAmulet")
	local washedSkillList = { }
	utils.shallow_copy_to(g_PagesInfo[msg.pageid].SkillAttrs, washedSkillList)
	for _, attr in pairs(msg.washresult) do
		local bSkillLocked = false
		if attr.islock == 1 then
			bSkillLocked = true
		end
		washedSkillList[attr.propindex] = SkillData:new(attr.skillid, attr.professionid, attr.addlevel, bSkillLocked)
	end

	local DlgAlert_AmuletWash = require("ui.playerrole.equip.dlgalert_amuletwash")

	if UIManager.isshow("common.dlgdialogbox_complex") then
		local params = { }
		params.washedSkillList = washedSkillList
		params.pageIndex = g_SelectedPageIndex
		params.callBackFunc = DlgAlert_AmuletWash.refresh
		UIManager.refresh("common.dlgdialogbox_complex", params)
	else
		local params = { }
		params.washedSkillList = washedSkillList
		params.pageIndex = g_SelectedPageIndex
		-- 选择UIGROUP_WASH = 0
		params.type = 0
		params.callBackFunc = function(p, f) DlgAlert_AmuletWash.init(f); DlgAlert_AmuletWash.show(p) end
		UIManager.show("common.dlgdialogbox_complex", params)
	end
	-- 刷新洗炼锁定消耗和钱币消耗
	RefreshLockCost()
	RefreshWashCost()
end
-- endregion

local function show(params)
	-- print(name, "show")
		listenerIds = network.add_listeners( {
		{ "lx.gs.amulet.SWashAmulet", onmsg_SWashAmulet },
	} )

	g_PagesInfo = AmuletManager.GetPagesInfo()
	g_SelectedPageIndex = 1
	-- 界面左侧skill属性展示
	InitAmuletSkillAttrList()
	-- 界面右侧page展示
	InitSkillList()
	fields.UIList_PageTab:SetSelectedIndex(g_SelectedPageIndex-1)
	-- 技能加锁
	fields.UIList_AllSkills.IsMultiCheckBox = true
end

local function hide()
	-- print(name, "hide")
	network.remove_listeners(listenerIds)
	ClearSkillList()
	ClearAmuletSkillAttrList()
end

local function update()
	-- print(name, "update")
end

local function init(params)
	print("护符页面！！！")
	name, gameObject, fields = unpack(params)
	
	EventHelper.SetClick(fields.UIButton_Detail,function()
	
	    UIManager.show( "common.dlgdialogbox_complex", { 
                    type = Dlg_Complex_Type.UIGROUP_BILLIONOFWORDS,
                    callBackFunc = function(params,fields)
                        fields.UILabel_Title.text = LocalString.City_War_Rule_Title
                        fields.UILabel_Content_Single.text = ConfigManager.getConfig("amuletconfig").introduction
         end })

	end)
	
	EventHelper.SetClick(fields.UIButton_WashAmulet, function()
		-- print("Button wash clicked")
		-- 检查消耗道具和钱币是否足够
		local lockCost = nil
		local washCost = nil

		local lockCostList =(ConfigManager.getConfig("amuletconfig")).lockcost
		local selectedListItems = fields.UIList_AllSkills:GetSelectedItems()
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
				ItemManager.GetSource(currency:GetConfigId(),"playerrole.equip.dlgamuletenhance")
			elseif not validate2 and lockCost then 
				-- 培养丹不足
				ItemManager.GetSource(lockCost.itemid,"playerrole.equip.dlgamuletenhance")
			end
		end

	end )

	EventHelper.SetListSelect(fields.UIList_AllSkills, function(listItem)
		-- print("UIList_AllSkills selected")
		if g_PagesInfo[g_SelectedPageIndex].SkillAttrs[listItem.Index + 1].bLocked == true then
			-- 如果相应技能属性已经锁定，无需再发锁定协议
			return
		end
		local selectedItems = fields.UIList_AllSkills:GetSelectedItems()
		if selectedItems.Length > 5 then
			UIManager.ShowSystemFlyText(LocalString.AmuletWash_MaxLockSkillNum)
			fields.UIList_AllSkills:SetUnSelectedIndex(listItem.Index)
			return
		end
		RefreshLockCost()
		local msg = lx.gs.amulet.CLockAmulet( { pageid = g_SelectedPageIndex, amuletid = (listItem.Index + 1) })
		network.send(msg)
	end )

	EventHelper.SetListUnSelect(fields.UIList_AllSkills, function(listItem)
		-- print("UIList_AllSkills unselected")
		if g_PagesInfo[g_SelectedPageIndex].SkillAttrs[listItem.Index + 1].bLocked == false then
			-- 如果相应技能属性未锁定，无需再发解锁定协议
			return
		end
		RefreshLockCost()
		local msg = lx.gs.amulet.CUnLockAmulet( { pageid = g_SelectedPageIndex, amuletid = (listItem.Index + 1) })
		network.send(msg)
	end )

	EventHelper.SetListClick(fields.UIList_PageTab, function(listItem)

		local pageOpenLevel =(ConfigManager.getConfig("amuletconfig")).expandlevel
		local bPageOpened = (PlayerRole:Instance():GetLevel() >= pageOpenLevel[listItem.Index + 1])
		if bPageOpened then 
			if g_PagesInfo[listItem.Index + 1] then
				g_SelectedPageIndex = listItem.Index + 1
				ResetSkillList(g_SelectedPageIndex)
				RefreshLockCost()
				RefreshWashCost()
			else
				logError("[dlgamuletenhance]:No skill page data")
			end
		else
			UIManager.ShowSystemFlyText(format(LocalString.AmuletWash_PageOpenLevel, pageOpenLevel[listItem.Index + 1]))
		end
	end )
end

return {
	init     = init,
	show     = show,
	hide     = hide,
	update   = update,
	destroy  = destroy,
	refresh  = refresh,
}
