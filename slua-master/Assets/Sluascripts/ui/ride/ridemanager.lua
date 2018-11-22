local NetWork=require "network"
local UIManager=require "uimanager"
local PlayerRole=require "character.playerrole"
local ConfigManager=require"cfg.configmanager"
local Utils=require"common.utils"

local m_RideList={}
local m_GetNewRideList={}

local function SortRideData()
    Utils.table_sort(m_RideList,function(a,b) return a.state>b.state end )
end

local function Ride(id,type)
    --printyellowmodule(Local.LogModuals.Ride,"ridemanager.ride")
    local re=map.msg.CChangeRide({ridetype=type})
    NetWork.send(re)
end

local function NotAcquired(id)
    local notAcquired=true
    if m_RideList then
        for i=1,#m_RideList do
            if m_RideList[i].ridekey==id then
                notAcquired=false
                break
            end
        end
    end
    return notAcquired
end

local function GetRemainRide()
    local rideConfigData=ConfigManager.getConfig("riding")
    local remainRideList={}
    for key,data in pairs(rideConfigData) do
        if (NotAcquired(key)) and (data.showmode==cfg.equip.EquipTitleShowMode.Normal) then           
            data.id=key
            table.insert(remainRideList,data)
        end
    end
    Utils.table_sort(remainRideList,function(a,b) return a.displayorder<b.displayorder end)
    return remainRideList
end

local function GetActivedRide()
    local rideId=nil
    for i=1,#m_RideList do
        local rideInfo=m_RideList[i]
        if rideInfo.state==defineenum.MountActiveStatus.Actived then
            rideId=rideInfo.ridekey
            break
        end
    end
    return rideId
end

local function SGetRideInfo(msg)
    m_RideList=msg.rideinfo
    for i=1,#m_RideList do
        local rideInfo=m_RideList[i]
        rideInfo.state=defineenum.MountActiveStatus.Get
        if rideInfo.ridekey==msg.activeride then
            rideInfo.state=defineenum.MountActiveStatus.Actived
            PlayerRole:Instance().m_MountId=rideInfo.ridekey
        end
    end
    SortRideData()
    if UIManager.isshow("ride.dlgridedisplay") then
        UIManager.refresh("ride.dlgridedisplay",{loadModel=true})
    end
end

local function SActiveRide(msg)
    for i=1,#m_RideList do
        --local ride=m_RideList[i]
        if msg.ridekey~=m_RideList[i].ridekey then
            if m_RideList[i].state==defineenum.MountActiveStatus.Actived then
                m_RideList[i].state=defineenum.MountActiveStatus.Get
            end
        else
            PlayerRole:Instance().m_MountId=msg.ridekey
            m_RideList[i].state=defineenum.MountActiveStatus.Actived
        end
    end
    if m_GetNewRideList[msg.ridekey] then
        m_GetNewRideList[msg.ridekey]=nil    
        if UIManager.hasloaded("dlgmain_open") then       
            UIManager.call("dlgmain_open","RefreshRedDot",cfg.ui.FunctionList.MOUNT)
        end
    end
    SortRideData()
    if UIManager.isshow("ride.dlgridedisplay") then
        UIManager.refresh("ride.dlgridedisplay",{loadModel=false})
    end
	
	--if UIManager.isshow("dlguimain") then
		local DlgUIMain_Combat=require"ui.dlguimain_combat"
		--DlgUIMain_Combat.SetRidingState(true)
		DlgUIMain_Combat.RefreshRidingState()
	--end
end

local function GetNameById(id)
    local text=""
    local data=ConfigManager.getConfigData("riding",id)
    if data then
        text=data.name
    end
    return text
end

