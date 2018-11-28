local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local actmgr = require("family.activitymanager")
local partymgr = require("family.partymanager")
local familymgr = require("family.familymanager")
local configmanager = require("cfg.configmanager")
local taskmanager = require "taskmanager"
local FamilyBossInfo = require("ui.family.boss.familybossinfo")
local PlayerRole = require "character.playerrole"
local warmanager = require("family.warmanager")
local FamilyBossMgr

local ButtonNames =
{
    Mission   = "UIListItem_Mission",
    Pray      = "UIListItem_Pray",
    Boss      = "UIListItem_Boss",
    HomeLand  = "UIListItem_HomeLand",
    LuckyStar = "UIListItem_LuckyStar",
    Ectype    = "UIListItem_Ectype",
    Battle    = "UIListItem_Battle",
    CupWar    = "UIListItem_Cupwar",
}

local fields
local name

local function showtab(params)
    actmgr.GetReady(function()
        uimanager.show("family.tabactivity", params)
    end)
end

local function RefreshBoss(uilistitem)
    local UILabel_LevelLimit = uilistitem.Controls["UILabel_LevelLimit"]
    local UILabel_Lock = uilistitem.Controls["UILabel_Lock"]
    local UILabel_Open = uilistitem.Controls["UILabel_Open"]
    local UISprite_Warning = uilistitem.Controls["UISprite_Warning"]
    if UISprite_Warning then
        UISprite_Warning.gameObject:SetActive(FamilyBossMgr.UnRead())
    end
    
    UILabel_Lock.gameObject:SetActive(true)
    UILabel_Open.gameObject:SetActive(false)
    UILabel_LevelLimit.gameObject:SetActive(false)
    UILabel_Lock.text = LocalString.Family_Boss_Not_Open
    --[[
    local bossTimeCfg  = configmanager.getConfig("bossconfig")
    if bossTimeCfg and FamilyBossInfo.GetBossChallengeTime()>0 and FamilyBossInfo.GetBossChallengeTime()< bossTimeCfg.battletime then  --challenge time
        UILabel_Lock.gameObject:SetActive(false)
        UILabel_Open.gameObject:SetActive(true)
        UILabel_LevelLimit.gameObject:SetActive(false)

        local challengecountdown = math.ceil(FamilyBossInfo.GetBossChallengeTime())
        UILabel_Open.text = timeutils.getDateTimeString(challengecountdown,"hh:mm:ss")..LocalString.Family_Boss_Countdown_Challenge
    elseif FamilyBossInfo.GetBossOpenTime()>0 then  --opentime
        UILabel_Lock.gameObject:SetActive(false)
        UILabel_Open.gameObject:SetActive(true)
        UILabel_LevelLimit.gameObject:SetActive(false)

        local opencountdown = math.ceil(FamilyBossInfo.GetBossOpenTime())
        UILabel_Open.text = timeutils.getDateTimeString(opencountdown,"hh:mm:ss")..LocalString.Family_Boss_Countdown_Open
    else
        UILabel_Lock.gameObject:SetActive(true)
        UILabel_Open.gameObject:SetActive(false)
        UILabel_LevelLimit.gameObject:SetActive(false)

        UILabel_Lock.text = LocalString.Family_Boss_Not_Open
    end
    --]]
end

