local ConfigMgr 	  = require "cfg.configmanager"
local UIManager 		= require("uimanager")
local gameevent         = require "gameevent"
local CityData = require"ui.citywar.citydata"
local FamilyManager = require("family.familymanager")
local CitywarLog = require("ui.citywar.citywarlog")
local CitywarTip = require("ui.citywar.citywartip")
local bonusmanager 	  = require "item.bonusmanager"
local citywarmanager

------------------------data start------------------------
--cfg
local m_CityWarCfg

--family City Info
local m_FamilyColor
local m_FamilyCityWarStage
local m_FamilyLogoname
local m_FamilyOwnCitys  --type="vector" value="int"
local m_FamilyDeclareWarCityId
local m_FamilyDeclareMoney
local m_FamilyLuckyAwards --type="map.msg.Bonus"
local m_FamilyCityCounts --map<level, count>
local m_FamilyTaxBonus --list<"cfg.cmd.action.Bonus">
local m_IsCityWarOver

--log
local m_FamilyLogs
local m_FamilyTips


--war
local m_HasNewWar = false
local m_FamilyWeekBattles --type="map" key="int" value="BattleInfo"
local Prepare_War_Interval = 300

--all City Data
local m_AllCities --map<id, citydata>

--can declare war Cities
local m_CanDeclareCities --map<id, citydata>

--world lucky award
local m_WorldLuckyAwards --type="map" key="int" value="map.msg.Bonus"
------------------------data end------------------------


------------------------utils start------------------------
local function reset()
    --family City Info
    m_FamilyColor = nil
    m_FamilyCityWarStage = nil
    m_FamilyLogoname = nil
    m_FamilyOwnCitys = nil
    m_FamilyDeclareWarCityId = nil
    m_FamilyDeclareMoney = nil
    m_FamilyLuckyAwards = nil
    m_FamilyCityCounts = nil
    m_FamilyTaxBonus = nil

    --log
    m_FamilyLogs = nil
    --m_FamilyTips = nil

    --war
    m_HasNewWar = false
    m_FamilyWeekBattles = nil
    
    --all City Data
    if m_AllCities then
        for cityid,citydata in pairs(m_AllCities) do
            if citydata then
                citydata:SetServerInfo(nil)
            end
        end 
    end

    --can declare war Cities
    m_CanDeclareCities = nil

    --world lucky award
    m_WorldLuckyAwards = nil
end

local function GetDefaultHexColor()
    return m_CityWarCfg.colors[1] and m_CityWarCfg.colors[1] or "ffffff"
end

local function SetCityWarOver(cityover)
	m_IsCityWarOver  = cityover
end

local function GetCityWarIsOver()
	if m_IsCityWarOver ~= nil then
		return m_IsCityWarOver
	else
		return false
	end
	
end

--index starts from 0
local function GetHexColorByIndex(index)
    if index then
        index = index+1
    end

    if index then
        return m_CityWarCfg.colors[index] and m_CityWarCfg.colors[index] or GetDefaultHexColor()
    else
        return GetDefaultHexColor()
    end
end

--index starts from 0
local function GetColorByIndex(index)
    if index then
        index = index+1
    end

    local color = mathutils.IntToColorWithoutAlpha(tonumber("0x"..GetDefaultHexColor()))
    if index and m_CityWarCfg.colors[index] then
        --printyellow(string.format("[citywarinfo:GetColorByIndex] index=%s, m_CityWarCfg.colors[index]=%s, tonumber(0x..m_CityWarCfg.colors[index])=%s.", index, m_CityWarCfg.colors[index], tonumber("0x"..m_CityWarCfg.colors[index]) ))
        local colorint = tonumber("0x"..m_CityWarCfg.colors[index])
        color = colorint and mathutils.IntToColorWithoutAlpha(colorint) or color
        --printyellow("[citywarinfo:GetColorByIndex] get color at index:", index)
        --printt(color)
    end
    return color
end

--Get City detail by id
--return: CityData
local function GetCity(cityid)
    local citydata
    if cityid and m_AllCities then
        citydata = m_AllCities[cityid]
    end
    return citydata
end


local function GetColorText(hexcolor, text)
    if hexcolor and not IsNullOrEmpty(text) then
        --printyellow("[citywarinfo:GetColorText] return:")
        --printt(string.format(LocalString.City_War_Text_Color_Name, hexcolor, text))
        return string.format(LocalString.City_War_Text_Color_Name, hexcolor, text)
    else
        --printyellow("[citywarinfo:GetColorText] return:", text)
        return text
    end
end
------------------------utils end------------------------


