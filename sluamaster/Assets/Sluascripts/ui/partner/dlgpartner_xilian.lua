local unpack                = unpack
local print                 = print
local uimanager             = require"uimanager"
local ConfigManager         = require"cfg.configmanager"
local network               = require"network"
local BagManager            = require"character.bagmanager"
local PetManager            = require"character.pet.petmanager"
local mathutils             = require"common.mathutils"
local CheckCmd              = require"common.checkcmd"
local EventHelper            = UIEventListenerHelper
local ItemManager           = require"item.itemmanager"
local gameObject,name,fields
local StatusText
local listeners
local washed
local pet
local washYuanBao
local CfgWash
local ItemID = 10400013
local uiList_Attributes
local washattrs
local internaltime = 1
local temp = 0
local cdover = true

local colorUp = "[9afe19]+"
local colorDown = "[fa4926]-"

local function destroy()

end

local function hide()
    pet.LastWashRecord = {}
end

local function SwitchCheckBox()
    fields.UIToggle_Checkbox01:Set(not washYuanBao)
    fields.UIToggle_Checkbox02:Set(washYuanBao)
end

local function show(params)
    pet = params
    washYuanBao = false
    local pos = gameObject.transform.localPosition
    gameObject.transform.localPosition = Vector3(pos.x,pos.y,-1000)
end

local function refresh(params)
    washed = PetManager.HasWashed(pet)
    SwitchCheckBox()
    local petAttr = PetManager.GetAttributes(pet)
    local washedAttr = PetManager.GetWashTotalAttributes(pet)
    local deltaAttr = {}
    for _,v in ipairs(PetManager.BaseAttr) do
        deltaAttr[v.idx] = (washedAttr[v.idx] or 0)-(petAttr[v.idx] or 0)
    end
    for i,v in ipairs(PetManager.BaseAttr) do
        local currentItem = uiList_Attributes[i]

        local demonminater = mathutils.GetAttr(pet.WashMaxValues[v.idx] or 1,StatusText[v.idx].displaytype)
        local molecure =  mathutils.GetAttr(pet.WashCurrValues[v.idx] or 0,StatusText[v.idx].displaytype)
        local svalue = (pet.WashCurrValues[v.idx] or 0) / (pet.WashMaxValues[v.idx] or 1)
        currentItem.sliderAttr.value = svalue
        currentItem.labelValue.text = molecure .. '/' .. demonminater
        if washed then
            currentItem.labelUp.gameObject:SetActive(true)
            -- if (deltaAttr[v.idx] or 0) > 0 then
            --     -- currentItem.labelUp.gameObject:SetActive(true)
            --     currentItem.labelUp.text = '+' .. mathutils.GetAttr(deltaAttr[v.idx],StatusText[v.idx].displaytype)
            -- elseif (deltaAttr[v.idx] or 0) < 0 then
            --     -- currentItem.labelDown.gameObject:SetActive(true)
            --     currentItem.labelUp.text = '-' .. mathutils.GetAttr(deltaAttr[v.idx],StatusText[v.idx].displaytype)
            -- end
            local textAttr = deltaAttr[v.idx] >= 0 and colorUp or  colorDown

            currentItem.labelUp.text = textAttr .. mathutils.GetAttr(math.abs(deltaAttr[v.idx]),StatusText[v.idx].displaytype) .. '[-]'
        else
            currentItem.labelUp.gameObject:SetActive(false)
            -- currentItem.labelDown.gameObject:SetActive(false)
        end
    end
    local itemCnt = BagManager.GetItemNumById(ItemID)
    fields.UILabel_Amount03.text = tostring(itemCnt) .. '/'  .. '1'
    fields.UILabel_Amount04.text = tostring(itemCnt) .. '/'  .. '1'
    if washed then
        fields.UILabel_Wash1.text = LocalString.PartnerText.Cancel
        fields.UILabel_Wash10.text = LocalString.PartnerText.Sure
    else
        fields.UILabel_Wash1.text = LocalString.PartnerText.Wash1
        fields.UILabel_Wash10.text = LocalString.PartnerText.Wash10
    end

end

local function varrefresh()
    refresh()
end


local function update()
	if not cdover then
		temp = temp + Time.unscaledDeltaTime
		if temp >= internaltime then
			temp = 0
			cdover = true
		end
	end
end

