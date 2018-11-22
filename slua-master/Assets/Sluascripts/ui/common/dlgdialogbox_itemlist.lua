local EventHelper = UIEventListenerHelper
local UIManager   = require("uimanager")

local name
local gameObject
local fields
local subDlg

local DlgType = enum {
	"TransferredEquips",
	"WelfarePets",
    "AccEnhance",
	"UpgradedProp1",
	"UpgradedProp2",
}
local DefiniteDlg = {
    [DlgType.TransferredEquips] = "ui.playerrole.equip.dlgalert_equips",
    [DlgType.WelfarePets] = "ui.dlgalert_pets",
    [DlgType.AccEnhance] = "ui.playerrole.equip.dlgalert_equips",
	[DlgType.UpgradedProp1] = "ui.playerrole.equip.dlgalert_equips",
	[DlgType.UpgradedProp2] = "ui.playerrole.equip.dlgalert_equips",
}

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

local function uishowtype()
	-- 公用弹窗hide直接销毁，防止其他界面使用出现
	-- 公用部分显隐错误
	return UIShowType.DestroyWhenHide
end

local function show(params)
    subDlg = require(DefiniteDlg[params.type])
	subDlg.init(name,gameObject,fields)
    subDlg.show(params)
end

local function init(params)
    name,gameObject,fields = unpack(params)
	gameObject.transform.localPosition = Vector3(0,0,-3500)
    EventHelper.SetClick(fields.UIButton_Close,function()
        UIManager.hide(name)
    end)
end

return{
    show        = show,
    init        = init,
    update      = update,
    refresh     = refresh,
    hide        = hide,
    DlgType     = DlgType,
	uishowtype  = uishowtype,
}
