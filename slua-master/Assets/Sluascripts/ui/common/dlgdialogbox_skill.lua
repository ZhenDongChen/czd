local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require"uimanager"
local network = require"network"
local subDlg
local DlgType = enum{
    "TalentUpgrade",
    "TalismanSkill",
}
local DefiniteDlg = {
    [DlgType.TalentUpgrade]="ui.partner.dlgpartner_talentupgrade",
    [DlgType.TalismanSkill]="ui.playerrole.talisman.dlgtalisman_skillupdate"
}
local type

local function destroy()
    subDlg.destroy()
end

local function refresh(params)
    subDlg.refresh(params)
end

local function show(params)
    type = params.type
    --printyellow("====",type)

    subDlg = require(DefiniteDlg[type])
    subDlg.show(params)
    local go = GameObject.Find("dlgdialogbox_skill")
    go.transform.localPosition = Vector3(0,0,-3500)
end

local function hide()
    subDlg.hide()
end

local function update()
    subDlg.update()

end

local function init(params)
    name, gameObject, fields = unpack(params)

    for _,mod in pairs(DefiniteDlg) do
        local t = require(mod)
        t.init(params)
    end
    --子lua的init不要做任何事


end



return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  DlgType = DlgType,
}
