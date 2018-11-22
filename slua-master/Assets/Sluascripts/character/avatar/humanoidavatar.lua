local defineenum = require "defineenum"
local CharacterType = defineenum.CharacterType
local Element = require"character.avatar.element"
local attachsfxinfo = require"character.avatar.attachsfxinfo"
local EquipInfo = Class:new()
local ConfigManager = require "cfg.configmanager"
local Define= require"define"
local Utils = require"common.utils"

local skeletonL = "weapon_L"
local skeletonR = "weapon_R"
local weaponAttachPoint1Name		= "jl_fx01"
local weaponAttachPoint2Name 		= "jl_fx03"
local weaponAttachPoint3Name 		= "jl_fx03"


local CharacterType = defineenum.CharacterType

function EquipInfo:__new()
    self.m_Tranform = nil
    self.m_ID       = nil
end

local HumanoidAvatar = Class:new()

HumanoidAvatar.EquipDetailType = enum{
    "ARMOUR=1", --盔甲
    "FASHION=2", --时装
    "DEFAULTWEAPON=3", --默认装备
    "DEFAULTARMOUR=4", -- 默认盔甲
    "WEAPON=5", --武器
    "CREATEWEAPON=6", --创建角色时候的武器
    "CREATEARMOUR=7", --创建角色时候的盔甲
    "COUNT=8",
}

HumanoidAvatar.EquipType = enum{
    "ARMOUR=1",
    "WEAPON=2",
    "COUNT=3",
}

HumanoidAvatar.WeaponHand = {
    [cfg.role.EProfessionType.XIANZU] = {left=true,right=true},
    [cfg.role.EProfessionType.RENZU] = {left=true,right=true},
    [cfg.role.EProfessionType.MOZU] = {left=true,right=true},
}

function HumanoidAvatar:__new(character)
    self.m_EquipInfo                = EquipInfo:new()
    self.m_DefaultAmourID           = 55000001
    self.m_lComponents              = {}            -- index by ObjectID
    self.m_lAttachments             = {}            -- index by ObjectID
    self.m_lEquipingInfo            = {}            -- L1 index by EquipType L2 index by EquipInfo.m_ID
	self.m_Materials				= {}			--模型材质
    self.m_AmourID                  = nil
    self.m_Profession               = nil
    self.m_bNeedGenerateModel       = nil
    self.m_bNeedAttachModel         = nil
    self.m_bNeedAttachEquipSfx      = nil
    self.m_bNeedAttachClothSfx      = nil
	self.m_bLWeaponAttachObjLoaded  = nil
	self.m_bRWeaponAttachObjLoaded  = nil
    self.m_EquipSfxInfos 	        = {} 		    --武器特效
    self.m_ClothSfxInfo 	        = nil 		    --武器特效
	self.m_ArmourSfxInfos 			= {} 		    --时装特效
    self.m_EquipManager             = {}
    self.m_AvatarCallBack           = nil
    self:SetPlayer(character)
    self:Init(character)
end

function HumanoidAvatar:AddEquipItem(type,item)
    local idx = item.m_ID
    if not self.m_lEquipingInfo[type].idx then
        self.m_lEquipingInfo[type][idx] = item
        self.m_lEquipingInfo[type].Count = self.m_lEquipingInfo[type].Count+1
		
		local smrArray = item.m_Transform.gameObject:GetComponentsInChildren(SkinnedMeshRenderer,true);
		local smr = smrArray[1]
		self.m_Materials[type][idx] = smr.materials[1]
    end
end

function HumanoidAvatar:RemoveEquipItem(type,idx)
    if self.m_lEquipingInfo[type][idx] then
        self.m_lEquipingInfo[type][idx] = nil
        self.m_lEquipingInfo[type].Count = self.m_lEquipingInfo[type].Count-1
		self.m_Materials[type][idx] = nil;
    end
end

function HumanoidAvatar:RegisterAvatarCallback(func)
    self.m_AvatarCallBack = func
end

function HumanoidAvatar:AvatarCallBack()
    if self.m_AvatarCallBack then
        self.m_AvatarCallBack()
    end
    self.m_AvatarCallBack = nil
end

function HumanoidAvatar:Init(Character)
    self.m_Character= Character
    self:Reset()
end

