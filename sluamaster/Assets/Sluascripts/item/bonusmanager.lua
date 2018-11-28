local ItemManager = require("item.itemmanager")
local ItemEnum = require("item.itemenum")
local ItemIntroduc = require("item.itemintroduction")
local PlayerRole = require("character.playerrole")
local ConfigManager = require("cfg.configmanager")
local ColorUtil = require("common.colorutil")
local EventHelper = UIEventListenerHelper

-- 获得单个物品(单个id)
local function GetOneItem(bonusaction)
    local items = {}
    local itemid = bonusaction.itemid
    local item = ItemManager.CreateItemBaseById(itemid)
    items[#items + 1] = item
    return items
end
-- 获得多个物品(多个id)
local function GetOneItems(bonusaction)
    local items = { }
    local itemids = bonusaction.items
    for _, itemid in ipairs(itemids) do
        local item = ItemManager.CreateItemBaseById(itemid)
        items[#items + 1] = item
    end
    return items
end
-- 获得单个物品(单个{id,amount})
local function GetItem(bonusaction)
    local items = {}
    local itemid = bonusaction.itemid
    local itemamount = bonusaction.amount
    local item = ItemManager.CreateItemBaseById(itemid, nil, itemamount)
    items[#items + 1] = item
    return items
end
-- 获得多个物品(多个{id,amount})
local function GetItems(bonusaction)
    local items = { }
    local itemlist = bonusaction.items
    for _, item in ipairs(itemlist) do
        local its = GetItem(item)
        for _,it in ipairs(its) do
            items[#items + 1] = it
        end
    end
    return items
end

-- 获取随机奖励的全部物品(等概率获取)
local function GetRandomItems(bonusaction)
    local items = { }
    local itemids = bonusaction.items
    for _, itemid in ipairs(itemids) do
        local item = ItemManager.CreateItemBaseById(itemid)
        items[#items + 1] = item
    end
    return items
end

-- 获得钱币(通用)
local function GetCurrencyCommon(currencytype, amount)
    local items = {}
    local itemamount = amount
    local item = ItemManager.CreateItemBaseById(currencytype, nil, itemamount)
    items[#items + 1] = item
    return items
end
-- 获得单个钱币
local function GetCurrency(bonusaction)
    local currencys = GetCurrencyCommon(bonusaction.type, bonusaction.amount)
    return currencys
end
-- 获得多种钱币
local function GetCurrencys(bonusaction)
    local items = { }
    local itemlist = bonusaction.currencys
    for _, item in ipairs(itemlist) do
        local currencys = GetCurrency(item)
        for _,currency in ipairs(currencys) do
            items[#items + 1] = currency
        end
    end
    return items
end

-- 获得虚拟币
local function GetXuNiBi(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.XuNiBi, bonusaction.amount)
end
-- 获得元宝
local function GetYuanBao(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.YuanBao, bonusaction.amount)
end
-- 获得绑定元宝
local function GetBindYuanBao(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.BindYuanBao, bonusaction.amount)
end
-- 获得灵晶
local function GetLingJing(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.LingJing, bonusaction.amount)
end
-- 获得经验
local function GetJingYan(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.JingYan, bonusaction.amount)
end
-- 获得造化
local function GetZaoHua(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.ZaoHua, bonusaction.amount)
end
-- 获得悟性
local function GetWuXing(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.WuXing, bonusaction.amount)
end
-- 获得个人帮贡
local function GetBangGong(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.BangGong, bonusaction.amount)
end
-- 获得帮派贡献
local function GetBangPai(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.BangPai, bonusaction.amount)
end
-- 获得师门贡献
local function GetShiMen(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.ShiMen, bonusaction.amount)
end
-- 获得战场声望
local function GetZhanChang(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.ZhanChang, bonusaction.amount)
end
-- 获得竞技场声望
local function GetShengWang(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.ShengWang, bonusaction.amount)
end
-- 获得伙伴积分
local function GetHuoBanJiFen(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.HuoBanJiFen, bonusaction.amount)
end
-- 获得法宝积分
local function GetFaBaoJiFen(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.FaBaoJiFen, bonusaction.amount)
end
-- 获得天赋
local function GetTianFu(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.TianFu,bonusaction.amount)
end
-- 获得成就
local function GetChengJiu(bonusaction)
    return GetCurrencyCommon(cfg.currency.CurrencyType.ChengJiu,bonusaction.amount)
end
-- 获得bonus通用方法
local function GetBonusItems(bonusaction)
    local items = {}
	-- printt(bonusaction)
    local bonusitems = AllBonusActions[bonusaction.class](bonusaction)
    for _,item in ipairs(bonusitems) do
        items[#items + 1] = item
    end
    return items
end
-- 获得multi bonus通用方法
local function GetMultiBonusItems(bonusaction)
    local items = {}
    for _, item in ipairs(bonusaction.bonuss) do
        local bonusitems = GetBonusItems(item)
        for _,bonusitem in ipairs(bonusitems) do
            items[#items + 1] = bonusitem
        end
    end
    return items
end
-- 获取随机奖励的全部物品，仅在获取前展示使用，与
-- 最终获得的奖励可能不同(存在随机抽取概率)
local function GetRandomBonusItems(bonusaction)
    local items = {}
    for _, bonusData in ipairs(bonusaction.bonuss) do
        local bonusitems = GetBonusItems(bonusData.bonus)
        for _,bonusitem in ipairs(bonusitems) do
            items[#items + 1] = bonusitem
        end
    end
    return items
end

-- 获取重复奖励(指操作重复，例如结构中num=5，意味着此操作执行5次，每次获取奖励可能不同)
local function GetRepeatBonus(bonusaction)
    local items = {}
    local bonusitems = GetBonusItems(bonusaction.bonus)
    for _,bonusitem in ipairs(bonusitems) do
        items[#items + 1] = bonusitem
    end
    return items
end

-- 获取Copy奖励(数量重复，例如结构中num = 5，即结构中每个id的物品数量x5)
local function GetCopyBonus(bonusaction)
    local items = {}
    local bonusitems = GetBonusItems(bonusaction.bonus)
    for _,bonusitem in ipairs(bonusitems) do
		local itemNum = bonusitem:GetNumber()
		bonusitem:AddNumber((bonusaction.num-1)*itemNum)
        items[#items + 1] = bonusitem
    end
    return items
end

-- 获取掉落奖励
local function GetDropBonus(bonusaction)
	local bonus = ConfigManager.getConfigData("drop",bonusaction.dropid).droplist
	local items = {}
    local bonusitems = GetBonusItems(bonus)
    for _,bonusitem in ipairs(bonusitems) do
        items[#items + 1] = bonusitem
    end
    return items
end

local function GetCareerBonus(bonusaction)
    local items = {}
    local bonusitems = GetBonusItems(bonusaction.bonus)
    for _,bonusitem in ipairs(bonusitems) do
        items[#items + 1] = bonusitem
    end
    return items
end

local function init()
    -- 初始化bonus类型名
    AllBonuses = {
        ["cfg.bonus.BeginnerBonus"]   = ConfigManager.getConfig("beginnerbonus"),
        ["cfg.bonus.MonthBonus"]      = ConfigManager.getConfig("monthbonus"),
        ["cfg.bonus.OnlineTimeBonus"] = ConfigManager.getConfig("onlinetimebonus"),
        ["cfg.bonus.MonthlyCard"]     = ConfigManager.getConfig("monthlycard"),
        ["cfg.bonus.GrowPlan"]        = ConfigManager.getConfig("growplan"),
        ["cfg.bonus.Wish"]            = ConfigManager.getConfig("wish"),
        ["cfg.bonus.FamilyBonus"]     = ConfigManager.getConfig("familybonus"),
        ["cfg.bonus.ChargeBonus"]     = ConfigManager.getConfig("familybonus"),

    }
    -- 初始化bonus结果类型
    AllBonusActions = {
        ["cfg.cmd.action.OneItem"]     = GetOneItem,
        ["cfg.cmd.action.OneItems"]    = GetOneItems,
        ["cfg.cmd.action.Item"]        = GetItem,
        ["cfg.cmd.action.Items"]       = GetItems,
        ["cfg.cmd.action.MultiBonus"]  = GetMultiBonusItems,
        ["cfg.cmd.action.RandomBonus"] = GetRandomBonusItems,
        ["cfg.cmd.action.Bonus"]       = GetBonusItems,
		["cfg.cmd.action.RandomItems"] = GetRandomItems,
		["cfg.cmd.action.CopyBonus"]   = GetCopyBonus,
		["cfg.cmd.action.RepeatBonus"] = GetRepeatBonus,
		["cfg.cmd.action.Drop"]		   = GetDropBonus,
        ["cfg.cmd.action.Currencys"]   = GetCurrencys,
        ["cfg.cmd.action.Currency"]    = GetCurrency,
        ["cfg.cmd.action.CareerBonus"] = GetCareerBonus,
        -- 钱币
        ["cfg.cmd.action.XuNiBi"]      = GetXuNiBi,
        ["cfg.cmd.action.YuanBao"]     = GetYuanBao,
        ["cfg.cmd.action.BindYuanBao"] = GetBindYuanBao,
        ["cfg.cmd.action.LingJing"]    = GetLingJing,
        ["cfg.cmd.action.JingYan"]     = GetJingYan,
        ["cfg.cmd.action.ZaoHua"]      = GetZaoHua,
        ["cfg.cmd.action.WuXing"]      = GetWuXing,
        ["cfg.cmd.action.BangGong"]    = GetBangGong,
        ["cfg.cmd.action.BangPai"]     = GetBangPai,
        ["cfg.cmd.action.ShiMen"]      = GetShiMen,
        ["cfg.cmd.action.ZhanChang"]   = GetZhanChang,
        ["cfg.cmd.action.ShengWang"]   = GetShengWang,
        ["cfg.cmd.action.HuoBanJiFen"] = GetHuoBanJiFen,
        ["cfg.cmd.action.FaBaoJiFen"]  = GetFaBaoJiFen,
        ["cfg.cmd.action.TianFu"]	   = GetTianFu,
        ["cfg.cmd.action.ChengJiu"]	   = GetChengJiu,
    }
end

----------------------------------------------------------------------
--[[
功能：获取.\csv\bonus\bonus.xml中描述的奖品列表,此函数会获取相应csvId对应的所有bonus列表
入参：params{bonustype,csvid}
      bonustype          type:string         奖品类型名称      【必填】
      csvid             type:int(csv的index)                  【必填】
返回值：
      items type：list(目录./item中定义的类型)
--]]
----------------------------------------------------------------------
local function GetItemsOfBonus(params)
    local items = {}
    if not params.bonustype or not params.csvid then
        log("please specify bonus type or csvid")
        return items
    end
    if AllBonuses[params.bonustype] then
        local bonuses = AllBonuses[params.bonustype][params.csvid]
        if bonuses then
            for k,bonusaction in pairs(bonuses) do
                if type(bonusaction) == "table" and AllBonusActions[bonusaction.class] then
                    local bonusitems = AllBonusActions[bonusaction.class](bonusaction)
                    for _,bonusitem in ipairs(bonusitems) do
						-- 默认情况下奖励物品都是绑定的(钱币类除外)，非绑定奖励在具体界面中另需设置
						if bonusitem:GetDetailType() ~= ItemEnum.ItemType.Currency then 
							bonusitem:SetBound(true)
						end	
                        items[#items + 1] = bonusitem
                    end
                end
            end
            return items
        end
    end
    return items
end
----------------------------------------------------------------------
--[[
功能：获取配置的bonus子项中所包含的奖励物品列表
入参：配置子项
返回值：
      items type：list(目录./item中定义的类型)
--]]
----------------------------------------------------------------------

local function GetItemsOfSingleBonus(bonusaction)
	local items = {}
	if type(bonusaction) == "table" and AllBonusActions[bonusaction.class] then
		local bonusitems = AllBonusActions[bonusaction.class](bonusaction)
		for _,bonusitem in ipairs(bonusitems) do
			-- 默认情况下奖励物品都是绑定的(钱币类除外)，非绑定奖励在具体界面中另需设置
			if bonusitem:GetDetailType() ~= ItemEnum.ItemType.Currency then 
				bonusitem:SetBound(true)
			end
			items[#items + 1] = bonusitem
		end
	end
	return items

end
--------------------------------------------------------------
--[[
功能：根据配置bonus的子项，返回物品表，例如组队推图副本TeamStoryEctype中某个csvid对应的bonus子项有3个
分别为starbonus，ectypedrop，ectypeminbonus，需要获取哪个子项的bonus物品列表即可将其当做参数传入，例如
local itemlist = GetItemsByBonusConfig(某个csvid对应的配置.starbonus)即可得到对应子项的bonus表
]]
local ConfigBonusActions



local function GetConfigBonusFixCurrency(bonus,type)
    local list = {}
    table.insert(list,ItemManager.CreateItemBaseById(type, nil, bonus.amount))
    return list
end

local function GetConfigBonusCurrency(bonus,params)
    local list = {}
    table.insert(list,ItemManager.CreateItemBaseById(bonus.type, nil, bonus.amount))
    return list
end

local function GetConfigBonusCurrencys(bonus,params)
    local list = {}
    for _,subBonus in pairs(bonus) do
        local sublist = GetConfigBonusCurrencyGroup("cfg.cmd.action.Currency",subBonus)
        for _,item in pairs(sublist) do
            table.insert(list,item)
        end
    end
    return list
end

local function GetConfigBonusOneItem(bonus, params)
    local list = {}
    table.insert(list,ItemManager.CreateItemBaseById(bonus.itemid, nil, 1))
    return list
end

local function GetConfigBonusOneItems(bonus, params)
    local list = {}
    for i,id in pairs(bonus.items) do
        table.insert(list,ItemManager.CreateItemBaseById(id, nil, 1))
    end
    return list
end

local function GetConfigBonusItem(bonus, params)
    local list = {}
    table.insert(list,ItemManager.CreateItemBaseById(bonus.itemid, nil, bonus.amount))
    return list
end

local function GetConfigBonusItems(bonus, params)
    local list = {}
    for _,subBonus in pairs(bonus.items) do
        local sublist = GetConfigBonusItem(subBonus)
        for _,item in pairs(sublist) do
            table.insert(list,item)
        end
    end
    return list
end

local function GetConfigBonus(bonus, params)
    local list = {}
    if ConfigBonusActions[bonus.class] then
        list = ConfigBonusActions[bonus.class].func(bonus, ConfigBonusActions[bonus.class].params)
    end
    return list
end

local function GetConfigMultiBonus(bonus, params)
    local list = {}
    for _,subBonus in pairs(bonus.bonuss) do
        if ConfigBonusActions[subBonus.class] then
            local sublist = ConfigBonusActions[subBonus.class].func(subBonus, ConfigBonusActions[subBonus.class].params)
            for _,item in pairs(sublist) do
                table.insert(list,item)
            end
        end
    end
    return list
end


ConfigBonusActions = {
    ["cfg.cmd.action.OneItem"]     = { func = GetConfigBonusOneItem,    params = nil},
    ["cfg.cmd.action.OneItems"]    = { func = GetConfigBonusOneItems,   params = nil},
    ["cfg.cmd.action.Item"]        = { func = GetConfigBonusItem,       params = nil},
    ["cfg.cmd.action.Items"]       = { func = GetConfigBonusItems,      params = nil},

    ["cfg.cmd.action.MultiBonus"]  = { func = GetConfigMultiBonus,      params = nil},
    ["cfg.cmd.action.Bonus"]       = { func = GetConfigBonus,           params = nil},


    ["cfg.cmd.action.Currencys"]   = { func = GetConfigBonusCurrencys,  params = nil},
    ["cfg.cmd.action.Currency"]    = { func = GetConfigBonusCurrency,   params = nil},
    -- 钱币
    ["cfg.cmd.action.XuNiBi"]      = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.XuNiBi },
    ["cfg.cmd.action.YuanBao"]     = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.YuanBao },
    ["cfg.cmd.action.BindYuanBao"] = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.BindYuanBao },
    ["cfg.cmd.action.LingJing"]    = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.LingJing },
    ["cfg.cmd.action.JingYan"]     = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.JingYan },
    ["cfg.cmd.action.ZaoHua"]      = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.ZaoHua },
    ["cfg.cmd.action.WuXing"]      = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.WuXing },
    ["cfg.cmd.action.BangGong"]    = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.BangGong },
    ["cfg.cmd.action.BangPai"]     = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.BangPai },
    ["cfg.cmd.action.ShiMen"]      = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.ShiMen },
    ["cfg.cmd.action.ZhanChang"]   = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.ZhanChang },
    ["cfg.cmd.action.ShengWang"]   = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.ShengWang },
    ["cfg.cmd.action.HuoBanJiFen"] = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.HuoBanJiFen },
    ["cfg.cmd.action.FaBaoJiFen"]  = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.FaBaoJiFen },
	["cfg.cmd.action.LingShi"]      = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.LingShi },
	["cfg.cmd.action.XuanJing"]      = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.XuanJing },
	["cfg.cmd.action.XianYu"]      = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.XianYu },
    ["cfg.cmd.condition.TianFu"]   = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.TianFu },
    ["cfg.cmd.condition.ChengJiu"] = { func = GetConfigBonusFixCurrency,params = cfg.currency.CurrencyType.ChengJiu },
	
}

 

