--[[ 20180616 屏蔽不用的,  用了headinfomanager.lua

local defineenum = require "defineenum"
local CharacterType = defineenum.CharacterType
local currentCamera = UnityEngine.Camera.main
local hideDistance      = 30
local maxViewAngle      = 90
local fadeDistance      = 25
local NpcStatusType = defineenum.NpcStatusType
local HeadObjectManager = require"character.headinfo.headobjmanager"
local RedColor      = Color(210/255,32/255,2/255,1)
local GreenColor    = Color(152/255,204/255,84/255,1)
local HeadInfo = Class:new()

function HeadInfo:SetActive(comp,b)
    -- printyellow(self.m_Character.m_Name,comp.gameObject.name,b)
    if comp.gameObject.name == "UISprite_TargetArrow" then
        comp.gameObject:SetActive(b)
        return
    end
    if b then
        local vec3
        if comp.gameObject.name == "headinfo_hp" then
            vec3 = Vector3(0,self.m_Height,0)
        else
            vec3 = self.m_Components[comp.gameObject.name].location
        end
        comp.gameObject.transform.localPosition = Vector3(vec3.x,vec3.y,vec3.z)
        -- printyellow(comp.gameObject.transform.localPosition)
    else
        comp.gameObject.transform.localPosition = Vector3.one*1e8
    end
end

function HeadInfo:__new(character)
    self.m_Character    = character
    self.m_HpBar        = nil
    self.m_HpProgress   = nil
    self.m_UIName       = nil
    self.m_TextureAwake = nil
    self.m_UITitleName  = nil
    self.m_UITitleTexture = nil
    self.m_UITitleSprite = nil
    self.m_UITalkBackground = nil
    self.m_UITalkContent = nil
    self.m_UITitleCurrentId = nil
    self.m_UISprite_TargetArrow = nil
    self.m_Components   = {}
end

function HeadInfo:LoadHeadObj(obj)

end

function HeadInfo:Load(characterObj, callback)
    local CharacterManager = require"character.charactermanager"
    self.m_HeadObject = HeadObjectManager.GetObject()
    self.m_HpBar = self.m_HeadObject:GetHeadObject()
    self.m_HpBar.name = "headinfo_hp"
    -- DontDestroyOnLoad(self.m_HpBar)
    self.m_HpProgress = self.m_HpBar.transform:Find("UIProgressBar_BackGround")
    self.m_SpriteForeground = self.m_HpProgress:Find("UISprite_Foreground"):GetComponent("UISprite")
    self.m_UIName = self.m_HpBar.transform:Find("UILabel_Name"):GetComponent("UILabel")
    self.m_TextureAwake = self.m_HpBar.transform:Find("UITexture_PetAwake"):GetComponent("UITexture")
    self.m_UISprite_TargetArrow = self.m_HpBar.transform:Find("UISprite_TargetArrow"):GetComponent("UISprite")
    self.m_TitleObj = self.m_HpBar.transform:Find("UIGroup_Title")
    self.m_UITitleName = self.m_TitleObj:Find("UILabel_Title"):GetComponent("UILabel")
    self.m_UITitleTexture = self.m_TitleObj:Find("UITexture_Title"):GetComponent("UITexture")
    self.m_UITitleSprite = self.m_TitleObj:Find("UISprite_Title"):GetComponent("UISprite")
    self.m_UITalkBackground = self.m_HpBar.transform:Find("UILabel_Content/UISprite_SpeakBackground"):GetComponent("UISprite")
    self.m_UITalkContent = self.m_HpBar.transform:Find("UILabel_Content"):GetComponent("UILabel")
    self.m_UIbar = self.m_HpProgress:GetComponent("UIProgressBar") -- self.m_HpProgress 
    self.m_UIFamilyName = self.m_HpBar.transform:Find("UILabel_FamilyName"):GetComponent("UILabel")
    self.m_UINPCInfoQuestion = self.m_HpBar.transform:Find("UISprite_QuestionMark"):GetComponent("UISprite")
    self.m_UINPCInfoExclamation = self.m_HpBar.transform:Find("UISprite_Exclamation"):GetComponent("UISprite")
    self:SetActive(self.m_UINPCInfoExclamation,false)
    self:SetActive(self.m_UISprite_TargetArrow,false)
    self.m_HpBar.transform.parent = characterObj.transform
    self.m_HpBar.transform.localScale = Vector3(0.7, 1, 1) *(1 / 180)
    self.m_HeadInfoOffset = (((self.m_Character:IsMonster()) and self.m_Character.m_ModelData.namehighshift) or 0)
    self.m_Height = self.m_HeadInfoOffset + self.m_Character.m_Height
    self.m_HpBar.transform.localPosition = Vector3(0,self.m_Height,0)
    self.m_IsHide = false
    self.m_Components = self.m_HeadObject:GetComponents()
    self.m_MaxDepth = self.m_HeadObject:GetMaxDepth()
    -- self.m_Components["headinfo_hp"] = {}
    -- self.m_Components[self.m_HpBar.name] = {}
    -- self.m_Components[self.m_HpBar.name].location = Vector3(0,self.m_Character.m_Height + offset,0)
    self:Reset()
end

function HeadInfo:Reset()
    self:TurnHPProgressColor(self.m_Character:HaveRelationshipWithRole())
    -- self.m_HpProgress.gameObject:SetActive(false)
    self:SetActive(self.m_HpProgress,false)
    self.m_TextureAwake:SetIconTexture("")
    self:ShowName()
    self.m_UITitleName.text = ""
    self.m_UITitleTexture:SetIconTexture("")
    self.m_UITitleSprite.spriteName = ""
    self.m_UITitleCurrentId = nil
    -- self.m_UITalkBackground.transform.gameObject:SetActive(false)
    -- self.m_UITalkContent.transform.gameObject:SetActive(false)
    self.m_ShowTalkTime = 0.0
    -- self.m_UINPCInfoQuestion.transform.gameObject:SetActive(false)
    -- self.m_UINPCInfoExclamation.transform.gameObject:SetActive(false)
    self:SetActive(self.m_UITalkBackground,false)
    self:SetActive(self.m_UITalkContent,false)
    self:SetActive(self.m_UINPCInfoQuestion,false)
    self:SetActive(self.m_UINPCInfoExclamation,false)
    self.m_CurNPCStatus = NpcStatusType.None
    -- self.m_UIbar.transform.gameObject:SetActive(false)
    self:SetActive(self.m_UIbar,false)
    -- self.m_HpBar.name = "headinfo" .. "_hp"
    -- self.m_HpBar:SetActive(true)
    -- self:SetActive(self.m_HpBar,true)
    self.m_Character:ChangeAttr({})
    if self.m_UISprite_TargetArrow then
        self:SetActive(self.m_UISprite_TargetArrow,false)
    end
    self.m_UIFamilyName.text = "[15dcc8]"..(self.m_Character.m_FamilyName or "")
end



function HeadInfo:SetDepth(depthOffset)


    if self.m_DepthOffset ~= depthOffset then
        for cname,component in pairs(self.m_Components) do
            if cname ~= self.m_HpBar.name then
                if component.widget.depth ~= depthOffset*self.m_MaxDepth + component.depth then
                    component.widget.depth = depthOffset*self.m_MaxDepth + component.depth
                end
            end
        end
    end
    self.m_DepthOffset = depthOffset
end

function HeadInfo:GetHpBar()
    return self.m_HpBar
end


function HeadInfo:Update()
    if self.m_UITalkBackground ~= nil and self.m_ShowTalkTime > 0.0 and Time.time - self.m_ShowTalkTime >= 4 then
        self.m_ShowTalkTime = 0
        -- self.m_UITalkBackground.transform.gameObject:SetActive(false)
        -- self.m_UITalkContent.transform.gameObject:SetActive(false)
        self:SetActive(self.m_UITalkBackground,false)
        self:SetActive(self.m_UITalkContent,false)
    end
end

function HeadInfo:OnAttributeChange()
    if self.m_UIbar == nil then
        return
    end
    if self.m_Character.m_Type == CharacterType.PlayerRole then
        return
    end
    if self.m_Character:IsMineral() then
        return
    end
    if self.m_Character:IsMount() then
        return
    end
    if self.m_Character:IsDropItem() then
        return
    end
    if self.m_Character:IsNpc() then
        return
    end
    if self.m_Character.m_Attributes[cfg.fight.AttrId.HP_VALUE] and self.m_Character.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE] then
        self.m_UIbar.value = self.m_Character.m_Attributes[cfg.fight.AttrId.HP_VALUE] / self.m_Character.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
    end
end


function HeadInfo:SetTalkContent(content)
    if self.m_UITalkBackground ~= nil and self.m_UITalkContent ~= nil then
        if content ~= nil and string.len(content) > 0 then
            -- self.m_UITalkBackground.transform.gameObject:SetActive(true)
            -- self.m_UITalkContent.transform.gameObject:SetActive(true)
            self:SetActive(self.m_UITalkBackground,true)
            self:SetActive(self.m_UITalkContent,true)
            self.m_UITalkContent.text = content
            self.m_ShowTalkTime = Time.time
        end
    end
end

function HeadInfo:OnChangeFamily()
    if self.m_UIFamilyName.text then
        self.m_UIFamilyName.text = "[15dcc8]"..(self.m_Character.m_FamilyName or "")
    end
end

function HeadInfo:CaculateTranform()


end

function HeadInfo:NpcUpdate2()
    local taskmanager = require "taskmanager"
    local npcstatus = taskmanager.GetNpcStatus(self.m_Character.m_CsvId)
    if self.m_CurNPCStatus ~= npcstatus then
        self.m_CurNPCStatus = npcstatus
        if npcstatus == NpcStatusType.CanAcceptTask then
            -- self.m_UINPCInfoQuestion.transform.gameObject:SetActive(true)
            -- self.m_UINPCInfoExclamation.transform.gameObject:SetActive(false)
            self:SetActive(self.m_UINPCInfoQuestion,true)
            self:SetActive(self.m_UINPCInfoExclamation,false)
        elseif npcstatus == NpcStatusType.CanCommitTask then
            -- self.m_UINPCInfoQuestion.transform.gameObject:SetActive(false)
            -- self.m_UINPCInfoExclamation.transform.gameObject:SetActive(true)
            self:SetActive(self.m_UINPCInfoQuestion,false)
            self:SetActive(self.m_UINPCInfoExclamation,true)
        else
            -- self.m_UINPCInfoQuestion.transform.gameObject:SetActive(false)
            -- self.m_UINPCInfoExclamation.transform.gameObject:SetActive(false)
            self:SetActive(self.m_UINPCInfoQuestion,false)
            self:SetActive(self.m_UINPCInfoExclamation,false)
        end
    end
end

function HeadInfo:PlayerUpdate2()
    local char = self.m_Character
    if char.m_Title then
        if self.m_UITitleCurrentId == nil or self.m_UITitleCurrentId ~= char.m_Title.m_Id then
            char.m_Title:SetTitleShow(self.m_UITitleTexture,self.m_UITitleSprite,self.m_UITitleName)--uiTexture, uiSprite, uiLabel)
            self.m_UITitleCurrentId = char.m_Title.m_Id
        end
    end
