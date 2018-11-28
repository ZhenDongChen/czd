local unpack 		= unpack
local print 		= print
local UIManager 	= require("uimanager")
local FriendManager = require("ui.friend.friendmanager")
local ConfigManager = require("cfg.configmanager")
local EventHelper 	= UIEventListenerHelper
local ItemManager   = require("item.itemmanager")
------------------------------------------------------------------------------------------------------
local name, gameObject, fields




local function destroy()

end

local function GetString(type)
    if type == "Send" then
        return LocalString.Friend_SendFlower_Title, LocalString.Friend_SendFlower_Empty, LocalString.Friend_SendFlower_Infos
    else
        return LocalString.Friend_ReceiveFlower_Title, LocalString.Friend_ReceiveFlower_Empty, LocalString.Friend_ReceiveFlower_Infos 
    end
end

local function GetInfoContent(prototype, info)
    if prototype == nil or info == nil then
        return ""
    end
    local item = ItemManager.CreateItemBaseById(info.flowertype, {}, info.flowernum)
    local flowername = (((item ~= nil) and item:GetName()) or "")
    local time_table = os.date("*t", info.time/1000)
    local infoContent = string.format(prototype, time_table.month, time_table.day, time_table.hour, time_table.min,
                            info.name, info.flowernum, flowername)
    return infoContent
end

local function refresh(params)

end

local function show(params)
    if params and params.type and params.infos then
        utils.table_sort(params.infos, function(a,b)
            return a.time > b.time
        end)
        local infoNum = #params.infos
        local title, empty, content = GetString(params.type)
        fields.UILabel_Title.text = title
        fields.UILabel_Empty.text = empty
        local wrapList = fields.UIList_BattlefieldReport.gameObject:GetComponent("UIWrapContentList")
        if infoNum >0 then
            fields.UIGroup_Empty.gameObject:SetActive(false)
            wrapList.gameObject:SetActive(true)
        else
            fields.UIGroup_Empty.gameObject:SetActive(true)
            wrapList.gameObject:SetActive(false)
            return
        end
        if wrapList then

            EventHelper.SetWrapListRefresh(wrapList,function(uiItem,index,realIndex)
                local uiLabel = uiItem.Controls["UILabel_ReportInfo"]
                if uiLabel then
                    uiLabel.text = GetInfoContent(content, params.infos[realIndex])
                end
            end)
            wrapList:SetDataCount(infoNum)
        end
    end
end

local function hide()

end

local function update()

end


local function init(params)
	name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_CloseReport, function()
        UIManager.hide(name)
    end)
end

local function uishowtype()
    return UIShowType.Refresh
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
