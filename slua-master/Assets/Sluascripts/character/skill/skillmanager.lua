local ConfigManager        = require "cfg.configmanager"
local DataSkill            = require "character.skill.data.dataskill"
local Skill                = require "character.skill.skill"
local PassiveSkill         = require "character.skill.passiveskill"
local EffectManager
local allskills          = {} --{skillid,skill}
local talismanskillactions = {}
local showeffect = true


local defaultcliporder = {}
local actionname_animtypeselect = {}
local allmodelclips = {}
local showeffect = true

local function SetShowEffect(isshow)
    showeffect = isshow
end

local function CompareTimeLine(a,b) 
	return a.timeline<b.timeline 
end

local function Load()

     for _,modelactions in pairs(ConfigManager.getConfig("modelactions")) do
        for _,skillaction in pairs(modelactions.skillactions) do
            skillaction.MovementList = {}
            skillaction.HitPointList = {}
            skillaction.FlyWeaponList = {}
            skillaction.BombList = {}
            skillaction.SpawnObjectList = {}
            for _ ,action in pairs(skillaction.actions) do
                if action.class == "cfg.skill.Movement" then
                    table.insert(skillaction.MovementList,action)

                elseif action.class == "cfg.skill.Attack" then
                    table.insert(skillaction.HitPointList,action)

                elseif action.class == "cfg.skill.FlyWeapon" then
                    table.insert(skillaction.FlyWeaponList,action)--�ӵ�

                elseif action.class == "cfg.skill.Bomb" then
                    table.insert(skillaction.BombList,action)--ը��

                elseif action.class == "cfg.skill.SpawnObject" then
                    table.insert(skillaction.SpawnObjectList,action)--�ٻ���

                end
            end
            table.sort(skillaction.MovementList,CompareTimeLine)
            table.sort(skillaction.HitPointList,CompareTimeLine)
            table.sort(skillaction.FlyWeaponList,CompareTimeLine)
            table.sort(skillaction.BombList,CompareTimeLine)
            table.sort(skillaction.SpawnObjectList,CompareTimeLine)
        end
    end


    local modelname = nil
    for _, model in pairs( ConfigManager.getConfig("model")) do
        if model.modeltype == cfg.character.ModelType.Talisman  then
            modelname = model.modelname
            break
        end
    end

    talismanskillactions = ConfigManager.getConfigData("modelactions",modelname).skillactions

	--获取技能的伤害值
    for _,dataskilldmg in pairs(ConfigManager.getConfig("skilldmg")) do 
        local skill = Skill:new()
        skill:initData(dataskilldmg)
        allskills[dataskilldmg.id] = skill
    end

   for _,datapassiveskill in pairs(ConfigManager.getConfig("passiveskill")) do
        local skill = PassiveSkill:new()
        skill:initData(datapassiveskill)
        allskills[datapassiveskill.id] = skill
    end



 --   printyellow("load skill config")
end


local function InitModelClip(actionclip,action,actionfile,modelname,templatemodelname,defaultclip)
    if action == nil or IsNullOrEmpty(actionfile) then
        return
    end
    local actionsourcetype = action.actionsourcetype
    local othermodelname = action.othermodelname
    local actionname = action.actionname

    local _modelname = nil
    local _clipname = nil
    if actionsourcetype == cfg.skill.ActionSourceType.SelfModel then
        _modelname = modelname
        _clipname = actionfile
    elseif actionsourcetype == cfg.skill.ActionSourceType.Template then
        _modelname = templatemodelname
        local modelactiontemplate = ConfigManager.getConfigData("modelactiontemplate",templatemodelname)
        if modelactiontemplate then
            _clipname = modelactiontemplate.actions[actionfile]
        else
            _clipname = nil
        end
    elseif actionsourcetype == cfg.skill.ActionSourceType.OtherModel then
        _modelname = othermodelname
        _clipname = actionfile
    end
    if IsNullOrEmpty(_modelname) or IsNullOrEmpty(_clipname) then
        return
    end
    local model = ConfigManager.getConfigData("model",_modelname)
    if model then
        actionclip[actionfile]= string.lower(string.format("%s_%s",model.modelpath,_clipname))

        Game.CharacterLoader.Instance:AddModelClip(modelname,StringToHash(actionclip[actionfile]),actionname_animtypeselect[actionname] or 0)
        if defaultcliporder[actionname] ~=nil then
            if defaultclip.order> defaultcliporder[actionname] then
                defaultclip.order = defaultcliporder[actionname]
                defaultclip.cliphash = StringToHash(actionclip[actionfile])
            end
        elseif defaultcliporder[actionfile] ~=nil then
            if defaultclip.order> defaultcliporder[actionfile] then
                defaultclip.order = defaultcliporder[actionfile]
                defaultclip.cliphash = StringToHash(actionclip[actionfile])
            end
        end
    end
