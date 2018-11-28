local SceneManager  = require("scenemanager")
local CameraManager = require("cameramanager")
local ConfigManager = require("cfg.configmanager")
local PlayerRole    = require("character.playerrole")
local Layout        = require("ectype.layout")
local network       = require("network")
local uimanager     = require("uimanager")
local tools         = require("ectype.ectypetools")
local Ectype        = require("ectype.ectypebase")



local dlgectype
local dlgmain
local ui
local PersonalBoss = Class:new(Ectype)


function PersonalBoss:__new(entryInfo)
    Ectype.__new(self,entryInfo,cfg.ectype.EctypeType.PERSONAL_BOSS)
    self.m_RemainTime       = entryInfo.remaintime/1000
    self.m_PlayerRole       = PlayerRole.Instance()
    self.m_CurrentReviveTime= 0
end

function PersonalBoss:SendRevive()
    local msg=map.msg.CRevive({})
    network.send(msg)
end

function PersonalBoss:OnEnd(msg)
    Ectype.OnEnd(self,msg)

    self.m_EctypeUI = self.m_EctypeUI or require("ui." .. self.m_UI)
    local reInfo = (((msg.errcode == 0) and "[00DD00] (1/1)[-]") or "[00DD00] (0/1)[-]")
    self.m_EctypeUI.InsertMissionInfomation(0, { LocalString.PersonalBoss_EctypeInfo[1],"[u]" .. self.m_EctypeInfo.name .. "[/u]" , reInfo} ,nil)
    uimanager.hide("ectype.dlguiectype")
    uimanager.showdialog("ectype.dlggrade",
                    {   result      = (((msg.errcode==0) and true) or false),
                        bonus       = msg.bonus,
                        callback    = function()
                            uimanager.hidedialog("ectype.dlggrade")
                            uimanager.show("ectype.dlguiectype")
                            network.send(lx.gs.map.msg.CLeaveMap({}))
                    end})

end

function PersonalBoss:OnUpdateLoadingFinished()
    Ectype.OnUpdateLoadingFinished(self)

    self.m_EctypeUI = self.m_EctypeUI or require("ui." .. self.m_UI)
    local monstersInfo = self.m_EctypeInfo.monsters[1].monsters

    if monstersInfo then
        local index = 0
        for monsterId, monsterNum in pairs(monstersInfo) do
            self.m_EctypeUI.InsertMissionInfomation(
                    index,
                    { LocalString.PersonalBoss_EctypeInfo[1],"[u]" .. self.m_EctypeInfo.name .. "[/u]" , "(0/1)"},
                    { type = "monster", target = monsterId })
            index = index + 1
         end
         self.m_EctypeUI.ShowGoal()
     end
end

function PersonalBoss:Update()
    Ectype.Update(self)
end

function PersonalBoss:late_update()

end

return PersonalBoss
