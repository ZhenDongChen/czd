local UIManager         = require("uimanager")
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")
local ItemEnum          = require("item.itemenum")
local ItemManager       = require("item.itemmanager")
local TalismanModel     = require("character.talisman.talisman")
local ColorUtil         = require("common.colorutil")
local EventHelper       = UIEventListenerHelper
local BagManager        = require("character.bagmanager")
local DlgUpdate         = require("ui.playerrole.talisman.dlgtalisman_update")
local DlgAdvance        = require("ui.playerrole.talisman.dlgtalisman_advanced")

local PageTalismanEquip = {
    m_Talisman = nil,
    m_IsLoading = false,
    m_UIModel = nil,
}

function PageTalismanEquip:SetTopInfo(talisman)
    self.fields.UILabel_TopTalismanLV.text      = talisman:GetNormalLevel()
    --self.fields.UILabel_TopTalismanName.text    = talisman:GetName()

    --self.fields.UILabel_TopTalismanName.color = ColorUtil.GetQualityColor(talisman:GetQuality())
    --self.fields.UILabel_TopTalismanName.effectColor = ColorUtil.GetOutlineColor(talisman:GetQuality())
    ColorUtil.SetQualityColorText(self.fields.UILabel_TopTalismanName, talisman:GetQuality(), talisman:GetName())

    self.fields.UILabel_TopTalismanPower.text   = talisman:GetPower()
    self.fields.UILabel_TopStar.text            = TalismanUITools.GetStarOrderText(talisman)
    self.fields.UILabel_TopAwakening.text       = TalismanUITools.GetAwakeText(talisman)
end

function PageTalismanEquip:SetModelInfo(talisman)

    if self.m_Talisman ~= talisman then
        if self.m_Talisman and self.m_UIModel then
            self.m_UIModel:remove()
            self.m_UIModel = nil
        end
        self.m_Talisman = talisman
    end
    if self.m_UIModel == nil and self.m_IsLoading == false then
        self.m_IsLoading = true
        self.m_UIModel = TalismanModel:new()
        self.m_UIModel.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
        self.m_UIModel:RegisterOnLoaded(function(asset_obj)
            self.m_IsLoading = false
            asset_obj:SetActive(true)
            asset_obj.transform.parent = self.fields.UITexture_TalismanModel.gameObject.transform
			asset_obj.transform.localScale = Vector3.one * talisman:GetUILocalScale()
            asset_obj.transform.localPosition = talisman:GetUILocalPosition()
            asset_obj.transform.rotation = Quaternion.Euler(-90,0,0)
            ExtendedGameObject.SetLayerRecursively(asset_obj, define.Layer.LayerUICharacter)
            EventHelper.SetDrag(self.fields.UITexture_TalismanModel, function(o,delta)
                local vecRotate = Vector3(0,-delta.x,0)
                self.m_UIModel.m_Object.transform.localEulerAngles = self.m_UIModel.m_Object.transform.localEulerAngles + vecRotate
            end)
            self.fields.UITexture_TalismanModel.gameObject:SetActive(false)
            self.fields.UITexture_TalismanModel.gameObject:SetActive(true)
        end)
        self.m_UIModel:init(talisman, PlayerRole:Instance(), -1)

    elseif self.m_UIModel ~= nil and self.m_UIModel.m_Object ~= nil and self.m_IsLoading == false then
        self.m_UIModel.m_Object:SetActive(true)
        self.m_UIModel.m_Object.transform.parent = self.fields.UITexture_TalismanModel.gameObject.transform
		self.m_UIModel.m_Object.transform.localScale = Vector3.one * talisman:GetUILocalScale()
        self.m_UIModel.m_Object.transform.localPosition = talisman:GetUILocalPosition()--Vector3(0, -200, -500);
        self.m_UIModel.m_Object.transform.rotation = Quaternion.Euler(-90,0,0)
        --ExtendedGameObject.SetLayerRecursively(self.m_UIModel.m_Object, define.Layer.LayerUICharacter)
        EventHelper.SetDrag(self.fields.UITexture_TalismanModel, function(o,delta)
            local vecRotate = Vector3(0,-delta.x,0)
            self.m_UIModel.m_Object.transform.localEulerAngles = self.m_UIModel.m_Object.transform.localEulerAngles + vecRotate
        end)
    else
    
    end
end

function PageTalismanEquip:SetButtons(talisman)
    EventHelper.SetClick(self.fields.UIButton_Unload, function()
        TalismanManager.UnEquipTalisman(talisman)
    end)
    EventHelper.SetClick(self.fields.UIButton_Strengthen, function()
        UIManager.show("playerrole.talisman.dlgtalisman_advanced",{talisman = talisman, page = 1, showRedDot = true})
    end)
    EventHelper.SetClick(self.fields.UIButton_Update, function()
        UIManager.show("playerrole.talisman.dlgtalisman_update",{talisman = talisman})
    end)
end

local function EquipTalismanByGetPanel(selectedTaliman)

    local currentTalisman = TalismanManager.GetCurrentTalisman()
    if selectedTaliman ~= nil then
        TalismanManager.EquipTalisman(selectedTaliman)
    end

end

function PageTalismanEquip:update()
    if self.m_UIModel then
        self.m_UIModel.m_Avatar:Update()
    end
end

function PageTalismanEquip:UpgradeRedDot(talisman)
    return DlgUpdate.UnRead(talisman)
end

function PageTalismanEquip:AdvanceRedDot(talisman)
    return DlgAdvance.UnRead(talisman)
end

function PageTalismanEquip:refresh(currentTalisman)

    self.talisman = currentTalisman
    if self.talisman == nil then
        self.fields.UIGroup_NoneTalisman.gameObject:SetActive(true)
        self.fields.UIGroup_EquipedTalisman.gameObject:SetActive(false)
        EventHelper.SetClick(self.fields.UIButton_Battle, function()
            UIManager.show("playerrole.talisman.dlgtalisman_get")
        end)
    else
        self.fields.UIGroup_NoneTalisman.gameObject:SetActive(false)
        self.fields.UIGroup_EquipedTalisman.gameObject:SetActive(true)
        self:SetTopInfo(currentTalisman)
        self:SetModelInfo(currentTalisman)
        self:SetButtons(currentTalisman)

        if self:UpgradeRedDot(currentTalisman) then
            self.fields.UISprite_UpgradeTip.gameObject:SetActive(true)
        else
            self.fields.UISprite_UpgradeTip.gameObject:SetActive(false)
        end

        if self:AdvanceRedDot(currentTalisman) then
            self.fields.UISprite_StrTip.gameObject:SetActive(true)
        else
            self.fields.UISprite_StrTip.gameObject:SetActive(false)
        end
    end
end

function PageTalismanEquip:show()

    self.fields.UIGroup_MagicKeyEquip.gameObject:SetActive(true)
end

function PageTalismanEquip:hide()
    self.m_Talisman = nil
    if self.m_UIModel ~= nil then
        --printyellow("hide....")
        self.m_UIModel:remove()
        self.m_UIModel = nil
    end
    self.m_IsLoading = false

    self.fields.UIGroup_MagicKeyEquip.gameObject:SetActive(false)
end

function PageTalismanEquip:init(name, gameObject, fields)
    self.fields = fields
end

return PageTalismanEquip
