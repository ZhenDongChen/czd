local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local marriagemanager = require("marriage.marriagemanager")
local ItemManager = require("item.itemmanager")
local network = require("network")
local Player = require"character.player"
local PlayerRole=require"character.playerrole"


local gameObject
local name
local fields

local m_uiType
local m_modelFemale
local m_modelMale
local m_bHasLuxurious

local function destroy()
end

local function show(params)
    m_bHasLuxurious = false
end

local function hide()
     if m_modelMale then m_modelMale:remove() m_modelMale=nil end
     if m_modelFemale then m_modelFemale:remove() m_modelFemale=nil end   
end

local function OnModelMaleLoaded(go)
    if not m_modelMale.m_Object then return end
    local playerTrans           = m_modelMale.m_Object.transform
    playerTrans.parent          = fields.UITexture_3DModel.gameObject.transform
	playerTrans.localScale      = Vector3.one*300
    playerTrans.localPosition   = Vector3(-970,-320,-16)  
    playerTrans.localRotation   = Vector3.up*135
    ExtendedGameObject.SetLayerRecursively(m_modelMale.m_Object,define.Layer.LayerUICharacter)
    
    m_modelMale.m_Object:SetActive(true)
end

local function OnModelFemaleLoaded(go)
    if not m_modelFemale.m_Object then return end
    local playerTrans           = m_modelFemale.m_Object.transform
    playerTrans.parent          = fields.UITexture_3DModel.gameObject.transform
	playerTrans.localScale      = Vector3.one*300
    playerTrans.localPosition   = Vector3(92,-320,-16)
    playerTrans.localRotation   = Vector3.up*(-170)
    ExtendedGameObject.SetLayerRecursively(m_modelFemale.m_Object,define.Layer.LayerUICharacter)
    m_modelFemale.m_Object:SetActive(true)
end

local function ShowMarriageModel(otherRoleInfo)
    otherRoleInfo.equipsdetail = {}
    for i, equipMsg in pairs(otherRoleInfo.equips) do
        otherRoleInfo.equipsdetail[i] = equipMsg
    end
    for i, equipMsg in pairs(otherRoleInfo.equips) do
        otherRoleInfo.equips[i] = map.msg.EquipBrief({equipkey = equipMsg.modelid, anneallevel = equipMsg.normalequip.anneallevel})
    end

    local maleInfo = {}
    --maleInfo.gender = cfg.role.GenderType.MALE
    local femalInfo = {}
    --femalInfo.gender = cfg.role.GenderType.FEMALE
    --if PlayerRole.Instance().m_Gender == cfg.role.GenderType.MALE then
        maleInfo.profession = PlayerRole.Instance().m_Profession
        maleInfo.fashionid = PlayerRole.Instance().m_Dress
        maleInfo.equips = PlayerRole.Instance().m_Equips
        maleInfo.gender = PlayerRole.Instance().m_Gender

        femalInfo.profession = otherRoleInfo.profession
        femalInfo.fashionid = otherRoleInfo.dressid
        femalInfo.equips = otherRoleInfo.equips
        femalInfo.gender = otherRoleInfo.gender
    --[[else
        maleInfo.profession = otherRoleInfo.profession
        maleInfo.fashionid = otherRoleInfo.dressid
        maleInfo.equips = otherRoleInfo.equips

        femalInfo.profession = PlayerRole.Instance().m_Profession 
        femalInfo.fashionid = PlayerRole.Instance().m_Dress
        femalInfo.equips = PlayerRole.Instance().m_Equips
    end]]

    if m_modelMale then m_modelMale:remove() m_modelMale=nil end
    m_modelMale = Player:new(true)
    m_modelMale.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    m_modelMale:init(0,maleInfo.profession,maleInfo.gender,false,maleInfo.fashionid,maleInfo.equips,nil,0.5)
    m_modelMale:RegisterOnLoaded(OnModelMaleLoaded)

    if m_modelFemale then m_modelFemale:remove() m_modelFemale=nil end
    m_modelFemale = Player:new(true)
    m_modelFemale.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    m_modelFemale:init(0,femalInfo.profession,femalInfo.gender,false,femalInfo.fashionid,femalInfo.equips,nil,0.5)
    m_modelFemale:RegisterOnLoaded(OnModelFemaleLoaded)
end

