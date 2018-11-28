local unpack                = unpack
local EventHelper           = UIEventListenerHelper
local print                 = print
local printt                = printt

local uimanager             = require"uimanager"
local network               = require"network"
local EctypeManager         = require"ectype.ectypemanager"

local gameObject,name,fields

local BossTotalHP
local teamDmg
local enemyDmg
local teamScore
local enemyScore

local function ShowTasks(b)
    fields.UIWidget_Left.gameObject:SetActive(b)
end

local function LeaveEctype()
    if EctypeManager.IsFinished() then
        EctypeManager.FuncEnd()
    else
        EctypeManager.RequestLeaveEctype()
    end
end

local function ChangeScore(params)--tScore,eScore)
    teamScore = params.teamscore
    enemyScore = params.enemyscore
    fields.UILabel_MyScore.text = tostring(teamScore)
    fields.UILabel_EnemyScore.text = tostring(enemyScore)
end

local function ChangeDmg(params)
    teamDmg = params.teamdmg
    enemyDmg = params.enemydmg
    -- printyellow("teamDmg",teamDmg)
    -- printyellow("enemyDmg",enemyDmg)
    fields.UILabel_MyScorePercent.text = string.format("%.1f%%", teamDmg)
    fields.UILabel_EnemyScorePercent.text = string.format("%.1f%%",enemyDmg)
end

local function destroy()

end

local function hide()

end

local function update()

end

local function EnterEctype()

end

local function GetFormatedTime(t)
    return string.format("%02d",t)
end

local function UpdateRemainTime(h,m,s)
    if fields then
        if h==0 then
            fields.UILabel_RemainTime.text = GetFormatedTime(m) ..':'.. GetFormatedTime(s)
        else
            fields.UILabel_RemainTime.text = GetFormatedTime(h) ..':'.. GetFormatedTime(m) ..':'.. GetFormatedTime(s)
        end
    end
end

local function ChangeDescription(str)
    fields.UILabel_Description.text = str
end

local function refresh(params)
    if params then
        BossTotalHP = params.bosshp
        ChangeDescription(params.description)
        --    string.format(params.description)-- params.description
        ChangeScore(params)
        ChangeDmg(params)
    end
end

local function show(params)
    -- refresh(params)
end

local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_Left)
    uimanager.SetAnchor(fields.UIWidget_TopRight)
end

local function init(params)
    name,gameObject,fields = unpack(params)
    SetAnchor(fields)
    EventHelper.SetClick(fields.UIButton_RequestLeave,function()
        local tb = {}
        tb.immediate = true
        tb.title = LocalString.EctypeText.LeaveWarningTitle
        tb.content = LocalString.EctypeText.LeaveWarningContent
        tb.callBackFunc = LeaveEctype
        uimanager.ShowAlertDlg(tb)
    end)
end

return {
    destroy             = destroy,
    hide                = hide,
    update              = update,
    refresh             = refresh,
    show                = show,
    init                = init,
    EnterEctype         = EnterEctype,
    ChangeScore         = ChangeScore,
    ChangeDmg           = ChangeDmg,
    UpdateRemainTime    = UpdateRemainTime,
    ChangeDescription   = ChangeDescription,
    ShowTasks           = ShowTasks,
}
