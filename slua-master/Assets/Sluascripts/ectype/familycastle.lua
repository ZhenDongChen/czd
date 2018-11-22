local SceneManager = require "scenemanager"
local PlayerRole = require"character.playerrole"
local network = require"network"
local uimanager = require"uimanager"
local Ectype = require"ectype.ectypebase"
local ConfigManager = require"cfg.configmanager"
local CharacterManager = require"character.charactermanager"
local FamilyCityTower        = require"character.familycitytower"
local ApertureManager       = require"ectype.aperturemanager"

local FamilyManager
local dlgectype
local dlgmain
local ui
local CastleWarInfo
local FamilyCastle = Class:new(Ectype)

function FamilyCastle:__new(entryInfo)
    FamilyManager           = require"family.familymanager"
    CastleWarInfo     = ConfigManager.getConfig("citywar",60490701)--entryInfo.city)
    local basic             = ConfigManager.getConfigData("ectypebasic",CastleWarInfo.ectypeid)
    entryInfo.ectypeid      = CastleWarInfo.ectypeid
    self.m_DelayWall        = true
    Ectype.__new(self,entryInfo,basic.type)
    self.m_bRoleEnter       = false
    self.m_IsTeamRed        = nil
    self.m_UI               = "ectype.dlgfamilywarui"
    self.m_UIList           = {"dlgjoystick",self.m_UI}
    self.m_StatisticElapse  = nil
    self.m_Scores           = {attackscore=0,defencescore=0}
    self.m_Towers           = {}
    --self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid, self.m_EctypeInfo.regionbeforebattlebegin1)
   -- self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid, self.m_EctypeInfo.regionbeforebattlebegin2)
    self.m_AttackFamilyID   = entryInfo.attackfamilyid
    self.m_DefenceFamilyID  = entryInfo.defencefamilyid
    self.m_AttackFamilyName = entryInfo.attackfamilyname
    self.m_DefenceFamilyName = entryInfo.defencefamilyname
    self.m_AttackFamilyCamp = entryInfo.attackfamilycamp
    self.m_DefenceFamilyCamp = entryInfo.defencefamilycamp
    local familymanager = require"family.familymanager"
    self.m_TowersState      = {}
    for i=1,7 do
        self.m_TowersState[i] = cfg.family.citywar.OccupyState.GREY
    end
    --self.m_ApertureManager  = ApertureManager:new(self)
end

function FamilyCastle:RemoveTowers()
    for i=#self.m_Towers ,1 , -1  do
        local tower = self.m_Towers[i]
        if tower then
           tower:remove()
		--GameObject:Destroy()
            self.m_Towers[i] = nil
        end
    end
    self.m_Towers = nil
end

function FamilyCastle:LeaveEctype()
    self:RemoveTowers()
    Ectype.LeaveEctype(self)
end

function FamilyCastle:InitUI()
    if not self.m_bAddTowers then
        self:AddTowers()
    end
    local familyInfo = FamilyManager.Info()
    if familyInfo then
        local rolefamilyid  = familyInfo.familyid
        self.m_IsAttacker   = (rolefamilyid == self.m_AttackFamilyID)
    end
    self.m_bRoleEnter   = true
    self.m_IsTeamRed    = PlayerRole.Instance().m_Camp == cfg.fight.CampType.PLAYER_RED
    self.m_EnemyCamp    = self.m_IsTeamRed and cfg.fight.CampType.PLAYER_BLUE   or cfg.fight.CampType.PLAYER_RED
    self.m_AllyCamp     = self.m_IsTeamRed and cfg.fight.CampType.PLAYER_RED    or cfg.fight.CampType.PLAYER_BLUE
    if uimanager.hasloaded(self.m_UI) then
        uimanager.call(self.m_UI,"InitTowerState",{
            maxScore    = CastleWarInfo.winscore,
            isattacker  = self.m_IsAttacker,
            worldTowers = self.m_Towers,
            attackFamilyName = self.m_AttackFamilyName,
            defenceFamilyName = self.m_DefenceFamilyName,
        })
    end