function HumanoidAvatar:Reset()
    self.m_AmourID              = 0
    self.m_bNeedAttachModel     = false
    self.m_bNeedGenerateModel   = false
    self.m_bNeedAttachEquipSfx      = false
    self.m_bNeedAttachClothSfx      = false
	self.m_bLWeaponAttachObjLoaded  = false
	self.m_bRWeaponAttachObjLoaded  = false
    for i,v in pairs(self.m_lComponents) do
        v:Release()
    end
    for i,v in pairs(self.m_lAttachments) do
        v:Release()
    end
    for i,v in pairs(self.m_EquipSfxInfos) do
        v:Release()
    end
	for i,v in pairs(self.m_ArmourSfxInfos) do
		v:Release()
	end
    self.m_lComponents          = {}
    self.m_lAttachments         = {}
    self.m_EquipSfxInfos        = {}
	self.m_ArmourSfxInfos       = {}
    self.m_Profession           = nil
    if self.m_ClothSfxInfo then
        self.m_ClothSfxInfo:Release()
        self.m_ClothSfxInfo = nil
    end
end

function HumanoidAvatar:SetPlayer(character)
    self.m_Character = character
    self.m_lEquipingInfo = {}
	self.m_Materials = {}
   -- self.m_ReplacePlayerShaderUI = UnityEngine.Shader.Find("SuperPop/Character/PlayerRole_NormalUI")
  --  self.m_ReplacePlayerShaderOther = UnityEngine.Shader.Find("Toony/DiffuseOnly")
    for type=HumanoidAvatar.EquipType.ARMOUR,HumanoidAvatar.EquipType.COUNT do
        self.m_lEquipingInfo[type]={}
        self.m_lEquipingInfo[type].Count=0
		self.m_Materials[type] = {}
    end
end


function HumanoidAvatar:IsLoading()
    return self:IsLoadingComponent() or self:IsLoadingAttachments()
end

function HumanoidAvatar:IsLoadingComponent()
    local isLoading = false
    for i,v in pairs(self.m_lComponents) do
        if v.m_bIsLoading then isLoading = true break end
    end
    return isLoading
end

function HumanoidAvatar:IsLoadingAttachments()
    local isLoading = false
    for i,v in pairs(self.m_lAttachments) do
        if v.m_bIsLoading then isLoading = true break end
    end
    return isLoading
end

function HumanoidAvatar:Release()
    self:Reset()
    self.m_lEquipingInfo    = {}
	self.m_Materials		= {}
    self.m_Character        = nil
end

function HumanoidAvatar:ResetModel()

end

function HumanoidAvatar:Update()
    if self.m_bNeedGenerateModel then
        self:Generate()
    end
    if self.m_bNeedAttachModel then
        self:Attach()
    end
    if self.m_bNeedAttachEquipSfx and self.m_bLWeaponAttachObjLoaded  and self.m_bRWeaponAttachObjLoaded  then

        self:AttachEquipSfx()
    end
    if self.m_bNeedAttachClothSfx then
        self:AttachClothSfx()
    end
end

--盔甲的类型
function HumanoidAvatar:HangArmourImpl(armourID)
    local modelPath = self:GetAvatarFile(armourID,self.m_DefaultAmourID)

    if modelPath and modelPath~="" then
        local ele = Element:new()
        ele.m_ObjectType = HumanoidAvatar.EquipType.ARMOUR
        ele.ObjectID = armourID
        ele:Add(modelPath)
        table.insert(self.m_lComponents,ele) --这个是把所有的盔甲都添加到self.m_lComponents里面
        self.m_bNeedGenerateModel = true
    end
end

function HumanoidAvatar:LoadAvatar(ModelData)
    if not ModelData.avatarid or ModelData.avatarid == "" then return end
    local avatarid = ModelData.avatarid
    self:UnEquip(HumanoidAvatar.EquipType.ARMOUR)
    local path = string.format("avatar/armour_%s.bundle",tostring(avatarid))
    if path then
        local ele = Element:new()
        ele.m_ObjectType = HumanoidAvatar.EquipType.ARMOUR
        ele.ObjectID = avatarid
        ele:Add(path)
        table.insert(self.m_lComponents,ele)
        self.m_bNeedGenerateModel = true
    end
end

function HumanoidAvatar:HangByModelname(modelname)
    local modelInfo = ConfigManager.getConfigData("model",modelname)
    local modelpath = modelInfo.modelpath
    local avatarid = modelInfo.avatarid
    if avatarid == "" or avatarid == nil then return end
    local path = string.format("avatar/armour_%s.bundle",avatarid)
    self:HangArmourImpl(path)
end

function HumanoidAvatar:HangAmourById(id)
    local dressInfo = ConfigManager.getConfigData("dress",id)
    self:HangByModelname(dressInfo.modelname)
end

function HumanoidAvatar:HangAmourByProfession(profession,gender)
    local roleInfo = ConfigManager.getConfigData("profession",profession)
    local modelname = gender == cfg.role.GenderType.MALE and roleInfo.modelname or roleInfo.modelname2
    self:HangByModelname(modelname)
end

