local unpack, print     = unpack, print
local UIManager 	    = require("uimanager")
local EventHelper 	    = UIEventListenerHelper
local ConfigManager     = require("cfg.configmanager")
local PVPManager        = require("ui.arena.multi.pvp.pvpmanager")
local DlgRewards        = require("ui.arena.multi.pvp.dlgrewards")
local HelpInfo          = require("ui.helpinfo.helpinfo")
local ColorUtil         = require("common.colorutil")

local name, gameObject, fields



local function SetDescription()
    local lowerLevel, higherLevel = PVPManager.GetLevelRegion()
    if higherLevel ~= nil then
        fields.UILabel_Levels.text = tostring(lowerLevel) .. "-" .. tostring(higherLevel)
    else
        fields.UILabel_Levels.text = string.format(LocalString.TeamFight.HigherLevel, tostring(lowerLevel))
    end

    fields.UILabel_Time.text = tostring(PVPManager.GetDuration()/60) .. LocalString.Time.Min

    if fields.UILabel_ExplainTimes then
        fields.UILabel_ExplainTimes.text = PVPManager.GetMaxExtraBonusTimes()
    end
end

local function SetDayWinBonus()
    local winTimes, totalTimes = PVPManager.GetWinTimes()
    local resetedWinTimes = (((winTimes < totalTimes) and winTimes) or totalTimes)
    fields.UILabel_DayWinTimes.text = tostring(resetedWinTimes) .. "/" .. tostring(totalTimes)

    local isReceived = PVPManager.IsDayBonusReceive()
    local canReceive = (winTimes >= totalTimes)
    local tweenPosition = fields.UIButton_DayWin.gameObject:GetComponent("TweenPosition")

    --fields.UIButton_DayWin.isEnabled = (not isReceived)
    fields.UIButton_DayWin.gameObject:SetActive(true)
    if isReceived == false and canReceive == true then
        fields.UIGroup_DayWinEffect.gameObject:SetActive(true)
        tweenPosition.enabled = true
    else
        fields.UIGroup_DayWinEffect.gameObject:SetActive(false)
        tweenPosition.enabled = false
    end
    EventHelper.SetClick(fields.UIButton_DayWin, function()
        DlgRewards.show("DayRewards",1, canReceive, isReceived)
    end)

    fields.UITexture_DayWinColor.gameObject:SetActive(not isReceived)
    fields.UITexture_DayWinGray.gameObject:SetActive(isReceived)
end

local function SetScoreBonus()
    local curScore, maxScore = PVPManager.GetScore()
    fields.UISlider_Star.value = curScore / maxScore
    local bonusConfig = PVPManager.GetScoreBonus()
  --  fields.UILabel_PassRewardsValue.text = string.format("%s//%s", curScore, maxScore)
    UIHelper.ResetItemNumberOfUIList(fields.UIList_ScoreRewards,#bonusConfig)

    for i = 1, #bonusConfig do
        local uiItem = fields.UIList_ScoreRewards:GetItemByIndex(i-1)
        uiItem:SetText("UILabel_Score", bonusConfig[i].grade)
        local button = uiItem.Controls["UIButton_Box"]
        local effect = uiItem.Controls["UIGroup_Effect"]
        local textureColor = uiItem.Controls["UITexture_Color"]
        local textureGray = uiItem.Controls["UITexture_Gray"]
        if button then
            button.gameObject:SetActive(true)
            local isReceived = PVPManager.IsWeekBonusReceive(i) or false
            local canReceive = (curScore >= bonusConfig[i].grade)
            --button.isEnabled = ((not isReceived) and canReceive)
            local tweenPosition = button.gameObject:GetComponent("TweenPosition")
            if isReceived == false and canReceive == true then
                effect.gameObject:SetActive(true)
                tweenPosition.enabled = true
            else
                effect.gameObject:SetActive(false)
                tweenPosition.enabled = false
            end
            EventHelper.SetClick(button, function()
                DlgRewards.show("ScoreRewards",i, canReceive, isReceived)
            end)
            -- printyellow("isReceived",isReceived)
            -- printyellow("canReceive",canReceive)
            textureColor.gameObject:SetActive(not isReceived)
            textureGray.gameObject:SetActive(isReceived)
        end
    end

    fields.UILabel_PassRewardsValue.text = tostring(curScore) .. "/" .. tostring(maxScore)
    fields.UILabel_ArenaMultiPVP_CurrencyNum.text = PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.TeamFightScore] or 0
end

local function GetTimeStr(restTime)
    local sec = restTime%60
    local min, _ = math.modf((restTime%3600)/60)
    local hour, _ = math.modf(restTime/3600)
    return string.format("%02d:%02d:%02d", hour, min, sec)
end

