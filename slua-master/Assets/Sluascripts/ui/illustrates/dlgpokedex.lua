local print,printt,unpack       = print,printt,unpack
local ConfigManager             = require"cfg.configmanager"
local PetManager                = require"character.pet.petmanager"
local Pet                       = require"character.pet.pet"
local EventHelper               = UIEventListenerHelper
local inactiveShader            = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader              = UnityEngine.Shader.Find("Unlit/Transparent Colored")
local uimanager                 = require"uimanager"
local dess
local name,gameObject,fields
local pets
local pet
local selectedIndex
local currQuality
local model
local isshow
local wrapContent

local PetQuality = {
    [3] = cfg.item.EItemColor.PURPLE,
    [2] = cfg.item.EItemColor.ORANGE,
    [1] = cfg.item.EItemColor.RED,
}

local PetQualityTexture = {
    [cfg.item.EItemColor.PURPLE]    = "Texture_Excellent",
    [cfg.item.EItemColor.ORANGE]    = "Texture_Perfect",
    [cfg.item.EItemColor.RED]       = "Texture_Peerless",
}

local function destroy()

end

local function hide()

end

local function GetPetIndex(modelid)
    printyellow("modelid",modelid)
    for idx,apet in ipairs(pets) do
        printyellow("configid",apet.ConfigId)
        if apet.ConfigId == modelid then return idx end
    end
end

local function RefreshRedDot(rPet)
    if rPet then
        printyellow("pet name",rPet.ConfigData.name)
    end
    fields.UISprite_StarReddot.gameObject:SetActive(PetManager.CanStarAward(pet))
    fields.UISprite_AwakeReddot.gameObject:SetActive(PetManager.CanAwakeAward(pet))
    if rPet then
        local ridx = GetPetIndex(rPet.ConfigId)
        if ridx then
            local idx = wrapContent:RealIndex2Index(ridx)
            local item = fields.UIList_Bag:GetItemByIndex(idx-1)
            printyellow("ridx",ridx,"idx",idx,rPet.ConfigData.name)
            item.Controls["UISprite_StarReddot"].gameObject:SetActive(PetManager.CanAward(rPet))
        end
    end
end

local function OnModelLoaded(obj)
    if not model or not model.m_Object then return end
    local parentTransform           = fields.UITexture_Player.gameObject.transform
    local playerTransform           = model.m_Object.transform
    playerTransform.parent          = parentTransform
    model:SetUIScale(200)
    playerTransform.localPosition   = Vector3(0,-200,-1500)
    playerTransform.localEulerAngles   = Vector3(-90,180,0)
    ExtendedGameObject.SetLayerRecursively(model.m_Object,define.Layer.LayerUICharacter)
end

local function RefreshModel(pet)
    if model and model.m_Object then
        model:release()
    end
    model = Pet:new(0,pet.ConfigId,nil,true)
    model.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    model:RegisterOnLoaded(OnModelLoaded)
    model:init(pet.PetSkin)
end

local function RefreshInformations()
    fields.UILabel_PartnerName.text = pet.ConfigData.name
    for i=1,5 do
        local item = fields.UIList_ScrollAttr:GetItemByIndex(i-1)
        local sliderAttribute = item.Controls["UISlider_SlideBackground"]
        local labelNumber = item.Controls["UILabel_Number"]
        sliderAttribute.value = pet.ConfigData.featurelist[i] / 100
        labelNumber.text = tostring(pet.ConfigData.featurelist[i])
    end
    fields.UILabel_Feature.text = dess[pet.ConfigId].shortdescribe
end

local function OnSelectPet(currPet)
    if pet and pet.ConfigId == currPet.ConfigId then return end
    pet = currPet
    RefreshInformations(pet)
    RefreshModel(pet)
    RefreshRedDot()
end