--创建角色时候的装备
function HumanoidAvatar:HangCreateEquip(profession,gender)
    local roleInfo = ConfigManager.getConfigData("profession",profession)
    local equipInfo = ConfigManager.getConfigData("equip",roleInfo.createarmourid)
    local modelname = gender == cfg.role.GenderType.MALE and equipInfo.male or equipInfo.female
    self:HangByModelname(modelname)
end

--穿上盔甲装备通过ID来装备
function HumanoidAvatar:HangAmourByEquipId(profession,gender,equipid)
    local clothesInfo = ConfigManager.getConfigData("equip",equipid)
    local modelname = gender == cfg.role.GenderType.MALE and clothesInfo.male or clothesInfo.female
    if modelname then
        self:HangByModelname(modelname)
    else
        self:HangAmourByProfession(profession,gender)
    end
end


--替换全身的装备
function HumanoidAvatar:Dress(profession,gender,type,armourID)
    local path

    if type == HumanoidAvatar.EquipDetailType.FASHION then
        if armourID == self.m_EquipManager[HumanoidAvatar.EquipDetailType.FASHION] then
            return
        else
            if armourID==0 or armourID==nil then
                self:Dress(profession,gender,HumanoidAvatar.EquipDetailType.DEFAULTARMOUR)
            else
                self:UnEquip(HumanoidAvatar.EquipType.ARMOUR)
                self.m_EquipManager[HumanoidAvatar.EquipDetailType.FASHION] = armourID
                self:HangAmourById(armourID)
            end
        end
    elseif type == HumanoidAvatar.EquipDetailType.ARMOUR then
        if armourID == self.m_EquipManager[HumanoidAvatar.EquipDetailType.ARMOUR] then
            return
        else
            self.m_EquipManager[HumanoidAvatar.EquipDetailType.ARMOUR] = armourID
            if self.m_EquipManager[HumanoidAvatar.EquipDetailType.FASHION] then
                return
            else
                self:UnEquip(HumanoidAvatar.EquipType.ARMOUR)
                self:HangAmourByEquipId(profession,gender,armourID)
            end
        end
    elseif type == HumanoidAvatar.EquipDetailType.DEFAULTARMOUR then
        if self.m_EquipManager[HumanoidAvatar.EquipDetailType.FASHION] == nil and
        self.m_EquipManager[HumanoidAvatar.EquipDetailType.ARMOUR] == nil then
            self:UnEquip(HumanoidAvatar.EquipType.ARMOUR)
            self:HangAmourByProfession(profession,gender)
        else
            return
        end
    elseif type == HumanoidAvatar.EquipDetailType.CREATEARMOUR then
        if self.m_EquipManager[HumanoidAvatar.EquipDetailType.FASHION] == nil and
        self.m_EquipManager[HumanoidAvatar.EquipDetailType.ARMOUR] == nil then
            self:UnEquip(HumanoidAvatar.EquipType.ARMOUR)
            ---------------
            self:HangCreateEquip(profession,gender)
        else
            return
        end
    end
end

--加载手中的武器
function HumanoidAvatar:Arm(profession,type,weaponID)
    self.m_Profession = profession
    local weaponid
    self:UnEquip(HumanoidAvatar.EquipType.WEAPON)
    if type == HumanoidAvatar.EquipDetailType.WEAPON then
        if weaponID and weaponID ~=0 then
            weaponid = weaponID
        else
            local roleInfo = ConfigManager.getConfigData("profession",profession)
            weaponid = roleInfo.defaultweaponid
        end
    elseif type == HumanoidAvatar.EquipDetailType.DEFAULTWEAPON then
        local roleInfo = ConfigManager.getConfigData("profession",profession)
        weaponid = roleInfo.defaultweaponid
    elseif type == HumanoidAvatar.EquipDetailType.CREATEWEAPON then
        local roleInfo = ConfigManager.getConfigData("profession",profession)
        weaponid = roleInfo.createweaponid

    end
    self:HangWeaponImpl(weaponid,profession)
end

function GetWeaponPath(name)

    return string.format("weapon/w_%s.bundle",name)
end

function GetSfxPath(name)
    if name == nil then
        name = ""
    end
    return string.format("sfx/s_%s.bundle",name)
end

