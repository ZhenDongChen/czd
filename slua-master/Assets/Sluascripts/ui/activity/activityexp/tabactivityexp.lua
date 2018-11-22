local unpack, print         = unpack, print
local UIManager             = require("uimanager")
local ExpMonsterManager   = require("ui.activity.activityexp.activityexpmanager")
local ItemIntroduction      = require("item.itemintroduction")
local BonusManager          = require("item.bonusmanager")
local ConfigManager         = require("cfg.configmanager")
local Define                = require("define")
local EventHelper           = UIEventListenerHelper
local CheckCmd				= require("common.checkcmd")
local ColorUtil             = require("common.colorutil")
local Monster               =require("character.monster")
local define                =require("define")
local fields
local name
local gameObject
local monsterData = nil
local m_Boss=nil
local monsterbonus = {}
local isResetStart = true
--local inactiveShader


local function destroy()
end


local function GetRewardData(killnum)
    for _,monsterbonu in pairs(monsterbonus) do
        if killnum == monsterbonu.killnum then
            local items = BonusManager.GetItemsByBonusConfig(monsterbonu.killbonus)
            return  items
        end       
    end
end

local function init(params)
    name, gameObject, fields    = unpack(params)
    ExpMonsterManager.refresh()
    monsterData = ExpMonsterManager.GetExpMonsterInfo()
    if monsterData then
        monsterbonus = monsterData.monsterbonus
    end
	
    EventHelper.SetDrag(fields.UITexture_Boss,function (go,delta)
        if m_Boss then
            local modelObj=m_Boss.m_Object 
            if modelObj  then 
                local vecRotate = Vector3(0,-delta.x,0)
                modelObj.transform.localEulerAngles = modelObj.transform.localEulerAngles + vecRotate
            end
        end
    end)
    EventHelper.SetClick(fields.UIButton_PersonalBossChallenge,function ()
        if m_Boss then
            ExpMonsterManager.sendFightMsg()
        end
    end)
	
    for i=1,#monsterbonus do
        local killNum = ExpMonsterManager.GetKillMonsterNum()
        if fields["UITexture_0"..i] then
--[[            if  killNum >= monsterbonus[i].killnum then
                fields["UIGroup_Tween_Play_0"..i].gameObject:SetActive(true)
            else
                fields["UIGroup_Tween_Play_0"..i].gameObject:SetActive(false)
            end--]]
			
            EventHelper.SetClick(fields["UITexture_0"..i],function ()
                --local killNum = ExpMonsterManager.GetKillMonsterNum()
                local params   = {}
                params.type    = 1
                params.items   = GetRewardData(monsterbonus[i].killnum)
                params.title   = LocalString.Alert_RewardsList
                local text = LocalString.Task_GetReward
                if not ExpMonsterManager.isReceived(monsterbonus[i].killnum) then
                    text = LocalString.Common_Receive
                end
                params.buttons =
                {
                    { 
                        text = text,
                        Enable = (ExpMonsterManager.GetKillMonsterNum() >= monsterbonus[i].killnum and ExpMonsterManager.isReceived(monsterbonus[i].killnum)),                
                        callBackFunc = function() 
                            UIManager.hide("common.dlgdialogbox_reward")
                            ExpMonsterManager.sendGetReward(monsterbonus[i].killnum) 
							local expMonsterData=ConfigManager.getConfig("expmonster")  
							if killNum >= monsterbonus[i].killnum then 
								local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
								fields["UITexture_Grey_"..i].shader= inactiveShader
								--fields["UITexture_Grey_"..i]:SetIconTexture(expMonsterData.opentexturename[i])
							end
                        end 
                    },
                }
                local DlgAlert_ShowRewards = require("ui.dlgalert_showrewards")
                params.callBackFunc = function(p, f) 
                    DlgAlert_ShowRewards.init(f)
                    DlgAlert_ShowRewards.show(p) 
                end
                UIManager.show("common.dlgdialogbox_reward", params) 
            end)
        end
    end
