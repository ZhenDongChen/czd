
--坐标缩放必须跟客户端一致
SCALE_XY=100---
SCALE_XY_FRACTION=1/SCALE_XY--0.01;

--速度缩放 （距离 速度都用这个 翻倍 ） 必须跟客户端一致
MOVE_SPEED_DEFAULT=300 ---原来是5

SCALE_SPEED=MOVE_SPEED_DEFAULT/5
DROP_ITEM_Z=-800
EFFECT_Z=-800
PLAYER_Z_MIN=-300  ----必须比特效 物品的 Z大，确保角色显示在后面
	
NAV_ASTAR_CELL_Y=32 ---A*原来是16*32  实际使用时放大1倍
NAV_ASTAR_CELL_X=64

LMIIT_MAX_ONE = 20 --- 版号限制单抽最大次数
LMIIT_MAX_TEN = 2 --- 版号限制十抽最大次数

	
local Local = require"local"

local NoviceGuideType = enum{
    "NONE",
    "TRIGGERNEXT",
    "HIDEOBJ",
    "FINDOBJ",
    "CANNOTFINDOBJ",
    "SHOWEFFECT",
    "SHOWINGGUIDE",
}

local Channels = enum{
	"LYSDK=1",
	"TEST=0",
}


local GenderType = enum
{
    "Male=0",
    "Female=1",
}

local GrahpicQuality = enum{
    "Low=1",
    "Mid",
    "High",
    "Extreme",
}

local NpcStatusType = enum {
    "None",
    "CanAcceptTask",
    "CanCommitTask",
}

local CharacterType = enum
{

  "Character = 1",
  "PlayerRole = bit.lshift (1,1)",
  "Player = bit.lshift (1,2)",
  "Monster = bit.lshift (1,3)",
  "Npc = bit.lshift (1,4)",
  "Pet = bit.lshift (1,5)" ,
  "Boss = bit.lshift (1,6)",
  "Mount = bit.lshift(1,7)",
  "Mineral = bit.lshift(1,8)",
  "DropItem= bit.lshift(1,9)",
  "Portal = bit.lshift(1,10)",
  "RolePet = bit.lshift(1,11)",
  "Talisman = bit.lshift(1,12)",
  "Rune = bit.lshift(1,13)",
  "FamilyCityTower = bit.lshift(1,14)",
}

local LimitType =
{
    DAY      = 1,
    WEEK     = 2,
    MONTH    = 3,
    LIFELONG = 4,
    NO_LIMIT = -1,
}
local ActivationCodeErr = 
{
    --成功
    ERR_SUCCESS = 0,
    --激活码格式错误
    ERR_FORMATE_INVALID = 1,
    --激活码无效
    ERR_INVALID = 2,
    --激活码类型不匹配
    ERR_TYPE_NOT_MATCH = 3,
    --激活码已使用
    ERR_CODE_IS_USED = 4,
    --激活码已过期
    ERR_CODE_IS_EXPIRATED = 5,
    --激活码未到使用时间
    ERR_CODE_IS_NOT_OPEN = 6,
    --激活码功能已关闭
    ERR_FUNCTION_IS_CLOSED = 7,
    --激活码平台不匹配
    ERR_PLATFORM_NOT_MATCH = 8,
    --已经使用过同一类型的激活码
    ERR_HAS_ALEADY_ACTIVATED = 9,
    --deliver和au通讯异常
    ERR_NETWORK = 10,
    --超出每日使用次数
    ERR_EXCEED_DAY_USENUM = 11,
    --超出累计使用次数
    ERR_EXCEED_ALL_USENUM = 12,
    --服务器内部错误
    ERR_INTERNAL = 13,
    --等级太低,无法使用
    ERR_LEVEL_TOO_LOWE = 15,
    --等级太高,无法使用
    ERR_LEVEL_TOO_HIGH = 16
}
local AniStatus = enum
{
  "Idle =0",
  "Run = 1",
  "RunEnd = 2",
  "Skill1",
  "Skill2",
  "Skill3",
  "Skill4",
  "StandRide",
  "RunRide", --11
  "Stand",
  "Running",
  "Trotting", --14
  "Faint",
  "Hurt",
  "Feijian",
  "Death",
  "Caiji",
  "Combat",
  "Float",
  "Qishen",
  "Skill06_1",
  "Skill06_2",
  "Skill06_3",
  "Skill07",
  "Skill08",
  "Attack01End",
  "Attack02End"
}


