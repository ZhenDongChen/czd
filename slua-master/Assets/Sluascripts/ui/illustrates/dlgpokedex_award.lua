local print,printt,unpack   = print,printt,unpack
local EventHelper           = UIEventListenerHelper
local uimanager             = require"uimanager"
local name,gameObject,fields
local subDlg

local uiTypes = {
    ["STAGESTAR"]   = "ui.illustrates.dlgpokedex_stagestar",
    ["AWAKE"]       = "ui.illustrates.dlgpokedex_awake",
}

local function destroy()
    subDlg.destroy()
end

local function hide()
    subDlg.hide()
end

local function refresh(params)
    subDlg.refresh(params)
end

local function show(params)
    printt(params)
    local ui = uiTypes[params.type]
    subDlg = require(ui)
    subDlg.show(params)
end

local function update()
    subDlg.update()
end

local function OnAward(idx)
    local item = fields.UIList_Award:GetItemByIndex(idx)
    local effectTransform = fields.UIGroup_Effect.gameObject.transform
    local itemTransform = item.gameObject.transform
    effectTransform.gameObject:SetActive(false)
    effectTransform.parent = itemTransform
    effectTransform.localPosition = Vector3(400,59,0)
    effectTransform.gameObject:SetActive(true)
end

local function init(params)
    name,gameObject,fields = unpack(params)
    gameObject.transform.localPosition = Vector3.forward * -800
    for _,v in pairs(uiTypes) do
        local t = require(v)
        t.init(name,gameObject,fields)
    end

    EventHelper.SetClick(fields.UIButton_Close,function()
        uimanager.hide(name)
    end)
end

return {
    destroy             = destroy,
    hide                = hide,
    refresh             = refresh,
    show                = show,
    update              = update,
    init                = init,
    OnAward             = OnAward,
}
