local print             = print
local require           = require
local defineenum        = require "defineenum"
local CharacterType     = defineenum.CharacterType
local CharState         = defineenum.CharState
local WorkType          = defineenum.WorkType
local WorkManager       = require "character.work.workmanager"
local ResourceLoadType  = define.ResourceLoadType
local uimanager         = require "uimanager"
local OutFightTime      = 5
local scenemanager      = require"scenemanager"
local event             = require "character.event.event"
local mathutils         = require"common.mathutils"
local ShadowObjectManager   = require"character.footinfo.shadowobjmanager"
local TransformSync     = require "character.transformsync.transformsync"

local TeamManager
local SimplifiedCharacter = Class:new()

function SimplifiedCharacter:__new()
    printyellow("new SimplifiedCharacter")
    if not TeamManager then
        TeamManager             = require"ui.team.teammanager"
    end
    self.WorkMgr                = WorkManager:new(self)
    self.m_Attributes           = {}
    self.m_HeadInfo             = nil
    self.EventQuene             = event.EventQuene:new()
    self:reset()
    self.m_TransformSync        = self:CreateTransformSync()
    self.m_IsDestroy            = false
end

function SimplifiedCharacter:CreateTransformSync()
    return TransformSync:new(self)
end

function SimplifiedCharacter:reset()
    self.m_Id                   = 0
    self.m_CsvId                = 0
    self.m_Type                 = CharacterType.SimplifiedCharacter
    self.m_Level                = 1
    self.m_Attributes[cfg.fight.AttrId.MOVE_SPEED]
                                = 5
    self.m_Jumpheigt            = 0
    self.m_Pos                  = Vector3.zero
    self.m_Rotation             = Quaternion.identity
    self.m_Height               = 1.7
    self.m_OffsetY              = 0
    self.m_State                = CharState.None
    self.m_Gravity              = 9.8
    self.m_JumpHeight           = 2
    self.m_Buffs                = {}
    self.m_LoverName            = ""
    self.m_PathFlyState         = false
    self.WorkMgr:reset(self)
	
	
	if g_idRoldTraceRotate and g_idRoldTraceRotate==m_Id then
		printyellow("trace rotate SimplifiedCharacter reset:",m_Rotation)
	end
end

function SimplifiedCharacter:SwitchPathFlyState(isPathFlayState)
    self.m_PathFlyState = isPathFlayState
end

function SimplifiedCharacter:GetMessage(ret)
    ret.fightercommon = {}
    ret.fightercommon.isdead = 0
    ret.fightercommon.isrevive = 0
    ret.fightercommon.isborn = 0
    ret.fightercommon.position = self:GetPos()
    ret.fightercommon.orient = self.m_Object.transform.forward
    if self:IsMoving() then
        ret.fightercommon.targetposition = self.m_TargetPos
    end
    ret.fightercommon.skills = self.m_FighterCommon.skills
    ret.fightercommon.attrs = self.m_Attributes
    ret.fightercommon.attrs[cfg.fight.AttrId.MOVE_SPEED] = 6*SCALE_SPEED
    ret.fightercommon.camp = self.m_Camp
    return ret
end

function SimplifiedCharacter:IsPathFlying()
    return self.m_PathFlyState
end

function SimplifiedCharacter:Load()
    local objName
    if self:IsPlayer() then
        objName = "player"  .. tostring(self.m_Id)
    elseif self:IsPet() then
        objName = "pet"     .. tostring(self.m_Id)
    end
    self.m_Object                   = GameObject(objName)
    local managerObject             = CharacterManager.GetCharacterManagerObject()
    self.m_Object.transform:SetParent(managerObject.transform)
    self.m_TransformControl         =utils.SetDefaultComponent(self.m_Object,TransformControl)
    self.m_TransformControl:Init(self.m_Object.transform)
    self.m_Height                   = 2.1
    --DontDestroyOnLoad(self.m_Object)
    SetDontDestroyOnLoad(self.m_Object)
    self.WorkMgr:Init(self)
    local dlgHead = require"ui.dlgmonster_hp"
    self.m_HeadInfo = dlgHead.Add(self,false)
    if self.m_OnLoaded then
        printyellow("call onloaded")
        self.m_OnLoaded()
        self.m_OnLoaded = nil
    end
end

function SimplifiedCharacter:init()
    self:Load()
end

function SimplifiedCharacter:GetName()
    return self.m_Name
end