local function SRideGetNotify(msg)
    for i=1,#m_RideList do
        local rideInfo=m_RideList[i]
        if rideInfo.ridekey==msg.ride.ridekey then
            m_RideList[i]=msg.ride
            m_RideList[i].state=defineenum.MountActiveStatus.Get
            return
        end
    end
    if (msg.ride.expiretime) and (msg.ride.expiretime~=0) then
        UIManager.ShowSystemFlyText(string.format(LocalString.Ride_Have,GetNameById(msg.ride.ridekey)))
    end
    table.insert(m_RideList,(#m_RideList+1),msg.ride)
    m_RideList[#m_RideList].state=defineenum.MountActiveStatus.Get
    SortRideData()     
    if UIManager.isshow("ride.dlgridedisplay") then
        UIManager.refresh("ride.dlgridedisplay")
    end
    m_GetNewRideList[msg.ride.ridekey]=true
    if UIManager.hasloaded("dlgmain_open") then
        UIManager.call("dlgmain_open","RefreshRedDot",cfg.ui.FunctionList.MOUNT)
    end
end

local function SDeActiveRide(msg)
    for i=1,#m_RideList do
        local rideInfo=m_RideList[i]
        if rideInfo.state==defineenum.MountActiveStatus.Actived then
            rideInfo.state=defineenum.MountActiveStatus.Get
            --Ride(msg.ride.ridekey,cfg.equip.RideType.NONE)
            break
        end
    end
    SortRideData()
    if UIManager.isshow("ride.dlgridedisplay") then
        UIManager.refresh("ride.dlgridedisplay",{loadModel=false})
    end
	
	--if UIManager.isshow("dlguimain") then
		local DlgUIMain_Combat=require"ui.dlguimain_combat"
		--DlgUIMain_Combat.SetRidingState(true)
		DlgUIMain_Combat.RefreshRidingState()
	--end
end

local function SBuyRide(msg)
    for i=1,#m_RideList do
        local rideInfo=m_RideList[i]
        if rideInfo.ridekey==msg.ridekey then
            rideInfo.state=defineenum.MountActiveStatus.Get
            --Ride(msg.ride.ridekey,cfg.equip.RideType.NONE)
            break
        end
    end
    SortRideData()
    if UIManager.isshow("ride.dlgridedisplay") then
        UIManager.refresh("ride.dlgridedisplay",{loadModel=false})
    end
    m_GetNewRideList[msg.ridekey]=true
    if UIManager.hasloaded("dlgmain_open") then
        UIManager.call("dlgmain_open","RefreshRedDot",cfg.ui.FunctionList.MOUNT)
    end
end

local function SRideExpired(msg)
    for i=1,#m_RideList do
        local rideInfo=m_RideList[i]
        if rideInfo.ridekey==msg.rideid then
            table.remove(m_RideList,i) 
            break
        end
    end
    SortRideData()
    if UIManager.isshow("ride.dlgridedisplay") then
        UIManager.refresh("ride.dlgridedisplay",{loadModel=false})
    end
    if UIManager.hasloaded("dlgmain_open") then
        UIManager.call("dlgmain_open","RefreshRedDot",cfg.ui.FunctionList.MOUNT)
    end

	--if UIManager.isshow("dlguimain") then
		local DlgUIMain_Combat=require"ui.dlguimain_combat"
		--DlgUIMain_Combat.SetRidingState(true)
		DlgUIMain_Combat.RefreshRidingState()
	--end
end

local function SendCDeActiveRide()
    if PlayerRole:Instance():IsRiding() and (PlayerRole:Instance():CanLand()~=true) then
        UIManager.ShowSystemFlyText(LocalString.Ride_CanNotLand)
    else
        local msg=lx.gs.mount.CDeActiveRide({})
        NetWork.send(msg)
    end
end

local function SendCActiveRide(id)
    local message=lx.gs.mount.CActiveRide({ridekey=id})
    NetWork.send(message)
end

local function SendCGetRideInfo()
    local message=lx.gs.mount.CGetRideInfo({})
    NetWork.send(message)
end

local function SendCBuyRide(id)
    local message=lx.gs.mount.CBuyRide({ridekey=id})
    NetWork.send(message)
end

local function GetRideInfo()
    return m_RideList
end

local function GetAllRide()
	print("GetAllRide")
    local allRideList={}
    for _,ride in pairs(GetRideInfo()) do
        local tempRide={}
        tempRide.id=ride.ridekey
        tempRide.expiretime=ride.expiretime
        tempRide.state=ride.state
        local rideData=ConfigManager.getConfigData("riding",ride.ridekey)
        tempRide.name=rideData.name
        tempRide.icon=rideData.icon
        tempRide.introduction=rideData.introduction
        tempRide.price=rideData.price
        tempRide.viplimit=rideData.viplimit
        tempRide.speedbuff=rideData.speedbuff
        tempRide.quickbuy=rideData.quickbuy
        tempRide.gain=rideData.gain
        tempRide.gainpage=rideData.gainpage
        tempRide.scale=rideData.scale
        tempRide.rotationy=rideData.rotationy
        tempRide.height=rideData.height
        tempRide.riggingpoint=rideData.riggingpoint
        tempRide.ridingmotion=rideData.ridingmotion
        tempRide.quality=rideData.quality
        tempRide.rotateplayer=rideData.rotateplayer
        tempRide.battleproperty=rideData.battleproperty
		tempRide.trans_pos=rideData.trans_pos
		tempRide.trans_rotate=rideData.trans_rotate
        table.insert(allRideList,tempRide)
    end
    for _,ride in pairs(GetRemainRide()) do
        ride.state=0
        table.insert(allRideList,ride)
    end
    return allRideList
end

local function NotAcquired(id)
    local notAcquired=true
    if m_RideList then
        for i=1,#m_RideList do
            if m_RideList[i].ridekey==id then
                notAcquired=false
                break
            end
        end
    end
    return notAcquired
end

local function JudgeOpenLevel()
    local opened=false
    local info=""
    if PlayerRole:Instance().m_Level>=cfg.equip.Riding.OPEN_LEVEL then
        opened=true
    else
        info=string.format(LocalString.OpenLevelLimit,cfg.equip.Riding.OPEN_LEVEL)
    end
    return opened,info
end

local function Start()
    SendCGetRideInfo()
end

local function UnRead()
    if #m_RideList >= 1 then
        for i=1,#m_RideList do
            local rideInfo=m_RideList[i]
            if rideInfo.state == defineenum.MountActiveStatus.Actived then
                return false
            end
        end
    else
        return false
    end
    return true
    --return (#m_GetNewRideList>0)
end
 
local function IsNewGet(id)
    return (m_GetNewRideList[id]~=nil)
end

local function ClearData()
    m_RideList={}
    m_GetNewRideList={}
end

local function init()
    gameevent.evt_system_message:add("logout",ClearData)
    NetWork.add_listeners({
        {"lx.gs.mount.SGetRideInfo",SGetRideInfo},
        {"lx.gs.mount.SActiveRide",SActiveRide},
        {"lx.gs.mount.SRideGetNotify",SRideGetNotify},
        {"lx.gs.mount.SDeActiveRide",SDeActiveRide},
        {"lx.gs.mount.SBuyRide",SBuyRide},
        {"lx.gs.mount.SRideExpired",SRideExpired},
    })
end

return{
    Start=Start,
    init=init,
    GetRideInfo=GetRideInfo,
    NotAcquired=NotAcquired,
    Ride=Ride,
    JudgeOpenLevel=JudgeOpenLevel,
    SendCDeActiveRide=SendCDeActiveRide,
    SendCActiveRide=SendCActiveRide,
    SendCGetRideInfo=SendCGetRideInfo,
    SendCBuyRide=SendCBuyRide,
    GetActivedRide=GetActivedRide,
    GetRemainRide=GetRemainRide,
    GetAllRide=GetAllRide,
    UnRead=UnRead,
    IsNewGet=IsNewGet,
}
