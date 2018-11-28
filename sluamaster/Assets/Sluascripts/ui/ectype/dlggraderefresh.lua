local print, unpack = print, unpack
local EventHelper   = UIEventListenerHelper
local Network       = require("network") 
local UIManager     = require("uimanager")
local BonusManager  = require("item.bonusmanager")
local EctypeManager = require("ectype.ectypemanager")
local ConfigManager = require("cfg.configmanager")
local AudioManager  = require("audiomanager")

local fields, name, gameObject


local GroupId = nil
local EctypeId = nil
local EndCallBack = nil
local Result = true
local RemainingTime = 0

local TaskList = {}
local TotalTime = 0

--==================================================================================================
--[[显示结果：胜利或者失败]]
local function ShowResult(success)
    if success == true then
        fields.UIGroup_Success.gameObject:SetActive(true)
        fields.UIGroup_Failure.gameObject:SetActive(false)
    else
        fields.UIGroup_Success.gameObject:SetActive(false)
        fields.UIGroup_Failure.gameObject:SetActive(true)
    end

    fields.UIPlayTween_Result.gameObject:SetActive(true)
    fields.UIPlayTween_Result:Play(true)
    if success == true then
        if cfg.ectype.EctypeBasic.successaudioid ~= 0 then
            AudioManager.Play2dSound(cfg.ectype.EctypeBasic.successaudioid)
        end
    else
        if cfg.ectype.EctypeBasic.failedaudioid ~= 0 then
            AudioManager.Play2dSound(cfg.ectype.EctypeBasic.failedaudioid)
        end
    end
end
--==================================================================================================
--[[显示星星]]
local function ShowStar(star)
    fields.UISprite_Star_1.gameObject:SetActive(star>=1)
    fields.UISprite_Star_2.gameObject:SetActive(star>=2)
    fields.UISprite_Star_3.gameObject:SetActive(star>=3)
    
    fields.UIPlayTween_Star.gameObject:SetActive(true)
    fields.UIPlayTween_Star:Play(true)
end
--==================================================================================================
--[[显示文字]]
local function ShowText(text,timeStr)

    fields.UILabel_Text.text = text or ""

    if timeStr then
        fields.UILabel_ClearTime.gameObject:SetActive(true)
        fields.UILabel_Time.gameObject:SetActive(true)
        fields.UILabel_ClearTime.text = timeStr
    else
        fields.UILabel_Time.gameObject:SetActive(false)
        fields.UILabel_ClearTime.gameObject:SetActive(false)
    end
    
    fields.UIPlayTween_Lable.gameObject:SetActive(true)
    fields.UIPlayTween_Lable:Play(true)
