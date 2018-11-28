local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require "uimanager"
local network = require "network"

local os = require 'cfg.structs'
local create_datastream = create_datastream
local charactermanager = require "character.charactermanager"
local configmanager = require "cfg.configmanager"
local taskmanager = require "taskmanager"
local PlayerRole = require "character.playerrole"
local Npc = require "character.npc"
local Player = require "character.player"

local defineenum = require "defineenum"
local NpcStatusType = defineenum.NpcStatusType
local TaskStatusType = defineenum.TaskStatusType
local TaskType = defineenum.TaskType

local EffectManager = require "effect.effectmanager"
local AudioManager = require"audiomanager"
local itemmanager = require "item.itemmanager"


local gameObject
local name

local fields

local UILabel_Content = nil
local UILabel_Name = nil
local UITexture_Left = nil
local UITexture_Right = nil
local UIButton_GetReward = nil
local UIButton_Close = nil
local UIButton_Next = nil
local UILabel_Next = nil
local UISprite_Click = nil
local UIList_Reward = nil
local UIList_Currency = nil
local UISprite_Background = nil

local audioSource = nil


local dialogIndex = 1

local LABEL_MOVESIZE = 50
local LABEL_DISTANCE = 5
local uiMoveSize = 0

local taskid = 0

local CurTalkDuration = -1;

local g_Character

local function OnModelLeftLoaded(obj)
    if not g_Character or not g_Character.m_Object then return end
    local playerTrans         = g_Character.m_Object.transform
    playerTrans.parent        = UITexture_Left.transform
    g_Character.m_Object:SetActive(true)
    g_Character:SetUIScale(300)
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
    playerTrans.localPosition = Vector3.zero
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
    local isFinished = false
	
    local task = taskmanager.GetTask(taskid)
    if task then
		
		CurTalkDuration = 0;
        local npcid = task.complete.npcid
        if task.basic.tasktype == TaskType.Family then
            npcid = taskmanager.GetFamilyNPC(task.id, false)
        end

        taskmanager.SetNpcStatus(npcid, { taskid = task.id, npcstatus = NpcStatusType.None })

        local len = table.getn(task.basic.success)
        if len > 0 and len >= dialogIndex then
            local dialoginfo = task.basic.success[dialogIndex]
            UILabel_Content.text = taskmanager.ReplaceWildcard(dialoginfo.dialogcontent)

            if dialoginfo.voiceid > 0 and audioSource then
                local audioid = taskmanager.GetDialogueAudioClipId(dialoginfo.voiceid)
                if audioid and audioid > 0 then -- 对话框音效暂时不加
                    AudioManager.PlaySoundBySelfAudioSource(audioid, audioSource)
                end
            end
			
			local npc = taskmanager.GetNpcData(npcid)
				
            if dialoginfo.role == cfg.task.EDialogueRoleType.NPC then
                -- NPC
                if npc then
                    UILabel_Name.text = npc.name
                end
				ShowLeftNpc(npcid, npcid);
				UITexture_Left.gameObject:SetActive(true)
				UITexture_Right.gameObject:SetActive(false)
                --UITexture_Left.color = Color(1.0, 1.0, 1.0, 1.0)
                --UITexture_Right.color = Color(0.35, 0.35, 0.35, 1.0)

                local rightTweenScale = UITexture_Right:GetComponent("TweenScale")
                rightTweenScale:ResetToBeginning()
                rightTweenScale.enabled = false

                local leftTweenScale = UITexture_Left:GetComponent("TweenScale")
                leftTweenScale.enabled = true
                leftTweenScale:PlayForward()
            else
                -- 主角
                UILabel_Name.text = PlayerRole:Instance().m_Name
				
				ShowRightPlayer();
				UITexture_Left.gameObject:SetActive(false)
				UITexture_Right.gameObject:SetActive(true)
				
                --UITexture_Left.color = Color(0.35, 0.35, 0.35, 1.0)
                --UITexture_Right.color = Color(1.0, 1.0, 1.0, 1.0)

                local leftTweenScale = UITexture_Left:GetComponent("TweenScale")
                leftTweenScale:ResetToBeginning()
                leftTweenScale.enabled = false

                local rightTweenScale = UITexture_Right:GetComponent("TweenScale")
                rightTweenScale.enabled = true
                rightTweenScale:PlayForward()
            end

            dialogIndex = dialogIndex + 1
            if dialogIndex > len and table.getn(task.reward.rewarditem.itemid) <= 0 then
                isFinished = true
            end
        elseif dialogIndex > len then
            isFinished = true
            if table.getn(task.reward.rewarditem.itemid) > 0  then
                UILabel_Name.text = ""
                UILabel_Content.text = ""
            end
        end
    end

    if isFinished then
        UIButton_Next.gameObject:SetActive(false)
        UIButton_GetReward.gameObject:SetActive(true)
    end
    return isFinished
