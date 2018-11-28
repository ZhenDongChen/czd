
local defineenum    = require "defineenum"
local uimanager     = require"uimanager"
local ItemPet       = require"item.pet"
local ConfigManager = require"cfg.configmanager"
local network       = require"network"
local Partner       = require"character.pet.pet"
local gameevent     = require"gameevent"
local ItemManager   = require"item.itemmanager"
local CheckCmd      = require"common.checkcmd"
local cfgModel
local lastFollowPetModelId = nil
--local bit           = require"bit"
local CharacterManager

local CharacterType = defineenum.CharacterType
local EctypeManager
local dlguimain_partner
local BagManager
local StatusText

local i_AttainedPets -- id index
local p_AttainedPets -- sorted list
local i_UnAttainedPets
local p_UnAttainedPets
local i_PetFragments
local ActivePet
local battlePets -- list
local fieldPets
local equipCD
local deadMap -- modelid index
local UpdateFieldPetsNextFrame

--cd
local cfgEquipCD
local cfgDeadCD
local CfgBasicStatus
local CfgExp
local CfgStageStar
local CfgWash
local CfgAwake
local CfgTalent
local CfgSkill
local CfgSkin
local CfgKarma
local CfgConfig
local CfgFragment

local effectAwake = 0x01
local effectStage = 0x02
local effectStar  = 0x04
local effectsToShow

local refreshUIs = {
    refreshAssist={},
    refreshChoose={},
    refreshInformation={},
    refreshKarma={},
    refreshWash={},
    refreshDlgPartner={},
    refreshStrength={},
    refreshLoadState={},
    refreshSkins = {},
}

local PetState = enum{
    "EQUIPED=1",
    "ACTIVE=2",
    "DEAD=3",
    "NOPARTNER=4",
}

local function UnMarshal(slot)
    local petInfo = Octets:new(slot)
    local tb = {}
    tb = petInfo:pop_lx_gs_pet_msg_Pet()
    return tb
end

local InfoAttr = {
    {key="hp",ratekey="hpmaturerate",idx=cfg.fight.AttrId.HP_FULL_VALUE,},
    {key="mp",ratekey="mpmaturerate",idx=cfg.fight.AttrId.MP_FULL_VALUE,},
    {key="attackvaluemin",ratekey="minatkmaturerate",idx=cfg.fight.AttrId.ATTACK_VALUE,},
    {key="defence",ratekey="defmaturerate",idx=cfg.fight.AttrId.DEFENCE,},
    {key="hitrate",ratekey="hitmaturerate",idx=cfg.fight.AttrId.HIT_RATE,},
    {key="hitresistrate",ratekey="hitresistmaturerate",idx=cfg.fight.AttrId.HIT_RESIST_RATE,},
}

local BaseAttr = {
    {key="hp",ratekey="hpmaturerate",idx=cfg.fight.AttrId.HP_FULL_VALUE,},
    {key="mp",ratekey="mpmaturerate",idx=cfg.fight.AttrId.MP_FULL_VALUE,},
    {key="attackvaluemin",ratekey="minatkmaturerate",idx=cfg.fight.AttrId.ATTACK_VALUE_MIN,},
    {key="attackvaluemax",ratekey="maxatkmaturerate",idx=cfg.fight.AttrId.ATTACK_VALUE_MAX,},
    {key="defence",ratekey="defmaturerate",idx=cfg.fight.AttrId.DEFENCE,},
    {key="hitrate",ratekey="hitmaturerate",idx=cfg.fight.AttrId.HIT_RATE,},
    {key="hitresistrate",ratekey="hitresistmaturerate",idx=cfg.fight.AttrId.HIT_RESIST_RATE,},
}
local ExtendAttr = {
    {key="critrate",idx=cfg.fight.AttrId.CRIT_RATE,},
    {key="critvalue",idx=cfg.fight.AttrId.CRIT_VALUE,},
    {key="critresistrate",idx=cfg.fight.AttrId.CRIT_RESIST_RATE,},
    {key="critresistvalue",idx=cfg.fight.AttrId.CRIT_RESIST_VALUE,},
    {key="excellentrate",idx=cfg.fight.AttrId.EXCELLENT_RATE,},
    {key="excellentvalue",idx=cfg.fight.AttrId.EXCELLENT_VALUE,},
    {key="excellentresistrate",idx=cfg.fight.AttrId.EXCELLENT_RESIST_RATE,},
    {key="excellentresistvalue",idx=cfg.fight.AttrId.EXCELLENT_RESIST_VALUE,},
    {key="lucky",idx=cfg.fight.AttrId.LUCKY_VALUE,},
    {key="attackmultirate",idx=cfg.fight.AttrId.ATTACK_MULTI_RATE,},
    {key="defencemultirate",idx=cfg.fight.AttrId.DEFENCE_MUTLI_RATE,},
    {key="abnormalresistrate",idx=cfg.fight.AttrId.ABNORMAL_RESIST_RATE},
    {key="movespeed",idx=cfg.fight.AttrId.MOVE_SPEED,},
}

local function GetKarmaLevelByRequireLevel(karma,level)
    for lv,v in ipairs(karma.prop) do
        if v.level == level then return lv end
    end
    return 0
end

local function GetStar(level)
    return math.floor((level-1)/10)
end

local function GetStage(level)
    return (level-1)%10 + 1
end

local function GetKarmas(pet)
    local ret = {}
    local petKarmas =  CfgKarma[pet.ConfigId].petkarmas
    for _,karma in pairs(petKarmas) do
        local bestmatchlevel = 1e10
        local b = true
        for _,petkey in pairs(karma.petkeys) do
            if not i_AttainedPets[petkey] then
                b = false
                break
            end
        end
        if b then
            for _,petkey in ipairs(karma.petkeys) do
                local petBestmatch = -1
                local pet = i_AttainedPets[petkey]
                for _,prop in ipairs(karma.prop) do
                    if karma.carmatype == cfg.pet.StarKarmaType.XINGJIE then
                        if pet.PetStageStar >= prop.level then
                            petBestmatch = math.max(petBestmatch,prop.level)
                        end
                    elseif karma.carmatype == cfg.pet.StarKarmaType.JUEXING then
                        if pet.PetAwakeLevel >= prop.level then
                            petBestmatch = math.max(petBestmatch,prop.level)
                        end
                    end
                end
                if petBestmatch>=0 then
                    bestmatchlevel = math.min(petBestmatch,bestmatchlevel)
                end
            end
            if bestmatchlevel<1e10 then
                local karmalevel = GetKarmaLevelByRequireLevel(karma,bestmatchlevel)
                table.insert(ret,{level=bestmatchlevel,karma=karma,karmalevel=karmalevel})
            else
                table.insert(ret,{level=-1,karma=karma,karmalevel=0})
            end
        else
            table.insert(ret,{level=-1,karma=karma,karmalevel=0})
        end
    end
    return ret
end

local function GetStageStarText(stagestarlevel)
    local star = GetStar(stagestarlevel)
    local stage = GetStage(stagestarlevel)
    local text = tostring(star)
    text = text .. LocalString.PartnerText.Star
    text = text .. tostring(stage)
    text = text .. LocalString.PartnerText.Stage
    return text
end


local function GetWashTotalAttributes(pet,washattrs)
    local ret = {}
    for _,attr in ipairs(BaseAttr) do
        ret[attr.idx] = pet.PetAttrs[attr.idx] + (pet.LastWashRecord[attr.idx] or 0)
    end
    return ret
end

local function GetAttributes(pet)
    return pet.PetAttrs
