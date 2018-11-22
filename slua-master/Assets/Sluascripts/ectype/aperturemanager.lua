local PlayerRole = require"character.playerrole"
local CharacterManager = require("character.charactermanager")
local Define = require("define")

local Aperture = Class:new()

function Aperture:__new(manager, charId, selfCamp)
    self.m_Manager = manager
    self.m_Object = GameObject("aperture_" .. tostring(charId))
    self.m_Object.transform:SetParent(self.m_Manager.m_Object.transform)
    self.m_Transform = self.m_Object.transform
    self.m_CharId = charId
    self.m_IsSelfCamp = selfCamp
    self:Load()
end

function Aperture:Load()
    local bundleName = "sfx/s_footinfo.bundle"
    Util.Load(bundleName, Define.ResourceLoadType.LoadBundleFromFile, function(obj)
        if not IsNull(obj) then
            local template = Util.Instantiate(obj,bundleName)
            if IsNull(self.m_Object) then
                GameObject.Destroy(template)
            else
                template.transform:SetParent(self.m_Object.transform)
                template.transform.localPosition = Vector3(0,0,0)
                local blue_trans = template.transform:Find("mubiao_Xuan_Lan")
                local red_trans = template.transform:Find("mubiao_Xuan_Hong")
                local yellow_trans = template.transform:Find("mubiao_Xuan_Huang")
                if blue_trans and red_trans and yellow_trans then
                    blue_trans.gameObject:SetActive(self.m_IsSelfCamp)
                    red_trans.gameObject:SetActive(not self.m_IsSelfCamp)
                    yellow_trans.gameObject:SetActive(false)
                end
            end
        end
    end)
end

function Aperture:GetCharacterId()
    return self.m_CharId
end

function Aperture:SetPos(refPos)
    if self.m_Transform then
        self.m_Transform.position = refPos
    end
end

function Aperture:Destroy()
    if self.m_Object then
        GameObject.Destroy(self.m_Object)
    end
    self.m_Object = nil
    self.m_Transform = nil
end
--==============================================================================

local ApertureManager = Class:new()

function ApertureManager:__new(ectype)
    self.m_Ectype = ectype
    self.m_Object = GameObject("ApertureRootObject")
    SetDontDestroyOnLoad(self.m_Object)
    self.m_Apertures = {}
end

function ApertureManager:RemoveAll()
    for _, aperture in pairs(self.m_Apertures) do
        aperture:Destroy()
    end
    self.m_Apertures = {}
end

function ApertureManager:OnStart()
    self:RemoveAll()
    for _, character in pairs(CharacterManager.GetCharacters()) do
        if PlayerRole:Instance().m_Camp and (character:IsPlayer() or character:IsPet()) and character.m_Camp ~= nil then
            self:Add(character.m_Id, character.m_Camp)
        end
    end
end

function ApertureManager:Contain(charId)
    return self.m_Apertures[charId] ~= nil
end

function ApertureManager:Remove(charId)
    if self.m_Apertures[charId] then
        self.m_Apertures[charId]:Destroy()
        self.m_Apertures[charId] = nil
    end
end

function ApertureManager:Add(charId, camp)
    if self.m_Apertures[charId] == nil then
        self.m_Apertures[charId] = Aperture:new(self, charId, (camp == PlayerRole:Instance().m_Camp))
    end

end

function ApertureManager:OnEnd()
    --printyellow("ApertureManager OnEnd")
    self:RemoveAll()
    if self.m_Object then
        GameObject.Destroy(self.m_Object)
    end
end

function ApertureManager:OnUpdate()
    local removeList = {}
    for i, aperture in pairs(self.m_Apertures) do
        local charId = aperture:GetCharacterId()
        local character = CharacterManager.GetCharacter(charId)
        if character then
            aperture:SetPos(character:GetRefPos())
        else
            table.insert(removeList, charId)
        end
    end
    if #removeList > 0 then
        for i, id in pairs(removeList) do
            if self.m_Apertures[id] then
                self.m_Apertures[id]:Destroy()
                self.m_Apertures[id] = nil
            end
        end
    end
end

return ApertureManager
