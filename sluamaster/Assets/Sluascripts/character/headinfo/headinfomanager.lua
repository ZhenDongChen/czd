local defineenum    = require"defineenum"
local objectpool    = require"common.objectpool"
local TitleInfo     = require"ui.title.info.titleinfo"
local SettingManager = require("character.settingmanager")
local GraphicSettingMgr = require"ui.setting.graphicsettingmanager"
local NpcStatusType = defineenum.NpcStatusType
local hideDistance  = 0.5*SCALE_SPEED --30
local maxViewAngle  = 60
local RedColor      = Color(210/255,32/255,2/255,1)
local GreenColor    = Color(152/255,204/255,84/255,1)
local HeadInfo      = Class:new()
--local cameraPos
--local cameraForward

function HeadInfo:__new()

end

function HeadInfo:SetActive(comp,b)
    if comp==nil then
        return;
    end
    --comp.gameObject.transform.localScale = b and Vector3.one or Vector3.zero
	
    if comp then
        comp.gameObject:SetActive(b)
    end
end

function HeadInfo:TurnHPProgressColor(b)
    self.m_SpriteForeground.color = b and GreenColor or RedColor
end

function HeadInfo:ShowName(name)
    if self.m_Name then
        local strName = name or self.m_Character:GetName()
        self.m_Name.text = TitleInfo.GetTextColor(self.m_Character)..strName.."[-]"
    end
end

function HeadInfo:HideHeadInfo()
    -- self.m_IsHide = true
    self:Hide()
    self.m_HeadInfoControl.enabled = false
end

function HeadInfo:ShowHeadInfo()
    if self.m_Character:IsPlayer() then
        self:Show()
    else
        self.m_IsHide = false
    end
    self.m_HeadInfoControl.enabled = true

end

function HeadInfo:Hide()
    if not self.m_Hiding then
        self:SetActive(self.m_HeadInfoItem,false)
        self.m_Hiding = true
    end
end

function HeadInfo:Remove()
    self.m_HeadInfoItem.gameObject.transform.localPosition = Vector3.one * 1e8

    if self.m_HeadInfoControl then
        self.m_HeadInfoControl:Reset()
    end
end

function HeadInfo:Show()
    if self.m_Hiding then
        self:SetActive(self.m_HeadInfoItem,true)
        self.m_Hiding = false
    end
end

function HeadInfo:HeadActive(b)
    if self.m_HeadInfoItem then
        self.m_HeadInfoItem.gameObject:SetActive(b)
    end
end

function HeadInfo:AddItem(item)
    self.m_HeadInfoItem = item
    self:Remove()
    if item then
        --if not self.m_HeadInfoItem.gameObject.activeSelf then
        --    self.m_HeadInfoItem.gameObject:SetActive(true)
        --end
        self.m_HeadInfoControl      = item.gameObject:AddComponent("HeadInfoControl")
        if self.m_HeadInfoControl.isActiveAndEnabled == false then
            self.m_HeadInfoControl:Invoke("Awake",0)
        end
        --basic
        self.m_Name                 = item.Controls["UILabel_Name"]
        self.m_HpProgress           = item.Controls["UIProgressBar_BackGround"]
        self.m_SpriteForeground     = item.Controls["UISprite_Foreground"]
        -- self.m_UITalkBackground     = item.Controls["UISprite_SpeakBackground"]
        --ext
        self.m_TextureAwake         = item.Controls["UITexture_PetAwake"]
        -- self.m_UISprite_TargetArrow = item.Controls["UISprite_TargetArrow"]
        self.m_UITitleName          = item.Controls["UILabel_Title"]
        self.m_UITitleTexture       = item.Controls["UITexture_Title"]
        -- self.m_UITitleSprite        = item.Controls["UISprite_Title"]

        -- self.m_UITalkContent        = item.Controls["UILabel_Content"]
        self.m_UIFamilyName         = item.Controls["UILabel_FamilyName"]
        self.m_UIFamilyWar            = item.Controls["UISprite_FamilyWar"]
        -- self.m_UINPCInfoQuestion    = item.Controls["UISprite_QuestionMark"]
        -- self.m_UINPCInfoExclamation = item.Controls["UISprite_Exclamation"]
    end
end

