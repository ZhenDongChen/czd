local Unpack = unpack
local EventHelper = UIEventListenerHelper
local ConfigManager= require("cfg.configmanager")
local HeroChallengeManager = require("ui.activity.herochallenge.herochallengemanager")
local LimitManager = require("limittimemanager")
local BonusManager = require("item.bonusmanager")
local UIManager = require("uimanager")

local m_GameObject
local m_Name
local m_Fields

local function destroy()
end

local function refresh()
end

local function DisplayBonus()
    local rewards = HeroChallengeManager.GetBonus()
    m_Fields.UIList_Icon:Clear()
    for _,item in pairs(rewards) do      
        local rewardItem = m_Fields.UIList_Icon:AddListItem()
        BonusManager.SetRewardItem(rewardItem,item)       
    end
end

local function show(params)
    local openLevel,curStage,stageLevel = HeroChallengeManager.GetStageByLevel()
    local isOpen = (curStage > 0)
    local times = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.HERO_TASK,0)
    m_Fields.UIGroup_Lock.gameObject:SetActive(not isOpen)
    m_Fields.UILabel_Level.gameObject:SetActive(isOpen)
    if times < HeroChallengeManager.GetMaxBonusCount() then
        m_Fields.UILabel_LastTime.text = times
    else
        m_Fields.UILabel_LastTime.text = LocalString.HeroChallenge_FinishMax
    end
    m_Fields.UIButton_Setting.isEnabled = isOpen
    m_Fields.UITexture_Pvp:SetIconTexture("Texture_Activity_27")
    if isOpen == true then
        colorutil.SetTextureColorGray(m_Fields.UITexture_Pvp, false)
        m_Fields.UILabel_Levels.text=curStage .. "-" .. (curStage + stageLevel - 1)
        EventHelper.SetClick(m_Fields.UIButton_Setting,function()
            UIManager.hidecurrentdialog()
            HeroChallengeManager.NavigateToOpenActivity()
        end)
    else
        m_Fields.UILabel_UnLockLevel.text = string.format(LocalString.Ectype_OpenLevel,openLevel)
        colorutil.SetTextureColorGray(m_Fields.UITexture_Pvp,true)
    end
    DisplayBonus()
end

local function hide()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)      
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    init = init,
    show = show,
    hide = hide,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
}