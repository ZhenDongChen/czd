local print             = print
local require           = require
local Character         = require "character.character"
local DefineEnum        = require "defineenum"
local Define            = require "define"
local ConfigManager     = require "cfg.configmanager"
local HumanoidAvatar    = require "character.avatar.humanoidavatar"
local TalismanContoller = require "character.talisman.talismancontroller"
local CharacterType     = DefineEnum.CharacterType
local MountType         = DefineEnum.MountType
local ItemManager       = require "item.itemmanager"
local PlayerTransformSync   = require "character.transformsync.playertransformsync"
local PlayerSkill
local TeamManager
local Player = Class:new(Character)

function Player:__new(isPlayerRole)
    Character.__new(self)
    self.m_Type             = CharacterType.Player
    if isPlayerRole then
        self.m_Type         = CharacterType.PlayerRole
    end
    if PlayerSkill == nil then
        PlayerSkill = require "character.skill.playerskill"
    end
	if TeamManager == nil then
        TeamManager = require"ui.team.teammanager"
    end
    self.m_Dress            = 0
    self.PlayerSkill        = PlayerSkill:new(self)
    self.m_VipLevel         = 0
    self.m_Exp              = 0
    self.m_Factionlevel     = 0
    self.m_MountType        = cfg.equip.RideType.NONE
    self.m_MountId          = 0
    self.m_Mount            = nil
    self.m_Profession       = 0         --职业
    self.m_ProfessionData   = nil     --职业配置数据x
    self.m_Gender           = 0         --性别
	self.m_LoverId 		    = nil		--情侣Id
    self.m_LoverName        = ""
    self.m_Equips           = {}
	self.m_FamilyID		    = 0		--家族、工会
    self.m_FamilyName       = "" --家族工会名字
    self.m_FamilyJob        = 0
    self.m_FamilyLevel      = 0
    self.m_LastOnlineTime   = 0
    self.m_Talisman         = nil
    self.m_ServerId         = 0

    self.m_DeclareWarFamilys = {}

    self.m_TalismanController = TalismanContoller:new(self)
end

function Player:GetProfession()
	return self.m_Profession
end

function Player:GetMountId()
	return m_MountId
end
function Player:GetMount()
	return m_Mount
end

function Player:init(id,profession,gender,showheadinfo,dress,equips,iscreat,sfxScale)
    self.m_Id                   = id
    self.m_Profession           = profession
    self.m_Gender               = gender
    self.m_Dress                = dress or self.m_Dress
    self.m_Equips               = equips or {}
    self.m_ProfessionData       = ConfigManager.getConfigData("profession",profession)
    self.m_ProfessionModel      = gender==cfg.role.GenderType.MALE and self.m_ProfessionData.modelname or self.m_ProfessionData.modelname2
    self.m_AvatarId             = nil
    Character.SetSfxScale(self,sfxScale)
    local characterModelData    = ConfigManager.getConfigData("model",self.m_ProfessionModel)
    self.m_Image                = characterModelData.portrait
    local ModelData             = self:GetModelData(iscreat)
    self:CriticalLoadModel({ModelData,characterModelData,showheadinfo})

    self.m_Avatar.m_Profession = self.m_Profession
    if self.m_Dress == 0 then

        self.m_Avatar:UpdateClothSfx(self:GetClothInfo())
    end
    self:LoadWeapon()
end
function Player:CreateTransformSync()
    return PlayerTransformSync:new(self)
end

function Player:GetBundlePath(path)
    return string.format("character/player_%s.bundle",path)
end

function Player:sync_SPathFlyBegin(startPos, curveId, targetPos, portalId)
    if self:IsRiding() then
        self:CancelRiding()
        self:DeviatePlayerFromMount(false)
    end

    Character.sync_SPathFlyBegin(self, startPos, curveId, targetPos, portalId)
end
function Player:sync_SPathFlyEnd(orient)
    Character.sync_SPathFlyEnd(self, orient)
end

