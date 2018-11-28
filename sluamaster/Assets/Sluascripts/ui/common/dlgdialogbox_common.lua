local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")

local name
local gameObject
local fields

local secondUpdateDelegate = nil
local updateDelegate = nil
local refreshDelegate = nil



Dlg_Common_Type={
    UIGROUP_RESOURCE=0,
    UIGROUP_OPTION=1,
    UIGROUP_GETREWARDS=2,
    UIGROUP_REMINDER_FULL=3,
    UIGROUP_REMINDER_SHORT=4,
    UIGROUP_ITEMUSE=5,
    UIGROUP_BUY=6,
}
----------------------------
--显示功能所需的Group，关闭无关的Group
-----------------------------
local function DisplayGroupByType()
    fields.UIGroup_Resource.gameObject:SetActive(false)
    fields.UIGroup_Option.gameObject:SetActive(false)
    fields.UIGroup_GetRewards.gameObject:SetActive(false)
    fields.UIGroup_Reminder_Full.gameObject:SetActive(false)
    fields.UIGroup_Reminder_Short.gameObject:SetActive(false)
    fields.UIGroup_ItemUse.gameObject:SetActive(false)
    fields.UIGroup_Buy.gameObject:SetActive(false)
end

local function refresh(params)
    if refreshDelegate ~= nil then
        refreshDelegate(fields,name,params)
    end
end

local function update()
    if updateDelegate ~= nil then
        updateDelegate(fields,name)
    end
end

local function second_update()
    if secondUpdateDelegate ~= nil then
        secondUpdateDelegate(fields,name)
    end
end

---------------------------------------
--调用接口
--参数释义({type:功能类型，见Dlg_Common_Type;callBackFunc:回调函数，实现个人所需功能})
---------------------------------------
local function show(params)
    DisplayGroupByType()
    if params then
        if params.callBackFunc then
            params.callBackFunc(fields,name,params)
        end
        if params.refreshDelegate then
            refreshDelegate = params.refreshDelegate
        end
        if params.secondUpdateDelegate then
            secondUpdateDelegate = params.secondUpdateDelegate
        end
        if params.updateDelegate then
            updateDelegate = params.updateDelegate
        end
    end
end

local function init(params)
    name,gameObject,fields=Unpack(params)
    EventHelper.SetClick(fields.UIButton_Close,function()
        UIManager.hide(name)
    end)
end

local function hide()
end

return{
    show = show,
    init = init,
    update = update,
    refresh = refresh,
    hide = hide,
    second_update = second_update,
}
