local print = print
local require = require
local loadstring = loadstring
local tostring = tostring
local string = string
local type = type
local gameevent = require "gameevent"
local network = require "network"
local uimanager = require("uimanager")
local ConfigManager = require("cfg.configmanager")
local TimeUtils = require"common.timeutils"
local GraphicSettingMgr


local insert = table.insert
local concat = table.concat


g_settingAll=g_settingAll or {}

local SettingAF   = {}

local WorldTable   = {}
local PrivateTable = {}
local FamilyTable  = {}
local TeamTable    = {}
local SystemTable  = {}

local SettingSystem = {}
local selected_Skills = {}
local MagicWeapon = {}
local MagicLimit = {}

local redDotAutoFight = false
local redDotSystem = false

local function SetRedDotSetting(b)
	redDotAutoFight = b		
	redDotSystem = b 
end

local function UnReadAutoFight()
	return redDotAutoFight
end

local function UnReadSystem()
	return redDotSystem 
end

local function GetSettingTableByChannel(channel)
	print("Setting Channel"..channel)
	if channel == cfg.chat.ChannelType.WORLD then
		return WorldTable 
	elseif channel == cfg.chat.ChannelType.PRIVATE then
		return PrivateTable
	elseif channel == cfg.chat.ChannelType.TEAM then
		return TeamTable
	elseif channel == cfg.chat.ChannelType.FAMILY then
		return FamilyTable
	elseif channel == cfg.chat.ChannelType.SYSTEM then
		return SystemTable
	else
		return nil
	end
end

local function SetSettingTableByChannel(channel,Table)
	print(Table)
	if channel == cfg.chat.ChannelType.WORLD then
		 WorldTable  = Table
	elseif channel == cfg.chat.ChannelType.PRIVATE then
		 PrivateTable = Table
	elseif channel == cfg.chat.ChannelType.TEAM then
		 TeamTable = Table
	elseif channel == cfg.chat.ChannelType.FAMILY then
		 FamilyTable = Table
	elseif channel == cfg.chat.ChannelType.SYSTEM then
		 SystemTable = Table
	else
		error("Channel doesnot exit")
	end
end

local function GetRedDotSetting()
	return redDotSystem or redDotAutoFight
end

local function GetRedDotAutoFightSetting()
	return redDotAutoFight
end 

local function GetRedDotSystemSetting()
	return redDotSystem
end

local function SetSettingSkillByIndex(index, b)
	SettingAF["Skill"..index] = b
end 


local function update()

end

local function CountTB(t) --计算表中元素个数
    local count = 0
    if t then
        for i, val in pairs(t) do
            count = count + 1
        end
    end
    return count
end

local function dump_atom (x)
    --if type(x) == "string" then
    --    return to_readable(x)
    --else
        return tostring(x)
    --end
end

local function dump_table_(t)
    local code = {"{"}
    for k, v in pairs(t) do
        if type(v) ~= "table" then
            insert(code, tostring(k) .. "=" .. dump_atom(v) .. ",")
        else
            insert(code, tostring(k) .. "=" .. dump_table_(v) .. ",")
        end
    end
    local count = CountTB(code) -- 去掉最后一项字符串后面的逗号","
    code[count] = string.sub(code[count],0,string.len(code[count])-1)
    insert(code, "}")
    return table.concat(code)
end

local function TableToString(t)
    if type(t) == "table" then
        return(dump_table_(t))
    else
        return(t)
    end
end

local function StringToTable(str)
    local Table = { }
    if str == nil then
        printyellowmodule(Local.LogModuals.SettingManager,"This is a nil string")
    end

    if type(str) == "string" then
--        printyellow("StringToTable")/
--        printyellow(str)
        local str1 = string.gsub(str,"({)(%d+)(=)","%1[%2]%3")
		local str2 = string.gsub(str1,"(,)(%d+)(=)","%1[%2]%3")
		print(str2)
		
        Table, err = assert(loadstring("return " .. str2))()
		
        if not Table then
            printyellowmodule(Local.LogModuals.SettingManager,err)
        end
        return Table
    else
        return Table
    end
end