function Player:IsInWarWithRoleFamily()
    local roleFamilyId = PlayerRole:Instance().m_FamilyID
    if self.m_FamilyID ~= nil and roleFamilyId ~= nil then
        if self.m_DeclareWarFamilys[roleFamilyId] == true then
            return true
        end
        if PlayerRole:Instance().m_DeclareWarFamilys[self.m_FamilyID] == true then
            return true
        end
    end
    return false
end

function Player:OnFamilyWarChange()
    if self.m_HeadInfo then
        self.m_HeadInfo:OnFamilyWarChange()
    end
end


function Player:ChangeDeclareWarFamilys(newFamilysId)
    if newFamilysId == nil then
        return
    end
    self.m_DeclareWarFamilys = {}
    for i, id in pairs(newFamilysId) do
        self.m_DeclareWarFamilys[id] = true
    end
    self:OnFamilyWarChange()
end

function Player:IsFashionChange(dressid)
    local id = dressid
    if dressid == nil then
        id = 0
    end

    if self.m_Dress ~= id then
        return true
    end
    return false
end

function Player:IsClothChange(equips)
    if not equips then
        return false
    end

    local oldClothID = 0
    local newClothID = 0
    local oldClothAnneallevel = 0
    local newClothAnneallevel = 0
    for _,equip in pairs(self.m_Equips) do
        local equipInfo = ConfigManager.getConfigData("equip",equip.equipkey)
        if equipInfo and equipInfo.type == cfg.item.EItemType.CLOTH then
            oldClothID = equip.equipkey
            oldClothAnneallevel = equip.anneallevel
        end
    end
    for _,equip in pairs(equips) do
        local equipInfo = ConfigManager.getConfigData("equip",equip.equipkey)
        if equipInfo and equipInfo.type == cfg.item.EItemType.CLOTH then
            newClothID = equip.equipkey
            newClothAnneallevel = equip.anneallevel
        end
    end
    if newClothID ~= oldClothID or oldClothAnneallevel ~= newClothAnneallevel then
        return true
    end
    return false
end

function Player:ChangeArmour(dressid,equips)
    local isFashionChange = self:IsFashionChange(dressid)
    local isClothChange = self:IsClothChange(equips)
    self.m_Dress = dressid or self.m_Dress
    self.m_Equips = equips or self.m_Equips
    local ModelData = self:GetModelData()
    self:CriticalLoadModel({ModelData})
    if self.m_Dress == 0 and (isClothChange or isFashionChange) then
        self.m_Avatar:UpdateClothSfx(self:GetClothInfo())
    elseif self.m_Dress ~= 0 then
        self.m_Avatar:DestoryClothSfx()
    end
end

function Player:GetClothInfo()
    for _,equip in pairs(self.m_Equips) do
        local equipInfo = ConfigManager.getConfigData("equip",equip.equipkey)
        if equipInfo and equipInfo.type == cfg.item.EItemType.CLOTH then
            return equip.equipkey, equip.anneallevel
        end
    end
    return 0,0
end

function Player:GetModelData(isCreat)
    local modelName = nil
    if isCreat then
        local roleInfo = ConfigManager.getConfigData("profession",self.m_Profession)
        --modelName = self.m_Gender==cfg.role.GenderType.MALE and equipInfo.male or equipInfo.female
        --modelName = self.m_Gender == cfg.role.GenderType.MALE and roleInfo.modelname or roleInfo.modelname2
        table.insert(self.m_Equips,{["equipkey"] = roleInfo.createweaponid,["anneallevel"] = roleInfo.weaponanneallevel})
        table.insert(self.m_Equips,{["equipkey"] = roleInfo.createarmourid,["anneallevel"] = roleInfo.clothanneallevel})
        local talismanInfo = ConfigManager.getConfigData("talismanbasic",roleInfo.talismanid)
    end
    --else
        if self.m_Dress ~= 0 then
            local dressInfo = ConfigManager.getConfigData("dress",self.m_Dress)
			if dressInfo == nil then
				printyellow("dressinfo is invalid:"..self.m_Dress)
			end
            modelName = dressInfo.modelname[self.m_Profession]
        else
            local haveEquip = false
            for _,v in pairs(self.m_Equips) do
                local equipInfo = ConfigManager.getConfigData("equip",v.equipkey)
                if not equipInfo then
                    logError("equip model is nil")
                else
                    if equipInfo.type == cfg.item.EItemType.CLOTH then
                        haveEquip = true
                        modelName = self.m_Gender == cfg.role.GenderType.MALE and equipInfo.male or equipInfo.female
                        break
                    end
                end
            end
            if not haveEquip then
                local roleInfo = ConfigManager.getConfigData("profession",self.m_Profession)
                modelName = self.m_Gender == cfg.role.GenderType.MALE and roleInfo.modelname or roleInfo.modelname2
            end
        end
    --end
    local modelData = ConfigManager.getConfigData("model",modelName)

    return modelData