end

function HeadInfo:OnChangeTitle()
    local char = self.m_Character
    if char.m_Title ~= nil and self.m_UITitleTexture and self.m_UITitleSprite and self.m_UITitleName then
        char.m_Title:SetTitleShow(self.m_UITitleTexture,self.m_UITitleSprite,self.m_UITitleName)
        self.m_UITitleCurrentId = char.m_Title.m_Id
    else
        if self.m_UITitleTexture then
            self.m_UITitleTexture:SetIconTexture("")
        end
        if self.m_UITitleName then
       -- self.m_UITitleSprite =
            self.m_UITitleName.text = ""
        end
    end
end
function HeadInfo:SetNpcTitleName(name)
    if self.m_UIFamilyName then
        self.m_UIFamilyName.text = name or ""
    end
end

function HeadInfo:OnChangeFamily()
    if self.m_UIFamilyName then
        self.m_UIFamilyName.text = "[15dcc8]"..self.m_Character.m_FamilyName
    end
end


function HeadInfo:lateUpdate2()
    local char = self.m_Character
    if char.m_Object == nil or self.m_HpBar == nil then
        return
    end
    if not self.m_VectorToCamera then return end
    local cameraDistance = self.m_DistToCamera
    -- printyellow(string.format("name:%s,dist%s,angle:%s",self.m_Character.m_Name,cameraDistance,Vector3.Angle(currentCamera.transform.forward, self.m_VectorToCamera)))
    if cameraDistance > hideDistance or Vector3.Angle(currentCamera.transform.forward, self.m_VectorToCamera) > maxViewAngle then
        -- printyellow(self.m_Character.m_Name,"set hpbar false")
        -- if not self.m_IsHide then
            -- self.m_HpBar:SetActive(false)
            -- self:SetActive(self.m_HpBar,false)
            -- self.m_IsHide = true
        -- end
        -- printyellow("cameraDistance",cameraDistance)
        -- printyellow("hideDistance",hideDistance)
        --
        -- printyellow("Vector3.Angle(currentCamera.transform.forward, self.m_VectorToCamera)",Vector3.Angle(currentCamera.transform.forward, self.m_VectorToCamera))
        -- printyellow("maxViewAngle",maxViewAngle)

        -- self.m_HpBar:SetActive(false)
        -- printyellow("set hpbar false 1")
        -- self:SetActive(self.m_HpBar,false)

    else
        local distCompensation = cameraDistance / hideDistance + 1
        distCompensation = distCompensation ^ 2.7
        distCompensation = distCompensation > 3.5 and 3.5 or distCompensation

        self.m_HpBar.transform.rotation = currentCamera.transform.rotation
        local charTrans = self.m_Character.m_Object.transform
        local newScale = Vector3( 1/charTrans.lossyScale.x,1/charTrans.lossyScale.y,1/charTrans.lossyScale.z)
        self.m_HpBar.transform.localScale = newScale *(distCompensation) *(1 / 180)

        if self.m_Character.m_Type == CharacterType.Npc then
            self:NpcUpdate2()
        elseif self.m_Character.m_Type == CharacterType.Player or self.m_Character.m_Type == CharacterType.PlayerRole then
            self:PlayerUpdate2()
        end
        -- if self.m_IsHide then
            -- self.m_HpBar:SetActive(true)
            -- self:SetActive(true)
            -- self.m_IsHide = false
        -- end
        -- printyellow(self.m_Character.m_Name,"set hpbar true")
        -- self.m_HpBar:SetActive(true)
        -- self:SetActive(self.m_HpBar,true)
    end
