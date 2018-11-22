local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local ItemManager = require("item.itemmanager")
local BonusManager=require("item.bonusmanager")
local TeamManager = require("ui.team.teammanager")
local PlayerRole = require("character.playerrole")
local LimitManager=require("limittimemanager")

local gameObject
local name
local fields

local function destroy()
end

local function show(params)
end

local function hide()
end

local function refresh(params)   
    local useTime = 0
    local limit = nil
    limit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.FAMILY_TEAM_ECTYPE,0)
    if limit then
        useTime=limit[cfg.cmd.condition.LimitType.DAY]
    end
    local familyteamConfig = ConfigManager.getConfig("familyteam")
    local enterTime = familyteamConfig.rewardfinishnum.num
    local remainTime=enterTime-useTime
    if remainTime>0 then
        fields.UILabel_Times.text=string.format(LocalString.Ectype_RemainChallengeTime,remainTime,enterTime)
    else
        fields.UILabel_Times.text=string.format(LocalString.Ectype_ChallengeTime,remainTime,enterTime)
    end  
end

local function update()
end

local function init(params)
    name, gameObject, fields = unpack(params)
    local familyteamConfig = ConfigManager.getConfig("familyteam")

    local rewardList = familyteamConfig.showrewards.items  --����item��ģ��չʾ���佱������
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Icon, #rewardList)
    for i = 1,#rewardList do
        local rewardsItem = ItemManager.CreateItemBaseById(rewardList[i])
        local item = fields.UIList_Icon:GetItemByIndex(i-1)
        BonusManager.SetRewardItem(item,rewardsItem,{notShowAmount = true})
    end

    if TeamManager.IsInTeam() then
        fields.UILabel_OthersName.text = TeamManager.GetAverageLevel()
    else
        fields.UILabel_OthersName.text = PlayerRole:Instance().m_Level
    end

    EventHelper.SetClick(fields.UIButton_Close, function()
        uimanager.hide("family.dlgfamilyactivities")
    end)

    EventHelper.SetClick(fields.UIButton_Extract, function()
        if TeamManager.IsInTeam() then
            if TeamManager.IsLeader(PlayerRole:Instance().m_Id) then
                --if TeamManager.IsInSameFamily() then
                    if TeamManager.GetTeamMemberNum() < familyteamConfig.minteammembernum then
                        uimanager.ShowSingleAlertDlg({content=LocalString.Family.FamilyEctypeNeedTwoMore})
                    else
                        local familyactmgr = require("family.activitymanager")
                        familyactmgr.OpenFamilyTeamEctype()
                    end                    
                --else
                    --uimanager.ShowSingleAlertDlg({content=LocalString.Family.FamilyEctypeTeamSame})
                --end
            else
                uimanager.ShowSingleAlertDlg({content=LocalString.Family.FamilyEctypeNeedLeader})
            end
        else
            uimanager.ShowSingleAlertDlg({content=LocalString.Family.FamilyEctypeNeedTeam})
        end
    end )
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