end

local function AdjustDialogTextPosition(isMoveDown)
    local pos = UILabel_Name.gameObject.transform.localPosition
    if isMoveDown then
          UILabel_Name.gameObject.transform.localPosition = Vector3(pos.x,pos.y-LABEL_MOVESIZE,pos.z)
          uiMoveSize =  uiMoveSize - LABEL_MOVESIZE
    else
          UILabel_Name.gameObject.transform.localPosition = Vector3(pos.x,pos.y+LABEL_MOVESIZE,pos.z)
          uiMoveSize =  uiMoveSize + LABEL_MOVESIZE
    end

    pos = UILabel_Content.gameObject.transform.localPosition
    if isMoveDown then
        UILabel_Content.gameObject.transform.localPosition = Vector3(pos.x,pos.y-LABEL_MOVESIZE-LABEL_DISTANCE,pos.z)
    else
        UILabel_Content.gameObject.transform.localPosition = Vector3(pos.x,pos.y+LABEL_MOVESIZE+LABEL_DISTANCE,pos.z)
    end
end


local function destroy()
	CurTalkDuration = -1;
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
    if params == nil then
       -- printyellow("dlgtaskreward show params is nil")
       return
    end

    taskid = params.taskid

    UIButton_Next.gameObject:SetActive(true)
    UIButton_GetReward.gameObject:SetActive(false)
    UIList_Currency.gameObject:SetActive(false)
    UIList_Reward.gameObject:SetActive(false)
	
	CurTalkDuration = -1;
    dialogIndex = 1
		
    PlayTalk()
end


local function hide()
    -- print(name, "hide")
	CurTalkDuration = -1;
    if audioSource then
        audioSource:Stop()
    end

    local leftTweenScale = UITexture_Left:GetComponent("TweenScale")
    leftTweenScale.enabled = false

    local rightTweenScale = UITexture_Right:GetComponent("TweenScale")
    rightTweenScale.enabled = false

    UITexture_Left.gameObject:SetActive(false)
    UITexture_Right.gameObject:SetActive(false)
end

local function refresh(params)
    -- print(name, "refresh")
end

