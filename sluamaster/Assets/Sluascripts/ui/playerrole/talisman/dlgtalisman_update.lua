local unpack            = unpack
local print             = print
local require           = require

local UIManager         = require("uimanager")
local EventHelper       = UIEventListenerHelper
local ConfigManager     = require("cfg.configmanager")
local BagManager        = require("character.bagmanager")
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")
local BonusManager      = require("item.bonusmanager")
local ItemManager       = require("item.itemmanager")
----------------------------------------------------------------------------------------------------
local name
local gameObject
local fields
local lastTime = 0

local buttonLastTime = {0,0,0,0,0}
local buttonPressed = {false, false, false, false, false}
local ConsumeList = {}
local uiItemList = {}
local CurrentTalisman = nil



local function CanUpdate(talisman)
    if talisman:GetNormalLevel() >= PlayerRole:Instance().m_Level and talisman:GetNormalExp() >= talisman:GetMaxNormalExp() then
        return false
    end
    if talisman:GetNormalLevel() >= talisman:GetMaxNormalLevel() and talisman:GetNormalExp() >= talisman:GetMaxNormalExp() then
        return false
    end
    return true
end

local function SetItem(uiItem,item,i)
    local button = uiItem.gameObject:GetComponent("UIButton")
    local itemGroup = uiItem.Controls["UIGroup_Props"]
	local itmeAdd = uiItem.Controls["UISprite_Add"]

   -- local texture = uiItem.Controls["UITexture_Icon"]
    if item then
        itemGroup.gameObject:SetActive(true)
		itmeAdd.gameObject:SetActive(false)
        if item:GetNumber() > 0 then
            BonusManager.SetRewardItem(uiItem,item,{notSetClick = true})
            EventHelper.SetPress(button, function(o,isPress)
                buttonPressed[i] = isPress
            end)
            EventHelper.SetClick(button, function()
            end)
        else
            BonusManager.SetRewardItem(uiItem,item,{notSetClick = true, setGray = true})
            EventHelper.SetPress(button, function(o,isPress)

            end)
            EventHelper.SetClick(button, function()
                ItemManager.GetSource(item:GetConfigId(),name)
            end)
        end
    else
		itmeAdd.gameObject:SetActive(true)
        itemGroup.gameObject:SetActive(false)
       -- texture:SetIconTexture("")
    --    uiItem.Controls["UISprite_AmountBG"].gameObject:SetActive(false)
        EventHelper.SetClick(button, function()
            TalismanUITools.ShowHelpInfo("Update/GetUpdateProp")
        end)
    end
end

local function OnMsgSAddNormalExp()
    TalismanUITools.PlayEffect(fields.UIGroup_Effect.gameObject)
end

local function GetConsumeItem()
    local consumeList = {}
    local consume = ConfigManager.getConfig("talismanrecycle")
    local expitemId = consume.allexpitemid

    for i,id in ipairs(expitemId) do
        local items = BagManager.GetItemById(id)
        local citem = nil
        if #items ~= 0 then
            citem = items[1]
            local itemnum = 0
            for i, bitem in pairs(items) do
                if bitem:GetNumber() > 0 then
                    itemnum = itemnum + bitem:GetNumber()
                end
            end
            --citem.Number = itemnum
        else
            citem = ItemManager.CreateItemBaseById(id,{},0)
        end
        if #consumeList < 5 then
            table.insert(consumeList,citem)
        end
    end
    return consumeList
end




