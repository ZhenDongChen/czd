local require            = require
local defineenum         = require "defineenum"
local mathutils          = require "common.mathutils"
local gameevent          = require "gameevent"
local EffectInstanceData = require "effect.data.effectinstancedata"
local CameraShakeData    = require "effect.data.camerashakedata"
local SoundInstanceData  = require "effect.data.soundinstancedata"
local EffectData         = require "effect.data.effectdata"
local SettingManager     = require "character.settingmanager"
local CameraShakeType    = defineenum.CameraShakeType
local EffectLevel        = defineenum.EffectLevel

local CharacterManager
local Effect


local m_iSkillEffectIDSeed = 0
local MaxSkillEffectLife  = 30
local MaxCommonEffectLife = 30
local MaxEffectNum        = 100
local ErrorEffectId       = -1
local Level               = EffectLevel.None
local m_ID                = 0
local bHideEffects        = false

local ExcludeCharList     = { } -- Item : Character

local SkillEffectDatas    = { }  -- Item : EffectData
local CommonEffectDatas   = { } -- Item : EffectData

local Effects             = { }    -- Item : Effect

local function InitActionEffect(action)

        action.SkillEffects = { }
        for _, effect in pairs(action.effects) do
            local SkillEffects = { }
            local SkillCameraShakes = { }
            local SkillSounds = { }

            for _,action in pairs(effect.actions) do
                if action.class == "cfg.skill.ParticleEffect" then
                    local effect                     = EffectInstanceData:new()
                    effect.Type                      = action.type -- 特效类型(0:Stand,1:Follow,2:Trace,3:TracePos,4:BindToCamera,5:UIStand)
                    effect.Life                      = action.life -- 生存时间
                    effect.Path                      = string.format("sfx/s_%s.bundle", action.path) -- 特效资源路径
                    effect.Scale                     = action.scale -- 缩放系数
                    effect.StartDelay                = action.timeline -- 延迟播放时间
                    effect.FadeOutTime               = action.fadeouttime -- 淡出时间
                    effect.FollowDirection           = true--action.followdirection    --是否跟随释放者方向
                    effect.FollowBeAttackedDirection = action.followbeattackeddirection -- 若攻击方为A，受击方为B，这个功能激活后（1=激活，0=不激活），B的受击特效的朝向始终指向A的方向
                    effect.TraceTime                 = action.tracetime -- 用于trace类型，飞行时间
                    effect.InstanceTraceType         = action.instancetracetype -- 跟踪类型(0:Line)
                    effect.WorldOffsetX              = action.worldoffsetx -- 世界偏移X
                    effect.WorldOffsetY              = action.worldoffsety -- 世界偏移Y
                    effect.WorldOffsetZ              = action.worldoffsetz -- 世界偏移Z
                    effect.OffSet                    = Vector3(action.worldoffsetx,action.worldoffsety,action.worldoffsetz)
                    effect.AlignType                 = action.aligntype -- 屏幕对齐类型(0:None,1:LeftTop,2:Left,3:LeftBottom,4:Top,5:Center,6:Bottom,7:RightTop,8:Right,9:RightBottom)
                    effect.IsPoolDestroyed           = action.ispooldestoryed -- 是否特效池管理
                    effect.CasterBindType            = action.casterbindtype -- 释放者绑定类型(0:Body,1:Head,2:Foot,3:LeftHand,4:RightHand)
                    effect.TargetBindType            = action.targetbindtype -- 目标者绑定类型(0:Body,1:Head,2:Foot,3:LeftHand,4:RightHand)
                    effect.BoneName                  = action.bonename -- 绑定骨骼名称
                    effect.BonePosX                  = action.boneposx -- 骨骼偏移X
                    effect.BonePosY                  = action.boneposy -- 骨骼偏移Y
                    effect.BonePosZ                  = action.boneposz -- 骨骼偏移Z
                    effect.BoneRotX                  = action.bonerotx -- 骨骼旋转X
                    effect.BoneRotY                  = action.boneroty -- 骨骼旋转Y
                    effect.BoneRotZ                  = action.bonerotz -- 骨骼旋转Z
                    effect.BoneScaleX                = action.bonescalex -- 骨骼缩放X
                    effect.BoneScaleY                = action.bonescaley -- 骨骼缩放Y
                    effect.BoneScaleZ                = action.bonescalez -- 骨骼缩放Z
                    effect.FollowBoneDirection       = action.followbonedirection -- 是否跟随绑定骨骼方向
                    effect.TerrainEffect       		 = action.terraineffect

                    effect.EulerAngles               = Vector3(action.worldrotx,action.worldroty,action.worldrotz)
                    effect.Rot                       = Quaternion.Euler(effect.EulerAngles)

                    table.insert(SkillEffects, effect)

                elseif action.class == "cfg.skill.ShakeScreen" then
                    local shake                 = CameraShakeData:new()
                    if action.type              == 'H' then
                        shake.Type              = CameraShakeType.Horizontal
                    elseif action.type          == 'V' then
                        shake.Type              = CameraShakeType.Vertical
                    elseif action.type          == 'M' then
                        shake.Type              = CameraShakeType.Normal
                    else
                        shake.Type              = CameraShakeType.NoShake
                    end
                    shake.Life                  = action.life -- 生存时间
                    shake.StartDelay            = action.timeline -- 延迟播放时间
                    shake.MaxRange              = action.maxrange  -- 最大影响范围
                    shake.MinRange              = action.minrange  -- 最小完整影响范围，在min和max范围之间受到影响递减
                    shake.MaxAmplitude          = action.amplitude  -- 最大振幅
                    shake.MinAmplitude          = action.amplitude  -- 最小振幅 真实振幅在min和max之间随机
                    shake.AmplitudeAttenuation  = action.amplitudeattenuation  -- 振幅衰减 0无衰减 值越大衰减越快
                    shake.Frequency             = action.frequency  -- 初始频率 次/秒
                    shake.FrequencyKeepDuration = action.frequencykeepduration -- 初始频率维持时间
                    shake.FrequencyAttenuation  = action.frequencyattenuation -- 频率衰减 0无衰减
                    table.insert(SkillCameraShakes, shake)
                 elseif action.class == "cfg.skill.SoundEffect" then
                    local sound      = SoundInstanceData:new()
                    sound.Type       = action.type
                    sound.Id         = action.id
                    sound.StartDelay = action.timeline
                    sound.Sound      = action.pathlist
                    sound.PlayProbability = action.probability
                    sound.MinVlm = action.volumemin
                    sound.MaxVlm = action.volumemax
                    table.insert(SkillSounds, sound)
                end
            end

            if #SkillEffects > 0 or
                #SkillCameraShakes > 0 or
                #SkillSounds > 0 then
                    m_iSkillEffectIDSeed                               = m_iSkillEffectIDSeed + 1
                    action.SkillEffects[effect.id]                     = m_iSkillEffectIDSeed
                    local effectData                                   = EffectData:new()
                    effectData.Id                                      = m_iSkillEffectIDSeed
                    effectData.Life                                    = MaxSkillEffectLife
                    effectData.InstanceDatas                           = SkillEffects
                    effectData.SoundDatas                              = SkillSounds
                    effectData.CameraShakes                            = SkillCameraShakes
                    effectData.ActionName                              = action.actionname
                    SkillEffectDatas[m_iSkillEffectIDSeed]             = effectData
            end
        end
        --- ]]

