local AssetBase         = require("plot.base.plotassets.base")
local ConfigManager     = require("cfg.configmanager")
local PlotDefine        = require("plot.base.plotdefine")
local ResourceManager   = require("resource.resourcemanager")
local Player            = require("character.player")

local AssetSpecial = Class:new(AssetBase)

function AssetSpecial:__new(index,config,parentObject,cutscene)
    AssetBase.__new(self,index,config,parentObject,cutscene)
    self.m_Prefab   = nil
    self.m_IsReady  = false
    self.m_State    = PlotDefine.AssetState.Inited
    self.m_Object   = parentObject
    self.m_TempPlayer = nil
    self.m_Cutscene = cutscene
    self:Load(self.m_Config,function() 
        self.m_IsReady = true
        self.m_State = PlotDefine.AssetState.Finish
    end)
end

function AssetSpecial:Load(config, callback)
    if config.index == "MainCharacter" then
        self.m_TempPlayer = Player:new()
        self.m_TempPlayer:RegisterOnLoaded(function(obj)
            if not IsNull(obj) then
                local modelname = tostring(self.m_Cutscene.m_Config:GetRoleModelName()) .. "CG"
                ResourceManager.ReplaceAnimatorControl(modelname, obj, function(gmobj)
                    if not IsNull(gmobj) then
                        self.m_Prefab = gmobj
                        self.m_Prefab:SetActive(false)
                        if not IsNull(self.m_Object) then
                            self.m_Prefab.transform.parent = self.m_Object.transform
                            callback()
                        else
                            ResourceManager.Destroy(self.m_Prefab)
                            self.m_Prefab = nil
                        end
                    else
                        logError("加载失败: MainCharacter")
                        self.m_State = PlotDefine.AssetState.Failed
                    end
                end)
            else
                logError("加载失败: MainCharacter")
                self.m_State = PlotDefine.AssetState.Failed
            end
        end)

        self.m_TempPlayer:init(1, 
                    PlayerRole:Instance().m_Profession,
                    PlayerRole:Instance().m_Gender,
                    false,
                    PlayerRole:Instance().m_Dress,
                    PlayerRole:Instance().m_Equips,
                    false,
                    1)
        self.m_ModelName = PlayerRole:Instance().m_ModelData.modelname
        
    elseif config.index == "Hand" then
        local modelname = self.m_Cutscene.m_Config:ProfessionHandIndex()

        ResourceManager.LoadObject(modelname, nil, function(asset_obj)
            if asset_obj ~= nil then
                self.m_Prefab = asset_obj
                self.m_Prefab:SetActive(false)
                self.m_Prefab.transform.parent = self.m_Object.transform
                callback()
            else
                logError("找不到模型: " .. plotassets.path)
                self.m_State = PlotDefine.AssetState.Failed
            end
        end)    
    else
        self.m_Prefab = UnityEngine.GameObject("None")
        callback()
    end
        
end

function AssetSpecial:GetModelName()
    return self.m_ModelName
end

function AssetSpecial:IsReady()
    if self.m_Prefab == nil then
        if self.m_TempPlayer ~= nil then
            self.m_TempPlayer.m_Avatar:Update()
        end
    end
    return self.m_IsReady
end


function AssetSpecial:Destroy()
    if self.m_TempPlayer ~= nil then
        self.m_TempPlayer:release()
        self.m_TempPlayer = nil
    end
    return AssetBase.Destroy(self)
end


function AssetSpecial:GetState()
    return self.m_State
end 

function AssetSpecial:Instantiate()
	assert(self.m_Prefab)
    local go = ResourceManager.Copy(self.m_Prefab)
    go:SetActive(true)
    
    local listName = {"footinfo","headinfo_hp","fx_direction_grn(Clone)","fx_direction_red(Clone)"}
    for i,name in pairs(listName) do
        local trans =  go.transform:Find(name)
        if trans then
            trans.gameObject:SetActive(false)
        end
    end
    
    return go
end

return AssetSpecial