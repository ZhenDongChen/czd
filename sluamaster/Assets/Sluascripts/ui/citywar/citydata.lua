local require = require
local print = print
local mathutils = require "common.mathutils"
local FamilyManager = require("family.familymanager")

local citywarinfo
local CityData = Class:new()
local Default_Color_Index = 0

-------------------------CityData detail----------------------------
--[[
self.m_CityCfg(from config):
<struct name="CityInfo">
	<field name="cityid" type="int"/>
	<field name="name" type="string"/>
	<field name="level" type="CityLevelType"/>
	<field name="conectcity" type="list:int"/>
</struct> 

self.m_Info(from server):
<bean name="City">
	<variable name="city" type="int"/>
	<variable name="ispeace" type="byte"/>
	<variable name="timerangeindex" type="int"/>时间段
	<variable name="defencefamilyid" type="long"/>
	<variable name="defencefamilyname" type="string"/>
	<variable name="defencecolor" type="int"/>
	<variable name="attackfamilyid" type="long"/>
	<variable name="attackfamilyname" type="string"/>
	<variable name="attackcolor" type="int"/>
	<variable name="logoname" type="string"/>
	<variable name="stability" type="int"/>百分制
</bean>
--]]
-------------------------------------------------------------------


--------------------------------init start-----------------------------------
function CityData:__new(citycfg, levelcfg, info)
    citywarinfo 	  = require "ui.citywar.citywarinfo"

    self.m_CityCfg = citycfg    
    if nil==citycfg then
        print("[ERROR][CityData:__new] citycfg nil!")    
    end
    self.m_LevelCfg = levelcfg
    if nil==levelcfg then
        print("[ERROR][CityData:__new] levelcfg nil!")    
    end

    self:SetServerInfo(info)
end

function CityData:SetServerInfo(info)
	
    self.m_Info = info

    if self.m_Info then
        self.m_WarTimeRange = citywarinfo.GetWarTimeRangeText(self.m_Info.timerangeindex)
	--printyellow(">>>>>>>>>>>>>>citydataname",self.m_Info.logoname)
        --test
        --printyellow(string.format("[CityData:SetServerInfo] city[%s] color index=[%s], color= ", self.m_CityCfg.cityid, self.m_Info.defencecolor))
        --printt(self:GetDefenderColor())
    else
        self.m_WarTimeRange = LocalString.City_War_No_Duration
    end
end
--------------------------------init end-----------------------------------


--------------------------------info start-----------------------------------
--get city id
function CityData:GetCityId()
    return self.m_CityCfg and self.m_CityCfg.cityid or nil
end

--get city name
function CityData:GetCityName()
    return self.m_CityCfg and self.m_CityCfg.name or ""
end

--get colored city name
function CityData:GetCityColorName()
    return citywarinfo.GetColorText(self:GetDefenderHexColor(), self:GetCityName())
end

--Get City defender Logo Name
function CityData:GetLogoName()
    return self.m_Info and self.m_Info.logoname or nil
end

--get city level
function CityData:GetCityLevel()
    return self.m_CityCfg and self.m_CityCfg.level or 0
end

--get city level text
function CityData:GetCityLevelText()
    --printyellow("[CityData:GetCityLevelText] LocalString.City_War_Level[self.m_CityCfg.level] = ", LocalString.City_War_Level[self.m_CityCfg.level])
    return self.m_CityCfg and LocalString.City_War_Level[self.m_CityCfg.level+1] or ""
end

--get city listitemname
function CityData:GetListItemName()
    return self.m_CityCfg and self.m_CityCfg.listitemname or ""
end

--get city Neighbours
function CityData:GetConnections()
    return self.m_CityCfg and self.m_CityCfg.conectcity or nil
end

--Is Connected from self to cityid
function CityData:IsConnected(cityid)
    local result = false
    local connections = self:GetConnections()
    if connections and #connections>0 and cityid then
        for _, id in ipairs(connections) do
            if id==cityid then
                result = true
                break
            end
        end
    end
    return result
end

--Is Neighbour relation
function CityData:IsNeighbour(cityid)
    local result = self:IsConnected(cityid)
    if false==result then
        local citydata = citywarinfo.GetCity(cityid)
        result = citydata and citydata:IsConnected(self:GetCityId()) or false
    end
    return result
end
--------------------------------info end-----------------------------------


------------------------------------Defender start------------------------------------
--Get City Defender family id
function CityData:GetDefenderFamilyId()
    return self.m_Info and self.m_Info.defencefamilyid or nil
end

--color of city defend family
function CityData:GetDefenderColor()
    --printyellow("[CityData:GetDefenderColor] self.m_Info.defencecolor:", self.m_Info and self.m_Info.defencecolor or nil)
    --printyellow("[CityData:GetDefenderColor] defencecolor:")
    --printt((self.m_Info and self.m_Info.defencecolor) and citywarinfo.GetColorByIndex(self.m_Info.defencecolor) or citywarinfo.GetColorByIndex(1))
   -- printyellow("self.m_Info.defencecolor",tostring(self.m_Info.defencecolor))

    local colorindex = self.m_Info and self.m_Info.defencecolor or Default_Color_Index
   -- printyellow(colorindex)
    return citywarinfo.GetColorByIndex(colorindex)
