local unpack = unpack
local print = print
local math = math
local EventHelper           = UIEventListenerHelper
local uimanager             = require("uimanager")
local network               = require("network")
local CharacterManager      = require "character.charactermanager"
local EctypeManager         = require "ectype.ectypemanager"
local ConfigManager         = require "cfg.configmanager"
local ErrorManager          = require "assistant.errormanager"
local PickManager           = require"character.pickupmanager"
local BonusManager          = require"item.bonusmanager"
local PlayerRole            = require "character.playerrole"
local AudioManager          = require("audiomanager")

local playerRole
local fields
local name
local gameObject
local baseid = nil
local base = nil
local map_item_buff = {}
local map_buff_item = {}
local bonus
local account
local ectypeid
local currScore
local isMax = {}
local requireScore = {}

-- statistic
local refreshSeconds
local totalDmg
local players
local bNeedInit
local showHurt

local function destroy()
end

local function show(params)
    showHurt = false
    fields.UIGroup_FirstOfSuccess.gameObject:SetActive(false)
    fields.UIGroup_Success.gameObject:SetActive(false)
    fields.UIGroup_MainUI.gameObject:SetActive(true)
end

local function hide()
end

local function UpdateBaseState()
    if base and base.m_Object then
        local pct = base.m_Attributes[cfg.fight.AttrId.HP_VALUE]/base.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
        fields.UIProgressBar_Blood.value = pct
        fields.UILabel_BaseHP.text = tostring(math.floor(pct*100))..'%'
        if base.m_HeadInfo then
            base.m_HeadInfo:ShowHpProgress(true)
        end
    else
        local char = CharacterManager.GetNearestCharacterByCsvId(baseid)
        if char and char.m_Object then
            base = char
            fields.UIProgressBar_Blood.gameObject:SetActive(true)
        else
            fields.UIProgressBar_Blood.gameObject:SetActive(false)
        end
    end
end

local function update()
    if baseid then
        UpdateBaseState(baseid)
    end
end

local function refresh(params)

end