end

local function OnBossLoaded()
    local modelObj = m_Boss.m_Object
    local modelTrans = modelObj.transform
    modelTrans.parent=fields.UITexture_Boss.transform
    ExtendedGameObject.SetLayerRecursively(modelObj,Define.Layer.LayerUICharacter)
	modelTrans.localScale = Vector3.one*(monsterData.scale)
    modelTrans.localPosition = Vector3(monsterData.positionx,monsterData.positiony,0)
    modelTrans.rotation = Quaternion.Euler(-90,0,0)
end

local function AddBossModel(bossId)
    if m_Boss then
        if bossId~=m_Boss.csvId then
            m_Boss:release()
            m_Boss=Monster:new()
            m_Boss.m_AnimSelectType=cfg.skill.AnimTypeSelectType.UI
            m_Boss:RegisterOnLoaded(OnBossLoaded)
            m_Boss:init(0,bossId)
        end
    else
        m_Boss=Monster:new()
        m_Boss.m_AnimSelectType=cfg.skill.AnimTypeSelectType.UI
        m_Boss:RegisterOnLoaded(OnBossLoaded)
        m_Boss:init(0,bossId)
    end
end

local function DisplayBonus(monsterbonusList)
    fields.UIList_PersonalBossRewards:Clear()
    -- for _,monsterbonus in pairs(monsterbonusList) do
    --     if ExpMonsterManager.GetKillMonsterNum() < monsterbonus.killnum then
    --         local items = BonusManager.GetItemsByBonusConfig(monsterbonus.killbonus)
    --         for _,item in pairs(items) do
    --             local uiItem = fields.UIList_PersonalBossRewards:AddListItem()
    --             BonusManager.SetRewardItem(uiItem,item)
    --         end
    --         break
    --     end       
    -- end
    local items = BonusManager.GetItemsByBonusConfig(monsterbonusList[1].killbonus)
    for _,item in pairs(items) do
        local uiItem = fields.UIList_PersonalBossRewards:AddListItem()
        BonusManager.SetRewardItem(uiItem,item)
    end
end

local function ResetStart()
    for i=1,#monsterbonus do
        --[[if fields["UITexture_Normal_"..i] then 
            fields["UITexture_Normal_"..i].gameObject:SetActive(false)
        end--]]
        if fields["UITexture_0"..i] then
            local StarLabel = fields["UITexture_0"..i].gameObject.transform:Find("UILabel_StarNum")
            if StarLabel then
                StarLabel.gameObject:GetComponent(UILabel).text = monsterbonus[i].killnum .. LocalString.Activity_ActivityExp_Num
            end
        end 
    end
    fields.UISlider_Star.value = 0
end

local function SetStartType()
    local killNum = ExpMonsterManager.GetKillMonsterNum()
    ResetStart()
