--local lotterymanager = require "ui.lottery.lotterymanager"
local require   = require
local print     = print
local printt    = printt
local ItemEnum 		= require("item.itemenum")
local ItemManager 	= require("item.itemmanager")
local BagManager    = require "character.bagmanager"
local LotteryData  = require "ui.lottery.lotterydata"
local network      = require "network"
local uimanager    = require("uimanager")
local gameevent    = require "gameevent"
local dlgname = "lottery.dlglottery"
local tabname = "lottery.tablottery_result"
local recruitState = true

local function Refresh()
    uimanager.refresh("lottery.tablottery_partner")
    uimanager.refresh("lottery.tablottery_talisman")
    uimanager.refresh("lottery.tablotteryscoreexchange")
end

local chickState = false

 ----------------------------------------------------------
 ----------兑换开始
 ----------------------------------------------------------
local gradeexchanges = {} --{exchangetype,GradeExchange}


local function InitGradeExchanges()
    local gradeexchange = ConfigManager.getConfig("gradeexchange")
    gradeexchanges = {}
    for _,data in pairs(gradeexchange) do
        gradeexchanges[data.currencytype] = {} 
        gradeexchanges[data.currencytype].exchangetype = data.cost
        gradeexchanges[data.currencytype].exchangelist = {}
        for _,exchange in pairs(data.exchangelist) do 
            local ge = {}
            ge.Id = exchange.id
            ge.Data = exchange
            ge.Item = ItemManager.CreateItemBaseById(exchange.item.itemid,nil,exchange.item.amount)
            table.insert(gradeexchanges[data.currencytype].exchangelist, ge)
        end 
    end

end

local function GetPickType(recievedcurrencytype)
    if recievedcurrencytype == cfg.currency.CurrencyType.HuoBanJiFen  then 
        return  cfg.lottery.PickType.HUO_BAN
    elseif recievedcurrencytype == cfg.currency.CurrencyType.FaBaoJiFen then 
        return cfg.lottery.PickType.FA_BAO
    end
    return nil
end

local function GetLimitType(exchangetyep)
    if exchangetyep == cfg.lottery.PickType.HUO_BAN  then 
        return cfg.cmd.ConfigId.EXCHANGE_HUOBAN
    elseif exchangetyep == cfg.lottery.PickType.FA_BAO then 
        return cfg.cmd.ConfigId.EXCHANGE_FABAO
    end
    return nil
end


local function GetExchange(recievedcurrencytype,id)
    if gradeexchanges then 
        for _,v in pairs(gradeexchanges[recievedcurrencytype]) do
            if v.Id == id then 
                return v
            end 
        end
    end
    return nil
end 



local function GetGradeExchanges()
    return gradeexchanges
end



local function CScoreExchange(exchangetype,id)
    local validate, info = checkcmd.Check( { moduleid = GetLimitType(exchangetype), cmdid = id, num = 1, showsysteminfo = true })
    if validate then
        local re = lx.gs.pickcard.msg.CScoreExchange({ exchangetyep = exchangetype,id = id})
        network.send(re)
    end
end

local function onmsg_SScoreExchange(msg)
    uimanager.ShowSystemFlyText(LocalString.DlgLottery_Success) --temp code
    Refresh()
end

 ----------------------------------------------------------
 ----------兑换开始
 ----------------------------------------------------------

local lotterys = {}
local pickcardtimes = {}

local function GetPickCardTime( picktype) 
    return pickcardtimes[picktype] or 0
end 


local function GetLotteryTextures()
    return ConfigManager.getConfig("lotterytexture")
end

--单个伙伴的数据LotteryData基类lotterys是存储所有伙伴的List
local function GetLotteryDatasByCurrencyType(currencytype)
    return lotterys[currencytype]
end 