------------------------city award start------------------------
local function SetWorldLuckyBonus(luckyaward)
    --printyellow("[citywarinfo:SetWorldLuckyBonus] Set m_WorldLuckyAwards:")
   -- printt(luckyaward)
    m_WorldLuckyAwards = luckyaward
end

--get world lucky awards
local function GetWorldLuckyBonus()
    --printyellow("[citywarinfo:GetWorldLuckyBonus] get m_WorldLuckyAwards:")
    --printt(m_WorldLuckyAwards)
    return m_WorldLuckyAwards
end

local function ExistsLuckyBonus(cityid)
    local result = false
    if cityid and m_WorldLuckyAwards then
        for id,bonus in pairs(m_WorldLuckyAwards) do
            if id==cityid then
                result = true
                break
            end
        end        
    end
    return result
end
------------------------city award end------------------------


------------------------family city start------------------------
local function SetFamilyLuckyBonus(luckyaward)
    --printyellow("[citywarinfo:SetFamilyLuckyBonus] Set m_FamilyLuckyAwards:")
    --printt(luckyaward)
    m_FamilyLuckyAwards = luckyaward
    
    --refresh map battle red dot
    if UIManager.isshow("citywar.tabfamilyworld") then
        UIManager.refresh("citywar.tabfamilyworld", { refresh = { ["luckybonus"] = true } })
    end
    
    --更新 tabcitywaraward
    if UIManager.isshow("citywar.tabcitywaraward") then
        UIManager.call("citywar.tabcitywaraward","RefreshFamilyLuckyBonus")
    end    
end

--return:type="map.msg.Bonus"
local function GetFamilyLuckyBonus()
    --printyellow("[citywarinfo:GetFamilyLuckyBonus] Get m_FamilyLuckyAwards:")
    --printt(m_FamilyLuckyAwards)
    return m_FamilyLuckyAwards
end

local function HasFamilyLuckyBonus()
    local familyluckybonus
	local familyluckybonusNumber  = 0
    if m_FamilyLuckyAwards then
        familyluckybonus = bonusmanager.GetItemsOfServerBonus(m_FamilyLuckyAwards)
    end
	if familyluckybonus == nil then
		return false 	
	else
		for i , bounsdata in ipairs(familyluckybonus) do 
			if bounsdata.Number == 0 then
				familyluckybonusNumber = familyluckybonusNumber+1
			end
		end
	end
    return familyluckybonus and table.getn(familyluckybonus) ~= familyluckybonusNumber
end

local function HasFamilyLucky()
    local familyluckybonus
    if m_FamilyLuckyAwards then
        familyluckybonus = bonusmanager.GetItemsOfServerBonus(m_FamilyLuckyAwards)
    end
    return familyluckybonus and table.getn(familyluckybonus)>0
end


--set City tax award
local function SetFamilyTaxBonus(familycities)
    --printyellow("[citywarinfo:SetFamilyTaxBonus] set family Tax Bonus:")
    --printt(familycities)
    m_FamilyTaxBonus = {}
    if m_CityWarCfg and m_CityWarCfg.scorebonuss and familycities and #familycities>0 then
        --calculate score
        local score = 0
        for _,cityid in ipairs(familycities) do
            local citydata = m_AllCities[cityid]
            if citydata then
                score = score+citydata:GetTaxBonusWeight()
            end
        end        
        --match scorebonus        
        local familyscorebonus
        for _,scorebonus in ipairs(m_CityWarCfg.scorebonuss) do
            if scorebonus and scorebonus.upperboundscore >= score then
                familyscorebonus = scorebonus
				break
            end
        end

        --extract tax bonus
        if familyscorebonus then
            table.insert(m_FamilyTaxBonus, familyscorebonus.bonus)
        end
    end
    --printt(m_FamilyTaxBonus)
end

--get family tax award
--list<"cfg.cmd.action.Bonus">
local function GetFamilyTaxBonus()
    --printyellow("[citywarinfo:GetFamilyTaxBonus] get family Tax Bonus:")
    --printt(m_FamilyTaxBonus)
    return m_FamilyTaxBonus
end

local function SetFamilyColor(color)
    --printyellow("[citywarinfo:SetFamilyColor] Set family color index:", color)
    m_FamilyColor = color
end

--get City lucky award
local function GetFamilyColor()
    --printyellow("[citywarinfo:GetFamilyColor] get m_FamilyColor:", m_FamilyColor)
    return m_FamilyColor
end

