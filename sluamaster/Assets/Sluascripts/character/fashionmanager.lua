local network = require"network"
local uimanager = require"uimanager"
local PlayerRole = require"character.playerrole"
local ConfigManager = require"cfg.configmanager"
local gameevent = require "gameevent"

local Fashions = nil
local getInfo = false
local haveNew = true
local CurrentDressing = 0
local bNeedRefresh = false
local refreshParam

local TimeUtils = require"common.timeutils"

local function NeedRefresh(param)
    refreshParam = param or refreshParam
    bNeedRefresh = true
end

local function FuncCampare(a,b)
    -- local gainA = a.state > 0 and 1 or 0
    -- local gainB = b.state > 0 and 1 or 0
    if a.state == b.state then
        return a.displayorder < b.displayorder
    else
        return a.state>b.state
    end
end

local function GetDressingIndex()
    for i=1,#Fashions do
        local fashionInfo = Fashions[i]
        if fashionInfo.id == PlayerRole.Instance().m_Dress then
            return i
        end
    end
    return 1
end

local function ShowFilter()
    local ret = {}
    for _,dress in ipairs(Fashions) do
        if dress.showmode ~= cfg.equip.EquipTitleShowMode.ShowAfterGet or dress.state ~= 0 then
            table.insert(ret,dress)
        end
    end
    return ret
end

local function GetFashions()
    table.sort(Fashions,FuncCampare)
    local ret = ShowFilter()
    return ret
end

local function RefreshDressUI(dresskey)
    if uimanager.isshow("dlgfashion") then
        uimanager.refresh("dlgfashion",dresskey)
    end
end

local function onmsg_GetDressInfo(msg)
	Util.Log("onmsg_GetDressInfo")
    Fashions = {}
    local gender = PlayerRole.Instance().m_Gender
    local profession = PlayerRole.Instance().m_Profession
    local FashionInfo = ConfigManager.getConfig("dress")
    local cnt = 0
    for _,info in pairs(FashionInfo) do
        if gender == info.sex  then
            cnt = cnt + 1
            Fashions[cnt] = info
            Fashions[cnt].state = 0
        end
    end
    CurrentDressing = msg.activedress
    for _,curfashion in pairs(msg.dresslist) do
        for _,info in pairs(Fashions) do
            if info.id == curfashion.dresskey then
                info.state = 1
                info.remaintime = curfashion.expiretime/1000 - TimeUtils.GetServerTime()
                info.isNew = false
                if curfashion.dresskey == CurrentDressing then
                    info.state = 2
                end
                break
            end
        end
    end
end

local function onmsg_ActiveDress(msg)
    if CurrentDressing~=0 then
        for _,dress in pairs(Fashions) do
            if dress.id == CurrentDressing then
                dress.state = 1
                CurrentDressing = 0
            end
        end
    end
    for _,dress in pairs(Fashions) do
        if dress.id == msg.dresskey then
            dress.state = 2
            CurrentDressing = dress.id
            dress.isNew = false
            break
        end
    end
    NeedRefresh(msg.dresskey)
end

local function onmsg_DeActiveDress(msg)
    local p = nil
    for _,dress in pairs(Fashions) do
        if dress.id == CurrentDressing then
            dress.state = 1
            p = CurrentDressing
            CurrentDressing = 0
            break
        end
    end
    NeedRefresh(p)
end

local function onmsg_BuyDress(msg)
    for _,dress in pairs(Fashions) do
        if dress.id == msg.dresskey then
            dress.state = 1
            dress.remaintime = 0
            dress.isNew = true
            break
        end
    end
    NeedRefresh(msg.dresskey)
    if uimanager.hasloaded"dlgfashion" then
        printyellow("aaaa")
        uimanager.call("dlgfashion","RefreshScroll")
    end
end

local function onmsg_DresGetNotify(msg)
    local uimainopen = require"ui.dlgmain_open"
    local cfgDot = ConfigManager.getConfigData("uimainreddot",cfg.ui.FunctionList.FASHION)
    uimainopen.RefreshRedDot(cfgDot.dottype)
    for _,dress in pairs(Fashions) do
        if dress.id == msg.dress.dresskey then
            dress.state = 1
            dress.remaintime = msg.dress.expiretime/1000 - TimeUtils.GetServerTime()
            uimanager.ShowSystemFlyText(string.format(LocalString.FashionText.ActiveDress,dress.name))
            dress.isNew = true
            break
        end
    end
    NeedRefresh()
end

local function GetFashionInfo()
    network.send(lx.gs.dress.CGetDressInfo({}))
end

local function UnRead()
    local bRead = false
    if Fashions then
        for _,dress in pairs(Fashions) do
            if dress.state ~=0 then
                bRead = true
                if dress.state == 2 then
                    bRead = false
                    break
                end
            end
        end
    end
    return bRead
end

local function GetDressIndexById(id)
    for idx,v in ipairs(Fashions) do
        if v.id == id then return idx end
    end
    return 1
end

local function late_update()
    if bNeedRefresh then
        bNeedRefresh = false
        RefreshDressUI(refreshParam)
        refreshParam = nil
    end
end

local function second_update()
    if Fashions then
        for _,v in pairs(Fashions) do
            if v.remaintime  and v.remaintime>0 then
                v.remaintime = v.remaintime - 1
                if v.remaintime <= 0 then
                    Fashions.state = 0
                    v.remaintime = nil
                end
            end
        end
    end
end

local function onmsg_DressExpired(msg)
    for _,dress in pairs(Fashions) do
        if dress.id == msg.dresskey then
            dress.state = 0
            dress.remaintime = nil
            dress.isNew = false
            break
        end
    end
    NeedRefresh()
end

local function init()
    gameevent.evt_late_update:add(late_update)
    gameevent.evt_second_update:add(second_update)
    haveNew = false
    CurrentDressing = 0
    network.add_listeners({
        {"lx.gs.dress.SGetDressInfo",onmsg_GetDressInfo},
        {"lx.gs.dress.SActiveDress",onmsg_ActiveDress},
        {"lx.gs.dress.SBuyDress",onmsg_BuyDress},
        {"lx.gs.dress.SDeActiveDress",onmsg_DeActiveDress},
        {"lx.gs.dress.SDressGetNotify",onmsg_DresGetNotify},
        {"lx.gs.dress.SDressExpired",onmsg_DressExpired}
    },"fashionmanager")
end

return {
    init = init,
    GetFashions = GetFashions,
    GetFashionInfo = GetFashionInfo,
    UnRead = UnRead,
    GetDressingIndex = GetDressingIndex,
    GetDressIndexById = GetDressIndexById,
    update = update,
}
