local NetWork=require("network")
local UIManager=require("uimanager")
local ConfigManager = require("cfg.configmanager")
local PlayerRole=require"character.playerrole"

-- local LuaErrorCode=require("errorcode")

local ErrorCode = {

}

local ErrorEnum = {

}


local function onmsg_DealError(msg)
    --获取错误码
    local content=ErrorCode[msg.errcode]

    printyellow("onmsg_DealError:",tostring(msg.errcode),tostring(content))

    -- 采矿相关
    -- if  msg.errcode >= 307 and esg.errcode <= 313 then
    --    return
    -- end

    -- 等级不够
    if msg.errcode == 107 then
        UIManager.ShowSystemFlyText(content)
        return
    end

    -- 任务相关
    if  (msg.errcode >= 500 and msg.errcode <= 506) or msg.errcode == 319 or msg.errcode == 306 or msg.errcode == 519 then
        return
    end
    --组队相关
    if  (msg.errcode>=2200 and msg.errcode<=2223 and msg.errcode ~= 2209) and msg.errcode ~= 2217 then
        return
    end

    --冷却未完成 
    if msg.errcode == 113 then
        return
    end
    --参数错误
    if msg.errcode == 102 then
        return
    end
    
    if shouldHideVip() and (msg.errcode == 112) then
        return
    end
    --家族聚宴飘字
    if msg.errcode == 2838 or msg.errcode == 356 then
        UIManager.ShowSystemFlyText(content)
        return
    end
	-- 背包操作
	if msg.errcode == 116 then
        UIManager.ShowSystemFlyText(content)
        return
	end
	--匹配相关
--	if  (msg.errcode>=6100 and msg.errcode <= 6105) then
--        return
--    end


	if msg.errcode == 366 then
        if PlayerRole:Instance():IsNavigating() then
			PlayerRole:Instance():StopNavigate()
		end
	end
	
    --显示提示弹框
    UIManager.ShowSingleAlertDlg({content=content})
end
local function onmsg_DealError2(msg)
    --获取错误码
    local content=ErrorCode[msg.errcode]
    UIManager.ShowSingleAlertDlg({content=msg.err})
end

local function LoadErrorCodeConfig()
    -- for key, value in pairs(LuaErrorCode) do
    --     if type(key) == "string" and type(value) == "number" then
    --         ErrorEnum[key] = value
    --     elseif  type(key) == "number" and type(value) == "string" then
    --         ErrorCode[key] = value
    --     else
    --         logError("Load ErrorCode Error")
    --     end
    -- end

    for key, value in pairs(cfg.error.ErrorCode) do
        ErrorEnum[key] = value
    end

    local errorCodeConfig = ConfigManager.getConfig("errorcodes")

    for key, value in pairs(errorCodeConfig) do
        ErrorCode[value.id] = value.desc
    end

end


local function init()
    NetWork.add_listeners({
        {"lx.gs.SError",onmsg_DealError},
        {"lx.gs.SError2",onmsg_DealError2},
    })

    LoadErrorCodeConfig()
end

local function ShowError(errorcode)
    onmsg_DealError({errcode = errorcode})
end

local function GetErrorText(id)

    return ErrorCode[id] or "Unknown Error: " .. tostring(id)
end
local function GetErrorEnum()
    return ErrorEnum
end

return {
    init=init,
    ShowError = ShowError,
    GetErrorEnum = GetErrorEnum,
    GetErrorText = GetErrorText,
}