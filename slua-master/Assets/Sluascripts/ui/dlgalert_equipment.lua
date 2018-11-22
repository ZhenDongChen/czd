local Unpack                  = unpack
local Math                    = math
local format                  = string.format
local UIManager               = require("uimanager")
local NetWork                 = require("network")
local BagManager              = require("character.bagmanager")
local ConfigManager           = require("cfg.configmanager")
local ItemEnum                = require("item.itemenum")
local ItemManager             = require("item.itemmanager")
local EventHelper             = UIEventListenerHelper

local name
local gameObject
local fields

local g_SelectedItem
local g_PlayerEquipItem
local g_LimitType
local g_PriceType
local g_DefaultPrice
local g_bVariablePrice
local g_bVariableNum
local g_TotalNum = 0
local g_bShowNum
local g_forceShowItem
local g_forceShowSolidUnitPrice
local g_BagNumInShop

local function pairsByLevel(attrList)
	local key = { }
	for level in pairs(attrList) do
		key[#key + 1] = level
	end
	table.sort(key)
	local i = 0
	return function()
		i = i + 1
		return key[i], attrList[key[i]]
	end
end

-- 设置单个属性信息(只适用饰品)
local function GetSpecifiedAttributeText(accLevel, bMainAttr, attrType, attrValue)
	local colorList = cfg.equip.AccessoryColor.JUDGE_COLOR_LIST
	local coefficientOfMainAttr = cfg.equip.AccessoryColor.JUDGE_COLOR_MAIN
	local accessoryColorData = ConfigManager.getConfigData("accessorycolor", accLevel)
	local denominatorOfAttrColor = nil

	for _, attrData in ipairs(accessoryColorData.standard) do
		if attrType == attrData.propertytype then
			denominatorOfAttrColor = attrData.value
			break
		end
	end
	local coefficientOfAttrColor = 0.0
	if bMainAttr then
		-- 计算主属性颜色系数值
		coefficientOfAttrColor = attrValue / denominatorOfAttrColor / coefficientOfMainAttr
	else
		-- 计算附加属性颜色系数值
		coefficientOfAttrColor = attrValue / denominatorOfAttrColor
	end
	local attrTypeToText = ConfigManager.getConfigData("statustext", attrType)
	local attrText = attrTypeToText.text
	local attributeText = ""
	if attrTypeToText.displaytype == cfg.fight.DisplayType.NORMAL then
		attributeText = format("%s%+.1f", attrText, attrValue)
	elseif attrTypeToText.displaytype == cfg.fight.DisplayType.ROUND then
		attributeText = format("%s%+d", attrText, attrValue)
	elseif attrTypeToText.displaytype == cfg.fight.DisplayType.PERCENT then
		attributeText = format("%s%+.1f%%", attrText, 100 * attrValue)
	else
		logError("attribute display type error!")
	end
	 -- 判断属性显示颜色
	 if coefficientOfAttrColor < colorList[1] and coefficientOfAttrColor >= 0 then
	 	-- 白色
	 	attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.WHITE,attributeText)
	 elseif coefficientOfAttrColor < colorList[2] and coefficientOfAttrColor >= colorList[1] then
	 	-- 绿色
	 	attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.GREEN,attributeText)
	 elseif coefficientOfAttrColor < colorList[3] and coefficientOfAttrColor >= colorList[2] then
	 	-- 蓝色
	 	attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.BLUE,attributeText)
	 elseif coefficientOfAttrColor < colorList[4] and coefficientOfAttrColor >= colorList[3] then
	 	-- 紫色
	 	attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.PURPLE,attributeText)
	 elseif coefficientOfAttrColor < colorList[5] and coefficientOfAttrColor >= colorList[4] then
	 	-- 橙色
	 	attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.ORANGE,attributeText)
	 elseif coefficientOfAttrColor >= colorList[5] then
	 	-- 红色
	 	attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.RED,attributeText)
	 else
	 	logError("Attribute value is wrong!")
	 end
	return attributeText -- "[7D3E2F]" ..
end

local function AdjustAttributesBGRect(listItem)
	local uiSprite_Com_AttrsBG = listItem.Controls["UISprite_AttributesBG"]
	local uiSprite_Com_TitleBG = listItem.Controls["UISprite_TitleBG"]
	local uiLabel_Com_Attrs = listItem.Controls["UILabel_AttributesList"]
	local padding = 10
	uiSprite_Com_AttrsBG.height = uiLabel_Com_Attrs.height + 2 * padding
	uiLabel_Com_Attrs:SetAnchor(uiSprite_Com_AttrsBG.gameObject, padding, padding, - padding, - padding)
	local uiWidget_Com_ListItem = listItem.gameObject:GetComponent("UIWidget")
	uiWidget_Com_ListItem.height = uiSprite_Com_TitleBG.height + uiSprite_Com_AttrsBG.height + 2 * padding
	uiSprite_Com_AttrsBG:SetAnchor(uiWidget_Com_ListItem.gameObject, padding, padding, - padding, -(uiSprite_Com_TitleBG.height + padding))
