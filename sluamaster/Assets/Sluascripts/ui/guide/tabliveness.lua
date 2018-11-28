local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local Define = require("define")
local uimanager = require("uimanager")
local livemgr = require("guide.livenessmanager")
local NPC = require("character.npc")
local ConfigManager  = require("cfg.configmanager")
local BonusManager = require("item.bonusmanager")

local name
local gameObject
local fields

local g_NPC
local m_MaxScore = 0
local m_EventIDList
local inactiveShader

local function OnNPCLoaded()
	local npcTrans = g_NPC.m_Object.transform
	npcTrans.parent = fields.UITexture_Player.gameObject.transform	
	npcTrans.localRotation = Vector3.up*0
	g_NPC:UIScaleModify()
	local npcCfg = ConfigManager.getConfigData("mallnpc",cfg.mall.MallType.DAILY_ACTIVITY)
	npcTrans.localPosition = Vector3(0, npcCfg.offset, 0)
	ExtendedGameObject.SetLayerRecursively(g_NPC.m_Object, Define.Layer.LayerUICharacter)
    g_NPC:Show()
	EventHelper.SetDrag(fields.UITexture_Player, function(o, delta)
		if g_NPC then
			local npcObj = g_NPC.m_Object
			if npcObj then
				local vecRotate = Vector3(0, - delta.x, 0)
				npcObj.transform.localEulerAngles = npcObj.transform.localEulerAngles + vecRotate
			end
		end
	end )
	EventHelper.SetClick(fields.UITexture_Player,function ()
   end)
end

local function AddNPC()
	if g_NPC == nil then
		g_NPC = NPC:new()
        g_NPC.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
		local npcCfg = ConfigManager.getConfigData("mallnpc",cfg.mall.MallType.DAILY_ACTIVITY)
        local npcCsvId = npcCfg.cornucopianpc
        g_NPC:RegisterOnLoaded(OnNPCLoaded)
		g_NPC:init(0, npcCsvId)	
	end
end

local function showtab(params)
	--TODO��ʱ��������ָ����
   livemgr.GetReady(function()
        uimanager.show("guide.tabliveness", params)
    end)
	-- uimanager.show("guide.tabliveness", params)
end

local function show()
	inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
    AddNPC()  
end

-- local function hidetab()
-- end

local function hide()
    if g_NPC then
		g_NPC:release()
		g_NPC = nil
	end
end

local function destroy()
    if g_NPC then
		g_NPC:release()
		g_NPC = nil
	end
end

local function IsFinishEvent(id)
    local dataevent = ConfigManager.getConfigData("activeevent", id)
    local count = livemgr.EventCount(id)
    if dataevent and count >= dataevent.times then
        return true
    end
    return false
end

local function CmpEventAchievement(a,b) 
    if IsFinishEvent(a) and not IsFinishEvent(b) then
        return false
    end
    return true
end

local function CmpEventOrder(a,b) 
    if not IsFinishEvent(a) and not IsFinishEvent(b) then
        local dataeventA = ConfigManager.getConfigData("activeevent", a)
        local dataeventB = ConfigManager.getConfigData("activeevent", b)
        return dataeventA.displayorder < dataeventB.displayorder
    end
    return true
end

local function refresh(params)
    fields.UISlider_Score.value = livemgr.Score() / m_MaxScore
    fields.UILabel_Score.text = livemgr.Score()

    utils.table_sort(m_EventIDList,CmpEventAchievement) 
    utils.table_sort(m_EventIDList,CmpEventOrder)   
    local wrapContent = fields.UIList_Liveness.gameObject:GetComponent("UIWrapContentList")  
    wrapContent:RefreshWithOutSort() 
    --wrapContent:CenterOnIndex(0)
    
    for i = 1,fields.UIList_Chest.Count do
        local item = fields.UIList_Chest:GetItemByIndex(i-1)
        local databonus = item.Data
        if item and  databonus then
            --item.Enable = not livemgr.BonusGot(item.Id)
			local isGetAward = livemgr.BonusGot(item.Id) and livemgr.Score() >= databonus.grade
            item.Controls["UISprite_Get"].gameObject:SetActive(isGetAward)  
			if isGetAward == true then
				local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
				--listItem.Controls["UITexture_Chapter"].shader= inactiveShader
				--item:SetIconTexture(databonus.openIcon)
				item.transform:GetComponent("UITexture").shader= inactiveShader
			end
            item.Controls["UIGroup_Tween_Play_01"].gameObject:SetActive( not livemgr.BonusGot(item.Id) and livemgr.Score() >= databonus.grade)    
            item.transform.localPosition = Vector3(item.Data.grade / m_MaxScore * fields.UISlider_Score.backgroundWidget.width, -73, 0)
            local uiTweenPos = item.transform.gameObject:GetComponent("TweenPosition")
            if uiTweenPos then
                uiTweenPos.from =  Vector3(item.Data.grade / m_MaxScore * fields.UISlider_Score.backgroundWidget.width, -70, 0) 
                uiTweenPos.to = Vector3(item.Data.grade / m_MaxScore * fields.UISlider_Score.backgroundWidget.width, -55, 0) 
                uiTweenPos.enabled = ( not livemgr.BonusGot(item.Id) and livemgr.Score() >= databonus.grade)
            end           
        end
    end

     require("ui.dlgdialog").RefreshRedDot("welfare.dlgwelfaremain")
