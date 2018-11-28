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

local uigrid1
local uigrid2

local attainedPets
local unattainedPets
local ItemPetMap
local delayTime
local currentShowType

local newPetEffect
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

local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")
local ShowTypeList = {ShowType.ALL,ShowType.ATTACK,ShowType.DEFENCE,ShowType.ASSIST}

local function GetShowType(pettype)
    return bit.lshift(1,pettype)
end

--新手指引用
local function RefreshScrollPos(value)
    fields.UIScrollView_Partner:MoveRelative(Vector3(0,value,0))
    fields.UIScrollView_Partner:UpdatePosition()
end

local function destroy()

end

local function hide()

end

local function update()
    if delayTime then
        delayTime = delayTime - 1
        if delayTime == 0 then
            tbPartner.repositionNow = true
            delayTime = nil
        end
    end
end

local function ShowAPet(type,pet)
    status.BeginSample("ShowAPet")
    if bit.band(type,GetShowType(pet.ConfigData.pettype)) > 0 then
        local item          = fields.UIList_Partner01:AddListItem()
        ItemPetMap[item.m_nIndex] = pet
        local labelLevel    = item.Controls["UILabel_LV"]
        local textureIcon   = item.Controls["UITexture_Partner01"]
        local labelName     = item.Controls["UILabel_Name"]
        local labelAwake    = item.Controls["UILabel_Awakening"]
        local listAwake     = item.Controls["UIList_StageStar"]
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
        if PetManager.IsBattlePet(pet.ConfigId) then
            spriteTip.gameObject:SetActive(PetManager.CanUpgrade(pet))
        else
            spriteTip.gameObject:SetActive(PetManager.CanUpgradeAwake(pet))
        end

        local stars = PetManager.GetStar(pet.PetStageStar)
       -- for i=1,10 do
          --  local starItem = listAwake:GetItemByIndex(i-1)
         --   local spriteStar = starItem.Controls["UISprite_Star"]
           -- spriteStar.gameObject:SetActive(stars>=i)
      --  end
        if pet.NewPet then
            local particle = item.Controls["ParticleSystem_NewPetEffect"]
            particle.gameObject:SetActive(true)
            uimanager.PlayUIParticleSystem(particle.gameObject)
            pet.NewPet = false
        end
        EventHelper.SetClick(buttonAdd,function()
            ItemManager.GetSource(pet.ConfigData.fragmentid,name)
        end)
    end
    status.EndSample()
end

local function refresh()
    attainedPets    = PetManager.GetSortedAttainedPets()
    unattainedPets  = PetManager.GetSortedUnAttainedPets()
    battlePets      = PetManager.GetBattlePets()
    fields.UIList_Partner01:Clear()
    fields.UIList_Partner02:Clear()
    for idx,pet in ipairs(battlePets) do
        ShowAPet(CurrentShowType,pet)
    end
    for idx,pet in ipairs(attainedPets) do
        if not PetManager.IsBattlePet(pet.ConfigId) then
            ShowAPet(CurrentShowType,pet)
        end
    end
    for idx,pet in ipairs(unattainedPets) do
        if bit.band(CurrentShowType,GetShowType(pet.ConfigData.pettype)) > 0 then
            -- local item = fields.UIList_Partner02:AddListItem()
            local item          = fields.UIList_Partner02:AddListItem()
            local textureIcon   = item.Controls["UITexture_Partner02"]
            local labelName     = item.Controls["UILabel_Name"]
            local spriteType    = item.Controls["UISprite_Type"]
            local sliderAmount  = item.Controls["UISlider_Amount"]
            local labelAmount   = item.Controls["UILabel_CanCall"]
            local btnAdd        = item.Controls["UIButton_Add"]
            local spriteTip     = item.Controls["UISprite_Tips2"]
            spriteTip.gameObject:SetActive(PetManager.CanCall(pet))
            spriteType.spriteName = PetTypeIcons[pet.ConfigData.pettype]
            PetManager.SetItemPetColor(item,pet.ConfigId)
            textureIcon:SetIconTexture(pet.ConfigData.icon)
            labelName.text      = pet:GetColorName()
            local fragmentid    = pet.ConfigData.fragmentid
            -- printyellow("fragmentid",fragmentid,pet.ConfigData.name)
            local CfgFragment   = ConfigManager.getConfigData("petfragment",fragmentid)
            local total         = CfgFragment.number
            local amount        = PetManager.GetFragmentNum(fragmentid)
            if amount >=total then
                sliderAmount.value = 1
                labelAmount.text = LocalString.PartnerText.CanCall
            else
                sliderAmount.value = amount/total
                labelAmount.text = tostring(amount) .. '/' .. tostring(total)
            end
            if amount >= total then
                EventHelper.SetClick(btnAdd,function()
                    PetManager.RequestCallPet(item.m_nIndex+1)
                end)
            else
                EventHelper.SetClick(btnAdd,function()
                    ItemManager.GetSource(pet.ConfigData.fragmentid,name)
                end)
            end
        end
    end
    uigrid1.repositionNow = true
    uigrid1.enabled = true
end

local function varrefresh()
    refresh()
end

local function show(params)
    CurrentShowType = ShowType.ALL
end

local function uishowtype()
    return UIShowType.Refresh
end


local function init(params)
    name, gameObject, fields = unpack(params)
    ItemPetMap = {}
    uigrid1 = LuaHelper.GetComponent(fields.UIList_Partner01.gameObject,"UIGrid")
    uigrid2 = LuaHelper.GetComponent(fields.UIList_Partner02.gameObject,"UIGrid")
    tbPartner = LuaHelper.GetComponent(fields.UIList_Partner01.gameObject.transform.parent.gameObject,"UITable")
    uigrid1.onReposition = function()
        tbPartner.repositionNow = true
    end


    delayTime = nil
    EventHelper.SetListClick(fields.UIList_Partner01,function(item)
        uimanager.showdialog("partner.dlgpartner",ItemPetMap[item.m_nIndex])
    end)

    EventHelper.SetClick(fields.UIButton_PartnerEmbattle,function(item)
        uimanager.show("partner.dlgpartner_assist")
    end)

    EventHelper.SetClick(fields.UIButton_SkinShop ,function(item)
        uimanager.showdialog("dlgfashion",{pet=pet,fashiontype="pet"})
    end)

    EventHelper.SetListClick(fields.UIList_ShowTypes,function(item)
        local newType = ShowTypeList[item.m_nIndex + 1]
        if newType~=CurrentShowType then
            CurrentShowType = newType
            -- printyellow("CurrentShowType",CurrentShowType)
            refresh()
        end
    end)
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
