local EventHelper       = UIEventListenerHelper
local UIManager         = require("uimanager")
local ItemEnum          = require("item.itemenum")
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")
local BonusManager      = require("item.bonusmanager")
local ItemManager       = require("item.itemmanager")
local ConfigManager     = require("cfg.configmanager")
local BagManager        = require("character.bagmanager")
local ColorUtil         = require("common.colorutil")
local SettingManager    = require "character.settingmanager"

local PageTalismanWuxing = {
    SkipAnim = false,
    isRotating = false,
    endAngle = 0,
}
local clickTime = 0
local consumeNum = 0


function PageTalismanWuxing:ChangeRotatingState(state)
    self.isRotating = state
    self.fields.UIButton_TurnLuck.isEnabled = (not state)
    self.fields.UIButton_TurnLuckSp.isEnabled = (not state)
end


function PageTalismanWuxing:StartRotate(endAngle, isSkip)
    if isSkip then

        self.fields.UISprite_Arrows.gameObject.transform.rotation = Quaternion.Euler(0,0,endAngle)
        self:SetFortuneText(true)
        self:SetFortuneTexture()
    else

        self:ChangeRotatingState(true)
        self.TweenRotation = self.fields.UISprite_Arrows.gameObject:GetComponent("TweenRotation")
        self.TweenRotation.duration = 0.5
        self.endAngle = endAngle

        --local currentWuxing = talisman:GetFiveElementsPropertyType()

        --TweenRotation.gameObject.transform.rotation = Quaternion.Euler(0,0,FiveElementsAngle[talisman:GetFiveElementsPropertyType()])
        self.TweenRotation.enabled = true

    end
end

local Forturntable = {
    [1] = {Type = cfg.talisman.LuckType.LUCKLVL_1, Angle = -18},
    [2] = {Type = cfg.talisman.LuckType.LUCKLVL_2, Angle = -48},
    [3] = {Type = cfg.talisman.LuckType.LUCKLVL_3, Angle = -78},
    [4] = {Type = cfg.talisman.LuckType.LUCKLVL_4, Angle = -108},
    [5] = {Type = cfg.talisman.LuckType.LUCKLVL_5, Angle = -138},
    [6] = {Type = cfg.talisman.LuckType.LUCKLVL_1, Angle = -168},
    [7] = {Type = cfg.talisman.LuckType.LUCKLVL_2, Angle = -198},
    [8] = {Type = cfg.talisman.LuckType.LUCKLVL_3, Angle = -228},
    [9] = {Type = cfg.talisman.LuckType.LUCKLVL_4, Angle = -258},
    [10] = {Type = cfg.talisman.LuckType.LUCKLVL_5, Angle = -288},
    [11] = {Type = cfg.talisman.LuckType.LUCKLVL_2, Angle = -318},
    [12] = {Type = cfg.talisman.LuckType.LUCKLVL_3, Angle = -348},
}

function PageTalismanWuxing:RefreshTransCost()
    if  SettingManager.GetMagicWeapon() then 
        self.SkipAnim = SettingManager.GetMagicWeapon()["skipAnim"]
    else
        self.SkipAnim = false
    end
    if self.SkipAnim == nil or self.SkipAnim == " " then 
        self.SkipAnim = false
    end

    self.fields.UIToggle_CheckBox.value = self.SkipAnim
    local allFreeTime = TalismanManager.GetFreeTransLuckyTimes()
    local curLuckyTimes = TalismanManager.GetChangeLuckTimes()
    local curMoney = TalismanManager.GetCurrency("YuanBao")
    if allFreeTime > curLuckyTimes then
        self.fields.UISprite_FreeTurn.gameObject:SetActive(true)
        self.fields.UISprite_IngotCost.gameObject:SetActive(false)
        self.fields.UILabel_ZhuanynTimes.text = tostring(curLuckyTimes .. "/" .. allFreeTime)
        self.fields.UILabel_ZhuanyunCost.text = tostring(TalismanManager.GetChangeLuckCost())
    else

        self.fields.UISprite_FreeTurn.gameObject:SetActive(false)
        self.fields.UISprite_IngotCost.gameObject:SetActive(true)
        self.fields.UILabel_ZhuanynTimes.text = tostring(allFreeTime .. "/" .. allFreeTime)
        self.fields.UILabel_ZhuanyunCost.text = tostring(TalismanManager.GetChangeLuckCost())
    end