local function NextBtnOnClick()
    local ret = PlayTalk()
    print("dlgtaskreward PlayTalk():"..tostring(ret))
    if ret == true and UIList_Currency.gameObject.activeSelf == false  then
        local task = taskmanager.GetTask(taskid)
        if task and task.reward then
            if task.reward.exp >0 or task.reward.money > 0 or task.reward.ingot > 0 then
               UIList_Currency.gameObject:SetActive(true)
               UIList_Currency:Clear()
            end
            -- exp
            if task.reward.exp > 0 then
                local item = UIList_Currency:AddListItem()
                item:SetText("UILabel_ItemName", tostring(task.reward.exp))
            end
            -- 金币
            if task.reward.money > 0 then
                local item = UIList_Currency:AddListItem()
                item:SetText("UILabel_ItemName", tostring(task.reward.money))
                item.Controls["UISprite_ItemIcon"].spriteName = "ICON_I_Currency_01"
            end
            -- 元宝
            if task.reward.ingot > 0 then
                local item = UIList_Currency:AddListItem()
                item:SetText("UILabel_ItemName", tostring(task.reward.ingot))
                item.Controls["UISprite_ItemIcon"].spriteName = "ICON_I_Currency_02"
            end

            -- 奖励物品
            if task.reward.rewarditem and table.getn(task.reward.rewarditem.itemid) > 0 then
                if isAdjustedLabelPos == false then
                    isAdjustedLabelPos = true
                end

                UIList_Reward.gameObject:SetActive(true)
                UIList_Reward:Clear()

                local len = table.getn(task.reward.rewarditem.itemid)
                for i = 1, len do
                    local id = task.reward.rewarditem.itemid[i]
                    local count = task.reward.rewarditem.itemcount[i]
                    if id > 0 and count > 0 then
                        local itemdata = itemmanager.GetItemData(id)
                        if itemdata  and i <= 5 then -- 最多只显示5个
                            local listitem = UIList_Reward:AddListItem()
                            local labelAmount = listitem.Controls["UILabel_Amount"]
                            labelAmount.gameObject:SetActive(true)
                            labelAmount.text = tostring(count)

                            local labelEquipName = listitem.Controls["UILabel_EquipName"]
                            labelEquipName.gameObject:SetActive(true)
                            labelEquipName.text = itemdata.name

                            local itemtex = listitem.Controls["UITexture_Icon"]
                            if itemtex then
                               ---- printyellow(itemdata.icon)
                               itemtex:SetIconTexture(itemdata.icon)
                            end

                            local spriteQuality = listitem.Controls["UISprite_Quality"]
                            if spriteQuality then
                               -- spriteQuality.color = colorutil.GetQualityColor(itemdata.quality)
								spriteQuality.spriteName = colorutil.GetQualitySprite(itemdata.quality)
                            end

                            local iconUnknow = listitem.Controls["UISprite_Unknow"]
                            if len > 1 then
                                iconUnknow.gameObject:SetActive(true)
                            else
                                iconUnknow.gameObject:SetActive(false)
                            end
                        end
                    end
                end
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
			if UIButton_GetReward.gameObject:GetActive() == true then
				uimanager.hidedialog("dlgtaskreward")

				local task = taskmanager.GetTask(taskid)
				if task then
					taskmanager.CompleteTask(task.complete.npcid, task.id)
				end
				
			else
				NextBtnOnClick()
			end
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
    UILabel_Name = fields.UILabel_Name
    UITexture_Left = fields.UITexture_Left
    UITexture_Right = fields.UITexture_Right
    UIButton_Next = fields.UIButton_Next
    UILabel_Next = fields.UILabel_Next
    UIButton_GetReward = fields.UIButton_GetReward
    UISprite_Click = fields.UISprite_Click
    UIList_Reward = fields.UIList_Reward
    UIList_Currency = fields.UIList_Currency
    UISprite_Background = fields.UISprite_Background

    if UISprite_Background and UISprite_Background.gameObject then
        audioSource = UISprite_Background.gameObject:GetComponent(AudioSource)
        if not audioSource then
            audioSource = UISprite_Background.gameObject:AddComponent(AudioSource)
        end
    end

    UIButton_Next.gameObject:SetActive(true)
    UIButton_GetReward.gameObject:SetActive(false)

    UITexture_Left.gameObject:SetActive(false)
    UITexture_Right.gameObject:SetActive(false)

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

    EventHelper.SetClick(fields.UIButton_GetReward, function()
        -- printyellow("UIButton_GetReward click")
        uimanager.hidedialog("dlgtaskreward")

        local task = taskmanager.GetTask(taskid)
        if task then
            taskmanager.CompleteTask(task.complete.npcid, task.id)
        end

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
