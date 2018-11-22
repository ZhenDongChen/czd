local SceneMgr=require "scenemanager"
local Character=require "character.character"
--local Navigation=require "character.navigation.navigation"
local DefineEnum=require "defineenum"
local WorkType = DefineEnum.WorkType
local CharacterType=DefineEnum.CharacterType
local CharState=DefineEnum.CharState
local MountType=DefineEnum.MountType
local CharacterMgr="character.charactermanager"
local RideManager=require"ui.ride.ridemanager"
local PlayerRole=require("character.playerrole"):Instance()
local NetWork=require "network"
local Mount=Class:new(Character)
local MathUtils = require "common.mathutils"
local MountTransformSync     = require "character.transformsync.mounttransformsync"


local EctypeManager

local DISTANCE=4.5
local HEIGHT_ERROR=-7.5
local HEIGHT_DIF=10

function Mount:__new()
    EctypeManager = require"ectype.ectypemanager"
    Character.__new(self)
    self.m_Type=CharacterType.Mount
    self.m_Attach=false
    self.m_ReCalTime=0

    self.m_LastMoveTime         = 0
    self.m_LastMoveDir          = Vector3.up
    self.m_LastMovePos          = Vector3(0,0,0)
    self.m_MoveMessageCache     = {}
end

function Mount:CreateTransformSync()
    return MountTransformSync:new(self)
end

function Mount:update()
    Character.update(self)
    if self.m_Player.m_Object and self.m_Player:IsRole() then
        if self.m_Attach then         --已绑定
            --self.m_Navigation:Update()
            local m_MountState=self.m_MountState
            if self.m_FlyNav==true then
			--[[
                local position=self:GetRefPos()
                local nextPos=position + self.m_FlyNavDir * self.m_FlySpeed * Time.deltaTime
                if MathUtils.DistanceOfXoY(nextPos, self.m_FlyNavTarget)>(self.m_FlySpeed * Time.deltaTime) and (MathUtils.DistanceOfXoY(position, self.m_FlyNavTarget)>(self.m_FlySpeed * Time.deltaTime)) then
                    local nextHeight=SceneMgr.GetHeight1(nextPos)
                    local heightDif=(position.y-nextHeight)
--                    printyellow("nextHeight:",nextHeight)
--                    printyellow("heightDif:",heightDif)
                    if heightDif<-2 then
--                        if heightDif>(-1) then
--                            nextHeight=position.y+1
--                        end
                        local target=Vector3(position.x,nextHeight,position.z)
                        if target~=self.m_NewTarget then
                            self.m_NewTarget=target
                            self:MoveUp(self.m_NewTarget)
                            --self:SendMove(self.m_NewTarget,self.m_AscendSpeed)
                        end
                    else                        
                        local target=Vector3(self.m_FlyNavTarget.x,position.y,self.m_FlyNavTarget.z)
                        if (target.x~=self.m_NewTarget.x) or (target.z~=self.m_NewTarget.z) then
                            self.m_NewTarget=target
                            self:MoveUp(self.m_NewTarget)
                            self:SendMove(self.m_NewTarget,self.m_FlySpeed)
                        end
                    end
                elseif self.m_FlyNavTarget.y<position.y then
                    local targetHeight=SceneMgr.GetHeight(self.m_FlyNavTarget)
                    if (self.m_Pos.y-targetHeight)>self.m_FlySpeed * Time.deltaTime then
                        self.m_FlyNavDown=true
                        local target=Vector3(self.m_FlyNavTarget.x,targetHeight+self.m_InitialHeightInRide,self.m_FlyNavTarget.z)
                        if target~=self.m_NewTarget then
                            self.m_NewTarget=target
                            self:MoveUp(self.m_NewTarget)
                            --self:SendMove(self.m_NewTarget,self.m_DescendSpeed)
                        end
                    else
                        self.m_FlyNavDown=false
                        self.WorkMgr:StopWork(WorkType.Fly)
                        self:SendStop()
                        if self.m_NavEndDir then
                            self:SetRotation(self.m_NavEndDir)
                        end
                        self.m_MountState=MountType.Ride
                        self:SendMountState(cfg.equip.RideType.WALK)
                        self:StopNavigate()
                        if self.m_NavCallBackFunc then
                            self.m_NavCallBackFunc()
                        end
                    end
                else
                    self.WorkMgr:StopWork(WorkType.Fly)
                    self:SendStop()
                    if self.m_NavEndDir then
                        self:SetRotation(self.m_NavEndDir)
                    end
                    self.m_FlyNav=false
                    if self.m_NavCallBackFunc then
                        self.m_NavCallBackFunc()
                    end
                end
			]]
            elseif m_MountState==MountType.Up then
                local newPos=self:GetRefPos()
                local height=SceneMgr.GetHeight(newPos)
                if (math.abs((newPos.y-height)-self.m_InitialHeightInFly)<0.2) or ((newPos.y-height)>=self.m_InitialHeightInFly) then
                    self.m_MountState=MountType.Fly
                    self:SendMountState(cfg.equip.RideType.FLY)
                    self.WorkMgr:StopWork(WorkType.Fly)
                    self:SendStop()
                    return
                end
            elseif m_MountState==MountType.Down or m_MountState==MountType.Land then
                local curPos=self:GetRefPos()
                local relativeheight=curPos.y-SceneMgr.GetHeight1(curPos)
                if m_MountState==MountType.Land and relativeheight<=0 then --着陆
                    self:SendMountState(cfg.equip.RideType.NONE)
                    --self:ResumePet()
                end