local WorkType = enum
{
  "None",
  "Idle",
  "Move",
  "MoveEnd",
  "NormalSkill",
  "TalismanSkill",
  "BeAttacked",
  "Dead",
  "Relive",
  "FreeAction",
  "PathFly",
}


local EventType = enum
{
  "None",
  "Skill",
  "BeAttacked",
  "MoveEnd",
  "Move",
  "Dead",
  "Relive",
  "FreeAction",
}


local SkillType = enum
{
    "Immediately",                                    -- ???????????
    "Fly",                                            -- ??????(????)
    "Bomb",                                           -- ?????
    "Ray",                                            -- ??????
    "Qte",                                            -- QTE??
    "Talisman",                                       -- ????????
}


local CharState = enum
{
  "None = 0",
  "Freeze = 1",   --can not move and animation ????
  "Vertigo = bit.lshift (1,1)", --can not move or skill, can animation  ???
  "Invincible = bit.lshift (1,2)", --no drophp,no hurtanim, no fly ????
  "Silence = bit.lshift (1,3)", --no hurtanim, no fly ???
  "Air = bit.lshift (1,4)", --???
  "Lock = bit.lshift (1,5)", --can not move,
  "Fixbody = bit.lshift (1,6)", --only no fly
}


local MonsterAudioType = enum{
    "BEATTACK",
    "DEAD",
    "PATROL",
}

local CameraShakeType = enum
{
  "NoShake",
  "Normal" ,
  "Horizontal",
  "Vertical",
}

local EffectLevel = enum
{
  "None",
  "All",
  "NotSkill",
}


local CharacterAbilities = enum{
    "NORMALSKILL=0x01",
    "SKILL=0x02",
    "ITEM=0x04",
    "MOVE=0x08",
    "ALLENABLE=0x0F"
}

local AutoAIEvent = enum
{
    "monster",   --?п???????
    "nomonster", --??й???
    "joy",       --????????
    "joystop",   --??????????
    "skillover", --???????
    "skillbreak",--?????ж?
    "automove", --???????????λ??
    "backtopos",--?????????λ??
    "start",    --????
    "stop",     --??
}

local AutoAIState = enum
{
    "any",
    "none",
    "idle",
    "attack",
    "joymove",
    "automove",
}


local MapType = enum
{
    "WorldMap = 0",
    "EctypeMap = 1",
    "FamilyStation = 2",
}


local AudioPriority = enum
{
  "Attack", --??????Ч
  "BeAttack", --??????Ч
  "ActionEffect", --??????Ч????????????
  "Default", --???
}


local ESpecialType = enum
{
  "None",
  "Bomb",
  "Ray",
}

local EffectInstanceType = enum
{
    "Stand",
    "Follow",
    "Trace",
    "TracePos",
    "BindToCamera",
    "UIStand",
    "StandTarget",
    "FollowTarget",
    --"SpaceLink",
    "CreateRole",
    "CreateTalisman",
    "BindToBip",-- = 10,
    "BindToBipTarget",-- = 11,
}

local EffectInstanceBindType = enum
{
    "Body=0",
    "Head",
    "Foot",
    "LeftHand",
    "RightHand",
    "LeftFoot",
    "RightFoot",
    "LeftWeapon",
    "RightWeapon",
}


local EffectInstanceAlignType = enum
{
    "None",
    "LeftTop",
    "Left",
    "LeftBottom",
    "Top",
    "Center",
    "Bottom",
    "RightTop",
    "Right",
    "RightBottom",
}

local TraceType = enum
{
    "Line",
    "Bezier",
    "Line2D",
}


local ModuleStatus = enum{
    "LOCKED",
    "UNLOCK",
}

local PortalEffectType=enum
{   --????????Ч????
    "HIDE=0",   --????
    "STEREO=1", --????
    "GROUND=2",  --????
}


local PortalTransMode=enum
{   --??????
    "DIRECT=0",  --????
    "FLY=1",     --????
}
local MountType = enum
{
  "Attaching",
  "Ride",
  "Up",
  "Fly",
  "Down",
  "ToPointLand"
}

local MountActiveStatus = enum
{
    "None",
    "Get",
    "Actived",
}


local TaskType = enum {
    "Mainline=1",
    "Branch=2",
    "Family=3",
}

local TaskNavModeType = enum {
    "Default=1",
    "AccordingMapConnection=2",
    "DirectTransfer=3",
}

local NpcStatusType = enum {
    "None",
    "CanAcceptTask",
    "CanCommitTask",
}

