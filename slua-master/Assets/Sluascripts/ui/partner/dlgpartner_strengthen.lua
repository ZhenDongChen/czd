
local unpack                    = unpack
local print                     = print
local math                      = math
local EventHelper               = UIEventListenerHelper
local uimanager                 = require("uimanager")
local network                   = require("network")
local ShopManager               = require("shopmanager")
local PlayerRole                = require"character.playerrole"
local ConfigManager             = require"cfg.configmanager"
local ItemPet                   = require"item.pet"
local BagManager                = require"character.bagmanager"
local PetManager                = require"character.pet.petmanager"
local CommonSkill               = require"ui.common.dlgdialogbox_skill"
local CfgCurrency               = ConfigManager.getConfig("currency")
local CfgItem                   = ConfigManager.getConfig("itembasic")
local mathutils                 = require"common.mathutils"
local CheckCmd                  = require"common.checkcmd"
local dlgList                   = require"ui.common.dlgdialogbox_list"
local ItemManager               = require"item.itemmanager"
local gameObject
local name
local fields

local CfgAwake
local CfgStageStar
local StatusText
local pet
local currentRatioButton
local groups

local uiList_Attributes
local uiList_Stars
local uiList_StageStarConsume
local effectsToShow
local effectAwake = 0x01
local effectStage = 0x02
local effectStar  = 0x04
local redDotFuncs = {}
-- refreshes region

local function ShowAwakeEffect()
    uimanager.PlayUIParticleSystem(fields.UIGroup_UpgradeAwake.gameObject)
end

local function ShowStarEffect()
    uimanager.PlayUIParticleSystem(fields.UIGroup_UpgradeStar.gameObject)
end

local function ShowStageEffect()
    uimanager.PlayUIParticleSystem(fields.UIGroup_UpgradeStage.gameObject)
end

local function RefreshPartnerInformation()
    local petAttribute = PetManager.GetAttributes(pet)
    for i,v in ipairs(PetManager.InfoAttr) do
        local CurrentItem = uiList_Attributes[i]
        if v.idx == cfg.fight.AttrId.ATTACK_VALUE then
            local val1 = petAttribute[cfg.fight.AttrId.ATTACK_VALUE_MIN] or 0
            local val2 = petAttribute[cfg.fight.AttrId.ATTACK_VALUE_MAX] or 0
            local text1 = mathutils.GetAttr(val1,StatusText[v.idx].displaytype)
            local text2 = mathutils.GetAttr(val2,StatusText[v.idx].displaytype)
            CurrentItem.labelValue.text =tostring(text1) .. '-' .. tostring(text2)
        else
            local val = petAttribute[v.idx] or 0
            CurrentItem.labelValue.text = mathutils.GetAttr(val,StatusText[v.idx].displaytype)
        end
        -- CurrentItem.spriteIcon.spriteName = StatusText[v.idx].spritename
        -- CurrentItem.labelValue.text = mathutils.GetAttr(val,StatusText[v.idx].displaytype)
    end

    for i=1,5 do
        local item = fields.UIList_ScrollAttr:GetItemByIndex(i-1)
        local slider = item.Controls["UISlider_SlideBackground"]
        slider.value = pet.ConfigData.featurelist[i]/100
        local label = item.Controls["UILabel_Number"]
        label.text = tostring(pet.ConfigData.featurelist[i])
    end

    fields.UILabel_Discription.text= pet.ConfigData.introduction
    fields.UILabel_Feature.text = pet.ConfigData.feature

    local karmas = PetManager.GetKarmas(pet)
    for i=1,6 do
        local karma = karmas[i]
        local item = fields.UIList_PartnerLuckychance:GetItemByIndex(i-1)
        if karma then
            item.gameObject:SetActive(true)
            local text = karma.karma.karmaname
            if karma.karmalevel>0 then
                text = LocalString.PartnerText.ActiveColor .. text .. LocalString.PartnerText.ColorSuffix
            end
            labelKarmaName = item.Controls["UILabel_PartnerLuckychance"]
            labelKarmaName.text = text
        else
            item.gameObject:SetActive(false)
        end
    end
end