local function SetButton(isMatching, matchEnable)
    local matchTime = PVPManager.GetMatchTime()
    if matchEnable == true then
	    fields.UILabel_Matching.text = (isMatching == false) and LocalString.TeamFight.StartMatching or LocalString.TeamFight.CancelMatching
    else
        fields.UILabel_Matching.text = (isMatching == false) and LocalString.TeamFight.StartMatching or LocalString.TeamFight.CancelMatching
    end
    if isMatching == false and matchEnable == false then
        fields.UIButton_Matching.isEnabled = true
    else
        fields.UIButton_Matching.isEnabled = true
    end
    local teamfightCfg = ConfigManager.getConfig("teamfight")
    if teamfightCfg and PlayerRole:Instance().m_Level < teamfightCfg.levellimit then
        fields.UIButton_Matching.isEnabled = false
    else
        fields.UIButton_Matching.isEnabled = true
    end
   -- fields.UISprite_CancelMatching.gameObject:SetActive(isMatching)
  --  fields.UISprite_Matching.gameObject:SetActive(not isMatching)
    EventHelper.SetClick(fields.UIButton_Matching, function()
        if isMatching then
            PVPManager.CancelMatchTeamFight()
        else
            PVPManager.BeginMatchTeamFight()
        end
    end)
end

--===================================================================================================
local function RefreshRedDot()
    local dlgAchievementTitle = require("ui.title.dlgachievementtitle")
    local titleUnRead = dlgAchievementTitle.UnRead(cfg.achievement.AchievementType.TEAMFIGHTTITLE)
    fields.UISprite_TitleWarning.gameObject:SetActive(titleUnRead)
end
local function RefreshOpenTimes()
    local opentimeStrs = PVPManager.GetOpenTimeStrs()
    local totalStr = ""
    for i, str in ipairs(opentimeStrs) do
        totalStr = totalStr .. "  " .. str
    end
    fields.UILabel_OpenTime1.text = totalStr
end

local function refresh(params)
    SetDescription()
    SetDayWinBonus()
    SetScoreBonus()
    SetButton(PVPManager.IsMatching(), PVPManager.GetMatchEnable())

    local teamfightCfg = ConfigManager.getConfig("teamfight")
    if teamfightCfg and PlayerRole:Instance().m_Level < teamfightCfg.levellimit then
        fields.UIGroup_Lock.gameObject:SetActive(true)
        fields.UILabel_LockLevel.text = tostring(teamfightCfg.levellimit)
        ColorUtil.SetTextureColorGray(fields.UITexture_Ectype,true)
        fields.UIButton_Rule.gameObject:SetActive(false)
        fields.UIButton_Title.gameObject:SetActive(false)
        fields.UILabel_Level.gameObject:SetActive(false)
        --fields.UISprite_Background.shader =
    else
        fields.UIGroup_Lock.gameObject:SetActive(false)
        ColorUtil.SetTextureColorGray(fields.UITexture_Ectype,false)
        fields.UIButton_Rule.gameObject:SetActive(true)
        fields.UIButton_Title.gameObject:SetActive(true)
        fields.UILabel_Level.gameObject:SetActive(true)

        --fields.UISprite_Background.shader =
    end
    RefreshRedDot()
    RefreshOpenTimes()
end

local function UnRead()
    local teamfightCfg = ConfigManager.getConfig("teamfight")
    local matchLevel = false
    if teamfightCfg and PlayerRole:Instance().m_Level >= teamfightCfg.levellimit then
        matchLevel = true
    end

    local dlgAchievementTitle = require("ui.title.dlgachievementtitle")
    local titleUnRead = dlgAchievementTitle.UnRead(cfg.achievement.AchievementType.TEAMFIGHTTITLE)
    local pvpUnRead = PVPManager.UnRead()

    local unRead = titleUnRead or pvpUnRead

    local showRedDot = PVPManager.ShowFirstRedDot()

    if PVPManager.IsInTimeRange() then
        unRead = unRead or showRedDot
    end
    
    return matchLevel and unRead
end

local function destroy()

end

local function show(params)

    PVPManager.SetFirstRedDot(false)

    EventHelper.SetClick(fields.UIButton_Title, function()
        UIManager.show("title.dlgachievementtitle", { type = cfg.achievement.AchievementType.TEAMFIGHTTITLE })
    end)
    EventHelper.SetClick(fields.UIButton_Rule, function()
        HelpInfo.ShowHelpInfo("teamfight","introduction")
    end)
end

local function hide()

end

local function update()


end

local function second_update()
 --   local matchTime = PVPManager.GetMatchTime()
  --  if matchTime > 0 then
  --      fields.UILabel_Matching.text = GetTimeStr(matchTime)
  --  end
end

local function init(params)
    name, gameObject, fields = unpack(params)
end

return {
    init    = init,
    show    = show,
    hide    = hide,
    update  = update,
    destroy = destroy,
    refresh = refresh,
    UnRead  = UnRead,
    second_update = second_update,
}
