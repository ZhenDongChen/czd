local ConfigManager = require("cfg.configmanager")

local function GetAttributeName(attrType)
    local attrText = ConfigManager.getConfigData("statustext",attrType)
    if attrText == nil then
        logError("属性类型说明（statustext）未定义：",attrType)
    end
    return attrText.text
end

local function GetAttributeValueString(attrType, attrValue)
    -- mathutils.GetAttr(attrType, attrValue)
    
    local attrText = ConfigManager.getConfigData("statustext",attrType)
    if attrText.displaytype == cfg.fight.DisplayType.NORMAL then
        return tostring(math.floor(attrValue*10)/10)
    elseif attrText.displaytype == cfg.fight.DisplayType.ROUND then
        local integer,decimal = math.modf(attrValue)
        return tostring(integer + (((decimal>= 0.5) and 1) or 0))
    elseif attrText.displaytype == cfg.fight.DisplayType.PERCENT then
        return tostring(math.floor(attrValue*1000)/10) .. "%"
    else
        return attrValue(attrValue)
    end
    
end
local function GetAttributeSpriteName(attrType)
    local attrCfg = ConfigManager.getConfigData("statustext",attrType)
    return attrCfg.spritename
end

local function GetBasicAttribute()
    local attrSeq = ConfigManager.getConfig("attrsequence")
    local basicAttrList = {}
    for i, attr in ipairs(attrSeq.basic) do
        table.insert(list,attr.type)    
    end
    return basicAttrList
end

local function GetAdvanceAttribute()
    local attrSeq = ConfigManager.getConfig("attrsequence")
    local advanceAttrList = {}
    for i, attr in ipairs(attrSeq.advance) do
        table.insert(list,attr.type)    
    end
    return advanceAttrList
end

local function init()
    
end

return {
    init                    = init,
    GetAttributeName        = GetAttributeName,
    GetAttributeValueString = GetAttributeValueString,
    GetBasicAttribute       = GetBasicAttribute,
    GetAdvanceAttribute     = GetAdvanceAttribute,
    GetAttributeSpriteName  = GetAttributeSpriteName,
}