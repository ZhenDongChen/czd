local unpack            = unpack
local print             = print
local format            = string.format
local math              = math
local EventHelper       = UIEventListenerHelper
local uimanager         = require("uimanager")
local network           = require("network")
local ConfigManager     = require"cfg.configmanager"
local PrologueManager = require"prologue.prologuemanager"
local RideManager=require"ui.ride.ridemanager"
local fields
local gameObject
local name
local PlayerRole

local isAutoFight
local CurrentSkillGroup = 1
local CanDragg          = false
local Delta             = 20

local Rotate0           = Vector3(0,0,0)
local Rotate180         = Vector3(0,0,180)
local RotateNegative180 = Vector3(0,0,-180)
local TeamManager       = require("ui.team.teammanager")
local AutoAI

local cfgMap

local CdItems = {}


local function SetAutoFightState(isAutoFight)
    uimanager.call("dlguimain","SetAutoFightSprite",isAutoFight)
    fields.UISprite_FightingIcon.gameObject:SetActive(isAutoFight)
	fields.UISprite_Normal.gameObject:SetActive(not isAutoFight)
    AutoAI.Start(isAutoFight)
end

local function IsAutoFight()
    return isAutoFight and isAutoFight or false
end

		
local function SwitchAutoFight(b)
	
    if type(b) ~= "nil" then
        isAutoFight = b
    else
        isAutoFight = not isAutoFight
    end
    if isAutoFight == false then
        SetAutoFightState(false)
    else
        if PlayerRole:Instance():IsRiding() then
            PlayerRole:Instance():CancelRiding({downToAutoFight=true})
        else
            SetAutoFightState(true)
        end
        TeamManager.RequestCancelFollowing(true)
    end
end


local function SetSkillsEnable(b)
	print("SetSkillsEnable")
    for i=0,fields.UIList_Skill.Count-1 do
        local item = fields.UIList_Skill:GetItemByIndex(i)
        item.Enable = b
    end
    fields.UIButton_TreasureSkill.isEnabled = b
end

local function SetAttackEnable(b)
    fields.UIButton_NormalSkill.isEnabled = b
end

local function SetItemEnable(b)
    fields.UIButton_HPTips.isEnabled = b
end


local function ClearData()
    SwitchAutoFight(false)
end



local function SetCurrentSkillGroup(groupid)
    CurrentSkillGroup = groupid
end

local function DragSkillGroup(draggroup,dragup)
    if CurrentSkillGroup == draggroup then
        if draggroup == 1 then
            if dragup then
                fields.TweenRotation_Skill.from =Rotate180
                fields.TweenRotation_Skill.to = Rotate0
            else
                fields.TweenRotation_Skill.from = RotateNegative180
                fields.TweenRotation_Skill.to = Rotate0
            end
        else
            if dragup then
                fields.TweenRotation_Skill.from = Rotate0
                fields.TweenRotation_Skill.to = RotateNegative180
            else
                fields.TweenRotation_Skill.from = Rotate0
                fields.TweenRotation_Skill.to = Rotate180
            end
        end
        fields.TweenRotation_Skill.transform.localEulerAngles = fields.TweenRotation_Skill.from
        fields.TweenRotation_Skill:ResetToBeginning()
        fields.TweenRotation_Skill:PlayForward()
        SetCurrentSkillGroup(mathutils.TernaryOperation(CurrentSkillGroup==1,2,1))
    end
end