local function GetItemsByBonusConfig(bonus)
    local items
    if ConfigBonusActions[bonus.class] then
        items = ConfigBonusActions[bonus.class].func(bonus, ConfigBonusActions[bonus.class].params)
    end
   -- if bonus.bindtype ~= nil then
    for i, item in pairs(items) do
        if bonus.bindtype ~= nil then
            printyellow("Bonus bindtype: ===============================>")
            item:SetBound(bonus.bindtype == cfg.item.EItemBindType.BOUND)
        else
            item:SetBound(true)
        end
    end
  --  end
    return items
end









----------------------
--[[
功能:获取从服务器返回的bonus中的物品列表（包含所有）
参数bonus结构定义在protocol.gsd.xml 中"lx.gs.bonus.msg.Bonus"
--]]
-------------------
local function GetItemsOfServerBonus(bonus,exceptCurrency)
    local items={}
    for csvid,num in pairs(bonus.items) do

        local item = ItemManager.CreateItemBaseById(csvid,nil,num)
            if bonus.bindtype ~= nil then
                item:SetBound(bonus.bindtype == cfg.item.EItemBindType.BOUND)
            end
		    if item and not (item:GetDetailType() == ItemEnum.ItemType.Currency and exceptCurrency == true) then
			     table.insert(items,item)
		    end
    end
    return items