--          elseif m_MountState==MountType.ToPointLand then     --着陆点着陆
--             self.distancetolandpoint=self.distancetolandpoint+Time.deltaTime*self.landspeed
--             local height=self.height-self.m_DescendSpeed*Time.deltaTime
--             local target
--             if height<=self.m_InitialHeightInRide then
--                self.offsetY=self.m_InitialHeightInRide
--                self.height=self.m_InitialHeightInRide
--                target=self.landpoint
--             else
--                self.height=height
--                self.offsetY=height
--                target=Vector3:MoveTo(self.landpoint,self.distancetolandpoint)
--             end
--             self:MoveUp(target)
            elseif self.m_MountState==MountType.Fly then
--             if self.m_Flying and (not self.m_PressDown) and (not self.m_PressUp) then --自动由飞行转骑行状态
--                local newPos=self.Pos
--                local heightInMap=SceneMgr.GetHeight(newPos)
--                if (newPos.y-heightInMap)<=0 then
--                  self.m_Flying=false
--                  self.m_MountState=MountType.Ride
--                elseif (newPos.y-heightInMap)<=self.m_HeightLimit then
--                  self.m_Flying=false
--                  self.m_MountState=MountType.Down
--                end
--             end
                local curPos=self:GetRefPos()
                local heightInSky=SceneMgr.GetHeight1(curPos)
                local heightInGround=SceneMgr.GetHeight(curPos)
                
                if (self.m_PressUp) and (not self.m_Flying) then
                    self.m_ReCalTime=self.m_ReCalTime-Time.deltaTime
                    if self.m_ReCalTime<=0 then
                        local targetPos=curPos+(Vector3.up)*DISTANCE
                        local heightCeil=SceneMgr.GetFlyHeightCeil()
                        if (targetPos.y)>heightCeil then
                            targetPos.y=heightCeil
                        end
                        self:MoveUp(targetPos)
                        self:SendMove(targetPos,self.m_FlySpeed)
                        self.m_ReCalTime=0.1
                    end
                else                    
                    if (self.m_PressDown) then
                        if heightInSky and ((curPos.y-heightInSky)<=self.m_InitialHeightInRide) and (math.abs(heightInSky-heightInGround)<cfg.map.Scene.DIFFWITHGROUNDANDSKY) and (heightInGround>cfg.map.Scene.HEIGHTMAP_MIN) and self:CanLand() then
                            self.WorkMgr:StopWork(WorkType.Fly)
                            self:SendStop()
                            self.m_Flying=false
                            self.m_PressDown=false
                            self.m_PressUp=false
                            self.m_MountState=MountType.Ride
                            self:SendMountState(cfg.equip.RideType.WALK)
                            return
                        end
                        if (not self.m_Flying) then
                            self.m_ReCalTime=self.m_ReCalTime-Time.deltaTime
                            if self.m_ReCalTime<=0 then
                            local targetPos=curPos+(Vector3.down)*DISTANCE
                            if (targetPos.y)<self.m_HeightLimit then
                                targetPos.y=self.m_HeightLimit
                            elseif (targetPos.y-heightInSky)<=self.m_InitialHeightInRide then
                                targetPos=Vector3(curPos.x,self.m_InitialHeightInRide+heightInSky,curPos.z)
                            end
                            self:MoveUp(targetPos)
                            self:SendMove(targetPos,self.m_DescendSpeed)
                            self.m_ReCalTime=0.1
                            end
                        end
                    end
                end
                if heightInSky and (self.m_Player:IsRole()) and (self.m_FlyNav~=true) and (heightInSky<=cfg.map.Scene.HEIGHTMAP_MIN) then
                    local MapManager=require"map.mapmanager"
                    if MapManager.GetBornPos() then
                        self:SetPos(MapManager.GetBornPos())
                    end
                end
--                if self.m_StopDown then
--                    self.m_StopDown=false
--                    self.WorkMgr:StopWork(WorkType.Fly)
--                    self:SendStop()
--                    if self.m_Destroy then
--                        self.m_Destroy=false
--                        self:SendMountState(cfg.equip.RideType.NONE)
--                    end
--                end
--                local heightInMap=self:GetHeightInMap(self:GetPos())
--                if self.m_StopUp then
--                    self.WorkMgr:StopWork(WorkType.Fly)
--                    self:SendStop()
--                    self.m_StopUp=false
--                end
            elseif self.m_MountState==MountType.Ride then
