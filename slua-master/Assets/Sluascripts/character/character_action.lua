
local Character = utils.get_or_create("character").Character

function Character:IsUIModel()
    return  self.m_AnimSelectType == cfg.skill.AnimTypeSelectType.UI
end 

function Character:IsNpcModel()
    return  self.m_AnimSelectType == cfg.skill.AnimTypeSelectType.Npc
end 

--获取动作：如果自身动作列表获取不到会从父模型中获取
function Character:GetAction(actionname)
    local model =  ConfigManager.getConfigData("modelactions",self.m_ModelData.modelname) 
    while model~=nil do
		
        if model.actions[actionname]~=nil then
			
            return model.actions[actionname],model
        elseif model.skillactions[actionname]~=nil then
            return model.skillactions[actionname],model
        end

        model = ConfigManager.getConfigData("modelactions",model.basemodelname)
    end
	
    ----Util.LogError(string.format("error Character:GetAction.model not found.modelname:%s actionname:%s.",tostring(self.m_ModelData.modelname),actionname))
    return nil
end

function Character:ResetAction() 
	

    if self.m_ActionEffectId and self.m_ActionEffectId>0 then 
        EffectManager.StopEffect(self.m_ActionEffectId)
    end
    self.m_ActionLoop = -1
    self.m_ActionEffectId = -1
    self.m_PlayEffect = false
    self.m_CrossFading = false
    self.m_CurrentActionName = nil
end

function Character:UpdateAction()
	
    if self.m_PlayEffect and  self.m_CurrentActionName then 
        local normalizedTime = self.AnimationMgr:GetNormalizedTime()
        if math.floor(normalizedTime)<self.m_ActionLoop then 
            self.m_ActionLoop = math.floor(normalizedTime)
        elseif math.floor(normalizedTime) > self.m_ActionLoop then 
            if Local.LogModuals.Action then 
                printyellow(math.floor(normalizedTime),self.m_ActionLoop)
            end
            self:PlayActionEffect(self.m_CurrentActionName)
            self.m_ActionLoop = math.floor(normalizedTime)
        end
    end

    if self.m_CrossFading and self.m_CurrentActionName then 
        local action = self:GetAction(self.m_CurrentActionName) 
        if action and self:IsPlayingAnimation(action,action.actionfile) or not self:IsActive() then 
            self.m_CrossFading = false
        end
    end
end


--是否需要融合
function Character:CrossFadeDuration(action)

    local crossfadeduration = -1
    if self:IsPlayer() then 
        local playeractioncrossfade = ConfigManager.getConfig("playeractioncrossfade")
        for _,translation in pairs(playeractioncrossfade) do 
            if self.m_CurrentActionName == translation.statebegin and 
                action.actionname == translation.stateend then 
                return translation.crossfadeduration

            elseif cfg.skill.AnimType.AnyState == translation.statebegin and 
                action.actionname == translation.stateend then 
                crossfadeduration = translation.crossfadeduration
            end
        end
    end
    return crossfadeduration
end

--播放动画 （actionfile 动画资源文件名称）
function Character:PlayAnimation(action,actionfile)
    self:ResetAction()
	
    local duration = self:CrossFadeDuration(action)

    local animName = SkillManager.GetAnimatorStateName(self.m_ModelData.modelname,action.actionname,actionfile)  --名字是
    if self:IsActive() then 
        if duration>0 then 
            if Local.LogModuals.Action then
                printyellow("Character:PlayAnimation(CrossFade)",self.m_Name,animName,duration)
            end
			
            self.AnimationMgr:CrossFade(animName,duration)
            self.m_CrossFading = true
        else 
            if Local.LogModuals.Action then
                printyellow("Character:PlayAnimation",self.m_Name,animName,action.actionspeed)
            end
			
            self.AnimationMgr:Play(animName,action.actionspeed)
        end
    end
    self.m_CurrentActionName = action.actionname
end

function Character:BindEffect() 
    if self.m_BindEffectId and self.m_BindEffectId>0 then 
        self:ReleaseBindEffect() 
    end
    local action,model = self:GetAction(cfg.skill.AnimType.BindEffect)
    if action then 
        if Local.LogModuals.Action then
            printyellow("Character:PlayActionEffect",self.m_Name,model.modelname,actionname)
        end
        self.m_BindEffectId = SkillManager.PlayBindEffect(action,self)
    end
end 



function Character:ReleaseBindEffect() 
    if self.m_BindEffectId and self.m_BindEffectId>0 then 
        EffectManager.StopEffect(self.m_BindEffectId)
    end
end


--播放动作绑定特效 注意 对于Player 会调用Player:PlayActionEffect(actionname)
function Character:PlayActionEffect(actionname)
    local action,model = self:GetAction(actionname)
    if action then 
        if Local.LogModuals.Action then
            printyellow("Character:PlayActionEffect",self.m_Name,model.modelname,actionname)
        end
        self.m_ActionEffectId = SkillManager.PlayAnimationEffect(action,self:IsMount() and self.m_Player.m_Id or self.m_Id)
    end