local function SetFamilyCityWarStage(stage)
    --printyellow("[citywarinfo:SetFamilyCityWarStage] Set m_FamilyCityWarStage:", stage)
    if m_FamilyCityWarStage ~= stage then
        citywarmanager.send_CGetAllCitys()
    end

    m_FamilyCityWarStage = stage

    if UIManager.isshow("citywar.tabfamilyworld") then
        UIManager.refresh("citywar.tabfamilyworld", { refresh = { ["tip"] = true } })
    end
end

local function GetFamilyCityWarStage()
    --printyellow("[citywarinfo:GetFamilyCityWarStage] get m_FamilyCityWarStage:", m_FamilyCityWarStage)
    return m_FamilyCityWarStage
	--return 1
end

local function SetFamilyDeclareWarInfo(cityid, declaremoney)
    --printyellow("[xxxxxxxxxxxxxxxx   citywarinfo:SetFamilyDeclareWarInfo] Set cityid & declaremoney:", cityid, declaremoney)
    m_FamilyDeclareWarCityId = cityid
    m_FamilyDeclareMoney = declaremoney
end

--get family city current DeclareMoney
local function GetFamilyDeclareMoney()
    return m_FamilyDeclareMoney and m_FamilyDeclareMoney or 0
end

--get family city current DeclareWarCityId
local function GetFamilyDeclareCity()
    return m_FamilyDeclareWarCityId
end

--has family declare war to city current DeclareWarCityId
local function HasFamilyDeclareCity()
    return m_FamilyDeclareWarCityId and m_FamilyDeclareWarCityId>0 or false
end

local function SetFamilyLogoname(logoname)
    --printyellow("[citywarinfo:SetFamilyLogoname] Set m_FamilyLogoname:", logoname)
    m_FamilyLogoname = logoname
end

local function GetFamilyLogoname()
    --printyellow("[citywarinfo:GetFamilyLogoname] get m_FamilyLogoname:", m_FamilyLogoname)
    return m_FamilyLogoname
end

--set Family City Counts
local function SetFamilyCityCounts(familycities)
    --printyellow("[citywarinfo:SetFamilyCityCounts] set Family City Counts:")
    m_FamilyCityCounts = {}
    if familycities and #familycities>0 then
        local count
        for _,cityid in ipairs(familycities) do
            local citydata = m_AllCities[cityid]
            if citydata then
                count = m_FamilyCityCounts[citydata:GetCityLevel()]
                if nil==count or count<0 then
                    m_FamilyCityCounts[citydata:GetCityLevel()] = 1
                else
                    m_FamilyCityCounts[citydata:GetCityLevel()] = count+1
                end
            end
        end        
    end
end

--get Family City Counts
--return map<level, count>
local function GetFamilyCityLevelCounts()
    --printyellow("[citywarinfo:GetFamilyCityLevelCounts] get Family City Counts:")
    --printt(m_FamilyCityCounts)
    return m_FamilyCityCounts
end

--set Family city
local function SetFamilyCities(familycities)
    --printyellow("[citywarinfo:SetFamilyCities] Set m_FamilyOwnCitys:")
    --printt(familycities)

    m_FamilyOwnCitys = familycities
    SetFamilyCityCounts(familycities)
    SetFamilyTaxBonus(familycities)
end

--get Family city
local function GetFamilyCities()
    --test
    --m_FamilyOwnCitys = {4, 5, 1, 2, 3, 6, 7}

    return m_FamilyOwnCitys
end

--get Family city
local function GetFamilyCityCount()
    --test
    --return 7

    return m_FamilyOwnCitys and #m_FamilyOwnCitys or 0
end

--is Family city
local function IsFamilyCity(cityid)
    local result = false
    if cityid and m_FamilyOwnCitys and #m_FamilyOwnCitys>0 then
        for _,id in ipairs(m_FamilyOwnCitys) do
            if id==cityid then
                result = true
                break
            end
        end        
    end
    --printyellow(string.format("[citywarinfo:IsFamilyCity] [%s] IsFamilyCity=[%s].", cityid, result))
    return result
end

local function IsFamilyNeighbour(cityid)
    local result = false
    if cityid and m_FamilyOwnCitys and #m_FamilyOwnCitys>0 then
        local familycitydata
        for _,id in ipairs(m_FamilyOwnCitys) do
            familycitydata = GetCity(id)
            if familycitydata and familycitydata:IsNeighbour(cityid) then
                result = true
                break
            end
        end        
    end
    return result
end

