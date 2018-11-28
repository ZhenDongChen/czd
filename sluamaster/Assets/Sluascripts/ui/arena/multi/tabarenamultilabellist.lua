local unpack, print     = unpack, print
local UIManager 	    = require "uimanager"
local EventHelper 	    = UIEventListenerHelper
local ConfigManager     = require("cfg.configmanager")
local name, gameObject, fields


local m_RedDotList = {
    ["arena.multi.pvp.tabarenamultipvp"] = require("ui.arena.multi.pvp.tabarenamultipvp").UnRead,
    ["arena.multi.speed.tabarenamultispeed"] = require("ui.arena.multi.speed.tabarenamultispeed").UnRead,
}


local function refresh(params)
    fields.UIList_Level:Clear()
--    UIList_Level


    local arenamultidata = ConfigManager.getConfig("arenamultilist")
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Level,#arenamultidata)

    local frameTimer = FrameTimer.New(function()
        if params and type(params) == "table" and params.tabindex2 then
            local oldIndex = fields.UIList_Level:GetSelectedIndex()
            fields.UIList_Level:SetUnSelectedIndex(oldIndex)
            fields.UIList_Level:SetSelectedIndex(params.tabindex2-1,true)
        end 
    end, 1, 1)
    frameTimer:Start()



    for id, value in pairs(arenamultidata) do
        local uiItem = fields.UIList_Level:GetItemByIndex(id-1)
        uiItem:SetText("UILabel_Theme",value.label)
        local spriteRedDot = uiItem.Controls["UISprite_Warning"]
        local unread_func = m_RedDotList[arenamultidata[uiItem.Index+1].tabname]
        local unread = unread_func()
        spriteRedDot.gameObject:SetActive( unread == true )
    end

    EventHelper.SetListSelect(fields.UIList_Level,function(uiItem)
        --printyellow(",.........................")
        --printyellow(arenamultidata[uiItem.Index+1].tabname)
        if UIManager.isshow(arenamultidata[uiItem.Index+1].tabname) then
            UIManager.refresh( arenamultidata[uiItem.Index+1].tabname )
        else
            UIManager.showtab( arenamultidata[uiItem.Index+1].tabname )
        end
        for i = 1, #arenamultidata do
            if (uiItem.Index + 1) ~= i and UIManager.isshow(arenamultidata[i].tabname) then
                UIManager.hidetab(arenamultidata[i].tabname)
            end
        end
    end)
end

local function destroy()

end

local function show(params)
    local arenamultidata = ConfigManager.getConfig("arenamultilist")
    if params and type(params) == "table" and params.tabindex2 then
        local index = params.tabindex2
        
     --   if index > 1 then
            local oldIndex = fields.UIList_Level:GetSelectedIndex()
            fields.UIList_Level:SetUnSelectedIndex(oldIndex)
            fields.UIList_Level:SetSelectedIndex(index-1)
     --   end
        if arenamultidata[index] ~= nil then
            if UIManager.isshow(arenamultidata[index].tabname) then
                UIManager.refresh( arenamultidata[index].tabname )
            else
                UIManager.showtab( arenamultidata[index].tabname )
            end
            for i = 1, #arenamultidata do
                if index ~= i and UIManager.isshow(arenamultidata[i].tabname) then
                    UIManager.hidetab(arenamultidata[i].tabname)
                end
            end
        end
    end
end

local function hide()

end

local function update()

end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    name, gameObject, fields = unpack(params)
end

local function showtab(params)
    UIManager.show("arena.multi.tabarenamultilabellist",params)
end

local function UnRead()
    for i, unread_func in pairs(m_RedDotList) do
        local unread = unread_func()

        if unread == true  then
            return true
        end
    end
    return false
end



return {
    init    = init,
    show    = show,
    hide    = hide,
    update  = update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    showtab = showtab,
    UnRead = UnRead,
}
