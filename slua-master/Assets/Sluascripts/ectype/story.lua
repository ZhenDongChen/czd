local SceneManager = require "scenemanager"
local CameraManager = require "cameramanager"
local ConfigManager = require "cfg.configmanager"
local AudioManager = require"audiomanager"
local uimanager = require "uimanager"
local PlayerRole
local Layout = require "ectype.layout"
local network = require "network"
local tools = require "ectype.ectypetools"
local EctypeOthersManager =  require("ectype.ectypeothersmanager")
local StoryEctype = Class:new()

StoryEctype.EctypeLoadState = enum
{
    "BeforeLoading=0",
    "Loading=1",
    "LoadingFinished=2",
    "BeforeStart=3",
    "Done=4",
}

function StoryEctype:__new(entryInfo,ectypetype)
    PlayerRole              = require"character.playerrole"
    self.m_bReady           = false
    self.m_ectypetype = ectypetype
	self.m_EctypeInfo       = ConfigManager.getConfigData("storylayout",entryInfo.ectypeid)
    self.m_BasicEctypeInfo  = ConfigManager.getConfigData("ectypebasic",entryInfo.ectypeid)
	self.m_EntryInfo        = entryInfo
    self.m_EctypeType       = self.m_BasicEctypeInfo.type
	self.m_EctypeInfo.endofftime = self.m_BasicEctypeInfo.endofftime
	self.m_PlayerRole       = PlayerRole:Instance()
	self.m_RemainTime       = entryInfo.remaintime/1000
	self.m_OpeningLayouts   = entryInfo.openlayouts
	self.m_Enviroments      = entryInfo.enviroments
    self.m_ExitSceneID      = self.m_EctypeInfo.storyexitscene
	
	self.m_ExitArrow        = nil
    self.m_MonsterArrow     = nil
	self.m_ArrowTarget      = nil
	self.m_BVRTarget        = nil
	self.m_HasRequestedMonsterPosition = false
	self.m_ShowArrowNextFrame = false
	
	self.m_State            = StoryEctype.EctypeLoadState.BeforeLoading
	self.m_EnterSceneName   = nil
	self.m_CurrentLayout    = nil
    self.m_CurrentLayoutIndex   = -1
    self.m_NextLayout       = nil
    self.m_EctypeType       = self.m_BasicEctypeInfo.type
    self.m_EctypeID         = entryInfo.id
    self.m_Name             = self.m_BasicEctypeInfo.ectypename
    self.m_ID               = entryInfo.ectypeid
    self.m_ReviveTimes      = entryInfo.remainrevivecount --复活次数保存在服务端
	self.m_RemainReviveTimes= self.m_ReviveTimes
	self.m_MapId            = self.m_BasicEctypeInfo.scenename
	self.m_UseTime          = 0
	self.m_ActionsReady     = false
	self.m_LayoutGroupID    = self.m_BasicEctypeInfo.regionsetid
	self.m_IsPrologue       = self.m_EctypeType == cfg.ectype.EctypeType.PROLOGUE
	self.m_InitActions      = entryInfo.activeactions
	local actionsmanager = require"ectype.ectypeactionsmanager"
	self.m_ActionsManager   = actionsmanager:new(self.m_EctypeInfo,PlayerRole:Instance(),self)
	
	 local CfgStoryEctype = ConfigManager.getConfigData("storyectype",entryInfo.ectypeid)
    if CfgStoryEctype then
    	self.m_ShowAccount = CfgStoryEctype.ifend
   	else
		self.m_ShowAccount = true
	end
	
	EctypeOthersManager.ShowUI()
	
end


function StoryEctype:Init(mapname)
end

function StoryEctype:ReviveMsg()
    return {self.m_RemainReviveTimes,self.m_BasicEctypeInfo.reviveinfo.maxcount}
end

function StoryEctype:CanRevive()
    return self.m_RemainReviveTimes>0
end

function StoryEctype:Revive()
    self.m_RemainReviveTimes = self.m_RemainReviveTimes - 1
    if self.m_RemainReviveTimes>=0 then
        return true
    else
        return false
    end
