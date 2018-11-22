local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local mgr = require("family.familymanager")
local searchmgr = require("family.searchmanager")
local player = require("character.playerrole"):Instance()
local ItemManager = require("item.itemmanager")
local ConfigManager=require"cfg.configmanager"

local fields
local name

local m_CurFamilyStr
local m_CurFamilies
local m_SearchFamilyStr

local m_CurFundingStr
local m_CurFundings

local RefreshPageFamilyList
local RefreshPageFunding
local DeclareWarMode = false
local CurrentPage = 1
local searchState = false
local CdTime = 120
local CdTable = {}

local function PopupFundingConflict()
    --[[uimanager.ShowAlertDlg({title=LocalString.Family.TagCancelFunding,
                                                         immediate = true,
                                                         content=string.format(LocalString.Family.Fund.TextNeedCancelFunding, cfg.family.FamilyInfo.FUND_FAILED_COST*100),
                                                         callBackFunc=function()
                                                             searchmgr.CancelFunding(function()
                                                                     if fields.UIToggle_Funding.value then
                                                                         SearchFunding("")
                                                                     end
                                                             end)
                                 end})]]
end

local function CmpRank(a,b)
    if a.totalbuilddegree < b.totalbuilddegree then
        return false
    end
    return true
end 
local function CmpRankWar(a,b)

end

local m_Searching = false
local pagesType = {
    [1] = lx.gs.family.msg.CFindFamily.ALL,
    [2] = lx.gs.family.msg.CFindFamily.DECLARE_WAR_MY_DECLARE,
    [3] = lx.gs.family.msg.CFindFamily.DECLARE_WAR_DECLARE_ME,
    [4] = lx.gs.family.msg.CFindFamily.DECLAR_WAR_NOT_DECLARE,
}

local function Search(str, startindex, focusindex)
    uimanager.showloading()
    --[[if m_Searching then
        return
    end
    m_Searching = true]]
    local isFristGet = false
    if not startindex or str ~= "" then
        startindex = 1
        isFristGet = true
    end
    printyellow("CurrentPage:" .. tostring(CurrentPage))
    searchmgr.Search(pagesType[CurrentPage], nil, str, startindex, function(familylist,getStartIndex)
                   if not isFristGet and  m_CurFamilies and getStartIndex < #m_CurFamilies then
                       return
                   end

                   if isFristGet then
                       m_CurFamilies = familylist
                   else
                       for key, value in pairs(familylist) do   
                           table.insert(m_CurFamilies, value)   
                       end                       
                   end    
                   if DeclareWar then
                        utils.table_sort(m_CurFamilies,CmpRankWar)
                   else            
                        utils.table_sort(m_CurFamilies,CmpRank)
                    end
                   --if fields.UIToggle_Join.value then
                       RefreshPageFamilyList()
                       local wrapContent = fields.UIList_Family.gameObject:GetComponent("UIWrapContentList")
                       if not isFristGet and focusindex then                                                    
                           wrapContent:Refresh()
                           wrapContent:CenterOnIndex(focusindex)
                       else 
                           wrapContent:CenterOnIndex(0)
                       end
                   --end
                   --m_Searching = false
                   uimanager.hideloading()
    end)
end

local function SearchFunding(str)
    --[[uimanager.showloading()
    if m_Searching then
        return
    end
    m_Searching = true
    searchmgr.SearchFunding(str, function(familylist)
                   m_CurFundings = familylist
                   if fields.UIToggle_Funding.value then
                       RefreshPageFunding()
                       local initedi = 1
                       for i,data in ipairs(familylist) do
                           if data.initroleid == player:GetId() then
                               initedi = i
                           end
                       end
                       fields.UIList_Funding.gameObject:GetComponent("UIWrapContentList"):CenterOnIndex(initedi-1)
                   end
                   m_Searching = false
                   uimanager.hideloading()
    end)]]
end