end

local function InitSkillData()
    SkillEffectDatas = { }
    m_iSkillEffectIDSeed = 0

    for _,model in pairs(ConfigManager.getConfig("modelactions")) do
        for _,action in pairs(model.actions) do
            InitActionEffect(action)
        end
        for _,action in pairs(model.skillactions) do
            InitActionEffect(action)
        end
    end

end

local function GetCommonEffectBindType(id) 
    if CommonEffectDatas and CommonEffectDatas[id] then 
        for _,data in pairs(CommonEffectDatas[id].InstanceDatas) do 
            return data.CasterBindType 
        end 
    end  
    return nil 
end 


local function GetCommonEffectLife(id) 
    local life = 0
    if CommonEffectDatas and CommonEffectDatas[id] then 
        for _,data in pairs(CommonEffectDatas[id].InstanceDatas) do 
            if data.Life<0 then 
                life = data.Life
                break
            elseif life<data.Life then 
                life = data.Life
            end 
        end 
    end 
    return life 
end 



local function InitCommonEffectData()
    local ConfigManager = require "cfg.configmanager"
    local AllCommonEffectData = ConfigManager.getConfig("commoneffect")

    CommonEffectDatas = { }

    for _, dataCommonEffect in pairs(AllCommonEffectData) do
        local ParticleEffects = { }
        local CameraShakeEffects = { }
        local SoundEffects = { }
        for _, action in pairs(dataCommonEffect["actions"]) do
            if action.class == "cfg.skill.ParticleEffect" then
                local effect                     = EffectInstanceData:new()
                effect.Type                      = action.type
                effect.Life                      = action.life
                effect.Path                      = string.format("sfx/s_%s.bundle", action.path)
                effect.Scale                     = action.scale
                effect.StartDelay                = action.timeline
                effect.FadeOutTime               = action.fadeouttime
                effect.FollowDirection           = action.followdirection
                effect.FollowBeAttackedDirection = action.followbeattackeddirection
                effect.TraceTime                 = action.tracetime
                effect.InstanceTraceType         = action.instancetracetype
                effect.WorldOffsetX              = action.worldoffsetx
                effect.WorldOffsetY              = action.worldoffsety
                effect.WorldOffsetZ              = action.worldoffsetz

                effect.AlignType                 = action.aligntype
                effect.IsPoolDestroyed           = action.ispooldestoryed
                effect.CasterBindType            = action.casterbindtype
                effect.TargetBindType            = action.targetbindtype
                effect.BoneName                  = action.bonename
                effect.BonePosX                  = action.boneposx
                effect.BonePosY                  = action.boneposy
                effect.BonePosZ                  = action.boneposz
                effect.BoneRotX                  = action.bonerotx
                effect.BoneRotY                  = action.boneroty
                effect.BoneRotZ                  = action.bonerotz
                effect.BoneScaleX                = action.bonescalex
                effect.BoneScaleY                = action.bonescaley
                effect.BoneScaleZ                = action.bonescalez
                effect.FollowBoneDirection       = action.followbonedirection
                effect.TerrainEffect       		 = action.terraineffect
				

                effect.OffSet                    = Vector3(action.worldoffsetx,action.worldoffsety,action.worldoffsetz)
                effect.EulerAngles               = Vector3(action.worldrotx,action.worldroty,action.worldrotz)
                effect.Rot                       = Quaternion.Euler(effect.EulerAngles)

                table.insert(ParticleEffects, effect)

            elseif action.class == "cfg.skill.ShakeScreen" then
				local shake                 = CameraShakeData:new()
                -- 振动类型(0:NoShake,1:Normal,2:Horizontal,3:Vertical)
                if action.type              == 'H' then
                    shake.Type              = CameraShakeType.Horizontal
                elseif action.type          == 'V' then
                    shake.Type              = CameraShakeType.Vertical
                elseif action.type          == 'M' then
                    shake.Type              = CameraShakeType.Normal
                else
                    shake.Type              = CameraShakeType.NoShake
                end
                shake.Life                  = action.life -- 生存时间
                shake.StartDelay            = action.timeline -- 延迟播放时间
                shake.MaxRange              = action.maxrange  -- 最大影响范围
                shake.MinRange              = action.minrange  -- 最小完整影响范围，在min和max范围之间受到影响递减
                shake.MaxAmplitude          = action.amplitude  -- 最大振幅
                shake.MinAmplitude          = action.amplitude  -- 最小振幅 真实振幅在min和max之间随机
                shake.AmplitudeAttenuation  = action.amplitudeattenuation  -- 振幅衰减 0无衰减 值越大衰减越快
                shake.Frequency             = action.frequency  -- 初始频率 次/秒
                shake.FrequencyKeepDuration = action.frequencykeepduration -- 初始频率维持时间
                shake.FrequencyAttenuation  = action.frequencyattenuation -- 频率衰减 0无衰减
                table.insert(CameraShakeEffects, shake)
            elseif action.class == "cfg.skill.SoundEffect" then
                local sound      = SoundInstanceData:new()
                sound.Type       = action.type
                sound.Id         = action.id
                sound.StartDelay = action.timeline
                sound.Sound      = action.pathlist
                sound.PlayProbability = action.probability
                sound.MinVlm = action.volumemin
                sound.MaxVlm = action.volumemax
                table.insert(SoundEffects, sound)
            end
        end

        if #ParticleEffects > 0 or #CameraShakeEffects > 0 or #SoundEffects > 0 then
            if CommonEffectDatas[dataCommonEffect.id] then
            else
                local effectData = EffectData:new()
                effectData.Id = dataCommonEffect.id
                effectData.Life = MaxCommonEffectLife
                effectData.InstanceDatas = ParticleEffects
                effectData.SoundDatas = SoundEffects
                effectData.CameraShakes = CameraShakeEffects
                CommonEffectDatas[dataCommonEffect.id] = effectData
            end

        end
    end

