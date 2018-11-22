
--注释：请使用枚举类（数字参考用，以后数字可能会变动）
--注意：枚举值ItemType,EquipType和FragType必须不一样
--物品基础类型
local ItemBaseType = enum 
{
    "Item      = 1",    --物品
    "Equipment = 2",    --装备
    "Fragment  = 3",	--碎片
    "Talisman  = 4",	--法宝
    "Pet       = 5",	--伙伴
}
--物品类型
local ItemType = enum
{  
    "Medicine  = 1",	--药品
    "Currency  = 2",	--钱币
    "GiftPack  = 3",	--礼包
    "Enhance   = 4",	--强化道具
    "Exp	   = 5",	--经验道具
    "Task      = 6",	--任务物品
    "Flower    = 7",    --鲜花
    "Dress     = 8",    --时装
    "Riding    = 9",	--坐骑
	"LevelUp   = 10",	--升级道具
	"Title	   = 11",	--称号
    "Gemstone  = 12",	--宝石
	"Other     = 13",	--其他
	"Scene     = 14",	--场景物品

}
--装备类型(必须与equip.xml枚举值一致)
local EquipType =
{
    --首饰
    Bangle   = cfg.item.EItemType.BANGLE,		--手镯
    Necklace = cfg.item.EItemType.NECKLACE,     --项链
    Ring     = cfg.item.EItemType.RING,			--戒指
    --四大件
    Weapon   = cfg.item.EItemType.WEAPON,		--武器
    Cloth    = cfg.item.EItemType.CLOTH,		--衣服
    Hat      = cfg.item.EItemType.HAT,			--帽子
    Shoe     = cfg.item.EItemType.SHOE,			--鞋子
}

local FragType = enum {
    "Common  = 30",	--普通碎片
    "Pet	 = 31",	--伙伴碎片
}

--五行属性
local FiveElements = enum {
    "Metal = 1",
    "Wood  = 2",
    "Water = 3",
    "Fire  = 4",
    "Earth = 5",
}

return {
    ItemBaseType    = ItemBaseType,
    ItemType        = ItemType,
    EquipType		= EquipType,
	FragType		= FragType,
    FiveElements    = FiveElements,
}