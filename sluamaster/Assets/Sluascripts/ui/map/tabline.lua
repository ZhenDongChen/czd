local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local ConfigManager=require("cfg.configmanager")
local MapManager=require("map.mapmanager")
local NetWork = require("network")
local PlayerRole=require("character.playerrole")

local m_GameObject
local m_Name
local m_Fields
local m_Lines

local function show(params)
end

local function hide()
	
end

local function refresh(params)
	 MapManager.GetMapLines() 
end

local function DisplayMapLines()
	m_Fields.UIList_LineButton:Clear()
	for i=1,#m_Lines do 
		local UIListItem_Line = m_Fields.UIList_LineButton:AddListItem()
		local lineId = m_Lines[i].lineid
		UIListItem_Line.Id = lineId
		UIListItem_Line:SetText("UILabel_Line",lineId..LocalString.LineMap_Line)
		if lineId == PlayerRole:Instance().m_MapInfo:GetLineId() then
			m_Fields.UIList_LineButton:SetSelectedIndex(i-1)
            local UILabel_CurLine=m_Fields.UILabel_CurLine
            UILabel_CurLine.text=lineId..LocalString.LineMap_Line
		else
			EventHelper.SetClick(UIListItem_Line,function()
				
				--[[
                local familymgr = require("family.familymanager")
                if familymgr.IsInStation() then
                    UIManager.ShowSingleAlertDlg({title=LocalString.LineMap_Warn,content=LocalString.Family.ChangeLineForbid})
                    return
                end
					]]
                MapManager.EnterMap(PlayerRole:Instance():GetMapId(),lineId)
            end)
		end
	end
	
	EventHelper.SetClick(m_Fields.UIButton_Sure,function()
	--弹出警告的弹窗家族中不能进行换线
	--[[
	local familymgr = require("family.familymanager")
	if familymgr.IsInStation() then
		UIManager.ShowSingleAlertDlg({title=LocalString.LineMap_Warn,content=LocalString.Family.ChangeLineForbid})
		return
	end
		]]
	local UILabel_CurSelectedLine=m_Fields.UILabel_CurSelectedLine
	local inputContent=UILabel_CurSelectedLine.text
	local n=tonumber(inputContent)
	if n==nil then           
		UIManager.ShowSingleAlertDlg({title=LocalString.LineMap_Warn,content=LocalString.LineMap_InputNum})
	elseif n<=0 then
		UIManager.ShowSingleAlertDlg({title=LocalString.LineMap_Warn,content=LocalString.LineMap_LineNotExit})
	else
		for i=1,#m_Lines do
			local lineId=m_Lines[i].lineid
			if lineId==n then
				if lineId~=PlayerRole:Instance().m_MapInfo:GetLineId() then
					MapManager.EnterMap(PlayerRole:Instance():GetMapId(),lineId )
				else
					UIManager.ShowSystemFlyText(LocalString.LineMap_InTheLine)
				end
				return
			end
		end
		UIManager.ShowSingleAlertDlg({title=LocalString.LineMap_Warn,content=LocalString.LineMap_LineNotExit})
	end                   
    end)
	
end

local function update()
end

local function ShowMapLines(msg)
    m_Lines=msg.lines
    DisplayMapLines()
end


local function destroy()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)          
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
    ShowMapLines = ShowMapLines,
}