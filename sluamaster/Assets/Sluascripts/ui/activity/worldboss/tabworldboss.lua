local Unpack=unpack
local EventHelper = UIEventListenerHelper
local Define=require("define")
local UIManager = require("uimanager")
local ConfigManager= require("cfg.configmanager")
local ItemManager = require("item.itemmanager")
local Monster=require("character.monster")
local TimeUtils=require("common.timeutils")
local PlayerRole=require("character.playerrole"):Instance()
local BonusManager=require("item.bonusmanager")
local WorldBossManager=require("ui.activity.worldboss.worldbossmanager")
local timeutils = require "common.timeutils"

local m_GameObject
local m_Name
local m_Fields
local m_Boss=nil
local m_WorldBoss=nil
local m_Index=-1
local m_IsBossTalk=false
local m_TalkRefreshTime=0
local m_SelectLine=false
local m_Line=-1
local m_UpdateInterval=0
local isopen = false
local tempCollider
local tempCheck

local function destroy()
end

local function OnBossLoaded()
    local modelObj = m_Boss.m_Object
    local modelTrans = modelObj.transform
    modelTrans.parent=m_Fields.UITexture_Boss.transform
    ExtendedGameObject.SetLayerRecursively(modelObj,Define.Layer.LayerUICharacter)  
    modelTrans.localScale = Vector3.one*(m_WorldBoss.scale)
    modelTrans.localPosition = Vector3(0,m_WorldBoss.localposy,-200)
    modelTrans.rotation =Quaternion.Euler(-90,m_WorldBoss.initialangle,0)
    m_Fields.UISprite_Pop.gameObject:SetActive(true)
    m_Fields.UILabel_BossTalk.text=m_WorldBoss.bosstalk
    m_IsBossTalk=true
    m_TalkRefreshTime=cfg.ectype.WorldBoss.TALK_LAST
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

local function DisplayBonus(rewards)
    m_Fields.UIList_Rewards:Clear()
    for _,id in pairs(rewards) do
        local item=ItemManager.CreateItemBaseById(id)
        local rewardItem=m_Fields.UIList_Rewards:AddListItem()
        BonusManager.SetRewardItem(rewardItem,item)       
    end
end

local function GetTimeByDate(newDate)  
    local t = os.time({year=os.date("%Y"),month=os.date("%m"),day=os.date("%d"), hour=newDate.hour, min=newDate.min, sec=newDate.sec})
    return t
end

local function GetSetverTimeByData(newDate)
	local t = os.time({year=newDate.year,month=newDate.month,day=newDate.day, hour=newDate.hour, min=newDate.min, sec=newDate.sec})
	return t
end

local function CompareDate(date1,date2)
    local result=false
    local curDate=os.date()
    if (date1.year>curDate.year) or ((date1.year==curDate.year) and (date1.month>curDate.month)) then
        result=true
    elseif (date1.month==curDate.month) then
        if (date1.day>curDate.day) then
            result=true
        elseif (date1.day==curDate.day) then
            if date1.hour>date2.hour then
                result=true
            elseif date1.hour==date2.hour then
                if date1.min>date2.min then
                    result=true
                end
            end
        end
    end
    return result
end

local function GetRemainTimeText(refreshSecs)
    local text=""
    --local tempSecs= timeutils.GetServerTime()
	--printyellow("tempSecs",tempSecs)
	local tempTimeNow = timeutils.TimeNow()
	local dateTime = GetSetverTimeByData(tempTimeNow)
    if (refreshSecs/1000>dateTime) then
        local maxRefreshTime=WorldBossManager.GetMaxRefreshTime(m_WorldBoss.id)
        if ((refreshSecs/1000)>GetTimeByDate(maxRefreshTime)) then
            text=LocalString.WorldBoss_Over
        else
            if (refreshSecs/1000>dateTime) then
                local remainTime=TimeUtils.getDateTime(refreshSecs/1000-dateTime)
                text=string.format(LocalString.WorldBoss_Refresh,remainTime.hours,remainTime.minutes,remainTime.seconds)
            else
                refresh()
            end
        end
    else
        text=LocalString.WorldBoss_Over
    end
    return text
end
  
