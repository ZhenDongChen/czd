local MapManager = require("map.mapmanager")
local ConfigManager = require("cfg.configmanager")
local SceneManager = Game.SceneMgr

local Config = {
    MinHeight           = -500,
    MaxHeight           = 500,
    DefaultStopLength   = NAV_ASTAR_CELL_X,
    SceneNameColor      = "[00DD00]",
}

local function LogError(msg)
    printyellow(msg)
end

local function CheckCanNavToPos(CurPos, TarPos)
	local TargetBlockPos = SceneManager.Instance:GetBlockByPiexl(Vector3(TarPos.x * SCALE_XY_FRACTION, TarPos.y * SCALE_XY_FRACTION, 0));
	local CurPosBlockPos = SceneManager.Instance:GetBlockByPiexl(Vector3(CurPos.x * SCALE_XY_FRACTION, CurPos.y * SCALE_XY_FRACTION, 0));
	if TargetBlockPos.x == CurPosBlockPos.x and TargetBlockPos.y == CurPosBlockPos.y then
		return true;
	end
	local result = SceneManager.Instance:PathFind(CurPosBlockPos,TargetBlockPos);
	if result == false then
		return false;
	end
	
	local pathlenth = SceneManager.Instance:PathFindListLength();
	if pathlenth > 0 then
		return true;
	end
	
	return false;
end

local function GetPortalPos(currentMapId, targetMapId)
    return MapManager.GetPortalOfMap(currentMapId,targetMapId)
end

local function CheckParams(params,player)
    local para = {}

    --[[
        目标点与停止距离
    ]]
    
    para.stopLength = params.newStopLength or Config.DefaultStopLength
    para.isAdjustByRideState = params.isAdjustByRideState or false
    para.targetPos  = params.targetPos
    para.lengthCallback = params.lengthCallback
    para.endDir     = params.endDir
       
    --[[
        地图Id与线Id
    ]]
    para.mapId  = params.mapId  or player:GetMapId()
    para.lineId = params.lineId or 0
    
    if para.mapId == player:GetMapId() then
		if params.neednavportal ~= nil and params.neednavportal > 0 then
			if CheckCanNavToPos(player:GetPos(),params.targetPos) == true then
				para.mode = 0
			else
				para.mode = 3
				local portalPos = MapManager.GetPortalOfMap_PortalId(player:GetMapId(),params.neednavportal)
				para.portalPos = portalPos
				para.portalId = params.neednavportal
			end
		else
			para.mode = 0
		end
    else
        local portalPos,portalId = GetPortalPos(player:GetMapId(), para.mapId)
        para.mode = (((params.navMode == 1 or portalPos == nil) and 1) or 2)
        if  params.isShowAlert == nil or params.isShowAlert == true then
            para.isShowAlert = true
        else
            para.isShowAlert = false
        end
        
        if para.mode == 2 then
            para.portalPos = portalPos
            para.portalId = portalId
        end
    end
    
    --[[
        设置回调
    ]]
    para.endCallback  = params.callback
    para.stopCallback = params.stopCallback
    
    return para
    
end

return {
    Config      = Config,
    LogError    = LogError,
	CheckCanNavToPos = CheckCanNavToPos,
    CheckParams = CheckParams,
}