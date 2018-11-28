local uimanager = require"uimanager"
local gameevent = require "gameevent"

local www
local broadcast
local bException
local url
local timeout = 3
local elapsedTime
local tbBroadcast
local eventid
local retry

local Transferreds = {
    {"&nbsp;"," "},
    {"&quot;","\""},
    {"&amp;","&"},
    {"&lt;","<"},
    {"&gt;",">"},
    {"&#39;","\'"},
    {"&ldquo;","“"},
    {"&rdquo;","”"},
    {"<p>",""},
    {"</p>",""},
}

local function ParseHtml(htmlContent)
    local body_head = "<body>"
    local body_tail = "</body>"
    local head = "<div>"
    local tail = "</div>"
    _,_,_,htmlContent,_ = string.find(htmlContent, "(.*)("..body_head..".-"..body_tail..")(.*)")
    htmlContent = string.gsub(htmlContent,body_tail,"")
    htmlContent = string.gsub(htmlContent,body_head,"")
    htmlContent = string.gsub(htmlContent,head,"")
    htmlContent = string.gsub(htmlContent,tail,"")
    for _,v in ipairs(Transferreds) do
        htmlContent = string.gsub(htmlContent,v[1],v[2])
    end
    return htmlContent
end

local function StopUpdate()
    if eventid then
        gameevent.evt_late_update:remove(eventid)
        eventid = nil
    end
end

local function ShowBroadcastFailed(err)
    bException = true
	print("dummy:ShowBroadcastFailed")
    if uimanager.isshow"dlgnotice" then
        uimanager.ShowSingleAlertDlg{
            content = LocalString.ShowBroadcastFailed[err],
            callBackFunc = function()
                uimanager.hide(name)
            end
        }
    end
    StopUpdate()
end

local function GetBroadcast()
    return tbBroadcast or {}
end


local function LoadBroadCast(BoradCastContent)
    if BoradCastContent then
        local str = BoradCastContent
        local f = assert(loadstring("return " .. str))
        tbBroadcast = assert(f())
    else
		printyellow("1")
        ShowBroadcastFailed(1)
    end
end

local function ReleaseWWW()
    www:Dispose()
    www = nil
end

local function Retry()
    ReleaseWWW()
    retry = retry - 1
    elapsedTime = 0
end

local function late_update()
    if isDone or bException then return end
    if not broadcast and elapsedTime < timeout then
        elapsedTime = elapsedTime + Time.deltaTime
        if www then
            if www.isDone then
                if IsNull(www.error) then
                    broadcast = www.text
					printyellow(broadcast)
                    ReleaseWWW()
                    broadcast = ParseHtml(broadcast)
                    if broadcast then
                        if pcall(function() LoadBroadCast(broadcast) end) then
                            isDone = true
                            if uimanager.isshow"dlgnotice" then
                                uimanager.call("dlgnotice","ShowContents")
                            end
                            StopUpdate()
                        else
							printyellow("11111")
                            ShowBroadcastFailed(1)
                        end
                    end
                else
                    if retry > 0 then
                        Retry()
                    else
						printyellow("2")
                        ShowBroadcastFailed(2)
                    end
                    --
                end
            end
        else
            www = WWW(url)
        end
    else
        if retry > 0 then
            Retry()
        else
			printyellow("3")
            ShowBroadcastFailed(3)
        end
    end
end

local function init()
    www = nil
    broadcast = nil
    bException = false
    tbBroadcast = nil
    url = GetBroadCastUrl() .. "?v=" .. tostring(os.time())
    elapsedTime = 0
    retry = 3
    eventid = nil
    eventid = gameevent.evt_late_update:add(late_update)
end

return {
    init            = init,
    GetBroadcast    = GetBroadcast,
}
