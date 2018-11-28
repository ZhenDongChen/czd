local unpack        = unpack
local print         = print
local UIManager       = require("uimanager")
local EventHelper       = UIEventListenerHelper
local ConfigManager 	  = require "cfg.configmanager"
local LimitTimeManager       = require("limittimemanager")
local FamilyBossMgr = require("ui.family.boss.familybossmanager")
local PlayerRole         = require "character.playerrole"
local ItemManager	  = require("item.itemmanager")

local name
local gameObject
local fields
local m_IsShow = false

local m_Bossid

local function refresh(msg)
end

local function OnUIButton_TrainGold()
    --printyellow("[dlgbosstrain:OnUIButton_TrainGold] UIButton_TrainGold clicked!")
    --FamilyBossMgr.send_CRaiseGodAnimal(lx.gs.family.msg.CRaiseGodAnimal.RAISE_TYPE_XUNIBI, m_Bossid)
    
    local traingoldcfg = ConfigManager.getConfigData("bossfeed", 1)
    local costmoney = traingoldcfg.feedlimit.amout[1]
    local rolemoney = PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.XuNiBi]
    --printyellow(string.format("[dlgbosstrain:OnUIButton_TrainGold] costmoney=%d, rolemoney=%d.", costmoney, rolemoney))
    if rolemoney>=costmoney then
        FamilyBossMgr.send_CRaiseGodAnimal(lx.gs.family.msg.CRaiseGodAnimal.RAISE_TYPE_XUNIBI, m_Bossid)
    else
        ItemManager.GetSource(cfg.currency.CurrencyType.XuNiBi,"family.boss.dlgfamilyboss")
        UIManager.hide("common.dlgdialogbox_commodity")
    end
end

local function OnUIButton_TrainYuanbao()
    --printyellow("[dlgbosstrain:OnUIButton_TrainYuanbao] UIButton_TrainYuanbao clicked!")
    --FamilyBossMgr.send_CRaiseGodAnimal(lx.gs.family.msg.CRaiseGodAnimal.RAISE_TYPE_YUANBAO, m_Bossid)
    
    local trainyuanbaocfg = ConfigManager.getConfigData("bossfeed", 2)
    local costyuanbao = trainyuanbaocfg.feedlimit.amout[1]
    local roleyuanbao = PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.YuanBao]
    --printyellow(string.format("[dlgbosstrain:OnUIButton_TrainYuanbao] costyuanbao=%d, roleyuanbao=%d.", costyuanbao, roleyuanbao))
    if roleyuanbao>=costyuanbao then
        FamilyBossMgr.send_CRaiseGodAnimal(lx.gs.family.msg.CRaiseGodAnimal.RAISE_TYPE_YUANBAO, m_Bossid)
    else
        ItemManager.GetSource(cfg.currency.CurrencyType.YuanBao,"family.boss.dlgfamilyboss")
        UIManager.hide("common.dlgdialogbox_commodity")
    end
end

local function ShowTrainCount()
    local traingoldcfg = ConfigManager.getConfigData("bossfeed", 1)
    local trainlimit = LimitTimeManager.GetLimitTime(cfg.cmd.ConfigId.FAMILY_FEED, 1)
    local trainTime = 0
    if trainlimit then
        trainTime=trainlimit[1]
        --[[for key, value in pairs(trainlimit) do
            printyellow(string.format("[dlgbosstrain:ShowTrainCount] key=%s, value=%s.", key, value))
        end--]]
    else
        -- printyellow("[dlgbosstrain:ShowTrainCount] trainlimit nil!")
    end
    local totalTime = 0
    if traingoldcfg then
        local vipindex = 1  --  ==viplevel+1
        totalTime = traingoldcfg.feedlimit.entertimes[vipindex]
    end
    --printyellow(string.format("[dlgbosstrain:ShowTrainCount]trainTime=%d, totalTime=%d!", trainTime, totalTime))
     fields.UILabel_Count.text = string.format("%d/%d", trainTime, totalTime)
end

local function UpdateReddot()
    --printyellow("[dlgbosstrain:UpdateReddot] UpdateReddot!")
    if true==m_IsShow and fields and fields.UISprite_Warning then
        fields.UISprite_Warning.gameObject:SetActive(FamilyBossMgr.UnRead())    
    end
end

local function OnLimitChange()
    --printyellow("[dlgbosstrain:OnLimitChange] OnLimitChange!")
    ShowTrainCount()
    UpdateReddot()
end

local function registereventhandler()
    --printyellow("[dlgbosstrain:registereventhandler]dlgbosstrain registereventhandler!")

    EventHelper.SetClick(fields.UIButton_Sure, OnUIButton_TrainYuanbao)
    EventHelper.SetClick(fields.UIButton_Return, OnUIButton_TrainGold)
    LimitTimeManager.AddLimitChangeCallback(OnLimitChange)
end

local function InitPanels()
end

local function ShowCurrencyTrain(traincfg, uiLabelButton, buttontext, uiLabelNote, uiLabelCost)
    uiLabelButton.text = buttontext
    local trainnotetext = ""
    local costtext = ""
    if traincfg then
        --[[
        printyellow("[dlgbosstrain:ShowCurrencyTrain] traincfg.buildrate.money=", traincfg.buildrate.money)
        printyellow("[dlgbosstrain:ShowCurrencyTrain] traincfg.buildrate.buildv=", traincfg.buildrate.buildv)
        printyellow("[dlgbosstrain:ShowCurrencyTrain] LocalString.Family_Boss_Train_Get_Build=", LocalString.Family_Boss_Train_Get_Build)
        --]]

        trainnotetext = trainnotetext..string.format(LocalString.Family_Boss_Train_Get_Build, traincfg.buildrate.buildv)
        trainnotetext = trainnotetext..string.format(LocalString.Family_Boss_Train_Get_Banggong, traincfg.familycontribution.amount)
        trainnotetext = trainnotetext..string.format(LocalString.Family_Boss_Train_Get_BossExp, traincfg.exp)

        local vipindex = 1  --  ==viplevel+1
        costtext = traincfg.feedlimit.amout[vipindex]
    end
    uiLabelNote.text = trainnotetext
    uiLabelCost.text = costtext
end

local function show(params)
    --printyellow("[dlgbosstrain:show] show!")
    InitPanels()
    m_IsShow = true
    registereventhandler()
    m_Bossid = params.bossid

    --title
    fields.UILabel_Title.text = LocalString.Family_Boss_Train_Title

    --train left
    local traingoldcfg = ConfigManager.getConfigData("bossfeed", 1)
    ShowCurrencyTrain(traingoldcfg, fields.UILabel_Return, LocalString.Family_Boss_Train_Gold, fields.UILabel_Note_L, fields.UILabel_Resource)
    UpdateReddot()

    --train right
    local trainyuanbaocfg = ConfigManager.getConfigData("bossfeed", 2)
    ShowCurrencyTrain(trainyuanbaocfg, fields.UILabel_Sure, LocalString.Family_Boss_Train_Yuanbao, fields.UILabel_Note_R, fields.UILabel_Resource_2)

    --vip tip
    fields.UILabel_Tip.gameObject:SetActive(false)

    --count
    ShowTrainCount()
end

local function init(pname, gpameobject, pfields)
    name = "dlgbosstrain"
    gameObject = gpameobject
    fields = pfields
end

local function update()
end

local function reset()
end

local function hide()
    m_IsShow = false
    reset()
end

local function destroy()
end

return{
    show = show,
    init = init,
    destroy = destroy,
    refresh = refresh,
    update = update,
    hide = hide,
}
