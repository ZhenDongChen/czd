--local LotteryData  = require "ui.lottery.lotterydata"

local BagManager    
local ItemManager 	
local LimitManager
local LotteryManager 

local LotteryData = Class:new()

function LotteryData:__new(currencytype,lotterylevel,lotterytype)
    LimitManager   = require "limittimemanager"
    ItemManager    = require "item.itemmanager" 
    BagManager     = require "character.bagmanager"
    LotteryManager = require "ui.lottery.lotterymanager"

    local lotterytexture = ConfigManager.getConfigData("lotterytexture",currencytype)
    self.m_CurrencyType = currencytype
    self.m_LotteryLevel = lotterylevel
    self.m_LotteryType = lotterytype 
    self.m_TextureLevelData = lotterytexture.levels[lotterylevel]
    self.m_TextureData = self.m_TextureLevelData.texturedetail[lotterytype]
    self.m_Name = lotterytexture.name

    if self.m_TextureData.freetype ~= cfg.lottery.HighLotteryType.Null then 
        local cfgid = ConfigManager.getConfigData("lotterytypetocfg",self.m_TextureData.freetype).cfgid
        self.m_FreeData = ConfigManager.getConfigData("highlottery",cfgid)
    end 

    if self.m_TextureData.type ~= cfg.lottery.HighLotteryType.Null then 
        local cfgid = ConfigManager.getConfigData("lotterytypetocfg",self.m_TextureData.type).cfgid
        self.m_Data = ConfigManager.getConfigData("highlottery",cfgid)
    end 
end

--获取抽卡道具数量
function LotteryData:GetItemCount()
    --printyellow("GetItemCount",self:GetRequireItem().itemid,BagManager.GetItemNumById(self:GetRequireItem().itemid))
    return BagManager.GetItemNumById(self:GetRequireItem().itemid)
end 

--获取冷却时间
function LotteryData:GetCdLeftTime()
    return LimitManager.GetLeftTime(cfg.cmd.ConfigId.PICKCARD,self.m_FreeData.id)
end 

--获取免费次数
function LotteryData:GetLeftTimes()
    return self.m_FreeData.refreshtimes.num - LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.PICKCARD,self.m_FreeData.id)
end

--是否冷却好
function LotteryData:IsCoolDown()
    if self.m_TextureData.iscooldown then 
        return LimitManager.IsReady(cfg.cmd.ConfigId.PICKCARD,self.m_FreeData.id) 
    end 
    return false
end

--是否有免费次数
function LotteryData:IsDayLimit()
    if self.m_TextureData.isdaylimit then 
        return self:GetLeftTimes() >0
    end 
    return false
end

--是否免费
function LotteryData:IsFree()
    return self:IsCoolDown() or self:IsDayLimit()
end 

--是否有抽卡道具
function LotteryData:CanUseItem()
    if self.m_TextureData.canuseitem then 
        return self:GetItemCount() >0
    end 
    return false
end

function LotteryData:GetMsg()
    if self.m_TextureData.iscooldown then 
        return string.format(LocalString.DlgLottery_FreeLeftTime ,timeutils.getDateTimeString(self:GetCdLeftTime(),"hh:mm:ss"))
    elseif self.m_TextureData.isdaylimit then
        return string.format(LocalString.DlgLottery_FreeTimes,self:GetLeftTimes())
    end 
    return ""
end 



function LotteryData:GetRequireItem() 
    if self.m_LotteryType == cfg.lottery.LotterType.ONE_LOTTERY then 
        return self.m_FreeData.requireitem
    else 
        return self.m_FreeData.requireitem2
    end 
end 

function LotteryData:GetIcon() 
    if not self:IsFree() and self:CanUseItem() then 
        --printyellow("self:GetRequireItem().itemid",self:GetRequireItem().itemid,ItemManager.CreateItemBaseById(self:GetRequireItem().itemid):GetIconName())
        return ItemManager.CreateItemBaseById(self:GetRequireItem().itemid):GetIconName()
    else 
        return ItemManager.CreateItemBaseById(self.m_Data.requirecurrency.currencytype):GetIconName()
    end 
end 

function LotteryData:GetAmount() 
    if self:IsFree() then 
        return LocalString.DlgLottery_Free
    elseif self:CanUseItem() then 
        return self:GetItemCount()
    else
        local num = self.m_LotteryType == cfg.lottery.LotterType.ONE_LOTTERY and 1 or 10
        return self.m_Data.requirecurrency.amount * num
    end 
end 

function LotteryData:Compare(other)
    if self.m_LotteryLevel<other.m_LotteryLevel then 
        return true 
    elseif self.m_LotteryLevel>other.m_LotteryLevel then 
        return false
    else 
        return self.m_LotteryType<other.m_LotteryType 
    end 
end 

function LotteryData:Desc()
    if self.m_TextureData.showdesc then 
        if self.m_LotteryType == cfg.lottery.LotterType.ONE_LOTTERY then 
            return string.format(self.m_TextureData.desc,LotteryManager.GetPickCardTime(self.m_TextureLevelData.pickcardtimes))
        else 
            return self.m_TextureData.desc
        end 
    end 
    return ""
end 

return LotteryData