local function RefreshSkillList()
     CdItems ={} --{index:{playerskilldata,cd,slider}}
     local hasskillgroup1 = false
     local hasskillgroup2 = false
     for i = 0,fields.UIList_Skill.Count -1 do
        local item  = fields.UIList_Skill:GetItemByIndex(i)
        local playerskilldata = PlayerRole:Instance().PlayerSkill:GetPlayerSkillByIndex(i+1)
        if playerskilldata then
            CdItems[i+1] = {playerskilldata = playerskilldata,cd = -1,slider = item.Controls["UISlider_CD"] }
            item.Id = playerskilldata:GetCurrentSkill().skillid
            item.gameObject:SetActive(true)
            item:SetIconTexture(playerskilldata:GetCurrentSkill():GetSkillIcon())
            if i <=2 then hasskillgroup1 = true else hasskillgroup2 = true end
        else
            item.Id  =0
            item.gameObject:SetActive(false)
            item:SetIconTexture("null")
        end

    end

    CanDragg = hasskillgroup1 and hasskillgroup2

    if not CanDragg then
        if CurrentSkillGroup == 1 and not hasskillgroup1 and hasskillgroup2 or
           CurrentSkillGroup == 2 and  hasskillgroup1 and not hasskillgroup2 then
            DragSkillGroup(CurrentSkillGroup,true)
        end
    end
    --fields.UIButton_Right.gameObject:SetActive(CanDragg)
    --fields.UIButton_Left.gameObject:SetActive(CanDragg)

    if PlayerRole:Instance().m_TalismanController then
        if PlayerRole:Instance().m_TalismanController:GetInitiativeSkill() then
            fields.UIButton_TreasureSkill.gameObject:SetActive(true)
            local playerskilldata = PlayerRole:Instance().PlayerSkill:GetPlayerSkillByIndex(-1)
            if playerskilldata then
                CdItems[-1] = {playerskilldata = playerskilldata,cd = -1,slider = fields.UISlider_TCD }
                fields.UITexture_TreasureSkill:SetIconTexture(playerskilldata:GetCurrentSkill():GetSkillIcon())
            else
                fields.UITexture_TreasureSkill:SetIconTexture("null")
            end
        else
            fields.UIButton_TreasureSkill.gameObject:SetActive(false)
        end
    end

    local playerskilldata = PlayerRole:Instance().PlayerSkill:GetPlayerSkillByIndex(0)
    if playerskilldata then
        fields.UITexture_Attack:SetIconTexture(playerskilldata:GetCurrentSkill():GetSkillIcon())
    else
        fields.UITexture_Attack:SetIconTexture("null")
    end

end


local function GetSkillItemPos(skillId)
    local index=-1
    local pos=fields.UIGroup_SkillArea.transform.localPosition
    local posIndex
    --local offsetX=100
    --local offsetY=100
    for i = 0, fields.UIList_Skill.Count-1 do
        local item  = fields.UIList_Skill:GetItemByIndex(i)
        if item.Id==skillId then
            index=i
            posIndex=index
            if((index<=2) and (CurrentSkillGroup==1)) or ((index>2)and(CurrentSkillGroup==2)) then
                if (index==0) then
                    if (math.floor(fields.TweenRotation_Skill.transform.eulerAngles.z)==180) or (math.floor(fields.TweenRotation_Skill.transform.eulerAngles.z)==-180) then
                        pos=item.transform.position
                    else
                        pos=nil
                    end
                else
                    pos=item.transform.position
                end
            else
                if (CurrentSkillGroup==1) then
                    local tempItem=fields.UIList_Skill:GetItemByIndex(index-3)
                    if (tempItem) then
                        pos=tempItem.transform.position
                    end
                    DragSkillGroup(CurrentSkillGroup,true)
                elseif(CurrentSkillGroup==2) then
                    local tempItem=fields.UIList_Skill:GetItemByIndex(index+3)
                    if (tempItem) then
                        pos=tempItem.transform.position
                    end
                    DragSkillGroup(CurrentSkillGroup,false)
                end
            end
            --pos=Vector3(pos.x+((posIndex%3)-1)*offsetX,pos.y+((posIndex%3)-1)*offsetY,0)
            break
        end
    end
    return pos
end

local function SetRidingState(bRiding)
	--todo:xbq 为什么 UISprite_GetDown总是一登录就出来？
	--if true then return end 
	
    local UISprite_GetDown = fields.UISprite_GetDown
    local UISprite_Riding = fields.UISprite_Riding

	UISprite_Riding.gameObject:SetActive(true)
	UISprite_GetDown.gameObject:SetActive(false)
	
	if bRiding then
		UISprite_Riding.flip = 2
	else
		UISprite_Riding.flip = 0
	end
	
	printyellow("SetRidingState:"..tostring(bRiding))
end

local function RefreshRidingState()
    --local UISprite_GetDown = fields.UISprite_GetDown
--    local UISprite_Riding = fields.UISprite_Riding
--    local UISprite_Up = fields.UISprite_Up
--    local UISprite_Down = fields.UISprite_Down
    --local UISprite_SelectTarget=fields.UISprite_SelectTarget
