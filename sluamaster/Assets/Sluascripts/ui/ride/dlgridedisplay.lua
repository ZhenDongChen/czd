local Unpack = unpack
local Define=require("define")
local EventHelper = UIEventListenerHelper
local NetWork = require("network")
local UIManager=require("uimanager")
local ConfigManager=require("cfg.configmanager")
local PlayerRole=require("character.playerrole"):Instance()

local Player=require("character.player")
local Mount=require("character.mount")
local RideManager=require("ui.ride.ridemanager")
local CheckCmd=require("common.checkcmd")
local CameraManager = require("cameramanager")
local BonusManager = require("item.bonusmanager")
local ItemManager = require("item.itemmanager")
local ItemManager = require("item.itemmanager")
local VipChargeManager = require("ui.vipcharge.vipchargemanager")


local m_GameObject
local m_Name
local m_Fields
local m_Mount=nil
local m_Player=nil
local m_RideData
local m_State
local m_FirstLoad=false
local m_RideList={}
local m_CanClick=true
local m_RefreshTime=nil

local function destroy()
    if m_Player then
        m_Player:release()
    end
    if m_Mount then
        m_Mount:release()
    end
end

local function hide()
--    printyellowmodule(Local.LogModuals.Ride,"hide")
end

local function SetPlayerShader()
	--???????shader????  ????????????ú???
	if true then return end
	--[[
    local meshRenderList=m_Player.m_Object:GetComponentsInChildren(SkinnedMeshRenderer,true)
    if not IsNull(meshRenderList) then
        for i=1,meshRenderList.Length do
            local smr=meshRenderList[i]
            for i=1,smr.materials.Length do
                local mat = smr.materials[i]
                mat.shader = Shader.Find("SuperPop/Character/PlayerRole_NormalUI")
            end
        end
    end
	]]
end

local function OnPlayerLoaded(params)
    printyellowmodule(Local.LogModuals.Ride,"OnPlayerLoaded")
    if m_Player and m_Player.m_Object and m_Mount and (not IsNull(m_Mount.m_Object)) then
        m_Player:HideShadow(false)       
        local playerObj = m_Player.m_Object
        if not IsNull(playerObj) then    
            SetPlayerShader()       
            ExtendedGameObject.SetLayerRecursively(playerObj,Define.Layer.LayerUICharacter)
            local playerTrans = playerObj.transform
            if not IsNull(playerTrans) then
				--assert(m_RideData)
				--assert(m_RideData.riggingpoint)
				--assert(m_Mount)
				--assert(m_Mount.m_Object)
				local rigpoint=m_Mount.m_Object.transform:GetChild(0).transform:Find(m_RideData.riggingpoint)
                local attachBone=rigpoint.gameObject
                if not IsNull(attachBone) then
                    playerTrans.parent=attachBone.transform
                    playerTrans.localPosition=Vector3.zero
                    local modelTrans = m_Mount.m_Object.transform
                    modelTrans.localScale = Vector3.one*(m_RideData.scale)
                   --modelTrans.localPosition = Vector3(0,m_RideData.height,300)
				   modelTrans.localPosition = Vector3(m_RideData.trans_pos[1],m_RideData.trans_pos[2],m_RideData.trans_pos[3])--Vector3(0,-360,300)
				
                    modelTrans.localEulerAngles = Vector3(m_RideData.trans_rotate[1],m_RideData.trans_rotate[2],m_RideData.trans_rotate[3])---Vector3(-90,-45,0) --Vector3.one* m_RideData.rotationy
                    if m_RideData.rotateplayer==true then
                        playerTrans.localEulerAngles = Vector3(playerTrans.localEulerAngles.x,-90,playerTrans.localEulerAngles.z)
						--playerTrans.localEulerAngles = Vector3(playerTrans.localEulerAngles.x,playerTrans.localEulerAngles.y,0)
                    end
                    m_Mount.m_Object:SetActive(true)
                    if m_RideData.ridingmotion==1 then
                        m_Player:PlayLoopAction(cfg.skill.AnimType.StandFly)
                        local flySwordHeight=ConfigManager.getConfig("flyingswordheight")
                        local flyOffSetY=0
                        if flySwordHeight then
                            for _,data in pairs(flySwordHeight) do
                                if data.faction==PlayerRole.m_Profession and data.gender==PlayerRole.m_Gender then
                                    flyOffSetY=data.offsety
                                    break
                                end
                            end
                            playerTrans.localPosition = Vector3(0,0,flyOffSetY)
                            end
                    elseif m_RideData.ridingmotion==2 then
                        m_Player:PlayLoopAction(cfg.skill.AnimType.StandRide)
                    elseif m_RideData.ridingmotion==3 then
                        m_Player:PlayLoopAction(cfg.skill.AnimType.SitRide)
                    end      
                end
            end
        end
    end
    m_CanClick=true
