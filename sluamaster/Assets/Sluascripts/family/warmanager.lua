local network = require("network")
local gameevent = require("gameevent")
local uimanager = require("uimanager")
local activitytipmanager=require("ui.activity.activitytipmanager")
local configmanager = require("cfg.configmanager")
local FamilyRoundRobinManager = require("family.familyroundrobinmanager")
local Utils=require "common.utils"

local m_Callback
local m_OnlineMemberNum = 1
local m_CurBattleInfo1 = {}
local m_CurBattleInfo2 = {}
local m_CurBattleInfo3 = {}
local m_CurBattleInfo4 = {}
local m_CandidateFamilyList = {}
local m_CandidateFamilyListTotalNum = 0
local m_ChallengeFamilyList = {}
local m_MyFamilyWarInfo = {}
local m_FamilyWarHistory = {}

local function IsWarStart()
    if m_MyFamilyWarInfo ~= nil and m_MyFamilyWarInfo.isinwar == 1 then
        return true
    end
    return false
end


local function SortFunc(itemA, itemB)
    if itemA.showinfo.level > itemB.showinfo.level then 
        return  true
    else
        return false
    end
end

local function GetFamilyWarHistory()
    return m_FamilyWarHistory
end

local function GetMyFamilyWarInfo()
    return m_MyFamilyWarInfo
end

local function GetChallengeFamilyList()
    return m_ChallengeFamilyList
end

local function GetCandidateFamilyList()
    return m_CandidateFamilyList
end

local function GetCandidateFamilyListTotalNum()
    return m_CandidateFamilyListTotalNum
end 

local function GetCurBattleInfo1()
    return m_CurBattleInfo1
end

local function GetCurBattleInfo3()
    return m_CurBattleInfo3
end

local function GetCurBattleInfo4()
    return m_CurBattleInfo4
end

local function SetCurBattleInfo1Remaintime(lefttime)
    m_CurBattleInfo1.remaintime = lefttime
end

local function SetCurBattleInfo2Remaintime(lefttime)
    m_CurBattleInfo2.remaintime = lefttime
end

local function SetCurBattleInfo3Remaintime(lefttime)
    m_CurBattleInfo3.remaintime = lefttime
end

local function SetCurBattleInfo4Remaintime(lefttime)
    m_CurBattleInfo4.remaintime = lefttime
end

local function GetCurBattleInfo2()
    return m_CurBattleInfo2
end

local function GetOnlineMemberNum()
    return m_OnlineMemberNum
end

local function Release()
end

local function ClearCandidateFamilyList()
    m_CandidateFamilyList = {}
    m_CandidateFamilyListTotalNum = 0
end

local m_CallbackGetFamilyWarStatus
local function CGetFamilyWarStatus(callback)
    m_CallbackGetFamilyWarStatus = callback
    network.send(lx.gs.family.msg.CGetFamilyWarStatus(){})
end

local m_CallbackGetFamilyWarStatus2
local function CGetFamilyWarStatus2(callback)
    m_CallbackGetFamilyWarStatus2 = callback
    network.send(lx.gs.family.msg.CGetFamilyWarStatus2(){})
end

local function OpenFaDetailDlg()
    m_CurBattleInfo1 = {}
    m_CurBattleInfo2 = {}
    m_CurBattleInfo3 = {}
    m_CurBattleInfo4 = {}
    local TabFaDetail = require("ui.family.tabfadetail")
    CGetFamilyWarStatus2(function() uimanager.showdialog("family.tabfadetail",{type = TabFaDetail.DlgType.FamilyWar}) end )
   
	-- network.send(lx.gs.family.msg.CEnterFamilyWar(){ battlefieldid = fieldid })
end

local function OpenAboutWarDlg()
    
    if m_MyFamilyWarInfo.isinwar == 1 then
        -- CGetFamilyWarStatus2(function() uimanager.showdialog("family.tabfadetail",{type = TabFaDetail.DlgType.FamilyWar}) end )
        OpenFaDetailDlg()
    else
        CGetFamilyWarStatus(function() uimanager.showdialog("family.tababoutwar") end )
    end  
end

local m_CallbackGetCandidateList
local function CGetFamilyWarCandidateList(curStartIndex, pageNum, callback)
    m_CallbackGetCandidateList = callback
    network.send(lx.gs.family.msg.CGetFamilyWarCandidateList(){startindex=curStartIndex, familynum = pageNum})
end

