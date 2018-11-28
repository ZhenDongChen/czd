local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local PlayerRole=require"character.playerrole"
local ConfigManager=require"cfg.configmanager"
local EctypeManager = require"ectype.ectypemanager"
local PetManager = require"character.pet.petmanager"
local gameObject
local name
local fields
local Alternate
local BattlePets
local uilistPets = {}
local fieldPets = nil
local uigrid
local refreshNextFrame
local equipCD
local cfgEquipCD
local cfgDeadCD

local function destroy()
  --print(name, "destroy")
end


local function show(params)
end

local function hide()
  --print(name, "hide")
end
--
--
-- local function ReviveUI(idx)
--     uilistPets[idx].spriteState.spriteName = LocalString.PartnerText.EQUIPED
--     uilistPets[idx].hpBar.value = 1
-- end
--
-- local function ActiveUI(idx)
--     uilistPets[idx].spriteState.spriteName = LocalString.PartnerText.ACTIVE
-- end
--
-- local function UnActiveUI(idx)
--     uilistPets[idx].spriteState.spriteName = LocalString.PartnerText.EQUIPED
-- end
--
-- local function DeadUI(idx)
--     uilistPets[idx].spriteState.spriteName = LocalString.PartnerText.DEAD
-- end
--
-- local function UnActive(modelid)
--     if not EctypeManager.IsInEctype() and PlayerRole.Instance().PetManager:CanUnActive() then
--         PetManager.RequestUnActive(modelid)
--     end
-- end
--
-- local function Active(modelid)
--     if not EctypeManager.IsInEctype() and PlayerRole.Instance().PetManager:CanActive(id) then
--         PetManager.RequestActive(modelid)
--     end
-- end

local function OnAttrChange(pet)
    local idx = PetManager.GetBattlePetIndex(pet.m_CsvId)
    if uilistPets[idx] then
        uilistPets[idx].hpBar.value = pet.m_Attributes[cfg.fight.AttrId.HP_VALUE]/pet.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
    end
end

local function RefreshLevel(param)
    local level = param.level
    local index = param.idx
    uilistPets[index].labelLV.text = tostring(level)
end

local function UpdateFieldPets()
    fieldPets = PetManager.GetFieldPets()
    if not fieldPets then refreshNextFrame = true return end
    for i=1,3 do
        if fieldPets[i] then
            local currState = fieldPets[i].state
            if currState == PetManager.PetState.DEAD then
                uilistPets[i].spriteState.spriteName = LocalString.PartnerText.DEAD
            elseif currState == PetManager.PetState.ACTIVE then
                uilistPets[i].spriteState.spriteName = LocalString.PartnerText.ACTIVE
            elseif currState == PetManager.PetState.EQUIPED then
                uilistPets[i].spriteState.spriteName = LocalString.PartnerText.EQUIPED
            elseif currState == PetManager.PetState.NOPARTNER then
                uilistPets[i].item.gameObject:SetActive(false)
            end
            if currState~= PetManager.PetState.NOPARTNER then
                local pet = fieldPets[i].pet
                uilistPets[i].item.gameObject:SetActive(true)
                uilistPets[i].textureIcon:SetIconTexture(pet.ConfigData.icon)
                uilistPets[i].labelName.text = pet.ConfigData.name
                uilistPets[i].btn.gameObject:SetActive(not EctypeManager.IsInStory())
                uilistPets[i].labelLV.text = tostring(pet.PetLevel)
                EventHelper.SetClick(uilistPets[i].btn,function()
                    local state = PetManager.GetPetState(i)
                    if state == PetManager.PetState.DEAD then

                    elseif state == PetManager.PetState.ACTIVE then
                        PetManager.RequestUnActive(pet.ConfigId)
                    elseif state == PetManager.PetState.EQUIPED then
                        PetManager.RequestActive(pet.ConfigId)
                    end
                end)
            end
        end
    end
    uigrid.enabled = true
end

local function update()
    if refreshNextFrame then
        refreshNextFrame = false
        UpdateFieldPets()
    end
    if fieldPets then
        for i=1,3 do
            if fieldPets[i] then
                if fieldPets[i].state == PetManager.PetState.DEAD then
                    uilistPets[i].sliderCD.value = (PetManager.GetDeadCD(fieldPets[i].pet.ConfigId) or 0)/cfgDeadCD
                elseif fieldPets[i].state == PetManager.PetState.ACTIVE or
                    fieldPets[i].state == PetManager.PetState.EQUIPED then
                    uilistPets[i].sliderCD.value = (equipCD or 0)/cfgEquipCD
                end
            end
        end
    end
    if equipCD then
        equipCD = equipCD - Time.deltaTime
        if equipCD<0 then
            equipCD = nil
        end
    end
end

local function refresh(params)
    UpdateFieldPets()
end

local function EquipCD(cd)
    equipCD = cd
end


local function init(n,g,f)
  name, gameObject, fields = n,g,f

  equipCD = nil
  local cfgConfig = ConfigManager.getConfig("petconfig")
  cfgEquipCD = cfgConfig.equipcd.time
  cfgDeadCD = cfgConfig.deadcd

  for i=1,3 do
      local item = fields.UIList_Partner:AddListItem()
      local textureIcon = item.Controls["UITexture_TargetHead"]
      local labelName = item.Controls["UILabel_TargetName"]
      local buttonPlayed = item.Controls["UIButton_Played"]
      local labelLV = item.Controls["UILabel_TargetLV"]
      local progressBar = item.Controls["UIProgressBar_PartnerHP"]
      local spriteState = item.Controls["UISprite_Played"]
      local sliderCD = item.Controls["UISlider_CD"]
      item.gameObject:SetActive(false)
      uilistPets[i] = {}
      uilistPets[i].item = item
      uilistPets[i].gameObject = item.gameObject
      uilistPets[i].textureIcon = textureIcon
      uilistPets[i].labelName = labelName
      uilistPets[i].labelLV = labelLV
      uilistPets[i].btn = buttonPlayed
      uilistPets[i].hpBar = progressBar
      uilistPets[i].spriteState = spriteState
      uilistPets[i].sliderCD = sliderCD
  end
  uigrid = LuaHelper.GetComponent(fields.UIList_Partner.gameObject,"UIGrid")

  EventHelper.SetListClick(fields.UIList_Partner,function(item)
      local index = item.m_nIndex + 1
    --   uimanager.showdialog("playerrole.dlgplayerrole",index,4)
  end)

end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  OnAttrChange = OnAttrChange,
  UpdateFieldPets = UpdateFieldPets,
  Active = Active,
  UnActive = UnActive,
  DeadUI = DeadUI,
  ActiveUI = ActiveUI,
  UnActiveUI = UnActiveUI,
  ReviveUI = ReviveUI,
  RefreshCD = RefreshCD,
  RefreshLevel = RefreshLevel,
  EquipCD   = EquipCD,
}
