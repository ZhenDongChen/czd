local network           = require"network"
local CharacterManager  = require"character.charactermanager"
local ConfigManager     = require"cfg.configmanager"
local AudioManager      = require"audiomanager"
local uimanager         = require"uimanager"
local PlayerRole        = require"character.playerrole"
local CameraManager     = require "cameramanager"
local tools             = require"ectype.ectypetools"
local PlotManager       = require("plot.plotmanager")
local SlowTime          = require"assistant.slowtime"
local defineenum        = require"defineenum"
local audioClipTime     = nil
local uiectype

local EctypeActionsManager = Class:new()


function EctypeActionsManager:AddActionIntoTable(index,Action)
    local ActionIndex = self.m_AllTypes[Action.class]
    if ActionIndex then
        if ActionIndex > 4 then
            local action = Action
            action.type = Action.class
            if action.actionid == 35 then
            end
            self.m_AllActions[Action.actionid]=action
        else
            if ActionIndex<3 then
                for _,v in pairs(Action.actions) do
                    self:AddActionIntoTable(_,v)
                end
            else
                for _,v in pairs(Action.cases) do
                    self:AddActionIntoTable(_,v.action)
                end
            end
        end
    end
end

function EctypeActionsManager:__new(ectypeinfo,character,currentEctype)
    self.m_ActionName         = {
        'cfg.ectype.Parallel',
        'cfg.ectype.Sequence',
        'cfg.ectype.Switch',
        'cfg.ectype.SwitchUntil',
        'cfg.ectype.OnceTimer',
        'cfg.ectype.CirculateTimer',
        'cfg.ectype.StopTimer',
        'cfg.ectype.Move',
        'cfg.ectype.PlayCG',
        'cfg.ectype.Dialog',
        'cfg.ectype.CharacterAction',
        'cfg.ectype.ControllerOperation',
        'cfg.ectype.SetEnviroment',
        'cfg.ectype.EnviromentOperate',
        'cfg.ectype.PlaySkill',
        'cfg.ectype.CallMonster',
        'cfg.ectype.CallMineral',
        'cfg.ectype.CallSpecialEffect',
        'cfg.ectype.Delay',
        'cfg.ectype.PlayAudio',
        'cfg.ectype.GetBuff',
        'cfg.ectype.ShapeShift',
        'cfg.ectype.GFX',
        'cfg.ectype.PlayerEffect',
        'cfg.ectype.Enter',
        'cfg.ectype.Exit',
        'cfg.ectype.LayoutFinished',
        'cfg.ectype.AlertRange',
        'cfg.ectype.AlterGuide',
        'cfg.ectype.KillMonster',
        'cfg.ectype.CollectMineral',
        'cfg.ectype.ResumeGuide',
        'cfg.ectype.PathFinding',
        'cfg.ectype.HPCheck',
        'cfg.ectype.ShowGlobalTips',
        'cfg.ectype.AddDescription',
        'cfg.ectype.RemoveDescription',
        'cfg.ectype.SpecialEffect',
        'cfg.ectype.ProfessionCG',
        'cfg.ectype.FreshGuide',
        'cfg.ectype.Transmit',
    }
    self.m_AllTypes                 = {}
    for i,v in ipairs(self.m_ActionName) do
        self.m_AllTypes[v]=i
    end
    self.m_AllActions               = {}
    self.m_CurrentActions           = {}
    for i,v in pairs(ectypeinfo.layouts_id) do
        for ii,vv in pairs(v.scripts) do
            self:AddActionIntoTable(ii,vv)
        end
    end
    self.m_Character                = character
    self.m_CurrentEctype            = currentEctype
    self.m_PlayAction               = false
    self.m_CurrentDialogActionID    = nil
    self.m_CurrentDialogElapsedTime = nil
    self.m_IsDialoging              = false
    self.m_IsManualTips             = false
    self.m_ManualActionID           = nil
    self.m_TextStack                = {}
    self.m_TextedAction             = {}
    self.m_PlayedAction             = {}
    self.m_CharsDoingActions        = {}
    self.m_HasTextAction            = false
    self.m_CurrentFindingArea       = {}
    self.m_CurrentTarget            = nil
    self.m_IsPlayingCG              = false
    self.m_ShowGlobalTips           = false
    self.m_IsStop                   = false
    self.m_bCurrentMissionGlobal    = false
    self.m_AudioClipTime            = nil
    self.m_SpecialEffects           = {}
    self.m_CurrentMissionInfomation = nil
    self.m_AlterdEnviroment         = false
    self.m_EctypePause              = false
    uiectype                        = require"ui.ectype.dlguiectype"