--                if self.m_StopDown then
--                    self.m_StopDown=false
--                    self.WorkMgr:StopWork(WorkType.Fly)
--                    self:SendStop()
--                    if self.m_Destroy then
--                        self.m_Destroy=false
--                        self:SendMountState(cfg.equip.RideType.NONE)
--                    end
--                end
                local newPos=self:GetRefPos()   --自动由骑行转飞行状态
                local heightInMap=SceneMgr.GetHeight1(newPos)
                local heightInGround=SceneMgr.GetHeight(newPos)
                if heightInMap then
--                    printyellow("heightInMap:",heightInMap)
--                    printyellow("newPos:",newPos)
--                    printyellow("self.m_InitialHeightInFly:",self.m_InitialHeightInFly)
                    if ((heightInMap>0) and (heightInMap~=heightInGround) and (newPos.y-heightInMap)>=self.m_InitialHeightInFly) then
                        self.WorkMgr:StopWork(WorkType.Ride)
                        self:SendStop()
                        self.m_MountState=MountType.Fly
                        self:SendMountState(cfg.equip.RideType.FLY)
                        --local PetManager=require"character.pet.petmanager"
                        --PetManager.PassiveUnActivePet()
                    end
					
					--[[
                    if (self.m_Player:IsRole()) and ((heightInGround<=cfg.map.Scene.HEIGHTMAP_MIN) or (heightInMap<=cfg.map.Scene.HEIGHTMAP_MIN)) then
                        local MapManager=require"map.mapmanager"
                        if MapManager.GetBornPos() then
                            self:SetPos(MapManager.GetBornPos())
                        end
                    end
					]]
                end
            end
        end
    end
end

function Mount:OnLoaded(go)
	--shader不再需要程序设定，直接美术设置
    Character.OnLoaded(self,go)
	--[[
    if go and self.m_Player and self.m_Player:IsRole() then
        local skin=go.transform:Find(self.m_ModelPath)
        if skin then
            local meshRenderList=skin:GetComponentsInChildren(SkinnedMeshRenderer,true)
            for i=1,meshRenderList.Length do
                local smr=meshRenderList[i]
                for i=1,smr.materials.Length do
                    local mat = smr.materials[i]
                    mat.shader = Shader.Find("SuperPop/Character/PlayerRole_Normal")
                end
            end
        end
    end
	]]
	if self.m_Player ~= nil then
		self:SetPos(self.m_Player:GetPos())
	end
	
    self.m_MountState=MountType.Attaching
end
---ride
function Mount:init(id,player)
    local ConfigMgr=require "cfg.configmanager"
    local riding=ConfigMgr.getConfig("riding")
    local PropData = ConfigMgr.getConfigData("riding",id)
    self.m_PropData=PropData
    self.m_Id=id
    self.m_RoleAction = PropData.ridingmotion   --角色騎行動作
    self.m_InitialHeightInRide = PropData.initialheightinride  --初始骑行高度
    self.m_InitialHeightInFly = PropData.initialheightinfly --初始飞行高度
    self.m_AscendSpeed = PropData.upspeed  --初始上升速度
    self.m_DescendSpeed = PropData.downspeed --初始下降速度
    self.m_HeightLimit = PropData.initalminhigh --高度下限
    --self.m_HeightCeiling = PropData.initalmaxhigh  --高度上限
    self.m_RiggingPoint = PropData.riggingpoint   --骨骼绑定点
    self.m_FlySpeed = PropData.flyspeed   --飞行速度
    self.m_Attributes[cfg.fight.AttrId.MOVE_SPEED] = PropData.ridespeed     --骑行速度
    self.m_MountState = MountType.Ride --初始化为骑行状态
    self.m_StopUp = false
    self.m_Flying = false
    self.m_Player = player
    local ModelData =  ConfigManager.getConfigData("model",PropData.modelname)
    self:CriticalLoadModel({ModelData,ModelData,false})
    self.m_FlyNav = false
    self.m_Height_Error = HEIGHT_ERROR
    self.m_Height_Dif = HEIGHT_DIF
    self.m_Name = PropData.name
    self.m_PlayerRotation=PropData.rotation
end


function Mount:IsAttach()
	if self.m_Attach==nil then
		return false
	end
    return self.m_Attach
end

function Mount:SetAttach(tof)
    self.m_Attach=tof
end

--function Mount:SetPos(vecPos)
--    if vecPos== nil then return end
--    if self.m_MountState~=defineenum.MountType.Ride and self.m_MountState~=defineenum.MountType.Attaching then
--        if scenemanager.GetHeight1(vecPos)>cfg.map.Scene.HEIGHTMAP_MIN then
--            vecPos.y=scenemanager.GetHeight1(vecPos)+self.m_OffsetY
--        end
--    else
--        vecPos.y=vecPos.y+self.m_InitialHeightInRide
--    end
--    self.m_Pos = vecPos
--end