local function RefreshFamilyItemButton(item)
    if DeclareWarMode == true and mgr.InFamily() then
        item.Controls["UILabel_Apply"].gameObject:SetActive(false)
        item.Controls["UILabel_DeclareWar"].gameObject:SetActive(true)
        item.Controls["UILabel_Cancel"].gameObject:SetActive(false)
        item.Controls["UILabel_CancelWar"].gameObject:SetActive(true)

        if item.Id ~= PlayerRole:Instance().m_FamilyID then

            item.Controls["UIButton_Apply"].gameObject:SetActive(not mgr.IsDeclaredWar(item.Id))
            item.Controls["UIButton_Cancel"].gameObject:SetActive(mgr.IsDeclaredWar(item.Id))
            
            item.Controls["UIButton_Apply"].isEnabled = mgr.CanChangeWarState()
            item.Controls["UIButton_Cancel"].isEnabled = mgr.CanChangeWarState()
        else
            item.Controls["UIButton_Apply"].gameObject:SetActive(true)
            item.Controls["UIButton_Cancel"].gameObject:SetActive(false)

            
            item.Controls["UIButton_Apply"].isEnabled = false
            item.Controls["UIButton_Cancel"].isEnabled = false
        end

    else
        item.Controls["UILabel_Apply"].gameObject:SetActive(true)
        item.Controls["UILabel_DeclareWar"].gameObject:SetActive(false)
        item.Controls["UILabel_Cancel"].gameObject:SetActive(true)
        item.Controls["UILabel_CancelWar"].gameObject:SetActive(false)

        item.Controls["UIButton_Apply"].gameObject:SetActive(not mgr.InFamily() and not searchmgr.IsApplying(item.Id))
        item.Controls["UIButton_Cancel"].gameObject:SetActive(not mgr.InFamily() and searchmgr.IsApplying(item.Id))
    end
end

