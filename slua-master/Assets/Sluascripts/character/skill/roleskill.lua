local utils             = require "common.utils"
local mathutils         = require "common.mathutils"
local network           = require "network"
local PlayerRole        = require "character.playerrole"
local PlayerSkill
local charactermanager -- = require "character.charactermanager"
local SkillManager      = require "character.skill.skillmanager"
local uimanager         = require "uimanager"
local CharacterSkillInfo = require "character.skill.characterskillinfo"
local ItemManager    = require "item.itemmanager"
local DlgUIMain_Combat

local SkillRangeCorrect = 0.3



local RoleSkillInfo     = nil
local TalismanSkill     = nil
local Index_TalismanSkill = -1
local Index_NormalSkill = 0
local timer = nil
local tabskill = "skill.tabskill"
local dlgskill = "skill.dlgskill"



local function GetRoleSkillInfo()
    return RoleSkillInfo
end
local function GetAllActiveSkills()
    
    local allskills = {}
	
    local careerskilllist = ConfigManager.getConfigData ("careerskilllist",PlayerRole:Instance().m_Profession)
    allskills[careerskilllist.normalskillid] = 1

    if TalismanSkill then
        allskills[TalismanSkill.skillid] = TalismanSkill.level
    end

    for _,skillinfo in pairs(RoleSkillInfo:GetAllSkills()) do
        if skillinfo.actived and not skillinfo:GetSkill():IsPassive() then
            allskills[skillinfo.skillid] = skillinfo.level
        end
    end
    return allskills
end 

local function GetAllEquipedSkills()
    local equipedskills = {}
    local careerskilllist = ConfigManager.getConfigData ("careerskilllist",PlayerRole:Instance().m_Profession)
    equipedskills[careerskilllist.normalskillid] = Index_NormalSkill

    if TalismanSkill then
        equipedskills[TalismanSkill.skillid] = Index_TalismanSkill
    end

    for index,skillid in pairs(RoleSkillInfo:GetEquipedSkills()) do
        equipedskills[skillid] = index
    end
    return equipedskills
end

local function RefreshEquipedSkills()
     --printyellow("[roleskill:RefreshEquipedSkills] RefreshEquipedSkills() begin" ,Time.realtimeSinceStartup)

    --------------------------------------------------------
    local allskills = GetAllActiveSkills()
    --------------------------------------------------------
    local equipedskills = GetAllEquipedSkills()

    PlayerRole:Instance().PlayerSkill:SetSkills(allskills,equipedskills)
    --printyellow(" RefreshEquipedSkills() done" ,Time.realtimeSinceStartup)
    DlgUIMain_Combat.refresh()
end

local function RefreshTransformSkills(skillmap)
    local oldskills = GetAllActiveSkills()
    local oldequipedskills = GetAllEquipedSkills()
    local allskills = {}
    local equipedskills = {}
    for skillid,level in pairs(oldskills) do
        local newskillid = skillmap[skillid]
        if newskillid ~=nil then 
            allskills[newskillid] = level
            if oldequipedskills[skillid] ~=nil then 
                equipedskills[newskillid] = oldequipedskills[skillid]
            end 
        end 
    end  

    PlayerRole:Instance().PlayerSkill:SetSkills(allskills,equipedskills)
    --printyellow(" RefreshEquipedSkills() done" ,Time.realtimeSinceStartup)
    DlgUIMain_Combat.refresh()

end 

local function GetSkillOrder(skillid, skillorder)
    if skillid and skillid>0 and skillorder and #skillorder>0 then
        for i=1, #skillorder do
            if skillorder[i] == skillid then
                return i
            end
        end
    end
    return 0
end

local function GetStartIndex(skills, skillorder)
    local index = 1
    if skills and #skills>0 and skillorder and #skillorder>0 then
        for index,skillid in ipairs(skillorder) do
            if skills[skillid] and skills[skillid]>0 then
                index = index+1
            end
        end
    end
    return index
end

