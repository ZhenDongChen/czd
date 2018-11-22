local unpack          = unpack
local EventHelper     = UIEventListenerHelper
local ConfigManager   = require("cfg.configmanager")
local UIManager       = require("uimanager")
local EventHelper     = UIEventListenerHelper
local gameObject
local fields
local name
local oldattr
local oldattr
local seconds   
local UpgradeAttributesList={}
local FirstTime = 0
local AttributesTtemTime = 0.18
local IsLastOne = false

local function GetStatusTextById(d)
	local statustext = ConfigManager.getConfig("statustext")
	for _,k in pairs(statustext) do
		if k.attrtype == d then
			return k 
		end
	end
	return nil
end

local function TweeenFinshed(params)
	local targetGameObject = params
	local listitem = targetGameObject:GetComponent(UIListItem)
	listitem.Parent:DelListItem(listitem)
end


local function SetItemInfo(attrid)
	local list_item
	local status = GetStatusTextById(attrid)
	list_item = fields.UIList_Attribute:AddListItem() 
	local temptween = list_item.gameObject:GetComponent("TweenPosition")
	if temptween ~= nil then
		temptween:ResetToBeginning()
		temptween.enabled = true
	end

	EventHelper.SetTweenPositionOnfinshed(temptween,TweeenFinshed)
	
	list_item.Controls["UILabel_Attribute"].text = status.text
	--list_item.Controls["UILabel_AttributeAmount"].text = "+".. math.floor(newattr[attrid]) or 0 
    list_item.Controls["UILabel_AttributeAmount"].text = "+".. math.floor(newattr[attrid] - oldattr[attrid])
end
local function show(params)
	printyellow("升级！！！！！")
	seconds = 18.3
	newattr = params.new_attr
	oldattr = params.old_attr
	fields.UIList_Attribute:Clear()
	-- table.insert(UpgradeAttributesList,cfg.fight.AttrId.HP_FULL_VALUE)
	-- table.insert(UpgradeAttributesList,cfg.fight.AttrId.MP_FULL_VALUE)
	-- table.insert(UpgradeAttributesList,cfg.fight.AttrId.ATTACK_VALUE_MAX)
	-- table.insert(UpgradeAttributesList,cfg.fight.AttrId.ATTACK_VALUE_MIN)
	-- table.insert(UpgradeAttributesList,cfg.fight.AttrId.DEFENCE)
	-- table.insert(UpgradeAttributesList,cfg.fight.AttrId.HIT_RATE)
	-- table.insert(UpgradeAttributesList,cfg.fight.AttrId.HIT_RESIST_RATE)
	EventHelper.SetClick(fields.UISprite_Black ,function()
		seconds = 4.3
		UIManager.hide(name)
	end)

end 

local function refresh(params)
	printyellow("升级！！！！！")
	newattr = params.new_attr
	oldattr = params.old_attr
	fields.UIList_Attribute:Clear()
	fields.UILabel_UpdateLevel.text = params.level

	table.insert(UpgradeAttributesList,cfg.fight.AttrId.HP_FULL_VALUE)
	table.insert(UpgradeAttributesList,cfg.fight.AttrId.MP_FULL_VALUE)
	table.insert(UpgradeAttributesList,cfg.fight.AttrId.ATTACK_VALUE_MAX)
	table.insert(UpgradeAttributesList,cfg.fight.AttrId.ATTACK_VALUE_MIN)
	table.insert(UpgradeAttributesList,cfg.fight.AttrId.DEFENCE)
	table.insert(UpgradeAttributesList,cfg.fight.AttrId.HIT_RATE)
	table.insert(UpgradeAttributesList,cfg.fight.AttrId.HIT_RESIST_RATE)


	-- SetItemInfo(cfg.fight.AttrId.HP_FULL_VALUE   ,oldattr,newattr)
    -- SetItemInfo(cfg.fight.AttrId.MP_FULL_VALUE   ,oldattr,newattr)
	-- SetItemInfo(cfg.fight.AttrId.ATTACK_VALUE_MAX,oldattr,newattr)
	-- SetItemInfo(cfg.fight.AttrId.ATTACK_VALUE_MIN,oldattr,newattr)
	-- SetItemInfo(cfg.fight.AttrId.DEFENCE         ,oldattr,newattr)
	-- SetItemInfo(cfg.fight.AttrId.HIT_RATE        ,oldattr,newattr)
	-- SetItemInfo(cfg.fight.AttrId.HIT_RESIST_RATE  ,oldattr,newattr)
end 

local function update()
	if #UpgradeAttributesList > 0 then
        FirstTime = FirstTime - Time.deltaTime
		if FirstTime < 0 then
			FirstTime = AttributesTtemTime
            local info=UpgradeAttributesList[1]
            table.remove(UpgradeAttributesList,1)
			SetItemInfo(info)
		end
	end
	if #UpgradeAttributesList == 1 then
		IsLastOne = true
	end
	seconds = seconds - 0.1
	if seconds <= 0 then
		seconds = 4.3
		UIManager.hide(name)
	end
end



local function hide()
	
end


local function init(params)
	name, gameObject, fields = unpack(params)
end

return {
	init = init,
	show = show,
	hide = hide,
	update = update,
	refresh = refresh,
}