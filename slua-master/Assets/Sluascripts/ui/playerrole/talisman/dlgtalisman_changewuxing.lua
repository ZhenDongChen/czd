local unpack            = unpack
local print             = print
local require           = require
local Network           = require("network")
local UIManager         = require("uimanager")
local EventHelper       = UIEventListenerHelper
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local ItemEnum          = require("item.itemenum")
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")
----------------------------------------------------------------------------------------------------
local name
local gameObject
local fields
local isRotating = false
local talisman
local TweenRotation

local FiveElementsAngle = {
    [cfg.fight.AttackType.METAL] = 0,
    [cfg.fight.AttackType.WOOD] = -85,
    [cfg.fight.AttackType.WATER] = 144,
    [cfg.fight.AttackType.FIRE] = 85,
    [cfg.fight.AttackType.EARTH] = 216,
}

local function StartRotate(endAngle, isSkip)
    if isSkip then
        fields.UISprite_Arrows.gameObject.transform.rotation = Quaternion.Euler(0,0,endAngle)
    else
        isRotating = true
        TweenRotation = fields.UISprite_Arrows.gameObject:GetComponent("TweenRotation")
        TweenRotation.duration = 0.5
        local currentWuxing = talisman:GetFiveElementsPropertyType()
        TweenRotation.gameObject.transform.rotation = Quaternion.Euler(0,0,FiveElementsAngle[talisman:GetFiveElementsPropertyType()])
        TweenRotation.enabled = true
    end
end


local function ChangeEnd(params)
    local allZaohua = TalismanManager.GetCurrency("ZaoHua")
    fields.UILabel_TatolZaohua.text= "/" .. allZaohua
    StartRotate(params.result,false)
end

local function destroy()

end

local function hide()

end

local function refresh(params)
    talisman = params.talisman
    fields.UILabel_WuXing.text = TalismanUITools.GetFiveElementName(talisman:GetFiveElementsPropertyType(),true)
    local allZaohua = TalismanManager.GetCurrency("ZaoHua")
    EventHelper.SetClick(fields.UIButton_Change, function()
        if TalismanManager.TalismanSystemConfig.ChangeWuxingCost <= allZaohua then
            TalismanManager.ChangeWuxingType(talisman)
        else
            UIManager.hide("playerrole.talisman.dlgtalisman_changewuxing")
            TalismanUITools.ShowHelpInfo("Wuxing/NotEnoughZaohua")
        end
    end)

    local FiveElementsValue = talisman:GetFiveElementsPropertyValue()

    fields.UILabel_Golden.text   = FiveElementsValue
    fields.UILabel_Wood.text     = FiveElementsValue
    fields.UILabel_Earth.text    = FiveElementsValue
    fields.UILabel_Water.text    = FiveElementsValue
    fields.UILabel_Fire.text     = FiveElementsValue

    fields.UILabel_CostZaohua.text = TalismanManager.TalismanSystemConfig.ChangeWuxingCost

    fields.UILabel_TatolZaohua.text= "/" .. allZaohua
end

local function show(params)
    talisman = params.talisman
    --printyellow("=-======>")
    isRotating = false
    local TweenRotation = fields.UISprite_Arrows.gameObject:GetComponent("TweenRotation")
    TweenRotation.duration = 0.5
    local currentWuxing = talisman:GetFiveElementsPropertyType()
    TweenRotation.enabled = false

    fields.UISprite_Arrows.gameObject.transform.rotation = Quaternion.Euler(0,0,FiveElementsAngle[currentWuxing])

end

local function update()
    if isRotating == false then
        return
    end

    if TweenRotation.duration < 5 then
        TweenRotation.duration = TweenRotation.duration + 1 * Time.deltaTime
    else
        local endAngle = FiveElementsAngle[talisman:GetFiveElementsPropertyType()]
        if math.abs(TweenRotation.gameObject.transform.eulerAngles.z - endAngle) < 2 then
            fields.UILabel_WuXing.text = TalismanUITools.GetFiveElementName(talisman:GetFiveElementsPropertyType(),true)
            TweenRotation.enabled = false
        end
    end
end


local function init(params)
    name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide("playerrole.talisman.dlgtalisman_changewuxing")
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
    ChangeEnd=ChangeEnd,

}
