local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local ItemEnum = require("item.itemenum")
local ItemIntroduct = require("item.itemintroduction")
local ItemManager = require("item.itemmanager")

local gameObject
local name
local fields

local gRewardList = { }

local function destroy()
	-- print(name, "destroy")
end

-- 设置按钮(说明和领取按钮)
local function SetButtons(buttons)
	if buttons then
		-- 清理按钮
		fields.UIList_Button:Clear()
		-- 重新排列按钮
		for index, buttonData in ipairs(buttons) do
			local buttonListItem = fields.UIList_Button:AddListItem()
			buttonListItem:SetText("UILabel_ButtonName", buttonData.text)
            if buttonData.Enable ~= nil then
                buttonListItem.Enable = buttonData.Enable
            end
			EventHelper.SetClick(buttonListItem, function()
				buttonData.callBackFunc()
			end )
		end
	end
end

local function RankListItemRefresh(listItem, wrapIndex, realIndex)

	local rewardItem = gRewardList[realIndex]
	-- icon
	listItem:SetIconTexture(rewardItem:GetTextureName())
	-- 品质颜色
	listItem.Controls["UISprite_Quality"].gameObject:SetActive(true)
	listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(rewardItem:GetQuality())

	-- 物品类型判断
	if rewardItem:GetBaseType() == ItemEnum.ItemBaseType.Item then
		listItem.Controls["UISprite_Fragment"].gameObject:SetActive(false)
		listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)

	elseif rewardItem:GetBaseType() == ItemEnum.ItemBaseType.Equipment then
		listItem.Controls["UISprite_Fragment"].gameObject:SetActive(false)
		listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(true)
        listItem:SetText("UILabel_AnnealLevel", "+" .. rewardItem:GetAnnealLevel())

	elseif rewardItem:GetBaseType() == ItemEnum.ItemBaseType.Fragment then
		listItem.Controls["UISprite_Fragment"].gameObject:SetActive(true)
		listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)

	elseif rewardItem:GetBaseType() == ItemEnum.ItemBaseType.Talisman then
		listItem.Controls["UISprite_Fragment"].gameObject:SetActive(false)
		listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)

	elseif rewardItem:GetBaseType() == ItemEnum.ItemBaseType.Pet then
		listItem.Controls["UISprite_Fragment"].gameObject:SetActive(false)
		listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
	else
		logError("Item type error")
	end
	-- 绑定类型
	listItem.Controls["UISprite_Binding"].gameObject:SetActive(rewardItem:IsBound())
	-- 设置数量
	listItem:SetText("UILabel_Amount",rewardItem:GetNumber())

	-- 名字和介绍
	--listItem:SetText("UILabel_ItemName",rewardItem:GetName())
	--listItem:SetTextColor("UILabel_ItemName",colorutil.GetQualityColor(rewardItem:GetQuality()))
	listItem:SetText("UILabel_ItemName",colorutil.GetColorStr(colorutil.ColorType.Red_Award,rewardItem:GetName()))
	listItem:SetText("UILabel_ItemIntroduce",rewardItem:GetIntroduction())

	EventHelper.SetClick(listItem,function()


		local params={item=rewardItem,buttons={{display=false,text="",callFunc=nil},{display=false,text="",callFunc=nil}}}
		ItemIntroduct.DisplayBriefItem(params)

		--ItemIntroduct.DisplayItem( {
		--	item = rewardItem,
		--	variableNum = false,
		--	buttons =
		--	{
		--		{ display = false, text = "", callFunc = nil },
		--		{ display = false, text = "", callFunc = nil },
		--		{ display = false, text = "", callFunc = nil }
		--	}
		--} )
	
	
	end)

end

local function RefreshRewardList(gRewardList)
	local wrapList = fields.UIList_ItemShow.gameObject:GetComponent("UIWrapContentList")
	EventHelper.SetWrapListRefresh(wrapList, RankListItemRefresh)
	wrapList:SetDataCount(#gRewardList)
	wrapList:CenterOnIndex(0)
end

local function show(params)
	-- print(name, "show")

	fields.UILabel_Title.text = params.title
	SetButtons(params.buttons)
    gRewardList = { }
	gRewardList = params.items
	RefreshRewardList(gRewardList)

end

local function hide()
	-- print(name, "hide")
	
end

local function update()
	-- print(name, "update")
end

local function refresh(params)
	-- print(name, "refresh")
end


local function init(params)
	-- name, gameObject, fields = unpack(params)
	fields = params

end

return {
	init = init,
	show = show,
	hide = hide,
	update = update,
	destroy = destroy,
	refresh = refresh,
}