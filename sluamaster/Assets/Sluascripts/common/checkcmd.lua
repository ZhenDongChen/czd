local PlayerRole
local UIManager
local LimitManager
local BagManager
local ItemManager
local MathUtils
local AllModules
local AllConditions
local CheckData
local ConfigManager     = require "cfg.configmanager"

-- 校验最小等级
local function CheckMinLevel(condition, params)
    local validate = true
    local info = ""
    if PlayerRole:Instance():GetLevel() < condition.level then
        info = string.format(LocalString.CheckConditionInfo[condition.class], condition.level)
        validate = false
    end
    return validate, info
end

-- 校验最大等级
local function CheckMaxLevel(condition, params)
    local validate = true
    local info = ""
    if PlayerRole:Instance():GetLevel() > condition.level then
        info = string.format(LocalString.CheckConditionInfo[condition.class], condition.level)
        validate = false
    end
    return validate, info
end

-- 校验最大等级
local function CheckMinMaxLevel(condition, params)
    local validate = true
    local info = ""
	if condition.max == -1 and condition.min ~= cfg.Const.NULL and PlayerRole:Instance():GetLevel() < condition.min then 
        info = string.format(LocalString.CheckConditionInfo["cfg.cmd.condition.MinLevel"], condition.min)
        validate = false
    elseif (condition.min ~= cfg.Const.NULL and PlayerRole:Instance():GetLevel() < condition.min) or
        (condition.max ~= cfg.Const.NULL and PlayerRole:Instance():GetLevel() > condition.max) then
        info = string.format(LocalString.CheckConditionInfo[condition.class], condition.min, condition.max)
        validate = false
    end
    return validate, info
end

-- 检测单个物品是否足够（待添加）
local function CheckOneItem(condition, params)
    local validate = true
    local info = ""
    local item=BagManager.GetItemById(condition.itemid)
    if item and item[1] then
        if item[1]:GetNumber()<params.num then
            info = string.format(LocalString.CheckConditionInfo["cfg.cmd.condition.OneItem"],item[1]:GetName())
            validate=false
        end
	else
		-- 背包里相应物品数目为0,仅为了显示物品信息
        local itemData = ConfigManager.getConfigData("itembasic",condition.itemid)
        if (itemData) and (itemData.name) then
            info = string.format(LocalString.CheckConditionInfo["cfg.cmd.condition.OneItem"], itemData.name)
        end
        validate=false
    end
    return validate, info
end

-- 检测物品是否足够（待添加）
local function CheckItem(condition, params)
    local validate = true
    local info = ""
    -- 背包中存在同一个csvid放在不同格子里，函数返回list
    local totalItemNumInBag = BagManager.GetItemNumById(condition.itemid)
	if totalItemNumInBag<condition.amount then
        local itemData = ConfigManager.getConfigData("itembasic",condition.itemid)
        if (itemData) and (itemData.name) then
            info = string.format(LocalString.CheckConditionInfo["cfg.cmd.condition.Item"], itemData.name)
        end
        validate=false
    end
    return validate, info
end

-- 购买物品的时候会首先检测货币

-- 检测货币

local function CheckCurrencyCommon(currencytype, amount, num)
    local validate = true
    local info = ""
    local leftnum = PlayerRole:Instance():GetCurrency(currencytype)
    if amount * num > leftnum then
		local currency = ItemManager.CreateItemBaseById(currencytype)

        info = string.format(LocalString.CheckConditionInfo["cfg.cmd.condition.Currency"],currency:GetName()) --金币不足

       -- info = string.format(LocalString.CheckConditionInfo["cfg.cmd.condition.Currency"],currency:GetName())

        validate = false
    end
    return validate, info
end
-- 检测货币(单类型)是否足够
local function CheckCurrency(condition, params)
    return CheckCurrencyCommon(condition.currencytype, condition.amount, params.num)
end

-- 检测货币(多类型)是否足够
local function CheckCurrencys(condition, params)
    local validate = true
    local info = ""
    for _, c in pairs(condition.currencys) do
        validate, info = CheckCurrencyCommon(c.currencytype, c.amount, params.num)
        if not validate then
            break
        end
    end

    return validate, info
end