function SimplifiedCharacter:ChangeAttr(ppt)
    local attrMap = cfg.fight.AttrId
    for _,v in pairs(cfg.fight.AttrId) do
        self.m_Attributes[v] = ppt[v] or self.m_Attributes[v]
        self.m_FighterCommon.attrs[v] = self.m_Attributes[v]
    end
    if self.m_HeadInfo then
        self.m_HeadInfo:OnAttributeChange()
    end
end

function SimplifiedCharacter:ChangeHP(v)
    self.m_Attributes[cfg.fight.AttrId.HP_VALUE] = v
    if self.m_HeadInfo then
        self.m_HeadInfo:OnAttributeChange()
    end
end



function SimplifiedCharacter:SetParent(obj)
    if self.m_Object then
      if obj then
          self.m_Object.transform:SetParent(obj.transform)
      else
          local managerObject = CharacterManager.GetCharacterManagerObject()
          self.m_Object.transform:SetParent(managerObject.transform)
      end
    end
end



function SimplifiedCharacter:update()

    if self.m_Object then
        if not self.m_Mount and not self.m_TransformControl then
            self.m_TransformControl:UpdateTransform(self.m_Pos,self.m_Rotation)
        end
        self.EventQuene:Update()
        self.WorkMgr:Update()
    end

end



function SimplifiedCharacter:remove()
    -- if self.m_ShadowObject then
    --     if not ShadowObjectManager.PushObject(self.m_ShadowObject) then
    --         GameObject.Destroy(self.m_ShadowObject)
    --     end
    -- end
    self.m_IsDestroy = true

    if self.m_HeadInfo then
        local dlgHead =require"ui.dlgmonster_hp"
        dlgHead.Remove(self)
        self.m_HeadInfo = nil
    end

    -- if self.m_HeadInfo then
    --     self.m_HeadInfo:Destroy()
    -- end
    if self.m_Object then
        GameObject.Destroy(self.m_Object)
        self.m_Object = nil
    end
end

function SimplifiedCharacter:SetPos(vecPos)
    self.m_Pos = vecPos
end

function SimplifiedCharacter:SetPosCorrectly(vecPos)
    if vecPos == nil then
        return
    end
    self.m_Pos = vecPos
end

function SimplifiedCharacter:SetRotationImmediate(dir)
    if dir ~= Vector3.zero then
        self:SetRotation(dir)
        if self.m_Object then
            self.m_Object.transform.localRotation = Quaternion.LookRotation(dir, Vector3.up)
        end
    end
end

function SimplifiedCharacter:IsAttacking()
    return false
end

function SimplifiedCharacter:IsBeAttacked()
    return false
end

function SimplifiedCharacter:lateUpdate()

end

function SimplifiedCharacter:GetPos()
	
    return Vector3(self.m_Pos.x,self.m_Pos.y,self.m_Pos.z)
end

function SimplifiedCharacter:GetRefPos()
    return self.m_Pos
end

function SimplifiedCharacter:SetRotation(dir)
    if dir ~= Vector3.zero then
        local rotation = Quaternion.LookRotation(dir,Vector3.up)
        self.m_Rotation = rotation
			
		if g_idRoldTraceRotate and g_idRoldTraceRotate==m_Id then
			printyellow("trace rotate SimplifiedCharacter SetRotation:",m_Rotation)
		end
		
    end
end

function SimplifiedCharacter:GetRotation()
    return self.m_Rotation
end


function SimplifiedCharacter:SetEulerAngle(eulerAngle)
    self.m_Rotation = Quaternion.Euler(-60,180,eulerAngle)
end


function SimplifiedCharacter:GetGroundHeight(pos)
	local ret = pos or self.m_Object.transform.position
	return ret
end


function SimplifiedCharacter:UpdateY()
    self.m_Pos = Vector3(self.m_Pos.x, self.m_Pos.y,0)
end


function SimplifiedCharacter:IsOnGround()
    local curHeight = self:GetGroundHeight(self.m_Pos) + self.m_OffsetY
    return math.abs(curHeight - self.m_Pos.y) < 0.001
end

function SimplifiedCharacter:CanMove()
    if IsNull(self.m_Object) then
        return false
    end
    if self.WorkMgr == nil then
        return false
    end
    if self.m_Attributes[cfg.fight.AttrId.MOVE_SPEED] == 0 then
        return false
    end
    return true
end

function SimplifiedCharacter:IsIdle()
    return self:IsWorkState(WorkType.Idle)
end

function SimplifiedCharacter:CanRotate()
    return true
end

function SimplifiedCharacter:MoveTo(position)
    if not self:IsDead() then
        self.m_TargetPos = position
      --  local move = event.MoveEvent:new(self,{TargetPos = position})
        self.EventQuene:CreateMoveEvent(self,position)--:Push(move)
    end
