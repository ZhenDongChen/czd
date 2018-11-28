
local PlayerRole = require"character.playerrole"
local Layout = require "ectype.layout"
local network = require"network"
local uimanager = require"uimanager"
local tools = require"ectype.ectypetools"
local Ectype = require"ectype.ectypebase"
local ConfigManager = require("cfg.configmanager")
local EctypeOthersManager = require("ectype.ectypeothersmanager")
local CharacterManager = require("character.charactermanager")
local Define = require("define")

local dlgectype
local dlgmain
local ui
-- class Daily
--==============================================================================
--==============================================================================
local TeamFight = Class:new(Ectype)

function TeamFight:__new(entryInfo)
    --printyellow("teamfight new")
    Ectype.__new(self,entryInfo,cfg.ectype.EctypeType.TEAMFIGHT)
  --  self.m_RemainTime       = entryInfo.remaintime/1000
    self.m_PlayerRole       = PlayerRole.Instance()

    self.m_TotalReviveTime  = self.m_BasicEctypeInfo.reviveinfo.maxrevivecount
    self.m_CurrentReviveTime= 0
    self.m_ReviveCountDown  = self.m_BasicEctypeInfo.reviveinfo.time
    --self.m_ReviveCountDown =
    --function Arena:BeginArenaFight(msg)
    --printyellow("9090909090")
    self.m_UIList = Local.TeamFightDlgList
    self.m_UI = "ectype.dlgathletics3v3"
    --completeneedkillnum

    self.m_MyCamp = entryInfo.mycamp
    self.m_EnemyCamp = 0
    self.m_TeamKillNums = {}
    for camp, num in pairs(entryInfo.teamkillnums) do
        self.m_TeamKillNums[camp] = num
        if camp ~= self.m_MyCamp then
            self.m_EnemyCamp = camp
        end
    end

    self.m_CompleteScore = self.m_EctypeInfo.completeneedkillnum

    --printyellow("entryInfo.state",entryInfo.state,cfg.ectype.EctypeState.START)
    if entryInfo.state == cfg.ectype.EctypeState.START then
        self:BeginFight({state = entryInfo.state})
    end

    self.m_IsEctypeEnd = false

    self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid, self.m_EctypeInfo.team1bornregionid)
    self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid, self.m_EctypeInfo.team2bornregionid)

    self.m_TimeElapsedAfterEnd = 7

    --self.m_ApertureMgr = ApertureManager:new(self)
end

function TeamFight:GetEctypeInfo()
    return ConfigManager.getConfig("teamfight")
end

function TeamFight:ShowTasks(isShow)
    if uimanager.isshow(self.m_UI) then
        uimanager.call( self.m_UI, "ShowScorePanel", { isShowPanel = isShow } )
    end
end

function TeamFight:SetDefaultAirWallArea()

end

function TeamFight:EatRune(runeid)

end

function TeamFight:BeginFight(msg)
    Ectype.BeginFight(self, msg)
    --printyellow("TeamFight BeginFight")
    self:RemoveAllAirWallArea()
    --self.m_ApertureMgr:OnStart()
end



function TeamFight:ChangeTeamKillNum(msg)
    if msg.camp ~= self.m_MyCamp then
        self.m_EnemyCamp = msg.camp
    end

    self.m_TeamKillNums[msg.camp] = msg.killnum


    self:UpdateTeamFightUI()
end

function TeamFight:CanRevive()
    if self.m_IsEctypeEnd == false then
        return true
    else
        return false
    end
end

function TeamFight:SKillEvent(msg)
    if uimanager.isshow(self.m_UI) then
        uimanager.call( self.m_UI,"NewBattleMsg",{serverMsg = msg, playerCamp = self.m_MyCamp})
    end
end


function TeamFight:SendRevive()
    local msg=map.msg.CRevive({})
    network.send(msg)
end

function TeamFight:UpdateTeamFightUI()
    if uimanager.isshow(self.m_UI) then
        uimanager.call( self.m_UI,
                        "ChangeScore",
                        {   friendlyScore = (self.m_TeamKillNums[self.m_MyCamp] or 0),
                            enemyScore    = (self.m_TeamKillNums[self.m_EnemyCamp] or 0),
                            maxScore      = self.m_CompleteScore,
                            } )
    else
        uimanager.show(self.m_UI)
    end
end


function TeamFight:EctypeEvaluate(msg)
    uimanager.hide(self.m_UI)
    uimanager.showdialog("arena.multi.pvp.dlgarenamultipvpevaluate",
                        { msgEvaluate   = msg.evaluate,
                          onClose       = function()
                            self:EctypeGrade(msg)
                          end})
end

function TeamFight:EctypeGrade(msg)
    uimanager.hide(self.m_UI)
    uimanager.showdialog("ectype.dlggrade",
            {   result      = (((msg.result > 0) and true) or false),
                bonus       = msg.bonus,
             --   text        = (((msg.errcode==0) and string.format(LocalString.Arena.ArenaGrade_Success,msg.newrank)) or LocalString.Arena.ArenaGrade_Failure),
                checkFunc   = function()
                    local msg = map.msg.CEctypeStatistic({})
                    network.send(msg)
                end,

                callback    = function()
                                uimanager.hidedialog("ectype.dlggrade")
                                uimanager.show(self.m_UI)
                                network.send(lx.gs.map.msg.CLeaveMap({}))
                            end})
end

function TeamFight:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    self.m_IsEctypeEnd = true
    if uimanager.isshow("dlguimain") then
        uimanager.call("dlguimain", "SwitchAutoFight", false)
    end
    self:EctypeEvaluate(msg)
    --self.m_ApertureMgr:OnEnd()
end

function TeamFight:EctypeStatistic(msg)
    -- printyellow(msg)
    Ectype.EctypeStatistic(self, msg)
    uimanager.showdialog("ectype.dlgstatistic", { statisticMsg = msg })
end


function TeamFight:EndTeamFight(msg)
    self.m_IsEctypeEnd = true
    if uimanager.isshow("ectype.dlgtower_revive") then
        uimanager.hide("ectype.dlgtower_revive")
    end
    self:EctypeEvaluate(msg)
end


function TeamFight:OnUpdateLoadingFinished()
    Ectype.OnUpdateLoadingFinished(self)
    self:UpdateTeamFightUI()
end

function TeamFight:EndExistCountDown()
    if self.m_IsEctypeEnd == false then
        return
    end

    local teamManager = require("ui.team.teammanager")
    if teamManager.IsInTeam() == true and teamManager.IsLeader() == false then
        if self.m_RemainTime > 7 then
            self.m_RemainTime = 7
        end
        -- self.m_TimeElapsedAfterEnd = self.m_TimeElapsedAfterEnd - 1
        if self.m_RemainTime <= 0 then
            for i = 1, 10 do
                local dlgName = uimanager.currentdialogname()
                if dlgName == "ectype.dlgstatistic"
                        or dlgName == "ectype.dlggrade"
                        or dlgName == "arena.multi.pvp.dlgarenamultipvpevaluate" then
                    uimanager.hidedialog(dlgName)
                else
                    break
                end
            end
            network.send(lx.gs.map.msg.CLeaveMap({}))
        end
    end
end


function TeamFight:Update()
    Ectype.Update(self)
    self:EndExistCountDown()
    --self.m_ApertureMgr:OnUpdate()
end

function TeamFight:late_update()

end


return TeamFight
