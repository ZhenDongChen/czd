local DlgUIMain_Combat = require("ui.dlguimain_combat")
local DlgUIMain_RoleInfo = require("ui.dlguimain_roleinfo")
local MapManager =require("map.mapmanager")

local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local defineenum = require "defineenum"
local PlayerRole
local FashionManager = require"character.fashionmanager"
local dlguimain_partner = require"ui.partner.dlguimain_partner"
local charactermanager = require "character.charactermanager"
local ConfigManager = require "cfg.configmanager"
local EctypeManager = require"ectype.ectypemanager"
local DlgEctypeManager = require"ui.ectype.dlgectypemanager"
local DlgMain_Open = require("ui.dlgmain_open.main_openmanager")
local RecommendEquipTip = require("ui.uimain.recommendequip")
local ModuleLockManager = require("ui.modulelock.modulelockmanager")
local PlayerStateTip = require("ui.uimain.playerstatetip")
local OtherCharacterHead = require("ui.uimain.othercharacterhead")
local DlgActivityManager = require"ui.activity.dlgactivitymanager"
local BagManager = require ("character.bagmanager")
local WelfareManager = require "ui.welfare.welfaremanager"
local PetManager = require("character.pet.petmanager")
local RankManager = require "ui.rank.rankmanager"
local OperationActivity = require("ui.operationactivity.operationactivitymanager")
local DlgUIMain_Team = require("ui.dlguimain_team")
local taskmanager = require "taskmanager"
local DlgUIMain_Task = require("ui.dlguimain_task")
local dlguimain_hide = require("ui.dlguimain_hide")
local redpacketinfo = require"ui.activity.redpacket.redpacketinfo"
local Friendmanager = require("ui.friend.friendmanager")
local LotteryManager = require "ui.lottery.lotterymanager"
local playerRole
local ShopManager = require "shopmanager"
local DlgUIMain_HPTip = require("ui.dlguimain_hptip")
local MultiEctypeManger = require("ui.ectype.multiectype.multiectypemanager")
local redpacketmanager = require"ui.activity.redpacket.redpacketmanager"
local TimerBuffDescription
local DlgUIMain_Novice=require"ui.dlguimain_novice"
local BonusManager = require("item.bonusmanager")
local timeutils      = require("common.timeutils")

local Camera = UnityEngine.Camera.main

local CameraManager = require("cameramanager")
local logmanager = require("loggermanager")
local mathutils = require("common.mathutils")
local colorutil = require("common.colorutil")
local CharacterType = defineenum.CharacterType
local NpcStatusType = defineenum.NpcStatusType
local TaskType   = defineenum.TaskType


local subFunctions = {}

local gameObject
local name
local fields
local textList

local curTaskTabIndex = 0
local refreshMapInfo = 0 
local showBuffDscriptionTime = 5
local m_WMiniMapScaleRatio=1
local m_HMiniMapScaleRatio=1
local m_ShowDis=50
local isUIlistBuffActive = false

local ModuleList = {}
local MapPlayerObjList = {} 
local MapMonsterObjList = {} 
local MapNPCObjList = {} 

local subFunctions = {}

local curTaskTabIndex = 0

local taskGroupGo

local newSystemInfo = nil

local function to2num(value)
    str = tostring(value + 100)
    return str:sub(2)
end