end

--播放动作（不播放动作绑定特效）注意 对于Player 会调用Player:PlayActionWithOutEffect(actionname)
function Character:PlayActionWithOutEffect(actionname)
    local action,model = self:GetAction(actionname)
    if action then 
        if Local.LogModuals.Action then
            printyellow("Character:PlayActionWithOutEffect",self.m_Name,model.modelname,actionname)
        end
        self:PlayAnimation(action,action.actionfile)
    end
end

--播放动作（同时播放动作绑定特效）注意 对于Player 会调用Player:PlayAction(actionname)
function Character:PlayAction(actionname)
    local action,model = self:GetAction(actionname)
	printyellow(">>>>>>>>>>>>>>>actionname",actionname)
    if action then 
        if Local.LogModuals.Action then
            printyellow("Character:PlayAction",self.m_Name,model.modelname,actionname)
        end
        self:PlayAnimation(action,action.actionfile)
        self:PlayActionEffect(actionname)
    end
    
end


--播放动作（同时循环播放动作绑定特效）
function Character:PlayLoopAction(actionname)
    local action,model = self:GetAction(actionname)
	
	
    if action then 
        if Local.LogModuals.Action then
            printyellow("Character:PlayLoopAction",self.m_Name,model.modelname,actionname)
        end
        self:PlayAnimation(action,action.actionfile)
        if action.effectid >0 then 
            self.m_PlayEffect = true
        end
    end
end

--前摇动作
function Character:PlayForeAction(actionname)
    local action,model = self:GetAction(actionname)
    if action and action.foreactionfile and action.foreactionfile~=""  then 
        if Local.LogModuals.Action then
            printyellow("Character:PlayForeAction",self.m_Name,model.modelname,actionname)
        end
        self:PlayAnimation(action,action.foreactionfile)
        return true
    end
    return false
end

--后摇动作
function Character:PlaySuccAction(actionname)
    local action,model = self:GetAction(actionname)
    if action and action.succactionfile and action.succactionfile~="" then 
        if Local.LogModuals.Action then
            printyellow("Character:PlaySuccAction",self.m_Name,model.modelname,actionname)
        end
        self:PlayAnimation(action,action.succactionfile)
        return true
    end
    return false
end

function Character:IsPlayingAnimation(action,actionfile)

    local animName = SkillManager.GetAnimatorStateName(self.m_ModelData.modelname,action.actionname,actionfile)

	return self.AnimationMgr:IsPlaying(animName)

end 


--是否正在播放动作
function Character:IsPlayingAction(actionname)

    local action = self:GetAction(actionname)

    if self.m_CrossFading then 

        return self.m_CurrentActionName == actionname
    elseif action then
	
        return self:IsPlayingAnimation(action,action.actionfile)
    end

    return false
end


--是否正在播放前摇动作
function Character:IsPlayingForeAction(actionname)
    local action = self:GetAction(actionname)
    if action then 
        return self:IsPlayingAnimation(action,action.foreactionfile)
    end
    return false
end


--是否正在播放后摇动作
function Character:IsPlayingSuccAction(actionname)
    local action = self:GetAction(actionname)
    if action then 
        return self:IsPlayingAnimation(action,action.succactionfile)
    end
    return false
end

--是否正在播放技能动作
function Character:IsPlayingSkill(actionname)
    local action = self:GetAction(actionname)
    if self.AnimationMgr then
        return self.AnimationMgr:IsPlayingSkill(SkillManager.GetAnimatorStateName(self.m_ModelData.modelname,action.actionname,action.actionfile),action.loopplay)
    end
    return false
end


--是否正在播放移动动画
function Character:IsPlayingRun()
    return self:IsPlayingAction(cfg.skill.AnimType.Run) or
           self:IsPlayingAction(cfg.skill.AnimType.RunFight) or
           self:IsPlayingAction(cfg.skill.AnimType.Walk) 
end


--是否正在播放站立
function Character:IsPlayingStand()
    return self:IsPlayingAction(cfg.skill.AnimType.Stand) or
           self:IsPlayingAction(cfg.skill.AnimType.StandFight) 
end


--是否正在播放轨迹飞行开始
function Character:IsPlayingPathFlyStart()
    return self:IsPlayingAction(cfg.skill.AnimType.PathFlyStart)
end
--是否正在播放轨迹飞行中
function Character:IsPlayingPathFlyLoop()
    return self:IsPlayingAction(cfg.skill.AnimType.PathFlyLoop)
end
--是否正在播放轨迹飞行结束
function Character:IsPlayingPathFlyEnd()
    return self:IsPlayingAction(cfg.skill.AnimType.PathFlyEnd)
end