end

function Player:LoadWeapon(equips)
    self.m_Equips = equips or self.m_Equips
    local haveWeapon
    for _,equip in pairs(self.m_Equips) do
		print(equip.equipkey)
		assert(equip.equipkey)
        local equipInfo = ConfigManager.getConfigData("equip",equip.equipkey)
        if not equipInfo then
            logError("equip model is null ")
        else
            if equipInfo.type == cfg.item.EItemType.WEAPON then
                haveWeapon = true
                self.m_Avatar:Arm(self.m_Profession,HumanoidAvatar.EquipDetailType.WEAPON,equip.equipkey)

                self.m_Avatar:UpdateWeaponSfx(equip.equipkey, equip.anneallevel)
            end
        end
    end
    if not haveWeapon then
        self.m_Avatar:Arm(self.m_Profession,HumanoidAvatar.EquipDetailType.DEFAULTWEAPON)
    end
end

function Player:GetVipLevel()
    return self.m_VipLevel
end

function Player:GetTalisman()
    return self.m_Talisman
end

function Player:ChangeTalisman(talisman)
    self.m_Talisman = talisman
    self.m_TalismanController:OnTalismanChange(self.m_Talisman)
end

function Player:AdjustMountSpeed()
    if (self.m_Mount) then
        if self.m_Mount.m_Attributes[cfg.fight.AttrId.MOVE_SPEED]~=self.m_Attributes[cfg.fight.AttrId.MOVE_SPEED] then
            self.m_Mount.m_Attributes[cfg.fight.AttrId.MOVE_SPEED]=self.m_Attributes[cfg.fight.AttrId.MOVE_SPEED]
        end
    end
end

function Player:CheckMountUpdate()
    if self.m_Object and self:GetRefPos()~=Vector3.zero then
        if  (self.m_MountId==0 or self.m_MountType==cfg.equip.RideType.NONE) then
            if self.m_Mount and (self.m_Mount.m_MountState~=MountType.Attaching) then
                self:DeviatePlayerFromMount(false)
                self.m_Mount=nil
            end
        else
            if self.m_MountType==cfg.equip.RideType.WALK then
                if self.m_PathFlyState~=true then
                    if not self.m_Mount then
                        self:AddMount()
                    else
                        if self.m_MountId~=self.m_Mount.m_Id then
                            self:DeviatePlayerFromMount(false,true)
                            self:AddMount()
                        end
                        if self.m_Mount then
                            if self.m_Mount.m_MountState==MountType.Attaching then
                                self:AttachPlayerToMount()
                            else
                                if self.m_Type==CharacterType.Player then
                                    self.m_Mount.m_MountState=MountType.Ride
                                end
                            end
                            self:AdjustMountSpeed()
                        end
                    end
                end
            elseif self.m_MountType==cfg.equip.RideType.FLY then
                if not self.m_Mount then
                    self:AddMount()
                else
                    if self.m_MountId~=self.m_Mount.m_Id then
                        self:DeviatePlayerFromMount(false,true)
                        self:AddMount()
                    end
                    if self.m_Mount then
                        if self.m_Mount.m_MountState==MountType.Attaching then
                            self:AttachPlayerToMount()
                        else
                            if (self.m_Type==CharacterType.Player) and (self.m_Mount.m_MountState~=MountType.Fly) then
                                self.m_Mount.m_MountState=MountType.Fly
                            end
                            if (self:IsRole()) then
                                local FlyNavManager=require"character.navigation.flynavigationmanager"
                                if FlyNavManager.IsFlyNav()==true then
                                    local ConfigMgr=require"cfg.configmanager"
                                    local PropData = ConfigMgr.getConfigData("riding",self.m_MountId)
                                    self.m_Mount.m_MountState=MountType.Fly
                                    self.m_Mount:SetOffsetY(PropData.initialheightinfly)
                                    self.m_Mount:SetPos(self.m_Pos)
                                end
                            end
                        end
                        self:AdjustMountSpeed()
                    end
                end
            end
        end
    end
