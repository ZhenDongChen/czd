local unpack = unpack
local unpack = unpack
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require "network"
local login = require("login")
local dlgalert_tempdialog = require("ui.dlgalert_tempdialog")

local serverlist
local gameObject
local name
local fields
local selectedServer
local elapsedTime
local bc

local function destroy()

end

local function OpEnable(b)
    fields.UILabel_Change.gameObject:SetActive(b)
    fields.UIButton_Server.gameObject:SetActive(b)
end

local function update()
    if fields.UILabel_Change.gameObject.activeSelf then
        elapsedTime = nil
    else
        if elapsedTime then
            elapsedTime = elapsedTime - Time.deltaTime
            if elapsedTime<0 then
                OpEnable(true)
            end
        else
            elapsedTime = 1
        end
    end
end

local function getLatestLoginServer()
    return network.GetDefaultLogin()
end

local function show(params)
    OpEnable(true)
    local bcObj = fields.UILabel_Change.gameObject
    bc = bcObj:GetComponent("BoxCollider")
    if params and params.bNeedLogin then
        Game.Platform.Interface.Instance:Login()
    else
        uimanager.show("dlgnotice")
    end
    selectedServer = getLatestLoginServer()

    local name = UnityEngine.PlayerPrefs.GetString("username");
    fields.UIInput_ZChange.value = name

    local trfTexBG = gameObject.transform:Find("Texture_BG")
    if trfTexBG~=nil then
        local uiTex = trfTexBG.gameObject:GetComponent("UITexture")
        uimanager.SetUITextureFit(uiTex)
    end
end

local function hide()

end

local function serverLabelInfo(serverNum, serverName)
    return string.format(LocalString.mapping.concatStr,serverNum,serverName)
end

local function OnLoginSuccess()
    selectedServer = getLatestLoginServer()
end

local function refresh(params)
    serverlist = GetServerList()
    bc.enabled = true
    fields.UILabel_Change.text = serverLabelInfo(selectedServer, serverlist[selectedServer].name)
end

--保持用户的信息
local function saveLatestLoginServer(idx)
  
        UserConfig.DefaultLogin = idx
        UserConfig.DefaultServer = idx
        SaveUserConfig()

end

local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_TopLeft)
    uimanager.SetAnchor(fields.UIWidget_Bottom)
    uimanager.SetAnchor(fields.UIWidget_BottomRight)
    uimanager.SetAnchor(fields.UIWidget_Center)
end
local function init(params)
    name, gameObject, fields = unpack(params)
    SetAnchor(fields)
	
	
    EventHelper.SetClick(fields.UILabel_Change, function()
        uimanager.show("dlgselectserver", getLatestLoginServer())
        OpEnable(false)
    end )
    EventHelper.SetClick(fields.UIButton_Server, function()
		local loginstatus = Game.Platform.Interface.Instance:GetLoginStatus();
		if loginstatus == -1 or loginstatus == 0 then
			Game.Platform.Interface.Instance:Login()
        else
            if fields.UIInput_ZChange.gameObject.activeSelf then
                local strName = fields.UIInput_ZChange.value
                login.set_username(strName)
            end
			saveLatestLoginServer(selectedServer)
			network.connect()
            OpEnable(false)
		end
		
    end )

    EventHelper.SetClick(fields.UIButton_Announcement, function()
        uimanager.show("dlgnotice")
        OpEnable(false)
    end )

    EventHelper.SetClick(fields.UISprite_Account,function()
        login.Game_logout(login.LogoutType.to_login)
        Game.Platform.Interface.Instance:Login()
    end)
	
    fields.UIButton_Scan.gameObject:SetActive(false)


	--Application.platform == UnityEngine.RuntimePlatform.Android
    if LuaHelper.IsWindowsEditor()
     or Application.platform == UnityEngine.RuntimePlatform.WindowsPlayer then
		fields.UIInput_ZChange.gameObject:SetActive(true)
    else
        fields.UIInput_ZChange.gameObject:SetActive(false)
    end
	
	
	local dlgmonster_hp = require("ui.dlgmonster_hp")
	dlgmonster_hp.init() --TODO暂时加载这个预制的处理
end

local function ResetSelectedServer(idx)
    selectedServer = idx
	network.setSelectedServer(selectedServer)
    refresh()
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    serverLabelInfo = serverLabelInfo,
    ResetSelectedServer = ResetSelectedServer,
    OpEnable = OpEnable,
    OnLoginSuccess = OnLoginSuccess,
}
