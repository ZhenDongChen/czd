local unpack                = unpack
local print                 = print
local EventHelper           = UIEventListenerHelper
local UIManager             = require("uimanager")
local TitleManager          = require("ui.title.titlemanager")
local Configmanager         = require("cfg.configmanager")
local AchievementManager    = require("ui.achievement.achievementmanager")
local BonusManager          = require("item.bonusmanager")

local gameObject, name, fields

local achievements = nil
local titleList = nil

local function TitleItemRefresh(uiItem,index,realIndex)
    
    local title = titleList[realIndex]
    local achievement = achievements[realIndex]
    
    local state = AchievementManager.GetStateById(achievement.id)
    
    local UITexture_Title = uiItem.Controls["UITexture_Title"]
    local UILabel_Title = uiItem.Controls["UILabel_Title"]
    local UISprite_Title = uiItem.Controls["UISprite_Title"]
    --设置称号
    title:SetTitleShow(UITexture_Title, UISprite_Title, UILabel_Title)
    --完成进度
    uiItem:SetText("UILabel_ReportInfo", achievement.detail)
    
    
    local currentCount = AchievementManager.GetCountById(achievement.id)
    local totalCount = AchievementManager.GetTotalCountById(achievement.id)
    uiItem:SetText("UILabel_Slider", tostring(currentCount) .. "/" ..tostring(totalCount) )
    
    local trans = uiItem.transform:Find("UISlider_Star")
    local UISlider_Star = trans.gameObject:GetComponent("UISlider")
    
    UISlider_Star.value = (((currentCount > totalCount) and 1) or (currentCount/totalCount))
    
    --领取按钮
    local button = uiItem.Controls["UIButton_Matching"]
    
    if state == cfg.achievement.Status.GETREWARD then
        button.isEnabled = false
        uiItem:SetText("UILabel_Matching", LocalString.DlgAchievement_StateName[2])
        EventHelper.SetClick(button, function()
            AchievementManager.CGetReward(achievement.id)
        end)
        
    elseif state == cfg.achievement.Status.NOTCOMPLETED then
        button.isEnabled = false
        uiItem:SetText("UILabel_Matching", LocalString.DlgAchievement_StateName[0])
        
    else
        button.isEnabled = true
        uiItem:SetText("UILabel_Matching", LocalString.DlgAchievement_StateName[1])
        
        EventHelper.SetClick(button, function()
            AchievementManager.CGetReward(achievement.id)
        end)
    end
    
end

---------------------------------------------------------------------------------------------
local function refresh(params)
    local titleNum = #titleList
    local wrapList = fields.UIList_BattlefieldReport.gameObject:GetComponent("UIWrapContentList")
    EventHelper.SetWrapListRefresh(wrapList,TitleItemRefresh)
    wrapList:SetDataCount(titleNum)
    wrapList:CenterOnIndex(0)
end

local function show(params)
    local allachieves = AchievementManager.GetAllAchievement()
    achievements = allachieves[params.type]
    titleList = {}
    gameObject.transform.position = Vector3(0,0,-1000)
    
    for i, achievement in pairs(achievements) do

        local titleKey
        if type(achievement.titleid) == "number" then
            titleKey = achievement.titleid
        else
            titleKey = achievement.titleid.itemid
        end
        local title = TitleManager.GetTitleById(titleKey)
        if title ~= nil then
            titleList[i] = title
        else
            logError("找不到成就中的称号配置：", achievement.titleid)
        end
    end
    
    EventHelper.SetClick(fields.UIButton_CloseReport, function()
        UIManager.hide(name)
    end)
    
end
---------------------------------------------------------------------------------------------
local function UnRead(type)
    local unread = false
    local allachieves = AchievementManager.GetAllAchievement()
    local curachievements = allachieves[type]
    for i, achievement in pairs(curachievements) do
        local state = AchievementManager.GetStateById(achievement.id)
        if state ~= cfg.achievement.Status.GETREWARD and state ~= cfg.achievement.Status.NOTCOMPLETED then
            unread = true
        end
    end
    return unread
end
---------------------------------------------------------------------------------------------
local function destroy()

end

local function hide()

end

local function update()

end

local function init(params)
    name, gameObject, fields    = unpack(params)
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  UnRead = UnRead,
}
