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

local towers
local worldTowers

local fmtScore = "%d/%d"
local maxScore = 0

local OccupyState = enum{
  "CENTRE=1",
  "ALLY=2",
  "ENEMY=3",
}

local OccupySprite = {
    [OccupyState.CENTRE]  = "Column_Grey",
    [OccupyState.ALLY]    = "Column_Green",
    [OccupyState.ENEMY]   = "Column_Red",
}

local OccupyColor = {
    [OccupyState.CENTRE]  = Color(254/255,        1,  240/255  ,1),
    [OccupyState.ALLY]    = Color(154/255,  254/255,   25/255  ,1),
    [OccupyState.ENEMY]   = Color(250/255,   73/255,   38/255  ,1),
}

local OccupyEffectColor = {
    [OccupyState.CENTRE]  = Color(12 /255,  32 /255,  46 /255,  1),
    [OccupyState.ALLY]    = Color(17 /255,  44 /255,  62 /255,  1),
    [OccupyState.ENEMY]   = Color(75 /255,  13 /255,   9 /255,  1),
}

local StateCampMap = {
    [cfg.family.citywar.OccupyState.GREEN]  = OccupyState.ALLY,
    [cfg.family.citywar.OccupyState.RED]    = OccupyState.ENEMY,
    [cfg.family.citywar.OccupyState.GREY]   = OccupyState.CENTRE,
}

local towersMap = {
    [true]  = {1,2,3,4,5,6,7},
    [false] = {1,2,3,4,5,6,7},
}

local towerMap

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
    for _,member in ipairs(teamInfo.members) do
        ret = ret + member.damage
    end
    return ret
end

local function ShowStatistic(teamInfo)
    local totalDmg = GetTotalHarm(teamInfo)
    local totalDmg = totalDmg>0 and totalDmg or 1
    fields.UIList_HarmRanking:ResetListCount(#teamInfo.members)
    for idx,member in ipairs(teamInfo.members) do
        local item = fields.UIList_HarmRanking:GetItemByIndex(idx-1)
        item.Controls["UILabel_Rank"].text = tostring(idx)
        item.Controls["UILabel_Name"].text = member.name
        item.Controls["UILabel_Harm"].text = string.format("%.1f%%",member.damage/totalDmg*100)
    end
end

local function OnStatistic(info)
    local roleteam = nil
    for _,team in pairs(info.teams) do
        if team.broleteam then
            roleteam = team
            break
        end
    end
    if roleteam then
        ShowStatistic(roleteam)
    end
end

local function GetFormatedTime(t)
    return string.format("%02d",t)
end

local function AutoFight()
    uimanager.call("dlguimain","SwitchAutoFight",true)
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

local function OnScore(scores)
	  local allyscore = 0
	if isattacker == true then
		allyscore = scores.myfamilyscore 
		enemyscore = scores.opponentscore
	else
		allyscore = scores.opponentscore
		enemyscore = scores.myfamilyscore
	end


	if allyscore == nil then
		allyscore = 0
	end
	
	if enemyscore == nil then
		enemyscore = 0
	end
	fields.UILabel_MyScore.text = string.format(fmtScore,allyscore,maxScore)
	fields.UILabel_YourScore.text = string.format(fmtScore,enemyscore,maxScore)

    
end

local function ChangeTowerState(towerid,state)
    local camp = StateCampMap[state]
	if towerMap~= nil then
		towers[towerMap[towerid]].sprite.spriteName = OccupySprite[camp]
		towers[towerMap[towerid]].label.color = OccupyColor[camp]
		towers[towerMap[towerid]].label.effectColor = OccupyEffectColor[camp]
	end

end

local function RegClickTowers()
    for idx,tower in ipairs(towers) do
        local realidx = towerMap[idx]
        local towerposition = cfgFamilyWar.towers[realidx].position
        EventHelper.SetClick(tower.sprite,function()
			--printyellow("cfgFamilyWar.distance",cfgFamilyWar.distance)
            local param = {
                targetPos = Vector3(towerposition.x-cfgFamilyWar.distance,towerposition.y-cfgFamilyWar.distance,0),
				--targetPos = Vector3(towerposition.x-45,towerposition.y-45,0),
				newStopLength = 100,
                stopCallback = AutoFight,
            }
            PlayerRole.Instance():navigateTo(param)
			
        end)
    end
end

local function RefreshTowersStates(params)
    for _,sInfo in ipairs(params) do
        ChangeTowerState(sInfo.idx,sInfo.state)
    end
end

local function InitTowersCamp()
    for towerid,tower in pairs(towers) do
        ChangeTowerState(towerid,cfg.family.citywar.OccupyState.GREY)
    end
    RegClickTowers()
end

local function InitTowerState(params)
	printyellow("InitTowerState")
    towerMap          = towersMap[params.isattacker]
    isattacker        = params.isattacker
    maxScore          = params.maxScore
    local allyName
    local enemyName
	
    allyName = params.attackFamilyName 
    enemyName =  params.defenceFamilyName 
    fields.UILabel_AllyName.text = allyName
    fields.UILabel_EnemyName.text = enemyName
    InitTowersCamp()
end

local function InitTowers()
    towers = {}
    for i=0,fields.UIList_Towers.Count-1 do
        local item = fields.UIList_Towers:GetItemByIndex(i)
        if item then
            local tower   = {}
            tower.item    = item
            tower.sprite  = item.Controls["UISprite_Tower"]
            tower.label   = item.Controls["UILabel_Tower"]
            local globaltweens = item.Controls["UIGroup_TowerState"]
            tower.sprite.spriteName = OccupySprite[OccupyState.CENTRE]
            tower.label.color = OccupyColor[OccupyState.CENTRE]
            tower.label.effectColor = OccupyEffectColor[OccupyState.CENTRE]
            table.insert(towers,tower)
        end
    end
    OnScore{attackscore=0,defencescore=0}
end

local function EnterEctype()
    InitTowers()
end

local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_Left)
    uimanager.SetAnchor(fields.UIWidget_TopRight)
end

local function init(params)
    name,gameObject,fields = unpack(params)
    SetAnchor(fields)
	--ConfigManager.getConfig("citywar")
    cfgFamilyWar = ConfigManager.getConfig("citywar")
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
    UpdateRemainTime    = UpdateRemainTime,
    ShowTasks           = ShowTasks,
    OnScore             = OnScore,
    OnStatistic         = OnStatistic,
    InitTowerState      = InitTowerState,
    RefreshTowersStates = RefreshTowersStates,
}
