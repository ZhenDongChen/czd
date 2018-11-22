local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local familymanager = require("family.familymanager")
local warmanager = require("family.warmanager")
local player = require("character.playerrole"):Instance()
local ItemManager = require("item.itemmanager")
local configmanager = require("cfg.configmanager")

local fields
local name
local NUM_PER_PAGE = 4

local m_CurPage=0  --当前购买页码
local m_TotalPage = 0

local RefreshPageAboutWar
local RefreshPageAcceptBattle
local RefreshPageRecord
local OfffsetAboutWar = 0
local OringinalPosAboutWar = 0

local OfffsetAcceptBattle = 0
local OringinalPosAcceptBattle = 0

local OfffsetRecord = 0
local OringinalPosRecord = 0

local function show(params)
    warmanager.ClearCandidateFamilyList()

    local familywarConfig = configmanager.getConfig("familywar")
    fields.UILabel_FamilyNumber.text = string.format("%d/%d",warmanager.GetOnlineMemberNum(), familymanager.Info().membernum)
    fields.UILabel_ActivityNumber.text = string.format("%d/%d", familywarConfig.daychallengenum - warmanager.GetMyFamilyWarInfo().todayfamilywarnum,
         familywarConfig.daychallengenum)
    fields.UILabel_HistoryResult.text = string.format(LocalString.Family.AboutWarFamilyWins, 
        warmanager.GetMyFamilyWarInfo().winnum, warmanager.GetMyFamilyWarInfo().drawnum, 
        warmanager.GetMyFamilyWarInfo().losenum )
end

-- local function hidetab()
-- end

local function hide()

end

local function destroy()
end

local function RefreshPageAboutWar()
    local startIndex = (m_CurPage-1)*NUM_PER_PAGE
    for i = 1,NUM_PER_PAGE do
        local item = fields.UIList_AboutWar:GetItemByIndex(i-1)
        local data = warmanager.GetCandidateFamilyList()[startIndex+i] --FamilyWarShowInfo
        if data then
            item.Controls["UISprite_Family"].gameObject:SetActive(false)
            item.gameObject:SetActive(false)
            item.gameObject:SetActive(true)
            item.Id = data.showinfo.id 
            item.Data = data
            item.Controls["UISprite_Family"].gameObject:SetActive(true)
            item.Controls["UILabel_FamilyRank"].text = startIndex+i
            item.Controls["UILabel_FamilyName"].text = data.showinfo.familyname
            item.Controls["UILabel_Level"].text = "等级." .. data.showinfo.level
            item.Controls["UILabel_ChiefName"].text = data.showinfo.chiefname    
            item.Controls["UILabel_Membernum"].text = string.format("%d/%d", data.showinfo.totalmembernum, ConfigManager.getConfigData("familyinfo", data.showinfo.level).memberamount)
            item.Controls["UILabel_Record"].text = string.format(LocalString.Family.AboutWarFamilyWins, data.showinfo.winnum, data.showinfo.drawnum, data.showinfo.losenum)
        
            if data.showinfo.level < 1 then
                item.Controls["UIButton_AboutWar"].isEnabled = false
                item.Controls["UILabel_AboutWar"].text = LocalString.Family.AboutWarButtonLevelReq
            --[[elseif warmanager.GetOnlineMemberNum() < 10 then
                item.Controls["UIButton_AboutWar"].isEnabled = false
                item.Controls["UILabel_AboutWar"].text = LocalString.Family.AboutWarButtonMemberReq]]
            --[[elseif  not warmanager.IsInOpenTime() then
                item.Controls["UIButton_AboutWar"].isEnabled = false
                item.Controls["UILabel_AboutWar"].text = LocalString.Family.AboutWarButtonNotInTime]]
            elseif data.showinfo.id == familymanager.Info().familyid then
                item.Controls["UIButton_AboutWar"].isEnabled = false
            elseif data.canchallenge == 0 then
                item.Controls["UIButton_AboutWar"].isEnabled = false
                item.Controls["UILabel_AboutWar"].text = LocalString.Family.AboutWarButtonAskDone
            else
                item.Controls["UIButton_AboutWar"].isEnabled = true
                item.Controls["UILabel_AboutWar"].text = LocalString.Family.AboutWarButtonAsk
            end

            EventHelper.SetClick(item.Controls["UIButton_AboutWar"], function()
                if familymanager.IsChief() or familymanager.IsViceChief() then
                    warmanager.CFamilyWarChallenge(data.showinfo.id)
                else
                    uimanager.ShowSystemFlyText(LocalString.Family.NoRightForDealWar)
                end
            end)
        else
            item.gameObject:SetActive(false)
        end      
    end
