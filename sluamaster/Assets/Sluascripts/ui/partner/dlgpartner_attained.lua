local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local PlayerRole=require"character.playerrole"
local ConfigManager=require"cfg.configmanager"
local PetManager = require"character.pet.petmanager"
local mathutils = require"common.mathutils"
local ItemManager = require"item.itemmanager"
local gameObject
local name
local fields

local oringinalPos
local oringinalOffsetY

local uigrid1
local uigrid2

local attainedPets
local unattainedPets
local ItemPetMap
local delayTime
local CurrentShowType
local petsList
local showPetsList
local pairPetsData
local newPetEffect
local battlePets
local ShowType = enum{
    "ATTACK=1",
    "DEFENCE=2",
    "ASSIST=4",
    "ALL=7",
}

local PetTypeIcons = {
    [cfg.pet.PetType.GONGJI] = "Sprite_Attack",
    [cfg.pet.PetType.FANGYU] = "Sprite_Defense",
    [cfg.pet.PetType.FUZHU] = "Sprite_Auxiliary",
}

local function GetShowType(pettype)
    return bit.lshift(1,pettype)
end

local function InsertToPetsList(tb,pet,type)
    if bit.band(type,GetShowType(pet.ConfigData.pettype)) >0 then
        table.insert(tb,pet)
    end
end

local function GetPetsList(aPets,bPets,type)
    local ret = {}
    for _,pet in ipairs(bPets) do
        InsertToPetsList(ret,pet,type)
    end
    for _,pet in ipairs(aPets) do
        if not PetManager.IsBattlePet(pet.ConfigId) then
            InsertToPetsList(ret,pet,type)
        end
    end
    return ret
end

local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")
local ShowTypeList = {ShowType.ALL,ShowType.ATTACK,ShowType.DEFENCE,ShowType.ASSIST}

local function hide()

end


local function ShowAPet(item,pet)
    if not pet then 
		item.gameObject.transform.localScale = Vector3.zero return
    else 
		item.gameObject.transform.localScale = Vector3.one
    end
	printyellow(pet.ConfigData.fragmentid)
    -- local item          = fields.UIList_Partner01:AddListItem()
    -- ItemPetMap[item.m_nIndex] = pet
    local labelLevel    = item.Controls["UILabel_LV"]
    local textureIcon   = item.Controls["UITexture_Partner01"]
    local labelName     = item.Controls["UILabel_Name"]
    local labelAwake    = item.Controls["UILabel_Awakening"]
    -- local listAwake     = item.Controls["UIList_StageStar"]
    local spriteType    = item.Controls["UISprite_Type"]
    local labelAwakePrograss = item.Controls["UILabel_ProgressValue"]
    local progressAwake = item.Controls["UIProgressBar_Fragment"]
    local labelCombatPower = item.Controls["UILabel_PowerAmount"]
    local buttonAdd     = item.Controls["UIButton_Add"]
    local spriteTip     = item.Controls["UISprite_Tips"]
    item.Id=pet.ConfigId
    textureIcon:SetIconTexture(pet.ConfigData.icon)
    labelCombatPower.text = pet.PetCombatPower
    labelLevel.text     = pet.PetLevel
    labelName.text      = pet:GetColorName()
    labelAwake.text     = pet.PetAwakeLevel
    spriteType.spriteName = PetTypeIcons[pet.ConfigData.pettype]
    local requireAwakeFragments = PetManager.GetFragmentRequirementAwake(pet)
    local ownedAwakeFragments = PetManager.GetFragmentNumByPet(pet)
    labelAwakePrograss.text = tostring(ownedAwakeFragments) .. '/' .. tostring(requireAwakeFragments)
    if requireAwakeFragments == 0 then
        progressAwake.value = 1
    else
        progressAwake.value = ownedAwakeFragments / requireAwakeFragments
    end
    PetManager.SetItemPetColor(item,pet.ConfigId)
    spriteTip.gameObject:SetActive(PetManager.CanUpgrade(pet))
    --[[策划需求没上阵得伙伴不止单纯觉醒显示红点
    if PetManager.IsBattlePet(pet.ConfigId) then
        spriteTip.gameObject:SetActive(PetManager.CanUpgrade(pet))
    else
        spriteTip.gameObject:SetActive(PetManager.CanUpgradeAwake(pet))
    end
    --]]

    local stars = PetManager.GetStar(pet.PetStageStar)
    for i=1,10 do
        -- local starItem = listAwake:GetItemByIndex(i-1)
        -- local spriteStar = starItem.Controls["UISprite_Star"]
        -- spriteStar.gameObject:SetActive(stars>=i)
        -- fields["UISprite_Star"..tostring(i)].gameObject:SetActive(stars>=i)
        item.Controls["UISprite_Star"..tostring(i)].gameObject:SetActive(stars>=i)
    end
    if pet.NewPet then
        local particle = item.Controls["ParticleSystem_NewPetEffect"]
        particle.gameObject:SetActive(true)
        uimanager.PlayUIParticleSystem(particle.gameObject)
        pet.NewPet = false
    end
    EventHelper.SetClick(buttonAdd,function()
		
        ItemManager.GetSource(pet.ConfigData.fragmentid,name)
    end)

    EventHelper.SetClick(item,function()
        -- printyellow"on item"
        uimanager.showdialog("partner.dlgpartner",pet) --չʾ����������UI
    end)
