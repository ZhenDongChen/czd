local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local partymgr = require("family.partymanager")
local network = require("network")
local configmanager = require("cfg.configmanager")

local gameObject
local name
local fields

local m_LeftSecs
local m_banquetState

local BanquetStateType = enum
{
    "None = 0",
    "Wait",
    "Arrange",
    "Opening",
    "End",   
}

local function refresh(params)   
    local bChief = partymgr.IsChief()
    fields.UIButton_Open.gameObject:SetActive(bChief)
    UITools.SetButtonEnabled(fields.UIButton_Open, true)
    fields.UILabel_Button_Open.text = LocalString.Family.Party.ButtonOpen 

    if m_banquetState == BanquetStateType.Wait then
        fields.UIGroup_Wait.gameObject:SetActive(true)
        fields.UIGroup_Arrange.gameObject:SetActive(false)
        fields.UIGroup_Opening.gameObject:SetActive(false)
        UITools.SetButtonEnabled(fields.UIButton_Open, false)            

    elseif m_banquetState == BanquetStateType.Arrange then
        fields.UIGroup_Wait.gameObject:SetActive(false)
        fields.UIGroup_Arrange.gameObject:SetActive(true)
        fields.UIGroup_Opening.gameObject:SetActive(false)

        fields.UIGroup_Chief_Arrange.gameObject:SetActive(bChief)
        fields.UIGroup_Normal_Arrange.gameObject:SetActive(not bChief)       

    elseif m_banquetState == BanquetStateType.Opening then
        fields.UIGroup_Wait.gameObject:SetActive(false)
        fields.UIGroup_Arrange.gameObject:SetActive(false)
        fields.UIGroup_Opening.gameObject:SetActive(true)

        fields.UIGroup_Normal_Opening.gameObject:SetActive(not bChief)
        fields.UILabel_Button_Open.text = LocalString.Family.Party.ButtonCall

    elseif m_banquetState == BanquetStateType.End then
        fields.UIGroup_Wait.gameObject:SetActive(false)
        fields.UIGroup_Arrange.gameObject:SetActive(true)
        fields.UIGroup_Opening.gameObject:SetActive(false)

        fields.UIGroup_Chief_Arrange.gameObject:SetActive(true)
        fields.UIGroup_Normal_Arrange.gameObject:SetActive(false)
        UITools.SetButtonEnabled(fields.UIButton_Open, false)
        fields.UILabel_Open.text = LocalString.Family.Party.PartyEnd       
    end
end

local function updateStateAndTime()
    local partyInfo = configmanager.getConfig("familyparty")
    local beginSecsDay1 = timeutils.getSeconds({days = 0, hours = partyInfo.starttime[1], 
        minutes = partyInfo.starttime[2], seconds = 0})
    local beginSecsDay2 = timeutils.getSeconds({days = 0, hours = partyInfo.starttime2[1], 
        minutes = partyInfo.starttime2[2], seconds = 0})

    local timeNow = timeutils.TimeNow()
	local nowSecsDay = timeutils.getSeconds({days = 0,          hours = timeNow.hour ,minutes = timeNow.min,seconds = timeNow.sec})
    local nowSecs    = timeutils.getSeconds({days = timeNow.day,hours = timeNow.hour ,minutes = timeNow.min,seconds = timeNow.sec})

    local bInOpenTime = partymgr.IsInOpenTime()

    local bOpening = false
    if (timeutils.GetServerTime() - partymgr.GetLastOpenTime()) < partyInfo.duration then
        bOpening = true       
    end

    local lastTime = os.date("*t", partymgr.GetLastOpenTime())
    local bTodayOpened = true
    if lastTime.year ~= timeNow.year or lastTime.month ~= timeNow.month or lastTime.day ~= timeNow.day then
        bTodayOpened = false
    end

    local  banquetState = BanquetStateType.End
    if bTodayOpened and not bOpening then
        banquetState = BanquetStateType.End
    elseif bOpening then
        banquetState = BanquetStateType.Opening
    elseif bInOpenTime then
        banquetState = BanquetStateType.Arrange
    else
        banquetState = BanquetStateType.Wait
    end

    if banquetState ~= m_banquetState then
        m_banquetState = banquetState
        refresh()
    end

    if m_banquetState == BanquetStateType.Wait then
        if nowSecsDay < beginSecsDay1 then
            m_LeftSecs = beginSecsDay1 - nowSecsDay - 1
        else
            m_LeftSecs = beginSecsDay2 - nowSecsDay - 1
        end

        local leftTime = timeutils.getDateTime(m_LeftSecs)	
	    fields.UILabel_OpenTime.text = string.format(LocalString.Welfare_WishingTree_WishTime,
            leftTime.hours,leftTime.minutes,leftTime.seconds)

    elseif m_banquetState == BanquetStateType.Opening then
        m_LeftSecs = partyInfo.duration - (timeutils.GetServerTime() - partymgr.GetLastOpenTime()) 
        local leftTime = timeutils.getDateTime(m_LeftSecs)	
	    fields.UILabel_CloseTime.text = string.format(LocalString.Welfare_WishingTree_WishTime,
            leftTime.hours,leftTime.minutes,leftTime.seconds)
    end		
end

local function destroy()
end

local function show(params)  
    updateStateAndTime() 
end

local function hide()
end

local function update()
end

local function second_update(now)
    updateStateAndTime()    
end

local function init(params)
    name, gameObject, fields = unpack(params)
    m_banquetState = m_banquetState == BanquetStateType.None
    m_LeftSecs = 0

    local partyInfo = configmanager.getConfig("familyparty")
    fields.UILabel_Rule01.text = string.format(LocalString.Family.Party.Desc,
        partyInfo.starttime[1],partyInfo.starttime[2], partyInfo.endtime[1], partyInfo.endtime[2],
        partyInfo.starttime2[1],partyInfo.starttime2[2], partyInfo.endtime2[1], partyInfo.endtime2[2])

    local rewardList = partyInfo.showitem.bonuss  --利用item来模拟展示符咒奖励内容
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Reward, #rewardList)
    for i = 1,#rewardList do
        local ItemManager = require"item.itemmanager"
        local BonusManager = require("item.bonusmanager")
        local rewardsItem = ItemManager.CreateItemBaseById(rewardList[i].itemid)
        local item = fields.UIList_Reward:GetItemByIndex(i-1)
        BonusManager.SetRewardItem(item,rewardsItem,{notShowAmount = true})
    end

    EventHelper.SetClick(fields.UIButton_Close, function()
        uimanager.hide("family.dlgbanquet")
    end )

    EventHelper.SetClick(fields.UIButton_Open, function()        
        if m_banquetState ~= BanquetStateType.Opening then
            partymgr.COpenFamilyParty()
        else 
            if (timeutils.GetServerTime() - partymgr.GetLastCallTime()) > 60 then
                partymgr.CCallAllFamilyMembers()
            else
                uimanager.ShowSystemFlyText(LocalString.Family.Party.CanNotCall)
            end           
        end
        
    end )
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    second_update = second_update,
}
