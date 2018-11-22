local PlotAssetFactory = require("plot.base.plotassets.factory")
local PlotDefine = require("plot.base.plotdefine")

local PlotPool = Class:new()

function PlotPool:__new(cutscene, config)
    self.m_AssetsIndex = cutscene.m_Cutscene.AssetIndexList
    self.m_Cutscene = cutscene
    self.m_Assets = {}
    self.m_GameObjects = {}
    self.m_GameObjectInfos = {}

    self.m_Object = UnityEngine.GameObject("ObjectPool")
    self.m_Object.transform.parent = cutscene.m_GameObject.transform
end

function PlotPool:Init()

end

function PlotPool:Load()
    for i, index in pairs(self.m_AssetsIndex) do
        self.m_Assets[index] = PlotAssetFactory.CreateAsset(self.m_Object,index, self.m_Cutscene)   --PlotAsset:new(index)
    end
end

function PlotPool:IsReady()
    for index, asset in pairs(self.m_Assets) do
        if asset:IsReady() == false then
            return false
        end
    end
    return true
end


function PlotPool:GetAssetsState()
    local state = PlotDefine.AssetState.Inited
    
    for index, asset in pairs(self.m_Assets) do
        local assetState = asset:GetState()
        if assetState == PlotDefine.AssetState.Failed then
            return PlotDefine.AssetState.Failed
        end
        if assetState ~= PlotDefine.AssetState.Finish then
            return PlotDefine.AssetState.Loading
        end
    end
    return PlotDefine.AssetState.Finish
end

function PlotPool:Spawn(index, name, active)
    local obj = self.m_Assets[index]:Instantiate()
    obj.name = name
    if active ~= nil then
        obj:SetActive(active)
    end
    self.m_GameObjects[name] = obj
    self.m_GameObjectInfos[name] = self.m_Assets[index]
    obj.transform.parent = self.m_Object.transform
    return obj
end

function PlotPool:GetAssetType(index)
    --printyellow("index:=> ", index)
    return self.m_Assets[index]:GetType()
end

function PlotPool:Get(name)
    local index, objName, subName;
    index = string.find(name,"/")
    if index then
        objName = string.sub(name,1,index-1)
        subName = string.sub(name,index+1,#name)
    else
        objName = name
        subName = nil
    end
    local go = self.m_GameObjects[objName]
    if subName == nil then
        return go
    elseif go ~= nil then
        local trans = go.transform:Find(subName)
        return (trans ~= nil) and trans.gameObject or nil
    end
    
end

function PlotPool:GetObjectModelName(name)
    return self.m_GameObjectInfos[name]:GetModelName()
end

function PlotPool:Despawn(name)
    local obj = self.m_GameObjects[name]
    self.m_GameObjects[name] = nil
    if obj ~= nil then
        PlotAssetFactory.DestroyObject(obj)
        --UnityEngine.GameObject.Destroy(obj)
    end
end

function PlotPool:Destroy()
    for i, asset in pairs(self.m_Assets) do
        asset:Destroy()
    end
end

function PlotPool:OnStart()

end

function PlotPool:OnEnd()

end

function PlotPool:OnLoad()

end

return PlotPool