local require       = require
local unpack        = unpack
local print         = print
local format        = string.format
local Utils         = require("common.utils")
local UIManager     = require("uimanager")
local network       = require("network")
local ConfigManager = require("cfg.configmanager")
local Jewelry       = require("item.jewelry")
local Jade          = require("item.jade")

local MAX_JEWELRY_BAG_CAPACITY = ConfigManager.getConfig("jadeenhance").packlarge

local JEWELRY_TYPE =
{
	JEWELRY_INBAG  = 1,
	JEWELRY_INJADE = 2,
}

local SORT_ORDER =
{
	DESCENDING = 1,
	ASCENDING  = 2
}
------------------------------------------------------
-- 背包里的宝珠,类型为list(主要因为界面中有按照品质的升序
-- 和降序两种方式显示宝珠，背包中jewelrylist数据仅按照服务器原始数据排列)
-- 升序和降序的排列由显示界面负责,jewelrylist中存储的是Jewelry类实例
------------------------------------------------------
local g_BagInfo = { capacity = MAX_JEWELRY_BAG_CAPACITY, jewelrylist = { } }

-- 全局变量
-- 装备在玉佩上的宝珠
local g_JadeLoadedJewelry = { }
-- 玩家玉佩信息
local g_PlayerJade = { }
-- 上次的猎命师档次
local g_JewelryHunterLevel = 1

local function GetBagJewelrySize()
	local jewelryList = g_BagInfo.jewelrylist
	local count = 0
	for _, _ in pairs(jewelryList) do
		count = count + 1
	end

	return count
end

local function GetBagTotalSize()
	return g_BagInfo.capacity
end

local function GetBagRemainingSize()
    return (GetBagTotalSize() - GetBagJewelrySize())
end

-- 按照品质降序排序
local function AscendingFunc(item1, item2)
	if (not item1) or (not item2) then
		return false
	end
	if item1:GetQuality() == item2:GetQuality() then
		return false
	else
		return(item1:GetQuality() < item2:GetQuality())
	end
end

-- 按照品质升序排序
local function DescendingFunc(item1, item2)
	if (not item1) or (not item2) then
		return false
	end
	if item1:GetQuality() == item2:GetQuality() then
		return false
	else
		return(item1:GetQuality() > item2:GetQuality())
	end
end

local function GetAllLoadedJewelries()
	return g_JadeLoadedJewelry
end

-- 默认升序排列
local function GetJewelriesSortedByQuality(order)
	
	local itemList = { }
	Utils.shallow_copy_to(g_BagInfo.jewelrylist, itemList)

	if order == SORT_ORDER.DESCENDING then
		table.sort(itemList, DescendingFunc)
	else
		table.sort(itemList, AscendingFunc)
	end
	return itemList
end

local function IsBagFull()
	local curSize = GetBagJewelrySize()
	local totalSize = GetBagTotalSize()
	if curSize == totalSize then
		return true
	end
	return false
end

local function ClearAllJewelries()
	g_BagInfo.jewelrylist = { }
end

local function AddJewelryToBag(jewelry)
	local listPos = jewelry:GetPos()
	if listPos > GetBagTotalSize() then
		logError("Jewelry bag is full or slot pos is larger than max bag capacity!")
		return
	end
	if not g_BagInfo.jewelrylist[listPos] then
		g_BagInfo.jewelrylist[listPos] = jewelry
		-- 交换类型和位置
		g_BagInfo.jewelrylist[listPos]:SetPos(listPos)
		g_BagInfo.jewelrylist[listPos]:SetType(JEWELRY_TYPE.JEWELRY_INBAG)
	else
		logError("There already exists one jewelry in bag!")
	end
end

local function RemoveJewelryByListPos(listPos)
	g_BagInfo.jewelrylist[listPos] = nil
end

local function RemoveLoadedJewelryBySlotPos(jadeSlotPos)
	g_JadeLoadedJewelry[jadeSlotPos] = nil