end



local function AddPlayer()
    m_Player = Player:new(true)
    --m_Player.m_AnimSelectType=cfg.skill.AnimTypeSelectType.UI
    m_Player.m_MountUIPlayer=true
    m_Player:init(0,PlayerRole.m_Profession,PlayerRole.m_Gender,false,PlayerRole.m_Dress,PlayerRole.m_Equips, nil, m_RideData.scale/320)
    m_Player:RegisterOnLoaded(OnPlayerLoaded)
end

local function AttachPlayerToMount()
--    if m_Player then
----        m_Player:release()
----        m_Player=nil
--m_FirstLoadPlayer=false
--        OnPlayerLoaded()
--    end
    AddPlayer()
end

local function OnMountLoaded()
    printyellowmodule(Local.LogModuals.Ride,"OnMountLoaded")
	
    if m_Mount then
        local modelObj=m_Mount.m_Object
        if not IsNull(modelObj) then
            local modelTrans = modelObj.transform
            if not IsNull(modelTrans) then
                modelTrans.parent = m_Fields.UITexture_3DModel.transform
                ExtendedGameObject.SetLayerRecursively(modelObj,Define.Layer.LayerUICharacter)
                modelObj:SetActive(false)
                m_Fields.UITexture_3DModel.gameObject:SetActive(false)
                m_Fields.UITexture_3DModel.gameObject:SetActive(true)
	
				--shader????????????趨?????????????
				--[[
                local skin=modelObj.transform:FindChild(m_Mount.m_ModelPath)
                if not IsNull(skin) then
                    local meshRenderList=skin:GetComponentsInChildren(SkinnedMeshRenderer,true)
                    if not IsNull(meshRenderList) then
                        for i=1,meshRenderList.Length do
                            local smr=meshRenderList[i]
                            for i=1,smr.materials.Length do
                                local mat = smr.materials[i]
                                mat.shader = Shader.Find("SuperPop/Character/PlayerRole_NormalUI")
                            end
                        end
                    end
                end
				]]
                AttachPlayerToMount()
            end
        end
    end
end

local function Load3DModel()
    printyellowmodule(Local.LogModuals.Ride,"Load3DModel")
    printtmodule(Local.LogModuals.Ride,m_RideData)
    if m_Mount and m_Mount.m_Object and m_Player and m_Player.m_Object then
--        local attachBone=m_Mount.m_Object.transform:Find(m_RideData.riggingpoint).gameObject
--        local attachTransform
--        if attachBone then
--            attachTransform=attachBone.transform
--        end
--        if attachTransform then
--            attachTransform:DetachChildren()
--        end
        m_Player:release()
        m_Player=nil
        m_Mount:release()
        m_Mount=nil
    end
    if m_RideData then
        m_Mount=Mount:new()
        m_Mount.m_AnimSelectType=cfg.skill.AnimTypeSelectType.UI
        m_Mount:RegisterOnLoaded(OnMountLoaded)
        m_Mount:init(m_RideData.id)        
    end
end

local function GetOwnTime(time)
    local text=""
    if time then
        if time==0 then
            text=LocalString.Ride_Forever
        else
            local tempSecs= timeutils.GetServerTime()
            if (time/1000>tempSecs) then
                local remainTime=timeutils.getDateTime(time/1000-tempSecs)
                text=string.format(LocalString.Ride_OwnTime,remainTime.days,remainTime.hours,remainTime.minutes)
            end
        end
    end
    return text
end

local function GetAttr()
    local text=""
	assert(LocalString.Ride_SpeedBuff)
	assert(m_RideData.speedbuff)
    text=string.format(LocalString.Ride_SpeedBuff,m_RideData.speedbuff).."\n"
    if m_RideData.battleproperty then
        for _,propertyData in pairs(m_RideData.battleproperty) do
            local tempText=ItemManager.GetAttrText(propertyData.propertytype,propertyData.value)
            text=text..tempText.."\n"
        end
    end
    text=text..GetOwnTime(m_RideData.expiretime)
    return text
