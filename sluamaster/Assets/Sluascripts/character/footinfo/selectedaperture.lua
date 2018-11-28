local Define            = require("define")

local SelectedAperture = Class:new()

function SelectedAperture:__new()
    self.m_Character = nil
    self.m_Object = nil
    self.m_ObjColor_Blue = nil
    self.m_ObjColor_Red = nil
    self.m_ObjColor_Yellow = nil
    self:Load()

    
end

function SelectedAperture:Load()
    local CharacterManager  = require("character.charactermanager")
    self.m_Object = UnityEngine.GameObject("selectedaperture")
    self.m_Object:SetActive(false)
    local objCharacters = CharacterManager.GetCharacterManagerObject()
    self.m_Object.transform:SetParent(objCharacters.transform)
    local bundleName = "sfx/s_footinfo.bundle"
    Util.Load(bundleName,Define.ResourceLoadType.LoadBundleFromFile,function(obj)
        if not IsNull(obj) then
            local template = Util.Instantiate(obj,bundleName)
            template.transform:SetParent(self.m_Object.transform)
            template.transform.localPosition = Vector3(0,0,2)
            local blue_trans = template.transform:Find("mubiao_Xuan_Lan")
            local red_trans = template.transform:Find("mubiao_Xuan_Hong")
            local yellow_trans = template.transform:Find("mubiao_Xuan_Huang")
            if blue_trans and red_trans  and yellow_trans then
                self.m_ObjColor_Blue    = blue_trans.gameObject
                self.m_ObjColor_Red     = red_trans.gameObject
                self.m_ObjColor_Yellow  = yellow_trans.gameObject
                self:SetColor()
            end
        end
    end)

end

function SelectedAperture:SetColor()
    local isShowRed = false
    local isShowYellow = true
    local isShowBlue = false
    if self.m_Character and self.m_Character.m_ModelData and self.m_Character.m_Camp ~= nil then
        local CharacterManager  = require("character.charactermanager")
        local campRelation = CharacterManager.GetRelation(self.m_Character.m_Camp)
        if campRelation == cfg.fight.Relation.ENEMY then
            isShowRed = true
            isShowYellow = false
            isShowBlue = false 
        elseif campRelation == cfg.fight.Relation.FRIEND then
            isShowRed = false
            isShowYellow = false
            isShowBlue = true 
        else
            isShowRed = false
            isShowYellow = true
            isShowBlue = false 
        end
    end
    if self.m_ObjColor_Red then
        self.m_ObjColor_Red:SetActive(isShowRed)
    end
    if self.m_ObjColor_Yellow then
        self.m_ObjColor_Yellow:SetActive(isShowYellow)
    end
    if self.m_ObjColor_Blue then
        self.m_ObjColor_Blue:SetActive(isShowBlue)
    end

end

function SelectedAperture:Instance()
    if _G.SelectedAperture then
        return _G.SelectedAperture
    end
    local aperture = SelectedAperture:new()
    _G.SelectedAperture = aperture
    return aperture
end

function SelectedAperture:Update()
    if self.m_Object and self.m_Character and self.m_Character.m_Object then
		if self.m_Character.m_Mount ~= nil then
			local playerPos = self.m_Character.m_Mount.m_Object.transform.position
			self.m_Object.transform.position = Vector3(playerPos.x, playerPos.y, playerPos.z)
		else
			local playerPos = self.m_Character.m_Object.transform.position
			self.m_Object.transform.position = Vector3(playerPos.x, playerPos.y, playerPos.z)
		end
        
    end
end


function SelectedAperture:SetTarget(char)
    if char == nil then
        self:CancelTarget()
    else
        self.m_Character = char
        self.m_Object:SetActive(true)
        if self.m_Character.m_ModelData then
            local scale = self.m_Character.m_ModelData.aperturescale or 1
            self.m_Object.transform.localScale = Vector3(scale,scale,scale)
            self:SetColor()
        end
    end
end

function SelectedAperture:GetTarget()
    return self.m_Character
end

function SelectedAperture:CancelTarget()
    self.m_Character = nil
    if self.m_Object then
        self.m_Object:SetActive(false)
        self.m_Object.transform.localScale = Vector3(1,1,1)
    end
end


return SelectedAperture