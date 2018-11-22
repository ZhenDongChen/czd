local SceneManager = require "scenemanager"
local ConfigManager = require"cfg.configmanager"
local PlayerRole = require"character.playerrole"
local network = require"network"
local uimanager = require"uimanager"
local Ectype = require"ectype.ectypebase"

------------------------------------------
--家族循环赛
------------------------------------------
local FamilyRoundRobin = Class:new(Ectype)

function FamilyRoundRobin:__new(entryInfo)
    local familyWarInfo     = ConfigManager.getConfig("familyleague")
    local basic             = ConfigManager.getConfigData("ectypebasic",familyWarInfo.ectypeid)
    entryInfo.ectypeid = familyWarInfo.ectypeid
    self.m_DelayWall = true
    Ectype.__new(self,entryInfo,basic.type)
    self.m_IsTeamRed        = entryInfo.camp == cfg.fight.CampType.PLAYER_RED
    self.m_TotalReviveTime  = self.m_BasicEctypeInfo.reviveinfo.maxcount
    self.m_RegionEffects    = {}
    self.m_UI               = "ectype.dlgfamilyui"
    self.m_UIList           = {"dlgjoystick",self.m_UI}
    self.m_TeamsInfo        = {
        ["ally"] = {score=0,towerhps={1,1,1}},
        ["enemy"] = {score=0,towerhps={1,1,1}},
    }
    self.m_CountDownWalls  = {}
    self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid, self.m_EctypeInfo.regionbeforebattlebegin1)
    self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid, self.m_EctypeInfo.regionbeforebattlebegin2)
    self.m_bBeginFight = false
    self.m_StatisticElapse = nil

end

function FamilyRoundRobin:BeginFight(msg)
    Ectype.BeginFight(self,msg)
    self:RemoveAirWallArea(self.m_EctypeInfo.regionbeforebattlebegin1)
    self:RemoveAirWallArea(self.m_EctypeInfo.regionbeforebattlebegin2)
    self:SetDefaultAirWallArea()
    uimanager.call("dlguimain","SwitchAutoFight",true)
    self.m_bBeginFight = true
    network.send(map.msg.CEctypeStatistic({}))
end

function FamilyRoundRobin:TimeUpdate()
    if self.m_bBeginFight then
        Ectype.TimeUpdate(self)
    end
end

function FamilyRoundRobin:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    uimanager.hide(self.m_UI)
    uimanager.showdialog("ectype.dlggrade",
    {   result      = (((msg.iswin > 0) and true) or false),
        bonus       = msg.bonus,
        --text        = string.format(LocalString.EctypeText.FamilyWarBuildDegree,msg.familybuilddegree),
        checkFunc   = function() network.send(map.msg.CEctypeStatistic({})) end,
        callback    = function()
            uimanager.hidedialog("ectype.dlggrade")
            uimanager.show(self.m_UI)
            network.send(lx.gs.map.msg.CLeaveMap({}))
        end
    })
end

function FamilyRoundRobin:PackPlayer(player,pets)
    for _,pet in pairs(pets) do
        player.damage = player.damage + pet.damage
        player.kill = player.kill + pet.kill
        player.dead = player.dead + pet.dead
    end
    return player
end

function FamilyRoundRobin:second_update()
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

function FamilyRoundRobin:RePackage(msg)
    local ret = {}
    ret.teams = {}
    -- for _,mTeam in ipairs(msg.teams) do
    for i=1,2 do
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
                            table.insert(pets,mPet)
                        end
                    end
                    table.insert(team.members,self:PackPlayer(player,pets))
                    if mPlayer.name == PlayerRole.Instance().m_Name then
                        team.broleteam = true
                    end
                end
            end
        end
        table.sort(team.members,function(a,b) return a.damage>b.damage end)
        table.insert(ret.teams,team)
    end
    return ret
end

function FamilyRoundRobin:OnUpdateLoading()
    Ectype.OnUpdateLoading(self)
        if not SceneManager.IsLoadingScene() then
            if uimanager.isshow("dlguimain") and uimanager.isshow(self.m_UI) then
                uimanager.call(self.m_UI,"InitTowerPositions",self.m_IsTeamRed)
            end
        end
    -- end
end

function FamilyRoundRobin:EctypeStatistic(msg)
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

function FamilyRoundRobin:CheckBreak(prevState,newState,isally)
    for i=1,3 do
        if prevState.towerhps[i] > 0 and newState.towerhps[i]<=0 then
            uimanager.call("ectype.dlgfamilyui","BreakTower",{idx=i,isally=isally})
        end
    end
end

function FamilyRoundRobin:OnWarStatus(msg)
    if uimanager.hasloaded(self.m_UI) then
        local params = {}
        params.ally = self.m_IsTeamRed and msg.status1 or msg.status2
        params.enemy = self.m_IsTeamRed and msg.status2 or msg.status1
        self:CheckBreak(self.m_TeamsInfo.ally ,params.ally ,true )
        self:CheckBreak(self.m_TeamsInfo.enemy,params.enemy,false)
        self.m_TeamsInfo = params
        uimanager.call("ectype.dlgfamilyui","OnChange",params)
    end
end

return FamilyRoundRobin