-- 检测虚拟币是否足够
local function CheckXuNiBi(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.XuNiBi, condition.amount, params.num)
end

-- 检测元宝是否足够
local function CheckYuanBao(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.YuanBao, condition.amount, params.num)
end

-- 检测绑定元宝是否足够,优先消耗绑定元宝，如果绑定元宝数量不够，会继续消耗元宝(暂用此规则，服务器同样依照此规则处理的)
local function CheckBindYuanBao(condition, params)
  --printyellow(">>>>>>>>>>>>>>>>>>>>>>CheckBindYuanBao")
	local iscalculateTotalnumber  = params.istotal
	if  iscalculateTotalnumber   == nil then
		local validate = true
		local info = ""
		local totalLeftnum = PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.BindYuanBao) + PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.YuanBao)
		if condition.amount * params.num > totalLeftnum then
			local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.BindYuanBao)
			--info = string.format(LocalString.CheckConditionInfo["cfg.cmd.condition.Currency"], currency:GetName())
			info = LocalString.CheckConditionInfo["cfg.cmd.condition.YuanBaoLimit"]
			validate = false
		end
		return validate, info
	else if iscalculateTotalnumber == true then
		return CheckCurrencyCommon(cfg.currency.CurrencyType.BindYuanBao, condition.amount, params.num)
	end
end
   
end

-- 检测灵晶是否足够
local function CheckLingJing(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.LingJing, condition.amount, params.num)
end

-- 检测经验是否足够
local function CheckJingYan(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.JingYan, condition.amount, params.num)
end

-- 检测经验是否足够
local function CheckJingYan(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.JingYan, condition.amount, params.num)
end

-- 检测造化是否足够
local function CheckZaoHua(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.ZaoHua, condition.amount, params.num)
end

-- 检测悟性是否足够
local function CheckWuXing(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.WuXing, condition.amount, params.num)
end

-- 检测帮派贡献是否足够
local function CheckBangPai(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.BangPai, condition.amount, params.num)
end

-- 检测师门贡献是否足够
local function CheckShiMen(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.ShiMen, condition.amount, params.num)
end

-- 检测战场声望是否足够
local function CheckZhanChang(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.ZhanChang, condition.amount, params.num)
end

-- 检测竞技场声望是否足够
local function CheckShengWang(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.ShengWang, condition.amount, params.num)
end

-- 检测伙伴积分是否足够
local function CheckHuoBanJiFen(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.HuoBanJiFen, condition.amount, params.num)
end

-- 检测法宝积分是否足够
local function CheckFaBaoJiFen(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.FaBaoJiFen, condition.amount, params.num)
end

-- 检测成就点是否足够
local function CheckChengJiu(condition, params)
    return CheckCurrencyCommon(cfg.currency.CurrencyType.ChengJiu, condition.amount, params.num)
end

local function CheckLimitCommon(params, limittype, limitsum)
    local validate = true
    local info = ""
    local limit = LimitManager.GetLimitTime(params.moduleid,params.cmdid)
    local limitcount = 0
    -- if limit and limit.typenums and limit.typenums[limittype] then  limitcount = limit.typenums[limittype] end
    if limit and limit[limittype] then limitcount = limit[limittype] end
    if limitcount + params.num > limitsum then
        local str = LocalString.CheckConditionInfo["cfg.cmd.condition.Limit"]
        local num = LocalString.LimitTypeNames[limittype]
        info = string.format(str,num , limitsum, limitcount)
        validate = false
    end
    return validate, info
end



-- 校验限制
local function CheckLimit(condition, params)
    return CheckLimitCommon(params, condition.type, condition.num)
end



-- 校验限制(多类型)
local function CheckLimits(condition, params)
    local validate = true
    local info = ""
    for _, c in pairs(condition.limits) do
        validate, info = CheckLimitCommon(params, c.type, c.num)
        if not validate then
            break
        end
    end
    return validate, info
end

local function CheckProfessionLimit(condition, params)
    local validate = true
    local info = ""
    if condition.profession ~= cfg.Const.NULL and condition.profession ~= PlayerRole:Instance().m_Profession then
        info = LocalString.CheckConditionInfo["cfg.cmd.condition.ProfessionLimit"]
        validate = false
    end
    return validate, info
