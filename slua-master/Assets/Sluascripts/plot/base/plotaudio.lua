local AudioManager      = require("audiomanager")
local ConfigManager     = require("cfg.configmanager")
local SystemManager     = require("character.settingmanager")

local PlotAudio = Class:new()

function PlotAudio:__new(cutscene, config)
    self.m_Cutscene = cutscene
    self.m_Config = config
        
    self.m_CanPlay = true
    
    self.m_Object = nil
    
    self.m_BackMusicVolume = 1
    self.m_EffectSoundVolume = 1
    
    self.m_CameraTransform = nil
end

function PlotAudio:GetCameraPos()
    return self.m_Cutscene.m_Camera:GetMainCameraPosition()
end

function PlotAudio:OnStart()
    if self.m_Config.independentMusic then
        AudioManager.StopBackgroundMusic()
    end
    AudioManager.LockAudio()
    local SystemSetting = SystemManager.GetSettingSystem()
    
    self.m_BackMusicVolume = SystemSetting["Music"]
    self.m_EffectSoundVolume = SystemSetting["MusicEffect"]
    
    if self.m_Object == nil then
        self.m_Object = UnityEngine.GameObject("Audio")
        self.m_Object.transform.parent = self.m_Cutscene.m_GameObject.transform
    end
    
    self.m_CameraTransform = self.m_Cutscene.m_Camera:GetCameraTransform()
end

function PlotAudio:OnEnd()
    AudioManager.UnLockAudio()
    if self.m_Config.independentMusic == true then
        AudioManager.RestartBackgroundMusic()
    end
    
end

function PlotAudio:GetConfigPath(index, isBackMusic)
    local plotassets = ConfigManager.getConfigData("plotassets",index)
    if plotassets == nil then
        logError("Can't find Plot Resources: " .. tostring(index))
        return nil
    else
        if isBackMusic == true then
            if plotassets.detailtype == "music" then
                return plotassets.path
            else
                logError("BackMusic config error: " .. tostring(index))
                return nil
            end
        else
            if plotassets.detailtype == "sound" then
                return plotassets.path
            else
                logError("Sound config error: " .. tostring(index))
                return nil 
            end
        end
    end
end

function PlotAudio:GetAudioBundlePath(path,isBackMusic)
	local str1 = string.sub(path,string.find(path,"[%w_]+/"))
	local str2 = string.sub(path,string.find(path,"[%w_]+%."))
    return str1 .. "a_" .. str2 .. "bundle"
end

function PlotAudio:GetAudioPathInfo(index, isBackMusic)
    local path, bundlePath
    path = self:GetConfigPath(index,isBackMusic)
    if path ~= nil then
        bundlePath = self:GetAudioBundlePath(path, isBackMusic)
    else
        logError("找不到剧情音频配置：" .. index)
    end
    return path, bundlePath
end

function PlotAudio:SetAudioSourceVolume(audioSource, volume, isBackMusic)
    if isBackMusic == true then
        audioSource.volume = volume * self.m_BackMusicVolume
    else
        audioSource.volume = volume * self.m_EffectSoundVolume
    end
end

function PlotAudio:SetAudioSourcePosition(audioSource, position)
    audioSource.position = position
end
--播放2D声音
function PlotAudio:Play2DSound(index,isLoop,startPos)
    if self.m_CanPlay == false then
        return nil
    end
    
    local path, bundlePath = self:GetAudioPathInfo(index, false)
    if path ~= nil and path ~= "" and bundlePath ~= nil and bundlePath ~= "" then
        local cameraPosition = self.m_CameraTransform.position
        return Game.Director.Instance:Play2DSound(self.m_Object, bundlePath,isLoop,startPos);
    end
    return nil
end
--播放3D声音
function PlotAudio:Play3DSound(index,playPos,isLoop,startPos)
    if self.m_CanPlay == false then 
        return nil
    end
    local path, bundlePath = self:GetAudioPathInfo(index, false)
    if path ~= nil and path ~= "" and bundlePath ~= nil and bundlePath ~= "" then
        return Game.Director.Instance:Play3DSound(self.m_Object,bundlePath,playPos,isLoop,startPos);
    end
    return nil
end
--播放背景音乐
function PlotAudio:PlayBackMusic(index,isLoop,startPos)
    if self.m_CanPlay == false then 
        return nil
    end
    local path, bundlePath = self:GetAudioPathInfo(index, true)
    local cameraPosition = self.m_CameraTransform.position
    --Delay = 0, Immediate = 1, Stream = 2
    --local plotAudioSource = PlotDirector.PlotAudioSource.Create(self.m_Object, index)
    --return plotAudioSource:PlayAudio(bundlePath, false, 2, cameraPosition, isLoop, startPos);
    if path ~= nil and path ~= "" and bundlePath ~= nil and bundlePath ~= "" then
        return Game.Director.Instance:PlayBackMusic(self.m_Object, bundlePath,isLoop,startPos);
    end
    return nil
end

function PlotAudio:NeedExtraCode(index)
    local asset = ConfigManager.getConfigData("plotassets", index)
    if asset then
        return asset.extraasset
    else
        logError("找不到剧情音频配置：",index)
        return false
    end
end


function PlotAudio:GetRoleTypeExtensionCode()
    local gender = PlayerRole:Instance().m_Gender
    local profession = PlayerRole:Instance().m_Profession
    local genderStr, professtionStr
    genderStr = (gender == cfg.role.GenderType.MALE) and "m" or "f"
    if profession == cfg.role.EProfessionType.QINGYUNMEN then
        professtionStr = "q"
    elseif profession == cfg.role.EProfessionType.TIANYINSI then
        professtionStr = "t"
    elseif profession == cfg.role.EProfessionType.GUIWANGZONG then
        professtionStr = "g"
    elseif profession == cfg.role.EProfessionType.HEHUANPAI then
        professtionStr = "h"
    else
        logError("错误的门派类型：",profession)
        professtionStr = "q"
    end
    return string.format( "_%s%s", professtionStr, genderStr)
end



return PlotAudio