end
-- 设置属性列表
local function SetEquipAttributePanel(equip, bInBag)
	local UIList_Com_Attrs = nil
	if bInBag then
		UIList_Com_Attrs = fields.UIList_AttributePanel
	else
		UIList_Com_Attrs = fields.UIList_Player_AttributePanel
	end
	if equip:IsAccessory() then
		-- 饰品所有属性
		if UIList_Com_Attrs.Count == 0 then
			for index1 = 1, 5 do

				local accAttributes = { }
				if index1 == 1 then
					-- 饰品主属性
					accAttributes = equip:GetAccMainAttributes()
				elseif index1 == 3 then
					-- 饰品附加属性
					accAttributes = equip:GetAccExtraAttributes()
				elseif index1 == 2 then
					-- 强化属性(炼器增加属性和灌注增加属性)
					-- [1]炼器增加属性 type:map {key = cfg.fight.AttrId,value = 属性值}
					accAttributes[1] = equip:GetAnnealAddedAttrs()
					-- [2]灌注增加属性 type:map {key = cfg.fight.AttrId,value = 属性值}
					accAttributes[2] = equip:GetPerfuseAddedAttrs()
				elseif index1 == 4 then
					-- 达到相应炼器等级所激活的隐藏附加属性
					-- type:map {key = 炼器等级，value = {属性列表,每个项类型为(type:map {key = cfg.fight.AttrId,value = 属性值})，bActived}}
					accAttributes = equip:GetAnnealHiddenAttrs()
				else
				end
				if index1 <= 4 and getn(accAttributes) == 0 then
					logError("Can not get Acc Attributes!")
					break
				end
				local listItem = UIList_Com_Attrs:AddListItem()
				local uiLabel_Com_Attrs = listItem.Controls["UILabel_AttributesList"]
				local uiLabel_Com_Title = listItem.Controls["UILabel_AttributeTitle"]
				uiLabel_Com_Title.text = LocalString.AccAttrsTitle[index1]

				if index1 == 2 then
					-- 饰品强化属性显示为橙色(炼器增加属性和灌注增加属性)(只有激活一个)		
					for index2 = 1, 2 do
						local dec = ""
						if index2 == 1 then
							dec = LocalString.EquipAttrsAnnealAddedAttrDesc
						elseif index2 == 2 then
							dec = LocalString.EquipAttrsPerfuseAddedAttrDesc
						end
						local attributeText = ""

						for attrType, attrValue in pairs(accAttributes[index2]) do
							if accAttributes[index2][cfg.fight.AttrId.ATTACK_VALUE_MIN] and accAttributes[index2][cfg.fight.AttrId.ATTACK_VALUE_MAX] then
								local attackMinText = ItemManager.GetAttrText(cfg.fight.AttrId.ATTACK_VALUE_MIN, accAttributes[index2][cfg.fight.AttrId.ATTACK_VALUE_MIN])
								local attackMaxText = ItemManager.GetAttrText(cfg.fight.AttrId.ATTACK_VALUE_MAX, accAttributes[index2][cfg.fight.AttrId.ATTACK_VALUE_MAX])
								attributeText = "[FFFFFF]" .. dec .. LocalString.EquipAttrs_AttackDecs .. attackMinText .. "-" .. attackMaxText .. "[-]"
								break
							else
								attributeText = ItemManager.GetAttrText(attrType, attrValue)
								attributeText = "[FFFFFF]" .. dec .. attributeText .. "[-]"
							end
						end
						local bReturn = true
						if index2 == 2 then
							bReturn = false
						end
						ItemManager.AddAttributeDescText(uiLabel_Com_Attrs, bReturn, attributeText)
					end
				elseif index1 == 4 then 
					-- 达到相应炼器等级所激活的隐藏附加属性
					local maxAnnealLevel = 0
					for level in pairs(accAttributes) do
						maxAnnealLevel = Math.max(maxAnnealLevel, level)
					end
					-- 按照炼器等级升序排列
					for annealLevel, hiddenAttr in pairsByLevel(accAttributes) do
						local dec = format("(+%02d) ", annealLevel)
						local attributeText = ""
						for attrType, attrValue in pairs(hiddenAttr.Attrs) do
							if hiddenAttr.Attrs[cfg.fight.AttrId.ATTACK_VALUE_MIN] and hiddenAttr.Attrs[cfg.fight.AttrId.ATTACK_VALUE_MAX] then
								local attackMinText = ItemManager.GetAttrText(cfg.fight.AttrId.ATTACK_VALUE_MIN, hiddenAttr.Attrs[cfg.fight.AttrId.ATTACK_VALUE_MIN])
								local attackMaxText = ItemManager.GetAttrText(cfg.fight.AttrId.ATTACK_VALUE_MAX, hiddenAttr.Attrs[cfg.fight.AttrId.ATTACK_VALUE_MAX])
								if hiddenAttr.bActived then
									-- 显示为橙色
									attributeText = "[FF783D]" .. dec .. LocalString.EquipAttrs_AttackDecs .. attackMinText .. "-" .. attackMaxText .. "[-]"
								else
									-- 显示为灰色
									attributeText = "[7B7979]" .. dec .. LocalString.EquipAttrs_AttackDecs .. attackMinText .. "-" .. attackMaxText .. "[-]"
								end
								break
							else
								attributeText = ItemManager.GetAttrText(attrType, attrValue)
								if hiddenAttr.bActived then
									-- 显示为橙色
									attributeText = "[FF783D]" .. dec .. attributeText .. "[-]"
								else
									-- 显示为灰色
									attributeText = "[7B7979]" .. dec .. attributeText .. "[-]"
								end
								
							end
						end
						local bReturn = true
						if maxAnnealLevel == annealLevel then
							bReturn = false
						end
						ItemManager.AddAttributeDescText(uiLabel_Com_Attrs, bReturn, attributeText)
					end
				elseif index1 == 5 then
					-- 饰品介绍
					uiLabel_Com_Attrs.text =  "[FFFFFF]".. equip:GetIntroduction()
				else
					-- index1 = 1,2 主属性和附加属性，显示颜色由等级来定
					local bMainAttr = false
					if index1 == 1 then
						bMainAttr = true
					end
					for index, attribute in ipairs(accAttributes) do
						local attributeText = GetSpecifiedAttributeText(equip:GetLevel(), bMainAttr, attribute.AttrType, attribute.AttrValue)
						local bReturn = true
						if index == #accAttributes then
							bReturn = false
						end
						ItemManager.AddAttributeDescText(uiLabel_Com_Attrs, bReturn, attributeText)
					end
				end
				AdjustAttributesBGRect(listItem)
			end
			UIList_Com_Attrs.gameObject:GetComponent("UITable").repositionNow = true
		end
	elseif equip:IsMainEquip() then
		-- 装备
		if UIList_Com_Attrs.Count == 0 then
			for index1 = 1, 5 do

				local mainEquipAttrs = { }
				if index1 == 1 then
					-- 基础属性
					mainEquipAttrs = equip:GetEquipBasicAttributes()
				elseif index1 == 2 then
					-- 强化属性(炼器增加属性和灌注增加属性)
					-- [1]炼器增加属性 type:map {key = cfg.fight.AttrId,value = 属性值}
					mainEquipAttrs[1] = equip:GetAnnealAddedAttrs()
					-- [2]灌注增加属性 type:map {key = cfg.fight.AttrId,value = 属性值}
					mainEquipAttrs[2] = equip:GetPerfuseAddedAttrs()
				elseif index1 == 3 then
					-- 达到相应炼器等级所激活的隐藏附加属性
					-- type:map {key = 炼器等级，value = {属性列表,每个项类型为(type:map {key = cfg.fight.AttrId,value = 属性值})，bActived}}
					mainEquipAttrs = equip:GetAnnealHiddenAttrs()
				else
				end
				if index1 <= 3 and getn(mainEquipAttrs) == 0 then
					logError("Can not get Attributes!")
					break
				end
				local listItem = UIList_Com_Attrs:AddListItem()
				local uiLabel_Com_Attrs = listItem.Controls["UILabel_AttributesList"]
				local uiLabel_Com_Title = listItem.Controls["UILabel_AttributeTitle"]
				uiLabel_Com_Title.text = LocalString.EquipAttrsTitle[index1]
				if index1 == 1 then
					local attrNum = 0
					for attrType, attrValue in pairs(mainEquipAttrs) do
						local attributeText = ""

						attrNum = attrNum + 1
						local bReturn = true
						if attrNum == getn(mainEquipAttrs) then
							bReturn = false
						end

						if attrType == cfg.fight.AttrId.ATTACK_VALUE_MIN then
							if mainEquipAttrs[cfg.fight.AttrId.ATTACK_VALUE_MIN] and mainEquipAttrs[cfg.fight.AttrId.ATTACK_VALUE_MAX] then
								local attackMinText = ItemManager.GetAttrText(cfg.fight.AttrId.ATTACK_VALUE_MIN, mainEquipAttrs[cfg.fight.AttrId.ATTACK_VALUE_MIN])
								local attackMaxText = ItemManager.GetAttrText(cfg.fight.AttrId.ATTACK_VALUE_MAX, mainEquipAttrs[cfg.fight.AttrId.ATTACK_VALUE_MAX])
								-- 装备基础属性显示为白色
								attributeText = "[FFFFFF]" .. LocalString.EquipAttrs_AttackDecs .. attackMinText .. "-" .. attackMaxText .. "[-]"
								if getn(mainEquipAttrs) == 2 or attrNum ==(getn(mainEquipAttrs) -1) or attrNum == getn(mainEquipAttrs) then
									-- 基础属性只有 ATTACK_VALUE_MIN和ATTACK_VALUE_MAX两个属性
									bReturn = false
								end
								ItemManager.AddAttributeDescText(uiLabel_Com_Attrs, false, attributeText)
							else
								logError("csv data is wrong!")
							end
						elseif attrType ~= cfg.fight.AttrId.ATTACK_VALUE_MAX then
							attributeText = ItemManager.GetAttrText(attrType, attrValue)
							-- 装备基础属性显示为白色
							attributeText = "[FFFFFF]" .. attributeText .. "[-]"
							ItemManager.AddAttributeDescText(uiLabel_Com_Attrs, bReturn, attributeText)
						end
					end

				elseif index1 == 2 then
					-- 装备强化属性显示为橙色(炼器增加属性和灌注增加属性)(只有激活一个)
					for index2 = 1, 2 do
						local dec = ""
						if index2 == 1 then
							dec = LocalString.EquipAttrsAnnealAddedAttrDesc
						elseif index2 == 2 then
							dec = LocalString.EquipAttrsPerfuseAddedAttrDesc
						end
						local attributeText = ""

						for attrType, attrValue in pairs(mainEquipAttrs[index2]) do
							if mainEquipAttrs[index2][cfg.fight.AttrId.ATTACK_VALUE_MIN] and mainEquipAttrs[index2][cfg.fight.AttrId.ATTACK_VALUE_MAX] then
								local attackMinText = ItemManager.GetAttrText(cfg.fight.AttrId.ATTACK_VALUE_MIN, mainEquipAttrs[index2][cfg.fight.AttrId.ATTACK_VALUE_MIN])
								local attackMaxText = ItemManager.GetAttrText(cfg.fight.AttrId.ATTACK_VALUE_MAX, mainEquipAttrs[index2][cfg.fight.AttrId.ATTACK_VALUE_MAX])
								attributeText = "[FFFFFF]" .. dec .. LocalString.EquipAttrs_AttackDecs .. attackMinText .. "-" .. attackMaxText .. "[-]"
								break
							else
								attributeText = ItemManager.GetAttrText(attrType, attrValue)
								attributeText = "[FFFFFF]" .. dec .. attributeText .. "[-]"
							end
						end
						local bReturn = true
						if index2 == 2 then
							bReturn = false
						end
 						ItemManager.AddAttributeDescText(uiLabel_Com_Attrs, bReturn, attributeText)
					end
				elseif index1 == 3 then
					-- 达到相应炼器等级所激活的隐藏附加属性
					local maxAnnealLevel = 0
					for level in pairs(mainEquipAttrs) do
						maxAnnealLevel = Math.max(maxAnnealLevel, level)
					end
					-- 按照炼器等级升序排列
					for annealLevel, hiddenAttr in pairsByLevel(mainEquipAttrs) do
						local dec = format("(+%02d) ", annealLevel)
						local attributeText = ""
						for attrType, attrValue in pairs(hiddenAttr.Attrs) do
							if hiddenAttr.Attrs[cfg.fight.AttrId.ATTACK_VALUE_MIN] and hiddenAttr.Attrs[cfg.fight.AttrId.ATTACK_VALUE_MAX] then
								local attackMinText = ItemManager.GetAttrText(cfg.fight.AttrId.ATTACK_VALUE_MIN, hiddenAttr.Attrs[cfg.fight.AttrId.ATTACK_VALUE_MIN])
								local attackMaxText = ItemManager.GetAttrText(cfg.fight.AttrId.ATTACK_VALUE_MAX, hiddenAttr.Attrs[cfg.fight.AttrId.ATTACK_VALUE_MAX])
								if hiddenAttr.bActived then
									-- 显示为橙色
									attributeText = "[FF783D]" .. dec .. LocalString.EquipAttrs_AttackDecs .. attackMinText .. "-" .. attackMaxText .. "[-]"
								else
									-- 显示为灰色
									attributeText = "[7B7979]" .. dec .. LocalString.EquipAttrs_AttackDecs .. attackMinText .. "-" .. attackMaxText .. "[-]"
								end
								break
							else
								attributeText = ItemManager.GetAttrText(attrType, attrValue)
								if hiddenAttr.bActived then
									-- 显示为橙色
									attributeText = "[FF783D]" .. dec .. attributeText .. "[-]"
								else
									-- 显示为灰色
									attributeText = "[7B7979]" .. dec .. attributeText .. "[-]"
								end
								
							end
						end
						local bReturn = true
						if maxAnnealLevel == annealLevel then
							bReturn = false
						end
						ItemManager.AddAttributeDescText(uiLabel_Com_Attrs, bReturn, attributeText)
					end
				elseif index1 == 4 then
					-- 套装显示
					local equipSuitsConfigData = equip:GetEquipSuitsConfigData()
					if not equipSuitsConfigData then
						-- 无套装属性，删除套装属性显示item
						UIList_Com_Attrs:DelListItem(listItem)
					else
						-- 重写套装名字
						uiLabel_Com_Title.text = equipSuitsConfigData.name
						-- 有套装属性
						if equip.BagType == cfg.bag.BagType.EQUIP then
							-- 背包里的套装都显示为未激活,均显示为灰色
							for suitAttrIndex, attrData in ipairs (equipSuitsConfigData.suitsbonus) do
								local attributeText = ""
								local text = ItemManager.GetAttrText(attrData.propertydata.propertytype, attrData.propertydata.value)
								attributeText = format("[7B7979](%d%s) %s[-]", attrData.amountlimit, LocalString.EquipAttrsNeedSuitDesc, text)
								local bReturn = true
								if suitAttrIndex == #(equipSuitsConfigData.suitsbonus) then
									bReturn = false
								end
								ItemManager.AddAttributeDescText(uiLabel_Com_Attrs, bReturn, attributeText)
							end
						else
							-- 获取所有玩家身上装备
							local allMainEquipOnPlayer = BagManager.GetMainEquipsOnBody()
							-- num初始值为1表示包括所选装备本身
							local numOfPlayerEquipInSuits = 1
							for _, playerEquip in pairs(allMainEquipOnPlayer) do
								if playerEquip:GetConfigId() ~= equip:GetConfigId() then
									for _, includedEquipId in ipairs(equipSuitsConfigData.includeid) do
										if includedEquipId == playerEquip:GetConfigId() then
											numOfPlayerEquipInSuits = numOfPlayerEquipInSuits + 1
											break
										end
									end
								end
							end

							for suitAttrIndex, attrData in ipairs(equipSuitsConfigData.suitsbonus) do
								local attributeText = ""
								local text = ItemManager.GetAttrText(attrData.propertydata.propertytype, attrData.propertydata.value)
								if numOfPlayerEquipInSuits < attrData.amountlimit then
									-- 未激活套装属性，灰色
									attributeText = format("[7B7979](%d%s) %s[-]", attrData.amountlimit, LocalString.EquipAttrsNeedSuitDesc, text)
								else
									-- 激活套装属性，绿色
									attributeText = format("[FF0000](%d%s) %s[-]", attrData.amountlimit, LocalString.EquipAttrsNeedSuitDesc, text)
								end
								local bReturn = true
								if suitAttrIndex == #(equipSuitsConfigData.suitsbonus) then
									bReturn = false
								end
								ItemManager.AddAttributeDescText(uiLabel_Com_Attrs, bReturn, attributeText)
							end
						end

					end
				elseif index1 == 5 then
					uiLabel_Com_Attrs.text =  "[FFFFFF]".. equip:GetIntroduction()
				end
				AdjustAttributesBGRect(listItem)
			end
			UIList_Com_Attrs.gameObject:GetComponent("UITable").repositionNow = true
		end
	else
		logError("Equip Type Error!")
	end
