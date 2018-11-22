local require            = require
local unpack             = unpack
local print              = print
local format             = string.format
local UIManager          = require("uimanager")
local network            = require("network")
local ConfigManager      = require("cfg.configmanager")
local PlayerRole         = require("character.playerrole")
local JewelryBagManager  = require("ui.jade.jewelrybagmanager")
local CheckCmd           = require("common.checkcmd")
local ItemManager        = require("item.itemmanager")
local EventHelper        = UIEventListenerHelper

local gameObject
local name
local fields

local listenerIds

local MAX_JEWELRY_SLOTNUM = 8

local function SetJewelrySlots()
	local slotOpenLevels = ConfigManager.getConfig("jadeenhance").holeopenlevel
	local jewelries = JewelryBagManager.GetAllLoadedJewelries()
	for i = 1, MAX_JEWELRY_SLOTNUM do

		if PlayerRole:Instance():GetLevel() >= slotOpenLevels[i] then
			fields[format("UILabel_Jewelry%02d_OpenLevel", i)].gameObject:SetActive(false)
			fields[format("UISprite_Jewelry%02d_Lock", i)].gameObject:SetActive(false)
			if jewelries[i] then
				fields[format("UISprite_Jewelry%02d_Level", i)].gameObject:SetActive(true)
				fields[format("UISprite_Add%02d", i)].gameObject:SetActive(false)
				fields[format("UILabel_Jewelry%02d_Level", i)].text = LocalString.Ranklist_RankName[2].."."..jewelries[i]:GetLevel()
				fields[format("UITexture_Jewelry%02d_Icon", i)]:SetIconTexture(jewelries[i]:GetTextureName())
				fields[format("UISprite_JadeQuality%02d", i)].spriteName = colorutil.GetQualitySpriteYuan(jewelries[i]:GetQuality())
			else
				fields[format("UISprite_Jewelry%02d_Level", i)].gameObject:SetActive(false)
				fields[format("UISprite_Add%02d", i)].gameObject:SetActive(true)
				fields[format("UITexture_Jewelry%02d_Icon", i)]:SetIconTexture("null")
				fields[format("UISprite_JadeQuality%02d", i)].spriteName = "N_FramCreatePlayer"
			end
		else
			fields[format("UILabel_Jewelry%02d_OpenLevel", i)].gameObject:SetActive(true)
			fields[format("UISprite_Add%02d", i)].gameObject:SetActive(false)
			fields[format("UISprite_Jewelry%02d_Lock", i)].gameObject:SetActive(true)
			fields[format("UISprite_Jewelry%02d_Level", i)].gameObject:SetActive(false)
			fields[format("UITexture_Jewelry%02d_Icon", i)]:SetIconTexture("null")
		    fields[format("UISprite_JadeQuality%02d", i)].spriteName =  "N_FramCreatePlayer"

		end
		fields[format("UILabel_Jewelry%02d_OpenLevel", i)].text = format(LocalString.JadeEnhance_JewelrySlotOpenLevel, slotOpenLevels[i])

		EventHelper.SetClick(fields[format("UISprite_JewelryBG%02d", i)], function()
			-- print(format("UISprite_Jewelry%02d clicked", i))
			if PlayerRole:Instance():GetLevel() < slotOpenLevels[i] then
				-- 提示开启等级
				UIManager.ShowSystemFlyText(format(LocalString.JadeEnhance_JewelrySlotOpenLevel, slotOpenLevels[i]))
			else
				-- jewelries[i]有可能为空
				UIManager.show("jade.dlgalert_jewelrybag", { jewelry = jewelries[i],jadeSlotPos = i })
			end

		end )

	end
end

local function SetJadeSlot()
	local playerJade = JewelryBagManager.GetPlayerJade()
	fields.UITexture_Jade_Icon:SetIconTexture(playerJade:GetTextureName())
	fields.UILabel_JadeAttr01_Name.text = format(LocalString.JadeEnhance_JadeAttrName1, playerJade:GetAttrValue())
	fields.UILabel_JadeAttr02_Name.text = format(LocalString.JadeEnhance_JadeAttrName2, playerJade:GetAttrPercent() * 100)
end

