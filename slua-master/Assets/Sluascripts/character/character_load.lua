local Define            = require "define"
local Character         = utils.get_or_create("character").Character
local ConfigManager     = require"cfg.configmanager"
local ShadowObjectManager = require"character.footinfo.shadowobjmanager"
local ResourceManager   = require("resource.resourcemanager")
function Character:GetBundlePath(path)
    return string.format("character/c_%s.bundle",path)
end

function Character:loadmodel(modeldata,charactermodeldata,isShowHeadInfo,playbornaction)
	
    self.m_IsLoadingModel = true
    self.m_CharacterModelData = charactermodeldata or self.m_CharacterModelData
    self.m_ModelData = modeldata or self.m_CharacterModelData
    self.m_bNeedLoadAvatar = false
	
	if not self.m_ModelData then		
		Util.LogError(string.format("Character:loadmodel error.type:%s id:%s m_CsvId:%s.",tostring(self.m_Type),tostring(self.m_Id),tostring(self.m_CsvId)))
	end
    self.m_bHasAvatar = not self.m_ModelData.avatarid or self.m_ModelData.avatarid ~= ""

    if self.m_ModelPath ~= self.m_ModelData.modelpath then
        self.m_ModelPath = self.m_ModelData.modelpath
        self:ReleaseModel()
        self.m_bNeedLoadAvatar = true
        self.m_AvatarId  = self.m_ModelData.avatarid
		--printyellow(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Character Load Model failed",self.m_ModelData.modelname)
        self:load(self.m_ModelData.modelname,isShowHeadInfo,playbornaction)
    elseif self.m_AvatarId ~= self.m_ModelData.avatarid then
        self.m_AvatarId = self.m_ModelData.avatarid
        self.m_Avatar:LoadAvatar(self.m_ModelData)
    else
        self.m_IsLoadingModel = false
        self.m_bNeedLoadModel = false
        self:OnLoaded(self.m_Object)
    end
end


function Character:load(modelname,isShowHeadInfo,playbornaction)
    self.m_AttachBones = {}
    ResourceManager.LoadObject(modelname, {notLoadAvatar = true, animSelectType = self.m_AnimSelectType}, function(asset_obj)
		--logError(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Character Load Model failed1111111: " .. tostring(modelname))
        if asset_obj ~= nil then
            if self.m_IsDestroy == false then
                self.m_Object = asset_obj
                self:OnCharacterLoaded(modelname,asset_obj,isShowHeadInfo,playbornaction)
            else
                ResourceManager.Destroy(asset_obj)
            end
        else
            self.m_Object = nil
            logError("Character Load Model failed: " .. tostring(modelname))
        end
    end)
end

--
function Character:ReName()
    if self.m_Object then
        if self.m_ObjectSetName ~= nil then
            self.m_Object.name = self.m_ObjectSetName
        elseif self:IsMonster() or self:IsPlayer() then
            self.m_Object.name = self.m_ModelData.modelpath .. tostring(self.m_Id)
        end
    end
end


function Character:ChangeAlpha(alpha)
	if self.m_Alpha ~= alpha then
		self.m_Alpha = alpha;
		self.m_Avatar:ChangeAlpha(alpha);
		
		if self.m_MountState then
		    if self.m_Player then
				self.m_Player:ChangeAlpha(alpha)			  
			end
		end
	end
	
end
	

function Character:OnCharacterLoaded(modelpath,asset_obj,isShowHeadInfo,playbornaction)

    if self.m_Object then
        SetDontDestroyOnLoad(self.m_Object)
        local managerObject = CharacterManager.GetCharacterManagerObject() --����ģ�͵ĸ��ڵ㣨characters��
        self.m_Object.transform:SetParent(managerObject.transform)

        if self.m_Rotation ~= Vector3.zero then
            self.m_Object.transform.localRotation = self.m_Rotation
        end
		local scale = self.m_Attributes[cfg.fight.AttrId.MODEL_SCALE] or 0
        
		self:SetScale(scale +1 )

    end

    self:ReName()
    local collider = self.m_Object.transform:GetChild(0):GetComponent("CapsuleCollider")
    if collider then
        if collider.direction == 1 then
            self.m_Height = collider.height
        elseif collider.direction == 2 then
            self.m_Height = collider.radius*3
        end
    else

        self.m_Height = 2.1
    end
   
	--��ʼ������������
	self.AnimationMgr:Init(self)

    self:RefreshAvatarObject()

    if self.m_bNeedLoadAvatar then
        self.m_Avatar:LoadAvatar(self.m_ModelData)
    end
    
    if playbornaction and self.m_IsBorn then
        self:PlayFreeAction("born")
        self.m_IsBorn = true
    else
        self.m_IsBorn = false
    end
    if isShowHeadInfo then
        local dlgHead = require"ui.dlgmonster_hp"
        local CharacterManager = require"character.charactermanager"
		
        self.m_HeadInfo = dlgHead.Add(self,CharacterManager.GetHeadInfoActivity() or self:IsRole() or self:IsNpc())
    end
    self.WorkMgr:ResumeWork()

	
    if not self.m_bHasAvatar then

        self:OnLoaded(self.m_Object)
    end
end

function Character:OnAvatarLoaded()
    if self.m_bHasAvatar then

        self:OnLoaded(self.m_Object)
    end
end

function Character:RegisterOnLoaded(onload)
    self.m_OnLoaded = onload
end

function Character:CriticalLoadModel(data)
	--print("CriticalLoadModel")
    if data then
        if self.m_IsLoadingModel then
            self.m_LoadModelData = data
            self.m_bNeedLoadModel = true

        else

            self:loadmodel(data[1],data[2],data[3],data[4])
            return true
        end
    else
        if not self.m_IsLoadingModel then
            if self.m_bNeedLoadModel then

                local ldata = self.m_LoadModelData
                self:loadmodel(ldata[1],ldata[2],ldata[3],ldata[4])
                self.m_bNeedLoadModel = false
                return true
            end
        end
    end

    return false
end

function Character:BecameVisiable()
    if self.WorkMgr then
        self.WorkMgr:ResumeWork()
    end
end

function Character:OnLoaded(go)

    self.m_IsLoadingModel = false
	
    if not self:CriticalLoadModel() then
		
        if self.m_OnLoaded then
            self.m_bCallOnLoaded = true
            self.m_OnLoaded(go)
            self.m_OnLoaded = nil
        end
    else
        return
    end
	
	self.m_Renderers = self.m_Object:GetComponentsInChildren(UnityEngine.SkinnedMeshRenderer,true)
    self.m_BodyObjectsColor = {}
    for i=1,self.m_Renderers.Length do
        local renderer = self.m_Renderers[i]
        local bodyObject = renderer.gameObject
        local component = bodyObject:GetComponent(Game.CharacterColor)
        if component then
            self.m_BodyObjectsColor[bodyObject.name] = component
			self.m_BodyObjectsColor[bodyObject.name].enabled = false
        else
             self.m_BodyObjectsColor[bodyObject.name] = bodyObject:AddComponent(Game.CharacterColor)
             self.m_BodyObjectsColor[bodyObject.name].enabled = false
        end
    end
	
    self:BindEffect()
    self.m_TransformControl =utils.SetDefaultComponent(self.m_Object,TransformControl)
    self.m_TransformControl:Init(self.m_Object.transform)
    self.m_TransformControl:RegistBecameVisiable(function() self:BecameVisiable() end)
    if not self:IsUIModel() then
        local objShadow = self.m_Object.transform:Find("shadow")
        if objShadow then return end
        local cfgShadow = ConfigManager.getConfigData("shadow",self.m_ModelPath)

        if cfgShadow and cfgShadow.bneedshadow then
            self.m_ShadowObject = ShadowObjectManager:GetObject()
            local size = math.min(math.min(cfgShadow.scale.x,cfgShadow.scale.y),cfgShadow.scale.z)
            self.m_ShadowObject.transform.localScale =
                Vector3.one*size
            self.m_ShadowObject.transform:SetParent(self.m_Object.transform)
            self.m_ShadowObject.transform.localPosition = Vector3.zero
            self.m_ShadowObject.transform.localRotation = Quaternion.Euler(Vector3(0,0,0))
        end
    end
end

function Character:IsLoadingModel()
    return self.m_IsLoadingModel
end