local unpack            = unpack
local print             = print
local format            = string.format
local math              = math
local EventHelper       = UIEventListenerHelper
local gameevent         = require"gameevent"
local UIManager         = require("uimanager")
local network           = require("network")
local LimitTimeManager = require("limittimemanager")
local BagManager = require "character.bagmanager"
local PlayerRole = require "character.playerrole"
local ConfigManager = require "cfg.configmanager"
local ShopManager = require "shopmanager"
local CarryShopManager = require "ui.carryshop.carryshopmanager"


local gameObject
local name
local fields

local curUseItem
local isUseItem = false

local function destroy()
end

local function show(params)
end

local function hide()
end

local function SetItemIcon()
	--printyellow("SetHPIcom")
	local items1 = BagManager.GetHPItem()
	local items2 = BagManager.GetMPItem()
	if #items1 == 0 then
		fields.UITexture_HPTips:SetIconTexture("")
		fields.UILabel_HPTips.gameObject:SetActive(true)     --显示“血瓶不足”
		fields.UILabel_HPTips.text = LocalString.HPTip_NotEnough
	--[[elseif #items2 == 0 then
		fields.UITexture_HPTips:SetIconTexture("")
		fields.UILabel_HPTips.gameObject:SetActive(true)     --显示“蓝药不够”
		fields.UILabel_HPTips.text = LocalString.MPTip_NotEnough--]]
	else
		fields.UILabel_HPTips.gameObject:SetActive(false)    --不显示“药瓶不够”
		local item = items1[1]
		fields.UITexture_HPTips:SetIconTexture(item:GetRoundIconName())

	end
end

local function update()
	if LimitTimeManager.GetCoolDownTip() then
		local items = BagManager.GetHPItem()
		local item  = items[1]
		if item then
			local cdData = item.CDData
			fields.UISlider_TipHP_CD.gameObject:SetActive(true)
			fields.UISlider_TipHP_CD.value = cdData:GetCDRatio()
			if cdData:IsReady() then
				SetItemIcon()
				LimitTimeManager.SetCoolDownTip(false)
				fields.UISlider_TipHP_CD.gameObject:SetActive(false)
			end
		end
	end
end

local function refresh()
    SetItemIcon()
end


local function init(iName,iGameObject,iFields)
    name            = iName
    gameObject      = iGameObject
    fields          = iFields
	  gameevent.evt_cdchange:add(refresh)
	  fields.UISlider_TipHP_CD.gameObject:SetActive(false)
	  SetItemIcon()
	  EventHelper.SetClick(fields.UIButton_HPTips,function()
		    local items = BagManager.GetHPItem()
		    --local items1 = BagManager.GetMPItem()
		    if #items ~= 0 then
		        local item = items[1]
					local cdData =item:GetCDData()
					if not cdData:IsReady() then
				        UIManager.ShowSystemFlyText(LocalString.Bag_ItemCDNotReady)
				        return
            		end
		        if  cdData:IsReady() then
					curUseItem = item
					BagManager.SendCUseItem(item.BagPos,1)
				end
		    else
		        local TeamManager = require("ui.team.teammanager")
		        if (TeamManager.IsForcedFollow() ~= true) then  --非强制跟随    
					--快速商店
					CarryShopManager.NavigateToCarryShopNPC()
            	end
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
}