local function RefreshDamanges()
    if fields.UIGroup_Rank.gameObject.activeSelf then
        printyellow("players",players)
        printt(players)
        fields.UIList_Rank:ResetListCount(#players)
        for idx,player in pairs(players) do
            local item = fields.UIList_Rank:GetItemByIndex(idx-1)
            local labelName = item.Controls["UILabel_Name"]
            local sliderHP = item.Controls["UISlider_HP"]
            local rank = item.Controls["UILabel_RankList"]
            rank.text = tostring(idx)
            labelName.text = player.name
            if totalDmg<1 then
                sliderHP.value = 0
            else
                sliderHP.value = player.dmg/totalDmg
            end
        end
    end
end

local function ShowTasks(b)
    if b then
        fields.UIGroup_MainUI.gameObject:SetActive(not showHurt)
        fields.UIGroup_Rank.gameObject:SetActive(showHurt)
    else
        fields.UIGroup_MainUI.gameObject:SetActive(false)
        fields.UIGroup_Rank.gameObject:SetActive(false)
    end
    fields.UIButton_Hurt.gameObject:SetActive(b)
    RefreshDamanges()
end

local function LeaveEctype()
    EctypeManager.RequestLeaveEctype()
end

local function RequestEndTower()
    network.send(map.msg.CEndClimbTowerEctype({}))
end

local function ShowItemsFlyTexts(id,cnt)

end

local function RefreshUIGroup_Success(floor,endInfo,time)
    local firstbonus = endInfo.firstbonus
    local normalbonus = endInfo.normalbonus
    local bonus = firstbonus
    for idx,count in pairs(normalbonus.items) do
        if bonus.items[idx] then
            bonus.items[idx] = bonus.items[idx] + count
        else
            bonus.items[idx] = count
        end
    end
    local bonusItems = BonusManager.GetItemsOfServerBonus(bonus)
    for _,item in pairs(bonusItems) do
        local uiItem = fields.UIList_Rewards:AddListItem()
        BonusManager.SetRewardItem(uiItem,item)
    end
    fields.UILabel_SuccessNumber.text = tostring(floor)
    fields.UILabel_EXP.text = BonusManager.GetCurrencyValueOfServerBonusByType(normalbonus,cfg.currency.CurrencyType.JingYan)
    fields.UILabel_Money.text = BonusManager.GetCurrencyValueOfServerBonusByType(normalbonus,cfg.currency.CurrencyType.XuNiBi)
    fields.UIPlayTween_Other2:Play(true)
    fields.UIPlayTween_Background2:Play(true)
end


local function RefreshUIGroup_Alert(endInfo,ectypeid,time,floor)
    local text = ""
    local towerConfig = ConfigManager.getConfigData("climbtowerectype",ectypeid)
    local floorsInfo = towerConfig.floors_id
    local nextFloorLv = floorsInfo[floor+1].requirelevel
    text = LocalString.EctypeText.Tower_LevelPrefix
    text = text .. tostring(nextFloorLv)
    text = text .. EctypeText.Tower_LevelSuffix
    fields.UILabel_AlertFloor.text = text
    text = ""
    text = tostring(math.floor(time/60))
    text = text .. LocalString.EctypeText.Tower_Minute
    text = text .. (math.floor(math.modf(time,60)))
    text = text .. LocalString.EctypeText.Tower_Second
    fields.UILabel_AlertTime.text = text
    text = ""
    text = LocalString.EctypeText.Tower_LevelPrefix
    text = text .. tostring(nextFloorLv)
    text = text .. EctypeText.Tower_LevelSuffix
    fields.UILabel_Remind.text = text
end

local function RefreshUIGroup_FirstOfSuccess(ectypeid,endInfo,time)
    local player = PlayerRole.Instance()
    local firstbonus = endInfo.firstbonus
    local normalbonus = endInfo.normalbonus
    local bonus = firstbonus
    for idx,count in pairs(normalbonus.items) do
        if bonus.items[idx] then
            bonus.items[idx] = bonus.items[idx] + count
        else
            bonus.items[idx] = count
        end
    end
    fields.UILabel_FirstOfSuccessLayer1.text =tostring(endInfo.newmaxfloorid)
    fields.UILabel_FirstOfSuccessLayer.text = tostring(PlayerRole.Instance().m_ClimbTowerInfo[ectypeid].maxfloorid)
    fields.UILabel_FirstOfSuccessNumber.text = tostring(endInfo.newrank and endInfo.newrank or LocalString.EctypeText.UnRank)
    fields.UILabel_CostTime.text = tostring(math.floor(time/60)) .. LocalString.EctypeText.Minute .. tostring(math.floor(time%60)) .. LocalString.EctypeText.Second
    fields.UIList_FirstOfSuccessRewards:Clear()
    local bonusItems = BonusManager.GetItemsOfServerBonus(bonus)
    for _,item in pairs(bonusItems) do
        local uiItem = fields.UIList_FirstOfSuccessRewards:AddListItem()
        BonusManager.SetRewardItem(uiItem,item)
    end
    fields.UIPlayTween_Other:Play(true)
    fields.UIPlayTween_Background:Play(true)

end
local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_Left)
    uimanager.SetAnchor(fields.UIWidget_TopRight)
end
local function init(params)
    name, gameObject, fields = unpack(params)
    SetAnchor(fields)
    playerRole = PlayerRole.Instance()

    EventHelper.SetClick(fields.UIButton_RequestLeave,function()
        local tb = {}
        tb.immediate = true
        tb.title = LocalString.EctypeText.LeaveWarningTitle
        tb.content = LocalString.EctypeText.LeaveWarningContent
        tb.callBackFunc = LeaveEctype
        uimanager.ShowAlertDlg(tb)
    end)

    EventHelper.SetClick(fields.UIButton_FirstOfSuccessSure,function()
        LeaveEctype()
    end)

    EventHelper.SetClick(fields.UIButton_SuccessSure,function()
        LeaveEctype()
    end)

    EventHelper.SetClick(fields.UIButton_Hurt,function()
        showHurt = not showHurt
        fields.UIGroup_Rank.gameObject:SetActive(showHurt)
        fields.UIGroup_MainUI.gameObject:SetActive(not showHurt)
        RefreshDamanges()
    end)
end

local function Clear()
        fields.UIList_Mission:Clear()
        Mappings = {}
end

local function GetFormatedTime(t)
    return string.format("%02d",t)
end

local function UpdateRemainTime(h,m,s)
    if fields then
        fields.UILabel_RemainTime.text = GetFormatedTime(h)..':'..GetFormatedTime(m)..':'..GetFormatedTime(s)
    end
end

local function Revive(remainReviveTime)
    fields.UILabel_IntegralNumber.text = tostring(remainReviveTime)
end

