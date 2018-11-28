local print             = print
local require           = require
local Define            = require "define"
local Pet               = require"character.pet.pet"
local Player            = require"character.player"
local SimplifiedPet     = require"character.simplifiedpet"
local SimplifiedPlayer     = require"character.simplifiedplayer"
local CameraManager     = require"cameramanager"
local mathutils         = require"common.mathutils"
local SceneManager      = require"scenemanager"
local RoleSkill         = require"character.skill.roleskill"


local function AssignmentPlayerCommon(player,msg)
	
    player.m_outDated   = false
    player:ChangeTitle(msg.titleid)
    player.m_Camp       = msg.fightercommon.camp
    player.m_Name       = msg.name
   -- printyellow("player.camp",player.m_Name,player.m_Camp)
    player.m_VipLevel   = msg.viplevel
    player:ChangeLevel(msg.level)
    player.m_MountType  = msg.ridestatus
    player.m_MountId    = msg.rideid
    player.m_ServerId   = msg.serverid
    player.m_FamilyName = msg.familyname

    player:ClearEffect()
    for i,v in pairs(msg.effects) do
        player:AddEffect(v)
    end

    player:ChangeAttr(msg.fightercommon.attrs)
    --prologue
    local PrologueManager = require"prologue.prologuemanager"
    if PrologueManager.IsInPrologue() and player:IsRole() and msg.fightercommon and msg.fightercommon.skills then
        RoleSkill.RefreshTempEquipedSkills(msg.fightercommon.skills, PrologueManager.GetSkillOrder(msg.profession))
        local autoai = require "character.ai.autoai"
        autoai.InitPrologueSkills()
    end
	
end

local function UpdatePlayer(player,msg)
    player:ChangeArmour(msg.dressid,msg.equips)
    player:LoadWeapon(msg.equips)
    local mpos = msg.fightercommon.position
    local newPos = Vector3(mpos.x, mpos.y, 0)
    local dist = mathutils.DistanceOfXoY(newPos,player:GetRefPos())
    if (dist > 1*SCALE_SPEED or SceneManager.LoadedEctypeMap()) and player:IsRole() then
        printyellow("reset position & rotation")
        player:SetPos(Vector3(msg.fightercommon.position.x, msg.fightercommon.position.y, 0))
        player:SetEulerAngle(msg.fightercommon.orient)
    end
    player:ChangePKState(msg.pkstate)

    AssignmentPlayerCommon(player,msg)
    return player
end

local function CreatePlayer(msg,bSimplified)
    local CharacterManager = require"character.charactermanager"
    local player = bSimplified and SimplifiedPlayer:new(msg) or Player:new()
                                   
    AssignmentPlayerCommon(player,msg)
    player.m_PKState = msg.pkstate
    player:RegisterOnLoaded(function()
        player:SetPos(Vector3(msg.fightercommon.position.x, msg.fightercommon.position.y, 0))
        player:SetEulerAngle(msg.fightercommon.orient)
        player:ChangePKState(msg.pkstate)
        if CharacterManager.HidingRoles() then
            player:Hide()
        elseif CharacterManager.IsHidingHpBar() then
            player:HideHeadInfo()
        end
    end)
    player:init(msg.roleid,msg.profession,msg.gender,true,msg.dressid,msg.equips)
    CharacterManager.AddCharacter(msg.roleid,player,not bSimplified)
    return player
end


local function AssignmentPetCommon(pet,msg,master)
    pet:ChangeAttr(msg.fightercommon.attrs)
    if master then
        pet:ChangePKState(master.m_PKState)
    end
    pet.m_outDated = false
    pet.m_Camp = msg.fightercommon.camp
    pet.m_Level = msg.level
    pet.m_StarLevel = msg.starlevel
    pet.m_AwakeLevel = msg.awakelevel
    pet.m_SkinId = msg.skinid
    pet.m_IsBorn = msg.fightercommon.isborn
    

end


local function UpdatePet(pet,msg,master)
    AssignmentPetCommon(pet,msg,master)
    return pet
end

local function CreatePet(msg,bSimplified,master)
    local CharacterManager = require"character.charactermanager"
    local pet = bSimplified and SimplifiedPet:new(msg) or Pet:new(msg.agentid,msg.petkey,msg.owenrid)
    AssignmentPetCommon(pet,msg,master)
    pet:RegisterOnLoaded(function()
        --printyellow("aaaa")
        if CharacterManager.HidingRoles() then
            pet:Hide()
        elseif CharacterManager.IsHidingHpBar() then
            pet:HideHeadInfo()
        end
    end)
    pet:init(msg.skinid)
    CharacterManager.AddCharacter(msg.agentid,pet)
    return pet
end


return {
    UpdatePlayer    = UpdatePlayer,
    CreatePlayer    = CreatePlayer,
	UpdatePet       = UpdatePet,
    CreatePet       = CreatePet,
}