end

function SimplifiedCharacter:CanMoveTo(targetPos)
    return (self:GetGroundHeight(targetPos)>cfg.map.Scene.HEIGHTMAP_MIN)
end


function SimplifiedCharacter:Death(b)
end

function SimplifiedCharacter:Revive()
end
function SimplifiedCharacter:SetLoverName(name)
    self.m_LoverName = name
    if self.m_HeadInfo then
        self.m_HeadInfo:OnChangeTitle()
    end
end

function SimplifiedCharacter:IsWorkState(workType)
    if self.WorkMgr then
        return self.WorkMgr:IsWorking(workType)
    end
    return false
end


function SimplifiedCharacter:IsIdle()
    return self:IsWorkState(WorkType.Idle)
end

function SimplifiedCharacter:IsDead()
    return self:IsWorkState(WorkType.Dead)
end

function SimplifiedCharacter:IsMoving()
    if self.m_Mount then
        return self.m_Mount:IsMoving()
    else
        return self:IsWorkState(WorkType.Move) or self:IsWorkState(WorkType.Fly)
    end
end


function SimplifiedCharacter:IsRelive()
    return self:IsWorkState(WorkType.Relive)
end


function SimplifiedCharacter:HaveRelationshipWithRole()
    if self:IsRole() then
        return true
    elseif self:IsPlayer() then
        return TeamManager.IsTeamMate(self.m_Id)
    elseif self:IsPet() then
        local master = self:GetMaster()
        if master then
            return TeamManager.IsTeamMate(master.m_Id)
        end
    end
    return false
end

function SimplifiedCharacter:AddState(state)
    self.m_State = bit.bor(self.m_State, state)
end

function SimplifiedCharacter:RemoveState(state)
    self.m_State = bit.band(self.m_State, bit.bnot(state))
end

function SimplifiedCharacter:HasState(state)
    return bit.band(self.m_State, state) == state
end

function SimplifiedCharacter:IsPet()
    return bit.band(self.m_Type, CharacterType.Pet) > 0
end

function SimplifiedCharacter:IsPlayer()
    return bit.band(self.m_Type, CharacterType.Player) > 0 or bit.band(self.m_Type, CharacterType.PlayerRole) > 0
end

function SimplifiedCharacter:IsMineral()
    return false
end

function SimplifiedCharacter:IsMonster()
    return false
end

function SimplifiedCharacter:IsRole()
    return false
end

function SimplifiedCharacter:IsBoss()
    return false
end

function SimplifiedCharacter:IsDropItem()
    return false
end

function SimplifiedCharacter:IsMount()
    return false
end

function SimplifiedCharacter:IsNpc()
    return false
end

function SimplifiedCharacter:GetPower()
    return self.m_Power
end

function SimplifiedCharacter:GetId()
    return self.m_Id
end

function SimplifiedCharacter:GetCsvId()
    return self.m_CsvId
end

function SimplifiedCharacter:GetName()
    return self.m_Name
end

function SimplifiedCharacter:GetLevel()
    return self.m_Level
end

function SimplifiedCharacter:ChangeLevel(level)
    self.m_Level = level
end

function SimplifiedCharacter:GetParentModelData(modeldata)
    if modeldata then
        --return self.m_ModelData.headicon
        local model =  ConfigManager.getConfigData("modelactions",modeldata.modelname)
        if model~=nil then
            return ConfigManager.getConfigData("model",model.basemodelname)
        end
    end
    return nil
end
--头像
function SimplifiedCharacter:GetHeadIcon()
    local modeldata = self.m_ModelData
    while modeldata~=nil do
        if modeldata.headicon ~=nil and modeldata.headicon ~="" then
            return modeldata.headicon
        end
        modeldata = self:GetParentModelData(modeldata)
    end
    return ""
end
--半身像
function SimplifiedCharacter:GetPortrait()
    local modeldata = self.m_ModelData
    while modeldata~=nil do
        if modeldata.portrait ~=nil and modeldata.portrait ~="" then
            return modeldata.portrait
        end
        modeldata = self:GetParentModelData(modeldata)
    end
    return ""
end

function SimplifiedCharacter:GetBodyRadius()
    if self.m_ModelData~=nil then
        return self.m_ModelData.bodyradius or 0
    end
    return 0
end


function SimplifiedCharacter:Hide(hideHP)
    --printyellow("hide",tostring(hideHP))
    if self.m_HeadInfo and hideHP then
        self.m_HeadInfo:Hide()
    else
        if self.m_Object ~= nil then
            self.m_Object:SetActive(false)
        end
    end
end