--set family city info
--[[
<protocol name="SInfo">
	<variable name="stage" type="int"/>
	<variable name="logoname" type="string"/>
	<variable name="owncitys" type="vector" value="int"/>
	<variable name="declarewarcity" type="int"/>
	<variable name="declaremoney" type="long"/>
	<variable name="luckybonus" type="map.msg.Bonus"/>
</protocol>
--]]
local function SetFamilyCityInfo(msg)
   -- printyellow("xxxxxxxxxxxxxxxxxxxxxx[citywarinfo:SetFamilyCityInfo] Set FamilyCityInfo:", msg.declarewarci,msg.declaremoney,msg.owncitys)
    SetFamilyCityWarStage(msg.stage)
    SetFamilyLogoname(msg.logoname)
    SetFamilyCities(msg.owncitys)
    SetFamilyDeclareWarInfo(msg.declarewarcity, msg.declaremoney)
    SetFamilyLuckyBonus(msg.luckybonus)
end
------------------------family city end------------------------


------------------------war start------------------------
local function GetDeclareWarFamilyLevel()
    return m_CityWarCfg and m_CityWarCfg.minfamilylevel.level or 0
end

--[[
--deleted:SInfo may comes after SGetAllCitys, then SetDeclareCities() get nothing
--set cities can be declared
local function SetDeclareCities()
    printyellow("[citywarinfo:SetDeclareCities] Set m_CanDeclareCities:", msg)
    m_CanDeclareCities = {}
    for cityid,citydata in pairs(m_AllCities) do
        if citydata and citydata:CanDeclareWar() then
            table.insert(m_CanDeclareCities, cityid, citydata)
        end
    end 
    printt(m_CanDeclareCities)
end
--]]

--get cities can be declared
local function GetDeclareCities()
    --printyellow("[citywarinfo:GetDeclareCities] get m_CanDeclareCities:", msg)
    m_CanDeclareCities = {}
    for cityid,citydata in pairs(m_AllCities) do
        if citydata and citydata:CanDeclareWar() then
            table.insert(m_CanDeclareCities, cityid, citydata)
        end
    end 
    --printt(m_CanDeclareCities)
    return m_CanDeclareCities
end

local function GetDayTime(weektime)
    local daytime = ""
    if weektime then
        daytime = string.format( "%02d:%02d", weektime.hour, weektime.minute)
    end
    return daytime
end

local function GetWeekTimeRange(weektimerange)
    local timerange = LocalString.City_War_No_Duration
    if weektimerange then
        local week = LocalString.WeekCapitalForm[weektimerange.begintime.weekday]
        week = week and week or ""
        local startdaytime = GetDayTime(weektimerange.begintime)
        local enddaytime = GetDayTime(weektimerange.endtime)
        timerange = string.format(LocalString.City_War_War_Range, week, startdaytime, enddaytime)
    end
    return timerange
end

--get War TimeRange by index
local function GetWarTimeRangeText(battleindex)
    local timerange = LocalString.City_War_No_Duration
    if battleindex and m_CityWarCfg.battletimes[battleindex] then
        timerange = GetWeekTimeRange(m_CityWarCfg.battletimes[battleindex])
    end
    return timerange
end

local function CompareInt(a, b)
    local result = 0
    if a and b then
        if a>b then
            result = 1
        elseif a<b then
            result = -1
        else
            result = 0
        end
    end
    return result
end

--[[
weektime:
<struct name="WeekTime" delimiter=":|-">��ʽ  ww-hh:mm:ss
	<field name="weekday" type="int"/> 1 - 7 ��Ӧ��һ������
	<field name="hour" type="int"/>
	<field name="minute" type="int"/>
	<field name="second" type="int"/>
</struct>
localdatetime:
    year (four digits), month (1--12), day (1--31), 
    hour (0--23), min (0--59), sec (0--61), 
    wday (weekday, Sunday is 1), yday (day of the year), 
    isdst (daylight saving flag, a boolean).
--]]
local function CompareWeekTime(weektime, localdatetime)    
    --[[
    printyellow("[citywarinfo:CompareWeekTime]weektime  localdatetime:")
    printt(weektime)
    printt(localdatetime)
    --]]

    local result = 0
    if weektime and localdatetime then
        --weekday
        local localweekday = localdatetime.wday
        --sunday is the first day
        if localweekday == 1 then
            localweekday = 7
        else
            localweekday = localweekday -1
        end
        result = CompareInt(weektime.weekday, localweekday)
        if 0~=result then
            return result
        end
        
        --hour
        result = CompareInt(weektime.hour, localdatetime.hour)
        if 0~=result then
            return result
        end
        
        --minute
        result = CompareInt(weektime.minute, localdatetime.min)
        if 0~=result then
            return result
        end
        
        --second
        result = CompareInt(weektime.second, localdatetime.sec)
    else
        if nil==weektime then
            --printyellow("[citywarinfo:CompareWeekTime] weektime nil!")
        end
        if nil==localdatetime then
            --printyellow("[citywarinfo:CompareWeekTime] localdatetime nil!")
        end
    end
    return result
