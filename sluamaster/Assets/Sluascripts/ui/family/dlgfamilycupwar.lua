local Unpack = unpack
local Format = string.format
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local FamilyManager = require("family.familymanager")
local FamilyRoundRobinManager = require("family.familyroundrobinmanager")
local BonusManager = require("item.bonusmanager")
local ItemManager = require("item.itemmanager")
local PlayerRole = require("character.playerrole"):Instance()
local DefineEnum = require("defineenum")

local m_Fields
local m_Name
local m_GameObject
local m_CurrentType = 1
local m_Group = nil
local m_AllContributionList = {}

local function SetCurrentPanel()
    m_Fields.UIScrollView_WarSchedule.gameObject:SetActive(m_CurrentType == 1)
    m_Fields.UIGroup_FamilyList.gameObject:SetActive(m_CurrentType == 2)
    m_Fields.UIScrollView_MVP.gameObject:SetActive(m_CurrentType == 3)
    m_Fields.UIScrollView_AllPlayerList.gameObject:SetActive(m_CurrentType == 4)
    m_Fields.UIButton_RewardFamily.gameObject:SetActive(m_CurrentType == 2)
    m_Fields.UIButton_RewardPlayer.gameObject:SetActive((m_CurrentType == 2) or (m_CurrentType == 4))
    m_Fields.UILabel_HistoryResultTitle.gameObject:SetActive((m_CurrentType == 3) or (m_CurrentType == 4))
end

---------------------
--对阵表
---------------------
local function DisplayWarSchedule()
    m_CurrentType = 1 
    SetCurrentPanel()
    m_Fields.UIList_WarSchedule:Clear()
    local groupType = FamilyRoundRobinManager.GetOwnGroup()
    local scheduleList = FamilyRoundRobinManager.GetSchedule()
    if scheduleList then
        for time,game in pairs(scheduleList) do
            local listItem = m_Fields.UIList_WarSchedule:AddListItem()
            listItem.Controls["UILabel_Group"].text = LocalString.FamilyRoundRobin_GroupType[groupType]   --分组
            listItem.Controls["UILabel_Time"].text = FamilyRoundRobinManager.GetBattleTime(time)    --时间
            
            local result = game.result
            local UIButton_Enter = listItem.Controls["UIButton_Enter"]
            local UILabel_Result = listItem.Controls["UILabel_Result"]
            if (result ~= -2) then
                if (game.family1info.fid) ~= (FamilyManager.Info().familyid) then
                    result = -result
                end
                UILabel_Result.text = LocalString.FamilyRoundRobin_Result[result]
                UIButton_Enter.gameObject:SetActive(false)
                UILabel_Result.gameObject:SetActive(true)
            else
                UIButton_Enter.gameObject:SetActive(true)
                UILabel_Result.gameObject:SetActive(false)
                if (FamilyRoundRobinManager.IsInActivityTime(time)) then
                    UIButton_Enter.isEnabled = true
                    listItem.Controls["UILabel_Enter"].text = LocalString.FamilyRoundRobin_EnterBattle
                    EventHelper.SetClick(UIButton_Enter,function()
                        FamilyRoundRobinManager.SetCurGame(game)
                        FamilyRoundRobinManager.SendCGetFamilyRoundMatchStatus()
                    end)
                else
                    UIButton_Enter.isEnabled = false
                    listItem.Controls["UILabel_Enter"].text = LocalString.FamilyRoundRobin_NotOpen
                end
            end  
            listItem.Controls["UILabel_FamilyName1"].text = FamilyManager.Info().familyname  --本家族名称      
            listItem.Controls["UILabel_Level1"].text = Format(LocalString.Family_Boss_Level,FamilyManager.Info().flevel) --本家族等级
            if (FamilyManager.Info().familyid) == game.family1info.fid then                              
                if (game.family2info.fid ~= 0) then
                    listItem.Controls["UILabel_FamilyName2"].text = game.family2info.familyname  --对阵家族名称
                    listItem.Controls["UILabel_Level2"].text = Format(LocalString.Family_Boss_Level,game.family2info.familylvl)  --对阵家族名称
                else
                    listItem.Controls["UILabel_FamilyName2"].text = LocalString.City_War_Invest_None  --无
                    listItem.Controls["UILabel_Level2"].text = ""
                    UIButton_Enter.gameObject:SetActive(false)
                    UILabel_Result.gameObject:SetActive(false)
                end
            else
                if (game.family1info.fid ~= 0) then
                    listItem.Controls["UILabel_FamilyName2"].text = game.family1info.familyname  --对阵家族名称
                    listItem.Controls["UILabel_Level2"].text = Format(LocalString.Family_Boss_Level,game.family1info.familylvl)  --对阵家族名称
                else
                    listItem.Controls["UILabel_FamilyName2"].text = LocalString.City_War_Invest_None  --无
                    listItem.Controls["UILabel_Level2"].text = ""
                    UIButton_Enter.gameObject:SetActive(false)
                    UILabel_Result.gameObject:SetActive(false)
                end
            end
        end
    end