end

local function InitModelClips()


    defaultcliporder = {
        [cfg.skill.AnimType.Stand] = 1,
        ["stand"] = 2,
        [cfg.skill.AnimType.StandFight] = 3,
        ["standfight"] = 4,
        [cfg.skill.AnimType.Idle] = 5,
        ["_maxorder"] = 100,
    }
	
    actionname_animtypeselect = {}

    for selecttype,d in pairs (ConfigManager.getConfig("animtypeselector")) do
        for _,actionname in pairs(d.animtypes) do
            if actionname_animtypeselect[actionname] == nil then
                actionname_animtypeselect[actionname] = selecttype
            else
                actionname_animtypeselect[actionname] = bit.bor(actionname_animtypeselect[actionname],selecttype)
            end
        end
    end 
    allmodelclips = {}
    local ModelActions = ConfigManager.getConfig("modelactions")
    for modelname,ma in pairs(ModelActions) do
        local actions = {}
        local defaultclip = {order = defaultcliporder["_maxorder"],cliphash = nil}

        local modelaction = ma
        while modelaction~=nil do
            for _,action in pairs(modelaction.skillactions) do
                if actions[action.actionname] == nil then
                    actions[action.actionname] = {}
                    InitModelClip(actions[action.actionname],action,action.actionfile,modelname,ma.templatemodelname,defaultclip)
                    InitModelClip(actions[action.actionname],action,action.foreactionfile,modelname,ma.templatemodelname,defaultclip)
                    InitModelClip(actions[action.actionname],action,action.succactionfile,modelname,ma.templatemodelname,defaultclip)
                end
            end

            for _,action in pairs(modelaction.actions) do
                if actions[action.actionname] == nil then
                    actions[action.actionname] = {}
                    InitModelClip(actions[action.actionname],action,action.actionfile,modelname,ma.templatemodelname,defaultclip)
                    InitModelClip(actions[action.actionname],action,action.foreactionfile,modelname,ma.templatemodelname,defaultclip)
                    InitModelClip(actions[action.actionname],action,action.succactionfile,modelname,ma.templatemodelname,defaultclip)
                end
            end

            modelaction = ConfigManager.getConfigData("modelactions",modelaction.basemodelname)
        end

        allmodelclips[modelname] = actions
        if defaultclip.cliphash ~=nil then
		
            Game.CharacterLoader.Instance:SetDefaultClip(modelname,defaultclip.cliphash)
        end
    end

end


local function GetAnimatorStateName(modelname,actionname,animName)
    if allmodelclips and allmodelclips[modelname] and allmodelclips[modelname][actionname] then
        
		return allmodelclips[modelname][actionname][animName]
    end
    return nil
end

local function init()
    EffectManager        = require "effect.effectmanager"
    Load()

    InitModelClips()
end

local function GetSkill(skillid)
    if allskills[skillid] then
        return allskills[skillid]
    end
    return nil
end

local function GetOriginalSkillId(skillid)
    local skill = GetSkill(skillid)
    if skill then return skill.OriginalSkillId end
    return 0
end