local function refresh(params)   
    --local uiType = params.uiType
    --printyellow("refresh XXX:", params.uiType)
    if params and params.uiType then
        m_uiType = params.uiType
        if m_uiType == marriagemanager.DialogType.Propose then
            fields.UIGroup_Propose.gameObject:SetActive(true)
            fields.UIGroup_GetGift.gameObject:SetActive(false)
            fields.UIGroup_DivorceCertificate.gameObject:SetActive(false)
            fields.UILabel_Lover.text = PlayerRole.Instance():GetName()
            if params.roleInfo then
                ShowMarriageModel(params.roleInfo)
            end
            
            local marriageConfig = ConfigManager.getConfig("marrigeconfig")
            if params.proposeName then
                fields.UILabel_LoveDeclaration.text = string.format(LocalString.Marriage.ProposeOathShow, 
                    params.proposeName, marriageConfig.marrigetextlength)           
            end
           
        elseif m_uiType == marriagemanager.DialogType.GetGift then
            fields.UIGroup_Propose.gameObject:SetActive(false)
            fields.UIGroup_GetGift.gameObject:SetActive(true)
            fields.UIGroup_DivorceCertificate.gameObject:SetActive(false)

        elseif m_uiType == marriagemanager.DialogType.DivorceBook then
            fields.UIGroup_Propose.gameObject:SetActive(false)
            fields.UIGroup_GetGift.gameObject:SetActive(false)
            fields.UIGroup_DivorceCertificate.gameObject:SetActive(true)
            fields.UIButton_ConfirmDivorce.gameObject:SetActive(true)
            fields.UIInput_Divorce.value = LocalString.Marriage.DivorceBookContent
            marriagemanager.EnableInputControlEdit(fields.UIInput_Divorce, true)
            if params.name then
                fields.UILabel_DivorceeName.text = params.name
            end
            fields.UILabel_DivorcerName.text = PlayerRole.Instance():GetName()
            local l_Time = os.date("*t", timeutils.GetServerTime())
		    local l_TimeStr = string.format(LocalString.Time.Timestamp, l_Time.year, l_Time.month, l_Time.day)
            fields.UILabel_DivorceDate.text = l_TimeStr

        elseif m_uiType == marriagemanager.DialogType.DivorceBookNotify then
            fields.UIGroup_Propose.gameObject:SetActive(false)
            fields.UIGroup_GetGift.gameObject:SetActive(false)
            fields.UIGroup_DivorceCertificate.gameObject:SetActive(true)
            fields.UIButton_ConfirmDivorce.gameObject:SetActive(false) 
            marriagemanager.EnableInputControlEdit(fields.UIInput_Divorce, false) 
            if params.bookcontent then
                fields.UIInput_Divorce.value = params.bookcontent
            end
            
            if params.divorcerolename then
                fields.UILabel_DivorcerName.text = params.divorcerolename
            end
            fields.UILabel_DivorceeName.text = PlayerRole.Instance():GetName()  
            
            if params.time then
                local sendTime = os.date("*t", params.time/1000)
		        local sendTimeStr = string.format(LocalString.Time.Timestamp, sendTime.year, sendTime.month, sendTime.day)
                fields.UILabel_DivorceDate.text = sendTimeStr
            end            
        end
    end
end

local function update()   
     if m_uiType == marriagemanager.DialogType.Propose then        
        if m_modelMale and m_modelMale.m_Object then
            m_modelMale.m_Avatar:Update()
        end
        if m_modelFemale and m_modelFemale.m_Object then
            m_modelFemale.m_Avatar:Update()
        end  
        
        local bHasLuxuriousNow = marriagemanager.IsGiftsExist(marriagemanager.GiftsType.Luxurious)
        if m_bHasLuxurious ~= bHasLuxuriousNow then           
            marriagemanager.EnableInputControlEdit(fields.UIInput_LoveDeclaration, bHasLuxuriousNow)
            UITools.SetButtonEnabled(fields.UIButton_GetBetrothalGifts, not bHasLuxuriousNow)
            m_bHasLuxurious = bHasLuxuriousNow
        end   
     end    
end