end

function Player:update()
    self:CheckMountUpdate()
    if self.m_Mount then
        self.m_Mount:update()
    end
    self.PlayerSkill:Update()
    Character.update(self)
end


function Player:lateUpdate()
    Character.lateUpdate(self)
    self.m_TalismanController:Update(self:GetTalisman())
end



function Player:AddMount()
    --printyellowmodule(Local.LogModuals.Ride,"AddMount")
    self.m_UnLoadMount=false
    local Mount=require "character.mount"
    self.m_Mount=Mount:new()
    self.m_Mount:init(self.m_MountId,self)
end

function Player:HideShadow(valid)
    if self.m_ShadowObject then
        self.m_ShadowObject:SetActive(valid)
    end
end

function Player:AttachPlayerToMount()
--	print("AttachPlayerToMount")
    if self.m_Object and self.m_Mount.m_Object then
		--self.m_AngleZBeforeMount=self.m_AngleZ
		--self.m_RotationBeforeMount=self.m_Rotation
		
        printyellowmodule(Local.LogModuals.Ride,"AttachPlayerToMount")
        local playerPos=self.m_Object.transform:GetChild(0).transform.position
        local ConfigMgr=require "cfg.configmanager"
        local PropData = ConfigMgr.getConfigData("riding",self.m_MountId)
        self.m_Mount:SetOffsetY(PropData.initialheightinride)
        self.m_Mount:SetPos(Character.GetPos(self))
        self.m_Mount.m_Rotation=self.m_Rotation
        local attachTransform=nil
        local attachBone=nil
        if self.m_Mount.m_Object then
            attachBone=self.m_Mount.m_Object.transform:GetChild(0).transform:Find(self.m_Mount.m_RiggingPoint).gameObject
        end
        if attachBone then
            attachTransform=attachBone.transform
        end
        local attachedBone=nil
        local attachedTransform=nil
        attachedBone=self.m_Object
        if attachedBone then
            printyellowmodule(Local.LogModuals.Ride,"attachedBone")
            attachedTransform=attachedBone.transform
            local bipBone=self.m_Object.transform:GetChild(0).transform:Find("Bip001").gameObject
            local bipBonetrans=bipBone.transform
            bipBonetrans.position=Vector3.zero
        end
        if attachTransform and attachedTransform then
            printyellowmodule(Local.LogModuals.Ride,"attachedTransform.parent=attachTransform")
            attachedTransform:SetParent(attachTransform)
            self.m_Mount:SetAttach(true)
            self.m_Mount.m_MountState=MountType.Ride
            self.WorkMgr:ShutAllWorks()
            attachedTransform.localPosition = Vector3.zero
            self:HideShadow(false)
            if self.m_Mount.m_RoleAction==1 then 
               self:PlayLoopAction(cfg.skill.AnimType.StandFly)
               local flySwordHeight=ConfigManager.getConfig("flyingswordheight")
               local flyOffSetY=0
               if flySwordHeight then
                  for _,data in pairs(flySwordHeight) do
                      if data.faction==self.m_Profession and data.gender==self.m_Gender then
                          flyOffSetY=data.offsety
                          break
                      end
                  end
                  attachedTransform.localPosition = Vector3(0,0,flyOffSetY)
               end
            elseif self.m_Mount.m_RoleAction==2 then
               self:PlayLoopAction(cfg.skill.AnimType.StandRide)
			elseif self.m_Mount.m_RoleAction==3 then
               self:PlayLoopAction(cfg.skill.AnimType.SitRide)
            end
            attachedTransform.localEulerAngles=Vector3(self.m_Mount.m_PlayerRotation[1],self.m_Mount.m_PlayerRotation[2],self.m_Mount.m_PlayerRotation[3])
            if (self.m_HeadInfo) and (self.m_HeadInfo:GetHpBar()) then
                    self.m_oldHeadPos=self.m_HeadInfo:GetHpBar().transform.localPosition
                    self.m_HeadInfo:GetHpBar().transform.localPosition=Vector3(self.m_oldHeadPos.x,self.m_oldHeadPos.y-1,self.m_oldHeadPos.z)
            end
        end
        if (self:IsRole()) then
