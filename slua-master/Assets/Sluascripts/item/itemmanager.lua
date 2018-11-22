local ItemEnum 		     = require("item.itemenum")
local ItemBase 		     = require("item.itembase")
local Item 			     = require("item.item")
local Fragment		     = require("item.fragment")
local Equipment 	     = require("item.equipment")
local ConfigManager      = require("cfg.configmanager")
local Talisman		     = require("item.talisman.talisman")
local Pet 		         = require("item.pet")

local ItemDataList = { }

local ItemClasses = 
{
	[ItemEnum.ItemBaseType.Item] 		= Item,
	[ItemEnum.ItemBaseType.Equipment] 	= Equipment,
	[ItemEnum.ItemBaseType.Fragment] 	= Fragment, --碎片
	[ItemEnum.ItemBaseType.Talisman] 	= Talisman,
	[ItemEnum.ItemBaseType.Pet] 	    = Pet,--伙伴
}

local Class2Enum =
{
	-- 物品
	["cfg.item.ItemMedicine"]   = ItemEnum.ItemType.Medicine,
	["cfg.item.ItemExperience"] = ItemEnum.ItemType.Exp,
	["cfg.item.ItemGiftPack"]   = ItemEnum.ItemType.GiftPack,
	["cfg.item.ItemEnhance"]    = ItemEnum.ItemType.Enhance,
	["cfg.item.ItemTask"]       = ItemEnum.ItemType.Task,
	["cfg.item.ItemFlower"]     = ItemEnum.ItemType.Flower,
	["cfg.item.ItemLevelUp"]    = ItemEnum.ItemType.LevelUp,
	["cfg.item.ItemDress"]      = ItemEnum.ItemType.Dress,
	["cfg.item.ItemRiding"]     = ItemEnum.ItemType.Riding,
	["cfg.item.ItemCurrency"]   = ItemEnum.ItemType.Currency,
	["cfg.item.ItemTitle"]		= ItemEnum.ItemType.Title,
    ["cfg.item.ItemGemstone"]	= ItemEnum.ItemType.Gemstone,
	["cfg.item.ItemOther"]      = ItemEnum.ItemType.Other,
	["cfg.item.ItemScene"]      = ItemEnum.ItemType.Scene,
	-- 装备
	["cfg.equip.Weapon"]        = ItemEnum.EquipType.Weapon,
	["cfg.equip.Cloth"]         = ItemEnum.EquipType.Cloth,
	["cfg.equip.Hat"]           = ItemEnum.EquipType.Hat,
	["cfg.equip.Shoe"]          = ItemEnum.EquipType.Shoe,
	-- 饰品
	["cfg.equip.Bangle"]        = ItemEnum.EquipType.Bangle,
	["cfg.equip.Necklace"]      = ItemEnum.EquipType.Necklace,
	["cfg.equip.Ring"]          = ItemEnum.EquipType.Ring,
	-- 碎片
	["cfg.pet.PetFragment"]		= ItemEnum.FragType.Pet,
	["cfg.equip.Fragment"]		= ItemEnum.FragType.Common,
}

--判断物品种类
local function GetItemType(itemId)
	local item = ItemDataList[itemId]
	if item then 
		return item.BaseType, item.DetailType, item.DetailType2
	else
		return cfg.Const.NULL, cfg.Const.NULL, cfg.Const.NULL
	end
end

--判断物品是否是货币类
local function IsCurrency(itemId)
	local classType1, classType2, classType3 = GetItemType(itemId)
	if classType1 == ItemEnum.ItemBaseType.Item and classType2 == ItemEnum.ItemType.Currency then
		return true
	end
	return false
end

-- 获取配置数据
local function GetItemData(itemId)
     local item = ItemDataList[itemId]
     return (item and item.Data)
end

--创建物品基本类
local function CreateItemBaseById(itemId,msg,num)
	if ItemDataList[itemId] then
		local baseType, detailType ,detailType2 = GetItemType(itemId)
		return ItemClasses[baseType]:CreateInstance(itemId, ItemDataList[itemId].Data, detailType, detailType2, msg, num)
	else
		logError("Item Not Exist: " .. tostring(itemId))
	end
    return nil
end

local function GetEmptyQualityColor()
	return Color(255 / 255, 255 / 255, 255 / 255, 1)
end

-- 获得钱币(通用)
local function GetCurrencyCommon(currencytype, amount)
    local currency = CreateItemBaseById(currencytype, nil, amount)
    return currency
