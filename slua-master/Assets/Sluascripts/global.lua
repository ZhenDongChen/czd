
Object          = UnityEngine.Object
GameObject 		= UnityEngine.GameObject
Transform 		= UnityEngine.Transform
MonoBehaviour 	= UnityEngine.MonoBehaviour
Component		= UnityEngine.Component
Application		= UnityEngine.Application
SystemInfo		= UnityEngine.SystemInfo
Screen			= UnityEngine.Screen
Camera			= UnityEngine.Camera
Material 		= UnityEngine.Material
Renderer 		= UnityEngine.Renderer
AsyncOperation	= UnityEngine.AsyncOperation
Color           = UnityEngine.Color
Vector3         = UnityEngine.Vector3
Vector2         = UnityEngine.Vector2
Quaternion      = UnityEngine.Quaternion
Mathf           = UnityEngine.Mathf
Shader          = UnityEngine.Shader
CharacterController = UnityEngine.CharacterController
SkinnedMeshRenderer = UnityEngine.SkinnedMeshRenderer
Animator		= UnityEngine.Animator
Animation       = UnityEngine.Animation
AnimationClip	= UnityEngine.AnimationClip
AnimationEvent	= UnityEngine.AnimationEvent
AnimationState	= UnityEngine.AnimationState
Input			= UnityEngine.Input
KeyCode			= UnityEngine.KeyCode
AudioClip		= UnityEngine.AudioClip
AudioSource		= UnityEngine.AudioSource
Physics			= UnityEngine.Physics
Light			= UnityEngine.Light
LightType		= UnityEngine.LightType
ParticleEmitter	= UnityEngine.ParticleEmitter
Space			= UnityEngine.Space
CameraClearFlags= UnityEngine.CameraClearFlags
RenderSettings  = UnityEngine.RenderSettings
MeshRenderer	= UnityEngine.MeshRenderer
WrapMode		= UnityEngine.WrapMode
QueueMode		= UnityEngine.QueueMode
PlayMode		= UnityEngine.PlayMode
ParticleAnimator= UnityEngine.ParticleAnimator
TouchPhase 		= UnityEngine.TouchPhase
WWW				= UnityEngine.WWW
AnimationBlendMode = UnityEngine.AnimationBlendMode
EffectPool = Game.EffectPool
DontDestroyOnLoad = UnityEngine.Object.DontDestroyOnLoad
DestroyImmadiate = GameObject.DestroyImmediate
OctetsStream = Aio.OctetsStream
Octets = Aio.Octets
RangeCube = Game.RangeCube
AudioManager = Game.AudioManager
UpdateManager = Game.UpdateManager
mainCamera      = Camera.main
cameraObject    = mainCamera.gameObject
cameraTransform = cameraObject.transform
log_message_queue = {}
logerror_message_queue = {}
gTeamManagerListState = {autoAcceptInvite = 0,autoAcceptRequest = 0,isInvitedFollow = false}


local unity_log = Util.Log
local unity_logError = Util.LogError


function cloneVector3(pos)
    return Vector3(pos.x, pos.y, pos.z)
end

Util.Log(Application.persistentDataPath)
local concat = table.concat
local format = string.format
local schar = string.char
local sbyte = string.byte
local tostring = tostring
local type = type
local insert = table.insert
local pairs = pairs
local ipairs = ipairs
local serverInfos = nil

print("=================package.loaded ", package.loaded["bit"])
if package.loaded["bit"] == nil then
    --printyellow("bit is nil now ....")
    bit = Game.bit
else
    bit = require "bit"
end

require "system.math"
require "system.list"

require "local"


local loggermanager

function print(...)
    --if not Local.LogManager or not loggermanager then return end
    local args = {...}
    for k, v in ipairs(args) do
        args[k] = tostring(v)
    end
    if Local.LogTraceback then
        unity_log(concat(args, '\t') .. '\t' .. debug.traceback())
		loggermanager.LogDebug(concat(args, '\t') .. '\t' .. debug.traceback())
    else
        unity_log(concat(args, '\t'))
		loggermanager.LogDebug(concat(args, '\t'))
    end
    --logError(debug.traceback())
end

local print = print

