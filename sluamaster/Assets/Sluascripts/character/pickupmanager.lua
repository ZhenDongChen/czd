local UIManager=require"uimanager"
local ItemManager=require"item.itemmanager"
local SettingManager=require"character.settingmanager"
local ItemEnum=require"item.itemenum"

local function update()    
end

local function init()
end

local function CanPick(itemId)
    local canPick=true
    local pickupData=SettingManager.GetPickUpData()        
    if itemId==cfg.currency.CurrencyType.XuNiBi then
        if (pickupData["PickupGoldCoin"]==false)and(secondClass==ItemEnum.ItemType.Currency) then
            canPick=false
        end
	  elseif itemId==cfg.currency.CurrencyType.ZaoHua then
		    canPick=true
    else
        local firstClass,secondClass=ItemManager.GetItemType(itemId)
        local item=ItemManager.CreateItemBaseById(itemId)
        local itemQuality=item:GetQuality()
        if (firstClass==ItemEnum.ItemBaseType.Equipment) then
            if  (pickupData["PickupWhiteEquip"]==false) and (itemQuality==cfg.item.EItemColor.WHITE) then
                canPick=false
            end
            if  (pickupData["PickupGreenEquip"]==false) and (itemQuality==cfg.item.EItemColor.GREEN) then
            canPick=false
            end
            if  (pickupData["PickupBlueEquip"]==false) and (itemQuality==cfg.item.EItemColor.BLUE) then
            canPick=false
            end
            if  (pickupData["PickupPurpleEquip"]==false) and (itemQuality==cfg.item.EItemColor.PURPLE) then
            canPick=false
            end
        elseif (firstClass==ItemEnum.ItemBaseType.Item) then
            if (pickupData["PickupRuby"]==false)and(secondClass==ItemEnum.ItemType.Jewelry) then
            canPick=false
            end
            if (pickupData["PickupPill"]==false)and(secondClass==ItemEnum.ItemType.Medicine) then
            canPick=false  
            end
            if (pickupData["PickupGoldCoin"]==false)and(secondClass==ItemEnum.ItemType.Currency) then
                canPick=false
            end
        else
            if (pickupData["PickupOtherItem"]==false) then
            canPick=false
            end
        end
    end
    return canPick
end

return{
    init=init,
    update=update,
    CanPick=CanPick,
}