end

-- 获得单个钱币
local function GetCurrency(condition)
    local currency = GetCurrencyCommon(condition.currencytype, condition.amount)
    return currency
end

-- 获得多种钱币
local function GetCurrencys(condition)
    local currencys = { }
    local currencylist = condition.currencys
    for _, currencyData in ipairs(currencylist) do
        local currency = GetCurrency(currencyData)
        currencys[#currencys + 1] = currency
    end
    return currencys
end
-- 获得虚拟币
local function GetXuNiBi(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.XuNiBi, condition.amount)
end
-- 获得元宝
local function GetYuanBao(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.YuanBao, condition.amount)
end
-- 获得绑定元宝
local function GetBindYuanBao(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.BindYuanBao, condition.amount)
end
-- 获得灵晶
local function GetLingJing(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.LingJing, condition.amount)
end
-- 获得经验
local function GetJingYan(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.JingYan, condition.amount)
end
-- 获得造化
local function GetZaoHua(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.ZaoHua, condition.amount)
end
-- 获得悟性
local function GetWuXing(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.WuXing, condition.amount)
end
-- 获得个人帮贡
local function GetBangGong(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.BangGong, condition.amount)
end
-- 获得帮派贡献
local function GetBangPai(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.BangPai, condition.amount)
end
-- 获得师门贡献
local function GetShiMen(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.ShiMen, condition.amount)
end
-- 获得战场声望
local function GetZhanChang(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.ZhanChang, condition.amount)
end
-- 获得竞技场声望
local function GetShengWang(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.ShengWang, condition.amount)
end
-- 获得伙伴积分
local function GetHuoBanJiFen(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.HuoBanJiFen, condition.amount)
end
-- 获得法宝积分
local function GetFaBaoJiFen(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.FaBaoJiFen, condition.amount)
end
-- 获得天赋
local function GetTianFu(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.TianFu,condition.amount)
end
-- 获得成就
local function GetChengJiu(condition)
    return GetCurrencyCommon(cfg.currency.CurrencyType.ChengJiu,condition.amount)
end
-- 获取钱币数据
local AllCurrencyConditions = 
{
    ["cfg.cmd.condition.XuNiBi"]      = GetXuNiBi,
    ["cfg.cmd.condition.YuanBao"]     = GetYuanBao,
    ["cfg.cmd.condition.BindYuanBao"] = GetBindYuanBao,
    ["cfg.cmd.condition.LingJing"]    = GetLingJing,
    ["cfg.cmd.condition.JingYan"]     = GetJingYan,
    ["cfg.cmd.condition.ZaoHua"]      = GetZaoHua,
    ["cfg.cmd.condition.WuXing"]      = GetWuXing,
    ["cfg.cmd.condition.BangGong"]    = GetBangGong,
    ["cfg.cmd.condition.BangPai"]     = GetBangPai,
    ["cfg.cmd.condition.ShiMen"]      = GetShiMen,
    ["cfg.cmd.condition.ZhanChang"]   = GetZhanChang,
    ["cfg.cmd.condition.ShengWang"]   = GetShengWang,
    ["cfg.cmd.condition.HuoBanJiFen"] = GetHuoBanJiFen,
    ["cfg.cmd.condition.FaBaoJiFen"]  = GetFaBaoJiFen,
    ["cfg.cmd.condition.TianFu"]	  = GetTianFu,
    ["cfg.cmd.condition.ChengJiu"]	  = GetChengJiu,
	["cfg.cmd.condition.Currencys"]	  = GetCurrencys,
    ["cfg.cmd.condition.Currency"]	  = GetCurrency,
}
----------------------------------------------------------------------------------------------------------
-- 返回钱币数据(例如大小图标等)
-- 参数condition为配置里的单项字段
-- 例如equip.xml中equip结构中定的字段：<field name="upgradecurrencycost" type="cfg.cmd.condition.XuNiBi" />
-- 此例子中参数condition即是upgradecurrencycost
-- 界面中需要展示消耗的货币种类和数量时,可以用此函数获取配置中货币数据
----------------------------------------------------------------------------------------------------------
local function GetCurrencyData(condition)
	if type(condition) == "table" and AllCurrencyConditions[condition.class] then
		local currencys = AllCurrencyConditions[condition.class](condition)
		return currencys
	end
	return { }
end
-- 物品类子类较多需要细分类型
local function GetDetailType2(configData)
	local detailType = Class2Enum[configData.class]
	-- 目前以下几种类型具有子类
	if detailType == ItemEnum.ItemType.Medicine then
		return configData.medicinetype
	elseif detailType == ItemEnum.ItemType.Flower then
		return configData.flowertype
	elseif detailType == ItemEnum.ItemType.LevelUp then  
		return configData.leveluptype 
	elseif detailType == ItemEnum.ItemType.Currency then
		return configData.currencytype
	else
		return cfg.Const.NULL
	end
end

-- 返回单个属性信息文本，不包括颜色信息
-- 参数bShowAttackMinMaxName设置:
-- (1)值为false or nil 合并显示：(最小攻击属性+1)，(最大攻击属性+3)合并显示为(攻击 1-2)
-- (2)值为true         单独显示：(最小攻击属性+1) 或者 (最大攻击属性+3)
local function GetAttrText(attrType, attrValue,bShowAttackMinMaxName)
	local attrTypeToText = ConfigManager.getConfigData("statustext", attrType)
	local attrText = attrTypeToText.text
	local attributeText = ""
	if not bShowAttackMinMaxName then
		if attrType == cfg.fight.AttrId.ATTACK_VALUE_MAX or attrType == cfg.fight.AttrId.ATTACK_VALUE_MIN then
			attributeText = string.format("%d", attrValue)
			return attributeText
		end
	end

	if attrTypeToText.displaytype == cfg.fight.DisplayType.NORMAL then
		attributeText = string.format("%s %+.1f", attrText, attrValue)
	elseif attrTypeToText.displaytype == cfg.fight.DisplayType.ROUND then
		attributeText = string.format("%s %+d", attrText, attrValue)
	elseif attrTypeToText.displaytype == cfg.fight.DisplayType.PERCENT then
		attributeText = string.format("%s %+.1f%%", attrText, 100 * attrValue)
	else
		logError("attribute display type error!")
	end
	return attributeText
end

-- 设置属性列表文本
local function AddAttributeDescText(UILabel_Com, bReturn, attributeText)
	UILabel_Com.text = UILabel_Com.text .. attributeText
	if bReturn then
		UILabel_Com.text = UILabel_Com.text .. "\n"
	end
end

-- 根据物品id得到获取路径
-- 参数: 1.configId：配置id,2.view_name:跳转前界面(若是tab界面，为tab所属的总界面名)
-- 参数2:用于购买后刷新当前界面或者隐藏当前界面(弹窗)
local function GetSource(configId,view_name)
	local ItemIntroduct = require("item.itemintroduction")
	local ShopManager   = require("shopmanager")
	local CheckCmd      = require("common.checkcmd")
	local UIManager		= require("uimanager")
	local FamilyManager = require("family.familymanager")
	local item = CreateItemBaseById(configId,nil,0)
	local sourceData = ConfigManager.getConfigData("itemsource",configId)
	if sourceData == nil then
		logError("GetSource Can't find source of item: " .. tostring(configId))
		return
	end
	local allDialogs = ConfigManager.getConfig("dialog")

	if sourceData.class == "cfg.item.DirectBuy" then 
		local shopItems = ShopManager.GetShopItemsWithoutPage(cfg.mall.MallType.DIAMOND_MALL)
		local sourceItem = nil
		for i = 1, #shopItems do
			local itemkey = shopItems[i].itemid.itemid
			local currency = GetCurrencyData(shopItems[i].cost)
			if itemkey == configId and currency:GetDetailType2() == cfg.currency.CurrencyType.YuanBao then 
				sourceItem = shopItems[i]
				break
			end
		end
		if not sourceItem then 
			logError("The 'source configId' data between itemsource.xlsx and mall.xlsx is not coincident!!!")
			return 
		end
		-- 剩余个数(当物品不限购时值为math.huge)
		local remainingNum, limitType = ShopManager.GetShopItemRemainingNumAndLimitType(sourceItem)
		item:AddNumber(remainingNum > 0 and remainingNum or 0)
		local currency = GetCurrencyData(sourceItem.cost)


		--发送随身商店购买物品的协议

		local buyFunc = function(params)
			local validate, info = CheckCmd.Check( { moduleid = cfg.cmd.ConfigId.MALL, cmdid = sourceItem.id, num = params.num, showsysteminfo = true })
			if validate then
				ShopManager.SendCCommand( { moduleid = cfg.cmd.ConfigId.MALL, cmdid = sourceItem.id, num = params.num })
			end
		end

		local params = {
			item = item,
			variableNum = true,
			price = currency:GetNumber(),
			priceType = currency:GetDetailType2(),
			bShowNum = (item:GetNumber() ~= math.huge) and true or false, 
			buttons =
			{
				{ display = true, text = LocalString.ShopAlert_Buy, callFunc = buyFunc },
				{ display = false, text = "", callFunc = nil },
				{ display = false, text = "", callFunc = nil },
			}
		}
		ItemIntroduct.DisplayItem(params)
		-- 购买后回调
		local eventId = nil
		eventId = ShopManager.evt_bought:add(function()
			-- 刷新信息
			-- 当前窗口是普通界面还是弹窗
			local bIsDialog = false
			if allDialogs[view_name] then 
				bIsDialog = allDialogs[view_name].showreturn
			end
			if not bIsDialog then 
				-- 弹窗
				UIManager.refresh(view_name)
			else
				if #(allDialogs[view_name].tabgroups) == 0 then 
					-- 普通界面(无tab组)
					UIManager.refresh(view_name)
				else
					-- 普通界面(有tab组),刷新正在显示的tab
					local curTabGroupIndex = UIManager.gettabindex(view_name)
					local curTabGroup = allDialogs[view_name].tabgroups[curTabGroupIndex]
					for _,tab in ipairs(curTabGroup.tabs) do
						if UIManager.isshow(tab.tabname) then 
							UIManager.refresh(tab.tabname)
						end
					end
				end
			end
			ShopManager.evt_bought:remove(eventId)
		end)

	elseif sourceData.class == "cfg.item.SingleSource" then 
		local sourceDlg = sourceData.source
		if sourceDlg.dlgname == "" then
			return
		elseif sourceDlg.dlgname == "family.dlgfamily" and not FamilyManager.InFamily() then 
			UIManager.ShowSystemFlyText(LocalString.Family.NoFamily)
			return	 
		end
		local tabIndex1 = (sourceDlg.tabindex1 ~= cfg.Const.NULL) and sourceDlg.tabindex1 or nil
		local tabIndex2 = (sourceDlg.tabindex2 ~= cfg.Const.NULL) and sourceDlg.tabindex2 or nil
		local tabIndex3 = (sourceDlg.tabindex3 ~= cfg.Const.NULL) and sourceDlg.tabindex3 or nil
		local bShowRetunBtn = allDialogs[sourceDlg.dlgname].showreturn

		-- 当前窗口是普通界面还是弹窗
		local bIsDialog = false
		if allDialogs[view_name] then 
			bIsDialog = allDialogs[view_name].showreturn
		end

		local params = { }
		params.immediate = true
        params.title = LocalString.TipText
        params.content = sourceDlg.desc
		params.callBackFunc = function() 
			if not bIsDialog then 
                -- task界面特殊处理
                if view_name ~= "dlgtask" then 
				    UIManager.hide(view_name)
                end
			end
			local ModuleLockManager  = require("ui.modulelock.modulelockmanager")
			local status = defineenum.ModuleStatus.LOCKED
			if tabIndex1 then
				status = ModuleLockManager.GetModuleStatusByIndex(sourceDlg.dlgname,tabIndex1)
			else
				status = ModuleLockManager.GetModuleStatusByType(allDialogs[sourceDlg.dlgname].parenttype)
			end
			if status == defineenum.ModuleStatus.UNLOCK then
				-- 已经开启
				-- 来源是同一个界面
				if bShowRetunBtn then 
					if view_name == sourceDlg.dlgname then 
						UIManager.hidedialog(sourceDlg.dlgname)
					end
					UIManager.showdialog(sourceDlg.dlgname,{tabindex2 = tabIndex2,tabindex3 = tabIndex3},tabIndex1) 
				else
					UIManager.show(sourceDlg.dlgname) 
				end
			elseif status == defineenum.ModuleStatus.LOCKED then
				-- 未开启，飘字
				local configData = nil
				if tabIndex1 then 	
					configData = UIManager.gettabgroup(sourceDlg.dlgname,tabIndex1)
				else
					configData = ConfigManager.getConfigData("uimainreddot",allDialogs[sourceDlg.dlgname].parenttype)
				end

				if configData then
					local conditionData = ConfigManager.getConfigData("moduleunlockcond",configData.conid)
					if conditionData then 
						local text = ""
						if conditionData.openlevel ~= 0 then
							text = (conditionData.openlevel)..(LocalString.WorldMap_OpenLevel)
						elseif conditionData.opentaskid ~= 0 then
							local taskData = ConfigManager.getConfigData("task",conditionData.opentaskid)
							if taskData then
								text = string.format(LocalString.CompleteTaskOpen,taskData.basic.name)
							end
						end
						UIManager.ShowSystemFlyText(text)
					else
						UIManager.ShowSystemFlyText(LocalString.ItemSource_Locked)
					end
				end
			end

		end

		 if configId == 10200001 then ---金币不足摇钱树特殊处理
			 UIManager.show("shakemoney.dlgmoneytree")
		 else	
		    UIManager.ShowAlertDlg(params)
		 end
	elseif sourceData.class == "cfg.item.MultiSource" then
		if #(sourceData.sourcelist) == 0 then 
			return 
		end 
		local tempItem = CreateItemBaseById(configId,nil,0)
		UIManager.show("dlgalert_itemsource",{ item = tempItem ,viewname = view_name })
	end
end
-- 根据装备类型得到获取路径
-- 参数: 1.equipType：装备类型,2.view_name:跳转前界面(若是tab界面，为tab所属的总界面名)
-- 参数2用于购买后刷新当前界面或者隐藏当前界面(弹窗)
local function GetEquipSource(equipType,view_name)
	local UIManager	= require("uimanager")
	local sourceData = ConfigManager.getConfigData("equipsource",equipType)
	if sourceData == nil then
		logError("Can't find source of equip")
		return
	end
	if #(sourceData.sourcelist) == 0 then 
		return 
	end
	UIManager.show("dlgalert_itemsource",{ equiptype = equipType, viewname = view_name })
end
 
-- 初始化配置数据表
local function init()
	-- 物品
	for configId,configData in pairs(ConfigManager.getConfig("itembasic")) do
		if configId == "10100254" then
			printyellow("10100254")
		end
		ItemDataList[configId] 			= {
			BaseType		= ItemEnum.ItemBaseType.Item,
			DetailType 		= Class2Enum[configData.class],
			DetailType2		= GetDetailType2(configData),
			Data 			= configData,
		}
	end
	-- 装备
	for configId,configData in pairs(ConfigManager.getConfig("equip")) do
		ItemDataList[configId] 			= {
			BaseType		= ItemEnum.ItemBaseType.Equipment,
			DetailType 		= Class2Enum[configData.class],
			DetailType2		= cfg.Const.NULL,
			Data 			= configData,
		}
	end
	-- 普通碎片
	for configId,configData in pairs(ConfigManager.getConfig("fragment")) do
		ItemDataList[configId] = {
			BaseType 		= ItemEnum.ItemBaseType.Fragment,
			DetailType 		= Class2Enum[configData.class],
			DetailType2		= cfg.Const.NULL,
			Data 			= configData,
		}
	end
	-- 伙伴碎片
	for configId,configData in pairs(ConfigManager.getConfig("petfragment")) do
		ItemDataList[configId] = {
			BaseType 		= ItemEnum.ItemBaseType.Fragment,
			DetailType 		= Class2Enum[configData.class],
			DetailType2		= cfg.Const.NULL,
			Data 			= configData,
		}
	end
	-- 伙伴
    for configId,configData in pairs(ConfigManager.getConfig("petbasicstatus")) do
		ItemDataList[configId] = {
			BaseType 		= ItemEnum.ItemBaseType.Pet,
			DetailType 		= cfg.Const.NULL,
			DetailType2		= cfg.Const.NULL,
			Data 			= configData,
		}
	end
	-- 法宝
    for configId,configData in pairs(ConfigManager.getConfig("talismanbasic")) do
        ItemDataList[configId] = {
            BaseType		= ItemEnum.ItemBaseType.Talisman,
            DetailType		= cfg.Const.NULL,
			DetailType2		= cfg.Const.NULL,
			Data 			= configData,
        }
    end
end

return {
	init					= init,
	GetItemType				= GetItemType,
	CreateItemBaseById 		= CreateItemBaseById,
    GetItemData				= GetItemData,
	IsCurrency				= IsCurrency,
	GetEmptyQualityColor	= GetEmptyQualityColor,
	GetCurrencyData			= GetCurrencyData,
	GetAttrText				= GetAttrText,
    AddAttributeDescText    = AddAttributeDescText,
	GetSource				= GetSource,
	GetEquipSource			= GetEquipSource,
	GetCurrencyCommon       = GetCurrencyCommon,
}