end

local function LoadData()
    InitSkillData()
    InitCommonEffectData()
end



local function Relase()
    for i = 1, #Effects do
        if Effects[i] then
            Effects[i]:Destroy()
        end
    end
end

local function CanShow(characterId,isBindEffect)
    local character = CharacterManager.GetCharacter(characterId)
    if character ~=nil then
        if not character:IsVisiable() then
            return false
        end
        if not isBindEffect then 
            local SettingSystem = SettingManager.GetSettingSystem()
            if character:IsRole() or character:IsPet() and character:IsRolePet() then
                if not SettingSystem["SkillEffectSelf"] then
                    return false
                end
            elseif character:IsMonster() then
                if not SettingSystem["SkillEffectMonster"] then
                    return false
                end
            elseif character:IsPlayer() or character:IsPet() then
                if not SettingSystem["SkillEffectOther"] then
                    return false
                end
            end
        end
    end
    if bHideEffects then
        if ExcludeCharList and ExcludeCharList[characterId] then
            return true
        else
            return false
        end
    end
    return true
end

local function GetID()
    local tId =(m_ID + 1) % MaxEffectNum
    while tId ~= m_ID do
        if tId >= MaxEffectNum then
            tId = tId % MaxEffectNum
            if tId == m_ID then
                break
            end
        end
        if Effects[tId] == nil then
            m_ID = tId
            return tId
        end
        tId = tId + 1
    end
    return ErrorEffectId
