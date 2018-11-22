local colorutil = require("common.colorutil")
local format             = string.format
local EventHelper       = UIEventListenerHelper
local SystemFlyTextList = {}
local NewSystemTextList = {}
local NewSystemTextNumber = {}

local offset = 0
local ItemFlyTime = 0.5
local ThisGameObject 


local function TweeenFinshed(params)
	if params ~= nil then
		printyellow("dasdasdas")
		local listitem = params:GetComponent(UIListItem)
		--TODO��ֹlistitemΪ0��Ҫȥ��ɾ������
		--local UIListItemsCount = listitem.Parent:GetComponent(UIList)
			--if tonumber(UIListItemsCount) ~= nil and tonumber(UIListItemsCount)  > 1 then
				--GameObject:Destroy(listitem.gameObject)
				listitem.Parent:DelListItem(listitem)
			--end
		
		table.remove(NewSystemTextList,1);
	end

end

local function SynIteminfo(newItem)
	
	--TODOÿ�λ�ȡList��Ҫ����Get��Vip��ֵ�Ļ���֣���������ò�����
	--printyellow(">>>>>>��Ӷ���SynIteminfo")
	local tempUIList_FlyTextItemInfoGameObject =  ThisGameObject.transform:Find("Panel_SystemInfo/UIList_FlyTextItemInfo")
	
	local tempUIList_FlyTextItemInfo = tempUIList_FlyTextItemInfoGameObject:GetComponent(UIList)
	if tempUIList_FlyTextItemInfo ~= nil then
		CurrentItem = tempUIList_FlyTextItemInfo:AddListItem()
		local temptween = CurrentItem.gameObject:GetComponent("TweenPosition")
		
		EventHelper.SetTweenPositionOnfinshed(temptween,TweeenFinshed);
		local label = CurrentItem.Controls["UILabel_FlyText"]
		local quatityicon = CurrentItem.Controls["UISprite_QuatityIcon"]
		local UITexture_ItemIcon = CurrentItem.Controls["UITexture_ItemIcon"]
		
		--TODO������������Ʒ���ֶβ�һ��
		local currenctquality = 0
		if newItem.ConfigData.quality == nil then
			currenctquality =  newItem.ConfigData.basiccolor
		else
			currenctquality = newItem.ConfigData.quality
		end
		
		label.text = format(LocalString.NewFlyText_Reward,colorutil.GetQualityColorText(currenctquality,newItem.ConfigData.name), tostring(NewSystemTextNumber[newItem.ConfigData.name]))
		quatityicon.spriteName =colorutil.GetQualitySprite(currenctquality)
		UITexture_ItemIcon:SetIconTexture(newItem.ConfigData.icon)
		table.insert(NewSystemTextList,TempItem)
		table.remove(NewSystemTextNumber,1)
	else
		printyellow(">>>>>>���Icon����ʧ��AddSynIteminfo Fail ")
	end

end

local function AddSyncItem(item,tempgetnumber)
	
	local TempItem = nil
	--TODOͳһ��Ʒ���ֶ�
	if #item > 0 then
		if item[1] ~= nil and item[1].ConfigData.name ~= nil then
			TempItem = item[1]
			table.insert(SystemFlyTextList,TempItem)
		else
			printyellow("this item is error")
			return;
		end
	else
		TempItem = item
		table.insert(SystemFlyTextList,TempItem)
	end
	
	local ItemNum  = 1
	--TODO ��ÿһ����Ʒ�ı仯����ӵ�List����
	if tempgetnumber == nil then
		NewSystemTextNumber[TempItem.ConfigData.name] = TempItem:GetNumber()
	else
		NewSystemTextNumber[TempItem.ConfigData.name] = tempgetnumber
	end
	
	--SynIteminfo(TempItem, ItemNum)
	if #NewSystemTextList > 5 then
		for i = 1, table.getn(NewSystemTextList) do
			NewSystemTextList[i].duration = 1
			ItemFlyTime = 0.2
		end
	else
		ItemFlyTime = 0.5
	end
	
end


--TODO Ϊ�˱�����һ֡��ʱ��ӽ�ȥ�˶���������еĶ��󶼻��ص���һ�����
local function update()
	if #SystemFlyTextList  > 0 then
		offset = offset + Time.deltaTime
		if offset > ItemFlyTime then
			offset = 0
			SynIteminfo(SystemFlyTextList[1])
			table.remove(SystemFlyTextList,1)
		end
		
	end
end


local function hide()
	
end

local function init(params)
	name,gameObject,fields = unpack(params)
	
end

local function refresh()
	ThisGameObject = GameObject.Find("/UI Root (2D)/UI_Root/dlgdynamicflyitem")
end

local function show()
	
end

return
{
	init = init,
	refresh = refresh,
	update = update,
	hide = hide,
	show = show,
	AddSyncItem = AddSyncItem,

}