end
--校验最小VIP等级
local function CheckMinVipLevel(condition, params)
    local validate = true
    local info = ""
    if PlayerRole:Instance().m_VipLevel < condition.level then
        info = string.format(LocalString.CheckConditionInfo[condition.class], condition.level)
        validate = false
    end
    return validate, info
end
--校验日限制
local function CheckDayLimit(condition, params)
    local validate = true
    local info = ""
    local limitcount = LimitManager.GetDayLimitTime(params.moduleid,params.cmdid)
    --printyellow("CheckDayLimit",limitcount,params.num,condition.num)
    if limitcount + params.num > condition.num and condition.num ~= cfg.Const.NULL then
        info = string.format(LocalString.CheckConditionInfo["cfg.cmd.condition.DayLimit"], condition.num)
        validate = false
    end

    return validate, info
end

local function CheckVipLimitsLite(condition,params)
    local validate=true
    local i=0
    for _,c in pairs(condition.entertimes) do
        if c==-1 then
            break
        else
            if PlayerRole:Instance().m_VipLevel==i then
                local consumeTime=LimitManager.GetDayLimitTime(params.moduleid,params.cmdid)             
                if consumeTime then
                    if c<=consumeTime then
                        validate=false
                        break
                    end
                else
                    validate=true
                    break
                end
            end
            i=i+1
        end
    end
    return validate
end

local function CheckVipLimits(condition,params)
    local validate = true
    local i=0
    for _,c in pairs(condition.entertimes) do
        if c==-1 then
            break
        else
            if PlayerRole:Instance().m_VipLevel==i then
                local consumeTime=LimitManager.GetDayLimitTime(params.moduleid,params.cmdid)
                if consumeTime then
                    if c<=consumeTime then
                        validate=false
                        break                  
                    end
                end
            end
            i=i+1
        end       
    end
    return validate
end

