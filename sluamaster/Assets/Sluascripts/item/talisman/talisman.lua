local ItemBase 		    = require("item.itembase")
local ItemEnum 		    = require("item.itemenum")
local ConfigManager     = require("cfg.configmanager")
local SkillManager      = require("character.skill.skillmanager")
local TalismanSkill     = require("item.talisman.talismanskill")
local ResourceManager   = require("resource.resourcemanager")

local Talisman = { }
setmetatable( Talisman, { __index = ItemBase } )
-----------------------------------------------------------------------------

function Talisman:GetDetailTypeName()
    return LocalString.Talisman.TypeName
end

function Talisman:GetQuality()
    return self.ConfigData.quality
end


function Talisman:LoadModel(callBack)
    ResourceManager.LoadObject(self.ConfigData.modelpath,{},function(assert_obj)
        if assert_obj then
            if callBack then
                callBack(assert_obj)
            end
        end
    end)
end

function Talisman:ReleaseModel()
    self.m_HeadInfo = nil

    if self.m_Effect then
        self.m_Effect:Clear()
    end

    if self.m_Avatar then
        self.m_Avatar:UnEquip(HumanoidAvatar.EquipType.WEAPON)
    end
    if self.m_ShadowObject then
        --printyellow("self.m_ShadowObject")
        self.m_ShadowObject.transform:SetParent(nil)
        if not ShadowObjectManager.PushObject(self.m_ShadowObject) then
            GameObject.DestroyImmediate(self.m_ShadowObject)
        end
        self.m_ShadowObject = nil
    end
    self:ReleaseBindEffect()
    self:DestroyObject()
end


function Talisman:LoadModelForScene(callBack)
    self:LoadModel(function(go)
        local uimodel = go.transform:Find("uimodel")
        if uimodel ~= nil then
            uimodel.gameObject:SetActive(false)
        end
        callBack(go)
    end)
end

function Talisman:LoadModelForUI(callBack)
    self:LoadModel(function(go)
        local uimodel = go.transform:Find("uimodel")
        if uimodel ~= nil then
            uimodel.gameObject:SetActive(true)
        end
        callBack(go)
    end)
end


function Talisman:GetQualityExp()
    return self.ConfigData.qualityexp
end
--
function Talisman:GetMatureRate()
    local basicAttr = {
        [cfg.fight.AttrId.HP_FULL_VALUE]    = self.ConfigData.maturerate.hpmaturerate,
        [cfg.fight.AttrId.MP_FULL_VALUE]    = self.ConfigData.maturerate.mpmaturerate,
        [cfg.fight.AttrId.ATTACK_VALUE_MIN] = self.ConfigData.maturerate.minatkmaturerate,
        [cfg.fight.AttrId.ATTACK_VALUE_MAX] = self.ConfigData.maturerate.maxatkmaturerate,
        [cfg.fight.AttrId.DEFENCE]          = self.ConfigData.maturerate.defmaturerate,
        [cfg.fight.AttrId.HIT_RATE]         = self.ConfigData.maturerate.hitmaturerate,
        [cfg.fight.AttrId.HIT_RESIST_RATE]  = self.ConfigData.maturerate.hitresistmaturerate,
    }
    return basicAttr
end
--获取基本属性
function Talisman:GetAttribute()
    local basicAttr = {
        [cfg.fight.AttrId.HP_FULL_VALUE]    = self.ConfigData.attr.hp,
        [cfg.fight.AttrId.MP_FULL_VALUE]    = self.ConfigData.attr.mp,
        [cfg.fight.AttrId.ATTACK_VALUE_MIN] = self.ConfigData.attr.attackvaluemin,
        [cfg.fight.AttrId.ATTACK_VALUE_MAX] = self.ConfigData.attr.attackvaluemax,
        [cfg.fight.AttrId.DEFENCE]          = self.ConfigData.attr.defence,
        [cfg.fight.AttrId.HIT_RATE]         = self.ConfigData.attr.hitrate,
        [cfg.fight.AttrId.HIT_RESIST_RATE]  = self.ConfigData.attr.hitresistrate,
    }
    return basicAttr