end

local function RefreshPageAcceptBattle()
    local startIndex = (m_CurPage-1)*NUM_PER_PAGE
    for i = 1,NUM_PER_PAGE do
        local item = fields.UIList_AcceptBattle:GetItemByIndex(i-1)
        local data = warmanager.GetChallengeFamilyList()[startIndex+i] --FamilyWarChallenge
        if data then
            item.gameObject:SetActive(false)
            item.gameObject:SetActive(true)
            item.Controls["UISprite_Family"].gameObject:SetActive(false)
            item.Id = data.showinfo.id 
            item.Data = data
            item.Controls["UISprite_Family"].gameObject:SetActive(true)
            item.Controls["UILabel_FamilyRank"].text = startIndex+i
            item.Controls["UILabel_FamilyName"].text = data.showinfo.familyname
            item.Controls["UILabel_Level"].text = "Lv." .. data.showinfo.level
            item.Controls["UILabel_ChiefName"].text = data.showinfo.chiefname  
            item.Controls["UILabel_Membernum"].text = string.format("%d/%d", data.showinfo.totalmembernum, ConfigManager.getConfigData("familyinfo", data.showinfo.level).memberamount)
            item.Controls["UILabel_Record"].text = string.format(LocalString.Family.AboutWarFamilyWins, data.showinfo.winnum, data.showinfo.drawnum, data.showinfo.losenum)
            
            local leftTimeSeces = data.expiretime/1000 - timeutils.GetServerTime()
            if leftTimeSeces < 0 then
                item.Controls["UILabel_Time"].text = ""
                item.Controls["UILabel_AboutWar"].text = LocalString.Family.AboutWarChallengeButtTimeOut
            else
                item.Controls["UILabel_AboutWar"].text = LocalString.Family.AboutWarChallengeButt
                local leftTime = timeutils.getDateTime(leftTimeSeces)
                item.Controls["UILabel_Time"].text = string.format(LocalString.Family.AboutWarAreaTimeLeft, leftTime.minutes,leftTime.seconds)
            end	           

            EventHelper.SetClick(item.Controls["UIButton_AboutWar"], function()
                if familymanager.IsChief() or familymanager.IsViceChief() then
                    warmanager.CFamilyWarResponse(data.showinfo.id)
                else
                    uimanager.ShowSystemFlyText(LocalString.Family.NoRightForDealWar)
                end               
            end)
        else
            item.gameObject:SetActive(false)
        end      
    end
end

local function RefreshPageRecord()
    local startIndex = (m_CurPage-1)*NUM_PER_PAGE
    local historyListLen = #warmanager.GetFamilyWarHistory()
    for i = 1,NUM_PER_PAGE do
        local item = fields.UIList_Record:GetItemByIndex(i-1)
        local data = warmanager.GetFamilyWarHistory()[historyListLen+1 - (startIndex+i)] --FamilyWarHistory
        if data then
            item.gameObject:SetActive(false)
            item.Controls["UISprite_Family"].gameObject:SetActive(false)
            item.gameObject:SetActive(true)
            item.Data = data
            item.Controls["UISprite_Family"].gameObject:SetActive(true)
            item.Controls["UILabel_FamilyName01"].text = "Lv." .. familymanager.Info().flevel .. "  " .. familymanager.Info().familyname
            item.Controls["UILabel_FamilyName02"].text = "Lv." .. data.level .. "  " .. data.familyname
            item.Controls["UILabel_ResultWin"].gameObject:SetActive(data.result == cfg.ectype.FamilyWarBattleResult.WIN)
            item.Controls["UILabel_ResultFaile"].gameObject:SetActive(data.result == cfg.ectype.FamilyWarBattleResult.FAIL)
            item.Controls["UILabel_ResultDraw"].gameObject:SetActive(data.result == cfg.ectype.FamilyWarBattleResult.DRAW)
            -- if data.challengeme == 0 then
            --     item.Controls["UILabel_VS"].text = LocalString.Family.WarHistoryAsk
            -- else   
            --     item.Controls["UILabel_VS"].text = LocalString.Family.WarHistoryAccept 
            -- end
            local l_Time = os.date("*t", data.time/1000)
		    local l_TimeStr = string.format(LocalString.Family.WarHistoryTime, l_Time.year, l_Time.month, l_Time.day)
            item.Controls["UILabel_Time"].text = l_TimeStr
        else
            item.gameObject:SetActive(false)
        end
    end
