local ItemBase 		= require("item.itembase")
local ItemEnum 		= require("item.itemenum")
local ConfigManager = require("cfg.configmanager")
local CharacterSkillInfo = require"character.skill.characterskillinfo"

local Pet = { }
setmetatable( Pet, { __index = ItemBase } )

function Pet:GetDetailTypeName()
    return LocalString.PartnerText.Type
end
--碰撞半径
function Pet:GetBodyRadius()
    return self.ConfigData.bodyradius
end
--基础模型路径
function Pet:GetModelPath()
    return self.ConfigData.modelpath
end
--时装模型路径
function Pet:GetFashionPath()
    return self.ConfigData.fashionpath
end
--伙伴品质颜色
function Pet:GetQuality()
    return self.ConfigData.basiccolor
end
--伙伴品质颜色
function Pet:GetBasicQuality()
    return self.ConfigData.quality
end
--伙伴携带的品阶经验值
function Pet:GetQualityExp()
    return self.ConfigData.qualityexp
end
--成长率列表
function Pet:GetMatureRateList()
    return self.ConfigData.matureratelist
end
--转换率列表
function Pet:GetTransferRateList()
    return self.ConfigData.transferratelist
end
--伙伴的级别
function Pet:GetPetLevel()
    return self.PetLevel or 1
end
--伙伴的星阶
function Pet:GetPetStageStar()
    return self.PetStageStar
end
--
function Pet:GetPetSkinId()
    return self.PetSkinId
end
--觉醒的等级
function Pet:GetWakeLevel()
    return self.WakeLevel
end
--伙伴的技能信息
function Pet:GetSkills()
    return self.Skills
end
--缘分
function Pet:GetKarma()
    return self.Karma
end
--觉醒的id列表
function Pet:GetWakeIds()
    return self.WakeIds
end
--天赋列表
function Pet:GetTalents()
    return self.Talents
end
--伙伴属性值
function Pet:GetPetAttrInfo()
    return self.PetAttrInfo
end
--伙伴经验值
function Pet:GetExp()
    return self.Exp
end
--星阶的经验值
function Pet:GetStageStarExp()
    return self.StageStarExp
end
--伙伴的状态，0为普通背包物品，1为上阵中
function Pet:GetStatus()
    return self.Status
end
---- 获得许愿状态(true or false)
--function Pet:GetWishStatus()
--    return self.IsWhishing
--end
---- 设置许愿状态(true or false)
--function Pet:SetWishStatus(isWishing)
--    self.IsWhishing = isWishing
--end
--最近一次的洗练结果
function Pet:GetLastWashRecord()
    return self.LastWashRecord
end
--激活的法宝信息
function Pet:GetActiveTalismanInfo()
    return self.ActiveTalismanInfo
end
--购买过的皮肤id列表
function Pet:GetBuyedSkins()
    return self.BuyedSkins
end

function Pet:GetHeadIcon()
    return self.ModelData.headicon
end

function Pet:GetColorName()
    --return self.ConfigData.name
    -- printyellow("LocalString.PartnerText.NameColorPrefix[self.ConfigData.basiccolor]",LocalString.PartnerText.NameColorPrefix[self.ConfigData.basiccolor])
    -- printyellow("self.ConfigData.name",self.ConfigData.name)
    -- printyellow("")
    return LocalString.PartnerText.NameColorPrefix[self.ConfigData.basiccolor] .. self.ConfigData.name .. LocalString.PartnerText.ColorSuffix
end
-----------------------------------------------------------------------------
--具体类型参看服务器协议里的定义
function Pet:LoadFromServerMsg(id,serverMsg,NewPet)

    self.ID                  = serverMsg.petid
    self.PetSkin             = serverMsg.activeskinid
    self.PetLevel            = serverMsg.level
    self.PetExp              = serverMsg.exp
    self.PetStageStar        = serverMsg.starlevel
    self.PetAwakeLevel       = serverMsg.awakelevel
    self.PetAttrs            = serverMsg.attrs
    self.PetAwardAwake       = serverMsg.activeawake
	self.currvalues          = serverMsg.currvalues
	self.maxvalues           = serverMsg.maxvalues
    self.PetAwardStar = -1
    for _,v in pairs(serverMsg.activestar) do
        self.PetAwardStar = self.PetAwardStar<v and v or self.PetAwardStar
    end
    self.PetSkinList         = {}
    if serverMsg.skinidlist then
        for _,skinid in pairs(serverMsg.skinidlist) do
            self.PetSkinList[skinid] = false
        end
    end
    self.LastWashRecord      = {}
    self.PetPower            = serverMsg.combatpower
    self.NewPet              = NewPet or false
    self.PetSkills           = serverMsg.skills
    self.PetCombatPower      = serverMsg.combatpower
    if id and self.ID~=0 then
        local skills = serverMsg.skills or {}
        local skilllist = {}
        for i,v in pairs(skills) do
            local tb = {}
            tb.skillid = i
            tb.level = v
            table.insert(skilllist,tb)
        end
        self.PetCharacterSkillInfo = CharacterSkillInfo:new()
        local cfgPetSkill = ConfigManager.getConfigData("petskill",id)
        local cfgskilllist = {} --  cfgPetSkill and cfgPetSkill.skilllist or {}
        if cfgPetSkill then
            for _,id in pairs(cfgPetSkill.skilllist) do
                table.insert(cfgskilllist,id)
            end
            for _,id in pairs(cfgPetSkill.awakeskill) do
                table.insert(cfgskilllist,id)
            end
        end
        for _,skill in pairs(skilllist) do
            local id = skill.skillid
            local intheconfig = false
            for _,vv in pairs(cfgskilllist) do
                if vv == id then
                    intheconfig = true
                    break
                end
            end
            if not intheconfig then
                table.insert(cfgskilllist,id)
            end
        end
        self.PetCharacterSkillInfo:init(cfgskilllist,skilllist)
    end

    self.BagPos = serverMsg.pos or 0
end
-- 实例化
function Pet:CreateInstance(configId, config, detailType, detailType2, serverMsg, number)

	local pet = {
       ConfigId    = configId,
       BaseType    = ItemEnum.ItemBaseType.Pet,
	   DetailType  = detailType,
	   DetailType2 = detailType2,
	   ConfigData  = config,
	   Number      = number or 1,
	}
	
    setmetatable(pet, { __index = self })

	if serverMsg ~= nil then
		pet:LoadFromServerMsg(configId,serverMsg)
	end
    pet.ModelData = ConfigManager.getConfigData("model",pet.ConfigData.modelname)
	--self.ConfigData.quality = self.ConfigData.basiccolor
	return pet
end

return Pet
