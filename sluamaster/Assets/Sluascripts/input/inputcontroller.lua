local print          = print
local require        = require
local mathutils = require"common.mathutils"
local InputController = Class:new()
local utils         = require"common.utils"

InputController.OperateType = enum{
    "CLICK=1",
    "DRAG=2",
    "PRESS=3",
}

function InputController:__new()
    self.m_MaxElapsedTime = 0.3
    self.m_MaxElapsedDist = 30
    self.m_Controls = {}
    -- windows editor callback
    self.m_fOnClick = {}
    self.m_fOnPress = {}
    self.m_fOnPressing = {}
    self.m_fOnPressEnd = {}
    self.m_fOnDrag = {}
    self.m_fOnDraging = {}
    self.m_fOnDragEnd = {}
    -- touch callback
    self.m_tOnClick = nil
    self.m_tOnDrag = nil
    self.m_tOnDraging = nil
    self.m_tOnDragEnd = nil
    self.m_tOnPress = nil
    self.m_tOnPressing = nil
    self.m_tOnPressEnd = nil

    self.m_CurrentClick = {}
    self.m_CurrentDrag = {}
    self.m_CurrentPress = {}

    self.m_isWindowsPlatform = false
    if LuaHelper.IsWindowsEditor() or Application.platform == UnityEngine.RuntimePlatform.WindowsPlayer then
        self.m_isWindowsPlatform = true
    end

end



function InputController:Instance()
    local obj = _G.InputController
    if obj then return obj end
    obj = InputController:new()
    _G.InputController = obj
    return obj
end

function InputController:init()

end

function InputController:GetTouchIndexByFingerId(fingerid)
    for i=0,Input.touchCount-1 do
        local touch = Input.GetTouch(i)
        if touch.fingerId == fingerid then
            return i
        end
    end
    return nil
end

function InputController:GetTouchByFingerId(fingerid)
    for i=0,Input.touchCount - 1 do
        local touch = Input.GetTouch(i)
        if touch.fingerId == fingerid then
            return touch
        end
    end
    return nil
end

function InputController:GetControlIndex(index)
    if self.m_isWindowsPlatform then
        return index
    else
        local touch = Input.GetTouch(index)
        return touch.fingerId
    end
end

function InputController:RegisterOnClick(func,id)
    if self.m_isWindowsPlatform then
        self.m_fOnClick[id] = func
    else
        self.m_tOnClick = func
    end
end
function InputController:RegisterOnPress(func,id)
    if self.m_isWindowsPlatform then
        self.m_fOnPress[id] = func
    else
        self.m_tOnPress = func
    end
end
function InputController:RegisterOnPressing(func,id)
    if self.m_isWindowsPlatform then
        self.m_fOnPressing[id] = func
    else
        self.m_tOnPressing = func
    end
end
function InputController:RegisterOnPressEnd(func,id)
    if self.m_isWindowsPlatform then
        self.m_fOnPressEnd[id] = func
    else
        self.m_tOnPressEnd = func
    end
end
function InputController:RegisterOnDrag(func,id)
    if self.m_isWindowsPlatform then
        self.m_fOnDrag[id] = func
    else
        self.m_tOnDrag = func
    end
end
function InputController:RegisterOnDraging(func,id)
    if self.m_isWindowsPlatform then
        self.m_fOnDraging[id] = func
    else
        self.m_tOnDraging = func
    end
end
function InputController:RegisterOnDragEnd(func,id)
    if self.m_isWindowsPlatform then
        self.m_fOnDragEnd[id] = func
    else
        self.m_tOnDragEnd = func
    end
end

function InputController:JudgeBegin(id)
    if self.m_isWindowsPlatform then
        return Input.GetMouseButtonDown(id)
    else
        local touch = self:GetTouchByFingerId(id)
        if not touch then return false end
        return touch.phase == TouchPhase.Began
    end
end

function InputController:JudgeEnd(id)
    if self.m_isWindowsPlatform then
        return Input.GetMouseButtonUp(id)
    else
        local touch = self:GetTouchByFingerId(id)
        if not touch then return true end
        return touch.phase == TouchPhase.Ended or touch.phase == TouchPhase.Canceled
    end
end

function InputController:GetOperatePosition(id)
    if self.m_isWindowsPlatform then
        return Input.mousePosition
    else
        local touch = self:GetTouchByFingerId(id)
        if not touch then return end
        return touch.position
    end
end

function InputController:GetOperateCount()
    if self.m_isWindowsPlatform then
        return 2  -- 3 - 1
    else
        return Input.touchCount - 1
    end
end

function InputController:GetCurrentClicks()
    return self.m_CurrentClick
end

function InputController:GetCurrentDrags()
    return self.m_CurrentDrag