end


function PageTalismanWuxing:ChangeEnd(params)
    self.endAngle = self:GetEndAngle()
    self:RefreshTransCost()
    self:StartRotate(self.endAngle, self.SkipAnim)
end

function PageTalismanWuxing:GetEndAngle(lastEnd)
    if lastEnd ~= nil and lastEnd ~= 0 then
        return lastEnd
    end


    local luckType = TalismanManager.TalismanSystemConfig.m_LuckyType

    --printyellow("luckType",luckType)
    local angle = math.floor(math.random(12))
    local k
    for i = angle,angle + 11 do
        if i > 12 then
            k = i -12
        else
            k = i
        end
        if Forturntable[k].Type == luckType then
            --printyellow("A",luckType,k,Forturntable[k].Angle)
            self.endAngle = Forturntable[k].Angle
            return Forturntable[k].Angle
        end
    end
    return 0
end

function PageTalismanWuxing:SetFortuneTexture()
    local curAngle = self.TweenRotation.gameObject.transform.eulerAngles.z
    if curAngle > 0 then
        curAngle = curAngle - 360
    end
    for i, k in pairs(Forturntable) do
        local listItem = self.fields.UIList_LuckTurn:GetItemByIndex(i-1)
        local uiTexture = listItem.Controls["UITexture_Fortune"]
        if uiTexture then
            if math.abs(curAngle - k.Angle) < 15 then
                if uiTexture.gameObject.activeSelf == false then
                    uiTexture.gameObject:SetActive(true)
                end
            else
                if uiTexture.gameObject.activeSelf == true then
                    uiTexture.gameObject:SetActive(false)
                end
            end
        end
    end
end


function PageTalismanWuxing:update()
    if self.isRotating == false then
        return
    end


    self:SetFortuneTexture()
    if self.TweenRotation.duration < 2 then
        self.TweenRotation.duration = self.TweenRotation.duration + 1 * Time.deltaTime
    else
        local curAngle = self.TweenRotation.gameObject.transform.eulerAngles.z
        if curAngle > 0 then
            curAngle = curAngle - 360
        end
        if math.abs(curAngle - self.endAngle) < 5 then
            self.TweenRotation.enabled = false
            self:ChangeRotatingState(false)
            self:SetFortuneText(true)
        end
    end
end


function PageTalismanWuxing:SetForturntable()

    for i= 1,12 do
        local uiItem = self.fields.UIList_LuckTurn:GetItemByIndex(i-1)
        local label = uiItem.gameObject:GetComponent("UILabel")
        local luckType = Forturntable[i].Type
        local luckCfg = ConfigManager.getConfigData("talismanfeed",luckType)
        label.text = luckCfg.luckname
    end
end

function PageTalismanWuxing:ChangeFortune(talisman)
    self:SetForturntable()

    self:RefreshTransCost()

    local curMoney = TalismanManager.GetCurrency("YuanBao")

    EventHelper.SetClick(self.fields.UIButton_TurnLuck, function()
        local luckType = TalismanManager.TalismanSystemConfig.m_LuckyType
        if luckType == 1 then 
            UIManager.ShowSingleAlertDlg{content=LocalString.JadeEnhance_NeedMaxLevel}
        else
            TalismanManager.ChangeLuckType(false)
        end
    end)
    self.fields.UILabel_ZhuanyunSpCost.text = TalismanManager.GetChangeBestLuckCost()

    EventHelper.SetClick(self.fields.UIButton_TurnLuckSp, function()
        local luckType = TalismanManager.TalismanSystemConfig.m_LuckyType
        if luckType == 1 then 
            UIManager.ShowSingleAlertDlg{content=LocalString.JadeEnhance_NeedMaxLevel}
        else
            TalismanManager.ChangeLuckType(true)
        end
    end)