end

local function RefreshGroup(group)
    if m_Group and (m_Group == group) then
        return
    end
    if group == nil then
       group = FamilyRoundRobinManager.GetOwnGroup() 
    end
    m_Group = group
    local rankList = FamilyRoundRobinManager.GetRankListByGroup(group)
    for i = 0,5 do      
        local listItem = m_Fields.UIList_WarList:GetItemByIndex(i)
        if rankList and rankList.rankinfo and rankList.rankinfo[i + 1] then
            local familyInfo = rankList.rankinfo[i + 1]
            listItem.gameObject:SetActive(true)
            listItem.Controls["UILabel_FamilyName"].text = familyInfo.familyname
            listItem.Controls["UILabel_Level"].text = Format(LocalString.Family_Boss_Level,familyInfo.familylvl)
            listItem.Controls["UILabel_Record"].text = Format(LocalString.FamilyRoundRobin_Record,familyInfo.win,familyInfo.lose,familyInfo.draw)
            listItem.Controls["UILabel_TotalRecord"].text = Format(LocalString.FamilyRoundRobin_TotalRecord,familyInfo.score)
        else
            listItem.gameObject:SetActive(false)
        end 
    end
end

local function DisplayRewards(type,rewardFields)
    local rewardList = FamilyRoundRobinManager.GetRankBonus()
    for _,reward in pairs(rewardList) do
        local listItem = rewardFields.UIList_RewardGroups:AddListItem()
        local detailReward
        if type == 1 then
            detailReward = reward.award1
        elseif type == 2 then
            detailReward = reward.award2
        end
		local rank = ((reward.id -1) % 6) + 1
        listItem.Controls["UILabel_Line1"].text = Format(LocalString.FamilyRoundRobin_Rank[math.floor((reward.id - 1) / 6) + 1],rank)
        local items = BonusManager.GetMultiBonusItems(detailReward)
        listItem.Controls["UILabel_Diamond"].text = 0
        listItem.Controls["UILabel_Gold"].text = 0
        listItem.Controls["UILabel_BindingDiamond"].text = 0
        for _,item in pairs(items) do
            local id = item:GetId()
            if id == cfg.currency.CurrencyType.YuanBao then
                listItem.Controls["UILabel_Diamond"].text = item:GetNum()
            elseif id == cfg.currency.CurrencyType.XuNiBi then
                listItem.Controls["UILabel_Gold"].text = item:GetNum()
            elseif id == cfg.currency.CurrencyType.BindYuanBao then
                listItem.Controls["UILabel_BindingDiamond"].text = item:GetNum()
            else
                local rewardListItem = listItem.Controls["UIList_Rewards"]:AddListItem()
                BonusManager.SetRewardItem(rewardListItem,item)
                rewardListItem.Controls["UILabel_ItemName"].text = item:GetName()
            end            
        end
    end
end

local function DisplayBaseBonus(params,rewardFields)
    DisplayRewards(1,rewardFields)
    rewardFields.UILabel_Title.text = LocalString.FamilyRoundRobin_RankBaseRewards
end

local function CheckDistributionLog()
    UIManager.show("citywar.tabworldterritoryrewarddistribution",{type = DefineEnum.RewardDistributionType.RoundRobin})
end