--    local UISprite_Jump=fields.UISprite_Jump
    if PlayerRole==nil then
		return 
	end

	local bRiding=PlayerRole:Instance():IsRiding() 
	
	SetRidingState(bRiding)
	
	
    if bRiding then
        --UISprite_Riding.gameObject:SetActive(false)
        local SceneManager=require"scenemanager"
		--[[
        if SceneManager.HasSkyHeight()==true then
            UISprite_Up.gameObject:SetActive(true)
            UISprite_SelectTarget.gameObject:SetActive(false)
            if PlayerRole:Instance():IsFlying() then
                UISprite_Jump.gameObject:SetActive(false)
                UISprite_Down.gameObject:SetActive(true)
            else
                UISprite_Jump.gameObject:SetActive(true)
                UISprite_Down.gameObject:SetActive(false)
            end
        else
			]]
        --UISprite_Riding.gameObject:SetActive(false)
        --UISprite_GetDown.gameObject:SetActive(true)
            --UISprite_Up.gameObject:SetActive(false)
            --UISprite_Down.gameObject:SetActive(false)
            --UISprite_SelectTarget.gameObject:SetActive(true)
            --UISprite_Jump.gameObject:SetActive(true)
        --end
    else
        --UISprite_Riding.gameObject:SetActive(true)
        --UISprite_GetDown.gameObject:SetActive(false)
        --UISprite_Up.gameObject:SetActive(false)
        --UISprite_Down.gameObject:SetActive(false)
        --UISprite_SelectTarget.gameObject:SetActive(true)
        --UISprite_Jump.gameObject:SetActive(true)
    end
end



local function NotifyAttackComplete(playerskilldata)
    if fields and fields.UIButton_NormalSkill and UICamera.IsPressed(fields.UIButton_NormalSkill.gameObject) then
        PlayerRole:Instance().m_RoleSkillFsm:OnButtonCastSkill(0)
    end
end

local function RefreshPKStateIcon()
    if not cfgMap[PlayerRole.Instance():GetMapId()].allowpk then
        fields.UISprite_PKType.spriteName = fields.UISprite_Peace.spriteName
        return
    end
    local state = PlayerRole.Instance().m_PKState
    if state == cfg.fight.PKState.PEACE then
        fields.UISprite_PKType.spriteName = fields.UISprite_Peace.spriteName
    elseif state == cfg.fight.PKState.FAMILY_AND_TEAM then
        fields.UISprite_PKType.spriteName = fields.UISprite_Family.spriteName
    elseif state == cfg.fight.PKState.TEAM then
        fields.UISprite_PKType.spriteName = fields.UISprite_Team.spriteName
    end
end

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    SwitchAutoFight(isAutoFight)
end

local function hide()
    -- print(name, "hide")
end

local function update()

    for index,data in pairs(CdItems) do
        local currentcd = data.playerskilldata:GetCDRatio()
        if currentcd ~= data.cd then
            data.slider.value = currentcd
            data.cd = currentcd
        end
    end

end

local function refreshPKMode(pkMode)
    if pkMode ==  cfg.fight.PKState.PEACE then
        fields.UIToggle_Peace:Set(true)
    elseif    pkMode ==  cfg.fight.PKState.FAMILY_AND_TEAM then
        fields.UIToggle_Family:Set(true)
    else
        fields.UIToggle_Team:Set(true)
    end
end

local function refresh(params)
    if uimanager.isshow("dlguimain") then
        RefreshSkillList()
        --RefreshRidingState()
    end
end


local function EnterEctype()
    if PrologueManager.IsInPrologue() then
        fields.UIButton_HPTips.gameObject:SetActive(false)
        return
    end
end

local function LeaveEctype()
    fields.UIButton_FightAuto.gameObject:SetActive(true)
    fields.UIButton_HPTips.gameObject:SetActive(true)
end


local function ShowSkillTips(text)

    fields.UILabel_SkillTips.text = text
    fields.UIPlayTweens_SkillLoading:Play(true)
end


local function RequestSendPKState(state)
    if state == PlayerRole.Instance().m_PKState then return end
    --if state == cfg.fight.PKState.PEACE then
        if PlayerRole.Instance().m_IsFighting then
            uimanager.ShowSingleAlertDlg{content=LocalString.ChangeFightModeInFighting}
        else

            network.send(lx.gs.map.msg.CSetPKState({worldid = PlayerRole.Instance():GetMapId(),pkstate=state}))
        end
    --else
    --
    --    network.send(lx.gs.map.msg.CSetPKState({worldid = PlayerRole.Instance():GetMapId(),pkstate=state}))
    --end

end