local function GenerateTable(t)
    local new_table = { }
    local v1 = { isPray = false, isTick = false }
    local v2 = { isPray = true , isTick = true  }  --默认为灰色勾选
    local v3 = { isPray = true , isTick = false }  --家族频道，只有在世界频道和家族频道下才可以勾选
    local v4 = { isPray = true , isTick = false }  --队伍频道，只有在世界频道和队伍频道下才可以勾选
    local v5 = { isPray = false, isTick = false }
    local v6 = { isPray = false, isTick = true  }  --默认为绿色勾选
    local v7 = { isPray = false, isTick = true  }  --默认为绿色勾选
    local v8 = { isPray = false, isTick = false  }  --默认为绿色不勾选

    new_table[cfg.chat.ChannelType.WORLD]    = v1
    new_table[cfg.chat.ChannelType.PRIVATE]  = v2
    new_table[cfg.chat.ChannelType.FAMILY]   = v3
    new_table[cfg.chat.ChannelType.TEAM]     = v4
    new_table[cfg.chat.ChannelType.SYSTEM]   = v5
    new_table[6]   = v6
    new_table[7]   = v7
    new_table[8]   = v8

    new_table[cfg.chat.ChannelType.WORLD].isPray =   t[1]
    new_table[cfg.chat.ChannelType.WORLD].isTick =   t[2]
    new_table[cfg.chat.ChannelType.PRIVATE].isPray =   t[3]
    new_table[cfg.chat.ChannelType.PRIVATE].isTick =   t[4]
    new_table[cfg.chat.ChannelType.FAMILY].isPray =   t[5]
    new_table[cfg.chat.ChannelType.FAMILY].isTick =   t[6]
    new_table[cfg.chat.ChannelType.TEAM].isPray   =   t[7]
    new_table[cfg.chat.ChannelType.TEAM].isTick   =   t[8]
    new_table[cfg.chat.ChannelType.SYSTEM].isPray =   t[9]
    new_table[cfg.chat.ChannelType.SYSTEM].isTick =   t[10]
    new_table[6].isPray =   t[11]
    new_table[6].isTick =   t[12]
    new_table[7].isPray =   t[13]
    new_table[7].isTick =   t[14]
    new_table[8].isPray =   t[15]
    new_table[8].isTick =   t[16]

    return new_table
end

local function InitChatTable()

    printyellow("InitTable")
    local WorldTable1   = GenerateTable({false,true,false,true,false,true,false,true,false,true,true,false,false,true,false,false})
    local PrivateTable1 = GenerateTable({false,false,true,true,false,false,false,false,false,false,true,false,false,true,false,false})
    local FamilyTable1  = GenerateTable({false,false,false,true,true,true,false,true,false,false,true,false,false,true,false,false})
    local TeamTable1    = GenerateTable({false,false,false,true,false,false,true,true,false,false,true,false,false,true,false,false})
    local SystemTable1  = GenerateTable({false,false,false,false,false,false,false,false,true,true,true,false,false,true,false,false})
	WorldTable   =  WorldTable1
	PrivateTable =  PrivateTable1
	FamilyTable  =  FamilyTable1
	TeamTable    =  TeamTable1
	SystemTable  =  SystemTable1

end

local function InitAFTable()
	redDotAutoFight = true
	SettingAF["HP"] = 0.7
	SettingAF["MP"] = 0.7
	SettingAF["Range"] = 1
	SettingAF["Normal_Monster"] = true
	SettingAF["Elite_Monster"]  = true
	SettingAF["Boss_Monster"]   = true
	SettingAF["Skill1"] = true
	SettingAF["Skill2"] = true
	SettingAF["Skill3"] = true
	SettingAF["Skill4"] = true
	SettingAF["Skill5"] = true
	SettingAF["Skill6"] = true
	SettingAF["Skill7"] = true -- 法宝技能
	SettingAF["Skill8"] = false
	SettingAF["White"] = true
	SettingAF["Green"] = true
	SettingAF["Blue"] = true
	SettingAF["Purple"] = true
	SettingAF["Orange"] = true
	SettingAF["Red"] = true
    printyellow(SettingAF)
	
end

local function InitSystemTable()
	redDotSystem = true
	SettingSystem = {}
	local roleconfig = ConfigManager.getConfig("roleconfig")
	local playernums  = roleconfig.playeramount
	local monsternums = roleconfig.monsteramount
	SettingSystem["Player"]       = playernums[1]  
	SettingSystem["Monster"]      = monsternums[1]
	SettingSystem["Music"]        = 1  
	SettingSystem["MusicEffect"]  = 1
   	SettingSystem["SkillEffectOther"]   = true 
   	SettingSystem["SkillEffectMonster"] = true
   	SettingSystem["SkillEffectSelf"]    = true
   	SettingSystem[GraphicSettingMgr.FlyTextSettingName] = true
   	SettingSystem[GraphicSettingMgr.NameHPSettingName]    = true
end

local function SetPlayerNumMonsterNum(num1,num2)
	SettingSystem["Player"]       = num1
	SettingSystem["Monster"]      = num2

end

local function InitSettingData()
   

end