end
----------------------
--[[
功能:获取从服务器返回的bonus中的物品列表（包含除货币外的所有物品）
参数bonus结构定义在protocol.gsd.xml 中"lx.gs.bonus.msg.Bonus"
--]]
-------------------
local function GetItemsOfServerBonusExceptCurrency(bonus)
    return GetItemsOfServerBonus(bonus,true)
end
----------------------
--[[
功能:根据货币类型获取从服务器返回的bonus中的货币数量
参数bonus结构定义在protocol.gsd.xml 中"lx.gs.bonus.msg.Bonus"
--]]
-------------------
local function GetCurrencyValueOfServerBonusByType(bonus,currencyType)
    local result=0
    for csvid,num in pairs(bonus.items) do
        local item = ItemManager.CreateItemBaseById(csvid,nil,num)
        if item and (item:GetDetailType() == ItemEnum.ItemType.Currency) and (currencyType == csvid) then
           result=num
        end
    end
    return result
end

-----------
--[[
功能:根据类型设置货币图标
--]]
-----------
local function SetCurrencyIcon(currencyType,uiSprite)
    if currencyType == cfg.currency.CurrencyType.XuNiBi then
        uiSprite.spriteName = "Sprite_Icon_Money"
    elseif currencyType == cfg.currency.CurrencyType.YuanBao then
        uiSprite.spriteName = "Sprite_Icon_Diamond"
    elseif currencyType == cfg.currency.CurrencyType.BindYuanBao then
        uiSprite.spriteName = "Sprite_Icon_Diamondlock"
    elseif currencyType == cfg.currency.CurrencyType.LingJing then
        uiSprite.spriteName = "Icon_Jewel"
    else
        logError("Currency type error!")
    end
