local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local PlayerRole=require"character.playerrole"
local ConfigManager=require"cfg.configmanager"
local BagManager = require"character.bagmanager"
local PetType = cfg.bag.BagType.PET
local PetManager = require"character.pet.petmanager"
local AssistLevel
local gameObject
local name
local fields


local oringinalPos
local oringinalOffsetY

local battlePets
local attainedPets
local currentShowType

local spritenames = {
    [cfg.pet.PetType.GONGJI] = "Sprite_Attack",
    [cfg.pet.PetType.FANGYU] = "Sprite_Defense",
    [cfg.pet.PetType.FUZHU] = "Sprite_Auxiliary",
}
local uiList_Battle
local uiList_Pets
local ItemPetMap

local onHide = nil

local ShowType = enum{
    "ATTACK=1",
    "DEFENCE=2",
    "ASSIST=4",
    "ALL=7",
}

local ShowTypeList = {ShowType.ALL,ShowType.ATTACK,ShowType.DEFENCE,ShowType.ASSIST}

local function GetShowType(pettype)
    return bit.lshift(1,pettype)
end

local function LoadPet(params)
    local idx   = params.idx
    local b     = params.b
    uiList_Battle[idx].labelState.text = LocalString.PartnerText.IsFollowing[b]
end

local function ListAPet(pet,type,idx)
    if bit.band(type,GetShowType(pet.ConfigData.pettype)) >0 then
        local item          = fields.UIList_Partner:GetItemByIndex(idx)
        item.Id=pet.ConfigId
        ItemPetMap[item.m_nIndex] = pet
        local spriteType    = item.Controls["UISprite_Type"]
        local textureIcon   = item.Controls["UITexture_AttainedPartner"]
        local spriteSelect  = item.Controls["UISprite_Select"]
        local labelLevel    = item.Controls["UILabel_LV"]
        local labelName     = item.Controls["UILabel_Name"]
        local labelAwake    = item.Controls["UILabel_Awakening"]
        local buttonInfo    = item.Controls["UISprite_DetailInformation"]
        local labelCombatPower = item.Controls["UILabel_PowerAmount"]
        spriteType.spriteName = spritenames[pet.ConfigData.pettype]
        labelCombatPower.text = pet.PetCombatPower
        PetManager.SetItemPetColor(item,pet.ConfigId)
        textureIcon:SetIconTexture(pet.ConfigData.icon)
        local b = PetManager.IsBattlePet(pet.ConfigId)
        spriteSelect.gameObject:SetActive(b)
        labelLevel.text     = pet.PetLevel
        labelName.text      = pet:GetColorName()
        labelAwake.text     = pet.PetAwakeLevel
        EventHelper.SetClick(buttonInfo,function()
            uimanager.show("partner.dlgpartner_information",pet)
        end)
        idx = idx + 1
    end
    return idx
end

local function RefreshPets(type)
    ItemPetMap = {}
    local cnt = 0
    for idx,pet in ipairs(attainedPets) do
        if bit.band(type,GetShowType(pet.ConfigData.pettype)) >0 then
            cnt = cnt + 1
        end
    end
    fields.UIList_Partner:ResetListCount(cnt)
    local idx = 0
    local totalCombatPower = 0
    for _,pet in ipairs(battlePets) do
        idx = ListAPet(pet,type,idx)
        totalCombatPower = totalCombatPower + pet.PetCombatPower
    end
    for _,pet in ipairs(attainedPets) do
        if not PetManager.IsBattlePet(pet.ConfigId) then
            idx = ListAPet(pet,type,idx)
        end
    end
    fields.UILabel_Power.text = totalCombatPower

    local bagPanel =  fields.UIScrollView_Partner.gameObject:GetComponent("UIPanel")
    bagPanel.transform.localPosition = oringinalPos
    bagPanel:SetClipOffsetY(oringinalOffsetY)
    fields.UIScrollView_Partner.gameObject:SetActive(false)
    fields.UIScrollView_Partner.gameObject:SetActive(true)
end

local function RefreshBattlePets()
    for i=1,3 do
        local pet = battlePets[i]
        if pet then
            uiList_Battle[i].spriteType.spriteName = spritenames[pet.ConfigData.pettype] -- change
            uiList_Battle[i].spriteType.gameObject:SetActive(true)
            uiList_Battle[i].texture:SetIconTexture(pet.ConfigData.icon)
            uiList_Battle[i].labelName.text = pet:GetColorName()
            uiList_Battle[i].spriteFollow.gameObject:SetActive(true)
            uiList_Battle[i].labelState.text = LocalString.PartnerText.IsFollowing[PetManager.IsFollowingPet(i)]-- and 0 or 1]
            PetManager.SetItemPetColor(uiList_Battle[i].item,pet.ConfigId)
            EventHelper.SetClick(uiList_Battle[i].spriteFollow,function()
                if PetManager.IsFollowing(pet) then
                    if PetManager.CanActiveOrUnActive() then
                        PetManager.RequestUnActive(pet.ConfigId)
                    else
                        uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.PartnerText.EquipCD})
                    end
                elseif PetManager.IsBattlePet(pet.ConfigId) then
                    if PetManager.CanActiveOrUnActive() then
                        PetManager.RequestActive(pet.ConfigId)
                    else
                        uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.PartnerText.EquipCD})
                    end
                else
                    uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.PartnerText.NotEquipPet})
                end
                --PetManager.RequestFollow(i)
            end)
            EventHelper.SetClick(uiList_Battle[i].spriteBox,function()
                PetManager.RequestUnLoad(i)
            end)
            uiList_Battle[i].spriteAdd.gameObject:SetActive(false)
        else
            PetManager.SetItemPetColor(uiList_Battle[i].item)
            uiList_Battle[i].spriteType.gameObject:SetActive(false)
            uiList_Battle[i].texture:SetIconTexture("null")
            uiList_Battle[i].labelName.text = ""
            uiList_Battle[i].spriteFollow.gameObject:SetActive(false)
            uiList_Battle[i].spriteAdd.gameObject:SetActive(true)
            EventHelper.SetClick(uiList_Battle[i].spriteBox,function()
                uimanager.hide(name)
                uimanager.showdialog("lottery.dlglottery",nil,1)
            end)
        end
    end