function HumanoidAvatar:HangWeaponImpl(weaponID,profession)
    local weaponInfo = ConfigManager.getConfigData("weapon",weaponID)
    if weaponInfo then
        if HumanoidAvatar.WeaponHand[profession].left then
            local modelFileLPath = GetWeaponPath(weaponInfo.lpath)
	
            if modelFileLPath and modelFileLPath~="" then
                local ele = Element:new()
                ele:Add(modelFileLPath) --这个是调用C#中Util.LoadAvatar这个函数来加载武器对象
                ele.m_ObjectType = HumanoidAvatar.EquipType.WEAPON
                ele.m_ObjectID = weaponID*2
                ele.m_bLeftHand = true
    			ele.m_ModelOriginalFile = weaponInfo.lpath
                table.insert(self.m_lAttachments,ele)--加载出来的武器对象存储到这个表当中
                self.m_bNeedAttachModel = true
            end
        end
        if HumanoidAvatar.WeaponHand[profession].right then
			
            local modelFileRPath = GetWeaponPath(weaponInfo.rpath)
		
            if modelFileRPath and modelFileRPath~="" then
                local ele = Element:new()
                ele:Add(modelFileRPath)
                ele.m_ObjectType = HumanoidAvatar.EquipType.WEAPON
                ele.m_ObjectID = weaponID*2+1
                ele.m_bLeftHand = false
    			ele.m_ModelOriginalFile = weaponInfo.rpath
                table.insert(self.m_lAttachments,ele)--加载出来的武器对象存储到这个表当中
                self.m_bNeedAttachModel = true
            end
        end
    end
end


--加载avatar文件
function HumanoidAvatar:GetAvatarFile(ArmourID,DefaultID)
    local modelID = 0
    if ArmourID and ArmourID~="" then modelID = ArmourID
    else modelID = DefaultID end --"avatar/{0}_{1}_{2}.bundle",
    local path = --"avatar/"--..tostring(modelID)
    string.format("avatar/armour_%s.bundle",ArmourID)
    return path
end

function HumanoidAvatar:GetEquipingInfoCount()
    local c = 0
    for _,v in pairs(self.m_lEquipingInfo) do
        c=c+1
    end
    return c
end

function HumanoidAvatar:Clear(type)
    for i,v in pairs(self.m_lEquipingInfo[type]) do
        if i~="Count" then
            self:RemoveEquipItem(type,v.m_ID)
        end
    end
end

--卸掉装备
function HumanoidAvatar:UnEquip(type)
    if self:GetEquipingInfoCount()>type and self.m_lEquipingInfo[type].Count>0 then
        if type == HumanoidAvatar.EquipType.WEAPON then
            if getn(self.m_EquipSfxInfos) ~= 0 then
                for i,v in pairs(self.m_EquipSfxInfos) do
                    v:Release()
                end
		        self.m_EquipSfxInfos = {}
            end
        end
        if type ~= HumanoidAvatar.EquipType.ARMOUR then
            if self.m_Character and self.m_Character.AnimationMgr then
            end
        else 
            if self.m_Character then
                self.m_Character:ReleaseBindEffect()
            end
        end
        for i,v in pairs(self.m_lEquipingInfo[type]) do
            if i=="Count" then
                --do nothing
            else
                if v and v.m_Transform then
                   GameObject.Destroy(v.m_Transform.gameObject)
                end
                   self:RemoveEquipItem(type,v.m_ID)
            end
        end
    end
    if self.m_lComponents then
        for i,v in pairs(self.m_lComponents) do
            if v and v.m_ObjectType  == type then

                v:Remove()
                self.m_lComponents[i]=nil
            end
        end
    end
    if self.m_lAttachments then
        for i,v in pairs(self.m_lAttachments) do
            if v and v.m_ObjectType==type then
                v:Remove()
                self.m_lAttachments[i]=nil
            end
        end
    end
end

--得到装备的数量
function HumanoidAvatar:GetEquipingInfoCount()
    local c = 0
    for _,v in pairs(self.m_lEquipingInfo) do
        c=c+1
    end
    return c
end