local function GetRemainTimes(id)
    local openState=WorldBossManager.GetWorldBoss(id)
	--printyellow(openState.isopen)
    local timeList=WorldBossManager.GetRefreshTimeList(id)
    local remainTimes=0
    for _,time in pairs(timeList) do
		local tempTimeNow = timeutils.TimeNow()
		local dateTime = GetSetverTimeByData(tempTimeNow)
		local tempa =GetTimeByDate(time)
        if (dateTime <= GetTimeByDate(time)) then     
			--printyellow(">>>>>>>>>temptime",temptime,GetTimeByDate(time))      
            remainTimes=remainTimes+1          
        end
    end
    if openState and (openState.isopen~=0) then
        remainTimes=remainTimes+1
    end
    return remainTimes
end
  
local function RefreshBossIcon()  
    local worldBossData=ConfigManager.getConfig("worldboss")
    local i=0
    for i=0,(m_Fields.UIList_Boss.Count-1) do
        local item=m_Fields.UIList_Boss:GetItemByIndex(i)
        local remainTimes=GetRemainTimes(item.Id)     
        local UITexture_Boss=item.Controls["UITexture_Boss"]
        local UISprite_Refresh=item.Controls["UISprite_Refresh"]
        local UISprite_UnRefresh=item.Controls["UISprite_UnRefresh"]
        if remainTimes>0 then
           -- UITexture_Boss.shader=Shader.Find("Unlit/Transparent Colored")
            local openState=WorldBossManager.GetWorldBoss(item.Id)
            if openState then
                --UISprite_Refresh.gameObject:SetActive(openState.isopen~=0)
               -- UISprite_UnRefresh.gameObject:SetActive(openState.isopen==0)	
            end           
        else
			--m_Fields.UIButton_ChangeLine.gameObject:SetActive(false)
			--  UISprite_UnRefresh.gameObject:SetActive(true)
            -- UISprite_Refresh.gameObject:SetActive(false)
        end
		
    end
end


--检测所有分线的boss是否全部死亡
local function CheckAllBoassDead()
	local lines=WorldBossManager.GetLines()
	local linesLength = #lines
	local offset = 0
	for line,value in pairs(lines) do
		if value==2 then
			offset = offset + 1
		end    
	end
	if offset == linesLength then
		return true
	else
		return false
	end

end

local function UpdateTimeState()
    local text=""
    local openState=WorldBossManager.GetWorldBoss(m_WorldBoss.id)
    
    if openState then
        if (openState.isopen~=0) then
            text=LocalString.WorldBoss_Refreshed
			
			isopen = true
			 m_Fields.UIButton_ChangeLine.gameObject:SetActive(true)
			tempCollider.enabled = true
			tempCheck.gameObject:SetActive(true)  
        else
            text=GetRemainTimeText(openState.opentime)

			isopen = false
			--m_Fields.UIButton_ChangeLine.gameObject:SetActive(false)
			--tempCollider.enabled = false
			--tempCheck.gameObject:SetActive(false)
        end
		m_Fields.UIGroup_Button.transform:GetComponent("UIGrid").enabled = true
    end

    m_Fields.UILabel_Time.text=text    


	EventHelper.SetClick(m_Fields.UIButton_Goto,function()
		
		
		m_SelectLine=false
		local value=m_Fields.UIToggle_Line.value
		
		--printyellow("WorldBossManager")
			--TODO 添加自动换线的功能
		if value  then
			local lines=WorldBossManager.GetLines()
			for line,value in pairs(lines) do
				if value==1 then
						printyellow("WorldBossManager",line)
					  m_Line=line
					break
				end    
			end
		end
		--自动换线也需要对应的position
		local worldmapdata = ConfigManager.getConfigData("worldmap",m_WorldBoss.mapid)
		local position = Vector3(worldmapdata.WorldFlyInX,worldmapdata.WorldFlyInY,0)
		local isAlldead = CheckAllBoassDead()
		
		if isAlldead then
			UIManager.ShowSystemFlyText(LocalString.WorldBoss_NoBoss)
		else
			if m_Line~=-1 then             
				WorldBossManager.NavigateToLine({mapId=m_WorldBoss.mapid,lineId=m_Line,position=position})
			elseif value then
				WorldBossManager.SendGetWorldBossLineStatus(m_WorldBoss.id,0)
			else
				UIManager.ShowSingleAlertDlg({content=LocalString.WorldBoss_LineTip})
			end
		end
		
	end) 
	
	EventHelper.SetClick(m_Fields.UIButton_ChangeLine,function()
		if m_WorldBoss then
			WorldBossManager.SendGetWorldBossLineStatus(m_WorldBoss.id,0)           
			m_SelectLine=true
		end
	end)      