end

local function SetSellInfo(sellNum)
	if type(sellNum) ~= "number" or sellNum < 0 then
		logError("Var:sellNum is not a 'number' type or less than 0")
		sellNum = 0
	end
	if g_bVariableNum then
		fields.UIInput_Item_SellNumber.value = sellNum
	else
		fields.UILabel_Item_SolidSellNumber.text = sellNum
	end

	local unitPrice = 0
	if g_bVariablePrice then
		unitPrice = tonumber(fields.UILabel_Item_UnitPrice.text)
		if not unitPrice then 
			unitPrice = 0
			fields.UILabel_Item_UnitPrice.text = 0
		end
	else
		unitPrice = g_DefaultPrice
	end

	if sellNum~=nil and unitPrice~=nil then
		fields.UILabel_SolidTotalPrice.text = sellNum * unitPrice
		fields.UILabel_Item_SolidUnitPrice.text = sellNum * unitPrice
	end
	--总价不可手动修改
end

--TODO修改法宝出售时的价格
local function SetItemSellInfo(totalprice)

	printyellow("SetItemSellInfo:",totalprice)
	if totalprice ~= nil then
		fields.UILabel_SolidTotalPrice.text = totalprice
		fields.UILabel_Item_SolidUnitPrice.text = totalprice
		fields.UILabel_Item_UnitPrice.text = totalprice
	end