local function SendCSetConfigureChat()
   
	local SettingChat = {}
	SettingChat.WorldTable   = WorldTable
	SettingChat.PrivateTable = PrivateTable
	SettingChat.FamilyTable  = FamilyTable
	SettingChat.TeamTable    = TeamTable
	SettingChat.SystemTable  = SystemTable
	
	printyellow("SendCSetConfigure(data1)")

	local SettingChatString = TableToString(SettingChat)
	
	--TODO
	--替换之前保存协议的数据
	local targetfilestring = LuaHelper.GetPath("chatsystem.txt")
	print(targetfilestring)
	local utils = require("common.utils")
	utils.WriteFile(targetfilestring,SettingChatString)


end

local function SendCSetConfigureAutoFight()
	  printyellow("SendCSetConfigure(data2)")
	--TODO
	--替换之前保存协议的数据
	local AutoFightfilestring = LuaHelper.GetPath("AutoFight.txt")
	print(AutoFightfilestring)
	local utils = require("common.utils")
	utils.WriteFile(AutoFightfilestring,TableToString(SettingAF))
end

local function SendCSetConfigureSystem()
	--TODO暂时屏蔽游戏设置 
	--TODO
	--替换之前保存协议的数据
	local Systemfilestring = LuaHelper.GetPath("System.txt")
	print(Systemfilestring)
	local utils = require("common.utils")
	utils.WriteFile(Systemfilestring,TableToString(SettingSystem))
end

---法宝
local function SendMagicWeapon(SkipAnim)
	 MagicWeapon["skipAnim"] = SkipAnim
	 local Weaponfilestring = LuaHelper.GetPath("Weapon.txt")
	 local utils = require("common.utils")
	 utils.WriteFile(Weaponfilestring,TableToString(MagicWeapon))
end


---版号送审次数
local function SendMagicLimit(LimitNumber,limitType)
	local time = os.date("%Y%m%d",TimeUtils.GetServerTime())
	local PlayerRole = require "character.playerrole"
	local timeType = PlayerRole:Instance().m_Name .. limitType..time
	MagicLimit[timeType] = LimitNumber
    local Limitfilestring = LuaHelper.GetPath("Limit.txt")
    local utils = require("common.utils")
    utils.WriteFile(Limitfilestring,TableToString(MagicLimit))
end



local function IsValidBrace(str)
    local leftnum = 0
    local index = 1
--	printyellow("IsValidBrace",str)
    while index <= string.len(str) do
        if string.sub(str,index,index) == "{" then
            leftnum = leftnum + 1
        end
        if string.sub(str,index,index) == "}" then
            leftnum = leftnum - 1
        end
        if leftnum < 0 then
            return false
        end
        index = index + 1
    end
    return true
end

function loadSetting()
	
	local utils = require("common.utils")
	local chatsystemfilepath = LuaHelper.GetPath("chatsystem.txt")
	local chatsystemfilestring = utils.ReadFile(chatsystemfilepath)
	
	local AutoFightfilepath = LuaHelper.GetPath("AutoFight.txt")
	local AutoFightfilestring = utils.ReadFile(AutoFightfilepath)
	
	local Systemfilepath = LuaHelper.GetPath("System.txt")
	local Systemfilestring = utils.ReadFile(Systemfilepath)

	local Weaponfilepath = LuaHelper.GetPath("Weapon.txt")
	local Weaponfilestring = utils.ReadFile(Weaponfilepath)

	local Limitfilepath = LuaHelper.GetPath("Limit.txt")
	local Limitfilestring = utils.ReadFile(Limitfilepath)
	
	--聊天数据
	if not g_settingAll["SettingChat"] then
		  g_settingAll["SettingChat"]={}
	end
	if IsValidBrace(chatsystemfilestring) then
		g_settingAll["SettingChat"] = StringToTable(chatsystemfilestring)
	end
	
	
	--自动战斗数据
	if not g_settingAll["SettingAF"] then
		  g_settingAll["SettingAF"]={}
	end
	
	if IsValidBrace(AutoFightfilestring) then
		g_settingAll["SettingAF"] = StringToTable(AutoFightfilestring)
	end

	
	--系统设置数据
	if not g_settingAll["SettingSystem"] then
		  g_settingAll["SettingSystem"]={}
	end
	if  IsValidBrace(Systemfilestring) then
		g_settingAll["SettingSystem"] = StringToTable(Systemfilestring) or {}
		SettingSystem = g_settingAll["SettingSystem"]
	end


	--法宝数据
	if not g_settingAll["Weapon"] then
		g_settingAll["Weapon"]={}
	end
	if  IsValidBrace(Weaponfilestring) then
		g_settingAll["Weapon"] = StringToTable(Weaponfilestring) or {}
		MagicWeapon = g_settingAll["Weapon"]
	end


	--版号限制次数数据
	if not g_settingAll["Limit"] then
		g_settingAll["Limit"]={}
	end
	if IsValidBrace(Limitfilestring) then
		g_settingAll["Limit"] = StringToTable(Limitfilestring) or {}
		MagicLimit = g_settingAll["Limit"]
	end