function HumanoidAvatar:Generate()
   if not self.m_Character or not self.m_Character.m_Object or self:IsLoadingComponent() then return end
   self.m_bNeedGenerateModel = false
   self.m_Character.m_Object:SetActive(false)
   ---  原来: local trans = self.m_Character.m_Object.transform:FindChild("Bip001")
   local trans = self.m_Character.m_Object.transform:GetChild(0):Find("Bip001")
   local bbb = nil
   if trans then
		bbb = trans.gameObject
   end
   if not bbb then 
        printyellow("HumanoidAvatar:Generate failed. Bip001 not found!")
		return 
	end
   local transforms = bbb:GetComponentsInChildren(Transform)
   local name_transform = {}
   for i=1,transforms.Length do
   local trans = transforms[i]
      name_transform[trans.name] = trans
   end


   if getn(self.m_ArmourSfxInfos) ~= 0 then
        for i,v in pairs(self.m_ArmourSfxInfos) do
            v:Release()
        end
		self.m_ArmourSfxInfos = {}
   end

   for i,v in pairs(self.m_lComponents) do
       local go = v.m_Object

       if not go then
           v:Release()
           self.m_lComponents[i]=nil
       else
           local smrArray = go:GetComponentsInChildren(SkinnedMeshRenderer,true)
           if not smrArray or smrArray.Length<1 then
               v:Release()
               self.m_lComponents[i]=nil
           else
               for i=1,smrArray.Length do
                   local smr = smrArray[i]
                   local bones = LuaHelper.CreateArrayInstance(Transform,smr.bones.Length)--Type.MakeArrayType(Transform,1)
                   local k=1
                   for i=1,smr.bones.Length do
                       local bone = smr.bones[i]
                       local bonename = bone.name
                       if name_transform[bonename] then 
                            bones[k]=name_transform[bonename]
                            k=k+1
                       end 
                   end                   
                ----todo:为什么这么改?
					--[[
                   for i=1,smr.materials.Length do
                       local mat = smr.materials[i]
                       if self.m_Character:IsUIPlayer() then
                           mat.shader = self.m_ReplacePlayerShaderUI
                       elseif self.m_Character.m_Type ~= CharacterType.PlayerRole then
                           mat.shader = self.m_ReplacePlayerShaderOther
                       end
                   end
                        ]]
                    
                   if Application.platform == UnityEngine.RuntimePlatform.WindowsEditor then  --HLS在编辑器下重新赋SHADER
                        local shaderName = ""
                        for i=1,smr.materials.Length do
                            shaderName = smr.materials[i].shader.name
                            smr.materials[i].shader = Shader.Find(shaderName)
                        end
                   end 
                  
                   local rootBoneName = smr.rootBone.name
                   if name_transform[rootBoneName] then 
                      smr.rootBone=name_transform[rootBoneName]
                   end 

                   local localPos = smr.gameObject.transform.localPosition
                   local localEulerAngles = smr.gameObject.transform.localEulerAngles
                   local localScale = smr.gameObject.transform.localScale

                   smr.bones=bones
                   smr.gameObject.transform:SetParent(self.m_Character.m_Object.transform:GetChild(0))
                   smr.gameObject.layer = self.m_Character.m_Object.layer
                   smr.gameObject.transform.localPosition = localPos
                   smr.gameObject.transform.localEulerAngles = localEulerAngles
                   smr.gameObject.transform.localScale = localScale
                   if self:GetEquipingInfoCount()> v.m_ObjectType then
                       local info = EquipInfo:new()
                       info.m_Transform = smr.gameObject.transform
                       info.m_ID = string.format("%s_%02d",v.ObjectID,i)
                       self:AddEquipItem(v.m_ObjectType,info)
                   end
               end
               v:Release()
               self.m_lComponents[i]=nil
			
           end -- end if not smrArray or smrArray.Length<1
       end -- end if not go
   end -- end for
   self.m_lComponents = {}

   if not (self.m_Character:IsNpc() or self.m_Character:IsMineral()) then
        self.m_Character:Show()
   end

   if self.m_AvatarCallBack then
       self:AvatarCallBack()
   end

   self.m_Character:OnAvatarLoaded()
end

--把武器附着到骨骼的父节点上面weaponTransform是 m_lAttachments 表中存储的对象（v.m_Object.transform）
function HumanoidAvatar:AttachWeaponToBone(weaponTransform,weaponID,bLeftSkeleton,weaponModelFile)
    if weaponTransform and weaponID~=0 then
        local weaponInfo = nil
        local transformBone = nil
        local CurrentSkeleton = bLeftSkeleton and skeletonL or skeletonR

        transformBone = self.m_Character:GetAttachBone(CurrentSkeleton,false) --得到绑定武器节点的
		
		local str = transformBone.gameObject.transform.name

