local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local PlayerRole=require"character.playerrole"
local ConfigManager=require"cfg.configmanager"
local PetManager = require"character.pet.petmanager"
local mathutils = require"common.mathutils"
local ItemManager = require"item.itemmanager"
local gameObject
local name
local fields

local oringinalPos
local oringinalOffsetY

local uigrid1
local uigrid2

local attainedPets
local unattainedPets
local ItemPetMap
local delayTime
local CurrentShowType
local petsList
local showPetsList
local pairPetsData
local newPetEffect
local ShowType = enum{
    "ATTACK=1",
    "DEFENCE=2",
    "ASSIST=4",
    "ALL=7",
}

local PetTypeIcons = {
    [cfg.pet.PetType.GONGJI] = "Sprite_Attack",
    [cfg.pet.PetType.FANGYU] = "Sprite_Defense",
    [cfg.pet.PetType.FUZHU] = "Sprite_Auxiliary",
}

local function GetShowType(pettype)
    return bit.lshift(1,pettype)
end

local function InsertToPetsList(tb,pet,type)
    if bit.band(type,GetShowType(pet.ConfigData.pettype)) >0 then
        table.insert(tb,pet)
    end
end

local function GetPetsList(aPets,type)
	print("GetPetsList")
    local ret = {}
    for _,pet in ipairs(aPets) do
        if not PetManager.IsBattlePet(pet.ConfigId) then
            InsertToPetsList(ret,pet,type)
        end
    end
    return ret
end

local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")
local ShowTypeList = {ShowType.ALL,ShowType.ATTACK,ShowType.DEFENCE,ShowType.ASSIST}

local function hide()

end


local function ShowAPet(item,pet,idx)
    if not pet then item.gameObject.transform.localScale = Vector3.zero return
    else item.gameObject.transform.localScale = Vector3.one
    end
    -- local item          = fields.UIList_Partner:AddListItem()
    -- ItemPetMap[item.m_nIndex] = pet
    -- local item          = fields.UIList_Partner02:AddListItem()
    local textureIcon   = item.Controls["UITexture_Partner02"]
    local labelName     = item.Controls["UILabel_Name"]
    local spriteType    = item.Controls["UISprite_Type"]
    local sliderAmount  = item.Controls["UISlider_Amount"]
    local labelAmount   = item.Controls["UILabel_CanCall"]
    local btnAdd        = item.Controls["UIButton_Add"]
    local spriteTip     = item.Controls["UISprite_Tips2"]
    spriteTip.gameObject:SetActive(PetManager.CanCall(pet))
    spriteType.spriteName = PetTypeIcons[pet.ConfigData.pettype]
    PetManager.SetItemPetColor(item,pet.ConfigId)
    textureIcon:SetIconTexture(pet.ConfigData.icon)
    labelName.text      = pet:GetColorName()
    local fragmentid    = pet.ConfigData.fragmentid
	
   
    local CfgFragment   = ConfigManager.getConfigData("petfragment",fragmentid)
	if  CfgFragment then
		local total         = CfgFragment.number
		local amount        = PetManager.GetFragmentNum(fragmentid)
		if amount >=total then
			sliderAmount.value = 1
			labelAmount.text = LocalString.PartnerText.CanCall
		else
			sliderAmount.value = amount/total
			labelAmount.text = tostring(amount) .. '/' .. tostring(total)
		end
		if amount >= total then
			EventHelper.SetClick(btnAdd,function()
				--printyellow("idx = ",idx)
                for index, pet1 in pairs(unattainedPets) do
                    if pet.ConfigId == pet1.ConfigId then
                        PetManager.RequestCallPet(index)
                        return
                    end
                end
			end)
		else
			EventHelper.SetClick(btnAdd,function()
				ItemManager.GetSource(pet.ConfigData.fragmentid,name)
			end)
		end
	else
		 printyellow("fragmentid",fragmentid,pet.ConfigData.name)
	end
	
end

local function PetItemInit(go,index,realIndex)
    local item = go:GetComponent("UIListItem")
    ShowAPet(item,petsList[realIndex+1],realIndex+1)
end

local function ResetPetList()

    local wrapContent = fields.UIList_Partner.gameObject:GetComponent("UIGridWrapContent")
    -- printyellow("#petsList",#petsList)

    wrapContent.minIndex = -(mathutils.Round((#petsList)/2))
    wrapContent.maxIndex = 0
    EventHelper.SetWrapContentItemInit(wrapContent,PetItemInit)

    fields.UIScrollView_Partner.currentMomentum = Vector3(0,0,0)
    local content = fields.UIList_Partner.gameObject:GetComponent("UIGridWrapContent")
    --bagWrapContent:ResetChildPositions()
    content:ResetAllChildPositions()
    local bagPanel =  fields.UIScrollView_Partner.gameObject:GetComponent("UIPanel")
    bagPanel.transform.localPosition = oringinalPos
    bagPanel:SetClipOffsetY(oringinalOffsetY)
    content.firstTime = true
    content:WrapContent()

    fields.UIScrollView_Partner.gameObject:SetActive(false)
    fields.UIScrollView_Partner.gameObject:SetActive(true)



end

local function InitPetList()
    if fields.UIList_Partner.Count == 0 then
        for i = 1,14 do
            local item = fields.UIList_Partner:AddListItem()
        end
        local wrapContent = fields.UIList_Partner.gameObject:GetComponent("UIGridWrapContent")
        wrapContent.minIndex = 1
        wrapContent.maxIndex = 0
        EventHelper.SetWrapContentItemInit(wrapContent,PetItemInit)
    end
end

--local function RefreshPetInfo()
--    local wrapContent = fields.UIList_Partner.gameObject:GetComponent("UIGridWrapContent")
--    wrapContent.firstTime = true
--    wrapContent:WrapContent()
--end

local function refresh()
    print("unattainedPets refresh")
    unattainedPets          = PetManager.GetSortedUnAttainedPets()--��ȡδȡ�û����б�
    petsList                = GetPetsList(unattainedPets,CurrentShowType)
    ResetPetList()
    --RefreshPetInfo()
end

local function show()
    CurrentShowType = ShowType.ALL
    unattainedPets = {}
    petsList = {}
    InitPetList()
end

local function destroy()
    fields = nil
end

local function update()

end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    name,gameObject,fields = unpack(params)

    oringinalPos = fields.UIScrollView_Partner.gameObject.transform.localPosition
    oringinalOffsetY =  fields.UIScrollView_Partner.gameObject:GetComponent("UIPanel"):GetClipOffsetY()

    EventHelper.SetListClick(fields.UIList_ShowTypes,function(item)
        -- local idx = item.m_nIndex
        local newType = ShowTypeList[item.m_nIndex+1]
        if newType ~= CurrentShowType then
            CurrentShowType = newType
            refresh()
        end
    end)

    EventHelper.SetClick(fields.UIButton_SkinShop,function()
        uimanager.showdialog("dlgfashion",{pet=pet,fashiontype="pet"})
    end)

    EventHelper.SetClick(fields.UIButton_PartnerEmbattle,function()
        uimanager.show("partner.dlgpartner_assist")
    end)

end



return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    varrefresh = varrefresh,
    uishowtype = uishowtype,
    RefreshScrollPos = RefreshScrollPos,
}