end

local function SetEquipPriceInfo()
	-- 装备，总价即单价，根据参数设定是否可变
	if g_bVariablePrice then
		fields.UIInput_TotalPrice.gameObject:SetActive(true)
		fields.UILabel_SolidTotalPrice.gameObject:SetActive(false)
		fields.UIInput_TotalPrice.value = g_DefaultPrice
	else
		fields.UIInput_TotalPrice.gameObject:SetActive(false)
		fields.UILabel_SolidTotalPrice.gameObject:SetActive(true)
		fields.UILabel_SolidTotalPrice.text = g_DefaultPrice
	end

	local currency = ItemManager.CreateItemBaseById(g_PriceType)
	fields.UISprite_TotalCurrency_Icon.spriteName = currency:GetIconName()
end

local function SetItemPriceInfo(item)
	-- 单价是否可变
	if g_bVariablePrice then

		fields.UIGroup_Item_UnitPrice.gameObject:SetActive(item:CanSell())
		fields.UILabel_Item_UnitPrice.gameObject:SetActive(true)

	
		
		if	g_forceShowSolidUnitPrice then
			fields.UILabel_Item_SolidUnitPrice.gameObject:SetActive(true)
			fields.UILabel_Item_PriceText.gameObject:SetActive(true)
			fields.UISprite_Item_Currency_Icon.gameObject:SetActive(true)
	    else	
			fields.UILabel_Item_SolidUnitPrice.gameObject:SetActive(false)
			fields.UILabel_Item_PriceText.gameObject:SetActive(false)
			fields.UISprite_Item_Currency_Icon.gameObject:SetActive(false)
		end
		fields.UILabel_Item_UnitPrice.text = g_DefaultPrice
	else
		

		fields.UIGroup_Item_UnitPrice.gameObject:SetActive(item:CanSell())


		
		if g_forceShowItem then
			fields.UILabel_Item_UnitPrice.gameObject:SetActive(true)
	    else 
			fields.UILabel_Item_UnitPrice.gameObject:SetActive(false)
		end
		
		fields.UILabel_Item_SolidUnitPrice.gameObject:SetActive(true)
		fields.UILabel_Item_PriceText.gameObject:SetActive(true)
		fields.UISprite_Item_Currency_Icon.gameObject:SetActive(true)
		fields.UILabel_Item_SolidUnitPrice.text = g_DefaultPrice
	end

	-- 总价不可变
	fields.UIInput_TotalPrice.gameObject:SetActive(false)
	fields.UILabel_SolidTotalPrice.gameObject:SetActive(item:CanSell() or g_bVariablePrice )
	fields.UILabel_CurrencyText.gameObject:SetActive(item:CanSell() or g_bVariablePrice )
	fields.UISprite_TotalCurrency_Icon.gameObject:SetActive(item:CanSell() or g_bVariablePrice )
	fields.UISprite_SellBG.gameObject:SetActive(item:CanSell() or g_bVariablePrice )
	fields.UILabel_SolidTotalPrice.text = g_DefaultPrice

	local currency = ItemManager.CreateItemBaseById(g_PriceType)
	fields.UISprite_Item_Currency_Icon.spriteName = currency:GetIconName()
	fields.UISprite_TotalCurrency_Icon.spriteName = currency:GetIconName()
	-- 是否可以更改数量
	fields.UIButton_ItemNum_Minus.isEnabled = g_bVariableNum
	fields.UIButton_ItemNum_Add.isEnabled = g_bVariableNum
	fields.UIInput_Item_SellNumber.gameObject:SetActive(g_bVariableNum)
	fields.UILabel_Item_SolidSellNumber.gameObject:SetActive(not g_bVariableNum)


	-- 是否显示拥有数量
	fields.UIGroup_Item_Number.gameObject:SetActive(g_forceShowItem or g_bShowNum and (g_TotalNum ~= math.huge))
	
	
	--判断是不是限购物品
	if g_LimitType ~= nil and (g_LimitType == cfg.cmd.condition.LimitType.DAY or g_LimitType ~= defineenum.LimitType.NO_LIMIT)  then
		fields.UILabel_ItemNumText.text = LocalString.LimityNum
		fields.UILabel_Item_Num.text  = (g_TotalNum == math.huge) and "" or g_TotalNum --显示限购数量
	else
		fields.UILabel_ItemNumText.text = LocalString.NO_LimityNum
		fields.UILabel_Item_Num.text = (g_BagNumInShop ~=nil) and g_BagNumInShop or (g_TotalNum == math.huge) and "" or g_TotalNum --显示背包里面的数量
	end
	
	

	EventHelper.SetClick(fields.UIButton_ItemNum_Minus, function()
		local sellNumber = 0
		if g_bVariableNum then 
			sellNumber = tonumber(fields.UIInput_Item_SellNumber.value)
			if not sellNumber then 
				sellNumber = 1
			end
		else
			sellNumber = tonumber(fields.UILabel_Item_SolidSellNumber.text)
			if not sellNumber then 
				sellNumber = 1
			end
		end
		if sellNumber > 1 and sellNumber <= g_TotalNum then
			sellNumber = sellNumber - 1
		else
			if g_TotalNum == math.huge then
				sellNumber = 1
			else
				sellNumber = g_TotalNum
			end
		end
		SetSellInfo(sellNumber)
	end )
	EventHelper.SetClick(fields.UIButton_ItemNum_Add, function()
		local sellNumber = 0
		if g_bVariableNum then 
			sellNumber = tonumber(fields.UIInput_Item_SellNumber.value)
			if not sellNumber then 
				sellNumber = 1
			end
		else
			sellNumber = tonumber(fields.UILabel_Item_SolidSellNumber.text)
			if not sellNumber then 
				sellNumber = 1
			end
		end
		if sellNumber < g_TotalNum and sellNumber >= 1 then
			sellNumber = sellNumber + 1
			if sellNumber > 9999 then
				sellNumber = 9999
			end
		else
			sellNumber = 1
		end
		SetSellInfo(sellNumber)
	end )