local function CFamilyWarChallenge(familyid)
    network.send(lx.gs.family.msg.CFamilyWarChallenge(){ opponentfamilyid = familyid })
end

local function CFamilyWarResponse(familyid)
    network.send(lx.gs.family.msg.CFamilyWarResponse(){ opponentfamilyid = familyid})
end

local function CEnterFamilyWar(fieldid)
    network.send(lx.gs.family.msg.CEnterFamilyWar(){ battlefieldid = fieldid })
end

local function IsInOpenTime()
    local timeNow = timeutils.TimeNow()
	local nowSecsDay = timeutils.getSeconds({days = 0, hours = timeNow.hour ,minutes = timeNow.min,seconds = timeNow.sec})
    local beginSecsDay = timeutils.getSeconds({days = 0, hours = 12, minutes = 0, seconds = 0})
    local endSecsDay   = timeutils.getSeconds({days = 0, hours = 23, minutes = 0, seconds = 0})

    --if timeNow.wday == 1 or timeNow.wday == 3 or timeNow.wday == 5 then
        local bInOpenTime = false
        if ( nowSecsDay > beginSecsDay and nowSecsDay < endSecsDay ) then
            bInOpenTime = true
        end
    --end
    return bInOpenTime
end

local function UnRead()
    local familywarConfig = configmanager.getConfig("familywar")
    -- if m_MyFamilyWarInfo.todayfamilywarnum >= familywarConfig.daychallengenum then
    --     return false
    -- end
    if m_MyFamilyWarInfo.isinwar == 1 then
        return true
    end
    for id, familyinfo in pairs(m_ChallengeFamilyList) do
        local leftTimeSeces = familyinfo.expiretime/1000 - timeutils.GetServerTime()
        if leftTimeSeces > 0 then
            return true
        end
    end

    return false
end

local function update()
    if IsWarStart() then
        if not activitytipmanager.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.FAMILYGATHERS) then
            activitytipmanager.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.FAMILYGATHERS,nil,function ()
                OpenAboutWarDlg()
            end)
        end
    else
        -- if  activitytipmanager.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.FAMILYGATHERS) then
        --     activitytipmanager.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.FAMILYGATHERS)
        -- end
    end
end

local function OnLogout()
    m_CurBattleInfo1 = {}
    m_CurBattleInfo2 = {}
    m_CurBattleInfo3 = {}
    m_CurBattleInfo4 = {}
    m_CandidateFamilyList = {}
    m_CandidateFamilyListTotalNum = 0
    m_ChallengeFamilyList = {}
    m_MyFamilyWarInfo = {}
    m_FamilyWarHistory = {}
end


