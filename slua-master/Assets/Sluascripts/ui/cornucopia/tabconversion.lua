local Unpack =unpack
local EventHelper = UIEventListenerHelper
local Define=require"define"
local Player=require"character.player"
local NPC=require"character.npc"
local ShopManager=require"shopmanager"
local LimitManager=require"limittimemanager"
local CheckCmd = require("common.checkcmd")
local ItemManager=require"item.itemmanager"
local ItemIntroduct=require"item.itemintroduction"
local BonusManager=require("item.bonusmanager")
local ConfigManager=require("cfg.configmanager")
local PlayerRole=require("character.playerrole"):Instance()
local UIManager=require("uimanager")
local BagManager= require("character.bagmanager")

local m_GameObject
local m_Name
local m_Fields
local m_CurrencyType=nil
local m_SelectedId
local m_NPC=nil
local m_Items={}

local function destroy()
end

local function Buy(params)
    local validate, info = CheckCmd.Check( { moduleid = cfg.cmd.ConfigId.MALL, cmdid = m_SelectedId, num = params.num, showsysteminfo = true })
    if validate then
        ShopManager.SendCCommand( { moduleid = cfg.cmd.ConfigId.MALL, cmdid = m_SelectedId, num = params.num })
    else
        ItemManager.GetSource(cfg.currency.CurrencyType.LingJing,UIManager.currentdialogname())
    end
end

local function GetRemainTime(item)
    local remainTime = 0
    local totalTime = 0
    for _,limit in pairs(item.limitlist.limits) do
        if limit.type == cfg.cmd.condition.LimitType.DAY then
            totalTime = limit.num
            break
        end
    end
    local limits = LimitManager.GetLimitTime(cfg.cmd.ConfigId.MALL,item.id)
    if limits then
        remainTime = totalTime - limits[cfg.cmd.condition.LimitType.DAY]           
    else
        remainTime = totalTime
    end
    return remainTime
end

local function ShowItemDetail(listItem,item)
    local itemCSVData=ItemManager.CreateItemBaseById(item.itemid.itemid,item)
    BonusManager.SetRewardItem(listItem,itemCSVData,{notSetClick=true})
    local UISprite_Quality=listItem.Controls["UISprite_Quality"]
    if UISprite_Quality then
        EventHelper.SetClick(UISprite_Quality,function()
            local params={item=itemCSVData,buttons={{display=false,text="",callFunc=nil},{display=false,text="",callFunc=nil}}}
            local ItemIntroduct=require"item.itemintroduction"
            ItemIntroduct.DisplayBriefItem(params)
        end)
    end
	
	listItem.Controls["UISprite_Binding"].gameObject:SetActive((itemCSVData.bindtype ~= cfg.item.EItemBindType.NOT_BOUND))
	
    local UILabel_LingJingAmount=listItem.Controls["UILabel_Amount1"]
    if UILabel_LingJingAmount then
        UILabel_LingJingAmount.text=item.cost.amount
    end
    local UILabel_RemainTime=listItem.Controls["UILabel_Amount2"]
    local remainTime=0
    if UILabel_RemainTime then
        remainTime = GetRemainTime(item)
        UILabel_RemainTime.text=remainTime
    end
    local UILabel_Desc=listItem.Controls["UILabel_Description"]
    if UILabel_Desc then
        UILabel_Desc.text=item.introduce
    end
    local UILabel_Name=listItem.Controls["UILabel_ShopItemName"]
    if UILabel_Name then
        UILabel_Name.text=itemCSVData:GetName()
    end
    local UIButton_Buy=listItem.Controls["UIButton_Buy"]

    local currency = ItemManager.GetCurrencyData(item.cost)    
	
    if UIButton_Buy then
        if remainTime>0 then
            UIButton_Buy.isEnabled=true
            EventHelper.SetClick(UIButton_Buy,function()
                local rT = GetRemainTime(item)
                if rT > 0 then
                    m_SelectedId=item.id
                    --Buy()
					--显示购买界面
					local params = {
                        item = itemCSVData,
						bagNumInShop = BagManager.GetItemNumById(item.itemid.itemid,cfg.bag.BagType.ITEM),
                        variableNum = true,
                        price = currency:GetNumber(),
				        priceType = currency:GetDetailType2(),
						num = GetRemainTime(item),
				        bShowNum = (remainTime ~= math.huge) and true or false, 
						limitType = cfg.cmd.condition.LimitType.DAY,
				        buttons =
				        {
					      { display = true, text = LocalString.ShopAlert_Buy, callFunc = Buy },
					      { display = false, text = "", callFunc = nil },
					      { display = false, text = "", callFunc = nil },
				        } 
                      }
					local ItemIntroduct=require"item.itemintroduction"
					ItemIntroduct.DisplayItem(params)
                end
            end)
        else
           UIButton_Buy.isEnabled=false 
        end
    end