--����skills map{skillid��level}
local function RefreshTempEquipedSkills(skills, skillorder)
    -- printyellow("[roleskill:RefreshTempEquipedSkills] RefreshEquipedSkills() begin" ,Time.realtimeSinceStartup)

    --------------------------------------------------------
    local allskills = {}
    local equipedskills = {}

    local careerskilllist = ConfigManager.getConfigData ("careerskilllist",PlayerRole:Instance().m_Profession)
    allskills[careerskilllist.normalskillid] = 1
    equipedskills[careerskilllist.normalskillid] = Index_NormalSkill

    -- printt(skillorder)
    local index = GetStartIndex(skills, skillorder)
    for skillid,level in pairs(skills) do
        local skill = SkillManager.GetSkill(skillid)
        if skill~=nil and not skill:IsPassive() and  not skill:IsNormal() then
            allskills[skillid] = level

            local order = GetSkillOrder(skillid, skillorder)
            if order>0 then
                --printyellow(string.format("[roleskill:RefreshTempEquipedSkills] skill [%s] orkder is [%s].", skillid, order))
                equipedskills[skillid] = order
            else
                --printyellow(string.format("[roleskill:RefreshTempEquipedSkills] skill [%s] index is [%s].", skillid, index))
                equipedskills[skillid] = index
                index = index+1
            end
        end
    end

    PlayerRole:Instance().PlayerSkill:SetSkills(allskills,equipedskills)
    --printyellow(" RefreshEquipedSkills() done" ,Time.realtimeSinceStartup)
    DlgUIMain_Combat.refresh()
end

local function SetTalismanSkillId(skillid,level)
    if skillid~=0 then
        TalismanSkill = {skillid = skillid,level = level}
    else
        TalismanSkill = nil
    end
    RefreshEquipedSkills()

    local autoai = require "character.ai.autoai"
    autoai.InitSkills()
end

local function ResetTalismanCD()
    PlayerRole:Instance().PlayerSkill:ResetTalismanCD()
end


local function onmsg_SInfo(msg)
    if Local.LogModuals.Skill then
    printyellow("Skill onmsg_SInfo(msg)")
    end
    RoleSkillInfo     = CharacterSkillInfo:new()
    local characterskills = {}
    local careerskilllist = ConfigManager.getConfigData ("careerskilllist",PlayerRole:Instance().m_ProfessionData.faction)
    for _,skillid in ipairs(careerskilllist.skilllist) do
        table.insert(characterskills,skillid)
    end

    RoleSkillInfo:init(characterskills,msg.skills,msg.equipskillpositions)

    RefreshEquipedSkills()

    local autoai = require "character.ai.autoai"
    autoai.InitSkills()
end



local function ChangeEquipActiveSkill(equipskillpositions)
    local re = lx.gs.skill.msg.CChangeEquipActiveSkill({ equipskillpositions = equipskillpositions})
    network.send(re)
end


local function onmsg_SChangeEquipActiveSkill(msg)
    RoleSkillInfo:ChangeEquipActiveSkill(msg.equipskillpositions)
    uimanager.call(tabskill,"CloseDialog")
    --tabskill.CloseDialog()
    uimanager.refresh(tabskill)
    RefreshEquipedSkills()
    local autoai = require "character.ai.autoai"
    autoai.InitSkills()
end

local function CheckData(data,showsysteminfo)
    if data == nil then
        return false
    end
    if PlayerRole:Instance():GetLevel()< data.requirelvl then
        if showsysteminfo then uimanager.ShowSystemFlyText(LocalString.DlgSkill_LEVEL) end
        return false
    end
	local checkcmd           = require("common.checkcmd")
    local validate, info = checkcmd.CheckData( { data = data.requirecurrency1, num = 1, showsysteminfo = showsysteminfo })
    if not validate then
        if showsysteminfo then
            ItemManager.GetSource(cfg.currency.CurrencyType.XuNiBi,dlgskill)
        end
        return false
    end

    validate, info = checkcmd.CheckData( { data = data.requirecurrency2, num = 1, showsysteminfo = showsysteminfo })
    if not validate then
        if showsysteminfo then
            ItemManager.GetSource(cfg.currency.CurrencyType.ZaoHua,dlgskill)
        end
        return false
    end
    return true

end


