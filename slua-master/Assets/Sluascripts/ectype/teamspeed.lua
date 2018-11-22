local PlayerRole    = require"character.playerrole"
local network       = require"network"
local uimanager     = require"uimanager"
local tools         = require"ectype.ectypetools"
local EctypeBase    = require"ectype.ectypebase"
local SceneManager = require"scenemanager"

local TeamSpeed = Class:new(EctypeBase)

function TeamSpeed:__new(entryInfo)
    local cfgTeamSpeed              = ConfigManager.getConfig("teamspeed")
    self.m_ExtendEctypeInfo         = cfgTeamSpeed.lvmsg_id[entryInfo.levelindex]
    entryInfo.ectypeid              = self.m_ExtendEctypeInfo.ectypeid
    EctypeBase.__new(self,entryInfo,cfg.ectype.EctypeType.TEAMSPEED)
    self.m_PlayerRole               = PlayerRole.Instance()
    self.m_Team                     = entryInfo.teamid
    self.m_TeamEctypeInfo           = self.m_Team == 2 and self.m_ExtendEctypeInfo.team1 or self.m_ExtendEctypeInfo.team2
    self.m_Enemy                    = self.m_Team == 2 and 3 or 2
    self.m_CurrScore                = entryInfo.teamscore
    self.m_CurrDmg                  = {}
    self.m_CurrRegionInfoIndex      = self:GetCurrentGrade()
    self.m_CurrAreaID               = self.m_TeamEctypeInfo.speedregioninfo[self.m_CurrRegionInfoIndex].regionid
    self.m_UpgradeScore             = self:GetNextGradeScore()
    self.m_UI                       = "ectype.dlgbattlefieldui"
    self.m_UIList                   = {self.m_UI,"dlgjoystick"}
    self.m_Description              = self.m_TeamEctypeInfo.speedregioninfo[self.m_CurrRegionInfoIndex].decs
    self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid,self.m_CurrAreaID)
end

function TeamSpeed:GetLvMsgId(cfgTeamSpeed,ectypeid)
    for _,speedlvmsg  in ipairs(cfgTeamSpeed.lvmsg) do
        if speedlvmsg.ectypeid == ectypeid then
            return speedlvmsg.id
        end
    end
end

function TeamSpeed:GetEctypeInfo()
    return self.m_ExtendEctypeInfo
end

function TeamSpeed:GetScore(team)
    return self.m_CurrScore[team] or 0
end

function TeamSpeed:GetDmg(team)
    return self.m_CurrDmg[team] or 0
end

function TeamSpeed:GetCurrentGrade()
    local speedRegionInfos = self.m_TeamEctypeInfo.speedregioninfo
    for idx,regioninfo in ipairs(speedRegionInfos) do
        if self:GetScore(self.m_Team) < regioninfo.needgrade then
            return idx - 1
        end
    end
    return #speedRegionInfos
end

function TeamSpeed:GetNextGradeScore()
    if self.m_TeamEctypeInfo.speedregioninfo[self.m_CurrRegionInfoIndex + 1] then
        return self.m_TeamEctypeInfo.speedregioninfo[self.m_CurrRegionInfoIndex + 1].needgrade
    else
        return 1e10
    end
end

function TeamSpeed:NextGrade()
    self.m_CurrRegionInfoIndex  = self.m_CurrRegionInfoIndex + 1
    self:RemoveAirWallArea(self.m_CurrAreaID)
    self.m_CurrAreaID           = self.m_TeamEctypeInfo.speedregioninfo[self.m_CurrRegionInfoIndex].regionid
    self.m_UpgradeScore         = self:GetNextGradeScore()
    self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid,self.m_CurrAreaID)
    self.m_Description = self.m_TeamEctypeInfo.speedregioninfo[self.m_CurrRegionInfoIndex].decs
    local pos = self.m_TeamEctypeInfo.speedregioninfo[self.m_CurrRegionInfoIndex].aimposition
    local param = {
        targetPos = Vector3(pos.x,pos.y, 0),
        lengthCallback = {{length=300,callback=function()
            uimanager.call("dlguimain","SwitchAutoFight",true)
        end}},
        stopCallback = function()
            uimanager.call("dlguimain","SwitchAutoFight",true)
        end,
    }
    PlayerRole.Instance():navigateTo(param)
    return self.m_TeamEctypeInfo.speedregioninfo[self.m_CurrRegionInfoIndex].decs
end

function TeamSpeed:SyncTeamScore(msg)
    self.m_CurrScore = msg.teamscore
    uimanager.call(self.m_UI,"ChangeScore",{
        teamscore=self:GetScore(self.m_Team),
        enemyscore=self:GetScore(self.m_Enemy)
    })
    if self:GetScore(self.m_Team) >= self.m_UpgradeScore then
        info = self:NextGrade()
        -- 飞字
        uimanager.call("dlgflytext","AddSystemInfo",self.m_Description)
        uimanager.call(self.m_UI,"ChangeDescription",self.m_Description)
    end
end

function TeamSpeed:SyncTeamDmg(msg)
    self.m_CurrDmg = msg.bossdamage
    uimanager.call(self.m_UI,"ChangeDmg",{
        teamdmg = self:GetDmg(self.m_Team),
        enemydmg = self:GetDmg(self.m_Enemy),
    })
end

function TeamSpeed:OnEnd(msg)
    EctypeBase.OnEnd(self,msg)
    uimanager.hide(self.m_UI)
    uimanager.showdialog("ectype.dlggrade",
    {   result      = (((msg.result > 0) and true) or false),
        bonus       = msg.bonus,
        checkFunc   = function() network.send(map.msg.CEctypeStatistic({})) end,
        callback    = function()
            uimanager.hidedialog("ectype.dlggrade")
            uimanager.show(self.m_UI)
            network.send(lx.gs.map.msg.CLeaveMap({}))
        end
    })
end

function TeamSpeed:EctypeStatistic(msg)
    EctypeBase.EctypeStatistic(self, msg)
    uimanager.showdialog("ectype.dlgstatistic", { statisticMsg = msg,hidekill = true })
end


function TeamSpeed:OnUpdateLoadingFinished()
    if uimanager.isshow(self.m_UI) then

    end
    EctypeBase.OnUpdateLoadingFinished(self)
end

function TeamSpeed:OnUpdateLoading()
    EctypeBase.OnUpdateLoading(self)
    if not SceneManager.IsLoadingScene() then
        local tb = {}
        -- local bossid    = self.m_ExtendEctypeInfo.bossref.monsterid
        -- local bossdata  = ConfigManager.getConfigData("monster",bossid)
        tb.teamscore    = self:GetScore(self.m_Team)
        tb.enemyscore   = self:GetScore(self.m_Enemy)
        tb.teamdmg      = self:GetDmg(self.m_Team)
        tb.enemydmg     = self:GetDmg(self.m_Enemy)
        -- tb.bosshp       = bossdata.attr.hp
        tb.upgradescore = self.m_UpgradeScore
        tb.description  = self.m_Description
        uimanager.call(self.m_UI,"refresh",tb)
    end
end

function TeamSpeed:Update()
    EctypeBase.Update(self)
end

function TeamSpeed:late_update()

end

return TeamSpeed
