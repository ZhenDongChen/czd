local require, print = require, print
local Character = require("character.character")
local ConfigManager = require("cfg.configmanager")
local TalismanConfig            = require("character.talisman.talismanconfig")

local Talisman = Class:new(Character)

function Talisman:__new()
    Character.__new(self)
end

function Talisman:init(talisman, player, talismanId)
    if talismanId ~= nil then
        self.m_Id = talismanId
    else
        if talisman and talisman.ID then
            self.m_Id = talisman.ID
        elseif player and player.m_Id then
            self.m_Id = player.m_Id
        else
            self.m_Id = 0
        end
    end
    self.m_CsvId    = talisman:GetConfigId()

    self.IsSettedMaster = false
    
    self.m_ObjectName = string.format( "Talisman_%s", tostring(player.m_Id))
    self.m_ObjectSetName = self.m_ObjectName
    self.m_Talisman = talisman
    self.m_Master = player

    self.m_LastSpeed = 0  
    self.m_CsControl = nil
    local itemConfig = self.m_Talisman:GetConfigData()
    local modelData = ConfigManager.getConfigData("model", itemConfig.modelpath)
    self:CriticalLoadModel({modelData,modelData,false,nil})

end

--创角界面专用
function Talisman:init2(talismanId, player)
    self.m_CsvId    = talismanId

    self.IsSettedMaster = false

    self.m_ObjectName = string.format( "Talisman_%s", tostring(player.m_Id))
    self.m_ObjectSetName = self.m_ObjectName
    self.m_Master = player

    self.m_LastSpeed = 0
    self.m_CsControl = nil

    local itemConfig =  ConfigManager.getConfigData("talismanbasic", talismanId)
    local modelData = ConfigManager.getConfigData("model", itemConfig.modelpath)
    self:CriticalLoadModel({modelData,modelData,false,nil})

end

function Talisman:OnLoaded(go)
    Character.OnLoaded(self, go)
    if TalismanConfig.LuaMode == false then
        if go ~= nil then
            self.m_CsControl = go:AddComponent("Game.TalismanControl")
            if self.m_CsControl.isActiveAndEnabled == false then
                self.m_CsControl:Invoke("Awake",0)
            end
            self:SetCsControl()
        end
    end
end

function Talisman:SetCsControl()
    if self.m_CsControl and self.m_Master and self.m_Master.m_Object then
        self.m_CsControl.masterTransform = self.m_Master.m_Object.transform 
        self.m_CsControl.autoUpdate = (not TalismanConfig.LuaUpdate)
        self.IsSettedMaster = true
        self.m_CsControl.FollowD = 5
        self.m_CsControl.IdleP = 1.5
        
    end
end


function Talisman:Equal(talisman)
    if self.m_Talisman == talisman then
        return true
    else
        return false
    end
end

function Talisman:UpdateCsControl()
    if TalismanConfig.LuaMode == false then
        if self.IsSettedMaster == false and self.m_Master.m_Object then
            self:SetCsControl()
        end
        if self.m_CsControl then
            if self.m_Master.m_Attributes[cfg.fight.AttrId.MOVE_SPEED] ~= self.m_LastSpeed then
                self.m_LastSpeed = self.m_Master.m_Attributes[cfg.fight.AttrId.MOVE_SPEED]
                self.m_CsControl:SetFloat("MaxSpeed", self.m_LastSpeed * SCALE_XY_FRACTION*10)
            end
        end
    end
    if self.m_CsControl then
        self.m_CsControl:OnUpdate(Time.deltaTime)
    end
end

function Talisman:Update()
    Character.Update(self)

end

function Talisman:SetActive(active)
    if self.m_Object then
        self.m_Object:SetActive(active)
    end
end

function Talisman:SetPos(position)
    self.m_Pos = position
end

function Talisman:GetPos()
    return self.m_Pos
end

function Talisman:SetPlaySkill(value)
    self:SetActive(not value)
end

function Talisman:SwitchToIdle()

end

function Talisman:SwitchToFollow()

end

return Talisman