end
-- 装备和替换
local function LoadJewelry(jadeSlotPos, listPos)
	if g_JadeLoadedJewelry[jadeSlotPos] then
		-- 替换装备
		local temp = g_JadeLoadedJewelry[jadeSlotPos]
		g_JadeLoadedJewelry[jadeSlotPos] = g_BagInfo.jewelrylist[listPos]
		-- 交换类型和位置
		g_JadeLoadedJewelry[jadeSlotPos]:SetPos(jadeSlotPos)
		g_JadeLoadedJewelry[jadeSlotPos]:SetType(JEWELRY_TYPE.JEWELRY_INJADE)
		g_BagInfo.jewelrylist[listPos] = temp
		-- 交换类型和位置
		g_BagInfo.jewelrylist[listPos]:SetPos(listPos)
		g_BagInfo.jewelrylist[listPos]:SetType(JEWELRY_TYPE.JEWELRY_INBAG)
	else
		-- 仅装备，不替换,并删除宝珠背包中装备
		g_JadeLoadedJewelry[jadeSlotPos] = g_BagInfo.jewelrylist[listPos]
		-- 交换类型和位置
		g_JadeLoadedJewelry[jadeSlotPos]:SetPos(jadeSlotPos)
		g_JadeLoadedJewelry[jadeSlotPos]:SetType(JEWELRY_TYPE.JEWELRY_INJADE)

		table.remove(g_BagInfo.jewelrylist, listPos)
		-- 更新背包中宝珠pos信息(因为删除了listPos位置的宝珠，全部向前移动)
		for i = listPos, #g_BagInfo.jewelrylist do
			g_BagInfo.jewelrylist[i]:SetPos(i)
		end
	end
end

local function UnloadJewelry(jadeSlotPos, listPos)
	-- 装入背包
	local jewelry = g_JadeLoadedJewelry[jadeSlotPos]
	jewelry:SetPos(listPos)
	AddJewelryToBag(jewelry)
	-- 清空
	RemoveLoadedJewelryBySlotPos(jadeSlotPos)
end

local function GetLoadedJewelryBySlotPos(jadeSlotPos)
	return g_JadeLoadedJewelry[jadeSlotPos]
end

local function SetLoadedJewelryBySlotPos(jadeSlotPos, newJewelry)
	g_JadeLoadedJewelry[jadeSlotPos] = newJewelry
end

local function GetJewelryHunterLevel()
	return g_JewelryHunterLevel
end

local function SetJewelryHunterLevel(hunterLevel)
	g_JewelryHunterLevel = hunterLevel
end

local function GetPlayerJade()
	return g_PlayerJade
end

-- region msg

local function OnMsg_SGetJadeInfo(msg)
	-- print("OnMsg_SGetJadeInfo")
	-- 玩家玉佩信息
	g_PlayerJade = Jade:new(msg.jadeinfo.jade.level, msg.jadeinfo.jade.bonus)
	-- 装备的宝珠信息
	for pos, jewelryData in pairs(msg.jadeinfo.jewelry) do
		g_JadeLoadedJewelry[pos] = Jewelry:new(jewelryData.id, jewelryData.level, pos, jewelryData.exp, JEWELRY_TYPE.JEWELRY_INJADE)
	end
	-- 宝珠背包信息
	for pos, jewelryData in ipairs(msg.jadeinfo.jewelrybag) do
		local jewelry = Jewelry:new(jewelryData.id, jewelryData.level, pos, jewelryData.exp, JEWELRY_TYPE.JEWELRY_INBAG)
		AddJewelryToBag(jewelry)
	end

	-- 上次猎命师档次
	SetJewelryHunterLevel(msg.jadeinfo.jewelrygetlevel)
end
-- 刷新开孔数量
local function OnMsg_SJadeUnLockNotify(msg)
	-- print("OnMsg_SJadeUnLockNotify")
	-- print(msg.holenum)
	-- 更新jade信息
	g_PlayerJade = Jade:new(msg.jade.level,msg.jade.bonus)
	UIManager.refresh("jade.tabjade")
end
-- 玉佩培养
local function OnMsg_SEnhanceJade(msg)
	-- print("OnMsg_SEnhanceJade")
	local originalAttrValue = g_PlayerJade:GetAttrValue()
	g_PlayerJade:AddAttrValue(msg.addbonus - originalAttrValue)
	UIManager.refresh("jade.tabjade")
end
-- 玉佩进阶
local function OnMsg_SEvolveJade(msg)
	-- print("OnMsg_SEvolveJade")
	g_PlayerJade = Jade:new(msg.jade.level, msg.jade.bonus)
	UIManager.refresh("jade.tabjade")
end

local function OnMsg_SUnloadJewelry(msg)
	-- print("OnMsg_SUnloadJewelry")
	UnloadJewelry(msg.position, msg.index)
	UIManager.hide("jade.dlgalert_jewelrybag")
	UIManager.refresh("jade.tabjade")
end

local function OnMsg_SLoadJewelry(msg)
	-- print("OnMsg_SLoadJewelry")
	LoadJewelry(msg.position, msg.index)
	UIManager.hide("jade.dlgalert_jewelrybag")
	UIManager.refresh("jade.tabjade")
