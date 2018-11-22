local MaxAudioSourceCount = 3

-----------------------------------------------------------------------------
--class: CharacterAudioSource
-----------------------------------------------------------------------------
local CharacterAudioSource = Class:new()

function CharacterAudioSource:__new(AudioSource)
    self.m_AudioSource = AudioSource
    self.m_priority = defineenum.AudioPriority.Default
    self.m_playtime = 0
end

function CharacterAudioSource:CanPlay()
    return not self.m_AudioSource.isPlaying
end 

function CharacterAudioSource:Compare(priority,playtime) 
    if self.m_priority < priority then 
        return true 
    elseif self.m_priority > priority then 
        return false
    else 
        return self.m_playtime > playtime
    end 
end 

function CharacterAudioSource:Play(audiopath,priority,volume) 
    Game.AudioManager.Instance:Play3dSound(self.m_AudioSource,audiopath,volume)
end 

-----------------------------------------------------------------------------
--class: CharacterAudioSourceManager
-----------------------------------------------------------------------------
local CharacterAudioSourceManager = Class:new() 

function CharacterAudioSourceManager:__new()
    self.m_Character = nil 
    self.m_CharacterAudioSources = {}
end

function CharacterAudioSourceManager:init(character)
    self.m_Character = character 
    self.m_CharacterAudioSources = {}
    if self.m_Character.m_Object then 
        local AudioSources = self.m_Character.m_Object:GetComponents(UnityEngine.AudioSource)
        for i = 1,AudioSources.Length do
            table.insert(self.m_CharacterAudioSources,CharacterAudioSource:new(AudioSources[i]))
        end 
        while #self.m_CharacterAudioSources < MaxAudioSourceCount do 
            local as = self.m_Character.m_Object:AddComponent(UnityEngine.AudioSource)
            as.playOnAwake = false
            as.dopplerLevel = 0
            table.insert(self.m_CharacterAudioSources,CharacterAudioSource:new(as))
        end 
    end 
end

function CharacterAudioSourceManager:GetAudioSource(ipriority) 
    for _ ,cas in ipairs(self.m_CharacterAudioSources) do 
        if cas:CanPlay() then 
            return cas 
        end 
    end
    local retcas = nil
    local time = Time.time 
    local priority = ipriority
    for _ ,cas in ipairs(self.m_CharacterAudioSources) do 
        if not cas:Compare(priority,time) then 
            retcas = cas 
            time = cas.m_playtime 
            priority = cas.m_priority
        end 
    end 
    return retcas
end 




function CharacterAudioSourceManager:Play(audiopath,ipriority,volume)
    local cas = self:GetAudioSource(ipriority)
    if cas ~=nil then 
        cas:Play(audiopath,ipriority,volume)
    end 
end 
     
   


return CharacterAudioSourceManager
