local network       = require("network")
local uimanager     = require("uimanager")
local Ectype        = require("ectype.ectypebase")
local TournamentInfo = require("ui.activity.tournament.tournamentinfo")

local dlgectype
local dlgmain
local ui
local Tournament = Class:new(Ectype)

function Tournament:__new(entryInfo)
    Ectype.__new(self,entryInfo, cfg.ectype.EctypeType.HUIWU)
    self.m_RemainTime       = entryInfo.remaintime/1000  + TournamentInfo.GetRoleRoundBeginTime()
    self.m_CountDownTimeBeforeStart = TournamentInfo.GetRoleRoundBeginTime()
    --printyellow(string.format("[Tournament:__new] entryInfo.remaintime=%s, TournamentInfo.GetRoleRoundBeginTime()=%s.", entryInfo.remaintime, TournamentInfo.GetRoleRoundBeginTime()))
end

function Tournament:CountDown(msg)
    --self.m_CountDownTimeBeforeStart = math.ceil(TournamentInfo.GetRoleRoundBeginTime())
    self.m_CountDownTimeBeforeStart = msg.endtime/1000 - timeutils.GetServerTime()    
    self.m_RemainTime       = self.m_ServerMsg.remaintime/1000  + self.m_CountDownTimeBeforeStart
    uimanager.ShowCountDownFlyText(self.m_CountDownTimeBeforeStart)
end

function Tournament:OnEnd(msg)
    Ectype.OnEnd(self,msg)
  --  self.m_DelayEndTime = cfg.ectype.Tournament.ENDOFFTIME
  --  self.m_EndMsg = msg
    self.m_EctypeUI = self.m_EctypeUI or require("ui." .. self.m_UI)
    local reInfo = (((msg.errcode == 0) and "[00DD00] (1/1)[-]") or "[00DD00] (0/1)[-]")
    uimanager.hide("ectype.dlguiectype")
    
    local TournamentManager   =require("ui.activity.tournament.tournamentmanager")
    if TournamentManager.IsInTournamentEctype() then
        uimanager.showdialog("ectype.dlggrade",
            {   result      = (1==msg.result) and true or false,
                --bonus       = msg.bonus,
                callback    = function()
                    uimanager.hidedialog("ectype.dlggrade")
                    uimanager.show("ectype.dlguiectype")
                    network.send(lx.gs.map.msg.CLeaveMap({}))
            end})    
    end
end

function Tournament:GetEctypeInfo()
    return ConfigManager.getConfig("huiwu")
end

--called by ectypemanager
function Tournament:late_update()
end

return Tournament
