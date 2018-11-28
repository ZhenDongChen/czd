local NavigationHelper  = require("character.navigation.navigationhelper.navigationhelper")
local StateDelay        = require("character.navigation.navigationstate.statedelay")
local StateNavToFly        = require("character.navigation.navigationstate.statenavtofly")
local StateEndSet       = require("character.navigation.navigationstate.stateendset")
local StateNavToMap     = require("character.navigation.navigationstate.statenavtomap")
local StateNavToPos     = require("character.navigation.navigationstate.statenavtopos")
local StateStartSet     = require("character.navigation.navigationstate.statestartset")
local UIManager         = require("uimanager")

local NavigationStateType = {
    Stop = 0,
    Create = 1,
    Start = 2,
}


local NavigationController = Class:new()

function NavigationController:__new(player)
    self.m_Player = player
    self.m_Params = nil
    self.m_ParamsForSave = nil
    self.m_NavMode = nil
    self.m_DefaultNavMode =(((cfg.role.Const.LOCAL_NAVMESH == 1) and true) or false)
    self:Reset()
end

function NavigationController:GetNavMode()
    return self.m_DefaultNavMode
end

function NavigationController:StartNavigate(params)
    self.m_Params = params
    self.m_ParamsForSave = params
    --self:Update()
end

function NavigationController:Reset()
    self.m_NavigationState  = NavigationStateType.Stop
    self.m_StateList        = {}
    self.m_Callback         = { End = nil, Stop = nil, }
    self.m_Target           = { MapId = nil, Position = nil}
    self.m_CurrentState     = nil
    self.m_IsPause          = false
    self.m_LocalMode        = self:GetNavMode()
    self.m_Params           = nil

	self.m_Callback         = { End = nil, Stop = nil, }
	self.m_IsPause = false

    self.m_NavMode          = nil

end

function NavigationController:SetNavMode(isLocal)
    self.m_DefaultNavMode = isLocal
end

function NavigationController:CheckPos(targetPos)

	local IsWalk = NavigationHelper.CheckCanNavToPos(targetPos,self.m_Player:GetPos())
	return IsWalk
end


function NavigationController:StartNavigate2(params)

    self:Reset()
    local para = NavigationHelper.CheckParams(params,self.m_Player)
    if para == nil then
        return
    end

    --[[
        ������֮���Ĳ���
        targetPos = Ŀ���ص㣬endDir = ����ʱ����ת�ǣ� mapId, lineId= Ŀ����ͼ��endCallback = �����ص���stopCallback = ��ֹ�ص�
    ]]
    self.m_Callback.End     = para.endCallback    or function() end
    self.m_Callback.Stop    = para.stopCallback   or function() end
    self.m_Target.MapId     = para.mapId
    self.m_Target.Position  = para.targetPos
    self.m_NavMode          = para.mode
    --[[
        ��һ��������ͬͼ����
    ]]
    if para.mode == 0 then
        table.insert(self.m_StateList,
                    StateStartSet:new(self, para.mapId, para.lineId, false))            
        table.insert(self.m_StateList,
                    StateNavToPos:new(self, para.targetPos, para.stopLength, para.isAdjustByRideState, para.lengthCallback, self.m_LocalMode))            --������Ŀ����ͼ
        table.insert(self.m_StateList,
                    StateEndSet:new(self, para.endDir))                                 
    --[[
        �ڶ���������ֱ�Ӵ���ʽ��ͼ����
    ]]
    elseif para.mode == 1 then
        table.insert(self.m_StateList,
                    StateStartSet:new(self, para.mapId, para.lineId, para.isShowAlert))  --��ʼ����
        table.insert(self.m_StateList,
                    StateNavToMap:new(self, true, para.mapId, para.lineId, nil))         --������Ŀ����ͼ
--        table.insert(self.m_StateList, StateDelay:new(self, 0))                                             --�ȴ�
        table.insert(self.m_StateList,
                    StateNavToPos:new(self, para.targetPos, para.stopLength, para.isAdjustByRideState,para.lengthCallback, self.m_LocalMode))            --�ƶ���Ŀ���ص�
        table.insert(self.m_StateList,
                    StateEndSet:new(self, para.endDir))                                  --���ý�������״̬
    --[[
        �������������ٽ���ͼ�ܲ������͵�
    ]]
    elseif para.mode == 2 then
        table.insert(self.m_StateList,
                    StateStartSet:new(self, para.mapId, para.lineId, false))             --��ʼ����
        table.insert(self.m_StateList,
                    StateNavToPos:new(self, para.portalPos, nil, false,nil,self.m_LocalMode))                        --���������͵�
        table.insert(self.m_StateList,
                    StateNavToMap:new(self, false, para.mapId, para.lineId, para.portalId)) --������Ŀ����ͼ