function Mount:Attaching()
    self.m_MountState=MountType.Attaching  --挂载状态
end

function Mount:SetOffsetY(offset)
    self.m_OffsetY=offset
end

function Mount:Remove()
    Character.remove(self)
end

function Mount:move(target)
    if self.m_Attach then
        if self.m_Object then
            if self.m_Player:IsRole() then
                self.m_FlyNavDown=false
                if self.m_MountState==MountType.Up or self.m_MountState==MountType.Down or self.m_MountState==MountType.Land then
                    self.m_Flying=false
                    return
                end
                if self.m_MountState==MountType.Ride then
                    self:MoveTo(target)
                    --self:SendMove(target,self.m_Attributes[cfg.fight.AttrId.MOVE_SPEED])
                elseif  self.m_MountState==MountType.Fly then
                    if self:CanFlyTo(target)==true then
                        self:StopNavigate()
                        self.m_Flying=true
                        self:MoveUp(target)
                        self:SendMove(target,self.m_FlySpeed)
                    end                   
                end
            else
                if self.m_MountState == MountType.Ride then
                    self:MoveTo(target)
                elseif self.m_MountState == MountType.Fly then
                    self.m_OffsetY=target.y
                    self:MoveUp(target)
                end
            end
        end
    end
end

--function Mount:CaloffsetY(target)
--    local heightInMap=SceneMgr.GetHeight1(target)
--    if self.m_PressUp then
--        local ascendheight,targetPosY=self:CalUpHeight(target)
--        if targetPosY>=self.m_HeightCeiling then
--            self.m_OffsetY=self.m_HeightCeiling-heightInMap
--        else
--            self.m_OffsetY=targetPosY-heightInMap
--        end
--    elseif self.m_PressDown then
--        local targetPosY=self:CalDownHeight(target)
--        if (targetPosY-heightInMap)<=self.m_HeightLimit then
--            self.m_OffsetY=self.m_HeightLimit
--            self.m_MountState=MountType.Down
--        else
--            self.m_OffsetY=targetPosY-heightInMap
--        end
--    else
--        self.m_OffsetY=self:GetPos().y-heightInMap
--    end
--end

function Mount:stop(delta)
    --printyellow("stop:MountType:",self.m_MountState)
    if self.m_Object then
        if self.m_MountState==MountType.Ride then
            self.WorkMgr:StopWork(WorkType.Move)
            self:SendStop()
        elseif self.m_MountState==MountType.Fly then
            self.m_Flying=false
            self.m_PressDown=false
            self.m_PressUp=false
            self.WorkMgr:StopWork(WorkType.Fly)
            self:SendStop()
        end
    end
end
--上升
function Mount:moveup(bPress)
    self.m_PressDown=false
    if self.m_MountState==MountType.Up or self.m_MountState==MountType.Down or self.m_MountState==MountType.Land then
        return
    end
    local curPos=self:GetRefPos()
    local heightInMap=SceneMgr.GetHeight1(curPos)    
    if self:IsNavigating() then
        if (self.m_FlyNav==true) then
            if ((heightInMap==nil) or (heightInMap<=cfg.map.Scene.HEIGHTMAP_MIN)) then
                local UIManager=require"uimanager"
                UIManager.ShowSystemFlyText(LocalString.Ride_Battleing)
                return
            end
        else
            local UIManager=require"uimanager"
            UIManager.ShowSystemFlyText(LocalString.Ride_Battleing)
            return
        end
    end
    self:StopNavigate()
    if not bPress then
        self.m_PressUp=false
        self.WorkMgr:StopWork(WorkType.Fly)
        self:SendStop()
        return
    end
    self.m_PressUp=true
    local pos=self:GetRefPos()
    local heightCeil=SceneMgr.GetFlyHeightCeil()
    if pos.y>heightCeil then
        self.WorkMgr:StopWork(WorkType.Fly)
        self:SendStop()
        return
    end
    local heightInGround=SceneMgr.GetHeight(curPos)
    local relativeHeight=heightInGround-heightInMap
    local relativeGroundHeight=curPos.y-heightInMap
    if (self.m_MountState == MountType.Ride) then
        if (relativeGroundHeight<self.m_InitialHeightInFly) and (relativeHeight>=-(cfg.map.Scene.DIFFWITHGROUNDANDSKY)) then
            self:stop()
            self.m_MountState=MountType.Up
            self.m_PressUp=false
            self:SendMountState(cfg.equip.RideType.FLY)
            --local PetManager=require"character.pet.petmanager"
            --PetManager.PassiveUnActivePet()
            local targetPos=curPos+(Vector3.up)*(self.m_InitialHeightInFly)
            self:MoveUp(targetPos)
           -- self:SendMove(targetPos,self.m_FlySpeed)
        else
            local UIManager=require"uimanager"
            UIManager.ShowSystemFlyText(LocalString.Ride_CanNotLand)
        end
    else
        self.m_ReCalTime=0
    end
