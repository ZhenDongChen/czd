local ConfigManager = require("cfg.configmanager")

local function GetCorrespondingRelation(relation,gender)
    local relationConfig = ConfigManager.getConfigData("maimairelationship",relation)
    if gender == cfg.role.GenderType.MALE then
        return relationConfig.correspondingrelationshipmale
    else
        return relationConfig.correspondingrelationshipfemale
    end
end

local function GetRelationName(relation)
    if relation > 0 then
        local relationConfig = ConfigManager.getConfigData("maimairelationship",relation)
        if relationConfig then
            return relationConfig.nametext
        end
    end
    return ""
end

local function GetRelationGender(relation)
    if relation > 0 then
        local relationConfig = ConfigManager.getConfigData("maimairelationship",relation)
        if relationConfig then
            return relationConfig.gender
        end
    else
        return PlayerRole:Instance().m_Gender
    end
    return nil
end

local function GetRelationDeleteText(relation)
    if relation > 0 then
        local relationConfig = ConfigManager.getConfigData("maimairelationship",relation)
        if relationConfig then
            return relationConfig.deletetext
        end
    end
    return ""
end

local function GetRelationIcon(relation)
    if relation and relation > 0 then
        local relationConfig = ConfigManager.getConfigData("maimairelationship",relation)
        if relationConfig then
            return relationConfig.icon
        end
    end
    return nil
end

return {
    GetCorrespondingRelation    = GetCorrespondingRelation,
    GetRelationName             = GetRelationName,
    GetRelationGender           = GetRelationGender,
    GetRelationDeleteText       = GetRelationDeleteText,
    GetRelationIcon             = GetRelationIcon,
}
