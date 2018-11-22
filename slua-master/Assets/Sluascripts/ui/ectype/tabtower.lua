local unpack = unpack
local print = print
local math = math
local tostring          = tostring
local floor             = math.floor
local strfmt            = string.format
local tinsert           = table.insert
local EventHelper       = UIEventListenerHelper
local uimanager         = require("uimanager")
local network           = require("network")
local login             = require("login")
local EctypeManager     = require"ectype.ectypemanager"
local ConfigManager     = require"cfg.configmanager"
local BonusManager      = require"item.bonusmanager"
local ItemManager       = require"item.itemmanager"
local RankManager       = require"ui.rank.rankmanager"
local CheckCmd          = require"common.checkcmd"
local CfgItem           = ConfigManager.getConfig("itembasic")
local LimitManager      = require"limittimemanager"
local CurrentEctype     = 60430001
local PlayerRole        = require"character.playerrole"
local player            = PlayerRole.Instance()
local uiListTower       = {}
local inactiveShader    = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader      = UnityEngine.Shader.Find("Unlit/Transparent Colored")

local CfgTower
local manualIndex
local layersInfo
local gameObject
local name
local fields
local DlgInfo
local HighestLevel
local CurrentLevel
local HistoryTime
local layerData
local wrapContent
local currentIndex
local rewardText
local bLianYu
local FirstBonuss
local spriteType
local labelType

local function destroy()
    -- print(name, "destroy")
end

local function GetBonus(floorId)
    local climbData=ConfigManager.getConfig("climbtowerectype")
    local floorData=climbData[CurrentEctype].floors[floorId]
    local firstItems=nil
    local normalItems=nil
    if floorData then
        firstItems=BonusManager.GetItemsByBonusConfig(floorData.firstbonus)
        normalItems=BonusManager.GetItemsByBonusConfig(floorData.normalbonus)
    end
    return firstItems,normalItems
end