end

--function Mount:CalUpHeight(target)
--    local ascendHeight=0
--    ascendHeight=(Time.deltaTime)*(self.m_AscendSpeed)
--    local targetPosY=target.y+ascendHeight
----  printyellow("CalUpheight:ascendHeight:",ascendHeight)
----  printyellow("CalUpheight:targetPosY:",targetPosY)
--    return ascendHeight,targetPosY
--end

function Mount:MoveUp(position)
   -- printyellow("MoveUp:position",position)
--    printyellow("MOVEUP self.pos:",self:GetPos())
   -- printyellow("MOVEUP height:",SceneMgr.GetHeight1(position))
    local Event=require "character.event.event"
    local fly = Event.FlyEvent:new(self, {TargetPos = position})
    self.EventQuene:Push(fly)
end

--下降
function Mount:movedown(bPress)
    --printyellow("Mount:movedown:bPress",bPress)
    self.m_PressUp=false
    if self.m_MountState==MountType.Ride or self.m_MountState==MountType.Down or self.m_MountState==MountType.Up or self.m_MountState==MountType.Land then
        return
    end
    if self:IsNavigating() then
        if (self.m_FlyNav==true) then
            local skyHeight=SceneMgr.GetHeight1(self:GetRefPos())
            if ((skyHeight==nil) or (skyHeight<=cfg.map.Scene.HEIGHTMAP_MIN)) then
                local UIManager=require"uimanager"
                UIManager.ShowSystemFlyText(LocalString.Ride_Battleing)
                return
            end
        else
            local UIManager=require"uimanager"
            UIManager.ShowSystemFlyText(LocalString.Ride_Battleing)
            return
        end
    end
    self:StopNavigate()
    if not bPress then
        self.m_PressDown=false
        self.WorkMgr:StopWork(WorkType.Fly)
        self:SendStop()
        return
    end
    
    self.m_PressDown=true
    self.m_ReCalTime=0
end

--function Mount:CalDownHeight(target)  --计算下降高度
--    local descendHeight=0
--    descendHeight=(Time.deltaTime)*(self.m_DescendSpeed)
----  local targetHeight=self.height-descendHeight
----  return targetHeight
--    local targetPosY=target.y-descendHeight
--    return targetPosY
--end

--function Mount:GetHeightInMap(target)--返回最高的高度
--    local height1=SceneMgr.GetHeight(target)
--    local height2=SceneMgr.GetHeight1(target)
--    --printyellow("GetheightInmap:height1:",height1)
--    --printyellow("GetHeightInMap:height2:",height2)
--    local height=height1
--    if height1<height2 then
--        height=height2
--    end
--    return height
--end

--function Mount:GetRelativeHeight(newPos,targetPosY)
--    local height=SceneMgr.GetHeight1(newPos)
----  printyellow("GetRelativeHeight:height:",height)
----  printyellow("GetRelativeHeight:targetPosY:",targetPosY)
--    local relativeHeight=targetPosY-height
--    return relativeHeight
--end

function Mount:NavigateTo(params)   --导航
    if self.m_MountState==MountType.Fly then
        local UIManager=require"uimanager"
        if UIManager.isshow("dlguimain") then
            UIManager.call("dlguimain","SetTargetHoming",{pathFinding=true})
        end
        self:FlyNavTo(params)
    elseif self.m_MountState==MountType.Ride then
        --self.m_Navigation:StartNavigate(params)
    end
end

function Mount:StopNavigate()
    if self.m_FlyNav==true then
        if self:CanFlyTo(self:GetRefPos()) then
            self.m_FlyNav=false
            self.m_UltimateTargetInfo=nil
            local UIManager=require"uimanager"
            if UIManager.isshow("dlguimain") then
                UIManager.call("dlguimain","CloseTargetHoming")
            end
        end
    end
end

function Mount:GetNavigateTarget()    
    if self:IsFlyNavigating() and self.m_UltimateTargetInfo then
        return self.m_UltimateTargetInfo
    end
end
--
--function Mount:EndNavigate()    --结束导航
--    Navigation.EndNavigate(self)
--end

function Mount:IsNavigating()
    return (self.m_Player:IsRole()) and ((self.m_Player:IsNavigating()) or (self.m_FlyNav==true))
end

function Mount:IsFlyNavigating()
    return (self.m_Player:IsRole()) and (self.m_FlyNav==true)
end

function Mount:PlayerIsRole()
    return (self.m_Player:IsRole())
end

function Mount:Land(destroy)
    --printyellow("Mount:Land")
    self.m_Destroy=destroy
    local canland=self:CanLand()
    if canland then
        self:StopNavigate()
        self.WorkMgr:StopWork(WorkType.Fly) 
        self:ImmediateLand()
        return true
    else
