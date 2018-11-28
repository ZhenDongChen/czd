local unpack = unpack
local table = table 
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local dlgdialogbox = require("ui.common.dlgdialogbox_input")
local RoleSkill  = require "character.skill.roleskill"
local SettingManager = require "character.settingmanager"
local PlayerRole = require "character.playerrole"
local fields
local name
local gameObject
local SettingAutoFight = {}
local dlgFields
local AllSkills = {}
--local isSkillChange = true


local function refresh(params)
end

local function update()
end



--local function IsSkillChange()
--	return isSkillChange 
--end

--local function SetSkillChange(b)
--	printyellow("setskillchange",b)
--	isSkillChange = b
--end

local function SetTalismanSkillIcon()
	local listItem = fields.UIList_GridConjure:GetItemByIndex(6)
	local SettingAutoFight = SettingManager.GetSettingAutoFight()
	if RoleSkill.GetRoleSkillByIndex(-1) then
		listItem.Controls["UITexture_skill"]:SetIconTexture(RoleSkill.GetRoleSkillByIndex(-1):GetFirstSkill():GetSkillIcon())
		listItem.Checkbox.value	=  SettingAutoFight["Skill7"]
		return true
	else
--		listItem.Controls["UITexture_skill"]:SetIconTexture("skill90006")
--		local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
--		listItem.Controls["UITexture_skill"].shader= inactiveShader
--		printyellow("SetTalismanSkillIcon false")
		listItem.Checkbox.value = false
	end
	return false
end



local function InitAllSkills()
	local AllSkills =  RoleSkill.GetRoleSkillInfo():GetAllSkills()
	local equipdSkillTable = RoleSkill.GetRoleSkillInfo().EquipedSkills ---装备技能
	local index = 0
	local tbHasSkill = {}
	for i,skillinfo in pairs(AllSkills) do 
		for j, equipdSkill in pairs(equipdSkillTable) do 
			if equipdSkill == skillinfo.skillid then 
				if  not skillinfo:GetSkill():IsPassive() then 
					local listItem = fields.UIList_GridConjure:GetItemByIndex(index)
					if skillinfo.actived then
						listItem.Controls["UITexture_skill"]:SetIconTexture(skillinfo:GetSkill():GetSkillIcon())
					else
						listItem.Controls["UITexture_skill"]:SetIconTexture(skillinfo:GetSkill():GetSkillIcon())
						local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
						listItem.Controls["UITexture_skill"].shader= inactiveShader
					end
					tbHasSkill[index] = true
					index = index + 1
				end 
			end
		end
	end 
	tbHasSkill[6] = SetTalismanSkillIcon()
	for i=0, 7, 1 do
		local listItem = fields.UIList_GridConjure:GetItemByIndex(i)
		if tbHasSkill[i] then
			listItem.Checkbox.enabled = true
			listItem.Controls["UISprite_Selected"].gameObject:SetActive(true);
			--listItem.gameObject:GetComponent("UIToggle").enabled = true
		else
			listItem.Checkbox.value = false
			listItem.Checkbox.enabled = false
			listItem.Controls["UISprite_Selected"].gameObject:SetActive(false);
			--listItem.gameObject:GetComponent("UIToggle").enabled = false
		end
	end
end



local function ShowPickInfo(dlgfields)
	
--	dlgfields.UIGroup_Button_2.gameObject:SetActive(false)
	dlgfields.UILabel_Title.text = LocalString.Setting_AutoFight_PickUp
	dlgfields.UIGroup_Button_Mid.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_Norm.gameObject:SetActive(false)
	dlgfields.UIGroup_Resource.gameObject:SetActive(false)
	dlgfields.UIInput_Input_Large.gameObject:SetActive(false)
--	dlgfields.UIGroup_Select.gameObject:SetActive(true)
	SettingAutoFight = SettingManager.GetSettingAutoFight()
	dlgfields.UIToggle_Green.value  = SettingAutoFight["Green"] 
	dlgfields.UIToggle_Blue.value   = SettingAutoFight["Blue"] 
	dlgfields.UIToggle_Purple.value = SettingAutoFight["Purple"] 
	dlgfields.UIToggle_Orange.value = SettingAutoFight["Orange"]
	dlgfields.UIToggle_Red.value    = SettingAutoFight["Red"]
	dlgfields.UIToggle_White.value  = SettingAutoFight["White"]  
	
end

