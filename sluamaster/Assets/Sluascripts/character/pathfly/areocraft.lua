local ConfigManager = require("cfg.configmanager")
local SceneManager = require("scenemanager")
local Character = require("character.character")

local Areocraft = Class:new(Character)

function Areocraft:__new()
    Character.__new(self)
    self.m_Character = nil
   
    self.m_WaitForDestroy = false
    self.m_IsDestroyed = false

    self.m_CurrentAnimationName = nil
end

function Areocraft:init(character)
    self.m_Character = character
    self.m_Index = cfg.pathfly.Areocraft.defaultmodelname
    self.m_Id = -self.m_Character.m_Id
    self.m_ObjectName = string.format( "AreoCraft_%s", tostring(self.m_Character.m_Id))
    self.m_ObjectSetName = self.m_ObjectName
    self.m_Name =  string.format( "%s(%s)", self.m_Index, self.m_Character.m_Name )

    local modelData = ConfigManager.getConfigData("model", self.m_Index)
    self:CriticalLoadModel({modelData,modelData,false,nil})

    self.m_WaitForDestroy = false
    self.m_IsDestroyed = false
end

function Areocraft:SetPositionStart()
    if self.m_Object then
        self:SetPos(self.m_Character:GetPos())
        local playerRotation = self.m_Character:GetRotation()
        self:SetEulerAngleImmediate(playerRotation.eulerAngles)
        self.m_Object.transform.localScale = Vector3(1,1,1)
    end
end

function Areocraft:SetPositionEnd()
    if self.m_Object then
        self:SetPos(self.m_Character:GetPos())
        local playerRotation = self.m_Character:GetRotation()
        self:SetEulerAngleImmediate(playerRotation.eulerAngles)
        self.m_Object.transform.localScale = Vector3(1,1,1)
    end
end


function Areocraft:update()
    self:SetPos(self.m_Character:GetPos())
    local playerRotation = self.m_Character:GetRotation()
    self:SetEulerAngle(playerRotation.eulerAngles)
    Character.update(self)
    if self.m_WaitForDestroy then
        if self:IsPlaying() == false then
            self:remove()
            self.m_Character.m_Areocraft = nil
        end
    end
end
function Areocraft:SetPos(vecPos)
    if vecPos then
        self.m_Pos = vecPos
    end
end

function Areocraft:OnPathFlyEnd()
    self:SetPositionEnd()
    self.m_WaitForDestroy = true
end



--=================================================================================================
function Areocraft:IsPlaying()
    if self.m_CurrentAnimationName == nil then
        return false
    end
    return self:IsPlayingAction(self.m_CurrentAnimationName)
end

function Areocraft:FlyStart()
    --printyellow("cfg.pathfly.Areocraft.startanimname",cfg.pathfly.Areocraft.startanimname)
    self.WorkMgr:ShutAllWorks()
    self:PlayAction(cfg.pathfly.Areocraft.startanimname)
    self.m_CurrentAnimationName = cfg.pathfly.Areocraft.startanimname
    self:SetPositionStart()
end

function Areocraft:FlyLoop()
    --printyellow("cfg.pathfly.Areocraft.loopanimname",cfg.pathfly.Areocraft.loopanimname)
    self:PlayLoopAction(cfg.pathfly.Areocraft.loopanimname)
    self.m_CurrentAnimationName = cfg.pathfly.Areocraft.loopanimname
end

function Areocraft:FlyEnd()
    --printyellow("cfg.pathfly.Areocraft.endanimname",cfg.pathfly.Areocraft.endanimname)
    self:PlayAction(cfg.pathfly.Areocraft.endanimname)
    self.m_CurrentAnimationName = cfg.pathfly.Areocraft.endanimname
end


return Areocraft