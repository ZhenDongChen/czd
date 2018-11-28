local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper

local ConfigManager = require "cfg.configmanager"
local BonusManager = require("item.bonusmanager")
local define = require "define"
local PlayerRole = require "character.playerrole"
local Pet                   = require"character.pet.pet"
local lotteryfragmentinfo = require"ui.lottery.lotteryfragment.lotteryfragmentinfo"
local lotteryfragmentmgr = require"ui.lottery.lotteryfragment.lotteryfragmentmanager"
local UIManager       = require("uimanager")
local ItemManager = require("item.itemmanager")
local colorutil = colorutil
local VipChargeManager=require"ui.vipcharge.vipchargemanager"
local ItemIntroduct=require"item.itemintroduction"
local ItemEnum = require"item.itemenum"
local TalismanModel     = require("character.talisman.talisman")

local RotateState = enum{
    "Idle",
    "RotatingBefore",
    "RotatingAfter",
}

local TurntableAngle = {
    [1] = 0,
    [2] = 330,
    [3] = 300,
    [4] = 270,
    [5] = 240,
    [6] = 210,
    [7] = 180,
    [8] = 150,
    [9] = 120,
    [10] = 90,
    [11] = 60,
    [12] = 30,
}

local ScoreProgress = {
    [1] = 0.14,
    [2] = 0.28,
    [3] = 0.42,
    [4] = 0.56,
    [5] = 0.72,
    [6] = 0.86,
    [7] = 1,
}

local Pet_Icon_Valid = "ICON_Treature_Monley"
local Pet_Icon_Invalid = "ICON_Treature_Monley_Grey"

--ui
local fields
local gameObject
local name

--click interval control
local LOTTERY_DRAW_INTERVAL = 0.5
local m_DrawTime
local m_IsDrawEnabled

--tween rotate
local m_RotateTween
local m_RotateState
local m_TargetListitem
local m_TargetIndex
local m_TargetEngle
local m_PointingListitem

--others
local m_CurrentLotteryCfg
local m_TotalScore
local m_OneDrawCost
local m_AwardModel

local function ShowTurnTableBonus(index, listitem, bonusitem)
    if nil==listitem then
        print(string.format("[ERROR][dlglotteryfragment:ShowTurnTableBonus] listitem nil at index[%s]!", index))
    end
    if nil==bonusitem then
        print(string.format("[ERROR][dlglotteryfragment:ShowTurnTableBonus] bonusitem nil at index[%s]!", index))
    end
    if listitem and bonusitem then
        --printyellow(string.format("[dlglotteryfragment:ShowTurnTableBonus] show award[%s] at index[%s] on listitem[%s]!", bonusitem:GetName(), index, listitem.gameObject.name))
        listitem.Data = bonusitem

        --icon
        local UITexture_Icon = listitem.Controls["UITexture_Icon"]
        if UITexture_Icon then
            UITexture_Icon:SetIconTexture(bonusitem:GetIconPath())
        end
        
        --quality
        local spriteQuality = listitem.Controls["UISprite_Quality"]
        if spriteQuality then
            spriteQuality.spriteName = colorutil.GetQualitySprite(bonusitem:GetQuality())
        end
        
        --fragment        
        local UISprite_Fragment=listitem.Controls["UISprite_Fragment"]
        if UISprite_Fragment then
            UISprite_Fragment.gameObject:SetActive(bonusitem:GetBaseType()==ItemEnum.ItemBaseType.Fragment)
        end
        
        --count
        local labelNum = listitem.Controls["UILabel_Amount"]
        if labelNum then
            labelNum.gameObject:SetActive(true)
            labelNum.text = bonusitem:GetNumber()
        end
        --[[
        --name
        local labelName = listitem.Controls["UILabel_Amount"]
        if labelName then
            --labelName.text = bonusitem:GetName()
            labelName.gameObject:SetActive(true)
            colorutil.SetQualityColorText(labelName, bonusitem:GetQuality(), bonusitem:GetName())
        end
        --]]
    end
end

