local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")
local PlaySound = {};
-----------------------------------------------------------------------------------------------------------------------------------
PlaySound.LoadFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Loaded;
end
-----------------------------------------------------------------------------------------------------------------------------------
PlaySound.StartFunction = function(self)

    local playPosition = self.Position
    if self.AttachedObject == true then
        self.Object = self.Cutscene.m_Pool:Get(self.ObjectName)
        if self.Object then
            playPosition = self.Position + self.Object.transform.position
        end
    end
    if self.IndexName ~= nil and self.IndexName ~= "" then
        if self.AudioMode == "Sound2D" then
            self.audioSource = self.Cutscene.m_Audio:Play2DSound(self.IndexName,self.Looping,self.StartPlayPos)
        elseif self.AudioMode == "Sound3D" then
            self.audioSource = self.Cutscene.m_Audio:Play3DSound(self.IndexName,playPosition,self.Looping,self.StartPlayPos)
        elseif self.AudioMode == "BackMusic" then
            self.audioSource = self.Cutscene.m_Audio:PlayBackMusic(self.IndexName,self.Looping,self.StartPlayPos)
        end
    else
        logError("剧情音频索引配置为空")
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
PlaySound.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime
    if self.audioSource ~= nil then
        if self.VolumeControl == "Curve" then
            local currentVolume = self.VolumeCurve.Curve:Evaluate(self.CurrentTime)
            self.Cutscene.m_Audio:SetAudioSourceVolume(self.audioSource, currentVolume, self.AudioMode == "BackMusic")
        else
            self.Cutscene.m_Audio:SetAudioSourceVolume(self.audioSource, self.VolumeValue, self.AudioMode == "BackMusic")
        end
        if self.AttachedObject == true then
            if self.Object and self.audioSource then
                self.Cutscene.m_Audio:SetAudioSourcePosition(self.audioSource, self.Position + self.Object.transform.position)
            end
        end
    end

end
-----------------------------------------------------------------------------------------------------------------------------------
PlaySound.EndFunction = function(self)
    if self.audioSource ~= nil then
       	if self.audioSource.isPlaying == true then
       		self.audioSource:Stop();
       	end
    end
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
PlaySound.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
PlaySound.SampleFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
return PlaySound;
