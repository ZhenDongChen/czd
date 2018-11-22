local ConfigManager = require("cfg.configmanager")
--竞技场战报类
local FightReportInfo = Class:new()

function FightReportInfo:__new(msg)
	self.m_Time 				= 0 			--战斗时间
	self.m_Action			 	= 0				--挑战还是被挑战，挑战别人是0，被挑战是1
	self.m_Result 				= 0 			--挑战结果，成功是0，失败是1
	self.m_ResultRank 			= 0				--挑战的结果排名
	self.m_OldRank				= 0
	--self.m_RankAction 			= 0				--上升，下降，不变，0不变，1下降，2上升
--	self.m_OpponentId 			= 0 			--对方的角色id
	self.m_OpponentName 		= 0				--对方角色名字

    if msg then
        self:Set(msg)
    end
end
--[[
<variable name="fighttime" type="long"/>
<variable name="challengetype" type="int"/>
<variable name="succ" type="int"/>
<variable name="newrank" type="int"/>
<variable name="opponentname" type="string"/>
]]
function FightReportInfo:Set(msgReportInfo)

	self.m_Time 				= msgReportInfo.fighttime
	self.m_Action 				= msgReportInfo.challengetype
	self.m_Result 				= msgReportInfo.succ
	self.m_ResultRank 			= msgReportInfo.newrank
--	self.m_RankAction 			= msgReportInfo.rankaction
--	self.m_OpponentId 			= msgReportInfo.peerroleid
	self.m_OpponentName 		= msgReportInfo.opponentname
	self.m_OldRank				= msgReportInfo.oldrank or 0
end


function FightReportInfo:ToString()
	local infoCfg = ConfigManager.getConfig("arenainfo")
	local str_info = ""
	if self.m_Action == 0 then
		if self.m_Result == 1 then
			if self.m_ResultRank < self.m_OldRank or self.m_OldRank == 0 then
				str_info = string.format(infoCfg["report_1"].content, self.m_OpponentName, self.m_ResultRank)
			else
				str_info = string.format(infoCfg["report_2"].content, self.m_OpponentName)
			end
		else
			str_info = string.format(infoCfg["report_3"].content, self.m_OpponentName) 
		end
	else
		if self.m_Result == 1 then
			str_info = string.format(infoCfg["report_4"].content, self.m_OpponentName) 
		else
			if self.m_ResultRank > self.m_OldRank then
				str_info = string.format(infoCfg["report_5"].content, self.m_OpponentName, self.m_ResultRank) 
			else	
				str_info = string.format(infoCfg["report_6"].content, self.m_OpponentName) 
			end
		end
	end
	return str_info
end

return FightReportInfo
