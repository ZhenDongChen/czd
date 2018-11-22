local ConfigMgr 	= require("cfg.configmanager")
local define		= require("define")
local ItemManager	= require("item.itemmanager")
local UIManager 	= require("uimanager")
local CheckCmd      = require("common.checkcmd")
local Monster       = require("character.monster")
local LimitManager  = require("limittimemanager")
local BossInfo      = Class:new()

function BossInfo:__new(configId)
    local bossData = ConfigMgr.getConfigData("personalboss",configId)

    self.m_Id       		= configId                      --BossID
	self.m_Name				= bossData.name         or ""	--Boss名称
	self.m_Introduction		= bossData.introduction or ""	--Boss说明
	self.m_TalkContent		= bossData.bosstalk     or ""	--Boss聊天内容
	self.m_ReCommendPower	= bossData.battlepower  or 0	--推荐战力
	self.m_CombatedTimes	= 0			                    --已战斗次数
	
    self.m_TaskLimit        = bossData.tasklimit
    self.m_TaskId           = self.m_TaskLimit.taskid
    self.m_TaskDescribe     = bossData.taskdescribe
    
    self.m_DayLimit         = bossData.daylimit
    self.m_MaxCombatTimes	= self:GetTotalTimes()	--最大战斗次数
	self.m_ModelPath		= bossData.bossicon		        --Boss模型地址
	self.m_AllowIcon		= bossData.allowicon		        --头像
	self.m_ForbidIcon		= bossData.forbidicon		    --灰色头像
	self.m_LimitCondition	= {
        Level               = bossData.openlevel.level,		           
        VipLevel            = bossData.viplimit.level,	                
    }                                                       --挑战条件
	self.m_SceneId			= self.m_Id			            --场景ID
    self.m_BossId           = bossData.bossid
    
    self.m_Rewards			= {}		                    --Boss奖励
	self.m_Model			= nil		                    --Boss模型
	self.m_ectypeId         = bossData.ectypeid
    
    for i,itemId in ipairs(bossData.showbonusitemid) do
        local rewardsItem = ItemManager.CreateItemBaseById(itemId)
        table.insert( self.m_Rewards, rewardsItem )
    end
    self:SetServerInfo()
end

function BossInfo:GetChallengedTimes()
    local limit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.PERSONAL_BOSS_ECTYPE, self.m_Id)
    local costtime = 0
    if limit then
        local daylimit = limit[cfg.cmd.condition.LimitType.DAY]
        costtime = (((daylimit ~= nil) and daylimit) or 0)
    end
    return costtime
end

function BossInfo:GetTotalTimes(roleVipLevel)
    local daylimit = self.m_DayLimit
    local vipLevel = roleVipLevel or PlayerRole:Instance().m_VipLevel
    local entertimes = (((vipLevel < #daylimit.entertimes) and daylimit.entertimes[vipLevel]) or daylimit.entertimes[#daylimit.entertimes])
    return entertimes
end

function BossInfo:GetCost(count)
    local daylimit = self.m_DayLimit
    local amout = (((count < #daylimit.amout) and daylimit.amout[count]) or daylimit.amout[#daylimit.amout])
    return amout
end


function BossInfo:SetServerInfo()
    local limit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.PERSONAL_BOSS_ECTYPE, self.m_Id)
end

function BossInfo:GetChallengeCost()
    local limit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.PERSONAL_BOSS_ECTYPE, self.m_Id)
    local costtime = 0
    if limit then
        local daylimit = limit[cfg.cmd.condition.LimitType.DAY]
        costtime = (((daylimit ~= nil) and daylimit) or 0)
    end
    return self:GetCost(costtime+1)
end

function BossInfo:GetCostCurrencyName()
    local daylimit = self.m_DayLimit
    local limitType = daylimit.currencytype
    local item = ItemManager.CreateItemBaseById(limitType, {}, nil)
    return item:GetName() --LocalString.CurrencyType[limitType]
end

function BossInfo:GetCostCurrencyType()
	local daylimit = self.m_DayLimit
    local limitType = daylimit.currencytype
	return limitType
end



function BossInfo:GetFreeTimes()
    local daylimit = self.m_DayLimit
    local freeTime = 0
    for i, k in pairs(daylimit.amout) do
        if k <= 0 then
            freeTime = freeTime + 1
        end
    end
    return freeTime
end




function BossInfo:GetRemainTimes()
    local limit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.PERSONAL_BOSS_ECTYPE, self.m_Id)
    local costtime = 0
    if limit then
        local daylimit = limit[cfg.cmd.condition.LimitType.DAY]
        costtime = (((daylimit ~= nil) and daylimit) or 0)
    end
    return self:GetTotalTimes() - costtime
end

function BossInfo:LoadCharacter(callback)
    local bossData = ConfigMgr.getConfigData("personalboss",self.m_Id)
    local monster = Monster:new()
    monster.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    monster:RegisterOnLoaded(function(obj)
        if callback then
            callback(monster, obj)
        end
    end)
    monster:init(self.m_BossId,self.m_BossId,false)
    return monster
end

function BossInfo:SetUIPos(obj)
    local bossData = ConfigMgr.getConfigData("personalboss",self.m_Id)
    if obj then
        obj.transform.localPosition = Vector3(bossData.localposx,bossData.localposy - 200,-2)--Vector3(-0.15,-0.20,-2)
        obj.transform.localRotation = Quaternion.Euler(0,180,0)
       -- obj.transform.localScale = Vector3(bossData.scale * 200,bossData.scale * 200,bossData.scale * 200)
    end
end

function BossInfo:GetUIScale()
    local bossData = ConfigMgr.getConfigData("personalboss",self.m_Id)
    return bossData.scale
end


function BossInfo:CanChanllenge()
    local chanllengedTimes = self:GetChallengedTimes()
    local allfreeTimes = self:GetFreeTimes()
    if chanllengedTimes < allfreeTimes then
        return true
    end
    return false
end
function BossInfo:GetRewards()
    return self.m_Rewards
end

function BossInfo:GetBossID()
	return self.m_BossId
end

function BossInfo:GetEcTypeID()
	
	return self.m_ectypeId
end

return BossInfo
