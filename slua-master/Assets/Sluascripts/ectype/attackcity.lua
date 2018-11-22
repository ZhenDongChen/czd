local Ectype    = require("ectype.ectypebase")
local UIManager = require("uimanager")

local AttackCity = Class:new(Ectype)


function AttackCity:__new(entryInfo)
	Ectype.__new(self,entryInfo, cfg.ectype.EctypeType.ATK_CITY)
	self.m_RemainTime = entryInfo.remaintime/1000
end

function AttackCity:OnEnd(msg)
	Ectype.OnEnd(self,msg)
	UIManager.hide("ectype.dlguiectype")
	local EctypeManager = require("ectype.ectypemanager")
	EctypeManager.RequestLeaveEctype()
end

function AttackCity:GetEctypeInfo()
	return  ConfigManager.getConfig("attackcity")
end


function AttackCity:OnUpdateLoadingFinished()
	Ectype.OnUpdateLoadingFinished(self)
	if UIManager.isshow(self.m_UI) then
        UIManager.call(self.m_UI,"AddDescription",self.m_EctypeInfo.introduce)
		UIManager.call(self.m_UI,"ShowGoal")
	end
end
function AttackCity:Update()
    if self.m_State==Ectype.EctypeLoadState.BeforeLoading then
        self:OnUpdateBeforeLoading()
    elseif self.m_State==Ectype.EctypeLoadState.Loading then
        self:OnUpdateLoading()
    elseif self.m_State==Ectype.EctypeLoadState.LoadingFinished then
        self:OnUpdateLoadingFinished()
		self.m_EctypeUI.InsertMissionInfomation(
			0,
			{ LocalString.Activity_AttackCity_Attack,"[u]" .. LocalString.Activity_AttackCity_Target .. "[/u]", LocalString.Activity_AttackCity_Reward},
			{ type = "monster", target = nil }
		)
    elseif self.m_State== Ectype.EctypeLoadState.BeforeStart then
        self:OnUpdateBeforeStart()
    else
        self:TimeUpdate()
        self:WallsUpdate()
    end
end
return AttackCity