end

local function refresh(params)
    fields.UISprite_Warning.gameObject:SetActive(warmanager.UnRead())
    fields.UIButton_ArrowsLeft.isEnabled = true
    fields.UIButton_ArrowsRight.isEnabled = true
    if m_CurPage == 0 then
        fields.UIButton_ArrowsLeft.isEnabled = false
        fields.UIButton_ArrowsRight.isEnabled = false
    elseif m_CurPage==1 then
        fields.UIButton_ArrowsLeft.isEnabled = false
    end
    if m_CurPage==m_TotalPage then
        fields.UIButton_ArrowsRight.isEnabled = false
    end
    fields.UILabel_Page.text=m_CurPage.."/"..m_TotalPage

    if fields.UIToggle_AboutWar.value then
        local panel = fields.UIScrollView_AboutWar.gameObject:GetComponent("UIPanel")
        panel.transform.localPosition = OringinalPosAboutWar
        panel:SetClipOffsetY(OfffsetAboutWar)
        RefreshPageAboutWar()
    elseif fields.UIToggle_AcceptBattle.value then
        RefreshPageAcceptBattle()
        local panel = fields.UIScrollView_AcceptBattle.gameObject:GetComponent("UIPanel")
        panel.transform.localPosition = OringinalPosAcceptBattle
        panel:SetClipOffsetY(OfffsetAcceptBattle)
    elseif fields.UIToggle_Record.value then
        RefreshPageRecord()
        local panel = fields.UIScrollView_Record.gameObject:GetComponent("UIPanel")
        panel.transform.localPosition = OringinalPosRecord
        panel:SetClipOffsetY(OfffsetRecord)
    end       
end

-- local function update()
-- end