--升级技能发送给服务端
local function UpgradeSkill(skill,nextlevel)

    if CheckData( skill:GetSkillLvlupData(nextlevel),true) then
        local re = lx.gs.skill.msg.CUpgradeSkill({ skillid = skill.skillid})
        network.send(re)
    end
end


local function onmsg_SUpgradeSkill(msg)
    local skillinfo = RoleSkillInfo:UpgradeSkill(msg.skillid,msg.newlevel)
    uimanager.refresh(tabskill)
    if uimanager.needrefresh(tabskill) then
       uimanager.call(tabskill,"RefreshUpgradeSkill",skillinfo)
    end

    uimanager.ShowSystemFlyText(LocalString.DlgSkill_UpgradeSuccess )
    RefreshEquipedSkills()
    uimanager.call(tabskill,"PlayUpgradeEffect")
end

local function EvolveSkill(skill)
	
	
    if CheckData(skill:GetEvolveSkill():GetSkillLvlupData(1),true) then
		printyellow("XXXXXXXforward",skill.skillid)
        local re = lx.gs.skill.msg.CEvolveSkill({ skillid = skill.skillid})
        network.send(re)
    end

end

local function onmsg_SEvolveSkill(msg)
	printyellow("XXXXXXXXXback",msg.newskillid)
    local skillinfo = RoleSkillInfo:EvolveSkill(msg.oldskillid, msg.newskillid)
    uimanager.refresh(tabskill)
    uimanager.ShowSystemFlyText(LocalString.DlgSkill_EvolveSuccess  )
    RefreshEquipedSkills()
    --uimanager.call(tabskill,"PlayEvolveEffect")
    uimanager.showorrefresh("dlgtweenset",{
        tweenfield = "UIPlayTweens_EvolveSkill",
        fieldparams = {texture = skillinfo:GetSkill():GetSkillIcon() }
    })
    timer = Timer.New(function()
        if uimanager.needrefresh(tabskill) then
            uimanager.call(tabskill,"RefreshUpgradeSkill",skillinfo)
        end
    end,1,false)
    timer:Start()
end

function GetAmuletLevel(s)
    --[[local skill = s:GetFirstOriginalSkill()
    if skill~=nil then
        local AmuletManager  = require("ui.playerrole.equip.amuletmanager")
        local attrs = AmuletManager.GetAmuletAttrs()
        if attrs[skill.skillid] then
            return attrs[skill.skillid]
        end
    end]]
    return 0
end

function GetAmuletLabel(s)
    local amuletlevel = GetAmuletLevel(s)
    if amuletlevel>0 then
        return string.format("[9FCB36](+%s)[-]",amuletlevel)
    end
    return ""
end

local function Logout ()
    RoleSkillInfo     = nil
    TalismanSkill     = nil
end


local function onmsg_SError(msg)
    if msg.errcode == lx.gs.skill.msg.SError.LEVEL then
    --    printyellow(msg.errcode,lx.gs.skill.msg.SError.LEVEL,LocalString.DlgSkill_LEVEL)
        uimanager.AddSystemInfo(LocalString.DlgSkill_LEVEL)

    elseif msg.errcode == lx.gs.skill.msg.SError.EXCEED_MAX_EQUIP_SKILL_NUM then
        uimanager.AddSystemInfo(LocalString.DlgSkill_EXCEED_MAX_EQUIP_SKILL_NUM)

    elseif msg.errcode == lx.gs.skill.msg.SError.NOT_INT_SKILL_LIST then
        uimanager.AddSystemInfo(LocalString.DlgSkill_NOT_INT_SKILL_LIST)

    elseif msg.errcode == lx.gs.skill.msg.SError.DUPLICATE_EQUIP_POSITION then
        uimanager.AddSystemInfo(LocalString.DlgSkill_DUPLICATE_EQUIP_POSITION)

    elseif msg.errcode == lx.gs.skill.msg.SError.CANNOT_EQUIP_PASSIVE_SKILL then
        uimanager.AddSystemInfo(LocalString.DlgSkill_CANNOT_EQUIP_PASSIVE_SKILL)

    elseif msg.errcode == lx.gs.skill.msg.SError.CUR_LEVEL_CANNOT_EVOLVE then
        uimanager.AddSystemInfo(LocalString.DlgSkill_CUR_LEVEL_CANNOT_EVOLVE)

    elseif msg.errcode == lx.gs.skill.msg.SError.NOT_NEXT_EVOLVE_SKILL then
        uimanager.AddSystemInfo(LocalString.DlgSkill_NOT_NEXT_EVOLVE_SKILL)

    elseif msg.errcode == lx.gs.skill.msg.SError.XUNIBI_NOT_ENOUGH then
        uimanager.AddSystemInfo(LocalString.DlgSkill_XUNIBI_NOT_ENOUGH)

    elseif msg.errcode == lx.gs.skill.msg.SError.YUANBAO_NOT_ENOUGH then
        uimanager.AddSystemInfo(LocalString.DlgSkill_YUANBAO_NOT_ENOUGH)

    elseif msg.errcode == lx.gs.skill.msg.SError.CANNOT_UPGRADE_MAX_LEVEL then
        uimanager.AddSystemInfo(LocalString.DlgSkill_CANNOT_UPGRADE_MAX_LEVEL)


    end