function SimplifiedCharacter:IsShowObj()
    if self.m_Object and self.m_Object.activeSelf then return true end
    return false
end

function SimplifiedCharacter:IsShowHp()
    if self.m_HpBar and self.m_HpBar.activeSelf then return true end
    return false
end

function SimplifiedCharacter:Show()
    if self.m_Object ~= nil then
        self.m_Object:SetActive(true)
    end
    if self.m_HeadInfo then
        self.m_HeadInfo:Show()
    end

--self.m_TalismanController.m_Object
end


function SimplifiedCharacter:InitState(fightercommon,bLoadMap)
    if fightercommon.isdead~=0 then
        self.m_IsDead = true
        self:Death(true)
    end
    if fightercommon.isrevive~=0 then
        self.m_Revive = true
        self:Revive()
    end
    if fightercommon.position and fightercommon.targetposition then
        if mathutils.DistanceOfXoY(fightercommon.position, fightercommon.targetposition) > 0.5 then
            self.m_TransformSync:SyncMoveTo({position = fightercommon.position, target = fightercommon.targetposition,isplayercontrol = 0})
        end
    end
end

function SimplifiedCharacter:PlayAction()

end

function SimplifiedCharacter:IsPlayingAction()
    return false
end

function SimplifiedCharacter:RedName(b)
    if b then
        self:ShowName(LocalString.UnderGroundText.RedNameColor .. self.m_Name .. LocalString.PartnerText.ColorSuffix)
    else
        self:ShowName()
    end
    if self:IsPlayer() and not self:IsRole() then
        local pets = CharacterManager.GetPlayerPets(self)
        for _,pet in pairs(pets) do
            pet:RedName(b)
        end
    end
end

function SimplifiedCharacter:ChangePKState(state)
    self.m_PKState = state
    if self:IsPlayer() or self:IsPet() then
        if CharacterManager.CanAttack(self) then
            self:RedName(true)
        else
            self:RedName(false)
        end
    end
end

function SimplifiedCharacter:ShowName(name)
    if self.m_HeadInfo then
        self.m_HeadInfo:ShowName(name)
    end
end


function SimplifiedCharacter:IsInCamera()
    if self.m_Object ~=nil then
        return LuaHelper.IsInCamera(self.m_Object.transform.position)
    end
    return false
end

function SimplifiedCharacter:IsVisiable()
    return self.m_Visiable
end

function SimplifiedCharacter:SetVisiable(visiable)
    --printyellow("SimplifiedCharacter:SetVisiable(visiable) begin",self.m_Id)
    if IsNull(self.m_Object) or self.m_Renderers == nil  or self.m_Renderers.Length == 0 then
        return
    end
    --printyellow("SimplifiedCharacter:SetVisiable(visiable)",self.m_Visiable,visiable)
    if self.m_Visiable ~= visiable then
        self.m_Visiable = visiable
        --printyellow("renderers SetActive",self.m_Id,self.m_Visiable)
        for i=1,self.m_Renderers.Length do
            --printyellow("renderers SetActive",self.m_Visiable)
            self.m_Renderers[i].gameObject:SetActive(self.m_Visiable)
        end
    end
end


function SimplifiedCharacter:OnBeAttacked()

end

function SimplifiedCharacter:RegisterOnLoaded(func)
    self.m_OnLoaded = func
end

function SimplifiedCharacter:AddEffect(effect)
    if effect.istransient then
        self.m_Effects[effect.id] = effect
    end
end

function SimplifiedCharacter:RemoveEffect(effectid)
    self.m_Effects[effectid] = nil
end

function SimplifiedCharacter:ClearEffect()
    self.m_Effects = {}
end

function SimplifiedCharacter:IsSimplified()
    return true
end

function SimplifiedCharacter:IsJumping()
    return false
end

function SimplifiedCharacter:IsPlayingRun()
    return true
end

function SimplifiedCharacter:PlayLoopAction()

end

function SimplifiedCharacter:IsPlayingStand()
    return false
end

function SimplifiedCharacter:OnSkillPerform()

end

function SimplifiedCharacter:BreakSkill()

end

function SimplifiedCharacter:HideHeadInfo()
    if self.m_HeadInfo then
        printyellow("self.m_Name",self.m_Name)
        self.m_HeadInfo:Hide()
    end
end


function SimplifiedCharacter:HeadActive(b)
    if self.m_HeadInfo then
        self.m_HeadInfo:HeadActive(b)
    end
end


function SimplifiedCharacter:IsActive()
    return false
end

function SimplifiedCharacter:SetActive(active)
end

return SimplifiedCharacter
