local unpack, print     = unpack, print
local UIManager 	    = require("uimanager")
local EventHelper 	    = UIEventListenerHelper

local name, gameObject, fields

local remainingTime = 20

local function ShowRole(uiItem, roleInfo)
    local textureHead = uiItem.Controls["UITexture_Head"]
    
    textureHead:SetIconTexture(roleInfo:GetIcon())
    
    uiItem:SetText("UILabel_Name",  roleInfo:GetName())
    uiItem:SetText("UILabel_Level", LocalString.TeamFight.Level .. roleInfo:GetLevel())
    uiItem:SetText("UILabel_Power", roleInfo:GetPower())
    
end

local function show(params)
    local friendlyList = params.friendlyList
    local enemyList = params.enemyList
    
    remainingTime = params.remainingTime or 20
        
    if enemyList == nil or friendlyList == nil then
        UIManager.hidedialog(name)
    end
    
    
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Player01,#friendlyList)
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Player02,#enemyList)
    
    for i = 1, #friendlyList do
        local uiItem = fields.UIList_Player01:GetItemByIndex(i-1)
        local roleInfo = friendlyList[i]
        ShowRole(uiItem, roleInfo)
    end
    
    for i = 1, #enemyList do
        local uiItem = fields.UIList_Player02:GetItemByIndex(i-1)
        local roleInfo = enemyList[i]
        ShowRole(uiItem, roleInfo)
    end
end

local function hide()

end

local function update()
    
    local showTime = (remainingTime > 0) and remainingTime or 0
    fields.UILabel_LastTime.text = string.format(LocalString.TeamFight.PrepareTime, tostring(math.floor( showTime )))
    remainingTime = remainingTime - Time.deltaTime
    if remainingTime < 0  then
        UIManager.hidedialog(name)
    end
    
end

local function refresh(params)
    
end

local function destroy()

end

local function init(params)
    name, gameObject, fields = unpack(params)
end

return {
    init    = init,
    show    = show,
    hide    = hide,
    update  = update,
    destroy = destroy,
    refresh = refresh,
}
