local Unpack = unpack
local Format = string.format
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local ConfigManager = require("cfg.configmanager")
local PlayerRole = require("character.playerrole"):Instance()
local NetWork = require("network")
local EctypeManager = require("ectype.ectypemanager")
local ItemManager = require("item.itemmanager")
local LimitManager = require("limittimemanager")
local ItemEnum = require("item.itemenum")
local ItemIntroduction = require("item.itemintroduction")
local BonusManager = require("item.bonusmanager")
local BagManager = require("character.bagmanager")
local CheckCmd = require("common.checkcmd")
local DailyEctypeManager = require("ui.ectype.dailyectype.dailyectypemanager")
local TimeUtils = require("common.timeutils")
local VipChargeManager = require("ui.vipcharge.vipchargemanager")
local EctypeDlgManager = require("ui.ectype.storyectype.ectypedlgmanager")
local ColorUtil = colorutil

local m_GameObject
local m_Name
local m_Fields

local function destroy()
end

local function show(params)
    local a = params
end

local function hide()
end

local function SetRecordNULL()
    m_Fields.UILabel_OthersName.text = LocalString.Ectype_NO
    m_Fields.UILabel_OthersAmount.text = ""
    m_Fields.UILabel_MyAmount.text = LocalString.Ectype_NO
end

local function ClearDetailInfo()
    m_Fields.UILabel_Contents2.text = ""
    m_Fields.UIList_Icon:Clear()
    SetRecordNULL()
end

local function ShowBonus(bonusIds)
    for _,id in pairs(bonusIds) do
        BonusManager.SetRewardItem(m_Fields.UIList_Icon:AddListItem(),ItemManager.CreateItemBaseById(id),{notShowAmount = true})
    end
end

local function GetVipLevel(data)
    local level = nil
    local extraTime = nil
    local currencyTimes = data.entertimes[PlayerRole:GetVipLevel() + 1]
    local i = 0
    for _,c in pairs(data.entertimes) do
        if i > PlayerRole:GetVipLevel() then
            if c > currencyTimes then
                level = i
                extraTime = (c - currencyTimes)
                break
            end
        end
        i = i + 1
    end
    return level,extraTime
end