--[[
        local smr = weaponTransform:GetComponentsInChildren(SkinnedMeshRenderer,true)
        for i=1,smr.Length do
            for j=1,smr[i].materials.Length do
                if self.m_Character:IsUIPlayer() or (self.m_Character.m_MountUIPlayer==true) then
                    smr[i].materials[j].shader = self.m_ReplacePlayerShaderUI
                elseif self.m_Character.m_Type ~= CharacterType.PlayerRole then
                    smr[i].materials[j].shader = self.m_ReplacePlayerShaderOther
                end
            end
        end
        ]]
        if transformBone then
            weaponTransform.gameObject:SetActive(true)
            weaponTransform:SetParent(transformBone)
            weaponTransform.localScale = Vector3.one
            weaponTransform.localRotation = Quaternion.identity
            weaponTransform.localPosition = Vector3.zero
			ExtendedGameObject.SetLayerRecursively(weaponTransform.gameObject,self.m_Character.m_Object.layer)

			local attachGameObject = nil
			if not bLeftSkeleton or self.m_Profession == cfg.role.EProfessionType.RENZU then
				if bLeftSkeleton then
				    self.m_bLWeaponAttachObjLoaded  = false
                else
                    self.m_bRWeaponAttachObjLoaded  = false
				end

				local attachName = "jl_"..weaponModelFile --加载武器特效的名字

				if not attachGameObject then
					local attachNameNew = string.sub(attachName, 1, -4).."default"
					--加载武器的特效模型
					Util.Load( GetWeaponPath(attachNameNew), Define.ResourceLoadType.LoadBundleFromFile,  function(asset_obj)
                        if (not IsNull(asset_obj)) and self.m_Character and (not IsNull(self.m_Character.m_Object)) then
                            attachGameObject = GameObject.Instantiate(asset_obj)
						    if attachGameObject and attachGameObject.transform then

                                if weaponTransform then
                                    attachGameObject.transform.gameObject:SetActive(true)
							        attachGameObject.transform:SetParent(weaponTransform) --transformParentBone会出现偶尔无法挂上去的问题  --不能使用上文weaponTransform，快速升级会导致失效
							        attachGameObject.transform.localScale = Vector3.one
							        attachGameObject.transform.localRotation = Quaternion.identity
							        attachGameObject.transform.localPosition = Vector3.zero
							        ExtendedGameObject.SetLayerRecursively(attachGameObject.transform.gameObject,self.m_Character.m_Object.layer)
                                else
                                    GameObject.Destroy(attachGameObject.transform.gameObject)
                                end

                                if bLeftSkeleton then
				                    self.m_bLWeaponAttachObjLoaded  = true
                                else
                                    self.m_bRWeaponAttachObjLoaded  = true
                                    if self.m_Profession == cfg.role.EProfessionType.TIANYINSI then
                                        self.m_bLWeaponAttachObjLoaded  = true
                                    end
				                end
						    end
						end
					end)
				end
			else
                --self.m_bRWeaponAttachObjLoaded  = true
				self.m_bLWeaponAttachObjLoaded  = true
			end
            return true
        end
    end
    return false
end

function HumanoidAvatar:CheckWeaponSfx(weaponAnnealLevel, bLeft)
    ----装备报错临时解决
	--if true then return false end
	if weaponAnnealLevel == 0 then   return false end

    local weaponData

    if self.m_Profession == cfg.role.EProfessionType.XIANZU then
         weaponData = ConfigManager.getConfigData("xianzuweaponsfx",weaponAnnealLevel)
    else
        weaponData= ConfigManager.getConfigData("renzuweaponsfx",weaponAnnealLevel)
    end

    if not weaponData then return false end

	local sfx1 = attachsfxinfo:new()
    sfx1.sfxId = 0
	sfx1.sfxType = attachsfxinfo.EquipSfxType.WEAPON

	--sfx1.sfxFileName = weaponAttachPoint1Name..string.format("_%02d", weaponAnnealLevel)
    sfx1.sfxFileName = weaponData.fx01path
    sfx1.attachPoint = weaponAttachPoint1Name
    sfx1.sfxObject = nil
    table.insert(self.m_EquipSfxInfos,sfx1)

    if bLeft then
        local sfx4 = attachsfxinfo:new()
        sfx4.sfxId = 0
        sfx4.sfxType = attachsfxinfo.EquipSfxType.WEAPON_LEFT

        --sfx1.sfxFileName = weaponAttachPoint1Name..string.format("_%02d", weaponAnnealLevel)
        sfx4.sfxFileName = weaponData.fx01path
        sfx4.attachPoint = weaponAttachPoint1Name
        sfx4.sfxObject = nil
        table.insert(self.m_EquipSfxInfos,sfx4)

    end


    --local sfx2 = attachsfxinfo:new()
    --sfx2.sfxId = 0
    --sfx2.sfxType = attachsfxinfo.EquipSfxType.WEAPON
    --
    --if self.m_Profession == cfg.role.EProfessionType.TIANYINSI then
    --    --sfx2.sfxFileName = weaponAttachPoint3Name..string.format("_%02d", weaponAnnealLevel)
    --    sfx2.sfxFileName = weaponData.fx03path
    --    sfx2.attachPoint = weaponAttachPoint3Name
    --else
    --    --sfx2.sfxFileName = weaponAttachPoint2Name..string.format("_%02d", weaponAnnealLevel)
    --    sfx2.sfxFileName = weaponData.fx03path
    --    sfx2.attachPoint = weaponAttachPoint2Name
    --end
    --sfx2.sfxObject = nil
    --table.insert(self.m_EquipSfxInfos,sfx2)
    --
    --if bLeft then
    --
    --    local sfx5 = attachsfxinfo:new()
    --    sfx5.sfxId = 0
    --    sfx5.sfxType = attachsfxinfo.EquipSfxType.WEAPON_LEFT
    --
    --    if self.m_Profession == cfg.role.EProfessionType.TIANYINSI then
    --        --sfx2.sfxFileName = weaponAttachPoint3Name..string.format("_%02d", weaponAnnealLevel)
    --        sfx5.sfxFileName = weaponData.fx03path
    --        sfx5.attachPoint = weaponAttachPoint3Name
    --    else
    --        --sfx2.sfxFileName = weaponAttachPoint2Name..string.format("_%02d", weaponAnnealLevel)
    --        sfx5.sfxFileName = weaponData.fx03path
    --        sfx5.attachPoint = weaponAttachPoint2Name
    --    end
    --    sfx5.sfxObject = nil
    --    table.insert(self.m_EquipSfxInfos,sfx5)
    --end

	return true