end

function StoryEctype:SendRevive()
    network.send(map.msg.CRevive({}))
end


function StoryEctype:Release()
	 if self.m_ExitArrow then
        GameObject.Destroy(self.m_ExitArrow)
    end
    if self.m_MonsterArrow then
        GameObject.Destroy(self.m_MonsterArrow)
    end
    self.m_CurrentLayout=nil
end


function StoryEctype:IsReady()
    return self.m_bReady
end

function StoryEctype:TimeUpdate()
    if self.m_RemainTime>0 then
        self.m_RemainTime = self.m_RemainTime-Time.deltaTime
        self.m_UseTime = self.m_UseTime + Time.deltaTime
        if self.m_RemainTime>=0 then
            local h,m,s = tools.GetFixedTime(self.m_RemainTime)
            local dlgectype = require"ui.ectype.dlguiectype"
            if uimanager.isshow("ectype.dlguiectype") then
                dlgectype.UpdateRemainTime(h,m,s)
            end
        end
    end
end

function StoryEctype:AddAction(actionid)
    self.m_ActionsManager:AddAction(actionid)
end

function StoryEctype:RemoveAction(actionid)
    local ret = self.m_ActionsManager:RemoveAction(actionid)
end


function StoryEctype:DeadCount()

end

function StoryEctype:Update()
    if self.m_State==StoryEctype.EctypeLoadState.BeforeLoading then
        self:OnUpdateBeforeLoading()
    elseif self.m_State==StoryEctype.EctypeLoadState.Loading then
        self:OnUpdateLoading()
    elseif self.m_State==StoryEctype.EctypeLoadState.LoadingFinished then
        self:OnUpdateLoadingFinished()
    elseif self.m_State== StoryEctype.EctypeLoadState.BeforeStart then
        self:OnUpdateBeforeStart()
    else
        if self.m_ActionsReady then
            self.m_ActionsManager:Update()
            if not self.m_ActionsManager:IsPlayingCG() and not self.m_ActionsManager.m_EctypePause then
                self:TimeUpdate()
                if self.m_NextLayout then
                    self.m_NextLayout:UpdateEnterLayout()
                    self.m_CurrentLayout:Update()
                elseif self.m_CurrentLayout then
                    if self.m_CurrentLayout:GetFinished() then
                        self.m_CurrentLayout:UpdateCompletedLayout()
                    else
                        self.m_CurrentLayout:Update()
                    end
                end
            end
        else
            if uimanager.isshow("ectype.dlguiectype") and uimanager.isshow("dlguimain") then
                for _,action in ipairs(self.m_InitActions) do
                    self:AddAction(action)
                end
                self.m_ActionsReady = true
            end
        end
    end
end


function StoryEctype:RoleEnterEctype()

end


function StoryEctype:ExitArrowDirectTo(pos)
	
	local NewPos = Vector3(self.m_PlayerRole:GetRefPos().x * SCALE_XY_FRACTION, self.m_PlayerRole:GetRefPos().y * SCALE_XY_FRACTION, 0);
    if mathutils.DistanceOfXoY(NewPos,pos)> 3 then
		local angle = mathutils.PosGetAngle(pos,NewPos)
		
		self.m_ExitArrow.transform.localRotation  = Quaternion.Euler(0,180, angle)
        self.m_ExitArrow:SetActive(true)
    else
        self.m_ArrowTarget = nil
        self.m_BVRTarget = nil
        self.m_ExitArrow:SetActive(false)
    end
end


function StoryEctype:CheckUI()
    for i,v in pairs(Local.EctypeDlgList) do
        if not uimanager.isshow(v) then return false end
    end
    return uimanager.isshow("dlguimain")
end