local function ShowAPet(item,currPet,ridx)
    if not currPet then item.gameObject.transform.localScale = Vector3.zero return
    else item.gameObject.transform.localScale = Vector3.one end
    PetManager.SetItemPetColor(item,currPet.ConfigId)
    local textureIcon = item.Controls["UITexture_Icon"]
    item.Controls["UISprite_StarReddot"].gameObject:SetActive(PetManager.CanAward(currPet))
    textureIcon:SetIconTexture(currPet.ConfigData.icon)
    textureIcon.shader = PetManager.IsAttainedPets(currPet.ConfigId) and activeShader or inactiveShader
    EventHelper.SetClick(item,function()
        selectedIndex = ridx
        OnSelectPet(currPet)
    end)
end

local function PetItemInit(go,idx,ridx)
    local item = go:GetComponent("UIListItem")
    ShowAPet(item,pets[ridx+1],ridx)
end

local function InitPetList()
    if fields.UIList_Bag.Count == 0 then
        fields.UIList_Bag:ResetListCount(18)
        wrapContent       = fields.UIList_Bag.gameObject:GetComponent("UIGridWrapContent")
        wrapContent.minIndex    = 1
        wrapContent.maxIndex    = 0
        EventHelper.SetWrapContentItemInit(wrapContent,PetItemInit)
    else
        -- local wrapContent       = fields.UIList_Bag.gameObject:GetComponent("UIGridWrapContent")
        wrapContent.firstTime   = true
        wrapContent:WrapContent()
    end
end

local function refresh(params)
    if isshow then isshow = false return end
    InitPetList()
end

local function OnSelectGroup(idx)
    if currQuality ~= PetQuality[idx] then
        currQuality = PetQuality[idx]
        pets = PetManager.GetQualityPets(currQuality)
        selectedIndex = 1
        OnSelectPet(pets[selectedIndex])
        refresh()
        local attCnt,unattCnt = PetManager.GetQualityPetsCount(currQuality)
        fields.UILabel_BagItemAmount.text = string.format("%d/%d",attCnt,unattCnt)
        fields.UITexture_Quality:SetIconTexture(PetQualityTexture[currQuality])
        fields.UIScrollView_Bag:ResetPosition()
    end
end

local function show(param)
    dess = ConfigManager.getConfig"petdescribe"
    OnSelectGroup(3)
end

local function update()
    if model and model.m_Object then
        model.m_Avatar:Update()
    end
end

local function init(params)
    name,gameObject,fields = unpack(params)
    currQuality = nil
    pet = nil

    EventHelper.SetListClick(fields.UIList_BagRadioButton,function(item)
        local idx = item.m_nIndex + 1
        OnSelectGroup(idx)
    end)

    EventHelper.SetDrag(fields.UITexture_Player,function(o,delta)
        if model and model.m_Object then
            local vec = Vector3(0,-delta.x,0)
            local modelTransform = model.m_Object.transform
            modelTransform.localEulerAngles = modelTransform.localEulerAngles + vec
        end
    end)

    EventHelper.SetClick(fields.UIButton_PartnerFillUp,function()
        uimanager.show("illustrates.dlgpokedex_illustrate",pet)
    end)

    EventHelper.SetClick(fields.UIButton_PartnerDecomposition,function()
        if PetManager.IsAttainedPets(pet.ConfigId) then
            uimanager.show("illustrates.dlgpokedex_award",{pet=pet,type="STAGESTAR"})
        else
            uimanager.ShowSingleAlertDlg{content=LocalString.PartnerText.UnattainedPet}
        end
    end)

    EventHelper.SetClick(fields.UIButton_PartnerFashionBox,function()
        if PetManager.IsAttainedPets(pet.ConfigId) then
            uimanager.show("illustrates.dlgpokedex_award",{pet=pet,type="AWAKE"})
        else
            uimanager.ShowSingleAlertDlg{content=LocalString.PartnerText.UnattainedPet}
        end
    end)
end

return {
    destroy             = destroy,
    hide                = hide,
    refresh             = refresh,
    show                = show,
    update              = update,
    init                = init,
    RefreshRedDot       = RefreshRedDot,
}
