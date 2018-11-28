local NetWork=require("network")
local UIManager=require("uimanager")
local CharacterManager  = require("character.charactermanager")
local PlayerRole=require("character.playerrole"):Instance()
local itemmanager = require "item.itemmanager"
local LimitTimeManager       = require("limittimemanager")
local ConfigManager 	  = require "cfg.configmanager"
local lotteryfragmentinfo 	  = require "ui.lottery.lotteryfragment.lotteryfragmentinfo"
local BonusManager = require("item.bonusmanager")
local timeutils = timeutils

local function send_CLotteryRoll()
    local msg = lx.gs.lottery.msg.CLotteryRoll()
    --printyellow("[lotteryfragmentmanager:send_CLotteryRoll] send:", msg)
    NetWork.send(msg)
end

local function on_SLotteryRoll(msg)
    --printyellow("[lotteryfragmentmanager:on_SLaunchGodAnimalActivity] receive:", msg)
    if UIManager.isshow("lottery.lotteryfragment.dlglotteryfragment") then
        UIManager.call("lottery.lotteryfragment.dlglotteryfragment","on_SLotteryRoll",msg)
    end
end

local function on_SSyncScoreBonus(msg)
    --printyellow("[lotteryfragmentmanager:on_SSyncScoreBonus] receive:", msg)
    lotteryfragmentinfo.SyncScoreBonus(msg)

    if UIManager.isshow("lottery.lotteryfragment.dlglotteryfragment") then
        UIManager.call("lottery.lotteryfragment.dlglotteryfragment","on_SSyncScoreBonus",msg)
    end
end

local function on_SCurrencyChange(msg)
    --printyellow("[lotteryfragmentmanager:on_SCurrencyChange] receive:", msg)
    if UIManager.isshow("lottery.lotteryfragment.dlglotteryfragment") then
        UIManager.call("lottery.lotteryfragment.dlglotteryfragment","on_SCurrencyChange",msg)
    end
end

local function on_SLotteryScoreExchange(msg)
    --printyellow("[lotteryfragmentmanager:on_SLotteryScoreExchange] receive:", msg)

    local scorebonus = lotteryfragmentinfo.GetScoreBonus(msg.score)
    if scorebonus then
        local awardItemList = BonusManager.GetMultiBonusItems(scorebonus)
	    UIManager.show("common.dlgdialogbox_itemshow", {itemList = awardItemList})       
    end
end

local function send_CLotteryScoreExchange(score)
    local msg = lx.gs.lottery.msg.CLotteryScoreExchange({score = score})
    --printyellow("[lotteryfragmentmanager:send_CLotteryScoreExchange] send:", msg)
    NetWork.send(msg)
end

local function send_CLotteryRoll10()
    local msg = lx.gs.lottery.msg.CLotteryRoll10()
    --printyellow("[lotteryfragmentmanager:send_CLotteryRoll10] send:", msg)
    NetWork.send(msg)
end

local function on_SLotteryRoll10(msg)
    --printyellow("[lotteryfragmentmanager:on_SLotteryRoll10] receive:", msg)
    if UIManager.isshow("lottery.lotteryfragment.dlglotteryfragment") then
        UIManager.call("lottery.lotteryfragment.dlglotteryfragment","on_SLotteryRoll10",msg)
    end
end

--[[
local function on_SSyncLotteryScore(msg)
    printyellow("[lotteryfragmentmanager:on_SSyncLotteryScore] receive:", msg)
end
--]]

local function OnLimitChange()
    --printyellow("[lotteryfragmentmanager:OnLimitChange] OnLimitChange!")
    if UIManager.isshow("lottery.lotteryfragment.dlglotteryfragment") then
        UIManager.call("lottery.lotteryfragment.dlglotteryfragment","OnLimitChange")
    end
end

local function IsLotteryOpen()
    return nil~=lotteryfragmentinfo.GetCurrentLottery()
end

local function UnRead()
    return IsLotteryOpen() and lotteryfragmentinfo.GetLeftFreeCount()>0
end

local function init()
    --printyellow("[lotteryfragmentmanager:init] init!")
    lotteryfragmentinfo.init()

    --LimitTimeManager.AddLimitChangeCallback(OnLimitChange) 

    NetWork.add_listeners({
        {"lx.gs.lottery.msg.SLotteryRoll",on_SLotteryRoll},
        {"lx.gs.lottery.msg.SSyncScoreBonus",on_SSyncScoreBonus},    
        {"lx.gs.lottery.msg.SLotteryScoreExchange",on_SLotteryScoreExchange},  
        {"lx.gs.lottery.msg.SLotteryRoll10",on_SLotteryRoll10},           
        { "lx.gs.role.msg.SCurrencyChange",        on_SCurrencyChange     },  
              
        --{"lx.gs.lottery.msg.SSyncLotteryScore",on_SSyncLotteryScore},      
    })
end

return
{
    init     = init,
    UnRead   = UnRead,
    send_CLotteryRoll = send_CLotteryRoll,
    send_CLotteryScoreExchange = send_CLotteryScoreExchange,
    send_CLotteryRoll10 = send_CLotteryRoll10,
    IsLotteryOpen = IsLotteryOpen,
}