local function RefreshPartnerSkill()
	print("RefreshPartnerSkill")
    local skillInfo = pet.PetCharacterSkillInfo:GetAllSkills()
    local skillcnt = 0
    for i,v in ipairs(skillInfo) do
        if PetManager.IsShowedSkill(pet.ConfigId,v.skillid) then
            skillcnt = skillcnt + 1
        end
    end
    fields.UIList_PartnerSkill:ResetListCount(skillcnt)
    local idx = 0
    for i,v in ipairs(skillInfo) do
        if PetManager.IsShowedSkill(pet.ConfigId,v.skillid) then
            local skillInformation = ConfigManager.getConfigData("skilldmg",v.skillid)
            if not skillInformation then
                skillInformation = ConfigManager.getConfigData("passiveskill",v.skillid)
            end
            local skillCost = ConfigManager.getConfigData("skilllvlupcost",v.skillid)
            local item = fields.UIList_PartnerSkill:GetItemByIndex(idx)
            idx = idx + 1
            local labelName = item.Controls["UILabel_SkillName"]
            local labelLevel = item.Controls["UILabel_LevelCount"]
            local labelAmount1 = item.Controls["UILabel_Amount01"]
            local labelButton = item.Controls["UILabel_Button"]
            local buttonUpdate = item.Controls["UIButton_Update"]
            local labelDescription = item.Controls["UILabel_SkillDiscription"]
            local spriteRedDot = item.Controls["UISprite_SkillWarning"]
            local goldIcon = item.Controls["UISprite_Icon01"]
          
            labelDescription.text = skillInformation.introduction
            labelName.text = skillInformation.name
            labelLevel.text = tostring(v.level)
            if pet.NewLevelSkill and pet.NewLevelSkill == v.skillid then
                local levelEffect = item.Controls["ParticleSystem_UpgradeSkill"]
                -- uimanager.PlayUIParticleSystem(levelEffect.gameObject)
                pet.NewLevelSkill = nil
            end
			print("state")
            local state

            if v.actived then
                local requiredAwakeLevel = 0
                if v:GetSkill():IsMaxLevel(v.level) then
                    -- buttonUpdate.enabled = false
                    labelButton.text = LocalString.PartnerText.SkillMaxLevel
                    labelAmount1.gameObject:SetActive(false)
                    goldIcon.gameObject:SetActive(false)
                    state = "maxlevel"
                elseif v:GetSkill():CanUpgrade(v.level) then
                    -- buttonUpdate.enabled = true
                    local lvlupdata = skillCost.skilllvlupdata[v.level+1]
                    local requiredata1 = ItemManager.GetCurrencyData(lvlupdata.requirecurrency1)
                    -- local requiredata2 = ItemManager.GetCurrencyData(lvlupdata.requirecurrency2)
                    labelAmount1.text = tostring(requiredata1.Number)
                    labelAmount1.gameObject:SetActive(true)
                    goldIcon.gameObject:SetActive(true)
                    -- labelAmount2.text = tostring(requiredata2.Number)
                    labelButton.text = LocalString.PartnerText.SkillUpgradeLevel
                    if v:GetSkill():RoleLevelAchieve(pet.PetLevel,v.level+1) then
                        if skillCost.requireawakelvl>pet.PetAwakeLevel then
                            requiredAwakeLevel = skillCost.requireawakelvl

                            state = 'shortawake'
                        else

                            state = 'canupgrade'
                        end
                    else

                        state = 'shortlevelupgrade'
                    end

                end
                --buttonUpdate.isEnabled = (state == "canupgrade")
                --过审核
                local updateButtonSprite =  buttonUpdate.gameObject:GetComponent("UISprite")

                if state == "canupgrade" then
                    --updateButtonSprite.color = Color(1, 1, 1, 1)
                    buttonUpdate.defaultColor = Color(1, 1, 1, 1)
                    buttonUpdate.hover = Color(225/255, 200/255, 150/ 255, 1)
                    buttonUpdate.pressed = Color(183/255, 163/255, 123/255, 1)
                else
                    --updateButtonSprite.color = Color(150/255, 150/255, 150/255, 1)
                    buttonUpdate.defaultColor = Color(150/255, 150/255, 150/255, 1)
                    buttonUpdate.hover = Color(150/255, 150/255, 150/255, 1)
                    buttonUpdate.pressed = Color(150/255, 150/255, 150/255, 1)
                end

                local b = PetManager.CanUpgradeASkill(v,pet)
                spriteRedDot.gameObject:SetActive(b)
                EventHelper.SetClick(buttonUpdate,function()
					local b = PetManager.CanUpgradeASkill(v,pet)
					spriteRedDot.gameObject:SetActive(b)
                    if state == 'canupgrade' then
                        if b then
                            PetManager.RequestUpgradeSkill(pet.ConfigId,v.skillid)
                        else
                            local lvlupdata = skillCost.skilllvlupdata[v.level+1]
                            local val1,info1 = CheckCmd.CheckData{data=lvlupdata.requirecurrency1,num=1}
                            if not val1 then
                                ItemManager.GetSource(cfg.currency.CurrencyType.XuNiBi,"partner.dlgpartner")
                                --TODO造化值的
                            else
                                local val2,info2 = CheckCmd.CheckData{data=lvlupdata.requirecurrency2,num=1}
                                ItemManager.GetSource(cfg.currency.CurrencyType.ZaoHua,"partner.dlgpartner")
                            end
                        end

                    elseif state == 'canevolve' then
                        PetManager.RequestEvolveSkill(pet.ConfigId,v.skillid)
                    else
                        --过审核
                        local needLevel = skillCost.skilllvlupdata[v.level+1].requirelvl
                        uimanager.ShowSystemFlyText(string.format( LocalString.NeedPetLevel,needLevel))
                    end
                end)
            else
                labelAmount1.text = ""
                -- labelAmount2.text = ""
                labelButton.text = LocalString.PartnerText.UnActive
                buttonUpdate.isEnabled = false
                spriteRedDot.gameObject:SetActive(false)
                EventHelper.SetClick(buttonUpdate,function()
                    uimanager.show("dlgalert_reminder_singlebutton",{content=string.format(LocalString.PartnerText.AwakeSkil,skillCost.requireawakelvl+1)})
                end)
            end
        end
    end