local function DisplayReward(floorId)
    local firstItems,normalItems = GetBonus(floorId)
    fields.UIList_Rewards01:ResetListCount(#normalItems)
    fields.UIList_Rewards02:ResetListCount(#firstItems)
    if firstItems~=nil then
        for idx, item in ipairs(firstItems) do
            local listItem=fields.UIList_Rewards02:GetItemByIndex(idx-1)
            BonusManager.SetRewardItem(listItem,item)
            local labelGet = listItem.Controls["UILabel_Get"]
            local textureIcon = listItem.Controls["UITexture_Icon"]
            local b = floorId<=PlayerRole.Instance().m_ClimbTowerInfo[CurrentEctype].maxfloorid
            textureIcon.shader = b and inactiveShader or activeShader
            labelGet.gameObject:SetActive(b)
        end
    end
    if normalItems~=nil then
        for idx, item in pairs(normalItems) do
            local listItem=fields.UIList_Rewards01:GetItemByIndex(idx-1)
            BonusManager.SetRewardItem(listItem,item)
        end
    end
end



local function hide()
    fields.UIScrollView_Layer:ResetPosition()
    -- print(name, "hide")
end

local function hidetab()
    uimanager.hide("ectype.tabtower")
end
local function showtab(params)
    uimanager.show("ectype.tabtower",params)
end

local function RefreshLayerInformations()
    local color = player.m_Power >= layersInfo[1+currentIndex].battlevalue and " %d[9afe19](%d)[-]" or " %d[fa4926](%d)[-]"
    local text = strfmt(color,layersInfo[1+currentIndex].battlevalue,player.m_Power)
    fields.UILabel_PowerValue.text = text
    DisplayReward(1+currentIndex)
end

local function update()
    local newIndex = manualIndex
    manualIndex = nil
    if not newIndex then
		assert(floor(10))
        newIndex = floor(LuaHelper.GetCenterOnIndex(fields.UIList_Layer)+0.5)
    end
    if newIndex ~= currentIndex then
        if newIndex>=0 and newIndex<#layersInfo then
            currentIndex = newIndex
            RefreshLayerInformations()
        end
    end
end

local function GetFormatedTime(time)
    local s = time%60
    local m = floor(time/60)
    return strfmt(LocalString.EctypeText.TowerTime,m,s)
end

local function AddCurrency(item,bonus)
    local textureIcon = item.Controls["UITexture_Icon"]
    local labelAmount = item.Controls["UILabel_Amount"]
	local currency = ItemManager.CreateItemBaseById(bonus.type)
    local icon = currency:GetIconName()
    local amount = bonus.amount
    textureIcon:SetIconTexture(icon)
    labelAmount.text = tostring(amount)
end

local function AddOneItem(item,bonus)
    local textureIcon = item.Controls["UITexture_Icon"]
    local icon = CfgItem[bonus.itemid].icon
    textureIcon:SetIconTexture(icon)
end

local function AddItem(item,bonus)
    local textureIcon = item.Controls["UITexture_Icon"]
    local labelAmount = item.Controls["UILabel_Amount"]
    local icon = CfgItem[bonus.itemid].icon
    textureIcon:SetIconTexture(icon)
    local amount = bonus.amount
    labelAmount.text = tostring(amount)
end

local function AddBonusToList(item,bonus)
    if bonus.class == 'cfg.cmd.action.Currency' then
        AddCurrency(item,bonus)
    elseif bonus.class == 'cfg.cmd.action.Currencys' then
        for i,v in pairs(bonus.currencys) do
            AddBonusToList(item,v)
        end
    elseif bonus.class == 'cfg.cmd.action.OneItem' then
        AddOneItem(item,bonus)
    elseif bonus.class == 'cfg.cmd.action.OneItems' then
        for i,v in pairs(bonus.items) do
            AddBonusToList(item,v)
        end
    elseif bonus.class == 'cfg.cmd.action.Item' then
        AddItem(item,bonus)
    elseif bonus.class == 'cfg.cmd.action.Items' then
        for i,v in pairs(bonus.items) do
            AddBonusToList(item,v)
        end
    end
end

local function DisplayOneLayerItem(item,layer,idx)
    if idx~=1 and idx ~= #layersInfo+2 then
        item.gameObject:SetActive(true)
        local uigroup = item.Controls["UIGroup_Content"]
        uigroup.gameObject:SetActive(true)
        local layerIdx = #layersInfo+2-idx
        local labelCurrent = item.Controls["UILabel_Current"]
        local labelFinished = item.Controls["UILabel_Finished"]
        local labelNew = item.Controls["UILabel_New"]
        labelCurrent.gameObject:SetActive(false)
        labelFinished.gameObject:SetActive(false)
        labelNew.gameObject:SetActive(false)
        local showLabel
        if layerIdx == CurrentLevel then
            showLabel = labelCurrent
        elseif layerIdx <= HighestLevel then
            showLabel = labelFinished
        else
            showLabel = labelNew
        end
        showLabel.gameObject:SetActive(true)
        showLabel.text = strfmt(LocalString.EctypeText.TabTowerLevel,layerIdx)
    else
        local uigroup = item.Controls["UIGroup_Content"]
        uigroup.gameObject:SetActive(false)
    end
end

local function OnItemInit(UIListItem,wrapIndex,realIndex)
    if realIndex == 1 or realIndex == #layersInfo + 2 then
        mail = nil
    else
        local mail = layersInfo[#layersInfo+2-realIndex]
    end
    DisplayOneLayerItem(UIListItem,mail,realIndex)
end

local function InitList(num)
    wrapContent = fields.UIList_Layer.gameObject:GetComponent("UIWrapContentList")
    if wrapContent == nil then return end
    EventHelper.SetWrapListRefresh(wrapContent,OnItemInit)
    wrapContent:SetDataCount(num)
    wrapContent:CenterOnIndex(#layersInfo+2-CurrentLevel)
    currentIndex = #layersInfo - CurrentLevel
end

local function RefreshLayers()
    for i=1,#layersInfo do
        uiListTower[i].labelCurrent.gameObject:SetActive(false)
        uiListTower[i].labelFinished.gameObject:SetActive(false)
        uiListTower[i].labelNew.gameObject:SetActive(false)
        if CurrentLevel == i then
            uiListTower[i].labelCurrent.gameObject:SetActive(true)
        elseif HighestLevel>=i then
            uiListTower[i].labelFinished.gameObject:SetActive(true)
        else
            uiListTower[i].labelNew.gameObject:SetActive(true)
        end
    end
end

local function StartTabTower()
    fields.UIList_Layer:ResetListCount(#layersInfo+2)
    local text
    for i=1,#layersInfo+2 do
        local item = fields.UIList_Layer:GetItemByIndex(i-1)
        if i==1 or i == #layersInfo + 2 then
            item.Controls["UILabel_Current"].text = ""
            item.Controls["UILabel_Finished"].text = ""
            item.Controls["UILabel_New"].text = ""
            local spriteItem = item.Controls["UISprite_Item"]
            spriteItem.gameObject:SetActive(false)
        else
            uiListTower[i-1] = {}
            uiListTower[i-1].item = item
            local labelCurrent = item.Controls["UILabel_Current"]
            local labelFinished = item.Controls["UILabel_Finished"]
            local labelNew = item.Controls["UILabel_New"]
            uiListTower[i-1].labelCurrent = labelCurrent
            uiListTower[i-1].labelFinished = labelFinished
            uiListTower[i-1].labelNew = labelNew
            text = strfmt(LocalString.EctypeText.TabTowerLevel,i-1)
            uiListTower[i-1].labelCurrent.text = text
            uiListTower[i-1].labelFinished.text = text
            uiListTower[i-1].labelNew.text = text
        end
    end
end

local function refresh(params)

end

local function ShowContents(params)
	printyellow("___________ShowContents_CurrentEctype",CurrentEctype)
    local rankData = RankManager.GetRankData()
    local towerRankData = rankData[cfg.bonus.RankType.CLIMB_TOWER].m_Ranks
    HighestLevel = player.m_ClimbTowerInfo[CurrentEctype].maxfloorid
    CurrentLevel = HighestLevel>10 and HighestLevel-10 or 1
    fields.UIButton_Sweep.isEnabled = HighestLevel>1
    fields.UILabel_MyLayer.text = strfmt(LocalString.EctypeText.TabTowerLevel,HighestLevel)
    HistoryTime = player.m_ClimbTowerInfo[CurrentEctype].costtime and player.m_ClimbTowerInfo[CurrentEctype].costtime or 0
    if bLianYu then
        fields.UILabel_HighestRecord.gameObject:SetActive(true)
        if #towerRankData>0 then
            fields.UILabel_HighestLayer.text = strfmt(LocalString.EctypeText.TabTowerLevel,towerRankData[1].m_RankValue1)
            local spendTime = towerRankData[1].m_RankValue2
            fields.UILabel_FastTime.text = strfmt(LocalString.EctypeText.TowerFastestTime,floor(spendTime/60),spendTime%60)
        else
            fields.UILabel_HighestLayer.text = LocalString.EctypeText.NoRanks
            fields.UILabel_FastTime.text = ""
        end
    else
        fields.UILabel_HighestRecord.gameObject:SetActive(false)
    end

    local remainLimit = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.CLIMB_TOWER_ECTYPE,CurrentEctype)
    local totalLimit = CfgTower.dailylimit.entertimes[PlayerRole.Instance().m_VipLevel+1]
    fields.UILabel_RemainTime.text = strfmt("%d/%d",totalLimit - remainLimit,totalLimit)
    fields.UILabel_MyTime.text = strfmt(LocalString.EctypeText.TowerTime,floor(HistoryTime/60),HistoryTime%60)
    currentIndex = CurrentLevel-1
    RefreshLayers()
    LuaHelper.CenterOnIndex(fields.UIList_Layer,currentIndex)
    currentIndex = -1
end

local function RefreshInfo()
   if bLianYu then
		--labelType.text = LocalString.EctypeText.NormalMode
       -- spriteType.spriteName = "Button_Common_Normal"
	fields.UITexture_BackgroundTest:SetIconTexture("BG_HYDF_Hard")
    else
        
		--labelType.text = LocalString.EctypeText.LianyuMode
       -- spriteType.spriteName = "Button_Common_Normal"
	fields.UITexture_BackgroundTest:SetIconTexture("BG_HYDF")
    end
    CurrentEctype = bLianYu and 60430002 or 60430001
    CfgTower = ConfigManager.getConfigData("climbtowerectype",CurrentEctype)
    layersInfo = CfgTower.floors_id
    StartTabTower()
    if not PlayerRole.Instance().m_ClimbTowerInfo[CurrentEctype] then
        PlayerRole.Instance().m_ClimbTowerInfo[CurrentEctype] = {maxfloorid = 0,costtime = 0}
    end
    CfgTower = ConfigManager.getConfigData("climbtowerectype",CurrentEctype)
    FirstBonuss = {}
    for i=1,#CfgTower.floors_id do
        local floorInfo = CfgTower.floors_id[i]
        local multiBonus = floorInfo.firstbonus
        local BonusItems = BonusManager.GetItemsByBonusConfig(multiBonus)
        tinsert(FirstBonuss,BonusItems)
    end
    ShowContents()
end

local function show(params)
    fields.UILabel_VIP.gameObject:SetActive(not Local.HideVip)
    RefreshInfo()
end

local function uishowtype()
    return UIShowType.Refresh
end

local function addText(name,amount)
    return strfmt(LocalString.EctypeText.SingleBonusText,name,amount)
end

local function Switch(params)
    bLianYu = params
    currentIndex = -1
	
    RefreshInfo()
end

local function ShowFirstBonuss(params,ofields)
    local highlevel = params.highlevel

    ofields.UILabel_Title.text = LocalString.EctypeText.TowerFirstBonus
    ofields.UIList_RewardGroups:ResetListCount(#FirstBonuss)
    for idx,bonusitems in ipairs(FirstBonuss) do
        local item = ofields.UIList_RewardGroups:GetItemByIndex(idx-1)
        item.Controls["UILabel_Line1"].text = strfmt(LocalString.EctypeText.TowerLevel,idx)
        item.Controls["UIGroup_Resource"].gameObject:SetActive(false)
        local listReward = item.Controls["UIList_Rewards"]
        listReward:ResetListCount(#bonusitems)
        for rewradIdx,bonusitem in ipairs(bonusitems) do
            local rewardItem = listReward:GetItemByIndex(rewradIdx-1)
            rewardItem.Controls["UILabel_ItemName"].text = bonusitem.ConfigData.name
            BonusManager.SetRewardItem(rewardItem,bonusitem)
        end
    end
    LuaHelper.CenterOnIndex(ofields.UIList_RewardGroups,10)
end

local function init(params)
    name, gameObject, fields = unpack(params)
    local dlgname = uimanager.currentdialogname()
    bLianYu = false
    rewardText = ""

  --  spriteType = fields.UIButton_Type.gameObject.transform:GetComponent("UISprite")
   -- labelType = fields.UILabel_Type

    EventHelper.SetClick(fields.UIButton_Challenge,function()
        local validate,info=CheckCmd.CheckData({data=CfgTower.dailylimit,moduleid=cfg.cmd.ConfigId.CLIMB_TOWER_ECTYPE,cmdid=CurrentEctype})
        local validate2,info2 = CheckCmd.CheckData{data=CfgTower.levellimit}
        if not validate then
            uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.EctypeText.TowerDailyLimit})
            return
        end
        if not validate2 then
            uimanager.show("dlgalert_reminder_singlebutton",{content=strfmt(LocalString.EctypeText.TowerLevelLimit,CfgTower.levellimit.level)})
            return
        end
        EctypeManager.RequestEnterTower(CurrentEctype)
    end)
    --

    EventHelper.SetClick(fields.UIButton_RankingList,function()
        uimanager.showdialog("rank.dlgranklist",{rankType=1})
    end)
    EventHelper.SetClick(fields.UISprite_Reward,function()
        uimanager.show("common.dlgdialogbox_reward",{type=0,callBackFunc=ShowFirstBonuss,highlevel = HighestLevel})
    end)

    fields.UIScrollView_Layer.onStoppedMoving = function()
        LuaHelper.CenterOnIndex(fields.UIList_Layer,currentIndex)
    end

    EventHelper.SetListClick(fields.UIList_Layer,function(item)
        manualIndex = item.m_nIndex - 1
    end)

    EventHelper.SetClick(fields.UIButton_Sweep,function()
		printyellow("___________UIButton_Sweep",CurrentEctype)
        local validate,info=CheckCmd.CheckData({data=CfgTower.dailylimit,moduleid=cfg.cmd.ConfigId.CLIMB_TOWER_ECTYPE,cmdid=CurrentEctype})
        local validate2,info2 = CheckCmd.CheckData{data=CfgTower.levellimit}
        local validate3,info3 = CheckCmd.CheckData{data=CfgTower.sweep.limit,moduleid=cfg.cmd.ConfigId.SWEEP_CLIMBTOWER,cmdid=CurrentEctype}
        if not validate then
            uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.EctypeText.TowerDailyLimit})
            return
        end
        if not validate2 then
            uimanager.show("dlgalert_reminder_singlebutton",{content=strfmt(LocalString.EctypeText.TowerLevelLimit,CfgTower.levellimit.level)})
            return
        end
        if not validate3 then
            uimanager.show("dlgalert_reminder_singlebutton",{content=LocalString.EctypeText.TowerSweepLimit})
            return
        end
        EctypeManager.RequestSweepTower(CurrentEctype)
    end)

    EventHelper.SetClick(fields.UIButton_Ordinary,function()
      
            Switch(false)
			fields.UISprite_Ordinary.gameObject:SetActive(true)
			fields.UISprite_LianYu.gameObject:SetActive(false)
       
    end)
	
	EventHelper.SetClick(fields.UIButton_LianYu,function()
        if PlayerRole.Instance().m_Level >= 60 then
            Switch(true)
			fields.UISprite_Ordinary.gameObject:SetActive(false)
			fields.UISprite_LianYu.gameObject:SetActive(true)
        else
            uimanager.ShowSingleAlertDlg{content=strfmt(LocalString.EctypeText.TowerLevelLimit,60)}
        end
    end)
end

local function uishowtype()
    return UIShowType.Refresh
end

local function OnShowSweepReward(params,ofields)
    ofields.UILabel_Title.text = LocalString.EctypeText.SweepTowerResult
    local mainItem = ofields.UIList_RewardGroups:AddListItem()
    mainItem.Controls["UIGroup_Resource"].gameObject:SetActive(false)
    mainItem.Controls["UILabel_Line1"].text = LocalString.EctypeText.RewardSweepTower
    local mainList = mainItem.Controls["UIList_Rewards"]
    local bonusItems = BonusManager.GetItemsOfServerBonus(params.msg.bonus)
    for _,item in pairs(bonusItems) do
        local uiItem = mainList:AddListItem()
        BonusManager.SetRewardItem(uiItem,item)
        uiItem.Controls["UILabel_ItemName"].text = item.ConfigData.name
    end
    ShowContents()
end

local function OnSweep(msg)
    uimanager.show("common.dlgdialogbox_reward",{type=0,callBackFunc=OnShowSweepReward,msg=msg})
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    hidetab = hidetab,
    showtab = showtab,
    uishowtype = uishowtype,
    OnSweep = OnSweep,
}