local function SetJewelryAttrList()
	local jewelries = JewelryBagManager.GetAllLoadedJewelries()

	local jewelryList = { }
	for _, jewelry in pairs(jewelries) do
		jewelryList[#jewelryList + 1] = jewelry
	end
	fields.UIList_JewelryAttributes:Clear()
	for i = 1, #jewelryList do
		local listItem = fields.UIList_JewelryAttributes:AddListItem()
		listItem.Controls["UILabel_Attr_Name"].text = jewelryList[i]:GetAttrText()
	end
end

local function ResetJewelrySlot()


end

local function SetJadeEnhanceDlg()

	if fields.UIGroup_EnhanceJadeDlg.gameObject.activeSelf then
		local playerJade = JewelryBagManager.GetPlayerJade()
		local jadeEnhanceData = ConfigManager.getConfig("jadeenhance")
		-- 玉佩图标和等级
		fields.UITexture_EnhanceJadeDlg_JadeIcon:SetIconTexture(playerJade:GetTextureName())
		fields.UILabel_EnhanceJadeDlg_JadeLevel.text = LocalString.Ranklist_RankName[2]..".".. playerJade:GetLevel()
		-- 攻击属性
		fields.UILabel_JadeEnhanceDlg_JadeAttr01_Name.text = format(LocalString.JadeEnhance_JadeAttrName1, playerJade:GetAttrValue())
		-- 攻击属性百分比
		fields.UILabel_JadeEnhanceDlg_JadeAttr02_Name.text = format(LocalString.JadeEnhance_JadeAttrName2, playerJade:GetAttrPercent() * 100)
		-- 虚拟币培养
		fields.UILabel_EnhanceJade_Xunibi_Name.text = jadeEnhanceData.enhancedata[1].enhancetypename
		fields.UILabel_XunibiCost_Amount.text = jadeEnhanceData.enhancedata[1].currency.amount
		fields.UILabel_Prop01Cost_Amount.text = 1
		-- 元宝培养
		fields.UILabel_EnhanceJade_Yuanbao_Name.text = jadeEnhanceData.enhancedata[2].enhancetypename
		fields.UILabel_YuanbaoCost_Amount.text = jadeEnhanceData.enhancedata[2].currency.amount
		fields.UILabel_Prop02Cost_Amount.text = 1

		-- 进度条
		fields.UISlider_AdvanceJadeLevel.value =(playerJade:GetAttrValue()) /(playerJade:GetAttrUpperLimitIfAdvanced())
		fields.UILabel_JadeLevel_Progress.text =(playerJade:GetAttrValue()) .. "/" ..(playerJade:GetAttrUpperLimitIfAdvanced())

		EventHelper.SetClick(fields.UIButton_JadeEnhanceOnce, function()
			-- 培养一次
			local playerJade = JewelryBagManager.GetPlayerJade()
			if playerJade:GetAttrValue() >= playerJade:GetAttrUpperLimitIfAdvanced() then
				-- 已经达到进阶条件
				UIManager.ShowSystemFlyText(LocalString.JadeEnhance_NeedAdvance)
			else
				-- 检查条件
				local enhanceType = fields.UIToggle_ByXunibi.value and 1 or 2

				local checkCurrency = jadeEnhanceData.enhancedata[enhanceType].currency
				local checkUsedProp = jadeEnhanceData.enhanceitemid

				local currencyValidated = CheckCmd.CheckData( { data = checkCurrency, num = 1, showsysteminfo = false })
				local propValidated = CheckCmd.CheckData( { data = checkUsedProp, num = 1, showsysteminfo = false })

				if currencyValidated and propValidated then
					local msg = lx.gs.jade.CEnhanceJade( { enhancetypeid = enhanceType,num = 1 })
					network.send(msg)
				else
					if not currencyValidated then
						-- 钱币不足
						local currency = ItemManager.GetCurrencyData(checkCurrency)
						ItemManager.GetSource(currency:GetConfigId(),"playerrole.equip.dlgjadeenhance")
					elseif not propValidated then 
						-- 培养丹不足
						ItemManager.GetSource(checkUsedProp.itemid,"playerrole.equip.dlgjadeenhance")
					end
				end
			end
		end )

		EventHelper.SetClick(fields.UIButton_JadeEnhance10Time, function()
			-- 培养十次
			local playerJade = JewelryBagManager.GetPlayerJade()
			if playerJade:GetAttrValue() >= playerJade:GetAttrUpperLimitIfAdvanced() then
				-- 已经达到进阶条件
				UIManager.ShowSystemFlyText(LocalString.JadeEnhance_NeedAdvance)
			else
				-- 检查条件
				local enhanceType = fields.UIToggle_ByXunibi.value and 1 or 2

				local checkCurrency = jadeEnhanceData.enhancedata[enhanceType].currency
				local checkUsedProp = jadeEnhanceData.enhanceitemid

				local currencyValidated = CheckCmd.CheckData( { data = checkCurrency, num = 10, showsysteminfo = false })
				local propValidated = CheckCmd.CheckData( { data = checkUsedProp, num = 10, showsysteminfo = false })

				if currencyValidated and propValidated then
					local msg = lx.gs.jade.CEnhanceJade( { enhancetypeid = enhanceType,num = 10 })
					network.send(msg)
				else
					if not currencyValidated then
						-- 钱币不足
						local currency = ItemManager.GetCurrencyData(checkCurrency)
						ItemManager.GetSource(currency:GetConfigId(),"playerrole.equip.dlgjadeenhance")
					elseif not propValidated then 
						-- 培养丹不足
						ItemManager.GetSource(checkUsedProp.itemid,"playerrole.equip.dlgjadeenhance")
					end
				end
			end

		end )

		EventHelper.SetClick(fields.UIButton_AdvanceToNextLevel, function()
			-- 玉佩进阶

			if (playerJade:GetAttrValue()) >=(playerJade:GetAttrUpperLimitIfAdvanced()) then

				local checkLevel = playerJade:GetRequiredPlayerLevelIfAdvanced()
				local checkUsedProp = playerJade:GetRequiredPropIfAdvanced()
				local usedProp = ItemManager.CreateItemBaseById(checkUsedProp.itemid,nil,checkUsedProp.amount)

				local params = { }
				params.immediate = true
				params.title = LocalString.TipText
				params.content = format(LocalString.JadeEnhance_ItemCost,usedProp:GetNumber(),usedProp:GetName())
				params.callBackFunc = function()

					local data = {}
					data[#data + 1] = checkLevel
					data[#data + 1] = checkUsedProp

					local validate = CheckCmd.CheckData( { data = data, num = 1, showsysteminfo = true })
					if validate then
						network.create_and_send("lx.gs.jade.CEvolveJade")
					end
				end
				UIManager.ShowAlertDlg(params)
			else
				-- 不够进阶条件,提示
				UIManager.ShowSystemFlyText(format(LocalString.JadeEnhance_NeededAdvanceLevel,playerJade:GetAttrUpperLimitIfAdvanced()))
			end

		end )
	end
end

local function StopUIParticleSystem()
	UIManager.StopUIParticleSystem(fields.UIGroup_JadeEnhance.gameObject)
	UIManager.StopUIParticleSystem(fields.UIGroup_JadeAdvance.gameObject) 
end
-- region msg
local function OnMsg_SEnhanceJade_Dlg(msg)
	-- 播放玉佩培养UI动画
	UIManager.PlayUIParticleSystem(fields.UIGroup_JadeEnhance.gameObject)
end

local function OnMsg_SEvolveJade_Dlg(msg)
	-- 播放玉佩进阶UI动画
	UIManager.PlayUIParticleSystem(fields.UIGroup_JadeAdvance.gameObject)
end
-- endregion msg

local function destroy()
	-- print(name, "destroy")
end

local function show(params)
	-- print(name, "show")
	fields.UIGroup_EnhanceJadeDlg.gameObject:SetActive(false)
	fields.UIGroup_Jade_MainDlg.gameObject:SetActive(true)
	listenerIds = network.add_listeners( {
		{ "lx.gs.jade.SEnhanceJade", OnMsg_SEnhanceJade_Dlg },
		{ "lx.gs.jade.SEvolveJade", OnMsg_SEvolveJade_Dlg },
	} )
end

local function hide()
	-- print(name, "hide")
	network.remove_listeners(listenerIds)
	fields.UIList_JewelryAttributes:Clear()
	StopUIParticleSystem()
end

local function refresh(params)
	-- print(name, "refresh")
	SetJewelryAttrList()
	SetJadeSlot()
	SetJewelrySlots()
	if fields.UIGroup_EnhanceJadeDlg.gameObject.activeSelf then
		SetJadeEnhanceDlg()
	end
end

local function update()
	-- print(name, "update")
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
	name, gameObject, fields = unpack(params)

	EventHelper.SetClick(fields.UIButton_EnhanceJade, function()

		fields.UIGroup_EnhanceJadeDlg.gameObject:SetActive(true)
		SetJadeEnhanceDlg()
	end )

	EventHelper.SetClick(fields.UIButton_EhanceJadeDlg_Close, function()

		fields.UIGroup_EnhanceJadeDlg.gameObject:SetActive(false)
	end )

end

return {
	init       = init,
	show       = show,
	hide       = hide,
	update     = update,
	destroy    = destroy,
	refresh    = refresh,
	uishowtype = uishowtype,
}

