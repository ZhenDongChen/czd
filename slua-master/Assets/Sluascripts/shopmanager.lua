local print            = print
local require          = require
local event            = require "common.event"
local math             = math
local format           = string.format
local defineenum       = require("defineenum")
local network          = require("network")
local UIManager        = require("uimanager")
local ConfigManager    = require("cfg.configmanager")
local PlayerRole       = require("character.playerrole")
local LimitTimeManager = require("limittimemanager")
local BonusManager     = require("item.bonusmanager")
local evt_bought       = event.new_simple("evt_bought")

local SHOPTYPE_ENUM2CLASS =
{
      [cfg.mall.MallType.DIAMOND_MALL]      = "cfg.mall.DiamondMall",
    --[cfg.mall.MallType.FAMILY_MALL]       = "cfg.mall.FamilyMall",
      [cfg.mall.MallType.LINJING_MALL]      = "cfg.mall.LingJingMall",
      [cfg.mall.MallType.BLACK_MALL]        = "cfg.mall.BlackMall",
      [cfg.mall.MallType.ARENA_MALL]        = "cfg.mall.ArenaMall",
      [cfg.mall.MallType.POCKET_SHOP]       = "cfg.mall.PocketShop",
      [cfg.mall.MallType.TEAM_FIGHT_SCORE]  = "cfg.mall.TeamFightScore",
}
local BlackMallItemIds = { }

local AllDataMall = { }

local function Load()
    AllDataMall = ConfigManager.getConfig("mall")
end

local function GetAllDataMall()
    if AllDataMall then
        return AllDataMall
    end
    return nil
end

local function GetMallData(index)
    if AllDataMall and AllDataMall[index] then
        return AllDataMall[index]
    end
    return nil
end

local function SortPage(val1, val2)
    if (not val1) or(not val2) or(type(val1) ~= "number") or(type(val2) ~= "number") then
        return false
    end
    if val1 == val2 then
        return false
    else
        return(val1 < val2)
    end
end

