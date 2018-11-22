local ItemBase = require("item.itembase")
local ItemEnum = require("item.itemenum")
local ConfigManager = require("cfg.configmanager")
local math = math

-- 装备类
local Equipment = { }
setmetatable(Equipment, { __index = ItemBase })
----------------------------------------------------------------------

function Equipment:GetDetailTypeName()
    return self.DetailType and LocalString.EquipType[self.DetailType]
end

-- 获取到期时间(值为0表示无时间限制)
function Equipment:GetExpireTime()
    return self.ExpireTime
end

----------------------------------------------------------------------
function Equipment:GetMaxPile()
    return 1
end
-- 获取推荐指数
function Equipment:GetRecommendRate()
	if self:IsMainEquip() then 
		return self.ConfigData.recommendrate
	end
end
-- 获取装载需要等级
function Equipment:GetLevel()
	return self.ConfigData.level
end

-- 只有主装备有炼器和灌注等级，饰品无炼器或者灌注等级
-- 装备炼器强化等级
function Equipment:GetAnnealLevel()
	return self.AnnealLevel
end
-- 装备追加等级
function Equipment:GetPerfuseLevel()
	return self.PerfuseLevel
end
-- 设置炼器等级
function Equipment:SetAnnealLevel(level)
	self.AnnealLevel = level
end
-- 设置装备追加等级
function Equipment:SetPerfuseLevel(level)
	self.PerfuseLevel = level
end
-- 此函数只针对饰品，四大装备此属性为空
-- 获取饰品主属性(2个随机属性)
function Equipment:GetAccMainAttributes()
	if self:IsAccessory() then
		return self.AccMainAttributes
	end
end
-- 此函数只针对饰品，四大装备此属性为空
-- 获取饰品附加属性(5个随机属性)
function Equipment:GetAccExtraAttributes()
	if self:IsAccessory() then
		return self.AccExtraAttributes
	end
end

-- 此函数只针对饰品，四大装备此属性为空
-- 设置饰品主属性(2个随机属性)
function Equipment:SetAccMainAttributes(accMainAttrs)
	if self:IsAccessory() then
		self.AccMainAttributes = accMainAttrs
	end
end
-- 此函数只针对饰品，四大装备此属性为空
-- 设置饰品附加属性(5个随机属性)
function Equipment:SetAccExtraAttributes(accExtraAttrs)
	if self:IsAccessory() then
		self.AccExtraAttributes = accExtraAttrs
	end
end

function Equipment:GetDisassembly()
    return self.ConfigData.break2lingjing.amount
end

--------------------------------------------------------------------------------------------
-- 主要装备类

-- 模型1地址(string)
function Equipment:GetModelPath1()
    return self.ConfigData.mod
end
-- 模型2地址(string)
function Equipment:GetModelPath2()
    return self.ConfigData.mod2
end
-- 神器进阶的目标id(int)
function Equipment:GetUpgradedEquipId()
    return self.ConfigData.nextid
end
-- 神器进阶额外需要的装备id(int)
function Equipment:GetExtraPropId()
    return self.ConfigData.extraequipid
end
-- 神器进阶消耗的虚拟币(int)
function Equipment:GetUpgradeEquipCost()
    return self.ConfigData.upgradecurrencycost
end
-- 装备携带的千华龙筋数(int)
function Equipment:GetCarryingItemNum()
    return self.ConfigData.carryingitemnum
end
-- 是否是四大主要装备(武器，衣服，帽子，鞋)
function Equipment:IsMainEquip()
	if self.DetailType == ItemEnum.EquipType.Weapon or
		self.DetailType == ItemEnum.EquipType.Cloth or 
		self.DetailType == ItemEnum.EquipType.Hat or 
		self.DetailType == ItemEnum.EquipType.Shoe  then

		return true
	else
		return false
	end
end

-- 是否是饰品
function Equipment:IsAccessory()
	if self.DetailType == ItemEnum.EquipType.Bangle or
		self.DetailType == ItemEnum.EquipType.Ring or 
		self.DetailType == ItemEnum.EquipType.Necklace then 

		return true
	else
		return false
	end
end

-- 基础属性列表(只适用四大主要装备)
function Equipment:GetEquipBasicAttributes()
    if self:IsMainEquip() then
        self.BasicAttrs = { }
        for _, property in ipairs(self.ConfigData.property) do
            self.BasicAttrs[property.propertytype] = property.value
        end
        if getn(self.BasicAttrs) == 0 then
            return nil
        end
        return self.BasicAttrs
    end
