local EventHelper       = UIEventListenerHelper
local UIManager         = require("uimanager")
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local Configmanager     = require("cfg.configmanager")
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")

local PageTalismanInfo = {}

--[[
function PageTalismanInfo:SetAdvanceAttribute(talisman)

    local extraProperty = talisman:GetExtraProperty()
    local extroNum = 0
    for i,attr in pairs(extraProperty) do
        extroNum = extroNum + 1
    end

    if extroNum >= 1 then

        self.fields.UIGroup_Awakening01.gameObject:SetActive(false)
        self.fields.UIGroup_Awakening02.gameObject:SetActive(true)
        --高级属性设置
        TalismanUITools.SetAdvanceAttribute(self.fields.UIList_Attribute,extraProperty,"UILabel_AttributeName","UILabel_Attribute")
    else

        self.fields.UIGroup_Awakening01.gameObject:SetActive(true)
        self.fields.UIGroup_Awakening02.gameObject:SetActive(false)
    end

end



function PageTalismanInfo:SetFiveElements(talisman)
    if PlayerRole.Instance().m_Level < TalismanManager.TalismanSystemConfig.FiveElementsSystemLevel then
        self.fields.UISprite_WuXing01.gameObject:SetActive(true)
        self.fields.UISprite_WuXing02.gameObject:SetActive(false)
    else
        self.fields.UISprite_WuXing01.gameObject:SetActive(false)
        self.fields.UISprite_WuXing02.gameObject:SetActive(true)

        self.fields.UILabel_WuxingProperties.text = TalismanUITools.GetFiveElementName(talisman:GetFiveElementsPropertyType(),false)
        self.fields.UILabel_WuxingAmount.text = talisman:GetFiveElementsPropertyValue()
        self.fields.UITexture_WuxingPic:SetIconTexture(TalismanUITools.GetFiveElementIconName(talisman:GetFiveElementsPropertyType()))

        EventHelper.SetClick(self.fields.UIButton_WuxingChange, function()
            UIManager.show("playerrole.talisman.dlgtalisman_changewuxing",{talisman = talisman})
        end)
    end

end
]]
function PageTalismanInfo:SetAwakeAttributeInfo(talisman)
    --(UIList,talisman,showGary,labelText,labelName)
    TalismanUITools.SetAwakeInfo(self.fields.UIList_AwakeAttribute,talisman)
end

function PageTalismanInfo:update()

end


function PageTalismanInfo:refresh(talisman)

    TalismanUITools.SetBaiscAttribute(self.fields.UIList_InfoAttribute, talisman:GetMainProperty(), "UILabel_AttributeName","UILabel_Attribute", 2)
    self:SetAwakeAttributeInfo(talisman)

end

function PageTalismanInfo:show()
    self.fields.UIGroup_Information.gameObject:SetActive(true)
end

function PageTalismanInfo:hide()
    self.fields.UIGroup_Information.gameObject:SetActive(false)
end

function PageTalismanInfo:init(name, gameObject, fields)
    self.fields = fields
end
return PageTalismanInfo