end

function EctypeActionsManager:LeaveEctype()
    for path,trans in pairs(self.m_SpecialEffects) do
        trans.gameObject:SetActive(false)
    end
    self:ResumeMoveSkillsNav()
end

function EctypeActionsManager:Reset(initActions)
    for id,v in pairs(self.m_CurrentActions) do
        self:RemoveAction(id)
    end
    for _,id in pairs(initActions) do
		
        self:AddAction(id)
    end
end

function EctypeActionsManager:IsPlayingCG()
    return self.m_IsPlayingCG
end

function EctypeActionsManager:CheckShowText(action)
    if action.isglobal and not self.m_ShowGlobalTips then
        return false
    else
        return true
    end
end

function EctypeActionsManager:ChangeEnviroment()
    self.m_AlterdEnviroment = true
end

function EctypeActionsManager:RefreshShowGlobalTips()
    self.m_ShowGlobalTips = false
end

function EctypeActionsManager:GetAction(id)
    return self.m_AllActions[id]
end

function EctypeActionsManager:IsTextAction(id)
    local action = self:GetAction(id)
    if  action.type == 'cfg.ectype.PathFinding'     or
        action.type == 'cfg.ectype.KillMonster'     or
        action.type == 'cfg.ectype.CollectMineral'  or
        action.type == 'cfg.ectype.HPCheck'
    then
        return true
    end
    return false
end

function EctypeActionsManager:IsResuming(id)
    local action = self:GetAction(id)
    return action.type == 'cfg.ectype.AlterGuide'
end

function EctypeActionsManager:IsKillMonsterAction(id)
    local action = self:GetAction(id)
    if action.type == 'cfg.ectype.KillMonster' then
        return true
    end
    return false
end

function EctypeActionsManager:IsSlowMotionAction(id)
    local action = self:GetAction(id)
    if action.type == 'cfg.ectype.HPCheck' or
    action.type == 'cfg.ectype.KillMonster' then
        return true
    else
        return false
    end
end

function EctypeActionsManager:AddAction(id)
     printyellow("AddAction",id)
    if not self.m_CurrentActions[id] then
        self.m_CurrentActions[id] = self:GetAction(id)
        if self:IsTextAction(id) then
            table.insert(self.m_TextStack,id)
        end
    end
end

