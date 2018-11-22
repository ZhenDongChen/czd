local unpack, print     = unpack, print
local UIManager 	    = require "uimanager"
local EventHelper 	    = UIEventListenerHelper
local ConfigManager     = require("cfg.configmanager")
local LimitManager      = require"limittimemanager"
local ectypeid          = 60480001
local network           = require"network"
local EctypeManager     = require"ectype.ectypemanager"
local CheckCmd          = require"common.checkcmd"
local TimeUtils         = require"common.timeutils"
local BonusManager      = require"item.bonusmanager"
local TeamSpeedManager  = require"ectype.teamspeedmanager"
local name, gameObject, fields
local ConfigSpeed
local Config
local serverTime
local bOpen
local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")
local bSigned
local mathLast = 15 * 60

local function refresh(params)
    bSigned = TeamSpeedManager.IsSigned()
    if not bSigned then
        fields.UILabel_SignSingle.text = LocalString.EctypeText.TeamSpeedSign
        EventHelper.SetClick(fields.UIButton_Sign,function()
            network.send(lx.gs.map.msg.CBeginMatchTeamSpeed({}))
            --network.send(lx.gs.map.msg.CPersonalApplyTeamSpeed({}))
        end)
    else
        fields.UILabel_SignSingle.text = LocalString.EctypeText.TeamSpeedCancel
        EventHelper.SetClick(fields.UIButton_Sign,function()
            --network.send(lx.gs.map.msg.CCancelMatchTeamSpeed({}))
            network.send(lx.gs.map.msg.CCancelTeamSpeedApply({}))
        end)
    end
end

local function destroy()

end

local function IsInActivity()

    local serverDayTime = serverTime % (24*60*60)
    local space = ConfigSpeed.battlelast - ConfigSpeed.singuplast
    for i,timeinfo in ipairs(ConfigSpeed.timeinfo) do
        local beginTime     = timeinfo.begintime
        local endTime       = timeinfo.endtime
        local beginSeconds = TimeUtils.getSeconds({days=0,hours=beginTime.hour,minutes=beginTime.minute,seconds=beginTime.second})
        local endSeconds = TimeUtils.getSeconds({days=0,hours=endTime.hour,minutes=endTime.minute,seconds=endTime.second})
        if serverDayTime<endSeconds and serverDayTime >= beginSeconds then return true end
    end
    return nil
end

local function RefreshState()
    if bOpen then
        local timeInfoIndex = IsInActivity()
        if timeInfoIndex then
            fields.UILabel_StatusNow.text = LocalString.EctypeText.TeamSpeedOpen
        else
            fields.UILabel_StatusNow.text = LocalString.EctypeText.TeamSpeedClose
        end
    end
end

local function show(params)
    bSigned = TeamSpeedManager.IsSigned()
    serverTime = TimeUtils.GetServerTime() + 8*3600
    local level
    bOpen = false
    local floorid
    for id,v in pairs(ConfigSpeed.lvmsg) do
        local val,info = CheckCmd.CheckData({data=v.lv})
        if val then
            floorid = id
            bOpen = true
            break
        end
    end
    if bOpen then
        fields.UIGroup_Lock.gameObject:SetActive(false)
        fields.UITexture_Pvp.shader = activeShader
        fields.UILabel_Level.gameObject:SetActive(true)
        fields.UIButton_Detail.gameObject:SetActive(true)
        fields.UILabel_Levels.text = tostring(ConfigSpeed.lvmsg[floorid].lv.min) .. '-' .. tostring(ConfigSpeed.lvmsg[floorid].lv.max)
        fields.UIList_Icon:Clear()
        local bonuses = BonusManager.GetItemsByBonusConfig(ConfigSpeed.lvmsg[floorid].showbonusid)
        if bonuses then
            for _,bonus in pairs(bonuses) do
                local item = fields.UIList_Icon:AddListItem()
                BonusManager.SetRewardItem(item,bonus,{notShowAmount= true})
            end
        end
        local remainTime = ConfigSpeed.dailylimit.entertimes[PlayerRole.Instance().m_VipLevel+1] - LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.TEAM_SPEED,0)
        fields.UILabel_RewardCount.text = string.format(LocalString.EctypeText.TeamSpeedRemainTime,tostring(remainTime))
    else
        fields.UITexture_Pvp.shader = inactiveShader
        fields.UIButton_Detail.gameObject:SetActive(false)
        fields.UIGroup_Lock.gameObject:SetActive(true)
        fields.UILabel_Lock.text = string.format(LocalString.EctypeText.SpeedLevelRequire,ConfigSpeed.openlevel.level)
        fields.UILabel_Level.gameObject:SetActive(false)
        local remainTime = ConfigSpeed.dailylimit.entertimes[PlayerRole.Instance().m_VipLevel+1] - LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.TEAM_SPEED,0)
        fields.UILabel_RewardCount.text = string.format(LocalString.EctypeText.TeamSpeedRemainTime,tostring(remainTime))
    end

    -- fields.UIButton_Sign.isEnabled = bOpen
    -- fields.UIButton_TeamSign.isEnabled = bOpen
    RefreshState()
end

local function hide()

end

local function update()

end

local function to2num(value)
    return string.format("%02d",value)
end

local function GetFixedTime(h,m,s)
    return to2num(h) .. ':' .. to2num(m)
end

local function init(params)
    name, gameObject, fields = unpack(params)

    ConfigSpeed = ConfigManager.getConfig("teamspeed")
    local textTime = ""
    for _,timeinfo in ipairs(ConfigSpeed.timeinfo) do
        if textTime ~= "" then
            textTime = textTime .. '\n'
        end
        local timeOpen = timeinfo.begintime
        local timeFinish = timeinfo.endtime
        textTime = textTime .. GetFixedTime(timeOpen.hour,timeOpen.minute,timeOpen.second)
        textTime = textTime .. ' - '
        textTime = textTime .. GetFixedTime(timeFinish.hour,timeFinish.minute,timeFinish.second)
    end

    fields.UILabel_Time.text = textTime

    EventHelper.SetClick(fields.UIButton_Detail,function()
        UIManager.show("common.dlgdialogbox_complex",{type=2,text = rewardText,callBackFunc = function(params,ofields)
            ofields.UILabel_Content_Single.text = ConfigSpeed.desc
        end})
    end)
    --
    -- EventHelper.SetClick(fields.UIButton_Sign,function()
    --     network.send(lx.gs.map.msg.CPersonalApplyTeamSpeed({}))
    -- end)
    --
    -- EventHelper.SetClick(fields.UIButton_TeamSign,function()
    --     network.send(lx.gs.map.msg.CTeamApplyTeamSpeed({}))
    -- end)
end

local function second_update()
    serverTime = serverTime + 1
    RefreshState()
end

local function UnRead()
    serverTime = TimeUtils.GetServerTime() + 8*3600
    bOpen = false
    local floorid
    ConfigSpeed = ConfigManager.getConfig("teamspeed")
    for id,v in pairs(ConfigSpeed.lvmsg) do
        local val,info = CheckCmd.CheckData({data=v.lv})
        if val then
            floorid = id
            bOpen = true
            break
        end
    end
    if not bOpen then return false end
    if ConfigSpeed.dailylimit.entertimes[PlayerRole.Instance().m_VipLevel+1] <= LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.TEAM_SPEED,0) then
        return false
    end
    return IsInActivity()
end

return {
    init    = init,
    show    = show,
    hide    = hide,
    update  = update,
    destroy = destroy,
    refresh = refresh,
    second_update = second_update,
    UnRead  = UnRead,
}