end

local function LoadDetailInfo(params)
    printyellowmodule(Local.LogModuals.Ride,"LoadDetailInfo")
    if m_RideData then
        m_Fields.UILabel_FashionDes.text=m_RideData.introduction
        m_State=m_RideData.state
				
		local bRiding=(bRiding==true)
	
		local bActivated=(bRiding and (m_State==defineenum.MountActiveStatus.Actived))
	
		--m_Fields.UILabel_Unload.gameObject:SetActive(bUnload)				
        --m_Fields.UILabel_Activate.gameObject:SetActive(not bUnload and (m_State==defineenum.MountActiveStatus.Get))
        ---m_Fields.UILabel_Unload.gameObject:SetActive(bRiding and (m_State==defineenum.MountActiveStatus.Actived))

        m_Fields.UILabel_FashionAttr.text=GetAttr()
        m_RefreshTime=os.time()

        
        m_Fields.UIButton_FashionEquip.isEnabled=((m_State==defineenum.MountActiveStatus.Get) or (m_State==defineenum.MountActiveStatus.Actived))

		m_Fields.UIButton_FashionEquip.gameObject:SetActive(m_Fields.UIButton_FashionEquip.isEnabled)--(m_State==defineenum.MountActiveStatus.Get) or (m_State==defineenum.MountActiveStatus.Actived))
		
		if m_Fields.UIButton_FashionEquip.isEnabled then			
			m_Fields.UILabel_Activate.gameObject:SetActive(m_State==defineenum.MountActiveStatus.Get)
			m_Fields.UILabel_Unload.gameObject:SetActive(m_State==defineenum.MountActiveStatus.Actived)
		else
			m_Fields.UILabel_Unload.gameObject:SetActive(false)
			m_Fields.UILabel_Activate.gameObject:SetActive(false)
		end


        EventHelper.SetClick(m_Fields.UIButton_FashionEquip,function()
                if m_State==defineenum.MountActiveStatus.Get then
                    RideManager.SendCActiveRide(m_RideData.id)
                elseif m_State==defineenum.MountActiveStatus.Actived then
                    RideManager.SendCDeActiveRide()
                end
        end)
        local text=""
        local validate,info=CheckCmd.CheckData({data=m_RideData.viplimit})
        local validate1,info1=CheckCmd.CheckData({data=m_RideData.price})
        printtmodule(Local.LogModuals.Ride,m_RideData)
        if m_RideData.quickbuy then
            m_Fields.UIGroup_Buy.gameObject:SetActive(true)