end

function PageTalismanWuxing:Wuxing(talisman)
    --self.fields.UILabel_WuxingType.text = TalismanUITools.GetFiveElementName(talisman:GetFiveElementsPropertyType(),false)
    self.fields.UILabel_CurrentWuxingValue.text = math.floor( talisman:GetFiveElementsPropertyValue() )
    self.fields.UILabel_MaxWuxingValue.text = math.floor( talisman:GetFiveElementsMaxValue() )

    if self.fields.UILabel_WuxingPageLevel and self.fields.UILabel_WuxingPageStar then
        self.fields.UILabel_WuxingPageLevel.text = TalismanUITools.GetLevelText(talisman:GetLevel())
        self.fields.UILabel_WuxingPageStar.text = TalismanUITools.GetStarOrderText(talisman)
    end

    --self.fields.UITexture_WuXingPic:SetIconTexture(TalismanUITools.GetFiveElementIconName(talisman:GetFiveElementsPropertyType()))

 --   if PlayerRole:Instance().m_Level < cfg.talisman.TalismanFeed.WUXING_OPEN_LEVEL then
  --      self.fields.UIButton_WuxingChange.isEnabled = false
 --   else
 --       self.fields.UIButton_WuxingChange.isEnabled = true
  --      EventHelper.SetClick(self.fields.UIButton_WuxingChange, function()
  --          UIManager.show("playerrole.talisman.dlgtalisman_changewuxing",{talisman = talisman})
  --      end)
 --   end
end

function PageTalismanWuxing:SetFortuneText(playerEffect)
    local luckType = TalismanManager.TalismanSystemConfig.m_LuckyType
    self.fields.UILabel_Luck.text = TalismanUITools.GetLuckName(luckType)
    self.fields.UISprite_Luck.spriteName = TalismanUITools.GetLuckIconName(luckType)
    self.fields.UILabel_Odds.text = TalismanUITools.GetLuckDescribe(luckType)
    if self.fields.UILabel_LeastWashTimes then
        self.fields.UILabel_LeastWashTimes.text = TalismanManager.GetLeastWashCount()
    end

    if playerEffect then
        TalismanUITools.PlayEffect(self.fields.UIGroup_Luck.gameObject)
    end
    if playerEffect and luckType and luckType == cfg.talisman.LuckType.LUCKLVL_1 then
        UIManager.showorrefresh( "dlgtweenset", {
                                tweenfield  = "UIPlayTweens_Talisman_7",
                                callback    = function()

                                end})
    end
end


