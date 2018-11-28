local GameObjectPool    = require"common.objectpool"
local template          = nil
local Define            = require"define"
local ObjPool           = nil
local CharacterManager
local objCharacters
local objHeadInfos
local HeadObjDepth      = {}

local HeadObject = Class:new()

function HeadObject:__new()
    self.m_Object = GameObject.Instantiate(template)
    self.m_Object:SetActive(true)
    self.m_Object.transform:SetParent(objHeadInfos.transform)
    self.m_Components = {}
    self.m_MaxDepth = -1e5
    local components = self.m_Object:GetComponentsInChildren(UIWidget)
    for i=1,components.Length do
        local component = components[i]
        self.m_Components[component.gameObject.name] = {}
        self.m_Components[component.gameObject.name].widget = component
        self.m_Components[component.gameObject.name].depth = component.depth
        self.m_Components[component.gameObject.name].location = component.gameObject.transform.localPosition
        self.m_MaxDepth = math.max(self.m_MaxDepth,component.depth)
    end
    -- self.m_Components[component.gameObject.name]
    -- self.m_Components["headinfo_hp"].location = vec3.zero
end

function HeadObject:GetHeadObject()
    return self.m_Object
end

function HeadObject:GetComponents()
    return self.m_Components
end

function HeadObject:GetMaxDepth()
    return self.m_MaxDepth + 2
end

function HeadObject:Release()
    self.m_Object.transform:SetParent(objCharacters.transform)
    GameObject.Destroy(self.m_Object)
end

function HeadObject:Recover()
    self.m_Object.transform:SetParent(objHeadInfos.transform)
    self.m_Object.transform.position = Vector3(1e10,1e10,1e10)
end

local function GetObject()
    if ObjPool then
        return ObjPool:GetObject()
    end
end

local function PushObject(obj)
    if ObjPool then
        if ObjPool:PushObject(obj) then
            obj:Recover()
            return true
        end
    end
    return false
end

local function GetHeadObjDepth()
    return HeadObjDepth
end

local function init()
    HeadObjDepth        = {}
    -- HeadObjMaxDepth     = -1e5
    CharacterManager    = require"character.charactermanager"
    objHeadInfos  = GameObject("headinfos")
    objCharacters       = CharacterManager.GetCharacterManagerObject()
    objHeadInfos.transform:SetParent(objCharacters.transform)
    local bundleName = "ui/dlgmonster_hp.ui"
--    Util.Load(bundleName, Define.ResourceLoadType.LoadBundleFromFile,function(obj)
--        if not IsNull(obj) then
--            template = Util.Instantiate(obj,bundleName)
--            ExtendedGameObject.SetLayerRecursively(template, Define.Layer.LayerDefault)
--            template.transform.parent = objHeadInfos.transform
--            -- template.transform.position = Vector3(1e8,1e8,1e8)
--            -- template.transform.localPosition = Vector3(1e8,1e8,1e8)

--            template:SetActive(false)
--            ObjPool = GameObjectPool:new(HeadObject,20,true)
--        end
--    end)
end


return {
    init            = init,
    GetObject       = GetObject,
    PushObject      = PushObject,
    GetMaxObjDepth  = GetMaxObjDepth,
    GetHeadObjDepth = GetHeadObjDepth,

}
