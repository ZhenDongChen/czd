local require = require
local unpack = unpack
local print = print
local network     = require("network")
local uimanager   = require("uimanager")
local familymgr = require("family.familymanager")
local configmanager = require("cfg.configmanager")

local m_lastOpenTime
local m_lastCallTime
local s_PartySfxName = "sfx/s_changjing_fazhen02.bundle"
local m_gameObjectPartySfx = nil

local function GetLastOpenTime()
    return m_lastOpenTime
end

local function IsOpening()
    local bOpening = false
    local partyInfo = configmanager.getConfig("familyparty")
    if (timeutils.GetServerTime() - GetLastOpenTime()) < partyInfo.duration then
        bOpening = true       
    end
    return bOpening
end

local function IsTodayOpened()
    local timeNow = timeutils.TimeNow()
    local lastTime = os.date("*t", GetLastOpenTime())
    local bTodayOpened = true
    if lastTime.year ~= timeNow.year or lastTime.month ~= timeNow.month or lastTime.day ~= timeNow.day then
        bTodayOpened = false
    end
    return bTodayOpened
end

local function ShowPartySfx()
    if not familymgr.IsInStation() or not IsOpening() or m_gameObjectPartySfx ~= nil then
       return
    end

    local partyInfo = configmanager.getConfig("familyparty")
    Util.Load( s_PartySfxName, define.ResourceLoadType.LoadBundleFromFile,  function(asset_obj) 
        if not IsNull(asset_obj) then
            m_gameObjectPartySfx = GameObject.Instantiate(asset_obj)
			if m_gameObjectPartySfx and m_gameObjectPartySfx.transform then
                m_gameObjectPartySfx.transform.gameObject:SetActive(true)
				m_gameObjectPartySfx.transform:SetParent(nil)-- UnityEngine.GameObject.Find("chapter_9_1").transform
				m_gameObjectPartySfx.transform.localScale = Vector3(partyInfo.effectzoomin.x, partyInfo.effectzoomin.y, partyInfo.effectzoomin.z) --Vector3(3,3,3)
                m_gameObjectPartySfx.transform.localPosition = Vector3(partyInfo.effectposition.x, partyInfo.effectposition.y, partyInfo.effectposition.z) --Vector3(518,4.0,648)
				--m_gameObjectPartySfx.transform.localRotation = Quaternion.identity			
            else
                GameObject.Destroy(m_gameObjectPartySfx.transform.gameObject)
            end
        end
    end)      
end 

local function DestoryPartySfx()
    if m_gameObjectPartySfx then
        Util.Destroy(m_gameObjectPartySfx.transform.gameObject)
        m_gameObjectPartySfx = nil
    end
end 

local function GetLastCallTime()
    return m_lastCallTime
end

local function IsChief()
    return ( ( familymgr.IsChief() or familymgr.IsViceChief() ) )
end

local function COpenFamilyParty()
    network.send(lx.gs.family.msg.COpenFamilyParty(){})
end
 
local function CCallAllFamilyMembers()
    network.send(lx.gs.family.msg.CCallAllFamilyMembers(){})
end


--*******************************************************************
local function onmsg_SOpenFamilyParty(msg)
    m_lastOpenTime = timeutils.GetServerTime()
    m_lastCallTime = timeutils.GetServerTime()
    uimanager.ShowSystemFlyText(LocalString.Family.Party.PartyOpenRe)
    ShowPartySfx()
end

local function onmsg_SCallAllFamilyMembers(msg)
    m_lastCallTime = timeutils.GetServerTime()
end

local function onmsg_SFamilyPartyOpenNotify(msg)
    if msg.openid ~= PlayerRole.Instance().m_Id then
        if not familymgr.IsInStation() then
            uimanager.ShowAlertDlg({
                title        = LocalString.Family.Party.Title, 
                content      = LocalString.Family.Party.EnterNotify,        
                callBackFunc = function()
                    local EctypeManager = require"ectype.ectypemanager"
                    if EctypeManager.IsInEctype() then
                        uimanager.ShowSingleAlertDlg({content=LocalString.Family.FamilyPartyInEctype})
                    else
                        familymgr.CEnterFamilyStation(familymgr.EnterType.OnlyEnter)
                    end 
                end,
                immediate = true,
            })
        end        

        m_lastCallTime = timeutils.GetServerTime()

        local partyInfo = configmanager.getConfig("familyparty")
        if (timeutils.GetServerTime() - m_lastOpenTime ) > (2*partyInfo.duration) then
            m_lastOpenTime = timeutils.GetServerTime()
        end   
        ShowPartySfx()              
    end    
end

local function onmsg_SPartyEndNotify(msg)
    DestoryPartySfx()
end

local function onmsg_SGetFamilyInfo(msg)
    m_lastOpenTime =  math.floor(msg.family.familypartylastopentime/1000)
    m_lastCallTime =  math.floor(msg.family.familypartylastcalltime/1000)
end

local function Logout()
    m_gameObjectPartySfx = nil
end

local function IsInOpenTime()
    local partyInfo = configmanager.getConfig("familyparty")
    local timeNow = timeutils.TimeNow()
	local nowSecsDay = timeutils.getSeconds({days = 0, hours = timeNow.hour ,minutes = timeNow.min,seconds = timeNow.sec})

    local beginSecsDay1 = timeutils.getSeconds({days = 0, hours = partyInfo.starttime[1], 
        minutes = partyInfo.starttime[2], seconds = 0})
    local endSecsDay1 = timeutils.getSeconds({days = 0, hours = partyInfo.endtime[1], 
        minutes = partyInfo.endtime[2], seconds = 0})
    local beginSecsDay2 = timeutils.getSeconds({days = 0, hours = partyInfo.starttime2[1], 
        minutes = partyInfo.starttime2[2], seconds = 0})
    local endSecsDay2 = timeutils.getSeconds({days = 0, hours = partyInfo.endtime2[1], 
        minutes = partyInfo.endtime2[2], seconds = 0})

    local bInOpenTime = false
    if (beginSecsDay1 < nowSecsDay and nowSecsDay < endSecsDay1) or (beginSecsDay2 < nowSecsDay and nowSecsDay < endSecsDay2) then
        bInOpenTime = true
    end

    return bInOpenTime
end

local function UnRead()
   if IsInOpenTime() and not IsTodayOpened() then
       return true
   end
   return false
end

local function init()
    network.add_listeners({
         {"lx.gs.family.msg.SOpenFamilyParty",            onmsg_SOpenFamilyParty}, 
         {"lx.gs.family.msg.SCallAllFamilyMembers",       onmsg_SCallAllFamilyMembers},          

         {"lx.gs.family.msg.SFamilyPartyOpenNotify",      onmsg_SFamilyPartyOpenNotify},
         {"lx.gs.family.msg.SPartyEndNotify",             onmsg_SPartyEndNotify},
         {"lx.gs.family.msg.SGetFamilyInfo",              onmsg_SGetFamilyInfo},          
    })
    gameevent.evt_system_message:add("logout",Logout)
end

return{
    DialogType            = DialogType,
    init                  = init,
    COpenFamilyParty      = COpenFamilyParty,
    CCallAllFamilyMembers = CCallAllFamilyMembers,
    GetLastOpenTime       = GetLastOpenTime,
    GetLastCallTime       = GetLastCallTime,
    IsChief               = IsChief,
    IsInOpenTime          = IsInOpenTime,
    UnRead                = UnRead,
    IsOpening             = IsOpening,
    IsTodayOpened         = IsTodayOpened,
    ShowPartySfx          = ShowPartySfx,
    DestoryPartySfx       = DestoryPartySfx,
}