end

local function IsInWeektimeRange(weektimerange)
    local result = false
    if weektimerange then
        local localdatetime = timeutils.TimeNow()
		
        result = CompareWeekTime(weektimerange.begintime, localdatetime)<=0 and CompareWeekTime(weektimerange.endtime, localdatetime)>=0
    end
    --printyellow("[citywarinfo:IsInWeektimeRange] IsInWeektimeRange=", result)
    return result
end

local function IsOverWeekTimeRange(weektimerange)
	 local result = false
	if weektimerange then
		local localdatetime = timeutils.TimeNow()
		if m_CityWarCfg.battletimes ~= nil then
			result =  CompareWeekTime(m_CityWarCfg.battletimes[weektimerange].endtime ,localdatetime) <= 0
		end
	end
    return result	

end

--Can Enter City War
local function CanEnterCityWar(battleindex)
	--TODO临时屏蔽战争时间段
    local result = false
    if battleindex and m_CityWarCfg.battletimes[battleindex] then
        result = IsInWeektimeRange(m_CityWarCfg.battletimes[battleindex])
    end
    return result
end

local function GetWeekTimeSeconds(weektime)
    local seconds = 0

    local curweekday = 0
    local curhour = 0
    local curminite = 0
    local cursecond = 0
    if weektime then
        --printyellow("[TournamentInfo:GetWeekTimeSeconds] weektime:")
        --printt(weektime)
        curweekday = weektime.weekday and weektime.weekday or curweekday
        curhour = weektime.hour and weektime.hour or curhour
        curminite = weektime.minute and weektime.minute or curminite
        cursecond = weektime.second and weektime.second or cursecond
    else
        local timenow= timeutils.TimeNow()
        --printyellow("[TournamentInfo:GetWeekTimeSeconds] timeutils.TimeNow():")
        --printt(timenow)
        curweekday = timenow.wday and timenow.wday or curweekday
        curhour = timenow.hour and timenow.hour or curhour
        curminite = timenow.min and timenow.min or curminite
        cursecond = timenow.sec and timenow.sec or cursecond
        --sunday is the first day
        if curweekday == 1 then
            curweekday = 7
        else
            curweekday = curweekday -1
        end
    end
    --printyellow(string.format("[TournamentInfo:GetWeekTimeSeconds] curweekday=%s, curhour=%s, curminite=%s, cursecond=%s!", curweekday, curhour, curminite, cursecond))
    seconds = seconds + (curweekday-1)*86400
    seconds = seconds + curhour*3600
    seconds = seconds + curminite*60
    seconds = seconds + cursecond

    return seconds
end

local function IsInPrepareTimerange(weektimerange)
    local result = false
    local preparetime = 0
    if weektimerange then
        local citywartime = GetWeekTimeSeconds(weektimerange.begintime)
        local curweektime = GetWeekTimeSeconds()
        preparetime = citywartime-curweektime

        --test
        --preparetime = 10
        
        --printyellow("[citywarinfo:IsInPrepareTimerange] citywartime-curweektime =", preparetime)
        if preparetime and preparetime>0 and preparetime<=Prepare_War_Interval then
            result = true
        end
    end
    --printyellow("[citywarinfo:IsInPrepareTimerange] IsInWeektimeRange=", result)
    return result, preparetime
end

--is preparing City war
local function IsPreparingWar(battleindex)
    local result = false
    local preparetime = 0
    if battleindex and m_CityWarCfg.battletimes[battleindex] then
        result, preparetime = IsInPrepareTimerange(m_CityWarCfg.battletimes[battleindex])
    end

	--test
	--result =true
	--preparetime = 300

    --printyellow("[citywarinfo:IsPreparingWar] return result, preparetime:", result, preparetime)
    return result, preparetime
end

local function SetNewBattleState(value)
    if m_HasNewWar ~= value then
        --printyellow("[citywarinfo:SetNewBattleState] set m_HasNewWar ==", value)
        m_HasNewWar = value   
         
        --refresh map battle red dot
        if UIManager.isshow("citywar.tabfamilyworld") then
            UIManager.refresh("citywar.tabfamilyworld", { refresh = { ["weekbattles"] = true } })
        end
    end
end

--family Has New War, used for red dot
local function HasNewBattle()
    return m_HasNewWar
end