local function CheckVipLimits2(condition,params)
    local validate = true
    local info = ""
	local roleVipLevel = PlayerRole:Instance().m_VipLevel
	local idx = math.min(roleVipLevel+1,#(condition.entertimes))
	local maxCostTime = condition.entertimes[idx]
	local curCostTime = LimitManager.GetDayLimitTime(params.moduleid,params.cmdid)
	local nextCostTime = curCostTime + params.num
	if maxCostTime ~= cfg.Const.NULL and nextCostTime > maxCostTime then
		info = string.format(LocalString.CheckConditionInfo["cfg.cmd.condition.DayLimit"], maxCostTime)
        validate = false
		return validate, info
	end
	for costTime = curCostTime+1,nextCostTime do
		local costIdx = math.min(costTime,#(condition.costs))
		local costValidated,costInfo = CheckData({ data = condition.costs[costIdx], num = 1, showsysteminfo = true })
		if not costValidated then 
			return costValidated,costInfo
		end
	end

	return validate, info
end

local function CheckMinFamilyLevel(condition, params)
    local familymgr = require("family.familymanager")
    if familymgr.IsReady() then
        return familymgr.Info().flevel >= condition.level, string.format(LocalString.CheckConditionInfo[condition.class], condition.level)
    else
        return false, LocalString.CheckConditionInfo["FamilyDataUnavailable"]
    end
end

local function CheckMinFamilyShopLevel(condition, params)
    local familymgr = require("family.familymanager")
    if familymgr.IsReady() then
        return familymgr.Info().malllevel >= condition.level, string.format(LocalString.CheckConditionInfo[condition.class], condition.level)
    else
        return false, LocalString.CheckConditionInfo["FamilyDataUnavailable"]
    end
end

local function CheckFamilyMoney(condition, params)
    local familymgr = require("family.familymanager")
    if familymgr.IsReady() then
        return familymgr.Info().money >= condition.money, string.format(LocalString.CheckConditionInfo[condition.class], condition.money)
    else
        return false, LocalString.CheckConditionInfo["FamilyDataUnavailable"]
    end
end

local function CheckEquiped(condition,params)
    local validate=false
    local equips=PlayerRole:Instance().m_Equips
    local equipId=condition.id[PlayerRole:Instance().m_Profession]
    if equipId then
        if PlayerRole:Instance().m_Dress==equipId then
            return true
        end
        for _,v in pairs(equips) do
            if v.equipkey==equipId then
                validate=true
                break
            end
        end
    end   
    return validate
end

local function CheckOwnTask(condition,params)
    local validate=false
    local TaskManager=require"taskmanager"
    local task=TaskManager.GetCurTask(defineenum.TaskType.Mainline)
    if task then
        if task.id==condition.taskid then
            return true
        end
    end
    local branchTasks=TaskManager.GetCurTask(defineenum.TaskType.Branch)
    if branchTasks and (branchTasks[condition.taskid]~=nil) then
        return true
    end
    local familyTask=TaskManager.GetCurTask(defineenum.TaskType.Family)
    if familyTask and familyTask.id==condition.taskid then
        return true
    end   
    return validate
end

local function CheckAcceptTask(condition,params)
    local TaskManager=require"taskmanager"
    local status=TaskManager.GetTaskStatus(condition.taskid)
    return status == defineenum.TaskStatusType.Accepted or status == defineenum.TaskStatusType.Doing
end

local function CheckCompleteTask(condition,params)
    local TaskManager=require"taskmanager"
    return TaskManager.GetTaskStatus(condition.taskid)==defineenum.TaskStatusType.Completed
end

local function CheckCompleteAchievement(condition,params)
    local AchieveManager=require"ui.achievement.achievementmanager"
    return AchieveManager.GetTaskStatus(condition.achievementid)~=cfg.achievement.Status.NOTCOMPLETED
end

local function CheckMonsterHP(condition,params)
    local CharacterManager=require"character.charactermanager"
    local monsters=CharacterManager.GetCharactersByCsvId(condition.monsterid)
    local validate=false
    for _,monster in pairs(monsters) do
        if monster then
            if (monster.m_Attributes[cfg.fight.AttrId.HP_VALUE]) and (monster.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]) then
                if (monster.m_Attributes[cfg.fight.AttrId.HP_VALUE]~=0) and (monster.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]~=0) then
                    local hpPercent=monster.m_Attributes[cfg.fight.AttrId.HP_VALUE] / monster.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
                    if hpPercent<=(condition.hp/100) then
                        validate=true
                        break
                    end
                end
            end
        end
    end
    return validate
end

local function CheckOpenEctype(condition,params)
    local EctypeManager=require"ectype.ectypemanager"
    return EctypeManager.IsInOneEctype(condition.ectypeid)
end

local function CheckMonsterAppear(condition,params)
    local validate=false
    local CharacterManager=require"character.charactermanager"
    local characters=CharacterManager.GetCharacters()
    if characters then
        for _,character in pairs(characters) do
            if character.m_CsvId==condition.monsterid then
                if MathUtils.DistanceOfXoY(character:GetRefPos(),PlayerRole:Instance():GetRefPos())<condition.distance then
                    validate=true
                    break
                end
            end
        end
    end
    return validate
end

local function CheckDisplayDlg(condition,params)
    return (UIManager.isshow(condition.dialogname) and condition.open==0) or ((not UIManager.isshow(condition.dialogname)) and condition.open==1)
end

local function CheckEnterRegion(condition,params)
    local validate=false
    validate=MathUtils.DistanceOfXoY(Vector3(condition.coordinate[1],condition.coordinate[2],0),PlayerRole:Instance():GetRefPos())<(condition.distance)
    return validate
end

local function CheckCanPlaySkill(condition,params)
    local validate=false
    local PlayerRole=require"character.playerrole"
    local skillid=condition.skillids[PlayerRole:Instance().m_Profession]
    if skillid then
        local RoleSkill=require"character.skill.roleskill"
        local playerSkillData=PlayerRole:Instance().PlayerSkill:GetPlayerSkill(skillid)
        if playerSkillData then       
            validate=(playerSkillData:CanAttack())
        end
    end
    --printyellow("CheckCanplay:",validate)
    return validate
end

