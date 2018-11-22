local require = require
local Character = require "character.character"
local CharacterInstPool = require "character.characterinstpool"
local ConfigManager = require "cfg.configmanager"
local Define=require"define"
local Defineenum = require "defineenum"
local CharacterType = Defineenum.CharacterType
local NetWork=require"network"
local CharacterManager=require"character.charactermanager"

local CurveModelManager=require"character.curve.curvemodelmanager"
local PlayerRole=require "character.playerrole"
local SceneManager=require"scenemanager"
local EctypeManager=require"ectype.ectypemanager"
local ItemList={
    [cfg.item.EItemColor.WHITE]="diaoluo_bai",
    [cfg.item.EItemColor.GREEN] = "diaoluo_lv",
    [cfg.item.EItemColor.BLUE] = "diaoluo_lan",
    [cfg.item.EItemColor.PURPLE] = "diaoluo_zi",
    [cfg.item.EItemColor.ORANGE] = "diaoluo_cheng",
    [cfg.item.EItemColor.RED] = "diaoluo_hong",
}

local FlyItemList={
    [cfg.item.EItemColor.WHITE]="diaoluo_bai_fly",
    [cfg.item.EItemColor.GREEN] = "diaoluo_lv_fly",
    [cfg.item.EItemColor.BLUE] = "diaoluo_lan_fly",
    [cfg.item.EItemColor.PURPLE] = "diaoluo_zi_fly",
    [cfg.item.EItemColor.ORANGE] = "diaoluo_cheng_fly",
    [cfg.item.EItemColor.RED] = "diaoluo_hong_fly",
}

local DropItem = Class:new(Character)

function DropItem:__new()
    Character.__new(self)
    self.m_Type = CharacterType.DropItem
    self.m_Owner=nil
    self.m_LightEffect=false
    self.m_AutoTime=0
end

function DropItem:SetCSV(bonus)
    if bonus then
        for id ,value in pairs(bonus.items) do
            self.m_CsvId=id
            self.m_Value=value
            local ItemManager=require"item.itemmanager"
            if ItemManager.IsCurrency(id) then
                self.m_IsCurrency=true
            end
            break
        end
    end
end

function DropItem:AddLightEffect()
    if self.m_BufferObj~=true then
        local lightEffectName=ItemList[self.m_Color]
        Util.Load(string.format("sfx/s_%s.bundle", lightEffectName), Define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)
            if not IsNull(asset_obj) then
                local effectObject = GameObject.Instantiate(asset_obj)
                if not IsNull(self.m_Object) and (self.m_Object.transform) then
                    local attachTransform=self.m_Object.transform
                    effectObject.transform:SetParent(attachTransform)
                    local selfCollider=attachTransform:GetComponent("CapsuleCollider")
                    if selfCollider then
                        effectObject.transform.localPosition = Vector3(0,selfCollider.height/2,DROP_ITEM_Z)
                    else
                        effectObject.transform.localPosition = Vector3(0,0,DROP_ITEM_Z)
                    end
                    effectObject:SetActive(true)
                    self.m_CountTime=Time.time
                else
                    GameObject.DestroyImmediate(effectObject)
                    if self.m_Object then
                        GameObject.DestroyImmediate(self.m_Object)
                        self.m_Object = nil                    
                    end
                    self:remove()
                end
            else
                if self.m_Object then
                    GameObject.DestroyImmediate(self.m_Object)
                    self.m_Object = nil                    
                end
                self:remove()
            end
        end)
    else
        self.m_CountTime=Time.time
    end
end
function DropItem:SetHeadInfo()
    if self.m_HeadInfo then
        self.m_HeadInfo:ShowName(string.format(LocalString.TextColor[self.m_Color],(self.m_Name or self.m_Id or self.m_UIName.text)))
    end
end

function DropItem:OnLoaded(go)
    Character.OnLoaded(self,go)
end

function DropItem:update()
    Character.update(self)
    if self.m_Object  then
        if self.m_CountTime and (Time.time-self.m_CountTime)>=cfg.bonus.Drop.SHOW_TIME then
            self.m_CountTime=nil
            self:remove()
        end
    end
end

