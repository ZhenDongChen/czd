local WorldBossManager=require"ui.activity.worldboss.worldbossmanager"
local TournamentManager   =require("ui.activity.tournament.tournamentmanager")
local HeroBookManager = require("ui.activity.herobook.herobookmanager")
local GuardTowerManager = require "ui.ectype.guardtower.guardtowermanager"
local PersonalBoss = require "ui.activity.personalboss.personalboss"
local AttackCity = require "ui.activity.attackcity.attackcitymanager"
local ActivityExp = require "ui.activity.activityexp.activityexpmanager"
local Maimai = require "ui.activity.maimai.maimaiactmanager"
local PersonalBossManager   = require("ui.activity.personalboss.personalboss")

local function UnRead()
    return WorldBossManager.UnRead() or TournamentManager.UnRead() or GuardTowerManager.UnRead() or PersonalBoss.UnRead() or AttackCity.UnRead() or HeroBookManager.UnRead() or ActivityExp.UnRead() or Maimai.UnRead()
end

local function Start()
    printyellow("Start ... ... OnStart")
    HeroBookManager.Start()
end

local function init()
    HeroBookManager.init()
    PersonalBossManager.init()
end

return{
    init = init,
    Start = Start,
    UnRead = UnRead,
}