-- region *.lua
-- Date
-- 此文件由[BabeLua]插件自动生成
--UILabel_Rise
--UILabel_Ranking


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
local ItemManager = require"item.itemmanager"
local ColorUtil = require"common.colorutil"
local gameObject,name,fields
local opItemId
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
local TimeUtils = require"common.timeutils"
local ColorUtils = require"common.colorutil"
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
    playerTrans.localPosition   = Vector3(0,-290,-300)
	playerTrans.localRotation=Quaternion.Euler(-90,0,0)
	
    ExtendedGameObject.SetLayerRecursively(Model.m_Object,define.Layer.LayerUICharacter)
    Model.m_Object:SetActive(true)
end

local function RefreshModel()
    if Model then Model:remove() Model=nil end
    Model = Player:new(true)
    Model.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    Model:init(0,PlayerRole.Instance().m_Profession,PlayerRole.Instance().m_Gender,false,FashionData.id,PlayerRole.Instance().m_Equips, nil, 0.75)
    Model:RegisterOnLoaded(OnModelLoaded)
end

local function refreshRight(dress_info)
    local statusText = ConfigManager.getConfig("statustext")
    fields.UILabel_FashionDes.text = dress_info.introduction
    local text = ""
    for i,v in pairs(dress_info.propertylist) do
        local itemText = ""
        itemText = itemText..statusText[v.propertytype].text .. ' '
        itemText = itemText..(v.value>=0 and '+' or '-')
        itemText = itemText..mathutils.GetAttr(v.value,statusText[v.propertytype].displaytype)
        text = text .. itemText..'\n'
    end
    if dress_info.remaintime then
        if dress_info.remaintime <=0 then
            text = text .. LocalString.FashionText.Eternity .. '\n'
        else
            local textRemainTime = ""

            local RemainTime = TimeUtils.getDateTime(dress_info.remaintime)
            textRemainTime = string.format(LocalString.FashionText.Limited,RemainTime.days,RemainTime.hours,RemainTime.minutes)
            text = text .. textRemainTime .. '\n'
        end
    end
    fields.UILabel_FashionAttr.text = text
end

local function refreshGet(dress_info)
    if dress_info.gainfunction == cfg.equip.GetDressFunction.MONEY then
        fields.UIGroup_Go.gameObject:SetActive(false)
        fields.UIGroup_Buy.gameObject:SetActive(true)
        if dress_info.viplimit.level > 0 then
            fields.UILabel_VIP.text = string.format(LocalString.FashionText.BuyText,dress_info.viplimit.level)
        else
            fields.UILabel_VIP.text = LocalString.FashionText.BuyDressDirectly
        end
        fields.UILabel_Cost.text = dress_info.price.amount
        fields.UILabel_GetFashion.text = LocalString.FashionText.Buy
        fields.UISprite_MoneyBG.gameObject:SetActive(true)
		fields.UIButton_GetFashion.gameObject:SetActive(true)
        fields.UIButton_GetFashion.isEnabled = (dress_info.state == 0) or (dress_info.remaintime and dress_info.remaintime>0)
    elseif dress_info.gainfunction == cfg.equip.GetDressFunction.ACTIVITY then
        fields.UIGroup_Buy.gameObject:SetActive(true)
        fields.UISprite_MoneyBG.gameObject:SetActive(false)
        fields.UIGroup_Go.gameObject:SetActive(false)
        fields.UILabel_VIP.text = dress_info.gainpage
		fields.UIButton_GetFashion.gameObject:SetActive(false)
		
    elseif dress_info.gainfunction == cfg.equip.GetDressFunction.PAGE then
        fields.UIGroup_Go.gameObject:SetActive(true)
        fields.UIGroup_Buy.gameObject:SetActive(false)
        fields.UISprite_MoneyBG.gameObject:SetActive(false)
        fields.UILabel_GetFashion.text = LocalString.FashionText.Go
    end
    -- if FashionState>0 and  or dress_info.gainfunction == cfg.equip.GetDressFunction.ACTIVITY then
    --     fields.UIButton_GetFashion.gameObject:SetActive(false)
    -- else
    --     fields.UIButton_GetFashion.gameObject:SetActive(true)
    -- end
end

local function show(params)
    fields.UILabel_TitleName.text = LocalString.FashionText.RoleFashions
end

local function hide()
    if Model then Model:remove() Model=nil end
end

local function update()
    if Model and Model.m_Object then
        Model.m_Avatar:Update()
    end
end

local function SetBuyFunc(dress_info)
    EventHelper.SetClick(fields.UIButton_GetFashion,function()
        if dress_info.quickbuy then
            local validate,info=CheckCmd.CheckData({data=dress_info.viplimit})
            local validate1,info1=CheckCmd.CheckData({data=dress_info.price})
            if validate and validate1 then
                uimanager.ShowAlertDlg({immediate = true,content = LocalString.FashionText.BuyDress,
                callBackFunc = function() network.send(lx.gs.dress.CBuyDress{dresskey=dress_info.id}) end
            })
            else
                if not validate then
                    uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.FashionText.VipRequire})
                else
                    uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.FashionText.MoneyRequire})
                end
            end
        else
            -- printyellow("dress_info",dress_info.gainpage,type(dress_info.gainpage))
            uimanager.showdialog(dress_info.gainpage)
        end
    end)