local function EnterTower(level,score,bid,buffs,remainReviveTime)
    currScore = score
    fields.UILabel_Integral.text = string.format(LocalString.EctypeText.TowerScore,score)
    fields.UILabel_LayerNumber.text = tostring(level)
    fields.UILabel_IntegralNumber.text = tostring(remainReviveTime)
    baseid = bid
    for i,v in pairs(buffs) do
        item = fields.UIList_Attribute:AddListItem()
        map_item_buff[item.m_nIndex] = i
        map_buff_item[i] = item
    end
end

local function ScoreEnough(id)
    return currScore>= requireScore[id]
end

local function IsMax(id)
    return isMax[id]
end

local function RequestBuyBuff(id)
    local re = map.msg.CBuyBuff({buffid=id})
    network.send(re)
end

local function BuyBuff(id,newLevel,buffs)
    local buff = buffs[id]
    local item = map_buff_item[id]
    local buttonlabel = item.Controls["UILabel_Integral"]
    if buff.price[newLevel+1] then
        requireScore[id] = buff.price[newLevel+1]
        buttonlabel.text = buff.price[newLevel+1]..LocalString.EctypeText.Integral
    else
        isMax[id] = true
        buttonlabel.text = "MAX"
    end
    local buffinfo = ConfigManager.getConfigData("buff",id)
    local effect = buffinfo.effects[1]
    local effectinfo = ConfigManager.getConfigData("effect",effect.effectid)
    local value = effectinfo.value*100
    local text
    local totaltext
    if value>0 then
        text = effectinfo.name .. '+' .. tostring(value) ..'%'
        totaltext = tostring(100+value*newLevel) ..'%'
    else
        text = effectinfo.name .. '-' .. tostring(value) ..'%'
        totaltext = tostring(100-value*newLevel) ..'%'
    end
    local addValueLabel = item.Controls["UILabel_AddValue"]
    addValueLabel.text = text
    local attributeValueLabel = item.Controls["UILabel_AttributeValue"]
    attributeValueLabel.text = totaltext

end

local function InitBuff(buffs,currentLevel)
    for id,buff in pairs(buffs) do
        isMax[id] = false
        requireScore[id] = 0
        local item = map_buff_item[id]
        local buttonlabel = item.Controls["UILabel_Integral"]
        local textureBuff = item.Controls["UITexture_Arrows"]
        if buff.price[currentLevel[id]+1] then
            buttonlabel.text = buff.price[currentLevel[id]+1]..LocalString.EctypeText.Integral
            requireScore[id] = buff.price[currentLevel[id]+1]
        else
            buttonlabel.text = "MAX"
            isMax[id] = true
        end
        local buffinfo = ConfigManager.getConfigData("buff",id)
        local effect = buffinfo.effects[1]
        local effectinfo = ConfigManager.getConfigData("effect",effect.effectid)
        local value = effectinfo.value*100
        local text
        local totaltext
        if value>0 then
            text = effectinfo.name .. '+' .. tostring(value) ..'%'
            totaltext = tostring(100+value*(currentLevel[id])) ..'%'
        else
            text = effectinfo.name .. '-' .. tostring(value) ..'%'
            totaltext = tostring(100-value*(currentLevel[id])) ..'%'
        end
        local addValueLabel = item.Controls["UILabel_AddValue"]
        textureBuff:SetIconTexture(buff.icon)
        addValueLabel.text = text
        local attributeValueLabel = item.Controls["UILabel_AttributeValue"]
        attributeValueLabel.text = totaltext
        local btn = item.Controls["UIButton_Intensify"]
        EventHelper.SetClick(btn,function()
            if IsMax(id) then return end
            if not ScoreEnough(id) then return end
            RequestBuyBuff(id)
        end)
    end
end

local function SendStatistic()
    if fields.UIGroup_Rank.gameObject.activeSelf or bNeedInit then
        network.send(map.msg.CEctypeStatistic({}))
    end
end

local function OnStatistic(info)
    frameCount = info.frameCount
    totalDmg = info.totalDmg
    players = info.players
    RefreshDamanges()
end

local function InitPlayersDmg()
    printyellow("InitPlayersDmg")
    players = {}
    SendStatistic()
    bNeedInit = false
end

local function second_update()
    if frameCount then
        frameCount = frameCount - 1
        if frameCount < 0 then
            SendStatistic()
        end
    end
end

local function EctypeReady()
    InitPlayersDmg()
end

local function ChangeScore(score)
    currScore = score
    fields.UILabel_Integral.text = string.format(LocalString.EctypeText.TowerScore,score)
end