--            if (self.m_WalkInSky==true) then
--                self.m_WalkInSky=false
--                self.m_Mount.m_MountState=MountType.Fly
--                self.m_Mount:SendMountState(cfg.equip.RideType.FLY)
--            end
--            if (self.m_Mount.m_MountState==MountType.Fly) then
--                self.m_Mount:moveup(true)
--            end
            if self.m_MountType==cfg.equip.RideType.FLY then
                local SceneManager=require"scenemanager"
                if SceneManager.HasSkyHeight()==true then
                    self.m_Mount.m_MountState=MountType.Fly
                    self.m_Mount:SetOffsetY(PropData.initialheightinfly)
                    self.m_Mount:SetPos(Character.GetPos(self))
                else
                    self.m_Mount:SendMountState(cfg.equip.RideType.Walk)
                end
            end
        end
        self:ResetMainRide()
    end
end

function Player:ResetMainRide()
    if  (self:IsRole()) then
        local UIManager=require"uimanager"
        if UIManager.isshow("dlguimain") then
			local DlgUIMain_Combat=require"ui.dlguimain_combat"
			-- DlgUIMain_Combat.SetRidingState(true)
			DlgUIMain_Combat.RefreshRidingState()
		end
        if self:IsFlying() then
            self.m_Mount:BindFlyEffect()
        elseif self:IsRiding() then
            self.m_Mount:ReleaseBindFlyEffect()
        end
    end
    self.m_HeadInfo:OnRideStateChange()
	
	
	
end

function Player:IsRiding()
	if self.m_Mount==nil then
		return false
	end
    return self.m_Mount and self.m_Mount:IsAttach()
end

function Player:IsFlying()
    if self.m_Mount and self.m_Mount.m_MountState == MountType.Fly then
        return true
    end
    return false
end

function Player:CancelRiding()
    if self.m_Mount then
        if self.m_Mount.m_MountState == MountType.Ride then
            --self:DeviatePlayerFromMount(false)
            local RideManager = require "ui.ride.ridemanager"
            RideManager.Ride(self.m_MountId,cfg.equip.RideType.NONE)
        elseif  self.m_Mount.m_MountState == MountType.Fly then
            if self.m_Mount.destroy then
                return
            end
            self.m_Mount:Land(true)
        end
    end
end

function Player:GetOffsetY(changeRide)
    local offsetY=0
--    local pos=self.m_Mount:GetPos()
--    local SceneMgr=require "scenemanager"
--    local groundHeight=SceneMgr.GetHeight(pos)
--    local flyHeight=SceneMgr.GetHeight1(pos)
--    if changeRide~=true then
--        if groundHeight and (groundHeight> cfg.map.Scene.HEIGHTMAP_MIN) then
--            if flyHeight and (flyHeight>cfg.map.Scene.HEIGHTMAP_MIN) then
--                if math.abs(groundHeight-flyHeight)>1 then
--                    if pos.y>=flyHeight then
--                        offsetY=pos.y-groundHeight
--                        self.m_WalkInSky=true
--                    end
--                end
--            end
--        else
--            offsetY=pos.y-groundHeight
--            self.m_WalkInSky=true
--        end
--    end
    return offsetY