function EctypeActionsManager:RemoveAction(id)
    print("RemoveAction",id)
    if self.m_CurrentActions[id] then
        if self:IsTextAction(id) then
            table.remove(self.m_TextStack)
            if #self.m_TextStack > 0 then
                if self.m_CurrentActions[self.m_TextStack[#self.m_TextStack]].isglobal then
                    self.m_TextedAction[self.m_TextStack[#self.m_TextStack]] = -1
                end
            end
        end
        if self:IsResuming(id) then
            self.m_ManualActionID = nil
            self.m_IsManualTips = false
            if uimanager.isshow("ectype.dlguiectype") then
                uimanager.call("ectype.dlguiectype","Clear")
            end
        end
        if self:IsSlowMotionAction(id) then
            local action = self:GetAction(id)
            if action.slowmotion then
                local motionid = tonumber(action.motionid)
                SlowTime.StartSlowTimeById(motionid)
            end
        end
        self.m_CurrentActions[id] = nil
    end
end

function EctypeActionsManager:ContainsAction(id)
    if self.m_CurrentActions[id] then return true
    else return false end
end

function EctypeActionsManager:DoAction(action)
    if action.type == 'cfg.ectype.OnceTimer' then

    elseif action.type == 'cfg.ectype.CirculateTimer' then

    elseif action.type == 'cfg.ectype.StopTimer' then

    elseif action.type == 'cfg.ectype.Move' then

    elseif action.type == 'cfg.ectype.PlayCG' then
        self:ActionPlayCG(action)
    elseif action.type == 'cfg.ectype.Dialog' then
        self:ActionDialog(action)
    elseif action.type == 'cfg.ectype.CharacterAction' then
        self:CharacterAction(action)
    elseif action.type == 'cfg.ectype.ControllerOperation' then

    elseif action.type == 'cfg.ectype.SetEnviroment' then

    elseif action.type == 'cfg.ectype.EnviromentOperate' then

    elseif action.type == 'cfg.ectype.PlaySkill' then

    elseif action.type == 'cfg.ectype.CallMonster' then

    elseif action.type == 'cfg.ectype.CallMineral' then

    elseif action.type == 'cfg.ectype.CallSpecialEffect' then

    elseif action.type == 'cfg.ectype.Delay' then

    elseif action.type == 'cfg.ectype.PlayAudio' then
        self:ActionPlayAudio(action)
    elseif action.type == 'cfg.ectype.GetBuff' then

    elseif action.type == 'cfg.ectype.ShapeShift' then
        self:ActionShapeShift(action)
    elseif action.type == 'cfg.ectype.GFX' then

    elseif action.type == 'cfg.ectype.PlayerEffect' then
        self:ActionPlayerEffect(action)
    elseif action.type == 'cfg.ectype.Enter' then

    elseif action.type == 'cfg.ectype.Exit' then

    elseif action.type == 'cfg.ectype.LayoutFinished' then

    elseif action.type == 'cfg.ectype.AlertRange' then

    elseif action.type == 'cfg.ectype.AlterGuide' then
        self:ActionAlterGuide(action)
    elseif action.type == 'cfg.ectype.KillMonster' then
        self:ActionKillMonster(action)
    elseif action.type == 'cfg.ectype.CollectMineral' then
        self:ActionCollectMineral(action)
    elseif action.type == 'cfg.ectype.ResumeGuide' then
        self:ActionResumeGuide(action)
    elseif action.type == 'cfg.ectype.PathFinding' then
        self:ActionPathFinding(action)
    elseif action.type == 'cfg.ectype.HPCheck' then
        self:ActionHPCheck(action)
    elseif action.type == 'cfg.ectype.Transmit' then
        -- self:ActionTransmit(action)
    elseif action.type == 'cfg.ectype.ShowGlobalTips' then
        self:ActionShowGlobalTips(action)
    elseif action.type == 'cfg.ectype.AddDescription' then
        self:ActionAddDescription(action)
    elseif action.type == 'cfg.ectype.RemoveDescription' then
        self:ActionRemoveDescription(action)
    elseif action.type == 'cfg.ectype.SpecialEffect' then
        self:ActionSpecialEffect(action)
    elseif action.type == 'cfg.ectype.ProfessionCG' then
        self:ActionProfessionCG(action)
    elseif action.type == 'cfg.ectype.FreshGuide' then
        self:ActionFreshGuide(action)
    end
end

function EctypeActionsManager:DisplayCurrentActions()
    local text = "current actions:"
    for _,v in pairs(self.m_CurrentActions) do
        text = text .. '\t' .. tostring(v.actionid)
    end
    -- printyellow(text)
end

function EctypeActionsManager:ClearText()
    if uimanager.isshow("ectype.dlguiectype") then
        uimanager.call("ectype.dlguiectype","Clear")
    end
end

function EctypeActionsManager:Update()
    -- self:DisplayCurrentActions()
    if uimanager.isshow("ectype.dlguiectype") then
        if #self.m_TextStack>0 or self.m_IsManualTips then
            uimanager.call("ectype.dlguiectype","ShowGoal")
        else
            uimanager.call("ectype.dlguiectype","HideGoal")
        end
    end
    self.m_HasTextAction = false
    for _,v in pairs(self.m_CurrentActions) do
        self:DoAction(v)
    end
    if not self.m_HasTextAction and not self.m_IsManualTips then
        self:ClearText()
    end
    self.m_AlterdEnviroment = false
end

function EctypeActionsManager:ActionAddDescription(action)
    uimanager.call("ectype.dlguiectype","AddDescription",action.content)
    self:RemoveAction(action.actionid)
end

function EctypeActionsManager:ActionRemoveDescription(action)
    uimanager.call("ectype.dlguiectype","RemoveDescription",action.content)
    self:RemoveAction(action.actionid)
end

function EctypeActionsManager:GetFormatedMissionInfo(name,cnt,env,type)
    local ret = {}
    local coloredName = ' '..LocalString.PartnerText.ActiveColor..name .. LocalString.PartnerText.ColorSuffix..' '
    if type==1 then
        table.insert(ret,string.format(LocalString.EctypeText.KillMonster, coloredName))
        table.insert(ret,string.format("(%s/%s)",tostring(env),tostring(cnt)))
    else
        table.insert(ret,string.format(LocalString.EctypeText.CollectMineral,coloredName))
        table.insert(ret,string.format("(%s/%s)",tostring(env),tostring(cnt)))
    end
    return ret
end

function EctypeActionsManager:GetFormatedHPCheckInfo(name,op,percent)
    local ret = {}
    local coloredName = ' '..LocalString.PartnerText.ActiveColor..name .. LocalString.PartnerText.ColorSuffix..' '
    table.insert(ret,LocalString.EctypeText.Beat .. coloredName)
    table.insert(ret,'('..LocalString.EctypeText.Do .. LocalString.EctypeText.HPCheckOperator[op] .. tostring(percent) .. '%)')
    return ret
end

function EctypeActionsManager:ActionShowGlobalTips(action)
    self.m_ShowGlobalTips = true
    self:RemoveAction(action.actionid)
end

function EctypeActionsManager:ActionHPCheck(action)
    if self.m_IsManualTips then return end
    if not self:CheckShowText(action) then return end
        self.m_HasTextAction = true
    if self.m_TextedAction[action.actionid] then
        if self.m_TextedAction[action.actionid] < 0 and self.m_TextedAction[action.actionid]+Time.deltaTime >=0 then
            -- uimanager.call("ectype.dlguiectype","ATFight",0)
            if action.autofight then
                if uimanager.isshow("ectype.dlguiectype") then
                    uimanager.call("ectype.dlguiectype","ATFight",0)
                end
            end
        end
        self.m_TextedAction[action.actionid] = self.m_TextedAction[action.actionid] + Time.deltaTime
        if self:ContainsAction(action.actionid) then
            if action.actionid == self.m_TextStack[#self.m_TextStack] and (self.m_CurrentMissionInfomation~=action.actionid or self.m_AlterdEnviroment) then
                self.m_CurrentMissionInfomation = action.actionid
                local csvid = action.id
                local op = action.op
                local percent = action.percent * 100
                local name
                if csvid  == 0 then
                    name = PlayerRole.Instance():GetName()
                else
                    local cfgMonster = ConfigManager.getConfigData("monster",action.id)
                    name = cfgMonster.name
                end
                if uimanager.hasloaded("ectype.dlguiectype") then
                    uiectype = require"ui.ectype.dlguiectype"
                    self:ClearText()
                    uiectype.InsertMissionInfomation(0,self:GetFormatedHPCheckInfo(name,op,percent),{type="monster",target=action.id,autofight=false})
                end
            end
        end
    else
        self.m_TextedAction[action.actionid] = -1
    end
end

function EctypeActionsManager:ActionShapeShift(action)

end

function EctypeActionsManager:ActionPlayAudio(action)
--    AudioManager.Instance:PlayBgMusic("audio/"..action.name..".mp3")
end

function EctypeActionsManager:ActionPathFinding(action)
    if self.m_IsManualTips then return end
    if not self:CheckShowText(action) then return end
    self.m_HasTextAction = true
    if self.m_TextedAction[action.actionid] then
        if self:ContainsAction(action.actionid) then
            if action.actionid == self.m_TextStack[#self.m_TextStack] then
                if self.m_CurrentMissionInfomation~=action.actionid or self.m_AlterdEnviroment then
                    self.m_CurrentMissionInfomation = action.actionid
                    if uimanager.isshow("ectype.dlguiectype") then
                        uiectype = require"ui.ectype.dlguiectype"
                        self:ClearText()
                        uiectype.InsertMissionInfomation(0,{action.content,""},{type="position",target=self.m_CurrentTarget,actionid=actionid,area=self.m_CurrentFindingArea})
                    end
                end
		local newPos = Vector3(PlayerRole.Instance():GetPos().x * SCALE_XY_FRACTION, PlayerRole.Instance():GetPos().y * SCALE_XY_FRACTION, 0);
                if tools.CheckInTheArea(newPos,self.m_CurrentFindingArea) then
                    local re = map.msg.CClientActionEnd({actionid = action.actionid})
                    network.send(re)
                    self:RemoveAction(action.actionid)
                end
            end
        end
    else
        self.m_CurrentFindingArea = self.m_CurrentEctype:GetArea(action.curveid)
        local Tarpos = tools.GetMidPoint(self.m_CurrentFindingArea)
		 self.m_CurrentTarget = Vector3(Tarpos.x * SCALE_XY, Tarpos.y * SCALE_XY , 0);
        self.m_TextedAction[action.actionid] = true
    end
end

function EctypeActionsManager:ActionAlterGuide(action)
    if not self.m_IsManualTips then
        if uimanager.isshow("ectype.dlguiectype") then
            uimanager.call("ectype.dlguiectype","Clear")
        end
        if uimanager.isshow("ectype.dlguiectype") then
            uiectype = require"ui.ectype.dlguiectype"
            self:ClearText()
            if action.bpathfinding then
                uiectype.InsertMissionInfomation(0,{action.content,""},{type="position",target=Vector3(action.targetposition.x,action.targetposition.y, 0)})
            else
                uiectype.InsertMissionInfomation(0,{action.content,""})
            end
        end
        self.m_ManualActionID = action.actionid
        self.m_IsManualTips = true
    end
end

function EctypeActionsManager:ShutDialogActon()
	printyellow("EctypeActionsManager:ShutDialogActon")
    self.m_CurrentDialogElapsedTime = -1
    self.m_AudioClipTime = nil
    AudioManager.Stop2DSound()
end

function EctypeActionsManager:DialogTimeUpdate()
	
	--printyellow("DialogTimeUpdate m_AudioClipTime="..tostring(m_AudioClipTime).." ,m_CurrentDialogElapsedTime="..tostring(m_CurrentDialogElapsedTime))
	
    if self.m_AudioClipTime then
        self.m_CurrentDialogElapsedTime = math.max(self.m_AudioClipTime,self.m_CurrentDialogElapsedTime)
        self.m_AudioClipTime = nil
    end
    if self.m_CurrentDialogElapsedTime then
        self.m_CurrentDialogElapsedTime = self.m_CurrentDialogElapsedTime - Time.deltaTime
    else
        return
    end
    if self.m_CurrentDialogElapsedTime<0 then
        self.m_CurrentDialogElapsedTime = nil
        self.m_IsDialoging = false
		--printyellow("DialogTimeUpdate")
        local re = map.msg.CClientActionEnd({actionid = self.m_CurrentDialogActionID})
        network.send(re)
	--	printyellow("DialogTimeUpdate m_CurrentDialogActionID="..tostring(self.m_CurrentDialogActionID))
		
        self:RemoveAction(self.m_CurrentDialogActionID)
        if self.m_IsStop then
            self:ResumeMoveSkillsNav()
            self.m_EctypePause = false
        end
        uimanager.hide("dlgstorycopy_talk")
    end
end

function EctypeActionsManager:ResumeMoveSkillsNav()
    self.m_Character:ResumeMoveOperations()
    self.m_Character:ResumeSkillsOperations()
    if uimanager.isshow("ectype.dlguiectype") then
        -- local uiEctype = require"ui.ectype.dlguiectype"
        -- uiEctype.ContinueNav()
        uimanager.call("ectype.dlguiectype","ContinueNav")
    end
end

function EctypeActionsManager:StopMoveSkillsNav()
    self.m_Character:StopMoveOperations()
    self.m_Character:StopSkillsOperations()
    if uimanager.isshow("ectype.dlguiectype") then
        -- local uiEctype = require"ui.ectype.dlguiectype"
        -- uiEctype.StopNav()
        uimanager.call("ectype.dlguiectype","StopNav")
    end
end

function EctypeActionsManager:ActionDialog(action)
    local speaker,speakername, image
    if not self.m_IsDialoging then
        self.m_IsDialoging = true
        self.m_IsStop = action.isstop
        if self.m_IsStop then
            self:StopMoveSkillsNav()
            self.m_EctypePause = true
        end
        local audioInfo = ConfigManager.getConfigData("storydialogsound",action.audioid)
        local audioid = nil
        if action.speakertype == 0 then
            speaker=PlayerRole.Instance()
            speakername = PlayerRole.Instance():GetName()
            image = PlayerRole.Instance():GetHeadIcon()
        elseif action.speakertype == 1 then
            speaker = ConfigManager.getConfigData("npc",action.id)
            local model = ConfigManager.getConfigData("model",speaker.modelname)
            speakername = speaker.name
            image = model.headicon
            audioid = audioInfo and audioInfo.npcaudio or 0
        else
            speaker = ConfigManager.getConfigData("monster",action.id)
            local model = ConfigManager.getConfigData("model",speaker.modelname)
            speakername = speaker.name
            image = model.headicon
            audioid = audioInfo and audioInfo.npcaudio or 0
        end
        if not audioid and audioInfo then
            if self.m_Character:IsMale() then
                if self.m_Character.m_Profession == cfg.role.EProfessionType.XIANZU then
                    audioid = audioInfo.boyaudio
                else
                    audioid = audioInfo.maleaudio
                end
            else
                if self.m_Character.m_Profession == cfg.role.EProfessionType.XIANZU then
                    audioid = audioInfo.girlaudio
                else
                    audioid = audioInfo.femaleaudio
                end
            end
        end
        audioid = audioid or 0
        uimanager.show("dlgstorycopy_talk",{name=speaker and speakername or "speaker",content = action.content,icon=image,
        frameid=action.dialogtype,stop=action.isstop,callbackClose = function()
			
            self:ShutDialogActon()
        end})
		--TODO 获取音频的长度
--[[        AudioManager.PlayAduioByAudioClip(audioid,function(f)
              self.m_AudioClipTime = f
        end)
--]]
		--由于资源原因临时处理
		self.m_AudioClipTime = 1
		--
        self.m_CurrentDialogActionID = action.actionid
        self.m_CurrentDialogElapsedTime = 3
    else
        self:DialogTimeUpdate()
    end
end

function EctypeActionsManager:CharacterAction(action)
    if not self.m_PlayedAction[action.actionid] then
        self.m_PlayedAction[action.actionid] = true
        self.m_CharsDoingActions[action.actionid] = {}
        local characters = CharacterManager.GetCharacters()
        local chars = self.m_CharsDoingActions[action.actionid]
        if action.actortype == 0 then
            table.insert(chars,PlayerRole.Instance())
        else
            for i,v in pairs(characters) do
                if v.m_CsvId == action.id then
                    table.insert(chars,v)
                end
            end
        end
        for i,v in pairs(chars) do
            v:PlayFreeAction(action.action)
        end
    else
        local finished = true
        local chars = self.m_CharsDoingActions[action.actionid]
        for i,v in pairs(chars) do
            if v.AnimationMgr:IsPlaying(action.action) then
                finished = false
            end
        end
        if finished then
            self:RemoveAction(action.actionid)
            local re = map.msg.CClientActionEnd({actionid = action.actionid})
            network.send(re)
            self.m_CharsDoingActions[action.actionid] = nil
        end
    end
end

function EctypeActionsManager:ActionPlayCG(action)
    if not self.m_IsPlayingCG then
        self.m_IsPlayingCG = true
        PlotManager.CutscenePlay(action.name,function()
            self.m_IsPlayingCG = false
            uimanager.show("ectype.dlguiectype")
            self:RemoveAction(action.actionid)
            local re = map.msg.CClientActionEnd({actionid=action.actionid})
            network.send(re)
            -- CameraManager.ResetRotation()
        end)
    end
end

function EctypeActionsManager:ActionProfessionCG(action)
    if not self.m_IsPlayingCG then
        self.m_IsPlayingCG = true
        PlotManager.CutscenePlay(action.professioncgs[PlayerRole.Instance().m_Profession],function()
            self.m_IsPlayingCG = false
            uimanager.show("ectype.dlguiectype")
            self:RemoveAction(action.actionid)
            local re = map.msg.CClientActionEnd({actionid=action.actionid})
            network.send(re)
            -- CameraManager.ResetRotation()
        end)
    end
end

function EctypeActionsManager:ActionPlayerEffect(action)
    self.m_Character.m_Effect:AddEffect(action.id)
end


function EctypeActionsManager:ActionKillMonster(action)
    if self.m_IsManualTips then return end
    if not self:CheckShowText(action) then return end
    self.m_HasTextAction = true
    if self.m_TextedAction[action.actionid] then
        self.m_TextedAction[action.actionid] = self.m_TextedAction[action.actionid] + Time.deltaTime
		if self.m_TextedAction[action.actionid] > 1 and self.m_TextedAction[action.actionid] < 1.5 then
			self.m_TextedAction[action.actionid] = 1.5
            if action.autofight then
                if uimanager.isshow("ectype.dlguiectype") then
                    uimanager.call("ectype.dlguiectype","ATFight",0)
                end
            end
        end
        if self:ContainsAction(action.actionid) then
            if action.actionid == self.m_TextStack[#self.m_TextStack] and (self.m_CurrentMissionInfomation~=action.actionid or self.m_AlterdEnviroment) then

                self.m_CurrentMissionInfomation = action.actionid
                self:ClearText()
                for i,v in ipairs(action.missions) do
                    local monsterid = v.monsterid
                    local enviroment = self.m_CurrentEctype:GetEnviroment(v.enviroment)
                    local count = v.count
                    --update ui
                    local monsterinfo = ConfigManager.getConfigData("monster",monsterid)
                    if monsterinfo then
                        if uimanager.isshow("ectype.dlguiectype") then
                            uiectype = require"ui.ectype.dlguiectype"
                            uiectype.InsertMissionInfomation(i-1,self:GetFormatedMissionInfo(monsterinfo.name,count,enviroment,1),
                            {type="monster",target=monsterid,autofight=false})
                        end
                    end
                end
            end
        end
    else
        self.m_TextedAction[action.actionid] = -1
    end
end

function EctypeActionsManager:ActionCollectMineral(action)
    if self.m_IsManualTips then return end
    if not self:CheckShowText(action) then return end
    self.m_HasTextAction = true
    if self.m_TextedAction[action.actionid] then
        if self:ContainsAction(action.actionid) then
            if action.actionid == self.m_TextStack[#self.m_TextStack] and (self.m_CurrentMissionInfomation~=action.actionid or self.m_AlterdEnviroment) then

                self.m_CurrentMissionInfomation = action.actionid
                self:ClearText()
                for i,v in ipairs(action.missions) do
                    local mineralid = v.mineralid
                    local enviroment = self.m_CurrentEctype:GetEnviroment(v.enviroment)
                    local count = v.count
                    local mineralinfo = ConfigManager.getConfigData("mine",mineralid)
                    if uimanager.isshow("ectype.dlguiectype") then
                        uiectype = require"ui.ectype.dlguiectype"
                        uiectype.InsertMissionInfomation(i-1,self:GetFormatedMissionInfo(mineralinfo.name,count,enviroment,2),
                        {type="mineral",target=mineralid})
                    end
                end
            end
        end
    else
        self.m_TextedAction[action.actionid] = true
    end
end

function EctypeActionsManager:ActionSpecialEffect(action)
    local go = GameObject.Find("SpecialEffects")
    if not go then return end
    local seTransform = go.transform:Find(action.path)
    if not seTransform then return end
    seTransform.gameObject:SetActive(action.isopen)
    if action.isopen then
        self.m_SpecialEffects[action.path] = seTransform
    else
        if self.m_SpecialEffects[action.path] then
            self.m_SpecialEffects[action.path] = nil
        end
    end
    self:RemoveAction(action.actionid)
end

function EctypeActionsManager:Transmit(action)
    self.m_Character.WorkMgr:StopWork(defineenum.WorkType.Move)
    local targetposition = Vector3(action.position.x,0,action.position.y)
    local quat = Quaternion.Euler(0,action.rotation,0)
    local targetrotation = quat:Forward()
    self.m_Character:SetPos(targetposition)
    self.m_Character:SetRotationImmediate(targetrotation)
    self.m_Character.m_TransformSync:SendStop()
    self:RemoveAction(action.actionid)
end
--
function EctypeActionsManager:ActionTransmit(action)

end

function EctypeActionsManager:ActionFreshGuide(action)
    local cb = function()
        local re = map.msg.CClientActionEnd({actionid = action.actionid})
    end

end


return EctypeActionsManager
