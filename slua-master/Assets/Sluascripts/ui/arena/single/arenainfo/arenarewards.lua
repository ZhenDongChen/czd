local BonusManager = require("item.bonusmanager")

--奖励信息
local RewardsInfo = Class:new()

function RewardsInfo:__new(config)
	self.m_Times		= 0
	self.m_Items 		= {}
	self.m_IsReceived 	= false 			--是否已经领取
    if config then
        self:ConfigSet(config)
    end
end
function RewardsInfo:ConfigSet(config)
	self.m_Times = config.times
	self.m_Items = BonusManager.GetItemsByBonusConfig(config.award) or {}
end

function RewardsInfo:SetReceived(isReceive)
	self.m_IsReceived = isReceive
end


function RewardsInfo:TextString()
	return tostring(LocalString.Arena.RewardsText[1]) 
			.. tostring(self.m_Times) 
			--.. tostring(LocalString.NumberCapitalForm[self.m_Times + 1]) 
			.. tostring(LocalString.Arena.RewardsText[2])
end



return RewardsInfo

