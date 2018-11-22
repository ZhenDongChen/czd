local unpack = unpack
local print = print
local VoiceManager = VoiceManager
local EventHelper = UIEventListenerHelper

local uimanager = require("uimanager")
local network = require("network")
local login = require("login")
local NPC = require("character.npc")
local Player = require"character.player"
local ConfigManager = require "cfg.configmanager"
local BonusManager = require("item.bonusmanager")
local define = require "define"
local PlayerRole = require "character.playerrole"
local LimitManager = require "limittimemanager"
local VipChargeManager = require "ui.vipcharge.vipchargemanager"
local CgManager = require "ui.cg.cgmanager"
local TalismanModel = require("character.talisman.talisman")
local ItemManager 	= require("item.itemmanager")
local OperationActivityManager  = require("ui.operationactivity.operationactivitymanager")

local fields
local gameObject
local name



local function RefreshRewardItem(params)
    local groupData = OperationActivityManager.GetActivityGroup(params.groupid)
    local itemData = groupData:GetActivityItem(params.itemid)
    fields.UIList_Rewards:Clear()
    fields.UILabel_Level.text = tostring(itemData.m_Config.condition.num)
    if itemData.m_Config.condition.num == 60 then
        fields.UILabel_Next.gameObject:SetActive(false)
    else
        fields.UILabel_Next.gameObject:SetActive(true)
        fields.UILabel_NextLevel.text = itemData.m_Config.condition.num + 10
    end
    for _,item in pairs(itemData:GetRewards()) do
        local listItem=fields.UIList_Rewards:AddListItem()
        BonusManager.SetRewardItem(listItem,item)
    end
end



local function show(params)

    RefreshRewardItem(params)
    EventHelper.SetClick(fields.UIButton_GetBonus, function ()
        OperationActivityManager.ReceiveActivityBonus(params.groupid, params.itemid)
        uimanager.hidedialog("operationactivity.dlgnewserverlevelbonus")
    end)

end

local function hide()

end


local function refresh()



end



local function destroy()



end

local function update()

end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    name, gameObject, fields = unpack(params)

    fields.UITexture_AD:SetIconTexture("NewServerLevelBonous")

    EventHelper.SetClick(fields.UIButton_Return,function ()
        uimanager.hidedialog("operationactivity.dlgnewserverlevelbonus")
    end)




end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
}
