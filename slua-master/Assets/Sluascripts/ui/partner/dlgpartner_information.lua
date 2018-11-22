local unpack                = unpack
local print                 = print
local math                  = math
local uimanager             = require"uimanager"
local EventHelper           = UIEventListenerHelper
local ConfigManager         = require"cfg.configmanager"
local BagManager            = require"character.bagmanager"
local PetManager            = require"character.pet.petmanager"
local mathutils             = require"common.mathutils"
local dlgList               = require"ui.common.dlgdialogbox_list"

local gameObject ,name ,fields
local StatusText
local pet

local function RefreshPartnerInformation()
    local petAttribute = PetManager.GetAttributes(pet)
    for i,v in ipairs(PetManager.InfoAttr) do
        -- local currentItem =
        if v.idx == cfg.fight.AttrId.ATTACK_VALUE then
            local val1 = petAttribute[cfg.fight.AttrId.ATTACK_VALUE_MIN] or 0
            local val2 = petAttribute[cfg.fight.AttrId.ATTACK_VALUE_MAX] or 0
            local text1 = mathutils.GetAttr(val1,StatusText[v.idx].displaytype)
            local text2 = mathutils.GetAttr(val2,StatusText[v.idx].displaytype)
            uiList_Attributes[i].labelValue.text = tostring(text1) .. '-' .. tostring(text2)
        else
            local val = petAttribute[v.idx] or 0
            uiList_Attributes[i].labelValue.text = mathutils.GetAttr(val,StatusText[v.idx].displaytype)
        end
    end

    -- fields.UILabel_Discription = pet.ConfigData.introduction
	printyellow("pet.ConfigData.introduction"..tostring(pet.ConfigData.feature))
    fields.UILabel_Feature.text = pet.ConfigData.feature

    local karmas = PetManager.GetKarmas(pet)
    for i=1,6 do
        local karma = karmas[i]
        local item = fields.UIList_PartnerLuckychance:GetItemByIndex(i-1)
        if karma then
            item.gameObject:SetActive(true)
            local text = karma.karma.karmaname
            if karma.level > 0 then
                text = LocalString.PartnerText.ActiveColor .. text .. LocalString.PartnerText.ColorSuffix
            end
            local labelKarmaName = item.Controls["UILabel_PartnerLuckychance"]
            labelKarmaName.text = text
        else
            item.gameObject:SetActive(false)
        end
    end
    for i=1,5 do
        local item = fields.UIList_ScrollAttr:GetItemByIndex(i-1)
        local slider = item.Controls["UISlider_SlideBackground"]
        slider.value = pet.ConfigData.featurelist[i]/100
        local label = item.Controls["UILabel_Number"]
        label.text = tostring(pet.ConfigData.featurelist[i])
    end
    fields.UILabel_Discription.text = pet.ConfigData.introduction
end

local function destroy()

end

local function hide()

end

local function refresh()
    RefreshPartnerInformation()
end

local function varrefresh()
    refresh()
end

local function show(params)
    pet = params
    local p = gameObject.transform.localPosition
    gameObject.transform.localPosition = Vector3(p.x,p.y,-1000)
end

local function update()

end

local function InitUI()
    fields.UIList_PartnerAttribute:Clear()
    uiList_Attributes = {}
    for i,v in ipairs(PetManager.InfoAttr) do
        local item = fields.UIList_PartnerAttribute:AddListItem()
        local labelName = item.Controls["UILabel_PartnerAttributeName"]
        local labelValue = item.Controls["UILabel_PartnerAttribute"]
        local spriteIcon = item.Controls["UISprite_AttributeIcon"]
        labelName.text = StatusText[v.idx].text..':'
        spriteIcon.spriteName = StatusText[v.idx].spritename
        uiList_Attributes[i] = {}
        uiList_Attributes[i].item = item
        uiList_Attributes[i].labelValue = labelValue
    end
end

local function init(params)
    name ,gameObject,fields = unpack(params)
    StatusText = ConfigManager.getConfig("statustext")
    InitUI()
    EventHelper.SetClick(fields.UILabel_DetailKarma,function()
        uimanager.show("partner.dlgpartner_karma",{pet=pet})
    end)
    EventHelper.SetClick(fields.UIButton_Close,function()
        uimanager.hide(name)
    end)
end

return {
    init            = init,
    refresh         = refresh,
    hide            = hide,
    show            = show,
    update          = update,
    destroy         = destroy,
    varrefresh      = varrefresh,
}