end



local function RefreshStageStar()


    local b = PetManager.CanUpgradeStageStar(pet)
    fields.UISprite_StageStarWarning.gameObject:SetActive(b)
    local currStar = PetManager.GetStar(pet.PetStageStar)
    for i=1,9 do
        uiList_Stars[i].gameObject:SetActive(currStar>=i)
    end
    local currStage = PetManager.GetStage(pet.PetStageStar)
    fields.UIProgressBar_StageStarExp.value = currStage/10
    local stagestarText = PetManager.GetStageStarText(pet.PetStageStar)
    fields.UILabel_StarLevel.text = LocalString.PartnerText.Current .. stagestarText
    local nextLevel = ""
    if CfgStageStar[pet.PetStageStar] then
        nextLevel = tostring(CfgStageStar[pet.PetStageStar].requirepetlvl)
    else
        nextLevel = "90"
    end
    fields.UILabel_Limit.text = string.format(LocalString.PartnerText.StageStarLevelLimit,nextLevel)
    --上限判断
    local upStarStageLevelData = CfgStageStar[pet.PetStageStar+1]
    if upStarStageLevelData == nil then
        fields.UIList_StageStarProps.gameObject:SetActive(false)
        fields.UISprite_MoneyBG.gameObject:SetActive(false)
        fields.UIButton_StageStarIntensify.gameObject:SetActive(false)
        fields.UILabel_Limit.text = LocalString.PartnerText.StageStarMax

    else
        fields.UIList_StageStarProps.gameObject:SetActive(true)
        fields.UISprite_MoneyBG.gameObject:SetActive(true)
        fields.UIButton_StageStarIntensify.gameObject:SetActive(true)
    end

    local currInfo = CfgStageStar[pet.PetStageStar]

    for i=1,3 do
        if currInfo.requireitem[i] then
            local itemid = currInfo.requireitem[i].itemid
            local amount = currInfo.requireitem[i].amount
            local ownedAmount = BagManager.GetItemNumById(itemid)
            uiList_StageStarConsume[i].item.gameObject:SetActive(true)
            -- uiList_StageStarConsume[i].spriteAdd.gameObject:SetActive(false)
            uiList_StageStarConsume[i].labelName.text = CfgItem[itemid].name
            uiList_StageStarConsume[i].textureIcon:SetIconTexture(CfgItem[itemid].icon)
			uiList_StageStarConsume[i].spritequality.spriteName = colorutil.GetQualitySprite(CfgItem[itemid].quality)
            uiList_StageStarConsume[i].labelAmount.gameObject:SetActive(true)
            local cl = ownedAmount>=amount and LocalString.PartnerText.SatisfiedColor or LocalString.PartnerText.NotEnoughColor
            uiList_StageStarConsume[i].labelAmount.text = cl..tostring(ownedAmount)..'/'..tostring(amount).."[-]"
        else
            uiList_StageStarConsume[i].item.gameObject:SetActive(false)
        end
    end
    fields.UILabel_StageStarAmount.text = ItemManager.GetCurrencyData(currInfo.requirexunibi).Number
    if bit.band(effectsToShow,effectStage) > 0 then
        ShowStageEffect()
    end
    if bit.band(effectsToShow,effectStar) > 0 then
        ShowStarEffect()
    end