function HeadInfo:Reset(character)
    self.m_Character                    = character
    -- self.m_IsHide                       = false
    self.m_HeadInfoControl.enabled      = true
    if self.m_UITitleName then
        self.m_UITitleName.text             = ""
    end
    -- self.m_UITitleSprite.spriteName     = ""
    self.m_UITitleCurrentId             = nil
    self.m_ShowTalkTime                 = 0.0
    self.m_TargetPos                    = nil
    self.m_Hiding                       = false
    self.m_HeadInfoItemTransform        = self.m_HeadInfoItem.gameObject.transform
    -- 模型大小缩放值
    self.m_CurScale                     = 1;

    if self.m_UITitleTexture then
        self.m_UITitleTexture:SetIconTexture("")
    end
    if self.m_TextureAwake then
        self.m_TextureAwake:SetIconTexture("")
    end
    if self.m_UIFamilyWar then
        self:SetActive(self.m_UIFamilyWar,false)
    end
	self:Hide()
    -- self:SetActive(self.m_UITalkBackground,false)
    -- self:SetActive(self.m_UITalkContent,false)
    -- self:SetActive(self.m_UINPCInfoQuestion,false)
    -- self:SetActive(self.m_UINPCInfoExclamation,false)
    -- self:SetActive(self.m_UISprite_TargetArrow,false)
end

function HeadInfo:OnTeamChanged()
    local b = self.m_Character:HaveRelationshipWithRole()
    self:TurnHPProgressColor(b)
    -- if b then
    --     self:ShowHpProgress(true)
    -- end
end

function HeadInfo:GetNameHeight()
    local nameHeight = 2.1
    if self.m_Character:IsPlayer() and not self.m_Character:IsSimplified() then
        if self.m_Character:IsRiding() then
            local ret = 0
            ret = self.m_Character.m_Mount.m_PropData.ridingheight
            ret = ret - 0.4 * self.m_Character.m_Height
            nameHeight = ret
        else
            nameHeight = self.m_Character.m_Height
        end
    else
        nameHeight = self.m_Character.m_Height
    end
    if self.m_Character:IsPet() then
        local PetManager = require"character.pet.petmanager"
        local NameTexutre = PetManager.GetQualityColorTexture(self.m_Character)
        if NameTexutre ~= nil and NameTexutre ~= "" then
            --boss_youmingxuekun 冰晶龙鱼m_Height=4.5，伙伴中目前最高的，调整后太高，按之前*0.7
            return (nameHeight >3.0) and nameHeight*0.7 or nameHeight
        end
    end
    return nameHeight*0.7
end

function HeadInfo:GetNameOffset()
    return self.m_HeadInfoOffset
end

function HeadInfo:OnRideStateChange()
    self.m_HeadInfoControl:UpdateHeight(self:GetNameHeight()*self.m_CurScale, self:GetNameOffset()*self.m_CurScale)
end

function HeadInfo:Init()
    if self.m_Character:IsMonster() or self.m_Character:IsNpc() then
        self.m_HeadInfoOffset = self.m_Character.m_ModelData.namehighshift or 0
    else
        self.m_HeadInfoOffset = 0
    end
    self:OnTeamChanged()
	if self.m_Character:IsMonster() == false then
		self:Show()
		self:SetActive(self.m_HpProgress,false)
	else
        local SettingSystem = SettingManager.GetSettingSystem()
        if SettingSystem[GraphicSettingMgr.NameHPSettingName] == true then
            self:Show()
        else
            self:Hide()
        end
	end
    self:ShowName()
    self.m_CurNPCStatus = NpcStatusType.None
    if self.m_Character and self.m_Character.m_Object then
        self:OnAttributeChange()
    end
    if self.m_UIFamilyName then
        self:SetActive(self.m_UIFamilyWar, false);
        self.m_UIFamilyName.text = "";
    end

	--��ʱ���μ���������
