local unpack 		= unpack
local print 		= print
local UIManager 	= require "uimanager"
local ArenaManager   = require "ui.arena.single.arenamanager"
local FightReportInfo 	= require("ui.arena.single.arenainfo.arenafightreport")
local EventHelper 	= UIEventListenerHelper
local ArenaData = ArenaManager.ArenaData

local name
local fields
local gameObject


local function RefreshItem(uiItem,wrapIndex,realIndex)
        local reportInfo = ArenaData.FightReportList[realIndex]
        
     --   printyellow("reportInfo",reportInfo)
        local str = reportInfo:ToString()
        --str = str.."itemIdx"..wrapIndex.." dataIdx"..realIndex
        --print(str)
        uiItem:SetText("UILabel_ReportInfo",str)
        uiItem:SetText("UILabel_Name",""--[[reportInfo.m_OpponentName]])
        uiItem:SetText("UILabel_RiseNum",""--[[reportInfo.m_ResultRank]])
        uiItem:SetText("UILabel_Win",""--[[reportInfo.m_ResultRank]])

end


local function refresh(params)
    -- local newReport = {}
    -- for i=1, 4, 1 do
    --     newReport = FightReportInfo:new({fighttime=100+i, challengetype=0, succ=1, opponentname="us"..tostring(i), newrank=100+i, oldrank=9999})
    --     table.insert(ArenaData.FightReportList, 1, newReport)
    -- end
    
    local reportListCount = #ArenaData.FightReportList

  --  printyellow("[][][][][][][][][][][]")
 --   printyellow(reportListCount)

    local wrapList = fields.UIList_BattlefieldReport.gameObject:GetComponent("UIWrapContentList")
    EventHelper.SetWrapListRefresh(wrapList,RefreshItem)
    wrapList:SetDataCount(reportListCount)
    if reportListCount > 0 then 
        fields.UIGroup_Empty.gameObject:SetActive(false)
    else
        fields.UIGroup_Empty.gameObject:SetActive(true)
    end
end

local function destroy()

end

local function show(params)

end

local function hide()

end

local function update()

end

local function init(params)
    name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_CloseReport, function ()
        UIManager.hide(name)
	end)
    gameObject.transform.position = Vector3(0,0,-1000)
end
return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