--            m_Fields.UIGroup_GetWay.gameObject:SetActive(false)
            m_Fields.UILabel_Approaches.gameObject:SetActive(false)
            m_Fields.UILabel_Cost.text=m_RideData.price.amount
            --if not m_RideData.viplimit or m_RideData.viplimit<1 then
            --    m_Fields.UILabel_VIP.gameObject:SetActive(false)
            --else
                m_Fields.UILabel_VIP.gameObject:SetActive(true)
                if m_RideData.viplimit.level>0 then
                    m_Fields.UILabel_VIP.text=string.format(LocalString.Ride_BuyVipLevel,m_RideData.viplimit.level)
                else
                    m_Fields.UILabel_VIP.text=LocalString.Ride_DirectBuy
                end
            --end
            m_Fields.UIButton_GetRide.isEnabled=((m_State~=defineenum.MountActiveStatus.Get)and(m_State~=defineenum.MountActiveStatus.Actived))
            m_Fields.UIButton_GetRide.gameObject:SetActive(true)
            local DirectBuy=function()
                text=LocalString.Ride_Purchase                
                m_Fields.UIButton_GetRide.isEnabled=true
                EventHelper.SetClick(m_Fields.UIButton_GetRide,function()
                    if validate and validate1 then
                        local params={}
                        params.content=LocalString.Ride_BuyTip
                        params.callBackFunc=function()
                            RideManager.SendCBuyRide(m_RideData.id)
                        end
                        params.immediate=true
                        UIManager.ShowAlertDlg(params)
                    else
                        if not validate then
                            local params={}
                            params.immediate    = true
                            params.content=LocalString.Ride_VIPNotEnough
                            params.callBackFunc=function()
                                VipChargeManager.ShowVipChargeDialog()
                            end
                            params.sureText=LocalString.ImmediateRecharge
                            UIManager.ShowAlertDlg(params)
                        else
                            UIManager.ShowSingleAlertDlg({content=LocalString.Exchange_YuanBaoNotEnough})
                        end
                    end
                end)
            end
            if ((m_State==defineenum.MountActiveStatus.Get)or(m_State==defineenum.MountActiveStatus.Actived)) then
                if m_RideData.expiretime==0 then
                    text=LocalString.Ride_HavePurchased
                else
                    DirectBuy()
                end  
            else
                DirectBuy()            
            end
        else
            m_Fields.UIGroup_Buy.gameObject:SetActive(false)
            m_Fields.UILabel_Approaches.gameObject:SetActive(true)
            m_Fields.UILabel_Approaches.text=m_RideData.gain
            if m_RideData.gainpage and m_RideData.gainpage~="" then
                m_Fields.UIButton_GetRide.isEnabled=true                             
                text=LocalString.Ride_GoTo
                EventHelper.SetClick(m_Fields.UIButton_GetRide,function()
                    UIManager.showdialog(m_RideData.gainpage)
                end)
            else
                m_Fields.UIButton_GetRide.gameObject:SetActive(false)
            end
        end
        m_Fields.UILabel_GetRide.text=text
        if params and (params.loadModel==true) then
            Load3DModel()
        end
    else
        m_Fields.UILabel_FashionDes.text=""
        m_Fields.UILabel_Approaches.text=""
        m_Fields.UILabel_FashionAttr.text=""
        m_Fields.UIButton_FashionEquip.gameObject:SetActive(false)
        m_Fields.UIButton_GetRide.gameObject:SetActive(false)
        --Load3DModel()
    end
end



local function DisplayOneRideItem(rideItem,ride)
	local bRiding=PlayerRole:IsRiding() 
	local idMount=PlayerRole:GetMountId() 
	local mount=PlayerRole:GetMount() 
	
	bRiding=(bRiding==true)
	
    local UITexture_Ride=rideItem.Controls["UITexture_Ride"]
    local UISprite_RideQuality=rideItem.Controls["UISprite_RideQuality"]
    local UILabel_FashionName=rideItem.Controls["UILabel_FashionName"]
    local UILabel_Activited=rideItem.Controls["UILabel_Activited"]
    local UILabel_UnAcquired=rideItem.Controls["UILabel_Unacquired"]
    local UILabel_Acquired=rideItem.Controls["UILabel_Acquired"]
    local UISprite_RedDot=rideItem.Controls["UISprite_Warning"]
	
    UILabel_UnAcquired.gameObject:SetActive(ride.state==0)
    --UILabel_Activited.gameObject:SetActive(bRiding and (ride.state==defineenum.MountActiveStatus.Actived))
    --UILabel_Acquired.gameObject:SetActive(ride.state==defineenum.MountActiveStatus.Get or (ride.state==defineenum.MountActiveStatus.Actived and (not bRiding)))---ride.state==defineenum.MountActiveStatus.Get or ((not bRiding) and (ride.state==defineenum.MountActiveStatus.Actived)))
	
	UILabel_Activited.gameObject:SetActive(ride.state==defineenum.MountActiveStatus.Actived)
    UILabel_Acquired.gameObject:SetActive(ride.state==defineenum.MountActiveStatus.Get)
	
    UISprite_RedDot.gameObject:SetActive(RideManager.IsNewGet(ride.id))
    --if rideList[i].quality== then
    --end
    UISprite_RideQuality.spriteName = colorutil.GetQualitySprite(ride.quality)
    rideItem.Id=ride.id
    rideItem.Data=ride
    if (m_RideData~=nil) and (rideItem.Id==m_RideData.id) then
        m_RideData=rideItem.Data
        rideItem.Checked=true
        local UIToggle=rideItem:GetComponent("UIToggle")
        UIToggle:Set(true)
    else
        local UIToggle=rideItem:GetComponent("UIToggle")
        UIToggle:Set(false)
        rideItem.Checked=false
    end
    UILabel_FashionName.text= colorutil.GetQualityColorText(ride.quality,ride.name)
    UITexture_Ride:SetIconTexture(ride.icon)
    EventHelper.SetClick(rideItem,function()
        if m_RideData.id~=rideItem.Id then
            if (m_Mount and m_Mount.m_Object and m_Player and m_Player.m_Object)  or (m_Mount==nil and m_Player==nil) then               
                m_RideData=ride
                m_State=ride.state
                LoadDetailInfo({loadModel=true})
            end
        end
    end)
