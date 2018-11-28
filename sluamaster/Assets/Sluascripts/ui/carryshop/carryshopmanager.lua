local PlayerRole = require "character.playerrole"
local ShopManager = require "shopmanager"
local UIManager         = require("uimanager")
local ConfigManager     = require("cfg.configmanager")

local function GetItemsByLevel(level)
	local items = {}
	local pocketshopitems = ShopManager.GetShopItemsWithoutPage(cfg.mall.MallType.POCKET_SHOP)
	-- printyellow("pocketshopitems")
	-- printt(pocketshopitems)

    local sortitems ={}
	local hpitems ={}
	local mpitems ={}
	for _,shopitem in pairs(pocketshopitems) do
--		printyellow("for pocket item")
--		printt(shopitem)
		if shopitem.requirelevel.level <= level then
			items[#items + 1] = shopitem
		end
	end
	--排序--
	--printt(items)
	table.sort(items,function(item1, item2) return(item1.id < item2.id) end)

	return items
end

local function GetConId(opentype)
--	printyellow("GetConId = ",opentype)
	local uimainreddot = ConfigManager.getConfig("uimainreddot")
	for _,item in pairs(uimainreddot) do
--			printyellow("uimainreddot = ",item.functionname)
		if item.functionname ==  opentype then
			return item.conid
		end
	end
	return 0
end

local function ShowCarryShop()

	local items = GetItemsByLevel(PlayerRole:Instance().m_Level)
	UIManager.showdialog("carryshop.dlgcarryshop",{items = items})
end

local m_callBackEnterFamilyStation  = ShowCarryShop

local function NavigateToCarryShopNPC()

	local conid = GetConId(cfg.ui.FunctionList.PHARMACY)

	if PlayerRole:Instance().m_Level < conid then
		UIManager.ShowSystemFlyText(string.format(LocalString.CarryShopNavigateLevel,conid))
		return 
	end

--	local npcID = 23000454
	local roleconfig = ConfigManager.getConfig("roleconfig")
	local npcID = roleconfig.medicalnpcid
--	printyellow("npcID = ",npcID)
    if npcID then
        local worldmapid
        local pos
        local direction
        local charactermanager = require"character.charactermanager"
        local CharacterType = defineenum.CharacterType
        worldmapid, pos, direction = charactermanager.GetAgentPositionInCSV(npcID, CharacterType.Npc)

        PlayerRole:Instance():navigateTo( {
            targetPos = pos,           
            roleId = npcID,
            mapId = worldmapid,
            eulerAnglesOfRole = direction,
            newStopLength = 100,---100,
            isAdjustByRideState = true,
            callback = function()
                if m_callBackEnterFamilyStation then                  
                   m_callBackEnterFamilyStation()
               end   
--               m_callBackEnterFamilyStation = nil
          end
        } )
    end  
end



return {
	NavigateToCarryShopNPC = NavigateToCarryShopNPC,
	GetItemsByLevel = GetItemsByLevel,
}