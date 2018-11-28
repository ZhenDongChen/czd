local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require "uimanager"
local network = require "network"

local os = require 'cfg.structs'
local create_datastream = create_datastream
local charactermanager = require "character.charactermanager"
local configmanager = require "cfg.configmanager"
local PlayerRole = require "character.playerrole"
local defineenum = require "defineenum"
local itemmanager = require "item.itemmanager"
local scenemanager = require "scenemanager"
local springfestivalmanager = require"ui.activity.springfestival.springfestivalmanager"
local gameObject
local name

local fields

local UILabel_Lv = nil
local UILabel_EXPlimit = nil
local UILabel_EXPRemain = nil
local UITexture_Pot = nil
local UISlider_EXP = nil
local UILabel_worldlevel = nil
local UILabel_killmonster_rate = nil
local UILabel_totalexp_rate = nil

local function GetDungeonId()
    local mapData = configmanager.getConfig("worldmap")
    local openlevel = 0
    local mapid = 0
    for _, map in pairs(mapData) do
        if map.isdungeon and map.openlevel <= PlayerRole:Instance().m_Level and map.openlevel > openlevel then
            mapid = map.id
            openlevel = map.openlevel
        end
    end

    return mapid
end

local function destroy()
    -- print(name, "destroy")
end

local function refreshExp()
    local totalExtraExpLimit = 0
    local expdata = configmanager.getConfigData("exptable", PlayerRole:Instance().m_Level)
    if expdata ~= nil then
        totalExtraExpLimit = expdata.bonusexp
        if PlayerRole:Instance().m_worldlevelrate > 0 then
            totalExtraExpLimit = math.floor(totalExtraExpLimit * PlayerRole:Instance().m_worldlevelrate)
        end
        UILabel_EXPlimit.text = tostring(totalExtraExpLimit)
    end
    local monsterData = springfestivalmanager.getMonsterData()

    local remainExp = totalExtraExpLimit - PlayerRole:Instance().m_TodayKillMonsterExtraExp + monsterData.MonsterExpStatus * monsterData.remainexp
    if remainExp < 0 then
        remainExp = 0
    end

    UILabel_Lv.text = tostring(PlayerRole:Instance().m_Level)
    UILabel_EXPRemain.text = tostring(remainExp)

    if totalExtraExpLimit > 0 then
        UISlider_EXP.value = remainExp/totalExtraExpLimit
    end
end

local function refreshWorldLevelRate()
    UILabel_worldlevel.text = tostring(PlayerRole:Instance().m_worldlevel)
    if PlayerRole:Instance().m_worldlevelrate > math.floor(PlayerRole:Instance().m_worldlevelrate) then
        UILabel_totalexp_rate.text = string.format(LocalString.WORLDLEVEL_RATE_FLOAT, PlayerRole:Instance().m_worldlevelrate)
    else
        UILabel_totalexp_rate.text = string.format(LocalString.WORLDLEVEL_RATE_INT, PlayerRole:Instance().m_worldlevelrate)
    end

    local worldleveldata = configmanager.getConfig("worldlevel")
    if worldleveldata ~= nil then
        if PlayerRole:Instance().m_Level > PlayerRole:Instance().m_worldlevel or PlayerRole:Instance().m_Level < worldleveldata.startlevel then
            UILabel_killmonster_rate.text = string.format(LocalString.WORLDLEVEL_RATE_INT, 1)
        else
            local worldlevelDisparitydata = configmanager.getConfig("worldlevel_disparity")
            if worldlevelDisparitydata ~= nil then
                local monsterexprate = worldlevelDisparitydata[PlayerRole:Instance().m_worldlevel + 1 - PlayerRole:Instance().m_Level].monsterexprate
                if monsterexprate > math.floor(monsterexprate) then
                    UILabel_killmonster_rate.text = string.format(LocalString.WORLDLEVEL_RATE_FLOAT, monsterexprate)
                else
                    UILabel_killmonster_rate.text = string.format(LocalString.WORLDLEVEL_RATE_INT, monsterexprate)
                end
            end
        end
    end

    refreshExp()
end

local function show(params)
    -- print(name, "show")

    refreshWorldLevelRate()
end


local function hide()
    -- print(name, "hide")
end

local function refresh(params)
    -- print(name, "refresh")
end

local function update()
    -- print(name, "update")
end

local function init(params)
    name, gameObject, fields = unpack(params)

    -- printyellow("DlgDailyExp init")

    UILabel_Lv = fields.UILabel_Lv
    UILabel_EXPlimit = fields.UILabel_EXPlimit
    UILabel_EXPRemain = fields.UILabel_EXPRemain
    UITexture_Pot = fields.UITexture_Pot
    UISlider_EXP = fields.UISlider_EXP
    UILabel_worldlevel = fields.UILabel_worldlevel
    UILabel_killmonster_rate = fields.UILabel_worldexp
    UILabel_totalexp_rate = fields.UILabel_worldexplimit

    EventHelper.SetClick(fields.UIButton_GO, function()
        -- printyellow("UIButton_Go click")

        local curMapId = scenemanager.GetCurMapId()
        local mapData = configmanager.getConfigData("worldmap",curMapId)
        if mapData and mapData.isdungeon then
            local info = LocalString.WorldMap_EnteredDungeon
            uimanager.ShowSingleAlertDlg( { content = info, } )
            return
        end

        local mapid = GetDungeonId()
        if mapid > 0 then
            mapData = configmanager.getConfigData("worldmap",mapid)
            if mapData ~= nil then
                local info = string.format(LocalString.WorldMap_IsEnterDungeon, mapData.mapname)
                local pos = Vector3(mapData.WorldFlyInX, mapData.WorldFlyInY, 0)
                uimanager.ShowAlertDlg( {
                    immediate    = true,
                    title = LocalString.TipText,
                    content = info,
                    callBackFunc = function()
                        PlayerRole:Instance():navigateTo( {
                            navMode = 1,
                            isShowAlert = false,
                            targetPos = pos,
                            mapId = mapid,
                            isAdjustByRideState = true,
                            callback = function()
                                --
                            end,
                            immediate = true,
                        } )

                    end,
                } )
            end
        else
            local info = LocalString.WorldMap_CannotEnterDungeon
            uimanager.ShowSingleAlertDlg( {content = info,} )
        end
    end )

    EventHelper.SetClick(fields.UIButton_Close, function()
       
        uimanager.hidedialog("dlgdailyexp")
    end )

	 EventHelper.SetClick(fields.UIButton_Detail, function()
		 local worldlevelData = configmanager.getConfig("worldlevel")
		 uimanager.show("common.dlgdialogbox_complex",{type=2,text = rewardText,callBackFunc = function(params,ofields)
            ofields.UILabel_Content_Single.text = worldlevelData.info
        end})
    end )

end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    refreshExp = refreshExp,
    refreshWorldLevelRate = refreshWorldLevelRate,
}
