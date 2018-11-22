
local print = print
local require = require
local Character = require "character.character"
local defineenum = require "defineenum"
local Define        = require"define"
local CharacterType = defineenum.CharacterType
local ConfigManager = require "cfg.configmanager"
local effectmanager = require "effect.effectmanager"
local CharacterInstPool = require "character.characterinstpool"
local ShadowObjectManager   = require"character.footinfo.shadowobjmanager"

local Monster = Class:new(Character)
function Monster:__new()
    Character.__new(self)
    self.m_Type = CharacterType.Monster
end

function Monster:init(id,csvId,showheadinfo)
    self.m_Id = id
    self.m_CsvId = csvId
    self.m_Data = ConfigManager.getConfigData("monster",csvId)

    self.m_Name = self.m_Data.name
    self.m_BornEffectElapsedTime  = nil
    local ModelData =  ConfigManager.getConfigData("model",self.m_Data.modelname)
    self:CriticalLoadModel({ModelData,ModelData,showheadinfo,self.m_Data.playbornaction})
end

function Monster:loadmodel(modeldata,charactermodeldata,isShowHeadInfo,playbornaction)

    local bundlename = self:GetBundlePath(modeldata.modelpath)
    local cacheobject = nil
    if not self:IsUIModel() then
        cacheobject = CharacterInstPool.GetCharacter(modeldata.modelname)
        if cacheobject == nil then
           local cacheobjecttemplate = Game.CharacterPool.Get(modeldata.modelname)
           if cacheobjecttemplate~=nil then
               cacheobject =  Util.Instantiate(cacheobjecttemplate,bundlename)
           end
        end
    end


    if cacheobject ~=nil then
        self.m_CharacterModelData = charactermodeldata or self.m_CharacterModelData
        self.m_ModelData = modeldata or self.m_CharacterModelData
        self.m_bNeedLoadAvatar = false
        self.m_bHasAvatar = false
        self.m_ModelPath = self.m_ModelData.modelpath
        self.m_AvatarId = self.m_ModelData.avatarid
        if self.m_Object then
            GameObject.DestroyImmediate(self.m_Object)
            self.m_Object = nil
            self.m_Avatar:Clear(HumanoidAvatar.EquipType.ARMOUR)
            self.m_Avatar:Clear(HumanoidAvatar.EquipType.WEAPON)
        end
        self.m_Object = cacheobject
        self:OnCharacterLoaded(bundlename,cacheobject,isShowHeadInfo,playbornaction)
    else
        Character.loadmodel(self,modeldata,charactermodeldata,isShowHeadInfo,playbornaction)
    end
end

function Monster:GetLevel()
    return self.m_Data.level
end


function Monster:OnLoaded(obj)
    if self.m_Object~=nil and not self:IsBoss() and not self:IsUIModel() then
        Game.CharacterPool.Put(self.m_ModelData.modelname,self.m_Object)
    end
    Character.OnLoaded(self,obj)
    local EctypeManager = require "ectype.ectypemanager"
    if self.m_Data.playborneffect then
        effectmanager.PlayEffect{id=80001,casterId=self.m_Id,targetId=self.m_Id,targetPos=self:GetPos(),bSkill=false}
    end
end

function Monster:DestroyObject()
    if self.m_ShadowObject then
        if not ShadowObjectManager.PushObject(self.m_ShadowObject) then
            GameObject.Destroy(self.m_ShadowObject)
        end
    end
    if self.m_Object then
        if not self:IsBoss() and not self:IsUIModel() then
            CharacterInstPool.PutCharacter(self.m_ModelData.modelname,self.m_Object)
        else
            Character.DestroyObject(self)
        end
        self.m_Object = nil
    end

end

function Monster:RefreshAvatarObject()
    ExtendedGameObject.SetLayerRecursively(self.m_Object,Define.Layer.LayerMonster)
end

function Monster:OnCharacterLoaded(bundlename,asset_obj,isShowHeadInfo,playbornaction)
    Character.OnCharacterLoaded(self,bundlename,asset_obj,isShowHeadInfo,playbornaction)
    if self.m_Object then
        self.m_Object:SetActive(true)
    end
end

function Monster:update()
    if self.m_BornEffectElapsedTime then
        self.m_BornEffectElapsedTime = self.m_BornEffectElapsedTime + Time.deltaTime
        if self.m_BornEffectElapsedTime > Monster.BornEffectTime then
            self.m_BornEffectElapsedTime = nil
            if not Monster.BornEffectPool:PushObject(self.m_BornEffect) then
                GameObject.Destroy(self.m_BornEffect)
            end
        end
    end
    Character.update(self)
end

function Monster:SwitchToFightState(attackerid,beattackerid)
    if not self.m_IsFighting and #self.m_Data.battletalk>0 then
        local rand = math.random()
        if rand < self.m_Data.battletalkprobability then
            if (#self.m_Data.battletalk >0) then
                local idx = math.random(#self.m_Data.battletalk)
                local uimanager = require"uimanager"
                uimanager.call("dlgheadtalking","Add",{content=self.m_Data.battletalk[idx],target=self})
            end
        end
    end
    Character.SwitchToFightState(self,attackerid,beattackerid)
end

function Monster:IsElite()
    return (self.m_Data.monstertype == cfg.monster.MonsterType.ELITE)
end

function Monster:IsBoss()
    return (self.m_Data.monstertype == cfg.monster.MonsterType.BOSS)
end

return Monster