local function HasWeekBattles(weekbattles)
    --printyellow("[citywarinfo:HasWeekBattles] weekbattles:")
    --printt(weekbattles)
    local warcityids = weekbattles and keys(weekbattles) or nil
    return warcityids and table.getn(warcityids)>0 or false
end

--set week city wars
--[[
type="map" key="int" value="BattleInfo" cityid -> BattleInfo]
<bean name="BattleInfo">
	<variable name="status" type="int"/>
	<variable name="defencemembernum" type="int"/>
	<variable name="attackmembernum" type="int"/>
</bean>
--]]
local function SetFamilyWeekBattles(weekbattles)
    --printyellow("[citywarinfo:SetFamilyWeekBattles] Set m_FamilyWeekBattles:")
    --printt(weekbattles)

    --test
    --[[
    weekbattles = {}
    table.insert(weekbattles, 3, {})
    table.insert(weekbattles, 1, {})
    table.insert(weekbattles, 2, {})
    --]]

    SetNewBattleState(false==HasWeekBattles(m_FamilyWeekBattles) and true==HasWeekBattles(weekbattles))

    m_FamilyWeekBattles = weekbattles
end

--get week city wars
local function GetFamilyWeekBattles()
    --printyellow("[citywarinfo:GetFamilyWeekBattles] Get m_FamilyWeekBattles:")
    --printt(m_FamilyWeekBattles)
    
    --test

    --local m_FamilyWeekBattles = {}
   -- table.insert(m_FamilyWeekBattles, 3, {})
    --table.insert(m_FamilyWeekBattles, 1, {})
    --table.insert(m_FamilyWeekBattles, 2, {})


    return m_FamilyWeekBattles
end

local function IsWarTime()
    local result = false
    local citydata
    if cfg.family.citywar.CityWarStage.BATTLE==GetFamilyCityWarStage() and m_FamilyWeekBattles then
        for cityid, battleinfo in pairs(m_FamilyWeekBattles) do 
            citydata = GetCity(cityid)
            if citydata and citydata:CanEnterCityWar() then
                result = true
                break
            end
        end
    else
        --printyellow("[citywarinfo:IsWarTime] GetFamilyCityWarStage()=", GetFamilyCityWarStage())
        --printyellow("[citywarinfo:IsWarTime] m_FamilyWeekBattles()=")
        --printt(m_FamilyWeekBattles)
        result = false
    end
    if false==result then
        citydata = nil
    end
    --printyellow("[citywarinfo:IsWarTime] IsWarTime=", result)
    return result, citydata

    --test    
    --return true
end

local function IsPrepareWarTime()
    local result = false
    local preparetime = 0
    if (cfg.family.citywar.CityWarStage.BEFORE_BATTLE==GetFamilyCityWarStage() or cfg.family.citywar.CityWarStage.BATTLE==GetFamilyCityWarStage())
     and m_FamilyWeekBattles then
        local citydata
        for cityid, battleinfo in pairs(m_FamilyWeekBattles) do 
            citydata = GetCity(cityid)
            if citydata then
                result, preparetime = citydata:IsPreparingWar()
                if true==result then
                    break
                end
            end
        end
    else
        --printyellow("[citywarinfo:IsPrepareWarTime] GetFamilyCityWarStage()=", GetFamilyCityWarStage())
        --printyellow("[citywarinfo:IsPrepareWarTime] m_FamilyWeekBattles()=")
        --printt(m_FamilyWeekBattles)
        result = false
    end

    --printyellow("[citywarinfo:IsPrepareWarTime] return result, preparetime:", result, preparetime)
    return result, preparetime

    --test    
    --return true
end
------------------------war end------------------------


------------------------city data start------------------------
--Get all Tax Bonus
local function GetAllTaxBonus()
    return m_CityWarCfg and m_CityWarCfg.scorebonuss or nil
end

--Get all City Config
local function GetAllCityCfg()
    return m_CityWarCfg.citys
end

--Get CityCfg by id
local function GetAllCityCount()
    if m_CityWarCfg and m_CityWarCfg.citys then
        return #m_CityWarCfg.citys
    else
        return 0
    end
end

--Get CityCfg by id
local function GetCityCfg(cityid)
    local citycfg
    if cityid and m_CityWarCfg and m_CityWarCfg.citys then
        for _,cfg in ipairs(m_CityWarCfg.citys) do
            if cfg.cityid==cityid then
                citycfg = cfg      
                break      
            end
        end
    end
    return citycfg
end