--[[    if self.m_UIFamilyName then
        if self.m_Character:IsNpc() then
            self.m_UIFamilyName.text = self.m_Character.m_Data.title
        else
            self:SetActive(self.m_UIFamilyWar, (self.m_Character:IsPlayer() and self.m_Character:IsInWarWithRoleFamily()))
            if not (self.m_Character:IsPlayer() and self.m_Character:IsInWarWithRoleFamily()) then
                self.m_UIFamilyName.text = "[15dcc8]"..(self.m_Character.m_FamilyName or "") .. '[-]'
            else
                self.m_UIFamilyName.text = "[FF4A4A]"..(self.m_Character.m_FamilyName or "") .. '[-]'
            end
        end
    end--]]
    if not IsNull(self.m_Character.m_Object) and not IsNull(self.m_HeadInfoControl) then
        self.m_HeadInfoControl:Init(self.m_Character.m_Object.transform, self:GetNameHeight()*self.m_CurScale, self:GetNameOffset()*self.m_CurScale);
    end
end

function HeadInfo:Release()
    if self.m_HeadInfoItem then
        self.m_HeadInfoItem.Parent:DelListItem(self.m_HeadInfoItem)
        self.m_HeadInfoItem = nil
        self.m_HeadInfoControl = nil
    end
end

--function HeadInfo:UpdateItem()
--    -- print("a")
--    if self.m_Character:IsPathFlying() then return end
--    -- print("b")
--    if self.m_IsHide then return end
--    -- print("c")
--    if self.m_HeadInfoItem and self.m_HeadInfoItem.gameObject.activeSelf then
--        local targetPos = self.m_Character:GetPos()
--        targetPos.y = targetPos.y + self.m_Character.m_Height+self.m_HeadInfoOffset
--        local direction = targetPos - cameraPos
--        local distance  = direction.magnitude
--        -- status.BeginSample("aaaaa")
--        if distance>hideDistance then--or
--            -- Vector3.Angle(direction,cameraForward)>maxViewAngle
--            self:Hide()
--        else
--            self:Show()
--            local srcPos
--            local uiPos
--            -- status.BeginSample("position_Transform")
--            -- srcPos    = Camera.main:WorldToScreenPoint(targetPos)
--            -- uiPos     = UICamera.currentCamera:ScreenToWorldPoint(srcPos)
--            -- -- local trans = UICamera.currentCamera.transform
--            -- -- local uiPos = Vector3(scePos.x*trans.localScale.x,scePos.y*trans.localScale.y,5 )
--            -- status.EndSample()
--            -- status.BeginSample("c# transform")
--            -- uiPos     = LuaHelper.PositionTranmition(targetPos)
--            -- -- local trans = UICamera.currentCamera.transform
--            -- -- local uiPos = Vector3(scePos.x*trans.localScale.x,scePos.y*trans.localScale.y,5 )
--            -- status.EndSample()
--            distCompensation = distance / hideDistance + 1
--            distCompensation = distCompensation ^ 2.7
--            distCompensation = distCompensation * 2
--            distCompensation = distCompensation > 12 and 12 or distCompensation
--            self.m_HeadInfoItemTransform.position = targetPos
--            self.m_HeadInfoItemTransform.rotation = cameraTransform.rotation
--            self.m_HeadInfoItemTransform.localScale = Vector3.one * distCompensation
--            -- self.m_HeadInfoItemTransform.position = Vector3(uiPos.x,uiPos.y,5)
--        end
--        -- status.EndSample()
--    end
--end

-- function HeadInfo:UpdateTalk()
--     if self.m_UITalkBackground
--     and self.m_ShowTalkTime>0
--     and Time.time - self.m_ShowTalkTime >= 4 then
--         self.m_ShowTalkTime = 0
--         self:SetActive(self.m_UITalkBackground,false)
--         -- self:SetActive(self.m_UITalkContent,false)
--     end
-- end

function HeadInfo:Update()
    -- status.BeginSample("UpdateItem")
    --self:UpdateItem()
    -- status.EndSample()
    -- self:UpdateTalk()

end

