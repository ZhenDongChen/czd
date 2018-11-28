local defineenum = require "defineenum"

local CharacterType = defineenum.CharacterType
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local charactermanager = require("character.charactermanager")
local ConfigManager = require("cfg.configmanager")

local name,gameObject,fields
local playerRole
local elapsedTime = 0

local function IsInSameServer(playerServerIndex)
    local roleServerIndex = PlayerRole:Instance().m_ServerId
    local serverMapCfg = ConfigManager.getConfig("serveridmap")
    local playerServerId = serverMapCfg[playerServerIndex]
    local roleServerId = serverMapCfg[roleServerIndex]
    --printyellow("serverId: ", playerServerId, roleServerId)
    if playerServerId ~= nil and roleServerId ~= nil then
        return (playerServerId == roleServerId)
    end
    return true
end


--==========================================================================================
--角色菜单已移至文件ui.common.dlgothertips 
--==========================================================================================
local MAX_BUFF_NUM = 5
local EMPTY_EFFECT_LIST = {}

--==========================================================================================
local currentCharacter = nil
local lastSelectCharacterIdList = {}
local lastSelectCharacterIdTimeMap = {}

local function UpdateHeadInfo(char)
    local attributes = char.m_Attributes or {}
    local hp_current = attributes[cfg.fight.AttrId.HP_VALUE] or 100
    local hp_max = attributes[cfg.fight.AttrId.HP_FULL_VALUE] or 100
    local value = hp_current / hp_max
    fields.UIProgressBar_CharacterHP.value = value > 0.002 and value or 0.002
    fields.UILabel_CharHeadHp.text = tostring(math.ceil(value * 100)) .. "%"
end

local function UpdateEffect(char)
    local effectList = (char.m_Effect ~= nil) and char.m_Effect:GetEffectList() or EMPTY_EFFECT_LIST

    for i = 1, MAX_BUFF_NUM do
        local effect = effectList[i]

        local uiItem = fields.UIList_CharacterBuff:GetItemByIndex(i-1)

            local sprite = uiItem.Controls["UISprite_Buff"]
            if effect then
                sprite.spriteName = effect.icon
            else
                sprite.spriteName = ""
            end

    end
