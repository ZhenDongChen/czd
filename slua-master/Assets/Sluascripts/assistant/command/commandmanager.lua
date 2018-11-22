--local PlotManager = require("plot.plotmanager")
local UIManager = require("uimanager")
--local CharacterBuff = require"character.characterbuff"
--local BeAttackedWork = require"character.work.beattackedwork"
--local CameraManager = require"cameramanager"

local function ShowMessage(message, mode)
    if mode == nil then
        mode = {chat = true}
    end
    if mode.chat == true then
        UIManager.call( "chat.dlgchat01","AddMessage", {
                        sendername  = "[CMD]",
                        senderid    = PlayerRole:Instance().m_Id,
                        imageid     = -1,
                        voiceid     = -1,
                        text        = message,
                        channel     = cfg.chat.ChannelType.SYSTEM,
                    })
    end
    if mode.flytext == true then
        UIManager.ShowSystemFlyText(message)
    end
    if mode.log == true then
        print(message)
    end
    if mode.error == true then
        logError(message)
    end
end


local function PlayCG(name)
	printyellow("commandmanager")
    if UIManager.isshow("chat.dlgchat01") then
        UIManager.hide("chat.dlgchat01")
    end
   -- PlotManager.DirectPlayCutscene(name)

end

local function ReplaceLog(src, rep)
    local path = LuaHelper.GetPath("config/local.lua")
    local f = io.open(path, 'r')
    local str = f:read("*all")
    f:close()
    local str2 = string.gsub(str, src, rep)
    f = io.open(path, "w")
    f:write(str2)
    f:close()
end

local function ChangeLog(str)
    if str=="true" then
        Local.LogManager = true
        ReplaceLog("Local.LogManager = false", "Local.LogManager = true")
    else
        Local.LogManager = false
        ReplaceLog("Local.LogManager = true", "Local.LogManager = false")
    end
end

local function SetNavMode(str)
    if str == "server" then
        PlayerRole:Instance():SetNavigationMode(false)
    elseif str == "client" then
        PlayerRole:Instance():SetNavigationMode(true)
    else
        --printyellow("命令错误")
        ShowMessage("命令错误")
    end
end

local function NavigateTo(str)

    PlayerRole:Instance():navigateTo({ })
end

local function ShowEffect(str)
    if str == "true" then
        SkillManager.SetShowEffect(true)
    else
        SkillManager.SetShowEffect(false)
    end
end

local function ShowBuffEffect(str)

end

local function ShowFlash(str)

end

local function SetModuleId(str)
    local DlgUIMain = require "ui.dlguimain"
    DlgUIMain.setmodule_id(tonumber(str))
end

local function GroundTest(str)

end

local function SetMaxCount(count)
    --CharacterManager.SetMaxVisiableCount(tonumber(count) or -1)
end



local function LogProtocol(str)
    if str=="true" then
        Local.LogProtocol = true
        ReplaceLog("Local.LogProtocol = false", "Local.LogProtocol = true")
    else
        Local.LogProtocol = false
        ReplaceLog("Local.LogProtocol = true","Local.LogProtocol = false")
    end
end

local function LogTraceBack(str)
    if str=="true" then
        Local.LogTraceback = true
        ReplaceLog("Local.LogTraceback = false", "Local.LogTraceback = true")
    else
        Local.LogTraceback = false
        ReplaceLog("Local.LogTraceback = true","Local.LogTraceback = false")
    end
end

local function Status(str)
    if str=="true" then
        Local.Status = true
        ReplaceLog("Local.Status = false", "Local.Status = true")
    else
        Local.LogProtocol = false
        ReplaceLog("Local.Status = true","Local.Status = false")
    end
end

local  function ShowStatus(str)

end

local function ShowMemInfo() 

end 

local function ShowMaxTaskCount() 

end 




local CommandList = {
    ["playcg"] = PlayCG,
    ["changelog"] = ChangeLog,
    ["setnavmode"] = SetNavMode,
    ["navto"] = NavigateTo,
    ["showeffect"] = ShowEffect,
    ["showbuffeffect"] = ShowBuffEffect,
    ["showflash"] = ShowFlash,
    ["setm"] = SetModuleId,
    ["groundtest"] = GroundTest,
	["setmaxcount"] = SetMaxCount,
    ["logprotocol"] = LogProtocol,
    ["logtraceback"] = LogTraceBack,
    ["status"] = Status,
    ["showstatus"] = ShowStatus,
    ["showmeminfo"] = ShowMemInfo,
    ["showmaxtaskcount"] = ShowMaxTaskCount,
    
}

local function GetCommandTitle()
    return 1, 4, "/cmd"
end

local function Command(str,channel)
    if #str < 6 then
        return
    end
    --ShowMessage(tostring(str), {chat = true})
    local fullStr = string.sub(str,6,#str)
    local emptyI,emptyJ = string.find(fullStr," ")
    local cmdName = string.sub(fullStr, 1, emptyI-1)
    local cmdContent = string.sub(fullStr, emptyJ+1, #fullStr )

    local cmdFunc =  CommandList[cmdName]
    if cmdFunc ~= nil then
        local info = cmdFunc(cmdContent)
        if info ~=nil then 
            local chatmanager = require "ui.chat.chatmanager"
            local content = {}
            content.text = info
            content.channel = channel
            content.sendername = "CMD:"
            content.senderprofession = PlayerRole:Instance().m_Profession
            content.sendergender = PlayerRole:Instance().m_Gender
	        chatmanager.AddMessageInfo(content)
        end 

    end
end


return {
    Command = Command,
    GetCommandTitle = GetCommandTitle,
}