function HeadInfo:OnAttributeChange()

    -- scale
    local newScale = self.m_Character.m_Attributes[cfg.fight.AttrId.MODEL_SCALE]
    if newScale~=nil and newScale~=self.m_CurScale then
        --print("OnAttribute Scale:"..self.m_Character:GetName().." self.m_CurScale "..self.m_CurScale.." newScale"..newScale)
        self.m_CurScale = 1+newScale
        self.m_HeadInfoControl:UpdateHeight(self:GetNameHeight()*self.m_CurScale, self:GetNameOffset()*self.m_CurScale)
    end

    -- hpprogress
    if not self.m_HpProgress
    or self.m_Character:IsRole()
    or self.m_Character:IsMount()
    or self.m_Character:IsDropItem()
    or self.m_Character:IsNpc() then
        return
    end
    if self.m_Character.m_Attributes[cfg.fight.AttrId.HP_VALUE]
    and self.m_Character.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE] then
        -- self.m_HpProgress.value = self.m_Character.m_Attributes[cfg.fight.AttrId.HP_VALUE] / self.m_Character.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
        local v = self.m_Character.m_Attributes[cfg.fight.AttrId.HP_VALUE] / self.m_Character.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
        v = v > 0.002 and v or 0.002
        self.m_HpProgress.value = v
    end
end

function HeadInfo:OnFamilyWarChange()
    if self.m_Character:IsPlayer() then
        self:SetActive(self.m_UIFamilyWar, self.m_Character:IsInWarWithRoleFamily())
        if self.m_Character:IsInWarWithRoleFamily() then
            self.m_UIFamilyName.text = "[FF4A4A]"..(self.m_Character.m_FamilyName or "") .. '[-]'
        else
            self.m_UIFamilyName.text = "[15dcc8]"..(self.m_Character.m_FamilyName or "") .. '[-]'
        end
    end
end

--
-- function HeadInfo:SetTalkContent(content)
--     if self.m_UITalkBackground and self.m_UITalkContent then
--         if content and string.len(content)>0 then
--             self:SetActive(self.m_UITalkBackground,true)
--             self:SetActive(self.m_UITalkContent,true)
--             self.m_UITalkContent.text = content
--             self.m_ShowTalkTime = Time.time
--         end
--     end
-- end

function HeadInfo:OnChangeFamily()
    if self.m_UIFamilyName then
        self.m_UIFamilyName.text = "[15dcc8]"..(self.m_Character.m_FamilyName or "") .. '[-]'
    end
end

function HeadInfo:NpcUpdate()
	--��ʱ����npc��״̬
--[[--]]
    local taskmanager = require "taskmanager"
    local npcstatus = taskmanager.GetNpcStatus(self.m_Character.m_CsvId)
    if self.m_CurNPCStatus ~= npcstatus then
        self.m_CurNPCStatus = npcstatus
        if npcstatus == NpcStatusType.CanAcceptTask then
            -- printyellow("CanAcceptTask")
            -- self:SetActive(self.m_UINPCInfoQuestion,true)
            -- self:SetActive(self.m_UINPCInfoExclamation,false)
            self.m_Character:QuestionMark(true)
            self.m_Character:ExclamationMark(false)
        elseif npcstatus == NpcStatusType.CanCommitTask then
            -- printyellow("CanCommitTask")
            -- self:SetActive(self.m_UINPCInfoQuestion,false)
            -- self:SetActive(self.m_UINPCInfoExclamation,true)
            self.m_Character:QuestionMark(false)
            self.m_Character:ExclamationMark(true)
        else
            -- printyellow("no mask")
            -- self:SetActive(self.m_UINPCInfoQuestion,false)
            -- self:SetActive(self.m_UINPCInfoExclamation,false)
            self.m_Character:QuestionMark(false)
            self.m_Character:ExclamationMark(false)
        end
    end
end

function HeadInfo:PlayerUpdate()
    local char = self.m_Character
    if char.m_Title then
        if self.m_UITitleCurrentId
        or self.m_UITitleCurrentId ~= char.m_Title.m_Id then
            char.m_Title:SetTitleShow(self.m_UITitleTexture,nil,self.m_UITitleName)--uiTexture, uiSprite, uiLabel)
            self.m_UITitleCurrentId = char.m_Title.m_Id
        end
    end
end

function HeadInfo:OnChangeTitle()
    local char = self.m_Character
    if char.m_Title
    and self.m_UITitleTexture
    -- and self.m_UITitleSprite
    and self.m_UITitleName then
        char.m_Title:SetTitleShow(self.m_UITitleTexture,nil,self.m_UITitleName)
        self.m_UITitleCurrentId = char.m_Title.m_Id
    else
        if self.m_UITitleTexture then
            self.m_UITitleTexture:SetIconTexture("")
        end
        if self.m_UITitleName then
            self.m_UITitleName.text = ""
        end
    end