end


local function onmsg_SGetConfigures(dRaw)
	
	print("+++++++++++++++++++++++++++++onmsg_SGetConfigures+++++++++++++++++++++++++++++++++++++++")
	--TODO
	--替换之前保存协议的数据
	
	loadSetting()

	local d =g_settingAll
	 if  d  then
		if d["SettingAF"]  then
			SettingAF = d["SettingAF"]
			if next(SettingAF) == nil then 
				InitAFTable() 
			else 
				redDotAutoFight = false
			end 
		else

			InitAFTable()
		end 

		if d["SettingChat"]  then

			SettingChat = d["SettingChat"]
			if next(SettingChat)  == nil then 
				InitChatTable() 
			else
				WorldTable    = SettingChat.WorldTable
				PrivateTable  = SettingChat.PrivateTable
				FamilyTable   = SettingChat.FamilyTable
				TeamTable     = SettingChat.TeamTable
				SystemTable   = SettingChat.SystemTable
			end
		else                                     
			InitChatTable()
		end

		if d["SettingSystem"] then
			SettingSystem = d["SettingSystem"]
			if next(SettingSystem) ==nil then  
				InitSystemTable() 
			else
				redDotSystem = false			
			end 
		else
			InitSystemTable()

		end 
    else

		InitAFTable()
		InitChatTable()
		InitSystemTable()
	end 
    GraphicSettingMgr.InitSetting(SettingSystem)
end



local function GetPickUpData()
	local TablePickup = {}
	TablePickup["White"]  =  SettingAF["White"]
	TablePickup["Green"]  =  SettingAF["Green"]
	TablePickup["Blue"]   =  SettingAF["Blue"]
	TablePickup["Purple"] =  SettingAF["Purple"]
	TablePickup["Orange"] =  SettingAF["Orange"]
	TablePickup["Red"]    =  SettingAF["Red"]
	
    return  TablePickup
end

local function GetSettingAutoFight()
	return SettingAF
end

local function SetSettingAutoFight(Table)
	SettingAF = Table
end

--local function GetSettingChat()
--	return SettingChat
--end

--local function SetSettingChat(Table)
--	SettingChat = Table
--end

local function GetSettingSystem()
	return SettingSystem
end

local function SetSettingSystem(Table) 
	SettingSystem = Table
end

local function UnRead()
	printyellow("settingmanager unread")
	return GetRedDotSetting()
end

local function GetMagicWeapon()
	return MagicWeapon
end

local function GetMagicLimit()
	return MagicLimit
end


local function Release()
	SettingAF   = {}
	SettingChat = {}
	SettingSystem = {}
	selected_Skills = {}
	
	redDotAutoFight = false
end

local function OnLogout()
	Release()
end

local function init()
    GraphicSettingMgr = require"ui.setting.graphicsettingmanager"

	gameevent.evt_system_message:add("logout", OnLogout)

    network.add_listeners( {

       { "lx.gs.role.msg.SGetConfigures", onmsg_SGetConfigures },

    } ,"settingmanager")


end

return {

    init = init,
	UnRead = UnRead,
    TableToString = TableToString,
    StringToTable = StringToTable,
    GetPickUpData = GetPickUpData,
	GetSettingAutoFight = GetSettingAutoFight,
	SetSettingAutoFight = SetSettingAutoFight,
	GetSettingSystem = GetSettingSystem,
	SetSettingSystem = SetSettingSystem,
	GetMagicWeapon   = GetMagicWeapon,
	GetMagicLimit =  GetMagicLimit,
	SetSettingSkillByIndex = SetSettingSkillByIndex,
	GetSettingTableByChannel = GetSettingTableByChannel,
	SetSettingTableByChannel = SetSettingTableByChannel,
	SendCSetConfigureChat = SendCSetConfigureChat,
	SendCSetConfigureSystem = SendCSetConfigureSystem,
	SendMagicWeapon = SendMagicWeapon,
	SendMagicLimit = SendMagicLimit,
	SendCSetConfigureAutoFight = SendCSetConfigureAutoFight, 
	GetRedDotSystemSetting = GetRedDotSystemSetting,
	GetRedDotAutoFightSetting = GetRedDotAutoFightSetting,
	SetPlayerNumMonsterNum = SetPlayerNumMonsterNum,
	SetRedDotSetting = SetRedDotSetting,
	UnReadAutoFight = UnReadAutoFight,
	UnReadSystem = UnReadSystem,

}