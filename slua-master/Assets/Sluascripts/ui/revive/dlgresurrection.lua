local Unpack = unpack
local Math = math
local Format = string.format
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local NetWork = require("network")
local LimitManager = require("limittimemanager")
local PlayerRole = require("character.playerrole")
local CheckCmd = require("common.checkcmd")
local ConfigManager = require("cfg.configmanager")
local VipChargeManger = require("ui.vipcharge.vipchargemanager")
local ReviveManager

local REVIVE_DELAY_TIME = 2.5  --限制点击回城复活按钮频率

local m_GameObject
local m_Name
local m_Fields
local m_CanReviveTime = REVIVE_DELAY_TIME 
local m_CanRevive = false

local function destroy()
end

local function VIPTimes(reviveData)
    local vipTimes = reviveData.viprevivetimes
    local vipLevel = PlayerRole:Instance().m_VipLevel
    local totalTime = 0
    local hasLevel = false
    local i = 0
    for id,value in pairs(vipTimes.entertimes) do
        if (vipLevel == (id - 1)) then
            totalTime = value
            hasLevel = true
            break
        end
        i = i + 1
    end
    if hasLevel ~= true then
        totalTime = vipTimes.entertimes[i] or 0
    end
    local limit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.REVIVE,0)
    local remainTime
    if (limit == nil)  or (limit[cfg.cmd.condition.LimitType.DAY] == nil) then
        remainTime = totalTime
    else
        remainTime = totalTime - limit[cfg.cmd.condition.LimitType.DAY]
        if remainTime < 0 then
            remainTime = 0
        end
    end
    return totalTime,remainTime
end

local function GetCostYuanBaoCount()
    local reviveData = ConfigManager.getConfig("revive")
    local num = ReviveManager.GetCostYuanBaoReviveCount()
    local times = reviveData.revivecost[num + 1]
    if times == nil then
        times = reviveData.revivecost[#reviveData.revivecost]
    end
    return times
end

local function GetCostHuaShenCount()
    local reviveData=ConfigManager.getConfig("revive")
    local num = ReviveManager.GetCostHuaShenReviveCount()
    local times = reviveData.revivecost[num + 1]
    if times == nil then
        times = reviveData.revivecost[#reviveData.revivecost]
    end
    return times
end

local function show(params)   
    m_Fields.UIGroup_Message.gameObject:SetActive(true)
    m_Fields.UIButton_Close.gameObject:SetActive(false)
    m_Fields.UILabel_SituResurrection.text = LocalString.Revive_CurPos
    m_Fields.UILabel_StwpResurrection = LocalString.Revive_MainCity
    local title = ""
    if params then
        local CharacterManager = require("character.charactermanager")
        local attacker = CharacterManager.GetCharacter(params.attackerId)
        if attacker then
            title = Format(LocalString.DeadTip,attacker.m_Name)
        end
    end
    local UILabel_Resurrection = m_Fields.UILabel_Resurrection
    UILabel_Resurrection.text = title
    local reviveData = ConfigManager.getConfig("revive")
    local totalTime,remainTime = VIPTimes(reviveData)
    if shouldHideVip() ~= true then
        m_Fields.UILabel_Times.text = Format(LocalString.Revive_VIP,remainTime,totalTime)
    else
        m_Fields.UILabel_Times.text = ""
    end
    m_Fields.UILabel_Props.text = Format(LocalString.Revive_ResurStone,GetCostHuaShenCount())
    m_Fields.UILabel_Money.text = Format(LocalString.Revive_Ingot,GetCostYuanBaoCount() * (reviveData.reviveYuanBao.amount))    
    local validate1, info1 = CheckCmd.CheckData({data = reviveData.viprevivetimes,moduleid = cfg.cmd.ConfigId.REVIVE,cmdid = 0})
    local validate2, info2 = CheckCmd.CheckData({data = reviveData.reviveitem,num = GetCostHuaShenCount()})
    local validate3, info3 = CheckCmd.CheckData({data = reviveData.reviveYuanBao,num = GetCostYuanBaoCount()}) 
    m_Fields.UILabel_Times.gameObject:SetActive(validate1)
    m_Fields.UILabel_Props.gameObject:SetActive((not validate1) and validate2)
    m_Fields.UILabel_Money.gameObject:SetActive((not validate1) and (not validate2))
end

local function hide()
end

local function RefreshReviveTime(time)
    m_Fields.UILabel_AutoStwpResurrection.text = Format(LocalString.Revive_Tip,Math.ceil(time))
end

local function update()  
    if not m_CanRevive then
        m_CanReviveTime = m_CanReviveTime - Time.deltaTime
        if m_CanReviveTime < 0 then
            m_CanRevive = true
        end
    end
end

local function refresh(params)
end

local function init(name,gameObject,fields)
    ReviveManager = require("character.revivemanager")
    m_Name, m_GameObject, m_Fields = name,gameObject,fields
    m_CanReviveTime = REVIVE_DELAY_TIME 
    m_CanRevive = false
    EventHelper.SetClick(m_Fields.UIButton_SituResurrection,function()       
        local reviveData = ConfigManager.getConfig("revive") 
        local validate1, info1 = CheckCmd.CheckData({data = reviveData.viprevivetimes,moduleid = cfg.cmd.ConfigId.REVIVE,cmdid = 0})
        local validate2, info2 = CheckCmd.CheckData({data = reviveData.reviveitem,num = GetCostHuaShenCount()})
        local validate3, info3 = CheckCmd.CheckData({data = reviveData.reviveYuanBao,num = GetCostYuanBaoCount()})      
        if (validate1 or validate2 or validate3) then
            UIManager.hide(m_Name) 
            ReviveManager.SetReviveState(false)
            ReviveManager.SendCRevive(cfg.map.ReviveType.CUR_POSITION)
        else
            local params = {immediate = true,content = LocalString.Revive_CanNotRevive,callBackFunc = function()
                        UIManager.hide(m_Name)
                        VipChargeManger.ShowVipChargeDialog()
                end}
            UIManager.ShowAlertDlg(params)
        end 
    end)
  
    EventHelper.SetClick(m_Fields.UIButton_StwpResurrection,function()
        if m_CanRevive then
            UIManager.hide(m_Name)
            ReviveManager.SendCRevive(cfg.map.ReviveType.REVIVE_POSITION)
            ReviveManager.SetReviveState(false)
        end
    end)  
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  RefreshReviveTime = RefreshReviveTime,
}