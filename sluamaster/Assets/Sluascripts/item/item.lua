local ItemBase = require("item.itembase")
local ItemEnum = require("item.itemenum")
local ConfigManager = require("cfg.configmanager")
local CDData = require("item.itemcddata")

-- 物品类
local Item = { }
setmetatable(Item, { __index = ItemBase })
----------------------------------------------------------------------
-- 物品通用属性

-- 具体类型名称(string)
function Item:GetDetailTypeName()
	print("GetDetailTypeName")
    return self.ConfigData.displayitemtype
end
-- 立即使用(bool)
function Item:GetUseImmediately()
    return self.ConfigData.useimmediately
end
-- 是否可以批量使用(bool)
function Item:GanBatchUse()
    return self.ConfigData.batch
end
-- 获取到期时间(值为0表示无时间限制)
function Item:GetExpireTime()
    return self.ExpireTime
end

function Item:GetLevelLimit()
	return self.ConfigData.levellimit
end

----------------------------------------------------------------------

----------------------------------------------------------------------
-- 药品类

-- 附加Buff的id(int)
function Item:GetAddBuffId()
    if self:GetDetailType() == ItemEnum.ItemType.Medicine then
        return self.ConfigData.buffid
    end
    return -1
end
-- 加血量(float)
function Item:GetAddHpAmount()
    if self:GetDetailType() == ItemEnum.ItemType.Medicine then
        return self.ConfigData.HP
    end
    return 0
end

-- 加蓝量(float)
function Item:GetAddMpAmount()
    if self:GetDetailType() == ItemEnum.ItemType.Medicine then
        return self.ConfigData.MP
    end
    return 0
end

-- 类型为加血或者加蓝(string)s
function Item:GetMedicineType()
    if self:GetDetailType() == ItemEnum.ItemType.Medicine then
        return self.ConfigData.medicinetype
    end
    return  ""
end

-- CD组
function Item:GetCDGroupId()
    if self:GetDetailType() == ItemEnum.ItemType.Medicine then
        return self.ConfigData.cdgroup.groupid
    end
    return -1
end
-- 冷却时间
function Item:GetCDTime()
    if self:GetDetailType() == ItemEnum.ItemType.Medicine then
        return self.ConfigData.cdgroup.time
    end
    return 0
end
-- 获取圆形图标
function Item:GetRoundIconName()
	return self.ConfigData.roundicon
end
-- CD数据
function Item:GetCDData()
    return self.CDData
end

----------------------------------------------------------------------
-- 强化类
----------------------------------------------------------------------
-- 礼包类
----------------------------------------------------------------------
--经验类
function Item:GetEffect()
    return self.ConfigData.effect
end
----------------------------------------------------------------------

function Item:GetCurrencyType()
    return self.ConfigData.currencytype
end

function Item:GetIconName()
	return self.ConfigData.sprite
end

function Item:GetContainNum()
    return self.ConfigData.amount
end
----------------------------------------------------------------------
-- 任务类

----------------------------------------------------------------------
-- 鲜花类
function Item:GetFlowerType()
	return self.ConfigData.flowertype
end

function Item:GetFriendDegree()
	return self.ConfigData.frienddegree
end

function Item:GetImage()
	return self.ConfigData.image
end
----------------------------------------------------------------------
-- 坐骑类
function Item:GetRidingId()
    return self.ConfigData.RidingID
end
---------------------------------------------------------------------
--称号类
function Item:GetTitleId()
    return self.ConfigData.id
end
---------------------------------------------------------------------
--宝石类
function Item:GetComposedGemstoneId()
    if self:GetDetailType() == ItemEnum.ItemType.Gemstone then
        return self.ConfigData.nextid
    end
    return -1
end

function Item:GetComposeCostNum()
    if self:GetDetailType() == ItemEnum.ItemType.Gemstone then
        return self.ConfigData.composecost
    end
    return 0
end

function Item:GetGemstoneType1()
    if self:GetDetailType() == ItemEnum.ItemType.Gemstone then
        return self.ConfigData.type1
    end
    return cfg.Const.NULL
end

function Item:GetGemstoneType2()
    if self:GetDetailType() == ItemEnum.ItemType.Gemstone then
        return self.ConfigData.type2
    end
    return cfg.Const.NULL
end

function Item:GetGemstoneAttr()
    if self:GetDetailType() == ItemEnum.ItemType.Gemstone then
        self.GemstoneAttr = { }
        self.GemstoneAttr.AttrType =  self.ConfigData.property.propertytype 
        self.GemstoneAttr.AttrValue = self.ConfigData.property.value
        return self.GemstoneAttr
    end
    return { }
end

-- 场景物品
function Item:GetMineralId()
    if self:GetDetailType() == ItemEnum.ItemType.Scene then
        return self.ConfigData.mineralid
    end
end

function Item:GetActionName()
    if self:GetDetailType() == ItemEnum.ItemType.Scene then
        return self.ConfigData.actionname
    end
	return ""
end

function Item:GetPosOffset()
    if self:GetDetailType() == ItemEnum.ItemType.Scene then
        return self.ConfigData.posoffset
    end
	return 0
end
---------------------------------------------------------------------
-- 加载服务器数据
function Item:LoadFromServerMsg(serverMsg)
    self.ID         = serverMsg.itemid
    self.BagPos     = serverMsg.position or 0
    self.ExpireTime = serverMsg.expiretime
    self.Isbound    = serverMsg.isbind == 1 and true or false
end
-- 实例化
function Item:CreateInstance(configId, config, detailType, detailType2, serverMsg, number)
	
    local item = {
        ConfigId	= configId,
        BaseType	= ItemEnum.ItemBaseType.Item,
        DetailType	= detailType,
        DetailType2	= detailType2,
        ConfigData	= config,
        Number		= number or 1,
    }

    setmetatable(item, { __index = self })
    if item:GetDetailType() == ItemEnum.ItemType.Medicine then
        item.CDData = CDData:new(item:GetCDGroupId(),item:GetCDTime())
    end

    if serverMsg ~= nil then
        item:LoadFromServerMsg(serverMsg)
    end

    return item
end

return Item
