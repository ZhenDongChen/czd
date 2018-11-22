-- 宝珠不继承任何种类物品，单独一类
local format         = string.format
local ConfigManager  = require("cfg.configmanager")
local ItemManager    = require("item.itemmanager")


local Jewelry = Class:new()

function Jewelry:__new(jewelryId, level, pos, totalAddedExp, type)
	self.m_Id = jewelryId
	self.m_Level = level or 1
	self.type = type
	self.m_Pos = pos
	self.m_AttrType = ConfigManager.getConfigData("jewelry", jewelryId).propertytype
	self.m_AttrValue = (ConfigManager.getConfigData("jewelry", jewelryId).maturerate) *(ConfigManager.getConfigData("jewelrylvlup", self.m_Level).basicvalue) +(ConfigManager.getConfigData("jewelry", jewelryId).basicvalue)
	self.m_TotalAddedExp = totalAddedExp

	self.m_ConfigData = ConfigManager.getConfigData("jewelry", jewelryId)
end
-- 等级
function Jewelry:GetLevel()
	return self.m_Level
end

function Jewelry:SetLevel(level)
	self.m_Level = level
end
-- id
function Jewelry:GetId()
	return self.m_Id
end
-- 位置信息，在玉佩上为孔洞位置(索引为1-8)，
-- 在背包中为背包原始List的索引(按照功能，
-- 会对原始list按照品质进行升序或者降序排列)
function Jewelry:GetPos()
	return self.m_Pos
end

function Jewelry:SetPos(pos)
	self.m_Pos = pos
end

-- 宝珠类型(两种类型:背包中或者玉佩上)
function Jewelry:GetType()
	return self.type
end
-- 转载和卸载操作会更改类型
function Jewelry:SetType(type)
	self.type = type
end

-- 名称
function Jewelry:GetName()
	return self.m_ConfigData.jewelryname
end

-- 图标
function Jewelry:GetTextureName()
	return self.m_ConfigData.icon
end
-- 介绍
function Jewelry:GetIntroduce()
	return self.m_ConfigData.introduce
end

-- 品质
function Jewelry:GetQuality()
	return self.m_ConfigData.quality
end
-- fight属性种类
function Jewelry:GetAttrType()
	return self.m_AttrType
end
-- fight属性初始值
function Jewelry:GetAttrInitialValue()
	return self.m_ConfigData.basicvalue
end
-- fight属性具体数值
function Jewelry:GetAttrValue()
	return self.m_AttrValue
end
-- fight属性具体数值对应的文本
function Jewelry:GetAttrText()
	local attributeText = ItemManager.GetAttrText(self.m_AttrType,self.m_AttrValue,true)
	return attributeText
end
-- 成长率
function Jewelry:GetMAtureRate()
	return self.m_ConfigData.maturerate
end
-- 初始经验值，即天生携带的经验值
function Jewelry:GetInitialExp()
	return self.m_ConfigData.quatilyexp
end

-- 获取到的经验值(升级时消耗其他宝珠获得的，
-- 从1级开始所有获得的经验值，但不包括本身天生携带的经验值)
function Jewelry:GetTotalAddedExp()
	return self.m_TotalAddedExp
end
-- 包括天生经验值和升级消耗其他宝珠获得的经验值
-- 被其他宝珠消耗时候
function Jewelry:GetTotalExp()
	return(self.m_TotalAddedExp + ConfigManager.getConfigData("jewelry", self.m_Id).quatilyexp)
end
-- 获取宝珠升级后的剩余经验值(总获取经验值-升级到当前等级所消耗的经验值)
-- 仅供客户端显示使用
function Jewelry:GetRemainingExpAfterAdvanced()
	local totalRequiredExp = 0
	for i = 1,(self.m_Level - 1) do
		totalRequiredExp = totalRequiredExp + ConfigManager.getConfigData("jewelrylvlup", i).requireexp
	end
	if (self.m_TotalAddedExp - totalRequiredExp) >= 0 then
		return (self.m_TotalAddedExp - totalRequiredExp) 
	else
		logError("Jewelry remaining exp error!")
		return 0
	end
end
-- 增加经验值
function Jewelry:AddExp(expValue)
	self.m_TotalAddedExp = self.m_TotalAddedExp + expValue
end

function Jewelry:GetRequiredExpIfAdvanced()
	return ConfigManager.getConfigData("jewelrylvlup", self.m_Level).requireexp
end

return Jewelry