end
-- 猎取宝珠
local function OnMsg_SHuntJewelry(msg)
	-- print("OnMsg_SHuntJewelry")
	if msg.num ~= #(msg.jewelrylist) then
		logError("Hunter num is not coincident!")
		return
	end
	-- 设置转移后的猎命师档次
	SetJewelryHunterLevel(msg.jewelrygetlevel)
	-- 获取到的宝珠按顺序加到原有宝珠列表后面
	-- 此list用于在tabjewelry中显示用，属性pos只是list的索引值
	local jewelryList = { }

	local curBagSize = GetBagJewelrySize()
	for index, jewelryData in ipairs(msg.jewelrylist) do
		local pos = index + curBagSize
		local jewelry = Jewelry:new(jewelryData.id, jewelryData.level, pos, jewelryData.exp, JEWELRY_TYPE.JEWELRY_INBAG)
		jewelryList[#jewelryList + 1] = jewelry
		AddJewelryToBag(jewelry)
	end
	UIManager.refresh("jade.tabjewelry", { tempJewelryList = jewelryList })
end
-- 召唤猎取师
local function OnMsg_SSummonRole(msg)
	-- print("OnMsg_SSummonRole")
	SetJewelryHunterLevel(msg.role)
	UIManager.call("jade.tabjewelry","SetJewelryHunterStatus",true)
end
-- 宝珠升级
local function OnMsg_SEnhanceJewelry(msg)
	-- print("OnMsg_SEnhanceJewelry")
	local newJewelry = nil
	if msg.position == 0 then
		-- 升级的是背包里的宝珠
		newJewelry = Jewelry:new(msg.jewelry.id, msg.jewelry.level, msg.index, msg.jewelry.exp, JEWELRY_TYPE.JEWELRY_INBAG)

	else
		-- 升级的是玉佩装备的宝珠
		newJewelry = Jewelry:new(msg.jewelry.id, msg.jewelry.level, msg.position, msg.jewelry.exp, JEWELRY_TYPE.JEWELRY_INJADE)
		SetLoadedJewelryBySlotPos(msg.position, newJewelry)
	end
	-- 更新宝珠背包信息
	ClearAllJewelries()
	for pos, jewelryData in ipairs(msg.jewelrybag) do
		local jewelry = Jewelry:new(jewelryData.id, jewelryData.level, pos, jewelryData.exp, JEWELRY_TYPE.JEWELRY_INBAG)
		AddJewelryToBag(jewelry)
	end
	-- 刷新背包
	UIManager.refresh("jade.dlgalert_jewelrybag", { jewelry = newJewelry })
end

-- endregion

local function Release()
	g_BagInfo = { capacity = MAX_JEWELRY_BAG_CAPACITY, jewelrylist = { } }
	g_JadeLoadedJewelry = { }
	g_PlayerJade = { }
	g_JewelryHunterLevel = 1
end

local function OnLogout()
    Release()
end

local function init(params)
	-- gameevent.evt_update:add(Update)
	gameevent.evt_system_message:add("logout", OnLogout)
	network.add_listeners( {
		{ "lx.gs.jade.SGetJadeInfo", OnMsg_SGetJadeInfo },
		{ "lx.gs.jade.SJadeUnLockNotify", OnMsg_SJadeUnLockNotify },
		{ "lx.gs.jade.SEnhanceJade", OnMsg_SEnhanceJade },
		{ "lx.gs.jade.SEvolveJade", OnMsg_SEvolveJade },
		{ "lx.gs.jade.SUnloadJewelry", OnMsg_SUnloadJewelry },
		{ "lx.gs.jade.SLoadJewelry", OnMsg_SLoadJewelry },
		{ "lx.gs.jade.SHuntJewelry", OnMsg_SHuntJewelry },
		{ "lx.gs.jade.SSummonRole", OnMsg_SSummonRole },
		{ "lx.gs.jade.SEnhanceJewelry", OnMsg_SEnhanceJewelry },
	} )

end

local function UnRead()
	local nNum = 0
	for key,var in pairs(g_JadeLoadedJewelry)do
		nNum = nNum + 1
	end
	if nNum < 8 and GetBagJewelrySize() > 0 then
		return true
	end
	return false
end

return {
	init                        = init,
	IsBagFull                   = IsBagFull,
	GetPlayerJade               = GetPlayerJade,
	GetBagJewelrySize           = GetBagJewelrySize,
	GetBagTotalSize             = GetBagTotalSize,
    GetBagRemainingSize         = GetBagRemainingSize,
	GetAllLoadedJewelries		= GetAllLoadedJewelries,
	GetLoadedJewelryBySlotPos   = GetLoadedJewelryBySlotPos,
	GetJewelriesSortedByQuality = GetJewelriesSortedByQuality,
	UnRead = UnRead,
	-- 设置和获取猎命师等级
	GetJewelryHunterLevel       = GetJewelryHunterLevel,
	SetJewelryHunterLevel       = SetJewelryHunterLevel,
	-- 类型定义
	JEWELRY_TYPE                = JEWELRY_TYPE,
	SORT_ORDER                  = SORT_ORDER,
}