end
--[[
local function UpdateEffect(char)


    if char.m_Effect == nil then
        fields.UIGroup_CharacterBuff.gameObject:SetActive(false)
        fields.UIList_CharacterBuff.gameObject:SetActive(false)
        return
    end



    fields.UIGroup_CharacterBuff.gameObject:SetActive(true)
    fields.UIList_CharacterBuff.gameObject:SetActive(true)
    local effectList = char.m_Effect:GetEffectList()
    local effectNum = math.min( #effectList, 5)
    UIHelper.ResetItemNumberOfUIList(fields.UIList_CharacterBuff,effectNum)
    for i = 1, #effectList do
        if i > 5 then
            break
        end
        local uiItem = fields.UIList_CharacterBuff:GetItemByIndex(i-1)
        local sprite = uiItem.Controls["UISprite_Buff"]
        local effect = effectList[i]
        sprite.spriteName = effect.icon
        --effect.description
    end
end
]]
local function ChangeHeadFrame(char)
    if char:IsMonster() then
        if char:IsBoss() then
            fields.UISprite_EliteHead.gameObject:SetActive(false)
            fields.UISprite_BossHead.gameObject:SetActive(true)
        elseif char:IsElite() then
            fields.UISprite_EliteHead.gameObject:SetActive(true)
            fields.UISprite_BossHead.gameObject:SetActive(false)
        else
            fields.UISprite_EliteHead.gameObject:SetActive(false)
            fields.UISprite_BossHead.gameObject:SetActive(false)
        end
    else
        fields.UISprite_EliteHead.gameObject:SetActive(false)
        fields.UISprite_BossHead.gameObject:SetActive(false)
    end
end

g_bDebugShowId=g_bDebugShowId
local function clientCmd_showid(params)
	if not isEnableClientCmd("/showid") then
		   return 
	end 
	 if #params<2 then
	     return 
	 end
	 g_bDebugShowId=(params[2]=="1")
end
RegisterClientCmd("/showid",clientCmd_showid)

local function SetCharacterHeadInfo(char)
    fields.UITexture_CharacterHead:SetIconTexture(char:GetHeadIcon())
	
	if g_bDebugShowId then
		fields.UILabel_CharacterName.text = char:GetName().."."..tostring(char:GetId())
	else
		fields.UILabel_CharacterName.text = char:GetName()
	end
    local level = char:GetLevel() or 1
    fields.UILabel_CharacterLevel.text = tostring(level)
    UpdateHeadInfo(char)
    ChangeHeadFrame(char)
end

local function SetBuffInfo(char)
    UpdateEffect(char)
end


local function HideTips()
   -- printyellow("HideTips")
    if UIManager.isshow("common.dlgothertips") then
        UIManager.call("common.dlgothertips","HideTopTips")
    end
end



local function SetMenuInfo(char)
    if char:IsRole() or (not char:IsPlayer()) then
        --fields.UIGroup_Tips.gameObject:SetActive(false)
        EventHelper.SetClick(fields.UISprite_CharacterHead, function()

        end)
        HideTips()
        return
    end

    EventHelper.SetClick(fields.UISprite_CharacterHead, function()
        if UIManager.isshow("common.dlgothertips") then
            UIManager.hide("common.dlgothertips")
        else

            if not IsInSameServer(char.m_ServerId) then
                UIManager.ShowSystemFlyText(LocalString.OtherTipsDifferentServer)
                return
            end
            UIManager.show("common.dlgothertips",{charInfo = char,position = fields.UIGroup_Tips.gameObject.transform.position})
        end
    end)
    if UIManager.isshow("common.dlgothertips") then
        UIManager.refresh("common.dlgothertips", {charInfo = char,position = fields.UIGroup_Tips.gameObject.transform.position})
    end
end

local function ChangeCurrentCharacter(char)
    if lastSelectCharacterIdList == nil or #lastSelectCharacterIdList > 10 then
        lastSelectCharacterIdList = {}
        lastSelectCharacterIdTimeMap = {}
    end
    if currentCharacter then
        table.insert(lastSelectCharacterIdList, currentCharacter.m_Id)
        lastSelectCharacterIdTimeMap[currentCharacter.m_Id] = UnityEngine.Time.time
    end
    currentCharacter = char
end
local function ChangeSelectedCharacter(char)
    if currentCharacter ~= nil and currentCharacter.m_Id == char.m_Id then
        return
    end
    if char == nil or char.m_ListenerGroup == nil then
        return
    end
    local listenerKey = "dlguimain_othercharacterhead"
    if currentCharacter ~= nil then
        currentCharacter.m_ListenerGroup:RemoveDeathOrDestroyListener(listenerKey)
        currentCharacter.m_ListenerGroup:RemoveAttributeListener(listenerKey)
        currentCharacter.m_ListenerGroup:RemoveEffectListener(listenerKey)
        local apertureTarget = SelectedAperture:Instance():GetTarget()
        if apertureTarget and apertureTarget.m_Id and apertureTarget.m_Id == currentCharacter.m_Id then
            SelectedAperture:Instance():SetTarget(nil)
        end
    end
    char.m_ListenerGroup:AddDeathOrDestroyListener(listenerKey, function(lsnChar)
        currentCharacter.m_ListenerGroup:RemoveDeathOrDestroyListener(listenerKey)
        currentCharacter.m_ListenerGroup:RemoveAttributeListener(listenerKey)
        currentCharacter.m_ListenerGroup:RemoveEffectListener(listenerKey)
        local apertureTarget = SelectedAperture:Instance():GetTarget()
        if apertureTarget and apertureTarget.m_Id and apertureTarget.m_Id == currentCharacter.m_Id then
            SelectedAperture:Instance():SetTarget(nil)
        end

        ChangeCurrentCharacter(nil)
        fields.UIGroup_CharacterHead.gameObject.transform.localScale = Vector3.zero
        HideTips()
    end, false)
    char.m_ListenerGroup:AddAttributeListener(listenerKey, function(lsnChar)
        UpdateHeadInfo(char)
    end, false)
    char.m_ListenerGroup:AddEffectListener(listenerKey, function(lsnChar)
        UpdateEffect(char)
    end, false)
    SelectedAperture:Instance():SetTarget(char)

    ChangeCurrentCharacter(char)
end


--==========================================================================================

local function SetHeadInfo(isshow, char)
    if char == nil then
        fields.UIGroup_CharacterHead.gameObject.transform.localScale = Vector3.zero
        return
    end
    if char:IsRole() or char:IsMineral()  then
        return
    end
    if isshow == nil then
        isshow = false
    end
    --fields.UIGroup_CharacterHead.gameObject:SetActive(isshow)
    if isshow == false then
        fields.UIGroup_CharacterHead.gameObject.transform.localScale = Vector3.zero
        return
    else
        fields.UIGroup_CharacterHead.gameObject.transform.localScale = Vector3.one
    end
	--改变选择的角色
    ChangeSelectedCharacter(char)
   -- fields.UIGroup_CharacterBuff.gameObject:SetActive(false)
    --fields.UIGroup_Tips.gameObject:SetActive(false)
    HideTips()
    SetCharacterHeadInfo(char)
    SetBuffInfo(char)
    SetMenuInfo(char)
end

--设置头像
local function SetHeadInfoById(id)
    local char = charactermanager.GetCharacter(id)
    if char ~= nil then
        SetHeadInfo(true, char)
    else
        SetHeadInfo(false, char)
    end
end

local function NeedSetHeadInfoById(targetId)
    SetHeadInfoById(targetId)
end

local function refresh()

end

local function update()

end

local function show()

end

local function SelectOrderFunc(charIdA, charIdB)
    local timeA = lastSelectCharacterIdTimeMap[charIdA] or -1
    local timeB = lastSelectCharacterIdTimeMap[charIdB] or -1
    if timeA < timeB then
        return true
    end
    return false
end



local function ResetTarget()
    local chars = CharacterManager.GetRoleAttackableTargets()
    local canSelectList = {}
    for _, char in pairs(chars) do
        if currentCharacter ~= nil then
            if currentCharacter.m_Id ~= char.m_Id then
                table.insert(canSelectList, char.m_Id)
            end
        else
            canSelectList[1] = char.m_Id
            break
        end
    end
    table.sort( canSelectList, SelectOrderFunc )
    if canSelectList[1] ~= nil then
        PlayerRole:Instance():SetTargetId(canSelectList[1])
        SetHeadInfoById(canSelectList[1])
    end
end

local function init(dlgname,dlggameObject,dlgfields,params)
    name,gameObject,fields = dlgname,dlggameObject,dlgfields

    playerRole = PlayerRole:Instance()

   -- fields.UIPlayTweens_Death.gameObject:SetActive(false)
    fields.UIGroup_CharacterBuff.gameObject:SetActive(true)
    fields.UIList_CharacterBuff.gameObject:SetActive(true)
    UIHelper.ResetItemNumberOfUIList(fields.UIList_CharacterBuff,MAX_BUFF_NUM)
    EventHelper.SetClick(fields.UIButton_SelectTarget, function()
        ResetTarget()
    end)
end

local function hide()

end

local function destroy()

end




return {
    init    = init,
    show    = show,
    update  = update,
    refresh = refresh,
    hide    = hide,
    destroy = destroy,
    SetHeadInfo = SetHeadInfo,
    SetHeadInfoById = SetHeadInfoById,
    NeedSetHeadInfoById = NeedSetHeadInfoById,
}