end

function FamilyCastle:RoleEnterEctype()
    self:InitUI()
end

function FamilyCastle:BeginFight(msg)
    Ectype.BeginFight(self,msg)
    --self:RemoveAirWallArea(self.m_EctypeInfo.regionbeforebattlebegin1)
   -- self:RemoveAirWallArea(self.m_EctypeInfo.regionbeforebattlebegin2)
    --self:SetDefaultAirWallArea()
    uimanager.call("dlguimain","SwitchAutoFight",true)
    network.send(map.msg.CEctypeStatistic{})
   -- self.m_ApertureManager:OnStart()
end


function FamilyCastle:JudgeRoleOccuring(msg)
    for towerid,towerInfo in pairs(msg.towers) do
        for _,playerid in pairs(towerInfo.players) do
            if playerid == PlayerRole.Instance().m_Id then
                return towerid,towerInfo.addscore
            end
        end
    end
end

function FamilyCastle:RefreshWorldTowers(states)
    for _,sInfo in ipairs(states) do
        towerid = sInfo.idx
        state   = sInfo.state
        local tower = self.m_Towers[towerid]
        if tower then
			--tower:remove()
            tower:LoadAvatar(sInfo.state)
        end
    end
end

function FamilyCastle:RefreshTowersStates(msg)
  --[[  local states = {}
	--printyellow(#msg.towers)
    for idx,ti in pairs(msg.towers) do
        if (ti.attacknum == 0 and ti.defencenum == 0) or ti.attacknum ==  ti.defencenum  then
            table.insert(states,{idx=idx,state=cfg.family.citywar.OccupyState.GREY})
        else
		if ti.attacknum ~= ti.defencenum then
			local towerState = {}
            towerState.idx = idx
			if (ti.attacknum > ti.defencenum and self.m_IsAttacker) then
				towerState.state = cfg.family.citywar.OccupyState.GREEN
			end
			
			if (ti.defencenum > ti.attacknum and not self.m_IsAttacker) then 
				towerState.state = cfg.family.citywar.OccupyState.RED
			end
                table.insert(states,towerState)			
            end
        end
    end
    if uimanager.hasloaded(self.m_UI) then
        uimanager.call(self.m_UI,"RefreshTowersStates",states)
    end--]]
	local states = {}
	--printyellow(#msg.towers)
    for idx,ti in pairs(msg.towers) do
        if ti.attacknum == 0 and ti.defencenum == 0 then
            table.insert(states,{idx=idx,state=cfg.family.citywar.OccupyState.GREY})
        elseif ti.attacknum ~= ti.defencenum then
                local towerState = {}
                towerState.idx = idx
                if (ti.attacknum > ti.defencenum and self.m_IsAttacker)
                or (ti.defencenum > ti.attacknum and not self.m_IsAttacker) then
                    towerState.state = cfg.family.citywar.OccupyState.GREEN
                else
                    towerState.state = cfg.family.citywar.OccupyState.RED
                end
                table.insert(states,towerState)
			
			elseif  ti.attacknum == ti.defencenum then
				 table.insert(states,{idx=idx,state=cfg.family.citywar.OccupyState.GREY})
            end  
    end
    if uimanager.hasloaded(self.m_UI) then
        uimanager.call(self.m_UI,"RefreshTowersStates",states)
    end
    self:RefreshWorldTowers(states)
end

function FamilyCastle:OnScore(msg)
    self.m_Scores = msg
    self:RefreshTowersStates(msg)
    local towerid,score = self:JudgeRoleOccuring(msg)
    if towerid and score then
        uimanager.ShowSystemFlyText(string.format(LocalString.EctypeText.CityWarAddScore,score))
    end
    if uimanager.hasloaded(self.m_UI) then
        uimanager.call(self.m_UI,"OnScore",msg)
    end
end

function FamilyCastle:TimeUpdate()
    Ectype.TimeUpdate(self)
end

function FamilyCastle:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    uimanager.hide(self.m_UI)
    network.send(map.msg.CEctypeStatistic{})
    self.m_EndMsg = msg
	--if self.m_ApertureManager ~= nil then
		 -- self.m_ApertureManager:OnEnd()
	--end
	local citywarinfo 	  = require"ui.citywar.citywarinfo"
	citywarinfo.SetCityWarOver(true)
end


function FamilyCastle:PackPlayer(player,pets)
    for _,pet in pairs(pets) do
        player.damage = player.damage + pet.damage
        player.kill = player.kill + pet.kill
        player.dead = player.dead + pet.dead
    end
    return player
end

function FamilyCastle:RePackage(msg)
    local ret = {}
    ret.teams = {}
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

function FamilyCastle:EctypeStatistic(msg)
    local pMsg = self:RePackage(msg)
    if self.m_bEnd then
        local bAttacker = self.m_EndMsg.isdefence == 0
		--local pMsg = self:RePackage(msg)
        local endText = string.format(LocalString.EctypeText.CityWarEndText,LocalString.EctypeText.IsAttacker[bAttacker],self.m_EndMsg.money,bAttacker and 80 or 50)
        uimanager.showdialog("ectype.dlgmilitaryexploits",{
          scores = self.m_Scores,
          isattacker = self.m_IsAttacker,
          statisticMsg = pMsg,
          callback = function()
              uimanager.showdialog("ectype.dlggrade",{
                  result        = self.m_EndMsg.win>0,
                  bonus         = nil,
                  text          = self.m_EndMsg.win>0 and endText or "",
                  checkFunc     = function() network.send(map.msg.CEctypeStatistic{}) end,
                  callback      = function()
                      uimanager.hidedialog"ectype.dlggrade"
                      uimanager.show(self.m_UI)
                      network.send(lx.gs.map.msg.CLeaveMap{})
                  end
              })
          end
        })
    else
        self.m_StatisticElapse = 3
        if uimanager.isshow(self.m_UI) and uimanager.hasmethod(self.m_UI,"OnStatistic") then
            uimanager.call(self.m_UI,"OnStatistic",pMsg)
        end
    end
end


function FamilyCastle:UpdateTowers()
    for _,tower in ipairs(self.m_Towers) do
        if tower then
            tower:update()
        end
    end
end

function FamilyCastle:AddTowers()
    self.m_Towers = {}
    for i,towerInfo in ipairs(self.m_EctypeInfo.towers) do
        local tower = FamilyCityTower:new()
        tower:init(i,towerInfo.towerid)
        tower:SetPos(cloneVector3{x=towerInfo.position.x,y=towerInfo.position.y,z=0})
       -- tower:LoadAvatar(cfg.family.citywar.OccupyState.GREY)
        self.m_Towers[i] = tower
    end
    self.m_bAddTowers = true
end

function FamilyCastle:OnUpdateLoading()
    Ectype.OnUpdateLoading(self)
    if not SceneManager.IsLoadingScene() then
        if uimanager.isshow("dlguimain") and uimanager.isshow(self.m_UI) then
            if self.m_bRoleEnter then
                self:InitUI()
            end
        end
    end
end

function FamilyCastle:late_update()

end

function FamilyCastle:second_update()
    if self.m_bBeginFight and not self.m_bEnd then
        if self.m_StatisticElapse then
            self.m_StatisticElapse = self.m_StatisticElapse - 1
            if self.m_StatisticElapse < 0 then
              self.m_StatisticElapse = nil
              network.send(map.msg.CEctypeStatistic{})
            end
        end
    end
    Ectype.second_update(self)
end

function FamilyCastle:TimeUpdate()
    if self.m_bBeginFight then
        Ectype.TimeUpdate(self)
    end
end

function FamilyCastle:Update()
    self:UpdateTowers()
    Ectype.Update(self)
	--if self.m_ApertureManager ~= nil then
		--self.m_ApertureManager:OnUpdate()
	--end
	
end

return FamilyCastle
