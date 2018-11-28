local network = require"network"
local configManager = require "cfg.configmanager"

local level_LowestFayan	   --���ͷ��Եȼ�
local level_LowestJubao    --���;ٱ��ȼ�
local times_Jubao          --ÿ���ٱ�����
local duration_Base_Fayan  --�������Լ���
local lasttalktime         --�ϴη���ʱ��
local silentendtime		   --���Խ���ʱ��
local leftreporttime	   --ʣ���ٱ�����
local restTime = 0
local duration_level
local duration_viplevel 



local function GetRestTime()
	return restTime
end

local function GetLevelLowestFayan()
	return level_LowestFayan
end

local function SetLevelLowestFayan(b)
	level_LowestFayan = b
end

local function GetLevelLowestJubao()
	return level_LowestJubao
end

local function SetLevelLowestJubao(b)
	level_LowestJubao = b
end

local function GetTimesJubao()
	return times_Jubao
end

local function SetTimesJubao(b)
	times_Jubao = b
end

local function GetDurationBaseFayan()
	return duration_Base_Fayan
end

local function SetDurationBaseFayan(b)
	duration_Base_Fayan = b
end

local function GetTimeJubaoByVipLevel(viplevel)
end

local function GetReduceTimeByVipLevel(viplevel)
	local roleconfig = ConfigManager.getConfig("roleconfig")
	return roleconfig.intervalreducebyvip[viplevel + 1]
end

local function GetReduceTimeByLevel(level)
	local roleconfig = ConfigManager.getConfig("roleconfig")

	for index,interval in ipairs(roleconfig.intervallevel) do
		if level < interval  then
			return roleconfig.intervalreducebylevel[index]	
		end 
	end 
	return  0
end

local function SetRestTime(level,viplevel)
	assert(duration_Base_Fayan)
	assert(GetReduceTimeByLevel(level))
	assert(GetReduceTimeByVipLevel(viplevel))
	restTime = duration_Base_Fayan - GetReduceTimeByLevel(level) - GetReduceTimeByVipLevel(viplevel)
end


local function SendCReportPlayer(bereportid)
	local msg = lx.gs.chat.msg.CReportPlayer({bereportid = bereportid})
	network.send(msg)
end

local function GetLeftReportTime()
	return leftreporttime
end

local function onmsg_SChatMsg(d)
	lasttalktime = d.lasttalktime
	silentendtime = d.silentendtime
	leftreporttime = d.leftreporttime
end

local function onmsg_SReportPlayer(d)
	leftreporttime = leftreporttime - 1
end

local function onmsg_SBeSilentNotify(d)
	
end

local function second_update()
	if restTime ~= 0 then
		restTime = restTime - 1
	end  
end

local function IsBeSilentNotify()

	return   math.floor((silentendtime - timeutils.GetServerTime()*1000)/1000)
end

local function InitJubao()
	local roleconfig = ConfigManager.getConfig("roleconfig")	
	SetLevelLowestFayan(roleconfig.minspeaklevel)
	SetLevelLowestJubao(roleconfig.minreportlevel)
	SetTimesJubao(roleconfig.everydayreportnum)
	SetDurationBaseFayan(roleconfig.basicspeakinterval)
end

local function Release()
--	level_LowestFayan	 = nil	
--	level_LowestJubao    = nil
--	times_Jubao          = nil
--	duration_Base_Fayan  = nil
	lasttalktime         = nil
	silentendtime		 = nil
	leftreporttime	     = nil
	restTime			 = 0		
	duration_level		 = nil
	duration_viplevel    = nil  
end

local function OnLogout()
	Release()
end

local function init()
	gameevent.evt_second_update:add(second_update)
	gameevent.evt_system_message:add("logout", OnLogout)
	InitJubao()
    network.add_listeners( {

       { "lx.gs.chat.msg.SChatMsg", onmsg_SChatMsg },
       { "lx.gs.chat.msg.SReportPlayer", onmsg_SReportPlayer },
       { "lx.gs.chat.msg.SBeSilentNotify", onmsg_SBeSilentNotify },
	
    } )

end

return {
	init = init,
	SendCReportPlayer = SendCReportPlayer,
	SetLevelLowestFayan = SetLevelLowestFayan,
	SetLevelLowestJubao = SetLevelLowestJubao,
	SetTimesJubao = SetTimesJubao,
	SetDurationBaseFayan = SetDurationBaseFayan,
	GetLevelLowestFayan = GetLevelLowestFayan,
	GetLevelLowestJubao = GetLevelLowestJubao,
	GetTimesJubao = GetTimesJubao,
	SetRestTime = SetRestTime,
	GetRestTime = GetRestTime,
	GetLeftReportTime = GetLeftReportTime,
	IsBeSilentNotify = IsBeSilentNotify,
	
}