end

--TODO修改策划需求把法宝上架界面调整成跟装备界面一样
local function SetItemPriceInfoInExchange(item)
	-- 单价是否可变
	if g_bVariablePrice then

		fields.UIGroup_Item_UnitPrice.gameObject:SetActive(false)
		fields.UILabel_Item_UnitPrice.gameObject:SetActive(false)

	
		
		if	g_forceShowSolidUnitPrice then
			fields.UILabel_Item_SolidUnitPrice.gameObject:SetActive(true)
			fields.UILabel_Item_PriceText.gameObject:SetActive(true)
			fields.UISprite_Item_Currency_Icon.gameObject:SetActive(true)
	    else	
			fields.UILabel_Item_SolidUnitPrice.gameObject:SetActive(false)
			fields.UILabel_Item_PriceText.gameObject:SetActive(false)
			fields.UISprite_Item_Currency_Icon.gameObject:SetActive(false)
		end
		fields.UILabel_Item_UnitPrice.text = g_DefaultPrice
	else
		

		fields.UIGroup_Item_UnitPrice.gameObject:SetActive(false)
		
		if g_forceShowItem then
			fields.UILabel_Item_UnitPrice.gameObject:SetActive(true)
	    else 
			fields.UILabel_Item_UnitPrice.gameObject:SetActive(false)
		end
		
		fields.UILabel_Item_SolidUnitPrice.gameObject:SetActive(true)
		fields.UILabel_Item_PriceText.gameObject:SetActive(true)
		fields.UISprite_Item_Currency_Icon.gameObject:SetActive(true)
		fields.UILabel_Item_SolidUnitPrice.text = g_DefaultPrice
	end

	-- 总价不可变
	fields.UIInput_TotalPrice.gameObject:SetActive(false)
	fields.UILabel_SolidTotalPrice.gameObject:SetActive(item:CanSell() or g_bVariablePrice )
	fields.UILabel_CurrencyText.gameObject:SetActive(item:CanSell() or g_bVariablePrice )
	fields.UISprite_TotalCurrency_Icon.gameObject:SetActive(item:CanSell() or g_bVariablePrice )
	fields.UISprite_SellBG.gameObject:SetActive(item:CanSell() or g_bVariablePrice )
	fields.UILabel_SolidTotalPrice.text = g_DefaultPrice

	local currency = ItemManager.CreateItemBaseById(g_PriceType)
	fields.UISprite_Item_Currency_Icon.spriteName = currency:GetIconName()
	fields.UISprite_TotalCurrency_Icon.spriteName = currency:GetIconName()
	-- 是否可以更改数量
	fields.UIButton_ItemNum_Minus.isEnabled = g_bVariableNum
	fields.UIButton_ItemNum_Add.isEnabled = g_bVariableNum
	fields.UIInput_Item_SellNumber.gameObject:SetActive(g_bVariableNum)
	fields.UILabel_Item_SolidSellNumber.gameObject:SetActive(not g_bVariableNum)


	-- 是否显示拥有数量
	fields.UIGroup_Item_Number.gameObject:SetActive(false)
	fields.UIInput_TotalItemPrice.gameObject:SetActive(true)
	
	--判断是不是限购物品
	if g_LimitType ~= nil and (g_LimitType == cfg.cmd.condition.LimitType.DAY or g_LimitType ~= defineenum.LimitType.NO_LIMIT)  then
		fields.UILabel_ItemNumText.text = LocalString.LimityNum
		fields.UILabel_Item_Num.text  = (g_TotalNum == math.huge) and "" or g_TotalNum --显示限购数量
	else
		fields.UILabel_ItemNumText.text = LocalString.NO_LimityNum
		fields.UILabel_Item_Num.text = (g_BagNumInShop ~=nil) and g_BagNumInShop or (g_TotalNum == math.huge) and "" or g_TotalNum --显示背包里面的数量
	end
	
	
	--TODO修改法宝出售的总价
	 --fields.UIInput_TotalItemPrice.value
		
	EventHelper.AddInputValueChange(fields.UIInput_TotalItemPrice,function(input)
	
		local num = tonumber(input.value)
		if not num then 
			return 
		end
		printyellow("UIInput_TotalItemPrice:",num)
		SetItemSellInfo(num)
		
	end)
	