local function init()
    gameevent.evt_system_message:add("logout", OnLogout)

    network.add_listeners({
        {"lx.gs.family.msg.SGetFamilyWarStatus", function(msg) 
            m_OnlineMemberNum = msg.onlinemembernum   
            if m_CallbackGetFamilyWarStatus then
                 m_CallbackGetFamilyWarStatus()
                 m_CallbackGetFamilyWarStatus = nil
             end        
        end},
        {"lx.gs.family.msg.SGetFamilyWarStatus2", function(msg)  
            if msg.battleid == 1 then
                m_CurBattleInfo1 = msg
            elseif msg.battleid == 2 then
                m_CurBattleInfo2 = msg
            elseif msg.battleid == 3 then
                m_CurBattleInfo3 = msg
            elseif msg.battleid == 4 then
                m_CurBattleInfo4 = msg
            end
            if m_CallbackGetFamilyWarStatus2 then
                 m_CallbackGetFamilyWarStatus2()
                 m_CallbackGetFamilyWarStatus2 = nil
            end
            if uimanager.isshow("family.tabfadetail") then
                uimanager.refresh("family.tabfadetail")
            end                  
        end},
        {"lx.gs.family.msg.SGetFamilyWarCandidateList", function(msg)
            if msg then
                m_CandidateFamilyListTotalNum = msg.totalnum
                for id, list in pairs(msg.families) do
                    m_CandidateFamilyList[#m_CandidateFamilyList + 1] = list
                end
                Utils.table_sort(m_CandidateFamilyList, SortFunc)
            end
            if m_CallbackGetCandidateList then
                 m_CallbackGetCandidateList()
                 m_CallbackGetCandidateList = nil
            end   
        end},     

        -- notify
        {"lx.gs.family.msg.SFamilyWarInfo", function(msg) --receive when change
			 printyellow("!!!!!!!!!!!!!!!!!!!!!!!!!!!SFamilyWarInfo!!!!!!!!!")
            local oldWarInfo = m_MyFamilyWarInfo
            m_MyFamilyWarInfo = msg.info
            if uimanager.isshow("family.tababoutwar") and m_MyFamilyWarInfo.isinwar == 1 then
                uimanager.hidedialog("family.tababoutwar")
                OpenFaDetailDlg()
            end

           if not uimanager.isshow("family.tabfadetail") and oldWarInfo  and  m_MyFamilyWarInfo.isinwar == 1 then
                local EctypeManager = require("ectype.ectypemanager")
                if not EctypeManager.IsInEctype() then
                    uimanager.ShowAlertDlg({
                        title        = LocalString.Family.AboutWarTitle,
                        content      = LocalString.Family.AboutWarEnterNotify,
                        callBackFunc = function()
                            if m_MyFamilyWarInfo.isinwar == 1 then
                                 OpenFaDetailDlg()
                            else
                                uimanager.ShowSystemFlyText(LocalString.Family.AboutWarEnd)
                            end                            
                        end,
                        immediate = true,
                    })
                end
            end
        end},

        {"lx.gs.family.msg.SFamilyWarInfo2", function(msg) --receive when login
            printyellow("######################################SFamilyWarInfo2")
            m_MyFamilyWarInfo = msg.info
            m_ChallengeFamilyList = msg.challengemes
            m_FamilyWarHistory = msg.histories
        end},

        {"lx.gs.family.msg.SNewFamilyWarChallengeMe", function(msg)
            m_ChallengeFamilyList[#m_ChallengeFamilyList+1] = msg.challenge
        end},

        {"lx.gs.family.msg.SNewFamilyWarHistory", function(msg)
            m_FamilyWarHistory[#m_FamilyWarHistory +1] = msg.history
        end},

        {"lx.gs.family.msg.SRefuseFamilyWarChallengeMe", function(msg)
        end},

        {"lx.gs.family.msg.SNewFamilyWarMyChallenge", function(msg)
            for id, list in pairs(m_CandidateFamilyList) do
                if list.showinfo.id == msg.opponentfamilyid then
                    list.canchallenge = 0
                    break
                end
            end
            if uimanager.isshow("family.tababoutwar") then
                uimanager.refresh("family.tababoutwar")
            end            
        end},

        
        {"lx.gs.family.msg.SEndFamilyWar", function(msg) 
              m_MyFamilyWarInfo.isinwar = 0
        end},

    })
    gameevent.evt_update:add(update)
end

return{
    init                = init,
    update              = update,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    UnRead              = UnRead,
    Search              = Search,
    OpenAboutWarDlg     = OpenAboutWarDlg,
    OpenFaDetailDlg     = OpenFaDetailDlg,
    CGetFamilyWarStatus = CGetFamilyWarStatus,
    CGetFamilyWarStatus2= CGetFamilyWarStatus2,
    CFamilyWarChallenge = CFamilyWarChallenge,
    CFamilyWarResponse  = CFamilyWarResponse,
    CEnterFamilyWar     = CEnterFamilyWar,
    GetOnlineMemberNum  = GetOnlineMemberNum,
    GetCurBattleInfo1   = GetCurBattleInfo1,
    GetCurBattleInfo2   = GetCurBattleInfo2,
    GetCurBattleInfo3   = GetCurBattleInfo3,
    GetCurBattleInfo4   = GetCurBattleInfo4,
    GetCandidateFamilyList = GetCandidateFamilyList,
    GetMyFamilyWarInfo  = GetMyFamilyWarInfo,
    GetFamilyWarHistory = GetFamilyWarHistory,
    IsInOpenTime        = IsInOpenTime,
    IsWarStart          = IsWarStart,
    ClearCandidateFamilyList       = ClearCandidateFamilyList,
    GetChallengeFamilyList         = GetChallengeFamilyList,
    CGetFamilyWarCandidateList     = CGetFamilyWarCandidateList,
    SetCurBattleInfo1Remaintime    = SetCurBattleInfo1Remaintime,
    SetCurBattleInfo2Remaintime    = SetCurBattleInfo2Remaintime,
    SetCurBattleInfo3Remaintime    = SetCurBattleInfo3Remaintime,
    SetCurBattleInfo4Remaintime    = SetCurBattleInfo4Remaintime,
    GetCandidateFamilyListTotalNum = GetCandidateFamilyListTotalNum,
}
