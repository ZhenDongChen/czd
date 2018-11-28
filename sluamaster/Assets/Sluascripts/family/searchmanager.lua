local network = require("network")
local uimanager = require("uimanager")
local mgr = require("family.familymanager")
local player = require("character.playerrole"):Instance()
local Utils=require "common.utils"
local List_Server_Per_Size = 20

local m_IsReady = false
local m_Callback
local m_Applied = {}
local m_IsListEnd = false

local function IsReady()
    return m_IsReady
end

local function GetReady(callback)
    if not m_IsReady then
        m_Callback = callback
        network.send(lx.gs.family.msg.CGetRequestedFamily())
    else
        callback()
    end
end

local function Release()
    m_IsReady = false
    m_IsListEnd = false
end

local function IsListEnd()
    return m_IsListEnd
end

local function IsApplying(familyid)
    return m_Applied[familyid] ~= nil
end

local m_CreateCallback
local function CreateFamily(name, callback)
    m_CreateCallback = callback
    network.send(lx.gs.family.msg.CCreateFamily(){familyname=name})
end

local m_SearchCallback



local function Search(type, number, str, start, callback)
    m_SearchCallback = callback
    if start then
        m_IsListEnd = false
    end
    List_Server_Per_Size = number or List_Server_Per_Size
    local type_in = type or lx.gs.family.msg.CFindFamily.ALL
    network.send(lx.gs.family.msg.CFindFamily({familyname = str,ftype = type_in ,startindex = start, num = List_Server_Per_Size}))
end

local function IsApplyVacant()
    return getn(m_Applied) < cfg.family.FamilyInfo.MAX_APPLY_NUM
end

local m_ApplyCallback
local function ApplyFamily(id, callback)
    if not IsApplyVacant() then
        uimanager.ShowSingleAlertDlg({title=LocalString.Family.TagWarn, content=LocalString.Family.ContentApplyFull})
        callback()
        return
    end
    m_ApplyCallback = callback
    network.send(lx.gs.family.msg.CRequestJoinFamily(){familyid=id})
end

local m_ApplyAllCallback
local function ApplyAllFamily(callback)
    m_ApplyAllCallback = callback
    network.send(lx.gs.family.msg.CRequestJoinAllFamily(){})
end

local m_CancelCallback
local function CancelApplyFamily(id, callback)
    m_CancelCallback = callback
    network.send(lx.gs.family.msg.CCancelRequestJoinF(){familyid=id})
end

local m_SearchFundingCallback
local function SearchFunding(name, callback)
    m_SearchFundingCallback = callback
    network.send(lx.gs.family.msg.CGetCrowdInfo(){familyname=name})
end

local m_StartFundCallback
local function StartFunding(name, callback)
    m_StartFundCallback = callback
    network.send(lx.gs.family.msg.CCrowdFamily(){familyname=name,inityuanbao=cfg.family.FamilyInfo.MIN_CROWD_FUND_YUANBAO})
end

local m_AddFundCallback
local function AddFunding(id, amount, callback)
    m_AddFundCallback = callback
    network.send(lx.gs.family.msg.CAddMoney(){crowfamilyid=id,amount=amount})
end

local m_CancelFundCallback
local function CancelFunding(callback)
    m_CancelFundCallback = callback
    network.send(lx.gs.family.msg.CCancelCrowdFamily())
end


local function SortFunc(itemA, itemB)
    if itemA.flevel < itemB.flevel then 
        return false
    else
        if itemA.curlvlbuilddegree > itemB.curlvlbuilddegree then
            return  true
        else
            return false
        end
    end
end

local function init()

    network.add_listeners({
        {"lx.gs.family.msg.SGetRequestedFamily", function(msg)
             m_Applied = {}
             for i,familyid in ipairs(msg.ids) do
                 m_Applied[familyid] = true
             end
             m_IsReady = true
             if m_Callback then
                 m_Callback()
                 m_Callback = nil
             end
        end},
        {"lx.gs.family.msg.SFindFamily", function(msg)
             if m_SearchCallback then
                 Utils.table_sort(msg.families, SortFunc)
                 m_SearchCallback(msg.families, msg.startindex)
                 if #msg.families < List_Server_Per_Size or msg.startindex == 61 then --ȡ��60~80����ʱ����
                     m_IsListEnd = true
                 end
             end
        end},
        {"lx.gs.family.msg.SRequestJoinFamily", function(msg)
             m_Applied[msg.familyid] = true
             if m_ApplyCallback then
                 m_ApplyCallback(msg)
             end
        end},
        {"lx.gs.family.msg.SRequestJoinAllFamily", function(msg)
             for i,familyid in ipairs(msg.familyids) do
                 m_Applied[familyid] = true
             end
             if m_ApplyAllCallback then
                 m_ApplyAllCallback(msg)
             end
        end},
        {"lx.gs.family.msg.SCancelRequestJoinF", function(msg)
             m_Applied[msg.familyid] = nil
             if m_CancelCallback then
                 m_CancelCallback(getn(m_Applied) + 1 >= cfg.family.FamilyInfo.MAX_APPLY_NUM)
             end
        end},
        {"lx.gs.family.msg.SCreateFamily", function(msg)
             uimanager.ShowSystemFlyText(LocalString.Family.HintCreateFamilySuccess)
             mgr.Release()
             mgr.GetReady(function()
                     if m_CreateCallback then
                         m_CreateCallback()                         
                     end
                     uimanager.call("dlguimain","RefreshTaskList")  
             end)                                  
        end},
        {"lx.gs.family.msg.SGetCrowdInfo", function(msg)
             if m_SearchFundingCallback then
                 m_SearchFundingCallback(msg.crowdfamilylist)
             end
        end},
        {"lx.gs.family.msg.SCrowdFamily", function(msg)
             for key, value in pairs(m_Applied) do      
                 m_Applied[key] = nil
             end  
             if m_StartFundCallback then
                 m_StartFundCallback()
             end             
        end},
        {"lx.gs.family.msg.SAddMoney", function(msg)
             if m_AddFundCallback then
                 m_AddFundCallback()
             end
        end},
        {"lx.gs.family.msg.SCancelCrowdFamily", function(msg)
             if m_CancelFundCallback then
                 m_CancelFundCallback()
             end
        end},

        -- notify
        {"lx.gs.family.msg.SRejectRequestJoinFNotify", function(msg)
             if m_IsReady then
                 if msg.memberid == player:GetId() then
                     m_Applied[msg.family.familyid] = nil
                 end
             end
        end},

    })
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    Search              = Search,
    IsApplying          = IsApplying,
    IsApplyVacant       = IsApplyVacant,
    Create              = CreateFamily,
    ApplyFamily         = ApplyFamily,
    ApplyAllFamily      = ApplyAllFamily,
    CancelApplyFamily   = CancelApplyFamily,
    SearchFunding       = SearchFunding,
    StartFunding        = StartFunding,
    AddFunding          = AddFunding,
    CancelFunding       = CancelFunding,
    IsListEnd           = IsListEnd,
}
