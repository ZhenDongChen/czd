local unpack        = unpack
local print         = print
local math          = math
local insert        = table.insert
local remove        = table.remove
local format        = string.format
local ceil          = math.ceil
local EventHelper   = UIEventListenerHelper
local uimanager     = require("uimanager")
local DLGLogin      = require("ui.dlglogin")
local gameObject
local name
local stateLabels = {
    [0]="UILabel_Checking",
    "UILabel_Unimpeded",
    "UILabel_Crowd",
    "UILabel_Maintain",
}
local state2Label = {
    [gnet.ServerLoad.GREEN]         = "UILabel_Unimpeded",
    [gnet.ServerLoad.YELLOW]        = "UILabel_Unimpeded",
    [gnet.ServerLoad.RED]           = "UILabel_Crowd",
    [gnet.ServerLoad.UNAVAILABLE]   = "UILabel_Maintain",
    [0]                             ="UILabel_Checking"
}
local fields
local recommend
local addedGroups

local serverlist
local groupNum
local spriteServerList
local currPage
local spriteServerSelect
local serverInfos = {}
local refreshServers

local function getServerState(serverIndex)
    return serverInfos[serverIndex] and serverInfos[serverIndex].state or 0
end

local function destroy()
    uimanager.call("dlglogin","OpEnable",true)
    LuaHelper.ClearServersState()
end

local function hide()
    uimanager.show("dlglogin")
    uimanager.call("dlglogin","OpEnable",true)
end

local function AddGroupServers(page,cnt)
    if addedGroups[page] then return end
    addedGroups[page] = true
    local serverids = {}
    local hosts = {}
    local ports = {}
    for i=1,cnt do
        local serverid = (page-1) * 10 + i
        serverInfos[serverid] = {}
        local address = serverlist[serverid].addresses[1]
        local host = address.host
        local port = address.port
        table.insert(serverids,serverid)
        table.insert(hosts,host)
        table.insert(ports,port)
    end
    LuaHelper.AddGroupServers(serverids,hosts,ports)
end

refreshServers = function()
        local cnt = currPage == groupNum and #serverlist % 10 or 10
        if cnt==0 then cnt=10 end
        AddGroupServers(currPage,cnt)
        for i=1,10 do
            if i<=cnt then
                spriteServerSelect[i].gameObject:SetActive(true)
                local iServer =(currPage - 1) * 10 + i
                local uilabel_Server = spriteServerSelect[i].Controls["UILabel_Server"]
                local textureHot = spriteServerSelect[i].Controls["UITexture_ServerMark_1"]
                textureHot.gameObject:SetActive(serverlist[iServer].isNew)
                uilabel_Server.text = DLGLogin.serverLabelInfo(iServer, serverlist[iServer].name)
                for k=0,3 do
                    local tmp = spriteServerSelect[i].Controls[stateLabels[k]]
                    tmp.gameObject:SetActive(false)
                    if iServer == recommend then
                        fields[stateLabels[k] .. "Recommend"].gameObject:SetActive(false)
                    end
                end
                if serverlist[iServer].isNew then
                    local stateIcon = spriteServerSelect[i].Controls[state2Label[getServerState(iServer)]]
                    stateIcon.gameObject:SetActive(true)
                    if iServer == recommend then
                        fields[state2Label[getServerState(iServer)].."Recommend"].gameObject:SetActive(true)
                    end
                else
                    local currState = getServerState(iServer)
                    if currState ~= gnet.ServerLoad.GREEN then
                        local stateIcon = spriteServerSelect[i].Controls[state2Label[currState]]
                        stateIcon.gameObject:SetActive(true)
                        if iServer == recommend then
                            fields[state2Label[currState].."Recommend"].gameObject:SetActive(true)
                        end
                    end
                end
                local btn = spriteServerSelect[i].gameObject:GetComponent("UISprite")
                EventHelper.SetClick(btn,function()
                    local selectedServerIndex =(currPage - 1) * 10 + i
                    if not serverInfos[selectedServerIndex].state then return end
                    if serverInfos[selectedServerIndex].state == gnet.ServerLoad.UNAVAILABLE then
                        uimanager.ShowAlertDlg({ immediate    = true,title = "preserve", content = "start time \n\nend time" })
                    else
                        DLGLogin.ResetSelectedServer(selectedServerIndex)
                        uimanager.destroy(name)
                    end
                end)
            else
                spriteServerSelect[i].gameObject:SetActive(false)
            end
        end
    local grid = fields.UIList_Server.gameObject:GetComponent("UIGrid")
    grid.enabled = true
end

local function late_update()
    if LuaHelper.IsServersStateAltered() then
        local newStates = LuaHelper.GetServersState()
        for i=1,#serverlist do
            if serverInfos[i] then
                serverInfos[i].state = newStates[i]
            end
        end
        refreshServers()
    end
end

local function refresh(params)

end

local function show(params)
    recommend = params
    LuaHelper.ClearServersState()
    DLGLogin.ResetSelectedServer(recommend)
    local suffix = DLGLogin.serverLabelInfo(recommend, serverlist[recommend].name)
    local prefix = LocalString.mapping.serverState[serverlist[recommend].serverState]
    fields.UILabel_Recommend.text =  suffix
    refreshServers()
end

local function init(params)
    name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_Return, function()
        uimanager.destroy(name)
    end )
    serverlist = GetServerList()
    groupNum = ceil(#serverlist / 10)
    currPage = 1
    spriteServerList = {}
    spriteServerSelect = {}
    addedGroups = {}
    for i = 1,groupNum do
        local item = fields.UIList_ServerGroup:AddListItem()
        item.gameObject:SetActive(true)
        spriteServerList[i] = item
        local tpLabel = item.Controls["UILabel_ServerGroup"]
        tpLabel.text = format(LocalString.mapping.serverGroup,(i-1)*10+1,i*10)
        if i==1 then
            local toggle = item.gameObject:GetComponent("UIToggle")
            toggle.startsActive = true
        end
    end

    for i=1,10 do
        local item = fields.UIList_Server:AddListItem()
        spriteServerSelect[i] = item
        spriteServerSelect[i].gameObject:SetActive(true)
    end

    for i = 1, groupNum do
        local item = fields.UIList_ServerGroup:GetItemByIndex(i-1)
        local btn = item.gameObject:GetComponent("UIButton")
        EventHelper.SetClick(btn, function()
            currPage = fields.UIList_ServerGroup:GetSelectedIndex() + 1
            refreshServers()
        end )
    end

    EventHelper.SetClick(fields.UISprite_Recommend, function()
        DLGLogin.ResetSelectedServer(recommend)
        uimanager.destroy(name)
    end )
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    late_update = late_update,
}
