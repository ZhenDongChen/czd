local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")

local name
local gameObject
local fields
local subDlg

local DlgType = enum{
    "PetSkin",
    "WorldBossLine",
    "TournamentGuess",
}
local DefiniteDlg = {
    [DlgType.PetSkin] = "ui.partner.dlgpartner_skin",
}

local type

local function destroy()
    subDlg.destroy()
end

local function refresh(params)
    subDlg.refresh(params)
end

local function update()
    subDlg.update()
end

local function hide()
    subDlg.hide()
end

local function currenttype()
    return type
end

local function uishowtype()
	-- 公用弹窗hide直接销毁，防止其他界面使用出现
	-- 公用部分显隐错误
	return UIShowType.DestroyWhenHide
end

local function show(params)
    -- printyellow("[dlgdialogbox_list:show] params:", params)
    type = params.type
    subDlg = require(DefiniteDlg[type])
    subDlg.show(params)
    local go = GameObject.Find("dlgdialogbox_list")
    go.transform.localPosition = Vector3(0,0,-3500)
end

local function init(params)
    name,gameObject,fields=Unpack(params)
    for _,mod in pairs(DefiniteDlg) do
        local t = require(mod)
        t.init(name,gameObject,fields)
    end
    EventHelper.SetClick(fields.UIButton_Close,function()
        UIManager.hide(name)
    end)
    --子lua的init不要做任何事
end

return{
    show = show,
    init = init,
    update = update,
    refresh = refresh,
    hide = hide,
    DlgType = DlgType,
	uishowtype = uishowtype,
    currenttype = currenttype,
}