--        local haslandsite=self:LandOnSite()
--        if haslandsite then
--            return true
--        end
    end
    return false
end

function Mount:CanLand()  --判断当前位置可否着陆
   local result=true
  --[[   local heightInSky1=0--SceneMgr.GetHeight1(self.m_Pos)
    local heightInGround1=0--SceneMgr.GetHeight(self.m_Pos)
    local curPos=self:GetRefPos()
    local heighInSky=0--SceneMgr.GetHeight1(curPos)
    local heightInGround=0--SceneMgr.GetHeight(curPos)
    if (self.m_MountState==MountType.Fly) and ((heightInGround1<=cfg.map.Scene.HEIGHTMAP_MIN) or (math.abs(heightInSky1-heightInGround1)>cfg.map.Scene.DIFFWITHGROUNDANDSKY)) then
        result=false
    end
    if (self.m_MountState==MountType.Fly) and ((heightInGround<=cfg.map.Scene.HEIGHTMAP_MIN) or (math.abs(heighInSky-heightInGround)>cfg.map.Scene.DIFFWITHGROUNDANDSKY)) then
        result=false
    end
    local MapManager=require"map.mapmanager"
    if (MapManager.IsValidNavigatePos({pos=self.m_Pos})~=true) or (MapManager.IsValidNavigatePos({pos=self:GetPos()})~=true) then
        result=false
    end]]
    return result
end

function Mount:CanReach(position)
	
    if self.m_Player:IsRole() then
        if EctypeManager.CheckPosition(position) then --and self.m_Player.m_GroundProbe:CanReach(position) then
            return true
        else
            return false
        end
    else
        return Character.CanReach(self,position)
    end
end

function Mount:CanMoveTo(pos)

    if self.m_Player:IsRole() then
        return Character.CanMoveTo(self,pos) --- and self.m_Player.m_GroundProbe:CanMoveTo(pos)
    else
        return Character.CanMoveTo(self,pos)
    end
end

function Mount:CanFlyTo(target)
    local result=false
	--[[
    if (SceneMgr.GetHeight1(target)>cfg.map.Scene.HEIGHTMAP_MIN) then
        local Utils=require"common.utils"
        local MapManager=require"map.mapmanager"
        local polygon=MapManager.GetSkyRegion()
        if polygon then
            if Utils.insideAnyPolygon(polygon,target) then
                result=true
            end
        else
            result=true
        end
    end   
	]]
    return result
end

function Mount:TransformUpdate()    
    if self.m_MountState==defineenum.MountType.Ride then
        if self.m_Player:IsRole() then
            if self.m_Pos and self.m_Object and (self.m_OldRidePos~=self.m_Pos) then--or self:IsJumping()) then  --
                self.m_OldRidePos=self.m_Pos
                local probePos =self.m_Pos-- self.m_Player.m_GroundProbe:GetPos()
                local deltaY = 0
                --if self:IsJumping() then
                --    deltaY = self.m_Pos.y - probePos.y
                --else
				if self.m_MountState==defineenum.MountType.Ride then
                    deltaY=self.m_InitialHeightInRide
                end
                local vec = nil
                --if self.m_Player.m_GroundProbe:IsOnNavMesh() then
                --    vec = Vector3(probePos.x,probePos.y+deltaY, probePos.z)
                --else
                   -- vec = Vector3(self.m_Pos.x,self.m_Pos.y,0)
                    --self.m_Player.m_GroundProbe:PositionCheck()
                --end
               -- self.m_Object.transform.position = vec-- Vector3(self.m_Pos.x, heightY , self.m_Pos.z)
                --self.m_TransformControl:UpdateTransform(vec,self.m_Rotation)
				
				--vec = Vector3(self.m_Pos.x*SCALE_XY_FRACTION,self.m_Pos.y*SCALE_XY_FRACTION,self.m_Pos.z)
				--self.m_TransformControl:UpdateTransform(vec,self.m_Rotation)
				
				self.m_TransformControl:UpdateTransform(Vector3(self.m_Pos.x * SCALE_XY_FRACTION, self.m_Pos.y * SCALE_XY_FRACTION, -(300 - self.m_Pos.y * SCALE_XY_FRACTION)),self.m_Rotation)
				
                if self.m_ShadowObject then 
                    --self.m_ShadowObject.transform.position = Vector3(vec.x, 0, vec.z)
                    --if self.m_ShadowObject.activeSelf==false then
                     --   self.m_ShadowObject:SetActive(true)
                    --end
                end
                return
            end
        end
     elseif self.m_Player:IsRole() then
        if self.m_ShadowObject and self.m_ShadowObject.activeSelf==true then
            self.m_ShadowObject:SetActive(false)
        end
     end
     Character.TransformUpdate(self)
end

