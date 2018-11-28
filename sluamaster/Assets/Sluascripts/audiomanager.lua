local print = print
local printt = printt
local AudioManager = Game.AudioManager
local defineenum = require"defineenum"
local MonsterAudioType = defineenum.MonsterAudioType
local ConfigManager = require"cfg.configmanager"
local Define        = require"define"
local ResourceManager = require("resource.resourcemanager")
local MapType = {}
local delayedPlayList = {}
local CharacterType = defineenum.CharacterType
local SettingManager
local isLocked = false
local audioSource
local currBGM = nil
local timer
local timeBGM
local volumeBGM
local pathBGM

local FootStepMap = {
    [CharacterType.PlayerRole] = cfg.audio.SoundTypes.ROLEFOOTSTEP,
    [CharacterType.Mount] = cfg.audio.SoundTypes.MOUNTFOOTSTEP,
}

local function PlayMonsterAudio(type,monsterData,pos)
    if isLocked == true then
        return
    end
    local SystemSetting = SettingManager.GetSettingSystem()
    local monsterAudioInfo = ConfigManager.getConfigData("monstervoice",monsterData[MapType[type]])
    if not monsterAudioInfo then return end
    local playrate = monsterAudioInfo.playrate
    local random1 = math.random()
    if playrate >= random1 then
        if #monsterAudioInfo.voicelist > 0 then
            local rand = math.random(#monsterAudioInfo.voicelist)
            local audio = monsterAudioInfo.voicelist[rand]
            local audioInfo = ConfigManager.getConfigData("audio",audio)
            if not audioInfo then return end
            local path = string.format("audio/a_%s.bundle",audioInfo.cliplist)
            local volume = math.random()*(monsterAudioInfo.maxvolume- monsterAudioInfo.minvolume)+monsterAudioInfo.minvolume
            if SystemSetting["MusicEffect"] then
                Game.AudioManager.Instance:Play3dSound(path,pos,volume * SystemSetting["MusicEffect"])
            end
        end
    else
        return
    end
end

local function PlaySoundEffect(type,pos)
    if isLocked == true then
        return
    end
    local SystemSetting = SettingManager.GetSettingSystem()
    local soundeffect = ConfigManager.getConfigData("soundeffects",type)
    if not soundeffect then return end
    local soundlist = soundeffect.soundlist
    if #soundlist ==0 then return end
    local rand = math.random(#soundlist)
    local sound = soundlist[rand]
    local audioInfo = ConfigManager.getConfigData("audio",sound)
    local playrate = audioInfo.probability
    local randomPlay = math.random()
    if playrate >= randomPlay then
        local randomidle = math.random()
        local randomvolume = math.random()
        local idletime = audioInfo.minidletime + (audioInfo.maxidletime - audioInfo.minidletime) * randomidle
        local volume = audioInfo.minvolume + (audioInfo.maxvolume - audioInfo.minvolume) * randomvolume
        local tb = {}
        tb.pos = pos
        tb.idletime = idletime
        tb.volume = volume * (SystemSetting["MusicEffect"] or 0)
        tb.elapsedtime = 0
        local path = string.format("audio/a_%s.bundle",audioInfo.cliplist)
        tb.clip = path
        table.insert(delayedPlayList,tb)
    end
end

local function Play2dSound(audioid)
    if isLocked == true then
        return
    end
    if audioid == 0 then return end
    local SystemSetting = SettingManager.GetSettingSystem()
    local audioInfo = ConfigManager.getConfigData("audio",audioid)
    local path = string.format("audio/a_%s.bundle",audioInfo.cliplist)
    local rand = math.random()
    local randVolume = (audioInfo.maxvolume - audioInfo.minvolume) * rand + audioInfo.minvolume
    local volume = (SystemSetting["MusicEffect"] or 0) * randVolume
    AudioManager.Instance:Play2dSound(path, volume)
end

local function PlayAduioByAudioClip(audioid,func)

    if isLocked == true then
        return
    end
    if audioid == 0 then return end
    local SystemSetting = SettingManager.GetSettingSystem()
    local audioInfo = ConfigManager.getConfigData("audio",audioid)
    local path = string.format("audio/a_%s.bundle",audioInfo.cliplist)
    local rand = math.random()
    local randVolume = (audioInfo.maxvolume - audioInfo.minvolume) * rand + audioInfo.minvolume
    local volume = (SystemSetting["MusicEffect"] or 0) * randVolume
    ResourceManager.LoadAudio(path,nil,function(obj)
        if IsNull(obj) then
            return
        end
        AudioManager.Instance:Play2dSound(obj,volume)
        local audioClip = LuaHelper.GetAudioClip(obj)
        func(audioClip.length)
    end)
end

local function PlaySoundBySelfAudioSource(audioid,audioSource)
    if isLocked == true then
        return
    end
    local SystemSetting = SettingManager.GetSettingSystem()
    local audioInfo = ConfigManager.getConfigData("audio",audioid)
    local path = string.format("audio/a_%s.bundle",audioInfo.cliplist)
    local rand = math.random()
    local randVolume = (audioInfo.maxvolume - audioInfo.minvolume) * rand + audioInfo.minvolume
    local volume = (SystemSetting["MusicEffect"] or 0) * randVolume
    AudioManager.Instance:PlaySound(path, audioSource,volume)
end

local function PlayBackgroundMusic(id,restart,timeDelay)
    if isLocked == true then
        return
    end
    if id == 0 then return end
    local SystemSetting = SettingManager.GetSettingSystem()
    currBGM = id
    local audioInfo = ConfigManager.getConfigData("audio",id)
    if not audioInfo then return end
    local settingVolume = SystemSetting["Music"] or 1
    local volume = settingVolume * audioInfo.minvolume
    if audioInfo then
        local path = string.format("audio/a_%s.bundle",audioInfo.cliplist)
        local PlotManager = require"plot.plotmanager"
        volumeBGM = volume
        pathBGM = path
        timeBGM = timeDelay or 3
        -- if timer == nil then
        --     timer = Timer.New(function()
        --         if not PlotManager.IsPlayingCutscene() then
        --             printyellow("play bg music")
        --             AudioManager.Instance:PlayBgMusic(path,volume)
        --         end
        --     end,3)
        -- else
        --     timer:Reset(function()
        --         if not PlotManager.IsPlayingCutscene() then
        --             printyellow("play bg music")
        --             AudioManager.Instance:PlayBgMusic(path,volume)
        --         end
        --     end,3)
        -- end


    end
end
local function StopBackgroundMusic()
    local audioSource = cameraObject:GetComponent("AudioSource")
    if audioSource then
        audioSource:Stop()
    end
end
local function RestartBackgroundMusic()
 --   local audioSource = cameraObject:GetComponent("AudioSource")
--    if audioSource then
--        audioSource:Play()
--    end
    PlayBackgroundMusic(currBGM,true,0.5)
end

local function SetBackgroundMusicVolume(volume)
    local audioSource = cameraObject:GetComponent("AudioSource")
    if audioSource then
        if not audioSource.enabled and volume>0.01 then
            PlayBackgroundMusic(currBGM,true)
        end
        audioSource.volume = volume
    end
end

local function SetMuteBackgroundMusic(ismute)
    local audioSource = cameraObject:GetComponent("AudioSource")
    if audioSource then
        audioSource.mute = ismute
    end
end


local function PlayCharacterSound(character,audioname,volume,ipriority)
    local priority = ipriority or defineenum.AudioPriority.Default
    local audiopath = string.format("audio/a_%s.bundle",audioname)
    local SystemSetting = SettingManager.GetSettingSystem()
    --[[
    printyellow("PlayCharacterSound",
                character:IsRole(),
                audioname,
                volume,
                SystemSetting["MusicEffect"],
                utils.getenumname(defineenum.AudioPriority,priority))
    --]]
    if SystemSetting["MusicEffect"] then
        if character:IsRole() then         
            character:Play3dSound(audiopath,priority,volume*SystemSetting["MusicEffect"])
        else
            AudioManager.Instance:PlaySkillSound(audiopath,character:GetRefPos(),volume*SystemSetting["MusicEffect"],45+character:GetBodyRadius())
        end
    end
end

local function update()
    if isLocked == true then
        return
    end
    for i,v  in pairs(delayedPlayList) do
        v.elapsedtime = v.elapsedtime + Time.deltaTime
        if v.elapsedtime > v.idletime then
            Game.AudioManager.Instance:Play3dSound(v.clip,v.pos,v.volume)
            table.remove(delayedPlayList,i)
        end
    end
    if timeBGM then
        timeBGM = timeBGM - Time.deltaTime
        if timeBGM <= 0 then
            local plotmanager = require"plot.plotmanager"
            if not plotmanager.IsPlayingCutscene() then
              --   printyellow("play bg music",pathBGM,volumeBGM)

                 AudioManager.Instance:PlayBgMusic(pathBGM,volumeBGM)
                 timeBGM = nil
            end
        end
    end
end

local function init()
    timeBGM = nil
    gameevent.evt_update:add(update)
    MapType[MonsterAudioType.BEATTACK] = "beattackvoice"
    MapType[MonsterAudioType.DEAD] = "deadvoice"
    MapType[MonsterAudioType.PATROL] = "patrolvoice"
    SettingManager = require "character.settingmanager"
end

local function LockAudio()
    isLocked = true
end

local function UnLockAudio()
    isLocked = false
end

local function Stop2DSound()
    if not audioSource then
        audioSource = LuaHelper.GetComponent(UICamera.currentCamera.gameObject,"AudioSource")
    end
    if audioSource then
        audioSource:Stop()
    end
end

return {
    init = init,

    PlayMonsterAudio = PlayMonsterAudio,
    PlayBackgroundMusic = PlayBackgroundMusic,
    StopBackgroundMusic = StopBackgroundMusic,
    RestartBackgroundMusic = RestartBackgroundMusic,
    SetBackgroundMusicVolume = SetBackgroundMusicVolume,
    SetMuteBackgroundMusic = SetMuteBackgroundMusic,
    PlaySoundEffect = PlaySoundEffect,
    PlayCharacterSound = PlayCharacterSound,
    Play2dSound = Play2dSound,
    PlaySoundBySelfAudioSource = PlaySoundBySelfAudioSource,
    LockAudio = LockAudio,
    UnLockAudio = UnLockAudio,
    PlayAduioByAudioClip = PlayAduioByAudioClip,
    Stop2DSound     = Stop2DSound,
}
