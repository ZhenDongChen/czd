local unpack, print 	= unpack, print
local UIManager 	    = require "uimanager"
local ArenaManager      = require"ui.arena.single.arenamanager"
local CharacterManager  = require("character.charactermanager")
local ConfigManager     = require("cfg.configmanager")
local CharacterFactory  = require("character.factory.factory")
local CameraManager     = require("cameramanager")
local EventHelper 	    = UIEventListenerHelper
local ArenaData         = ArenaManager.ArenaData

local name
local gameObject
local fields
local opponentPlayers = {}



local function RefreshOpponentInfo(item,opponentInfo,index)

    item:SetText("UILabel_Rank",opponentInfo.m_Rank)
--    item:SetText("UILabel_ReputationDetal",opponentInfo.m_ReputationDetal)
    item:SetText("UILabel_Name",opponentInfo.m_Name)
    item:SetText("UILabel_Level",opponentInfo.m_Level)
    item:SetText("UILabel_Power",opponentInfo.m_Power)
    item:SetText("UILabel_ReputationDetal",ArenaManager.GetReputationIncrease(opponentInfo.m_Rank))

    if opponentPlayers[index] == nil or (opponentPlayers[index] ~= nil and opponentPlayers[index]:GetId() ~= opponentInfo.m_Id) then
        if opponentPlayers[index] then
            opponentPlayers[index]:release()
        end
        local rolePublicInfo = {    roleid      = opponentInfo.m_Id,
                                    profession  = opponentInfo.m_Profession,
                                    gender      = opponentInfo.m_Gender,
                                    dressid     = opponentInfo.m_DressId,
                                    equips      = opponentInfo.m_Equips,
                                }
        opponentPlayers[index] = CharacterManager.GetPlayerForUI(rolePublicInfo, function(player,object)
            object.transform.parent = item.gameObject.transform
            object.transform.localPosition = Vector3(150,-400,300)
            object.transform.localRotation = Quaternion.Euler(-90,0,0)
            player:SetUIScale(220)
            --object.transform.localScale = Vector3(240,240,240)
            
            object:SetActive(true)
            UIManager.refresh("arena.single.dlgarenaprapare")
        end)
    end
    local UIButton_Role = item.Controls["UIButton_Role"]

    EventHelper.SetClick(UIButton_Role, function ()
        ArenaData.CurrentOpponent = opponentInfo
        UIManager.showdialog("arena.single.dlgarenaprapare")
	end)
end
local function ResetRedDot()
    local dlgAchievementTitle = require("ui.title.dlgachievementtitle")
    local titleUnRead = dlgAchievementTitle.UnRead(cfg.achievement.AchievementType.ARENATITLE)
    fields.UISprite_TitleWarning.gameObject:SetActive(titleUnRead)
    fields.UISprite_Warning.gameObject:SetActive(ArenaManager.CanObtainDailyReward())
end
local function refresh(params)

   -- for i, k in pairs(opponentPlayers) do
   --     if opponentPlayers[i] then
   --         opponentPlayers[i]:release()
   --         opponentPlayers[i] = nil
   --     end
   -- end
    local state = ArenaManager.GetPlayerInfo()
    fields.UILabel_Rank.text = ((state.m_Rank > 0) and state.m_Rank) or LocalString.NoneText
    fields.UILabel_Reputation.text = state.m_Reputation
    fields.UILabel_ReputationDetal.text = state.m_ReputationIncrease
    fields.UILabel_Times.text = (state.m_ChallengeNum-state.m_ChallengeCount) .. "/" .. state.m_ChallengeNum
    fields.UILabel_FreeTimes.text = LocalString.Arena.FreeTimes
    -- 刷新对手的费用
    fields.UILabel_Money.text = state.m_RefreshCurrency


    --PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.YuanBao)

    local opponentCount = #ArenaData.OpponentList
    --fields.UIList_Challenge:Clear()
    --printyellow("===>",opponentCount)
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Challenge,opponentCount)

    for i = 1, opponentCount do
        local uiItem = fields.UIList_Challenge:GetItemByIndex(i-1)
        if uiItem ~= nil then
            RefreshOpponentInfo(uiItem,ArenaData.OpponentList[i],i)
        end
    end
    
    
    --===================================================================
    
    ResetRedDot()
end



local function destroy()

end



local function show(params)
    for i, k in pairs(opponentPlayers) do
        opponentPlayers[i]:release()
        opponentPlayers[i] = nil
    end
    ArenaManager.GetChallenge()
end

local function hide()
    for i, k in pairs(opponentPlayers) do
        opponentPlayers[i]:release()
        opponentPlayers[i] = nil
    end

end

local function update()
    for i,player in pairs(opponentPlayers) do
        if player and player.m_Object then
            player.m_Avatar:Update()
        end
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)
    --战报
    EventHelper.SetClick(fields.UIButton_BattlefieldReport, function ()
        UIManager.show("arena.single.dlgarenafightreport")
    end)
    --特殊奖励
    EventHelper.SetClick(fields.UIButton_Rewards, function()
        UIManager.show("arena.single.dlgarenarewards")
	end)
    --商店
    EventHelper.SetClick(fields.UIButton_Store, function()
        UIManager.showdialog("dlgshop_common",nil,4)
	end)
    --排行
    EventHelper.SetClick(fields.UIButton_Ranking, function()
       -- UIManager.showdialog("rank.dlgranklist",{rankType = cfg.bonus.RankType.ARENA})
        UIManager.showdialog("rank.dlgarenarank")
	end)
    --刷新
    EventHelper.SetClick(fields.UIButton_Refresh, function()
        local state = ArenaManager.GetPlayerInfo()
        if state.m_RefreshCurrency > 0 then
            UIManager.ShowAlertDlg({
                immediate    = true,
                content      = string.format(LocalString.Arena.RefreshCostMoney,tostring(state.m_RefreshCurrency)),
                callBackFunc = function()
                    ArenaManager.RefreshChallenge()
                end,
                callBackFunc1 = function()
                end,   
            })
        else
            ArenaManager.RefreshChallenge()
        end
	end)
    --称号
    EventHelper.SetClick(fields.UIButton_Title, function()
        UIManager.show("title.dlgachievementtitle", { type = cfg.achievement.AchievementType.ARENATITLE })
    end)
    
end

local function uishowtype()
    return UIShowType.Refresh
end

local function UnRead()
    local rewardUnRead = ArenaManager.UnRead()
    local dlgAchievementTitle = require("ui.title.dlgachievementtitle")
    local titleUnRead = dlgAchievementTitle.UnRead(cfg.achievement.AchievementType.ARENATITLE)
    
    return rewardUnRead or titleUnRead
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    ResetRedDot = ResetRedDot,
    UnRead = UnRead,
}
