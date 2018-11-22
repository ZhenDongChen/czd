local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local membermgr = require("family.membermanager")
local itemmanager = require("item.itemmanager")

local gameObject
local name
local fields

local FamilyLogType = enum
{
    "JOIN_FAMILY = 1",
    "PROMOTION",
    "QUIT_FAMILY",
    "CHIEF_TRANSFER",
    "UPLEVEL_FAMILY",
    "PRAY",
    "RAISE_ANIMAL",
    "CREATE_FAMILY",
    "UPLEVEL_MALL",
    "KICKOUT_MEMBER",
    "FAMILY_DEPOT",
}

local function GetDesc(logInfo)
    local desc
    if logInfo.actiontype == FamilyLogType.JOIN_FAMILY then
        desc = LocalString.Family.Log.Join
    elseif logInfo.actiontype == FamilyLogType.PROMOTION then
        if logInfo.param ~= nil and #logInfo.param > 1 then
            desc = string.format(LocalString.Family.Log.PromoteBy, logInfo.param, membermgr.JobId2Str(logInfo.number))
        else
            desc = string.format(LocalString.Family.Log.Promote, membermgr.JobId2Str(logInfo.number))
        end       
    elseif logInfo.actiontype == FamilyLogType.QUIT_FAMILY then
        desc = LocalString.Family.Log.Quit
    elseif logInfo.actiontype == FamilyLogType.CHIEF_TRANSFER then
        desc = LocalString.Family.Log.TransferChief
    elseif logInfo.actiontype == FamilyLogType.UPLEVEL_FAMILY then
        desc = string.format(LocalString.Family.Log.FamilyLevelup, logInfo.number)
    elseif logInfo.actiontype == FamilyLogType.PRAY then
        desc = string.format(LocalString.Family.Log.Pray, logInfo.number)
    elseif logInfo.actiontype == FamilyLogType.RAISE_ANIMAL then
        desc = string.format(LocalString.Family.Log.FeedBoss, logInfo.number)
    elseif logInfo.actiontype == FamilyLogType.CREATE_FAMILY then
        desc = LocalString.Family.Log.CreateFamily
    elseif logInfo.actiontype == FamilyLogType.UPLEVEL_MALL then
        desc = string.format(LocalString.Family.Log.MallLevelup, logInfo.number)
    elseif logInfo.actiontype == FamilyLogType.KICKOUT_MEMBER then
        if logInfo.param ~= nil and #logInfo.param > 1 then
            desc = string.format(LocalString.Family.Log.KickoutBy, logInfo.param)
        else
            desc = LocalString.Family.Log.Kickout
        end
    elseif logInfo.actiontype == FamilyLogType.FAMILY_DEPOT then
        if logInfo.param ~= nil then
            local item = itemmanager.CreateItemBaseById(logInfo.number) 
            if item then   
                desc = string.format(LocalString.Family.Log.GiveItem,logInfo.param,item:GetName()) 
            end
        end  
    end

    if not desc then
        desc = ""
    end
    return desc
end

local function destroy()
end

local function show(params)
    local logInfos = params.msg.logs
    local wrapList = fields.UIList_Log.gameObject:GetComponent("UIWrapContentList")    
    EventHelper.SetWrapListRefresh(wrapList,function(uiItem,wrapIndex,realIndex)
        local uiGroup = uiItem.Controls["UIGroup_All"]
        uiGroup.gameObject:SetActive(true)

        local logInfo = logInfos[realIndex]
        local actionTime = os.date("*t", logInfo.actiontime/1000)
        local tiemStr = string.format(LocalString.Time.TagTime, actionTime.month, actionTime.day, 
            actionTime.hour, actionTime.min)
        uiItem:SetText("UILabel_Time", tiemStr)
        uiItem:SetText("UILabel_Name", logInfo.rolename)
        uiItem:SetText("UILabel_Content", GetDesc(logInfo))
        uiItem.Controls["UILabel_Content"].applyGradient = (logInfo.actiontype ~= FamilyLogType.FAMILY_DEPOT)
    end)  
    wrapList:SetDataCount(#logInfos)
    wrapList:CenterOnIndex(-0.4)
end

local function hide()
end

local function refresh(params)   
end

local function update()
end

local function init(params)
    --name, gameObject, fields = unpack(params)
    fields = params

    --------------------------Propose Group 
    EventHelper.SetClick(fields.UIButton_Close, function()
        hide()
        uimanager.hide("common.dlgdialogbox_complex")
    end )

end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