local function CheckOwnSkill(condition,params)
    local validate=false
    local PlayerRole=require"character.playerrole"
    local skillid=condition.skillids[PlayerRole:Instance().m_Profession]
    if skillid then
        local RoleSkill=require"character.skill.roleskill"
        local playerSkillData=PlayerRole:Instance().PlayerSkill:GetPlayerSkill(skillid)
        if playerSkillData then
            validate=true
        end
    end
    return validate       
end

local function CheckCanJoinActivity(condition,params)
    local validate=false
    if condition.activitytype==cfg.cmd.condition.ActivityType.XUEZHANQINGYUN then
        local GuardTowerManager=require"ui.ectype.guardtower.guardtowermanager"
        validate=GuardTowerManager.UnRead()
    elseif condition.activitytype==cfg.cmd.condition.ActivityType.SHOUYAOGONGCHENG then
        local AttackCityManager = require("ui.activity.attackcity.attackcitymanager")
        validate=AttackCityManager.UnRead()
    elseif condition.activitytype==cfg.cmd.condition.ActivityType.HONGMENGZHENGBA then
        local TabArenaMultiSpeed=require"ui.arena.multi.speed.tabarenamultispeed"
        validate=TabArenaMultiSpeed.UnRead()
    elseif condition.activitytype==cfg.cmd.condition.ActivityType.QIMAIHUIWU then
        local tournamentManager=require"ui.activity.tournament.tournamentmanager" 
        validate=tournamentManager.UnRead()
    elseif condition.activitytype==cfg.cmd.condition.ActivityType.TIANXIAHUIWU then
        local PVPManager=require"ui.arena.multi.pvp.pvpmanager"
        validate=PVPManager.GetMatchEnable()       
    end
    return validate
end

local function CheckPlayCGOver()
    return false
end

local function CheckLoginDay(condition,params)
    local welfaremanager = require "ui.welfare.welfaremanager"
    local day=welfaremanager.GetLoginDays()
    local validate=false
    if (day) and (condition.day) then
        if (day>=condition.day) then
            validate=true
        end
    end
    return validate
end

local function CheckIsNavigating(condition,params)
    local validate=false
    if (PlayerRole:Instance():IsNavigating()) then
        validate=true
    end
    return validate
end

local function CheckJoinFamily(condition,params)
    local FamilyManager=require"family.familymanager"
    return FamilyManager.InFamily()
end

local function CheckPetSkillUpgrade(condition,params)
    local PetManager=require"character.pet.petmanager"
    return PetManager.CanUpgradeFirstSkill()
end

local function CheckPetLevel(condition,params)
    local validate=false
    local PetManager=require"character.pet.petmanager" 
    local pets=PetManager.GetBattlePets()
    if pets then
        for _,pet in pairs(pets) do
            if pet then
                if pet.PetLevel>=condition.level then
                   validate=true 
                end
            end
            break
        end
    end
    return validate
end

local function CheckFirstRecharge(condition,params)
    local validate=false
    local VipChargeManager=require"ui.vipcharge.vipchargemanager"
    if VipChargeManager.GetFirstPayUsed()==0 then
        validate=true
    end
    return validate
end

local function CheckFirstRecharge2(condition,params)
    local validate=false
    local PlayerRole=  require "character.playerrole"
    if PlayerRole:Instance():GetFirstCharge() == condition.num then
        validate=true
    end
    return validate
end


local function CheckHasActiveRide(condition,params)
    local validate=false
    local RideManager=require"ui.ride.ridemanager"
    validate=(RideManager.GetActivedRide()~=nil and condition.has==true) or (RideManager.GetActivedRide()==nil and condition.has==false)
    return validate 
end

local function CheckWelfare(condition,params)
    local validate=false
    local WelfareManager = require("ui.welfare.welfaremanager")
    if WelfareManager.CheckIsWelfareReceive() == false then
        validate=true
    end
    return validate
end

local function CheckWeaponAnnealLevel(condition,params)
    local validate=false
    for _,equip in pairs(PlayerRole.Instance().m_Equips) do
        local equipInfo = ConfigManager.getConfigData("equip",equip.equipkey)
        if not equipInfo then
            logError("equip model is null ")
        else
            if equipInfo.type == cfg.item.EItemType.WEAPON then
                if equip.anneallevel == 0 then
                   return true
                end
            end
        end
    end
    return validate
end