--[[    for i=1,#monsterbonus do
        if (killNum >= monsterbonus[i].killnum and ExpMonsterManager.isReceived(monsterbonus[i].killnum) and fields["UITexture_Normal_"..i]) then 
            fields["UITexture_Normal_"..i].gameObject:SetActive(true)
        end
    end--]]
    fields.UISlider_Star.value = killNum/monsterbonus[#monsterbonus].killnum
end

local function DisplayOpenTime()
    local openTimeText=""
    local refreshTimes=ExpMonsterManager.GetRefreshTimeList()
    --printt(refreshTimes)
    for _,timeInfo in pairs(refreshTimes) do
        if openTimeText~="" then
            openTimeText=openTimeText.."--"..(timeInfo.hour)..":"..(string.format("%02d",timeInfo.min))
        else
            openTimeText=(timeInfo.hour)..":"..(string.format("%02d",timeInfo.min))
        end
    end
    fields.UILabel_Time.text = openTimeText
end

local function RefreshKillNum()
    SetStartType()
end

local function DisplayDetailInfo()
    if monsterData then
        local monster = ConfigManager.getConfigData("monster",monsterData.monsterid)
        AddBossModel(monsterData.monsterid)
        fields.UILabel_BossRecommendPower.text = monsterData.battlepower

        if ExpMonsterManager.GetPlayerPower() > monsterData.battlepower then
            ColorUtil.SetLabelColorText( fields.UILabel_BossPlayerPower, ColorUtil.ColorType.Green_Remind, ExpMonsterManager.GetPlayerPower())
        else
            ColorUtil.SetLabelColorText( fields.UILabel_BossPlayerPower, ColorUtil.ColorType.Red_Remind, ExpMonsterManager.GetPlayerPower())
        end
        fields.UILabel_BossName.text = monster.name
        fields.UILabel_BossName01.text = monster.name
        DisplayBonus(monsterData.monsterbonus)
        DisplayOpenTime()
        SetStartType()
    else
        gameObject:SetActive(false)
    end

end




local function refresh()
    if monsterData then
        DisplayBonus(monsterData.monsterbonus)
        SetStartType()
    end
	local killNum = ExpMonsterManager.GetKillMonsterNum()
	fields.UISlider_Star.value = killNum/monsterbonus[#monsterbonus].killnum
	local Receiveednomus = ExpMonsterManager.GetReceivedbonus()
    local expMonsterData=ConfigManager.getConfig("expmonster")
    for i = 1, #monsterbonus do 
        local visState = false
        for j = 1, #Receiveednomus do
            local isKillnum = Receiveednomus[j]
            if monsterbonus[i].killnum == isKillnum then 
                visState = true
                break
            end
        end
		
        if  killNum >= monsterbonus[i].killnum and visState  then
			local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
			fields["UITexture_Grey_"..i].shader= inactiveShader
			--fields["UITexture_Grey_"..i]:SetIconTexture(expMonsterData.opentexturename[i])
        else
			fields["UITexture_Grey_"..i]:SetIconTexture(expMonsterData.closetexturename[i])
        end
		
		
		if  killNum >= monsterbonus[i].killnum   then
			 fields["UIGroup_Tween_Play_0"..i].gameObject:SetActive(true)
        else
            fields["UIGroup_Tween_Play_0"..i].gameObject:SetActive(false)
        end
		
		
		if  visState then
            fields["UIGroup_Tween_Play_0"..i].gameObject:SetActive(false)
		end
    end
end


local function update()
    if m_Boss and m_Boss.m_Object then 
        m_Boss.m_Avatar:Update() 
    end
	--printyellow("<<<<<<<<<<<ExpMonsterManager.GetOpenStatus()",ExpMonsterManager.GetOpenStatus())
    if ExpMonsterManager.GetOpenStatus() == 1 then
        ColorUtil.SetLabelColorText( fields.UILabel_OpenOrClose, ColorUtil.ColorType.Green_Remind, LocalString.Activity_ActivityExp_Open)
        fields.UIButton_PersonalBossChallenge.isEnabled = true
		
    elseif ExpMonsterManager.GetOpenStatus() == 0 then 
        ColorUtil.SetLabelColorText( fields.UILabel_OpenOrClose, ColorUtil.ColorType.Red_Remind, LocalString.Activity_ActivityExp_NotOpen)
        fields.UIButton_PersonalBossChallenge.isEnabled = false
    else
        ColorUtil.SetLabelColorText( fields.UILabel_OpenOrClose, ColorUtil.ColorType.Red_Remind, LocalString.Activity_ActivityExp_Close)
        fields.UIButton_PersonalBossChallenge.isEnabled = false
    end
end

local function show()
    DisplayDetailInfo()
	
end

local function hide()
    if m_Boss then
        m_Boss:release()
    end
end

local function uishowtype()
    return UIShowType.Refresh
end

local function UnRead()
end
return{
    show=show,
    hide=hide,
    init=init,
    refresh=refresh,
    uishowtype=uishowtype,
    update=update,
    destroy = destroy,
    UnRead = UnRead,
}
