local CharacterManager = require "character.charactermanager"
local SettingManager = require "character.settingmanager"
--local PlotManager      = require "plot.plotmanager"
local BagManager       = require "character.bagmanager"
local PlayerRole = require "character.playerrole"

local defineenum = require "defineenum"
local GrahpicQuality = defineenum.GrahpicQuality
local events = defineenum.AutoAIEvent
local states = defineenum.AutoAIState

local _curState = states.none
local _States = {}
local _Transtions = {}
local _Running = false
local _HealHpTimer
local _HealMpTimer
local _ResetPosTimer
local _CastSkillTimer
local _SimpleTimer
local _StartPos
local _IsSimpleMode = false

local function ToSimpleMode()
    printyellow("#############################simple mode now")
    --[[if not _IsSimpleMode then 
        _IsSimpleMode = true
        local DlgUIMainHide=(require"ui.dlguimain_hide")
        DlgUIMainHide.ChangeHideUIMode(true)
        GraphicSettingMgr = require"ui.setting.graphicsettingmanager"
        GraphicSettingMgr.UseTmpQuality(GrahpicQuality.Low)
        _SimpleTimer:Stop()
        Application.targetFrameRate = 15
    end]]
end

local function ToNormalMode()
    printyellow("#############################to normal mode now")
    _SimpleTimer:Reset(ToSimpleMode, 300, -1)
    _SimpleTimer:Start()

    if _IsSimpleMode then        
        _IsSimpleMode = false
        local DlgUIMainHide=(require"ui.dlguimain_hide")
        DlgUIMainHide.ChangeHideMode(false) 
        GraphicSettingMgr = require"ui.setting.graphicsettingmanager"
        GraphicSettingMgr.ResumeQuality() 
        Application.targetFrameRate = 30      
    end
end

  
local function CastSkill()
    if (_curState == states.attack) then
        if CharacterManager.GetRoleNearestAttackableTarget4AI() then
            if PlayerRole:Instance().m_RoleSkillFsm:GetState() == 0 then
                printyellow("auto ai, fa dai zhong...")
                _States[_curState]:OnEvent(events.skillover)
            end
        end
    end
end

local function RecordStartPos()  
    _StartPos = PlayerRole:Instance():GetPos()
    _States[states.automove]:RecordStartPos(_StartPos)
end
 
local function ResetSkillIndex()
    local state = _States[states.attack]
    state:ResetSkillIndex()
end


local function NeedHp()
	local SettingAutoFight = SettingManager.GetSettingAutoFight()
    local max_hp = PlayerRole:Instance().m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE] or 1
	local cur_hp = PlayerRole:Instance().m_Attributes[cfg.fight.AttrId.HP_VALUE] or 0
	return cur_hp/max_hp  < (SettingAutoFight["HP"] or 0)
end

local function NeedMp()
	local SettingAutoFight = SettingManager.GetSettingAutoFight()
	local max_mp = PlayerRole:Instance().m_Attributes[cfg.fight.AttrId.MP_FULL_VALUE] or 1
	local cur_mp = PlayerRole:Instance().m_Attributes[cfg.fight.AttrId.MP_VALUE] or 0
	return cur_mp/max_mp  < (SettingAutoFight["MP"] or 0)  
end

local function HealMp() 
    if not PlayerRole:Instance():IsDead() and NeedMp() then  
        --printyellow("###############healmp") 
	    local items = BagManager.GetMPItem()
	    if #items ~= 0 then
		    item = items[1]
		    local cdData =item:GetCDData() 
	        if  cdData:IsReady() then
			    BagManager.SendCUseItem(item.BagPos,1)
		    end
	    end 
    end
end

local function HealHp()
    if not PlayerRole:Instance():IsDead() and NeedHp() then
        --printyellow("##########################healhp") 
	    local items = BagManager.GetHPItem()
	    if #items ~= 0 then
		    item = items[1]
		    local cdData =item:GetCDData()
		    if  cdData:IsReady() then
			    BagManager.SendCUseItem(item.BagPos,1)
		    end
	    end
    end
end




local function AddTransition(sFrom, evt, sTo)  
    if _Transtions[sFrom] then  
        if _Transtions[sFrom][evt] then 
            --assert("event already be added")  
        else  
            _Transtions[sFrom][evt] = sTo
        end
    else
        _Transtions[sFrom] = {}
        _Transtions[sFrom][evt] = sTo 
       
    end
--    print("=========================================>")
--    printt(_Transtions)  
--    print("=========================================>")
end  
  