function printyellow(...)
    if not Local.LogManager then return end
    local args = {...}
    for k, v in ipairs(args) do
        args[k] = tostring(v)
    end

    if Local.LogTraceback then
        unity_log("<color=yellow>" .. concat(args, '\t') .. "</color>".. '\t' .. debug.traceback())
    else
        unity_log("<color=yellow>" .. concat(args, '\t') .. "</color>")
    end
end

function printyellowmodule(m,...)
    if not Local.LogManager then return end
    if m then
        printyellow(string.format("%.3f",UnityEngine.Time.time),...)
    end
end


function to_readable(s)
    if #s > 32 then
        return "#" .. #s
    else
        local a = {sbyte(s, 1, #s)}
        local all_ascii = true
        for i, b in ipairs(a) do
            if b >= 128 then
                all_ascii = false
                break
            end
        end
        return all_ascii and ("'" .. s .. "'") or ("#" .. #s .. "#" .. concat(a, "."))
    end
end

local to_readable = to_readable

local function dump_atom (x)
    if type(x) == "string" then
        return to_readable(x)
    else
        return tostring(x)
    end
end

local function dump_table_(t)
    local code = {"{"}

    for k, v in pairs(t) do
        if type(v) ~= "table" then
            insert(code, tostring(k) .. "=" .. dump_atom(v) .. ",")
        else
            insert(code, tostring(k) .. "=" .. dump_table_(v) .. ",")
        end
    end
    insert(code, "}")
    return concat(code)
end

dump_table = dump_table_

function printt(t)
    if not Local.LogManager then return end
    if type(t) == "table" then
        print(dump_table_(t))
    else
        print(t)
    end
end

function printtmodule(m,t)
    if not Local.LogManager then return end
    if m then
        printt(t)
    end
end

--function log(...)
--    if not Local.LogManager then return end
--    unity_log(format(...))
--end

function logError(...)
    if not Local.LogManager then return end
	unity_logError(format(...))
	loggermanager.LogInfo(format(...))
end


function LuaGC()
    local c1 = collectgarbage("count")
   -- unity_log("Begin gc count = {0} kb", c)
    collectgarbage("collect")
    local c2 = collectgarbage("count")
    print(string.format("=== gc before:%.1fkb, after %.1fkb", c1, c2))
  --  unity_log("End gc count = {0} kb", c)
end

function enum(t)
    local enumtable = {}
    local enumindex = 0
    local tmp,key,val
    for _,v in ipairs(t) do
        key,val = string.gmatch(v,"([%w_]+)[%s%c]*=[%s%c]*([%w%p%s]+)%c*")()
        if key then
            tmp = "return " .. string.gsub(val,"([%w_]+)",function (x) return enumtable[x] and enumtable[x] or x end)
            enumindex = loadstring(tmp)()
        else
            key = string.gsub(v,"([%w_]+)","%1");
        end
        enumtable[key] = enumindex
        enumindex = enumindex + 1
    end
    return enumtable
end

function LogLuaState()
    unity_log("Lua Total Memory:"..tostring(gcinfo()))

    local count = 0
    for k, v in pairs(_G) do
        count = count + 1
    end
    unity_log("Lua global variable number:"..tostring(count))
end

function GetTable()
    local t={}
    return t
end

function Split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end


function getn(t)
    local count = 0
    for k,v in pairs(t) do
        count = count + 1
    end
    return count
end

function keys(t)
    if type(t) ~= "table" then
        return {}
    end
    local keylist = {}
    for k,v in pairs(t) do
        keylist[#keylist+1] = k
    end
    return keylist
end

function trim(str)
	return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
end

require "common.class"
require "system.timer"
require "system.time"

define             = require "define"
defineenum         = require "defineenum"
utils              = require "common.utils"
mathutils          = require "common.mathutils"
timeutils          = require "common.timeutils"
viewutil           = require "common.viewutil"
checkcmd           = require "common.checkcmd"
gameevent          = require "gameevent"
status             = require "status"
colorutil		   = require "common.colorutil"

ConfigManager      = require "cfg.configmanager"
CharacterManager   = require "character.charactermanager"
SkillManager       = require "character.skill.skillmanager"
EffectManager      = require "effect.effectmanager"
local linkedlist   = require "common.linkedlist"
LinkedListNode     = linkedlist.LinkedListNode
LinkedListIterator = linkedlist.LinkedListIterator
LinkedList         = linkedlist.LinkedList
Queue              = require "common.queue"
Stack              = require "common.stack"
ObjectPool         = require "common.objectpool"
loggermanager      = require "loggermanager"

function newset()
    local reverse = {}
    local set = {}
    return setmetatable(set,{__index = {
          insert = function(self,value)
              if not reverse[value] then
                    table.insert(set,value)
                    reverse[value] = table.getn(set)
              end
          end,

          remove = function(self,value)
              local index = reverse[value]
              if index then
                    reverse[value] = nil
                    local top = table.remove(set)
                    if top ~= value then

                        reverse[top] = index
                        set[index] = top
                    end
              end
          end,

          find = function(self,value)
              local index = reverse[value]
              return (index and true or false)
          end,

		  clear = function(self)
			set = {}
			reverse = {}
		  end

    }})
end


--Animator.StringToHash
function StringToHash(aniName)
    if LuaHelper.name_hash_map [aniName] == nil then
        LuaHelper.StringToHash(aniName)
    end
    return LuaHelper.name_hash_map [aniName]
end

function IsNullOrEmpty(s)
    return s==nil or s==""
end

function IsNull(o)
    return o == nil or LuaHelper.IsNull(o)
end

function SetObjectParent(obj, parentObj)
    local trans = obj.transform
    local parentTrans = parentObj.transform
    trans:SetParent(parentTrans)
    trans.localPosition = Vector3(0,0,0)
    trans.localEulerAngles = Vector3(0,0,0)
end

function SetDontDestroyOnLoad(obj)
    if not IsNull(obj) then
        if IsNull(obj.transform.parent) then
            GameObject.DontDestroyOnLoad(obj)
        end
    end
    return obj
end

local defineenum = require"defineenum"
local Channels = defineenum.Channels
local serverMaps = {
    [Channels.LYSDK]  		= "serverlist_lysdk", -- LYSDK
    [Channels.TEST] 		= "serverlist_test",--"dhf_serverlist",
}

local BroadCastUrlMap = {
    [Channels.TEST] 		= Channels.TEST,
    [Channels.LYSDK]  		= Channels.LYSDK, -- LYSDK
}

function GetServerInfos()
    -- if not serverInfos then
         serverInfos = loadstring(LuaHelper.GetServerList())()
    -- end
    return serverInfos
end

function GetServerList()
    local channelid = Game.Platform.Interface.Instance:GetSDKPlatform()
    local serverinfos = GetServerInfos()
    local serverlist = serverinfos[serverMaps[channelid]]
    if not serverlist then
        serverlist = serverinfos[serverMaps[Channels.TEST]]
    end
    return serverlist
end

IsAndroid   = UnityEngine.RuntimePlatform.Android       == Application.platform
IsIos       = UnityEngine.RuntimePlatform.IPhonePlayer  == Application.platform
IsEditor    = UnityEngine.RuntimePlatform.WindowsEditor == Application.platform
IsWindows   = UnityEngine.RuntimePlatform.WindowsPlayer == Application.platform

function GetBroadCastUrl()
   local channelid = Game.Platform.Interface.Instance:GetSDKPlatform()
	--todo:简化处理 渠道0总是这样处理
	--if channelid ==0 then
    --    return Local.BroadCastUrls[1]
    --end
    local val = BroadCastUrlMap[channelid]
    if val then
        return Local.BroadCastUrls[BroadCastUrlMap[channelid]]
    else
        return Local.BroadCastUrls[BroadCastUrlMap[Channels.TEST]]
    end
end

--字符串换行转换，sourceString 源字符串， insertBase = 30， 字符串在每30个字符后添加一个换行"\n"，处理NGUI字符串不会自动换行问题
function StringAddLineBreak(sourceString,insertBase)
    if type(sourceString) ~= "string" or type(insertBase) ~= "number" then
        return
    end

    if insertBase <= 0 then
        return
    end

    local result = sourceString
    local lenth = string.len(result)
    if lenth>insertBase then
        local times = math.ceil(lenth/insertBase)
        local strings = {}
        for i = 1,times do
            local subEndIndex = insertBase*i
            if subEndIndex > lenth then
                subEndIndex = lenth
            end
            local tempString
            if i ~= times then
                tempString = string.sub(result,1+insertBase*(i-1),subEndIndex).."\n"
            else
                tempString = string.sub(result,1+insertBase*(i-1),subEndIndex)
            end

            strings[i] = tempString
        end

        result = table.concat(strings)

    end

    return result
end