local function uiInit()
    uiList_Attributes = {}
    fields.UIList_WashProperty:Clear()

    for i,v in ipairs(PetManager.BaseAttr) do
        local item                  = fields.UIList_WashProperty:AddListItem()
        local labelName             = item.Controls["UILabel_Name"]
        local labelValue            = item.Controls["UILabel_Value"]
        local labelUp               = item.Controls["UILabel_Up"]
        local sliderAttr            = item.Controls["UISlider_SlideBackground01"]
        -- local labelDown             = item.Controls["UILabel_Down"]
        uiList_Attributes[i]        = {}
        uiList_Attributes[i].item   = item
        uiList_Attributes[i].labelValue = labelValue
        uiList_Attributes[i].sliderAttr = sliderAttr
        labelName.text              = StatusText[v.idx].text .. ':'
        uiList_Attributes[i].labelUp= labelUp
        -- uiList_Attributes[i].labelDown = labelDown
        labelUp.gameObject:SetActive(false)
        -- labelDown.gameObject:SetActive(false)
    end
    local washcostamount1 = CfgWash[cfg.pet.PetWash.WASH_XUNIBI_KEY].cost.conditions[2].amount
    local washcostamount2 = CfgWash[cfg.pet.PetWash.WASH_YUANBAO_KEY].cost.conditions[2].amount
	--local washconstmount3 = CfgWash[cfg.pet.PetWash.COST_ITEM_ID].cost.conditions[1].amount
    fields.UILabel_Amount01.text = tostring(washcostamount1)
    fields.UILabel_Amount02.text = tostring(washcostamount2)
	--fields.UILabel_Amount03.text = tostring(washconstmount3)
	--fields.UILabel_Amount04.text = tostring(washconstmount3)

end



local function init(params)
    name,gameObject,fields = unpack(params)
    StatusText = ConfigManager.getConfig("statustext")
    CfgWash = ConfigManager.getConfig("petwash")
    uiInit()
    EventHelper.SetClick(fields.UIButton_Close,function()
        uimanager.hide(name)
    end)

    EventHelper.SetClick(fields.UIButton_Wash1,function()
		
		if cdover then
			local washtp = washYuanBao and cfg.pet.PetWash.WASH_YUANBAO_KEY or cfg.pet.PetWash.WASH_XUNIBI_KEY
			local currencytype = washYuanBao and cfg.currency.CurrencyType.YuanBao or cfg.currency.CurrencyType.XuNiBi
			
			if washed then
				PetManager.RequestCancelWash(pet.ConfigId)
			else
				for _,v in pairs(CfgWash[washtp].cost.conditions) do
					local validate,info = CheckCmd.CheckData{data=v,num=1}
					if not validate then
						if v.class == 'cfg.cmd.condition.OneItem' then
							ItemManager.GetSource(v.itemid,name)
						else
							ItemManager.GetSource(currencytype,name)
						end
						return
					end
				end
				PetManager.RequestWash(pet.ConfigId,washtp,false)
			end
		end	
       cdover = false
    end)

    EventHelper.SetClick(fields.UIButton_Wash10,function()
		if cdover then
			local washtp = washYuanBao and cfg.pet.PetWash.WASH_YUANBAO_KEY or cfg.pet.PetWash.WASH_XUNIBI_KEY
			local currencytype = washYuanBao and cfg.currency.CurrencyType.YuanBao or cfg.currency.CurrencyType.XuNiBi
			if washed then
				PetManager.RequestConfirmWash(pet.ConfigId)
			else
				for _,v in pairs(CfgWash[washtp].cost.conditions) do
					local validate,info = CheckCmd.CheckData{data=v,num=10}
					if not validate then
						if v.class == 'cfg.cmd.condition.OneItem' then
							ItemManager.GetSource(v.itemid,name)
						else
							ItemManager.GetSource(currencytype,name)
						end
						return
					end
				end
				PetManager.RequestWash(pet.ConfigId,washtp,true)
			end
		end
		cdover = false
    end)

    EventHelper.SetClick(fields.UIToggle_Checkbox01,function()
        washYuanBao = false
        SwitchCheckBox()
    end)

    EventHelper.SetClick(fields.UIToggle_Checkbox02,function()
        washYuanBao = true
        SwitchCheckBox()
    end)

end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    destroy                 = destroy,
    update                  = update,
    hide                    = hide,
    show                    = show,
    init                    = init,
    refresh                  = refresh,
    varrefresh              = varrefresh,
    uishowtype              = uishowtype,
}