local function DisplayDetailDailyEctype(ectypeType)
    ClearDetailInfo()
    local ectype,eId = DailyEctypeManager.GetEctypeByLevel(ectypeType)
    local UIButton_Extract = m_Fields.UIButton_Extract
    local UIButton_Sweep = m_Fields.UIButton_Sweep
    local isLock = (ectype == nil)
    m_Fields.UIGroup_Lock.gameObject:SetActive(isLock)
    if isLock then
        ColorUtil.SetTextureColorGray(m_Fields.UITexture_Pvp, true)
    else
        ColorUtil.SetTextureColorGray(m_Fields.UITexture_Pvp, false)
    end
    UIButton_Extract.gameObject:SetActive(not isLock)
    UIButton_Sweep.gameObject:SetActive(not isLock)
    m_Fields.UISprite_Background02.gameObject:SetActive(not isLock)    
    if ectype == nil then
        ectype = DailyEctypeManager.GetDefaultEctype(ectypeType)
        if ectype then
            m_Fields.UILabel_Condition.text = ""
            m_Fields.UILabel_Level.text = Format(LocalString.Ectype_OpenLevel,ectype.openlevel.level)
        end
    else
        local sweepNum,sweepName = DailyEctypeManager.GetSweepNumAndName(ectype.sweepinfo)       
        local ectypeInfo = DailyEctypeManager.GetEctypeInfo(ectypeType)
        local sweepResult = DailyEctypeManager.HasEnoughSweepTicket(ectype.sweepinfo)
        local tiliResult = false
        local validate,info = CheckCmd.CheckData({data = ectypeInfo.viptimes,moduleid = cfg.cmd.ConfigId.DAILY_ECTYPE,cmdid = ectypeType})
        if validate then
            tiliResult = PlayerRole:GetCurrency(cfg.currency.CurrencyType.TiLi) >= ectype.costtili.amount
        end
        if sweepResult then
            m_Fields.UILabel_Sweep.text = Format(LocalString.Ectype_RemainSweepGreen,sweepName,sweepNum)
        else
            m_Fields.UILabel_Sweep.text = Format(LocalString.Ectype_RemainSweepRed,sweepName,sweepNum)
        end
        EventHelper.SetClick(UIButton_Sweep,function()
            if validate then
                if tiliResult == true then
                    if sweepResult == true then
                        DailyEctypeManager.SendSweep(ectypeType)
						local tempEctype,eId = DailyEctypeManager.GetEctypeByLevel(ectypeType)
						if (tempEctype ~= nil) then
							DailyEctypeManager.SendGetBestRecord(ectypeType)
						end
                    else
                        local content = Format(LocalString.Ectype_SweepTicket,sweepName)
                        UIManager.ShowAlertDlg({immediate = true,content = content,sureText = LocalString.Ride_GoTo,callBackFunc = function()
                            UIManager.showdialog("dlgshop_common")
                        end})
                    end   
                else
                    EctypeDlgManager.ShowReminderTiLi()
                end
            end 
        end)            
        EventHelper.SetClick(UIButton_Extract,function()            
            if ectypeInfo then
                if validate then
                    if (tiliResult == false) then
                        --体力不足
                        EctypeDlgManager.ShowReminderTiLi()
                    else
                        EctypeManager.RequestEnterDailyEctype(ectypeType)
                    end
                else                   
                   if (shouldHideVip() ~= true) then
                      local level,extraTime = GetVipLevel(ectypeInfo.viptimes)
                      if (level == nil) or (extraTime == nil) then
                          UIManager.ShowSingleAlertDlg({content = LocalString.Ectype_UpgradeVIP})
                      else
                          local content = Format(LocalString.Ectype_UpgradeVIP_Tip,level,extraTime)
                          UIManager.ShowAlertDlg({immediate = true,content = content,sureText = LocalString.ImmediateRecharge,callBackFunc = function()
                                    --立即充值
                              VipChargeManager.ShowVipChargeDialog()
                          end})
                      end
                   end
                end
            end
        end)
        local enterTime = DailyEctypeManager.GetFreeTimes(ectypeType)
        local useTime = 0
        local limit = nil
        limit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.DAILY_ECTYPE,ectypeType)
        if limit then
            useTime = limit[cfg.cmd.condition.LimitType.DAY]
        end
        local remainTime = enterTime - useTime
        if (remainTime > 0) then
            m_Fields.UILabel_Times.text = Format(LocalString.Ectype_RemainChallengeTime,remainTime,enterTime)
        else
            m_Fields.UILabel_Times.text = Format(LocalString.Ectype_ChallengeTime,remainTime,enterTime)
        end
        local basicEctype = DailyEctypeManager.GetBasicEctypeById(eId)
        m_Fields.UILabel_Time.text = Format(LocalString.Ectype_LimitTime,basicEctype.totaltime / 60)
        m_Fields.UILabel_Grade.text = Format(LocalString.Ectype_ChallengeLevel,ectype.showlv)
    end
    if ectype ~= nil then
        local tili = PlayerRole:GetCurrency(cfg.currency.CurrencyType.TiLi)
        if tili < ectype.costtili.amount then
            m_Fields.UILabel_PhysicalStrength.text = Format(LocalString.Ectype_VitNotEnough, ectype.costtili.amount,tili)
        else
            m_Fields.UILabel_PhysicalStrength.text = Format(LocalString.Ectype_Vit, ectype.costtili.amount,tili)
        end
        m_Fields.UILabel_Contents1.text = ectype.introduction
        if ectype.backgroundpic and ectype.backgroundpic ~= "" then
            m_Fields.UITexture_Pvp:SetIconTexture(ectype.backgroundpic)
        end
        ShowBonus(ectype.showbonusid)
        m_Fields.UILabel_Money.text = ectype.introduction           
    end
end

local function DisplayDailyEctype(params)
    local ectype = ConfigManager.getConfigData("dailyactivitytab",3)
    DisplayDetailDailyEctype(ectype.ectypetype)
    local tempEctype,eId = DailyEctypeManager.GetEctypeByLevel(ectype.ectypetype)
    if (tempEctype ~= nil) then
        DailyEctypeManager.SendGetBestRecord(ectype.ectypetype)
    end
end

local function RefreshRedDot(ectypeType)
    -- for i = 0,m_Fields.UIList_Ectype.Count do
    --     local ectypeItem = m_Fields.UIList_Ectype:GetItemByIndex(i)
    --     if ectypeItem and ectypeItem.Id == ectypeType then
    --         ectypeItem.Controls["UISprite_Warning"].gameObject:SetActive(DailyEctypeManager.HasRemainChallengeTimeByType(ectypeType))
    --         break
    --     end
    -- end
end

local function OnMsg_SGetDailyBestRecord(msg)
    if (msg.name and msg.name ~= "") and (msg.mincosttime ~= 0) then
        m_Fields.UILabel_OthersName.text = msg.name
        m_Fields.UILabel_OthersAmount.text = TimeUtils.getDateTimeString(msg.mincosttime,"hh:mm:ss")
    else
        m_Fields.UILabel_OthersName.text = LocalString.Ectype_NO
        m_Fields.UILabel_OthersAmount.text = ""
    end
    if msg.mymincosttime ~= 0 then
        m_Fields.UILabel_MyAmount.text = TimeUtils.getDateTimeString(msg.mymincosttime,"hh:mm:ss")
    else
        m_Fields.UILabel_MyAmount.text = LocalString.Ectype_NO
    end
end

local function refresh(params)
    DisplayDailyEctype(params)
end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)
end

return {
    init = init,
    show = show,
    hide = hide,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    DisplayDetailDailyEctype = DisplayDetailDailyEctype,
    OnMsg_SGetDailyBestRecord = OnMsg_SGetDailyBestRecord,
    RefreshRedDot = RefreshRedDot,
}