end
-- 获取装备炼器后所获得的主属性以及所提升值
function Equipment:GetAnnealAddedAttrs()
    self.AnnealAddedAttrs = { }
    local annealAddData = self.AnnealAddedAttrConfigData
    for _, addData in ipairs(annealAddData.adddata) do
        self.AnnealAddedAttrs[addData.addpropertyid] = addData.addvalues[self:GetAnnealLevel()+1]
    end
    if getn(self.AnnealAddedAttrs) == 0 then
        self.AnnealAddedAttrs = nil
    end
    return self.AnnealAddedAttrs
end
-- 获取达到相应炼器等级后所激活的隐藏附加属性
function Equipment:GetAnnealHiddenAttrs()
    self.AnnealHiddenAttrs = { }
    local annealHiddenData = self.AnnealHiddenAttrConfigData
    for _, hiddenData in ipairs(annealHiddenData.bonus) do
            
        self.AnnealHiddenAttrs[hiddenData.bonuslevel] = {}
        self.AnnealHiddenAttrs[hiddenData.bonuslevel].Attrs = {}
        for _,attrData in ipairs(hiddenData.bonusvalue) do 
            self.AnnealHiddenAttrs[hiddenData.bonuslevel].Attrs[attrData.propertytype] = attrData.value
        end
        local bActived = false
        if hiddenData.bonuslevel <= self:GetAnnealLevel() then
            bActived = true
        end
        self.AnnealHiddenAttrs[hiddenData.bonuslevel].bActived = bActived
    end
    if getn(self.AnnealHiddenAttrs) == 0 then
        self.AnnealHiddenAttrs = nil
    end
    return self.AnnealHiddenAttrs
end

-- 获取装备灌注后所获得的主属性以及所提升值
function Equipment:GetPerfuseAddedAttrs()
    self.PerfuseAddedAttrs = { }
    local perfuseAddData = self.PerfuseAddedAttrConfigData
    for _, addData in ipairs(perfuseAddData.adddata) do
        self.PerfuseAddedAttrs[addData.addpropertyid] = addData.addvalues[self:GetPerfuseLevel()+1]
    end

    if getn(self.PerfuseAddedAttrs) == 0 then
        self.PerfuseAddedAttrs = nil
    end
    return self.PerfuseAddedAttrs
end
-- 获取对应id的装备套装属性配置文件，若没有套装属性，返回nil
-- 饰品无套装属性
function Equipment:GetEquipSuitsConfigData()
	if self:IsMainEquip() then
		return self.SuitsAttrsConfigData
	end
