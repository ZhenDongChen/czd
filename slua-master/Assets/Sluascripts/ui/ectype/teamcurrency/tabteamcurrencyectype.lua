local Unpack = unpack
local Format = string.format
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local TeamCurrencyManager = require("ui.activity.teamcurrency.teamcurrencymanager")
local BonusManager = require("item.bonusmanager")
local TeamManager = require("ui.team.teammanager")
local LimitManager = require("manager.limittimemanager")
local ItemManager = require("item.itemmanager")
local EctypeManager = require("ectype.ectypemanager")

local m_Fields
local m_Name
local m_GameObject

local function destroy()
end

local function ShowBonus(bonusIds)
    for _,id in pairs(bonusIds) do
        BonusManager.SetRewardItem(m_Fields.UIList_Icon:AddListItem(),ItemManager.CreateItemBaseById(id),{notShowAmount = true})
    end
end

local function show(params)
    local ectype = TeamCurrencyManager.GetEctypeByLevel()
    m_Fields.UITexture_Pvp:SetIconTexture(ectype.backgroundpic)
    ShowBonus(ectype.showbonusid)
    m_Fields.UILabel_PhysicalStrength.text = TeamManager.GetAverageLevel()
    local freeTimes = ectype.dailytime.num
    local remainTimes = freeTimes - LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.DAILY_ECTYPE,cfg.ectype.EctypeType.CURRENCY_ACTIVITY)
    if remainTimes > 0 then
        m_Fields.UIButton_Extract.isEnabled = true 
        EventHelper.SetClick(m_Fields.UIButton_Extract,function()
            EctypeManager.RequestEnterTeamCurrency()
        end)
    else
        m_Fields.UIButton_Extract.isEnabled = false 
    end
    m_Fields.UILabel_Times.text = Format(LocalString.TeamCurrencyEctype_RemainTime,remainTimes)
end

local function init(params)
    m_Name,m_GameObject,m_Fields = Unpack(params)
    
end

return
{
    init = init,
    show = show,
    destroy = destroy,
}