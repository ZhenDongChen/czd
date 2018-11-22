local EffectData = Class:new()

function EffectData:__new()
    self:reset()
end


function EffectData:reset()
  self.InstanceDatas = {}
  self.CameraShakeDatas = {}
  self.SoundDatas = {}
  self.Id = 0
  self.Life = 0
end


function EffectData:PreLoad()
  self.InstanceDatas = {}
  self.CameraShkeDatas = {}
  self.SoundDatas = {}
end

function EffectData:AddEffectData(data)
  table.insert(self.InstanceDatas,data)
end

function EffectData:AddCameraShakeData(data)
  table.insert(self.CameraShakeDatas,data)
end

function EffectData:AddSoundData(data)
  table.insert(self.SoundDatas,data)
end

return EffectData