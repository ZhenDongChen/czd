local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require "uimanager"
local network = require "network"

local os = require 'cfg.structs'
local create_datastream = create_datastream

local configmanager = require "cfg.configmanager"
local taskmanager = require "taskmanager"
local charactermanager = require "character.charactermanager"
local PlayerRole = require "character.playerrole"
local Npc = require "character.npc"
local Player = require "character.player"

local EffectManager = require "effect.effectmanager"
local AudioManager = require"audiomanager"


local defineenum = require "defineenum"
local NpcStatusType = defineenum.NpcStatusType
local TaskStatusType = defineenum.TaskStatusType
local TaskType = defineenum.TaskType



local gameObject
local name

local fields

local UILabel_Content = nil
local UILabel_Name = nil
local UITexture_Left = nil
local UITexture_Right = nil
local UIButton_Next = nil
local UILabel_Next = nil
local UISprite_Click = nil
local UISprite_NPChead = nil
local UITexture_NPChead = nil
local UISprite_Background = nil

local audioSource = nil

local dialogIndex = 1

local taskid = 0


local g_Character

local CurTalkDuration = -1;


local function OnModelLeftLoaded(obj)
    if not g_Character or not g_Character.m_Object then return end
    local playerTrans         = g_Character.m_Object.transform
    playerTrans.parent        = UITexture_Left.transform
    g_Character:SetUIScale(300)
	g_Character.m_Object:SetActive(true)
    local yOffset = defineenum.g_ModelOffset[g_Character.m_Id] or 0
    playerTrans.localPosition = Vector3(0, yOffset, 0)
    playerTrans.localRotation = Quaternion.Euler(-90,0,0)
    ExtendedGameObject.SetLayerRecursively(g_Character.m_Object, define.Layer.LayerUICharacter)
end

local function OnModelRightLoaded(obj)
    if not g_Character or not g_Character.m_Object then return end
    local playerTrans         = g_Character.m_Object.transform
    playerTrans.parent        = UITexture_Right.transform
    g_Character:SetUIScale(250)
    playerTrans.localPosition = Vector3().zero
    playerTrans.localRotation = Quaternion.Euler(-90,180,0)
    ExtendedGameObject.SetLayerRecursively(g_Character.m_Object, define.Layer.LayerUICharacter)
end

local function ShowLeftNpc(Id, CsvId)
	
	if g_Character then
		g_Character:release()
		g_Character = nil
	end
	
	-- 初始化模型
	g_Character = Npc:new()
	g_Character.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
	g_Character:RegisterOnLoaded(OnModelLeftLoaded)
	g_Character:init(Id, CsvId, false)
	
end

local function ShowRightPlayer()
	if g_Character then
		g_Character:release()
		g_Character = nil
	end
	
	
	-- 初始化模型
	g_Character = Player:new(true)
	g_Character.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
	g_Character:RegisterOnLoaded(OnModelRightLoaded)
	g_Character:init(PlayerRole:Instance().m_Id, PlayerRole:Instance().m_Profession, PlayerRole:Instance().m_Gender,false,
        PlayerRole:Instance().m_Dress,PlayerRole:Instance().m_Equips,nil,0.75)
	
end


local function PlayTalk()
    local task = taskmanager.GetTask(taskid)
    local isFinished = true
    if task then
		CurTalkDuration = 0;
        isFinished = false
        local taskStatus = taskmanager.GetTaskStatus(task.id)
        if taskStatus == TaskStatusType.Completed then
            isFinished = true
        else
            local npcid = task.accept.npcid
            if task.basic.tasktype == TaskType.Family then
                if taskStatus == TaskStatusType.UnCommitted then
                    npcid = taskmanager.GetFamilyNPC(task.id, false)
                else
                    npcid = taskmanager.GetFamilyNPC(task.id, true)
                end
            end

            taskmanager.SetNpcStatus(npcid, { taskid = task.id, npcstatus = NpcStatusType.None })

            local len = 0
            if taskStatus == TaskStatusType.UnCommitted then
                len = table.getn(task.basic.success)
            else
                len = table.getn(task.basic.npcdialogue)
            end

            if len > 0 and len >= dialogIndex then
                local dialoginfo = nil
                if taskStatus == TaskStatusType.UnCommitted then
                    dialoginfo = task.basic.success[dialogIndex]
                else
                    dialoginfo = task.basic.npcdialogue[dialogIndex]
                end

                UILabel_Content.text = taskmanager.ReplaceWildcard(dialoginfo.dialogcontent)

                if dialoginfo.voiceid > 0 and audioSource then
                    -- printyellow("voiceid:" .. dialoginfo.voiceid)
                    local audioid = taskmanager.GetDialogueAudioClipId(dialoginfo.voiceid)
                    if audioid and audioid > 0 then
                        AudioManager.PlaySoundBySelfAudioSource(audioid, audioSource)
                    end
                end

                local npc = taskmanager.GetNpcData(npcid)
                local npcmodeldata = nil
                if npc then
                    npcmodeldata = configmanager.getConfigData("model", npc.modelname)
                end

                -- if task.basic.tasktype == TaskType.Family then
                --     if dialoginfo.role == cfg.task.EDialogueRoleType.NPC then
                --         if npcmodeldata and npcmodeldata.headicon and string.len(npcmodeldata.headicon) > 0 then
                --             -- printyellow("npc head icon:" .. npcmodeldata.headicon)
                --             UILabel_Name.text = npc.name
                --             UITexture_NPChead:SetIconTexture(npcmodeldata.headicon)
                --             -- UISprite_NPCheadUISprite_NPChead.gameObject:SetActive(true)
                --         else
                --             -- UISprite_NPChead.gameObject:SetActive(false)
                --             logError("npc head icon is nil")
                --         end
                --     else
                --         UILabel_Name.text = PlayerRole:Instance().m_Name
                --         local headicon = PlayerRole:Instance():GetHeadIcon()
                --         if headicon and string.len(headicon) > 0 then
                --             -- printyellow("role head icon:" .. headicon)
                --             UITexture_NPChead:SetIconTexture(headicon)
                --             -- UISprite_NPChead.gameObject:SetActive(true)
                --         else
                --             -- UISprite_NPChead.gameObject:SetActive(false)
                --             logError("role head icon is nil")
                --         end
                --     end
                -- else
                    if dialoginfo.role == cfg.task.EDialogueRoleType.NPC then
                        -- NPC
                        if npc then
                            UILabel_Name.text = npc.name
                        end
                        ShowLeftNpc(npcid, npcid);
						UITexture_Left.gameObject:SetActive(true)
						UITexture_Right.gameObject:SetActive(false)
                    else
                        -- 主角
                        UILabel_Name.text = PlayerRole:Instance().m_Name
                        ShowRightPlayer();
						UITexture_Left.gameObject:SetActive(false)
						UITexture_Right.gameObject:SetActive(true)
                    end
                -- end

                dialogIndex = dialogIndex + 1
            else
                isFinished = true;
            end
        end
    end

    return isFinished
