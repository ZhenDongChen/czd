local ItemManager   = require("item.itemmanager")
local Network       = require("network")
local UIManager     = require("uimanager")
local BagManager    = require("character.bagmanager")
local ItemEnum      = require("item.itemenum")
local ConfigManager = require("cfg.configmanager")
local LimitManager  = require("limittimemanager")
local talisman
local listenerId

local TalismanSystemConfig = {
    FiveElementsSystemLevel = 0,
    BasicAttributeNum = 7,
    ConsumeTalismans = {},
  --  FreeTransLuckyTimes = 5,
   -- TransLuckCost = 10,
    --TransBestLuckCost = 30,
    WashCostJinBi = 5,
    WashCostYuanBao = 6,
    ChangeWuxingCost = 100,


    m_LuckyType = 1,
    m_WashCount = 0,
}

local function GetTalismanBag()

end


local function RefreshUI(talisman)
	if UIManager.isshow("playerrole.talisman.tabtalisman") then
		UIManager.refresh("playerrole.talisman.tabtalisman")
	end
    --UIManager.refresh("playerrole.talisman.dlgtalisman_update")
    --UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")
    --UIManager.refresh("playerrole.talisman.dlgtalisman_get")
    --UIManager.refresh("playerrole.talisman.dlgtalisman_get")
end
local function GetCurrency(type)
    if type == nil then
        return PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.XuNiBi)
    end
    if type == "YuanBao" then
        return PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.YuanBao)
    end
    if type == "ZaoHua" then
        return PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ZaoHua)
    end
    return 0
end
--==========================================================================
--获取当前装备的法宝

local function GetCurrentTalisman()
    local items = BagManager.GetItems(cfg.bag.BagType.TALISMAN_BODY)
    if items and #items > 0 and items[1] then
        return items[1]
    end
    return nil
end
local function GetItemByPosition(bagType,position)
    return BagManager:GetItemBySlot(bagType,position)
end


local function GetLocation(talisman)
    local currentTalisman = GetCurrentTalisman()
    if currentTalisman and currentTalisman.ID == talisman.ID then
        return cfg.bag.BagType.TALISMAN_BODY, talisman.BagPos
    else
        return cfg.bag.BagType.TALISMAN, talisman.BagPos
    end
end

local function GetTalisman(bagType, bagPos)
    local talisman
    if bagType == cfg.bag.BagType.TALISMAN_BODY then
        talisman = GetCurrentTalisman()
    else
        talisman = BagManager.GetItemBySlot(bagType,bagPos)
    end

    if talisman ~= nil then
        return talisman
    end
    logError("Can not find talisman => BagType:" .. tostring(bagType) .. " => BagPos:" .. tostring(bagPos))
    return nil
end

--==========================================================================
--装备法宝  卸载法宝

local function EquipTalisman(talisman)
    --printyellowmodule(Local.LogModuals.Talisman,"Equip Talisman: "..talisman.BagPos)
    BagManager.SendCEquipTalisman(talisman.BagPos)
end

local function UnEquipTalisman(talisman)
    --printyellowmodule(Local.LogModuals.Talisman,"UnEquip Talisman")
    BagManager.SendCUnEquipTalisman()
end

--==========================================================================
--法宝升级
local function AddNormalExp(talisman,item,num)
    num = num or 1
    --printyellowmodule(Local.LogModuals.Talisman,string.format("AddNormalExp: %s, %s",  item.BagPos, num))

    local talismanBagType, talismanBagPos = GetLocation(talisman)
    local ctalisman = GetCurrentTalisman()
    if item.BagPos > 0 and num > 0 then
        local re = lx.gs.talisman.CAddNormalExp({ bagtype =talismanBagType, pos = talismanBagPos, materialpos = item.BagPos, materialnum = num})
        Network.send(re)
    end
end

