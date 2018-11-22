local unpack            = unpack
local print             = print
local require           = require

local UIManager         = require("uimanager")
local EventHelper       = UIEventListenerHelper
local BagManager        = require("character.bagmanager")
local ItemEnum          = require("item.itemenum")
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local BonusManager      = require("item.bonusmanager")
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")

----------------------------------------------------------------------------------------------------

local name
local gameObject
local fields
local advanceTalisman = nil

local function CanAdd(talisman, item)
    return TalismanManager.CanAddStarOrder(talisman, item)
end

local function IsSelected(item)
    for i,talisman in pairs(TalismanManager.TalismanSystemConfig.ConsumeTalismans) do
        if talisman.BagPos == item.BagPos then
            return true, i
        end
    end
    return false,nil
end

local function SetItem(uiItem,item,i)
    BonusManager.SetRewardItem(uiItem,item,{notShowAmount = true, notSetClick=true})
  --  local texture = uiItem.Controls["UITexture_Icon"]
   -- texture:SetIconTexture(item:GetIconPath())

    uiItem:SetText("UILabel_Name",item:GetName())
    uiItem:SetText("UILabel_Level",item:GetNormalLevel())
    uiItem:SetText("UILabel_Star",TalismanUITools.GetStarOrderText(item))
    uiItem:SetText("UILabel_Awakening",string.format(LocalString.Talisman.Top.Awake,item:GetAwakeLevel()))
    
    local toggleObj = uiItem.gameObject.transform:Find("UIToggle_CheckBox")
    local toggle = toggleObj.transform:GetComponent("UIToggle")
    local isItemSelected,pos = IsSelected(item)
    local selectedTalismanNum = #TalismanManager.TalismanSystemConfig.ConsumeTalismans
    if isItemSelected == true then
        toggle.value = true
        EventHelper.SetClick(uiItem, function()
            toggle.value = false
            table.remove(TalismanManager.TalismanSystemConfig.ConsumeTalismans,pos)
            UIManager.refresh(name,{talisman = advanceTalisman})
        end)
    else
        toggle.value = false
        EventHelper.SetClick(uiItem, function()
            if selectedTalismanNum < TalismanManager.GetMaxStarOrderConsumeCount() then
                toggle.value = true
                table.insert(TalismanManager.TalismanSystemConfig.ConsumeTalismans,item)
                UIManager.refresh(name,{talisman = advanceTalisman})
            else
                UIManager.ShowSystemFlyText(LocalString.Talisman.TalismanSelectMax)
            end
        end)
    end

end

local function SetNumAndButton(num,talismans)
    local selectNum = #(TalismanManager.TalismanSystemConfig.ConsumeTalismans)

    fields.UILabel_Amount.text = string.format("%d/%d", selectNum, TalismanManager.GetMaxStarOrderConsumeCount())
    EventHelper.SetClick(fields.UIButton_Sure,function()

        UIManager.hide(name)
        UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")
    end)
end


local function TalismanSortFunc(itemA, itemB)
    local qualityA = itemA:GetQuality()
    local qualityB = itemB:GetQuality()
    if qualityA < qualityB then
        return true
    else
        return false
    end
end

local function refresh(params)
    if params == nil or params.talisman == nil then
        UIManager.hide(name)
    end

    advanceTalisman = params.talisman
    
    local items = BagManager.GetItems(cfg.bag.BagType.TALISMAN)
    local talismans = {}
    for i, item in pairs(items) do
        if CanAdd(advanceTalisman, item) then
            table.insert(talismans,item)
        end
    end
    table.sort( talismans, TalismanSortFunc)
    local num = #talismans
    
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Props, num)
    for i = 1, num do
        local uiItem = fields.UIList_Props:GetItemByIndex(i-1)
        SetItem(uiItem,talismans[i],i)
    end
    SetNumAndButton(num,talismans)
end

local function update()

end

local function show(params)

end

local function destroy()

end

local function hide()
    UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")
end

local function init(params)
    name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide(name)
    end)
    gameObject.transform.position = Vector3(0,0,-1000)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,

}
