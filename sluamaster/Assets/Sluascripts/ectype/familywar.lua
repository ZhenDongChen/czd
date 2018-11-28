local SceneManager = require "scenemanager"
local CameraManager = require"cameramanager"
local ConfigManager = require"cfg.configmanager"
local PlayerRole = require"character.playerrole"
local Layout = require "ectype.layout"
local network = require"network"
local uimanager = require"uimanager"
local tools = require"ectype.ectypetools"
local define = require"define"

local dlgectype
local dlgmain
local ui
local Ectype = require"ectype.ectypebase"

local tinsert       = table.insert
local strfmt        = string.format
local tsort         = table.sort    
-- class FamilyEctype
local FamilyWar = Class:new(Ectype)

function FamilyWar:__new(entryInfo)
    local familyWarInfo     = ConfigManager.getConfig("familywar")
    local basic             = ConfigManager.getConfigData("ectypebasic",familyWarInfo.ectypeid)
    entryInfo.ectypeid      = familyWarInfo.ectypeid
    self.m_DelayWall        = true
    Ectype.__new(self,entryInfo,basic.type)
    self.m_IsTeamRed        = entryInfo.camp == cfg.fight.CampType.PLAYER_RED
    self.m_TotalReviveTime  = self.m_BasicEctypeInfo.reviveinfo.maxcount
    self.m_RegionEffects    = {}
    self.m_UI               = "ectype.dlgfamilyui"
    self.m_UIList           = {"dlgjoystick",self.m_UI}
    self.m_TeamsInfo        = {
        ["ally"]    = {score=0,towerhps={1,1,1}},
        ["enemy"]   = {score=0,towerhps={1,1,1}},
    }
    self.m_CountDownWalls   = {}
    self.m_bBeginFight      = false
    self.m_StatisticElapse  = nil
--    self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid, self.m_EctypeInfo.regionbeforebattlebegin1)
--    self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid, self.m_EctypeInfo.regionbeforebattlebegin2)
end

function FamilyWar:BeginFight(msg)
    Ectype.BeginFight(self,msg)
--    self:RemoveAirWallArea(self.m_EctypeInfo.regionbeforebattlebegin1)
--    self:RemoveAirWallArea(self.m_EctypeInfo.regionbeforebattlebegin2)
--    self:SetDefaultAirWallArea()
    uimanager.call("dlguimain","SwitchAutoFight",true)
    self.m_bBeginFight = true
    network.send(map.msg.CEctypeStatistic({}))
end

function FamilyWar:TimeUpdate()
    if self.m_bBeginFight then
        Ectype.TimeUpdate(self)
    end
end

function FamilyWar:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    uimanager.hide(self.m_UI)
    -- self.m_bEnd = true
    uimanager.showdialog("ectype.dlggrade",
    {   result      = (((msg.iswin > 0) and true) or false),
        bonus       = msg.bonus,
        text        = strfmt(LocalString.EctypeText.FamilyWarBuildDegree,msg.familybuilddegree),
        checkFunc   = function() network.send(map.msg.CEctypeStatistic({})) end,
        callback    = function()
            uimanager.hidedialog("ectype.dlggrade")
            uimanager.show(self.m_UI)
            network.send(lx.gs.map.msg.CLeaveMap({}))
        end
    })
end

function FamilyWar:PackPlayer(player,pets)
    for _,pet in pairs(pets) do
        player.damage = player.damage + pet.damage
        player.kill = player.kill + pet.kill
        player.dead = player.dead + pet.dead
    end
    return player
end

function FamilyWar:second_update()
    if self.m_bBeginFight and not self.m_bEnd then
        if self.m_StatisticElapse then
            self.m_StatisticElapse = self.m_StatisticElapse - 1
            if self.m_StatisticElapse < 0 then
                self.m_StatisticElapse = nil
                network.send(map.msg.CEctypeStatistic({}))
            end
        end
    end
    Ectype.second_update(self)
end

function FamilyWar:RePackage(msg)
    local ret = {}
    ret.teams = {}
    -- for _,mTeam in ipairs(msg.teams) do
    for i=2,3 do
        local mTeam = msg.teams[i]
        local team = {}
        team.broleteam = false
        team.members = {}
        if mTeam then
            local player = nil
            local pets = {}
            for _,mPlayer in ipairs(mTeam.members) do
                if mPlayer.ownername == "" then
                    player = mPlayer
                    pets = {}
                    for _,mPet in ipairs(mTeam.members) do
                        if mPet.ownername == player.name then
                            tinsert(pets,mPet)
                        end
                    end
                    tinsert(team.members,self:PackPlayer(player,pets))
                    if mPlayer.name == PlayerRole.Instance().m_Name then
                        team.broleteam = true
                    end
                end
            end
        end
        tsort(team.members,function(a,b) return a.damage>b.damage end)
        tinsert(ret.teams,team)
    end
    return ret
end

function FamilyWar:OnUpdateLoading()
	--printyellow("OnUpdateLoadingOnUpdateLoadingOnUpdateLoadingOnUpdateLoadingOnUpdateLoading")
    Ectype.OnUpdateLoading(self)
    -- if self.m_bEnd then
        if not SceneManager.IsLoadingScene() then
            if uimanager.isshow("dlguimain") and uimanager.isshow(self.m_UI) then
                uimanager.call(self.m_UI,"InitTowerPositions",self.m_IsTeamRed)
            end
        end
    -- end
end

function FamilyWar:EctypeStatistic(msg)
    local pMsg = self:RePackage(msg)
    if self.m_bEnd then
        uimanager.showdialog("ectype.dlgstatistic", { statisticMsg = pMsg,groupindex=3,towerInfo=self.m_TeamsInfo})
    else
        self.m_StatisticElapse = 3
        if uimanager.isshow(self.m_UI) and uimanager.hasmethod(self.m_UI,"OnStatistic") then
            uimanager.call(self.m_UI,"OnStatistic",pMsg)
        end
    end
end

function FamilyWar:CheckBreak(prevState,newState,isally)
    for i=1,3 do
        if prevState.towerhps[i] > 0 and newState.towerhps[i]<=0 then
            uimanager.call("ectype.dlgfamilyui","BreakTower",{idx=i,isally=isally})
        end
    end
end

function FamilyWar:OnWarStatus(msg)
    local FamilyManager = require("family.familymanager")
    local familyId = FamilyManager.GetFamilyId()
    if uimanager.hasloaded(self.m_UI) then
        local params = {}
        if msg.status1.familyid == familyId then
            params.ally = msg.status1
            params.enemy = msg.status2
        else
            params.ally = msg.status2
            params.enemy = msg.status1
        end
        self:CheckBreak(self.m_TeamsInfo.ally ,params.ally ,true )
        self:CheckBreak(self.m_TeamsInfo.enemy,params.enemy,false)
        self.m_TeamsInfo = params
        uimanager.call("ectype.dlgfamilyui","OnChange",params)
    end
end

return FamilyWar
