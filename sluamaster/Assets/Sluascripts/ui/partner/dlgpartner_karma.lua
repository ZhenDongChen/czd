local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local login = require("login")
local BagManager = require"character.bagmanager"
local ConfigManager = require"cfg.configmanager"
local mathutils = require"common.mathutils"
local CfgPetBasicStatus
local parent
local PetManager = require"character.pet.petmanager"

local gameObject
local name
local pet
local fields
local StatusText

local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")

local function destroy()

end

local function hide()

end

local function update()

end

local function ShowAnItem(karma)
    local item = fields.UIList_PartnerItemShow:AddListItem()
    local labelName = item.Controls["UILabel_ItemTitle"]
    local labelAttr = item.Controls["UILabel_ItemTitle2"]
    local labelLevel = item.Controls["UILabel_PartnerLevel"]
    local labelNextLevel = item.Controls["UILabel_NextLevel"]
    local listPartner = item.Controls["UIList_Partner"]
    local labelFullAttr = item.Controls["UILabel_ItemTitle3"]
    local spriteNotActive = item.Controls["UISprite_NotActive"]
    labelLevel.text = tostring(karma.karmalevel) .. '/' .. tostring(#karma.karma.prop) .. LocalString.PartnerText.Level
    labelName.text = karma.karma.karmaname
    local attrText = ""
    if karma.karmalevel>0 then
        local attrText = ""
        for _,karmadata in pairs(karma.karma.prop_level[karma.level].karmadata) do
            attrText = attrText .. ' ' .. StatusText[karmadata.propertytype].text .. ' '
            local sign = karmadata.value >= 0 and '+' or '-'
            attrText = attrText .. sign
            attrText = attrText .. mathutils.GetAttr(karmadata.value,StatusText[karmadata.propertytype].displaytype)
        end
        labelAttr.text = attrText
    else
        labelAttr.text = ""
    end

    local fullKarmaProp = karma.karma.prop[#karma.karma.prop].karmadata
    local attrFullProp = LocalString.PartnerText.FullLevel
    for _,propertydata in pairs(fullKarmaProp) do
        attrFullProp = attrFullProp .. ' ' ..  StatusText[propertydata.propertytype].text .. ' '
        local sign = propertydata.value >=0 and '+' or '-'
        attrFullProp = attrFullProp .. sign
        attrFullProp = attrFullProp .. mathutils.GetAttr(propertydata.value,StatusText[propertydata.propertytype].displaytype)
    end
    labelFullAttr.text = attrFullProp

    local ret = PetManager.GetNextKarmaLevel(karma.karma,karma.level)
    if ret then
        if ret > 0 then
            local p1
            local text
            if karma.karma.carmatype == cfg.pet.StarKarmaType.XINGJIE then
                p1 = LocalString.PartnerText.StageStar
                text = string.format(LocalString.PartnerText.StarKarmaNextLevel,p1,tostring(math.floor(ret/10)))
            elseif karma.karma.carmatype == cfg.pet.StarKarmaType.JUEXING then
                p1 = LocalString.PartnerText.Awaken
                text = string.format(LocalString.PartnerText.StarKarmaNextLevel,p1,tostring(math.floor(ret)))
            end
            labelNextLevel.text = text
        else
            labelNextLevel.text = LocalString.PartnerText.GetAllPartner
        end
    else
        labelNextLevel.text = LocalString.PartnerText.MaxKarmaLevel
    end
    local bActive = false
    for i=1,4 do
        local petkey = karma.karma.petkeys[i]
        local petItem = listPartner:GetItemByIndex(i-1)
        local textureIcon = petItem.Controls["UITexture_Icon"]
        local labelPetName = petItem.Controls["UILabel_PartnerName"]
        if petkey then
            PetManager.SetItemPetColor(petItem,petkey)
            petItem.gameObject:SetActive(true)
            if PetManager.IsAttainedPets(petkey) then
                textureIcon.shader = activeShader
            else
                textureIcon.shader = inactiveShader
                bActive = true
            end
            labelPetName.text = CfgPetBasicStatus[petkey].name
            textureIcon:SetIconTexture(CfgPetBasicStatus[petkey].icon)
        else
            petItem.gameObject:SetActive(false)
            labelPetName.text = ""
            textureIcon:SetIconTexture("null")
        end
    end
    spriteNotActive.gameObject:SetActive(bActive)
end

local function refresh(params)
    local karmas = PetManager.GetKarmas(pet)
    for _,karma in pairs(karmas) do
        ShowAnItem(karma)
    end
end

local function varrefresh()
    refresh()
end

local function show(params)
    -- fields.UIGroup_PartnerShow.gameObject:SetActive(true)
    pet = params.pet
    fields.UILabel_Title.text = LocalString.PartnerText.PetKarma
end

local function init(params)
    name,gameObject,fields=unpack(params)
    StatusText = ConfigManager.getConfig("statustext")
    CfgPetBasicStatus = ConfigManager.getConfig("petbasicstatus")

    EventHelper.SetClick(fields.UIButton_Close,function()
        uimanager.hide(name)
    end)
end

return {
    init                    = init,
    show                    = show,
    refresh                 = refresh,
    update                  = update,
    hide                    = hide,
    destroy                 = destroy,
    varrefresh              = varrefresh,
}