end
--==================================================================================================
--[[显示奖励列表]]
local function ShowBonus(bonus)
    local JingYan = nil
    local XuNiBi = nil
    if bonus then
        if fields.UIGroup_Bonus then
            fields.UIGroup_Bonus.gameObject:SetActive(true)
        end
        local itemList = BonusManager.GetItemsOfServerBonus(bonus)
    --    printyellow("iiiii")
    --    printt(itemList)
        for i,item in pairs(itemList) do
            if item:GetConfigId() == cfg.currency.CurrencyType.XuNiBi then
                XuNiBi = item:GetNumber()
                itemList[i] = nil
            end
            if item:GetConfigId() == cfg.currency.CurrencyType.JingYan then
                JingYan = item:GetNumber()
                itemList[i] = nil
            end
        end
        local newList = {}
        for i,k in pairs(itemList) do
            table.insert(newList,k)
        end
        UIHelper.ResetItemNumberOfUIList(fields.UIList_Bonus,#newList)

        for ki = 1, #newList do
            if newList[ki] then
                local uiItem = fields.UIList_Bonus:GetItemByIndex(ki-1)
                BonusManager.SetRewardItem(uiItem, newList[ki])
            end
        end
    else
        fields.UIGroup_Bonus.gameObject:SetActive(false)
    end
    fields.UISprite_Money.gameObject:SetActive(true)
    fields.UISprite_EXP.gameObject:SetActive(true)
    fields.UILabel_Money.text = XuNiBi or 0
    fields.UILabel_EXP.text = JingYan or 0
    
    
    fields.UIPlayTween_Currency.gameObject:SetActive(true)
    fields.UIPlayTween_Currency:Play(true)
    fields.UIPlayTween_Award.gameObject:SetActive(true)
    fields.UIPlayTween_Award:Play(true)
end


--==================================================================================================
--[[显示花费金钱数量]]
local function ShowCostMoney(count)
    fields.UILabel_CostMoney.text = tostring(count)
    
    fields.UIPlayTween_RefreshRewards.gameObject:SetActive(true)
    fields.UIPlayTween_RefreshRewards:Play(true)
end

--==================================================================================================
--[[显示确定按钮]]

local function HeroRefreshAward(groupId, ectypeId)
    printyellowmodule(Local.LogModuals.HeroBook, "COpenHeroEctype",groupId, ectypeId)
    local re = lx.gs.map.msg.CHeroRefreshAward({groupid = groupId, ectypeid = ectypeId})
    Network.send(re)
end

local function HeroGainAward(groupId, ectypeId)
    printyellowmodule(Local.LogModuals.HeroBook, "HeroGainAward", groupId, ectypeId)
    local re = lx.gs.map.msg.CHeroGainAward({groupid = groupId, ectypeid = ectypeId})
    Network.send(re)
end

local function ShowButton(awardinfo)
    fields.UIButton_Sure01.gameObject:SetActive(true)
    EventHelper.SetClick(fields.UIButton_Sure01, function()
        if Result == true then
            HeroGainAward(GroupId, EctypeId)
        else
            if EndCallBack ~= nil then
                EndCallBack()
            end
        end
    end)
    
    fields.UIButton_Check.gameObject:SetActive(true)    
    EventHelper.SetClick(fields.UIButton_Check, function()
        HeroRefreshAward(GroupId, EctypeId)
    end)
    
    if awardinfo.leftrefreshcount > 0 then
        fields.UIButton_Check.isEnabled = true
        fields.UILabel_Times.text = tostring(awardinfo.leftrefreshcount)
    else
        fields.UIButton_Check.isEnabled = false
        fields.UILabel_Times.text = tostring(0)
    end
    
    fields.UIPlayTween_Button.gameObject:SetActive(true)
    fields.UIPlayTween_Button:Play(true)
    
end

local function ShowInfo(awardinfo)
    ShowCostMoney(awardinfo.refreshcost)
    fields.UILabel_CostMoney.text = tostring(awardinfo.refreshcost)
    
end




local function ShowRewards(awardinfo)
    ShowBonus(awardinfo.bonus)
    ShowInfo(awardinfo)  
end


local function OnMsgSHeroGainAward(msg)
    UIManager.hidedialog(name)
    if EndCallBack ~= nil then
        EndCallBack()
    end
end

local function OnMsgSHeroRefreshAward(msg)
    printyellowmodule(Local.LogModuals.HeroBook, msg)
    RemainingTime = RemainingTime - 1
    if RemainingTime < 0 then
        RemainingTime = 0
    end
    ShowRewards(msg.awardinfo)
    ShowButton(msg.awardinfo)
end

local function Reset()
    TaskList = {}
    TotalTime = 0
    fields.UIPlayTween_Result.gameObject:SetActive(false)
    fields.UIPlayTween_Star.gameObject:SetActive(false)
    fields.UIPlayTween_Lable.gameObject:SetActive(false)
    fields.UIPlayTween_Currency.gameObject:SetActive(false)
    fields.UIPlayTween_Award.gameObject:SetActive(false)
    fields.UIPlayTween_RefreshRewards.gameObject:SetActive(false)
    fields.UIPlayTween_Button.gameObject:SetActive(false)
end

local function AddTask(time, func)
    table.insert( TaskList, {m_Time = TotalTime, m_Execute = func } )
    TotalTime = time
end
--====================================================================
local function refresh(params)
    ShowRewards(params.awardinfo)
end

local function update()
    local currentTask = TaskList[1]
    if currentTask ~= nil then
        currentTask.m_Time = currentTask.m_Time - Time.deltaTime
        if currentTask.m_Time <= 0 then
            currentTask.m_Execute()
            table.remove( TaskList, 1 )
        end
    end
end

local function show(params)
    GroupId = params.groupid
    EctypeId = params.ectypeid
    EndCallBack = params.callback
    Result = params.result
    Reset()
    local gradeTimeCfg = ConfigManager.getConfig("ectypegrade")
        
    local time_result = 0
    local time_bonus = 0
    local time_button = 0

    if gradeTimeCfg then
        time_result = gradeTimeCfg["showresult"].time
        time_bonus = gradeTimeCfg["showbonus"].time 
        time_button = gradeTimeCfg["showbutton"].time 
    end

    AddTask(time_result, function() ShowResult(params.result) end)
    AddTask(time_bonus, function() ShowRewards(params.awardinfo) end)
    AddTask(time_button, function() ShowButton(params.awardinfo) end)
    
    
    
    RemainingTime = params.refreshtimes - 1
end

local function init(params)
    name, gameObject, fields = unpack(params)
    
    Network.add_listeners( {
           { "lx.gs.map.msg.SHeroRefreshAward", OnMsgSHeroRefreshAward },
           { "lx.gs.map.msg.SHeroGainAward", OnMsgSHeroGainAward}
        })
end

local function destroy()

end

local function hide()

end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
 --   showdialog = showdialog,
}
