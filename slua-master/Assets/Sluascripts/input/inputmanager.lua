local gameevent = require("gameevent")
local UIManager = require("uimanager")
local CharacterManager = require"character.charactermanager_sync"
local Pressed
local lastMoveTime
local InputController = require"input.inputcontroller"
local ic
local player
local CameraManager = require"cameramanager"
local effectmanager = require "effect.effectmanager"
local dlgalert_tempdialog = require "ui.dlgalert_tempdialog"
local scenemanager      = require "scenemanager"
local DefineEnum     = require "defineenum"

-- 暴露给c#的接口
function playerrole_move(delta)
    local TeamManager = require("ui.team.teammanager")
    if TeamManager.IsForcedFollow() ~= true then  --非强制跟随
--[[        if NoviceGuideManager.IsGuiding() then
            NoviceGuideTrigger.MoveJoy()
        end    --]]
		if PlayerRole:Instance():IsFollowing() then
			TeamManager.RequestCancelFollowing()
		end
    end
    
    if PlayerRole:Instance().m_Object then
        local speed = PlayerRole:Instance():GetJoySpeed()		
        local dst = PlayerRole:Instance():GetPos() + Vector3(speed * delta.x, speed * delta.y, 0)
		local CheckNextPos = PlayerRole:Instance():GetPos() + Vector3(NAV_ASTAR_CELL_X * delta.x, NAV_ASTAR_CELL_X * delta.y, 0)
		if PlayerRole:Instance():CanMoveTo(CheckNextPos) then
			PlayerRole:Instance():moveTo(dst)
			PlayerRole:Instance():OnJoyStickMove(delta)
		end
    end
end

function playerrole_stop()
    PlayerRole:Instance():stop()
    PlayerRole:Instance():OnJoyStickStop()
end

local G = {}

local function GetG() 
    local g = {}
    local t = {}
    for k,v in pairs(_G) do 
        local t = {}
        t.name = k 
        t.type = type(v)
        t.value = v
        table.insert(g,t)
        --printyellow("k",tostring(k),"v",type(v))
    end 
    table.sort(g,function(a,b) return a.type<b.type end)
    return g
end

local function PrintG(g)
    local ss = "count:" .. tostring(#g) .."\n"
    for k,v in pairs(g) do
        ss = ss .."type:"..v.type.."     name:"..v.name.."\n"
    end 
    printyellow(ss)
end  

local function PrintDiff(g1,g2)
    printyellow("#g1",#g1,"#g2",#g2)
    local ng = {}
    for _,v2 in pairs(g2) do 
        local new = true
        for _,v1 in pairs(g1) do 
            if v1.value == v2.value then 
                new = false
            end 
        end
        if new then 
            table.insert(ng,v2)
        end 
    end 
    PrintG(ng)
end 

local function update()
    ic:Update()
    if player and player.m_Object then
        player.m_Avatar:Update()
    end

end

local function init()
    lastMoveTime    = 0
    player          = nil
    gameevent.evt_update:add(update)
    ic = InputController.Instance()
end

function showGMUI()
    UIManager.show("DlgAlert_tempDialog")
end


function Process_F12()
	local str=""
	--uimanager.ShowSystemFlyText(str)
end

return {
    init = init,
}