local function updatePlayerRolesEffect(isInit)
    local MaxEffectCount = 5
    if TimerBuffDescription then
        TimerBuffDescription = TimerBuffDescription + Time.deltaTime
        if TimerBuffDescription > showBuffDscriptionTime then
            TimerBuffDescription = nil
            fields.UISprite_BuffDiscription.gameObject:SetActive(false)
        end
    end
	playerRole = PlayerRole:Instance()
    local lst = playerRole.m_Effect:GetEffectList()
	--printyellow(" playerRole.m_Effect:Altered() ", playerRole.m_Effect:Altered())
    if playerRole.m_Effect:Altered() or isInit then
        playerRole.m_Effect:ChangeAltered()
        local effectList = playerRole.m_Effect:GetEffectList()
		printyellow("effectlist number:",#effectList)
        showing = nil

        for i=1,5 do
            if effectList[i] ~= nil then
                uiBuffs[i].UISprite_Buff.gameObject:SetActive(true)
                uiBuffs[i].UISprite_Buff.spriteName =effectList[i].icon
				printyellow("XXXXXXXXXXXXXXXeffectListname:",effectList[i].icon)
            else
                uiBuffs[i].UISprite_Buff.gameObject:SetActive(false)
            end
        end
    end
end

local function InitBuffs()
    uiBuffs = {}
    fields.UISprite_BuffDiscription.gameObject:SetActive(false)
    TimerBuffDescription = nil
    fields.UIList_Buff:Clear()
    for i=1,5 do
        local item = fields.UIList_Buff:AddListItem()
        local UISprite_Buff = item.Controls["UISprite_Buff"]
        uiBuffs[i] = {}
        uiBuffs[i].item = item
        uiBuffs[i].UISprite_Buff = UISprite_Buff
        uiBuffs[i].eid = nil
    end
    updatePlayerRolesEffect(true)
end


----------------------------------------------------------------------

-- ??????????????Χ??????
local function UpdateAroundObject()
    local characters=charactermanager.GetCharacters()
    local i=0
    local j=0
    local k=0
	for id, character in pairs(characters) do
        local playerRolePos=PlayerRole:Instance():GetRefPos() --????????λ?????
        local characterPos=character:GetRefPos() -- ????????????????λ???????NPC ??????????
		--printyellow("m_ShowDis"..m_ShowDis)
        if mathutils.DistanceOfXoY(characterPos,playerRolePos)<m_ShowDis-500 then
            local pos=Vector3((characterPos.x-playerRolePos.x)*m_WMiniMapScaleRatio,(characterPos.y-playerRolePos.y)*m_HMiniMapScaleRatio,0)
            local targetObj=nil
            local UISprite_MapBgObj=fields.UISprite_MapBG.gameObject
            if (character:IsPlayer()) and (not character:IsRole()) then
                i=i+1
                if MapPlayerObjList[i] then
                    targetObj=MapPlayerObjList[i]
                else
                    local playerObj=fields.UISprite_Player.gameObject
                    targetObj=NGUITools.AddChild(UISprite_MapBgObj,playerObj) --??????????????
                    table.insert(MapPlayerObjList,targetObj)
                end
            elseif character:IsNpc() then
                if (character.m_Object) and (character.m_Object.activeSelf) then
                    j=j+1
                    if MapNPCObjList[j] then
                        targetObj=MapNPCObjList[j]
                    else
                        local npcObj=fields.UISprite_NPC.gameObject
                        targetObj=NGUITools.AddChild(UISprite_MapBgObj,npcObj) -- ?????cpn?????
                        table.insert(MapNPCObjList,targetObj)
                    end
                 end
            elseif character:IsMonster() then
                k=k+1
                if MapMonsterObjList[k] then
                    targetObj=MapMonsterObjList[k]
                else
                    local monsterObj=fields.UISprite_Monster.gameObject
                    targetObj=NGUITools.AddChild(UISprite_MapBgObj,monsterObj) -- ??????????????
                    table.insert(MapMonsterObjList,targetObj)
                end
            end
            if targetObj then
                targetObj:SetActive(true)
                targetObj.transform.localPosition=pos
            end
        end
    end
    local x=0
    for x=(i+1),#MapPlayerObjList do
        if not IsNull(MapPlayerObjList[x]) then
            MapPlayerObjList[x]:SetActive(false)
        end
    end
    for x=(j+1),#MapNPCObjList do
        if not IsNull(MapNPCObjList[x]) then
            MapNPCObjList[x]:SetActive(false)
        end
    end
    for x=(k+1),#MapMonsterObjList do
        if not IsNull(MapMonsterObjList[x]) then
            MapMonsterObjList[x]:SetActive(false)
        end
    end
end

local function UpdateMiniMapInfo()
	if PlayerRole:Instance() and PlayerRole:Instance().m_Object then
		if refreshMapInfo and os.time() - refreshMapInfo >= 1 then
			refreshMapInfo = os.time()
			local mPlayerTransform = PlayerRole:Instance().m_Object.transform
			local UISprite_Player = fields.UISprite_PlayerRole
			UISprite_Player.transform.rotation = Quaternion.Euler(0, 0,- mPlayerTransform.rotation.eulerAngles.z)
			local UITexture_Map=fields.UITexture_Map
            local tempPosition = MapManager.GetTransferCoord(mPlayerTransform.position,m_WMiniMapScaleRatio,m_HMiniMapScaleRatio)
            local leftBorder = UITexture_Map.width/2- fields.UISprite_MapBG.width/2
            local rightBorder = -leftBorder
            local downBorder = UITexture_Map.height/2- fields.UISprite_MapBG.height/2
            local upBorder = -downBorder
            local offsetX = 0
            local offsetY = 0
            if tempPosition.x> leftBorder or tempPosition.x < rightBorder then
                offsetX = tempPosition.x> leftBorder and -(tempPosition.x- leftBorder) or -(tempPosition.x- rightBorder)
                tempPosition.x = tempPosition.x> leftBorder and leftBorder or rightBorder
            end
            if tempPosition.y> downBorder or tempPosition.y < upBorder then
                offsetY = tempPosition.y> downBorder and -(tempPosition.y- downBorder) or -(tempPosition.y- upBorder)
                tempPosition.y = tempPosition.y> downBorder and downBorder or upBorder
            end
            UISprite_Player.transform.localPosition = Vector3(offsetX,offsetY,0)
			UITexture_Map.transform.localPosition = tempPosition
			fields.UILabel_XY.text = math.ceil(mPlayerTransform.position.x*SCALE_XY) .. "," .. math.ceil(mPlayerTransform.position.y*SCALE_XY)
			UpdateAroundObject()
		end
	end
end

local elapsedtime = -60

local function UpdateTime()
    if os.time()- elapsedtime > 60 then
        local ttime
        elapsedtime = os.time()
        ttime = os.date("*t")
        fields.UILabel_Time.text = string.format("%2d:%.2d", ttime.hour, ttime.min)
    end

end

local function RefreshMiniMap()
    local UITexture_Map=fields.UITexture_Map
    local ConfigManager=require"cfg.configmanager"
    local mapData=ConfigManager.getConfigData("worldmap",PlayerRole:Instance():GetMapId())
    if mapData then
        local sceneName=mapData.scenename
        local sceneData=ConfigManager.getConfigData("scene",sceneName)
        local thunbnailSizeX=sceneData.thunbnailX
		local thunbnailSizeY=sceneData.thunbnailY
        local scenesizeX=sceneData.scenesizeX
		local scenesizeY=sceneData.scenesizeY
        UITexture_Map:SetIconTexture(sceneName)
        UITexture_Map.width=thunbnailSizeX
        UITexture_Map.height=thunbnailSizeY
        m_WMiniMapScaleRatio =  thunbnailSizeX/scenesizeX
        m_HMiniMapScaleRatio = thunbnailSizeY/scenesizeY
	    local UISprite_MapBG=fields.UISprite_MapBG
        local showAreaSize=UISprite_MapBG.width/2
        m_ShowDis=showAreaSize*scenesizeX/thunbnailSizeX
    end
end

local function DetectCharacterClick()
    local clickEvent = false
    local clickPos = Vector3(0,0,0)
	
    if Input.GetMouseButtonDown(0) then
        clickEvent = true
        clickPos = Input.mousePosition
      --  printyellow("dlguimain 1")
    elseif Input.touchCount > 0 and Input.GetTouch(0).phase == TouchPhase.Began then
        clickEvent = true
        clickPos = Input.mousePosition
    end
    if clickEvent then

      --  local NoviceGuideManager=require"noviceguide.noviceguidemanager" --???????
		--or (NoviceGuideManager.IsGuiding()) or (uimanager.isshow("dlgalert_reminder_singlebutton")) or (uimanager.isshow("dlgalert_reminderimportant")) or (uimanager.isshow("dlgalert_reminder")) 
        if not uimanager.isshow("dlguimain") then
            return
        end
        local ray = Camera:ScreenPointToRay(clickPos)
        local ret = false
        local hit = nil
        ret, hit = Physics.Raycast(ray, hit)
        if ret and hit and hit.collider and hit.transform then
            local gameObj = hit.collider.gameObject.transform.parent.gameObject
            local characters = charactermanager.GetCharacters()
            for id, char in pairs(characters) do
 
                if char.m_Object and char.m_Object == gameObj then  
					if CharacterType.Rune == char.m_Type then --- 聚宴符咒点击不显示
						OtherCharacterHead.SetHeadInfo(false, char)
					else
						OtherCharacterHead.SetHeadInfo(true, char)
                    end
                    if not char:IsRole() and not char:IsMineral() and not char:IsNpc() and CharacterType.Rune ~= char.m_Type then
                        PlayerRole:Instance():SetTarget(char)
                    end
                elseif not char:IsSimplified() and  char:IsPlayer() and char:IsClick(gameObj) then
                    OtherCharacterHead.SetHeadInfo(true, char)
                end

                 -- 矿物
                 local miningmanager = require "miningmanager"
                 if char.m_Type == CharacterType.Mineral and char.m_Object == gameObj and miningmanager.GetCurMineID() ~= char.m_Id then
                    if miningmanager.IsCanBeMined(char.m_Id) then
                        miningmanager.NavigateToMine(char.m_Id, char:GetPos())
                    end
                    break
                end
                    -- NPC
                if char.m_Type == CharacterType.Npc and char.m_Object == gameObj then
                    local npcstatus = taskmanager.GetNpcStatus(char.m_CsvId)
                    if npcstatus and npcstatus ~= NpcStatusType.None then
                        local allNpcStatus = taskmanager.GetAllNpcStatus(char.m_CsvId)
                        local taskid = 0
                        -- 优先顺序：主线>支线>家族环
                        local priority = 0
                        for _key, _value in pairs(allNpcStatus) do
                            if _value == npcstatus then
                                local tasktype = taskmanager.GetTaskType(_key)
                                if tasktype == TaskType.Mainline then
                                        taskid = _key
                                        break
                                elseif tasktype == TaskType.Branch and priority < 2 then
                                    taskid = _key
                                    priority = 2
                                elseif tasktype == TaskType.Family and priority < 1 then
                                    taskid = _key
                                    priority = 1
                                end
                            end
                        end

                        local task = taskmanager.GetTask(taskid)
                        if npcstatus == NpcStatusType.CanAcceptTask then
                            taskmanager.AcceptTask(char.m_CsvId, task.id)
                        elseif npcstatus == NpcStatusType.CanCommitTask then
                            taskmanager.NavigateToRewardNPC(char.m_CsvId, task.id)
                        end
                    else
                        local heroChallengeManager = require("ui.activity.herochallenge.herochallengemanager")
                        if char.m_CsvId == 23000385 then      --家族广场对应的黑市商人
                            uimanager.showdialog("dlgshop_common",nil,3)
                        elseif char.m_CsvId == 23000384 then  --家族广场对应的仙府聚宴管理者
                            uimanager.show("family.dlgbanquet")
                        elseif char.m_CsvId == 23000454 then  --药店
                                            local CarryShopManager = require"ui.carryshop.carryshopmanager"
                                            local items = CarryShopManager.GetItemsByLevel(PlayerRole:Instance().m_Level)
                                            uimanager.showdialog("carryshop.dlgcarryshop",{items = items})
                                    elseif char.m_CsvId==23000455 then --仓库
                                            uimanager.showdialog("dlgwarehouse")
                                        elseif char.m_CsvId == heroChallengeManager.GetNpcId() then  --英雄挑战副本npc
                                            heroChallengeManager.DisplayNpcTalk()
                                        elseif char.m_CsvId == heroChallengeManager.GetCurTaskNpc() then
                                            heroChallengeManager.OpenTask()
                        else
                            --复活碧瑶
                            -- local ResurgenceBiyaoManager= require "ui.resurgencebiyao.resurgencebiyaomanager"
                            -- local rebornData = ResurgenceBiyaoManager.getLocalConfig()
                            -- if rebornData then
                            --     if char.m_CsvId==rebornData.npcmsg1.npcid then
                            --         uimanager.show("resurgencebiyao.dlgalert_delivery",{HeroData = rebornData.npcmsg1})
                            --     end
                            --     if char.m_CsvId==rebornData.npcmsg2.npcid then
                            --         uimanager.show("resurgencebiyao.dlgalert_delivery",{HeroData = rebornData.npcmsg2})
                            --     end
                            --     if char.m_CsvId==rebornData.npcmsg1.winnpc then
                            --         local heroData = {}
                            --         heroData.talkdecs = rebornData.npcmsg1.winnpctalk
                            --         heroData.npchead = rebornData.npcmsg1.winnpchead
                            --         heroData.npcname = rebornData.npcmsg1.winnpcname
                            --         uimanager.show("resurgencebiyao.dlgalert_delivery",{HeroData = heroData,justTalk = true})
                            --     end
                            -- end     
                        end
                    end
                    break
                end
            end --for end
		else
			local WorldPos = Camera:ScreenToWorldPoint(clickPos);
			local param         = {
                targetPos       = Vector3(WorldPos.x * SCALE_XY, WorldPos.y * SCALE_XY, 0),
            }
            PlayerRole:Instance():navigateTo(param)
			
			taskmanager.SetExecutingTask(0)
        end
    end
end
local function RefreshMapName()
    -- ????С??????
    local UILabel_MapName = fields.UILabel_MapName
    local UILabel_Line = fields.UILabel_Line
    local worldMapData = ConfigManager.getConfigData("worldmap", PlayerRole:Instance():GetMapId())
    local mapNameText = ""
    if worldMapData and worldMapData.mapname then
        mapNameText = worldMapData.mapname
    end
    UILabel_MapName.text = mapNameText
    local familymgr = require("family.familymanager")
    if familymgr.IsInStation() then
        UILabel_Line.text = ""
    else
        UILabel_Line.text =(PlayerRole:Instance().m_MapInfo:GetLineId()) ..(LocalString.LineMap_Line)
    end

end

local function AddMainScreenMessage(params)
	print("AddMainScreenMessage")
	  if params.isTopMessage then
		    fields.UILabel_Chat_Top.text = params.str
	else
          textList:Add(params.str)
          --if params.bagtype == 0 then
			--	local SettingChat = params.SettingChat
			--	if not SettingChat then
			--		 textList:Add(params.str)
			--	elseif SettingChat[params.channel].isTick == true then
			--		 textList:Add(params.str)
			--	end
		 --end
	  end
end

local function RefreshMainScreenMessage()
	local ChatManager = require("ui.chat.chatmanager")
	ChatManager.UpdateMainScreenMesssage(ChatManager.GetCurChannel(),textList)
end


local function RefreshBatteryLevel()
    if uimanager.GetIsLock() then
        return
    end
	  local batterylevel = tonumber(uimanager.GetBatteryLevel())
	  if batterylevel<25 then
		    fields.UISprite_Battery.spriteName = "Sprite_BatteryEmpty";
	  elseif batterylevel<50 then
		    fields.UISprite_Battery.spriteName = "Sprite_Battery1of3";
	  elseif batterylevel<75 then
		    fields.UISprite_Battery.spriteName = "Sprite_Battery2of3";
	  else
		    fields.UISprite_Battery.spriteName = "Sprite_BatteryFull";
	  end
end


local function RefreshTaskList()
    DlgUIMain_Task.RefreshTaskList()
end


local function ClickSetRedDot(type)
    local module=ModuleList[type]
    if module then
        local moduleData=ConfigManager.getConfigData("uimainreddot",type)
        if moduleData.dottype==cfg.ui.DotType.ONCE then
            module.click=true
        end
    end
end

local function OnUIGroup_Vip()
	  uimanager.showdialog("vipcharge.dlgprivilege_vip")
end

local function OnButtonSendRedPacket()
    uimanager.showdialog("activity.redpacket.dlgsendred")
end

local function OnButtonReceiveRedPacket()
    local pkg = redpacketinfo.GetUnfetchedPacket()
	if pkg ~= nil then
		redpacketmanager.send_CGetMoney(pkg.packageid, pkg.senderid)
		-- uimanager.show("activity.redpacket.dlgredinfo")
	end
end

local function OnButtonFirstCharge()
    print("OnButtonFirstCharge 0");
    uimanager.showdialog("vipcharge.dlgfirstofcharge")
end

local function OnButtonReCharge()
    print("OnButtonReCharge 0");
    uimanager.showdialog("vipcharge.dlgrecharge")
end

local function OnButton_Head()
    if EctypeManager.IsInEctype() then
        return
    end
	uimanager.showdialog("dlgmain_open")
end


local function OnButton_Bag()
    ClickSetRedDot(cfg.ui.FunctionList.BAG)
    local bagmanager = require("character.bagmanager")
    uimanager.showdialog("playerrole.dlgplayerrole",nil,2)
end

local function OnButton_Shop()

    ClickSetRedDot(cfg.ui.FunctionList.SHOP)
    uimanager.showdialog("dlgshop_common",nil,1)
end

local function OnButton_Welfare()
    ClickSetRedDot(cfg.ui.FunctionList.WELFARE)
    uimanager.showdialog("welfare.dlgwelfaremain")
end

local function OnButton_Battle()
    ClickSetRedDot(cfg.ui.FunctionList.BATTLE)
    uimanager.showdialog("arena.dlgarena")
end

local function OnButton_Ectype()
    ClickSetRedDot(cfg.ui.FunctionList.ECTYPE)
    uimanager.showdialog("ectype.dlgentrance_copy")
end

local function OnButton_Friend()

    uimanager.showdialog("friend.dlgfriend")
end

local function OnButton_Pray()
	print("OnButton_Pray")
    uimanager.showdialog("lottery.dlglottery")
end

local function OnButton_OperationActivity()
    uimanager.showdialog("operationactivity.dlgoperationactivity")
end

local function OnButton_Partner()
	print("OnButton_Partner")
    uimanager.showdialog("partner.dlgpartner_list")
end

----
--加号按钮处理事件
local function OnButton_Strech()
    local channelid = Game.Platform.Interface.Instance:GetSDKPlatform()
    if channelid == 39 then
          if fields.UIButton_QQVip.gameObject.activeSelf then
                fields.UIButton_QQVip.gameObject:SetActive(false)
          else
                fields.UIButton_QQVip.gameObject:SetActive(true)
          end
    end

    if fields.UISprite_Close.gameObject.activeSelf == true then
        fields.UISprite_Close.gameObject:SetActive(false)
        fields.UISprite_Open.gameObject:SetActive(true)
    else
        fields.UISprite_Close.gameObject:SetActive(true)
        fields.UISprite_Open.gameObject:SetActive(false)
    end
end


local function OnButton_ExtraExp()
    uimanager.showdialog("dlgdailyexp")
end
local function SetBtnEffcet_DailyOnline(bShowEffect)
    local trfEffect = fields.UIButton_DailyOnline.gameObject.transform:Find("xuanzhuankuang")
    if trfEffect~=nil then
        trfEffect.gameObject:SetActive(bShowEffect)
    end
end
local function OnButton_DailyOnline()
    uimanager.showdialog("welfare.dlgdailyonline")
end

local function ExtraExp_UnRead()
   local expdata = ConfigManager.getConfigData("exptable", PlayerRole:Instance().m_Level)
   if expdata ~= nil then
       local remainExp = expdata.bonusexp - PlayerRole:Instance().m_TodayKillMonsterExtraExp
       if remainExp > 0 then
           return true
       else
           return false
       end
   end
   return false
end

----
--家族事件
local function OnButton_Family()
    ClickSetRedDot(cfg.ui.FunctionList.FAMILY)
    local mgr = require("family.familymanager")
    mgr.OpenDlg()
end
local function OnButton_RankList()
	ClickSetRedDot(cfg.ui.FunctionList.RANKLIST)
    uimanager.showdialog("rank.dlgranklist")
end


local function OnButton_Activity()
    ClickSetRedDot(cfg.ui.FunctionList.ACTIVITY)
    uimanager.showdialog("activity.dlgactivity")
end


local function OnButton_Liveness()
    -- ClickSetRedDot(cfg.ui.FunctionList.LIVENESS)
    -- uimanager.showdialog("guide.dlglivenessmain")
end

--local function OnButton_Fashion()
--    ClickSetRedDot(cfg.ui.FunctionList.FASHION)
--    uimanager.showdialog("guide.dlglivenessmain")
--end


local function StrechUnRead()
    return ((ModuleLockManager.GetModuleStatusByType(cfg.ui.FunctionList.BATTLE)==defineenum.ModuleStatus.UNLOCK) and require("ui.arena.modulearena").UnRead())
           or ((ModuleLockManager.GetModuleStatusByType(cfg.ui.FunctionList.ACTIVITY)==defineenum.ModuleStatus.UNLOCK) and DlgActivityManager.UnRead())
           or ((ModuleLockManager.GetModuleStatusByType(cfg.ui.FunctionList.FAMILY)==defineenum.ModuleStatus.UNLOCK) and require("family.familymanager").UnRead())
           or ((ModuleLockManager.GetModuleStatusByType(cfg.ui.FunctionList.ECTYPE)==defineenum.ModuleStatus.UNLOCK) and DlgEctypeManager.UnRead())
end

local function SwitchAutoFight(b)
    DlgUIMain_Combat.SwitchAutoFight(b)
end

local function RegisterAllModules()
	ModuleList =
	{
	    [cfg.ui.FunctionList.ACTIVITY]      = {icon=fields.UIButton_Activity,redDotFunc=(DlgActivityManager.UnRead),callBackFunc=OnButton_Activity},
        [cfg.ui.FunctionList.SHOP] = {icon=fields.UIButton_ShopIcon,redDotFunc=(ShopManager.UnRead),callBackFunc=OnButton_Shop},
		[cfg.ui.FunctionList.BAG] = {click=false,icon=fields.UIButton_Bag,redDotFunc=(BagManager.UnUimainRead),callBackFunc=OnButton_Bag},
        [cfg.ui.FunctionList.WELFARE] = {icon=fields.UIButton_AwardCenterIcon,redDotFunc=(WelfareManager.UnRead),callBackFunc=OnButton_Welfare},
        [cfg.ui.FunctionList.HEAD] = {icon=fields.UISprite_HeroHeadAll,redDotFunc=(DlgMain_Open.UnRead),callBackFunc=OnButton_Head},
        [cfg.ui.FunctionList.ECTYPE] = {icon=fields.UIButton_Instance,redDotFunc=(DlgEctypeManager.UnRead),callBackFunc=OnButton_Ectype},
        [cfg.ui.FunctionList.BATTLE] = {icon=fields.UIButton_Battlefield,redDotFunc=(require("ui.arena.modulearena").UnRead),callBackFunc=OnButton_Battle},

        [cfg.ui.FunctionList.PARTNER]       = {icon=fields.UIButton_Partner,callBackFunc=OnButton_Partner,redDotFunc=PetManager.UnRead},	
        [cfg.ui.FunctionList.PLUSSIGN]      = {icon=fields.UIButton_Stretch,redDotFunc=(StrechUnRead),callBackFunc=OnButton_Strech}, -- 加号按钮
        [cfg.ui.FunctionList.MOUNTSHORTCUT] = {icon=fields.UIButton_Ride,callBackFunc = DlgUIMain_Combat.OnButton_Ride},--????
        [cfg.ui.FunctionList.TFBOYS]        = {icon=fields.UIButton_ActivityIcon,redDotFunc=(OperationActivity.UnRead),callBackFunc=OnButton_OperationActivity},---青春修炼手册
	
	    [cfg.ui.FunctionList.PRAY]          = {icon=fields.UIButton_Pray,redDotFunc=(LotteryManager.UnRead),callBackFunc=OnButton_Pray},
        [cfg.ui.FunctionList.RANKLIST]      = {icon=fields.UIButton_Ranklist,redDotFunc=(RankManager.UnRead),callBackFunc=OnButton_RankList},
		[cfg.ui.FunctionList.FRIEND]        = {icon=fields.UIButton_Friend,redDotFunc=(Friendmanager.UnRead),callBackFunc=OnButton_Friend},
        [cfg.ui.FunctionList.DAILYEXTRAEXP] = {icon=fields.UISprite_KillEXP,redDotFunc=ExtraExp_UnRead, callBackFunc=OnButton_ExtraExp}, --- 乾坤鼎
        --- 在线礼包 UIButton_DailyOnline
        [cfg.ui.FunctionList.DAILYONLINE]   = {icon=fields.UIButton_DailyOnline,redDotFunc=(WelfareManager.UnRead_DailyOnlinePage),callBackFunc=OnButton_DailyOnline,setBtnFunc=SetBtnEffcet_DailyOnline},
        [cfg.ui.FunctionList.FAMILY]        = {icon=fields.UIButton_Family,redDotFunc=(require("family.familymanager").UnRead),callBackFunc=OnButton_Family},--家族
        [cfg.ui.FunctionList.LIVENESS]      = {icon=fields.UIButton_Active,redDotFunc=(require("guide.livenessmanager").UnRead),callBackFunc=OnButton_Liveness},
		
        -----[cfg.ui.FunctionList.FASHION]      = {icon=fields.UIButton_Fashion,redDotFunc=(require("character.fashionmanager").UnRead),callBackFunc=OnButton_Fashion},
        [cfg.ui.FunctionList.VIPLEVEL]      = {icon=fields.UIGroup_Vip,redDotFunc=(require("ui.vipcharge.vipchargemanager").UnRead),callBackFunc=OnUIGroup_Vip},
        [cfg.ui.FunctionList.FIRSTCHARGE]   = {icon=fields.UISprite_FirstOfCharge,redDotFunc=(require("ui.vipcharge.vipchargemanager")).UnReadFirstCharge,callBackFunc=OnButtonFirstCharge},
        [cfg.ui.FunctionList.RECHARGE]      = {icon=fields.UISprite_Recharge,redDotFunc=(require("ui.vipcharge.vipchargemanager")).UnReadReCharge,callBackFunc=OnButtonReCharge},
        [cfg.ui.FunctionList.SENDREDPACKET]       = {icon=fields.UIButton_Red, redDotFunc=(require("ui.activity.redpacket.redpacketmanager")).UnReadSend,callBackFunc=OnButtonSendRedPacket},
        [cfg.ui.FunctionList.RECEIVEREDPACKET]       = {icon=fields.UIButton_RedGet, redDotFunc=(require("ui.activity.redpacket.redpacketmanager")).UnReadReceive,callBackFunc=OnButtonReceiveRedPacket},
		[cfg.ui.FunctionList.LEVELVIP]      = {icon=fields.UIButton_Vip,redDotFunc=(require("ui.vipcharge.vipchargemanager").UnRead),callBackFunc=OnUIGroup_Vip},
    }
    

	
end

local function GetModule(type)
    return ModuleList[type]
end

local function RefreshModuleByType(type)
    local moduleData=ModuleList[type]
    if moduleData then
        local configData=ConfigManager.getConfigData("uimainreddot",type)
        local conditionData=ConfigManager.getConfigData("moduleunlockcond",configData.conid)
        local status=ModuleLockManager.GetModuleStatusByType(type)
        if status==defineenum.ModuleStatus.LOCKED then  --δ????
            if configData.opentype==cfg.ui.FunctionOpenType.APPEAR then
                moduleData.icon.gameObject:SetActive(false)
            elseif configData.opentype==cfg.ui.FunctionOpenType.UNLOCK then
                local lockObj=moduleData.icon.gameObject.transform:Find("UISprite_Lock")
                if lockObj then
                    lockObj.gameObject:SetActive(true)
                end
                local redDotSprite=moduleData.icon.gameObject.transform:Find("UISprite_Warning")
                if redDotSprite then
                    redDotSprite.gameObject:SetActive(false)
                end
                EventHelper.SetClick(moduleData.icon,function()
                    if conditionData then
                        local text=""
                        if conditionData.openlevel~=0 then
                            text=(conditionData.openlevel)..(LocalString.WorldMap_OpenLevel)
                        elseif conditionData.opentaskid~=0 then
                            local taskData=ConfigManager.getConfigData("task",conditionData.opentaskid)
                            if taskData then
                                text=string.format(LocalString.CompleteTaskOpen,taskData.basic.name)
                            end
                        end
                        uimanager.ShowSystemFlyText(text)
                    end

                end)
            end
        elseif status==defineenum.ModuleStatus.UNLOCK then  --?????
            if configData.opentype==cfg.ui.FunctionOpenType.APPEAR then
                moduleData.icon.gameObject:SetActive(true)
            elseif configData.opentype==cfg.ui.FunctionOpenType.UNLOCK then
                local lockObj=moduleData.icon.gameObject.transform:Find("UISprite_Lock")
                if lockObj then
                    lockObj.gameObject:SetActive(false)
                end
                local redDotSprite=moduleData.icon.gameObject.transform:Find("UISprite_Warning")
                if redDotSprite then
                    if configData and (((configData.dottype==cfg.ui.DotType.ONCE) and (moduleData.click)) or (configData.dottype==cfg.ui.DotType.NONE)) then
                        redDotSprite.gameObject:SetActive(false)
                        if moduleData.setBtnFunc~=nil then
                            moduleData.setBtnFunc(false)
                        end
                    else
                        if moduleData.redDotFunc~=nil then
                            --先注释掉其他数据暂时没有??
                            local showRed = moduleData.redDotFunc()
                            redDotSprite.gameObject:SetActive(showRed)
                            if moduleData.setBtnFunc~=nil then
                                moduleData.setBtnFunc(showRed)
                            end
                        end
                    end
                end
            end
            EventHelper.SetClick(moduleData.icon,function()
				
                if moduleData.callBackFunc then
					
                    moduleData.callBackFunc()
                end
            end)
        end
    end
end

local function RefreshAllModules()
    for id,moduleData in pairs(ModuleList) do
        RefreshModuleByType(id)
    end
end

local function RefreshRedDotType(type)
    local module=ModuleList[type]
    if module then
        module.click=false
        if (uimanager.isshow(name)) then
            local redDotSprite=module.icon.gameObject.transform:Find("UISprite_Warning")
            local configData=ConfigManager.getConfigData("uimainreddot",type)
            if redDotSprite  and configData and (configData.dottype~=cfg.ui.DotType.NONE) then
                redDotSprite.gameObject:SetActive(module.redDotFunc())
            else
                redDotSprite.gameObject:SetActive(false)
            end
        else
            RefreshAllModules()
        end
    end
end

local function RefreshPKStateIcon()
    DlgUIMain_Combat.RefreshPKStateIcon()
end



local function ClearChatArea()
	  fields.UILabel_Chat_Top.text = ""
	  textList:Clear()
end

local function RefreshPetAttributes(params)
    dlguimain_partner.OnAttrChange(params)
end

local function PartnerEquipCD(cd)
    dlguimain_partner.EquipCD(cd)
end

local function RefreshFieldPets()
    dlguimain_partner.UpdateFieldPets()
end

local function RefreshChargeIcon()
    local PrologueManager = require"prologue.prologuemanager"
    if PrologueManager.IsInPrologue() then
        fields.UISprite_FirstOfCharge.gameObject:SetActive(false)
        fields.UISprite_Recharge.gameObject:SetActive(false)
		return 
	end

    local VipChargeManager = require("ui.vipcharge.vipchargemanager")

    if VipChargeManager.GetFirstPayUsed() == 1 then    --已充值已领取
        fields.UISprite_FirstOfCharge.gameObject:SetActive(false)
        fields.UISprite_Recharge.gameObject:SetActive(true)
    else                                               --已充值未领取或者未充值
        fields.UISprite_FirstOfCharge.gameObject:SetActive(true)
        fields.UISprite_Recharge.gameObject:SetActive(false)
    end
end

local function RefreshRoleInfo()
    DlgUIMain_RoleInfo.RefreshRoleInfo()
    RefreshChargeIcon()
end

local function StopSkillsOperations()
    DlgUIMain_Combat.SetSkillsEnable(false)
    DlgUIMain_Combat.SetAttackEnable(false)
end

local function ResumeSkillsOperations()
    DlgUIMain_Combat.SetSkillsEnable(true)
    DlgUIMain_Combat.SetAttackEnable(true)
    PlayerRole:Instance().m_Effect:RefreshAbilitiesOnUI()
end


local function HideRideButton(close)
    if ModuleLockManager.GetModuleStatusByType(cfg.ui.FunctionList.MOUNTSHORTCUT) == defineenum.ModuleStatus.UNLOCK then
        fields.UIButton_Ride.gameObject:SetActive(not close)
    end
    local PrologueManager = require"prologue.prologuemanager"
    if PrologueManager.IsInPrologue() then
        fields.UIButton_Ride.gameObject:SetActive(false)
    end
end

local function refreshTime(time)
    if time >300 then
        time = 300
    end
    if time < 100 then
		    fields.UILabel_DelayTime.text = string.format(LocalString.GameNetDelay,time)
	  elseif time < 500 then
		    fields.UILabel_DelayTime.text = string.format(LocalString.GameNetDelay,time)
	  else
		    fields.UILabel_DelayTime.text = string.format(LocalString.GameNetDelay,time)
	  end
end



local function RefreshNewSystemTip()
    local nextfunctiontips = ConfigManager.getConfig("nextfunctiontips")
    local moduleunlockcond = ConfigManager.getConfig("moduleunlockcond")
    local TaskManager=require"taskmanager"
    local valid = false
    for index, newFunctionData in ipairs(nextfunctiontips) do
        local con = moduleunlockcond[newFunctionData.conid]
        if con then
            if con.openlevel ~= 0 then
                if PlayerRole:Instance().m_Level < con.openlevel then
                    newSystemInfo = newFunctionData
                    valid = true
                    fields.UILabel_NewSystem.text = newFunctionData.name
                    break
                end
            elseif con.opentaskid ~= 0 then
                if  TaskManager.GetTaskStatus(con.opentaskid)~=defineenum.TaskStatusType.Completed then
                    newSystemInfo = newFunctionData
                    valid = true
                    fields.UILabel_NewSystem.text =newFunctionData.name
                    break
                end
            end

        end
    end
    if valid == false then
        newSystemInfo = nil
        fields.UIGroup_NewSystemTip.gameObject:SetActive(false)
    else
        fields.UIGroup_NewSystemTip.gameObject:SetActive(true)
    end
end

local function pairsByTimeType(list)
    local key = { }
    local map = { }

    for timeType, bonusData in pairs(list) do
        key[#key + 1] = timeType
        map[timeType] = BonusManager.GetItemsOfSingleBonus(bonusData.bonuslist)
    end
    -- 默认升序
    table.sort(key)
    local i = 0
    return function()
        i = i + 1
        return key[i], map[key[i]]
    end
end

--在线奖励
local function refreshOnline()
    local dailyOnlineData = WelfareManager.GetDailyOnlineData()
    local onlineBonus = ConfigManager.getConfig("onlinetimebonus")
    local isAllGet = true
    for timeType, bonusItemList in pairsByTimeType(onlineBonus) do
        if not dailyOnlineData.bReceivedGift[timeType] then
            isAllGet = false
            --未领取
            if dailyOnlineData.DailyOnlineSeconds >= timeType then
                --未领取，时间到，已经可以领取
                fields.UILabel_OnlineTime.text = LocalString.Welfare_Online_CanReceived
                 local redDotSprite= fields.UIButton_DailyOnline.gameObject.transform:Find("UISprite_Warning")
                 if redDotSprite then
                     redDotSprite.gameObject:SetActive(true)
                 end
                break
            else
                --未领取，时间不够，还不能领取
                local dateTime = timeutils.getDateTime(timeType - dailyOnlineData.DailyOnlineSeconds)
                fields.UILabel_OnlineTime.text = string.format(LocalString.Welfare_OnlineTimeMS, dateTime.minutes, dateTime.seconds)
                break
            end
        end
    end
    if isAllGet == true then
        fields.UILabel_OnlineTime.text = LocalString.Welfare_Online_HasReceived
    end
end

local function refresh(params)
    RefreshChargeIcon()
    RefreshMainScreenMessage()
    RefreshMapName()
    RefreshMiniMap()
    RefreshAllModules()
    RefreshNewSystemTip()

	for _,d in pairs(subFunctions) do
        d.refresh(params)
    end
	
	DlgUIMain_RoleInfo.refresh(params)
	DlgUIMain_Combat.refresh(params)
	DlgUIMain_HPTip.refresh()
    DlgUIMain_Task.refresh()
    DlgUIMain_Novice.refresh()
	RefreshBatteryLevel()
	Game.JoyStickManager.singleton:Reset()

	
end

local function GetCurTaskTabIndex()
    return curTaskTabIndex
end

local function SetCurTaskTabIndex(index)
    curTaskTabIndex = index
end

local function SetTarget(targetId)
    OtherCharacterHead.NeedSetHeadInfoById(targetId)
end


local function SetMatching(params)
    if fields ~= nil then
        fields.UIButton_Matching.gameObject:SetActive(params.matching)
        if params.matchmode == "teamfight" then
            EventHelper.SetClick(fields.UIButton_Matching,function()
                uimanager.showdialog("activity.dlgactivity",{},2)
                if params.callback then
                    params.callback()
                end
            end)
            fields.UISprite_March.spriteName = "Sprite_Gest"
        elseif params.matchmode == "teamspeed" then
            EventHelper.SetClick(fields.UIButton_Matching,function()
                uimanager.showdialog("activity.dlgactivity",{index=2},2)
                if params.callback then
                    params.callback()
                end
            end)
            fields.UISprite_March.spriteName = "Sprite_Grand"
        elseif params.matchmode == "multistory" then
            EventHelper.SetClick(fields.UIButton_Matching,function()
                uimanager.showdialog("ectype.dlgentrance_copy",{matchingbutton = true, index = 3},3)
                local MultiEctypeManager = require("ui.ectype.multiectype.multiectypemanager")
                uimanager.show("ectype.multiectype.dlgmultiectypematching",{lefttime = MultiEctypeManager.GetStoryEctypeLeftTime() , roleinfos = MultiEctypeManager.GetRoleInfos() ,title = MultiEctypeManager.GetTitle()})
                if params.callback then
                    params.callback()
                end
            end)
            fields.UISprite_March.spriteName = "Sprite_fight"
        end
    end
end


local function RefreshAbilities()
    --DlgUIMain_Combat.RefreshAbilities()
end

local function destroy()
	for _,d in pairs(subFunctions) do
        d.destroy()
    end
	
    DlgUIMain_Combat.destroy()
    DlgUIMain_RoleInfo.destroy()
	DlgUIMain_Task.destroy()
    DlgUIMain_HPTip.destroy()
    DlgUIMain_Novice.destroy()
end


local function show(params)
	InitBuffs()
	for _,d in pairs(subFunctions) do
        if d.show then
            d.show(params,true)
        end
    end
	
    DlgUIMain_Combat.show(params)
    DlgUIMain_RoleInfo.show(params)
    DlgUIMain_HPTip.show(params)
	DlgUIMain_Task.show(params)
    DlgUIMain_Novice.show(params)
    m_IsSendRedPacketShowed = nil
    m_IsReceiveRedPacketShowed = nil 
end



local function hide()
	for _,d in pairs(subFunctions) do
        if d.hide then
            d.hide()
        end
    end
	
    DlgUIMain_Combat.hide()
    DlgUIMain_RoleInfo.hide()
    DlgUIMain_HPTip.hide()
	RecommendEquipTip.hide()
    DlgUIMain_Task.hide()
    DlgUIMain_Novice.hide()
end

local m_IsSendRedPacketShowed = nil
local function SetSendRedPacketEnabled(value)
    if nil~=value and value~=m_IsSendRedPacketShowed then
        m_IsSendRedPacketShowed = value
        fields.UIButton_Red.gameObject:SetActive(m_IsSendRedPacketShowed)
    end
end

local m_IsReceiveRedPacketShowed = nil
local function SetReceiveRedPacketEnabled(value)
    if nil~=value then
        if true==value then
            fields.UILabel_RedGet.text = redpacketinfo.GetUnfetchedCount()
        end
        if value~=m_IsReceiveRedPacketShowed  then        
            m_IsReceiveRedPacketShowed = value
            fields.UIButton_RedGet.gameObject:SetActive(m_IsReceiveRedPacketShowed)
            -- local redDotSprite= fields.UIButton_RedGet.gameObject.transform:Find("UISprite_Warning")
            -- if redDotSprite then
            --     redDotSprite.gameObject:SetActive(false)
            -- end
        end
    end
end

local function update()
	
	for _, d in pairs(subFunctions) do
        if d.update then
            d.update()
        end
    end
	
	UpdateMiniMapInfo()

	if UICamera.isOverUI  == false then
		DetectCharacterClick()
	end
    DlgUIMain_Combat.update()
    DlgUIMain_HPTip.update()
    DlgUIMain_RoleInfo.update()
    DlgUIMain_Task.update()
	--DlgUIMain_OfflineExp.update()
    updatePlayerRolesEffect()
    UpdateTime()

end


local function second_update(now)
    for _,d in pairs(subFunctions) do
        if d.second_update then
            d.second_update()
        end
    end
    if m_IsShowMarriageBroadcast then
        m_MarriageBroadcastSecond = m_MarriageBroadcastSecond + 1
        if m_MarriageBroadcastSecond == 5 then
            fields.UIGroup_MarriageBrpadcast.gameObject:SetActive(false)
        elseif m_MarriageBroadcastSecond == 6 then
            m_IsShowMarriageBroadcast = false
        end
    end
    if m_MarriageBroadcastQueue.count > 0 and not m_IsShowMarriageBroadcast then
        local info = m_MarriageBroadcastQueue:Pop()
        fields.UILabel_Marriage.text = info
        fields.UIGroup_MarriageBrpadcast.gameObject:SetActive(true)
        m_MarriageBroadcastSecond = 0
        m_IsShowMarriageBroadcast = true
    end

    -- local totalExtraExpLimit = 0
    -- local expdata = ConfigManager.getConfigData("exptable", PlayerRole:Instance().m_Level)
    -- if expdata ~= nil and expdata.bonusexp > 0 then
    --     local totalExtraExpLimit = expdata.bonusexp
    --     if PlayerRole:Instance().m_worldlevelrate > 0 then
    --         totalExtraExpLimit = math.floor(totalExtraExpLimit * PlayerRole:Instance().m_worldlevelrate)
    --     end
    --     local curKillMonsterExp = math.floor(100*PlayerRole:Instance().m_TodayKillMonsterExtraExp / totalExtraExpLimit)
    --     if curKillMonsterExp ~= historyKillMonsterExp then
    --         historyKillMonsterExp = curKillMonsterExp
    --         local remainExp = totalExtraExpLimit - PlayerRole:Instance().m_TodayKillMonsterExtraExp + monsterData.MonsterExpStatus * monsterData.remainexp
    --         if remainExp < 0 then
    --             remainExp = 0
    --         end
    --         fields.UISlider_KillEXP.value =  remainExp / totalExtraExpLimit
    --         RefreshRedDotType(cfg.ui.FunctionList.DAILYEXTRAEXP)
    --     end
    -- end


    local totalExtraExpLimit = 0
    local expdata = ConfigManager.getConfigData("exptable", PlayerRole:Instance().m_Level)
    if expdata ~= nil and  expdata.bonusexp > 0 then
        totalExtraExpLimit = expdata.bonusexp
        if PlayerRole:Instance().m_worldlevelrate > 0 then
            totalExtraExpLimit = math.floor(totalExtraExpLimit * PlayerRole:Instance().m_worldlevelrate)
        end
    end
    local springfestivalmanager = require"ui.activity.springfestival.springfestivalmanager"
    local monsterData = springfestivalmanager.getMonsterData()

    local remainExp = totalExtraExpLimit - PlayerRole:Instance().m_TodayKillMonsterExtraExp + monsterData.MonsterExpStatus * monsterData.remainexp
    if remainExp < 0 then
        remainExp = 0
    end
    fields.UISlider_KillEXP.value =  remainExp / totalExtraExpLimit

    SetReceiveRedPacketEnabled(redpacketinfo.GetUnfetchedCount()>0 and redpacketinfo.GetReceiveCount()<redpacketinfo.GetReceiveLimit())

    --在线奖励
    refreshOnline()
end



local function late_update()
    for _,d in pairs(subFunctions) do
        if d.late_update then
           d.late_update()
        end
    end
end

local function ClearData()
	
    fields.UIButton_Matching.gameObject:SetActive(false)
    LuaHelper.CameraGrayEffect(false)
    fields.UIButton_RedGet.gameObject:SetActive(false)
end

local function init(params)
	
	gameObject,name,fields = unpack(params)

    DlgUIMain_Novice.init(name,gameObject,fields)
	
	fields.UIGroup_CharacterHead.gameObject:SetActive(true)
    fields.UIGroup_CharacterHead.gameObject.transform.localScale = Vector3.zero
	fields.UIGroup_SystemMessage.gameObject:SetActive(false)
    table.insert(subFunctions,dlguimain_partner)    
	for _,d in pairs(subFunctions) do
        d.init(name,gameObject,fields,params)
    end
    PlayerRole = require "character.playerrole"
   
    m_MarriageBroadcastQueue = Queue:new()

	RegisterAllModules()
	
	table.insert(subFunctions,OtherCharacterHead)
    table.insert(subFunctions,PlayerStateTip)

	table.insert(subFunctions,DlgUIMain_Team)

    table.insert(subFunctions,dlguimain_hide)

		
    for _,d in pairs(subFunctions) do
        d.init(name,gameObject,fields,params)
    end
	
    DlgUIMain_Combat.init(name, gameObject, fields, params)
    DlgUIMain_HPTip.init(name,gameObject,fields,params)
	RecommendEquipTip.init(name,gameObject,fields)
	DlgUIMain_Task.init(name,gameObject,fields,params)
	
	fields.UIGroup_ItemTeam.gameObject:SetActive(false)
    fields.UIGroup_ItemTask.gameObject:SetActive(true)
    fields.UIButton_TaskClose.gameObject:SetActive(true)
    --初始化充值图标
    local VipChargeManager = require"ui.vipcharge.vipchargemanager"
    if shouldHideVip()  then
        fields.UISprite_FirstOfCharge.gameObject:SetActive(false)
        fields.UISprite_Recharge.gameObject:SetActive(false)
    end

    EventHelper.SetClick(fields.UIButton_TaskClose, function()
        if fields.UISprite_TaskSwitch_Open.gameObject.activeSelf == true then
            fields.UISprite_TaskSwitch_Open.gameObject:SetActive(false)
            fields.UISprite_TaskSwitch_Close.gameObject:SetActive(true)
        else
            fields.UISprite_TaskSwitch_Open.gameObject:SetActive(true)
            fields.UISprite_TaskSwitch_Close.gameObject:SetActive(false)
        end


    end )


    --???С???????????
    EventHelper.SetClick(fields.UISprite_MapBG, function()
		
		uimanager.showdialog("map.dlgmap",{},2)

    end )   
	
	EventHelper.SetClick(fields.UISprite_HeroHeadAll,function()
        if EctypeManager.IsInEctype() then
            return
        end
		uimanager.showdialog("dlgmain_open")
	end)
	
	EventHelper.SetClick(fields.UIWidget_EnterChat, function()
		
        uimanager.showdialog("chat.dlgchat01")
    end)
	EventHelper.SetClick(fields.UIButton_Ride, function()
        DlgUIMain_Combat.OnButton_Ride()
	end)

    EventHelper.SetClick(fields.UIGroup_Vip, OnUIGroup_Vip)
	
    EventHelper.SetClick(fields.UIButton_Vip, OnUIGroup_Vip)
	
    EventHelper.SetClick(fields.UIButton_Jump, function()
        PlayerRole:Instance():Jump()
    end )
    EventHelper.SetPress(fields.UIButton_Jump, function(go, bPress)
        if PlayerRole:Instance().m_Mount and PlayerRole:Instance().m_Mount:IsAttach() then
            local MountType = defineenum.MountType
            if PlayerRole:Instance().m_Mount.m_MountState ~= MountType.Ride then
                PlayerRole:Instance().m_Mount:movedown(bPress)
            end
        end
    end )


    EventHelper.SetClick(fields.UIButton_PartnerTab, function()
        local moduleData=GetModule(cfg.ui.FunctionList.PARTNER)
        if moduleData then
            local status=ModuleLockManager.GetModuleStatusByType(cfg.ui.FunctionList.PARTNER)
            if status==defineenum.ModuleStatus.LOCKED then
                local configData = ConfigManager.getConfigData("uimainreddot",cfg.ui.FunctionList.PARTNER)
                local conditionData=ConfigManager.getConfigData("moduleunlockcond",configData.conid)
                if conditionData then
                    local text=""
                    if conditionData.openlevel~=0 then
                        text=(conditionData.openlevel)..(LocalString.WorldMap_OpenLevel)
                    elseif conditionData.opentaskid~=0 then
                        local taskData=ConfigManager.getConfigData("task",conditionData.opentaskid)
                        if taskData then
                            text=string.format(LocalString.CompleteTaskOpen,taskData.basic.name)
                        end
                    end
                    uimanager.ShowSystemFlyText(text)
                end
                return
            end
        end
        if fields.UIGroup_ItemPartner.gameObject.activeSelf then
            if not EctypeManager.IsInEctype() then
                uimanager.showdialog("partner.dlgpartner_list")
            end
        else
            fields.UIGroup_ItemTeam.gameObject:SetActive(false)
            fields.UIGroup_ItemTask.gameObject:SetActive(false)
            fields.UIGroup_HeroChallenge.gameObject:SetActive(false)
            fields.UIGroup_ItemPartner.gameObject:SetActive(true)
            if EctypeManager.IsInEctype() then
                EctypeManager.ShowTasks(false)
            else
                curTaskTabIndex = 1
                dlguimain_partner.UpdateFieldPets()
            end
        end
    end )

	--EventHelper.SetClick(fields.UIButton_Partner,function()
	--
    --
	-- uimanager.showdialog("partner.dlgpartner_list")
	--
	--end)

	
	
    EventHelper.SetClick(fields.UIButton_TeamTab, function()
        fields.UIGroup_ItemTeam.gameObject:SetActive(true)
        fields.UIGroup_ItemTask.gameObject:SetActive(false)
        fields.UIGroup_ItemPartner.gameObject:SetActive(false)
        fields.UIGroup_HeroChallenge.gameObject:SetActive(false)
        if EctypeManager.IsInEctype() then
            EctypeManager.ShowTasks(false)
        else
            if curTaskTabIndex == 2 then
                if not EctypeManager.IsInEctype() then
                    uimanager.showdialog("team.dlgteam")
                end
            else
                curTaskTabIndex = 2
                DlgUIMain_Team.RefreshTeamInfo()
            end
        end
    end )
		
	
	DlgUIMain_RoleInfo.init(name,gameObject,fields,params)

 	EventHelper.SetClick(fields.UIButton_TaskTab, function()
        fields.UIGroup_ItemTeam.gameObject:SetActive(false)
        fields.UIGroup_ItemPartner.gameObject:SetActive(false)
        fields.UIGroup_HeroChallenge.gameObject:SetActive(false)
        if EctypeManager.IsInEctype() then
            fields.UIGroup_ItemTask.gameObject:SetActive(false)
            EctypeManager.ShowTasks(true)
            curTaskTabIndex = 0
        else
            if curTaskTabIndex == 0 then
                uimanager.showdialog("dlgtask")
            else
                fields.UIGroup_ItemTask.gameObject:SetActive(true)
                curTaskTabIndex = 0
            end
        end
    end )
	DlgUIMain_RoleInfo.init(name,gameObject,fields,params)

    fields.UISprite_Close.gameObject:SetActive(true)
    fields.UISprite_Open.gameObject:SetActive(false)
    EventHelper.SetClick(fields.UIButton_Stretch, function()
        if fields.UISprite_Close.gameObject.activeSelf then
            fields.UISprite_Close.gameObject:SetActive(false)
            fields.UISprite_Open.gameObject:SetActive(true)
            fields.UISprite_Warning.gameObject:SetActive(false)
        else
            fields.UISprite_Close.gameObject:SetActive(true)
            fields.UISprite_Open.gameObject:SetActive(false)
        end
    end )
	--EventHelper.SetClick
	local textListTransform = fields.UISprite_ChatBackground.gameObject
	textList = textListTransform:GetComponent("UITextList")

	 EventHelper.SetListClick(fields.UIList_Buff,function(item)
		
        local effect = playerRole.m_Effect:GetEffectByIndex(item.m_nIndex + 1)
        if effect then
			isUIlistBuffActive = not isUIlistBuffActive
            fields.UISprite_BuffDiscription.gameObject:SetActive( isUIlistBuffActive)
            TimerBuffDescription = 0
            showingEffectId = effect.id
            showingEffectIdx = item.m_nIndex + 1
            fields.UILabel_BuffDiscription.text = effect.description
        end
    end)
	    gameevent.evt_system_message:add("logout",ClearData)

    EventHelper.SetClick(fields.UISprite_NewSystem, function()
        uimanager.show("common.DlgDialogBox_NewSystem",newSystemInfo)
    end)
	
	--设置血条血量颜色变化
	EventHelper.SetProgressBarValueChange(fields.UIProgressBar_RoleHP,function()
        if fields.UIProgressBar_RoleHP.value < 0.25 then
			fields.UISprite_Foreground.color = colorutil.RoleHpColor[cfg.item.EItemColor.RED]
		elseif  fields.UIProgressBar_RoleHP.value < 0.5 then
            fields.UISprite_Foreground.color = colorutil.RoleHpColor[cfg.item.EItemColor.ORANGE]
		elseif fields.UIProgressBar_RoleHP.value < 0.75 then
            fields.UISprite_Foreground.color = colorutil.RoleHpColor[cfg.item.EItemColor.PURPLE]

        else
            fields.UISprite_Foreground.color = colorutil.RoleHpColor[cfg.item.EItemColor.GREEN]
	    end
    end)

    -- uimanager.showorrefresh("common.dlgdialogbox_disconnetion")
    fields.UILabel_DelayTime.text = string.format(LocalString.GameNetDelay,0)
end

local function UpdateAttributes()
    DlgUIMain_RoleInfo.UpdateAttributes()
end

local function OnGuideShowTask()
    local pos = fields.UIGroup_Task.transform.localPosition
    if pos.x<-500 then
        fields.UISprite_TaskSwitch_Open.gameObject:SetActive(true)
        fields.UISprite_TaskSwitch_Close.gameObject:SetActive(false)
        fields.UIButton_TaskClose.gameObject:GetComponent("UIPlayTween"):Play(true)
    end

end


local function SetWeightsEnabled(weights, value)
    if weights and weights.Length>0 then
        for i = 1, weights.Length do
            weights[i].isEnabled = value
        end
    end
end

local function OnEnterLeavePrologue(isenter)
    local weights
    --?????????????
    weights = fields.UIGroup_ChatArea.gameObject:GetComponentsInChildren(UIButton, true)
    SetWeightsEnabled(weights, not isenter)
    --????????????
    weights = fields.UIGroup_HeroHead.gameObject:GetComponentsInChildren(UIButton, true)
    SetWeightsEnabled(weights, not isenter)
end

local function AddMarriageBroadcast(params)
    m_MarriageBroadcastQueue:Push(params)
end




local function EnterEctype()
    DlgUIMain_Combat.EnterEctype()
    fields.UIButton_TaskClose.gameObject:SetActive(false)
    fields.UIGroup_FunctionsArea.gameObject:SetActive(false)
    fields.UIGroup_ItemTeam.gameObject:SetActive(false)
    fields.UIGroup_ItemTask.gameObject:SetActive(false)
    fields.UIGroup_ItemPartner.gameObject:SetActive(false)
    fields.UIGroup_HeroChallenge.gameObject:SetActive(false)
    fields.UIButton_TaskTab.transform.parent.gameObject:SetActive(false)

    --新增进入副本后隐藏的主界面UI
    fields.UIGroup_ChargeGroup.gameObject:SetActive(false)
    fields.UIButton_Friend.gameObject:SetActive(false)
    fields.UISprite_KillEXP.gameObject:SetActive(false)
    fields.UIButton_DailyOnline.gameObject:SetActive(false)
    fields.UIGroup_Vip.gameObject:SetActive(false)

    curTaskTabIndex = 0
    dlguimain_partner.UpdateFieldPets()
    DlgUIMain_Combat.EnterEctype()
    if EctypeManager.IsBattleEctype() then
        local CharacterManager = require"character.charactermanager"
        --CharacterManager.ShowAllHpProgress()
    end
	if EctypeManager.IsInEctype() then
        local ectype = EctypeManager.GetEctype()
        local basicInfo = ConfigManager.getConfigData("ectypebasic",ectype.m_ID)
        if basicInfo.enterfight then
            SwitchAutoFight(true)
        end
    end

    local PrologueManager = require"prologue.prologuemanager"
    if PrologueManager.IsInPrologue() then
        --fields.UIButton_FightAuto.gameObject:SetActive(false)
        fields.UIButton_Ride.gameObject:SetActive(false)
        fields.UIButton_Friend.gameObject:SetActive(false)
        fields.UISprite_KillEXP.gameObject:SetActive(false)
        fields.UIButton_Bag.gameObject:SetActive(false)
        fields.UIGroup_Vip.gameObject:SetActive(false)
        fields.UISprite_FirstOfCharge.gameObject:SetActive(false)
        fields.UIButton_DailyOnline.gameObject:SetActive(false)
        fields.UISprite_HeroHeadAll.enabled = false
    end

end

local function LeaveEctype()
    fields.UIButton_TaskClose.gameObject:SetActive(true)
    fields.UIGroup_FunctionsArea.gameObject:SetActive(true)
    fields.UIGroup_ItemTeam.gameObject:SetActive(false)
    fields.UIGroup_ItemTask.gameObject:SetActive(false)
    fields.UIGroup_ItemPartner.gameObject:SetActive(false)
    fields.UIGroup_HeroChallenge.gameObject:SetActive(false)
    fields.UIButton_TaskTab.transform.parent.gameObject:SetActive(true)
    --新增离开副本后隐藏的主界面UI
    fields.UIGroup_ChargeGroup.gameObject:SetActive(true)
    fields.UIButton_Friend.gameObject:SetActive(true)
    fields.UISprite_KillEXP.gameObject:SetActive(true)
    fields.UIButton_DailyOnline.gameObject:SetActive(true)
    fields.UIGroup_Vip.gameObject:SetActive(true)

    
    if curTaskTabIndex == 0 then
        fields.UIGroup_ItemTask.gameObject:SetActive(true)
    elseif curTaskTabIndex == 1 then
        fields.UIGroup_ItemPartner.gameObject:SetActive(true)
    elseif curTaskTabIndex == 2 then
        fields.UIGroup_ItemTeam.gameObject:SetActive(true)
    end


    DlgUIMain_Combat.LeaveEctype()
    OnEnterLeavePrologue(false)

    fields.UIButton_FightAuto.gameObject:SetActive(true)
    fields.UIButton_Ride.gameObject:SetActive(true)
    fields.UIButton_Friend.gameObject:SetActive(true)
    fields.UISprite_KillEXP.gameObject:SetActive(true)
    fields.UIButton_Bag.gameObject:SetActive(true)
    fields.UIGroup_Vip.gameObject:SetActive(true)
    fields.UISprite_FirstOfCharge.gameObject:SetActive(true)
    fields.UIButton_DailyOnline.gameObject:SetActive(true)
    fields.UISprite_HeroHeadAll.enabled = true
end

local function clientCmd_ShowleaveBtn()	
	  return fields
end



return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    late_update = late_update,
    second_update = second_update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    refreshTime = refreshTime,
    EnterEctype = EnterEctype,
    LeaveEctype = LeaveEctype,
    RefreshNewSystemTip = RefreshNewSystemTip,
	
    SetAutoFightSprite = PlayerStateTip.SetAutoFightSprite,
    SetTargetHoming   =   PlayerStateTip.SetTargetHoming,
    CloseTargetHoming = PlayerStateTip.CloseTargetHoming,
    StopSkillsOperations = StopSkillsOperations,
    ResumeSkillsOperations = ResumeSkillsOperations,
    DragSkillGroup = DragSkillGroup,
    RefreshMapName = RefreshMapName,
    SwitchAutoFight = SwitchAutoFight,

    HideRideButton = HideRideButton,
    SetAttackEnable = SetAttackEnable,
    SetSkillsEnable = SetSkillsEnable,
    UpdateAttributes = UpdateAttributes,
    RefreshPKStateIcon = RefreshPKStateIcon,
    SetTarget = SetTarget,
    RefreshTaskList = RefreshTaskList,
    RefreshRoleInfo = RefreshRoleInfo,
    RefreshModuleByType = RefreshModuleByType,
    RefreshAllModules = RefreshAllModules,
	AddMainScreenMessage = AddMainScreenMessage,
	RefreshAbilities     = RefreshAbilities,

    PartnerEquipCD      = PartnerEquipCD,
    RefreshPetAttributes= RefreshPetAttributes,
    RefreshFieldPets    = RefreshFieldPets,
	GetCurTaskTabIndex  = GetCurTaskTabIndex,
	SetCurTaskTabIndex  = SetCurTaskTabIndex,
    ClearChatArea = ClearChatArea,
    AddMarriageBroadcast = AddMarriageBroadcast,
    RefreshRedDotType = RefreshRedDotType,
    DisplayMarriageBroadcast = DisplayMarriageBroadcast,
	SetMatching   = SetMatching,
    OnGuideShowTask = OnGuideShowTask,
	RefreshBatteryLevel = RefreshBatteryLevel,
	clientCmd_ShowleaveBtn = clientCmd_ShowleaveBtn,
    refreshOnline = refreshOnline,

}
