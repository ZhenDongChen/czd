local unpack = unpack

local name
local gameObject
local fields
local subDlg

local DlgType = enum {
    "FamilyWar",  --家族约战
    "RoundRobin", --家族循环赛
}
local DefiniteDlg = {
    [DlgType.FamilyWar] = "ui.family.dlgfamilywarbattle",
    [DlgType.RoundRobin] = "ui.family.dlgroundrobinbattle",
}

local function destroy()
    if subDlg.destroy then
        subDlg.destroy()
    end
end

local function refresh(params)
  if subDlg.refresh then
      subDlg.refresh(params)
  end
end

local function update()
  if subDlg.update then
      subDlg.update()
  end
end

local function second_update()
  if subDlg.second_update then
      subDlg.second_update()
  end
end

local function hide()
    if subDlg.hide then
        subDlg.hide()
    end
end

local function uishowtype()
    return UIShowType.DestroyWhenHide
end

local function show(params)
    subDlg = require(DefiniteDlg[params.type])
    if subDlg.init then
        subDlg.init(name,gameObject,fields)
    end
    if subDlg.show then
        subDlg.show(params)
    end
end

local function init(params)
    name,gameObject,fields = unpack(params)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    DlgType = DlgType,
    second_update = second_update,
    uishowtype = uishowtype,
}