end

local function init()
    PlayerSkill      = require "character.skill.playerskill"
    DlgUIMain_Combat = require "ui.dlguimain_combat"
    charactermanager  = require "character.charactermanager"
    network.add_listeners({
        {"lx.gs.skill.msg.SInfo", onmsg_SInfo},
        {"lx.gs.skill.msg.SChangeEquipActiveSkill", onmsg_SChangeEquipActiveSkill},
        {"lx.gs.skill.msg.SUpgradeSkill", onmsg_SUpgradeSkill},
        {"lx.gs.skill.msg.SEvolveSkill", onmsg_SEvolveSkill},
        {"lx.gs.skill.msg.SError", onmsg_SError},
    },"roleskill")

    gameevent.evt_system_message:add("logout",Logout)
end



local function Reset()
    RoleSkillInfo:Reset()
end

local function GetRoleSkill(id)
    return PlayerRole:Instance().PlayerSkill:GetPlayerSkill(id)
end

local function GetRoleSkillByIndex(index)
    return PlayerRole:Instance().PlayerSkill:GetPlayerSkillByIndex(index)
end

local function RefreshMoney()
    if uimanager.needrefresh(tabskill) then
        uimanager.call(tabskill,"RefreshMoney")
    end
end

local function ShowRedDot(skillinfo)
    if skillinfo.actived then
        local skill = skillinfo:GetSkill()
        local level = skillinfo.level
        if skill:IsMaxLevel(level) then
            return false
        elseif skill:CanUpgrade(level) then
            if CheckData(skill:GetSkillLvlupData(level+1),false) then
                return true
            end
        elseif skill:CanEvolve(level) then
            if CheckData(skill:GetEvolveSkill():GetSkillLvlupData(1),false) then
                return true
            end
        end
    end
    return false
end


local function UnRead()
    if RoleSkillInfo == nil then
        return false
    end
    local AllSkills       = RoleSkillInfo:GetAllSkills()
    if AllSkills then
       local index = 0
       for _,skillinfo in pairs(AllSkills) do
            if ShowRedDot(skillinfo) then
                return true
            end
        end
    end

    return false
end

return{
    init                   = init,
    RefreshMoney           = RefreshMoney,
    GetRoleSkillByIndex    = GetRoleSkillByIndex,
    GetRoleSkill           = GetRoleSkill,

    GetRoleSkillInfo       = GetRoleSkillInfo,

    UpgradeSkill           = UpgradeSkill,
    EvolveSkill            = EvolveSkill,
    ChangeEquipActiveSkill = ChangeEquipActiveSkill,
    SetTalismanSkillId     = SetTalismanSkillId,
    UnRead                 = UnRead,
    ShowRedDot             = ShowRedDot,
    RefreshTempEquipedSkills = RefreshTempEquipedSkills,
    RefreshEquipedSkills   = RefreshEquipedSkills,
    RefreshTransformSkills = RefreshTransformSkills,
    GetAmuletLevel = GetAmuletLevel,
    GetAmuletLabel = GetAmuletLabel,
    ResetTalismanCD = ResetTalismanCD,

}