end

-----------
--[[
功能:设置某个UIListItem来展示对应的奖励物品信息
--]]
-----------
local function SetRewardItemShow(textureIcon, spriteQuality, itemData)
    if textureIcon then
        textureIcon:SetIconTexture(itemData:GetTextureName())
    end
    if spriteQuality then
        if itemData:GetQuality() then
            spriteQuality.spriteName = colorutil.GetQualitySprite(itemData:GetQuality())
        end
    end
end

local function SetRewardItemSimple(listItem,itemData,params)
    local baseType = itemData:GetBaseType()
    local UITexture_Icon = listItem.Controls["UITexture_Icon"]
    UITexture_Icon:SetIconTexture(itemData:GetTextureName())
    if params and params.setGray == true then
        ColorUtil.SetTextureColorGray(UITexture_Icon, true)
    else
        ColorUtil.SetTextureColorGray(UITexture_Icon, false)
    end
    local UISprite_Fragment=listItem.Controls["UISprite_Fragment"]
    if UISprite_Fragment then
        UISprite_Fragment.gameObject:SetActive(baseType==ItemEnum.ItemBaseType.Fragment)
    end
    local spriteQuality = listItem.Controls["UISprite_Quality"]
    if spriteQuality then
        if itemData:GetQuality() then
            spriteQuality.spriteName = colorutil.GetQualitySprite(itemData:GetQuality())
        end
    end