end

function HeadInfo:ShowHpProgress(b)
    if self.m_Character:IsRole() then
        return
    end
    if self.m_Character.m_Object and self.m_HpProgress then
        -- self.m_HpProgress.gameObject:SetActive(b)
        -- printyellow(string.format("set %s %s",self.m_HpProgress.gameObject.name,tostring(b)))
        self:SetActive(self.m_HpProgress,b)
    end
end

function HeadInfo:Destroy()
    if self.m_HpBar then
        if not HeadObjectManager.PushObject(self.m_HeadObject) then
            self.m_HeadObject:Release()
        end
        self.m_HpBar = nil
    end
end

function HeadInfo:Hide()
    -- printyellow("head info hide")
    if self.m_HpBar ~= nil then
        -- printyellow("set hpbar false 2")
        -- self.m_HpBar:SetActive(false)
        -- self.m_UIName.gameObject:SetActive(false)
        -- self.m_UIFamilyName.gameObject:SetActive(false)
        -- self.m_TitleObj.gameObject:SetActive(false)
        --
        self:SetActive(self.m_HpBar,false)
        self:SetActive(self.m_UIName,false)
        self:SetActive(self.m_UIFamilyName,false)
        self:SetActive(self.m_TitleObj,false)
    end
end

function HeadInfo:Show()
    if self.m_HpBar ~= nil then
        -- printyellow("set hpbar true 2")
        -- self.m_HpBar:SetActive(true)
        -- self.m_UIName.gameObject:SetActive(true)
        -- self.m_UIFamilyName.gameObject:SetActive(true)
        -- self.m_TitleObj.gameObject:SetActive(true)
        self:SetActive(self.m_HpBar,true)
        self:SetActive(self.m_UIName,true)
        self:SetActive(self.m_UIFamilyName,true)
        self:SetActive(self.m_TitleObj,true)
    end
end

function HeadInfo:ShowName(name)
    if self.m_UIName then
        self.m_UIName.text = name or self.m_Character:GetName()
    end
end

function HeadInfo:ShowArrow()
    if self.m_UISprite_TargetArrow then
        --printyellow("================show arrow")
        -- self.m_UISprite_TargetArrow.gameObject:SetActive(false)
        -- printyellow("ShowArrow true")
        self:SetActive(self.m_UISprite_TargetArrow,true)
    end
end

function HeadInfo:HideArrow()
    if self.m_UISprite_TargetArrow then
        -- self.m_UISprite_TargetArrow.gameObject:SetActive(false)
        -- printyellow("ShowArrow false")
        --printyellow("-hide arrow")
        self:SetActive(self.m_UISprite_TargetArrow,false)
    end
end

function HeadInfo:TurnHPProgressColor(b) -- true green  false red
    self.m_SpriteForeground.color = b and GreenColor or RedColor
end

return HeadInfo
--]]