end

function HumanoidAvatar:CheckClothSfx(clothId, clothAnnealLevel)
    --local clothSfxData = ConfigManager.getConfigData("equipbindsfx",clothId)
    --if not clothSfxData then return false end
    --local curSfxId = clothSfxData.sfxlist[clothAnnealLevel+1]
    --
    --if curSfxId == 0 then return false end

    --local curSfxInfo = ConfigManager.getConfigData("sfxinfo",curSfxId)
    --if not curSfxInfo then return end

    local curSfxInfo

    if self.m_Profession == cfg.role.EProfessionType.RENZU then
        curSfxInfo = ConfigManager.getConfigData("renzuclothsfx",clothAnnealLevel)
    else
        curSfxInfo= ConfigManager.getConfigData("xianzuclothsfx",clothAnnealLevel)
    end

    if not curSfxInfo then return false end

    local curSfxAttachPointName = curSfxInfo.attachpoint
    if not curSfxAttachPointName or curSfxAttachPointName == ""  then return false end

    local sfx = attachsfxinfo:new()
    --sfx.sfxId = curSfxId
	sfx.sfxType = attachsfxinfo.EquipSfxType.CLOTH
	sfx.sfxFileName = curSfxInfo.path
    sfx.attachPoint = curSfxAttachPointName
    sfx.sfxObject = nil
    self.m_ClothSfxInfo = sfx
	return true
end

function HumanoidAvatar:UpdateWeaponSfx(equipid, equipAnnealLevel)
	if equipid == 0 or equipAnnealLevel == 0 then
		return
	end

    local bAttachWeaponSfx

    if self.m_Profession == cfg.role.EProfessionType.RENZU then
        bAttachWeaponSfx = self:CheckWeaponSfx(equipAnnealLevel, true)
    else
        bAttachWeaponSfx = self:CheckWeaponSfx(equipAnnealLevel, false)
    end


    if bAttachWeaponSfx then
        self.m_bNeedAttachEquipSfx = true
    end



	--local bAttachWeaponSfx = self:CheckWeaponSfx(equipAnnealLevel)
    --if bAttachWeaponSfx and self.m_Profession == cfg.role.EProfessionType.GUIWANGZONG then
     --   self:CheckWeaponSfx(equipAnnealLevel, true)
    --end
    --if bAttachWeaponSfx then
	--	self.m_bNeedAttachEquipSfx = true
	--end
end

function HumanoidAvatar:UpdateClothSfx(clothid, clothAnnealLevel)
    self:DestoryClothSfx()

    if self:CheckClothSfx(clothid, clothAnnealLevel) then
		self.m_bNeedAttachClothSfx = true
	end
end

function HumanoidAvatar:DestoryClothSfx()
    if self.m_ClothSfxInfo then
        self.m_ClothSfxInfo:Release()
        self.m_ClothSfxInfo = nil
    end
end

function HumanoidAvatar:AttachEquipSfx()
    if not self.m_Character or IsNull(self.m_Character.m_Object)
		or self:IsLoadingAttachments() or self:IsLoadingComponent() then return end

    for i,v in pairs(self.m_EquipSfxInfos) do
        if not v.sfxObject then
            if v.sfxFileName and v.sfxFileName ~= ""  then
                Util.Load(GetSfxPath(v.sfxFileName), Define.ResourceLoadType.LoadBundleFromFile,  function(asset_obj)
                    if not IsNull(asset_obj) then
                        local sfxGameObject = Util.Instantiate(asset_obj,GetSfxPath(v.sfxFileName))
                        if sfxGameObject and sfxGameObject.transform then
                            if v.attachPoint and v.attachPoint ~= "" then
                                local transformBone = nil
                                --if self.m_Profession ~= cfg.role.EProfessionType.GUIWANGZONG then
                                --    transformBone = self.m_Character:GetAttachBone(v.attachPoint,true)
                                --else
                                    local boneRoot = self.m_Character.m_Object.transform:Find("Bip001")
                                    if v.sfxType == attachsfxinfo.EquipSfxType.WEAPON_LEFT  then
                                        boneRoot = self.m_Character:GetAttachBone("Bip001 L Clavicle")
                                    else
                                        boneRoot = self.m_Character:GetAttachBone("Bip001 R Clavicle")
                                    end
                                    transformBone = self.m_Character:GetAttachBone(v.attachPoint,true, boneRoot.gameObject)
                                --end

                                sfxGameObject.transform.gameObject:SetActive(true)
                                sfxGameObject.transform:SetParent(transformBone)
                                sfxGameObject.transform.localScale = Vector3.one
					            sfxGameObject.transform.localRotation = Quaternion.identity
					            sfxGameObject.transform.localPosition = Vector3.zero
					            ExtendedGameObject.SetLayerRecursively(sfxGameObject.transform.gameObject,self.m_Character.m_Object.layer)
                                Utils.SetParticleSystemScale(sfxGameObject.transform.gameObject, self.m_Character.m_sfxScale)

					            v.sfxObject = sfxGameObject.transform.gameObject
                            else
                                GameObject.Destroy(sfxGameObject.transform.gameObject)
                            end
                        end
                    end
				end)
			end
		end
    end

    self.m_bNeedAttachEquipSfx = false
	self.m_bLWeaponAttachObjLoaded  = false
	self.m_bRWeaponAttachObjLoaded  = false