end

local function SetEmptyItem(listItem)
    local uiLabel_Amount = listItem.Controls["UILabel_Amount"]
    if uiLabel_Amount then
        uiLabel_Amount.gameObject:SetActive(false)
    end

    local UITexture_Icon = listItem.Controls["UITexture_Icon"]
    if UITexture_Icon then
        UITexture_Icon:SetIconTexture("")
    end

    local UISprite_Fragment=listItem.Controls["UISprite_Fragment"]
    if UISprite_Fragment then
        UISprite_Fragment.gameObject:SetActive(false)
    end

    local spriteAnnealLevel = listItem.Controls["UISprite_AnnealLevel"]
    local labelAnnealLevel = listItem.Controls["UILabel_AnnealLevel"]
    if spriteAnnealLevel then
        spriteAnnealLevel.gameObject:SetActive(false)
    end
    if labelAnnealLevel then
        labelAnnealLevel.gameObject:SetActive(false)
    end

    local spriteRedMask = listItem.Controls["UISprite_RedMask"]
    if spriteRedMask then
        spriteRedMask.gameObject:SetActive(false)
    end

    local spriteQuality = listItem.Controls["UISprite_Quality"]
    if spriteQuality then
        spriteQuality.spriteName = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
    end
    EventHelper.SetClick(listItem,function()

    end)