--Get City level config
local function GetCityLevelCfg(citylevel)
    local levelcfg
    if citylevel and m_CityWarCfg.citylevels and #m_CityWarCfg.citylevels then
        for _,cfg in ipairs(m_CityWarCfg.citylevels) do
            if cfg.level==citylevel then
                levelcfg = cfg
                break
            end
        end        
    end
    return levelcfg
end

--set all city
--[[
msg.citys:type="vector" value="City":
<bean name="City">
	<variable name="city" type="int"/>
	<variable name="ispeace" type="byte"/>
	<variable name="timerangeindex" type="int"/>ʱ����
	<variable name="defencefamilyid" type="long"/>
	<variable name="defencefamilyname" type="string"/>
	<variable name="attackfamilyname" type="string"/>
	<variable name="logoname" type="string"/>
	<variable name="color" type="int"/>
	<variable name="stability" type="int"/>�ٷ���
	<variable name="captureweek" type="int"/>
</bean>
--]]
local function SyncAllCityInfo(msg)
    m_AllCities = {}
    if msg.citys and #msg.citys>0 then
        local citycfg
        local levelcfg
        for _,cityinfo in ipairs(msg.citys) do
            local citydata = m_AllCities[cityinfo.city]
            if citydata then
                citydata:SetServerInfo(cityinfo)
            else
                citycfg = GetCityCfg(cityinfo.city)
                levelcfg = citycfg and GetCityLevelCfg(citycfg.level) or nil
                citydata = CityData:new(citycfg, levelcfg, cityinfo)
                m_AllCities[cityinfo.city] = citydata
            end

            if citydata:GetDefenderFamilyId()==FamilyManager.GetFamilyId() then
                SetFamilyColor(citydata:GetDefenderColor())
            end
        end 
    end
end

--get all city
--return: map<id, citydata>
local function GetAllCities()
    return m_AllCities
end

--Can Declare War to city
local function CanDeclareWar(cityid)
    local result = false
    if cfg.family.citywar.CityWarStage.ENTROLL~=GetFamilyCityWarStage() then
       --printyellow(string.format("[citywarinfo:CanDeclareWar] current stage [%s]~=cfg.family.citywar.CityWarStage.ENTROLL, return false!", GetFamilyCityWarStage()))
        result = false    
    elseif IsFamilyCity(cityid) then
        --printyellow(string.format("[citywarinfo:CanDeclareWar] city [%s] is family city, return false!", cityid))
        result = false
    else
        local citydata = GetCity(cityid)
        if m_FamilyCityCounts and citydata then
            if citydata:GetCityLevel()==cfg.family.citywar.CityLevelType.PRIMARY then
                result = (0==GetFamilyCityCount()) or IsFamilyNeighbour(cityid)
            elseif citydata:GetCityLevel()==cfg.family.citywar.CityLevelType.MEDIUM then
                result = (GetFamilyCityCount()>1) and IsFamilyNeighbour(cityid)
            elseif citydata:GetCityLevel()==cfg.family.citywar.CityLevelType.SENIOR then
                local mediumcount = m_FamilyCityCounts[cfg.family.citywar.CityLevelType.MEDIUM]
                mediumcount = mediumcount and mediumcount or 0
                local seniorcount = m_FamilyCityCounts[cfg.family.citywar.CityLevelType.SENIOR]
                seniorcount = seniorcount and seniorcount or 0
                result = ((seniorcount+mediumcount)>1) and IsFamilyNeighbour(cityid)
            end
        end
    end
    return result

    --test    
    --return true
end
------------------------city data end------------------------

------------------------city log end------------------------
local function SetFamilyLogs(warlogs)
    --printyellow(warlogs)
    --printt(warlogs)

    m_FamilyLogs = {}
    for i, warlog in ipairs(warlogs) do
        --printyellow(warlog)
        --printt(warlog)
        table.insert( m_FamilyLogs, CitywarLog:new(warlog) )
    end

    utils.table_sort( m_FamilyLogs, function(logA, logB) 
        if logA:GetTime() < logB:GetTime() then
            return true
        end
        return false
    end)
end

local function GetFamilyLogs()
    return m_FamilyLogs or {}
end

local function GetCurrentTip()
    local currentStage = GetFamilyCityWarStage()
    if currentStage and m_FamilyTips[currentStage] then
        return { [1] = m_FamilyTips[currentStage] }
    end
    return {}
end

local function LoadCitywarTip(tipCfgs)
    m_FamilyTips = {}
    for i,tipCfg in pairs(tipCfgs) do
        m_FamilyTips[tipCfg.stage] = CitywarTip:new(tipCfg)
    end
--CitywarTip
end

------------------------city log end------------------------


