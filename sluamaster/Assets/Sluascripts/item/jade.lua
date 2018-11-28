-- 玉佩不属于物品,没有基类
local ConfigManager = require("cfg.configmanager")

local Jade = Class:new()

function Jade:__new(level, attrValue)
    self.m_Level = level
    self.m_AttrValue = attrValue or 0
    self.m_ConfigData = ConfigManager.getConfigData("jade", level)
end
-- 增加属性攻击值
function Jade:AddAttrValue(attrValue)
    self.m_AttrValue = self.m_AttrValue + attrValue

end
-- 获取实际属性攻击值
function Jade:GetAttrValue()
    return self.m_AttrValue
end

function Jade:GetLevel()
    return self.m_Level
end
-- 图标
function Jade:GetTextureName()
    return self.m_ConfigData.icon
end

-- 进阶时玩家所需等级
function Jade:GetRequiredPlayerLevelIfAdvanced()
	-- 不是直接的level数值，是table类型，condition.xml中定义
    return self.m_ConfigData.requirelvl
end
-- 进阶所需的道具
function Jade:GetRequiredPropIfAdvanced()
	-- 不是直接的道具数量，是table类型，condition.xml中定义
    return self.m_ConfigData.requireitem
end
-- 属性攻击百分比
function Jade:GetAttrPercent()
    return self.m_ConfigData.percent
end
-- 属性攻击上限值，达到上限值可以进阶
function Jade:GetAttrUpperLimitIfAdvanced()
    return self.m_ConfigData.maxbonus
end

return Jade