local function ChangeLayer(floorid)
    fields.UILabel_LayerNumber.text = tostring(floorid)
end

local function EnterEctype(towername)

end

local function callbackMaxFloor(outFields,outName,params)
    outFields.UIGroup_Reminder_Full.gameObject:SetActive(true)
    outFields.UIGroup_Title.gameObject:SetActive(false)
    outFields.UIButton_Close.gameObject:SetActive(false)
    outFields.UIGroup_Button_2.gameObject:SetActive(false)
    outFields.UIGroup_Button_1.gameObject:SetActive(true)
    local endInfo,ectypeid,time,floor = params.endInfo,params.ectypeid,params.time,params.floor
    local text1 = LocalString.EctypeText.Tower_LevelPrefix .. tostring(params.floor) .. LocalString.EctypeText.Tower_LevelSuffix
    local text2 = LocalString.EctypeText.Tower_CostTime
    text2 = text2 .. tostring(math.floor(params.time/60)) .. LocalString.EctypeText.Tower_Minute
    text2 = text2 .. tostring(math.floor(params.time%60)) .. LocalString.EctypeText.Tower_Second
    local text3 = LocalString.EctypeText.Tower_LevelPrefix
    local cfgTower = ConfigManager.getConfigData("climbtowerectype",ectypeid)
    local floorInfo = cfgTower.floors_id[floor+1]
    if floorInfo then
        text3 = text3 .. tostring(floorInfo.requirelevel) .. LocalString.EctypeText.Tower_LevelSuffix
        outFields.UILabel_Content_Single1.text = text3
    else
        text3 = cfgTower.endword
        outFields.UILabel_Content_Single1.text = text3
    end
    outFields.UILabel_Content_Single2.text = text2
    outFields.UILabel_Button_1.text=LocalString.SureText
    EventHelper.SetClick(outFields.UIButton_1,function()
        fields.UIGroup_Success.gameObject:SetActive(true)
        RefreshUIGroup_Success(floor,endInfo,time)
        uimanager.hide(outName)
    end)
end

local function EndClimbTower(endInfo,ectypeid,time,floor,oldfloor)
    fields.UIGroup_MainUI.gameObject:SetActive(false)
    uimanager.hide("dlguimain")
    ectypeid = ectypeid
    bonus = endInfo.bonus
    time = time
    local ErrorEnum = ErrorManager.GetErrorEnum()
    if ErrorEnum.BASE_DESTROY==endInfo.errcode or
    ErrorEnum.ECTYPE_TIMEOUT==endInfo.errcode or
    ErrorEnum.MAX_REVIVE_NUM==endInfo.errcode or
    ErrorEnum.ECTYPE_MAX_DEAD_COUNT == endInfo.errcode or
    ErrorEnum.ECTYPE_PLAYER_EXIT == endInfo.errcode then  --失败 世间到 死亡次数到 主动退出
        if (floor) > oldfloor then
            fields.UIGroup_FirstOfSuccess.gameObject:SetActive(true)
            RefreshUIGroup_FirstOfSuccess(ectypeid,endInfo,time)
        else
            fields.UIGroup_Success.gameObject:SetActive(true)
            RefreshUIGroup_Success(floor,endInfo,time)
        end
    elseif ErrorEnum.MAX_TOWER_FLOOR==endInfo.errcode or
    ErrorEnum.MAX_CUR_LEVEL_TOWER_FLOOR == endInfo.errcode then --达到最大层
        local tb = {}
        tb.callBackFunc = callbackMaxFloor
        tb.floor = floor
        tb.time = time
        tb.ectypeid = ectypeid
        tb.endInfo = endInfo
        uimanager.show("common.dlgdialogbox_common",tb)
    end
    if cfg.ectype.EctypeBasic.successaudioid ~= 0 then
        AudioManager.Play2dSound(cfg.ectype.EctypeBasic.successaudioid)
    end
end

local function EnterEctype()
    bNeedInit = true
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  UpdateRemainTime = UpdateRemainTime,
  Clear = Clear,
  ChangeLayer = ChangeLayer,
  ChangeScore = ChangeScore,
  EnterTower = EnterTower ,
  InitBuff = InitBuff,
  BuyBuff = BuyBuff,
  EndClimbTower = EndClimbTower,
  EnterEctype = EnterEctype,
  ShowTasks = ShowTasks,
  Revive = Revive,
  OnStatistic = OnStatistic,
  second_update = second_update,
  EctypeReady = EctypeReady,
}