local function DisplayExtraBonus(params,rewardFields) 
    DisplayRewards(2,rewardFields)
    rewardFields.UILabel_Title.text = LocalString.FamilyRoundRobin_RankExtraRewards
    
    rewardFields.UIButton_Check.gameObject:SetActive(true)
    
    if (FamilyRoundRobinManager.HasRemainFamilyRoundRobinBonus() == true) and (FamilyManager.IsChief()) then
		    rewardFields.UIButton_Assign.gameObject:SetActive(true)
        rewardFields.UIButton_Assign.isEnabled = true
        EventHelper.SetClick(rewardFields.UIButton_Assign,function()
            UIManager.hide("common.dlgdialogbox_reward")
            UIManager.show("citywar.tabrewarddistribution",{type = DefineEnum.RewardDistributionType.RoundRobin,logBtn_callback = CheckDistributionLog})
        end)
	  else
		    rewardFields.UIButton_Assign.gameObject:SetActive(false)
    end
    EventHelper.SetClick(rewardFields.UIButton_Check,function()
        UIManager.hide("common.dlgdialogbox_reward")
        CheckDistributionLog()
    end)
end

---------------------
--排名
---------------------
local function DisplayRank()
    m_CurrentType = 2
    SetCurrentPanel()
    RefreshGroup() 
    m_Fields.UITexture_RankBG:SetIconTexture("Background_RoundRobin")  
    EventHelper.SetClick(m_Fields.UIToggle_GroupA,function()
        RefreshGroup(1)
    end)
    EventHelper.SetClick(m_Fields.UIToggle_GroupB,function()
        RefreshGroup(2)
    end)
    EventHelper.SetClick(m_Fields.UIToggle_GroupC,function()
        RefreshGroup(3)
    end)
    EventHelper.SetClick(m_Fields.UIToggle_GroupD,function()
        RefreshGroup(4)
    end)
    m_Fields.UILabel_RewardFamily.text = LocalString.FamilyRoundRobin_BaseBonus
    m_Fields.UILabel_RewardPlayer.text = LocalString.FamilyRoundRobin_ExtraBonus
    EventHelper.SetClick(m_Fields.UIButton_RewardFamily,function()
        UIManager.show("common.dlgdialogbox_reward",{type = 0,callBackFunc = DisplayBaseBonus})
    end)
    EventHelper.SetClick(m_Fields.UIButton_RewardPlayer,function()
        UIManager.show("common.dlgdialogbox_reward",{type = 0,callBackFunc = DisplayExtraBonus})
    end)
end

---------------------
--成员贡献
---------------------
local function DisplayMVPList()
    m_CurrentType = 3
    SetCurrentPanel()
    m_Fields.UIList_MVP:Clear()
    local familyContributionList = FamilyRoundRobinManager.GetFamilyContributionList()
    local ownRank = 0
    local i = 0
    if familyContributionList then
        for _,member in pairs(familyContributionList) do
            local listItem = m_Fields.UIList_MVP:AddListItem()
            i = i + 1
            listItem.Controls["UILabel_PlayerRank1"].text = i
            local TeamManager = require("ui.team.teammanager")
            local headIcon = TeamManager.GetHeadIcon(member.profession,member.gender)
            listItem.Controls["UITexture_Head"]:SetIconTexture(headIcon)
            listItem.Controls["UILabel_LV"].text = member.level
            listItem.Controls["UILabel_Fight"].text = member.combatpower
            listItem.Controls["UILabel_Name"].text = member.rolename
            listItem.Controls["UILabel_Contribution"].text = Format(LocalString.FamilyRoundRobin_HurtAndHeal,member.contribute)
            listItem.Controls["UISprite_Me"].gameObject:SetActive(member.roleid == PlayerRole:GetId())
            EventHelper.SetClick(listItem.Controls["UIButton_Check"],function()  
                UIManager.showdialog("otherplayer.dlgotherroledetails", {roleId = member.roleid})
            end)
            if (member.roleid == PlayerRole:GetId()) then
                ownRank = i
            end
        end
    end
    if ownRank == 0 then
        ownRank = i + 1
    end
    m_Fields.UILabel_HistoryResultTitle.text = Format(LocalString.FamilyRoundRobin_FamilyRank,ownRank)
end

