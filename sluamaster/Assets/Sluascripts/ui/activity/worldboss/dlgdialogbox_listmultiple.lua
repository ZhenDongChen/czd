local UIManager = require("uimanager")
local EventHelper = UIEventListenerHelper
local PlayerRole=require("character.playerrole"):Instance()
local DlgWorldBoss=require("ui.activity.worldboss.tabworldboss")
local WorldBossManager=require("ui.activity.worldboss.worldbossmanager")
local ConfigManager= require("cfg.configmanager")

local gameObject
local name
local fields

local function update()
end

local function refresh()
end

local function destroy()
end

local function hide()
end

local function show(params)
    fields.UILabel_Title.text=LocalString.WorldBoss_SelectLine
    local pos=gameObject.transform.localPosition
    gameObject.transform.localPosition=Vector3(pos.x,pos.y,-255)
    local lines=WorldBossManager.GetLines()
    fields.UIList_Line:Clear()
    for line,value in pairs(lines) do
        if value~=cfg.ectype.WorldBossStateType.NOT_EXIED then
            local listItem=fields.UIList_Line:AddListItem()
            local UILabel_Status=listItem.Controls["UILabel_Status"]
            local statusText=""
            if value==cfg.ectype.WorldBossStateType.ALIVE then
                statusText=string.format(LocalString.WorldBoss_NotBeKilled,line)
                local UIButton_Item=listItem.Controls["UIButton_Multiple"]
                EventHelper.SetClick(UIButton_Item,function()
                    UIManager.hide(name)
                    UIManager.hidecurrentdialog()
					local worldmapdata = ConfigManager.getConfigData("worldmap",params.worldBoss.mapid)
					local position = Vector3(worldmapdata.WorldFlyInX,worldmapdata.WorldFlyInY,0)
                    WorldBossManager.NavigateToLine({mapId=params.worldBoss.mapid,lineId=line,position=position})
                end)
            elseif value==cfg.ectype.WorldBossStateType.KILLED then
                statusText=string.format(LocalString.WorldBoss_HasBeenKilled,line)
            end
            UILabel_Status.text=statusText
        end
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_Close,function()
         UIManager.hide(name)
    end)
end

return{
    init = init,
    show = show,
    update = update,
    refresh = refresh,
    destroy = destroy,
    hide = hide,
}