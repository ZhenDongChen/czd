local ConfigManager     = require("cfg.configmanager")
local AssetBase         = require("plot.base.plotassets.base")
local PlotDefine        = require("plot.base.plotdefine")
local ResourceManager   = require("resource.resourcemanager")



local AssetModel = Class:new(AssetBase)

function AssetModel:__new(index,config,parentObject,cutscene)
    AssetBase.__new(self, index,config,parentObject,cutscene)

    self.m_Prefab   = nil
    self.m_IsReady  = false
    self.m_State    = PlotDefine.AssetState.Inited
    self.m_Object   = parentObject
    self.m_ModelName = config.path

    self:Load(self.m_Config, function()
        self.m_IsReady = true
        self.m_State   = PlotDefine.AssetState.Finish
    end)
end

function AssetModel:Load(config, callback)
    ResourceManager.LoadObject(config.path, nil, function(asset_obj)
        if asset_obj ~= nil then
            self.m_Prefab = asset_obj
            self.m_Prefab:SetActive(false)
            if not IsNull(self.m_Object) then
                self.m_Prefab.transform.parent = self.m_Object.transform
                callback()
            else
                ResourceManager.Destroy(self.m_Prefab)
                self.m_Prefab = nil
            end
        else
            logError("找不到模型: " .. config.path)
            self.m_State = PlotDefine.AssetState.Failed
        end
    end)
end

function AssetModel:Instantiate()
    return ResourceManager.Copy(self.m_Prefab)
end

function AssetModel:GetModelName()
    return self.m_ModelName
end

function AssetModel:GetPrefab()
    return self.m_Prefab
end

function AssetModel:IsReady()
    
    return self.m_IsReady
end
function AssetModel:GetState()
    return self.m_State
end

function AssetModel:Destroy()
    if self.m_Prefab ~= nil then
    --    UnityEngine.Object.Destroy(self.m_Prefab)
    end
end


return AssetModel