local function DisplayPersonalReward(params,rewardFields)
    rewardFields.UILabel_Title.text = LocalString.FamilyRoundRobin_PersonalRewards
    local rewardList = FamilyRoundRobinManager.GetPersonalRewardList()
    for _,reward in pairs(rewardList) do
        local listItem = rewardFields.UIList_RewardGroups:AddListItem()   
        listItem.Controls["UILabel_Line1"].text = Format(LocalString.FamilyRoundRobin_AllRank,reward.id) 
        local items = BonusManager.GetMultiBonusItems(reward.bonus)
        listItem.Controls["UILabel_Diamond"].text = 0
        listItem.Controls["UILabel_Gold"].text = 0
        listItem.Controls["UILabel_BindingDiamond"].text = 0
        for _,item in pairs(items) do
            local id = item:GetId()
            if id == cfg.currency.CurrencyType.YuanBao then
                listItem.Controls["UILabel_Diamond"].text = item:GetNum()
            elseif id == cfg.currency.CurrencyType.XuNiBi then
                listItem.Controls["UILabel_Gold"].text = item:GetNum()
            elseif id == cfg.currency.CurrencyType.BindYuanBao then
                listItem.Controls["UILabel_BindingDiamond"].text = item:GetNum()
            else
                local rewardListItem = listItem.Controls["UIList_Rewards"]:AddListItem()
                BonusManager.SetRewardItem(rewardListItem,item)
                rewardListItem.Controls["UILabel_ItemName"].text = item:GetName()
            end            
        end
    end
end

---------------------
--全服个人贡献
---------------------
local function OnItemInit(UIListItem,wrapIndex,realIndex)
    if UIListItem == nil then
        return
    end
    local member = m_AllContributionList[realIndex]
    if UIListItem then
        UIListItem.Controls["UILabel_FamilyName"].text = member.fname
        UIListItem.Controls["UILabel_Level"].text = Format(LocalString.Family_Boss_Level,member.flevel)
        UIListItem.Controls["UILabel_PlayerName"].text = member.rolename
        UIListItem.Controls["UILabel_PlayerRank"].text = realIndex
        UIListItem.Controls["UILabel_Record"].text = Format(LocalString.FamilyRoundRobin_Contribution,member.contribute)
    end
end

local function InitList(num,refreshIndex)
    local wrapList = m_Fields.UIList_AllPlayerList:GetComponent("UIWrapContentList")
    if wrapList == nil then
        return
    end
    EventHelper.SetWrapListRefresh(wrapList,OnItemInit)
    wrapList:SetDataCount(num)
end

local function DisplayFamilyList()
    m_CurrentType = 4
    SetCurrentPanel()
    local num = 0
    m_AllContributionList = FamilyRoundRobinManager.GetAllContributionList()
    if m_AllContributionList then
        num = #m_AllContributionList
    end
    InitList(num,0)
    m_Fields.UILabel_RewardPlayer.text = LocalString.FamilyRoundRobin_PersonalBonus
    EventHelper.SetClick(m_Fields.UIButton_RewardPlayer,function()
         UIManager.show("common.dlgdialogbox_reward",{type = 0,callBackFunc = DisplayPersonalReward})
    end)
end

local function destroy()
end

local function hide()
end

local function show()
end

local function refresh()
    DisplayWarSchedule()
end

local function DisplayHelp(params,helpFields)
    helpFields.UILabel_Content_Single.text = params.msg
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)
    EventHelper.SetClick(m_Fields.UIToggle_WarSchedule,DisplayWarSchedule)
    EventHelper.SetClick(m_Fields.UIToggle_Rank,DisplayRank)
    EventHelper.SetClick(m_Fields.UIToggle_MVPList,DisplayMVPList)
    EventHelper.SetClick(m_Fields.UIToggle_FamilyList,DisplayFamilyList)
    EventHelper.SetClick(m_Fields.UIButton_Details,function()
        local params = {}
        params.msg = FamilyRoundRobinManager.GetRuleByType(m_CurrentType)     
        params.type = 2
        params.callBackFunc = DisplayHelp
        UIManager.show("common.dlgdialogbox_complex", params)
    end)
    
end


return
{
    init = init,
    show = show,
    hide = hide,
    refresh = refresh,
    destroy = destroy,
}