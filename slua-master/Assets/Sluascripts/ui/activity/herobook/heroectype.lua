local ConfigManager = require("cfg.configmanager")
local ItemManager   = require("item.itemmanager")
local Monster       = require("character.monster")


local HeroEctype = Class:new()

function HeroEctype:__new(cfg)
    self.m_Id = cfg.id
    self.m_PetItemId = cfg.itemid
    self.m_RefreshText = cfg.refstring
    self.m_Color = cfg.color
    self.m_ConfigData = ConfigManager.getConfigData("heroectype", self.m_Id)
    
    self.m_BossId = self.m_ConfigData.bossid
end

function HeroEctype:GetItemsOfShow()
    local items = {}
    for _, itemId in pairs(self.m_ConfigData.showbonusid) do
        local item = ItemManager.CreateItemBaseById(itemId,{},1)
        table.insert( items, item )
    end
    return items
end

function HeroEctype:GetId()
    return self.m_Id
end

function HeroEctype:GetRefreshText()
    return self.m_RefreshText
end

function HeroEctype:GetPetItem()
    return ItemManager.CreateItemBaseById(self.m_PetItemId,{},1)
end

function HeroEctype:GetBossId()
    return self.m_BossId
end

function HeroEctype:GetName()
    local bossCfg = ConfigManager.getConfigData("monster", self.m_BossId)
    return bossCfg.name
end

function HeroEctype:GetBossConfig()
    local bossConfig = ConfigManager.getConfigData("monster", self.m_BossId)
    return bossConfig
end

function HeroEctype:LoadCharacter(callback)
    local monster = Monster:new()
    monster.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    monster:RegisterOnLoaded(function(obj)
        if callback then
            callback(monster, obj)
        end
    end)
    monster:init(self.m_BossId,self.m_BossId,false)
    
    return monster
end

function HeroEctype:GetUIScale()
    return self.m_ConfigData.uiscale
end

function HeroEctype:GetQualityColor()
    return self.m_Color
end

return HeroEctype