local function RefreshItem()
    for i = 1,fields.UIList_Buttons.Count do
        local item = fields.UIList_Buttons:GetItemByIndex(i-1)
        if item.name == ButtonNames.Mission then
            --item:SetText("UILabel_MissionCountNum", taskmanager.GetWeekFinishedFamilyTaskCount().."/"..taskmanager.GetWeekSpecialRewardFamilyTaskCount())            
            item:SetText("UILabel_MissionCountNum", taskmanager.GetWeekFinishedFamilyTaskCount())            
            local UIProgressBar_Times = item.Controls["UIProgressBar_BackGround"]
            UIProgressBar_Times.value = taskmanager.GetWeekFinishedFamilyTaskCount() / taskmanager.GetWeekSpecialRewardFamilyTaskCount()
            local hostPlayerLevel = PlayerRole:Instance().m_Level
            item.Controls["UILabel_Discription"].gameObject:SetActive(hostPlayerLevel>=30)
            item.Controls["UILabel_LevelLimit"].gameObject:SetActive(hostPlayerLevel<30)

        elseif item.name == ButtonNames.Pray then
            local praymgr = require("family.praymanager")
            item.Controls["UISprite_Warning"].gameObject:SetActive(praymgr.CanJinbiPray())
            --[[local info = familymgr.Info()
            local leveldata = configmanager.getConfigData("familyinfo", info.flevel)
            item:SetText("UILabel_MissionCountNum", info.curlvlbuilddegree.."/"..leveldata.requirebuildrate)  
            local UIProgressBar_Times = item.Controls["UIProgressBar_BackGround"]
            UIProgressBar_Times.value = info.curlvlbuilddegree / leveldata.requirebuildrate]]

        elseif item.name == ButtonNames.Boss then            
            RefreshBoss(item)
        elseif item.name == ButtonNames.HomeLand then             
            --[[local partyInfo = configmanager.getConfig("familyparty")
            if (timeutils.GetServerTime() - partymgr.GetLastOpenTime()) < partyInfo.duration then
                item.Controls["UILabel_Opening"].gameObject:SetActive(true)
                item.Controls["UILabel_Open"].gameObject:SetActive(false)
                item.Controls["UILabel_Lock"].gameObject:SetActive(false)
            else     
                item.Controls["UILabel_Opening"].gameObject:SetActive(false)
                local bInOpenTime = partymgr.IsInOpenTime()
                item.Controls["UILabel_Open"].gameObject:SetActive(bInOpenTime)
                item.Controls["UILabel_Lock"].gameObject:SetActive(not bInOpenTime)  
            end]]
            item.Controls["UISprite_Warning"].gameObject:SetActive(partymgr.IsInOpenTime() and not partymgr.IsTodayOpened())

        elseif item.name == ButtonNames.LuckyStar then
            local bInOpenTime = familymgr.IsInBlackMarketTime()              
            item.Controls["UISprite_Warning"].gameObject:SetActive(bInOpenTime)

        elseif item.name == ButtonNames.Ectype then
            item.Controls["UISprite_Warning"].gameObject:SetActive(actmgr.HasFamilyEctypeTimes())    
        elseif item.name == ButtonNames.Battle then
            item.Controls["UISprite_Warning"].gameObject:SetActive(warmanager.UnRead())                
        end
    end   
end

local function show()
    familymgr.CheckAllFamilyDlgHide()
    RefreshItem()
end

-- local function hidetab()
-- end

local function hide()
end

local function destroy()
end

local function refresh(params)
end

-- local function update()
-- end
local function OnFamilyPrayClicked()   
    uimanager.show("family.tabpray")
end

local function OnFamilyBossClicked()
    uimanager.show("family.boss.dlgfamilyboss")
end

local function OnFamilyStationClicked()
    uimanager.ShowAlertDlg({
        title        = LocalString.Family.Party.Title, 
        content      = LocalString.Family.Party.PartyEnter,        
        callBackFunc = function()
            uimanager.hidedialog("family.dlgfamily")
			uimanager.hidecurrentdialog()--在家族聚会副本的时候活跃界面跟家族聚会的界面重叠
            familymgr.CEnterFamilyStation(familymgr.EnterType.PartyManagerNPC, function() uimanager.show("family.dlgbanquet") end)           
        end,
        immediate = true,
    })
end

local function OnFamilyMissionClicked()
    if PlayerRole:Instance().m_Level >= 30 then
        --local familymgr = require("family.familymanager")
        --familymgr.CEnterFamilyStation(familymgr.EnterType.FamilyTaskNPC)
        uimanager.hidedialog("family.dlgfamily")
        uimanager.showdialog("dlgtask", {isShowFamilyInfo = true})
    end   
end 

local function OnFamilyLuckyStarClicked()
    --if familymgr.IsInBlackMarketTime() then
        uimanager.ShowAlertDlg({
            title        = LocalString.Family.Party.TitleLucky, 
            content      = LocalString.Family.Party.LuckyEnter,        
            callBackFunc = function()
                uimanager.hidedialog("family.dlgfamily")
                uimanager.showdialog("dlgshop_common",nil,3) 
                -- familymgr.CEnterFamilyStation(familymgr.EnterType.BlackMarketNPC, function() 
                --     local bInOpenTime = true --策划要求改为全天开放  familymgr.IsInBlackMarketTime()
                --     if bInOpenTime then
                --         uimanager.showdialog("dlgshop_common",nil,3) 
                --     end                   
                -- end)
            end,
            immediate = true,
        })
    --end   
