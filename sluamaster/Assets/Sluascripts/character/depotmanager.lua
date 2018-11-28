local print         = print
local require       = require
local gameevent     = require "gameevent"
local network       = require "network"
local uimanager     = require("uimanager")
local ConfigManager = require("cfg.configmanager")
local bagmanager    = require "character.bagmanager"
local PlayerRole    = require("character.playerrole")

local depotInfo = { savedCurrency = 0, } 

local function SendCTransferItem(bagType, Pos)
    local msg = lx.gs.depot.msg.CTransferItem( { bagtype = bagType, pos = Pos })
    network.send(msg)
end

local function SendCTakeGoldCoin(Amount)
    local msg = lx.gs.depot.msg.CTakeGoldCoin( { amount = Amount })
    network.send(msg)
end

local function SendCSaveGoldCoin(Amount)
    local msg = lx.gs.depot.msg.CSaveGoldCoin( { amount = Amount })
    network.send(msg)
end

local function SendCSyncFamilyDepot()
    network.create_and_send("lx.gs.family.msg.CSyncFamilyDepot")
end

local function SendCPutEquipToFamilyDepot(bagPos)
    local msg = lx.gs.family.msg.CPutEquipToFamilyDepot({ pos = bagPos })
    network.send(msg)
end
-- id ΪΨһid
local function SendCFamilyDepotEquipGive(id,roleId)
    local msg = lx.gs.family.msg.CFamilyDepotEquipGive({ itemid = id,recieveid = roleId })
    network.send(msg)
end

local function GetDepotSavedCurrency()
    return depotInfo.savedCurrency
end
-- region msg
local function OnMsg_SSaveGoldCoin(msg)
    depotInfo.savedCurrency = msg.depotgoldcoin
    if uimanager.isshow("dlgwarehouse") then
        uimanager.call("dlgwarehouse", "RefreshMoneyText")
    end
end

local function OnMsg_STakeGoldCoin(msg)
    depotInfo.savedCurrency = msg.depotgoldcoin;
    if uimanager.isshow("dlgwarehouse") then
        uimanager.call("dlgwarehouse", "RefreshMoneyText")
    end
end

local function OnMsg_SSyncGoldCoin(msg)
    depotInfo.savedCurrency = msg.depotgoldcoin;
    if uimanager.isshow("dlgwarehouse") then
        uimanager.call("dlgwarehouse", "RefreshMoneyText")
    end
end

local function OnMsg_SMove(msg)
    local deletedItem = bagmanager.GetBag(msg.srcbagtype):DeleteItem2(msg.srcpos);
    bagmanager.AddItem(msg.destbagtype, msg.destpos, deletedItem)
    uimanager.refresh("dlgwarehouse")
end
-- endregion msg
local function Release()
    depotInfo.savedCurrency = 0
end

local function Logout()
    Release()
end

local function NavigateToDepotNPC()
    local npcID = 23000455
    local worldmapid
    local pos
    local direction
    local charactermanager = require "character.charactermanager"
    local CharacterType    = defineenum.CharacterType
    worldmapid, pos, direction = charactermanager.GetAgentPositionInCSV(npcID, CharacterType.Npc)

    PlayerRole:Instance():navigateTo( {
        targetPos           = pos,
        roleId              = npcID,
        mapId               = worldmapid,
        eulerAnglesOfRole   = direction,
        newStopLength       = 100,
        isAdjustByRideState = true,
        callback            = function()
            uimanager.showdialog("dlgwarehouse")
        end
    } )
end


local function init()
    network.add_listeners( {
        { "lx.gs.bag.msg.SMove", OnMsg_SMove },
        -- gold info
        { "lx.gs.depot.msg.SSyncGoldCoin", OnMsg_SSyncGoldCoin },
    } ,"depotmanager")
    gameevent.evt_system_message:add("logout", Logout)
end

return {
    init                       = init,
    SendCTransferItem          = SendCTransferItem,
    SendCTakeGoldCoin          = SendCTakeGoldCoin,
    SendCSaveGoldCoin          = SendCSaveGoldCoin,
    SendCSyncFamilyDepot       = SendCSyncFamilyDepot,
    SendCPutEquipToFamilyDepot = SendCPutEquipToFamilyDepot,
    SendCFamilyDepotEquipGive  = SendCFamilyDepotEquipGive,
    GetDepotSavedCurrency      = GetDepotSavedCurrency,
    NavigateToDepotNPC         = NavigateToDepotNPC,
}
