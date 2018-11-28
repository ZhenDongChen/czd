local print = print
local require = require
local ConfigManager = require("cfg.configmanager")
local ItemEnum = require("item.itemenum")
local DefineEnum = require("defineenum")

-- 物品基础类
local ItemBase = { }
-- 获取类型
function ItemBase:GetClassType()
    return self.ConfigData.class
end
-- 基础类型
function ItemBase:GetBaseType()
    return self.BaseType
end
-- 具体类型   是宠物、装备、碎片、物品
function ItemBase:GetDetailType()
    return self.DetailType
end
-- 具体类型2
function ItemBase:GetDetailType2()
    return self.DetailType2
end
-- 获取配置信息
function ItemBase:GetConfigData()
    return self.ConfigData
end
-- 获取配置Id
function ItemBase:GetConfigId()
    return self.ConfigId
end
function ItemBase:GetId()
    return self.ID
end
-- 获取图标地址
function ItemBase:GetIconPath()
	return self.ConfigData.icon
end
-- 获取名称
function ItemBase:GetName()
    return self.ConfigData.name
end


-- 获取等级
function ItemBase:GetLevel()
    return self.ConfigData.level
end
-- 获取品质
function ItemBase:GetQuality()
    return self.ConfigData.quality
end


-- 获取价格
function ItemBase:GetPrice()
    return self.ConfigData.prize
end
-- 是否绑定(true或者false)
function ItemBase:IsBound()
    if self.Isbound ~= nil then
	    return (self.Isbound and true or false)
    else
        if self.ConfigData ~= nil and self.ConfigData.bindtype ~= nil and type(self.ConfigData.bindtype) == "table" and self.ConfigData.bindtype.bindtype ~= nil then
            if self.ConfigData.bindtype.bindtype == cfg.item.EItemBindType.BOUND then
                return true
            end
        end
        return false
    end
end
-- 设置是否绑定(true或者false)
function ItemBase:SetBound(isBound)
	self.Isbound = isBound
end
-- 获取简介
function ItemBase:GetIntroduction()
    return self.ConfigData.introduction
end
-- 获取是否可以售卖
function ItemBase:CanSell()
    if self.ConfigData.cansell ~= nil then
        return self.ConfigData.cansell
    else
        return true
    end
end
-- 获取性别限制
function ItemBase:GetGenderLimit()
    return self.ConfigData.gender
end
-- 获取职业限制
function ItemBase:GetProfessionLimit()
    return (self.ConfigData.professionlimit and self.ConfigData.professionlimit.profession or  cfg.Const.NULL)
end

-- 获取等级
function ItemBase:GetLevel()
    return self.ConfigData.level
end

-- 获取最大堆叠数量
function ItemBase:GetMaxPile()
    return self.ConfigData.maxpile
end
-- 获取品质名字
function ItemBase:GetQualityName()
    local ItemColorTypeName = LocalString.ItemColorType
    local quality = self:GetQuality()
    if quality and quality >= 0 and quality <= 5 then
        return ItemColorTypeName[quality + 1]
    end
end
-- 获取限制门派名称
function ItemBase:GetProfessionLimitName()
    local profession = self:GetProfessionLimit()
    if profession ~= cfg.Const.NULL then
        return LocalString.ProfessionType[profession + 1]
    else
        return LocalString.ProfessionType[1]
    end
end
-- 获取基础类型名称
function ItemBase:GetItemBaseTypeName()
    return LocalString.ItemBaseType[self:GetBaseType()]
end
-- 获取图标地址
function ItemBase:GetTextureName()
    return self.ConfigData.icon
end
-- 获取数量
function ItemBase:GetNumber()
    return self.Number
end
-- 增加数量
function ItemBase:AddNumber(num)
    self.Number = self.Number + num
end

function ItemBase:SetNumber(num)
	self.Number =num
end
-- 获取背包位置(若有的话)
function ItemBase:GetBagPos()
	return self.BagPos or cfg.Const.NULL
end

-- 获取所属背包类型(若有的话)
function ItemBase:GetBagType()
	return self.BagType or cfg.Const.NULL
end

return ItemBase