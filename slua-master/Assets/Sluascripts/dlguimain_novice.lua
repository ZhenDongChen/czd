local unpack            = unpack
local print             = print
local format            = string.format
local math              = math
local EventHelper       = UIEventListenerHelper
local gameevent         = require"gameevent"
local uimanager        = require("uimanager")
local network           = require("network")

local gameObject
local name
local fields
local NoviceModuleList={}

local function RegisterNoviceModules()
    NoviceModuleList=
    {
        [cfg.guide.NoviceModuleList.BAG]           = fields.UIButton_Bag,
        [cfg.guide.NoviceModuleList.ECTYPE]        = fields.UIButton_Instance,
        [cfg.guide.NoviceModuleList.ACTIVITY]      = fields.UIButton_Activity,
        [cfg.guide.NoviceModuleList.PARTNER]       = fields.UIButton_Partner,
        [cfg.guide.NoviceModuleList.HEAD]          = fields.UITexture_HeroHead,
        [cfg.guide.NoviceModuleList.FAMILY]        = fields.UIButton_Family,
        [cfg.guide.NoviceModuleList.BATTLE]        = fields.UIButton_Battlefield,
        [cfg.guide.NoviceModuleList.DAILYEXTRAEXP] = fields.UISprite_KillEXP,
        [cfg.guide.NoviceModuleList.IDOL]          = fields.UIButton_Stars,
    }
end

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
end

local function hide()
    -- print(name, "hide")
end

local function update()

end


local function refresh()
--  printyellow("refresh the icon")

end

local function init(iName,iGameObject,iFields)
    name            = iName
    gameObject      = iGameObject
    fields          = iFields
    RegisterNoviceModules()
end

local function GetItemPos(id)
    if (id==cfg.guide.NoviceModuleList.ACTIVITY) or (id==cfg.guide.NoviceModuleList.ECTYPE) or (id==cfg.guide.NoviceModuleList.FAMILY) or (id==cfg.guide.NoviceModuleList.BATTLE) then
        local Tween_Close=LuaHelper.FindGameObject("/UI Root (2D)/UI_Root/dlguimain/UIWidget_TopRight/UIGroup_FunctionsArea/UIGroup_ActivitiesClose/Tween_Close")
        if Tween_Close then
            if Tween_Close.gameObject.transform.localScale.x==0 then
                return Tween_Close.transform.parent.Find("UIButton_Stretch").position
                --return fields.UIButton_Stretch.gameObject.transform.position
            else
                local module=NoviceModuleList[id]
                if module then
                    return module.gameObject.transform.position
                end
            end
        end
    else
       local module=NoviceModuleList[id]
       if module then
          return module.gameObject.transform.position
       end 
    end
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    GetItemPos = GetItemPos,
}