------------------------others start------------------------
local function OnLogout() 
    reset()
end

local function init()
    --printyellow("[citywarinfo:init] citywarinfo init!")  
    citywarmanager 	  = require "ui.citywar.citywarmanager"

    reset()  
    m_CityWarCfg = ConfigManager.getConfig("citywar")
    if m_CityWarCfg then    
        m_AllCities = {}
        if m_CityWarCfg.citys then
            local levelcfg
            for _,citycfg in ipairs(m_CityWarCfg.citys) do
                levelcfg = citycfg and GetCityLevelCfg(citycfg.level) or nil
                m_AllCities[citycfg.cityid] = CityData:new(citycfg, levelcfg, nil)
            end 
        end
        LoadCitywarTip(m_CityWarCfg.tips)
    else
        print("[ERROR][citywarinfo:init] m_CityWarCfg nil!")
    end
    
	gameevent.evt_system_message:add("logout", OnLogout)
end
------------------------others end------------------------

return
{    
    ------------------------utils start------------------------
    GetDefaultHexColor = GetDefaultHexColor,
    GetColorByIndex = GetColorByIndex,
    GetCity = GetCity,
    GetHexColorByIndex = GetHexColorByIndex,
    GetColorText = GetColorText,
    ------------------------utils end------------------------
        
    ------------------------city award start------------------------
    SetWorldLuckyBonus = SetWorldLuckyBonus,
    GetWorldLuckyBonus = GetWorldLuckyBonus,
    ExistsLuckyBonus = ExistsLuckyBonus,
	HasFamilyLucky = HasFamilyLucky,
    ------------------------city award end------------------------
    
    ------------------------family city start------------------------ 
    GetFamilyTaxBonus = GetFamilyTaxBonus, 
    SetFamilyCityInfo = SetFamilyCityInfo,   
    SetFamilyLogoname = SetFamilyLogoname,
    GetFamilyLogoname = GetFamilyLogoname,
    SetFamilyCityWarStage = SetFamilyCityWarStage, 
    GetFamilyCityWarStage = GetFamilyCityWarStage,
    GetFamilyCities = GetFamilyCities,
    GetFamilyCityCount = GetFamilyCityCount,
    GetFamilyCityLevelCounts = GetFamilyCityLevelCounts,
    IsFamilyCity = IsFamilyCity,
    SetFamilyDeclareWarInfo = SetFamilyDeclareWarInfo,
    GetFamilyDeclareMoney = GetFamilyDeclareMoney,
    GetFamilyDeclareCity = GetFamilyDeclareCity,
    HasFamilyDeclareCity = HasFamilyDeclareCity,
    GetFamilyColor = GetFamilyColor,
    GetFamilyLuckyBonus = GetFamilyLuckyBonus,
    SetFamilyLuckyBonus = SetFamilyLuckyBonus,
    HasFamilyLuckyBonus = HasFamilyLuckyBonus,
    ------------------------family city end------------------------

    ------------------------city data start------------------------
    SyncAllCityInfo = SyncAllCityInfo,
    GetAllCityCount = GetAllCityCount,
    GetAllCities = GetAllCities,
    GetAllCityCfg = GetAllCityCfg,
    CanDeclareWar = CanDeclareWar,
    GetCityLevelCfg = GetCityLevelCfg,
    GetAllTaxBonus = GetAllTaxBonus,
    ------------------------city data end------------------------
    
    ------------------------war start------------------------
    GetDeclareWarFamilyLevel = GetDeclareWarFamilyLevel,
    GetDeclareCities = GetDeclareCities,
    CanEnterCityWar = CanEnterCityWar,
    IsPreparingWar = IsPreparingWar,
    GetWarTimeRangeText = GetWarTimeRangeText,
    SetFamilyWeekBattles = SetFamilyWeekBattles,
    GetFamilyWeekBattles = GetFamilyWeekBattles,
    IsWarTime = IsWarTime,
    IsPrepareWarTime = IsPrepareWarTime,
    HasNewBattle = HasNewBattle,
    SetNewBattleState = SetNewBattleState,
	SetCityWarOver  = SetCityWarOver,
	GetCityWarIsOver = GetCityWarIsOver,
	IsOverWeekTimeRange  = IsOverWeekTimeRange,
	
    ------------------------war end------------------------

    ------------------------log start------------------------
    SetFamilyLogs = SetFamilyLogs,
    GetFamilyLogs = GetFamilyLogs,
    GetCurrentTip = GetCurrentTip,
    ------------------------log end------------------------

    ------------------------others start------------------------
    init=init,
    ------------------------others end------------------------
}