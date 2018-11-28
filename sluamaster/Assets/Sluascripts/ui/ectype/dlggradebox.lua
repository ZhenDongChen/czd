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

local openBoxTime = 30
local TaskList = {}
local TotalTime = 0
--==================================================================================================
--[[显示结果：胜利或者失败]]
local function ShowResult()
    fields.UIGroup_OpenBox.gameObject:SetActive(true)
    
    fields.UIPlayTween_Result.gameObject:SetActive(true)
    fields.UIPlayTween_Result:Play(true)
    if cfg.ectype.EctypeBasic.successaudioid ~= 0 then
        AudioManager.Play2dSound(cfg.ectype.EctypeBasic.successaudioid)
    end
end

--==================================================================================================
--[[显示开箱子]]
local m_RemainOpenBoxNum    = 0
local m_BonusItemList       = nil
local m_MaxBoxNum           = 4
local m_AllOpenBoxIndex     = {}

local function SetAllCloseBoxDisable()
    for i = 1, m_MaxBoxNum do
        local uiItem = fields.UIList_Card:GetItemByIndex(i-1)
       -- if m_AllOpenBoxIndex[i] ~= true then
         --   local button = uiItem.gameObject:GetComponent("UIButton")
            local boxcolider = uiItem.gameObject:GetComponent("BoxCollider")
          --  boxcolider.enabled = false
          --  if button then
          --      button.isEnabled = false
                boxcolider.enabled = false
         --   end
      --  end

    end
end

local function OpenBoxOfIndex(num,boxNum)
    if m_RemainOpenBoxNum <= 0 then
        return
    end

    local uiItem    = fields.UIList_Card:GetItemByIndex(num-1)

    local itemPlayTweens = uiItem.gameObject:GetComponent("UIPlayTweens")

    itemPlayTweens:Play(true)
    m_AllOpenBoxIndex[num] = true

    m_MaxBoxNum = boxNum

    BonusManager.SetRewardItem(uiItem,m_BonusItemList[m_RemainOpenBoxNum])
    m_RemainOpenBoxNum = m_RemainOpenBoxNum -1
    if m_RemainOpenBoxNum <= 0 then
        SetAllCloseBoxDisable()
        fields.UIButton_Sure03.isEnabled = true
    end
end

local function ShowDescText(text)
    if text then
        fields.UILabel_Discription.text=text
        fields.UILabel_Discription.gameObject:SetActive(true)
    else
        fields.UILabel_Discription.gameObject:SetActive(false)
    end
end

local function ShowBox(bonuss,boxNum,text)
    fields.UIButton_Sure03.isEnabled = false
    m_BonusItemList = {}
    for i, bonus in pairs(bonuss) do
        local itemList = BonusManager.GetItemsOfServerBonus(bonus)
        if #itemList > 0 then
            table.insert(m_BonusItemList,itemList[1])
        end
    end

    m_RemainOpenBoxNum = #m_BonusItemList

    fields.UIList_Card:Clear()
    for i = 1, boxNum do
        local uiItem    = fields.UIList_Card:AddListItem()
        EventHelper.SetClick(uiItem, function()
            OpenBoxOfIndex(i,boxNum)
        end)
    end
    
    ShowDescText(text)
    fields.UIPlayTween_Box.gameObject:SetActive(true)
    fields.UIPlayTween_Box:Play(true)
end

--====================================================================================
--[[显示确定按钮]]
local function ShowButton(callback)

    fields.UIButton_Sure03.gameObject:SetActive(true)
    EventHelper.SetClick(fields.UIButton_Sure03, function()
        if callback then
            callback()
        end
    end)
    fields.UIPlayTween_Button.gameObject:SetActive(true)
    fields.UIPlayTween_Button:Play(true)
end


--====================================================================================

local function ResetAll()
    TaskList = {}
    m_AllOpenBoxIndex = {}
    openBoxTime = 30
    fields.UIPlayTween_Result.gameObject:SetActive(false)
    fields.UIPlayTween_Box.gameObject:SetActive(false)
    fields.UIPlayTween_Button.gameObject:SetActive(false)
    fields.UIPlayTween_Text.gameObject:SetActive(false)
    fields.UIPlayTween_Currency.gameObject:SetActive(false)
end

local function AddTask(time, func)
    table.insert( TaskList, {m_Time = time, m_Execute = func } )
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

    openBoxTime = openBoxTime - Time.deltaTime
    if openBoxTime < 0 then
        openBoxTime = 0
    end

    fields.UILabel_OpenTime.text = string.format(LocalString.OpenTreasure_Count, math.floor(openBoxTime))

    if openBoxTime == 0 and m_RemainOpenBoxNum > 0 then
        for i = 1, m_MaxBoxNum do
            local uiItem = fields.UIList_Card:GetItemByIndex(i-1)
            local openBox   = uiItem.Controls["UITexture_OpenBox"]
            if m_AllOpenBoxIndex[i] ~= false then
                OpenBoxOfIndex(i, m_MaxBoxNum)
            end
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
        bonuss = 奖励
        boxNum = 箱子数量
        callback = 点击确定按钮后的回调
    }
]]
local function show(params)
    ResetAll()

    local gradeTimeCfg = ConfigManager.getConfig("ectypegrade")
        
    local time_result = 0
    local time_bonus = 0
    local time_button = 0

    if gradeTimeCfg then
        time_result = gradeTimeCfg["showresult"].time
        time_bonus = gradeTimeCfg["showbonus"].time 
        time_button = gradeTimeCfg["showbutton"].time 
    end

    AddTask(time_result, function() ShowResult() end)
    AddTask(time_bonus, function() ShowBox(params.bonuss, params.boxNum or 4, params.descText) end)
    AddTask(time_button, function() ShowButton(params.callback) end)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    second_update = second_update,
}