local function ShowBuyGiftsDlg()
    local marriageConfig = ConfigManager.getConfig("marrigeconfig")

    local giftNormal = ItemManager.CreateItemBaseById(marriageConfig.marrigepack[1].marrigepackid)
    local normalMoneyInfo = ItemManager.GetCurrencyData(marriageConfig.marrigepack[1].marrigepackprice)
    fields.UISprite_Diamond_Normal.spriteName = normalMoneyInfo:GetIconName() 
    fields.UILabel_Diamond_Normal.text = normalMoneyInfo:GetNumber()
    fields.UITexture_NormalGift:SetIconTexture(giftNormal:GetTextureName())
    fields.UILabel_NormalGiftDes.text = giftNormal:GetIntroduction()

    local giftLuxurious = ItemManager.CreateItemBaseById(marriageConfig.marrigepack[2].marrigepackid)
    local luxuriousMoneyInfo = ItemManager.GetCurrencyData(marriageConfig.marrigepack[2].marrigepackprice)
    fields.UISprite_Diamond_Luxurious.spriteName = luxuriousMoneyInfo:GetIconName() 
    fields.UILabel_Diamond_Luxurious.text = luxuriousMoneyInfo:GetNumber()  
    fields.UITexture_LuxuriousGift:SetIconTexture(giftLuxurious:GetTextureName())
    fields.UILabel_LuxuriousGiftDes.text = giftLuxurious:GetIntroduction()

    local bHasNormalGift = marriagemanager.IsGiftsExist(marriagemanager.GiftsType.Normal)
    fields.UISprite_Diamond_Normal_Group.gameObject:SetActive(not bHasNormalGift)
    fields.UIButton_BuyNormal.gameObject:SetActive(not bHasNormalGift)
    if bHasNormalGift then     
        fields.UILabel_Diamond_Luxurious.text = marriageConfig.marrigepack[2].marrigepackprice.amount - marriageConfig.marrigepack[1].marrigepackprice.amount
    end

    refresh({uiType = marriagemanager.DialogType.GetGift})
end

local function OnReceiveGifts()
    fields.UIGroup_GetGift.gameObject:SetActive(false)
end

local function init(params)
    name, gameObject, fields = unpack(params)
    local marriageConfig = ConfigManager.getConfig("marrigeconfig")
    fields.UIInput_LoveDeclaration.characterLimit = marriageConfig.marrigetextlength*2 
    fields.UIInput_Divorce.characterLimit = marriageConfig.divorcetextlength*2

    local normalMoneyInfo = ItemManager.GetCurrencyData(marriageConfig.marrigepack[1].marrigepackprice)
    local luxuriousMoneyInfo = ItemManager.GetCurrencyData(marriageConfig.marrigepack[2].marrigepackprice)

    --------------------------Propose Group 
    EventHelper.SetClick(fields.UIButton_CancelPropose, function()
        uimanager.hidedialog(name)
    end )

    EventHelper.SetClick(fields.UIButton_Propose, function()
        local oath = fields.UIInput_LoveDeclaration.value
        if oath == nil or oath == "" then
             marriagemanager.CPropose(LocalString.Marriage.ProposeOath)
        else
             marriagemanager.CPropose(oath)
        end
    end )

    EventHelper.SetClick(fields.UIButton_GetBetrothalGifts, function()
        ShowBuyGiftsDlg()
    end )

    --------------------------GetGift Group
    EventHelper.SetClick(fields.UIButton_CloseGetGift, function()
        refresh({uiType = marriagemanager.DialogType.Propose, proposeName = marriagemanager.GetSelectedPlayerName()})
    end )

    EventHelper.SetClick(fields.UIButton_BuyNormal, function()
        if PlayerRole.Instance():Ingot() < normalMoneyInfo:GetNumber() then
			ItemManager.GetSource(cfg.currency.CurrencyType.YuanBao,name)
        else
            marriagemanager.CBuyCaili(marriageConfig.marrigepack[1].marrigepackid)
            refresh({uiType = marriagemanager.DialogType.Propose, proposeName = marriagemanager.GetSelectedPlayerName()})
        end
        
    end )

    EventHelper.SetClick(fields.UIButton_BuyLuxurious, function()
        local luxuriousMoney = luxuriousMoneyInfo:GetNumber()  
        local bHasNormalGift = marriagemanager.IsGiftsExist(marriagemanager.GiftsType.Normal)
        if bHasNormalGift then     
            fluxuriousMoney = marriageConfig.marrigepack[2].marrigepackprice.amount - marriageConfig.marrigepack[1].marrigepackprice.amount
        end
        if PlayerRole.Instance():Ingot() < luxuriousMoney then
			ItemManager.GetSource(cfg.currency.CurrencyType.YuanBao,name)
        else
            marriagemanager.CBuyCaili(marriageConfig.marrigepack[2].marrigepackid)
            refresh({uiType = marriagemanager.DialogType.Propose, proposeName = marriagemanager.GetSelectedPlayerName()})
        end
        
    end )

    --------------------------DivorceCertificate Group
    EventHelper.SetClick(fields.UIButton_CloseDivorce, function()
        uimanager.hidedialog("marriage.dlgmarriage")
    end )

    EventHelper.SetClick(fields.UIButton_ConfirmDivorce, function()
       local content = fields.UIInput_Divorce.value
       marriagemanager.CDivorceWithBook(content)
       uimanager.hidedialog("marriage.dlgmarriage")
    end )
end

return {
    DialogType = DialogType,
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