local function CheckWeaponPerfuseLevel(condition,params)
    local validate=false
    for _,equip in pairs(PlayerRole.Instance().m_Equips) do
        local equipInfo = ConfigManager.getConfigData("equip",equip.equipkey)
        if not equipInfo then
            logError("equip model is null ")
        else
            if equipInfo.type == cfg.item.EItemType.WEAPON then
                if equip.perfuselevel == 0 then
                    return true
                end
            end
        end
    end
    return validate
end

local function CheckUnWeapon(condition,params)
    local validate=true
    for _,equip in pairs(PlayerRole.Instance().m_Equips) do
        local equipInfo = ConfigManager.getConfigData("equip",equip.equipkey)
        if not equipInfo then
            logError("equip model is null ")
        else
            if equipInfo.type == cfg.item.EItemType.WEAPON then
                return false
            end
        end
    end
    return validate
end

local function CheckNotInEctype(condition,params)
    local EctypeManager=require"ectype.ectypemanager"
    if  EctypeManager.IsInEctype() then
        return false
    end
    return true
end

-- 初始化条件类型
AllConditions = {
    ["cfg.cmd.condition.FirstRecharge2"]             = CheckFirstRecharge2,
    ["cfg.cmd.condition.Welfare"]             = CheckWelfare,
    ["cfg.cmd.condition.WeaponAnnealLevel"]             = CheckWeaponAnnealLevel,
    ["cfg.cmd.condition.WeaponPerfuseLevel"]             = CheckWeaponPerfuseLevel,
    ["cfg.cmd.condition.NotInEctype"]             = CheckNotInEctype,
    ["cfg.cmd.condition.UnWeapon"]               = CheckUnWeapon,
    ["cfg.cmd.condition.MinLevel"]             = CheckMinLevel,
    ["cfg.cmd.condition.MaxLevel"]             = CheckMaxLevel,
    ["cfg.cmd.condition.MinMaxLevel"]          = CheckMinMaxLevel,
    ["cfg.cmd.condition.OneItem"]              = CheckOneItem,
    ["cfg.cmd.condition.Item"]                 = CheckItem,
    ["cfg.cmd.condition.Currency"]             = CheckCurrency,
    ["cfg.cmd.condition.Currencys"]            = CheckCurrencys,

    ["cfg.cmd.condition.XuNiBi"]               = CheckXuNiBi,
    ["cfg.cmd.condition.YuanBao"]              = CheckYuanBao,
    ["cfg.cmd.condition.BindYuanBao"]          = CheckBindYuanBao,
    ["cfg.cmd.condition.LingJing"]             = CheckLingJing,
    ["cfg.cmd.condition.JingYan"]              = CheckJingYan,
    ["cfg.cmd.condition.ZaoHua"]               = CheckZaoHua,
    ["cfg.cmd.condition.WuXing"]               = CheckWuXing,
    ["cfg.cmd.condition.BangPai"]              = CheckBangPai,
    ["cfg.cmd.condition.ShiMen"]               = CheckShiMen,
    ["cfg.cmd.condition.ZhanChang"]            = CheckZhanChang,
    ["cfg.cmd.condition.ShengWang"]            = CheckShengWang,
    ["cfg.cmd.condition.HuoBanJiFen"]          = CheckHuoBanJiFen,
    ["cfg.cmd.condition.FaBaoJiFen"]           = CheckFaBaoJiFen,
    ["cfg.cmd.condition.ChengJiu"]             = CheckChengJiu,

    ["cfg.cmd.condition.Limit"]                = CheckLimit,
    ["cfg.cmd.condition.Limits"]               = CheckLimits,
    ["cfg.cmd.condition.ProfessionLimit"]      = CheckProfessionLimit,

    ["cfg.cmd.condition.VipLimits"]			   = CheckVipLimits,
    ["cfg.cmd.condition.VipLimitsLite"]        = CheckVipLimitsLite,
    ["cfg.cmd.condition.VipLimits2"]           = CheckVipLimits2,

    ["cfg.cmd.condition.MinVipLevel"]          = CheckMinVipLevel,
    ["cfg.cmd.condition.DayLimit"]             = CheckDayLimit,

    ["cfg.cmd.condition.MinFamilyLevel"]       = CheckMinFamilyLevel,
    ["cfg.cmd.condition.MinFamilyShopLevel"]   = CheckMinFamilyShopLevel,
    ["cfg.cmd.condition.FamilyMoney"]          = CheckFamilyMoney,
    ["cfg.cmd.condition.Equiped"]              = CheckEquiped,
    ["cfg.cmd.condition.OwnTask"]              = CheckOwnTask,
    ["cfg.cmd.condition.AcceptTask"]           = CheckAcceptTask,
    ["cfg.cmd.condition.CompleteTask"]         = CheckCompleteTask,
    ["cfg.cmd.condition.CompleteAchievement"]  = CheckCompleteAchievement,
    ["cfg.cmd.condition.OpenEctype"]           = CheckOpenEctype,
    ["cfg.cmd.condition.MonsterHp"]            = CheckMonsterHP,
    ["cfg.cmd.condition.MonsterAppear"]        = CheckMonsterAppear,
    ["cfg.cmd.condition.DisplayDlg"]           = CheckDisplayDlg,
    ["cfg.cmd.condition.EnterRegion"]          = CheckEnterRegion,
    ["cfg.cmd.condition.CanPlaySkill"]         = CheckCanPlaySkill,
    ["cfg.cmd.condition.OwnSkill"]             = CheckOwnSkill,
    ["cfg.cmd.condition.CanJoinActivity"]      = CheckCanJoinActivity,
    ["cfg.cmd.condition.PlayCGOver"]           = CheckPlayCGOver ,
    ["cfg.cmd.condition.LoginDay"]             = CheckLoginDay,
    ["cfg.cmd.condition.IsNavigating"]         = CheckIsNavigating,
    ["cfg.cmd.condition.JoinFamily"]           = CheckJoinFamily,
    ["cfg.cmd.condition.PetSkillUpgrade"]      = CheckPetSkillUpgrade,
    ["cfg.cmd.condition.PetLevel"]             = CheckPetLevel,
    ["cfg.cmd.condition.FirstRecharge"]        = CheckFirstRecharge,
    ["cfg.cmd.condition.HasActiveRide"]        = CheckHasActiveRide,
}