end
-- 装备战斗力的公式在battlepowerconfig里定义
function Equipment:GetPower()
	local attrs = { }
	attrs[cfg.fight.AttrId.HP_FULL_VALUE]          = 0
	attrs[cfg.fight.AttrId.MP_FULL_VALUE]          = 0
	attrs[cfg.fight.AttrId.ATTACK_VALUE_MIN]       = 0
	attrs[cfg.fight.AttrId.ATTACK_VALUE_MAX]       = 0
	attrs[cfg.fight.AttrId.ATTACK_VALUE]		   = 0
	attrs[cfg.fight.AttrId.DEFENCE]                = 0
	attrs[cfg.fight.AttrId.HIT_RATE]               = 0
	attrs[cfg.fight.AttrId.HIT_RESIST_RATE]        = 0
	attrs[cfg.fight.AttrId.CRIT_RATE]              = 0
	attrs[cfg.fight.AttrId.CRIT_RESIST_RATE]       = 0
	attrs[cfg.fight.AttrId.CRIT_VALUE]             = 0
	attrs[cfg.fight.AttrId.CRIT_RESIST_VALUE]      = 0
	attrs[cfg.fight.AttrId.EXCELLENT_RATE]         = 0
	attrs[cfg.fight.AttrId.EXCELLENT_RESIST_RATE]  = 0
	attrs[cfg.fight.AttrId.EXCELLENT_VALUE]        = 0
	attrs[cfg.fight.AttrId.EXCELLENT_RESIST_VALUE] = 0
	attrs[cfg.fight.AttrId.LUCKY_VALUE]            = 0
	attrs[cfg.fight.AttrId.ABNORMAL_HIT_RATE]      = 0
	attrs[cfg.fight.AttrId.ABNORMAL_RESIST_RATE]   = 0


	local ratioData       = ConfigManager.getConfig("battlepower")
	local ratio_hp        = ratioData.hp
	local ratio_mp        = ratioData.mp
	local ratio_minatk    = ratioData.minatk
	local ratio_maxatk    = ratioData.maxatk
	local ratio_def       = ratioData.defence
	local ratio_hit       = ratioData.hit
	local ratio_hitresist = ratioData.hitresist
	local ratio_crit      = ratioData.crit
	local ratio_ex        = ratioData.excellent
	local ratio_luck      = ratioData.luck
	local ratio_ab        = ratioData.abnormal

	-- 主要装备(衣服，帽子，鞋子，武器)
	if self:IsMainEquip() then 
		-- 装备主属性
		local basicAttrs = self:GetEquipBasicAttributes()
		if basicAttrs then
			for attrType, attrValue in pairs(basicAttrs) do
				if attrs[attrType] then
					attrs[attrType] = attrs[attrType] + attrValue
				end
			end
		end
	elseif self:IsAccessory() then 
		-- 饰品主属性
		local accMainAttr = self:GetAccMainAttributes()
		if accMainAttr then 
			for index, attribute in pairs(accMainAttr) do
				if attrs[attribute.AttrType] then
					attrs[attribute.AttrType] = attrs[attribute.AttrType] + attribute.AttrValue
				end
			end
		end
		-- 饰品附加属性
		local accExtraAttr = self:GetAccExtraAttributes()
		if accExtraAttr then 
			for index, attribute in pairs(accExtraAttr) do
				if attrs[attribute.AttrType] then
					attrs[attribute.AttrType] = attrs[attribute.AttrType] + attribute.AttrValue
				end
			end
		end
	end
	-- 装备和饰品都有炼器和灌注等级，以下为装备和饰品共有代码
	-- 炼器增加属性
	local annealAddedAttrs = self:GetAnnealAddedAttrs()
	if annealAddedAttrs then
		for attrType, attrValue in pairs(annealAddedAttrs) do
			if attrs[attrType] then
				attrs[attrType] = attrs[attrType] + attrValue
			end
		end
	end
	-- 灌注增加属性
	local perfuseAddedAttrs = self:GetPerfuseAddedAttrs()
	if perfuseAddedAttrs then
		for attrType, attrValue in pairs(perfuseAddedAttrs) do
			if attrs[attrType] then
				attrs[attrType] = attrs[attrType] + attrValue
			end
		end
	end
	-- 达到相应炼器等级所激活的隐藏附加属性
	local annealHidedAttrs = self:GetAnnealHiddenAttrs()
	if annealHidedAttrs then
		for annealLevel, hidedAttr in pairs(annealHidedAttrs) do
			if hidedAttr.bActived then 
				-- 只有激活的属性才会计算
				for attrType, attrValue in pairs(hidedAttr.Attrs) do
					if attrs[attrType] then
						attrs[attrType] = attrs[attrType] + attrValue
					end
				end
			end
		end
	end
	-- 计算公式，参见battlepowerconfig里的定义
	local basicPower = (attrs[cfg.fight.AttrId.HP_FULL_VALUE]*ratio_hp + attrs[cfg.fight.AttrId.MP_FULL_VALUE]*ratio_mp + (attrs[cfg.fight.AttrId.ATTACK_VALUE_MIN] + attrs[cfg.fight.AttrId.ATTACK_VALUE])*ratio_minatk + (attrs[cfg.fight.AttrId.ATTACK_VALUE_MAX] + attrs[cfg.fight.AttrId.ATTACK_VALUE])*ratio_maxatk + attrs[cfg.fight.AttrId.DEFENCE]*ratio_def + attrs[cfg.fight.AttrId.HIT_RATE]*ratio_hit + attrs[cfg.fight.AttrId.HIT_RESIST_RATE]*ratio_hitresist) 
	local critPower = (1 + ratio_crit*(attrs[cfg.fight.AttrId.CRIT_RATE] + attrs[cfg.fight.AttrId.CRIT_RESIST_RATE])*(attrs[cfg.fight.AttrId.CRIT_VALUE] + attrs[cfg.fight.AttrId.CRIT_RESIST_VALUE]))
	local excellentPower = (1 + ratio_ex*(attrs[cfg.fight.AttrId.EXCELLENT_RATE] + attrs[cfg.fight.AttrId.EXCELLENT_RESIST_RATE])*(attrs[cfg.fight.AttrId.EXCELLENT_VALUE] + attrs[cfg.fight.AttrId.EXCELLENT_RESIST_VALUE]))
	local luckPower = (1 + ratio_luck*attrs[cfg.fight.AttrId.LUCKY_VALUE])
	local abnormalPower = (1 + ratio_ab*(attrs[cfg.fight.AttrId.ABNORMAL_HIT_RATE] + attrs[cfg.fight.AttrId.ABNORMAL_RESIST_RATE]))

	local totalPower = basicPower*critPower*excellentPower*luckPower*abnormalPower
	-- 四舍五入
	return math.floor(totalPower+0.5)