end
--
-- function HeadInfo:SetNpcTitleName(name)
--     if self.m_UIFamilyName then
--         printyellow("name")
--         self.m_UIFamilyName.text = name or ""
--     end
-- end

function HeadInfo:LateUpdate()
    if not self.m_Character
    or not self.m_HeadInfoItem then
        return
    end
    if not self.m_IsHide then
        if self.m_Character:IsNpc() then
            self:NpcUpdate()
        elseif self.m_Character:IsPlayer() then
            self:PlayerUpdate()
        end
    end
end

function HeadInfo:ShowHpProgress(b)
    if self.m_Character:IsRole() then
        return
    end
	
	if self.m_Character:IsMonster() == false then
		if self.m_Character.m_Object and self.m_HpProgress then
			self:SetActive(self.m_HpProgress,b)
		end
	else
		if b then
			self:Show()
		else
			self:Hide()			
		end
	end
	
    --if self.m_Character.m_Object and self.m_HpProgress then
    --    self:SetActive(self.m_HpProgress,b)
    --end
end
--
-- function HeadInfo:Hide()
--     if self.m_HeadInfoItem then
--         self:SetActive(self.m_HeadInfoItem,false)
--     end
-- end
--
-- function HeadInfo:Show()
--     if self.m_HeadInfoItem then
--         self:SetActive(self.m_HeadInfoItem,true)
--     end
-- end

-- function HeadInfo:ShowArrow()
--     if self.m_UISprite_TargetArrow then
--         self:SetActive(self.m_UISprite_TargetArrow,false)
--     end
-- end

function HeadInfo:SetAwakeTexture(name)
    if self.m_TextureAwake then
        self.m_TextureAwake:SetIconTexture(name)
    end
end

function HeadInfo:GetHpBar()
    return self.m_HeadInfoItem and self.m_HeadInfoItem.gameObject
end

local HeadInfoManager = Class:new()

function HeadInfoManager:__new(uilist)
    self.m_UIList       = uilist
    self.m_HeadInfoMap  = {}
    self.m_NewHeadInfos = {}
    self:Init()
end

function HeadInfoManager:Init()
    self.m_HeadInfoPool = objectpool:new(HeadInfo,50)
end

function HeadInfoManager:Add(character,isShow)
	print("HeadInfoManager:Add")
    if character then
        local obj = self.m_HeadInfoPool:GetObject()
        if IsNull(obj.m_HeadInfoItem) then
            local item = self.m_UIList:AddListItem()
            obj:AddItem(item)
        end
        obj.m_TargetPos = nil
        obj:Reset(character)
        -- table.insert(self.m_NewHeadInfos,{obj=obj})
        obj:Init()
        self.m_HeadInfoMap[character.m_Id] = obj
        --obj:HeadActive(isShow)
        return obj
    end
end

function HeadInfoManager:Remove(characterid)
    local obj = self.m_HeadInfoMap[characterid]
    self.m_HeadInfoMap[characterid] = nil
    if obj then
        obj:Remove()

        if not self.m_HeadInfoPool:PushObject(obj) then
            obj:Release()
        end
    end
end

-- function HeadInfoManager:LateUpdate()
--     local CharacterManager = require"character.charactermanager"
--     for id,headInfo in pairs(self.m_HeadInfoMap) do
--         local character = CharacterManager.GetCharacter(id)
--         if not character then
--             self:Remove(id)
--         else
--             headInfo:LateUpdate()
--         end
--     end
-- end

function HeadInfoManager:Update()
    -- for _,v in ipairs(self.m_NewHeadInfos) do
    --     if not v.obj.m_Character.m_IsDestroy then
    --         v.obj:Init()
    --     end
    -- end
    -- self.m_NewHeadInfos = {}
    local CharacterManager = require"character.charactermanager"
--    cameraPos = cameraTransform.position
--    cameraForward = cameraTransform.forward
    for id,headInfo in pairs(self.m_HeadInfoMap) do
        -- local character = CharacterManager.GetCharacter(id)
        -- if not character then
        --     self:Remove(id)
        -- else
        --     if character:IsRole() then
        --         -- printyellow("update role headinfo")
        --     end
            headInfo:Update()
            headInfo:LateUpdate()
        -- end
    end
end

return HeadInfoManager