end



local function ShowEquipInfo(equipItem, playerEquipItem)
	-- 以下是右边显示界面
	local equipName = format(LocalString.BagAlert_EquipName, equipItem:GetName(), equipItem:GetAnnealLevel(), equipItem:GetPerfuseLevel())

	colorutil.SetQualityColorText(fields.UILabel_EquipName,equipItem:GetQuality(),equipName)
	fields.UISprite_Equip_Quality.spriteName = colorutil.GetQualitySprite(equipItem:GetQuality())

	fields.UILabel_EquipType.text = equipItem:GetDetailTypeName()
	fields.UITexture_Equip_Icon:SetIconTexture(equipItem:GetTextureName())

	fields.UILabel_Equip_Binding.gameObject:SetActive(equipItem:IsBound())
	fields.UISprite_Equip_Binding.gameObject:SetActive(equipItem:IsBound())

    fields.UISprite_GemstoneType1.gameObject:SetActive(false)
    fields.UISprite_GemstoneType2.gameObject:SetActive(false)

	-- 饰品没有职业限制
	if equipItem:GetProfessionLimit() == cfg.Const.NULL then
		fields.UISprite_EquipProfessionBG.gameObject:SetActive(false)
	else
		fields.UISprite_EquipProfessionBG.gameObject:SetActive(true)
		fields.UILabel_EquipProfession.text = equipItem:GetProfessionLimitName()
	end
	fields.UILabel_EquipLevel.text = equipItem:GetLevel() .. LocalString.Level
	fields.UISprite_Equip_Fighting.gameObject:SetActive(true)
	fields.UILabel_EquipPower.text = equipItem:GetPower()
	-- 设置属性面板
	SetEquipAttributePanel(equipItem, true)

	-- 以下是作为对比显示的左边界面
	if fields.UIGroup_EquipOnPlayer.gameObject.activeSelf then
		local playerEquipName = format(LocalString.BagAlert_EquipName, playerEquipItem:GetName(), g_PlayerEquipItem:GetAnnealLevel(), g_PlayerEquipItem:GetPerfuseLevel())
		colorutil.SetQualityColorText(fields.UILabel_Player_EquipName,playerEquipItem:GetQuality(),playerEquipName)
		fields.UISprite_Player_EquipQuality.spriteName = colorutil.GetQualitySprite(playerEquipItem:GetQuality())

		fields.UILabel_Player_EquipType.text = playerEquipItem:GetDetailTypeName()
		fields.UITexture_Player_EquipIcon:SetIconTexture(playerEquipItem:GetTextureName())

		fields.UILabel_Player_Binding.gameObject:SetActive(playerEquipItem:IsBound())
		fields.UISprite_Player_Binding.gameObject:SetActive(playerEquipItem:IsBound())

		if playerEquipItem:GetProfessionLimit() == cfg.Const.NULL then
			fields.UISprite_Player_EquipProfessionBG.gameObject:SetActive(false)
		else
			fields.UISprite_Player_EquipProfessionBG.gameObject:SetActive(true)
			fields.UILabel_Player_EquipProfession.text = playerEquipItem:GetProfessionLimitName()
		end

		fields.UILabel_Player_EquipLevel.text = playerEquipItem:GetLevel() .. LocalString.Level
		fields.UILabel_Player_UnitPrice.text = playerEquipItem:GetPrice()
		fields.UILabel_Player_EquipPower.text = playerEquipItem:GetPower()
		-- 设置属性面板
		SetEquipAttributePanel(playerEquipItem, false)
	end

end

