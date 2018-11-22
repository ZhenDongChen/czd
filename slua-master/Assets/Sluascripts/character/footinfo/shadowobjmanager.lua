local GameObjectPool    = require"common.gameobjectpool"
local template          = nil
local Define            = require"define"
local ObjPool           = nil
local CharacterManager
local objCharacters

local function GetObject()
    if ObjPool then
        local obj = ObjPool:GetObject()
        obj.name = "shadow"
        return obj
    end
end

local function PushObject(obj)
    if ObjPool then
        return ObjPool:PushObject(obj)
    end
    return false
end

local function init()
    CharacterManager  = require"character.charactermanager"
    local objHeadInfos = GameObject("shadows")
    objCharacters = CharacterManager.GetCharacterManagerObject()
    objHeadInfos.transform:SetParent(objCharacters.transform)
    local bundleName = "character/c_shadow.bundle"
    Util.Load(bundleName, Define.ResourceLoadType.LoadBundleFromFile,function(obj)
        if not IsNull(obj) then
            template = Util.Instantiate(obj,bundleName)
            template.transform:SetParent(objHeadInfos.transform)
            template:SetActive(false)
            ObjPool = GameObjectPool:new(template,20,nil,objHeadInfos.transform)
        end
    end)
end


return {
    init            = init,
    GetObject       = GetObject,
    PushObject      = PushObject,
}