local function init(params)
    name, gameObject, fields = unpack(params)


    fields.UIScrollView_AboutWar.gameObject:SetActive(true)
    fields.UIScrollView_AcceptBattle.gameObject:SetActive(true)
    fields.UIScrollView_Record.gameObject:SetActive(true)
    OfffsetAboutWar = fields.UIScrollView_AboutWar.gameObject:GetComponent("UIPanel"):GetClipOffsetY()   
    OringinalPosAboutWar = fields.UIScrollView_AboutWar.gameObject.transform.localPosition

    OfffsetRecord = fields.UIScrollView_Record.gameObject:GetComponent("UIPanel"):GetClipOffsetY()   
    OringinalPosRecord = fields.UIScrollView_Record.gameObject.transform.localPosition

    OfffsetAcceptBattle = fields.UIScrollView_AcceptBattle.gameObject:GetComponent("UIPanel"):GetClipOffsetY()   
    OringinalPosAcceptBattle = fields.UIScrollView_AcceptBattle.gameObject.transform.localPosition

    while fields.UIList_AboutWar.Count < NUM_PER_PAGE do
        fields.UIList_AboutWar:AddListItem()
    end
    while fields.UIList_AcceptBattle.Count < NUM_PER_PAGE do
        fields.UIList_AcceptBattle:AddListItem()
    end
    while fields.UIList_Record.Count < NUM_PER_PAGE do
        fields.UIList_Record:AddListItem()
    end

    EventHelper.SetToggle(fields.UIToggle_AboutWar, function(toggle)
        fields.UIScrollView_AboutWar.gameObject:SetActive(toggle.value)
        if toggle.value then
            if warmanager.GetCandidateFamilyListTotalNum() > 0 then
                m_CurPage = 1
                m_TotalPage = math.ceil(warmanager.GetCandidateFamilyListTotalNum()/NUM_PER_PAGE)
                refresh()
            else
                warmanager.CGetFamilyWarCandidateList(0, NUM_PER_PAGE, function ()              
                    m_TotalPage = math.ceil(warmanager.GetCandidateFamilyListTotalNum()/NUM_PER_PAGE)
                    if warmanager.GetCandidateFamilyListTotalNum() > 0 then
                        m_CurPage = 1
                    else
                        m_CurPage = 0
                    end
                    refresh()
                end)
            end            
        end
    end)
    EventHelper.SetToggle(fields.UIToggle_AcceptBattle, function(toggle)
        fields.UIScrollView_AcceptBattle.gameObject:SetActive(toggle.value)
        if toggle.value then
            m_TotalPage = math.ceil(#warmanager.GetChallengeFamilyList()/NUM_PER_PAGE)
            if #warmanager.GetChallengeFamilyList() > 0 then
                m_CurPage = 1
            else
                m_CurPage = 0
            end
            refresh()
        end
    end)
    EventHelper.SetToggle(fields.UIToggle_Record, function(toggle)
        fields.UIScrollView_Record.gameObject:SetActive(toggle.value)
        if toggle.value then
            m_TotalPage = math.ceil(#warmanager.GetFamilyWarHistory()/NUM_PER_PAGE)
            if #warmanager.GetFamilyWarHistory() > 0 then
                m_CurPage = 1
            else
                m_CurPage = 0
            end
            refresh()
        end
    end)

    EventHelper.SetClick(fields.UIButton_Details, function()
        local familywarConfig = configmanager.getConfig("familywar")
        uimanager.show("common.dlgdialogbox_complex",{type=2,text = rewardText,callBackFunc = function(params,ofields)
            ofields.UILabel_Content_Single.text = familywarConfig.decs
        end})
    end)

    EventHelper.SetClick(fields.UIButton_ArrowsLeft,function()       
        m_CurPage = m_CurPage - 1
        refresh()       
    end)
    EventHelper.SetClick(fields.UIButton_ArrowsRight,function()
        if fields.UIToggle_AboutWar.value then
            if m_CurPage + 1 > math.ceil(#warmanager.GetCandidateFamilyList()/NUM_PER_PAGE)then
                warmanager.CGetFamilyWarCandidateList(#warmanager.GetCandidateFamilyList(), NUM_PER_PAGE, function()
                    m_CurPage = m_CurPage + 1
                    refresh()
                end)
            else
                m_CurPage = m_CurPage + 1
                refresh()
            end
        elseif fields.UIToggle_AcceptBattle.value then
            m_CurPage = m_CurPage + 1
            refresh()
        elseif fields.UIToggle_Record.value then
            m_CurPage = m_CurPage + 1
            refresh()
        end       
    end)
end

local function uishowtype()
    return UIShowType.Refresh
end

local function second_update()
    if fields.UIToggle_AcceptBattle.value then
        local startIndex = (m_CurPage-1)*NUM_PER_PAGE
        for i = 1,NUM_PER_PAGE do
            local item = fields.UIList_AcceptBattle:GetItemByIndex(i-1)
            local data = item.Data
            if data then            
                local leftTimeSeces = data.expiretime/1000 - timeutils.GetServerTime()             
                if leftTimeSeces < 0 then
                    item.Controls["UILabel_Time"].text = ""
                    item.Controls["UIButton_AboutWar"].isEnabled = false
                    item.Controls["UILabel_AboutWar"].text = LocalString.Family.AboutWarChallengeButtTimeOut
                else
                    item.Controls["UIButton_AboutWar"].isEnabled = true
                    item.Controls["UILabel_AboutWar"].text = LocalString.Family.AboutWarChallengeButt
                    local leftTime = timeutils.getDateTime(leftTimeSeces)
                    item.Controls["UILabel_Time"].text = string.format(LocalString.Family.AboutWarAreaTimeLeft, leftTime.minutes,leftTime.seconds)
                end
            end	           
        end
    end
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