function StoryEctype:GetLayout(info)


	printyellow("GetLayout______________________________________________________________________")
    local layout = Layout:new(info,self.m_EctypeInfo,self.m_LayoutGroupID,self.m_IsPrologue)


	local CurLayerId = info.id;
	if self.m_CurrentLayout ~= nil then
		CurLayerId = self.m_CurrentLayout.m_LayoutID;
	end
    local layout = Layout:new(info,self.m_EctypeInfo,self.m_LayoutGroupID, CurLayerId, self.m_IsPrologue)



    for _,exitid in pairs(info.openexitids) do
        layout:ChangeExit(exitid,true)
    end
    for _,entryid in pairs(info.openentryids) do
        layout:ChangeEntry(entryid,true)
    end
    layout.m_Completed = info.completed
    return layout
end


function StoryEctype:RefreshLayouts()
    if #self.m_OpeningLayouts==1 then
        self.m_CurrentLayout = self:GetLayout(self.m_OpeningLayouts[1])
        self.m_ActionsManager.m_ShowGlobalTips = self.m_OpeningLayouts[1].showglobaltips>0
    end
    if #self.m_OpeningLayouts==2 then
        if self.m_OpeningLayouts[1].m_Completed then
            self.m_CurrentLayout = self:GetLayout(self.m_OpeningLayouts[1])
            self.m_NextLayout = self:GetLayout(self.m_OpeningLayouts[2])
            self.m_ActionsManager.m_ShowGlobalTips = self.m_OpeningLayouts[2].showglobaltips>0
        else
            self.m_CurrentLayout = self:GetLayout(self.m_OpeningLayouts[2])
            self.m_NextLayout = self:GetLayout(self.m_OpeningLayouts[1])
            self.m_ActionsManager.m_ShowGlobalTips = self.m_OpeningLayouts[1].showglobaltips>0
        end
    end
end


function StoryEctype:CheckPosition(position)
    return true
end


function StoryEctype:OnMsgSReady(msg)
    self.m_bIsReady = true
    if uimanager.isshow("ectype.dlguiectype") then
        uimanager.call("ectype.dlguiectype","EctypeReady")
    end
end


function StoryEctype:OpenLayout(msg)
    if not self.m_NextLayout then
        self.m_ActionsManager:RefreshShowGlobalTips()
        self.m_NextLayout = Layout:new(msg.layout,self.m_EctypeInfo,self.m_LayoutGroupID,self.m_CurrentLayout.m_LayoutID,self.m_IsPrologue)
    end
end

function StoryEctype:CloseLayout(msg)
	print("CloseLayout")
    if msg.layoutid == self.m_CurrentLayout.m_LayoutID and self.m_NextLayout then
        self.m_CurrentLayout:Release()
        self.m_CurrentLayout = self.m_NextLayout
        self.m_NextLayout = nil
    end
end


function StoryEctype:ChangeEntry(msg)
    if msg.layoutid == self.m_CurrentLayout.m_LayoutID then
        self.m_CurrentLayout:ChangeEntry(msg.entryid,msg.open==1)
    end
end
function StoryEctype:ChangeExit(msg)
    if msg.layoutid == self.m_CurrentLayout.m_LayoutID then
        self.m_CurrentLayout:ChangeExit(msg.exitid,msg.open==1)
    end
end


function StoryEctype:OnUpdateBeforeLoading()
    if self.m_PlayerRole and self.m_PlayerRole.m_Object then
        self.m_EnterSceneName = SceneManager.GetMapName()
        if self.m_EnterSceneName ~= self.m_MapId then
			printyellow("OnUpdateBeforeLoading")
            SceneManager.load(Local.EctypeDlgList,self.m_MapId,nil)
            SceneManager.AlterLoadedEctypeMap(true)
        else
            for i,v in pairs(Local.EctypeDlgList) do
                uimanager.show(v)
            end
            SceneManager.AlterLoadedEctypeMap(false)
            uimanager.hide("dlgloading")
        end
        self.m_State = StoryEctype.EctypeLoadState.Loading
    end
end


function StoryEctype:OnUpdateLoading()

    if self.m_EnterSceneName ~= self.m_MapId then
        if not SceneManager.IsLoadingScene() and self:CheckUI() then
            self.m_State = StoryEctype.EctypeLoadState.LoadingFinished
        end
    else
        if self:CheckUI() then
            self.m_State = StoryEctype.EctypeLoadState.LoadingFinished
        end
    end