end

local function LoadDetailInfo()
    if FashionData then
        refreshGet(FashionData)
        refreshRight(FashionData)
        if FashionState==0 then
            fields.UIButton_FashionEquip.gameObject:SetActive(false)
            if FashionData.gainfunction ~= cfg.equip.GetDressFunction.ACTIVITY then
                fields.UIButton_GetFashion.gameObject:SetActive(true)
            end
            SetBuyFunc(FashionData)
        else
            if FashionData.remaintime and FashionData.remaintime>0 then
                if FashionData.gainfunction ~= cfg.equip.GetDressFunction.ACTIVITY then
                    fields.UIButton_GetFashion.gameObject:SetActive(true)
                end
                SetBuyFunc(FashionData)
            else
				fields.UILabel_GetFashion.text = LocalString.Ride_HavePurchased
                fields.UIButton_GetFashion.isEnabled = false
				  
            end
            fields.UIButton_FashionEquip.gameObject:SetActive(true)
            if FashionState == 1 then
                fields.UILabel_FashionEquip.text = LocalString.FashionText.Equip
            else
                fields.UILabel_FashionEquip.text = LocalString.FashionText.Unequip
            end
        end

        EventHelper.SetClick(fields.UIButton_FashionEquip,function()
            if FashionState == 0 then
                --btn not shown
            elseif FashionState == 1 then
                network.send(lx.gs.dress.CActiveDress({dresskey=FashionData.id}))
            elseif FashionState == 2 then
                network.send(lx.gs.dress.CDeActiveDress({}))
            end
        end)
        RefreshModel()
    else

    end
end

local function second_update()
    if FashionData and FashionData.remaintime and FashionData.remaintime > 0 then
        -- refreshGet(FashionData)
        refreshRight(FashionData)
    end
end

local function DisplayOneFashionItem(item,fashion,idx)
    for i,v in pairs(states) do
        local labelState = item.gameObject.transform:Find(v)
        labelState.gameObject:SetActive(false)
    end
    local colorName = ColorUtils.GetQualityColorText(fashion.quality,fashion.name)
    item:SetText("UILabel_FashionName",colorName)
    if fashion.icon and fashion.icon ~="" then
        local texture = item.Controls["UITexture_Ride"]
        texture:SetIconTexture(fashion.icon)
    end
    if fashion and opItemId then

        if fashion.id == opItemId then
            item.Checked = true
            local UIToggle = item:GetComponent("UIToggle")
            UIToggle:Set(true)
        else
            item.Checked = false
            local UIToggle = item:GetComponent("UIToggle")
            UIToggle:Set(false)
        end
    end
    local spriteQuality = item.Controls["UISprite_RideQuality"]
    local quality = ColorUtil.GetQualitySprite(fashion.quality)
    spriteQuality.spriteName = quality
    item.Data = fashion
    local sprite = item.Controls["UISprite_Warning"]
    if fashion.state == 0 or not fashion.isNew then
        sprite.gameObject:SetActive(false)
    else
        sprite.gameObject:SetActive(true)
    end
    local stateIcon = item.gameObject.transform:Find(states[fashion.state+1])
    stateIcon.gameObject:SetActive(true)
    EventHelper.SetClick(item,function()
        FashionData = fashion
        FashionState = fashion.state
        selectedIndex = item.Index
        LoadDetailInfo()
    end)
end

local function OnItemInit(UIListItem,wrapIndex,realIndex)
    local mail = FashionInfo[realIndex]
    DisplayOneFashionItem(UIListItem,mail,realIndex)
end

local function InitList(num)
    local wrapContent=fields.UIList_Fashion.gameObject:GetComponent("UIWrapContentList")
    if wrapContent==nil then
        return
    end

    EventHelper.SetWrapListRefresh(wrapContent,OnItemInit)
    wrapContent:SetDataCount(num)
end

local function DisplayAllFashions()
    InitList(#FashionInfo)
    local defaultItem = fields.UIList_Fashion:GetItemByIndex(FashionManager.GetDressIndexById(opItemId)-1)
    if defaultItem then
        FashionData = defaultItem.Data
        FashionState = FashionData.state
    else
        FashionData = nil
    end
    LoadDetailInfo()
end


local function refresh(param)
    FashionInfo = FashionManager.GetFashions()
    opItemId = type(param)=="number" and param or FashionInfo[1].id
    DisplayAllFashions()
end

local function showdialog(params)
    show(params)
end

local function init(oname,ogameObject,ofields)
    name, gameObject, fields = oname,ogameObject,ofields
    fields.UILabel_VIP.gameObject:SetActive(not shouldHideVip())
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    second_update = second_update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    RotateModel = RotateModel,
}
