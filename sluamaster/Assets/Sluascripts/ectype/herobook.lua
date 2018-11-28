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


local HeroBook = Class:new(Ectype)

function HeroBook:__new(entryInfo)
    Ectype.__new(self,entryInfo,cfg.ectype.EctypeType.HEROES)
 --   self.m_RemainTime       = entryInfo.remaintime/1000
    self.m_PlayerRole       = PlayerRole.Instance()
    -- self.m_TotalReviveTime  = self.m_EctypeInfo.maxrevivecount

    --self.m_HeroEctypeInfo = ConfigManager.getConfigData("heroectype",self.m_EctypeInfo. )

    self.m_CurrentReviveTime= 0
    self.m_GroupId = entryInfo.groupid
    self.m_EctypeId = entryInfo.ectypeid
end

function HeroBook:SendRevive()
    local msg=map.msg.CRevive({})
    network.send(msg)
end

function HeroBook:OnEnd(msg)
	print(" HeroBook:OnEnd(msg)")
    Ectype.OnEnd(self,msg)
    uimanager.hide("ectype.dlguiectype")
    uimanager.showdialog("ectype.dlggraderefresh", {
                        result       = (((msg.retcode==0) and true) or false),
                        awardinfo    = msg.awardinfo,

                        refreshtimes = #self.m_EctypeInfo.heroectypebonus,
                        groupid      = self.m_GroupId,
                        ectypeid     = self.m_EctypeId,

                        callback     = function()
                                uimanager.hidedialog("ectype.dlggraderefresh")
                                uimanager.show("ectype.dlguiectype")
                                network.send(lx.gs.map.msg.CLeaveMap({}))
                            end})

end

function HeroBook:OnUpdateLoadingFinished()
    Ectype.OnUpdateLoadingFinished(self)
    self.m_EctypeUI = self.m_EctypeUI or require("ui." .. self.m_UI)

    local monstersInfo = self.m_EctypeInfo.monsters[1].monsters

    if monstersInfo then
        local index = 0
        for monsterId, monsterNum in pairs(monstersInfo) do
            local monsterCfg = ConfigManager.getConfigData("monster", monsterId)
            self.m_EctypeUI.InsertMissionInfomation(
                    index,
                    { LocalString.PersonalBoss_EctypeInfo[1],"[u]" .. monsterCfg.name .. "[/u]" , "(0/1)"},
                    { type = "monster", target = monsterId })
            index = index + 1
        end
        self.m_EctypeUI.ShowGoal()
    end
end


function HeroBook:Update()
    Ectype.Update(self)

end

function HeroBook:late_update()

end

return HeroBook
