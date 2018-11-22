local unpack, print = unpack, print
local name, gameObject, fields



local function refresh(params)

end

local function update()

end

local function ShowUIField(uiField)
    if uiField.fieldType == "UILabel" then
        local uiLabel = fields[uiField.fieldName]
        uiLabel.text = tostring(uiField.fieldValue)
    elseif uiField.fieldType == "UITexture" then
        local uiTexture = fields[uiField.fieldName]
        uiTexture:SetIconTexture(tostring(uiField.fieldValue))
    elseif uiField.fieldType == "UIGroup" then
        local uiGroup = fields[uiField.fieldName]
        if uiField.fieldValue == "true" then
            uiGroup.gameObject:SetActive(true)
        else
            uiGroup.gameObject:SetActive(false)
        end
    end
end

local function show(params)
    local fieldList = params.fieldList
    for i, uiField in pairs(fieldList) do
        ShowUIField(uiField)
    end
end

local function hide()

end

local function init(params)
    name, gameObject, fields    = unpack(params)
end

local function destroy()

end


return {
  init                  = init,
  show                  = show,
  hide                  = hide,
  update                = update,
  destroy               = destroy,
  refresh               = refresh,

}