local function GetPageList(shopType)
    local pageList = { }
    local allDataMall = GetAllDataMall()

    if SHOPTYPE_ENUM2CLASS[shopType] then
        for _, item in pairs(allDataMall) do
            if (item.class) == SHOPTYPE_ENUM2CLASS[shopType] then
                local j = 0
                for i = 1, #pageList do
                    if pageList[i] == item.page then
                        break
                    end
                    j = j + 1
                end
                if j ==(#pageList) then
                    table.insert(pageList, item.page)
                end
            end
        end
    else
		print("shop type one")
        logError("Shop Type Error")
    end
    utils.table_sort(pageList, SortPage)
    return pageList
end

-- 获得指定商品的剩余可以购买数量和限定类型(所有类型商店都可用)
-- 包括无购买限定类型,shopitem 结构在mall.xml中定义
local function GetShopItemRemainingNumAndLimitType(shopItem)
    -- 所剩余限定次数取所有限定类型里限定次数最小的
    local remainingNum = math.huge
    local limitsInfo = LimitTimeManager.GetLimitTime(cfg.cmd.ConfigId.MALL, shopItem.id)
    -- oldRemainingNum用于判断所取的限定类型
    local preRemainingNum = remainingNum
    -- 默认无限制
    local limitType = defineenum.LimitType.NO_LIMIT
    for _, limit in ipairs(shopItem.limitlist.limits) do

        if limitsInfo and limitsInfo[limit.type] then
            remainingNum = math.min(remainingNum,(limit.num - limitsInfo[limit.type]))
            if remainingNum ~= preRemainingNum then
                limitType = limit.type
            end
        else
            -- 未使用或购买过，显示配置文件里的初始限定次数
            remainingNum = math.min(limit.num, remainingNum)
            if remainingNum ~= preRemainingNum then
                limitType = limit.type
            end
        end
        preRemainingNum = remainingNum

    end
    return remainingNum, limitType

end
-- 排序条件：1.限购次数为0 排在后面；都为0时，按照配置displayorder字段升序排序
-- 		2.无限购次数时，按照配置displayorder字段升序排序
local function SortItem(item1, item2)
    if (not item1) or(not item2)
        or(not item1.displayorder) or(not item2.displayorder)
        or(type(item1.displayorder) ~= "number") or(type(item2.displayorder) ~= "number") then

        return true
    end

    local remainingNum1 = GetShopItemRemainingNumAndLimitType(item1)
    local remainingNum2 = GetShopItemRemainingNumAndLimitType(item2)

    if remainingNum1 == 0 and remainingNum2 ~= 0 then
        return false
    elseif remainingNum1 ~= 0 and remainingNum2 == 0 then
        return true
    else
        if item1.displayorder == item2.displayorder then
            return true
        else
            return(item1.displayorder < item2.displayorder)
        end
    end
end

local function GetLingJingItems()
    local lingjingItems = { }
    local allDataMall = GetAllDataMall()
    for _, item in pairs(allDataMall) do
        if (item.class) == "cfg.mall.LingJingMall" then
            table.insert(lingjingItems, item)
        end
    end
    utils.table_sort(lingjingItems, SortItem)
    return lingjingItems
end

local function GetShopItems(shopType, pageType)
    local allDataMall = GetAllDataMall()
    local shopItems = { }

    if shopType == cfg.mall.MallType.BLACK_MALL then
        -- 黑市商场物品列表是从服务器获取
        for _, id in pairs(BlackMallItemIds) do
            local item = allDataMall[id]
            if item and item.class == "cfg.mall.BlackMall" and item.page == pageType then
                table.insert(shopItems, item)
            else
                logError("Shop Id in server is not BlackMall Item Id")
            end
        end
    elseif SHOPTYPE_ENUM2CLASS[shopType] then
        for _, item in pairs(allDataMall) do
            if item.class == SHOPTYPE_ENUM2CLASS[shopType] and item.page == pageType then
                table.insert(shopItems, item)
            end
        end
    else
        logError("Shop Type Error")
    end
    utils.table_sort(shopItems, SortItem)
    return shopItems
end

local function GetShopItemsWithoutPage(shopType)
    local allDataMall = GetAllDataMall()
    local shopItems = { }

    if SHOPTYPE_ENUM2CLASS[shopType] then
        for _, item in pairs(allDataMall) do
            if item.class == SHOPTYPE_ENUM2CLASS[shopType] then
                table.insert(shopItems, item)
            end
        end
    else
		print("shop type two")
        logError("Shop Type Error")
    end

    return shopItems
end

local function IsExistedAnyItemThatCanBeBought(shopType)
    -- 判断指定类型商店是否存在可以购买的物品
    local pageList = GetPageList(shopType)
    for _, pageType in ipairs(pageList) do
        local shopItems = GetShopItems(shopType, pageType)
        for i = 1, #shopItems do

            local remainingNum = 0
            local limitType = defineenum.LimitType.NO_LIMIT
            remainingNum, limitType = GetShopItemRemainingNumAndLimitType(shopItems[i])
            if remainingNum > 0 or limitType == defineenum.LimitType.NO_LIMIT then
                -- 存在可购买的商品即可返回true
                return true
            end
        end
    end
    return false
end

local function UnRead()
    local shopType = cfg.mall.MallType.DIAMOND_MALL
    return IsExistedAnyItemThatCanBeBought(shopType)
end

local function SendCCommand(sellGoodsinfo)
    local msg = lx.gs.cmd.msg.CCommand( { moduleid = sellGoodsinfo.moduleid, cmdid = sellGoodsinfo.cmdid, num = sellGoodsinfo.num })
    network.send(msg)
end

-- region onmsg
local function OnMsg_SCommand(msg)
    if msg.errcode == 0 then
        local bonusItems = BonusManager.GetItemsOfServerBonus(msg.bonus, true)
        if UIManager.isshow("cornucopia.tabconversion") then
            for i = 1, #bonusItems do
                UIManager.call("cornucopia.tabconversion", "RefreshItem", { itemId = bonusItems[i]:GetConfigId() })
            end
        end
        if msg.moduleid == cfg.cmd.ConfigId.MALL then
            evt_bought:trigger( { msg.moduleid, msg.cmdid })
        end
    end
end

local function OnMsg_SBlackMallList(msg)
    -- 0点会更新,清空数据,重新获取
    BlackMallItemIds = msg.lists
end

-- endregion onmsg

local function update()

end

local function init()
    Load()
    network.add_listeners( {
        { "lx.gs.cmd.msg.SCommand", OnMsg_SCommand },
        { "lx.gs.family.msg.SBlackMallList", OnMsg_SBlackMallList },
    } )
end


return {
    init                                = init,
    UnRead                              = UnRead,
    evt_bought                          = evt_bought,
    GetAllDataMall                      = GetAllDataMall,
    GetMallData                         = GetMallData,
    GetShopItems                        = GetShopItems,
    SendCCommand                        = SendCCommand,
    GetLingJingItems                    = GetLingJingItems,
    GetPageList                         = GetPageList,
    GetShopItemRemainingNumAndLimitType = GetShopItemRemainingNumAndLimitType,
    GetShopItemsWithoutPage             = GetShopItemsWithoutPage,
}