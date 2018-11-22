local unpack                = unpack
local EventHelper           = UIEventListenerHelper
local print                 = print
local printt                = printt

local uimanager             = require"uimanager"
local network               = require"network"
local EctypeManager         = require"ectype.ectypemanager"
local PlayerRole            = require"character.playerrole"
local cfgFamilyWar
local gameObject,name,fields

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

local function destroy()

end

local function hide()

end

local function update()

end

local function GetTotalHarm(teamInfo)
    local ret = 0
    printt(teamInfo)
    for _,member in ipairs(teamInfo.members) do
        ret = ret + member.damage
    end
    return ret
end

local function ShowStatistic(teamInfo)
    local totalDmg = GetTotalHarm(teamInfo)
    fields.UIList_HarmRanking:ResetListCount(#teamInfo.members)
    for idx,member in ipairs(teamInfo.members) do
        local item = fields.UIList_HarmRanking:GetItemByIndex(idx-1)
        item.Controls["UILabel_Rank"].text = tostring(idx)
        item.Controls["UILabel_Name"].text = member.name
        item.Controls["UILabel_Harm"].text = string.format("%.1f%%",member.damage/totalDmg*100)
    end
end

local function OnStatistic(info)
    printyellow("OnStatistic")
    printt(info)
    local roleteam = nil
    for _,team in pairs(info.teams) do
        if team.broleteam then
            roleteam = team
            break
        end
    end
    if roleteam then
        printyellow("ShowStatistic")
        ShowStatistic(roleteam)
    end
end

local function OnTeam(isally,params)
    local ss = isally and "My" or "Your"
    -- printyellow("a",string.format("UILabel_%sScore",ss))
    fields[string.format("UILabel_%sScore",ss)].text = tostring(params.score)
    for i=1,3 do
        -- local compName = "UILabel_MyTowerBlood0" .. tostring(i)
        local compName = string.format("UILabel_%sTowerBlood0%d",ss,i)
        -- fields[compName].text = tostring(params.towerhps[i]*100) ..'%'
        fields[compName].text = string.format("%d%%",math.floor(params.towerhps[i]*100))
    end
end

local function OnChange(params)
    OnTeam(true,params.ally)
    OnTeam(false,params.enemy)
end

local function GetFormatedTime(t)
    return string.format("%02d",t)
end

local function BreakTower(params)
    local idx = params.idx
    local isally = params.isally
    local ss = isally and "My" or "Your"
    local compName = string.format("UISprite_%sTowerColor0%d",ss,idx)
    fields[compName].gameObject:SetActive(false)
end

local function InitFamilyWar()
    OnTeam(true,{score=0,towerhps={1,1,1}})
    OnTeam(false,{score=0,towerhps={1,1,1}})
end

local function AutoFight()
    uimanager.call("dlguimain","SwitchAutoFight",true)
end

local function InitTowerPathFinding(isally,positions)
    local ss = isally and "My" or "Your"
    for i=1,3 do
        local compName = string.format("UISprite_%sTower0%d",ss,i)
        EventHelper.SetClick(fields[compName],function()
            local pos = positions[i]
            local param = {
                targetPos = Vector3(pos.x,pos.y,0),
                lengthCallback = {{length=1200,callback=AutoFight}},
                stopCallback = AutoFight,
            }
            PlayerRole.Instance():navigateTo(param)
        end)
    end
end

local function InitTowerPositions(isRed)
    -- local ourPositions = cfgFamilyWar.towerpositions1
    -- local enemy
    local ourPositions = isRed and cfgFamilyWar.towerpositions1 or cfgFamilyWar.towerpositions2
    local enemyPositions = isRed and cfgFamilyWar.towerpositions2 or cfgFamilyWar.towerpositions1
    InitTowerPathFinding(true,ourPositions)
    InitTowerPathFinding(false,enemyPositions)
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

local function refresh(params)
end

local function show(params)

end


local function EnterEctype()
    InitFamilyWar()
end

local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_Left)
    uimanager.SetAnchor(fields.UIWidget_TopRight)
end

local function init(params)
    name,gameObject,fields = unpack(params)
    SetAnchor(fields)
    cfgFamilyWar = ConfigManager.getConfig("familywar")
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
    UpdateRemainTime    = UpdateRemainTime,
    ShowTasks           = ShowTasks,
    OnScore             = OnScore,
    OnTowerInfo         = OnTowerInfo,
    OnChange            = OnChange,
    BreakTower          = BreakTower,
    InitTowerPositions  = InitTowerPositions,
    OnStatistic         = OnStatistic,
}