end

local function RefreshAwake()
	print("PPPPPP")
    local b = PetManager.CanUpgradeAwake(pet)
    fields.UISprite_AwakeWarning.gameObject:SetActive(b)
    fields.UIButton_AwakeningAwakening.enabled = b
    fields.UIList_AwakeningProps:Clear()
    for i=1,#CfgAwake[pet.ConfigId].awakelvlup_awakeid do
        local awakeInfo = CfgAwake[pet.ConfigId].awakelvlup_awakeid[i]
        local text = LocalString.PartnerText.Awaken .. tostring(i) .. ' '
        text = text .. CfgAwake[pet.ConfigId].awakelvlup_awakeid[i].displaytext
        local item = fields.UIList_AwakeningProps:AddListItem()
        local labelAwake = item.Controls["UILabel_AwakeningIntroduction"]
        labelAwake.text = text
        if pet.PetAwakeLevel >= i then
            --text = LocalString.PartnerText.ActiveColor .. text
            --text = text .. LocalString.PartnerText.ColorSuffix
            labelAwake.color = Color.New(125/256,62/256,47/256,1)
        else
            labelAwake.color = Color.New(145/256,144/256,144/256,1)
        end
    end

    local fragmentid = pet.ConfigData.fragmentid
	print(fragmentid)
    local itemFragment = ConfigManager.getConfigData("petfragment",fragmentid)
	print(itemFragment.icon)
    fields.UITexture_AwakeningStuff:SetIconTexture(itemFragment.icon)
    local QColor = colorutil.GetQualityColor(itemFragment.quality)
    fields.UISprite_AwakeQuality.color = QColor
    fields.UILabel_AwakeningName.text = itemFragment.name
    local isMax = false
    if pet.PetAwakeLevel == #CfgAwake[pet.ConfigId].awakelvlup_awakeid then
        isMax   = true
    else
        isMax   = false
    end
    if isMax then
        fields.UILabel_AwakeAmount.text = "MAX"
        -- fields.UILabel_AwakeMoney.text = ""
    else
        local ownedFragmentAmount = PetManager.GetFragmentNum(fragmentid)
        local lvlupFragmentAmount = CfgAwake[pet.ConfigId].awakelvlup_awakeid[pet.PetAwakeLevel+1].petfragmentcost
        local cl = ownedFragmentAmount>=lvlupFragmentAmount and LocalString.PartnerText.SatisfiedColor or LocalString.PartnerText.NotEnoughColor
        fields.UILabel_AwakeAmount.text = cl .. tostring(ownedFragmentAmount) .. '/' .. tostring(lvlupFragmentAmount) .. LocalString.PartnerText.ColorSuffix
        
		local currencyData = ItemManager.GetCurrencyData(CfgAwake[pet.ConfigId].awakelvlup_awakeid[pet.PetAwakeLevel+1].requirexunibi)
        -- fields.UILabel_AwakeMoney.text = tostring(currencyData.Number)
    end
    fields.UIList_AwakeningProps:Reposition()
    if bit.band(effectsToShow,effectAwake)>0 then
        ShowAwakeEffect()
    end