end

local function UpdateBossTalk()
    if m_IsBossTalk then
        m_TalkRefreshTime=m_TalkRefreshTime-Time.deltaTime
        if m_TalkRefreshTime<=0 then
            m_IsBossTalk=false
            m_Fields.UISprite_Pop.gameObject:SetActive(false)
            m_TalkRefreshTime=cfg.ectype.WorldBoss.TALK_INTERVAL
        end
    else
        m_TalkRefreshTime=m_TalkRefreshTime-Time.deltaTime
        if m_TalkRefreshTime<=0 then
            m_IsBossTalk=true
            m_Fields.UISprite_Pop.gameObject:SetActive(true)
            m_TalkRefreshTime=cfg.ectype.WorldBoss.TALK_LAST
        end
    end 
   
end

local function DisplayRefreshTime(id)
    local openTimeText=""
    local refreshTimes=WorldBossManager.GetRefreshTimeList(id)
    for _,timeInfo in pairs(refreshTimes) do
        if openTimeText~="" then
            openTimeText=openTimeText.."/"..(timeInfo.hour)..":"..(string.format("%02d",timeInfo.min))
        else
            openTimeText=(timeInfo.hour)..":"..(string.format("%02d",timeInfo.min))
        end
    end
    m_Fields.UILabel_RefreshTime.text= StringAddLineBreak(openTimeText,35)
end

local function DisplayDetailInfo(worldBoss)
    m_WorldBoss=worldBoss
    --TODO 解决换线问题
	WorldBossManager.SendGetWorldBossLineStatus(worldBoss.id,1)
	printyellow("SendGetWorldBossLineStatus",worldBoss.id)
    local boss=ConfigManager.getConfigData("monster",worldBoss.monsterid)
    WorldBossManager.SetCurBossName(boss.name)
    m_Fields.UILabel_BossName.text=boss.name
    AddBossModel(worldBoss.monsterid)

    m_Fields.UILabel_RecommendPower.text=worldBoss.fightforce
    m_Fields.UILabel_PersonalBossPlayerPower.text=PlayerRole.m_Power
    if PlayerRole.m_Power>=worldBoss.fightforce then
        m_Fields.UILabel_PersonalBossPlayerPower.color=Color.green
    else
        m_Fields.UILabel_PersonalBossPlayerPower.color=Color.red
    end
    m_Fields.UILabel_Objective01.text=boss.name
    DisplayBonus(worldBoss.showbonusid)
    DisplayRefreshTime(worldBoss.id)
    m_Fields.UIToggle_Line.value=true

end

local function DisplayOneWorldBoss(worldBoss)
    local bossItem=m_Fields.UIList_Boss:AddListItem()
    bossItem.Data=worldBoss
    bossItem.Id=worldBoss.id
    local boss=ConfigManager.getConfigData("monster",worldBoss.monsterid)
    local UITexture_Boss=bossItem.Controls["UITexture_Boss"]
    if boss then
        local modelData=ConfigManager.getConfigData("model",boss.modelname)
        if modelData then
            UITexture_Boss:SetIconTexture(modelData.headicon)
        end
    end  
    local UISprite_Select=bossItem.Controls["UISprite_Select"]
    UISprite_Select.gameObject:SetActive(false)
    EventHelper.SetClick(bossItem,function()
        if m_Index~=bossItem.m_nIndex then
			
            local UISprite_Select=bossItem.Controls["UISprite_Select"]
            UISprite_Select.gameObject:SetActive(true)
			
            if m_Index~=-1 then
                local oldItem=m_Fields.UIList_Boss:GetItemByIndex(m_Index)
                local oldSprite_Select=oldItem.Controls["UISprite_Select"]
                oldSprite_Select.gameObject:SetActive(false)

            end
            m_Index=bossItem.m_nIndex
            DisplayDetailInfo(worldBoss)
			
        end
		

    end)
	
			

    local mapData=ConfigManager.getConfigData("worldmap",worldBoss.mapid)
    if (mapData.openlevel)<=(PlayerRole:GetLevel()) then
        m_Index=bossItem.m_nIndex
    end