local function GetLotteryDatasByPickType(picktype)
    for recievedcurrency,texture in pairs(GetLotteryTextures()) do 
        for level ,texturelevel in pairs( texture.levels) do 
            for _,texturedetail in pairs(texturelevel.texturedetail) do 
                if texturedetail.freetype == picktype or texturedetail.type == picktype then 
                    local lotterydatas = {}
                    for lotterytype,_ in pairs(texturelevel.texturedetail) do
                        table.insert(lotterydatas,LotteryData:new(recievedcurrency,level,lotterytype))
                    end 
                    table.sort(lotterydatas,function (a,b) return a:Compare(b) end)
                    return lotterydatas
                end 
            end 
        end 
    end 
    return nil
end 



local function CPickCard(data)
	print("_+++++++++++++++++++++CPickCard++++++++++++++++++++++++")
    local validate = false
    local picktype = data.m_TextureData.type
    if data:IsFree() or data:CanUseItem() then 
        picktype = data.m_TextureData.freetype
        validate = true
    else 
        local num = data.m_LotteryType == cfg.lottery.LotterType.ONE_LOTTERY and 1 or 10
        validate = checkcmd.CheckData( { data = data.m_Data.requirecurrency, num = num, showsysteminfo = true })
        if not validate then
            local currentdlgname = uimanager.currentdialogname()
            printyellow("currentdlgname",currentdlgname)
            return ItemManager.GetSource(data.m_Data.requirecurrency.currencytype,currentdlgname)
        end 
    end 
    if picktype == 8 or picktype == 7 or picktype == 10 or picktype == 11 then 
        local num = data.m_LotteryType == cfg.lottery.LotterType.ONE_LOTTERY and 1 or 10
        if BagManager.GetUnLockedSize(cfg.bag.BagType.TALISMAN) - BagManager.GetItemSlotsNum(cfg.bag.BagType.TALISMAN) < num then 
            validate = false
            return uimanager.ShowSystemFlyText(LocalString.Exchange_BagTransFull)
        end
    end
    if validate then
		print("lx.gs.pickcard.msg.CPickCardByType")
        local re = lx.gs.pickcard.msg.CPickCardByType({ picktype = picktype})
        network.send(re)
        recruitState = false
    end
end



local function onmsg_SPickCardByType(msg)
	print("+++++++++++++++++++++++onmsg_SPickCardByType++++++++++++++++++++++++++++++++++++++")
    local LotteryTextures = GetLotteryTextures()
    local lotterydatas = GetLotteryDatasByPickType(msg.picktype)
    local results = {} 
    for _,bonusinfo in ipairs(msg.pickbonus) do 
        local iteminfo = {}
        
        iteminfo.issplit = bonusinfo.issplit>0
        if iteminfo.issplit then 
            iteminfo.wholecard = true
            for id,count in pairs(bonusinfo.bonus.items) do 
                iteminfo.itemid = id
                iteminfo.count = count
                break
            end 
            for id,count in pairs(bonusinfo.splitbonus.items) do 
                iteminfo.showitemid = id
                iteminfo.showitemcount = count
                break
            end
        else 
            for id,count in pairs(bonusinfo.bonus.items) do 
                iteminfo.itemid = id
                iteminfo.count = count
                iteminfo.showitemid = id
                iteminfo.showitemcount = count
                break
            end 
        end 
        iteminfo.item = ItemManager.CreateItemBaseById(iteminfo.itemid,nil,iteminfo.count)
        iteminfo.showitem = ItemManager.CreateItemBaseById(iteminfo.showitemid,nil,iteminfo.showitemcount)

        iteminfo.wholecard = false
        local itemtype = ItemManager.GetItemType(iteminfo.itemid)
        local color = colorutil.GetQualityStr(iteminfo.showitem:GetQuality())
        iteminfo.itemtype = itemtype
        if itemtype == ItemEnum.ItemBaseType.Pet then 
            iteminfo.wholecard = true
            
            iteminfo.title = string.format(LocalString.DlgLottery_WholeCard ,LotteryTextures[cfg.currency.CurrencyType.HuoBanJiFen].name,color,iteminfo.item:GetName())
            iteminfo.config = ItemManager.GetItemData(iteminfo.itemid)
            
        elseif itemtype == ItemEnum.ItemBaseType.Talisman then 
            iteminfo.wholecard = true
            iteminfo.title = string.format(LocalString.DlgLottery_Weapon ,color,iteminfo.item:GetName())
            iteminfo.config = ItemManager.GetItemData(iteminfo.itemid)
        end

        table.insert( results , iteminfo)
    end 
    local tablottery_result  = require "ui.lottery.tablottery_result"
    tablottery_result.showresult(results,lotterydatas)
    
    Refresh()
   