local function OnButton_Ride()
	print("OnButton_Ride")
    if PrologueManager.IsInPrologue() then
        -- printyellow("[dlguimain_combat:OnButton_Ride] OnButton_Ride clicked.")
         local NoviceGuideTrigger=require"noviceguide.noviceguide_trigger"
         NoviceGuideTrigger.ClickUIObject(fields.UIButton_Ride.transform)
         if PrologueManager.IsGuidingFly() then
            PrologueManager.NavToFlyPosition()
         end
    else
--        local UISprite_GetDown = fields.UISprite_GetDown
--        local UISprite_Riding = fields.UISprite_Riding
--        local UISprite_Up = fields.UISprite_Up
        if PlayerRole:Instance():IsRiding() then
            if PlayerRole:Instance():CanLand() then
                PlayerRole:Instance().m_UnLoadMount=true
                PlayerRole:Instance():CancelRiding()
            else
                uimanager.ShowSystemFlyText(LocalString.Ride_CanNotLand)
            end
        else
            if PlayerRole:Instance():CanRide() then
                if PlayerRole:Instance().m_MountType == cfg.equip.RideType.NONE then
                    
                    local rideId=RideManager.GetActivedRide()
                    if rideId then
                        --local mountId = PlayerRole:Instance().m_MountId
                        
                        RideManager.Ride(rideId, cfg.equip.RideType.WALK)
                    else			
                        uimanager.ShowSingleAlertDlg({ content = LocalString.Ride_NotActived, callBackFunc=function()
                           uimanager.showdialog("ride.dlgridedisplay")
                        end})
                    end
                end
            else
                --if (PlayerRole:Instance():IsBeAttacked()) or (PlayerRole:Instance():IsAttacking()) or (PlayerRole:Instance().m_IsFighting) or (IsAutoFight()) then
                    uimanager.ShowSystemFlyText(LocalString.Ride_Battleing)
                --end
            end
        end
    end