end

function HumanoidAvatar:AttachClothSfx()
    if not self.m_ClothSfxInfo then
        return
    end

    if not self.m_Character or not self.m_Character.m_Object
		or self:IsLoadingAttachments() or self:IsLoadingComponent() then return end

    if self.m_ClothSfxInfo.sfxFileName and self.m_ClothSfxInfo.sfxFileName ~= ""  then
        Util.Load(GetSfxPath(self.m_ClothSfxInfo.sfxFileName), Define.ResourceLoadType.LoadBundleFromFile,  function(asset_obj)
            if not IsNull(asset_obj) then
                local sfxGameObject = Util.Instantiate(asset_obj,GetSfxPath(self.m_ClothSfxInfo.sfxFileName)) --GameObject.Instantiate(asset_obj)
                if sfxGameObject then
                    local transformBone = self.m_Character:GetAttachBone(self.m_ClothSfxInfo.attachPoint)
                    if transformBone and self.m_ClothSfxInfo.attachPoint and self.m_ClothSfxInfo.attachPoint ~= "" then
                        sfxGameObject.transform.gameObject:SetActive(true)
                        sfxGameObject.transform:SetParent(transformBone)
                        sfxGameObject.transform.localScale = Vector3.one --transformBone.transform.localScale
		                sfxGameObject.transform.localRotation = Quaternion.identity
		                sfxGameObject.transform.localPosition = Vector3.zero
		                ExtendedGameObject.SetLayerRecursively(sfxGameObject.transform.gameObject,self.m_Character.m_Object.layer)
                        Utils.SetParticleSystemScale(sfxGameObject.transform.gameObject, self.m_Character.m_sfxScale)

                        if self.m_ClothSfxInfo.sfxObject then
                            GameObject.Destroy(self.m_ClothSfxInfo.sfxObject)
                        end
		                self.m_ClothSfxInfo.sfxObject = sfxGameObject.transform.gameObject
                    else
                        GameObject.Destroy(sfxGameObject.transform.gameObject)
                    end
                end
            end
	    end)
    end

    self.m_bNeedAttachClothSfx = false
end

--把武器附着到模型上面 所有存储武器节点的都是通过m_lAttachments这个表来存储的
function HumanoidAvatar:Attach()
    local tmp
    if not self.m_Character or IsNull(self.m_Character.m_Object) or self:IsLoadingAttachments() then return end
    self.m_bNeedAttachModel = false
    for i,v in pairs(self.m_lAttachments) do
        if v then
            if v.m_Object then
                if v.m_ObjectType == HumanoidAvatar.EquipType.WEAPON then
                    if self:AttachWeaponToBone(v.m_Object.transform,v.m_ObjectID,v.m_bLeftHand,v.m_ModelOriginalFile) then
                        if self:GetEquipingInfoCount()>v.m_ObjectType then
                            local info = EquipInfo:new()
                            tmp=v.m_Object.transform
                            info.m_Transform = v.m_Object.transform
                            info.m_ID   = v.m_ObjectID
                            self:AddEquipItem(v.m_ObjectType,info)
                        end
                        self.m_lAttachments[i]=nil
                    else
                        self.m_bNeedAttachModel = true
                    end
                end
            end
        else
             self.m_lAttachments[i]=nil
        end
    end
end
function HumanoidAvatar:ChangeAlpha(alpha)
	for type=HumanoidAvatar.EquipType.ARMOUR,HumanoidAvatar.EquipType.COUNT do
        if self.m_lEquipingInfo[type].Count > 0 then
			for i,v in pairs(self.m_Materials[type]) do
				if v then
					v:SetFloat("_SceneAlpha",alpha);
				end
		   end
		end
    end		
end
return HumanoidAvatar
