local require = require
local ExtendedGameObject = ExtendedGameObject
local Instance = require "effect.instance.instance"
local SoundInstance = Class:new(Instance)

local AudioManager = require"audiomanager"


SoundInstance.SoundType = enum
    {
        "Common",
        "Cry",
        "Weapon",
}



function SoundInstance:__new()
    Instance.__new(self)
    self.Data = nil --
end

function SoundInstance:Load(data)
    if data == nil then
        return false
    end
    --self:reset()
    self.SoundInstanceData = data
    self.StartTime = Time.time
    self.Dead = false
    return true
end

function SoundInstance:Update()
    if not self.Loaded and self.SoundInstanceData  and not self.Dead then
        if self.SoundInstanceData.StartDelay<=0 or Time.time - self.StartTime >= self.SoundInstanceData.StartDelay + self.ParentEffect.PauseTime then
            if not self:CheckCanShow() then
                self.Dead = true
                return
            end
            local pro = mathutils.Random()
            if Local.LogModuals.EffectManager then
                printyellow("pro",pro,"self.SoundInstanceData.PlayProbability",self.SoundInstanceData.PlayProbability)
            end
            --print(self.ParentEffect:Caster() )
            if self.ParentEffect:Caster() and 
                pro <=  self.SoundInstanceData.PlayProbability and 
                self.SoundInstanceData.Sound~=nil and 
                #self.SoundInstanceData.Sound>0 then
                local index = mathutils.Random(#self.SoundInstanceData.Sound)
                if Local.LogModuals.EffectManager then
                    printyellow("index",index,"self.SoundInstanceData.Sound[index]",self.SoundInstanceData.Sound[index])
                end
                local volume = self.SoundInstanceData.MinVlm + mathutils.Random() *(self.SoundInstanceData.MaxVlm - self.SoundInstanceData.MinVlm) 
                --printyellow("~~~volume",volume, SystemSetting["MusicEffect"])
                AudioManager.PlayCharacterSound(self.ParentEffect:Caster(),
                                                self.SoundInstanceData.Sound[index],
                                                volume,
                                                self.ParentEffect.SoundPriority)
                
                self.Loaded = true
            end
            self.Dead = true
        end
    end
end









return SoundInstance
