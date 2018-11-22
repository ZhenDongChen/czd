local Min            = math.min
local Format         = string.format
local Define         = require("define")
local defineenum     = require("defineenum")
local CheckCmd       = require("common.checkcmd")
local UIManager      = require("uimanager")
local NetWork        = require("network")
local NPC            = require("character.npc")
local ShopManager    = require("shopmanager")
local LimitManager   = require("limittimemanager")
local ConfigManager  = require("cfg.configmanager")
local PlayerRole     = require("character.playerrole")
local ItemManager    = require("item.itemmanager")
local ItemIntroduct  = require("item.itemintroduction")
local gameevent		 = require("gameevent")
local BonusManager   = require("item.bonusmanager")
local BagManager     = require("character.bagmanager")
local EventHelper    = UIEventListenerHelper

local name
local gameObject
local fields

local g_ShopType
local g_PageType
local g_NPC
local g_Time
local g_PageIndex
local g_LimitEvnetId
local g_BoughtEventId
local g_CachedListItem

-- 灵晶兑换商城不公用此界面
local TABINDEX2SHOPTYPE = 
{
	[1] = cfg.mall.MallType.DIAMOND_MALL,
	[3] = cfg.mall.MallType.BLACK_MALL,
	[4] = cfg.mall.MallType.ARENA_MALL,
    [5] = cfg.mall.MallType.TEAM_FIGHT_SCORE,
}

local function OnNPCLoaded()
	local npcTrans = g_NPC.m_Object.transform
	npcTrans.parent = fields.UITexture_Player.gameObject.transform	
	npcTrans.localScale      = Vector3.one*250
	npcTrans.rotation = Quaternion.Euler(-90,0,0)
	local npcCfg = ConfigManager.getConfigData("mallnpc",g_ShopType)
	npcTrans.localPosition = Vector3(0, npcCfg.offset, 0)
	ExtendedGameObject.SetLayerRecursively(g_NPC.m_Object, Define.Layer.LayerUICharacter)
    g_NPC:Show()
	EventHelper.SetDrag(fields.UITexture_Player, function(o, delta)
		if g_NPC then
			local npcObj = g_NPC.m_Object
			if npcObj then
				local vecRotate = Vector3(0, - delta.x, 0)
				npcObj.transform.localEulerAngles = npcObj.transform.localEulerAngles + vecRotate
			end
		end
	end )
	EventHelper.SetClick(fields.UITexture_Player,function ()
       if g_NPC and g_ShopType==cfg.mall.MallType.BLACK_MALL then
          local npcData=ConfigManager.getConfigData("npc",g_NPC.m_CsvId)
          local npcTextNum=#(npcData.opentext)
          local index=math.random(npcTextNum)
          local text=npcData.opentext[index]
          if text then
              fields.UILabel_Talk.text=text
              fields.UILabel_Talk.gameObject:SetActive(true)
              g_Time=cfg.mall.MallNPC.DISPLAYTIME
          end
       end
   end)
end

local function AddNPC(shopType)
    if g_NPC == nil then
		g_NPC = NPC:new()
		local npcCfg = ConfigManager.getConfigData("mallnpc",shopType)
        local npcCsvId = npcCfg.cornucopianpc
        g_NPC:RegisterOnLoaded(OnNPCLoaded)
		g_NPC:init(0, npcCsvId)	
	end
end

local function InitShopItemList(itemNum)
	if itemNum then
		if fields.UIList_Shop.Count == 0 then
			for i = 1, itemNum do
				local shopItem = fields.UIList_Shop:AddListItem()
			end
		end
	else
		return nil
	end
end

local function ClearShopItemList()
	if fields.UIList_Shop.Count ~= 0 then
		fields.UIList_Shop:Clear()
	end
end

