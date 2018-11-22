local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")
local BaseSound  = require("plot.plotevent.eventbase.sound")

local TalkSound = {};

-----------------------------------------------------------------------------------------------------------------------------------
TalkSound.LoadFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Loaded;
end
-----------------------------------------------------------------------------------------------------------------------------------
TalkSound.StartFunction = function(self)
    local extensionCode = self.Cutscene.m_Audio:GetRoleTypeExtensionCode()
    if self.IndexName ~= nil and self.IndexName ~= "" then
        local needExtraCode = self.Cutscene.m_Audio:NeedExtraCode(self.IndexName)
        if needExtraCode == true then
            self.audioSource = self.Cutscene.m_Audio:Play2DSound(self.IndexName .. extensionCode ,self.Looping,self.StartPlayPos)
        else
            self.audioSource = self.Cutscene.m_Audio:Play2DSound(self.IndexName ,self.Looping,self.StartPlayPos)
        end
    else
        logError("剧情音频配置错误")
        self.audioSource = nil
    end
    if self.audioSource ~= nil and self.VolumeControl == "Constant" then
        self.Cutscene.m_Audio:SetAudioSourceVolume(self.audioSource, self.VolumeValue, self.AudioMode == "BackMusic")
    end

    if self.audioSource ~= nil and self.VolumeControl == "Curve" then
        self.VolumeCurve.Curve = UnityEngine.AnimationCurve()
        for i, key in ipairs(self.VolumeCurve.KeyList) do
            self.VolumeCurve.Curve:AddKey(key)
        end
    end

    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Started;
end
-----------------------------------------------------------------------------------------------------------------------------------
TalkSound.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime
    if self.audioSource ~= nil then
        if self.VolumeControl == "Curve" then
            local currentVolume = self.VolumeCurve.Curve:Evaluate(self.CurrentTime)
            self.Cutscene.m_Audio:SetAudioSourceVolume(self.audioSource, currentVolume, self.AudioMode == "BackMusic")
        else
            self.Cutscene.m_Audio:SetAudioSourceVolume(self.audioSource, self.VolumeValue, self.AudioMode == "BackMusic")
        end
    end

end
-----------------------------------------------------------------------------------------------------------------------------------
TalkSound.EndFunction = function(self)
    if self.audioSource ~= nil then
       	if self.audioSource.isPlaying == true then
       		self.audioSource:Stop();
       	end
    end
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
TalkSound.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
TalkSound.SampleFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
return TalkSound;


--setmetatable(TalkSound,{__index = BaseSound})