end

local function RefreshItem(params)
    if params and params.itemId then      
        local itemId=params.itemId
        local listItem=m_Fields.UIList_Shop:GetItemById(itemId)
        if listItem then
            local itemData=listItem.Data          
            local UILabel_RemainTime=listItem.Controls["UILabel_Amount2"]
            local remainTime=0
            if UILabel_RemainTime then
                local totalTime=0
                for _,limit in pairs(itemData.limitlist.limits) do
                    if limit.type==cfg.cmd.condition.LimitType.DAY then
                        totalTime=limit.num
                        break
                    end
                end
                local limits=LimitManager.GetLimitTime(cfg.cmd.ConfigId.MALL,itemData.id)
                if limits then
                    remainTime=totalTime-limits[cfg.cmd.condition.LimitType.DAY]           
                else
                    remainTime=totalTime
                end
                UILabel_RemainTime.text=remainTime
           end
           local UIButton_Buy=listItem.Controls["UIButton_Buy"]   
           if UIButton_Buy then
                if remainTime<=0 then
                    UIButton_Buy.isEnabled=false 
                end
            end
        end
    end
end

local function OnNPCLoaded()
    local npcTrans=m_NPC.m_Object.transform
    npcTrans.parent=m_Fields.UITexture_Player.gameObject.transform    
	npcTrans.localScale      = Vector3.one*250
    npcTrans.localPosition   = Vector3(0,-270,120)
    npcTrans.rotation = Quaternion.Euler(-90,0,0)
    ExtendedGameObject.SetLayerRecursively(m_NPC.m_Object,Define.Layer.LayerUICharacter)
    m_NPC.m_Object:SetActive(true)
end

local function AddNPC()
    if m_NPC==nil then
        local npcData=ConfigManager.getConfigData("mallnpc",cfg.mall.MallType.LINJING_MALL)
        if npcData then
            m_NPC = NPC:new()
            m_NPC:RegisterOnLoaded(OnNPCLoaded)
            m_NPC:init(0,npcData.cornucopianpc)            
        end
    end
end

local function OnItemInit(UIListItem,wrapIndex,realIndex)
    if UIListItem==nil then
        return
    end
    local good=m_Items[realIndex]
    if UIListItem then
        --printt(good)
			-- 设置绑定类型
		
        UIListItem.Id=good.itemid.itemid
        UIListItem.Data=good
        ShowItemDetail(UIListItem,good)
    end
end

local function InitList(num)
    local wrapList=m_Fields.UIList_Shop.gameObject:GetComponent("UIWrapContentList")
    if wrapList==nil then
        return
    end
    EventHelper.SetWrapListRefresh(wrapList,OnItemInit)
    wrapList:SetDataCount(num)
    wrapList:CenterOnIndex(-0.3)
end

local function show(params)
    m_Fields.UILabel_ShopTitle.text=LocalString.Cornucopia_Title   
    AddNPC()
    m_CurrencyType=cfg.currency.CurrencyType.LingJing
	-- 更改商城货币类型的临时代码
    if UIManager.currentdialogname() == "dlgshop_common" then
		local dlgDialog = require("ui.dlgdialog")
		dlgDialog.ChangeCurrency(2,m_CurrencyType)
		dlgDialog.RefreshCurrency()
	end
end

local function hide()
end

local function refresh(params)
    --RefreshItem()
    m_Items=ShopManager.GetLingJingItems()
    if m_Items then
        InitList(#m_Items)
    end
end

local function update()
    if m_NPC and m_NPC.m_Object then
        m_NPC.m_Avatar:Update() 
    end 
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)   
    EventHelper.SetDrag(m_Fields.UITexture_Player,function(o,delta)
        if m_NPC then
            local npcObj=m_NPC.m_Object
            if npcObj  then
                local vecRotate = Vector3(0,-delta.x,0)
                npcObj.transform.localEulerAngles = npcObj.transform.localEulerAngles+vecRotate
            end
        end
    end)
end

local function uishowtype()
	return UIShowType.Refresh
end

return{
    init        = init,
    show        = show,
    hide        = hide,
    update      = update,
    destroy     = destroy,
    refresh     = refresh,
    RefreshItem = RefreshItem,
	uishowtype  = uishowtype,
}