end

function InputController:GetCurrentPresses()
    return self.m_CurrentPress
end

function InputController:GetCallBackOnClick(id)
    if self.m_isWindowsPlatform then
        return self.m_fOnClick[id]
    else
        return self.m_tOnClick
    end
end

function InputController:GetCallBackOnPress(id)
    if self.m_isWindowsPlatform then
        return self.m_fOnPress[id]
    else
        return self.m_tOnPress
    end
end

function InputController:GetCallBackOnPressing(id)
    if self.m_isWindowsPlatform then
        return self.m_fOnPressing[id]
    else
        return self.m_tOnPressing
    end
end

function InputController:GetCallBackOnPressEnd(id)
    if self.m_isWindowsPlatform then
        return self.m_fOnPressEnd[id]
    else
        return self.m_tOnPressEnd
    end
end

function InputController:GetCallBackOnDrag(id)
    if self.m_isWindowsPlatform then
        return self.m_fOnDrag[id]
    else
        return self.m_tOnDrag
    end
end

function InputController:GetCallBackOnDraging(id)
    if self.m_isWindowsPlatform then
        return self.m_fOnDraging[id]
    else
        return self.m_tOnDraging
    end
end

function InputController:GetCallBackOnDragEnd(id)
    if self.m_isWindowsPlatform then
        return self.m_fOnDragEnd[id]
    else
        return self.m_tOnDragEnd
    end
end

function InputController:CheckState(id)
    if self.m_isWindowsPlatform then
        return Input.GetMouseButton(id)
    else
        local touch = self:GetTouchByFingerId(id)
        if not touch then return false end
        return touch.phase == TouchPhase.Moved or touch.phase == TouchPhase.Stationary
    end
end

function InputController:Update()
    utils.clear_table(self.m_CurrentClick)
    for id,control in pairs(self.m_Controls) do
        local position = self:GetOperatePosition(id)
        control.m_ElapsedTime = control.m_ElapsedTime + Time.deltaTime
        if position and control.m_CurrentPos then
            control.m_ElapsedDist = control.m_ElapsedDist + mathutils.Vector2Dist(control.m_CurrentPos,position)
        end
        control.m_CurrentPos = position
        if control.m_ElapsedTime>self.m_MaxElapsedTime and control.state == InputController.OperateType.CLICK then
            local callback = nil
            if control.m_ElapsedDist > self.m_MaxElapsedDist then
                control.state = InputController.OperateType.DRAG
                callback = self:GetCallBackOnDrag(id)
                self.m_CurrentDrag[id] = control
            else
                control.state = InputController.OperateType.PRESS
                callback = self:GetCallBackOnPress(id)
                self.m_CurrentPress[id] = control
            end
            if callback then
                callback()
            end
        end
    end
    for idx=0,self:GetOperateCount() do
        local i = self:GetControlIndex(idx)
        local control = self.m_Controls[i]
        if control then
            if self:JudgeEnd(i) then
                local callback = nil
                if control.state == InputController.OperateType.CLICK then
                    callback = self:GetCallBackOnClick(i)
                    self.m_CurrentClick[i] = control
                elseif control.state == InputController.OperateType.PRESS then
                    callback = self:GetCallBackOnPressEnd(i)
                    self.m_CurrentPress[i] = nil
                elseif control.state == InputController.OperateType.DRAG then
                    callback = self:GetCallBackOnDragEnd(i)
                    self.m_CurrentDrag[i] = nil
                end
                if callback then
                    callback()
                end
                self.m_Controls[i] = nil
            else
                local ret = self:CheckState(i)
                local callback = nil
                if ret then
                    if control.state == InputController.OperateType.PRESS then
                        callback = self:GetCallBackOnPressing(i)
                    elseif control.state == InputController.OperateType.DRAG then
                        callback = self:GetCallBackOnDraging(i)
                    end
                    if callback then callback() end
                else
                    if control.state == InputController.OperateType.PRESS then
                        self.m_CurrentPress[i] = nil
                        callback = self:GetCallBackOnPressEnd(i)
                        self.m_Controls[i] = nil
                    elseif control.state == InputController.OperateType.DRAG then
                        self.m_CurrentDrag[i] = nil
                        callback = self:GetCallBackOnDragEnd(i)
                        self.m_Controls[i] = nil
                    end
                    if callback then callback() end
                end
            end
        else
            if not control and self:JudgeBegin(i) then
                local control = {}
                control.m_ElapsedTime = 0
                control.m_ElapsedDist = 0
                control.m_CurrentPos = self:GetOperatePosition(i)
                control.state = InputController.OperateType.CLICK
                self.m_Controls[i] = control
            end
        end
    end
end

return InputController