local function init()
    UIManager    =  require "uimanager"
    PlayerRole   = require "character.playerrole"
    LimitManager = require "limittimemanager"
    BagManager   = require "character.bagmanager"
	ItemManager  = require "item.itemmanager"
    MathUtils    = require"common.mathutils"
    -----------------积分兑换begin------------------------------------
   --[[ local gradeexchange = ConfigManager.getConfig("gradeexchange")
    local fabaoexchange = {}
    local huobanexchange = {}

    for _,data in pairs(gradeexchange) do
        for _,exchange in pairs(data.exchangelist) do
            if data.currencytype == cfg.currency.CurrencyType.HuoBanJiFen then
                huobanexchange [exchange.id] = exchange
            elseif data.currencytype == cfg.currency.CurrencyType.FaBaoJiFen then
                fabaoexchange [exchange.id] = exchange
            end
        end
    end
    -----------------积分兑换end------------------------------------

    -----------------运营活动begin------------------------------------
    local operationalactivityCfg = ConfigManager.getConfig("operationalactivity")
    local operationalactivity = {}

    for _, data in pairs(operationalactivityCfg) do
        for _, activityinfo in pairs(data.activityinfo) do
            operationalactivity[activityinfo.id] = activityinfo.condition
        end
    end
    -----------------运营活动end------------------------------------]]
	-- 初始化模块
AllModules = {
    [cfg.cmd.ConfigId.MALL]                 = ConfigManager.getConfig("mall"),
    [cfg.cmd.ConfigId.ITEMBASIC]            = ConfigManager.getConfig("itembasic"),
    [cfg.cmd.ConfigId.REVIVE]               = ConfigManager.getConfig("revive"),
    [cfg.cmd.ConfigId.PERSONAL_BOSS_ECTYPE] = ConfigManager.getConfig("personalboss"),
    [cfg.cmd.ConfigId.FAMILY_PRAY]          = ConfigManager.getConfig("pray"),
    [cfg.cmd.ConfigId.EXCHANGE_HUOBAN]      = huobanexchange,
    [cfg.cmd.ConfigId.EXCHANGE_FABAO]       = fabaoexchange,
    [cfg.cmd.ConfigId.FAMILY_LEVEL_BONUS]   = ConfigManager.getConfig("familybonus"),
    [cfg.cmd.ConfigId.OPERATION_ACTIVITY]   = operationalactivity,
}