local function StateTransition(event)  

    local newstate = nil
    if Local.LogModuals.AutoAI then
        print("state transition: oldstate, event ", utils.getenumname(states,_curState),utils.getenumname(events,event))
    end

    if _Transtions[states.any][event] then
        newstate = _Transtions[states.any][event]
    else
        newstate = _Transtions[_curState][event] 
    end
    
    if Local.LogModuals.AutoAI then
        print("state transition: newstate ", utils.getenumname(states,newstate))
    end

    if newstate == _curState then return end
     
    if newstate then  
        _States[_curState]:Exit()  
        _curState = newstate  
        _States[_curState]:Enter()  
    else  
        --print("no reponse to event:", event) 
    end  
end  

local function OnEvent(event)
    if not _Running then
        return
    end

	--if  PlotManager.IsPlayingCutscene()  then
	--	return 
	--end        
    
    StateTransition(event)

    --print("current state " , _curState)
    _States[_curState]:OnEvent(event)
end

local function InitSkills()
    local state = _States[states.attack]
--    print("xxxxxxxxxx")
--    printt(state)

    state:ResetSkills()
end

local function InitPrologueSkills()
    local state = _States[states.attack]
    state:ResetSkillsInProlgue()
end

local function Start(b)
    local old = _Running
    _Running = b
    
    if old ~= _Running then
        if (not _Running) then
            if Local.LogModuals.AutoAI then
                print("ai stop, currentstate is ", utils.getenumname(states,_curState))
            end
            OnEvent(events.stop)

            _HealHpTimer:Stop()
            _HealMpTimer:Stop()
            _ResetPosTimer:Stop()
            _CastSkillTimer:Stop()
            _SimpleTimer:Stop()
        else
            if Local.LogModuals.AutoAI then
                print("ai start, current is ", utils.getenumname(states,_curState))
            end        
            OnEvent(events.start)
            RecordStartPos()
            ResetSkillIndex()

            _HealHpTimer:Start()
            _HealMpTimer:Start()
            _ResetPosTimer:Start()
            _CastSkillTimer:Start()
            _SimpleTimer:Start()
        end
    end

end
local function IsRunning()
    return _Running
end
local function ReturnToStartPos()
    local SettingAF = SettingManager.GetSettingAutoFight()
    printyellow("autofight range is ", SettingAF["Range"])
    if SettingAF["Range"] > 0.75 then return end     --全服挂机

    if (mathutils.DistanceOfXoY(PlayerRole:Instance():GetRefPos(),_StartPos) > (SettingAF["Range"]*40 + 3 ) * SCALE_XY)  then
        --printyellow("#####################automove triggered now")
        OnEvent(events.automove)
    end
end

local function ClearData()
    Start(false)    
end

local function init()
    local FsmState = require "character.ai.autoaistate"

    local idle = FsmState.FSMStateIdle:new()
    local attack = FsmState.FSMStateAttack:new()
    local joymove = FsmState.FSMStateJoyMove:new()
    local none     = FsmState.FSMStateNone:new()
    local automove  = FsmState.FSMStateAutoMove:new()

    _States[states.idle]     = idle
    _States[states.attack]   = attack
    _States[states.joymove]  = joymove
    _States[states.none]     = none
    _States[states.automove] = automove
    

    AddTransition(states.idle, events.monster, states.attack)
	AddTransition(states.attack, events.nomonster, states.idle)    
    AddTransition(states.automove, events.backtopos, states.idle)
    AddTransition(states.joymove, events.joystop, states.idle)

    AddTransition(states.any,  events.automove, states.automove)
    AddTransition(states.any,  events.joy,     states.joymove)
    AddTransition(states.any,  events.stop,   states.none)
    AddTransition(states.any, events.start,  states.idle)

    _HealHpTimer = Timer.New(HealHp, 2, -1)
    _HealMpTimer = Timer.New(HealMp, 2, -1)
    _ResetPosTimer = Timer.New(ReturnToStartPos, 10, -1)
    _CastSkillTimer = Timer.New(CastSkill, 5, -1)
	 printyellow("auto ai init .")
    _SimpleTimer  = Timer.New(ToSimpleMode, 300, -1)
    gameevent.evt_system_message:add("logout",ClearData)
end

return 
{
    init = init,
    InitSkills = InitSkills,
    InitPrologueSkills = InitPrologueSkills,
    OnEvent = OnEvent,
    Start   = Start,
    IsRunning = IsRunning,
    ToNormalMode = ToNormalMode,
}