end

-- 加载装备炼器后所获得的主属性以及所提升值列表配置文件
-- 加载装备达到相应炼器等级后可以激活的隐藏附加属性
function Equipment:LoadEquipAnnealAttributesConfig()
    -- 装备，饰品都适用
    self.AnnealAddedAttrConfigData = ConfigManager.getConfigData("equipanneal",self:GetConfigId())
    self.AnnealHiddenAttrConfigData = ConfigManager.getConfigData("annealbonus",self:GetConfigId())
end

-- 加载装备灌注后所获得的主属性以及所提升值列表配置文件
function Equipment:LoadEquipPerfuseAttributesConfig()
    -- 装备，饰品都适用
    self.PerfuseAddedAttrConfigData = ConfigManager.getConfigData("equipappend", self:GetConfigId())
end
 -- 加载装备套装属性配置文件
function Equipment:LoadEquipSuitsAttributesConfig()
    -- 只针对主要装备，不包括饰品
	if self:IsMainEquip() then
        local AllSuitsAttrsData = ConfigManager.getConfig("equipsuits")
        for suitId,suitData in pairs(AllSuitsAttrsData) do
            -- 一件装备只会出现在一个套装里，否则配置出错
            local isFindSuitId = false
            for _,includedEquipId in ipairs(suitData.includeid) do
                if includedEquipId == self:GetConfigId() then
                    isFindSuitId = true
                    self.SuitsAttrsConfigData = suitData
                end
            end
            if isFindSuitId then
                break
            end
        end
    end
end


function Equipment:LoadFromServerMsg(serverMsg)
    self.ID           = serverMsg.equipid or -1
    self.BagPos       = serverMsg.position or -1
	-- 四大主装备
	if self:IsMainEquip() then  
		if not serverMsg.normalequip then
			self.AnnealLevel  = serverMsg.anneallevel or 0
			self.PerfuseLevel = serverMsg.perfuselevel or 0
		else
			self.AnnealLevel  = serverMsg.normalequip.anneallevel or 0
			self.PerfuseLevel = serverMsg.normalequip.perfuselevel or 0
		end
	end
    self.ExpireTime   = serverMsg.expiretime or 0
    self.Isbound      = serverMsg.isbind == 1 and true or false
	-- 饰品
	if self:IsAccessory() then 
		-- 主属性(2个)
		self.AccMainAttributes = { }
		-- 附加属性(5个)
		self.AccExtraAttributes = { }
		-- 炼器和灌注等级
		if not serverMsg.accessory then
			self.AnnealLevel  = serverMsg.anneallevel or 0
			self.PerfuseLevel = serverMsg.perfuselevel or 0
		else
			self.AnnealLevel  = serverMsg.accessory.anneallevel or 0
			self.PerfuseLevel = serverMsg.accessory.perfuselevel or 0
		end
		
		if (serverMsg.accessory) then
			if (serverMsg.accessory.mainprop) then
				for _, attr in ipairs(serverMsg.accessory.mainprop) do
					local tempAttr = { AttrType = attr.key, AttrValue = attr.val }
					table.insert(self.AccMainAttributes,tempAttr)
				end
			end
			if (serverMsg.accessory.extraprop) then
				for _, attr in ipairs(serverMsg.accessory.extraprop) do
					local tempAttr = { AttrType = attr.key, AttrValue = attr.val }
					table.insert(self.AccExtraAttributes,tempAttr)
				end
			end
		end
	end
end

-- 实例化
function Equipment:CreateInstance(configId, config, detailType, detailType2, serverMsg, number)
    local equip = {
        ConfigId      = configId,
        BaseType      = ItemEnum.ItemBaseType.Equipment,
        DetailType    = detailType,
	    DetailType2   = detailType2,
        ConfigData    = config,
        Number        = number or 1,
    }

    setmetatable(equip, { __index = self })

    -- 加载其他配置文件
    equip:LoadEquipAnnealAttributesConfig()
    equip:LoadEquipPerfuseAttributesConfig()
    equip:LoadEquipSuitsAttributesConfig()

    if not serverMsg then
        -- 默认炼器和灌注等级为0
		-- 仅用csvid时,炼器或灌注等级默认为0
		-- 装备和饰品的炼器等级和灌注等级
		equip:SetAnnealLevel(0)
		equip:SetPerfuseLevel(0)
		-- 饰品主属性和附加属性
		equip:SetAccMainAttributes({})
		equip:SetAccExtraAttributes({})
	else
        equip:LoadFromServerMsg(serverMsg)
    end

    return equip
end

return Equipment