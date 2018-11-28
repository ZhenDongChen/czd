local StateBase         = require("character.navigation.navigationstate.statebase")
local ConfigManager     = require("cfg.configmanager")
local NavigationHelper  = require("character.navigation.navigationhelper.navigationhelper") 
local UIManager         = require("uimanager")

local StateStartSet = Class:new(StateBase)

function StateStartSet:__new(controller,mapId,lineId,showAlert)
    StateBase.__new(self,controller,"StateStartSet")
    self.m_MapId = mapId
    self.m_LineId = lineId
    self.m_ShowAlert = showAlert
end

function StateStartSet:Start()
    StateBase.Start(self)
    
    if self.m_ShowAlert == true then
        local mapInfo = ConfigManager.getConfigData("worldmap",self.m_MapId or self.m_Player:GetMapId())
        local mapName = NavigationHelper.Config.SceneNameColor .. mapInfo.mapname .. "[-]"
        local changecontent

        if self.m_MapId ~= nil and self.LineId ~= nil then
            changecontent = string.format(LocalString.Navigation.ChangeMapLineInfo,mapName,self.LineId)
        elseif self.m_MapId == nil and self.LineId ~= nil then
            changecontent = string.format(LocalString.Navigation.ChangeLineInfo,self.LineId)
        else
            changecontent = string.format(LocalString.Navigation.ChangeMapInfo,mapName)
        end
		--TODO处于跟随状态的时候才会显示这个界面，取消完之后就不会再弹出
		if PlayerRole:Instance():IsFollowing() then
			UIManager.ShowAlertDlg({
                immediate       = true,
                title           = LocalString.Navigation.ChangMapTip,
                content         = changecontent,
                sureText        = LocalString.Navigation.ChangMapSure,
                cancelText      = LocalString.Navigation.ChangMapCancel,
                callBackFunc    = function()
                    self.m_Controller:OnStart()
                    self:End()
                end,
                callBackFunc1 = function()
                    local TeamManager=require"ui.team.teammanager"
                    TeamManager.RequestCancelFollowing(true)
                    self:End()
                    self.m_Controller:StopNavigate()
                end,})
		end
       
				
				
    else
        self.m_Controller:OnStart()
        self:End()
    end
end

function StateStartSet:Update()
    StateBase.Update(self)
end

function StateStartSet:End()
    StateBase.End(self)
end 

return StateStartSet