local function ShowItemInfo(item)
	local name = item:GetName()
	local quality = item:GetQuality()
	local baseType = item:GetBaseType()
    local detailType = item:GetDetailType()

    fields.UISprite_EquipProfessionBG.gameObject:SetActive(true)
    fields.UISprite_GemstoneType1.gameObject:SetActive(false)
    fields.UISprite_GemstoneType2.gameObject:SetActive(false)
	
	--TODO修改策划需求把法宝上架界面调整成跟装备界面一样
	if UIManager.isshow("exchange.tabexchangesell") then
		fields.UILabel_Item_UnitPrice.gameObject:SetActive(false)
		fields.UIGroup_Number.gameObject:SetActive(false)
		fields.UIGroup_Item_Number.gameObject:SetActive(false)
	end

	if baseType == ItemEnum.ItemBaseType.Fragment then
		-- 碎片
		name = format("%s(%s)",name,LocalString.FragType) 
		if item:GetConvertNumber() <= item:GetNumber() then
			if detailType == ItemEnum.FragType.Pet then
				local  PetManager  = require"character.pet.petmanager"
				local petframs = PetManager.GetFragmentNum(g_SelectedItem.ConfigData.id)
				fields.UILabel_Item_Description.text = format(LocalString.BagAlert_NeedPetFragNum, 
				item:GetName(),colorutil.GetColorStr(colorutil.ColorType.Green_Tip,PetManager.GetFragmentNum(g_SelectedItem.ConfigData.id)).."/".. item:GetConvertNumber())
			else
				 local bagmanager    = require "character.bagmanager"
				 local trailmanFrams = bagmanager.GetItemNumById(g_SelectedItem.ConfigData.id,cfg.bag.BagType.FRAGMENT)
				fields.UILabel_Item_Description.text = format(LocalString.BagAlert_NeedFragNum, 
				item:GetName(),colorutil.GetColorStr(colorutil.ColorType.Green_Tip,trailmanFrams).."/".. item:GetConvertNumber())
			end
			
		else
			if detailType == ItemEnum.FragType.Pet then
				local colorType
				local PetManager  = require"character.pet.petmanager"
				local petframs = PetManager.GetFragmentNum(g_SelectedItem.ConfigData.id)
				if petframs < item:GetConvertNumber() then
					colorType = colorutil.ColorType.Red
				else
					colorType = colorutil.ColorType.Green_Tip
				end
				fields.UILabel_Item_Description.text = format(LocalString.BagAlert_NeedPetFragNum, 
				item:GetName(),colorutil.GetColorStr(colorType,petframs ).."/".. item:GetConvertNumber())
			else
				local colorType
				local bagmanager    = require "character.bagmanager"
				local trailmanFrams = bagmanager.GetItemNumById(g_SelectedItem.ConfigData.id,cfg.bag.BagType.FRAGMENT)
				if trailmanFrams < item:GetConvertNumber() then
					colorType = colorutil.ColorType.Red
				else
					colorType = colorutil.ColorType.Green_Tip
				end
				fields.UILabel_Item_Description.text = format(LocalString.BagAlert_NeedFragNum, 
				item:GetName(),colorutil.GetColorStr(colorType,trailmanFrams).."/".. item:GetConvertNumber())
			end
			
		end
	else
	   fields.UILabel_Item_Description.text = item:GetIntroduction()
       if detailType == ItemEnum.ItemType.Gemstone then
            fields.UISprite_EquipProfessionBG.gameObject:SetActive(false)
            fields.UISprite_GemstoneType1.gameObject:SetActive(true)
            fields.UISprite_GemstoneType2.gameObject:SetActive(true)
            fields.UILabel_GemstoneType1.text = LocalString.Gemstone_Type1[item:GetGemstoneType1()]
            fields.UILabel_GemstoneType2.text = LocalString.Gemstone_Type2[item:GetGemstoneType2()]
       end
	end
	
	if item:CanSell() or g_bVariablePrice then
		fields.UILabel_Item_CanNotSell.gameObject:SetActive(false)
	else
		fields.UILabel_Item_CanNotSell.gameObject:SetActive(true)
		if fields.UIButton_Sell.gameObject.activeSelf then 
			fields.UIButton_Sell.gameObject:SetActive(false)
		end
	end

	-- 是否为碎片
	fields.UISprite_Fragment.gameObject:SetActive(baseType == ItemEnum.ItemBaseType.Fragment)
	-- 品质框
	fields.UISprite_Equip_Quality.spriteName = colorutil.GetQualitySprite(item:GetQuality())
	-- icon
	fields.UITexture_Equip_Icon:SetIconTexture(item:GetTextureName())
	-- 根据品质显示名字颜色
	colorutil.SetQualityColorText(fields.UILabel_EquipName,quality,name)
	-- 根据绑定类型显示是否绑定
	fields.UILabel_Equip_Binding.gameObject:SetActive(item:IsBound())
	fields.UISprite_Equip_Binding.gameObject:SetActive(item:IsBound())
	fields.UILabel_EquipType.text = item:GetDetailTypeName()
	fields.UILabel_EquipProfession.text = item:GetProfessionLimitName()
	fields.UILabel_EquipLevel.text = item:GetLevel() .. LocalString.Level
	fields.UISprite_Equip_Fighting.gameObject:SetActive(false)
end
-- 按钮排序由下往上
local function SetButtons(buttons)
	if buttons then
		for i = 1, 4 do
			local buttonData = buttons[i]
			local button
			local uiLabel
			if i == 1 then
				button = fields.UIButton_Sell
				uiLabel = fields.UILabel_Sell
			elseif i == 2 then
				button = fields.UIButton_UpdateEquip
				uiLabel = fields.UILabel_UpdateEquip
			elseif i == 3 then
				button = fields.UIButton_LoadAndUnloadEquip
				uiLabel = fields.UILabel_LoadAndUnloadEquip
		  	elseif i == 4 then
		    	button = fields.UIButton_Decompose
        		uiLabel = fields.UILabel_Decompose
			end
			if buttonData then
				if buttonData.display then
					button.gameObject:SetActive(true)
					--printyellow(buttonData.text)
					uiLabel.text = buttonData.text
					EventHelper.SetClick(button, function()
						local params = { }
						local unitPrice = nil
						local sellNumber = 0

						if g_bVariableNum then
							sellNumber = tonumber(fields.UILabel_Item_SellNumber.text)
						else
							sellNumber = tonumber(fields.UILabel_Item_SolidSellNumber.text)
						end
						if g_bVariablePrice then
							if g_SelectedItem:GetBaseType() == ItemEnum.ItemBaseType.Equipment then
								-- 装备
								unitPrice = tonumber(fields.UILabel_TotalPrice.text)
							else
								-- 其他类型物品
								unitPrice = tonumber(fields.UILabel_Item_UnitPrice.text)
							end
						else
							if g_SelectedItem:GetBaseType() == ItemEnum.ItemBaseType.Equipment then
								-- 装备
								unitPrice = tonumber(fields.UILabel_SolidTotalPrice.text)
							else
								-- 其他类型物品
								unitPrice = tonumber(fields.UILabel_Item_SolidUnitPrice.text)
							end
						end
						local params = { price = unitPrice, num = sellNumber }
						buttonData.callFunc(params)--装备项链出问题
						local autoHide = true
						if buttonData.autoHide~=nil and buttonData.autoHide==false then
							autoHide = false
						end
                        ----------------------
                        -- 主动hide,注意使用 --
                        ----------------------
                        if UIManager.isshow(name) and autoHide then
						    UIManager.hide(name)
                        end
					end )
				else
					button.gameObject:SetActive(false)
				end
			else
				if button then
					button.gameObject:SetActive(false)
				end
			end
		end
	else
		fields.UIButton_Sell.gameObject:SetActive(false)
		fields.UIButton_UpdateEquip.gameObject:SetActive(false)
		fields.UIButton_LoadAndUnloadEquip.gameObject:SetActive(false)
	end
	if fields.UIButton_Sell.gameObject.activeSelf == false then
		    GameObject.Destroy(fields.UIButton_Sell.gameObject)
	end
	
	if fields.UIButton_UpdateEquip.gameObject.activeSelf == false then
		GameObject.Destroy(fields.UIButton_UpdateEquip.gameObject)
	end
	
	if fields.UIButton_LoadAndUnloadEquip.gameObject.activeSelf ==false then
		GameObject.Destroy(fields.UIButton_LoadAndUnloadEquip.gameObject)
	end
	
	if  fields.UIButton_UpdateEquip.gameObject.activeSelf == false then
		GameObject.Destroy(fields.UIButton_UpdateEquip.gameObject)
	end
	
	fields.UIGroup_Buttons.gameObject:GetComponent(UIGrid).enabled = true