end

local function init(params)
    name, gameObject, fields = unpack(params)

    m_EventIDList = {}
    for id,_ in pairs(ConfigManager.getConfig("activeevent")) do
        m_EventIDList[#m_EventIDList+1] = id
    end

    local wrapContent = fields.UIList_Liveness.gameObject:GetComponent("UIWrapContentList")
    wrapContent:SetDataCount(m_EventIDList and #m_EventIDList or 0)
	inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
	
    EventHelper.SetWrapListRefresh(fields.UIList_Liveness.gameObject:GetComponent("UIWrapContentList"), function(item, itemi, i)
        if i > #m_EventIDList then return end
        local id = m_EventIDList[i]
        local dataevent = ConfigManager.getConfigData("activeevent", id)
        if not dataevent then return end

        item.Id = id
        item.Data = dataevent
      
		local count = livemgr.EventCount(id)
        local textColor = Color(209/255,71/255,38/255,1)
        if count >= dataevent.times then
            textColor = Color.green
        end


        item.Controls["UILabel_Score"].text = string.format(LocalString.Liveness.TagScore,
            dataevent.addnum * (dataevent.addtype == cfg.active.AddType.ADDPERTIME and dataevent.times or 1))
        item.Controls["UILabel_Score"].color = textColor
        item.Controls["UILabel_Descrip"].text = dataevent.decs
        item.Controls["UILabel_Descrip"].color = textColor
        item.Controls["UILabel_Count"].text = string.format("%d/%d", count, dataevent.times)
        -- item.Controls["UILabel_Count"].color = textColor
        item.Controls["UIButton_Go"].gameObject:SetActive(count < dataevent.times)
        item.Controls["UIButton_Complete"].gameObject:SetActive(count >= dataevent.times)
        item.Controls["UISlider_progress"].value = count/dataevent.times
    end)
    for i = 1,fields.UIList_Liveness.Count do
        local item = fields.UIList_Liveness:GetItemByIndex(i-1)
        if not item then return end
        item.Controls["UIButton_Complete"].isEnabled = false
        EventHelper.SetClick(item.Controls["UIButton_Go"], function()
                                 local dataevent = item.Data
                                 if not dataevent then return end
                                 uimanager.GoToDlg(dataevent.uientry,dataevent.uitabindex,dataevent.uitabindex02,nil)                                     
        end)
    end

    local datas = ConfigManager.getConfig("activebonus")
    while fields.UIList_Chest.Count < getn(datas) do
        fields.UIList_Chest:AddListItem()
    end
    for id,databonus in pairs(datas) do
        m_MaxScore = databonus.grade > m_MaxScore and databonus.grade or m_MaxScore
    end
    local bonuskeys = keys(datas)
    --printt(bonuskeys)
    table.sort(bonuskeys)
    --printt(bonuskeys)
    for i,key in ipairs(bonuskeys) do
        local item = fields.UIList_Chest:GetItemByIndex(i-1)
        if not item then return end
        local databonus = datas[key]
        if not databonus then return end

        item.transform.localPosition = Vector3(databonus.grade / m_MaxScore * fields.UISlider_Score.backgroundWidget.width, -73, 0)
        item.Id = databonus.grade
        item.Data = databonus
        item:SetIconTexture(databonus.icon)
        item.Controls["UILabel_Score"].text = string.format(LocalString.Liveness.TagScore, databonus.grade)
    end

    EventHelper.SetListClick(fields.UIList_Chest, function(item)
        local databonus = item.Data
        --printt(databonus)
        local params   = { }
        params.type    = 1
        params.items   = BonusManager.GetItemsOfSingleBonus(databonus.award)
        params.title   = LocalString.Alert_RewardsList
        params.buttons =
        {
            { 
                text = LocalString.Task_GetReward,
                Enable = (not livemgr.BonusGot(databonus.grade) and livemgr.Score() >= databonus.grade),                
                callBackFunc = function() 
                    uimanager.hide("common.dlgdialogbox_reward")
                    livemgr.GetBonus(databonus.grade, function()
                        refresh()
                    end)     
                end 
            },
        }
        local DlgAlert_ShowRewards = require("ui.dlgalert_showrewards")
        params.callBackFunc = function(p, f) 
            DlgAlert_ShowRewards.init(f)
            DlgAlert_ShowRewards.show(p) 
        end
        uimanager.show("common.dlgdialogbox_reward", params)                                       
    end)
end

local function uishowtype()
    return UIShowType.Refresh
end

local function update()
    if g_NPC and g_NPC.m_Object then
        g_NPC.m_Avatar:Update() 
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
    update       = update,
}