function PageTalismanWuxing:Xilian(talisman)
    local curJinBi = TalismanManager.GetCurrency()
    local curYuanBao = TalismanManager.GetCurrency("YuanBao")
    self:SetFortuneText()

    local items = BagManager.GetItemById(cfg.talisman.TalismanFeed.REQUIRE_ITEM)
    local totalNum = 0
    if #items > 0 then
        for i, item in pairs(items) do
            totalNum = totalNum + item:GetNumber()
        end
    else
        totalNum = 0
    end
    consumeNum = totalNum

    local uiItem = self.fields.UIList_WuxingConsume:GetItemByIndex(0)

    local item = ItemManager.CreateItemBaseById(cfg.talisman.TalismanFeed.REQUIRE_ITEM,{},1)
    uiItem:SetText("UILabel_WashName", item:GetName())

    local amountText
    local amountStr = string.format("%s/%s", totalNum, cfg.talisman.TalismanFeed.REQUIRE_ITEM_NUM)
    if cfg.talisman.TalismanFeed.REQUIRE_ITEM_NUM > totalNum then
        amountText = ColorUtil.GetColorStr(ColorUtil.ColorType.Red_Item, amountStr)
    else
        amountText = ColorUtil.GetColorStr(ColorUtil.ColorType.Green, amountStr)
    end

    uiItem:SetText("UILabel_WashAmount", amountText)

  --  uiItem:SetText("UILabel_WashMoney",tostring(cfg.talisman.TalismanFeed.WASH_COST))

    BonusManager.SetRewardItem(uiItem,item,{})
   -- local iconTexture = uiItem.Controls["UITexture_Icon"]
  --
   -- iconTexture  BonusManager
   -- local result = TalismanUITools.SetMoneyCostText(self.fields.UILabel_WashMoney,cfg.talisman.TalismanFeed.WASH_COST)

    --self.fields.UILabel_AwakeMoney.text = TalismanManager.TalismanSystemConfig.WashCostJinBi

  --  self.fields.UILabel_CostAmount01.text = TalismanManager.TalismanSystemConfig.WashCostJinBi
  --  self.fields.UILabel_CostAmount02.text = TalismanManager.TalismanSystemConfig.WashCostYuanBao
    EventHelper.SetClick(self.fields.UIButton_XiLian, function()
     --   if TalismanManager.TalismanSystemConfig.WashCostJinBi < curJinBi and TalismanManager.TalismanSystemConfig.WashCostYuanBao < curYuanBao then
            TalismanManager.WuxingWash(talisman)
    end)
    EventHelper.SetClick(self.fields.UIButton_XiLianAll, function()
            if  clickTime == 0 or os.time() > clickTime + 1  then
                -- UIManager.ShowSystemFlyText(clickTime)
                local num = 0
                if TalismanManager.GetLeastWashCount() > consumeNum then
                    num = consumeNum
                else
                    num = TalismanManager.GetLeastWashCount()
                end
                TalismanManager.WuxingWashAll(talisman,num)
                clickTime = os.time()
            end
    end)

    local addButton = uiItem.Controls["UIButton_WuxingAdd"]
    EventHelper.SetClick(addButton, function()
        ItemManager.GetSource(item:GetConfigId(),self.name)
    end)



end

function PageTalismanWuxing:refresh(talisman)
    self:ChangeFortune(talisman)
    self:Wuxing(talisman)
    self:Xilian(talisman)
end



function PageTalismanWuxing:show()
    self.fields.UIGroup_WuXing.gameObject:SetActive(true)
    self.fields.UISprite_IngotCost.gameObject:SetActive(false)

    self:ChangeRotatingState(false)
    self.TweenRotation = self.fields.UISprite_Arrows.gameObject:GetComponent("TweenRotation")
    self.TweenRotation.duration = 0.5
    self.TweenRotation.enabled = false

    self.fields.UISprite_Arrows.gameObject.transform.rotation = Quaternion.Euler(0,0,self:GetEndAngle(self.endAngle))
    self:SetFortuneTexture()
end

function PageTalismanWuxing:hide()
    self.fields.UIGroup_WuXing.gameObject:SetActive(false)
    TalismanUITools.StopEffect(self.fields.UIGroup_Wash.gameObject)
    TalismanUITools.StopEffect(self.fields.UIGroup_Luck.gameObject)
end

function PageTalismanWuxing:OnMsgWash(params)
    TalismanUITools.PlayEffect(self.fields.UIGroup_Wash.gameObject)

end


function PageTalismanWuxing:init(name, gameObject, fields)
    self.fields = fields
    self.name = name

    EventHelper.SetClick(self.fields.UIToggle_CheckBox, function()
        self.SkipAnim = self.fields.UIToggle_CheckBox.value
        SettingManager.SendMagicWeapon(self.SkipAnim)
    end)
end

function PageTalismanWuxing:ShowRedDot(talisman)
    if talisman == nil then
        return false
    end
    local items = BagManager.GetItemById(cfg.talisman.TalismanFeed.REQUIRE_ITEM)
    local totalNum = 0
    if #items > 0 then
        for i, item in pairs(items) do
            totalNum = totalNum + item:GetNumber()
        end
    else
        totalNum = 0
    end
    if totalNum >= cfg.talisman.TalismanFeed.REQUIRE_ITEM_NUM then
        local curValue = math.floor( talisman:GetFiveElementsPropertyValue() )
        local maxValue = math.floor( talisman:GetFiveElementsMaxValue() )
        if curValue < maxValue then
            return true
        end
    end
    return false
end

return PageTalismanWuxing
