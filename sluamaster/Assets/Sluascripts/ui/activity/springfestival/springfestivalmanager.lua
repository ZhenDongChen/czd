local NetWork=require("network")
local UIManager=require("uimanager")
local CharacterManager  = require("character.charactermanager")
local PlayerRole=require("character.playerrole"):Instance()
local itemmanager = require "item.itemmanager"
local LimitTimeManager       = require("limittimemanager")
local ConfigManager 	  = require "cfg.configmanager"
local springfestivalinfo 	  = require "ui.activity.springfestival.springfestivalinfo"
local BonusManager = require("item.bonusmanager")
local timeutils = timeutils
local MonsterData = {
            MonsterExpStatus = 0,
            activityid = nil,
            remainexp = 0,
        }
local KardsDataList = nil

--[[
<protocol name="SActivity">
	<variable name="id" type="int"/>
	<variable name="nextbonusid" type="int"/>��0��ʼ
	<variable name="dayindex" type="int"/>��1��ʼ
</protocol>
--]]
local function on_SActivity(msg)
    printyellow("[springfestivalmanager:on_SActivity] receive:", msg)
    springfestivalinfo.on_SActivity(msg)
        
    --���»����
	if UIManager.isshow("activity.springfestival.dlgspringfestivalgifts") then
		UIManager.refresh("activity.springfestival.dlgspringfestivalgifts")
	end
end

--[[
<protocol name="CGetBonus">
	<variable name="activityid" type="int"/>
	<variable name="bonusid" type="int"/>
</protocol>
--]]
local function send_CGetBonus()
    local msg = lx.gs.activity.onlinetimebonus.msg.CGetBonus({activityid=springfestivalinfo.GetCurrentActivityID(), bonusid=springfestivalinfo.GetNextBonusIndex()-1})
    printyellow("[springfestivalmanager:send_CGetBonus] send:", msg)
    NetWork.send(msg)
end

--[[
<protocol name="SGetBonus">
	<variable name="activityid" type="int"/>
	<variable name="nextbonusid" type="int"/>
	<variable name="bonus" type="map.msg.Bonus"/>
</protocol>
--]]
local function on_SGetBonus(msg)
    printyellow("[springfestivalmanager:on_SGetBonus] receive:", msg)
    springfestivalinfo.on_SGetBonus(msg)

    --��ʾ����
    local bonusItems = BonusManager.GetItemsOfServerBonus(msg.bonus)
	UIManager.show("common.dlgdialogbox_itemshow",{ itemList = bonusItems })

    --���»����
	if UIManager.isshow("activity.springfestival.dlgspringfestivalgifts") then
		UIManager.refresh("activity.springfestival.dlgspringfestivalgifts")
	end
end

--[[
<protocol name="SCloseActivity">
	<variable name="id" type="int"/>
</protocol>
--]]
local function on_SCloseActivity(msg)
    printyellow("[springfestivalmanager:on_SCloseActivity] receive:", msg)
    springfestivalinfo.on_SCloseActivity(msg)
    if msg.id  == MonsterData.activityid then
        MonsterData.MonsterExpStatus = 0
        if UIManager.isshow("dlgdailyexp") then
            UIManager.call("dlgdailyexp","refreshExp")
        end
    end
    --���»����
	if UIManager.isshow("activity.springfestival.dlgspringfestivalgifts") then
		UIManager.refresh("activity.springfestival.dlgspringfestivalgifts")
	end
end

local function on_MonsterSActivity(msg)
    printyellow("on_MonsterSActivity")
    MonsterData.MonsterExpStatus = 1
    MonsterData.activityid = msg.activityid
    MonsterData.remainexp = msg.remainexp
    if UIManager.isshow("dlgdailyexp") then
        UIManager.call("dlgdailyexp","refreshExp")
    end
end

local function on_KeybonusSActivity(msg)
    KardsDataList = msg.keys
end

local function on_KeybonusSNewKey(msg)
    table.insert(KardsDataList,msg.key)
    UIManager.show("dlgalert_reminder_singlebutton",{content = LocalString.JDDES})
    UIManager.call("dlgaccount","refresh")
end

local function getKardsDataList()
    return KardsDataList
end

local function getMonsterData()
    return MonsterData
end

local function UnRead()
    return springfestivalinfo.IsActivityOpen() and springfestivalinfo.CanFetchDailyBonus()
end

local function init()
    printyellow("[springfestivalmanager:init] init!")
    springfestivalinfo.init()

    --test
    --local msg = {id=1, nextbonusid=4, dayindex=1}
    --on_SActivity(msg)

    NetWork.add_listeners({
        {"lx.gs.activity.onlinetimebonus.msg.SActivity",on_SActivity},
        {"lx.gs.activity.onlinetimebonus.msg.SGetBonus",on_SGetBonus},
        {"lx.gs.activity.msg.SCloseActivity",on_SCloseActivity},
        {"lx.gs.activity.monsterexp.msg.SActivity",on_MonsterSActivity},
        {"lx.gs.activity.keybonus.msg.SActivity",on_KeybonusSActivity},
        {"lx.gs.activity.keybonus.msg.SNewKey",on_KeybonusSNewKey},
    })
end

return
{
    init     = init,
    UnRead   = UnRead,
    send_CGetBonus = send_CGetBonus,
    getMonsterData = getMonsterData,
    getKardsDataList = getKardsDataList,
}
