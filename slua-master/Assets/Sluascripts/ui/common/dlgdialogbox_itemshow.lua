local EventHelper   = UIEventListenerHelper
local UIManager     = require("uimanager")
local BonusManager  = require("item.bonusmanager")

local name, gameObject, fields

local function refresh(params)

end

local function update()

end

local function hide()

end

local function GetItemList(params)
    local itemList = {}
    if params and params.itemList then
        for i, item in pairs(params.itemList) do
            table.insert( itemList, item )
        end 
    end
    return itemList
end

local function ShowItem(uiItem, item)
    BonusManager.SetRewardItem(uiItem, item, {})
    local labelName = uiItem.Controls["UILabel_Name"]
    local labelCount = uiItem.Controls["UILabel_Count"]
    labelName.text = item:GetName()
    labelCount.text = string.format("X%s", tostring(item:GetNumber()))
end

local function show(params)
    local itemList = GetItemList(params)
    fields.UIList_ItemShow:Clear()
    for i, item in ipairs(itemList) do
        local uiItem = fields.UIList_ItemShow:AddListItem()
        ShowItem(uiItem, item)
    end
end

local function init(params)
    name, gameObject, fields    = unpack(params)
    EventHelper.SetClick(fields.UIButton_Back,function()
        --printyellow("AAAAAAAAAAAAAA",name)
        UIManager.hide(name)
    end)
end

return{
    show = show,
    init = init,
    update = update,
    refresh = refresh,
	hide = hide,
}