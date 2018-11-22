local require           = require
local unpack            = unpack
local print             = print
local format            = string.format
local UIManager         = require("uimanager")
local network           = require("network")
local ConfigManager     = require("cfg.configmanager")
local Jewelry           = require("item.jewelry")
local JewelryBagManager = require("ui.jade.jewelrybagmanager")
local CheckCmd          = require("common.checkcmd")
local ItemManager       = require("item.itemmanager")
local GameEvent         = require("gameevent")
local EventHelper       = UIEventListenerHelper
local SettingManager    = require "character.settingmanager"
local defineenum        = require "defineenum"
local limitOne 
local limitTen

local gameObject
local name
local fields

local MAX_CAPACITY = 120
local MAX_HUNTJEWELRY_NUM = 10
-- 全局变量
local g_AllJewelryData = { }
local g_WaitForSeconds = 0
local g_PreAcquiredJewelryNum = 0

local JEWELRY_HUNTER_LEVEL =
{
	LEVEL1 = 1,
	LEVEL2 = 2,
	LEVEL3 = 3,
	LEVEL4 = 4,
	LEVEL5 = 5,
}

local QUALITY2NAME = 
{
	[cfg.item.EItemColor.WHITE]  = "White",
	[cfg.item.EItemColor.GREEN]  = "Green",
	[cfg.item.EItemColor.BLUE]   = "Blue",
	[cfg.item.EItemColor.PURPLE] = "Purple",
	[cfg.item.EItemColor.ORANGE] = "Orange", 
	[cfg.item.EItemColor.RED]    = "Red",
}


