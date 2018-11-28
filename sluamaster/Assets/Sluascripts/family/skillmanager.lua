local network = require("network")
local uimanager = require("uimanager")
local mgr = require("family.familymanager")

local m_IsReady = false
local m_SkillMap = {}
local m_MaxLevel = 0

local function IsReady()
    return m_IsReady
end

local function GetReady(callback)
end

local function Release()
    m_IsReady = false
end

local function GetSkill(skillid)
    -- printyellow("on get skill", skillid)
    -- printt(m_SkillMap)
    return m_SkillMap[skillid] or {skillid=skillid,level=0}
end

local function MaxLevel()
    return m_MaxLevel
end

local m_LevelupSkillCallback
local function LevelupSkill(skillid, callback)
    m_LevelupSkillCallback = callback
    network.send(lx.gs.family.msg.CStudyFamilySkill(){skillid=skillid})
end

local m_LevelupCeilingCallback
local function LevelupMax(callback)
    m_LevelupCeilingCallback = callback
    network.send(lx.gs.family.msg.CUpMaxSkillLevel())
end

local function init()
    network.add_listeners({
        {"lx.gs.family.msg.SGetFamilyWelfareInfo", function(msg)
             m_SkillMap = msg.welfare.skills
             m_MaxLevel = msg.welfare.maxskilllevel
             m_IsReady = true
             if m_Callback then
                 m_Callback()
                 m_Callback = nil
             end
        end},
        {"lx.gs.family.msg.SStudyFamilySkill", function(msg)
             if m_SkillMap[msg.skillid] then
                 m_SkillMap[msg.skillid].level = m_SkillMap[msg.skillid].level + 1
             else
                 m_SkillMap[msg.skillid] = {skillid=msg.skillid, level=1}
             end
             if m_LevelupSkillCallback then
                 m_LevelupSkillCallback()
             end
        end},
        {"lx.gs.family.msg.SUpMaxSkillLevel", function(msg)
             m_MaxLevel = m_MaxLevel + 1
             if m_LevelupCeilingCallback then
                 m_LevelupCeilingCallback()
             end
        end},

        -- notify
        {"lx.gs.family.msg.SUpLevelSkillNotify", function(msg)
        end},
        {"lx.gs.family.msg.SStudyFamilySkillNotify", function(msg)
        end}
    })
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    GetSkill            = GetSkill,
    MaxLevel            = MaxLevel,
    LevelupSkill        = LevelupSkill,
    LevelupMax          = LevelupMax,
}
