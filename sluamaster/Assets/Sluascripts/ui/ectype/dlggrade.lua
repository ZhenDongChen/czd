local print         = print
local unpack        = unpack
local EventHelper   = UIEventListenerHelper
local UIManager     = require("uimanager")
local BonusManager  = require("item.bonusmanager")
local EctypeManager = require "ectype.ectypemanager"
local ConfigManager = require "cfg.configmanager"
local AudioManager  = require("audiomanager")
local fields
local name
local gameObject

--local DelayTime = 0
--local ParamSave = nil
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
        fields.UIGroup_Bonus.gameObject:SetActive(true)
        local itemList = BonusManager.GetItemsOfServerBonus(bonus)

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
        local newListCount = #newList

        -- if showflytext == true then
		-- 	for i, item in pairs(newList) do
		-- 		UIManager.ShowItemFlyText(string.format(LocalString.FlyText_Reward, item:GetNumber(), item:GetName()))
		-- 	end
        -- end
        
        UIHelper.ResetItemNumberOfUIList(fields.UIList_Bonus,newListCount)
        if newListCount > 0 then
            fields.UIGroup_Bonus.gameObject:SetActive(true)
        else
            fields.UIGroup_Bonus.gameObject:SetActive(false)
        end
        for ki = 1, newListCount do
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
--[[显示伤害文字]]
local function ShowHurtText(text)
     fields.UILabel_HurtMostPlayer.text = text or nil

     fields.UIPlayTween_RewardsLable.gameObject:SetActive(true)
     fields.UIPlayTween_RewardsLable:Play(true)
end


--==================================================================================================
--[[显示按钮]]
local function ShowButton(callback, checkFunc, hurtFunc)
    fields.UIButton_Sure01.gameObject:SetActive(true)
    EventHelper.SetClick(fields.UIButton_Sure01, function()
        if callback then
            callback()
        end
    end)

    if checkFunc then
        fields.UIButton_Check.gameObject:SetActive(true)
        EventHelper.SetClick(fields.UIButton_Check, function()
            if checkFunc then
                checkFunc()
            end
        end)
    else
        fields.UIButton_Check.gameObject:SetActive(false)
    end

    if hurtFunc then
        fields.UIButton_Hurt.gameObject:SetActive(true)
        EventHelper.SetClick(fields.UIButton_Hurt, function()
            if hurtFunc then
                hurtFunc()
            end
        end)
    else
        fields.UIButton_Hurt.gameObject:SetActive(false)
    end

    fields.UIPlayTween_Button.gameObject:SetActive(true)
    fields.UIPlayTween_Button:Play(true)
end



local function AddTask(time, func)
    table.insert( TaskList, {m_Time = time, m_Execute = func } )
end

local function ResetAll()
    TotalTime = 0
    TaskList = {}

    fields.UIPlayTween_Result.gameObject:SetActive(false)
    fields.UIPlayTween_Star.gameObject:SetActive(false)
    fields.UIPlayTween_Lable.gameObject:SetActive(false)
    fields.UIPlayTween_Button.gameObject:SetActive(false)
    fields.UIPlayTween_Currency.gameObject:SetActive(false)
    fields.UIPlayTween_Award.gameObject:SetActive(false)
    fields.UIPlayTween_RewardsLable.gameObject:SetActive(false)
end

local function destroy()

end

local function refresh()

end

local function second_update()

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

local function init(params)
    name, gameObject, fields = unpack(params)
end

local function hide()

end
--[[
    params = {
        result = 结果：true:成功   false:失败
        star = nil 不显示星星，0,1,2,3 星星数量

        text = 显示的文字
        clearTimeStr = 时间文字

        bonus = 奖励
        showitemflytext = 是否显示物品飘字
        hurtText = 下面的说明文字

        checkFunc = 查看战绩
        hurtFunc = 伤害统计
        callback = 点击确定按钮后的回调

    }
]]


local function show(params)
    local gradeTimeCfg = ConfigManager.getConfig("ectypegrade")
        
    local time_result = 0
    local time_star = 0
    local time_text = 0 
    local time_bonus = 0
    local time_hurttext = 0
    local time_button = 0

    if gradeTimeCfg then
        time_result = gradeTimeCfg["showresult"].time
        time_star = gradeTimeCfg["showstar"].time 
        time_text = gradeTimeCfg["showtext"].time 
        time_bonus = gradeTimeCfg["showbonus"].time 
        time_hurttext = gradeTimeCfg["showhurttext"].time 
        time_button = gradeTimeCfg["showbutton"].time 
    end

    ResetAll()
    if params.result ~= nil then
        AddTask(time_result, function() ShowResult(params.result) end)
    end

    if params.star ~= nil then
        AddTask(time_star, function() ShowStar(params.star) end)
    end

    if params.text ~= nil or params.clearTimeStr ~= nil then
        AddTask(time_text, function() ShowText(params.text, params.clearTimeStr) end)
    end

    if params.bonus ~= nil then
        AddTask(time_bonus, function() ShowBonus(params.bonus) end)
    end

    if params.hurtText ~= nil then
        AddTask(time_hurttext, function() ShowHurtText(params.hurtText) end)
    end

    AddTask(time_button, function() ShowButton(params.callback, params.checkFunc, params.hurtFunc) end)

    LuaGC()
	fields.UIList_Bonus.gameObject:GetComponent(UIGrid).enabled = true
end


return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    second_update=second_update,
}
