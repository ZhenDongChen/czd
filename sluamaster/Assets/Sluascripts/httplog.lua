
----获取设备标识
local DevicesText = {
    [0]  = "OSXEditor",
	[1]  = "OSXPlayer",
  	[2]  = "WindowsPlayer",
	[3]  = "OSXWebPlayer",
  	[4]  = "OSXDashboardPlayer",
  	[5]  = "WindowsWebPlayer",
  	[7]  = "WindowsEditor",
  	[8]  = "IPhonePlayer",
  	[9]  = "PS3",
  	[10] = "XBOX360",
    [11] = "Android",
}




--日志分类
local LogType =
{
    Behavior     = 1,
    Journal      = 2,
    Equipment    = 3,
}


---
--事件类型
local EventType =
{
    Warning       = 1,
    Information   = 2,
    Error         = 3,
    Collapse      = 4,
    Start         = 5,
    Sign          = 6,
    Out           = 7
}

---
--是否错误或者崩溃：（0：不是，1：是）
local IsException =
{
    Yes   = 1,
    No    = 0,

}



local http = "http://192.168.0.223:9999/logServer/Application/views/client/log/logCollect.php?%s"


local function SplicingProtocol(urlTable)
	local parameter = ""
	for i,v in pairs(urlTable) do
		if i == 1 then
			parameter = v
		else
			parameter = parameter.."&"..v
		end
	end
	local httpStr = string.format(http,parameter)
	LuaHelper:SendHttp(httpStr)
end


--[[
    @desc: 
    author:{author}
	time:2018-09-08 14:25:05
	--@pid          进程id
	--@logServer:   logServer
	--@deviceType:  设备分类：苹果 android linux windows（1，2，3，4）
    --@logType:     日志分类：角色行为   程序运行日志  设备信息（1，2，3）
	--@eventType:   事件类型：程序警告 程序信息 程序错误 程序崩溃 客户端启动  角色登录 角色退出 （1，2，3，4，5，6，7）
	--@isException:	是否错误或者崩溃：（0：不是，1：是）
	--@info:		详细信息：
	--@info1:		附加信息1：（附加信息的含义取决于事件类型）
	--@info2:		附加信息1：（附加信息的含义取决于事件类型）
	--@info3:		附加信息1：（附加信息的含义取决于事件类型）
	--@info4:		附加信息1：（附加信息的含义取决于事件类型）
	--@info5: 		附加信息1：（附加信息的含义取决于事件类型）
    @return:
]]
local function AddUrlTable(logType,eventType,isException,info,info1,info2,info3,info4,info5)
	local urlTable = {}
	local deviceType = 7 
	local pid = 0
	local server = GetServerInfos()
    local logServer = server.logserver.host
	if Application.platform == UnityEngine.RuntimePlatform.IPhonePlayer then  --- 设备类型
        deviceType = 1 
    elseif Application.platform == UnityEngine.RuntimePlatform.Android then
        deviceType = 2
	elseif Application.platform == UnityEngine.RuntimePlatform.LinuxPlayer then
		deviceType = 3
	elseif Application.platform == UnityEngine.RuntimePlatform.WindowsPlayer then
		deviceType = 4
	else
		deviceType = 5
	end
	table.insert(urlTable,"pid="..pid)             
	-- table.insert(urlTable,"logServer="..logServer)
	table.insert(urlTable,"device_type="..deviceType)  
	if logType ~= nil then 
		table.insert(urlTable,"log_type="..logType)
	end

	if eventType ~= nil then 
		table.insert(urlTable,"event_type="..eventType)
	end

	if isException ~= nil then 
		table.insert(urlTable,"is_exception="..isException)
	end

	if info ~= nil then 
		table.insert(urlTable,"info="..info)
	end

	if info1 ~= nil then 
		table.insert(urlTable,"info1="..info1)
	end

	if info2 ~= nil then 
		table.insert(urlTable,"info2="..info2)
	end

	if info3 ~= nil then 
		table.insert(urlTable,"info3="..info3)
	end
	
	if info4 ~= nil then 
		table.insert(urlTable,"info4="..info4)
	end

	if info5 ~= nil then 
		table.insert(urlTable,"info5="..info5)
	end

	SplicingProtocol(urlTable)
end





return{
	AddUrlTable = AddUrlTable,
	LogType = LogType, 
    EventType = EventType,  
    IsException = IsException,
} 
