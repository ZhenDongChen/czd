local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local applymgr = require("family.applymanager")
local familymgr = require("family.familymanager")

local fields

local function showtab(params)
    applymgr.GetReady(function()
        uimanager.show("family.tabapply", params)
    end)
end

local function show()
    familymgr.CheckAllFamilyDlgHide()
end

-- local function hidetab()
-- end

local function hide()
    applymgr.Release()
    require("ui.dlguimain").RefreshRedDotType(cfg.ui.FunctionList.FAMILY)
end

local function destroy()
end

local m_ApplyIDList
local function refresh(params)  
    m_ApplyIDList = keys(applymgr.Applys())
    local wrapContent = fields.UIList_Apply.gameObject:GetComponent("UIWrapContentList")
    if wrapContent then
        local index = wrapContent:GetCenterOnIndex()
        wrapContent:SetDataCount(#m_ApplyIDList)      
        wrapContent:Refresh()
        wrapContent:CenterOnIndex(index)
    end
    fields.UIGroup_Empty.gameObject:SetActive((#m_ApplyIDList)==0)
    --ˢ�º���
    require("ui.dlgdialog").RefreshRedDot("family.dlgfamily")
end

-- local function update()
-- end


local function init(params)
    name, gameObject, fields = unpack(params)
    if familymgr.CanSeeApply() then
        fields.UILabel_Empty.text = LocalString.Family.CanSesApplyListEmpty
    else
        fields.UILabel_Empty.text = LocalString.Family.CannotSesApplyList 
    end

    EventHelper.SetWrapListRefresh(fields.UIList_Apply.gameObject:GetComponent("UIWrapContentList"), function(item, itemi, i)
        if not m_ApplyIDList or i > #m_ApplyIDList then return end
        local roleid = m_ApplyIDList[i]
        local apply = applymgr.Applys()[roleid]
        if not apply then return end
        item.Id = apply.roleid
        item.Data = apply

        item.Controls["UITexture_Head"]:SetIconTexture(ConfigManager.GetHeadIcon(apply.profession, apply.gender))
        item.Controls["UISprite_VIP"].gameObject:SetActive(apply.viplevel > 0)
        item.Controls["UILabel_VIP"].text = apply.viplevel > 0 and apply.viplevel or ""
        item.Controls["UILabel_LV"].text = string.format("等级.%d", apply.level)
        item.Controls["UILabel_Name"].text = apply.name
        item.Controls["UILabel_Fight"].text = apply.combatpower
        item.Controls["UILabel_LastLogin"].gameObject:SetActive(false)
    end)

    for i = 0,fields.UIList_Apply.Count-1 do
        local item = fields.UIList_Apply:GetItemByIndex(i)
        EventHelper.SetClick(item.Controls["UIButton_Agree"], function()
            local apply = item.Data
            uimanager.showloading()
            applymgr.AcceptApply(apply.roleid, function()
                refresh()
                uimanager.hideloading()
            end)

            --[[uimanager.ShowAlertDlg({
                title=LocalString.Family.TagWarn,
                immediate = true,
                content=string.format(LocalString.Family.TextAcceptApply, apply.name), callBackFunc=function()
                    uimanager.showloading()
                    applymgr.AcceptApply(apply.roleid, function()
                        refresh()
                        uimanager.hideloading()
                    end)
            end})]]
        end)
        EventHelper.SetClick(item.Controls["UIButton_Disagree"], function()
            local apply = item.Data
            uimanager.showloading()
            applymgr.RejectApply(apply.roleid, function()
                refresh()
                uimanager.hideloading()
            end)

            --[[uimanager.ShowAlertDlg({title=LocalString.Family.TagWarn,
                immediate = true,
                content=string.format(LocalString.Family.TextRejectApply, apply.name), callBackFunc=function()
                    uimanager.showloading()
                    applymgr.RejectApply(apply.roleid, function()
                        refresh()
                        uimanager.hideloading()
                    end)
            end})]]
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
}