local function ShowTurnTable()
    local listcount = fields.UIList_LuckTurn.Count
    local bonuscount = lotteryfragmentinfo.GetLotteryBonusCount()
    local count = 0
    if listcount and bonuscount then
        count = math.min(listcount, bonuscount)
        count = math.max(0, count)
    end
    for index=1,count do
        local listitem = fields.UIList_LuckTurn:GetItemByIndex(index-1)
        local bonusinfo = lotteryfragmentinfo.GetLotteryBonusByIndex(index)
        local bonusList = bonusinfo and BonusManager.GetMultiBonusItems(bonusinfo.bonus) or nil
        local bonusitem
        if bonusList and #bonusList>0 then   
            --printyellow(string.format("[ERROR][dlglotteryfragment:ShowTurnTable] #bonusList = [%s]!", #bonusList))
            bonusitem = bonusList[1]
        end

        ShowTurnTableBonus(index, listitem, bonusitem)
    end
end

local function OnModelLoaded()
    if not m_AwardModel or not m_AwardModel.m_Object then 
        return 
    end

    --set transform, rotation ,scale
    local playerTrans         = m_AwardModel.m_Object.transform
    playerTrans.parent        = fields.UITexture_Model.transform
    m_AwardModel:SetUIScale(240)
    playerTrans.localPosition = Vector3(0, -230, -1500);
    playerTrans.localRotation = Vector3(0, 180, 0)
    ExtendedGameObject.SetLayerRecursively(m_AwardModel.m_Object, define.Layer.LayerUICharacter)
    EventHelper.SetDrag(fields.UITexture_Model, function(o, delta)
		if m_AwardModel then
			local petObj = m_AwardModel.m_Object
			if petObj then
				local vecRotate = Vector3(0,  -delta.x, 0)
				petObj.transform.localEulerAngles = petObj.transform.localEulerAngles + vecRotate
			end
		end
	end )
end

local function ShowModel()
	if m_AwardModel == nil and m_CurrentLotteryCfg then        
        if m_CurrentLotteryCfg.figureshow.figuretype == cfg.timelottery.FigureType.Pet then
            m_AwardModel = Pet:new(0, m_CurrentLotteryCfg.figureshow.petID, 0, true)
            m_AwardModel.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
            m_AwardModel:RegisterOnLoaded(OnModelLoaded)
            m_AwardModel:init()
        elseif m_CurrentLotteryCfg.figureshow.figuretype == cfg.timelottery.FigureType.Talisman then
            local talisman = ItemManager.CreateItemBaseById(m_CurrentLotteryCfg.figureshow.petID)
            m_AwardModel = TalismanModel:new()
            m_AwardModel.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
            m_AwardModel:RegisterOnLoaded(OnModelLoaded)
            m_AwardModel:init(talisman, PlayerRole:Instance(), -1)
        else
            print("[ERROR][dlglotteryfragment:ShowModel] invalid figure type:", m_CurrentLotteryCfg.figureshow.figuretype)
        end
	end
end

local function RefreshTurnCount()
    local leftfreecount = lotteryfragmentinfo.GetLeftFreeCount()    
    --printyellow("[dlglotteryfragment:RefreshTurnCount] leftfreecount:", leftfreecount)

    if true==fields.UIToggle_CheckBox_10.value then    
        if leftfreecount>=10 then
            fields.UILabel_Free.gameObject:SetActive(true)
            fields.UISprite_Money.gameObject:SetActive(false)
            --fields.UILabel_Free.text = string.format(LocalString.Lottery_Fragment_Free_Time, VipChargeManager.GetCurVipLevel())
            fields.UILabel_Free.text = LocalString.Lottery_Fragment_Free_Time
            fields.UILabel_Free_2.text = leftfreecount.."/"..lotteryfragmentinfo.GetVipFreeCount()
        else
            fields.UILabel_Free.gameObject:SetActive(false)
            fields.UISprite_Money.gameObject:SetActive(true)       
            local cost = lotteryfragmentinfo.GetOneDrawCost()*(10-leftfreecount)
            cost = math.max(cost, 0)
            fields.UILabel_Money.text = cost
        end
    else
        --test            
        --printyellow("[dlglotteryfragment:RefreshTurnCount] fields.UILabel_Free:", fields.UILabel_Free)
        --printyellow("[dlglotteryfragment:RefreshTurnCount] fields.UILabel_Free.gameObject:", fields.UILabel_Free.gameObject)

        if leftfreecount>0 then
            fields.UILabel_Free.gameObject:SetActive(true)
            fields.UISprite_Money.gameObject:SetActive(false)
            --fields.UILabel_Free.text = string.format(LocalString.Lottery_Fragment_Free_Time, VipChargeManager.GetCurVipLevel())
            fields.UILabel_Free.text = LocalString.Lottery_Fragment_Free_Time
            fields.UILabel_Free_2.text = leftfreecount.."/"..lotteryfragmentinfo.GetVipFreeCount()
        else
            fields.UILabel_Free.gameObject:SetActive(false)
            fields.UISprite_Money.gameObject:SetActive(true)       
            local cost = lotteryfragmentinfo.GetOneDrawCost()
            fields.UILabel_Money.text = cost
        end
    end
end

local function SetDrawEnable(value)
    if m_IsDrawEnabled ~=value then
        m_IsDrawEnabled =value
        if nil==m_IsDrawEnabled then
            m_IsDrawEnabled = true
        end
        fields.UIButton_Lottery.isEnabled = m_IsDrawEnabled
    end
end

local function ShowTitle()
    if m_CurrentLotteryCfg then
        fields.UILabel_ActiveTitle.text = m_CurrentLotteryCfg.figureshow.petName
        fields.UILabel_ActiveDate.text = m_CurrentLotteryCfg.desc    
    end
end

local function ShowScoreAward(index, listitem, awardCfg, curScore)
    if nil==listitem then
        print(string.format("[ERROR][dlglotteryfragment:ShowScoreAward] fields.UIList_Chest[%s] is nil!", index))
        return
    end
    if nil==awardCfg then
        print(string.format("[ERROR][dlglotteryfragment:ShowScoreAward] scorebonus nil at index[%s]!", index))
        return 
    end

    --score
    listitem.Data = awardCfg
    local UILabel_Score = listitem.Controls["UILabel_Score"]
    if UILabel_Score then
        UILabel_Score.text = string.format(LocalString.Lottery_Fragment_Fragment_Score, awardCfg.needscore)
    end

    --award
    local UILabel_Fragment = listitem.Controls["UILabel_Fragment"]
    if UILabel_Fragment then
        local awardItemList = BonusManager.GetMultiBonusItems(awardCfg.bonus)
        if awardItemList and #awardItemList>0 then   
            local item = awardItemList[1]
            UILabel_Fragment.text = "*"..(item:GetNumber() and item:GetNumber() or 1) 
        else
            print("[ERROR][dlglotteryfragment:ShowScoreAward] BonusManager.GetMultiBonusItems(awardCfg.bonus) null!")
            UILabel_Fragment.text = ""
        end
    end

    --other 
    local UISprite_Get = listitem.Controls["UISprite_Get"]
    if UISprite_Get then
        UISprite_Get.gameObject:SetActive(false)
    end

    --local UISprite_Monkey = listitem.Controls["UISprite_Monkey"]
    local UITexture_LootICON = listitem.Controls["UITexture_LootICON"]    
    local UIGroup_Tween = listitem.Controls["UIGroup_Tween_Play_01"]    
    local TweenPosition = listitem.gameObject:GetComponentInChildren("TweenPosition")
    if awardCfg.needscore<=curScore then
        --printyellow(string.format("[dlglotteryfragment:ShowScoreAward] awardCfg.needscore[%s]<=curScore[%s] at index[%s]!", awardCfg.needscore, curScore, index))
        local isawardclaimed = lotteryfragmentinfo.IsScoreAwardClaimed(awardCfg.needscore)
        if true==isawardclaimed then
            --UISprite_Monkey.spriteName = awardCfg.iconlocked--Pet_Icon_Invalid
            UITexture_LootICON:SetIconTexture(awardCfg.iconlocked)
            UIGroup_Tween.gameObject:SetActive(false)
            TweenPosition.enabled = false
        else
            --UISprite_Monkey.spriteName = awardCfg.iconunlock--Pet_Icon_Valid
            UITexture_LootICON:SetIconTexture(awardCfg.iconunlock)
            UIGroup_Tween.gameObject:SetActive(true)
            TweenPosition.enabled = true
        end
    else
        --printyellow(string.format("[dlglotteryfragment:ShowScoreAward] awardCfg.needscore[%s]>curScore[%s] at index[%s]!", awardCfg.needscore, curScore, index))
        --UISprite_Monkey.spriteName = awardCfg.iconunlock--Pet_Icon_Valid
        UITexture_LootICON:SetIconTexture(awardCfg.iconunlock)
        UIGroup_Tween.gameObject:SetActive(false)
        TweenPosition.enabled = false
    end
end

local function RefreshScore()
    --score
    local curScore = lotteryfragmentinfo.GetCurScore()
    fields.UILabel_Point.text = curScore
    local floorScoreProgress = 0
    --printyellow("[dlglotteryfragment:RefreshScore] curScore =", curScore)

    --award
    local scorebonus = lotteryfragmentinfo.GetAllScoreBonus()
    if scorebonus and #scorebonus>0 then
        for index=1,#scorebonus do
            local awardCfg = scorebonus[index]
            local awardListItem = fields.UIList_Chest:GetItemByIndex(index-1)
            ShowScoreAward(index, awardListItem, awardCfg, curScore)

            if curScore>=awardCfg.needscore then
                floorScoreProgress = ScoreProgress[index] and ScoreProgress[index] or floorScoreProgress
            end
        end
    else
        print("[ERROR][dlglotteryfragment:RefreshScore] lotteryfragmentinfo.GetAllScoreBonus() empty!")
    end
    
    --progress
    fields.UISlider_Score.value = floorScoreProgress
end

local function refresh()
    m_CurrentLotteryCfg = lotteryfragmentinfo.GetCurrentLottery()
    if m_CurrentLotteryCfg then
        --printyellow("[dlglotteryfragment:refresh] refresh dlglotteryfragment, m_CurrentLotteryCfg:")
        --printt(m_CurrentLotteryCfg)

        SetDrawEnable(true)

	    ShowModel()

        ShowTitle()

        ShowTurnTable()

        RefreshTurnCount()

        RefreshScore()    
    else
        print("[ERROR][dlglotteryfragment:refresh] lotteryfragmentinfo.GetCurrentLottery() nil, hide dlglotteryfragment!")
        UIManager.hidedialog("lottery.lotteryfragment.dlglotteryfragment")    
    end
end

local function show()
    --printyellow("[dlglotteryfragment:show] show dlglotteryfragment.")
end

local function destroy()
	if m_AwardModel then
		m_AwardModel:release()
		m_AwardModel = nil
	end
end

local function hide()
	if m_AwardModel then
		m_AwardModel:release()
		m_AwardModel = nil
	end
end

--[[
local function refresh()
    RefreshScore()
end
--]]

local function SetListitemTweenEnable(listitem, value)
    if listitem and nil~=value then   
        local UIGroup_Tween_Get = listitem and listitem.Controls["UIGroup_Tween_Get"] or nil
        if UIGroup_Tween_Get then
            if true==value then
                UIGroup_Tween_Get.gameObject:SetActive(true)
                local UIPlayTweens = UIGroup_Tween_Get.gameObject:GetComponent("UIPlayTweens")
                if UIPlayTweens then
                    --printyellow("[dlglotteryfragment:EndRotation] play UIPlayTweens at m_TargetIndex:", m_TargetIndex)
                    UIPlayTweens:Play(true)
                else
                    print("[ERROR][dlglotteryfragment:EndRotation] UIPlayTweens nil at m_TargetIndex:", m_TargetIndex)
                end         
            else
                UIGroup_Tween_Get.gameObject:SetActive(false)
            end
        else
            print("[ERROR][dlglotteryfragment:EndRotation] UIGroup_Tween_Get nil at m_TargetIndex:", m_TargetIndex)
        end   
    end
end

local function SetPointingListitem(listitem)
    --[[
    --reset old listitem tween
    if m_PointingListitem then
        local ScaleTween = m_PointingListitem.gameObject:GetComponent("TweenScale")
        if ScaleTween then
            --printyellow("[dlglotteryfragment:UpdateListitemTween] play TweenScale at listitem:", m_PointingListitem.gameObject.name)
            ScaleTween.enabled = false
        end
    end
    --]]

    --play current listitem tween
    m_PointingListitem = listitem
    if m_PointingListitem then
        local ScaleTween = m_PointingListitem.gameObject:GetComponent("TweenScale")
        if ScaleTween then
            --printyellow("[dlglotteryfragment:UpdateListitemTween] play TweenScale at listitem:", m_PointingListitem.gameObject.name)
            ScaleTween.enabled = false
            ScaleTween.duration = 0.5
            ScaleTween.enabled = true
            --ScaleTween:Play()
        else
            print("[ERROR][dlglotteryfragment:UpdateListitemTween] TweenScale nil at listitem:", m_PointingListitem.gameObject.name)
        end    
    end
end

local function EndRotation(needshowaward)
    --tween shine
    SetListitemTweenEnable(m_TargetListitem, true)

    --scaletween
    SetPointingListitem(m_TargetListitem)

    --tween rotation
    m_RotateTween.enabled = false   
    m_RotateState = RotateState.Idle 
    fields.UISprite_Arrows.gameObject.transform.rotation = Quaternion.Euler(0,0,m_TargetEngle)  
    --printyellow("[dlglotteryfragment:EndRotation] end rotating! m_TargetEngle=", m_TargetEngle)

    if false~=needshowaward then
        --show award
        --printyellow("[dlglotteryfragment:EndRotation] show awards and index:", m_TargetIndex)
        local awardCfg = lotteryfragmentinfo.GetLotteryBonusByIndex(m_TargetIndex)
        if awardCfg then
            local awardItemList = BonusManager.GetMultiBonusItems(awardCfg.bonus)
	        UIManager.show("common.dlgdialogbox_itemshow", {itemList = awardItemList})
        else
            print("[ERROR][dlglotteryfragment:EndRotation] lotteryfragmentinfo.GetLotteryBonusByIndex(m_TargetIndex) nil at index:", m_TargetIndex)
        end    
    end
end

local function UpdateListitemTween()
    local curAngle = m_RotateTween.gameObject.transform.eulerAngles.z
    curAngle = curAngle%360
    for index=1,fields.UIList_LuckTurn.Count do
        local listitem = fields.UIList_LuckTurn:GetItemByIndex(index-1)
        if m_PointingListitem~=listitem then
            local listitemangle = TurntableAngle[index]
            if listitemangle and math.abs(listitemangle-curAngle)<6 then
                SetPointingListitem(listitem)
            end
        end
    end
end

local function update()
    --model
	if m_AwardModel and m_AwardModel.m_Avatar then
		m_AwardModel.m_Avatar:Update()
	end

    --rotate
    if m_RotateState == RotateState.RotatingBefore or m_RotateState == RotateState.RotatingAfter then
        --UpdateListitemTween()
        
        if m_RotateState == RotateState.RotatingAfter then
            if m_RotateTween.duration < 1.6 then
                m_RotateTween.duration = m_RotateTween.duration + Time.deltaTime
            else
                local curAngle = m_RotateTween.gameObject.transform.eulerAngles.z
                curAngle = curAngle%360
                if math.abs(curAngle - m_TargetEngle) < 5 then
                    EndRotation(m_TargetEngle)
                end
            end         
        end   
    end

    --time
    if Time.time-m_DrawTime>LOTTERY_DRAW_INTERVAL then
        SetDrawEnable(true)    
    end
end

local function uishowtype()
	return UIShowType.Refresh
end

local function SetRotateTarget(index)
    --m_PointingListitem = nil
    local endAngle = TurntableAngle[index]
    if nil==endAngle then
        endAngle = m_TargetEngle and m_TargetEngle or 0
    end
    m_TargetEngle = endAngle
    m_TargetIndex = index
    SetListitemTweenEnable(m_TargetListitem, false)
    m_TargetListitem = fields.UIList_LuckTurn:GetItemByIndex(m_TargetIndex-1)
    --printyellow(string.format("[dlglotteryfragment:SetRotateTarget] start rotating! m_TargetEngle=[%d], m_TargetIndex=[%s]", m_TargetEngle, m_TargetIndex))

    if fields.UIToggle_CheckBox.value then
        EndRotation()
    else
        m_RotateState = RotateState.RotatingAfter
    end
end

local function OnLimitChange()
    --printyellow("[dlglotteryfragment:OnLimitChange] OnLimitChange!")
    if UIManager.isshow("lottery.lotteryfragment.dlglotteryfragment") then
        RefreshTurnCount()
    end
end

local function on_SLotteryRoll(msg)
    SetRotateTarget(msg.pos)
    RefreshScore()
    RefreshTurnCount()
end

local function Show10Award(awardindexlist)
    if awardindexlist and #awardindexlist>0 then
        --get bonus
        local awarditems = {}
        for _, index in ipairs(awardindexlist) do
            local awardCfg = lotteryfragmentinfo.GetLotteryBonusByIndex(index)
            if awardCfg then
                local bonuslist = BonusManager.GetMultiBonusItems(awardCfg.bonus)
                if bonuslist and #bonuslist>0 then
                    for _,bonusitem in ipairs(bonuslist) do
                        awarditems[#awarditems + 1] = bonusitem
                    end
                end
            end
        end
        
        --show bonus
        if awarditems and #awarditems>0 then
            UIManager.show("common.dlgdialogbox_itemshow", {itemList = awarditems})
        end
                
        --show arrow
        local index = awardindexlist[#awardindexlist]
        --m_PointingListitem = nil
        local endAngle = TurntableAngle[index]
        if nil==endAngle then
            endAngle = m_TargetEngle and m_TargetEngle or 0
        end
        m_TargetEngle = endAngle
        m_TargetIndex = index
        SetListitemTweenEnable(m_TargetListitem, false)
        m_TargetListitem = fields.UIList_LuckTurn:GetItemByIndex(m_TargetIndex-1)
        --printyellow(string.format("[dlglotteryfragment:SetRotateTarget] start rotating! m_TargetEngle=[%d], m_TargetIndex=[%s]", m_TargetEngle, m_TargetIndex))
        EndRotation(false)
    end
end

local function on_SLotteryRoll10(msg)
    --printyellow("[dlglotteryfragment:on_SLotteryRoll10] receive:", msg)
    Show10Award(msg.pos)
    RefreshScore()
    RefreshTurnCount()
end

local function on_SSyncScoreBonus(msg)
    RefreshScore()
end

local function on_SCurrencyChange(msg)
    --printyellow("[dlglotteryfragment:on_SCurrencyChange] receive:", msg)
    RefreshScore()
end

local function StartRotate()
    --printyellow("[dlglotteryfragment:StartRotate] Start Rotate.")
    m_RotateTween.duration = 0.3
    m_RotateTween.enabled = true
    m_RotateState = RotateState.RotatingBefore
end

local function StopRotate()
    --printyellow("[dlglotteryfragment:StartRotate] Stop Rotate.")
    m_RotateTween.enabled = false
    m_RotateState = RotateState.Idle
end

local function CanDrawLottery()
    if false==lotteryfragmentmgr.IsLotteryOpen() then
        return false
    end

    if lotteryfragmentinfo.GetLeftFreeCount()<=0 then
        local roleyuanbao = PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.YuanBao]
        if roleyuanbao<lotteryfragmentinfo.GetOneDrawCost() then
            return false
        end
    end

    return true
end

local function OnUIButton_Lottery()
    --printyellow("[dlglotteryfragment:OnUIButton_Lottery] UIButton_Lottery clicked!")
    if m_RotateState == RotateState.RotatingBefore or m_RotateState == RotateState.RotatingAfter then
        --printyellow("[dlglotteryfragment:OnUIButton_Lottery] abort! m_RotateState == RotateState.RotatingBefore or m_RotateState == RotateState.RotatingAfter")
        return
    end

    StopRotate()
    if true==fields.UIToggle_CheckBox_10.value then
        lotteryfragmentmgr.send_CLotteryRoll10()
    else
        --time
        m_DrawTime = Time.time
        SetDrawEnable(false)

        --send
        lotteryfragmentmgr.send_CLotteryRoll() 
    
        --rotate
        if false==fields.UIToggle_CheckBox.value and CanDrawLottery() then
            StartRotate()
        end

        --test
        --[[
        local seed = tonumber(tostring(os.time()):reverse():sub(1, 6))
        math.randomseed(seed)
        local index = math.random(1, 12)
        SetRotateTarget(index)
        --]]
    end
end

local function OnScoreAwardClicked(listitem)
    --printyellow(string.format("[dlglotteryfragment:OnScoreAwardClicked] [%s] clicked!", listitem.gameObject.name))
    local awardCfg = listitem and listitem.Data or nil
    if awardCfg then
        if awardCfg.needscore>lotteryfragmentinfo.GetCurScore() then
            UIManager.ShowSystemFlyText(LocalString.Lottery_Fragment_Score_Not_Enough)
            --UIManager.ShowSystemFlyText(LocalString.Lottery_Fragment_Score_Not_Enough)
            return 
        end

        if true==lotteryfragmentinfo.IsScoreAwardClaimed(awardCfg.needscore) then   
            UIManager.ShowSystemFlyText(LocalString.Lottery_Fragment_Score_Claimed)
            --UIManager.ShowSystemFlyText(LocalString.Lottery_Fragment_Score_Claimed)
            return   
        end

        lotteryfragmentmgr.send_CLotteryScoreExchange(awardCfg.needscore)  
    else
        print("[ERROR][dlglotteryfragment:OnScoreAwardClicked] listitem.Data nil!")
    end
end

local function OnTurntableItemClicked(listitem)
    if listitem and listitem.Data then
        --printyellow(string.format("[dlglotteryfragment:OnTurntableItemClicked] [%s] clicked!", listitem.gameObject.name))
        local params={item=listitem.Data, buttons={{display=false,text="",callFunc=nil}, {display=false,text="",callFunc=nil}}}
        ItemIntroduct.DisplayBriefItem(params) 
    end
end

local function OnToggleDraw10Change()
    RefreshTurnCount()
end

local function init(params)
    name, gameObject, fields = unpack(params)
    
    --rotate tween
    m_TargetListitem = nil
    m_TargetEngle = 0
    m_TargetIndex = 0
    m_RotateState = RotateState.Idle

    --click interval
    m_DrawTime = 0
    SetDrawEnable(true)
    
    --cfg
    m_TotalScore = lotteryfragmentinfo.GetTotalScore()
    --printyellow("[dlglotteryfragment:init] m_TotalScore =", m_TotalScore)

    --ui
    EventHelper.SetClick(fields.UIToggle_CheckBox_10, OnToggleDraw10Change)
    EventHelper.SetListClick(fields.UIList_LuckTurn, OnTurntableItemClicked)
    EventHelper.SetListClick(fields.UIList_Chest, OnScoreAwardClicked)
    EventHelper.SetClick(fields.UIButton_Lottery, OnUIButton_Lottery)
    m_RotateTween = fields.UISprite_Arrows.gameObject:GetComponent("TweenRotation")
    if m_RotateTween then
        m_RotateTween.enabled = false
    else  
        print("[ERROR][dlglotteryfragment:init] fields.UISprite_Arrows.gameObject:GetComponent(TweenRotation) null!")  
    end
	--fields.UITexture_AD:SetIconTexture("ICON_FirstOfCharge_BG01")
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  uishowtype = uishowtype,
  on_SLotteryRoll = on_SLotteryRoll,
  on_SSyncScoreBonus = on_SSyncScoreBonus,
  on_SLotteryRoll10 = on_SLotteryRoll10,
  OnLimitChange = OnLimitChange,
  on_SCurrencyChange = on_SCurrencyChange,
  RefreshTurnCount = RefreshTurnCount,
}