local function OnMsgSAddNormalExp(msg)
    --printyellowmodule(Local.LogModuals.Talisman,msg)
    local talisman = GetTalisman(msg.bagtype, msg.pos)

    if msg.newlevel then
        talisman:SetNormalLevel(msg.newlevel)
    end
    if msg.newexp then
        talisman.NormalExp = msg.newexp
    end

    talisman:SetBound(true)

    UIManager.refresh("playerrole.talisman.dlgtalisman_update",{talisman=talisman})
    if UIManager.isshow("playerrole.talisman.dlgtalisman_update") then
        UIManager.call("playerrole.talisman.dlgtalisman_update","OnMsgSAddNormalExp")
    end
    UIManager.refresh("playerrole.talisman.tabtalisman")
end
--==========================================================================
--法宝升星
local function AddStarExp(talisman,costs)
    --printyellowmodule(Local.LogModuals.Talisman, string.format("AddStarExp,%s,%s" , talisman.BagPos,#costs))
    local talismanBagType, talismanBagPos = GetLocation(talisman)

    local costitems = {}
    for i, item in pairs(costs) do
        table.insert(costitems,item.BagPos)
    end

    local re = lx.gs.talisman.CAddStarExp({ bagtype =talismanBagType, pos = talismanBagPos, costtalisman = costitems})
    Network.send(re)

end

local function OnMsgSAddStarExp(msg)
    --printyellowmodule(Local.LogModuals.Talisman,msg)
    local talisman = GetTalisman(msg.bagtype, msg.pos)
    local oldStarLevel = talisman:GetStarLevel()
    if msg.newlevel then
        talisman:SetStarOrderLevel(msg.newlevel)
    end
    local newStarLevel = talisman:GetStarLevel()
    if msg.newexp then
        talisman.StarOrderExp  = msg.newexp
    end

    TalismanSystemConfig.ConsumeTalismans = {}

    talisman:SetBound(true)

    UIManager.refresh("playerrole.talisman.dlgtalisman_update",{talisman=talisman})
    UIManager.refresh("playerrole.talisman.tabtalisman")
    UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")

    if UIManager.isshow("playerrole.talisman.dlgtalisman_advanced") then
        if oldStarLevel < newStarLevel then
            UIManager.call("playerrole.talisman.dlgtalisman_advanced","OnMsgStarOrder",{star = newStarLevel})
        else
            UIManager.call("playerrole.talisman.dlgtalisman_advanced","OnMsgStarOrder",{star = nil})
        end
    end
end

--==========================================================================
--法宝觉醒
local function TalismanAwake(talisman)
    --printyellowmodule(Local.LogModuals.Talisman,string.format("AddStarExp %s" , talisman.BagPos))
    local talismanBagType, talismanBagPos = GetLocation(talisman)

    local re = lx.gs.talisman.CTalismanAwake({bagtype = talismanBagType, pos = talismanBagPos})
    Network.send(re)
end
local function OnMsgSTalismanAwake(msg)
    --printyellowmodule(Local.LogModuals.Talisman,msg)
    local talisman = GetTalisman(msg.bagtype, msg.pos)

    if msg.newlevel and talisman then
        talisman:SetAwakeLevel(msg.newlevel)
    end

    talisman:SetBound(true)

    UIManager.refresh("playerrole.talisman.tabtalisman")
    UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")

    if UIManager.isshow("playerrole.talisman.dlgtalisman_advanced") then
        UIManager.call("playerrole.talisman.dlgtalisman_advanced","OnMsgAwake",{awakeLevel = msg.newlevel})
    end

    UIManager.showorrefresh( "dlgtweenset", {
                            tweenfield  = "UIPlayTweens_Talisman_3",
                            callback    = function()

                            end})
end

--==========================================================================
--五行转化

local function ChangeWuxingType(talisman)
    --printyellowmodule(Local.LogModuals.Talisman,string.format("ChangeWuxingType ", talisman:GetId()))
    local talismanBagType, talismanBagPos = GetLocation(talisman)
    local re = lx.gs.talisman.CChangeWuxingType({bagtype = talismanBagType, pos = talismanBagPos})
    Network.send(re)
end

local function OnMsgSChangeWuxingType(msg)
    --printyellowmodule(Local.LogModuals.Talisman,msg)

    local talisman = GetTalisman(msg.bagtype, msg.pos)

    if msg.wuxingtype and talisman then
        talisman:SetFiveElementsPropertyType(msg.wuxingtype)
    end

    UIManager.refresh("playerrole.talisman.tabtalisman")
    UIManager.refresh("playerrole.talisman.dlgtalisman_advanced",{talisman = talisman})
    if UIManager.isshow("playerrole.talisman.dlgtalisman_changewuxing") then
        UIManager.call("playerrole.talisman.dlgtalisman_changewuxing","ChangeEnd",{result = msg.wuxingtype})
    end
end

--==========================================================================
--法宝转运
local function ChangeLuckType(isBestLucy)
    --printyellowmodule(Local.LogModuals.Talisman,string.format("ChangeLuckType %s", isBestLucy))
    local bestType = 0
    if isBestLucy then
        bestType = 1
    else
        bestType = 0
    end
    local re = lx.gs.talisman.CChangeLuckType({isbestlucky = bestType})
    Network.send(re)
end

local function OnMsgSLuckyInfo(msg)
    --printyellowmodule(Local.LogModuals.Talisman, msg)
    if msg.luckytype then
        TalismanSystemConfig.m_LuckyType = msg.luckytype
    end
    if msg.washcount then
        TalismanSystemConfig.m_WashCount = msg.washcount
    end
    if UIManager.isshow("playerrole.talisman.dlgtalisman_changewuxing") then
        UIManager.refresh("playerrole.talisman.dlgtalisman_changewuxing")
    end
    if UIManager.isshow("playerrole.talisman.dlgtalisman_advanced") then
        UIManager.call("playerrole.talisman.dlgtalisman_advanced","ChangeEnd",{})
    end

end

--[[
local function OnMsgSChangeLuckType(msg)
    printyellowmodule(Local.LogModuals.Talisman,msg)

    if msg.lucktype then
        TalismanSystemConfig.m_LuckyType = msg.lucktype
    end
    if msg.luckywashtimes then
        TalismanSystemConfig.m_WashCount = msg.luckywashtimes
    end
    UIManager.refresh("playerrole.talisman.dlgtalisman_changewuxing")
    UIManager.call("playerrole.talisman.dlgtalisman_advanced","ChangeEnd",{})

--    UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")

end
]]
--==========================================================================
--五行洗练
local function WuxingWash(talisman)
    --printyellowmodule(Local.LogModuals.Talisman,string.format("WuxingWash ", talisman:GetId()))
    local talismanBagType, talismanBagPos = GetLocation(talisman)
    local re = lx.gs.talisman.CWuxingWash({bagtype = talismanBagType, pos = talismanBagPos})
    Network.send(re)
end

local function WuxingWashAll(talisman,washtimesNum)
    local talismanBagType, talismanBagPos = GetLocation(talisman)
    local re = lx.gs.talisman.CWuxingWashAll({washtimes = washtimesNum,bagtype = talismanBagType, pos = talismanBagPos})
    Network.send(re)
end

local function OnMsgSWuxingWash(msg)
    --printyellowmodule(Local.LogModuals.Talisman,msg)

    local talisman = GetTalisman(msg.bagtype, msg.pos)
    --criticaltimes   洗练出现的暴击次数，如果为1表示没有
    if msg.wuxingvalue then
        talisman:SetFiveElementsPropertyValue(msg.wuxingvalue)
    end
    if msg.washtimes then
        TalismanSystemConfig.m_WashCount = msg.washtimes
    end
    UIManager.refresh("playerrole.talisman.tabtalisman")
    UIManager.refresh("playerrole.talisman.dlgtalisman_advanced",{talisman = talisman})

    if UIManager.isshow("playerrole.talisman.dlgtalisman_advanced") then
        UIManager.call("playerrole.talisman.dlgtalisman_advanced","OnMsgWash",{})
    end
end

--==========================================================================
--法宝归元
local function TalismanRecycle(talisman)
    --printyellowmodule(Local.LogModuals.Talisman,string.format("FabaoRecycle ", talisman:GetId()))
    local talismanBagType, talismanBagPos = GetLocation(talisman)
   -- printt(location)
    local re = lx.gs.talisman.CTalismanRecycle({bagtype = talismanBagType, pos = talismanBagPos})
    Network.send(re)
end

local function OnMsgSTalismanRecycle(msg)
    --printyellowmodule(Local.LogModuals.Talisman,msg)

 --   local talisman = GetTalisman(msg.fabaolocation)

    if msg.bagtype == cfg.bag.BagType.TALISMAN_BODY then

    end
    if UIManager.isshow("playerrole.talisman.dlgtalisman_advanced") then
        UIManager.call("playerrole.talisman.dlgtalisman_advanced","OnMsgDecom",{})
    end

    local timer = Timer.New(function()
        if UIManager.isshow("playerrole.talisman.tabtalisman") then
            UIManager.refresh("playerrole.talisman.tabtalisman")
        end
        if UIManager.isshow("playerrole.talisman.dlgtalisman_advanced") then
            UIManager.hide("playerrole.talisman.dlgtalisman_advanced")
        end
        UIManager.ShowSingleAlertDlg({ content = LocalString.Talisman.GuiYuan[1], })
    end, 2, 1, 1)
    timer:Start()

end

--==========================================================================
--法宝技能升级
local function UpgradeSkill(talisman,skillId)
    --printyellowmodule(Local.LogModuals.Talisman,string.format("UpgradeSkill ", talisman:GetId()))
    local talismanBagType, talismanBagPos = GetLocation(talisman)
    local re = lx.gs.talisman.CUpgradeSkill({bagtype = talismanBagType, pos = talismanBagPos, skillid = skillId})
    Network.send(re)
end

local function OnMsgSUpgradeSkill(msg)
    --printyellowmodule(Local.LogModuals.Talisman,msg)

    local talisman = GetTalisman(msg.bagtype, msg.pos)
    if talisman then
        local skill = talisman:GetSkill(msg.skillid)
        skill:SetLevel(msg.skilllevel)
        if UIManager.isshow("playerrole.talisman.tabtalisman") then
            UIManager.refresh("playerrole.talisman.tabtalisman")
            UIManager.call("playerrole.talisman.tabtalisman", "OnMsgUpdateSkill",{curTalisman = talisman, skillId = msg.skillid})
        end
    else
        logError("Can't find talisman")
    end
end

local function OnMsgSSyncTalismanCombatPower(msg)
    --printyellowmodule(Local.LogModuals.Talisman,msg)

    local talisman = GetTalisman(msg.bagtype, msg.pos)
    if talisman then
        talisman:SetPower(msg.val)
    else
        logError("Can't find talisman")
    end
end

local function OnMsgChangeCurrency(msg)
    RefreshUI()
end

local function Start()
	
	 if listenerId then
        Network.remove_listeners(listenerId)
        listenerId = nil
    end
  listenerId =  Network.add_listeners( {
        { "lx.gs.talisman.SAddNormalExp",          OnMsgSAddNormalExp      },
        { "lx.gs.talisman.SAddStarExp",            OnMsgSAddStarExp        },
        { "lx.gs.talisman.STalismanAwake",         OnMsgSTalismanAwake     },
        { "lx.gs.talisman.SLuckyInfo",             OnMsgSLuckyInfo         },
        { "lx.gs.talisman.SChangeLuckType",        OnMsgSChangeLuckType    },
        { "lx.gs.talisman.SWuxingWash",            OnMsgSWuxingWash        },
        { "lx.gs.talisman.STalismanRecycle",       OnMsgSTalismanRecycle   },
        { "lx.gs.talisman.SChangeWuxingType",      OnMsgSChangeWuxingType  },
        { "lx.gs.talisman.SUpgradeSkill",          OnMsgSUpgradeSkill      },
        { "lx.gs.role.msg.SCurrencyChange",        OnMsgChangeCurrency     },
        { "lx.gs.talisman.SSyncTalismanCombatPower",          OnMsgSSyncTalismanCombatPower      },
    } )

    local talismanfeed = ConfigManager.getConfig("talismanfeed")

    TalismanSystemConfig.ChangeWuxingCost       = cfg.talisman.TalismanFeed.CHANGE_PROPERTY_COST
end

local function GetChangeLuckTimes()
    local limit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.TALISMAN_LUCK, 0)
    if limit then
        return limit[1]
    end
    return 0
end

local function GetFreeTransLuckyTimes()
    return cfg.talisman.TalismanFeed.FREE_CHANGE_LUCK_TIMES
end


local function GetChangeLuckCost()
    return cfg.talisman.TalismanFeed.WASH_LUCK_COST
end

local function GetChangeBestLuckCost()
    return cfg.talisman.TalismanFeed.BEST_LUCK_COST
end
--完全没有强化过的法宝
local function IsWhiteTalisman(item)
    if item:GetAwakeLevel() > 0 then
        return false
    end
    if item:GetStarOrderLevel() > 1 then
        return false
    end
    if item:GetNormalLevel() > 1 then
        return false
    end
    if item:GetNormalExp() > 0 then
        return false
    end
    if item:GetStarOrderExp() > 0 then
        return false
    end
end

local function CanAddStarOrder(talisman, item)
    if item:GetConfigId() == talisman:GetConfigId() then
        return false
    end
    if IsWhiteTalisman(item) == false then
        return false
    end
    return true
end

local function CanAddAwake(talisman, item)
    if item:GetConfigId() ~= talisman:GetConfigId() then
        return false
    end
    if IsWhiteTalisman(item) == false then
        return false
    end
    return true
end

local function GetMaxStarOrderConsumeCount()
    return 7
end

local function GetLeastWashCount()
    local luckCfg = ConfigManager.getConfigData("talismanfeed",TalismanSystemConfig.m_LuckyType)
    if luckCfg and luckCfg.maxusetime then
        return luckCfg.maxusetime - TalismanSystemConfig.m_WashCount
    end
    return 0
end



local function init()

end


return {
    init    = init,
    Start   = Start,
    RefreshUI = RefreshUI,

    TalismanSystemConfig    = TalismanSystemConfig,
    GetCurrency             = GetCurrency,
    GetCurrentTalisman      = GetCurrentTalisman,
    GetTalismanListInBag    = GetTalismanListInBag,
    GetTalismansInfo        = GetTalismansInfo,

    EquipTalisman           = EquipTalisman,
    UnEquipTalisman         = UnEquipTalisman,

    AddNormalExp            = AddNormalExp,
    AddStarExp              = AddStarExp,
    TalismanAwake           = TalismanAwake,

    ChangeWuxingType        = ChangeWuxingType,
    ChangeLuckType          = ChangeLuckType,
    WuxingWash              = WuxingWash,
    WuxingWashAll           = WuxingWashAll,

    TalismanRecycle         = TalismanRecycle,

    UpgradeSkill            = UpgradeSkill,
    GetChangeLuckTimes      = GetChangeLuckTimes,
    GetFreeTransLuckyTimes  = GetFreeTransLuckyTimes,
    GetChangeLuckCost       = GetChangeLuckCost,
    GetChangeBestLuckCost   = GetChangeBestLuckCost,
   -- GetCurrentTalisman = GetCurrentTalisman,
--    EquipTalisman = EquipTalisman,
--    UnLoadCurrentTalisman = UnLoadCurrentTalisman,
    CanAddStarOrder         = CanAddStarOrder,
    CanAddAwake             = CanAddAwake,
    GetMaxStarOrderConsumeCount = GetMaxStarOrderConsumeCount,

    GetLeastWashCount = GetLeastWashCount,
}
