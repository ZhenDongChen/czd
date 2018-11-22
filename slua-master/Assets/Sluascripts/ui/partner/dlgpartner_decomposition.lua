local unpack        = unpack
local print         = print
local PetManager    = require"character.pet.petmanager"
local network       = require"network"
local uimanager     = require"uimanager"
local ColorUtil     = require"common.colorutil"
local ItemManager   = require"item.itemmanager"
local ConfigManager = require"cfg.configmanager"
local EventHelper   = UIEventListenerHelper
local fields,gameObject,name
local pet
local retItems

local function destroy()

end

local function hide()

end

local function SetItem(icon,color,name,count,isFragment)
    local item = fields.UIList_Outcome:AddListItem()
    item.Controls["UILabel_OutcomeDes"].text = name .. "X" .. tostring(count)
    item.Controls["UISprite_BoxQuality"].color = color
    item.Controls["UITexture_OutcomeIcon"]:SetIconTexture(icon)
    if isFragment == true then
        item.Controls["UISprite_Fragment"].gameObject:SetActive(true)
    else
        item.Controls["UISprite_Fragment"].gameObject:SetActive(false)
    end
end

local function ShowItem(itemid,count)
    local item = ItemManager.CreateItemBaseById(itemid)
    local name = item.ConfigData.name
    local icon = item.ConfigData.icon
    local color= ColorUtil.GetQualityColor(item:GetQuality())
    SetItem(icon,color,name,count)
end

local function ShowCompositionExpItems(items)
    for _,v in pairs(items) do
        local itemid  = v.itemid
        local count   = v.count
        ShowItem(itemid,count)
    end
end

local function ShowCompositionStageStarItems(items)
    for itemid,count in pairs(items) do
        ShowItem(itemid,count)
    end
end

local function ShowCompositionFragmentItems(item)
    if item.count > 0 then
        local cfgFragment = ConfigManager.getConfigData("petfragment",item.fragmentid)
        local name  = cfgFragment.name
        local icon  = cfgFragment.icon
        local color = ColorUtil.GetQualityColor(cfgFragment.quality)
        SetItem(icon,color,name,item.count,true)
    end
end

local function ShowCompositionBeans(item)
    if item.count > 0 then
        ShowItem(item.itemid,item.count)
    end
end

local function ShowCompositionItems()
    ShowCompositionExpItems(retItems.exp)
    ShowCompositionStageStarItems(retItems.stagestar)
    ShowCompositionFragmentItems(retItems.fragment)
    ShowCompositionBeans(retItems.beans)
end

local function ShowPetInfo()
    local icon = PetManager.GetHeadIcon(pet.ConfigId)
    PetManager.SetPetColor(fields.UISprite_DecomBoxQuality,pet.ConfigId)
    fields.UITexture_TargetIcon:SetIconTexture(icon)
    fields.UILabel_TargetName.text = pet.ConfigData.name
    fields.UILabel_TargetLv.text = pet.PetLevel
    fields.UILabel_TargetQuality1.text = PetManager.GetStageStarText(pet.PetStageStar)
    fields.UILabel_TargetQuality2.text = LocalString.PartnerText.Awaken .. tostring(pet.PetAwakeLevel)
end

local function refresh(params)
    retItems = PetManager.GetPetDecomposition(pet.ConfigId)
    fields.UIList_Outcome:Clear()
    ShowPetInfo()
    ShowCompositionItems()
end

local function OnRecycle(newpet)
    pet = newpet
    refresh()
end

local function show(params)
      gameObject.transform.localPosition = Vector3(0,0,-1000)
      pet = params
      EventHelper.SetClick(fields.UIButton_DecompositionYES,function()
          network.send(lx.gs.pet.msg.CPetRecycle{modelid=pet.ConfigId})
      end)
end

local function update()

end

local function init(params)
    name,gameObject,fields = unpack(params)

    EventHelper.SetClick(fields.UIButton_Close,function()
        uimanager.hide(name)
    end)
end

return {
    init        = init,
    destroy     = destroy,
    hide        = hide,
    show        = show,
    refresh     = refresh,
    update      = update,
    OnRecycle   = OnRecycle,
}
