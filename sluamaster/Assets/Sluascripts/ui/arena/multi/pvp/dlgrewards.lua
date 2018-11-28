local PVPManager        = require("ui.arena.multi.pvp.pvpmanager")
local UIManager         = require("uimanager")
local EventHelper 	    = UIEventListenerHelper
local BonusManager      = require("item.bonusmanager")



local rewardItem = {}


local function RewardItemRefresh(uiItem,index,realIndex)
    local item = rewardItem[realIndex]

    uiItem:SetText("UILabel_ItemName", item:GetName())
    uiItem:SetText("UILabel_ItemIntroduce", item:GetIntroduction())
    BonusManager.SetRewardItem(uiItem, item, { notSetClick = true })
    
end




local function SetRewards(fields, bonus)
    --printyellow("Seettting Bonus")
    --printt(bonus)


    rewardItem = BonusManager.GetItemsByBonusConfig(bonus)

    local wrapList = fields.UIList_ItemShow.gameObject:GetComponent("UIWrapContentList")
    EventHelper.SetWrapListRefresh(wrapList,RewardItemRefresh)
    wrapList:SetDataCount(#rewardItem)
    wrapList:CenterOnIndex(-0.2)
end

local function SetTitle(fields)
    fields.UILabel_Title.text = LocalString.TeamFight.Rewards
end

local function HideUI()
    if UIManager.isshow("common.dlgdialogbox_reward") then
        UIManager.hide("common.dlgdialogbox_reward")
    end
end

local function SetButton(fields, mode, num, canGetReward, receivedReward)
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Button,1)
    local uiItem = fields.UIList_Button:GetItemByIndex(0)
    if uiItem then
        local uiButton = uiItem.gameObject:GetComponent("UIButton")
        if uiButton then            
            uiButton.isEnabled = (receivedReward == false and canGetReward)
            if mode == "DayRewards" then
                EventHelper.SetClick(uiButton, function()
                    --printyellow("DayRewards")
                    PVPManager.ObtainTeamFightDayReward()
                    HideUI()
                end)
            else
                EventHelper.SetClick(uiButton, function()
                    --printyellow("ScoreRewards")
                    PVPManager.ObtainTeamFightWeekReward(num)
                    HideUI()
                end)
            end
        end
        if receivedReward then
            uiItem:SetText("UILabel_ButtonName", LocalString.Common_Receive)
        else
            uiItem:SetText("UILabel_ButtonName", LocalString.Common_Receiving)
        end        
    end

end



local function showFunc(params,fields)
    --printyellow("Params",params.rewardsMode)
    --printt(params)
    
    
    local bonus
    
    if params.rewardsMode == "ScoreRewards" then
        local scoreBonus = PVPManager.GetScoreBonus()
        bonus = scoreBonus[params.rewardsNum].bonus
        --printyellow("ScoreBonus")
        
    else
        bonus = PVPManager.GetDayBonus()
        --printyellow("DayBonus")
    end
    
    SetTitle(fields)
    SetRewards(fields, bonus)
    SetButton(fields, params.rewardsMode, params.rewardsNum, params.canGetReward, params.receivedReward)
    
    
    
end


local function show(mode, num, canReceive, isReceived)
    UIManager.show( "common.dlgdialogbox_reward",
                    { type          = 1, 
                      callBackFunc  = showFunc, 
                      rewardsMode   = mode, 
                      rewardsNum    = num,
                      canGetReward  = canReceive, 
                      receivedReward = isReceived,
                      })
end


return {
    show = show,
}