end

function Talisman:GetSpecialAttackRate()
    return self.ConfigData.specialattackrate
end

function Talisman:GetLevel()
    return self.NormalLevel
end



function Talisman:GetUILocalScale()
    return self.ConfigData.uisize
end
function Talisman:GetUILocalPosition()
    return Vector3(self.ConfigData.uipositionx, self.ConfigData.uipositiony, self.ConfigData.uipositionz)
end

function Talisman:Destroy()

end

function Talisman:CanUse()
    return self.ConfigData.canuse
end

----------------------------------------------------------------------------
function Talisman:GetPower()
    return self.Power
end
function Talisman:SetPower(power)
    self.Power = power
end

function Talisman:GetMainProperty(normalLv,starLv)
    local nLevel = normalLv or self:GetNormalLevel()
    local sLevel = starLv or self:GetStarOrderLevel()
    local baseAttr = self:GetAttribute()
    local matureRate = self:GetMatureRate()
    local mainProperty = {}
 --   local awakeAttr = self:GetAwakeProperty()
    for i,attr in pairs(baseAttr) do
        mainProperty[i] = baseAttr[i] + matureRate[i] * self:GetNormalMatureRate(nLevel) * self:GetStarMatureRate(sLevel)
  --      if awakeAttr[i] ~= nil then
  --          mainProperty[i] = mainProperty[i] + awakeAttr[i]
 --       end
    end
    return mainProperty
end

--========================================================================================================
--法宝升级相关

function Talisman:GetNormalExp()
    return self.NormalExp
end

function Talisman:GetNormalLevel()
    return self.NormalLevel
end

function Talisman:GetMaxNormalLevel()
    local expConfigs = ConfigManager.getConfig("talismanexp")
    return #expConfigs
end

function Talisman:SetNormalLevel(level)
    self.NormalLevel = level
end

function Talisman:GetMaxNormalExp(lv)
    local level = lv or self:GetNormalLevel()
    local expConfig = ConfigManager.getConfigData("talismanexp",level)
    return expConfig.requireexp
end
function Talisman:GetNormalMatureRate(lv)
    local level = lv or self:GetNormalLevel()
    local expConfig = ConfigManager.getConfigData("talismanexp",level)
    return expConfig.maturerate
end
function Talisman:GetSpecialAttackFactor(lv)
    local level = lv or self:GetNormalLevel()
    local expConfig = ConfigManager.getConfigData("talismanexp",level)
    return expConfig.specialattackrate
end
--========================================================================================================
--法宝星阶相关

--法宝星阶等级,开始为0
function Talisman:GetStarOrderLevel()
    return self.StarOrderLevel
end

function Talisman:SetStarOrderLevel(level)
    self.StarOrderLevel = level
end

