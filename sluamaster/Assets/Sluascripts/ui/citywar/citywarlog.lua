

local CitywarLog = Class:new()

function CitywarLog:__new(msgLog)
    self.m_Id = msgLog.city
    self.m_DefenceFamilyName = msgLog.defencefamilyname
    self.m_AttackFamilyName = msgLog.attackfamilyname
    self.m_IsWin = (msgLog.win == 1)
    self.m_Time = msgLog.time/1000
end

function CitywarLog:GetTime()
    return self.m_Time
end

function CitywarLog:GetCityName()
    local cityInfo = require("ui.citywar.citywarinfo")
    local cityData = cityInfo.GetCity(self.m_Id)
    if cityData then
        return cityData:GetCityName()
    end
    return LocalString.None
end

function CitywarLog:GetTimeStr()
    local daytime = os.date("*t", self.m_Time)
    return string.format( LocalString.Family.FamilyWorld.TimeStr , daytime.year, daytime.month, daytime.day,daytime.hour, daytime.min  )
end

function CitywarLog:GetContent()
    if self.m_IsWin == true then
		if self.m_DefenceFamilyName == nil or self.m_DefenceFamilyName == "" then
			 return string.format( LocalString.Family.FamilyWorld.emptycity, 
                                self:GetTimeStr(), 
                                self.m_AttackFamilyName,
                                self:GetCityName()  )
		else
			return string.format( LocalString.Family.FamilyWorld.WinLog, 
									self:GetTimeStr(), 
									self.m_AttackFamilyName,
									self.m_DefenceFamilyName,
									self:GetCityName()  )
		end
    else
        return string.format( LocalString.Family.FamilyWorld.LoseLog, 
                                self:GetTimeStr(),
                                self.m_DefenceFamilyName,
                                self.m_AttackFamilyName,
                                self:GetCityName()  )
    end
    return ""
end

return CitywarLog