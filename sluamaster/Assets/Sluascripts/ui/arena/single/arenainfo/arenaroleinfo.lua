local ItemManager = require("item.itemmanager")
local PetManager    = require("character.pet.petmanager")

local ArenaPetInfo = Class:new()

function ArenaPetInfo:__new(petkey)
	self.m_Id = petkey
	self.m_Item = ItemManager.CreateItemBaseById(petkey,nil,1)
	self.m_Quality = PetManager.GetQuality(self.m_Id)
	self.m_Icon = PetManager.GetHeadIcon(self.m_Id)
end

function ArenaPetInfo:GetHeadIcon()
	return self.m_Icon
end
function ArenaPetInfo:GetQuality()
	return self.m_Quality
end
-------------------------------------------------------------------------------------
--角色战斗配置信息
--竞技场角色信息类
local ArenaRoleInfo = Class:new()

function ArenaRoleInfo:__new(msg)
	self.m_Id = 0
	self.m_Rank = 0				--排名
	self.m_Profession = 0
	self.m_Name = "Name"
	self.m_Level = 0
	self.m_Power 				= 0
	self.m_Gender = 0
	self.m_VipLevel = 0
	self.m_ServerRoleInfo = nil
	self.m_Pets = {}
    if msg then
        self:SetBaseInfo(msg)
	end
end
--[[
<variable name="roleid" type="long"/>
<variable name="name" type="string"/>

<variable name="profession" type="int"/>
<variable name="gender" type="int"/>

<variable name="level" type="int" comment="级别"/>
<variable name="viplevel" type="int" comment="vip等级"/>
<variable name="equips" type="list" value="lx.gs.role.msg.EquipBrief"/>
<variable name="dressid" type="int"/>
<variable name="combatpower" type="int"/>
]]

function ArenaRoleInfo:SetBaseInfo(msg)
	local petsInfo = msg.pets
	self.m_Id = msg.roleinfo.roleid
	self.m_Rank = msg.rank
	self.m_Name = msg.roleinfo.name
	self.m_Level = msg.roleinfo.level
	self.m_Profession = msg.roleinfo.profession
	self.m_Power = msg.roleinfo.combatpower
	self.m_Gender = msg.roleinfo.gender
	self.m_VipLevel = msg.roleinfo.viplevel

	self.m_DressId = msg.roleinfo.dressid
	self.m_Equips = msg.roleinfo.equips

	self.m_ServerRoleInfo = msg.roleinfo

	for i,k in ipairs(msg.pets) do
		local pet = ArenaPetInfo:new(k.petkey)
		--ItemManager.CreateItemBaseById(k.petkey,nil,1)
		table.insert(self.m_Pets,pet)
	end
end



return ArenaRoleInfo