end

local function refresh(params)
    battlePets      = PetManager.GetBattlePets()
    attainedPets    = PetManager.GetSortedAttainedPets()
    RefreshBattlePets()
    RefreshPets(CurrentShowType)
end

local function varrefresh()
    refresh()
end

local function destroy()
  --print(name, "destroy")
end

local function show(params)
    local CfgConfig = ConfigManager.getConfig("petconfig")
    CurrentShowType = ShowType.ALL
    local pos = gameObject.transform.localPosition
    gameObject.transform.localPosition = Vector3(pos.x,pos.y,-3000)
    if params and params.onHide then
        onHide = params.onHide
    else
        onHide = nil
    end
    for i=1,3 do
        if PlayerRole.Instance().m_Level < CfgConfig.petslotopenlevel[i] then
            uiList_Battle[i].spriteLock.gameObject:SetActive(true)
            uiList_Battle[i].spriteAdd.gameObject:SetActive(false)
            uiList_Battle[i].labelOpenLevel.text = tostring(CfgConfig.petslotopenlevel[i]) .. LocalString.PartnerText.LevelOpen
        else
            uiList_Battle[i].spriteLock.gameObject:SetActive(false)
            uiList_Battle[i].spriteAdd.gameObject:SetActive(true)
        end
    end
end

local function hide()
    if onHide then
        onHide()
    end
end

local function update()

end

local function init(params)
  name, gameObject, fields = unpack(params)

    oringinalPos = fields.UIScrollView_Partner.gameObject.transform.localPosition
    oringinalOffsetY =  fields.UIScrollView_Partner.gameObject:GetComponent("UIPanel"):GetClipOffsetY()

  uiList_Battle = {}
  for i=1,3 do
      uiList_Battle[i] = {}
      local item                    = fields.UIList_Assist:AddListItem()
      local spriteType              = item.Controls["UISprite_PartnerType"]
      local texture                 = item.Controls["UITexture_BattlePartner"]
      local labelName               = item.Controls["UILabel_PartnerName"]
      local labelState              = item.Controls["UILabel_Follow"]
      local spriteFollow            = item.Controls["UISprite_Follow"]
      local spriteBox               = item.Controls["UISprite_PartnerBox"]
      local spriteLock              = item.Controls["UISprite_Lock"]
      local labelOpenLevel          = item.Controls["UILabel_OpenLevel"]
      local spriteAdd               = item.Controls["UISprite_Add"]
      uiList_Battle[i].item         = item
      uiList_Battle[i].spriteType   = spriteType
      uiList_Battle[i].texture      = texture
      uiList_Battle[i].labelName    = labelName
      uiList_Battle[i].labelState   = labelState
      uiList_Battle[i].spriteFollow = spriteFollow
      uiList_Battle[i].spriteBox    = spriteBox
      uiList_Battle[i].spriteLock   = spriteLock
      uiList_Battle[i].labelOpenLevel = labelOpenLevel
      uiList_Battle[i].spriteAdd    = spriteAdd
  end

  EventHelper.SetListClick(fields.UIList_ShowTypes,function(item)
      local newType = ShowTypeList[item.m_nIndex+1]
      if newType~=CurrentShowType then
          CurrentShowType = newType
          RefreshPets(newType)
      end
  end)

  EventHelper.SetListClick(fields.UIList_Partner,function(item)
      local selectedPet = ItemPetMap[item.m_nIndex]
      if selectedPet then
          if not PetManager.IsBattlePet(selectedPet.ConfigId) then
              if PetManager.CanLoad() then
				print("PetManager.CanLoad() -------------------------")
                  PetManager.RequestLoad(selectedPet.ConfigId)
              else
                  uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.PartnerText.FullBattle})
              end
          end
      end
  end)

  EventHelper.SetClick(fields.UIButton_Sure,function()
      uimanager.hide(name)
  end)
  EventHelper.SetClick(fields.UIButton_Close,function()
      uimanager.hide(name)
  end)
end

local function uishowtype()
    return UIShowType.Refresh
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
  LoadPet = LoadPet,
  RefreshScrollPos = RefreshScrollPos,
}
