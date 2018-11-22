local unpack = unpack
local print = print
local math = math
local EventHelper           = UIEventListenerHelper
local uimanager             = require("uimanager")
local network               = require("network")
local login                 = require("login")
local DlgBag
local PlayerRole            = require"character.playerrole"
local StarStage             = ConfigManager.getConfig("petstagestar")
local PetManager            = require"character.pet.petmanager"
local BagManager            = require"character.bagmanager"
local EquipPetType          = cfg.bag.BagType.PET_BODY
local BagPetType            = cfg.bag.BagType.PET
local ItemEnum              = require"item.itemenum"
local ConfigManager         = require"cfg.configmanager"
local StatusText            = ConfigManager.getConfig("statustext")
local DlgDialogBox_List     = require"ui.common.dlgdialogbox_list"
local ItemPet               = require"item.pet"
local Pet                   = require"character.pet.pet"
local mathutils             = require"common.mathutils"
local ItemManager           = require"item.itemmanager"
local inactiveShader        = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader          = UnityEngine.Shader.Find("Unlit/Transparent Colored")
local ModuleLockManager     = require"ui.modulelock.modulelockmanager"
local TabBag
local gameObject
local name
local fields
local BattleLevel
local AssistLevel
local pet
local consumedItem
local bIsUpgrading
local currentRatioButton
local RefreshFunctions
local expFull
local prevPetConfigId
local listenerId

local opstate

local currItemSpeed
local itemElapsedTime
local itemLevelTime
local itemCounts
local selectedItemIndex

local CurrentOperation = enum{
    "ATTRIBUTES=1",
    "SKILLS=2",
    "STAGESTAR=3",
    "AWAKE=4",
}

local function ShowRedDot(params)
    local item = fields.UIList_RadioButton:GetItemByIndex(params.op-1)
    spriteRedDot = item.Controls["UISprite_Warning"]
    spriteRedDot.gameObject:SetActive(params.b)
end

local function RefreshLocalItemCounts()
    local uiitem = fields.UIList_Materials:GetItemByIndex(selectedItemIndex-1)
    local labelAmount = uiitem.Controls["UILabel_Amount"]
    labelAmount.text = tostring(consumedItem.num)

    local textureIcon   = uiitem.Controls["UITexture_Icon"]
    textureIcon.shader =  consumedItem.num == 0 and inactiveShader or activeShader

end

local function skillUpdate(num)
    local useNum = num or 1
    if consumedItem then
        if isMaxLevel then
            uimanager.ShowSingleAlertDlg({content=LocalString.PartnerText.MaxLevel})
        else
            local tb = {}
            local remainAmount = consumedItem.num
            local consumdedCount = math.min(useNum,remainAmount)
            local cfgExp = ConfigManager.getConfig("petexp")
            if consumdedCount == 0 then
                ItemManager.GetSource(consumedItem.id,name)
            elseif expFull or pet.PetLevel>=#cfgExp then
                uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.PartnerText.FullExp})
                consumedItem.num = consumedItem.num - consumdedCount
                PetManager.RequestUpgradeLevel(pet.ConfigId,consumedItem.bagpos,consumdedCount)
            else
                consumedItem.num = consumedItem.num - consumdedCount
                PetManager.RequestUpgradeLevel(pet.ConfigId,consumedItem.bagpos,consumdedCount)
            end
            RefreshLocalItemCounts()
        end
    end
end

local function SkillUpdatePressed()

end

local function GetOpPet()
    return pet
end

local function update()
    if Model and Model.m_Object then
        Model.m_Avatar:Update()
    end
    if bIsUpgrading and itemElapsedTime then
        itemElapsedTime = Time.deltaTime + itemElapsedTime
        itemLevelTime = Time.deltaTime + itemLevelTime
        if itemElapsedTime > 1 then
            itemElapsedTime = itemElapsedTime - 1
            skillUpdate(currItemSpeed)
        end
        if itemLevelTime > 1 then
            currItemSpeed = (currItemSpeed+1>10) and 10 or (currItemSpeed+1)
            itemLevelTime = itemLevelTime - 1
        end
    end
end

local function late_update()

end

--refreshs
local function OnModelLoaded(obj)
    if not Model or not Model.m_Object then return end
    --set transform, rotation ,scale
    local playerTrans         = Model.m_Object.transform
    playerTrans.parent        = fields.UITexture_Player.transform
    Model:SetUIScale(200)

    playerTrans.localPosition = Vector3(0, -170, -1500);
    playerTrans.rotation = Quaternion.Euler(-90,0,0)
    ExtendedGameObject.SetLayerRecursively(Model.m_Object, define.Layer.LayerUICharacter)
