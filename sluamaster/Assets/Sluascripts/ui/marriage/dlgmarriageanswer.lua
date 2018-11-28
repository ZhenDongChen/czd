local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local marriagemanager = require("marriage.marriagemanager")
local network = require("network")
local Player = require"character.player"
local PlayerRole=require"character.playerrole"

local gameObject
local name
local fields

local m_modelFemale
local m_modelMale
local m_giftType
local m_oath
local m_proposeroleid

local function destroy()
end

local function OnModelMaleLoaded(go)
    if not m_modelMale.m_Object then return end
    local playerTrans           = m_modelMale.m_Object.transform
    playerTrans.parent          = fields.UITexture_3DModel.gameObject.transform
	playerTrans.localScale      = Vector3.one*300
    playerTrans.localPosition   = Vector3(-490,-410,-200)
    playerTrans.rotation = Quaternion.Euler(-90,0,0)
    ExtendedGameObject.SetLayerRecursively(m_modelMale.m_Object,define.Layer.LayerUICharacter)
    m_modelMale.m_Object:SetActive(true)
end

local function OnModelFemaleLoaded(go)
    if not m_modelFemale.m_Object then return end
    local playerTrans           = m_modelFemale.m_Object.transform
    playerTrans.parent          = fields.UITexture_3DModel.gameObject.transform
	playerTrans.localScale      = Vector3.one*300
    playerTrans.localPosition   = Vector3(470,-410,-200)
    playerTrans.rotation = Quaternion.Euler(-90,0,0)
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
    m_modelFemale:init(0,femalInfo.profession,femalInfo.gender,false,femalInfo.fashionid,femalInfo.equips, nil,0.5)
    m_modelFemale:RegisterOnLoaded(OnModelFemaleLoaded)
end

local function show(params)
    if params and params.proposeroleid then
       m_oath = params.proposeoath
       m_giftType =  params.proposetype
       m_proposeroleid = params.proposeroleid
       local oath = params.proposeoath      
       if oath==nil or oath=="" then
           oath = LocalString.Marriage.ProposeOath
       end
       fields.UIInput_LoveDeclaration.value = string.format(LocalString.Marriage.BeProposedOathShow, 
           params.proposerolename, oath) 
       marriagemanager.EnableInputControlEdit(fields.UIInput_LoveDeclaration, false)
    end

    if params and params.roleInfo then
        ShowMarriageModel(params.roleInfo)  
    end   
end

local function hide()
     if m_modelMale then m_modelMale:remove() m_modelMale=nil end
     if m_modelFemale then m_modelFemale:remove() m_modelFemale=nil end    
end

local function refresh(params)   
end

local function update()
    if m_modelMale and m_modelMale.m_Object then
        m_modelMale.m_Avatar:Update()
    end
    if m_modelFemale and m_modelFemale.m_Object then
        m_modelFemale.m_Avatar:Update()
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)
    local marriageConfig = ConfigManager.getConfig("marrigeconfig")
    fields.UIInput_LoveDeclaration.characterLimit = marriageConfig.marrigetextlength*2 --����ռ�����ַ�

    EventHelper.SetClick(fields.UIButton_ProposeRefuse, function()
        marriagemanager.CBeproposed(m_proposeroleid, marriagemanager.ProposeRe.Refuse, m_giftType, m_oath)
        uimanager.hidedialog("marriage.dlgmarriageanswer")
    end )

    EventHelper.SetClick(fields.UIButton_ProposeAgree, function()
        marriagemanager.CBeproposed(m_proposeroleid, marriagemanager.ProposeRe.Agree, m_giftType, m_oath)     
        uimanager.hidedialog("marriage.dlgmarriageanswer")
    end )
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