end
-- end region


local function RefreshRedDots()
    redDotFuncs[2] = PetManager.CanUpgradeSkill
    redDotFuncs[3] = PetManager.CanUpgradeStageStar
    redDotFuncs[4] = PetManager.CanUpgradeAwake
    uimanager.call("partner.dlgpartner","ShowRedDot",{op=2, b=PetManager.CanUpgradeSkill(pet)})
    uimanager.call("partner.dlgpartner","ShowRedDot",{op=3, b=PetManager.CanUpgradeStageStar(pet)})
    uimanager.call("partner.dlgpartner","ShowRedDot",{op=4, b=PetManager.CanUpgradeAwake(pet)})
end

local function RefreshTab()
    groups[currentRatioButton].func()
end

local function Switch(params)
    currentRatioButton = params and params.idx or currentRatioButton
    pet = params and params.pet or pet
    for _,ratio in pairs(groups) do
        ratio.ui.gameObject:SetActive(false)
    end


		groups[currentRatioButton].ui.gameObject:SetActive(true)
		local redfunc = redDotFuncs[currentRatioButton]
		local b = false
		if redfunc then
			b = redfunc(pet)
		end
		uimanager.call("partner.dlgpartner","ShowRedDot",{op = currentRatioButton,b=b})

    RefreshTab()
end

local function destroy()

end

local function refresh()
    Switch()
end

local function varrefresh(params)
    effectsToShow = params or 0
    refresh()
end

local function OnRecycle(newpet)
    pet = newpet
    refresh()
end

local function update()

end

local function uishowtype()
    return UIShowType.Refresh
end

local function hide()
end

local function show(params)
    pet                 = params.pet
    currentRatioButton  = params.idx
    effectsToShow       = 0
    RefreshRedDots()
end

local function uiInit()
    fields.UIGroup_StageStar.gameObject:SetActive(true)
    uiList_Attributes = {}
    fields.UIList_PartnerAttribute:Clear()
    for i,v in ipairs(PetManager.InfoAttr) do
        local item                      = fields.UIList_PartnerAttribute:AddListItem()
        local labelName                 = item.Controls["UILabel_PartnerAttributeName"]
        local labelValue                = item.Controls["UILabel_PartnerAttribute"]
        local spriteIcon                = item.Controls["UISprite_AttributeIcon"]
        labelName.text                  = StatusText[v.idx].text..':'
        spriteIcon.spriteName           = StatusText[v.idx].spritename
        uiList_Attributes[i]            = {}
        uiList_Attributes[i].item       = item
        uiList_Attributes[i].labelValue = labelValue
        -- uiList_Attributes[i].spriteIcon = spriteIcon
    end

    uiList_Stars = {}
    -- fields.UIList_StageStar:Clear()
    for i=1,9 do
        local item = fields.UIList_StageStar:GetItemByIndex(i-1)
        local spriteStar = item.Controls["UISprite_Star"]
        spriteStar.gameObject:SetActive(false)
        uiList_Stars[i] = spriteStar
    end

    uiList_StageStarConsume = {}
    fields.UIList_StageStarProps:Clear()
    for i=1,3 do
        local item = fields.UIList_StageStarProps:AddListItem()
        -- local spriteAdd = item.Controls["UISprite_Add"]
        local labelName = item.Controls["UILabel_PropName"]
        local textureIcon = item.Controls["UITexture_Icon"]
        local labelAmount = item.Controls["UILabel_StageStarItemAmount"]
		local spritequality = item.Controls["UISprite_Quality"]
        labelName.gameObject:SetActive(true)
        uiList_StageStarConsume[i] = {}
        uiList_StageStarConsume[i].item = item
        -- uiList_StageStarConsume[i].spriteAdd = spriteAdd
        uiList_StageStarConsume[i].labelName = labelName
        uiList_StageStarConsume[i].textureIcon = textureIcon
        uiList_StageStarConsume[i].labelAmount = labelAmount
		uiList_StageStarConsume[i].spritequality = spritequality
    end
    fields.UIList_PartnerLuckychance:Clear()
    fields.UIList_PartnerLuckychance:ResetListCount(6)