RefreshPageFamilyList = function()
    fields.UIButton_OneKeyApply.gameObject:SetActive(not mgr.InFamily())
	local temp =  fields.UIList_Family.gameObject.transform:GetComponent("UIWrapContentList")
	if temp == nil then
		print("UIWrapContentList")
	end
    fields.UIList_Family.gameObject.transform:GetComponent("UIWrapContentList"):SetDataCount(m_CurFamilies and #m_CurFamilies or 0)

    if m_CurFamilies and (#m_CurFamilies == 0) then
        if DeclareWarMode then
            fields.UIGroup_Empty.gameObject:SetActive(false)
            fields.UILabel_FamilyEmptyEx.gameObject:SetActive(true)
        else
            fields.UIGroup_Empty.gameObject:SetActive(true)
            fields.UILabel_FamilyEmptyEx.gameObject:SetActive(false)
            if searchState then 
                fields.UILabel_FamilySearchEmpty.gameObject:SetActive(true)
                searchState = false
            end 
        end
    else
        fields.UIGroup_Empty.gameObject:SetActive(false)
        fields.UILabel_FamilyEmptyEx.gameObject:SetActive(false)
    end
    
    -- fields.UILabel_FamilyEmpty.gameObject:SetActive(true)
    -- fields.UILabel_FundingEmpty.gameObject:SetActive(false)
end

RefreshPageFunding = function()
    fields.UIButton_OneKeyApply.gameObject:SetActive(false)
    fields.UIList_Funding.gameObject:GetComponent("UIWrapContentList"):SetDataCount(m_CurFundings and #m_CurFundings or 0)

    if m_CurFundings and (#m_CurFundings == 0) then
        fields.UIGroup_Empty.gameObject:SetActive(true)
    else
        fields.UIGroup_Empty.gameObject:SetActive(false)
    end    
    fields.UILabel_FamilyEmpty.gameObject:SetActive(false)
    fields.UILabel_FundingEmpty.gameObject:SetActive(true)
end

local function showtab(params)
    -- printyellow("on tabserach showtab")
    if mgr.InFamily() then
        uimanager.show("family.tabsearch", params)
    else
        searchmgr.GetReady(function()
                uimanager.show("family.tabsearch", params)
        end)
    end
end

local function show(params)
    CdTable = {}
    if params and params.mode == "declare_war" then
        DeclareWarMode = true
    else
        DeclareWarMode = false
    end
    if DeclareWarMode then
        fields.UIList_RadioButton.gameObject:SetActive(true)
        CurrentPage = 1
    else
        fields.UIList_RadioButton.gameObject:SetActive(false)
        CurrentPage = 1
    end

    EventHelper.SetListClick(fields.UIList_RadioButton, function(uiItem)
        CurrentPage = uiItem.Index + 1
        local wrapContent = fields.UIList_Family.gameObject:GetComponent("UIWrapContentList")
        wrapContent:CenterOnIndex(0)
        m_CurFamilies = {}
        Search("")
        uimanager.refresh(name)
    end)


    if DeclareWarMode then
        fields.UILabel_DiscriptionDeclareWar.gameObject:SetActive(true)
        fields.UILabel_Discription.gameObject:SetActive(false)
        fields.UILabel_Warning.gameObject:SetActive(false)
        fields.UILabel_Warning2.gameObject:SetActive(true)
    else
        fields.UILabel_DiscriptionDeclareWar.gameObject:SetActive(false)
        fields.UILabel_Discription.gameObject:SetActive(true)
        fields.UILabel_Warning.gameObject:SetActive(true)
        fields.UILabel_Warning2.gameObject:SetActive(false)
    end
    --printyellow("on tab search show")
    fields.UIButton_Create.gameObject:SetActive(not mgr.InFamily())
    fields.UIButton_OneKeyApply.gameObject:SetActive(not mgr.InFamily())
    fields.UIInput_Search.value = ""
    fields.UIInput_Search.characterLimit = 20 -- 输入框最大限制
    --[[if mgr.HasInitFunding() then
        fields.UIToggle_Funding.value = true
        SearchFunding("")
    else]]
        --fields.UIToggle_Join.value = true
        m_SearchFamilyStr = ""
        Search("")
    --end


end

-- local function hidetab()
-- end
local function hide()
    CdTable = {}
    m_CurFamilies = nil
    m_CurFundings = nil
    DeclareWarMode = false
end

local function destroy()
end

local function refresh(params)
    -- printyellow("on tabserach refresh")
    --if fields.UIToggle_Join.value then
        RefreshPageFamilyList()
    --[[elseif fields.UIToggle_Funding.value then
        RefreshPageFunding()
    end]]
end

-- local function update()
-- end

local function init(params)
    name, gameObject, fields = unpack(params)

    fields.UIList_Funding.gameObject:GetComponent("UIWrapContentList"):SetDataCount(0)

    EventHelper.SetClick(fields.UIButton_Search, function()
                             uimanager.isshow("family.dlgfamily_apply")
                             --if fields.UIToggle_Join.value then
                                 m_SearchFamilyStr = fields.UIInput_Search.value
                                 Search(fields.UIInput_Search.value)
                                 searchState = true
                             --[[elseif fields.UIToggle_Funding.value then
                                 SearchFunding(fields.UIInput_Search.value)
                             end]]
    end)
    EventHelper.SetClick(fields.UIButton_OneKeyApply, function()
        if mgr.HasInitFunding() then
            PopupFundingConflict()
            return
        end
        uimanager.showloading()
        searchmgr.ApplyAllFamily(function(msg)
            RefreshPageFamilyList()
            uimanager.hideloading()
        end)
    end)
    EventHelper.SetClick(fields.UIButton_Create, function()
        uimanager.show("common.dlgdialogbox_input", {callBackFunc=function(popupfields)
            popupfields.UIGroup_Button_Mid.gameObject:SetActive(true)
            popupfields.UIWidget_Resource_Mid.gameObject:SetActive(true)
            popupfields.UIGroup_Button_Norm.gameObject:SetActive(false)
            popupfields.UIGroup_Resource.gameObject:SetActive(false)
            popupfields.UIGroup_Select.gameObject:SetActive(false)
            popupfields.UIGroup_Clan.gameObject:SetActive(false)
            popupfields.UIGroup_Rename.gameObject:SetActive(false)
            popupfields.UIGroup_Slider.gameObject:SetActive(false)
            popupfields.UIGroup_Delete.gameObject:SetActive(false)
            popupfields.UIInput_Input.gameObject:SetActive(true)
            popupfields.UIInput_Input_Large.gameObject:SetActive(false)
           
            popupfields.UILabel_Input.text = LocalString.Family.Create.HintInputFamilyName
            popupfields.UILabel_Title.text = LocalString.Family.Create.TagCreate
            popupfields.UIInput_Input.characterLimit = 6

            --popupfields.UILabel_Resource_Left.text = cfg.family.FamilyInfo.MIN_CROWD_FUND_YUANBAO
            popupfields.UILabel_Resource_Mid.text = cfg.family.FamilyInfo.CREATE_REQUIRE_YUANBAO
            popupfields.UIInput_Input.value = ""
            --popupfields.UILabel_Button_Left.text = LocalString.Family.Fund.TagStartFunding
            popupfields.UILabel_Button_Mid.text = LocalString.Family.Create.TagCreate

            popupfields.UIButton_Mid.isEnabled = true --player:Ingot() >= cfg.family.FamilyInfo.MIN_CROWD_FUND_YUANBAO
            --popupfields.UIButton_Right.isEnabled =true --player:Ingot() >= cfg.family.FamilyInfo.CREATE_REQUIRE_YUANBAO
            EventHelper.SetClick(popupfields.UIButton_Mid, function()
                if player:Ingot() < cfg.family.FamilyInfo.CREATE_REQUIRE_YUANBAO then
                    ItemManager.GetSource(cfg.currency.CurrencyType.YuanBao,"common.dlgdialogbox_input")
                else
                    local text = popupfields.UIInput_Input.value
                    local num = #text
                    if string.find(text,"%s") ~= nil or num == 0 then 
                        uimanager.ShowSingleAlertDlg({content=LocalString.Family.ChangeNameError})
                    else
                        searchmgr.Create(text, function()
                            uimanager.hide("common.dlgdialogbox_input")
                            popupfields.UIInput_Input.characterLimit = 0
                            if uimanager.currentdialogname() == "family.dlgfamily_apply" then
                                uimanager.showdialog("family.dlgfamily") --�˴�û������dlgfamily_apply
                            end
                        end)
                    end
                end                                   
            end)
            --[[EventHelper.SetClick(popupfields.UIButton_Left, function()
                if player:Ingot() < cfg.family.FamilyInfo.MIN_CROWD_FUND_YUANBAO then
                    ItemManager.GetSource(cfg.currency.CurrencyType.YuanBao,"common.dlgdialogbox_input")
                else
                    searchmgr.StartFunding(popupfields.UIInput_Input.value, function()
                        uimanager.hide("common.dlgdialogbox_input")
                        popupfields.UIInput_Input.characterLimit = 0
                        if fields.UIToggle_Funding.value then
                            SearchFunding("")
                        else
                            RefreshPageFamilyList()
                        end
                    end)
                end                                   
            end)]]
        end})
    end)
    --[[EventHelper.SetToggle(fields.UIToggle_Join, function(toggle)
                              fields.UIScrollView_Family.gameObject:SetActive(toggle.value)
                              if toggle.value then
                                  fields.UIInput_Search.value = ""
                                  m_SearchFamilyStr = ""
                                  Search("")
                              end
    end)]]
    --[[EventHelper.SetToggle(fields.UIToggle_Funding, function(toggle)
                              fields.UIScrollView_Funding.gameObject:SetActive(toggle.value)
                              if toggle.value then
                                  fields.UIInput_Search.value = ""
                                  SearchFunding("")
                              end
    end)]]

    -- familylist
    EventHelper.SetWrapListRefresh(fields.UIList_Family.gameObject:GetComponent("UIWrapContentList"), function(item, itemi, i)
        if not m_CurFamilies or i > #m_CurFamilies then return end
        local data = m_CurFamilies[i]
        item.Id = data.familyid
        item.Data = data

        item.Controls["UILabel_FamilyRank"].text =  i > 3 and i or ""  -- data.rank > 3 and data.rank or ""
        item.Controls["UISprite_NO1"].gameObject:SetActive(i == 1)
        item.Controls["UISprite_NO2"].gameObject:SetActive(i == 2)
        item.Controls["UISprite_NO3"].gameObject:SetActive(i == 3)
        item.Controls["UILabel_FamilyName"].text = data.familyname
        item.Controls["UILabel_Level"].text = "等级." .. data.flevel
        item.Controls["UILabel_ChiefName"].text = data.chiefname
        item.Controls["UILabel_Declaration"].text = data.declaration
        item.Controls["UILabel_Membernum"].text = string.format("%d/%d", data.membernum, ConfigManager.getConfigData("familyinfo", data.flevel).memberamount)
        
        EventHelper.SetClick(item.Controls["UIButton_Apply"], function()
            if CdTable[item.Index] then 
                 if  os.time() - CdTable[item.Index] < CdTime then
                     return uimanager.ShowSystemFlyText(string.format("对不起，等待%ds后再申请",CdTime -(os.time() - CdTable[item.Index])))
                 end
            else
                CdTable[item.Index] = os.time()
            end
            if DeclareWarMode == false then
                if mgr.HasInitFunding() then
                    PopupFundingConflict()
                    return
                end
                uimanager.showloading()
                searchmgr.ApplyFamily(data.familyid, function(msg)
                    RefreshFamilyItemButton(item)
                    uimanager.hideloading()
                    CdTable[item.Index] = os.time()
                end)
            elseif DeclareWarMode == true and data.familyid ~= PlayerRole:Instance().m_FamilyID then
                mgr.DeclareWar(data.familyid)
            end
        end)
        EventHelper.SetClick(item.Controls["UIButton_Cancel"], function()
            
            if DeclareWarMode == false then
                uimanager.showloading()
                searchmgr.CancelApplyFamily(data.familyid, function(applybecomevacant)
                    RefreshFamilyItemButton(item)
                    uimanager.hideloading()
                end)
            else
                mgr.CancelWar(data.familyid)
            end
        end)

        RefreshFamilyItemButton(item)

        if i == (#m_CurFamilies-5)  then
            local startIndex = #m_CurFamilies+1
            if not searchmgr.IsListEnd() then
                local focusindex = fields.UIList_Family.gameObject:GetComponent("UIWrapContentList"):GetCenterOnIndex()
                Search(m_SearchFamilyStr, startIndex, focusindex)
            end
        end
    end)

    -- end familylist

    -- fundinglist
    EventHelper.SetWrapListRefresh(fields.UIList_Funding.gameObject:GetComponent("UIWrapContentList"), function(item, itemi, i)
        if not m_CurFundings or i > #m_CurFundings then return end
        local data = m_CurFundings[i]
        item.Id = data.crowdfamilyid
        item.Data = data

        item.Controls["UILabel_FamilyRank"].text = i
        item.Controls["UILabel_FamilyName"].text = data.crowdfamilyname
        item.Controls["UILabel_LV"].text = "Lv." .. data.initrolelvl
        item.Controls["UILabel_ChiefName"].text = data.initrolename
        item.Controls["UILabel_Membernum"].text = getn(data.involveroles)
        item.Controls["UILabel_Money"].text = string.format("%d/%d", data.crowdyuanbao, cfg.family.FamilyInfo.CREATE_REQUIRE_YUANBAO)
        item.Controls["UILabel_Time"].text = timeutils.getDateTimeString(
            data.crowdstarttime/1000 + cfg.family.FamilyInfo.FUNDING_TIME - timeutils.GetServerTime(),
            LocalString.Time.TimeCountDown)
        item.Controls["UIButton_Fund"].gameObject:SetActive(not mgr.InFamily())
        item.Controls["UIButton_DeFund"].gameObject:SetActive(data.initroleid == player:GetId())

        EventHelper.SetClick(item.Controls["UIButton_Fund"], function()
            local data = item.Data
            if mgr.HasInitFunding() and data.initroleid ~= player:GetId() then
                PopupFundingConflict()
                return
            end
            uimanager.show("common.dlgdialogbox_input", {callBackFunc=function(fields)
                fields.UIGroup_Button_Mid.gameObject:SetActive(false)
                fields.UIGroup_Button_Norm.gameObject:SetActive(true)
                fields.UIGroup_Resource.gameObject:SetActive(false)
                fields.UIGroup_Select.gameObject:SetActive(false)
                fields.UIGroup_Clan.gameObject:SetActive(false)
                fields.UIGroup_Rename.gameObject:SetActive(false)
                fields.UIGroup_Slider.gameObject:SetActive(true)
                fields.UIGroup_Delete.gameObject:SetActive(false)
                fields.UIInput_Input.gameObject:SetActive(false)
                fields.UIInput_Input_Large.gameObject:SetActive(false)

                local curFund = 10
                local curRequired = cfg.family.FamilyInfo.CREATE_REQUIRE_YUANBAO - data.crowdyuanbao
                EventHelper.SetSliderValueChange(fields.UISlider_Slider, function()
                                                     curFund = mathutils.Round(fields.UISlider_Slider.value*(curRequired - cfg.family.FamilyInfo.MIN_ADD_FUND_YUANBAO)/cfg.family.FamilyInfo.MIN_ADD_FUND_YUANBAO_STEP)* cfg.family.FamilyInfo.MIN_ADD_FUND_YUANBAO_STEP + cfg.family.FamilyInfo.MIN_ADD_FUND_YUANBAO
                                                     if curFund > curRequired then
                                                         curFund = curRequired
                                                     end
                                                     fields.UILabel_Count.text = curFund
                                                     --fields.UIButton_Left.isEnabled = curFund > 0
                end)
                EventHelper.SetClick(fields.UIButton_Left, function()
                                         uimanager.showloading()
                                         searchmgr.AddFunding(data.crowdfamilyid, curFund, function()
                                                               uimanager.hide("common.dlgdialogbox_input")
                                                               SearchFunding("")
                                                               uimanager.hideloading()
                                         end)
                end)
                EventHelper.SetClick(fields.UIButton_Right, function()
                                         uimanager.hide("common.dlgdialogbox_input")
                end)
                EventHelper.SetClick(fields.UIButton_Close, function()
                                         uimanager.hide("common.dlgdialogbox_input")
                end)

                fields.UILabel_Title.text = LocalString.Family.Fund.TagAddFunding
                fields.UILabel_Descrip.text = string.format(LocalString.Family.Fund.TextCurState, data.crowdfamilyname,
                                                            data.crowdyuanbao, cfg.family.FamilyInfo.CREATE_REQUIRE_YUANBAO)
                fields.UILabel_Button_Left.text = LocalString.Family.Fund.TagAddFunding
                fields.UILabel_Button_Right.text = LocalString.Family.TagCancel

                fields.UISlider_Slider.value = 0
                fields.UISprite_Currency_01.gameObject:SetActive(false)
            end})
        end)

        EventHelper.SetClick(item.Controls["UIButton_DeFund"], function()
            -- printyellow("on button defund")
            -- printt(cfg.family.FamilyInfo.FUND_FAILED_COST)
            uimanager.ShowAlertDlg({title=LocalString.Family.TagCancelFunding,
                immediate = true,
                content=string.format(LocalString.Family.Fund.TextCancelFunding, cfg.family.FamilyInfo.FUND_FAILED_COST*100),
                callBackFunc=function()
                    searchmgr.CancelFunding(function()
                        SearchFunding("")
                    end)
                end})
            end)
        end)
    -- end fundinglist
end

local function uishowtype()
    return UIShowType.Refresh
end

local function second_update()
    local wrapList = fields.UIList_Funding.gameObject:GetComponent("UIWrapContentList")
    wrapList:RefreshWithOutSort()
end

return {
    showtab      = showtab,
    show         = show,
    hide         = hide,
    refresh      = refresh,
    destory      = destory,
    init         = init,
    uishowtype   = uishowtype,
    second_update= second_update,
}