end


------------------------------------------------------------------------------------------------------------
--[[
功能：校验cmd是否满足条件（校验csv的一行数据 moduleid确定csv,cmdid确定一行数据）
入参：params{moduleid,cmdid,showsysteminfo,num}
      moduleid          type:enum(cmd.xml - ConfigId)           模块ID                【必填】
      cmdid             type:int(csv的index)                    命令ID                【必填】
      showsysteminfo    type:bool                               是否显示校验信息      【默认为false】
      num               type:int                                命令执行次数          【默认为1】
返回值：
      [1]               type:bool                               是否满足
      [2]               type:string                             提示信息
--]]
------------------------------------------------------------------------------------------------------------
local function Check(params)
    local validate = true
    local info = ""
    if params.moduleid == nil or params.cmdid == nil then
        info = "moduleid or cmdid is nil"
        if params.showsysteminfo then UIManager.ShowSystemFlyText(info) end
        return false, info
    end
    if params.num == nil then params.num = 1 end
    --printt(params)
   -- printt(AllConditions)
    if AllModules[params.moduleid] then
        local cmd = AllModules[params.moduleid][params.cmdid]
        if cmd then
            --printt(cmd)
            for k, condition in pairs(cmd) do
                if type(condition) == "table" and AllConditions[condition.class] then
                  --  printyellow(string.format("checkcmd {moudleid:%s , cmdid:%s ,condition:%s}", params.moduleid, params.cmdid, condition.class))
                    validate, info = AllConditions[condition.class](condition, params)
                    if not validate then
                        break
                    end
                end
            end
        end
    end
    if params.showsysteminfo and info and info ~= "" then UIManager.ShowSystemFlyText(info) end
    --printyellow(string.format("validate : %s , info : %s", validate, info))
    return validate, info
end

------------------------------------------------------------------------------------------------------------
--[[
功能：校验cmd是否满足条件（当没有moduleid时使用该方法校验）
1)	当params.data的type为condition时，校验单一condition
2)	当params.data 为csv的一行数据时，遍历csv中所有condition，逐个校验
3)	当condition中包含limit限制时，因为limit condition中用到了moduleid，该校验方法不正确，请用Check方法替代

入参：params{data,showsysteminfo,num}
      data              type:table                              命令数据
      showsysteminfo    type:bool                               是否显示校验信息      【默认为false】
      num               type:int                                命令执行次数          【默认为1】
返回值：
      [1]               type:bool                               是否满足
      [2]               type:string                             提示信息
--]]
------------------------------------------------------------------------------------------------------------
CheckData = function(params)
    local validate = true
    local info = ""
    if params.data == nil then
        info = "data is nil"
        if params.showsysteminfo then UIManager.ShowSystemFlyText(info) end
        return false, info
    end
    if type(params.data) ~= "table" then
        info = "data type isn't table"
        if params.showsysteminfo then UIManager.ShowSystemFlyText(info) end
        return false, info
    end
    if params.num == nil then params.num = 1 end
--	local temp = params.data.class
	--local 
	--printyellow(temp)
    if AllConditions[params.data.class] then
        validate, info = AllConditions[params.data.class](params.data, params)
    else
        for k, condition in pairs(params.data) do
            if type(condition) == "table" and AllConditions[condition.class] then
                validate, info = AllConditions[condition.class](condition, params)
                if not validate then
                    break
                end
            end
        end
    end
    if params.showsysteminfo and info and info ~= "" then UIManager.ShowSystemFlyText(info) end
    --printyellow(string.format("validate : %s , info : %s", validate, info))
    return validate, info
end


return {
    init               = init,
    Check              = Check,
	CheckData          = CheckData,
    CheckCompleteTask  = CheckCompleteTask,
    CheckVipLimitsLite = CheckVipLimitsLite,
}