end

local function OnItemInit(UIListItem,wrapIndex,realIndex)
    if UIListItem==nil then
        return
    end
    local ride=m_RideList[realIndex]
    if UIListItem then
        DisplayOneRideItem(UIListItem,ride)
    end
end

local function InitList(num)
    local wrapList=m_Fields.UIList_Ride.gameObject:GetComponent("UIWrapContentList")
    if wrapList==nil then
        return
    end
    EventHelper.SetWrapListRefresh(wrapList,OnItemInit)
    wrapList:SetDataCount(num)
    wrapList:CenterOnIndex(-1.3)
end

local function DisplayAllRides(params)
    printyellowmodule(Local.LogModuals.Ride,"DisplayAllRides")
    m_RideList=RideManager.GetAllRide()
    InitList(#m_RideList)
    if m_RideData==nil then
        local defaultItem=m_Fields.UIList_Ride:GetItemByIndex(0)
        if defaultItem then
            m_RideData=defaultItem.Data
            m_Fields.UIList_Ride:SetSelectedIndex(0)
        else
            m_RideData=nil
        end
    end
    LoadDetailInfo(params)
end

local function show(params)
    printyellowmodule(Local.LogModuals.Ride,"show")
end

local function refresh(params)
    printyellowmodule(Local.LogModuals.Ride,"refresh")
    if m_FirstLoad then
        m_FirstLoad=false
    else
        DisplayAllRides(params)
    end
end

local function showdialog(params)
    printyellowmodule(Local.LogModuals.Ride,"showdialog")
    show(params)
end

local function uishowtype()
    return UIShowType.Refresh
end

local function update()
    if m_Mount and m_Mount.m_Object and m_Mount.m_Avatar then 
        m_Mount.m_Avatar:Update()   
    end
    if m_Player and m_Player.m_Object then
        m_Player.m_Avatar:Update()       
        if m_RideData.ridingmotion==1 then
            if not m_Player:IsPlayingAction(cfg.skill.AnimType.StandFly) then
                m_Player:PlayLoopAction(cfg.skill.AnimType.StandFly)
            end
        elseif m_RideData.ridingmotion==2 then
            if not m_Player:IsPlayingAction(cfg.skill.AnimType.StandRide) then
                m_Player:PlayLoopAction(cfg.skill.AnimType.StandRide)
            end
        elseif m_RideData.ridingmotion==3 then
            if not m_Player:IsPlayingAction(cfg.skill.AnimType.SitRide) then
                m_Player:PlayLoopAction(cfg.skill.AnimType.SitRide)
            end
        end
    end
    if m_RefreshTime then
        if (os.time()-m_RefreshTime)>=60 then
            m_RefreshTime=os.time()
            if m_RideData then
                if (m_RideData.expiretime) and (m_RideData.expiretime~=0) then
                    m_Fields.UILabel_FashionAttr.text=GetAttr()
                end
            end
        end
    end
end

local function ClearData()
    DisplayAllRides()
end

local function init(params)
    printyellowmodule(Local.LogModuals.Ride,"init")
    m_FirstLoad=true
    m_CanClick=true
    m_Name, m_GameObject, m_Fields = Unpack(params)
    ClearData()
    RideManager.SendCGetRideInfo()
    EventHelper.SetDrag(m_Fields.UITexture_3DModel,function (go,delta)
        if m_Mount and m_Mount.m_Object  then
            local vecRotate = Vector3(0,-delta.x,0)
            m_Mount.m_Object.transform.localEulerAngles = m_Mount.m_Object.transform.localEulerAngles + vecRotate
        end
    end)
end

return{
    init=init,
    update=update,
    hide=hide,
    show=show,
    uishowtype=uishowtype,
    refresh=refresh,
    DisplayAllRides=DisplayAllRides,
}
