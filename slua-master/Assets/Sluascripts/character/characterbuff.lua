local print = print
local require = require
local configManager = require "cfg.configmanager"

local mathutils = require"common.mathutils"
local define = require"define"
local uimanager = require"uimanager"
local effectmanager = require "effect.effectmanager"

local CharacterEffectData
local StatusText
local bShowEffect = false



local CharacterEffect = Class:new()


CharacterEffect.AbnormalStatesForbiddens = {

}

CharacterEffect.ShowEffect = function(b)
    bShowEffect = b
end

function CharacterEffect:__new(char)
    self.m_Altered = false
    self.effectList = {}
    self.m_Character = char
    self.m_CommonEffects = {}
    CharacterEffectData = configManager.getConfig("effect")
    StatusText = ConfigManager.getConfig("statustext")
    self.m_Abilities = nil
    self.m_ShortEffects = {}
    self:ResetCharacterAbilities()
end

function CharacterEffect:ResetCharacterAbilities()
    self.m_Abilities = bit.lshift(1,cfg.fight.AbilityType.NOT_IMMUNE_DEBUFF) - 1
end

function CharacterEffect:GetEffectIdx(id)
    for i=1,#self.effectList do
        if self.effectList[i].id == id then
            return i
        end
    end
    return 0
end

function CharacterEffect:CanMove()
    return bit.band(self.m_Abilities,bit.lshift(1,cfg.fight.AbilityType.MOVE))>0
end

function CharacterEffect:CanUseItem()
    return bit.band(self.m_Abilities,bit.lshift(1,cfg.fight.AbilityType.BEHEAL))>0
end

function CharacterEffect:CanPlaySkill()
    return bit.band(self.m_Abilities,bit.lshift(1,cfg.fight.AbilityType.SKILL_ATTACK))>0
end

function CharacterEffect:CanPlayNormalSkill()
    return bit.band(self.m_Abilities,bit.lshift(1,cfg.fight.AbilityType.NORMAL_ATTACK))>0
end

function CharacterEffect:CanBeAttack()
    return bit.band(self.m_Abilities,bit.lshift(1,cfg.fight.AbilityType.BEATTACKED))>0
end

function CharacterEffect:SetEffectInformation(_effect)
    local tb = {}
    tb.id = _effect.id
    if CharacterEffectData[_effect.id].class == 'cfg.buff.AddPropertyByLevel' then
        local cfgEffect = CharacterEffectData[_effect.id]
        local text = cfgEffect.introduction[_effect.level or 1]
        text = text .. '\n'
        local sign = cfgEffect.value[_effect.level or 1] >=0 and '+' or '-'
        text = text .. StatusText[cfgEffect.property].text.. ' '
        text = text .. sign .. ' '
        text = text .. mathutils.GetAttr(cfgEffect.value[_effect.level or 1],StatusText[cfgEffect.property].displaytype)
        tb.description = text
    else
        tb.description = CharacterEffectData[_effect.id].introduction
    end
    tb.level        = _effect.level
    tb.overlaynum   = _effect.overlaynum
    tb.endtime      = _effect.endtime
    tb.icon         = CharacterEffectData[_effect.id].icontype
    return tb
end

function CharacterEffect:PlayEffect(commoneffectid)
    return effectmanager.PlayEffect { id = commoneffectid,
                                      bindCharacter = self.m_Character ,
                                      bSkill = false}
end

function CharacterEffect:StopEffect(instanceId)
    effectmanager.StopEffect(instanceId)
end

function CharacterEffect:PlayBuffEffect(commoneffectid)
    if not self.m_CommonEffects[commoneffectid] then
        local instanceId = self:PlayEffect(commoneffectid)
        self.m_CommonEffects[commoneffectid] = {}
        self.m_CommonEffects[commoneffectid].cnt = 1
        self.m_CommonEffects[commoneffectid].instanceId = instanceId
    else
        self.m_CommonEffects[commoneffectid].cnt = self.m_CommonEffects[commoneffectid].cnt + 1
    end
end

function CharacterEffect:StopBuffEffect(commoneffectid)
    if self.m_CommonEffects[commoneffectid] then
        self.m_CommonEffects[commoneffectid].cnt = self.m_CommonEffects[commoneffectid].cnt - 1
        if self.m_CommonEffects[commoneffectid].cnt == 0 then
            self:StopEffect(self.m_CommonEffects[commoneffectid].instanceId)
            self.m_CommonEffects[commoneffectid] = nil
        end
    end
end

function CharacterEffect:AddShortEffect(commoneffectid)
    if commoneffectid > 0 then
        local instanceId    = self:PlayEffect(commoneffectid)
        local lifetime      = LocalString.MAX_BUFF_TIME
        table.insert(self.m_ShortEffects,{lifetime=lifetime,instanceId=instanceId,elapsedtime=0})
    end