function Mount:SetPos(pos)
    if pos== nil then return end   

    
    if self.m_MountState~=defineenum.MountType.Ride and self.m_MountState~=defineenum.MountType.Attaching then
		--[[
        local skyHeight=SceneMgr.GetHeight1(pos)
        if skyHeight then
            if (self:IsNavigating()) and (self.m_FlyNavDown==true) then
                local groudHeight=SceneMgr.GetHeight(pos)
                if groudHeight>cfg.map.Scene.HEIGHTMAP_MIN then
                    pos.y=self.m_OffsetY+groudHeight
                end
                --if self.m_Player:IsRole() then
                 --   self.m_Player.m_GroundProbe:SetPos(pos)
                --end
                self.m_Pos = pos
            elseif skyHeight>cfg.map.Scene.HEIGHTMAP_MIN then
                pos.y=skyHeight+self.m_OffsetY
                --if self.m_Player:IsRole() then
                    --self.m_Player.m_GroundProbe:SetPos(pos)
                --end
                self.m_Pos = pos
            elseif self.m_FlyNav==true then
                self.m_Pos=Vector3(pos.x,self:GetRefPos().y,pos.z)
            end
            self.m_Player.m_Pos=self.m_Pos
        end
		]]
            self.m_Player.m_Pos=self.m_Pos
    else
        Character.SetPos(self,pos)
        --if self.m_Player:IsRole() then
--            self.m_Pos = self.m_Player.m_GroundProbe:SetPos(self.m_Pos)           
        --end
        self.m_Player.m_Pos=self.m_Pos
    end       
end

function Mount:ImmediateLand() --立即着陆
    --printyellow("ImmediateLand")
    self.m_MountState=MountType.Land
    local targetPos=Vector3(self.m_Pos.x,SceneMgr.GetHeight1(self.m_Pos),self.m_Pos.z)
    self:MoveUp(targetPos)
    self:SendMove(targetPos,self.m_DescendSpeed)
    return true
end
--[[ {   targetPos = 目标位置, roleId = 目标人物Id, eulerAnglesOfRole = 目标人物欧拉角, callback = 导航结束后的回调函数, newStopLength = 距离目标点的停止距离,
        mapId = 目标地图, lineId=目标线, navMode = 导航模式, endDir = 结束方向,stopCallback = 终止回调函数  }
--]]
function Mount:FlyNavTo(params)
    --printyellowmodule(Local.LogModuals.Ride,"FlyNavTo")
	--[[
    if params then
        local MapManager=require"map.mapmanager"
        local FlyNavMgr=require"character.navigation.flynavigationmanager" 
        self.m_UltimateTargetInfo=params
        local curPos=self:GetRefPos()
        if (params.mapId==nil) or (params.mapId==PlayerRole:Instance():GetMapId()) then
            local lineId=PlayerRole:Instance().m_MapInfo:GetLineId()
            if (params.lineId==nil) or (params.lineId==lineId) then
                local charactermanager = require "character.charactermanager"
                local targetCharacter=nil
                if params.targetPos then
                    self.m_FlyNavTarget=params.targetPos
                elseif params.roleId then
                    targetCharacter =  charactermanager.GetCharacter(params.roleId)
                    if targetCharacter then
                        self.m_FlyNavTarget = targetCharacter:GetRefPos() + Vector3(0,0,1)*targetCharacter.m_Rotation
                    else
                        return
                    end
                end
                self.m_FlyNavDir=Vector3(self.m_FlyNavTarget.x-curPos.x,0,self.m_FlyNavTarget.z-curPos.z).normalized
                if params.endDir then
                    self.m_NavEndDir = params.endDir
                end
                self.m_NavCallBackFunc = params.callback
                self.m_NewTarget=Vector3(self.m_FlyNavTarget.x,curPos.y,self.m_FlyNavTarget.z)
                self:MoveUp(self.m_NewTarget)
                self:SendMove(self.m_NewTarget,self.m_FlySpeed)
                self.m_FlyNav=true
            else
                MapManager.EnterMap(params.mapId,params.lineId)
                params.changeLine=true
                FlyNavMgr.SetNavInfo(params)
            end
        else                                  
            if params.navMode==2 then               
                local portalPos,portalId=MapManager.GetPortalOfMap(PlayerRole:Instance():GetMapId(),params.mapId)
                if portalPos then
                    self.m_FlyNavTarget=portalPos
                    self.m_FlyNavDir=Vector3(self.m_FlyNavTarget.x-curPos.x,0,self.m_FlyNavTarget.z-curPos.z).normalized
                    self.m_NewTarget=Vector3(self.m_FlyNavTarget.x,curPos.y,self.m_FlyNavTarget.z)
                    self.m_NavCallBackFunc=function() MapManager.TransferMap(portalId) end
                    self:MoveUp(self.m_NewTarget)
                    self:SendMove(self.m_NewTarget,self.m_FlySpeed)                 
                    self.m_FlyNav=true
                    FlyNavMgr.SetNavInfo(params)
                else
                    MapManager.EnterMap(params.mapId,params.lineId)
                    FlyNavMgr.SetNavInfo(params)
                end
            else             
                MapManager.EnterMap(params.mapId,params.lineId)
                FlyNavMgr.SetNavInfo(params)
            end
        end
    end
	]]