function Talisman:GetMaxStarOrderLevel()
    local talismanStarOrderInfos = ConfigManager.getConfig("talismanevlove")
    return talismanStarOrderInfos[#talismanStarOrderInfos].level
end

--法宝星数
function Talisman:GetStarLevel(starOrderLevel)
    local level = starOrderLevel or self.StarOrderLevel
    return (level - level % 10)/10

end
--法宝阶数
function Talisman:GetOrderLevel(starOrderLevel)
    local level = starOrderLevel or self.StarOrderLevel
    return level % 10
end

function Talisman:GetRequiredPlayerLevel(starOrderLevel)
    local level = starOrderLevel or self:GetStarOrderLevel()
    local talismanStarOrderInfo = ConfigManager.getConfigData("talismanevlove",level)
    return talismanStarOrderInfo.levellimit
end

--法宝星阶经验
function Talisman:GetStarOrderExp()
    return self.StarOrderExp
end
--品质经验
function Talisman:GetQualityExp()
    return self.ConfigData.qualityexp
end


--升级星阶所需的经验值
function Talisman:GetMaxStarExp(lv)
    local level = lv or self:GetStarOrderLevel()
    local talismanStarOrderInfo = ConfigManager.getConfigData("talismanevlove",level)
    return talismanStarOrderInfo.requireexp
end

function Talisman:IsStarOrderExpFull()
    local currentExp = self:GetStarOrderExp()
    local maxExp = self:GetMaxStarExp()
    if currentExp >= maxExp then
        return true
    else
        return false
    end
end

--星阶对应的成长率
function Talisman:GetStarMatureRate(lv)
    local level = lv or self:GetStarOrderLevel()
    local talismanStarOrderInfo = ConfigManager.getConfigData("talismanevlove",level)
    return talismanStarOrderInfo.maturerate
end

function Talisman:GetStarOrderLevelCanReach(exp)

    local currentlv = self:GetStarOrderLevel()
    local curExp = self:GetStarOrderExp()
    while true do
        local maxExp = Talisman:GetMaxStarExp(currentlv)
        if exp < maxExp - curExp then
            return currentlv
        else
            currentlv = currentlv + 1
            exp = exp - (maxExp - curExp)
            curExp = 0
        end
    end
end

function Talisman:GetIntensifyCurrency()
    return 0
end
--========================================================================================================
--觉醒相关

--觉醒状态
function Talisman:GetAwakeStatus()
    return ((self.AwakeLevel > 0) and true) or false
end
--觉醒等级
function Talisman:GetAwakeLevel()
    return self.AwakeLevel
end
function Talisman:SetAwakeLevel(level)
    self.AwakeLevel = level
end

function Talisman:GetMaxAwakeLevel()
    local info = ConfigManager.getConfigData("talismanawake",self:GetConfigId())
    return #(info.awakeinfo)
end

--觉醒属性信息
function Talisman:GetAwakeInfo()
    local info = ConfigManager.getConfigData("talismanawake",self:GetConfigId())
    if info then
        return info.awakeinfo
    else
        --logError("找不到觉醒配置：",self:GetConfigId())
        return {}
    end
end
--[[
--觉醒增加的属性
function Talisman:GetAwakeProperty(awakeLv)
    local aLevel = awakeLv or self:GetAwakeLevel()
    local extraProperty = {}
    for i = 1, aLevel do
        local awakeInfos = self:GetAwakeInfo()
        local abilitys = awakeInfos[aLevel].gainability
        for i, ability in pairs(abilitys) do
            if extraProperty[ability.propertytype] == nil then
                extraProperty[ability.propertytype] = ability.value
            else
                extraProperty[ability.propertytype] = extraProperty[ability.propertytype] + ability.value
            end
        end
    end
    return extraProperty
end
]]
function Talisman:GetAwakeItemCost(level)
    local awakeLevel = level or self:GetAwakeLevel()
    local info = ConfigManager.getConfigData("talismanawake",self:GetConfigId())
    if info and info.awakeinfo and info.awakeinfo[awakeLevel+1] then
        return info.awakeinfo[awakeLevel+1].talismancost
    else
        return 0
    end
end

function Talisman:GetAwakeMoneyCost()
    return cfg.talisman.TalismanAwake.AWAKE_COST
end
--========================================================================================================
--五行、运气相关

function Talisman:GetFiveElementsPropertyType()
    return self.FiveElementsPropertyType
end
function Talisman:SetFiveElementsPropertyType(type)
    if type>=2 and type<=6 then
        self.FiveElementsPropertyType = type
    else
        logError("Error Set Wuxing Type: ", type)
        self.FiveElementsPropertyType = 2
    end
end
--
function Talisman:GetFiveElementsPropertyValue()
    return self.FiveElementsPropertyValue
end
function Talisman:SetFiveElementsPropertyValue(value)
    self.FiveElementsPropertyValue = value
end
function Talisman:GetFiveElementsMaxValue()
    --printyellow(",.,.,.,.")
    --printyellow(self:GetSpecialAttackRate(), self:GetSpecialAttackFactor() ,self:GetStarMatureRate())
    return self:GetSpecialAttackRate() * self:GetSpecialAttackFactor() * self:GetStarMatureRate()
end



--========================================================================================================
--归元
function Talisman:GetRecycleExp()
    local allNormalExp = 0
    for i =1, self:GetNormalLevel() - 1 do
        allNormalExp = allNormalExp + self:GetMaxNormalExp(i)
    end
    allNormalExp = allNormalExp + self:GetNormalExp()
    --local allNormalExp = self:GetNormalExp()
    local allStarExp = 0
    for i =1, self:GetStarOrderLevel() - 1 do
        allStarExp = allStarExp + self:GetMaxStarExp(i)
    end
    allStarExp = allStarExp + self:GetStarOrderExp()
    return allNormalExp,allStarExp
end

function Talisman:GetRecycleNormalExpItem(exp)
    local ItemManager   = require("item.itemmanager")

    local recycleCfg = ConfigManager.getConfig("talismanrecycle")
    local expitemids = recycleCfg.expitemid
    local items = {}
    local allExp = exp

    for i = 1, #expitemids do
        items[i] = ItemManager.CreateItemBaseById(expitemids[i].itemkey,nil,0)
        while items[i]:GetEffect().amount <= allExp do
            items[i].Number = items[i].Number + 1
            allExp = allExp - items[i]:GetEffect().amount
        end
    end
    local items2 = {}
    for i, item in ipairs(items) do
        if items[i].Number >=1 then
            table.insert(items2,item)
        end
    end

    return items2
end
function Talisman:GetRecycleStarExpItem(exp)
    local ItemManager   = require("item.itemmanager")

    local recycleCfg = ConfigManager.getConfig("talismanrecycle")
    local qualitytalismanids = recycleCfg.qualitytalismanid
    local items = {}
    local allExp = exp

    for i = 1, #qualitytalismanids do
        items[i] = ItemManager.CreateItemBaseById(qualitytalismanids[i].itemkey,nil,0)
        while items[i]:GetQualityExp() <= allExp do
            items[i].Number = items[i].Number + 1
            allExp = allExp - items[i]:GetQualityExp()
        end
    end
    local items2 = {}
    for i, item in ipairs(items) do
        if items[i].Number >=1 then
            table.insert(items2,item)
        end
    end

    return items2
end

function Talisman:GetRecycleItem()
    local allNormalExp,allStarExp = self:GetRecycleExp()
    return self:GetRecycleNormalExpItem(allNormalExp), self:GetRecycleStarExpItem(allStarExp)
end

function Talisman:GetAwakeRecycleItem()
    local ItemManager   = require("item.itemmanager")
    local currentAwakeLevel = self:GetAwakeLevel()
    local totalCost = 0
    for i = 0, currentAwakeLevel - 1 do
        totalCost = totalCost + self:GetAwakeItemCost(i)
    end
    totalCost = totalCost +1
    local items = {}
    table.insert( items, ItemManager.CreateItemBaseById(self:GetConfigId(), nil, totalCost) )
    return items
end

function Talisman:GetWashRecycleItem()
    local ItemManager   = require("item.itemmanager")
    local washItems = {}
    local fiveElmtValue = self:GetFiveElementsPropertyValue() or 0
    local washItemNum = math.floor( fiveElmtValue/6 )

    table.insert( washItems, ItemManager.CreateItemBaseById(cfg.talisman.TalismanFeed.REQUIRE_ITEM,nil, washItemNum) )
    return washItems
end

function Talisman:GetRecycleAllItem()
    local items1,items2 = self:GetRecycleItem()
    local items3 = self:GetAwakeRecycleItem()
    local items4 = self:GetWashRecycleItem()
    local items = {}
    for i,item in pairs(items1) do
        table.insert(items,item)
    end
    for i,item in pairs(items2) do
        table.insert(items,item)
    end
    for i,item in pairs(items3) do
        table.insert(items,item)
    end
    for i,item in pairs(items4) do
        table.insert(items,item)
    end
    return items
end
--========================================================================================================





-------------------------------------------------
function Talisman:GetSkills()
    return self.Skills
end
function Talisman:GetSkill(skillId)
    for i,skill in pairs(self.Skills) do
        if skill:GetConfigId() == skillId then
            return skill
        end
    end
    return nil
end
function Talisman:GetInitiativeSkill()
    return self.Skills[1]
end

function Talisman:GetCostZaohuaOfChangeFiveElements()
    return 10
end

function Talisman:GetFiveElementsValue()
    return {
        [ItemEnum.FiveElements.Metal] = self:GetFiveElementsPropertyValue(),
        [ItemEnum.FiveElements.Wood] = self:GetFiveElementsPropertyValue(),
        [ItemEnum.FiveElements.Water] = self:GetFiveElementsPropertyValue(),
        [ItemEnum.FiveElements.Fire] = self:GetFiveElementsPropertyValue(),
        [ItemEnum.FiveElements.Earth] = self:GetFiveElementsPropertyValue(),
    }
end
-----------------------------------------------------------------------------

----------------------------------------------------------------------------
function Talisman:LoadRelevantConfig()
    local skillData = ConfigManager.getConfigData("talismanskill",self:GetConfigId())
    self.Skills = { }
    for i, skillid in ipairs(skillData.skillid) do
        self.Skills[i] = TalismanSkill:new(skillid)
    end
end
function Talisman:TestSet()

     self.BagPos = 0
     --升级相关
     self.NormalExp = 0
     self.NormalLevel = 1
     --升星相关
     self.StarOrderExp = 0
     self.StarOrderLevel = 0
     --觉醒相关
     self.AwakeLevel = 0
     self.Power = 0
     --五行相关
     local talismanfeed = ConfigManager.getConfig("talismanfeed")
     self.FiveElementsPropertyType = cfg.talisman.TalismanFeed.DEFAULT_WUXING
     self.FiveElementsPropertyValue = 0
end
-- 加载服务器数据
function Talisman:LoadFromServerMsg(serverMsg)

     --法宝位置
     self.ID                = serverMsg.talismanid

     self.BagPos            = serverMsg.pos or 0    --物品在包裹中的位置，从1开始编号
     self.Isbound           = serverMsg.isbind == 1 and true or false       --法宝绑定类型
     --升级相关
     self.NormalExp         = serverMsg.normalexp or 0      --法宝普通经验
     self.NormalLevel       = serverMsg.normallevel or 1    --法宝普通等级,开始为1
     --升星相关
     self.StarOrderExp      = serverMsg.starexp or 0        --法宝星阶经验
     self.StarOrderLevel    = serverMsg.starlevel  or 1      --法宝星阶等级,开始为10
     --觉醒相关
     self.AwakeLevel        = serverMsg.awakelevel or 0     --法宝觉醒等级,觉醒后提升高级属性
     self.Power             = serverMsg.combatpower or 0
     --五行相关
     self:SetFiveElementsPropertyType(serverMsg.wuxingtype or 2)--法宝当前的五行属性类型
     self.FiveElementsPropertyValue = serverMsg.wuxingvalue  or 0--五行属性攻击值
     self.FiveElementsPropertyMaxValue = serverMsg.wuxingmaxvalue or 0--法宝的五行属性上限值

     --法宝技能相关
     if serverMsg.skills ~= nil then
        for id,svrlevel in pairs(serverMsg.skills) do
            for i, skill in pairs(self.Skills) do
                if skill.SkillId == id then
                    self.Skills[i].Level = svrlevel
                end
            end
        end
     end
end

-- 实例化
function Talisman:CreateInstance(configId, config, detailType, detailType2, serverMsg, number)
    local modelData = ConfigManager.getConfigData("model",config.modelpath)
	local talisman = {
       ConfigId    = configId,
       BaseType    = ItemEnum.ItemBaseType.Talisman,
	   DetailType  = detailType,
	   DetailType2 = detailType2,
	   ConfigData  = config,
	   Number      = number or 1,
       ModelData   = modelData,
       --BasicAttribute = {},
       --AdvanceAttribute = {},
	}
    setmetatable(talisman, { __index = self })

    talisman:LoadRelevantConfig()
    talisman:TestSet()
	if serverMsg ~= nil then
		talisman:LoadFromServerMsg(serverMsg or {})
	end
    --talisman:TestSet()
	return talisman
end

return Talisman