end

function StoryEctype:CompleteLayout(msg)
	printyellow("CompleteLayout___________________________________________________________________________________")
    if msg.layoutid == self.m_CurrentLayout.m_LayoutID and not self.m_CurrentLayout:GetFinished() then
        self.m_CurrentLayout:Finish()
    end
end

function StoryEctype:OnUpdateLoadingFinished()
	Util.Load("sfx/s_fx_direction_grn.bundle",define.ResourceLoadType.LoadBundleFromFile,function(obj)
        if IsNull(obj) then
            return
        end
        self.m_ExitArrow = GameObject.Instantiate(obj)
		local managerObject = CharacterManager.GetCharacterManagerObject()
        self.m_ExitArrow.transform:SetParent(managerObject.transform)
        self.m_ExitArrow:SetActive(false)
        self.m_ExitArrow.transform.localScale = Vector3.one
        self.m_ExitArrow.transform.localPosition = Vector3.zero
        self.m_ExitArrow.transform.localRotation = Quaternion.identity
    end)
    Util.Load("sfx/s_fx_direction_red.bundle",define.ResourceLoadType.LoadBundleFromFile,function(obj)
        if IsNull(obj) then
            return
        end
        self.m_MonsterArrow = GameObject.Instantiate(obj)
		local managerObject = CharacterManager.GetCharacterManagerObject()
        self.m_MonsterArrow.transform:SetParent(managerObject.transform)
        self.m_MonsterArrow:SetActive(false)
        self.m_MonsterArrow.transform.localScale = Vector3.one
        self.m_MonsterArrow.transform.localPosition = Vector3.zero
        self.m_MonsterArrow.transform.localRotation = Quaternion.identity
    end)
	
    local uimain = require"ui.dlguimain"
    uimain.EnterEctype()

    if not uimanager.isshow("ectype.dlguiectype") then
        uimanager.show("ectype.dlguiectype")
    end

    local dlgectype = require"ui.ectype.dlguiectype"
    dlgectype.EnterEctype(self.m_Name,self.m_ectypetype,self.m_IsPrologue)
    if not self.m_LoadedMap then
        uimanager.show("ectype.dlguiectypeeffects",{isEnter = true})
    end
    AudioManager.PlayBackgroundMusic(self.m_BackgroundAudio)
    self.m_State = StoryEctype.EctypeLoadState.BeforeStart
end


function StoryEctype:OnUpdateBeforeStart()
	printyellow("OnUpdateBeforeStart")
    self.m_State = StoryEctype.EctypeLoadState.Done
    if #self.m_OpeningLayouts~=0 then
        self:RefreshLayouts()
    end
   -- if self.m_EctypeType == cfg.ectype.EctypeType.MULTI_STORY then
   --     local MultiEtypeManager = require"ui.ectype.multiectype.multiectypemanager"
    --    if not MultiEtypeManager.GetCanReceiveReward() then
   --         uimanager.call("dlgflytext","AddSystemInfo",LocalString.EctypeText.CantReceiveRewards)
   --     end
   -- end
    self.m_bReady = true
    network.send(map.msg.CReady({}))
end


function StoryEctype:LeaveEctype(msg)
	printyellow("LeaveEctype_______________________________________________________________________")
    if not self.m_LoadedMap then
        uimanager.show("ectype.dlguiectypeeffects")
    end
    uimanager.destroy("ectype.dlguiectype")
    uimanager.call("dlguimain","LeaveEctype")
    uimanager.call("dlguimain","SwitchAutoFight",false)
    self.m_ActionsManager:LeaveEctype()
    local mapinfo = ConfigManager.getConfigData("worldmap",self.m_ExitSceneID)
    local EctypeManager = require"ectype.ectypemanager"
    if self.m_ErrorCode == 0 then
        if SceneManager.GetMapName() == mapinfo.scenename and
            SceneManager.GetMapName() == self.m_EnterSceneName then
            uimanager.RegistCallBack_DestroyAllDlgs(function()
                for i,v in pairs(Local.MaincityDlgList) do
                    uimanager.show(v)
                end
            end)
            SceneManager.AlterLoadedEctypeMap(false)
			--TODO ��ʱ�رձ�������
            SceneManager.PlayBackgroundMusic(nil,true)
        else
            SceneManager.AlterLoadedEctypeMap(true)
        end
    end
