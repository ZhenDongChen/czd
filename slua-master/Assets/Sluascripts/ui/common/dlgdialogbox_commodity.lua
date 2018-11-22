local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")

local name
local gameObject
local fields
local subDlg

local DlgType = enum{
    "FamilyBossTrain",
    "Commodity",
}
local DefiniteDlg = {
    [DlgType.FamilyBossTrain] = "ui.family.boss.dlgbosstrain",
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

----------------------------
--显示功能所需的Group，关闭无关的Group
-----------------------------
local function DisplayGroupByType(type)
    fields.UIGroup_Train.gameObject:SetActive(type==DlgType.FamilyBossTrain)
    fields.UIGroup_Commodity.gameObject:SetActive(type==DlgType.Commodity)
end

local function show(params)
    -- printyellow("[dlgdialogbox_commodity:show] params:", params)
    type = params.type
    DisplayGroupByType(type)
    subDlg = require(DefiniteDlg[type])
    subDlg.show(params)
    local go = GameObject.Find("dlgdialogbox_commodity")
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