end

--function Mount:LandOnSite()  --判断附近是否能找到着陆点并飞行到最近着陆点着陆
--  --寻找着陆点
--  local target=self:SearchLandPoint()
--  if target then
--    self.landpoint=target
--    self.landdistance=Vector3:Distance(target,self:GetPos())
--    self.landspeed=self.landdistance*self.m_DescendSpeed/(self.height-self.m_InitialHeightInRide)
--    self.curlanddis=0
--    self.m_MountState=MountType.ToPointLand
--    return true
--  end
--  return false
--end

--寻找着陆点
function Mount:SearchLandPoint()
    local target=nil
    return target
end


function Mount:SendMove(targetPos,speed)
    if self.m_Player and self.m_Player:IsRole() then
        self.m_TransformSync:SendMove(targetPos)
    end
end

function Mount:SendStop() 
    if self.m_Player and self.m_Player:IsRole() then
        self.m_TransformSync:SendStop()
    end
end

function Mount:SendMountState(mountState)
    if self.m_Player and self.m_Player:IsRole() then
        RideManager.Ride(self.m_Id,mountState)
        if self.m_Player then
            self.m_Player:ResetMainRide()
        end
    end
end

function Mount:PlayIdleWithPlayer()
     if self.m_RoleAction==1 then 
        self:PlayLoopAction(cfg.skill.AnimType.Stand)
        self.m_Player:PlayLoopAction(cfg.skill.AnimType.StandFly)
	elseif self.m_RoleAction==2 then 
        self:PlayLoopAction(cfg.skill.AnimType.Stand)
        self.m_Player:PlayLoopAction(cfg.skill.AnimType.StandRide)
	elseif self.m_RoleAction==3 then 
        self:PlayLoopAction(cfg.skill.AnimType.Stand)
        self.m_Player:PlayLoopAction(cfg.skill.AnimType.SitRide)
     end
end

function Mount:PlayRunWithPlayer()
     if self.m_RoleAction==1 then
        self:PlayLoopAction(cfg.skill.AnimType.Run)
        self.m_Player:PlayLoopAction(cfg.skill.AnimType.Fly)
     elseif self.m_RoleAction==2 then
        self:PlayLoopAction(cfg.skill.AnimType.Run)
        self.m_Player:PlayLoopAction(cfg.skill.AnimType.RunRide)
	elseif self.m_RoleAction==3 then
        self:PlayLoopAction(cfg.skill.AnimType.Run)
        self.m_Player:PlayLoopAction(cfg.skill.AnimType.SitRideRun)
     end
end

function Mount:GetNavStopLength()
    return 1.7
end

function Mount:OnCharacterLoaded(bundlename,asset_obj,isShowHeadInfo,playbornaction)
    if self.m_Object then
        self.m_Object:SetActive(true)
    end
    Character.OnCharacterLoaded(self,bundlename,asset_obj,isShowHeadInfo,playbornaction)
end

function Mount:IsPlayingStand()
    if self.m_Player then
        if self.m_RoleAction==1 then
            return (self:IsPlayingAction(cfg.skill.AnimType.Stand)) and (self.m_Player:IsPlayingAction(cfg.skill.AnimType.StandFly))
        elseif self.m_RoleAction==2 then
            return (self:IsPlayingAction(cfg.skill.AnimType.Stand)) and (self.m_Player:IsPlayingAction(cfg.skill.AnimType.StandRide))
        elseif self.m_RoleAction==3 then
            return (self:IsPlayingAction(cfg.skill.AnimType.Stand)) and (self.m_Player:IsPlayingAction(cfg.skill.AnimType.SitRide))
        end
    end
    return false
end

--function Mount:ResumePet()
--    if self.m_Player and self.m_Player:IsRole() then
--        local ConfigManager=require"cfg.configmanager"
--        local CfgConfig=ConfigManager.getConfig("petconfig")
--        self.m_Player.m_PetCd=CfgConfig.equipcd.time
--        self.m_Player.m_ResumePetTime=os.time()
--    end
--end

function Mount:BindFlyEffect() 
	--[[
    local action,model = self:GetAction(cfg.skill.AnimType.BindFlyEffect)
    if action and (self.m_BindFlyEffectId==nil) then 
        local SkillManager=require"character.skill.skillmanager"
        self.m_BindFlyEffectId = SkillManager.PlayBindEffect(action,self)
    end
	]]
end 

function Mount:ReleaseBindFlyEffect() 
	--[[
    if self.m_BindFlyEffectId and self.m_BindFlyEffectId>0 then 
        local EffectManager=require"effect.effectmanager"
        EffectManager.StopEffect(self.m_BindFlyEffectId)
        self.m_BindFlyEffectId=nil
    end
	]]
end

return Mount