end

local function CheckStatement(id, casterId, bSkill,isBindEffect)
    local effectId = ErrorEffectId
    local effectData = nil
    if Level == EffectLevel.None then
        return false, ErrorEffectId, nil
    end
    local effectDatas = mathutils.TernaryOperation(bSkill, SkillEffectDatas, CommonEffectDatas)
    if effectDatas[id] == nil then
        return false, ErrorEffectId, nil
    end
    effectData = effectDatas[id]

    if not CanShow(casterId,isBindEffect) then
        return false, ErrorEffectId, nil
    end

    effectId = GetID()
    if effectId == ErrorEffectId then
        return false, ErrorEffectId, nil
    else
        return true, effectId, effectData
    end

end


local function PlayEffect(effectArgs)
    local data
    local effectID = ErrorEffectId
    local casterId = effectArgs.bindCharacter and effectArgs.bindCharacter.m_Id or effectArgs.casterId
    local canPlayEffect = false
    canPlayEffect, effectID, data = CheckStatement(effectArgs.id, casterId, effectArgs.bSkill,effectArgs.bindCharacter~=nil)
    if not canPlayEffect then
        return ErrorEffectId
    end
    local e = Effect:new()
    e.CasterId = casterId
    e.TargetId = effectArgs.targetId
    e.ScaleModify = mathutils.TernaryOperation(effectArgs.scale, effectArgs.scale, 1)
    e.TargetPos = effectArgs.targetPos
    e.TracePosObj = effectArgs.tracePosObj
    e.UseTargetPos = effectArgs.useTargetPos
    e.BindCharacter = effectArgs.bindCharacter
    e.SoundPriority = effectArgs.soundPriority or defineenum.AudioPriority.Default
    e:Load(data)

    Effects[effectID] = e
    return effectID
