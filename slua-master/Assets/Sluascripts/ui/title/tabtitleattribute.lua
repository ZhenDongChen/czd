local unpack            = unpack
local print             = print
local EventHelper       = UIEventListenerHelper
local UIManager         = require("uimanager")
local TitleManager      = require("ui.title.titlemanager")
local Configmanager     = require("cfg.configmanager")
local AttributeHelper   = require("attribute.attributehelper")

local gameObject, name, fields





---------------------------------------------------------------------------------------------
local function refresh(params)

    local allProperties, num = TitleManager.GetAllProperty()
    local allNum = TitleManager.GetAllTitleNumber()
    local availableNum = TitleManager.GetAvailableTitleNum()

    fields.UILabel_TitleAmout.text = availableNum .. "/" .. allNum
    fields.UILabel_Fighting.text = PlayerRole:Instance().m_Power or 0
    
    UIHelper.ResetItemNumberOfUIList(fields.UIList_AllProperty,num)

    for i =1,num do
        item = fields.UIList_AllProperty:GetItemByIndex(i-1)
        local attrName = AttributeHelper.GetAttributeName(allProperties[i].type)
        local attrValue = AttributeHelper.GetAttributeValueString(allProperties[i].type, allProperties[i].value)
        item:SetText("UILabel_Property", tostring(attrName))
        item:SetText("UILabel_Amount", "+" .. tostring(attrValue))
        local sprite = item.Controls["UISprite_Icon"]
        if sprite then
            sprite.spriteName = AttributeHelper.GetAttributeSpriteName(allProperties[i].type)
        end
    end

    for i,k in pairs(allProperties) do

    end

    if num > 0 then
        fields.UIGroup_Empty.gameObject:SetActive(false)
    else
        fields.UIGroup_Empty.gameObject:SetActive(true)
    end
end

local function destroy()
  --print(name, "destroy")
end

local function show(params)

end

local function hide()
  --print(name, "hide")
end


local function update()

end
local function showtab(params)
    UIManager.show("title.tabtitleattribute",params)
end
local function init(params)
    name, gameObject, fields    = unpack(params)
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  showtab = showtab,
}
