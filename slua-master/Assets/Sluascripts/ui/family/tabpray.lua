local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local player = require("character.playerrole"):Instance()
local limitmgr = require("limittimemanager")
local praymgr = require("family.praymanager")
local mgr = require("family.familymanager")
local ItemManager = require("item.itemmanager")
local CheckCmd = require("common.checkcmd")


local fields
local name
local gameObject

local function showtab(params)
    uimanager.show("family.tabpray", params)
end

local function show()
end

-- local function hidetab()
-- end

local function hide()
end

local function destroy()
end

local function refresh(params)
    local leveldata = ConfigManager.getConfigData("familyinfo", mgr.Info().flevel)
    fields.UILabel_Money.text = mgr.Info().money
    fields.UILabel_Contrib.text = player:GetCurrency(cfg.currency.CurrencyType.BangGong)
    fields.UISlider_Build.value = mgr.Info().curlvlbuilddegree / leveldata.requirebuildrate
    fields.UILabel_Build.text = string.format("%d/%d", mgr.Info().curlvlbuilddegree, leveldata.requirebuildrate)

    local listpray = ConfigManager.getConfig("pray")
    for id,data in pairs(listpray) do
        local item = fields.UIList_Pray:GetItemById(id)
        if not item then return end

        local time = limitmgr.GetDayLimitTime(cfg.cmd.ConfigId.FAMILY_PRAY, id)
        local viplevel = player:GetVipLevel()+1
        if viplevel > #data.daylimit.entertimes then
            viplevel = #data.daylimit.entertimes
        end
        local limit = data.daylimit.entertimes[viplevel]
        local limitText = item.Controls["UILabel_Limit"]
        if limitText then
            item.Controls["UILabel_Limit"].text = limit > 0 and string.format("%d/%d", time, limit) or ""
        end       
        if limit <= 0 then
            item.Controls["UIButton_Pray"].isEnabled = true
        else
            item.Controls["UIButton_Pray"].isEnabled = time < limit
        end
        --item.Controls["UIButton_Pray"].isEnabled = checkcmd.CheckVipLimitsLite(data.daylimit,{moduleid=cfg.cmd.ConfigId.FAMILY_PRAY, cmdid=id})

        if id == 1 then
            item.Controls["UISprite_Warning"].gameObject:SetActive(time < limit)
        end
    end
end

-- local function update()
-- end

local function CurrencyIcon(cost)	
    if cost.class == "cfg.cmd.condition.XuNiBi" then
		local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.XuNiBi) 
        return currency:GetIconName()
    elseif cost.class == "cfg.cmd.condition.YuanBao" then
		local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.YuanBao) 
        return currency:GetIconName()
    end
    return ""
end

local function GetCurrencyType(cost)	
    if cost.class == "cfg.cmd.condition.XuNiBi" then
        return cfg.currency.CurrencyType.XuNiBi
    elseif cost.class == "cfg.cmd.condition.YuanBao" then
        return cfg.currency.CurrencyType.YuanBao
    end
    return ""
end

local function init(params)
    name, gameObject, fields = unpack(params)

    EventHelper.SetClick(fields.UIButton_Close, function()
                             uimanager.hide("family.tabpray")
    end)

    local listpray = ConfigManager.getConfig("pray")
    i = 0
    for id,data in pairs(listpray) do
        local item = fields.UIList_Pray:GetItemByIndex(i)
        i = i + 1
        if not item then return end
        item.Id = id
        item.Data = data

        local time = limitmgr.GetDayLimitTime(cfg.cmd.ConfigId.FAMILY_PRAY, id)
        local limit = data.daylimit.entertimes[player.m_VipLevel+1]
        item.Controls["UILabel_Pray"].text = data.prayname
        item.Controls["UILabel_Build"].text = data.familycapital.buildv
        item.Controls["UILabel_Contrib"].text = data.familycontribution.amount
        item.Controls["UILabel_FamilyMoney"].text = data.familycapital.money
        item.Controls["UISprite_CostIcon"].spriteName = CurrencyIcon(data.cost)
        item.Controls["UILabel_Cost"].text = data.cost.amount
        EventHelper.SetClick(item.Controls["UIButton_Pray"], function()
            if PlayerRole:Instance():GetCurrency(GetCurrencyType(data.cost)) < data.cost.amount then
			    ItemManager.GetSource(GetCurrencyType(data.cost),name)
            else
                praymgr.Pray(item.Id, function()
                    refresh()
                    --ˢ�º���
                    uimanager.refresh("family.tabbasic")
                    require("ui.dlgdialog").RefreshRedDot("family.dlgfamily")
                end)
            end           
        end)
    end
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    showtab      = showtab,
    show         = show,
    hide         = hide,
    refresh      = refresh,
    destory      = destory,
    init         = init,
    uishowtype   = uishowtype,
}