end

function Player:DeviatePlayerFromMount(isDead,changeRide)
	printyellow("DeviatePlayerFromMount")
    if self.m_Object then
        local attachTransform=nil
        local attachBone=nil
        if self.m_Mount.m_Object then
            attachBone=self.m_Mount.m_Object.transform:GetChild(0).transform:Find(self.m_Mount.m_RiggingPoint).gameObject
            --attachBone=self.m_Mount.m_Object.transform:Find(self.m_Mount.m_RiggingPoint).gameObject
        end
        if attachBone then
            attachTransform=attachBone.transform
        end
        if attachTransform then
            local pos=self.m_Mount:GetPos()
            local mountId=self.m_Mount:GetId()
            local offsetY=self:GetOffsetY(changeRide)
            --attachTransform:DetachChildren()
            if not isDead then
                self:PlayLoopAction(cfg.skill.AnimType.Stand)
                self.WorkMgr:ReStartWorks()
            end
            self.m_Object.gameObject:SetActive(false)
            --self.m_Object.transform.position=self.m_Mount.m_Object.transform.position
            --self.m_Rotation=self.m_Mount.m_Object.transform.rotation
            --if (changeRide~=true) then
				--self:SetEulerAngle(self.m_AngleZBeforeMount)
			--else
				--self.m_Rotation=self.m_Mount.m_Object.transform:GetChild(0).transform.rotation
			--end
			
			--self:SetEulerAngleImmediate(self.m_AngleZBeforeMount)
				
			---self.m_Rotation=self.m_RotationBeforeMount;
			
			
            self.m_OffsetY= offsetY
            self:SetPos(pos)          
            self:SetParent(nil)
            self.m_Object.gameObject:SetActive(true)
            self.m_Mount.attach=false
            self.m_Mount:Remove()
            self.m_Mount=nil
            if (changeRide~=true) then
                self.m_MountType=cfg.equip.RideType.NONE
				
				--self:SetEulerAngle(self.m_AngleZBeforeMount+1)
            end
            if (self.m_oldHeadPos) and (self.m_HeadInfo) and (self.m_HeadInfo:GetHpBar()) then
                self.m_HeadInfo:GetHpBar().transform.localPosition=Vector3(self.m_oldHeadPos.x,self.m_oldHeadPos.y,self.m_oldHeadPos.z)
            end
        end
        self:HideShadow(true)
        if self:IsRole() then
            if self.m_DownToAttackSkill~=nil then
                self.m_RoleSkillFsm:OnButtonCastSkill(self.m_DownToAttackSkill)
                self.m_DownToAttackSkill=nil
            end
            if self.m_DownToAutoFight==true then
                self.m_DownToAutoFight=nil
                local UIManager=require"uimanager"
                if UIManager.isshow("dlguimain") then
					UIManager.call("dlguimain","SwitchAutoFight",true)
                end
            end
        end
    end
    self:ResetMainRide()
end

--function Player:GetEquipmentInfo()
--    return self.m_Equipments
--end
function Player:DestroyMount()
    if self.m_Mount then
        self.m_Mount.attach=false
        self.m_Mount:Remove()
        self.m_Mount=nil
        self.m_MountType=cfg.equip.RideType.NONE
    end
end

function Player:SetRotation(dir)
    if dir ~= Vector3.zero then
        local rotation = Quaternion.LookRotation(dir, Vector3.up)
        if self:IsRiding() then
            self.m_Mount.m_Rotation=rotation
        else
            self.m_Rotation = rotation
			
			if g_idRoldTraceRotate and g_idRoldTraceRotate==m_Id then
				printyellow("trace rotate Player SetRotation:",m_Rotation)
			end
		
        end
    end