end

local function PetItemInit(go,index,realIndex)
   
    local item = go:GetComponent("UIListItem")
	
    ShowAPet(item,petsList[realIndex+1]) --���û��������Ĵ��� 
end

local function ResetPetList()
    --local wrapContent = fields.UIList_Partner01.gameObject:GetComponent("UIGridWrapContent")
    --wrapContent.minIndex = -((#petsList)/2)
    --wrapContent.maxIndex = 0
    --EventHelper.SetWrapContentItemInit(wrapContent,PetItemInit)

    local wrapContent = fields.UIList_Partner01.gameObject:GetComponent("UIGridWrapContent")
    -- printyellow("#petsList",#petsList)
    wrapContent.minIndex = -(mathutils.Round((#petsList)/2))
    wrapContent.maxIndex = 0
    EventHelper.SetWrapContentItemInit(wrapContent,PetItemInit)

    fields.UIScrollView_Partner.currentMomentum = Vector3(0,0,0)
    local content = fields.UIList_Partner01.gameObject:GetComponent("UIGridWrapContent")
    --bagWrapContent:ResetChildPositions()
    content:ResetAllChildPositions()
    local bagPanel =  fields.UIScrollView_Partner.gameObject:GetComponent("UIPanel")
    bagPanel.transform.localPosition = oringinalPos
    bagPanel:SetClipOffsetY(oringinalOffsetY)
    content.firstTime = true
    content:WrapContent()
    fields.UIScrollView_Partner.gameObject:SetActive(false)
    fields.UIScrollView_Partner.gameObject:SetActive(true)
end

local function InitPetList()
    if fields.UIList_Partner01.Count == 0 then
        for i = 1,14 do
            local item = fields.UIList_Partner01:AddListItem()
        end
        local wrapContent = fields.UIList_Partner01.gameObject:GetComponent("UIGridWrapContent")
        wrapContent.minIndex = 1
        wrapContent.maxIndex = 0
	
        EventHelper.SetWrapContentItemInit(wrapContent,PetItemInit)
		
    end
end

--local function RefreshPetInfo()
--    local wrapContent = fields.UIList_Partner01.gameObject:GetComponent("UIGridWrapContent")
--    wrapContent.firstTime = true
--    wrapContent:WrapContent()
--
--	--EventHelper.SetWrapContentItemInit(wrapContent,PetItemInit)
--
--end

local function refresh()

   	attainedPets            = PetManager.GetSortedAttainedPets()
    battlePets              = PetManager.GetBattlePets()
    petsList                = GetPetsList(attainedPets,battlePets,CurrentShowType) --��ȡ�������б�
    ResetPetList()
    --RefreshPetInfo()
end

local function show()
    CurrentShowType = ShowType.ALL
    petsList = {}
    battlePets = {}
    attainedPets = {}
    InitPetList()

end

local function destroy()
    fields = nil
end

local function update()

end



local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    name,gameObject,fields = unpack(params)

    oringinalPos = fields.UIScrollView_Partner.gameObject.transform.localPosition
    oringinalOffsetY =  fields.UIScrollView_Partner.gameObject:GetComponent("UIPanel"):GetClipOffsetY()

    EventHelper.SetListClick(fields.UIList_ShowTypes,function(item)
        -- local idx = item.m_nIndex
        local newType = ShowTypeList[item.m_nIndex+1]
        if newType ~= CurrentShowType then
            CurrentShowType = newType
            refresh()
        end
    end)

    EventHelper.SetClick(fields.UIButton_SkinShop,function()
        uimanager.showdialog("dlgfashion",{pet=pet,fashiontype="pet"})
    end)

    EventHelper.SetClick(fields.UIButton_PartnerEmbattle,function()
        uimanager.show("partner.dlgpartner_assist")
    end)

end

local function RefreshScrollPos(value)
    fields.UIScrollView_Partner:MoveRelative(Vector3(0,value,0))
    fields.UIScrollView_Partner:UpdatePosition()
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    varrefresh = varrefresh,
    uishowtype = uishowtype,
    RefreshScrollPos = RefreshScrollPos,
}