end

local function GetEffects()
    return Effects
end


local function GetEffect(id)
    return Effects[id]
end

local function PauseEffect(id, bPause)
    if Effects[id] then
        Effects[id]:Pause(bPause)
    end
end

local function StopEffect(id)
    if Effects[id] then
        Effects[id]:Destroy()
        Effects[id] = nil
    end
end

local function StopAllEffects()
    if Effects then
        for key, value in pairs(Effects) do
            if value and ExcludeCharList and value:Caster() then
                StopEffect(key)
            end
        end
    end
end

local function FadeOutEffect(id)
    if Effects[id] then
        Effects[id].FadeOut = true
        Effects[id].FadeOutTime = Time.time
    end
end

local function Update()
    for key, value in pairs(Effects) do
        if value.Dead then
            value:Destroy()
            Effects[key] = nil
        else
            value:Update()
        end
    end
end

local function ShowCharacterEffect(characterId, visible)
    for key, value in pairs(Effects) do
        if value.CasterId == characterId or value.TargetId == characterId then
            value:SetVisible(visible)
        end
    end
end

local function StopCharacterEffect(character)
    if character:IsUIModel() then
        for key, value in pairs(Effects) do
            if value.BindCharacter == character then
                StopEffect(key)
            end
        end
    else
        for key, value in pairs(Effects) do
            if value.CasterId == character.m_Id then
                StopEffect(key)
            end
        end
    end

end

local function AddHideExculdeCharList(excludeList)
    if excludeList and ExcludeCharList then
        for key, value in pairs(excludeList) do
            if ExcludeCharList[key] == nil then
                ExcludeCharList[key] = value
            end
        end
    end
end

local function RemoveHideExcludeCharList(excludeList)
    if excludeList and ExcludeCharList then
        for key, value in pairs(excludeList) do
            if ExcludeCharList[key] then
                ExcludeCharList[key] = nil
            end
        end
    end
end

local function ClearHideExcludeCharList()
    ExcludeCharList = { }
end
local function init()
    local evtid_update = gameevent.evt_update:add(Update)

    gameevent.evt_second_update:add(function ()
        local commoninfo = {}
        local skillinfo = {}
        local common_count = 0
        local skill_count = 0
        for _, effect in pairs(Effects) do 
            if effect.EffectData.ActionName then 
                skill_count = skill_count+1
                if skillinfo[effect.EffectData.Id] == nil then 
                    skillinfo[effect.EffectData.Id] = {actionname = effect.EffectData.ActionName,count =1}
                else 
                    skillinfo[effect.EffectData.Id].count = skillinfo[effect.EffectData.Id].count+1
                end 
            else 
                common_count = common_count+1
                if commoninfo[effect.EffectData.Id] == nil then 
                    commoninfo[effect.EffectData.Id] = {count =1}
                else 
                    commoninfo[effect.EffectData.Id].count = commoninfo[effect.EffectData.Id].count+1
                end 
            end 

        end 
        --[[local s = "effects,count:"..getn(Effects).."common_count:"..common_count.."skill_count:"..skill_count
        for id,info in pairs(commoninfo) do 
            s = s .. "【common id:"..id .."count:"..info.count .."】"
        end 

        for id,info in pairs(skillinfo) do 
            s = s .. "【skill id:"..id .."actionname:"..info.actionname.. "count:"..info.count .."】"
        end 
        printyellow(s)]]
    end )
    status.AddStatusListener("effectmgr",gameevent.evt_update,evtid_update)
    LoadData()
    Level = EffectLevel.All
    CharacterManager = require "character.charactermanager"
    Effect = require "effect.effect"
end




return
{
    init = init,
    PlayEffect = PlayEffect,
    StopEffect = StopEffect,
    StopAllEffects = StopAllEffects,
    StopCharacterEffect = StopCharacterEffect,
    GetCommonEffectLife = GetCommonEffectLife,
    GetCommonEffectBindType = GetCommonEffectBindType,
    GetEffects = GetEffects,
}
