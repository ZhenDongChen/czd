local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local ConfigManager = require"cfg.configmanager"
local reclaimmgr = require("guide.reclaimmanager")
local ItemManager = require("item.itemmanager")
local Player = require("character.playerrole")

local gameObject
local name
local fields
local m_curParams

local function destroy()

end

local function hide()
    m_curParams = nil
end

local function update()

end

local function ShowShopItemsInfo(params)
    if params then
        fields.UIList_ItemRecall:Clear()
        local bonus = params.items
	    for id,num in pairs(bonus) do
            if num > 0  then 
                local item = fields.UIList_ItemRecall:AddListItem()
                if item then
                    local dataitem = ItemManager.CreateItemBaseById(id)
                    -- Ŀǰ��Ʒ��icon
		            item.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(dataitem:GetQuality())	

                    item:SetIconTexture(dataitem:GetTextureName())
		            item:SetText("UILabel_ItemName", dataitem:GetName().." * "..num)
                    item:SetText("UILabel_ItemDetail", dataitem:GetIntroduction())	
                end           
            end        		
        end
    end   
end

local function refresh(params)
end

local function show(params)
    m_curParams = params
	fields.UILabel_Sure.text = LocalString.SureText

    if params.findType == reclaimmgr.FindType.JinBi or params.findType == reclaimmgr.FindType.JinBiAll then
        fields.UILabel_ItemRecall.text = LocalString.Welfare_Findback_Jinbi
        fields.UILabel_Resource.text = params.Data.costjinbi
        fields.UISprite_Icon_Resource.spriteName = "ICON_I_Currency_01"
        ShowShopItemsInfo(params.Data.jinbifindbackbonus)
    else
        fields.UILabel_ItemRecall.text = LocalString.Welfare_Findback_Yuanbao
        fields.UILabel_Resource.text = params.Data.costyuanbao
        fields.UISprite_Icon_Resource.spriteName = "ICON_I_Currency_02"
        ShowShopItemsInfo(params.Data.yuanbaofindbackbonus)
    end   
end

local function init(params)
    name, gameObject, fields = unpack(params)

    EventHelper.SetClick(fields.UIButton_Close, function()
        uimanager.hide(name)
    end)

    EventHelper.SetClick(fields.UIButton_Sure, function()        
        local dataeventserver = m_curParams.Data
        if not dataeventserver then return end
        local findtype
        local eventtype
        if m_curParams.findType == reclaimmgr.FindType.JinBi then
            if Player:Instance():Gold() < dataeventserver.costjinbi then
                uimanager.hide(name)
			    ItemManager.GetSource(cfg.currency.CurrencyType.XuNiBi,name)
                return
            end
            eventtype = dataeventserver.eventtype
            findtype = lx.gs.dailyactivity.msg.Findbacktype.JINBI_FIND
        elseif m_curParams.findType == reclaimmgr.FindType.YuanBao then             
            if Player:Instance():Ingot() < dataeventserver.costyuanbao then
			    uimanager.hide(name)
                ItemManager.GetSource(cfg.currency.CurrencyType.YuanBao,name)
                return
            end
            eventtype = dataeventserver.eventtype
            findtype = lx.gs.dailyactivity.msg.Findbacktype.YUANBAO_FIND
        elseif m_curParams.findType == reclaimmgr.FindType.JinBiAll then 
            if Player:Instance():Gold() < dataeventserver.costjinbi then
			    uimanager.hide(name)
                ItemManager.GetSource(cfg.currency.CurrencyType.XuNiBi,name)
                return
            end
            eventtype = cfg.active.EventNum.TOTAL
            findtype = lx.gs.dailyactivity.msg.Findbacktype.JINBI_FINDALL
        elseif m_curParams.findType == reclaimmgr.FindType.YuanBaoAll then   
            if Player:Instance():Ingot() < dataeventserver.costyuanbao then
			    uimanager.hide(name)
                ItemManager.GetSource(cfg.currency.CurrencyType.YuanBao,name)
                return
            end
            eventtype = cfg.active.EventNum.TOTAL
            findtype = lx.gs.dailyactivity.msg.Findbacktype.YUANBAO_FINDALL
        end
        if eventtype and findtype then
            reclaimmgr.Reclaim(eventtype, findtype, function()
                uimanager.refresh("guide.tabreclaim")
                uimanager.hide(name)
            end)            
        end        
    end)
end

return {
    init                    = init,
    show                    = show,
    refresh                 = refresh,
    update                  = update,
    hide                    = hide,
    destroy                 = destroy,
}
