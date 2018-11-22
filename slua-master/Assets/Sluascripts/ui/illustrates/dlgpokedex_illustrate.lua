local print,printt,unpack       = print,printt,unpack
local ConfigManager             = require"cfg.configmanager"
local PetManager                = require"character.pet.petmanager"
local EventHelper               = UIEventListenerHelper
local uimanager                 = require"uimanager"
local name,gameObject,fields
local pet
local cfgSkill
local petSkillInfo
local cfgPetDesc

local function destroy()

end

local function hide()

end

local function refresh()

end

local function ShowASkill(skillid)
    local skillInfo = cfgSkill[skillid]
    if not skillInfo then return end
    local item = fields.UIList_Award:AddListItem()
    item.Controls["UILabel_SkillDese"].text = string.format(LocalString.PartnerText.IllustrateSkillIntro,skillInfo.name,skillInfo.introduction)
end

local function ShowSkills()
    for idx,skillid in ipairs(petSkillInfo.skilllist) do
        if idx > 1 then
            ShowASkill(skillid)
        end
    end
    for _,skillid in ipairs(petSkillInfo.awakeskill) do
        ShowASkill(skillid)
    end
end

local function show(params)
    gameObject.transform.localPosition = Vector3.forward * -1000
    pet = params
    cfgSkill = ConfigManager.getConfig("skilldmg")
    cfgPetDesc = ConfigManager.getConfigData("petdescribe",pet.ConfigId)
    petSkillInfo = ConfigManager.getConfigData("petskill",pet.ConfigId)
    fields.UILabel_RoleDesc.text = cfgPetDesc.describe
    fields.UILabel_RoleName.text = pet.ConfigData.name
	print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
	print(PetManager.GetHalfBodyTexture(pet.ConfigId))
    fields.UITexture_Role:SetIconTexture(PetManager.GetHalfBodyTexture(pet.ConfigId))
    ShowSkills()
end

local function update()

end

local function init(params)
    name,gameObject,fields = unpack(params)

    EventHelper.SetClick(fields.UIButton_Close,function()
        uimanager.hide(name)
    end)
end

return {
    destroy         = destroy,
    hide            = hide,
    refresh         = refresh,
    show            = show,
    update          = update,
    init            = init ,
}