end
function StoryEctype:GetReviveFunction()
    return 0
end

function StoryEctype:OnEnd(msg)
    EctypeOthersManager.HideUI()
    self.m_ErrorCode = msg.errcode
    if self.m_EctypeType == cfg.ectype.EctypeType.PROLOGUE and msg.errcode ~= 0 then
        return
    end
    if self.m_EctypeType == cfg.ectype.EctypeType.PLAIN_STORY then
        local re = lx.gs.map.msg.CLeaveMap({})
        network.send(re)
        return
    end
    if self.m_EctypeType == cfg.ectype.EctypeType.PROLOGUE and msg.errcode == 0 then
        local PrologueManager = require"prologue.prologuemanager"
        PrologueManager.PlaySurfixVideo(
            function()
                network.send(lx.gs.map.msg.CLeaveMap({}))
            end
        )
    elseif self.m_ShowAccount then
        msg.finishTime = self.m_UseTime
        uimanager.hide("ectype.dlguiectype")
        uimanager.showdialog("ectype.dlggrade",
                    {   result      = (((msg.errcode == 0) and true) or false),
                        bonus       = msg.bonus,
						star        = msg.star,
                        callback    = function()
                            uimanager.hidedialog("ectype.dlggrade")
                            uimanager.show("ectype.dlguiectype")
                            network.send(lx.gs.map.msg.CLeaveMap({}))
                        end,})
    else
        network.send(lx.gs.map.msg.CLeaveMap({}))
    end


end


function StoryEctype:MonsterArrowDirectTo(pos)
	local NewPos = Vector3(self.m_PlayerRole:GetRefPos().x * SCALE_XY_FRACTION, self.m_PlayerRole:GetRefPos().y * SCALE_XY_FRACTION, 0);
    if mathutils.DistanceOfXoY(NewPos,pos)> 3 then
		local angle = mathutils.PosGetAngle(pos, NewPos)
		self.m_MonsterArrow.transform.localRotation  = Quaternion.Euler(0,180, angle)
        self.m_ShowArrowNextFrame = true
    else
        self.m_MonsterArrow:SetActive(false)
    end
end

function StoryEctype:ArrowsUpdate()
    if not self.m_MonsterArrow or not self.m_ExitArrow or
    not self.m_PlayerRole.m_Object or not self.m_PlayerRole.m_ShadowObject then return end
    self.m_MonsterArrow.transform.position = self.m_PlayerRole.m_ShadowObject.transform.position
    self.m_ExitArrow.transform.position = self.m_PlayerRole.m_ShadowObject.transform.position
    self.m_ArrowTarget = nil
    -- monster arrow
    if self.m_PlayerRole.m_IsFighting then
        self.m_ExitArrow:SetActive(false)
        self.m_MonsterArrow:SetActive(false)
    else
        if self.m_ArrowTarget then
            if self.m_ArrowTarget==-1 or self.m_ArrowTarget:IsDead() or not self.m_ArrowTarget.m_Object then
                self.m_ArrowTarget = nil
            end
        end
        if not self.m_ArrowTarget then
            self.m_ArrowTarget = CharacterManager.GetRoleNearestAttackableTarget()
        end
        if self.m_ArrowTarget or self.m_BVRTarget then
            if self.m_ArrowTarget == -1 then
                self.m_MonsterArrow:SetActive(false)
                self.m_ArrowTarget = nil
            elseif self.m_BVRTarget then
                if mathutils.DistanceOfXoY(self.m_PlayerRole:GetRefPos(),self.m_BVRTarget) < 900 then
                    self.m_BVRTarget = nil
                    return
                end
                self:MonsterArrowDirectTo(self.m_BVRTarget)
            else
                self.m_BVRTarget = nil
                self.m_HasRequestedMonsterPosition = false
                self:MonsterArrowDirectTo(self.m_ArrowTarget:GetPos())
            end
        else
            self.m_MonsterArrow:SetActive(false)
            if self.m_HasRequestedMonsterPosition then
                self.m_BVRTime = self.m_BVRTime + Time.deltaTime
                if self.m_BVRTime>9999 then
                    self.m_HasRequestedMonsterPosition = false
                end
            else
                local re = map.msg.CFindAgentByType({agenttype = cfg.fight.AgentType.MONSTER,camp=cfg.fight.CampType.ENEMY})
                network.send(re)
                self.m_HasRequestedMonsterPosition = true
                self.m_BVRTime = 0
            end
        end
    end

    -- exit arrow
    local arrowTo = self.m_CurrentLayout:GetOpenExitPoint(self.m_PlayerRole:GetPos())
    if arrowTo then
        self.m_ExitArrow:SetActive(true)
        self:ExitArrowDirectTo(arrowTo)
    else
        self.m_ExitArrow:SetActive(false)
    end