end
local function init(iName,iGameObject,iFields)
    name            = iName
    gameObject      = iGameObject
    fields          = iFields
	PlayerRole      = require "character.playerrole"
    RoleSkill       = require "character.skill.roleskill"
	AutoAI          = require "character.ai.autoai"
	cfgMap          = ConfigManager.getConfig("worldmap")
	isAutoFight     = false
    fields.UIPlayTweens_SkillLoading.gameObject:SetActive(false)
	fields.UISprite_FightingIcon.gameObject:SetActive(false)
    EventHelper.SetPress(fields.UIButton_NormalSkill, function(go, bPress)
        if TeamManager.IsForcedFollow() ~= true then
            if PlayerRole:Instance():IsRiding() then
                PlayerRole:Instance():CancelRiding({downToAttack=0})
                return
            end
            TryToNormalAttack = bPress
            if bPress then
                PlayerRole:Instance().m_RoleSkillFsm:OnButtonCastSkill(0)
                TeamManager.RequestCancelFollowing()
            end
        end
    end )

    --EventHelper.SetListDrag(fields.UIList_Skill, function(item,delta)
    --    if CanDragg then
    --        local delta = UICamera.currentTouch.totalDelta
    --        local groupid = mathutils.TernaryOperation(item.Index >2,2, 1)
    --        if delta.x >Delta and delta.y >Delta then
    --           DragSkillGroup(groupid,true)
    --        elseif delta.x <-Delta and delta.y <-Delta then
    --           DragSkillGroup(groupid,false)
    --        end
    --    end
    --
    --end )

    EventHelper.SetListClick(fields.UIList_Skill, function(item)

        if TeamManager.IsForcedFollow() ~= true then  --��ǿ�Ƹ���
            if PlayerRole:Instance():IsRiding() then
                PlayerRole:Instance():CancelRiding({downToAttack=item.Index+1})
                return
            end
            PlayerRole:Instance().m_RoleSkillFsm:OnButtonCastSkill(item.Index+1)
            TeamManager.RequestCancelFollowing()
        end
    end )
	
	 EventHelper.SetClick(fields.UIButton_FightAuto, function()
        --if (TeamManager.IsForcedFollow() ~= true) then  --��ǿ�Ƹ���
            SwitchAutoFight()
        --end
    end )
    
    EventHelper.SetClick(fields.UIButton_TreasureSkill, function()

        if TeamManager.IsForcedFollow() ~= true then
            if PlayerRole:Instance():IsRiding() then
                PlayerRole:Instance():CancelRiding({downToAttack=-1})
                return
            end
            PlayerRole:Instance().m_RoleSkillFsm:OnButtonCastSkill(-1)
        end
    end)

    EventHelper.SetPress(fields.UIButton_SelectTarget, function(go, bPress)
        local SceneManager=require"scenemanager"
        if (PlayerRole:Instance().m_Mount) and(PlayerRole:Instance().m_Mount:IsAttach()) then --and (SceneManager.HasSkyHeight()==true) then
            PlayerRole:Instance().m_Mount:moveup(bPress)
        end
    end )

    EventHelper.SetClick(fields.UIButton_FightAuto, function()
        if (TeamManager.IsForcedFollow() ~= true) then  --��ǿ�Ƹ���
            SwitchAutoFight()
        end
	end )
	EventHelper.SetClick(fields.UIButton_PKType,function()
        if cfgMap[PlayerRole.Instance():GetMapId()].allowpk then
            local cfgRole = ConfigManager.getConfig("roleconfig")
            if cfgRole.pkinfo.level.level > PlayerRole.Instance().m_Level then
                uimanager.call("dlgflytext","AddSystemInfo",string.format(LocalString.UnderGroundText.PKLevelLimit,cfgRole.pkinfo.level.level))
            else
                if fields.UIGroup_PK.gameObject.activeSelf then
                    fields.UIGroup_PK.gameObject:SetActive(false)
                else
                    fields.UIGroup_PK.gameObject:SetActive(true)
                end
            end
        else
            uimanager.call("dlgflytext","AddSystemInfo",LocalString.UnderGroundText.PeaceMap)
        end
        refreshPKMode(PlayerRole.Instance().m_PKState)
    end)
	
	
    EventHelper.SetClick(fields.UIToggle_Peace,function()
        fields.UIGroup_PK.gameObject:SetActive(false)
		if  not PlayerRole.Instance().m_IsFighting then
			  fields.UISprite_PKType.spriteName = fields.UISprite_Peace.spriteName
		else
			 -- fields.UIList_FactionSelect:SetSelectedIndex(0)
           -- refreshPKMode(PlayerRole.Instance().m_PKState)
		end
       

        RequestSendPKState(cfg.fight.PKState.PEACE)
    end)

    EventHelper.SetClick(fields.UIToggle_Family,function()
        fields.UIGroup_PK.gameObject:SetActive(false)
        if  not PlayerRole.Instance().m_IsFighting then
            fields.UISprite_PKType.spriteName = fields.UISprite_Family.spriteName
        else
            --refreshPKMode(PlayerRole.Instance().m_PKState)
        end
        -- fields.UISprite_PKType.spriteName = fields.UISprite_Family.spriteName
        RequestSendPKState(cfg.fight.PKState.FAMILY_AND_TEAM)
    end)

    EventHelper.SetClick(fields.UIToggle_Team,function()
        fields.UIGroup_PK.gameObject:SetActive(false)
        if  not PlayerRole.Instance().m_IsFighting then
            fields.UISprite_PKType.spriteName = fields.UISprite_Team.spriteName
        else
           -- refreshPKMode(PlayerRole.Instance().m_PKState)
        end
         --fields.UISprite_PKType.spriteName = fields.UISprite_Team.spriteName
        RequestSendPKState(cfg.fight.PKState.TEAM)
    end)

    EventHelper.SetClick(fields.UISprite_PKBlack,function()
        fields.UIGroup_PK.gameObject:SetActive(false)
    end)
	
    gameevent.evt_system_message:add("logout",ClearData)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    SwitchAutoFight = SwitchAutoFight,
    SetSkillsEnable = SetSkillsEnable,
    SetAttackEnable = SetAttackEnable,
	SetItemEnable = SetItemEnable,
	NotifyAttackComplete = NotifyAttackComplete,
	DragSkillGroup = DragSkillGroup,
	LeaveEctype = LeaveEctype,
	EnterEctype = EnterEctype,
	ShowSkillTips = ShowSkillTips,
	SetAutoFightState = SetAutoFightState,
	RefreshPKStateIcon = RefreshPKStateIcon,
	IsAutoFight        = IsAutoFight,
    GetSkillItemPos = GetSkillItemPos,
--	SetRidingState = SetRidingState,
    RefreshRidingState = RefreshRidingState,
	
	OnButton_Ride=OnButton_Ride,
	
}
