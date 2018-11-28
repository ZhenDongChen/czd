local EctypeOthersManager   = require("ectype.ectypeothersmanager")
local EventHelper           = UIEventListenerHelper
local UIManager             = require("uimanager")
local TeamManager           = require("ui.team.teammanager")
local ConfigManager         = require("cfg.configmanager")
local name, gameObject, fields

--=======================================================================================================================
--
--=======================================================================================================================
local function IsInSameServer(playerServerIndex)
    local roleServerIndex = PlayerRole:Instance().m_ServerId
    local serverMapCfg = ConfigManager.getConfig("serveridmap")
    local playerServerId = serverMapCfg[playerServerIndex]
    local roleServerId = serverMapCfg[roleServerIndex]
    --printyellow("serverId: ", playerServerId, roleServerId)
    if playerServerId ~= nil and roleServerId ~= nil then
        return (playerServerId == roleServerId)
    end
    return true
end


local function ShowTips(uiItem,playerInfo)
    if not IsInSameServer(playerInfo.m_ServerId) then
        UIManager.ShowSystemFlyText(LocalString.OtherTipsDifferentServer)
        return
    end

    local params = {
            charInfo        = playerInfo,
            coutDownTime    = 5,
            simpleMode      = true,
            sideMode        = true,
            position        = uiItem.Controls["UIGroup_Tips"].gameObject.transform.position,
        }
    if UIManager.isshow("common.dlgothertips") then
        UIManager.refresh("common.dlgothertips",params)
    else
        UIManager.show("common.dlgothertips",params)
    end
end

local function HideTip(allhide)
    if allhide == true then
        if UIManager.isshow("common.dlgothertips") then
            UIManager.hide("common.dlgothertips")
        end
    else
        if UIManager.isshow("common.dlgothertips") then
            UIManager.call("common.dlgothertips","HideSideTips")
        end
    end
end

local function RefreshPlayerItem(uiItem, playerInfo)

    local spriteHead = uiItem.Controls["UISprite_CharacterHead"]
    if spriteHead then
        spriteHead.spriteName = playerInfo:GetHeadIcon()
    end

    local spriteHeadBG = uiItem.Controls["UISprite_CharacterHeadBG"]
    if spriteHeadBG then
        EventHelper.SetClick(spriteHeadBG, function()
            if UIManager.isshow("common.dlgothertips") then
                UIManager.hide("common.dlgothertips")
            else
                ShowTips(uiItem,playerInfo)
            end

        end)
    end

    local labelCharacterName = uiItem.Controls["UILabel_CharacterName"]
    if labelCharacterName then
        labelCharacterName.text = playerInfo:GetName()
    end

    local labelCharacterLevel = uiItem.Controls["UILabel_CharacterLevel"]
    if labelCharacterLevel then
        labelCharacterLevel.text = tostring(playerInfo:GetLevel())
    end

    local labelVip = uiItem.Controls["UILabel_Vip"]
    if labelVip then
        labelVip.text = tostring(playerInfo:GetVipLevel())
    end
    local hpPercent = playerInfo:GetHpPercent()
    if hpPercent > 1 then
        hpPercent = 1
    end
    if hpPercent < 0 then
        hpPercent = 0
    end

    local progressBar = uiItem.Controls["UIProgressBar_CharacterHP"]
    if progressBar then
        progressBar.value = hpPercent
    end

    local labelHp = uiItem.Controls["UILabel_CharHeadHp"]
    if labelHp then
        labelHp.text = string.format("%s%%", tostring(math.ceil( hpPercent * 100 )))
    end

    local button =  uiItem.Controls["UIButton_Zan"]
    if button then
        EventHelper.SetClick(button, function()
            EctypeOthersManager.ClickLike(playerInfo:GetId())
        end)
    end
end


local function refresh(params)
    local playerInfos = EctypeOthersManager.GetEctypePlayers()
    local playerNum = #playerInfos
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Partner, playerNum)

    for i = 1, playerNum do
        local uiItem = fields.UIList_Partner:GetItemByIndex(i-1)
        local playerInfo = playerInfos[i]
        RefreshPlayerItem(uiItem, playerInfo)
    end
end

local function show(params)
    printyellow("show ")
end

local function hide()
    HideTip(true)
end

local function update()

end


local function init(params)
    name, gameObject, fields = unpack(params)
end

return {
    init = init,
    show = show,
    refresh = refresh,
    update = update,
    hide = hide,
}