end

local function IsDeadPet(modelid)
    return deadMap[modelid]~=nil
end

local function IsBattlePet(modelid)
    for i=1,3 do
        local pet = battlePets[i]
        if pet then
            if pet.ConfigId == modelid then
                return true
            end
        else
            break
        end
    end
    return false
end

local function IsShowedSkill(modelid,skillid)
    local currSkillInfo = CfgSkill[modelid]
        if currSkillInfo.skilllist[1] and
        currSkillInfo.skilllist[1] == skillid then
            return false
        end
    return true
end

local function GetBattlePet(idx)
    return battlePets[i]
end

local function GetBattlePetIndex(modelid)
    for i=1,3 do
        local pet = battlePets[i]
        if not pet then break end
        if pet.ConfigId == modelid then
            return i
        end
    end
    return 0
end

local function GetAttainedPetIndex(modelid)
    for idx,pet in ipairs(p_AttainedPets) do
        if pet.ConfigId == modelid then
            return idx
        end
    end
    return -1
end

local function GetRightPet(pet)
    local idx = GetAttainedPetIndex(pet.ConfigId)
    if idx == #p_AttainedPets then
        return p_AttainedPets[1]
    else
        return p_AttainedPets[idx+1]
    end
end

local function GetLeftPet(pet)
    local idx = GetAttainedPetIndex(pet.ConfigId)
    if idx == 1 then
        return p_AttainedPets[#p_AttainedPets]
    else
        return p_AttainedPets[idx-1]
    end
end

local function GetNextKarmaLevel(karma,level)
    local ret = 1e10
    for _,v in pairs(karma.prop) do
        if v.level > level then
            ret = math.min(ret,v.level)
        end
    end
    return ret<1e10 and ret or nil
end


local function IsFollowingPet(idx)
    return battlePets[idx].ConfigId == ActivePet
end

local function IsFollowing(pet)
    return pet.ConfigId == ActivePet
end

local function CanLoad()
    return #battlePets < 3
end

local function HasWashed(pet)
    return getn(pet.LastWashRecord)>0
end

local function GetFragmentNum(fragmentid)
    return i_PetFragments[fragmentid] or 0
end

local function GetFragmentNumByPet(pet)

    return i_PetFragments[pet.ConfigData.fragmentid] or 0
end

-- refresh uis

local function RefreshAssist()
    if uimanager.isshow("partner.dlgpartner_assist") then
        uimanager.call("partner.dlgpartner_assist","varrefresh")
    end
end

local function RefreshChoose()
    if uimanager.hasloaded("partner.dlgpartner_attained") then
        uimanager.refresh("partner.dlgpartner_attained")
    end
    if uimanager.hasloaded("partner.dlgpartner_unattained") then
        uimanager.refresh("partner.dlgpartner_unattained")
    end
end

local function RefreshInformation()
    if uimanager.isshow("partner.dlgpartner_information") then
        uimanager.call("partner.dlgpartner_information","varrefresh")
    end
end

local function RefreshKarma()
    if uimanager.isshow("partner.dlgpartner_karma") then
        uimanager.call("partner.dlgpartner_karma","varrefresh")
    end
end

local function RefreshWash()
    if uimanager.isshow("partner.dlgpartner_xilian") then
        uimanager.call("partner.dlgpartner_xilian","varrefresh")
    end
end

local function RefreshDlgPartner()
    if uimanager.isshow("partner.dlgpartner") then
        uimanager.call("partner.dlgpartner","varrefresh")
    end
end

local function RefreshPetExp()
    if uimanager.isshow("partner.dlgpartner") then
        uimanager.call("partner.dlgpartner","RefreshLeft")
    end
end

local function RefreshStrength()
    if uimanager.isshow("partner.dlgpartner_strengthen") then
        uimanager.call("partner.dlgpartner_strengthen","varrefresh",effectsToShow)
        effectsToShow = 0
    end
end

local function RefreshLoadState(idx,b)
    if uimanager.isshow("partner.dlgpartner_assist") then
        uimanager.call("partner.dlgpartner_assist","LoadPet",{idx=idx,b=b})
    end
end

local function RefreshSkin()
    if uimanager.isshow("dlgfashion") then
        uimanager.refresh("dlgfashion")
    end
end

local function RefreshUpgradeLevel()
    if uimanager.isshow("partner.dlgpartner") then
        uimanager.call("partner.dlgpartner","RefreshLvUp")
    end
end

local function RefreshUpgradeAward(modelid)
    if uimanager.isshow("illustrates.dlgpokedex_award") then
        uimanager.refresh("illustrates.dlgpokedex_award",modelid)
    end
end

local function RefreshAwardReddot(pet,level)
    printyellow("RefreshAwardReddot",level)
    if uimanager.hasloaded("illustrates.dlgpokedex") then
        uimanager.call("illustrates.dlgpokedex","RefreshRedDot",pet)
    end
    if uimanager.hasloaded("illustrates.dlgpokedex_award") then
        printyellow("loaded dlg_award")
        uimanager.call("illustrates.dlgpokedex_award","OnAward",level)
    end
end

local function GetPetsListIndex(csvid)
    for idx,v in ipairs(p_UnAttainedPets) do
        if v.ConfigId == csvid then
            return idx
        end
    end
end

local function GetAttainedPetsListIndex(pet)
    for idx,v in ipairs(p_AttainedPets) do
        if pet.PetPower > v.PetPower then
            return idx
        elseif pet.PetPower == v.PetPower then
            if pet.ConfigData.displayorder < v.ConfigData.displayorder then
                return idx
            end
        end
    end
    return #p_AttainedPets + 1
end

local function GetUnAttainedPetsListIndex(modelid)
    for idx,pet in ipairs(p_UnAttainedPets) do
        if pet.ConfigId == modelid then
            return idx
        end
    end
    return -1
end

local function SetWashMaxValue(modelid,maxvalues,currvalues)
    local pet = i_AttainedPets[modelid]
    pet.WashMaxValues = maxvalues
    pet.WashCurrValues = currvalues
end

local function AddPet(csvid,serverMsg,newPet)
    local pet = i_UnAttainedPets[csvid]
    if not pet then return end
    pet:LoadFromServerMsg(csvid,serverMsg,newPet)
    i_UnAttainedPets[csvid] = nil
    i_AttainedPets[csvid] = pet
    table.remove(p_UnAttainedPets,GetUnAttainedPetsListIndex(csvid))
    table.insert(p_AttainedPets,GetAttainedPetsListIndex(pet),pet)
	--TODO同步洗练数据
	if serverMsg ~= nil and  pet.maxvalues == nil then
		LogError("Pet WashMaxValue is NULL please Check Client_message Pet")
	end
	if pet.maxvalues ~= nil and pet.currvalues ~= nil then
		SetWashMaxValue(pet.ConfigId,pet.maxvalues,pet.currvalues)
	end
	
    RefreshAssist()
    RefreshChoose()
end

local function onmsg_ActiveStarProp(msg)
    local modelid = msg.modelid
    local newLevel = msg.level
    local pet = i_AttainedPets[modelid]
    if pet then
        if newLevel > pet.PetAwardStar then
            pet.PetAwardStar = newLevel
            RefreshUpgradeAward(modelid)
        end
    end
    RefreshAwardReddot(pet,math.floor(newLevel/10)+1)
end

local function onmsg_ActiveAwakeProp(msg)
    local modelid = msg.modelid
    local newLevel = msg.level
    local pet = i_AttainedPets[modelid]
    if pet then
        if newLevel > pet.PetAwardAwake then
            pet.PetAwardAwake = newLevel
            RefreshUpgradeAward(modelid)
        end
    end
    RefreshAwardReddot(pet,newLevel)
end

local function onmsg_SyncPetProp(msg)
    for modelid,spet in pairs(msg.pets) do
        local pet = i_AttainedPets[spet.modelid]
        if pet then
            pet.PetAttrs = spet.attrs
            pet.PetCombatPower = spet.combatpower
        end
    end
    RefreshAssist()
end

local function IsAttainedPets(modelid)
    if i_AttainedPets then
        return i_AttainedPets[modelid]
    end
end


--local SortOrder = {
--    [cfg.item.EItemColor.PURPLE] = 1,
--    [cfg.item.EItemColor.ORANGE] = 2,
--    [cfg.item.EItemColor.RED] = 3,
--}


local function CmpByDisplayOrder(a,b)

    local CfgFragmentA   = ConfigManager.getConfigData("petfragment",a.ConfigData.fragmentid)
    local totalA         = CfgFragmentA.number
    local amountA        = GetFragmentNum(a.ConfigData.fragmentid)
    local percentA= amountA/totalA
    local qualityA
    if a.ConfigData.basiccolor == cfg.item.EItemColor.PURPLE then
        qualityA = 1
    elseif     a.ConfigData.basiccolor == cfg.item.EItemColor.ORANGE then
        qualityA = 2
    else
        qualityA = 3
    end

    local CfgFragmentB   = ConfigManager.getConfigData("petfragment",b.ConfigData.fragmentid)
    local totalB         = CfgFragmentB.number
    local amountB        = GetFragmentNum(b.ConfigData.fragmentid)
    local percentB = amountB/totalB
    local qualityB
    if b.ConfigData.basiccolor == cfg.item.EItemColor.PURPLE then
        qualityB = 1
    elseif     b.ConfigData.basiccolor == cfg.item.EItemColor.ORANGE then
        qualityB = 2
    else
        qualityB = 3
    end

    if (percentA >= 1 and percentB >=1) or (percentA < 1 and percentB <1)  then
        return qualityA >qualityB

    else
        return percentA > percentB

    end


    --return a.ConfigData.displayorder < b.ConfigData.displayorder
end

local function ResetFieldPets()
    fieldPets = {}
    for i=1,3 do
        fieldPets[i] = {}
        fieldPets[i].state = PetState.NOPARTNER
    end
end

local function GetDeadCD(equipid)
    return deadMap[equipid]
end

local function GetFieldPets()
    if UpdateFieldPetsNextFrame then
        return nil
    end
    return fieldPets
end

local function GetPetState(idx)
    return fieldPets[idx].state
end

local function UpdateFieldPets()
    ResetFieldPets()
    for idx,pet in ipairs(battlePets) do
        local fieldPet
        if ActivePet == pet.ConfigId then
            local fieldPet = CharacterManager.GetRolePet(pet.ConfigId)
            if not fieldPet then
                UpdateFieldPetsNextFrame = true
                return
            end
        end
        fieldPets[idx].fieldPet = fieldPet
        fieldPets[idx].pet = pet
        if not deadMap[pet.ConfigId] then
            if ActivePet == pet.ConfigId then
                fieldPets[idx].state = PetState.ACTIVE
            else
                fieldPets[idx].state = PetState.EQUIPED
            end
        else
            fieldPets[idx].state = PetState.DEAD
        end
    end
    UpdateFieldPetsNextFrame = false
    if uimanager.isshow("dlguimain") then
        uimanager.call("dlguimain","RefreshFieldPets")
    end
end

local function onmsg_SPetRecycle(msg)
    uimanager.ShowSingleAlertDlg{content=LocalString.PartnerText.RecycleSuccess}
    local msgNewPet = msg.newpet
    local newPet = ItemPet:CreateInstance(msgNewPet.modelid, CfgBasicStatus[msgNewPet.modelid],1,1,msgNewPet,1)
    local oldpet = i_AttainedPets[msgNewPet.modelid]
    i_AttainedPets[msgNewPet.modelid] = newPet
    for i=1,#p_AttainedPets do
        local oPet = p_AttainedPets[i]
        if oPet.ConfigId == newPet.ConfigId then
            -- printyellow("got you attained")
            p_AttainedPets[i] = newPet
            break
        end
    end
    for i=1,#battlePets do
        local oPet = battlePets[i]
        if oPet.ConfigId == newPet.ConfigId then
            battlePets[i] = newPet
            
            break
        end
    end
    UpdateFieldPets()
    if uimanager.hasloaded"dlguimain" then
        uimanager.call("dlguimain","RefreshFieldPets")
    end
    refreshUIs.refreshChoose.refreshNow = true
    uimanager.call("partner.dlgpartner","OnRecycle",newPet)
    uimanager.call("partner.dlgpartner_decomposition","OnRecycle",newPet)
end

local function UpdateBattlePets(fightpets)
    battlePets = {}
    for _,petkey in pairs(fightpets) do
        local pet = i_AttainedPets[petkey]
        table.insert(battlePets,pet)
    end
    RefreshAssist()
    UpdateFieldPets()
end

local function GetBattlePets()
    return battlePets
end

local function GetSortedAttainedPets()
    return p_AttainedPets
end

local function GetSortedUnAttainedPets()
    table.sort(p_UnAttainedPets,CmpByDisplayOrder)
    return p_UnAttainedPets
end

local function CmpSkinQuality(a,b)
    return a.info.displayorder > b.info.displayorder
end



local function SetPetSkinOld(modelid,skinid)
    local pet = i_AttainedPets[modelid]
    pet.PetSkinList[skinid] = false
    refreshUIs.refreshSkins.refreshNow = true
end

local function HaveSkin(pet,id)
    for skinid,isNew in pairs(pet.PetSkinList) do
        if id == skinid then return true end
    end
    return false
end

local function IsEquipingSkin(pet,id)
    return pet.PetSkin == id
end

local function GetAllSkins()
    local tb = {}
    for id,skininfo in pairs(CfgSkin) do
        tb[id] = {}
        tb[id].info = skininfo
        local pet = IsAttainedPets(skininfo.petid)
        if not pet then
            tb[id].state = 0
            tb[id].isNew = false
        else
            if HaveSkin(pet,id) then
                if IsEquipingSkin(pet,id) then
                    tb[id].state = 2
                else
                    tb[id].state = 1
                end
                tb[id].isNew = pet.PetSkinList[id]
            else
                tb[id].state = 0
                tb[id].isNew = false
            end
        end
    end
    local ret = {}
    for _,skin in pairs(tb) do
        table.insert(ret,skin)
    end
    table.sort(ret,CmpSkinQuality)
    return ret
end

local function GetQualityColor(pet)
    return CfgConfig.qualitycolor[pet.m_Data.basiccolor] or CfgConfig.qualitycolor[cfg.item.EItemColor.WHITE]
end

local function GetQualityColorTexture(pet)
    return CfgConfig.awaketexture_awakelevel[pet.m_AwakeLevel].backgroundtexture.qualitytexture[pet.m_Data.basiccolor] or ""
end

local function RefreshPetSkill(pet)
    local pet = CharacterManager.GetRolePet(pet.ConfigId)
    pet.SetSkills(pet.PetSkills)
end

-- onmsgs
local function onmsg_PetInfo(msg)
	print("+++++++++++onmsg_PetInfo++++++++++++")
    i_UnAttainedPets = {}
    p_UnAttainedPets = {}
    i_AttainedPets = {}
    p_AttainedPets = {}
    battlePets = {}
    for csvid,petConfig in pairs( CfgBasicStatus) do
        newPet = ItemPet:CreateInstance(csvid, CfgBasicStatus[csvid],1,1,nil,1)
        i_UnAttainedPets[csvid] = newPet
    end
    for csvid,pet in pairs(i_UnAttainedPets) do
        table.insert(p_UnAttainedPets,pet)
    end
    i_PetFragments = msg.petfragment
    table.sort(p_UnAttainedPets,CmpByDisplayOrder)
    ActivePet = msg.activemodelid
    for csvid,msg in pairs(msg.petmap) do
        AddPet(csvid,msg)
		
    end
    UpdateBattlePets(msg.fightpets)


end

local function onmsg_CallPet(msg)
    AddPet(msg.addpet.modelid,msg.addpet,true)
	uimanager.RefreshRedDot()
	
    if uimanager.isshow("partner.dlgpartner_unattained") then
        uimanager.showdialog("lottery.tabpetcall_result",msg.addpet.modelid)
    end
	
	--TODO增加获取伙伴飘字
	 if uimanager.isshow("lottery.tablottery_result") or uimanager.isshow("lottery.tablottery_partner") then
	else
		local NewGetPet = i_AttainedPets[msg.addpet.modelid]
		uimanager.ShowSyncItem(NewGetPet)
    end
	
end

local function onmsg_SyncFightPets(msg)

    UpdateBattlePets(msg.fightpets)
end

local function onmsg_SyncPetLevel(msg)
		print("+++++++++++onmsg_SyncPetLevel++++++++++++")
    local pet = i_AttainedPets[msg.modelid]
    pet.PetLevel = msg.level
    pet.PetExp = msg.exp
    refreshUIs.refreshStrength.refreshNow = true
    local idx = GetBattlePetIndex(msg.modelid)
    if idx>0 then
        uimanager.call("dlguimain","RefreshPetLevel",{level=msg.level,idx=idx})
    end
    UpdateFieldPetsNextFrame = true
    RefreshUpgradeLevel()
end

local function onmsg_UpgradePetStar(msg)
    local pet = i_AttainedPets[msg.modelid]
    local oldStar = GetStar(pet.PetStageStar)
    local newStar = GetStar(msg.starlevel)
    if newStar>oldStar then
        effectsToShow = bit.bor(effectsToShow,effectStar)
    else

        local oldStage = GetStage(pet.PetStageStar)
        local newStage = GetStage(msg.starlevel)
        if newStage > oldStage then
            effectsToShow = bit.bor(effectsToShow,effectStage)
        end
    end
    pet.PetStageStar = msg.starlevel
    refreshUIs.refreshDlgPartner.refreshNow = true
    refreshUIs.refreshStrength.refreshNow = true
end

local function onmsg_UpgradePetAwake(msg)
    local pet = i_AttainedPets[msg.modelid]
    pet.PetAwakeLevel = msg.awakelevel
    effectsToShow = bit.bor(effectsToShow,effectAwake)
    uimanager.show("dlgtweenset",{tweenfield="UIPlayTweens_PartnerAwake"})
    refreshUIs.refreshDlgPartner.refreshNow = true
    refreshUIs.refreshStrength.refreshNow = true
end

local function onmsg_WashPet(msg)
    local pet = i_AttainedPets[msg.modelid]
    pet.LastWashRecord = msg.deltavalues
    uimanager.show("dlgtweenset",{tweenfield="UIPlayTweens_PartnerWash"})
    refreshUIs.refreshWash.refreshNow = true
end

local function onmsg_WashPetCancel(msg)
    local pet = i_AttainedPets[msg.modelid]
    pet.LastWashRecord = {}
    refreshUIs.refreshWash.refreshNow = true
end

local function onmsg_SyncPetSkin(msg)
    local pet = i_AttainedPets[msg.modelid]
    pet.PetSkin = msg.skinid
    refreshUIs.refreshSkins.refreshNow = true
end

local function onmsg_BuyPetSin(msg)
    local pet = i_AttainedPets[msg.modelid]
    pet.PetSkinList[msg.addskinid] = true
    refreshUIs.refreshSkins.refreshNow = true
end

local function onmsg_UpgradePetSkill(msg)
    local pet = i_AttainedPets[msg.modelid]
    if pet.PetSkills[msg.skillid] then
        pet.PetSkills[msg.skillid] = msg.level
        pet.PetCharacterSkillInfo:UpgradeSkill(msg.skillid,msg.level)
        pet.NewLevelSkill = msg.skillid
    else
        pet.PetSkills[msg.skillid] = msg.level
        pet.PetCharacterSkillInfo:ActiveSkill(msg.skillid,msg.level)
    end
    uimanager.show("dlgtweenset",{tweenfield="UIPlayTweens_PartnerSkill"})
    refreshUIs.refreshStrength.refreshNow = true

end

local function onmsg_EvolvePetSkill(msg)
    local pet = i_AttainedPets[msg.modelid]
    pet.PetSkills[msg.oldskillid] = nil
    pet.PetSkills[msg.newskillid] = 1
    pet.PetCharacterSkillInfo:EvolveSkill(msg.oldskillid,msg.newskillid)
    refreshUIs.refreshStrength.refreshNow = true
end

local function onmsg_SyncPetAttrs(msg)
    local pet = i_AttainedPets[msg.modelid]
    pet.PetAttrs = msg.attrs

    refreshUIs.refreshStrength.refreshNow = true
    if BaseAttr ~= nil and pet.WashMaxValues ~= nil and pet.WashCurrValues ~= nil and pet.LastWashRecord ~= nil then
        for _,attr in ipairs(BaseAttr) do
            pet.WashCurrValues[attr.idx] = pet.WashCurrValues[attr.idx] + (pet.LastWashRecord[attr.idx] or 0)
        end
    end
    pet.LastWashRecord = {}
    refreshUIs.refreshWash.refreshNow = true
end

local function onmsg_ActivePet(msg)
    ActivePet = msg.modelid
    refreshUIs.refreshAssist.refreshNow = true
    refreshUIs.refreshDlgPartner.refreshNow = true
    refreshUIs.refreshStrength.refreshNow = true
    refreshUIs.refreshChoose.refreshNow = true
    equipCD = CfgConfig.equipcd.time
    UpdateFieldPetsNextFrame = true
    uimanager.call("dlguimain","PartnerEquipCD",equipCD)
    UpdateFieldPets()

end

local function onmsg_UnActivePet(msg)
    ActivePet = 0
    refreshUIs.refreshAssist.refreshNow = true
    refreshUIs.refreshDlgPartner.refreshNow = true
    refreshUIs.refreshStrength.refreshNow = true
    refreshUIs.refreshChoose.refreshNow = true
    UpdateFieldPetsNextFrame = true
    equipCD = CfgConfig.equipcd.time
    uimanager.call("dlguimain","PartnerEquipCD",equipCD)
    UpdateFieldPets()
end

local function onmsg_SyncPetFragment(msg)
    local lotterymanager = require "ui.lottery.lotterymanager"
    local bagManager=require"character.bagmanager"
    for fragmentid,amount  in pairs(msg.petfragment) do
        local curNum=i_PetFragments[fragmentid]
        i_PetFragments[fragmentid] = amount
        if bagManager.CanShowFlyText() then
            local item=ItemManager.CreateItemBaseById(fragmentid)
            if item then
                local newGetNum=amount
                if curNum then
                    newGetNum=amount-curNum
                end
                if newGetNum>0  and lotterymanager.getRecruit() then
					uimanager.ShowSyncItem(item,newGetNum)
                   -- uimanager.ShowSystemFlyText(string.format(LocalString.FlyText_PetFragmentReward, newGetNum,colorutil.GetQualityColorText(item:GetQuality(),item:GetName())))
                end
            end
        end
    end
    refreshUIs.refreshStrength.refreshNow = true
    refreshUIs.refreshAssist.refreshNow = true
end

local function onmsg_SyncPetCombatPower(msg)
    local pet = i_AttainedPets[msg.modelid]
    pet.PetCombatPower = msg.combatpower
    refreshUIs.refreshChoose.refreshNow = true
    refreshUIs.refreshAssist.refreshNow = true
    refreshUIs.refreshDlgPartner.refreshNow = true
end

--send

local function RequestFollow(idx)
    local pet = battlePets[idx]
    if pet then
        if pet.ConfigId ~= ActivePet then
            network.send(lx.gs.pet.msg.CActivePet({modelid = pet.ConfigId}))
        else
            network.send(lx.gs.pet.msg.CUnActivePet({}))
        end
    end
end

local function RequestCallPet(idx)
    local pet = p_UnAttainedPets[idx]
    if pet then
        network.send(lx.gs.pet.msg.CCallPet({modelid=pet.ConfigId}))
    end
end

local function RequestUnLoad(idx)
    local pet = battlePets[idx]
    if pet then
        local tb = {modelid=pet.ConfigId}
        network.send(lx.gs.pet.msg.CUnloadPet(tb))
    end
end

local function RequestLoad(modelid)
    network.send(lx.gs.pet.msg.CLoadPet({modelid = modelid}))
end

local function RequestWash(modelid,washid,isten)
    network.send(lx.gs.pet.msg.CWashPet({modelid=modelid,washid=washid,isten=isten and 1 or 0}))
end

local function RequestCancelWash(modelid)
    network.send(lx.gs.pet.msg.CWashPetCancel({modelid=modelid}))
end

local function RequestConfirmWash(modelid)
    network.send(lx.gs.pet.msg.CWashPetConfirm({modelid=modelid}))
end

local function RequestUpgradeLevel(modelid,materialpos,materialnum)
    network.send(lx.gs.pet.msg.CUpgradePetLevel({
        modelid = modelid,
        materialpos = materialpos,
        materialnum = materialnum,
    }))
end

local function RequestUpgradePetStar(modelid)
    network.send(lx.gs.pet.msg.CUpgradePetStar({modelid=modelid}))
end

local function RequestActive(modelid)
    network.send(lx.gs.pet.msg.CActivePet({modelid=modelid}))
end

local function RequestUnActive(modelid)
    network.send(lx.gs.pet.msg.CUnActivePet({modelid=modelid}))
end

local function RequestUpgradeAwake(modelid)
    network.send(lx.gs.pet.msg.CUpgradePetAwake({modelid=modelid}))
end

local function RequestUpgradeSkill(modelid,skillid)
    network.send(lx.gs.pet.msg.CUpgradePetSkill({modelid=modelid,skillid=skillid}))
end

local function RequestEvolveSkill(modelid,skillid)
    network.send(lx.gs.pet.msg.CEvolvePetSkill({modelid=modelid,skillid=skillid}))
end

local function RequestBuyPetSkin(modelid,skinid)
    network.send(lx.gs.pet.msg.CBuyPetSkin({modelid=modelid,skinid=skinid}))
end

local function RequestEquipPetSkin(modelid,skinid)
    network.send(lx.gs.pet.msg.CEquipPetSkin({modelid=modelid,skinid=skinid}))
end

local function RequestUnEquipPetSkin(modelid)
    network.send(lx.gs.pet.msg.CUnEquipPetSkin({modelid=modelid}))
end

local function RequestActiveStagestarAward(modelid,level)
    network.send(lx.gs.pet.msg.CActiveStarProp{modelid=modelid,level=level})
end

local function RequestActiveAwakeAward(modelid)
    network.send(lx.gs.pet.msg.CActiveAwakeProp{modelid=modelid})
end

local function CanActiveOrUnActive()
    return equipCD==nil
end

local function AddListeners()
    network.add_listeners({
        {"lx.gs.pet.msg.SPetInfo",onmsg_PetInfo},
        {"lx.gs.pet.msg.SCallPet",onmsg_CallPet},
        {"lx.gs.pet.msg.SSyncFightPets",onmsg_SyncFightPets},
        {"lx.gs.pet.msg.SSyncPetLevel",onmsg_SyncPetLevel},
        {"lx.gs.pet.msg.SUpgradePetAwake",onmsg_UpgradePetAwake},
        {"lx.gs.pet.msg.SWashPet",onmsg_WashPet},
        {"lx.gs.pet.msg.SWashPetCancel",onmsg_WashPetCancel},
        {"lx.gs.pet.msg.SBuyPetSkin",onmsg_BuyPetSin},
        {"lx.gs.pet.msg.SSyncPetSkin",onmsg_SyncPetSkin},
        {"lx.gs.pet.msg.SSyncPetSkill",onmsg_UpgradePetSkill},
        {"lx.gs.pet.msg.SEvolvePetSkill",onmsg_EvolvePetSkill},
        {"lx.gs.pet.msg.SActivePet",onmsg_ActivePet},
        {"lx.gs.pet.msg.SUpgradePetStar",onmsg_UpgradePetStar},
        {"lx.gs.pet.msg.SUnActivePet",onmsg_UnActivePet},
        {"lx.gs.pet.msg.SSyncPetFragment",onmsg_SyncPetFragment},
        {"lx.gs.pet.msg.SSyncPetAttrs",onmsg_SyncPetAttrs},
        {"lx.gs.pet.msg.SSyncPetCombatPower",onmsg_SyncPetCombatPower},
        {"lx.gs.pet.msg.SPetRecycle",onmsg_SPetRecycle},
        {"lx.gs.pet.msg.SSyncActiveStarProp",onmsg_ActiveStarProp},
        {"lx.gs.pet.msg.SSyncActiveAwakeProp",onmsg_ActiveAwakeProp},
        {"lx.gs.pet.msg.SSyncPetProps",onmsg_SyncPetProp},
    },"petmanager")
end

local function InitFieldPets()
    deadMap = {}
    equipCD = nil
    ResetFieldPets()
end

local function Update()
    if UpdateFieldPetsNextFrame then
        UpdateFieldPets()
    end
    for csvid,_ in pairs(deadMap) do
        if deadMap[csvid] then
            deadMap[csvid] = deadMap[csvid] - Time.deltaTime
            if deadMap[csvid]<0 then
                deadMap[csvid] = nil
                for i=1,3 do
                    if fieldPets[i] and fieldPets[i].pet then
                        if fieldPets[i].pet.ConfigId == csvid then
                            if ActivePet ~= csvid then
                                fieldPets[i].state = PetState.EQUIPED
                            end
                        end
                    end
                end
                UpdateFieldPets()
            end
        end
    end
    if equipCD then
        equipCD = equipCD - Time.deltaTime
        if equipCD < 0 then
            equipCD = nil
        end
    end
end

local function late_update()
    for _,v in pairs(refreshUIs) do
        if v.refreshNow then
            v.func()
            v.refreshNow = false
        end
    end
end

local function init(player)
    CfgBasicStatus      = ConfigManager.getConfig("petbasicstatus")
    CfgExp              = ConfigManager.getConfig("petexp")
    CfgStageStar        = ConfigManager.getConfig("petstagestar")
    CfgWash             = ConfigManager.getConfig("petwash")
    CfgAwake            = ConfigManager.getConfig("petawake")
    CfgTalent           = ConfigManager.getConfig("pettalent")
    CfgSkill            = ConfigManager.getConfig("petskill")
    CfgSkin             = ConfigManager.getConfig("petskin")
    CfgKarma            = ConfigManager.getConfig("petkarma")
    CfgConfig           = ConfigManager.getConfig("petconfig")
    CfgFragment         = ConfigManager.getConfig("petfragment")
    cfgModel            = ConfigManager.getConfig("model")
    StatusText                  = ConfigManager.getConfig("statustext")
    EctypeManager               = require"ectype.ectypemanager"
    dlguimain_partner           = require"ui.partner.dlguimain_partner"
    BagManager                  = require"character.bagmanager"
    CharacterManager            = require"character.charactermanager"
    gameevent.evt_update:add(Update)
    gameevent.evt_late_update:add(late_update)
    i_PetFragments                      = {}
    refreshUIs.refreshAssist.func       = RefreshAssist
    refreshUIs.refreshChoose.func       = RefreshChoose
    refreshUIs.refreshInformation.func  = RefreshInformation
    refreshUIs.refreshKarma.func        = RefreshKarma
    refreshUIs.refreshWash.func         = RefreshWash
    refreshUIs.refreshDlgPartner.func   = RefreshDlgPartner
    refreshUIs.refreshStrength.func     = RefreshStrength
    refreshUIs.refreshLoadState.func    = RefreshLoadState
    refreshUIs.refreshSkins.func        = RefreshSkin
    for _,v in pairs(refreshUIs) do
        v.refreshNow = false
    end
    effectsToShow = 0
    AddListeners()
    InitFieldPets()
    UpdateFieldPetsNextFrame    = false
end

-- dlguimain

local function Death(modelid)
    local pet = i_AttainedPets[modelid]
    if pet then
        deadMap[modelid] = CfgConfig.deadcd
    end
    local idx = GetBattlePetIndex(modelid)
    if idx == 0 then return end
    fieldPets[idx].state = PetState.DEAD
    UpdateFieldPets()
end

local function Revive(modelid)
    local pet = i_AttainedPets[modelid]
    if pet then
        deadMap[modelid] = nil
    end
    local idx = GetBattlePetIndex(modelid)
    if idx == 0 then return end
    if ActivePet == modelid then
        fieldPets[idx].state = PetState.ACTIVE
    else
        fieldPets[idx].state = PetState.EQUIPED
    end
    UpdateFieldPets()
end

local function ChangeFieldAttr(pet)
    if uimanager.isshow("dlguimain") then
        uimanager.call("dlguimain","RefreshPetAttributes",pet)
    end
end

local function SetPetColor(sprite,modelid)
    local pet = i_AttainedPets[modelid]
    if not pet then pet = i_UnAttainedPets[modelid] end
    if pet then
        local quality = pet.ConfigData.basiccolor
        local Qcolor = colorutil.GetQualitySprite(quality)
        sprite.spriteName = Qcolor
    else
        local Qcolor = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
        sprite.spriteName = Qcolor
    end
end

local function SetItemPetColor(item,modelid)
    local sprite = item.Controls["UISprite_Quality"]
    SetPetColor(sprite,modelid)
end

local function IsMaxAwake(pet)
    return pet.PetAwakeLevel == #CfgAwake[pet.ConfigId].awakelvlup_awakeid
end

local function GetFragmentRequirementAwake(pet)
    if IsMaxAwake(pet) then
        return 0
    else
        return CfgAwake[pet.ConfigId].awakelvlup_awakeid[pet.PetAwakeLevel+1].petfragmentcost
    end
end

local function GetPetHeadIcon(modelid)
    local pet = i_AttainedPets[modelid]
    if not pet then
        pet = i_UnAttainedPets[modelid]
    end
    if pet then
        return pet:GetHeadIcon()
    end
end

local function GetPetQuality(modelid)
    local pet = i_AttainedPets[modelid]
    if not pet then
        pet = i_UnAttainedPets[modelid]
    end
    if pet then
        return pet.ConfigData.basiccolor
    end
end

local function CanUpgradeASkill(skillinfo,pet)
	
    local skillInformation = ConfigManager.getConfigData("skilldmg",skillinfo.skillid)
    if not skillInformation then
        skillInformation = ConfigManager.getConfigData("passiveskill",skillinfo.skillid)
    end
    local skillCost = ConfigManager.getConfigData("skilllvlupcost",skillinfo.skillid)
    if skillinfo.actived then
        if skillinfo:GetSkill():IsMaxLevel(skillinfo.level) then
            return false
        elseif skillinfo:GetSkill():CanUpgrade(skillinfo.level) then
            local lvlupdata = skillCost.skilllvlupdata[skillinfo.level+1]
            local requiredata1 = ItemManager.GetCurrencyData(lvlupdata.requirecurrency1)
            if skillinfo:GetSkill():RoleLevelAchieve(pet.PetLevel,skillinfo.level+1) then
                if skillCost.requireawakelvl>pet.PetAwakeLevel then
                    return false
                else
                    local val1,info1 = CheckCmd.CheckData{data=lvlupdata.requirecurrency1,num=1}
					--printyellow("xxxxxxxxCanUpgradeASkill")
                    return val1 --and val2
                end
            else
                return false
            end
        else
            return false
        end
    else
        return false
    end
    return false
end

local function CanUpgradeSkill(pet)
	
    local skillInfo = pet.PetCharacterSkillInfo:GetAllSkills()
    for _,v in ipairs(skillInfo) do
        if IsShowedSkill(pet.ConfigId,v.skillid) then
            if CanUpgradeASkill(v,pet) then
				printyellow("CanUpgradeSkill")
                return true
            end
        end
    end
    return false
end

local function CanUpgradeAwake(pet)
	
    if pet.PetAwakeLevel == #CfgAwake[pet.ConfigId].awakelvlup_awakeid then return false end
    local fragmentid = pet.ConfigData.fragmentid
    local itemFragment = ConfigManager.getConfigData("petfragment",fragmentid)
    local ownedFragmentAmount = GetFragmentNum(fragmentid)
    local lvlupFragmentAmount = CfgAwake[pet.ConfigId].awakelvlup_awakeid[pet.PetAwakeLevel+1].petfragmentcost
	printyellow("xxxxxxxxCanUpgradeAwake",lvlupFragmentAmount,ownedFragmentAmount)
    if ownedFragmentAmount >= lvlupFragmentAmount and
        pet.PetLevel >= CfgAwake[pet.ConfigId].awakelvlup_awakeid[pet.PetAwakeLevel+1].requirepetlevel then
            local val,info = CheckCmd.CheckData{data=CfgAwake[pet.ConfigId].awakelvlup_awakeid[pet.PetAwakeLevel+1].requirexunibi,num=1}
			printyellow("CanUpgradeAwake")
            return val
    end
    return false
end

local function CanUpgradeStageStar(pet)
	
    local currInfo = CfgStageStar[pet.PetStageStar]
	if pet.PetStageStar >=100  then return false end
    if currInfo.requirepetlvl > pet.PetLevel then return false end
    local val,info = CheckCmd.CheckData{data=currInfo.requirexunibi,num=1}
    if not val then return false end
    for _,cdt in pairs(currInfo.requireitem) do
        local val,info = CheckCmd.CheckData{data=cdt,num=1}
        if not val then return false end
    end
    return true
end

local function CanUpgradeLevel(pet)
	
    local PlayerRole = require"character.playerrole"
    if pet.PetLevel < PlayerRole.Instance().m_Level then
        local cfgConsume = ConfigManager.getConfig("petconsume")
        for _,itemid in ipairs(cfgConsume) do
            local num = BagManager.GetItemNumById(itemid)
            if num>0 then printyellow("CanUpgradeLevel") return true end
        end
    end
    return false
end




local function CanWash(pet)
    local num = BagManager.GetItemNumById(10400013)
	local WashKeyValue = {}
	local allKeyValue = {}
	
	
	
	if i_AttainedPets[pet.ConfigId].WashMaxValues ~= nil then
		
		for key,v in pairs(i_AttainedPets[pet.ConfigId].WashMaxValues) do
			table.insert(WashKeyValue,key)
		end
		
		for _,k in ipairs(WashKeyValue) do
			if i_AttainedPets[pet.ConfigId].WashMaxValues[k] == i_AttainedPets[pet.ConfigId].WashCurrValues[k] then
				table.insert(allKeyValue,true)
			else
				table.insert(allKeyValue,false)
			end
		end
		local isArriveFullLimit = allKeyValue[1] and allKeyValue[2]and allKeyValue[3]and allKeyValue[4]and allKeyValue[5]and allKeyValue[6]and allKeyValue[7]
		
		if isArriveFullLimit == true then
			return false
		end
	end
	printyellow("因为数据跟服务端没有同步造成的红点刷新不及时")
    return num>0 and pet.PetLevel>=CfgConfig.washopenlevel.level 
end

--伙伴升级包括了、升星判断、觉醒判断、技能升级、伙伴升级、洗练
local function CanUpgrade(pet)
	 	
    if i_AttainedPets then
        return CanUpgradeStageStar(pet)
        or CanUpgradeAwake(pet)
        or CanUpgradeSkill(pet)
        or CanUpgradeLevel(pet)
        or CanWash(pet)
    end
    return false
end

local function CanCall(pet)
    if i_AttainedPets[pet.ConfigId] then return false end
    if not i_UnAttainedPets[pet.ConfigId] then return false end
    local petfragmentid = pet.ConfigData.fragmentid
    if i_PetFragments[petfragmentid] then
        return CfgFragment[petfragmentid].number <= i_PetFragments[petfragmentid]
    end
    return false
end

local function CanStarAward(pet)
    local aPet = i_AttainedPets[pet.ConfigId]
    if not aPet then return false end
    local currlevel = math.floor((pet.PetStageStar-1)/10)
    local awardlevel = math.floor(pet.PetAwardStar/10)
    return currlevel > awardlevel
end

local function CanAwakeAward(pet)
    local aPet = i_AttainedPets[pet.ConfigId]
    if not aPet then return false end
    local currlevel = pet.PetAwakeLevel
    local awardlevel = pet.PetAwardAwake
    return currlevel >= awardlevel
end

local function CanAward(pet)
    return CanStarAward(pet) or CanAwakeAward(pet)
end

local function HaveAwardPet()
    for _,v in pairs(i_AttainedPets) do
        if CanStarAward(v) or CanAwakeAward(v) then
            return true
        end
    end
    return false
end

local function HaveCanCallPet()
    for _,v in ipairs(p_UnAttainedPets) do
        if CanCall(v) then return true end
    end
    return false
end

local function HaveCanUpgradePet()
    for _,v in ipairs(p_AttainedPets) do
        if CanUpgrade(v) then  return true end
        --[[策划需求没上阵得伙伴不止单纯觉醒显示红点
        if IsBattlePet(v.ConfigId) then
            if CanUpgrade(v) then  return true end
        else
            if CanUpgradeAwake(v) then  return true end
        end--]]
    end
    return false
end

local function UnRead()
    local ret = HaveCanUpgradePet() or HaveCanCallPet()
    return ret
end

local function GetFirstSkillInfo(pet)
    local skillInfo = pet.PetCharacterSkillInfo:GetAllSkills()
    for _,v in ipairs(skillInfo) do
        if IsShowedSkill(pet.ConfigId,v.skillid) then
            return v
        end
    end
end

local function CanUpgradeFirstSkill()
    local pet = battlePets[1]
    if pet then
        local skillInfo = GetFirstSkillInfo(pet)
        return CanUpgradeASkill(skillInfo,pet)
    else
        return false
    end
end

local function GetActivePet()
    for _,fieldPet in pairs(fieldPets) do
        if fieldPet.state == PetState.ACTIVE then
            return fieldPet
        end
    end
    return nil
end

local function PassiveUnActivePet()
    if EctypeManager.IsInEctype() then return end
    local fieldPet = GetActivePet()
    if fieldPet then
        lastFollowPetModelId = fieldPet.pet.ConfigId
        RequestUnActive(lastFollowPetModelId)
    end

end

local function PassiveResumePet()
    if lastFollowPetModelId then
        RequestActive(lastFollowPetModelId)
    end
end

local function HaveNewPet()
    for _,v in pairs(p_AttainedPets) do
        if v.NewPet then return true end
    end
    return false
end

local function SetAllPetOld()
    for _,v in pairs(p_AttainedPets) do
        v.NewPet = false
    end
end

local function SetAllPetSkinOld()
    for _,pet in pairs(p_AttainedPets) do
        for skinid,isNew in pairs(pet.PetSkinList) do
            pet.PetSkinList[skinid] = false
        end
    end
end

local function PetExpChange(modelid,level,exp)
    local pet = i_AttainedPets[modelid]
    pet.PetExp = exp
    if pet.PetLevel ~= level then
        pet.PetLevel = level
        refreshUIs.refreshDlgPartner.refreshNow = true
    else
        RefreshPetExp()
    end
end


local function GetQuality(modelid)
    local pet = i_AttainedPets[modelid]
    if not pet then
        pet = i_UnAttainedPets[modelid]
    end
    return pet.ConfigData.basiccolor
end

local function GetHeadIcon(modelid)
    local pet = i_AttainedPets[modelid]
    if not pet then
        pet = i_UnAttainedPets[modelid]
    end
    local modelName = pet.ConfigData.modelname
    local modelData = ConfigManager.getConfigData("model",modelName)
    return modelData.headicon
end

local function GetPetName(modelid)
    local pet = i_AttainedPets[modelid]
    if not pet then
        pet = i_UnAttainedPets[modelid]
    end
    if pet then
        return pet.ConfigData.name
    end
    return ""
end

local function GetDecompositionExp(pet)
    local ret = {}
    local currExp = 0
    for i=1,pet.PetLevel-1 do
        currExp = CfgExp[i].exp + currExp
    end
    currExp = pet.PetExp + currExp
    local cfgConsume = ConfigManager.getConfig("petconsume")
    for i=#cfgConsume.consumeitem,1,-1 do
        local itemid = cfgConsume.consumeitem[i]
        local item = ItemManager.CreateItemBaseById(itemid)
        local ItemExp = item.ConfigData.effect.amount
        local cnt = math.floor(currExp/ItemExp)
        currExp = currExp % ItemExp
        if cnt> 0 then
            table.insert(ret,{itemid=itemid,count=cnt})
        end
    end
    return ret
end

local function GetDecompositionStageStar(pet)
    local ret = {}
    for i=1,pet.PetStageStar-1 do
        for _,item in ipairs(CfgStageStar[i].requireitem) do
            local itemid = item.itemid
            local cnt = item.amount
            if ret.itemid then
                ret[itemid] = ret[itemid] + cnt
            else
                ret[itemid] = cnt
            end
        end
    end
    return ret
end

local function GetDecompositionFragment(pet)
    local ret = {}
    ret.fragmentid = CfgBasicStatus[pet.ConfigId].fragmentid
    ret.count = 0
    local petawakeinfo = CfgAwake[pet.ConfigId]
    for i=1,pet.PetAwakeLevel do
        ret.count = ret.count + petawakeinfo.awakelvlup_awakeid[i].petfragmentcost
    end
    return ret
end

local function GetDecompositionBeans(pet)
    local ret = {}
    ret.itemid = 10400013
    ret.count = 0
    if pet.WashCurrValues then
        ret.count = math.floor(pet.WashCurrValues[cfg.fight.AttrId.HP_FULL_VALUE] / cfg.pet.PetBasicStatus.INITIALIZE_RETURN_RATE )
    end
    return ret
end

local function GetPetDecomposition(modelid)
    local pet = i_AttainedPets[modelid]
    if not pet then
          return
    end
    local ret = {}
    ret.exp       = GetDecompositionExp(pet) --���龭��
    ret.stagestar = GetDecompositionStageStar(pet) --����������
    ret.fragment  = GetDecompositionFragment(pet) --������Ƭ
    ret.beans     = GetDecompositionBeans(pet)  --����beans
    return ret
end

local function GetQualityPets(quality)
    local ret = {}
    for _,pet in ipairs(p_AttainedPets) do
        if pet.ConfigData.basiccolor == quality then
            table.insert(ret,pet)
        end
    end
    for _,pet in ipairs(p_UnAttainedPets) do
        if pet.ConfigData.basiccolor == quality then
            table.insert(ret,pet)
        end
    end
    return ret
end

local function GetQualityPetsCount(quality)
    local attainedCount,totalCount
    attainedCount = 0
    unattainedCount = 0
    for _,pet in pairs(i_AttainedPets) do
        if pet.ConfigData.basiccolor == quality then
            attainedCount = attainedCount + 1
        end
    end
    for _,pet in pairs(i_UnAttainedPets) do
        if pet.ConfigData.basiccolor == quality then
            unattainedCount = unattainedCount + 1
        end
    end
    return attainedCount,attainedCount+unattainedCount
end

local function GetHalfBodyTexture(modelid)
    local pet = i_AttainedPets[modelid]
    if not pet then
        pet = i_UnAttainedPets[modelid]
    end
    local modelData = cfgModel[pet.ConfigData.modelname]
    return modelData.portrait
end

return {
    init                        = init,
    BaseAttr                    = BaseAttr,
    ExtendAttr                  = ExtendAttr,
    InfoAttr                    = InfoAttr,
    ChangeFieldAttr             = ChangeFieldAttr,
    PetExpChange                = PetExpChange,

    GetAttributes               = GetAttributes,
    GetStageStarText            = GetStageStarText,
    GetKarmas                   = GetKarmas,
    GetFieldPets                = GetFieldPets,
    GetBattlePetIndex           = GetBattlePetIndex,
    GetSortedAttainedPets       = GetSortedAttainedPets,
    GetSortedUnAttainedPets     = GetSortedUnAttainedPets,
    GetFragmentNum              = GetFragmentNum,
    GetRightPet                 = GetRightPet,
    GetLeftPet                  = GetLeftPet,
    GetBattlePets               = GetBattlePets,
    GetNextKarmaLevel           = GetNextKarmaLevel,
    GetStar                     = GetStar,
    GetStage                    = GetStage,
    GetWashTotalAttributes      = GetWashTotalAttributes,
    GetPetState                 = GetPetState,
    GetDeadCD                   = GetDeadCD,
    GetSkinInfo                 = GetSkinInfo,
    GetAllSkins                 = GetAllSkins,
    GetFragmentRequirementAwake = GetFragmentRequirementAwake,
    GetFragmentNumByPet         = GetFragmentNumByPet,
    GetAttainedQualityPets      = GetAttainedQualityPets,
    GetQualityPets              = GetQualityPets,
    GetQualityPetsCount         = GetQualityPetsCount,
    GetHalfBodyTexture          = GetHalfBodyTexture,

    -- for character.pet
    GetQualityColor             = GetQualityColor,
    GetQualityColorTexture      = GetQualityColorTexture,

    IsBattlePet                 = IsBattlePet,
    IsFollowingPet              = IsFollowingPet,
    IsFollowing                 = IsFollowing,
    IsAttainedPets              = IsAttainedPets,
    IsShowedSkill               = IsShowedSkill,
    CanLoad                     = CanLoad,
    HasWashed                   = HasWashed,
    CanActiveOrUnActive         = CanActiveOrUnActive,

    -- sends
    RequestFollow               = RequestFollow,
    RequestUnLoad               = RequestUnLoad,
    RequestLoad                 = RequestLoad,
    RequestWash                 = RequestWash,
    RequestCancelWash           = RequestCancelWash,
    RequestConfirmWash          = RequestConfirmWash,
    RequestCallPet              = RequestCallPet,
    RequestUpgradeAwake         = RequestUpgradeAwake,
    RequestUpgradePetStar       = RequestUpgradePetStar,
    RequestUpgradeSkill         = RequestUpgradeSkill,
    RequestEvolveSkill          = RequestEvolveSkill,
    RequestBuyPetSkin           = RequestBuyPetSkin,
    RequestEquipPetSkin         = RequestEquipPetSkin,
    RequestUnEquipPetSkin       = RequestUnEquipPetSkin,
    RequestActive               = RequestActive,
    RequestUnActive             = RequestUnActive,
    RequestUpgradeLevel         = RequestUpgradeLevel,
    RequestActiveStagestarAward = RequestActiveStagestarAward,
    RequestActiveAwakeAward     = RequestActiveAwakeAward,

    Death                       = Death,
    Revive                      = Revive,
    GetPetHeadIcon              = GetPetHeadIcon,
    PetState                    = PetState,
    SetPetColor                 = SetPetColor,
    SetItemPetColor             = SetItemPetColor,
    GetPetQuality               = GetPetQuality,
    CanUpgradeASkill            = CanUpgradeASkill,
    CanUpgradeFirstSkill        = CanUpgradeFirstSkill,
    CanUpgradeAwake             = CanUpgradeAwake,
    CanUpgradeStageStar         = CanUpgradeStageStar,
    CanUpgradeSkill             = CanUpgradeSkill,
    CanUpgrade                  = CanUpgrade,
    CanStarAward                = CanStarAward,
    CanAwakeAward               = CanAwakeAward,
    CanAward                    = CanAward,
    HaveCanUpgradePet           = HaveCanUpgradePet,
    HaveNewPet                  = HaveNewPet,
    HaveCanCallPet              = HaveCanCallPet,
    HaveAwardPet                = HaveAwardPet,

    SetAllPetSkinOld            = SetAllPetSkinOld,
    SetAllPetOld                = SetAllPetOld,
    SetPetSkinOld               = SetPetSkinOld,
    SetWashMaxValue             = SetWashMaxValue,

    PassiveUnActivePet          = PassiveUnActivePet,
    PassiveResumePet            = PassiveResumePet,

    GetQuality                  = GetQuality,
    GetHeadIcon                 = GetHeadIcon,
    GetPetName                  = GetPetName,

    UnRead                      = UnRead,
    CanCall                     = CanCall,
    CanWash                     = CanWash,
    GetPetDecomposition         = GetPetDecomposition,
}