end

--color of city defend family
function CityData:GetDefenderHexColor()
    local colorindex = self.m_Info and self.m_Info.defencecolor or Default_Color_Index
    return citywarinfo.GetHexColorByIndex(colorindex)
end

--Get City Defender family NAME
function CityData:GetDefenderFamilyName()
    return self.m_Info and self.m_Info.defencefamilyname or nil
end

--Get City Defender family colored NAME
function CityData:GetDefenderFamilyColorName()
    return citywarinfo.GetColorText(self:GetDefenderHexColor(), self:GetDefenderFamilyName())
end
------------------------------------Defender end------------------------------------


------------------------------------attacker start------------------------------------
--Get City attacker family id
function CityData:GetAttackerFamilyId()
    return self.m_Info and self.m_Info.attackfamilyid or nil
end

--color of city attack family
function CityData:GetAttackerColor()
    local colorindex = self.m_Info and self.m_Info.attackcolor or Default_Color_Index
    return citywarinfo.GetColorByIndex(colorindex)
end

--color of city attack family
function CityData:GetAttackerHexColor()
    local colorindex = self.m_Info and self.m_Info.attackcolor or Default_Color_Index
    return citywarinfo.GetHexColorByIndex(colorindex)
end

--Get City attack family NAME
function CityData:GetAttackerFamilyName()
    return self.m_Info and self.m_Info.attackfamilyname or nil
end

--Get City attack family colored NAME
function CityData:GetAttackerFamilyColorName()
    return citywarinfo.GetColorText(self:GetAttackerHexColor(), self:GetAttackerFamilyName())
end
------------------------------------attacker end------------------------------------


------------------------------------war start------------------------------------
--is city at peace
function CityData:IsPeace() 
    if self.m_Info then
        --printyellow(string.format("[CityData:IsPeace] city[%s] self.m_Info.ispeace=[%s].", self.m_CityCfg.cityid, self.m_Info.ispeace))
        return self.m_Info.ispeace==1
    else
        --printyellow(string.format("[CityData:IsPeace] city[%s] self.m_Info nil.", self.m_CityCfg.cityid))
        return true
    end
end

function CityData:OldfamilyName()
	if self.m_Info then
        --printyellow(string.format("[CityData:IsPeace] city[%s] self.m_Info.ispeace=[%s].", self.m_CityCfg.cityid, self.m_Info.ispeace))
        return self.m_Info.oldfamilyname
	end
end

--can declare war to city
function CityData:CanDeclareWar()  
	printyellow("CanDeclareWar")
    return citywarinfo.CanDeclareWar(self.m_CityCfg.cityid)
end

--Is Family Attacking this city
function CityData:IsFamilyAttacking()
    return FamilyManager.GetFamilyId()==self:GetAttackerFamilyId()
end

--Is Family Defending this city
function CityData:IsFamilyDefending()
    return self:GetAttackerFamilyId() and self:GetAttackerFamilyId()>0 and FamilyManager.GetFamilyId()==self:GetDefenderFamilyId()
end

--Get City Stability
function CityData:GetStability()
    --printyellow("[CityData:GetStability] stability=", self.m_Info and self.m_Info.stability or nil)   
    return self.m_Info and self.m_Info.stability or nil
end

--Get City Max Declare Invest money
function CityData:GetDeclareMaxInvest()
    return self.m_LevelCfg and self.m_LevelCfg.maxmoney or 0
end

--Get City Min Declare Invest money
function CityData:GetMinDeclareInvest()
    return self.m_LevelCfg and self.m_LevelCfg.minmoney or 0
end

--Get City war time Range
function CityData:GetWarTimeRangeText()
    return IsNullOrEmpty(self.m_WarTimeRange) and LocalString.City_War_No_Duration or self.m_WarTimeRange
end

--can enter City war time Range
function CityData:CanEnterCityWar()
    return self.m_Info and citywarinfo.CanEnterCityWar(self.m_Info.timerangeindex) or false
end

function CityData:IsCityWarOver()
	return self.m_Info and citywarinfo.IsOverWeekTimeRange(self.m_Info.timerangeindex) or self:IsPeace()
end

--is preparing City war
function CityData:IsPreparingWar()
    if self.m_Info then
        --local result, preparetime = citywarinfo.IsPreparingWar(self.m_Info.timerangeindex)
        --printyellow("[CityData:IsPreparingWar] return result, preparetime:", result, preparetime)
        return citywarinfo.IsPreparingWar(self.m_Info.timerangeindex)
    else
        --printyellow("[CityData:IsPreparingWar] self.m_Info nil!")
        return false
    end
end
------------------------------------war end------------------------------------


------------------------------------bonus start------------------------------------
--Exists lucky bonus
function CityData:ExistsLuckyBonus()
    return citywarinfo.ExistsLuckyBonus(self.m_CityCfg.cityid)
end

--Get City Tax Bonus weight
function CityData:GetTaxBonusWeight()
    return self.m_LevelCfg and self.m_LevelCfg.score or 0
end
------------------------------------bonus end------------------------------------

return CityData