local unpack, print     = unpack, print
local UIManager 	    = require("uimanager")
local ConfigManager     = require("cfg.configmanager")
local EventHelper 	    = UIEventListenerHelper
local ColorUtil         = require("common.colorutil")

local name, gameObject, fields

local roleCamp = nil





local function Contains(list, value)
    for i, vl in pairs(list) do
        if vl == value then
            return true
        end
    end
    return false
end

local function SetRoleEvaluate(uiItem, evaluates)
    local uiList = uiItem.Controls["UIList_Evaluate"]
    local teamfightConfig = ConfigManager.getConfig("teamfight")

    UIHelper.ResetItemNumberOfUIList(uiList, #teamfightConfig.evaluate)

    for i = 1, #teamfightConfig.evaluate do
        local subItem = uiList:GetItemByIndex(i-1)
        local evaluateCfg = teamfightConfig.evaluate[i]
        local textureEvaluate = subItem.Controls["UITexture_EvaluateIcon"]
        --evaluateCfg.evaluatename
        subItem:SetText("UILabel_EvaluateName", "")
        textureEvaluate:SetIconTexture(evaluateCfg.effectid)
        if Contains(evaluates, evaluateCfg.evaluateid) then
            ColorUtil.SetTextureColorGray(textureEvaluate, false)
        else
            ColorUtil.SetTextureColorGray(textureEvaluate, true)
        end
    end
end


local function ShowItem(uiItem, roleEvaluate, state)
     
    uiItem:SetText("UILabel_Name", roleEvaluate.name)
    local labelName = uiItem.Controls["UILabel_Name"]
    if roleEvaluate.camp == roleCamp then
        ColorUtil.SetLabelColorText(labelName, ColorUtil.ColorType.Green_Remind, roleEvaluate.name)
    else
        ColorUtil.SetLabelColorText(labelName, ColorUtil.ColorType.Red_Remind, roleEvaluate.name)
    end
    
    uiItem:SetText("UILabel_Hurt", roleEvaluate.damage)
    uiItem:SetText("UILabel_Kill", string.format("%d/",roleEvaluate.kill))
    uiItem:SetText("UILabel_Death", roleEvaluate.continuekill)
     
    SetRoleEvaluate(uiItem, roleEvaluate.evaluates)
         
    local spriteScoreHigher = uiItem.Controls["UISprite_Higher"]
    local spriteScoreEqual = uiItem.Controls["UISprite_Equal"]
    local spriteScoreLower = uiItem.Controls["UISprite_Lower"]
     
    if state > 0 then
       spriteScoreHigher.gameObject:SetActive(true)
       spriteScoreEqual.gameObject:SetActive(false)
       spriteScoreLower.gameObject:SetActive(false)
    elseif state == 0 then
       spriteScoreHigher.gameObject:SetActive(false)
       spriteScoreEqual.gameObject:SetActive(true)
       spriteScoreLower.gameObject:SetActive(false)
    else
       spriteScoreHigher.gameObject:SetActive(false)
       spriteScoreEqual.gameObject:SetActive(false)
       spriteScoreLower.gameObject:SetActive(true)
    end 
end

local function IsPlayerRole(roleEvaluate)
    if PlayerRole:Instance().m_Name == roleEvaluate.name then
        return true
    end
    return false
end
--[[
    				<variable name="name" type="string"/>
				<variable name="camp" type="int"/>
				<variable name="damage" type="int"/>
				<variable name="continuekill" type="int"/>
				<variable name="death" type="int"/>
				<variable name="evaluates" type="list" value="int"/>
]]
local function GetPlayerRoleCamp(evaluateList)
    for i, value in pairs(evaluateList) do
        if IsPlayerRole(value) then
            return value.camp
        end
    end
    return nil
end

local function show(params)
    if params == nil or params.msgEvaluate == nil then
        UIManager.hidedialog(name)
    end
    local evaluateList = params.msgEvaluate
    local onClose = params.onClose
    
    UIHelper.ResetItemNumberOfUIList(fields.UIList_Ranklist,#evaluateList)
    
    roleCamp = GetPlayerRoleCamp(evaluateList)

    local state = 1
    for i =1, #evaluateList do
        local uiItem = fields.UIList_Ranklist:GetItemByIndex(i-1)
        local roleEvaluate = evaluateList[i]        
        if IsPlayerRole(roleEvaluate) then
            ShowItem(uiItem, roleEvaluate, state)
            state = -1
        else
            ShowItem(uiItem, roleEvaluate, state)
        end
    end    
    
    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hidedialog(name)
        if onClose then
            onClose()
        end
    end)

    --UILabel_Time
end

local function hide()

end

local function update()

end

local function refresh(params)
    
end

local function destroy()

end

local function init(params)
    name, gameObject, fields = unpack(params)
    
    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hidedialog(name)
    end)
end

return {
    init    = init,
    show    = show,
    hide    = hide,
    update  = update,
    destroy = destroy,
    refresh = refresh,
}
