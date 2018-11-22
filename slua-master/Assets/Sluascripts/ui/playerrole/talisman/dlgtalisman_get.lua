local unpack            = unpack
local print             = print
local require           = require

local UIManager         = require("uimanager")
local EventHelper       = UIEventListenerHelper
local ConfigManager     = require("cfg.configmanager")
local BagManager        = require("character.bagmanager")
local ItemEnum          = require("item.itemenum")
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local BonusManager      = require("item.bonusmanager")
----------------------------------------------------------------------------------------------------
local name
local gameObject
local fields
local SelectedTaliman = nil



local function SetItem(uiItem,talisman)    
    local button = uiItem.gameObject:GetComponent("UIButton")
    uiItem.Id = talisman:GetConfigId()
    BonusManager.SetRewardItem(uiItem, talisman, {notShowAmount = true, notSetClick = true})
    
    local selectedSprite = uiItem.Controls["UISprite_Selected"]
 
    if SelectedTaliman and talisman.BagPos == SelectedTaliman.BagPos then
        selectedSprite.gameObject:SetActive(true)
    else
        selectedSprite.gameObject:SetActive(false)
    end
    uiItem.Id=talisman.ConfigId
    EventHelper.SetClick(uiItem, function()
        SelectedTaliman = talisman
        UIManager.refresh(name)
    end)
end

local function GetAllTalismanCanUse()
    local talismans = BagManager.GetItems(cfg.bag.BagType.TALISMAN)
    local newList = {}
    for i, talisman in ipairs(talismans) do
        printyellow(talisman:GetName(),talisman:CanUse())
        if talisman:CanUse() ~= false then
            table.insert( newList, talisman )
        end
    end
    return newList
end


local function refresh(params)

    local talismanItems = GetAllTalismanCanUse()
    local talismanNum = #talismanItems

    --printyellow("talismanItems",talismanItems)
    --printyellow("talismanNum",talismanNum)
    
    UIHelper.ResetItemNumberOfUIList(fields.UIList_TalismanBag, talismanNum)
    if talismanNum > 0 then
        fields.UIGroup_Empty.gameObject:SetActive(false)
    else
        fields.UIGroup_Empty.gameObject:SetActive(true)
    end

    for i, talisman in ipairs(talismanItems) do
        local uiItem = fields.UIList_TalismanBag:GetItemByIndex(i-1)
        SetItem(uiItem, talisman)
    end
        
    local currentTalisman = TalismanManager.GetCurrentTalisman()
    if SelectedTaliman ~= nil then
        fields.UIButton_Sure.isEnabled = true
        if currentTalisman ~= nil then
            EventHelper.SetClick(fields.UIButton_Sure,function()
                UIManager.ShowAlertDlg({
                    immediate    = true,
                    title        = LocalString.TipText,
                    content      = LocalString.Talisman.ReEquipInfo,
                    sureText     = LocalString.Talisman.Sure,
                    cancelText   = LocalString.Talisman.Cancel,
                    callBackFunc = function()
                        TalismanManager.EquipTalisman(SelectedTaliman)
                        UIManager.hide(name)
                    end,})
            end)
        else
            EventHelper.SetClick(fields.UIButton_Sure,function()
                TalismanManager.EquipTalisman(SelectedTaliman)
                UIManager.hide(name)
            end)
        end
    else
        fields.UIButton_Sure.isEnabled = false
    end
end

local function show(params)

end

local function destroy()

end

local function hide()

end

local function update()

end

local function init(params)
    name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide(name)
    end)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,

}