end

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
    if params == nil then
       logError("dlgtasktalk show params is nil")
       return
    end

    taskid = params.taskid

	CurTalkDuration = -1;
    dialogIndex = 1
    PlayTalk()
end


local function hide()
    -- print(name, "hide")

    if audioSource then
        audioSource:Stop()
    end

    local leftTweenScale = UITexture_Left:GetComponent("TweenScale")
    leftTweenScale.enabled = false

    local rightTweenScale = UITexture_Right:GetComponent("TweenScale")
    rightTweenScale.enabled = false

    UITexture_Left.gameObject:SetActive(false)
    UITexture_Right.gameObject:SetActive(false)
    UISprite_NPChead.gameObject:SetActive(false)
	CurTalkDuration = -1;
end

local function refresh(params)
    -- print(name, "refresh")
end

local function NextBtnOnClick()
    local ret = PlayTalk() 
    print("dlgtasktalk PlayTalk():"..tostring(ret))
    if ret == true then
        uimanager.hidedialog("dlgtasktalk")
        local task = taskmanager.GetTask(taskid)
        if task then
            local taskStatus = taskmanager.GetTaskStatus(task.id)
            if taskStatus == TaskStatusType.UnCommitted then
                 taskmanager.CompleteTask(task.complete.npcid, task.id)
            else
                taskmanager.RefreshNPCShowHide(task)
                if taskStatus ~= TaskStatusType.Doing then
                    taskmanager.SetTaskStatus(task.id, TaskStatusType.Doing)
                end
                -- 喊话
                taskmanager.SetShoutDialogue(task.id, function()
                    -- 播放CG
                    taskmanager.PlayCG(task, cfg.task.EPlayingCGType.WHEN_ACCEPTING, function()
                        -- 执行任务
                        taskmanager.DoTask(task.id)
                        EffectManager.PlayEffect { id = 51015, casterId = PlayerRole:Instance().m_Id, targetId = PlayerRole:Instance().m_Id, targetPos = PlayerRole:Instance():GetPos(), bSkill = false }
                    end )
                end )
            end
        end
    end
end

local function update()
    -- print(name, "update")
	if g_Character and g_Character.m_Object and g_Character.m_Avatar then
		g_Character.m_Avatar:Update()
	end
	
	if CurTalkDuration ~= -1 then
		CurTalkDuration = CurTalkDuration + Time.deltaTime
		if CurTalkDuration > 3 then
			CurTalkDuration = 0;
			NextBtnOnClick()
		end
	end
end


local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_Bottom)
end
local function init(params)
    name, gameObject, fields = unpack(params)
    SetAnchor(fields)
	CurTalkDuration = -1;
    UILabel_Content = fields.UILabel_Content
    UILabel_Name = fields.UILabel_NPCName
    UITexture_Left = fields.UITexture_Left
    UITexture_Right = fields.UITexture_Right
    UIButton_Next = fields.UIButton_Next
    UILabel_Next = fields.UILabel_Next
    UISprite_Click = fields.UISprite_Click
    UISprite_NPChead = fields.UISprite_NPChead
    UITexture_NPChead = fields.UITexture_NPChead
    UISprite_Background = fields.UISprite_Background

    if UISprite_Background and UISprite_Background.gameObject then
        audioSource = UISprite_Background.gameObject:GetComponent(AudioSource)
        if not audioSource then
            audioSource = UISprite_Background.gameObject:AddComponent(AudioSource)
        end
    end

    UITexture_Left.gameObject:SetActive(false)
    UITexture_Right.gameObject:SetActive(false)
    UISprite_NPChead.gameObject:SetActive(false)

    EventHelper.SetClick(fields.UIButton_Next, function()
        -- -- printyellow("UIButton_Next click")
        NextBtnOnClick()
    end )

    EventHelper.SetClick(fields.UILabel_Next, function()
        -- -- printyellow("UILabel_Next click")
        NextBtnOnClick()
    end )

    EventHelper.SetClick(fields.UISprite_Click, function()
        -- -- printyellow("UISprite_Click click")
        NextBtnOnClick()
    end )

end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
