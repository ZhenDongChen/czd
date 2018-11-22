local require = require
local Instance = require "effect.instance.instance"
local CameraShakeManager = require "effect.camerashakemanager"

local CameraShakeInstance = Class:new(Instance)

function CameraShakeInstance:__new()
    Instance.__new(self)
    self:reset()
end

function CameraShakeInstance:reset()
    Instance.reset(self)
    self.CameraShakeData = nil

end

function CameraShakeInstance:Destroy()
    if not self.Dead then
        self:reset()
    end
end

function CameraShakeInstance:Load(data)
    if data == nil then
        self:Destroy()
        return false
    end
    --self:reset()
    self.CameraShakeData = data
    self.StartTime = Time.time
    return true
end

function CameraShakeInstance:Update()
    Instance.Update(self)
    if not self.Loaded and self.CameraShakeData  and not self.Dead then
        if self.CameraShakeData.StartDelay<=0 or Time.time - self.StartTime >= self.CameraShakeData.StartDelay + self.ParentEffect.PauseTime then
            if not self:CheckCanShow() then
                self:Destroy()
                return
            end
            self.Loaded = true
            if self.ParentEffect then
                local pos
                if self.ParentEffect:Caster() then 
					pos = self.ParentEffect:Caster().m_Pos 
				else 
					pos = self.ParentEffect.TargetPos 
				end
                CameraShakeManager.StartNewShake(self.CameraShakeData,pos)
            end
        end
    end
end





return CameraShakeInstance