end

function CharacterEffect:AddEffect(_effect)
    self.m_Altered = true
    local commoneffectid = CharacterEffectData[_effect.id].commoneffectid
    local ispersistent = CharacterEffectData[_effect.id].ispersistent
    local idx = self:GetEffectIdx(_effect.id)
    local tb = self:SetEffectInformation(_effect)
    if ispersistent then
        if idx == 0 then
            table.insert(self.effectList,tb)
            if commoneffectid > 0 then
                self:PlayBuffEffect(commoneffectid)
            end
        else
            self.effectList[idx] = tb
        end
    else
        self:AddShortEffect(commoneffectid)
    end
    self:RefreshCharacterAbilities()
end

function CharacterEffect:InTheList(lst,value)
    for _,v in pairs(lst) do
        if v == value then
            return true
        end
    end
    return false
end

function CharacterEffect:GetCommonEffectList()
    local ret = {}
    for _,v in pairs(self.effectList) do
        local commoneffectid = CharacterEffectData[v.id].commoneffectid
        if not self:InTheList(ret,commoneffectid) then
            table.insert(ret,commoneffectid)
        end
    end
    return ret
end

function CharacterEffect:RemoveEffect(id)
    self.m_Altered = true
    local idx = self:GetEffectIdx(id)
    if idx == 0 then
        self.m_Altered = false
        return
    else
        local commoneffectid = CharacterEffectData[id].commoneffectid
        table.remove(self.effectList,idx)
        if commoneffectid > 0 then
            self:StopBuffEffect(commoneffectid)
        end
    end
    self:RefreshCharacterAbilities()
end

function CharacterEffect:Altered()
    return self.m_Altered
end

function CharacterEffect:ChangeAltered()
    self.m_Altered = false
end

function CharacterEffect:GetEffectList()
    return self.effectList
end

function CharacterEffect:GetEffectByIndex(idx)
    return self.effectList[idx]
end
--
function CharacterEffect:Update()
    if self:Altered() == true then
        self.m_Character:OnEffectChange()
        if not self.m_Character:IsRole() then
            self:ChangeAltered()
        end
    end
    for i=#self.m_ShortEffects,1 ,-1 do
        local shortEffect = self.m_ShortEffects[i]
        shortEffect.elapsedtime = shortEffect.elapsedtime + Time.deltaTime
        if  shortEffect.lifetime == nil or  shortEffect.elapsedtime > shortEffect.lifetime then
            self:StopEffect(shortEffect.instanceId)
            table.remove(self.m_ShortEffects,i)
        end
    end
end

function CharacterEffect:GetMessageEffects()
    local ret = {}
    for _,v in ipairs(self.effectList) do
        local tb = {}
        tb.id = v.id
        tb.overlaynum = v.overlaynum
        tb.level = v.level
    end
    return ret
end

function CharacterEffect:Clear()
    self.m_Altered = true
    for i=#self.effectList,1,-1 do
        local _effect = self.effectList[i]
        self:RemoveEffect(_effect.id)
    end
    self.effectList = {}
    for i=#self.m_ShortEffects,1 ,-1 do
        local shortEffect = self.m_ShortEffects[i]
        self:StopEffect(shortEffect.instanceId)
        table.remove(self.m_ShortEffects,i)
    end
    self:ResetCharacterAbilities()
end

function CharacterEffect:DisableAbility(ability)
    self.m_Abilities = bit.band(self.m_Abilities,bit.bnot(ability))
end

function CharacterEffect:RefreshAbilitiesOnUI()
    if uimanager.isshow("dlguimain") then
        uimanager.call("dlguimain","RefreshAbilities")
    end
end

function CharacterEffect:RefreshCharacterAbilities()
    self:ResetCharacterAbilities()
    local cfgState = ConfigManager.getConfig("state")
    for i,tb in ipairs(self.effectList) do
        if CharacterEffectData[tb.id].class == 'cfg.buff.SetAbnormalState' then
            local effectData    = CharacterEffectData[tb.id]
            local stateType     = effectData.statetype
            local stateData     = cfgState[stateType]
            for i=1,4 do
                if not stateData.abilities[i] then
                    local ability = bit.lshift(1,i-1)
                    self:DisableAbility(ability)
                end
            end
        end
    end
    self:RefreshAbilitiesOnUI()
end

function CharacterEffect:GetEffectsByBuffId(buffid)
    local cfgBuff =ConfigManager.getConfigData("buff",buffid)
    local effects = cfgBuff.effects
    local ret = {}
    for _,effect in pairs(effects) do
        local effectInfo = CharacterEffectData[effect.effectid]
        table.insert(ret,effectInfo)
    end
    return ret
end

return CharacterEffect