local function show(params)
	InitAllSkills()
	SettingAutoFight = SettingManager.GetSettingAutoFight()

	fields.UIToggle_Normal.value = 	SettingAutoFight["Normal_Monster"]
	fields.UIToggle_Elite.value  = 	SettingAutoFight["Elite_Monster"] 
	fields.UIToggle_BOSS.value   = 	SettingAutoFight["Boss_Monster"]  
	fields.UIGroup_HP.gameObject:GetComponent(UISlider).value   = SettingAutoFight["HP"]   
	fields.UIGroup_MP.gameObject:GetComponent(UISlider).value   = SettingAutoFight["MP"]   
	fields.UISlider_Range.value                        = SettingAutoFight["Range"]
	local skills = fields.UIList_GridConjure
	skills:GetItemByIndex(0).Checkbox.value	=  SettingAutoFight["Skill1"]
	skills:GetItemByIndex(1).Checkbox.value	=  SettingAutoFight["Skill2"]
	skills:GetItemByIndex(2).Checkbox.value	=  SettingAutoFight["Skill3"]
	skills:GetItemByIndex(3).Checkbox.value	=  SettingAutoFight["Skill4"]
	skills:GetItemByIndex(4).Checkbox.value	=  SettingAutoFight["Skill5"]
	skills:GetItemByIndex(5).Checkbox.value	=  SettingAutoFight["Skill6"]
	if RoleSkill.GetRoleSkillByIndex(-1) then
		skills:GetItemByIndex(6).Checkbox.value	=  SettingAutoFight["Skill7"]
	end 
	skills:GetItemByIndex(7).Checkbox.value =  false
	

end



local function SetMonster()
	SettingAutoFight["Normal_Monster"] =fields.UIToggle_Normal.value
	SettingAutoFight["Elite_Monster"]  =fields.UIToggle_Elite.value
	SettingAutoFight["Boss_Monster"]   =fields.UIToggle_BOSS.value
end

local function SetSlider()

--	printyellow("slider",slider)
--	printyellow("range.value",fields.UISlider_Range.value)
	
	SettingAutoFight["HP"]   =fields.UIGroup_HP.gameObject:GetComponent(UISlider).value
	SettingAutoFight["MP"]   =fields.UIGroup_MP.gameObject:GetComponent(UISlider).value
	SettingAutoFight["Range"]=fields.UISlider_Range.value
end

local function SetSkill()
	local skills = fields.UIList_GridConjure
	SettingAutoFight["Skill1"]=skills:GetItemByIndex(0).Checkbox.value
	SettingAutoFight["Skill2"]=skills:GetItemByIndex(1).Checkbox.value
	SettingAutoFight["Skill3"]=skills:GetItemByIndex(2).Checkbox.value
	SettingAutoFight["Skill4"]=skills:GetItemByIndex(3).Checkbox.value
	SettingAutoFight["Skill5"]=skills:GetItemByIndex(4).Checkbox.value
	SettingAutoFight["Skill6"]=skills:GetItemByIndex(5).Checkbox.value
	if RoleSkill.GetRoleSkillByIndex(-1) then
		SettingAutoFight["Skill7"]=skills:GetItemByIndex(6).Checkbox.value
	end
	SettingAutoFight["Skill8"]=false
end

local function SetPickUp(params)
	if params  then
		SettingAutoFight["White"]  =  params.White
		SettingAutoFight["Green"]  =  params.Green
		SettingAutoFight["Blue"]   =  params.Blue
		SettingAutoFight["Purple"] =  params.Purple
		SettingAutoFight["Orange"] =  params.Orange
		SettingAutoFight["Red"]    =  params.Red
	end
	
end
	
local function InitSettingAutoFight()
	
	SetSlider()
    SetMonster()
	SetSkill()
	--SetPickUp(dlgdialogbox.GetSettingPickUp())
end

local function GetSettingAutoFight()
	return SettingAutoFight
end

local function hide()
	InitSettingAutoFight()                               --����table

	SettingManager.SetSettingAutoFight(SettingAutoFight) --�رպ�����Э��
	SettingManager.SendCSetConfigureAutoFight()
	SettingManager.SetRedDotSetting(false)
--	local GameAI = require"character.ai.gameai"
--	GameAI.SetSkillChange(true)

    local autoai = require "character.ai.autoai"
    autoai.InitSkills()
end

local function destroy()
	
end
function init(params)
	name, gameObject, fields = unpack(params)
	--InitSettingAutoFight()

    --EventHelper.SetClick(fields.UIButton_Objectset,function()
    --    uimanager.show("common.dlgdialogbox_input",{type = 4,callBackFunc = ShowPickInfo})
    --end) 
end

local function uishowtype()
	return UIShowType.Refresh
end

return  {
	
	init = init,
	refresh = refresh,
	hide = hide,
	update = update,
	show = show,
	destory = destory,
	uishowtype = uishowtype,
	GetAllSkillIds = GetAllSkillIds,
--	IsSkillChange = IsSkillChange,
--	SetSkillChange = SetSkillChange,

	
}