end

--���ػ���ģ��
local function RefreshModel()
    if Model and Model.m_Object then Model:release() end
    Model = Pet:new(pet.BagId,pet.ConfigId,0,true)
    Model.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    Model:RegisterOnLoaded(OnModelLoaded)
    Model:init(pet.PetSkin)
end

local function GetItems()
    local ret = {}

    local cfgConsume = ConfigManager.getConfig("petconsume")
	print(#cfgConsume)
    for _,itemid in ipairs(cfgConsume.consumeitem) do
        local CfgItem = ConfigManager.getConfigData("itembasic",itemid)
        local itemInfo = {}
        itemInfo.id = itemid
        itemInfo.icon = CfgItem.icon
        itemInfo.quality = CfgItem.quality
        itemInfo.num = BagManager.GetItemNumById(itemid)
        ItemInstance = BagManager.GetItemById(itemid)
        if #ItemInstance > 0 then
            itemInfo.bagpos = ItemInstance[1].BagPos
        end
        table.insert(ret,itemInfo)
    end
    return ret
end

local function PartnerUtility(b)
    -- if b then return end
    if fields.UIGroup_Materials.gameObject.activeSelf then
        fields.UIGroup_RaidoButton.gameObject:SetActive(true)
        fields.UIGroup_Materials.gameObject:SetActive(false)
        fields.UILabel_PartnerUpdate.text = LocalString.PartnerText.Upgrade
    else
        fields.UIGroup_RaidoButton.gameObject:SetActive(false)
        fields.UIGroup_Materials.gameObject:SetActive(true)
        expItems = GetItems()
        for i=1,5 do
            local item          = fields.UIList_Materials:GetItemByIndex(i-1)
            local spriteAdd     = item.Controls["UISprite_Add"]
            local textureIcon   = item.Controls["UITexture_Icon"]
            local labelAmount   = item.Controls["UILabel_Amount"]
            local spriteQuality = item.Controls["UISprite_Quality"]
            if expItems[i] then
                spriteAdd.gameObject:SetActive(false)
                textureIcon.gameObject:SetActive(true)
                textureIcon:SetIconTexture(expItems[i].icon)
                textureIcon.shader = expItems[i].num > 0 and activeShader or inactiveShader
                labelAmount.gameObject:SetActive(true)
                labelAmount.text = tostring(expItems[i].num)
                local Qcolor = colorutil.GetQualitySprite(expItems[i].quality)
                spriteQuality.spriteName = Qcolor
            else
                spriteQuality.spriteName = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
                spriteAdd.gameObject:SetActive(true)
                textureIcon.gameObject:SetActive(false)
                labelAmount.gameObject:SetActive(false)
                textureIcon.shader = inactiveShader
            end
        end
        fields.UILabel_PartnerUpdate.text = LocalString.PartnerText.Return
    end
end

local function RefreshLeft()
    fields.UITexture_Quality:SetIconTexture(LocalString.PartnerText.QualityTexture[pet.ConfigData.basiccolor])
    fields.UILabel_PartnerName.text = pet:GetColorName()
    fields.UILabel_PartnerAwakening.text = pet.PetAwakeLevel

    local stars = PetManager.GetStar(pet.PetStageStar)
    fields.UIList_Star:ResetListCount(stars)
    fields.UILabel_Level.text =LocalString.ChineseLV .. pet.PetLevel
    fields.UILabel_Power.text = pet.PetCombatPower
    local cfgExp = ConfigManager.getConfig("petexp")
    local isFollowing = PetManager.IsFollowing(pet)
    --fields.UISprite_FollowEffect.gameObject:SetActive(isFollowing)
    fields.UILabel_PartnerFollow.text = LocalString.PartnerText.IsFollowing[isFollowing]
    fields.UISlider_EXP.value = pet.PetExp / cfgExp[pet.PetLevel].exp
    fields.UILabel_EXP.text = tostring(pet.PetExp) .. '/' .. tostring(cfgExp[pet.PetLevel].exp)
    expFull = pet.PetExp >= cfgExp[pet.PetLevel].exp
    if prevPetConfigId ~= pet.ConfigId then
        prevPetConfigId = pet.ConfigId
        RefreshModel()
    end
    fields.UISprite_Tips.gameObject:SetActive(PetManager.CanWash(pet))

    fields.UISprite_UpgradeTips.gameObject:SetActive(pet.PetLevel < PlayerRole:Instance().m_Level)

end

local function Switch()
    RefreshLeft()
    uimanager.call("partner.dlgpartner_strengthen","Switch",{pet=pet,idx=currentRatioButton})
end

local function RefreshAll()
    RefreshLeft()
    if uimanager.hasloaded("partner.dlgpartner_strengthen") then
        uimanager.refresh("partner.dlgpartner_strengthen","refresh")
    end
end

local function OnRecycle(newpet)
    pet = newpet
    uimanager.call("partner.dlgpartner_strengthen","OnRecycle",newpet)
    RefreshLeft()
    PartnerUtility()
end

local function varrefresh()
    RefreshAll()
end

local function RefreshLvUp()
    if fields.UIGroup_Materials.gameObject.activeSelf then
        expItems = GetItems()
        for i=1,5 do
            local item          = fields.UIList_Materials:GetItemByIndex(i-1)
            local spriteAdd     = item.Controls["UISprite_Add"]
            local textureIcon   = item.Controls["UITexture_Icon"]
            local labelAmount   = item.Controls["UILabel_Amount"]
            local spriteQuality = item.Controls["UISprite_Quality"]
            if expItems[i] then
                spriteAdd.gameObject:SetActive(false)
                textureIcon.gameObject:SetActive(true)
                textureIcon:SetIconTexture(expItems[i].icon)
                textureIcon.shader = expItems[i].num > 0 and activeShader or inactiveShader
                labelAmount.gameObject:SetActive(true)
                labelAmount.text = tostring(expItems[i].num)
                local Qcolor = colorutil.GetQualitySprite(expItems[i].quality)
                spriteQuality.spriteName = Qcolor
            else
                spriteQuality.spriteName = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
                spriteAdd.gameObject:SetActive(true)
                textureIcon.gameObject:SetActive(false)
                labelAmount.gameObject:SetActive(false)
                textureIcon.shader = inactiveShader
            end
        end
    end
    fields.UILabel_Level.text = LocalString.ChineseLV .. pet.PetLevel
    fields.UILabel_Power.text = pet.PetCombatPower
    local cfgExp = ConfigManager.getConfig("petexp")
    local isFollowing = PetManager.IsFollowing(pet)
   -- fields.UISprite_FollowEffect.gameObject:SetActive(isFollowing)
    fields.UILabel_PartnerFollow.text = LocalString.PartnerText.IsFollowing[isFollowing]
    fields.UISlider_EXP.value = pet.PetExp / cfgExp[pet.PetLevel].exp
    fields.UILabel_EXP.text = tostring(pet.PetExp) .. '/' .. tostring(cfgExp[pet.PetLevel].exp)
    expFull = pet.PetExp >= cfgExp[pet.PetLevel].exp
    uimanager.call("partner.dlgpartner_strengthen","Switch",{pet=pet,idx=currentRatioButton})
end

local function ClearBattle()

end


local function refresh(params)
    RefreshAll()
end

local function destroy()
    if listenerId then
        network.remove_listener(listenerId)
        listenerId = nil
    end
end

local function ShowUpgrade()

end

local function show(params)
    itemLevelTime = nil
    itemElapsedTime = nil
    fields.UIGroup_Materials.gameObject:SetActive(true)
    prevPetConfigId = nil
    pet = params
    currentRatioButton = 1
    uimanager.show("partner.dlgpartner_strengthen",{pet=pet,idx=currentRatioButton})
    PartnerUtility()
	listenerId = network.add_listener("lx.gs.pet.msg.SWashMaxValue",function(msg)
        PetManager.SetWashMaxValue(msg.modelid,msg.maxvalues,msg.currvalues)
		RefreshLeft()
        local pPet = GetOpPet()
        if opstate == 1 then
            uimanager.show("partner.dlgpartner_xilian",pPet)
        elseif opstate == 2 then
            uimanager.show("partner.dlgpartner_decomposition",pPet)
        end
        opstate = 0
    end)
    fields.UISprite_Tips.gameObject:SetActive(PetManager.CanWash(pet))
  
end

local function hide()
    uimanager.hide("partner.dlgpartner_strengthen")
    if Model and Model.m_Object then Model:release() end
    if listenerId then
        network.remove_listener(listenerId)
        listenerId = nil
    end
end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    name, gameObject, fields ,pet  = unpack(params)


    RefreshFunctions = {
        [CurrentOperation.ATTRIBUTES]   = RefreshAttributes,
        [CurrentOperation.SKILLS]       = RefreshSkills,
        [CurrentOperation.STAGESTAR]    = RefresStageStar,
        [CurrentOperation.AWAKE]        = RefreshAwake,
    }
    opstate = 0
    EventHelper.SetClick(fields.UIButton_PartnerUpdate,PartnerUtility)

    EventHelper.SetListClick(fields.UIList_Materials,function(item)
        selectedItemIndex = item.m_nIndex + 1
        consumedItem = expItems[selectedItemIndex]
        if consumedItem then
            local remainAmount = consumedItem.num
            skillUpdate()
        end
    end)

    EventHelper.SetListPress(fields.UIList_Materials,function(item,b)
        bIsUpgrading = b
        if b then
            selectedItemIndex = item.m_nIndex + 1
            consumedItem = expItems[selectedItemIndex]
            if consumedItem then
                currItemSpeed = 1
                itemElapsedTime = 0
                itemLevelTime = 0
            end
        else
            itemElapsedTime = nil
            itemLevelTime = nil
        end
    end)

    EventHelper.SetClick(fields.UISprite_PartnerArrowsLeft,function()
        prevPetConfigId = pet.ConfigId
        pet = PetManager.GetLeftPet(pet)
        Switch()
    end)

    EventHelper.SetClick(fields.UISprite_PartnerArrowsRight,function()
        prevPetConfigId = pet.ConfigId
        pet = PetManager.GetRightPet(pet)
        Switch()
    end)

    EventHelper.SetListClick(fields.UIList_RadioButton,function(item)
        currentRatioButton = item.m_nIndex + 1
        Switch()
    end)

    EventHelper.SetClick(fields.UIButton_PartnerFillUp,function()
        -- uimanager.show("partner.dlgpartner_xilian",pet)
        -- local cfgFuncOpen = ConfigManager.getConfigData("uifunctionopen",cfg.ui.UIFunctionList.PET_WASH)
        -- local status = ModuleLockManager.GetUIFuncStatusByType(cfg.ui.UIFunctionList.PET_WASH)
        local cfgConfig = ConfigManager.getConfig("petconfig")

        local openLevel = cfgConfig.washopenlevel.level
        if pet.PetLevel<openLevel then
            uimanager.ShowSingleAlertDlg{content=string.format(LocalString.PartnerText.WashOpenLevel,openLevel)}
        else
            opstate = 1
            network.send(lx.gs.pet.msg.CWashMaxValue{modelid = pet.ConfigId})
        end
    end)

    EventHelper.SetClick(fields.UIButton_PartnerDecomposition,function()
        opstate = 2
        network.send(lx.gs.pet.msg.CWashMaxValue{modelid = pet.ConfigId})
    end)

	--��ս
    EventHelper.SetClick(fields.UIButton_PartnerBattle,function()
        uimanager.show("partner.dlgpartner_assist")
    end)

    EventHelper.SetClick(fields.UIButton_PartnerFashionBox,function()
        -- uimanager.showdialog("dlgfashion",{pet=pet,fashiontype="pet"})
         uimanager.show("partner.dlgpartner_karma",{pet=pet}) --Ե��
    end)

	--����
    EventHelper.SetClick(fields.UISprite_PartnerFollow,function()
        -- fields.UISprite_FollowEffect.gameObject:SetActive(PetManager.IsFollowing(pet))
        if PetManager.IsFollowing(pet) then
            if PetManager.CanActiveOrUnActive() then
                PetManager.RequestUnActive(pet.ConfigId)
            else
                uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.PartnerText.EquipCD})
            end
        elseif PetManager.IsBattlePet(pet.ConfigId) then
            if PetManager.CanActiveOrUnActive() then
                PetManager.RequestActive(pet.ConfigId)
            else
                uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.PartnerText.EquipCD})
            end
        else
            uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.PartnerText.NotEquipPet})
        end
    end)

    EventHelper.SetDrag(fields.UITexture_Player,function(o,delta)
        if Model and Model.m_Object then
            local vecRotate = Vector3(0,-delta.x,0)
            Model.m_Object.transform.localEulerAngles = Model.m_Object.transform.localEulerAngles + vecRotate
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
  showtab = showtab,
  hidetab = hidetab,
  uishowtype = uishowtype,
  varrefresh = varrefresh,
  SetActiveRight = SetActiveRight,
  RefreshModel = RefreshModel,
  RefreshLvUp  = RefreshLvUp,
  ShowRedDot = ShowRedDot,
  OnRecycle   = OnRecycle,
}
