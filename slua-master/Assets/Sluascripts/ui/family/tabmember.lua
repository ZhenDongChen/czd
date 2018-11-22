local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local mgr = require("family.familymanager")
local membermgr = require("family.membermanager")
local player = require("character.playerrole"):Instance()

local fields
local m_MemberIDList
local m_bHasAdjustPopupList
local m_isCheckOperation = false

local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")

local function showtab(params)
    membermgr.GetReady(function()
        uimanager.show("family.tabmember", params)
    end)
end

local function show()
    mgr.CheckAllFamilyDlgHide()

    m_MemberIDList = keys(membermgr.Members())
    local wrapContent = fields.UIList_Member.gameObject:GetComponent("UIWrapContentList")
    if not m_isCheckOperation then
        if wrapContent then
            wrapContent:SetDataCount(#m_MemberIDList)
            wrapContent:CenterOnIndex(0)
            wrapContent:Refresh()
        end       
    else
        m_isCheckOperation = false
    end    
end

-- local function hidetab()
-- end

local function hide()
    if not m_isCheckOperation then
        membermgr.Release()
    end   
end

local function destroy()
end



local function refresh(params)
    m_MemberIDList = keys(membermgr.Members())

    utils.table_sort(m_MemberIDList, function(a,b)       
        local membera = membermgr.Members()[a]
        local memberb = membermgr.Members()[b]
        local joba = membera.familyjob
        local jobb = memberb.familyjob
        if memberb.roleid == player:GetId() then
            return false
        elseif membera.roleid == player:GetId() then
            return true
        else
            if joba ~= 0 and jobb ~= 0 then
                if joba > jobb  then
                    return false
                end           
            elseif joba == 0 and jobb ~= 0 then
                return false
             elseif joba ~= 0 and jobb == 0 then
                return true
            else
                if membera.isonline == 0 and memberb.isonline == 1 then
                    return false
                elseif membera.isonline == 0 and memberb.isonline == 0 then
                    return membera.level > memberb.level
                elseif membera.isonline == 1 and memberb.isonline == 1 then
                    return membera.level > memberb.level
                end
            end
        end
        return true
    end)
   
     local wrapContent = fields.UIList_Member.gameObject:GetComponent("UIWrapContentList")
     if wrapContent then
        wrapContent:RefreshWithOutSort()
     end    
end

local function update()
   
    if UIPopupList.isOpen and m_bHasAdjustPopupList == false then 
       
        local panelArray = fields.UIGroup_Member.gameObject:GetComponentsInChildren("UIPanel")
      
        for i=1,panelArray.Length do
            local panel = panelArray[i]
            if panel and panel.name == "Drop-down List" then
                panel.gameObject.transform.parent = fields.UILabel_PopupListPoint.gameObject.transform
                panel.gameObject.transform.localPosition = Vector3.zero
            end
        end
        m_bHasAdjustPopupList = true
    else 
        if not UIPopupList.isOpen then
            m_bHasAdjustPopupList = false
        end        
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)
    m_bHasAdjustPopupList = false

    EventHelper.SetWrapListRefresh(fields.UIList_Member.gameObject:GetComponent("UIWrapContentList"), function(item, itemi, i)
        if not m_MemberIDList or i > #m_MemberIDList then return end
        local roleid = m_MemberIDList[i]
        local member = membermgr.Members()[roleid]
        if not member then return end
        item.Id = member.roleid
        item.Data = member

        --item.Controls["UISprite_Role"].gameObject:SetActive(member.roleid == player:GetId())
        local texture = item.Controls["UITexture_Head"]
        texture:SetIconTexture(ConfigManager.GetHeadIcon(member.professiontype, member.gender))
        if member.isonline == 0 then
            texture.shader = inactiveShader
            item.Controls["UILabel_LastLogin"].text = timeutils.PeriodFromNow(member.lastonlinetime)
        else
            texture.shader = activeShader
        end
        item.Controls["UILabel_LastLogin"].gameObject:SetActive(member.isonline == 0)
        item.Controls["UILabel_Online"].gameObject:SetActive(member.isonline ~= 0)
        item.Controls["UISprite_Me"].gameObject:SetActive(member.roleid == player:GetId())

        item.Controls["UISprite_VIP"].gameObject:SetActive(member.viplevel > 0)
        item.Controls["UILabel_VIP"].text = member.viplevel > 0 and member.viplevel or ""
        item.Controls["UILabel_LV"].text = string.format("%d", member.level)
        item.Controls["UILabel_Name"].text = member.rolename
        item.Controls["UILabel_Fight"].text = member.attackpower
        local labeljob = item.Controls["UILabel_Job"]
        labeljob.text = membermgr.JobId2Str(member.familyjob)
        item.Controls["UILabel_ContribToday"].text = member.dailybuild
        item.Controls["UILabel_ContribAll"].text = member.pcontribution
        item.Controls["UIButton_Check"].gameObject:SetActive(member.roleid ~= player:GetId())
        item.Controls["UIButton_Quit"].gameObject:SetActive(member.roleid == player:GetId())

        item.Controls["UIButton_Appoint"].gameObject:SetActive(mgr.CanAppoint(member.familyjob))
        local listJob = item.Controls["UIButton_Appoint"].gameObject:GetComponent("UIPopupList")
        if not listJob then
            -- printyellow("can find the uipopuplist")
            return
        end
        listJob:Clear()
        if mgr.IsChief() then
            listJob:AddItem(membermgr.JobId2Str(cfg.family.FamilyJobEnum.CHIEF), {member = member, jobid = cfg.family.FamilyJobEnum.CHIEF})
        end
        for jobid,_ in pairs(mgr.CanAppointJobs()) do
            if jobid ~= member.familyjob and membermgr.IsJobVacant(jobid) then
                listJob:AddItem(membermgr.JobId2Str(jobid), {member = member, jobid = jobid})
            end
        end
        
    end)

    for i = 0,fields.UIList_Member.Count-1 do
        local item = fields.UIList_Member:GetItemByIndex(i)
        local listjob = item.Controls["UIButton_Appoint"].gameObject:GetComponent("UIPopupList")
        if not listjob then
            -- printyellow("can find the uipopuplist")
            break
        end
        EventHelper.SetClick(item.Controls["UIButton_Check"], function()
            m_isCheckOperation = true
            local wrapContent = fields.UIList_Member.gameObject:GetComponent("UIWrapContentList")
            local member = item.Data
            uimanager.showdialog("otherplayer.dlgotherroledetails", {roleId = item.Id, buttons =  mathutils.TernaryOperation(
                mgr.CanKickout(member.familyjob),
                {[1]={name=LocalString.Family.TagKickout, action=function(role)
                          uimanager.ShowAlertDlg({title=LocalString.Family.TagWarn, 
                            immediate = true,
                            content=string.format(LocalString.Family.ContentKickout, member.rolename), callBackFunc=function()
                              uimanager.showloading()
                              membermgr.Kickout(member.roleid, function(roleid)
                                  show()
                                  refresh()
                                  uimanager.hidedialog("otherplayer.dlgotherroledetails")
                                  uimanager.hideloading()
                              end)
                          end})
                end}},
                nil)})
        end)
        EventHelper.SetClick(item.Controls["UIButton_Quit"], function()
            uimanager.ShowAlertDlg({title=LocalString.Family.TitleQuitFamily, 
                immediate = true,
                content=LocalString.Family.ContentQuitFamily, callBackFunc=function()
                mgr.QuitFamily(function()
                        uimanager.hidecurrentdialog()
                        require("ui.dlguimain").RefreshRedDotType(cfg.ui.FunctionList.FAMILY)
                end)
            end})
        end)
        EventHelper.SetPopupListOnChange(listjob, function(popuplist)
            if not UIPopupList.isOpen then return end
            local member = popuplist.data.member
            local jobid = popuplist.data.jobid
            uimanager.ShowAlertDlg({title=LocalString.Family.TagWarn, 
                immediate = true,
                content=string.format(LocalString.Family.ContentAppoint, member.rolename, membermgr.JobId2Str(jobid)), callBackFunc=function()
                uimanager.showloading()
                if jobid == cfg.family.FamilyJobEnum.CHIEF then
                    membermgr.TransferChief(member.roleid, function()
                        refresh()
                        uimanager.hideloading()
                    end)
                else
                    membermgr.Appoint(member.roleid, jobid, function(jobid)
                        refresh()
                        uimanager.hideloading()
                    end)
                end
            end})
        end)
    end
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    showtab      = showtab,
    show         = show,
    hide         = hide,
    refresh      = refresh,
    destory      = destory,
    init         = init,
    uishowtype   = uishowtype,
    update       = update,
}