end

function Player:GetRotation()
    if self:IsRiding() then
        return self.m_Mount.m_Rotation
    else
        return self.m_Rotation
    end
end

function Player:SetRotationImmediate(dir)
    if dir ~= Vector3.zero then
        self:SetRotation(dir)
        if self:IsRiding() then
            self.m_Mount.m_Object.transform.localRotation = Quaternion.LookRotation(dir, Vector3.up)
        elseif self.m_Object then
            self.m_Object.transform.localRotation = Quaternion.LookRotation(dir, Vector3.up)
        end
    end
end

function Player:GetModel(callback)
    if self.m_Object ~= nil then
        callback(self.m_Object)
    end
end

function Player:OnPlaySkill(skillid)
    Character.OnPlaySkill(self,skillid)
    if self.m_TalismanController:IsTalsimanSkill(skillid) then
--        if self:IsRiding() then
--            self:DeviatePlayerFromMount(false)
--        end
        self.m_TalismanController:StartSkill()
    end
end

function Player:OnEndPlaySkill(skillid)
    Character.OnEndPlaySkill(self,skillid)
    if self.m_TalismanController:IsTalsimanSkill(skillid) then
        self.m_TalismanController:EndSkill()
    end
end

function Player:Hide(hideHP)
    Character.Hide(self,hideHP)
    if self.m_TalismanController and self.m_TalismanController.m_Object then
        self.m_TalismanController.m_Object:SetActive(false)
    end
end

function Player:Show()
    Character.Show(self)
    if self.m_TalismanController and self.m_TalismanController.m_Object then
        self.m_TalismanController.m_Object:SetActive(true)
    end
end

function Player:ResetRideState()
    if self:IsRiding() then
        if self.m_Mount.m_RoleAction==1 then
            self:PlayLoopAction(cfg.skill.AnimType.StandFly)
        elseif self.m_Mount.m_RoleAction==2 then
            self:PlayLoopAction(cfg.skill.AnimType.StandRide)
        elseif self.m_Mount.m_RoleAction==3 then
            self:PlayLoopAction(cfg.skill.AnimType.SitRide)
        end
    end
end

function Player:GetTalismanAction()
    return self:GetAction(self.m_ProfessionData.talismanactionname)
end




function Player:NotifyProcessor(info)
    if info.m_Name == "PlotCutsceneStart" then

    elseif info.m_Name == "PlotCutsceneEnd" then
        self:ResetRideState()
    end
end


function Player:IsMale()
    return self.m_Gender == cfg.role.GenderType.MALE
end

function Player:RefreshAvatarObject()
    ExtendedGameObject.SetLayerRecursively(self.m_Object,Define.Layer.LayerPlayer)
end

function Player:OnCharacterLoaded(bundlename,asset_obj,isShowHeadInfo,playbornaction)
    if self.m_Object then
        self.m_Object:SetActive(true)
    end
    Character.OnCharacterLoaded(self,bundlename,asset_obj,isShowHeadInfo,playbornaction)
end

function Player:GetPos()
    if self:IsRiding() then
        return self.m_Mount:GetPos()
    else
        return Character.GetPos(self)
    end
end

function Player:GetRefPos()
    if self:IsRiding() then
        return self.m_Mount:GetRefPos()
    else
        return Character.GetRefPos(self)
    end
end


function Player:ChangePKState(state)
	local CharacterManager = require"character.charactermanager"
    Character.ChangePKState(self,state)
    if not self:IsRole() then
        local pets = CharacterManager.GetCharacterPets(self)
        for _,pet in pairs(pets) do
            pet:ChangePKState(state)
        end
    end
end

function Player:ChangeFamily(name)
    self.m_FamilyName = name
    if self.m_HeadInfo then
        self.m_HeadInfo:OnChangeFamily()
    end
end

function Player:ChangeFabao(fabaokey)
    self.m_Fabao = fabaokey
    if fabaokey > 0 then
        local talisman = ItemManager.CreateItemBaseById(fabaokey,nil,1)
        self:ChangeTalisman(talisman)
    else
        self:ChangeTalisman(nil)
    end
