local unpack, print = unpack, print
local EventHelper   = UIEventListenerHelper
local UIManager     = require("uimanager")
local ConfigMangaer = require("cfg.configmanager")
local QteList       = require("ui.plot.plotqte.qtelist")

local name, gameObject, fields

local count = 0

local lastTimeScale = 1

local qteButtonList = nil
local currentButtonNum = 1
local currentButtonInfo
local remainTime = 1
local endTime = 0.5
local function QteStart()
    lastTimeScale = UnityEngine.Time.timeScale
    UnityEngine.Time.timeScale = cfg.plot.PlotQTE.timeScale
end

local function QteEnd()
    UnityEngine.Time.timeScale = lastTimeScale
    lastTimeScale = 1
end

local function SetComboButtonInfo(buttonInfo, uiItem)
    uiItem.gameObject:SetActive(false)
    local groupCombo = uiItem.Controls["UIGroup_Anticipation"]
    local groupClick = uiItem.Controls["UIGroup_Ghost"]
    local comboButton = uiItem.Controls["UIButton_Anticipation"]
    local handGroup = uiItem.Controls["UIGroup_Hand"]
    buttonInfo:SetButton(comboButton)
    local playTweens = comboButton.gameObject:GetComponent("UIPlayTweens")
        
    groupCombo.gameObject:SetActive(true)
    groupClick.gameObject:SetActive(false)
    local qteButtonPos = buttonInfo:GetPosition()
    uiItem.gameObject.transform.localPosition = Vector3(qteButtonPos.x,qteButtonPos.y,uiItem.gameObject.transform.position.z)
    uiItem:SetText("UILabel_Anticipation", tostring(0))
    
    EventHelper.SetPlayTweenFinish(playTweens, function(tweens)
        if buttonInfo.m_Count >= buttonInfo.m_MaxCount then
            buttonInfo.m_IsFinish = true
            uiItem.gameObject:SetActive(false)
        end
    end)
    
    EventHelper.SetClick(comboButton, function()
        if handGroup and handGroup.gameObject.activeSelf == true then
            handGroup.gameObject:SetActive(false)
        end
        buttonInfo.m_Count = buttonInfo.m_Count + 1
        uiItem:SetText("UILabel_Anticipation", tostring(buttonInfo.m_Count))
        --fields.UILabel_Anticipation.txt = tostring(buttonInfo.m_Count)
    end)
end

local function SetClickButtonInfo(buttonInfo, uiItem)
    uiItem.gameObject:SetActive(false)
    local groupCombo = uiItem.Controls["UIGroup_Anticipation"]
    local groupClick = uiItem.Controls["UIGroup_Ghost"]
    local clickButton = uiItem.Controls["UIButton_Ghost"]
    local listQteLevel = uiItem.Controls["UIList_QTELevel"]
    local handGroup = uiItem.Controls["UIGroup_Hand"]
    for i = 1, listQteLevel.Count do
        local subItem = listQteLevel:GetItemByIndex(i-1)
        subItem.gameObject:SetActive(false)
    end

    buttonInfo:SetButton(clickButton)
    local playTweens = clickButton.gameObject:GetComponent("UIPlayTweens")
    
    groupCombo.gameObject:SetActive(false)
    groupClick.gameObject:SetActive(true)
    clickButton.gameObject:SetActive(true)

    local qteButtonPos = buttonInfo:GetPosition()
    uiItem.gameObject.transform.localPosition = Vector3(qteButtonPos.x, qteButtonPos.y, uiItem.gameObject.transform.position.z )
    
    EventHelper.SetPlayTweenFinish(playTweens, function(tweens)
        buttonInfo:SetFinfish()
    end)

    
    EventHelper.SetClick(clickButton, function()
        if handGroup and handGroup.gameObject.activeSelf == true then
            handGroup.gameObject:SetActive(false)
        end
        local subItem = listQteLevel:GetItemByIndex(buttonInfo.m_Number-1)
        if subItem then
            subItem.gameObject:SetActive(true)
        end
        buttonInfo:OnClick()
    end)
end

local function refresh(params)
    
end

local function update()
    local buttonNum = qteButtonList:Count()
    qteButtonList:Update()
    --printyellow("currentButtonNum",currentButtonNum)
    if currentButtonNum <= buttonNum then
        local currentUIItem = fields.UIList_Buttons:GetItemByIndex(currentButtonNum-1)
        currentButtonInfo = qteButtonList:GetButton(currentButtonNum)
        
        if currentButtonInfo:IsStart() == false then
            currentButtonInfo:Start()
            currentUIItem.gameObject:SetActive(true)
        else
            if currentButtonInfo:CanNext() == true then
                currentButtonNum = currentButtonNum + 1
            end
        end
    else
        if currentButtonInfo:IsFinish() then
            UIManager.hide(name) 
        end
        endTime = endTime - UnityEngine.Time.unscaledDeltaTime
        if endTime < 0 then
            UIManager.hide(name) 
        end
    end
    remainTime = remainTime - UnityEngine.Time.deltaTime
    if remainTime <= 0 then
        UIManager.hide(name)
    end
end


local function show(params)
    QteStart()
    qteButtonList = QteList:new(params.index)
    local buttonNum = qteButtonList:Count()
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Buttons, buttonNum)
    for i = 1, buttonNum do
        local buttonInfo = qteButtonList:GetButton(i)
        local uiItem = fields.UIList_Buttons:GetItemByIndex(i-1)
        buttonInfo:SetUIItem(uiItem)
        if buttonInfo.m_Mode == cfg.plot.QTEModeType.Combo then
            SetComboButtonInfo(buttonInfo, uiItem)
        else
            SetClickButtonInfo(buttonInfo, uiItem)
        end
        buttonInfo:SetListNumber(i)
        uiItem.gameObject:SetActive(false)
    end
    currentButtonNum = 1

  --  printyellow("remainTime = params.duration",tostring(remainTime), tostring(params.duration))

    remainTime = params.duration
    endTime = 0.5
end   

local function hide()
    QteEnd()
end

local function init(params)
    name, gameObject, fields    = unpack(params)
end

local function destroy()

end

return {
    init    = init,
    show    = show,
    hide    = hide,
    update  = update,
    destroy = destroy,
    refresh = refresh,
}