end

local function destroy()
end

local function show(params)
	g_SelectedItem = params.item
	g_PlayerEquipItem = params.item2
	g_LimitType      = params.limitType
	
	if params.forceShowItem then
		g_forceShowItem = params.forceShowItem
	else
		g_forceShowItem = false
	end
	
	if params.forceShowSolidUnitPrice then
		g_forceShowSolidUnitPrice = params.forceShowSolidUnitPrice
	else
		g_forceShowSolidUnitPrice = false
	end

	if g_PlayerEquipItem ~= nil then
		fields.UIGroup_EquipOnPlayer.gameObject:SetActive(true)
	else
		fields.UIGroup_EquipOnPlayer.gameObject:SetActive(false)
	end
	
	if  params.bagNumInShop then
		g_BagNumInShop = params.bagNumInShop
	end

	if params.num then
		g_TotalNum = params.num
	else
		g_TotalNum = params.item:GetNumber()
	end
	
	if params.price then
		g_DefaultPrice = params.price
	else
		g_DefaultPrice = params.item:GetPrice()
	end
	if params.priceType then
		g_PriceType = params.priceType
	else
		g_PriceType = cfg.currency.CurrencyType.XuNiBi
	end
	if params.variablePrice then
		g_bVariablePrice = params.variablePrice
	else
		g_bVariablePrice = false
	end

	if params.variableNum ~= nil then
		g_bVariableNum = params.variableNum
	else
		g_bVariableNum = true
	end

	if params.bShowNum == nil then 
		g_bShowNum = true
	else
		g_bShowNum = params.bShowNum
	end

	if params.item:GetBaseType() == ItemEnum.ItemBaseType.Equipment then
		-- 装备
		fields.UIGroup_EquipInBag.gameObject:SetActive(true)
		fields.UIGroup_ItemInBag.gameObject:SetActive(false)
		ShowEquipInfo(g_SelectedItem, g_PlayerEquipItem)
		SetEquipPriceInfo()
	else
		-- 物品和碎片等
		fields.UIGroup_EquipInBag.gameObject:SetActive(false)
		fields.UIGroup_ItemInBag.gameObject:SetActive(true)
		ShowItemInfo(g_SelectedItem)
		
		if UIManager.isshow("exchange.tabexchangesell") then 
			--TODO修改策划需求把法宝上架界面调整成跟装备界面一样
			SetItemPriceInfoInExchange(g_SelectedItem)
			fields.UIGroup_TotalPrice.gameObject:SetActive(true)
		else
			fields.UIGroup_TotalPrice.gameObject:SetActive(false)
			SetItemPriceInfo(g_SelectedItem)
		end
		
		if params.defaultNum then
		    SetSellInfo(tonumber(params.defaultNum))
		else
		    SetSellInfo(1)
		end
	end
	SetButtons(params.buttons)
end

local function hide()
	fields.UIList_AttributePanel:Clear()
	if fields.UIGroup_EquipOnPlayer.gameObject.activeSelf then
		fields.UIList_Player_AttributePanel:Clear()
		fields.UIGroup_EquipOnPlayer.gameObject:SetActive(false)
	end
end

local function refresh(params)
end

local function update()

end

local function uishowtype()
	return UIShowType.DestroyWhenHide
end

local function init(params)
	name, gameObject, fields = Unpack(params)

	fields.UIGroup_EquipOnPlayer.gameObject:SetActive(false)

	EventHelper.SetClick(fields.UIButton_EquipAlertDlg_Close, function()
		UIManager.hide(name)
	end )

	EventHelper.SetClick(fields.UIButton_ItemAlertDlg_Close, function()
		UIManager.hide(name)
	end )

	EventHelper.SetClick(fields.UIButton_Player_Close, function()
		fields.UIGroup_EquipOnPlayer.gameObject:SetActive(false)
	end )

--	EventHelper.SetInputSubmit(fields.UIInput_Item_SellNumber,function()
--		local num = tonumber(fields.UIInput_Item_SellNumber.value)
--		if num < 0 or num > g_SelectedItem:GetNumber() then 
--			fields.UIInput_Item_SellNumber.value = 1
--		end

--	end)

--	EventHelper.SetInputSubmit(fields.UIInput_Item_UnitPrice,function()
--		local price = tonumber(fields.UIInput_Item_UnitPrice.value)
--		if price < 0 then 
--			fields.UIInput_Item_UnitPrice.value = g_DefaultPrice 
--		end

--	end)

--	EventHelper.SetInputSubmit(fields.UIInput_TotalPrice,function()
--		local price = tonumber(fields.UIInput_TotalPrice)
--		if price < 0 then
--			fields.UIInput_TotalPrice = g_DefaultPrice
--		end
--	end)
	EventHelper.AddInputValueChange(fields.UIInput_Item_SellNumber,function(input)

		local num = tonumber(input.value)
		if not num then 
			return 
		end
		if num <= 0 then
			input.value = 1 
			num = 1
		elseif num > g_TotalNum then 
			input.value = g_TotalNum
			num = g_TotalNum
		end
		
		
		
		fields.UILabel_SolidTotalPrice.text = num * fields.UILabel_Item_SolidUnitPrice.text
		fields.UILabel_Item_SolidUnitPrice.text = num * g_DefaultPrice
	end)

	--[[EventHelper.AddInputValueChange(fields.UIInput_Item_UnitPrice,function(input)

		local price = tonumber(input.value)
		if not price then
			fields.UILabel_SolidTotalPrice.text = 0
			return 
		end
		if price < 0 then 
			input.value = g_DefaultPrice 
		end
		local sellNum = 0
		if g_bVariableNum then
			sellNum = tonumber(fields.UIInput_Item_SellNumber.value)
		else
			sellNum = tonumber(fields.UILabel_Item_SolidSellNumber.text)
		end

		fields.UILabel_SolidTotalPrice.text = sellNum * tonumber(input.value)
	
	end)--]]

	EventHelper.AddInputValueChange(fields.UIInput_TotalPrice,function(input)
			print("UIInput_TotalPrice............................")
		local price = tonumber(input.value)
		if not price then
			return 
		end
		if price < 0 then
			input.value = g_DefaultPrice
		end
	end)
	gameObject.transform.position = Vector3(gameObject.transform.position.x, gameObject.transform.position.y, -5)

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