end

function StoryEctype:late_update()
    if not self.m_ActionsManager:IsPlayingCG() then
        if self.m_CurrentLayout then
            if self.m_ExitArrow and self.m_MonsterArrow then
                self:ArrowsUpdate()
            end
        end
        if self.m_CurrentLayout then
            self.m_CurrentLayout:late_update()
        end
    end
end

function StoryEctype:second_update()

end

function StoryEctype:RealTimeStatistic(msg)
    local info = {}
    info.frameCount = 3
    info.totalDmg = 0
    info.players = {}
    for _,player in pairs(msg.teams[1].members) do
        local tb = {}
        tb.name = player.name .. (player.ownername=="" and "" or ('-'..player.ownername))
        tb.dmg = player.damage
        table.insert(info.players,tb)
        info.totalDmg = info.totalDmg + player.damage
    end
    table.sort(info.players,function(a,b) return a.dmg>b.dmg end)
    return info
end


function StoryEctype:EctypeStatistic(msg)
    local info = self:RealTimeStatistic(msg)
    if uimanager.isshow("ectype.dlguiectype") then
        uimanager.call("ectype.dlguiectype","OnStatistic",info)
    end
end

function StoryEctype:ChangeEnviroment(msg)
    self.m_Enviroments[msg.envname] = msg.value
    self.m_ActionsManager:ChangeEnviroment()
end


function StoryEctype:GetEnviroment(env)
    return self.m_Enviroments[env]
end


function StoryEctype:GetArea(curveid)
    return self.m_CurrentLayout:GetArea(curveid)
end


function StoryEctype:AddArrowTarget(pos)
    local target = Vector3(pos.x,pos.y,0)
    if target ~= Vector3.zero then
        self.m_BVRTarget = target
    end
end


function StoryEctype:ShowTasks(b)
    if uimanager.isshow("ectype.dlguiectype") then
        uimanager.call("ectype.dlguiectype","ShowTasks",b)
    end
end


function StoryEctype:SendReady()
    if self:IsReady() then
        local re = map.msg.CReady({})
        network.send(re)
    end
end


function StoryEctype:RefreshEctype(entryInfo)
    self.m_EctypeID         = entryInfo.id
    self.m_ReviveTimes      = entryInfo.remainrevivecount
    self.m_RemainTime       = entryInfo.remaintime/1000
    self.m_Enviroments      = entryInfo.enviroments
    self.m_OpeningLayouts   = entryInfo.openlayouts
    self.m_ActionsManager:Reset(entryInfo.activeactions)
    if self.m_CurrentLayout then
        self.m_CurrentLayout = nil
    end
    if self.m_NextLayout then
        self.m_NextLayout = nil
    end
    self:RefreshLayouts()
end


return StoryEctype