local function ShowShopItemsInfo(shopType,pageType)
	local shopItems = ShopManager.GetShopItems(shopType, pageType)
	if #shopItems == 0 then
		return
	end
	InitShopItemList(#shopItems)

	for i = 1, #shopItems do
		local listItem = fields.UIList_Shop:GetItemByIndex(i - 1)
		local buttonBuy = listItem.Controls["UIButton_Buy"]
		local itemkey = shopItems[i].itemid.itemid
		local item = ItemManager.CreateItemBaseById(itemkey, nil, 0)
		
		BonusManager.SetRewardItem(listItem,item,{notShowAmount=true})
		-- 目前无品质icon
		listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(item:GetQuality())

		-- 设置绑定类型
		listItem.Controls["UISprite_Binding"].gameObject:SetActive((shopItems[i].bindtype.bindtype ~= cfg.item.EItemBindType.NOT_BOUND))
		if shopItems[i].bindtype.bindtype ~= cfg.item.EItemBindType.NOT_BOUND then
			item:SetBound(true)
		end
		listItem:SetText("UILabel_ShopItemName", item:GetName())		
		local currency = ItemManager.GetCurrencyData(shopItems[i].cost)
		listItem.Controls["UISprite_Currency_Icon"].spriteName = currency:GetIconName()
		listItem:SetText("UILabel_ShopItemUnitPrice", currency:GetNumber())

		listItem:SetIconTexture(item:GetTextureName())

		-- 所剩余限定次数取所有限定类型里限定次数最小的
		local remainingNum, limitType = ShopManager.GetShopItemRemainingNumAndLimitType(shopItems[i])
		
		if limitType == defineenum.LimitType.NO_LIMIT then
			-- 类型为无限制
			listItem.Controls["UIGroup_TimeLimitBG"].gameObject:SetActive(false)
		else
			-- 有限制类型
			listItem.Controls["UIGroup_TimeLimitBG"].gameObject:SetActive(true)
			listItem.Controls["UILabel_LimitTypeDesc"].text = Format(LocalString.Shop_LimitTypeDesc[limitType], remainingNum)
			listItem:SetText("UILabel_BuyLimits",remainingNum)
		end
		
		listItem:SetText("UILabel_Description", shopItems[i].introduce)

		if remainingNum <= 0 then
			listItem.Controls["UILabel_Buy"].color = Color.gray
			buttonBuy.isEnabled = false
		end

		-- item初始化时为0，改变item数量
		item:AddNumber(remainingNum > 0 and remainingNum or 0)

		EventHelper.SetClick(listItem.Controls["UIGroup_ShopItemBox"],function()
			-- 展示物品
			ItemIntroduct.DisplayBriefItem({ item = item })
		end)

		EventHelper.SetClick(buttonBuy, function()        

			local buyFunc = function(params)
				local validate = CheckCmd.Check( { moduleid = cfg.cmd.ConfigId.MALL, cmdid = shopItems[i].id, num = params.num, showsysteminfo = true })
				if validate then
					ShopManager.SendCCommand( { moduleid = cfg.cmd.ConfigId.MALL, cmdid = shopItems[i].id, num = params.num })
					listItem.Data = { shopItem = shopItems[i],itemData = item }
					g_CachedListItem = listItem
				else
					
					local currency_validate = CheckCmd.CheckData({ data = shopItems[i].cost, num = params.num, showsysteminfo = false })
					-- 货币不足显示来源
					if not currency_validate then 
						ItemManager.GetSource(currency:GetConfigId(),"dlgshop_common")
					end
				end
			end
			--[[if g_ShopType==cfg.mall.MallType.BLACK_MALL then
				buyFunc({num=1}) 
			else--]]
			local params = {
				item = item,
				--bagNumInShop = BagManager.GetItemNumById(shopItems[i].id,cfg.bag.BagType.FRAGMENT),
				variableNum = true,
				price = currency:GetNumber(),
				priceType = currency:GetDetailType2(),
				bShowNum = (item:GetNumber() ~= math.huge) and true or false, 
				limitType = limitType,
				buttons =
				{
					{ display = true, text = LocalString.ShopAlert_Buy, callFunc = buyFunc },
					{ display = false, text = "", callFunc = nil },
					{ display = false, text = "", callFunc = nil },
				}
			   }
			ItemIntroduct.DisplayItem(params)
			--end
		end )
	end

end



local function destroy()
	if g_NPC then
		g_NPC:release()
		g_NPC = nil
	end
end

local function refresh(params)
	ShowShopItemsInfo(g_ShopType,g_PageType)
	fields.UILabel_Talk.gameObject:SetActive(false)
end

local function show(params)
	local curTabIndex = UIManager.gettabindex("dlgshop_common")
	--if not curTabIndex then curTabIndex = 1 end

	g_ShopType = TABINDEX2SHOPTYPE[curTabIndex]

	if params and params.pageIndex then
		g_PageIndex = params.pageIndex
	else 
		g_PageIndex = 1
	end

    AddNPC(g_ShopType)
	local pageList = { }
	pageList = ShopManager.GetPageList(g_ShopType)

	-- 更改商城钱币类型的临时代码
	local dlgDialog = require("ui.dlgdialog")
    dlgDialog.ResumeCurrency(2)
    dlgDialog.RefreshCurrency()
    if g_ShopType == cfg.mall.MallType.TEAM_FIGHT_SCORE then 
        dlgDialog.ChangeCurrency(2,cfg.currency.CurrencyType.TeamFightScore)
        dlgDialog.RefreshCurrency()
    end

	fields.UIList_RadioButton:Clear()
	for _, page in ipairs(pageList) do
		local listItem = fields.UIList_RadioButton:AddListItem()
		local labelPage = listItem.Controls["UILabel_Promotion"]
		if g_ShopType == cfg.mall.MallType.DIAMOND_MALL then
			labelPage.text = LocalString.Shop_DiamondPageList[page]
		elseif g_ShopType == cfg.mall.MallType.BLACK_MALL then
			labelPage.text = LocalString.Shop_BlackPageList[page]
		elseif g_ShopType == cfg.mall.MallType.ARENA_MALL then
			labelPage.text = LocalString.Shop_ArenaPageList[page]
        elseif g_ShopType == cfg.mall.MallType.TEAM_FIGHT_SCORE then
			labelPage.text = LocalString.Shop_TeamFightScorePageList[page]
		end
		-- icon
		-- listItem:SetIconSprite(g_PageIconName[page])

		EventHelper.SetClick(listItem, function()
			g_PageType = page
			ClearShopItemList()
			ShowShopItemsInfo(g_ShopType,g_PageType)
		end )
	end
	g_PageType = pageList[g_PageIndex] or pageList[1]
	fields.UIList_RadioButton:SetSelectedIndex(g_PageIndex-1)

	-- 增加回调事件
	g_LimitEvnetId = gameevent.evt_limitchange:add(function()
		if g_CachedListItem and g_CachedListItem.Data then 
			local data = g_CachedListItem.Data
			local shopItemData = data.shopItem
			local item = data.itemData

			local remainingNum, limitType = ShopManager.GetShopItemRemainingNumAndLimitType(shopItemData)
			if limitType ~= defineenum.LimitType.NO_LIMIT then
				-- 有限制类型
				if remainingNum <= 0 then
					g_CachedListItem.Controls["UILabel_Buy"].color = Color.gray
					g_CachedListItem.Controls["UIButton_Buy"].isEnabled = false
				end
				g_CachedListItem:SetText("UILabel_BuyLimits",remainingNum)
				local preNum = item:GetNumber()
				item:AddNumber(remainingNum-preNum)
			end
		end
	end)
	-- 增加回调事件(播放特效使用)
	g_BoughtEventId = ShopManager.evt_bought:add(function(params)
		local moduleid,cmdid = unpack(params)
		if moduleid == cfg.cmd.ConfigId.MALL and g_CachedListItem then
			local effectObj = g_CachedListItem.Controls["UIGroup_Particle_Kuang"].gameObject 
			UIManager.PlayUIParticleSystem(effectObj)
			g_CachedListItem.Data = nil
			g_CachedListItem = nil
		end
	
	end)
end

local function hide()
	-- print(name, "hide")
	ClearShopItemList()
	fields.UIList_RadioButton:SetSelectedIndex(0)
	gameevent.evt_limitchange:remove(g_LimitEvnetId)

	if g_BoughtEventId then 
		ShopManager.evt_bought:remove(g_BoughtEventId)
		g_BoughtEventId = nil
	end
	if g_NPC then
		g_NPC:release()
		g_NPC = nil
	end
end

local function update()
	-- print(name, "update")
	if g_Time then
	   g_Time=g_Time-Time.deltaTime
	   if g_Time<=0 then
	       g_Time=nil
	       fields.UILabel_Talk.gameObject:SetActive(false)
	   end
	end
	    if g_NPC and g_NPC.m_Object then
        g_NPC.m_Avatar:Update() 
    end 
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
	name, gameObject, fields = unpack(params)

end

return {
	init       = init,
	show       = show,
	hide       = hide,
	update     = update,
	destroy    = destroy,
	refresh    = refresh,
	uishowtype = uishowtype,
}