function DropItem:loadmodel(modeldata,charactermodeldata,isShowHeadInfo,playbornaction)
    local bundlename = self:GetBundlePath(modeldata.modelpath)
    local cacheobject = nil
    cacheobject = CharacterInstPool.GetCharacter(self.m_DropModelName)
    if cacheobject ~=nil then
        self.m_CharacterModelData = charactermodeldata or self.m_CharacterModelData
        self.m_ModelData = modeldata or self.m_CharacterModelData
        self.m_bNeedLoadAvatar = false
        self.m_bHasAvatar = false
        self.m_ModelPath = self.m_ModelData.modelpath
        if self.m_Object then
            GameObject.DestroyImmediate(self.m_Object)
            self.m_Object = nil
        end
        self.m_Object = cacheobject
        self.m_BufferObj=true
        self:OnCharacterLoaded(bundlename,cacheobject,isShowHeadInfo,playbornaction)
    else
        Character.loadmodel(self,modeldata,charactermodeldata,isShowHeadInfo,playbornaction)
    end
end

function DropItem:init(params,showhideinfo)
    self:SetCSV(params.bonus)
    self.m_Data = ConfigManager.getConfigData("dropmodel",self.m_CsvId)
    self.m_ModelData = ConfigManager.getConfigData("model",self.m_Data.modelpath)
    self.m_Color = cfg.item.EItemColor.WHITE
    if self.m_Data then
        self.m_Name = self.m_Data.name
        local color=self.m_Data.namecolor        
        if color then
            if color<cfg.item.EItemColor.ORANGE then              
                self.m_Color=cfg.item.EItemColor.WHITE
            else
                self.m_Color=cfg.item.EItemColor.RED
            end
        end
    end
    self.m_DropModelName=(self.m_ModelData.modelname)..(self.m_Color)
    self:loadmodel(self.m_ModelData,self.m_ModelData,false,nil)
    self.m_Pos=Vector3(params.position.x,params.position.y,-800)
    self.m_Owner=CharacterManager.GetCharacter(params.owner)
    local Update=function()
        self:update()
    end
    self.m_EvtId_Update=gameevent.evt_update:add(Update)
end

function DropItem:PlayCurveEffect(deadEffectName,effectObject,pos)
    SetDontDestroyOnLoad(effectObject)
    effectObject.transform.position = pos
    effectObject:SetActive(true)
    local DefineEnum=require"defineenum"
    local curveType=DefineEnum.TraceType.Line
    if cfg.bonus.Drop.CURVE_TYPE==0 then
        curveType=DefineEnum.TraceType.Line
    elseif cfg.bonus.Drop.CURVE_TYPE==1 then
        curveType=DefineEnum.TraceType.Bezier
    end
    CurveModelManager.AddCurveData(effectObject,function()    
        CharacterInstPool.PutCharacter(deadEffectName,effectObject)                    
    end,curveType)
end

function DropItem:PlayDeadEffect(pos,color)
    local deadEffectName=FlyItemList[color]
    local cacheobject = CharacterInstPool.GetCharacter(deadEffectName)
    if cacheobject~=nil then
        self:PlayCurveEffect(deadEffectName,cacheobject,pos)
    else
        Util.Load(string.format("sfx/s_%s.bundle", deadEffectName), Define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)
            if not IsNull(asset_obj) then
                local effectObject = GameObject.Instantiate(asset_obj)
                self:PlayCurveEffect(deadEffectName,effectObject,pos)
            end
        end)
    end
end

function DropItem:DestroyObject()
    if self.m_Object then
        --printyellow("DestroyObject,modelName:",modelName)
        CharacterInstPool.PutCharacter(self.m_DropModelName,self.m_Object)
        self.m_Object = nil
    end
end

function DropItem:remove()
    gameevent.evt_update:remove(self.m_EvtId_Update)
    printyellowmodule(Local.LogModuals.Drop,"dropitem:remove")
    local pos=Vector3(self.m_Pos.x * SCALE_XY_FRACTION,self.m_Pos.y * SCALE_XY_FRACTION, -800)
    self:PlayDeadEffect(pos,self.m_Color)
    self:release()
    self:reset()
    local DropManager=require"character.dropmanager"
    DropManager.DelDrop()
end

function DropItem:OnCharacterLoaded(bundlename,asset_obj,isShowHeadInfo,playbornaction)
    if self.m_Object then
        self.m_Object:SetActive(true)
        local managerObject = CharacterManager.GetCharacterManagerObject()
        self.m_Object.transform:SetParent(managerObject.transform)
        self:SetPos(Vector3(self.m_Pos.x,self.m_Pos.y, -800))    
        self:AddLightEffect()
        self:SetHeadInfo()
        self:OnLoaded(self.m_Object)
    end
end

return DropItem
