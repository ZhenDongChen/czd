-- region *.lua
-- Date
-- 此文件由[BabeLua]插件自动生成



-- endregion

local unpack = unpack
local print = print

local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local ConfigManager = require"cfg.configmanager"
local Player = require"character.player"
local PlayerRole = require"character.playerrole"
local mathutils = require"common.mathutils"
local CheckCmd=require("common.checkcmd")

local gameObject,name,fields

local parent
local ArmourList
local DressInfo
local FashionInfo = nil
local Model
local currentState=nil
local dressing
local states = {"UILabel_Unacquired","UILabel_Acquired","UILabel_Activited"}
local isSend = false
local lastSelect
local currentSelect
local listeners = {}
local FashionList = {}
local CurrentEquipping = nil
local cnt
local UnEquiping
local showName = "UISprite_FashionHighlight"
local isReady
local HumanoidAvatar = require"character.avatar.humanoidavatar"
local FashionData = nil
local FashionState = nil
local selectedIndex = 0
local FashionManager = require"character.fashionmanager"
local CameraManager = require"cameramanager"
local PetManager = require"character.pet.petmanager"
local Pet = require"character.pet.pet"
local ItemManager = require"item.itemmanager"
local ItemPet = require"item.pet"
local ColorUtils = require"common.colorutil"
local opItemId
local skins
local skinData
local skinState
local skinNew

local function RotateModel(delta)
    if Model and Model.m_Object then
        local vecRotate = Vector3(0,-delta.x,0)
        Model.m_Object.transform.localEulerAngles = Model.m_Object.transform.localEulerAngles + vecRotate
    end
end

local function destroy()
end

local function OnModelLoaded(go)
    if not Model.m_Object then return end
    local playerTrans           = Model.m_Object.transform
    playerTrans.parent          = fields.UITexture_3DModel.gameObject.transform
	playerTrans.localScale      = Vector3.one*250
    playerTrans.localPosition   = Vector3(0,-290,-200)
    playerTrans.localEulerAngles = Vector3(-90,0,0)
    ExtendedGameObject.SetLayerRecursively(Model.m_Object,define.Layer.LayerUICharacter)
    Model.m_Object:SetActive(true)
end

local function RefreshModel(petid,skinid)
    if Model then Model:remove() Model=nil end
    Model = Pet:new(0,petid,0,true)
    Model.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
	print("dlgpartner_Skin"..skinid)
    Model:init(skinid)
    Model:RegisterOnLoaded(OnModelLoaded)
end

local function refreshRight(skininfo)
    fields.UILabel_FashionAttrTitle.text = LocalString.PartnerText.SkinShape
    fields.UILabel_FashionDes.text = skininfo.gain
    fields.UILabel_FashionAttr.text = skininfo.detail
end

local function refreshGet(skininfo,skinstate)
    -- if dress_info.quickbuy then
        fields.UIGroup_Go.gameObject:SetActive(false)
        fields.UIGroup_Buy.gameObject:SetActive(true)
        fields.UILabel_VIP.text = string.format(LocalString.PartnerText.SkinRequire,skininfo.modelname)
        local dt = ItemManager.GetCurrencyData(skininfo.price)
        fields.UILabel_Cost.text = tostring(dt.Number)
        fields.UILabel_GetFashion.text = LocalString.FashionText.Buy
        fields.UIButton_GetFashion.isEnabled = skinstate == 0
    -- else
    --     fields.UIGroup_Go.gameObject:SetActive(true)
    --     fields.UIGroup_Buy.gameObject:SetActive(false)
    --     fields.UILabel_GetFashion.text = LocalString.FashionText.Go
    -- end
end

local function show(params)
    -- pet = params.pet
    fields.UILabel_TitleName.text = LocalString.FashionText.PartnerSkins
    skinNew = false
end

local function hide()
    PetManager.SetAllPetSkinOld()
    if Model then Model:remove() Model=nil end
end

local function update()
    if Model and Model.m_Object then
        Model.m_Avatar:Update()
    end
end