--        table.insert(self.m_StateList, StateDelay:new(self, 0))                                             --�ȴ�
        table.insert(self.m_StateList,
                    StateNavToPos:new(self, para.targetPos, para.stopLength,para.isAdjustByRideState,para.lengthCallback, self.m_LocalMode))            --�ƶ���Ŀ���ص�
        table.insert(self.m_StateList,
                    StateEndSet:new(self, para.endDir))                                  --���ý�������״̬
    elseif para.mode == 3 then
        table.insert(self.m_StateList,
                    StateStartSet:new(self, para.mapId, para.lineId, false))             --��ʼ����
        table.insert(self.m_StateList,
                    StateNavToPos:new(self, para.portalPos, nil, false,nil,self.m_LocalMode))                        --���������͵�
        table.insert(self.m_StateList,
                    StateNavToFly:new(self)) 
        table.insert(self.m_StateList,
                    StateNavToPos:new(self, para.targetPos, para.stopLength,para.isAdjustByRideState,para.lengthCallback, self.m_LocalMode))            --�ƶ���Ŀ���ص�
        table.insert(self.m_StateList,
                    StateEndSet:new(self, para.endDir))    
    end

    self.m_NavigationState = NavigationStateType.Create
end

function NavigationController:Update()
    if self.m_IsPause == true then
        return
    end

    if self.m_Params then
        --printyellowmodule( Local.LogModuals.Navigate,"canmove",self.m_Player:CanMove())
        if self.m_Player:CanMove() == true then
            self:StartNavigate2(self.m_Params)
            self.m_Params = nil
        end
    end

    if self.m_NavigationState < NavigationStateType.Create then
        return
    end
 --   printyellow("NavigationController Loop")

    if self.m_CurrentState == nil then
        if #self.m_StateList <= 0 then
            self:EndNavigate()
            return
        else
            self.m_CurrentState = self.m_StateList[1]
            table.remove(self.m_StateList, 1)
            self.m_CurrentState:Start()

        end
    else
        if not self.m_CurrentState:IsEnd() then
            self.m_CurrentState:Update()
        else
            self.m_CurrentState = nil
        end
    end


end
--=============================================================================================
--[[
    ������ʼ������
]]
function NavigationController:OnStart()
   -- printyellow("OnStart")
    self.m_NavigationState = NavigationStateType.Start
    if self.m_Player:IsRole() then
        UIManager.call("dlguimain","SetTargetHoming",{pathFinding=true})
    end
end

function NavigationController:OnEnd()
    self.m_NavigationState = NavigationStateType.Stop
    --self:Reset()
    if UIManager.isshow("dlguimain") then
        UIManager.call("dlguimain","CloseTargetHoming")
    end
end
--=============================================================================================
function NavigationController:OnEnterMap(mapId)

    if self:IsNavigating() == false then
        return
    end
    
	if mapId == nil or self.m_Target.MapId ~= mapId then
        self:StopNavigate()
    end
end
--=============================================================================================
--[[
    ��ͣ�����¿�ʼ��������ֹͣ����
]]
function NavigationController:PauseNavigate()
    self.m_IsPause = true
end

function NavigationController:RestartNavigate(isReset)
    self.m_IsPause = false
    if isReset == true then
        self:StartNavigate(self.m_ParamsForSave)
    end
end

function NavigationController:EndNavigate()
    if self.m_Callback ~= nil and self.m_Callback.End ~= nil then
        --printyellowmodule( Local.LogModuals.Navigate,"����ʱ�ص�")
        self.m_Callback.End()
    end
    self:OnEnd()
    --printyellowmodule( Local.LogModuals.Navigate,"������������")
end

function NavigationController:StopNavigate()
	
    if self.m_Callback ~= nil and self.m_Callback.Stop ~= nil then
        --printyellowmodule( Local.LogModuals.Navigate,"ֹͣʱ�ص�")
        self.m_Callback.Stop()
    end
    self:OnEnd()
    --local TaskManager=require"taskmanager"
    --TaskManager.SetExecutingTask(0)
    --printyellowmodule( Local.LogModuals.Navigate,"�����ж�")
end

function NavigationController:IsPaused()
    return self.m_IsPause
end

function NavigationController:IsNavigating()
    return (((self.m_NavigationState == 2) and true) or false)
end

function NavigationController:GetTargetInfo()
    if self:IsNavigating() then
        return self.m_ParamsForSave.mapId,self.m_ParamsForSave.targetPos
    end
    return nil,nil
end

function NavigationController:GetTargetParams()
    if self:IsNavigating() then
        return self.m_ParamsForSave
    end
    return nil
end

function NavigationController:Restart()
    if self.m_ParamsForSave then
        self.m_Params = self.m_ParamsForSave
    end
end

function NavigationController:RestartNavigate(isReset)
    self.m_IsPause = false
    if isReset == true then
        self:StartNavigate(self.m_ParamsForSave)
    end
end
return NavigationController