end

local function OnFamilyEctypeClicked()
    uimanager.show("family.dlgfamilyactivities") 
end

local function OnFamilyBattleClicked()
    local warmanager = require("family.warmanager")
    warmanager.OpenAboutWarDlg()
end

local function OnFamilyCupWarClicked()
    uimanager.showdialog("family.dlgfamilycupwar")
end

local function InitItemTimeLabel()
    for i = 1,fields.UIList_Buttons.Count do
        local item = fields.UIList_Buttons:GetItemByIndex(i-1)
        if item.name == ButtonNames.Mission then ---家族环

        elseif item.name == ButtonNames.Pray then  ----烧香 

        elseif item.name == ButtonNames.Boss then  --神兽
            RefreshBoss(item)
        elseif item.name == ButtonNames.HomeLand then    ---聚宴        
            local partyInfo = configmanager.getConfig("familyparty")
            item:SetText("UILabel_MissionCount", string.format(LocalString.Family.Party.ActivityTime,
                partyInfo.starttime[1],partyInfo.starttime[2], partyInfo.endtime[1], partyInfo.endtime[2])) 
            item:SetText("UILabel_MissionCountNum", string.format(LocalString.Family.Party.ActivityTime,
                partyInfo.starttime2[1],partyInfo.starttime2[2], partyInfo.endtime2[1], partyInfo.endtime2[2]))   
        
        elseif item.name == ButtonNames.LuckyStar then ---仙府游商
            local blackmarketInfo = configmanager.getConfig("blackmarket")
            item:SetText("UILabel_MissionCount", string.format(LocalString.Family.Party.ActivityTime,
                blackmarketInfo.opentime[1].begintime.hour, blackmarketInfo.opentime[1].begintime.minute, 
                blackmarketInfo.opentime[1].endtime.hour,   blackmarketInfo.opentime[1].endtime.minute)) 
            item:SetText("UILabel_MissionCountNum", string.format(LocalString.Family.Party.ActivityTime,
                blackmarketInfo.opentime[2].begintime.hour, blackmarketInfo.opentime[2].begintime.minute, 
                blackmarketInfo.opentime[2].endtime.hour,   blackmarketInfo.opentime[2].endtime.minute)) 

        elseif item.name == ButtonNames.Ectype then ---四灵降世

        elseif item.name == ButtonNames.Battle then --约战

        elseif item.name == ButtonNames.Cupwar then --循环赛

        end        
    end
end

local function OnListItemClicked(uiListItem)
    if uiListItem then
        if uiListItem.name == ButtonNames.Mission then
            OnFamilyMissionClicked()
        elseif uiListItem.name == ButtonNames.Pray then
            OnFamilyPrayClicked()
        elseif uiListItem.name == ButtonNames.Boss then
            OnFamilyBossClicked()
        elseif uiListItem.name == ButtonNames.HomeLand then
            OnFamilyStationClicked()
        elseif uiListItem.name == ButtonNames.LuckyStar then
            OnFamilyLuckyStarClicked()
        elseif uiListItem.name == ButtonNames.Ectype then
            OnFamilyEctypeClicked()
        elseif uiListItem.name == ButtonNames.Battle then
            OnFamilyBattleClicked()
        elseif uiListItem.name == ButtonNames.CupWar then
            -- OnFamilyCupWarClicked()
        end
    end
end

local function init(params)
    FamilyBossMgr = require("ui.family.boss.familybossmanager")
    name, gameObject, fields = unpack(params)
    InitItemTimeLabel()

    EventHelper.SetListClick(fields.UIList_Buttons, OnListItemClicked)
end

local function uishowtype()
    return UIShowType.Refresh
end

local function second_update(now)      
    RefreshItem()
end

return {
    showtab      = showtab,
    show         = show,
    hide         = hide,
    refresh      = refresh,
    destory      = destory,
    init         = init,
    uishowtype   = uishowtype,
    second_update= second_update,
}