local function refresh(params)
    local talisman = params.talisman
    CurrentTalisman = talisman
  --  printyellow("4",talisman,params.talisman)
    ConsumeList = GetConsumeItem()
    TalismanUITools.SetBaiscAttribute(fields.UIList_Properties01,talisman:GetMainProperty(),"UILabel_Properties","UILabel_Amount")

    BonusManager.SetRewardItemShow(fields.UITexture_Icon, fields.UISprite_Quality, talisman)
    --fields.UITexture_Icon:SetIconTexture(talisman:GetIconPath())
    fields.UILabel_Level01.text = TalismanUITools.GetLevelText(talisman:GetNormalLevel())
    local currentExp = talisman:GetNormalExp()
    local maxExp = talisman:GetMaxNormalExp()
    fields.UIProgressBar_Exp.value = currentExp/maxExp
    fields.UILabel_Exp.text = "" .. currentExp .. "/" .. maxExp
    local uiItemNum =  ((#ConsumeList > 5) and #ConsumeList) or 5
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Props, uiItemNum)
    for i = 1, uiItemNum do
        local uiItem = fields.UIList_Props:GetItemByIndex(i-1)
        uiItemList[i] = uiItem
        SetItem(uiItem, ConsumeList[i],i)
    end
end

local function show(params)
    buttonLastTime = {0,0,0,0,0}
    buttonPressed = {}
    ConsumeList = {}
end
local function destroy()

end

local function hide()
    CurrentTalisman = nil
    TalismanUITools.StopEffect(fields.UIGroup_Effect.gameObject)
end

local currentEatingNumber = {1,1,1,1,1}
local isShowingAlert = false
local function update()
    for i = 1, 5 do
        if ConsumeList[i] ~= nil and buttonPressed[i]==true then
            currentEatingNumber[i] = currentEatingNumber[i] + 0.01
            if currentEatingNumber[i] > 10 then
                currentEatingNumber[i] = 10
            end
            local deltaTime = Time.time - buttonLastTime[i]
            if  deltaTime >= 0.5 then
                buttonLastTime[i] = Time.time
                if CurrentTalisman ~= nil then
                    if CanUpdate(CurrentTalisman) then
                        local consumeCount = math.floor(currentEatingNumber[i])
                        if consumeCount <= ConsumeList[i]:GetNumber() then
                            TalismanManager.AddNormalExp(CurrentTalisman,ConsumeList[i],consumeCount)
                        else
                            TalismanManager.AddNormalExp(CurrentTalisman,ConsumeList[i],ConsumeList[i]:GetNumber())
                        end
                    else
                        local helpinfo = ConfigManager.getConfigData("talismanhelpinfo","Update/ExpMax")
                        
                        --if helpinfo then
                        --    UIManager.ShowSystemFlyText(helpinfo.helpinfo)
                        --end
                        --printyellow("AAAAAAAAAAAAAAA")
                        if isShowingAlert == false and ConsumeList[i] ~= nil then
                            buttonPressed = {false, false, false, false, false}
                            isShowingAlert = true
                            UIManager.ShowAlertDlg({ content       = helpinfo.helpinfo,
                                                    immediate      = true,
                                                    callBackFunc   = function()
                                                        isShowingAlert = false
                                                        TalismanManager.AddNormalExp(CurrentTalisman,ConsumeList[i],1)
                                                    end,
                                                    callBackFunc1  = function()
                                                        isShowingAlert = false
                                                    end})
                        end
                        

                    end
                    UIManager.refresh("playerrole.talisman.talismanmanager")
                end
            end
        else
            currentEatingNumber[i] = 1
        end
    end
end

local function ShouldUpdate(talisman)
    if talisman:GetNormalLevel() >= PlayerRole:Instance().m_Level then
        return false
    end
    if talisman:GetNormalLevel() >= talisman:GetMaxNormalLevel() then
        return false
    end
    local consume = ConfigManager.getConfig("talismanrecycle")
    for i,id in ipairs(consume.allexpitemid) do
        local items = BagManager.GetItemById(id)
        if items and #items ~= 0 then
            for i, bitem in pairs(items) do
                if bitem:GetNumber() > 0 then
                    return true
                end
            end 
        end
    end
    return false
end


local function UnRead(talisman)
    return ShouldUpdate(talisman)
end

local function init(params)
    name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide("playerrole.talisman.dlgtalisman_update")
    end)
    gameObject.transform.position = Vector3(0,0,-1000)
end



return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    UnRead = UnRead,
    OnMsgSAddNormalExp = OnMsgSAddNormalExp,
}