-- local function GetPossiblyAcquiredJewelries(jewelryHunterLevel)
--    local jewelries = {}
--    local jewelryAquiredRateList = ConfigManager.getConfigData("jewelryget",jewelryHunterLevel).ratelist
--    --依次是橙、紫、蓝、绿、白品质的获取概率
--    local jewelryTable = ConfigManager.getConfig("jewelry")
--    for i = #jewelryAquiredRateList,1,-1 do
--        if jewelryAquiredRateList[i] ~= 0 then
--            for id,jewelryData in ipairs(jewelryTable) do
--                -- (i-1)为品质值，物品品质枚举值从0开始
--                if (i-1) == jewelryData.quality then
--                    jewelries[#jewelries + 1] = Jewelry:new(id)
--                end
--            end
--        end
--    end
--    return jewelries
-- end

local function GetPossiblyAcquiredJewelries()
	local jewelries = { }
	local allHunters = ConfigManager.getConfig("jewelryget")
	for jewelryHunterLevel, data in pairs(allHunters) do
		local jewelryAquiredRateList = data.ratelist
		jewelries[jewelryHunterLevel] = { }
		-- 依次是橙、紫、蓝、绿、白品质的获取概率
		local jewelryTable = ConfigManager.getConfig("jewelry")
		for i = #jewelryAquiredRateList, 1, -1 do
			if jewelryAquiredRateList[i] ~= 0 then
				for id, jewelryData in pairs(jewelryTable) do
					-- (i-1)为品质值，物品品质枚举值从0开始
					if (i - 1) == jewelryData.quality then
						-- 每个猎命师等级里按照橙、紫、蓝、绿、白品质顺序存储宝珠
						local jewelryIndex = #(jewelries[jewelryHunterLevel]) + 1
						jewelries[jewelryHunterLevel][jewelryIndex] = Jewelry:new(id, 1, jewelryIndex, 0, JewelryBagManager.JEWELRY_TYPE.JEWELRY_INBAG)
					end
				end
			end
		end
	end
	return jewelries
end


local function SetSelectedJewelryInfo(jewelry)
	if not jewelry then
		-- 无选择则清空信息
		fields.UILabel_SelectedJewelry_Name.text = ""
		fields.UITexture_SelectedJewelry_Icon:SetIconTexture("null")
		fields.UISprite_SelectedJewelry_Quality.spriteName = colorutil.GetQualitySpriteYuan()
		fields.UILabel_SelectedJewelry_Level.text = ""
		-- fields.UILabel_SelectedJewelry_Level2.text = ""
		fields.UILabel_SelectedJewelry_Attribute.text = ""
		fields.UILabel_SelectedJewelry_Discription.text = ""
	else
		fields.UILabel_SelectedJewelry_Name.text = jewelry:GetName()
		fields.UITexture_SelectedJewelry_Icon:SetIconTexture(jewelry:GetTextureName())
		fields.UISprite_SelectedJewelry_Quality.spriteName = colorutil.GetQualitySpriteYuan(jewelry:GetQuality())
		fields.UILabel_SelectedJewelry_Level.text = "LV."..jewelry:GetLevel()
		-- fields.UILabel_SelectedJewelry_Level2.text = jewelry:GetLevel()
		fields.UILabel_SelectedJewelry_Attribute.text = jewelry:GetAttrText()
		fields.UILabel_SelectedJewelry_Discription.text = jewelry:GetIntroduce()
	end
end


local function InitPossiblyAcquiredJewelriesList(jewelryList)
	if fields.UIList_PossiblyAcquiredJewelries.Count == 0 then
		for i = 1, #jewelryList do
			local listItem = fields.UIList_PossiblyAcquiredJewelries:AddListItem()
			listItem.Controls["UILabel_AcquiredJewelry_Level"].text = ""
			listItem.Controls["UILabel_AcquiredJewelry_Level"].gameObject:SetActive(false)
			listItem.Controls["UISprite_JewelryQuality"].spriteName = colorutil.GetQualitySpriteYuan()
			listItem:SetIconTexture("null")
		end
	end
end

local function ResetPossiblyAcquiredJewelriesList(jewelryList)
	-- 增加或者减少格子数量
	local listCount = fields.UIList_PossiblyAcquiredJewelries.Count
	-- 增加格子
	if #jewelryList > listCount then
		for i = listCount + 1, #jewelryList do
			local listItem = fields.UIList_PossiblyAcquiredJewelries:AddListItem()
			listItem.Controls["UILabel_AcquiredJewelry_Level"].text = ""
			listItem.Controls["UILabel_AcquiredJewelry_Level"].gameObject:SetActive(false)
			listItem.Controls["UISprite_JewelryQuality"].spriteName = colorutil.GetQualitySpriteYuan()
			listItem:SetIconTexture("null")
		end
	elseif #jewelryList < listCount then
		-- 减少格子
		for i = listCount, #jewelryList + 1, -1 do
			local listItem = fields.UIList_PossiblyAcquiredJewelries:GetItemByIndex(i - 1)
			fields.UIList_PossiblyAcquiredJewelries:DelListItem(listItem)
		end
	end

	for i = 1, #jewelryList do
		local listItem = fields.UIList_PossiblyAcquiredJewelries:GetItemByIndex(i - 1)
		if jewelryList[i] then
			listItem.Controls["UILabel_AcquiredJewelry_Level"].gameObject:SetActive(true)
			listItem.Controls["UILabel_AcquiredJewelry_Level"].text = "LV."..jewelryList[i]:GetLevel()
			listItem.Controls["UISprite_JewelryQuality"].spriteName = colorutil.GetQualitySpriteYuan(jewelryList[i]:GetQuality())
			listItem:SetIconTexture(jewelryList[i]:GetTextureName())
		else
			listItem.Controls["UILabel_AcquiredJewelry_Level"].text = ""
			listItem.Controls["UILabel_AcquiredJewelry_Level"].gameObject:SetActive(false)
			listItem.Controls["UISprite_JewelryQuality"].spriteName = colorutil.GetQualitySpriteYuan()
			listItem:SetIconTexture("null")
		end
	end
end

local function ResetAcquiredJewelryList()
	for i = 1,MAX_HUNTJEWELRY_NUM do
		local listItem = fields.UIList_AcquiredJewelry:GetItemByIndex(i-1)
		listItem:SetIconTexture("null")
		listItem:SetText("UILabel_Level", "")
		listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
		listItem.Data = nil
		-- 清除之前挂载的特效
		local uiEffects = listItem.Controls["UITexture_Icon"].gameObject:GetComponentsInChildren(UnityEngine.ParticleSystem,true)
		if uiEffects then 
			for i = 1,uiEffects.Length do
				GameObject.Destroy(uiEffects[i].gameObject)
			end
		end
		listItem.gameObject:SetActive(false)
	end
end

-- 设置猎命师
local function SetJewelryHunterStatus(bPlayEffect)
	-- 获取猎命师总数
	local allHunters = ConfigManager.getConfig("jewelryget")
	local curHunterLevel = JewelryBagManager.GetJewelryHunterLevel()

	-- 猎命师品质(绿蓝紫橙红,写死的)
	for i = 1, #allHunters do
		fields[format("UISprite_Character%02d_Quality", i)].color = colorutil.GetQualityColor(i)
	end

	for i = 1, #allHunters do
		fields[format("UISprite_Effect%02d", i)].gameObject:SetActive(curHunterLevel == i)
	end

	-- 播放召唤动画
	if bPlayEffect then
		local uiTexture = fields[format("UITexture_Character%02d_Icon", curHunterLevel)]
		local uiHunterEffectObj = GameObject.Instantiate(fields.UIGroup_CallHunterEffect.gameObject) 
		uiHunterEffectObj.transform.parent = uiTexture.transform
		uiHunterEffectObj.transform.localScale = Vector3(109,109,109)
		uiHunterEffectObj.transform.localPosition = Vector3(0,-uiTexture.height/2,0)
		uiHunterEffectObj.transform.localRotation =  Quaternion.Euler(-13,0,0)
		UIManager.PlayUIParticleSystem(uiHunterEffectObj)
		-- 播放完毕后释放资源
		local hunterEffect_EventId = 0
		hunterEffect_EventId = GameEvent.evt_update:add(function()
			if not UIManager.IsPlaying(uiHunterEffectObj) then
				GameEvent.evt_update:remove(hunterEffect_EventId)
				GameObject.Destroy(uiHunterEffectObj)
			end
		end)
	end
end

local function GetActivedItemsNum()
	local num = 0
	for i = 1,fields.UIList_AcquiredJewelry.Count do
		local listItem = fields.UIList_AcquiredJewelry:GetItemByIndex(i - 1)
		if listItem.gameObject.activeSelf then
			num = num + 1
		end
	end
	return num
end

local function StopUIParticleSystem()
	UIManager.StopUIParticleSystem(fields.UIGroup_CallHunterEffect.gameObject)
end

local function destroy()
	-- print(name, "destroy")
end

local function show(params)
	-- print(name, "show")
	SetJewelryHunterStatus()
end

local function hide()
	-- print(name, "hide")
end



local function setLimitNumber()
	if not IsBSReview() then 
		fields.UILabel_Limit1.gameObject:SetActive(false)
		fields.UILabel_Limit2.gameObject:SetActive(false)
		return 
	end
	local TimeUtils = require"common.timeutils"
	local time = os.date("%Y%m%d",TimeUtils.GetServerTime())
	local LimitMap = SettingManager.GetMagicLimit()
	if LimitMap then 
	 	 local PlayerRole = require "character.playerrole"
		 limitOne = tonumber(LimitMap[PlayerRole:Instance().m_Name..defineenum.ExamineLimitType.SoulOne..time] or 0)
		 limitTen = tonumber(LimitMap[PlayerRole:Instance().m_Name..defineenum.ExamineLimitType.SoulTen..time] or 0)
		 if limitOne then
			fields.UILabel_number1.text = string.format(LocalString.LimitNumber,LMIIT_MAX_ONE,LMIIT_MAX_ONE - limitOne)
			if LMIIT_MAX_ONE - limitOne <= 0 then
				fields.UIButton_AcquireOnce.isEnabled = false
			end
		 end
		 if limitTen then
			 fields.UILabel_number2.text = string.format(LocalString.LimitNumber,LMIIT_MAX_TEN,LMIIT_MAX_TEN - limitTen)
			 if LMIIT_MAX_TEN - limitTen <= 0 then
				fields.UIButton_Acquire10Times.isEnabled = false
			end
		 end
	end
end

local function refresh(params)
	-- print(name, "refresh")
	if params and params.tempJewelryList then
		-- 清除之前猎取到的宝珠
		local activedNum = GetActivedItemsNum()
		if #(params.tempJewelryList) >(MAX_HUNTJEWELRY_NUM - activedNum) then
			ResetAcquiredJewelryList()
		end
		-- 重新获取数量
		activedNum = GetActivedItemsNum()
		for index, jewelry in ipairs(params.tempJewelryList) do
			local listItem = fields.UIList_AcquiredJewelry:GetItemByIndex(activedNum + index - 1)
			-- 清除之前挂载的特效
			local uiEffects = listItem.Controls["UITexture_Icon"].gameObject:GetComponentsInChildren(UnityEngine.ParticleSystem,true)
			if uiEffects then
				for i = 1,uiEffects.Length do
					GameObject.Destroy(uiEffects[i].gameObject)
				end
			end
			listItem.gameObject:SetActive(true)
			listItem:SetIconTexture(jewelry:GetTextureName())
			listItem:SetText("UILabel_Level",LocalString.Ranklist_RankName[2].."."..jewelry:GetLevel())
			listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySpriteYuan(jewelry:GetQuality())
			listItem.Data = jewelry:GetQuality()
			-- 挂载特效
			local jewelryEffectObj = GameObject.Instantiate(fields["UIGroup_JewEffect_"..QUALITY2NAME[jewelry:GetQuality()]].gameObject) 
			jewelryEffectObj.transform.parent = listItem.Controls["UITexture_Icon"].transform
			jewelryEffectObj.transform.localScale = Vector3(1.1,1.1,1.1)
			jewelryEffectObj.transform.localPosition = Vector3.zero
			jewelryEffectObj.transform.localRotation = Quaternion.Euler(-90,0,0)
			UIManager.PlayUIParticleSystem(jewelryEffectObj)
		end
	end
	SetJewelryHunterStatus()
	setLimitNumber()
end

local function update()
	-- print(name, "update")
	-- 宝珠猎取动画
	local activedNum = GetActivedItemsNum()
	if g_PreAcquiredJewelryNum ~= activedNum then
		-- 猎取宝珠动画使用
		g_PreAcquiredJewelryNum = activedNum
		g_WaitForSeconds = 0
	end
end

local function second_update(now)
	local activedNum = GetActivedItemsNum()
	if activedNum ~= 0 then
		-- 2秒后界面中获取的宝珠消失(策划需求)
		if g_WaitForSeconds >= 2 then
			
			g_WaitForSeconds = 0
			g_PreAcquiredJewelryNum = 0

			local uiPlayTweens = fields.UIList_AcquiredJewelry.gameObject:GetComponent("UIPlayTweens")
			for i = 1,fields.UIList_AcquiredJewelry.Count do
				local listItem = fields.UIList_AcquiredJewelry:GetItemByIndex(i - 1)
				if listItem.gameObject.activeSelf then
					local jewQuality = listItem.Data
					-- 挂载飞入包裹特效
					local jewFlyEffectObj = GameObject.Instantiate(fields["UIGroup_JewFlyEffect_"..QUALITY2NAME[jewQuality]].gameObject)
					local uiWidget = listItem.gameObject:GetComponent("UIWidget")
					jewFlyEffectObj.transform.parent = listItem.transform
					jewFlyEffectObj.transform.localScale = Vector3.one
					jewFlyEffectObj.transform.localPosition = Vector3(uiWidget.width/2,-uiWidget.height/2,0)
					jewFlyEffectObj.transform.localRotation = Quaternion.Euler(0,0,0)
					
					local uiTweenTrans = jewFlyEffectObj:AddComponent(TweenTransform)
					uiTweenTrans.tweenGroup = 5
					uiTweenTrans.duration = 1
					uiTweenTrans.from = jewFlyEffectObj.transform
					uiTweenTrans.to = fields.UIButton_JewelryBag.transform
					uiPlayTweens:AddTweenTarget(uiTweenTrans.gameObject,5,false)
				end
			end
			
			EventHelper.SetPlayTweensFinish(uiPlayTweens,function()
				ResetAcquiredJewelryList()
				local uiTweenTargets = uiPlayTweens:GetTweenTargets()
				for i= 1,uiTweenTargets.Length do
					GameObject.Destroy(uiTweenTargets[i].tweenTarget)
				end
				uiPlayTweens:Clear()
			end)
			uiPlayTweens:Play(true)
		else
			g_WaitForSeconds = g_WaitForSeconds + 1
		end
	end
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
	name, gameObject, fields = unpack(params)

	g_AllJewelryData = GetPossiblyAcquiredJewelries()

	EventHelper.SetClick(fields.UIButton_JewelryBag, function()
		UIManager.show("jade.dlgalert_jewelrybag")
	end )

	EventHelper.SetClick(fields.UIButton_JewelryIntroduce, function()

		fields.UIGroup_PossiblyAcquiredJewelry.gameObject:SetActive(true)
		-- 猎命师品质(绿蓝紫橙红,写死的)
		for hunterIndex = 1,fields.UIList_AcquiredJewelry_RadioButton.Count do
			local listItem = fields.UIList_AcquiredJewelry_RadioButton:GetItemByIndex(hunterIndex-1)
			listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySpriteYuan(hunterIndex)
		end

		SetSelectedJewelryInfo()
		fields.UIList_AcquiredJewelry_RadioButton:SetSelectedIndex(0)
		local jewelries = g_AllJewelryData[JEWELRY_HUNTER_LEVEL.LEVEL1]
		InitPossiblyAcquiredJewelriesList(jewelries)
		ResetPossiblyAcquiredJewelriesList(jewelries)
		fields.UILabel_PossiblyAcquiredJewelries_Num.text = #jewelries .. "/" .. MAX_CAPACITY

	end )

	EventHelper.SetClick(fields.UIButton_PossiblyAcquiredJewelryDlg_Close, function()

		fields.UIGroup_PossiblyAcquiredJewelry.gameObject:SetActive(false)
	end )

	EventHelper.SetListClick(fields.UIList_AcquiredJewelry_RadioButton, function(listItem)
		if listItem.Index == 0 then
			-- 猎命师档次1
			local jewelries = g_AllJewelryData[JEWELRY_HUNTER_LEVEL.LEVEL1]
			ResetPossiblyAcquiredJewelriesList(jewelries)
			fields.UILabel_PossiblyAcquiredJewelries_Num.text = #jewelries .. "/" .. MAX_CAPACITY
		elseif listItem.Index == 1 then
			-- 猎命师档次2
			local jewelries = g_AllJewelryData[JEWELRY_HUNTER_LEVEL.LEVEL2]
			ResetPossiblyAcquiredJewelriesList(jewelries)
			fields.UILabel_PossiblyAcquiredJewelries_Num.text = #jewelries .. "/" .. MAX_CAPACITY

		elseif listItem.Index == 2 then
			-- 猎命师档次3
			local jewelries = g_AllJewelryData[JEWELRY_HUNTER_LEVEL.LEVEL3]
			ResetPossiblyAcquiredJewelriesList(jewelries)
			fields.UILabel_PossiblyAcquiredJewelries_Num.text = #jewelries .. "/" .. MAX_CAPACITY

		elseif listItem.Index == 3 then
			-- 猎命师档次4
			local jewelries = g_AllJewelryData[JEWELRY_HUNTER_LEVEL.LEVEL4]
			ResetPossiblyAcquiredJewelriesList(jewelries)
			fields.UILabel_PossiblyAcquiredJewelries_Num.text = #jewelries .. "/" .. MAX_CAPACITY

		else
			-- 猎命师档次5
			local jewelries = g_AllJewelryData[JEWELRY_HUNTER_LEVEL.LEVEL5]
			ResetPossiblyAcquiredJewelriesList(jewelries)
			fields.UILabel_PossiblyAcquiredJewelries_Num.text = #jewelries .. "/" .. MAX_CAPACITY

		end
		fields.UIScrollView_Jewelry:ResetPosition()
	end )

	EventHelper.SetListClick(fields.UIList_PossiblyAcquiredJewelries, function(listItem)
		local index = fields.UIList_AcquiredJewelry_RadioButton:GetSelectedIndex()
		local jewelries = g_AllJewelryData[index + 1]
		SetSelectedJewelryInfo(jewelries[listItem.Index + 1])
	end )

	EventHelper.SetClick(fields.UIButton_Call, function()
		-- 召唤指定档的猎命师，目前指定档次为4
		local allHunters = ConfigManager.getConfig("jewelryget")
		local curHunterLevel = JewelryBagManager.GetJewelryHunterLevel()
		local calledHunterLevel = 4

		if curHunterLevel == calledHunterLevel then 	
			-- 重复召唤猎命师4
			UIManager.ShowSystemFlyText(LocalString.Jewelry_CannotCallHunter)
			return 
		end
		local jadeEnhanceData = ConfigManager.getConfig("jadeenhance")
		local costData = jadeEnhanceData.level4cost
		local currency = ItemManager.GetCurrencyData(costData)

		local params = { }
		params.immediate = true
        params.title = LocalString.TipText
        params.content = format(LocalString.Jewelry_CallHunterCost,currency:GetNumber(),currency:GetName())
        params.callBackFunc = function()
			local bCurrencyValidated = CheckCmd.CheckData( { data = costData, num = 1, showsysteminfo = false })
			if bCurrencyValidated then
				local msg = lx.gs.jade.CSummonRole( { role = calledHunterLevel })
				network.send(msg)
			else
				ItemManager.GetSource(currency:GetConfigId(),"playerrole.equip.dlgequipenhance")
			end
        end
        UIManager.ShowAlertDlg(params)
	end )

	EventHelper.SetClick(fields.UIButton_AcquireOnce, function()
		if JewelryBagManager.IsBagFull() then
			UIManager.ShowSystemFlyText(LocalString.JewelryBag_Full)
			return
		end
		local bCurrencyValidated = CheckCmd.CheckData( { data = ConfigManager.getConfig("jadeenhance").searchcost,num = 1,showsysteminfo = false })
		local currency = ItemManager.GetCurrencyData(ConfigManager.getConfig("jadeenhance").searchcost)

		if bCurrencyValidated then 
			local msg = lx.gs.jade.CHuntJewelry( { num = 1 })
			network.send(msg)
		else
			ItemManager.GetSource(currency:GetConfigId(),"playerrole.equip.dlgequipenhance")
		end
		if  IsBSReview() then
			SettingManager.SendMagicLimit(limitOne+1,defineenum.ExamineLimitType.SoulOne)
		end
	end )

	EventHelper.SetClick(fields.UIButton_Acquire10Times, function()
		if JewelryBagManager.IsBagFull() then
			UIManager.ShowSystemFlyText(LocalString.JewelryBag_Full)
			return
        elseif JewelryBagManager.GetBagRemainingSize() < 10 then
			UIManager.ShowSystemFlyText(LocalString.JewelryBag_SizeNotEnough)
            return
		end
		local bCurrencyValidated = CheckCmd.CheckData( { data = ConfigManager.getConfig("jadeenhance").searchcost,num = 10,showsysteminfo = false })
		local currency = ItemManager.GetCurrencyData(ConfigManager.getConfig("jadeenhance").searchcost)
		
		if bCurrencyValidated then 
			local msg = lx.gs.jade.CHuntJewelry( { num = 10 })
			network.send(msg)
		else
			ItemManager.GetSource(currency:GetConfigId(),"playerrole.equip.dlgequipenhance")
		end
		if  IsBSReview() then
			SettingManager.SendMagicLimit(limitTen+1,defineenum.ExamineLimitType.SoulTen)
		end
	end )

	fields.UIGroup_PossiblyAcquiredJewelry.gameObject:SetActive(false)
	fields.UIGroup_AcquireJewelry.gameObject:SetActive(true)

	ResetAcquiredJewelryList()

	-- 猎取宝珠消耗
	local currency = ItemManager.GetCurrencyData(ConfigManager.getConfig("jadeenhance").searchcost)
	fields.UISprite_AcquireOnce_MoneyCost_Icon.spriteName = currency:GetIconName()
	fields.UISprite_UILabel_Acquire10Times_MoneyCost_Icon.spriteName = currency:GetIconName()
	fields.UILabel_AcquireOnce_MoneyCostNum.text = currency:GetNumber()
	fields.UILabel_Acquire10Times_MoneyCostNum.text = 10 * (currency:GetNumber())
	setLimitNumber()
end

return {
	init                   = init,
	show                   = show,
	hide                   = hide,
	update                 = update,
	second_update          = second_update,
	destroy                = destroy,
	refresh                = refresh,
	uishowtype             = uishowtype,
	SetJewelryHunterStatus = SetJewelryHunterStatus,
}

