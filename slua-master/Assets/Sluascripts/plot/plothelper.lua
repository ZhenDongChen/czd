local define = require "define"
local SceneManager = require("scenemanager")
local ConfigManager = require("cfg.configmanager")
local ResourceLoadType = define.ResourceLoadType
--===============================================================================================================================


local function AddObject(cutscene,obj)
    if cutscene.Objects == nil then
        cutscene.Objects = {}
    end
    if cutscene and obj then
        obj.transform.parent = cutscene.Object.transform
        cutscene.Objects[obj.name] = obj
    end
end

local function CreateObject(cutscene, obj, name)
    local obj = UnityEngine.GameObject.Instantiate(obj)
    obj.name = name
    AddObject(cutscene,obj)
    return obj
end

local modelPathInfo = {
    [cfg.character.ModelType.Base]      = {folder = "character", prefix ="c_"},
    [cfg.character.ModelType.Player]    = {folder = "character", prefix ="c_"},
    [cfg.character.ModelType.Monster]   = {folder = "character", prefix ="c_"},
    [cfg.character.ModelType.Npc]       = {folder = "character", prefix ="c_"},
    [cfg.character.ModelType.Dress]     = {folder = "character", prefix ="c_"},
    [cfg.character.ModelType.Talisman]  = {folder = "character", prefix ="c_"},
    [cfg.character.ModelType.Effect]    = {folder = "sfx",       prefix ="s_"},
    [cfg.character.ModelType.Item]      = {folder = "character", prefix ="c_"},
    [cfg.character.ModelType.Boss]      = {folder = "character", prefix ="c_"},
}
--获取模型地址
local function GetBundlePath(model)
    printyellow(model.modeltype, model.modelpath)
    local fullPath = modelPathInfo[model.modeltype].folder .. "/" ..
                        modelPathInfo[model.modeltype].prefix .. model.modelpath .. ".bundle"
	printyellow(fullPath)
    return fullPath
end
--加载皮肤
local function LoadModelTexture(go, model,callback)

    local mr = go.transform:GetChild(0):GetComponentInChildren(UnityEngine.Types.GetType("UnityEngine.SkinnedMeshRenderer","UnityEngine"))
    if mr ~= nil or model.avatarid == nil or model.avatarid == "" then
        callback(go)
        return
    else

    end
    if model.avatarid == "" or model.avatarid == nil then return end
    local path = string.format("avatar/amour_%s.bundle",tostring(model.avatarid))
    Util.LoadAvatar(path,function(asset_obj)
        if asset_obj then
            for i = 1, go.transform:GetChild(0).childCount do
                local trans = go.transform:GetChild(0):GetChild(i-1)
                UUtil.Destroy(trans.gameObject)
            end
            local newGo = Util.Instantiate(asset_obj)
            local childList = {}
            for i = 1, newGo.transform.childCount do
            --    printyellow(i , newGo.transform.childCount)
                local trans = newGo.transform:GetChild(i-1)
                table.insert(childList,trans)
            end
            for i,trans in pairs(childList) do
                trans.parent = go.transform:GetChild(0)
            end
            Util.Destroy(newGo)
        end
        callback(go)
    end)
    return
end
--加载Prefab
local function LoadObject(indexName,cutscene,name,callBack)
    local plotassets = ConfigManager.getConfigData("plotassets",indexName)
    local newCallBack = callBack or (function(tempGo) end)
    if plotassets == nil then
        logError("Can't find Plot Resources: " .. indexName)
    end
    local model = ConfigManager.getConfigData("model",plotassets.path)
    if model == nil then
        logError("Can't find Model: " .. plotassets.path)
    end
    local Path = GetBundlePath(model)
    Util.Load(Path, ResourceLoadType.LoadBundleFromFile,function(asset_obj)
        if asset_obj == nil then
            logError("Can't find Plot Resources: " .. Path)
        end
        local go = CreateObject(cutscene,asset_obj,name)
        if plotassets.detailtype == "character" then
            go = LoadModelTexture(go,model,newCallBack)
        else
            newCallBack(go)
        end
    end)
end

--加载Animator
local function LoadAnimator(indexName,callBack)
    local plotassets = ConfigManager.getConfigData("plotassets",indexName)
    local Path = plotassets.path
    Util.Load(Path, ResourceLoadType.LoadBundleFromFile, function(asset_obj)
        if callBack ~= nil then
            callBack(asset_obj)
        end
    end )
end
--从物体变中获取物体
local function GetObject(Cutscene,objectName)
    local index, objName, subName;
    if Cutscene and Cutscene.Objects and objectName then
        index = string.find(objectName,"/")
        if index then
            objName = string.sub(objectName,1,index-1)
            subName = string.sub(objectName,string.find(objectName,"/")+1,#objectName)
        else
            objName = objectName
            subName = nil
        end
        if Cutscene.Objects[objName] ~= nil then
            if subName == nil then
                return Cutscene.Objects[objName]
            else
                local trans = Cutscene.Objects[objName].transform:Find(subName)
                if trans then
                    return trans.gameObject
                else
                    return nil
                end
            end
        end
    end
end
--从Cutscene的物体表中移除物体
local function RemoveObject(cutscene,obj)
    if cutscene and cutscene.Objects and obj then
        if cutscene.Objects[obj.name] then
            cutscene.Objects[obj.name] = nil
        end
    end
end
--销毁物体
local function DestroyObject(cutscene,obj)
    RemoveObject(cutscene,obj)
    Util.Destroy(obj)
end
--使物体紧贴地面
local function SetObjectOnGround(obj,offsetY)
    local vecPos = Vector3(obj.transform.position.x,0,obj.transform.position.z)
    local terrianY = SceneManager.GetHeight(vecPos);
	obj.transform.position = Vector3(vecPos.x,terrianY + offsetY,vecPos.z);
end


--===============================================================================================================================
-------------------------------------------
--播放声音
-------------------------------------------
--计算音频文件路径
local function GetAudioBundlePath(path)
	local substr_start, substr_end= string.find(path,"/music")
	if substr_start ~= nil and substr_end ~= nil then
		local str,_ = string.gsub(path,"/music","")
		return str
	else
	 	local str1 = string.sub(path,string.find(path,"[%w_]+/"))
	 	local str2 = string.sub(path,string.find(path,"[%w_]+%."))
	 	return str1 .. "a_" .. str2 .. "bundle"
	end
end
--播放2D声音
local function Play2DSound(path,isLoop,startPos)
   -- if true then return end
    if true then return end
    return PlotDirector.Instance:Play2DSound(GetAudioBundlePath(path),isLoop,startPos);
end
--播放3D声音
local function Play3DSound(path,playPos,isLoop,startPos)
   -- if true then return end
   if true then return end
    return PlotDirector.Instance:Play3DSound(GetAudioBundlePath(path),playPos,isLoop,startPos);
end
--播放背景音乐
local function PlayBackMusic(path,isLoop,startPos)
   -- if true then return end
   if true then return end
    return PlotDirector.Instance:PlayBackMusic(GetAudioBundlePath(path),isLoop,startPos);
end
--===============================================================================================================================
return {
    --GetResourcesPath    = GetResourcesPath,
    GetBundlePath       = GetBundlePath,
    LoadObject          = LoadObject,
    GetObject           = GetObject,
    CreateObject        = CreateObject,
    DestroyObject       = DestroyObject,
    SetObjectOnGround   = SetObjectOnGround,
    GetAudioBundlePath  = GetAudioBundlePath,

    Play2DSound         = Play2DSound,
    Play3DSound         = Play3DSound,
    PlayBackMusic       = PlayBackMusic,
}