end

local function onmsg_SPickcardTimes(msg) 
    pickcardtimes = msg
    Refresh()
end 



local function onmsg_SError(msg)
    if msg.errcode ~= lx.gs.pickcard.msg.SError.OK then
        uimanager.ShowSystemFlyText(LocalString.DlgLottery_SError[msg.errcode])
    end
end

local function InitLotterys()
    lotterys = {}
    for recievedcurrency,texture in pairs(GetLotteryTextures()) do 
        local lotterydatas = {}
        for level ,texturelevel in pairs( texture.levels) do 
            for lotterytype,texturedetail in pairs(texturelevel.texturedetail) do 
                table.insert(lotterydatas,LotteryData:new(recievedcurrency,level,lotterytype))
            end 
        end 
        table.sort(lotterydatas,function (a,b) return a:Compare(b) end)
        lotterys[recievedcurrency] = lotterydatas
    end 
end


local function OnDlgDialogRefresh() 
    if uimanager.isshow(tabname) then 
        uimanager.call(tabname,"ondlgdialogrefresh")
    end
end 



local function init()
   
    InitLotterys()
    InitGradeExchanges()
    network.add_listeners({
        {"lx.gs.pickcard.msg.SPickCardByType", onmsg_SPickCardByType},
        {"lx.gs.pickcard.msg.SScoreExchange", onmsg_SScoreExchange},
        {"lx.gs.pickcard.msg.SPickcardTimes", onmsg_SPickcardTimes},
        {"lx.gs.pickcard.msg.SError", onmsg_SError},

        
    })

    gameevent.evt_dlgdialogrefresh:add(OnDlgDialogRefresh)

end

local function UnRead_HuoBanJiFen()
    for _,lotterydata in pairs(lotterys[cfg.currency.CurrencyType.HuoBanJiFen]) do 
        if lotterydata:IsFree() or lotterydata:CanUseItem() then 
            return true
        end 
    end 
    return false 
end

local function UnRead_FaBaoJiFen()
    local ModuleLockManager=require"ui.modulelock.modulelockmanager"
    local status=ModuleLockManager.GetModuleStatusByIndex("lottery.dlglottery",2)
    if status==defineenum.ModuleStatus.UNLOCK then
        for _,lotterydata in pairs(lotterys[cfg.currency.CurrencyType.FaBaoJiFen]) do 
            if lotterydata:IsFree() or lotterydata:CanUseItem() then 
                return true
            end
        end 
    end 
    return false  
end

local function UnRead()
    return UnRead_HuoBanJiFen() or UnRead_FaBaoJiFen() or require("ui.welfare.welfaremanager").UntreeRed()
end


--设置点击事件开关
local function setRecruit(state)
    recruitState = state
end

--获取状态
local function getRecruit()
    return recruitState 
end

return {
    init                = init,
    CPickCard           = CPickCard,
    CScoreExchange      = CScoreExchange,
    GetLotteryTextures  = GetLotteryTextures,
    GetGradeExchanges   = GetGradeExchanges,

    GetLimitType        = GetLimitType,
    
    Refresh             = Refresh,
    UnRead              = UnRead,
    UnRead_HuoBanJiFen  = UnRead_HuoBanJiFen,
    UnRead_FaBaoJiFen   = UnRead_FaBaoJiFen,

    GetLotteryDatasByCurrencyType = GetLotteryDatasByCurrencyType,
    GetLotteryDatasByPickType = GetLotteryDatasByPickType,
    GetPickCardTime = GetPickCardTime,
    setRecruit = setRecruit,
    getRecruit = getRecruit,
}