end

local function RefreshPos(offValue)
    local origiPos=m_Fields.UIScrollView_BOSS.transform.localPosition
    m_Fields.UIScrollView_BOSS.transform.localPosition=Vector3(origiPos.x-offValue,origiPos.y,origiPos.z)
    local UIPanel_Clip=m_Fields.UIScrollView_BOSS.transform:GetComponent("UIPanel")
    UIPanel_Clip.clipOffset=Vector2(UIPanel_Clip.clipOffset.x+offValue,UIPanel_Clip.clipOffset.y)
end

local function GetAllWorldBoss()
    local worldBossData=ConfigManager.getConfig("worldboss")
    m_Fields.UIList_Boss:Clear()
    for _,worldBoss in pairs(worldBossData) do
        DisplayOneWorldBoss(worldBoss)
    end
    if m_Index==-1 then
        m_Index=0
    end
    local initItem=m_Fields.UIList_Boss:GetItemByIndex(m_Index)
    if initItem then
        DisplayDetailInfo(initItem.Data)
        local Sprite_Select=initItem.Controls["UISprite_Select"]
        Sprite_Select.gameObject:SetActive(true)
        local index=m_Index-4
        if index>0 then
            local UIGrid_Boss=m_Fields.UIList_Boss.transform:GetComponent("UIGrid")
            RefreshPos(index*(UIGrid_Boss.cellWidth))
        end
    end
end

local function refresh()
    WorldBossManager.SendGetWorldBoss()
    RefreshBossIcon()
end

local function show(params)
    GetAllWorldBoss()
end

local function hide()
    if m_Boss then
        m_Boss:release()
    end
end

local function update()
    if m_WorldBoss then       
		UpdateTimeState()
		UpdateBossTalk()
    end
    if m_Boss and m_Boss.m_Object then 
        m_Boss.m_Avatar:Update() 
    end
end

local function ShowLines()

    local DlgDialogBox_List=require"ui.common.dlgdialogbox_list"
	
    if m_SelectLine then
        UIManager.show("activity.worldboss.dlgdialogbox_listmultiple",{worldBoss=m_WorldBoss})
    else
        local goLine=-1
		if isopen == true then
			local lines=WorldBossManager.GetLines()
			for line,value in pairs(lines) do
				if value==1 then
					goLine=line
					break
				end    
			end
		else
			goLine = 1
		end
		
        if goLine~=-1 then
			UIManager.hidecurrentdialog()
			local params={}
			local worldmapdata = ConfigManager.getConfigData("worldmap",m_WorldBoss.mapid)
			local position = Vector3(worldmapdata.WorldFlyInX,worldmapdata.WorldFlyInY,0)
			params.position= position
            params.mapId=m_WorldBoss.mapid
            params.lineId=goLine
            WorldBossManager.NavigateToLine(params)
        else
            UIManager.ShowSystemFlyText(LocalString.WorldBoss_NoBoss)
        end
    end   
end



local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)   
    m_UpdateInterval=Time.time
    EventHelper.SetDrag(m_Fields.UITexture_Boss,function (go,delta)
        if m_Boss then
            local modelObj=m_Boss.m_Object 
            if modelObj  then 
                local vecRotate = Vector3(0,-delta.x,0)
                modelObj.transform.localEulerAngles = modelObj.transform.localEulerAngles + vecRotate
            end
        end
    end)
    EventHelper.SetClick(m_Fields.UITexture_Boss,function ()
        if m_Boss and m_WorldBoss then
            UIManager.ShowSingleAlertDlg({title=LocalString.WorldBoss_Introduction,content=string.gsub(m_WorldBoss.bossdes,"\\n","\n")})
        end
    end)
	tempCollider = m_Fields.UIToggle_Line.gameObject:GetComponent("BoxCollider")
	tempCheck = m_Fields.UIToggle_Line.transform:Find("Check")
end

local function SetLine(line)
    m_Line=line
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    RefreshBossIcon = RefreshBossIcon,
    ShowLines = ShowLines,
    SetLine = SetLine,
    uishowtype = uishowtype,
}