end

function Player:ChangeRide(msg)
    if self:IsRole() then
        if  (msg.ridetype==0 or (msg.rideid==0)) or (self:CanRide()) then    --激活时，不可骑乘时禁止骑乘
            self.m_MountType = msg.ridetype
            self.m_MountId = msg.rideid
        else
            local RideManager=require"ui.ride.ridemanager"
            RideManager.Ride(0,cfg.equip.RideType.NONE)
        end
    else
        self.m_MountType = msg.ridetype
        self.m_MountId = msg.rideid
    end
end

function Player:IsClick(gameObject)
    return self:IsRiding() and self.m_Mount.m_Object and self.m_Mount.m_Object==gameObject
end

function Player:release()
    if self.m_TalismanController then
        self.m_TalismanController:OnDestroy()
    end
    return Character.release(self)
end

function Player:remove()
    if self.m_Mount then
        self.m_Mount:remove()
    end
    return Character.remove(self)
end
function Player:OnTeamChanged(b)
    -- if self.m_HeadInfo then
    --     self.m_HeadInfo:TurnHPProgressColor(b)
    -- end
    -- self:ChangePKState(self.m_PKState)
    -- local pets = CharacterManager.GetCharacterPets(self)
    -- for _,pet in pairs(pets) do
    --     if pet.m_HeadInfo then
    --         pet.m_HeadInfo:TurnHPProgressColor(b)
    --     end
    -- end
    self:ChangePKState(self.m_PKState)
    self.m_HeadInfo:OnTeamChanged()
    local pets = CharacterManager.GetCharacterPets(self)
    for _,pet in pairs(pets) do
        if pet.m_HeadInfo then
            pet.m_HeadInfo:OnTeamChanged(b)
        end
    end
end

function Player:GetMessage()
    local ret = {
        roleid          = self.m_Id,
        playerid        = self.m_Id,
        gender          = self.m_Gender,
        profession      = self.m_Profession,
        name            = self.m_Name,
        level           = self.m_Level,
        viplevel        = self.m_VipLevel,
        familyname      = self.m_FamilyName,
        fabaoid         = self.m_Fabao,
        lovername       = self.m_LoverName,
        ridestatus      = self.m_MountType,
        dressid         = self.m_Dress,
        rideid          = self.m_MountId,
        ridetype        = self.m_MountType,
        titleid         = self.m_Title and self.m_Title.m_Id or 0,
        equips          = self.m_Equips,
        pkstate         = self.m_PKState,
    }
    return Character.GetMessage(self,ret)
end

function Player:HideHeadInfo()
    local CharacterManager = require"character.charactermanager"
    local pets = CharacterManager.GetCharacterPets(self)
    for _,pet in pairs(pets) do
        pet:HideHeadInfo()
    end
    Character.HideHeadInfo(self)
end

function Player:ToSimplified()
    local CharacterManager = require"character.charactermanager"
    return CharacterManager.AlterCharacter(self.m_Id,true)
end

function Player:HaveRelationshipWithRole()
    if TeamManager.IsTeamMate(self.m_Id) then
        return true
    else
        local PlayerRole = require"character.playerrole"
        local camprelationInfo = ConfigManager.getConfigData("camprelation",PlayerRole:Instance().m_Camp)
        if camprelationInfo then
            return camprelationInfo.relations[self.m_Camp+1] == cfg.fight.Relation.FRIEND
        end
    end
end


--[[
function Player:sync_SPathFlyBegin(startPos, curveId, targetPos, portalId)
    if self:IsRiding() then
        self:CancelRiding()
        self:DeviatePlayerFromMount(false)
    end

    Character.sync_SPathFlyBegin(self, startPos, curveId, targetPos, portalId)
end

function Player:sync_SPathFlyEnd(orient)
    Character.sync_SPathFlyEnd(self, orient)
end
]]

return Player