end

local function init(params)
  name, gameObject, fields = unpack(params)

  groups = {
      {ui=fields.UIGroup_PartnerInformation,    func=RefreshPartnerInformation},
      {ui=fields.UIGroup_PartnerSkill,          func=RefreshPartnerSkill},
      {ui=fields.UIGroup_StageStar,             func=RefreshStageStar},
      {ui=fields.UIGroup_Awakening,             func=RefreshAwake},
  }

  StatusText = ConfigManager.getConfig("statustext")
  CfgAwake = ConfigManager.getConfig("petawake")
  CfgStageStar = ConfigManager.getConfig("petstagestar")
  uiInit()
  EventHelper.SetClick(fields.UILabel_DetailKarma,function()
      uimanager.show("partner.dlgpartner_karma",{pet=pet})
  end)
  EventHelper.SetClick(fields.UIButton_StageStarIntensify,function()
      local currInfo = CfgStageStar[pet.PetStageStar]
    --   local itemid = currInfo.requireitem[i].itemid
      local fullfill = true
      for i,requireItemInfo in ipairs(currInfo.requireitem) do
          local itemid = requireItemInfo.itemid
          local amount = requireItemInfo.amount
          local bagAmount = BagManager.GetItemNumById(itemid)
          if amount>bagAmount then
              local itemInfo = ItemManager.GetItemData(itemid)
              fullfill = false
              ItemManager.GetSource(itemid,"partner.dlgpartner")
              return
          end
      end
      local xunibi = PlayerRole.Instance():GetCurrency(cfg.currency.CurrencyType.XuNiBi)
      if xunibi < currInfo.requirexunibi.amount then
          ItemManager.GetSource(cfg.currency.CurrencyType.XuNiBi,"partner.dlgpartner")
          return
      end
      PetManager.RequestUpgradePetStar(pet.ConfigId)
    --   for local itemid = currInfo.requireitem[i].itemid
  end)

  EventHelper.SetClick(fields.UIButton_AwakeningAwakening,function()
      local fragmentid = pet.ConfigData.fragmentid
      local ownedFragmentAmount = PetManager.GetFragmentNum(fragmentid)
      if CfgAwake[pet.ConfigId].awakelvlup_awakeid[pet.PetAwakeLevel+1]==nil then
          uimanager.ShowSingleAlertDlg{content = LocalString.PartnerText.AwakeFullLevel}
          return
      end
      if CfgAwake[pet.ConfigId].awakelvlup_awakeid[pet.PetAwakeLevel+1].requirepetlevel > pet.PetLevel then
          uimanager.ShowSingleAlertDlg{content = LocalString.PartnerText.NotEnoughLevel}
      end
      local lvlupFragmentAmount = CfgAwake[pet.ConfigId].awakelvlup_awakeid[pet.PetAwakeLevel+1].petfragmentcost
      if ownedFragmentAmount>= lvlupFragmentAmount then
          if PetManager.CanUpgradeAwake(pet) then
              PetManager.RequestUpgradeAwake(pet.ConfigId)
          end
      else
        --   uimanager.show("dlgalert_reminder_singlebutton",{content = LocalString.PartnerText.NotEnoughFragments,Title=LocalString.TipText})
            ItemManager.GetSource(fragmentid,"partner.dlgpartner")
      end
  end)

	EventHelper.SetClick(fields.UIButton_Add,function()
      local fragmentid = pet.ConfigData.fragmentid
      ItemManager.GetSource(fragmentid,"partner.dlgpartner")
	end)
end


return {
  init                  = init,
  show                  = show,
  hide                  = hide,
  update                = update,
  destroy               = destroy,
  refresh               = refresh,
  uishowtype            = uishowtype,
  Switch                = Switch,
  varrefresh            = varrefresh,
  OnRecycle             = OnRecycle,
}
