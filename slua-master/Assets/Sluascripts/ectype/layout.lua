--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
--endregion

local mathutils = require"common.mathutils"
local ConfigManager
local defineenum = require "defineenum"
local PlayerRole = require "character.playerrole"
local network = require"network"
local mathutils = require"common.mathutils"
local tools = require"ectype.ectypetools"

local Layout = Class:new()

function Layout:__new(layout_infos,ectypeinfo,layoutGroupID,pre,IsPrologue)
    ConfigManager = require "cfg.configmanager"
    self.m_LayoutID             = layout_infos.id
    self.m_Completed            = layout_infos.completed
	local layouts               = ectypeinfo.layouts
    local layouts_id            = ectypeinfo.layouts_id
	local infos                 = layouts_id[self.m_LayoutID]
	self.m_Enters               = infos.enters_id
	self.m_Exits                = infos.exits_id
	self.m_ExitPoints           = {}
	self.m_EnterAreas           = {}
	self.m_PlayerRole           = PlayerRole:Instance()
	
	self.m_PreLayoutID          = pre
    for i,v in pairs(self.m_Exits) do
        v.isOpen = false
    end
    for i,v in pairs(self.m_Enters) do
        v.isOpen = true
    end
    self:Init(layoutGroupID,IsPrologue)
end


function Layout:Init(layoutGroupID,IsPrologue)
    local polygonRegion = ConfigManager.getConfigData("ectyperegionset",layoutGroupID)
    self.m_polygons = polygonRegion.regions_id
end

function Layout:ChangeEntry(id,open)
    self.m_Enters[id].isOpen = open
end

function Layout:ChangeExit(id,open)
    self.m_Exits[id].isOpen = open
end

function Layout:CheckPassage(position,points)
    return tools.CheckInTheArea(position,points)
end


function Layout:CheckPosition(position)
    return true
end

function Layout:UpdateCompletedLayout()
    if #self.m_ExitPoints == 0 then
        for i,v in pairs(self.m_Exits) do
            if v.isOpen then
                self.m_ExitPoints = self.m_polygons[v.curveid].polygon.vertices
                self.m_LinkedLayout = v.linkedlayout
            end
        end
    end
    if #self.m_ExitPoints>0 then
		local NewPos = Vector3(self.m_PlayerRole:GetPos().x * SCALE_XY_FRACTION, self.m_PlayerRole:GetPos().y * SCALE_XY_FRACTION, 0);
        if self:CheckPassage(NewPos,self.m_ExitPoints) then
            local re = map.msg.COpenLayout({layoutid = self.m_LinkedLayout})
            network.send(re)
        end
    end
end

function Layout:Finish()
    self.m_Completed = 1
end

function Layout:Update()

end

function Layout:LayoutFinished(id)
    if self.m_LayoutID == id then
        self.m_Completed = 1
    end
end

function Layout:UpdateEnterLayout()
    if not self.m_PreLayoutID then return end
    if getn(self.m_EnterAreas)==0 then
        for i,v in pairs(self.m_Enters) do
            self.m_EnterAreas[i] = self.m_polygons[v.curveid].polygon.vertices
        end
    else
        for i,v in pairs(self.m_EnterAreas) do
			local NewPos = Vector3(self.m_PlayerRole:GetPos().x * SCALE_XY_FRACTION, self.m_PlayerRole:GetPos().y * SCALE_XY_FRACTION, 0);
            if self:CheckPassage(NewPos,v) then
                local re = map.msg.CCloseLayout({layoutid=self.m_PreLayoutID})
                self.m_PreLayoutID=nil
                network.send(re)
                return
            end
        end
    end
end

function Layout:Release()
    
end


function Layout:late_update()

end

function Layout:GetFinished()
    return self.m_Completed == 1
end


function Layout:GetArea(curveid)
    return self.m_polygons[curveid].polygon.vertices
end


function Layout:GetOpenExitPoint(Pos)
    local nearestPoint = nil
    local nearestDist = 1e10
	local newPos = Vector3(Pos.x * SCALE_XY_FRACTION, Pos.y * SCALE_XY_FRACTION, 0);
    for i,v in pairs(self.m_Exits) do
        if v.isOpen then
            if tools.CheckInTheArea(newPos,self.m_polygons[v.curveid].polygon.vertices) then
                return nil
            end
            local target = tools.GetMidPoint(self.m_polygons[v.curveid].polygon.vertices)
            local dist = mathutils.DistanceOfXoY(newPos,target)
            if dist<nearestDist then
                nearestDist = dist
                nearestPoint = target
            end
        end
    end
    return nearestPoint
end

return Layout
