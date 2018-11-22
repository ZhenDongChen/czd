local Unpack = unpack
local Math = math
local Format = string.format

local AllDlgType = enum
{
    "Resurrection",
    --"HeroChallengeTeam",
}
local DefiniteDlg = {
    [AllDlgType.Resurrection] = "ui.revive.dlgresurrection",
    --[AllDlgType.HeroChallengeTeam] = "ui.activity.herochallenge.dlgherochallengeteam",
}

local m_GameObject
local m_Name
local m_Fields
local m_Type
local m_SubDlg

local function destroy()
    m_SubDlg.destroy()
end

local function show(params)   
    m_Type = params.type
    m_SubDlg = require(DefiniteDlg[m_Type])
    m_SubDlg.show(params)
end

local function hide()
    m_SubDlg.hide()
end

local function update()  
    if m_SubDlg.update then
        m_SubDlg.update()
    end
end

local function refresh(params)
    m_SubDlg.refresh()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)
    for _,mod in pairs(DefiniteDlg) do
        local t = require(mod)
        t.init(m_Name,m_GameObject,m_Fields)
    end
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  AllDlgType = AllDlgType,
}