local TaskStatusType = enum{
    "None",
    "Accepted",
    "Doing",
    "UnCommitted",
    "Completed",
}


---版号限制次数功能枚举
local ExamineLimitType =
{
    SoulOne      = "SoulOne", -- 魂晶狩猎1次
    SoulTen      = "SoulTen", -- 魂晶狩猎10次
}

g_idRoldTraceRotate=g_idRoldTraceRotate 

g_clientCmdList=g_clientCmdList or {}
function RegisterClientCmd(nm,fnc)
    g_clientCmdList[nm]=fnc
end

function isOSWindows() 
    if Application.platform == UnityEngine.RuntimePlatform.WindowsPlayer
           or Application.platform == UnityEngine.RuntimePlatform.WindowsEditor then
        return true
    end
	return false;
end

function isEnableClientCmd(cmd)
	 return true
end

g_tbFunctionSet = g_tbFunctionSet or {}
function isTestServer()
    if g_tbFunctionSet.test and g_tbFunctionSet.test==1 then
        return true
    end
	return false
end

function shouldHideVip()
    --return Local.hidevip 
    if g_tbFunctionSet.hidevip and g_tbFunctionSet.hidevip==1 then
        return true
    end
	return false
end

-- 是否版署审核状态
function IsBSReview()
    if g_tbFunctionSet.bsreview and g_tbFunctionSet.bsreview==1 then
        return true
    end
    return false
end

function needShowMsg()
    if g_tbFunctionSet.showMsg==nil then
        local vShowMsg = UnityEngine.PlayerPrefs.GetInt("c_cfg2018_showmsg", 1)
        g_tbFunctionSet.showMsg = vShowMsg > 0
    end
    return g_tbFunctionSet.showMsg
end
function setShowMsg(bShowMsg)
    g_tbFunctionSet.showMsg = bShowMsg
    local vTmp = 0
    if bShowMsg then vTmp = 1 end
    UnityEngine.PlayerPrefs.SetInt("c_cfg2018_showmsg", vTmp)
end



local BoneNames = {}
BoneNames[EffectInstanceBindType.LeftHand] = "Bip001 L Hand"
BoneNames[EffectInstanceBindType.RightHand] = "Bip001 R Hand"
BoneNames[EffectInstanceBindType.LeftFoot] = "Bip001 L Foot"
BoneNames[EffectInstanceBindType.RightFoot] = "Bip001 R Foot"
BoneNames[EffectInstanceBindType.LeftWeapon] = "weapon_L"
BoneNames[EffectInstanceBindType.RightWeapon] = "weapon_R"


-- g_ModelOffset 部分特殊的对话NPC头像偏移
local g_ModelOffset = {}
g_ModelOffset[23000063] = 33

local RewardDistributionType =
{
    Territory = 1,
    RoundRobin = 2,
}


return
{
	Channels = Channels,
	GenderType = GenderType,
	GrahpicQuality = GrahpicQuality,
	CharacterType = CharacterType,
	AniStatus = AniStatus,
	WorkType = WorkType,
	EventType = EventType,
	SkillType = SkillType,
	CharState = CharState,
	MonsterAudioType = MonsterAudioType,
	CameraShakeType = CameraShakeType,
	EffectLevel = EffectLevel,	
	CharacterAbilities    = CharacterAbilities,
	AutoAIEvent = AutoAIEvent,
	AutoAIState = AutoAIState,
	MapType = MapType,
	AudioPriority = AudioPriority,
	ESpecialType = ESpecialType,
	EffectInstanceType = EffectInstanceType,
	EffectInstanceBindType = EffectInstanceBindType,
	EffectInstanceAlignType = EffectInstanceAlignType,
	BoneNames = BoneNames,
	TraceType = TraceType,
	ModuleStatus = ModuleStatus,
	LimitType = LimitType,

	NpcStatusType = NpcStatusType,

	PortalEffectType = PortalEffectType,
	PortalTransMode = PortalTransMode,
	TaskType = TaskType,
	TaskNavModeType = TaskNavModeType,
	NpcStatusType = NpcStatusType,
    TaskStatusType = TaskStatusType,
    ExamineLimitType = ExamineLimitType,
    NoviceGuideType = NoviceGuideType,
    MountType=MountType,
    MountActiveStatus = MountActiveStatus,
    g_ModelOffset = g_ModelOffset,
    RewardDistributionType = RewardDistributionType,
    ActivationCodeErr = ActivationCodeErr,
}