local function LoadDetailInfo()
    if skinData then
        if skinNew then
            PetManager.SetPetSkinOld(skinData.petid,skinData.id)
            skinNew = false
        end


        local attained = false
        local pet = PetManager.IsAttainedPets(skinData.petid)
        if pet then
            attained = true
        else
            attained = false
            local cfgPet = ConfigManager.getConfigData("petbasicstatus",skinData.petid)
            pet = ItemPet:CreateInstance(skinData.petid,cfgPet,1,1,nil,1)
        end
        refreshGet(skinData,skinState)
        refreshRight(skinData)
        if skinState == 0 then
            fields.UIButton_FashionEquip.gameObject:SetActive(false)
            fields.UIButton_GetFashion.gameObject:SetActive(true)
            EventHelper.SetClick(fields.UIButton_GetFashion,function()

                local validate,info=CheckCmd.CheckData({data=skinData.price})
                if validate then
                    if attained then
                        PetManager.RequestBuyPetSkin(pet.ConfigId,skinData.id)
                    else
                        uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.PartnerText.NoPartnerToBuySkin})
                    end
                else
                    uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.Exchange_YuanBaoNotEnough})
                end
            end)
        else
            fields.UIButton_GetFashion.gameObject:SetActive(false)
            fields.UIButton_FashionEquip.gameObject:SetActive(true)
            if skinState == 1 then
                fields.UILabel_FashionEquip.text = LocalString.FashionText.Equip
            else
                fields.UILabel_FashionEquip.text = LocalString.FashionText.Unequip
            end
        end
        EventHelper.SetClick(fields.UIButton_FashionEquip,function()
            if skinState == 0 then
                --btn not shown
            elseif skinState == 1 then
                PetManager.RequestEquipPetSkin(pet.ConfigId,skinData.id)
            elseif skinState == 2 then
                PetManager.RequestUnEquipPetSkin(pet.ConfigId,0) --???
            end
        end)
        RefreshModel(skinData.petid,skinData.id)
    end
end

local function DisplayOneSkinItem(item,skin,idx)
    for i,v in pairs(states) do
        local labelState = item.gameObject.transform:Find(v)
        labelState.gameObject:SetActive(false)
    end
    local colorName = ColorUtils.GetQualityColorText(skin.info.quality,skin.info.name)
    item:SetText("UILabel_FashionName",colorName)
    local spriteWarning = item.Controls["UISprite_Warning"]
    spriteWarning.gameObject:SetActive(skin.isNew)
    local spriteColor = item.Controls["UISprite_RideQuality"]
    local quality = skin.info.quality
    local Qcolor = colorutil.GetQualitySprite(quality)
    spriteColor.spriteName = Qcolor
    if skin.info.icon and skin.info.icon~="" then
        local texture = item.Controls["UITexture_Ride"]
        texture:SetIconTexture(skin.info.icon)
    end
    item.Data = skin
    local stateIcon = item.gameObject.transform:Find(states[skin.state+1])
    stateIcon.gameObject:SetActive(true)
    if skin.info.id == opItemId then
        item.Checked = true
        local UIToggle = item:GetComponent("UIToggle")
        UIToggle:Set(true)
    else
        item.Checked = false
        local UIToggle = item:GetComponent("UIToggle")
        UIToggle:Set(false)
    end
    EventHelper.SetClick(item,function()
        skinData = skin.info
        skinState = skin.state
        skinNew = skin.isNew
        selectedIndex = item.Index
        opItemId = skin.info.id
        LoadDetailInfo()
    end)
end

local function GetSkinIndex(skinid)
    for index,skin in ipairs(skins) do
        if skin.info.id == skinid then return index end
    end
    return 1
end

local function OnItemInit(UIListItem,wrapIndex,realIndex)
    local mail = skins[realIndex]
    DisplayOneSkinItem(UIListItem,mail,realIndex)
end

local function InitList(num)
    local wrapContent=fields.UIList_Fashion.gameObject:GetComponent("UIWrapContentList")
    if wrapContent==nil then
        return
    end
    EventHelper.SetWrapListRefresh(wrapContent,OnItemInit)
    wrapContent:SetDataCount(num)
end

local function DisplayAllSkins()
    InitList(#skins)
    local defaultItem = fields.UIList_Fashion:GetItemByIndex(GetSkinIndex(opItemId)-1)
    if defaultItem then
        skinData = defaultItem.Data.info
        skinState = defaultItem.Data.state
        -- fields.UIList_Fashion:SetSelectedIndex(0)
    else
        skinData = nil
    end
    LoadDetailInfo()
end

local function refresh()
    skins = PetManager.GetAllSkins()
    if opItemId == nil then
        opItemId = skins[1].info.id
    end
    DisplayAllSkins()
    -- DisplayAllFashions()

end

local function showdialog(params)
    show(params)
end

local function uishowtype()
    return UIShowType.Refresh
end


local function init(oname,ogameObject,ofields)
    name, gameObject, fields = oname,ogameObject,ofields
end

local function second_update()

end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    RotateModel = RotateModel,
    second_update = second_update,
}
