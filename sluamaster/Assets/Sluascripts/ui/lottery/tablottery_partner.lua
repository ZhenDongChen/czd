local EventHelper    = UIEventListenerHelper
local uimanager      = require("uimanager")
local lotterymanager = require "ui.lottery.lotterymanager"
local Define         = require("define")
local gameObject
local name
local fields
local dialogname = "lottery.dlglottery"
local tabname = "lottery.tablottery_partner"
local Player              = require("character.player")
local PlayerRole          = require("character.playerrole")
local g_NPC
local NPC            = require("character.npc")
local ConfigManager  = require("cfg.configmanager")




--模型加载
local function OnModelLoaded(go)
	print("OnModelLoaded")
	if not g_Player and not g_Player.m_Object then return end

	local playerTrans = g_Player.m_Object.transform
	playerTrans.parent = fields.Texture_PlayerModel.transform
	playerTrans.localScale = Vector3.one * 150
	playerTrans.localPosition = Vector3(-5, -200, -170)
	playerTrans.rotation = Quaternion.Euler(-90,0,0)
	

	ExtendedGameObject.SetLayerRecursively(g_Player.m_Object, Define.Layer.LayerUICharacter)
end


local function destroy()
	if g_NPC then
		g_NPC:release()
		g_NPC = nil
	end
end

local function show(params)

end

local function hide()

end

local function showtab(params)
    uimanager.show(tabname,params)
end



local function refresh(params)
    -- print(name, "refresh")
    --RefreshLotteryBase()
    for index = 0,fields.UIList_LotteryMain.Count-1 do 
        local item = fields.UIList_LotteryMain:GetItemByIndex(index)
		if item.Data:IsFree() then 
			--listItem:SetText("UILabel_Amount", colorutil.GetColorStr(colorutil.ColorType.Green_Tip,item:GetNumber() .. "/" .. item:GetConvertNumber()))
			item:SetText("UILabel_Msg",colorutil.GetColorStr(colorutil.ColorType.Green,item.Data:GetMsg()))
		else
			item:SetText("UILabel_Msg",colorutil.GetColorStr(colorutil.ColorType.Red,item.Data:GetMsg()))
		end
       -- item:SetText("UILabel_Msg",item.Data:GetMsg())
        item.Controls["UISprite_Icon"].spriteName = item.Data:GetIcon()
        item:SetText("UILabel_Amount",item.Data:GetAmount())
        item:SetText("UILabel_Discription",item.Data:Desc())
        local UISprite_Warning = item.Controls["UISprite_Warning"]
        if UISprite_Warning~=nil then 
            UISprite_Warning.gameObject:SetActive(item.Data:IsFree() or item.Data:CanUseItem())
        end
    end 
    uimanager.RefreshRedDot()
    --RefreshMoney()
end

local function second_update(now)
    for index = 0,fields.UIList_LotteryMain.Count-1 do 
        local item = fields.UIList_LotteryMain:GetItemByIndex(index)
        if item.Data.m_TextureData.iscooldown then 
            local UILabel_Msg           = item.Controls["UILabel_Msg"]
            if not item.Data:IsCoolDown() then 
                UILabel_Msg.gameObject:SetActive(true)
                uimanager.refresh(tabname)
            else 
                if UILabel_Msg.gameObject.activeInHierarchy then
                    UILabel_Msg.gameObject:SetActive(false)
                    uimanager.refresh(tabname)
                end 
            end 
        end 
    end
end


local function OnNPCLoaded()
	local npcTrans = g_NPC.m_Object.transform
	npcTrans.localScale      = Vector3.one*250
	npcTrans.parent = fields.UITexture_PlayerModel.gameObject.transform	
	npcTrans.rotation = Quaternion.Euler(-90,0,0)
	local npcCfg = ConfigManager.getConfigData("mallnpc",cfg.mall.MallType.DIAMOND_MALL)
	npcTrans.localPosition = Vector3(0, npcCfg.offset, 0)
	ExtendedGameObject.SetLayerRecursively(g_NPC.m_Object, Define.Layer.LayerUICharacter)
    g_NPC:Show()
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

local function update()
	--[[if g_NPC and g_NPC.m_Object then
        g_NPC.m_Avatar:Update() 
	end--]]
end


local function init(params)
	
	
    name, gameObject, fields = unpack(params)
    print(name, "init")
    local lotterydatas = lotterymanager.GetLotteryDatasByCurrencyType(cfg.currency.CurrencyType.HuoBanJiFen)
    for index = 0,fields.UIList_LotteryMain.Count-1 do 
        local item = fields.UIList_LotteryMain:GetItemByIndex(index)
        item.Data = lotterydatas[index+1]
        local button = item.Controls["UIButton_Lottery"]
        EventHelper.SetClick(button, function()
            lotterymanager.CPickCard(item.Data)
        end )
    end 
	Texture_PlayerModelTransform = fields.UITexture_PlayerModel.transform
	--AddNPC(cfg.mall.MallType.DIAMOND_MALL)
	
end

--不写此函数 默认为 UIShowType.Default
local function uishowtype()
    --return UIShowType.Default
    --return UIShowType.ShowImmediate--强制在showtab页时 不回调showtab
    return UIShowType.Refresh  --强制在切换tab页时回调show
    --return bit.bor(UIShowType.ShowImmediate,UIShowType.Refresh)
end




return {
    init            = init,
    show            = show,
    hide            = hide,
    update          = update,
    second_update   = second_update,
    destroy         = destroy,
    refresh         = refresh,
    showtab         = showtab,
    uishowtype      = uishowtype,
}