end




local function SetRewardItem(listItem,itemData,params)
    SetRewardItemSimple(listItem,itemData,params)
    local baseType = itemData:GetBaseType()

    local uiLabel_Amount = listItem.Controls["UILabel_Amount"]
    if uiLabel_Amount then
        uiLabel_Amount.gameObject:SetActive(baseType~=ItemEnum.ItemBaseType.Equipment)
        if params and (params.notShowAmount) then
            uiLabel_Amount.gameObject:SetActive(false)
        else
            uiLabel_Amount.gameObject:SetActive(true)
            listItem:SetText("UILabel_Amount", itemData:GetNumber())
        end
    end

    local spriteAnnealLevel = listItem.Controls["UISprite_AnnealLevel"]
    local labelAnnealLevel = listItem.Controls["UILabel_AnnealLevel"]
    if spriteAnnealLevel and labelAnnealLevel then
        if baseType==ItemEnum.ItemBaseType.Equipment then
            if itemData:GetAnnealLevel() == nil or itemData:GetAnnealLevel() == 0 then
                spriteAnnealLevel.gameObject:SetActive(false)
                labelAnnealLevel.gameObject:SetActive(false)
            else
                spriteAnnealLevel.gameObject:SetActive(true)
                labelAnnealLevel.gameObject:SetActive(true)
            end


            if itemData:GetAnnealLevel() then
                labelAnnealLevel.text = "+" .. itemData:GetAnnealLevel()
            else
                labelAnnealLevel.text = ""
            end
        else
            labelAnnealLevel.gameObject:SetActive(false)
        end
    end

    local spriteRedMask = listItem.Controls["UISprite_RedMask"]
    if spriteRedMask then
        if baseType == ItemEnum.ItemBaseType.Fragment then
            if itemData:GetProfessionLimit() ~= cfg.Const.NULL and itemData:GetProfessionLimit() ~= PlayerRole:Instance().m_Profession then
                spriteRedMask.gameObject:SetActive(true)
            end
        elseif params and params.showRedMask then
            spriteRedMask.gameObject:SetActive(true)
        else
            spriteRedMask.gameObject:SetActive(false)
        end

    end

    local spriteBinding = listItem.Controls["UISprite_Binding"]
    if spriteBinding then
        if itemData.IsBound and itemData:IsBound() == true then
            if ItemManager.IsCurrency(itemData:GetConfigId()) ~= true then
                spriteBinding.gameObject:SetActive(true)
            else
                spriteBinding.gameObject:SetActive(false)
            end
        else
            spriteBinding.gameObject:SetActive(false)
        end
    end


    if (params and (not params.notSetClick)) or (params==nil) then
        EventHelper.SetClick(listItem,function()
            local params={item=itemData,buttons={{display=false,text="",callFunc=nil},{display=false,text="",callFunc=nil}}}
            ItemIntroduc.DisplayBriefItem(params)
        end)
    end
end

return{
    init                                = init,
    GetItemsOfBonus                     = GetItemsOfBonus,
	GetItemsOfSingleBonus               = GetItemsOfSingleBonus,
    GetItemsOfServerBonus               = GetItemsOfServerBonus,
    GetItemsOfServerBonusExceptCurrency = GetItemsOfServerBonusExceptCurrency,
    GetCurrencyValueOfServerBonusByType = GetCurrencyValueOfServerBonusByType,
    SetRewardItemSimple                 = SetRewardItemSimple,
    SetRewardItem                       = SetRewardItem,
    SetCurrencyIcon                     = SetCurrencyIcon,
    GetItemsByBonusConfig               = GetItemsByBonusConfig,
    GetMultiBonusItems                  = GetMultiBonusItems,
    SetRewardItemShow                   = SetRewardItemShow,
    SetEmptyItem                        = SetEmptyItem,
	GetItems							= GetItems,
}