local function GetTalismanAction(actionname)
    if talismanskillactions[actionname] then
        return talismanskillactions[actionname]
    end
    return nil
end


local function PlaySkillEffect(skilldata,casterid,targetid,targetPos,soundPriority)
    if Local.LogModuals.Skill then
		printyellow("PlaySkillEffect",skilldata)
		printyellow("PlaySkillEffect",skilldata.actionname,casterid,targetid)
    end
	
    if showeffect and skilldata and skilldata.SkillEffects and skilldata.effectid >0 then
        return EffectManager.PlayEffect { id = skilldata.SkillEffects[skilldata.effectid],
                                          casterId = casterid ,
                                          targetId = targetid,
                                          targetPos = targetPos,
                                          soundPriority = soundPriority,
                                          bSkill = true}
    end
    return -1
end

local function PlayBindEffect(skilldata,character)
    if Local.LogModuals.Skill then
		printyellow("PlayBindEffect",skilldata)
		printyellow("PlayBindEffect",skilldata.actionname,character.m_Id)
    end
	
    if showeffect and skilldata and skilldata.SkillEffects and skilldata.effectid >0 then
        return EffectManager.PlayEffect { id = skilldata.SkillEffects[skilldata.effectid],
                                          bindCharacter = character ,
                                          bSkill = true}
    end
    return -1
end



local function PlayAnimationEffect(skilldata,casterid)
    if Local.LogModuals.Skill then
		printyellow("PlayAnimationEffect",skilldata)
		printyellow("PlayAnimationEffect",skilldata.actionname,casterid,targetid)
    end
	
    if showeffect and skilldata and skilldata.SkillEffects and skilldata.effectid >0 then
        return EffectManager.PlayEffect { id = skilldata.SkillEffects[skilldata.effectid],
                                          casterId = casterid ,
                                          soundPriority = defineenum.AudioPriority.ActionEffect,
                                          bSkill = true}
    end
    return -1
end

local function PlayCommomAnimEffect(character,actionname)
    if Local.LogModuals.EffectManager then
		printyellowmodule(Local.LogModuals.EffectManager ,"PlayCommomAnimEffect",character.m_Name,actionname)
    end
    local action = character:GetAction(actionname)
    if action then
        return PlayAnimationEffect(action,character.m_Id)
    end
    return -1
end


local function PlayTraceObjEffect(skilldata,effectid,casterid,targetid,tracePosObj)
    if showeffect and skilldata and skilldata.SkillEffects then
        return EffectManager.PlayEffect { id = skilldata.SkillEffects[effectid],
                                          casterId = casterid ,
                                          targetId = targetid,
                                          tracePosObj = tracePosObj,
                                          soundPriority = defineenum.AudioPriority.Attack,
                                          bSkill = true}
    end
    return -1
end

local function PlayTargetPosEffect(skilldata,effectid,casterid,targetid,targetPos)
    if showeffect and skilldata and skilldata.SkillEffects then
        return EffectManager.PlayEffect { id = skilldata.SkillEffects[effectid],
                                          casterId = casterid ,
                                          targetId = targetid,
                                          targetPos = targetPos,
                                          useTargetPos = true,
                                          soundPriority = defineenum.AudioPriority.Attack,
                                          bSkill = true}
    end
    return -1
end



return {
    init                 = init,
    GetSkill             = GetSkill,
    GetOriginalSkillId   = GetOriginalSkillId,
    GetTalismanAction    = GetTalismanAction,
    PlayAnimationEffect  = PlayAnimationEffect,
    PlayBindEffect       = PlayBindEffect,
    PlayTraceObjEffect   = PlayTraceObjEffect,
    PlayTargetPosEffect  = PlayTargetPosEffect,
    PlayCommomAnimEffect = PlayCommomAnimEffect,
    PlaySkillEffect      = PlaySkillEffect,
    SetShowEffect        = SetShowEffect,
    GetAnimatorStateName = GetAnimatorStateName,

}
