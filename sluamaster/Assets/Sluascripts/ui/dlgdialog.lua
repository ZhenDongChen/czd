local unpack             = unpack
local print              = print
local math               = math
local EventHelper        = UIEventListenerHelper
local UIManager          = require("uimanager")
local PlayerRole         = require "character.playerrole"
local configmanager      = require "cfg.configmanager"
local network            = require "network"
local DailyEctypeManager = require"ui.ectype.dailyectype.dailyectypemanager"
local ExchangeManager    = require"ui.exchange.exchangemanager"
local DlgEctypeManager   = require"ui.ectype.dlgectypemanager"
local EctypeDlgManager   = require "ui.ectype.storyectype.ectypedlgmanager"
local BagManager         = require("character.bagmanager")
local StoryNoteManager   = require("ui.playerrole.storynote.storynotemanager")
local ModuleLockManager  = require"ui.modulelock.modulelockmanager"
local ItemManager        = require "item.itemmanager"
local VipChargeManager   = require "ui.vipcharge.vipchargemanager"
local MultiEctypeManger  = require "ui.ectype.multiectype.multiectypemanager"
local StoryEctypeManager = require "ui.ectype.storyectype.storyectypemanager"
local PetManager        = require"character.pet.petmanager"

local gameObject
local name
local fields
local RedDotList={}
local dialogname = "dlgdialog"
local lastItem  -- 记录上次点击的item
local preCurrency

---------------------------------------------------------------------------------------------

local function RegisterAllUnRead()
    RedDotList=
    {
        ["partner.dlgpartner_list"] = {
            {func = PetManager.HaveCanUpgradePet },
            {func = PetManager.HaveCanCallPet },
        },

        ["illustrates.dlgpokedex_illustrate"] = {
            {func = PetManager.HaveAwardPet},
        },

        ["ectype.dlgentrance_copy"]={
			[1]={func=StoryEctypeManager.UnRead},
            [2]={func=DailyEctypeManager.UnRead},
			[3]={func=MultiEctypeManger.UnRead},
            [4]={func=DlgEctypeManager.TowerUnRead},
            [5]={func=require("ui.ectype.weekend").UnRead},
        },
        ["exchange.dlgexchange"]={
            [3]={func=ExchangeManager.UnRead},
        },
        ["family.dlgfamily"]={
            [3]={func=require("family.welfaremanager").UnRead},
            [4]={func=require("family.activitymanager").UnRead},
            [5]={func=require("family.applymanager").UnRead},
        },
        ["skill.dlgskill"]={
            [1]={func=require("character.skill.roleskill").UnRead},
        },
        ["achievement.dlgachievement"]={
            [1]={func=require("ui.achievement.achievementmanager").UnRead_Achievement},
            [2]={func=require("ui.achievement.achievementmanager").UnRead_AchievementTitle},

        },
        ["lottery.dlglottery"]={
            [1]={func=require("ui.lottery.lotterymanager").UnRead_HuoBanJiFen},
            [2]={func=require("ui.lottery.lotterymanager").UnRead_FaBaoJiFen},
            [4]={func=require("ui.welfare.welfaremanager").UntreeRed},
        },
        ["playerrole.dlgplayerrole"]={
            [2]={func=BagManager.UnRead},
            [3]={func=require("ui.playerrole.talisman.tabtalisman").UnRead},
			[4]={func=StoryNoteManager.UnRead},
        },
        ["welfare.dlgwelfaremain"]={
            [1]={func=require("ui.welfare.welfaremanager").UnReadSingle},
            [2]={func=require("guide.livenessmanager").UnReadSingle},
            [3]={func=require("guide.reclaimmanager").UnRead}
        },
        -- ["guide.dlglivenessmain"]={
        --     [1]={func=require("guide.livenessmanager").UnReadSingle},
        --     [2]={func=require("guide.reclaimmanager").UnRead},
        -- },

        ["activity.dlgactivity"]={
            [1]={func=require("ui.activity.tabactivitylist").UnRead},
			      [2]={func=require("ui.arena.multi.tabarenamultilabellist").UnRead},
			      [3]={func=require("ui.activity.attackcity.attackcitymanager").UnRead},
                  [4]={func=require("ui.activity.tabactivitylist").UnRead},
        },
        ["arena.dlgarena"]={
          [1]={func=require("ui.arena.single.tabarenachallenge").UnRead},
          [2]={func=require("ui.citywar.citywarmanager").UnRead},
        },
		["dlgautofight"]={
          [1]={func=require("character.settingmanager").UnReadAutoFight},
		  [2]={func=require("character.settingmanager").UnReadSystem},
		},
        ["vipcharge.dlgrecharge"]={
			[2]={func=require("ui.welfare.welfaremanager").UnRead_MonthCard},
			[3]={func=require("ui.welfare.welfaremanager").UnRead_GrowPlan},
			[4]={func=require("ui.vipcharge.tabdaycharge").UnRead},
			[5]={func=require("ui.vipcharge.vipchargemanager").UnReadDailyMoney},
        },
        ["cornucopia.dlgcornucopia"]={
            [3]={func=require("ui.cornucopia.compressmanager").UnRead},
        },
       --[[ ["pureair.dlgpureair"]={
            [1]={func=require("ui.pureair.pureairmanager").UnRead1},
            [2]={func=require("ui.pureair.pureairmanager").UnRead2},
        }--]]
        ["playerrole.equip.dlgjadeenhance"]={
            [1]={func=require("ui.jade.jewelrybagmanager").UnRead},
        },
        ["operationactivity.dlgoperationactivity"]={
            [2]={func=require("ui.vipcharge.tabtimershop").UnRead},
        },
    }
end


local function RefreshRedDotByIndex(viewName,index,sprite)
    local tabs=RedDotList[viewName]
    if tabs then
        local redDot=tabs[index]
        if redDot then
            sprite.gameObject:SetActive(redDot.func(index))
        else
            sprite.gameObject:SetActive(false)
        end
    else
        sprite.gameObject:SetActive(false)
    end
end

local function RefreshModuleByIndex(viewName,index,listItem)
    local status=ModuleLockManager.GetModuleStatusByIndex(viewName,index)
    local lockObj=listItem.Controls["UISprite_Lock"]
    if status==defineenum.ModuleStatus.LOCKED then  --未解锁
        lockObj.gameObject:SetActive(true)
        local redDotSprite=listItem.Controls["UISprite_Dot"]
        if redDotSprite then
            redDotSprite.gameObject:SetActive(false)
        end
    elseif status==defineenum.ModuleStatus.UNLOCK then  --已解锁
        lockObj.gameObject:SetActive(false)
        local redDotSprite=listItem.Controls["UISprite_Dot"]
        if redDotSprite then
           RefreshRedDotByIndex(viewName,index,redDotSprite)
        end
     end
end

local function RefreshRedDot(viewName)
    local tabs=RedDotList[viewName]
    if tabs then
        local i
        for i = 1, (fields.UIList_Tab.Count) do
            local item = fields.UIList_Tab:GetItemByIndex(i-1)
            if item then
                RefreshModuleByIndex(viewName,i,item)
            end
        end
    end
end

local function changebackground(backgroundtype)
    ---- printyellow("==================changebackground",changebackground)
    if backgroundtype == cfg.ui.BackgroundType.None then
        ---- printyellow(fields.UISprite_Background.gameObject)
        fields.UISprite_Background.gameObject:SetActive(false)
        fields.UISprite_Seperate.gameObject:SetActive(false)

    elseif backgroundtype == cfg.ui.BackgroundType.LeftRight then
        fields.UISprite_Background.gameObject:SetActive(true)
        fields.UISprite_Seperate.gameObject:SetActive(true)

    elseif backgroundtype == cfg.ui.BackgroundType.Center then
        fields.UISprite_Background.gameObject:SetActive(true)
        fields.UISprite_Seperate.gameObject:SetActive(false)
    end
end

local function RefreshCurrency()
    if not UIManager.needrefresh(dialogname) then
        return
    end
    local player = PlayerRole:Instance()
	local currencyType = cfg.currency.CurrencyType

    for i=0,fields.UIList_Currency.Count-1 do
        local item = fields.UIList_Currency:GetItemByIndex(i)
        local currencytype = item.Data
        if currencytype and currencytype>=0 then
            item.Controls["UIGroup_Money"].gameObject:SetActive(currencytype ~= currencyType.TiLi)
            item.Controls["UIGroup_Energy"].gameObject:SetActive(currencytype == currencyType.TiLi)
            ---- printyellow(currencytype,ItemManager.CreateItemBaseById(currencytype):GetIconName())
            item:SetIconSprite(ItemManager.CreateItemBaseById(currencytype):GetIconName()) --设置元宝的名字
            if currencytype == currencyType.TiLi then
                local max_TiLi = configmanager.getConfig("roleconfig").maxtili                      --鏈�澶т綋鍔�
	            local cur_TiLi = player.m_Currencys[currencyType.TiLi] or 0                               --褰撳墠浣撳姏
	            local percent = cur_TiLi/max_TiLi
	            if percent > 1 then percent = 1 end
	            item.Controls["UISlider_Energy"].value =  percent
	            item.Controls["UILabel_Energy"].text = cur_TiLi .. "/".. max_TiLi
            else
                item.Controls["UILabel_Money"].text = player.m_Currencys[currencytype] or 0
            end

            EventHelper.SetClick(item.Controls["UIButton_Add"],function()
                if  currencytype == currencyType.YuanBao then
				            VipChargeManager.ShowVipChargeDialog()
                elseif currencytype == currencyType.BindYuanBao then
				            VipChargeManager.ShowVipChargeDialog()
                elseif currencytype == currencyType.TiLi then
                     EctypeDlgManager.ShowReminderTiLi()
                elseif currencytype == currencyType.BangGong then
                     UIManager.show("family.tabpray")
                elseif currencytype == currencyType.LingJing then
                     UIManager.ShowSystemFlyText(LocalString.Currency_GetLingJing)
                elseif currencytype == currencyType.ZhanChang then
                    ---- printyellow("战场声望")
                    UIManager.ShowSystemFlyText(LocalString.Currency_GetZhanChang)
                elseif currencytype == currencyType.ShengWang then
                    UIManager.ShowSystemFlyText(LocalString.Currency_GetShengWang)
                else
                    ItemManager.GetSource(currencytype,UIManager.currentdialogname())
                end
            end)
        end
    end
end

local function reset()
    fields.UIList_Currency.gameObject:SetActive(true)
    fields.UIList_Tab:Clear()
    changebackground(cfg.ui.BackgroundType.None)
end

local function destroy()
end

local function show(params)
    fields.UIList_Tab:SetSelectedIndex(0)
    local trfTex = gameObject.transform:Find("Panel_Block/UISprite_Background/Texture")
    if trfTex~=nil then
        local uiTex = trfTex.gameObject:GetComponent("UITexture")
        if uiTex~=nil then
            UIManager.SetUITextureFit(uiTex)
        end
    end
end

local function hide()
    reset()
    fields.UIList_Tab.gameObject:SetActive(true)
end

local function refresh(params)
    lastItem = nil 
    if Local.LogModuals.UIManager then
        printt(params)
    end
    reset()
    if Local.LogManager then
        printyellow(name, "[dlgdialog:refresh]==========callback refresh DlgDialog")
    end
    if params and params.view_name then
        local dialog = UIManager.getdialog(params.view_name)
        if dialog then
            fields.UIButton_Return.gameObject:SetActive(dialog.showreturn)
            fields.UIButton_Close.gameObject:SetActive(dialog.showreturn)
            fields.TweenPosition_Top.gameObject:SetActive(dialog.showcurrency)
            --printyellow("[DlgDialog.refresh] dialog.showcurrency = ", dialog.showcurrency)
            fields.UISprite_Edge.gameObject:SetActive(dialog.showedgebackground)
            for i=0,fields.UIList_Currency.Count-1 do
                local item = fields.UIList_Currency:GetItemByIndex(i)
                item.Data = dialog[string.format("showcurrency%s",i)]
                item.gameObject:SetActive(item.Data ~=nil)
            end
            fields.UIList_Currency:Refresh()
            if #dialog.tabgroups>0  and params.tab_index then
                for index = 1, #dialog.tabgroups do
                    local item = fields.UIList_Tab:AddListItem()
                    item:SetIconSprite(dialog.tabgroups[index].tabgroupicon)
                    item:SetText("UILabel_Title",dialog.tabgroups[index].tabgroupname)
                    item.Data = { dialog_name = params.view_name,tabgroup = dialog.tabgroups[index]}
                   -- printyellow(params.view_name,index,item)
                    RefreshModuleByIndex(params.view_name,index,item)
                    if index == params.tab_index then  --- 默认选中第一个
                        item.gameObject.transform:Find("Button_Animation").gameObject:SetActive(true)
                        item.gameObject.transform:Find("UISprite_Title1").gameObject:SetActive(true)
                        lastItem = item
                    end
                end
                fields.UIList_Tab:SetSelectedIndex(params.tab_index-1,false)
                changebackground(dialog.tabgroups[params.tab_index].backgroundtype)
            else
                changebackground(dialog.backgroundtype)
            end
            if dialog.showcurrency then
                local twSrc = fields.TweenPosition_Top.gameObject:GetComponent("TweenPosition");
                if twSrc~=nil then
                    -- print("twsrc:"..twSrc.from:ToString()..tostring(twSrc.enabled))
                    twSrc.enabled = false
                    twSrc.enabled = true
                end
            end
            local twSrcTop = fields.TweenPosition_Left.gameObject:GetComponent("TweenPosition");
            if twSrcTop~=nil then
                -- print("twsrc:"..twSrc.from:ToString()..tostring(twSrc.enabled))
                twSrcTop.enabled = false
                twSrcTop.enabled = true
            end
        end
    else
        fields.UIButton_Return.gameObject:SetActive(true)
        fields.UIButton_Close.gameObject:SetActive(true)
        fields.TweenPosition_Top.gameObject:SetActive(false)
        fields.UISprite_Edge.gameObject:SetActive(false)
        changebackground(cfg.ui.BackgroundType.None)
    end
    RefreshCurrency()
    gameevent.evt_dlgdialogrefresh:trigger()
    fields.TweenPosition_Left.gameObject.transform.position = Vector3(0,0,0)
    fields.TweenPosition_Top.gameObject.transform.position = Vector3(0,0,0)
end

local function init(params)
   
    name, gameObject, fields    = unpack(params)
   
	  RegisterAllUnRead()
    EventHelper.SetListSelect(fields.UIList_Tab,function(item)
        --此处还可以用tab名切换如 UIManager.changetab(name,"testtab.tabtest1")
        --changetab 也有uishowtype 的可选参数，参数说明见文档
        local status=ModuleLockManager.GetModuleStatusByIndex(item.Data.dialog_name,item.Index+1)
        if status==defineenum.ModuleStatus.UNLOCK then
            if lastItem then 
                lastItem.gameObject.transform:Find("Button_Animation").gameObject:SetActive(false)
                lastItem.gameObject.transform:Find("UISprite_Title1").gameObject:SetActive(false)
            end
            lastItem = item
            item.gameObject.transform:Find("Button_Animation").gameObject:SetActive(true)
            item.gameObject.transform:Find("UISprite_Title1").gameObject:SetActive(true)
            changebackground(item.Data.tabgroup.backgroundtype)
           ---- printyellow("[dlgdialog.onlistselected] change index:", item.Data.dialog_name,item.Index+1)
            UIManager.changetabbyindex(item.Data.dialog_name,item.Index+1)
        elseif status==defineenum.ModuleStatus.LOCKED then
            local text=""
            item.gameObject.transform:Find("Button_Animation").gameObject:SetActive(false)
            local configData=UIManager.gettabgroup(item.Data.dialog_name,item.Index+1)
            local conditionData=configmanager.getConfigData("moduleunlockcond",configData.conid)
            if configData then
                if conditionData then
                    if conditionData.openlevel~=0 then
                        text=(conditionData.openlevel)..(LocalString.WorldMap_OpenLevel)
                    elseif conditionData.opentaskid~=0 then
                        local taskData=configmanager.getConfigData("task",conditionData.opentaskid)
                        if taskData then
                            text=string.format(LocalString.CompleteTaskOpen,taskData.basic.name)
                        end
                    end
                    UIManager.ShowSystemFlyText(text)
                end
            end
        end
    end)
    EventHelper.SetClick(fields.UIButton_Return,function()
        UIManager.hidecurrentdialog()
    end)
    EventHelper.SetClick(fields.UIButton_Close,function()
        UIManager.hidecurrentdialog()
    end)
end



--不写此函数 默认为 UIShowType.Default
local function uishowtype()
    --return UIShowType.Default
    --return UIShowType.ShowImmediate--强制在showtab页时 不回调showtab
    return UIShowType.Refresh  --强制在切换tab页时回调show
    --return bit.bor(UIShowType.ShowImmediate,UIShowType.Refresh)
end

local function SetReturnButtonActive(b)
    if fields.UIButton_Return.gameObject.activeSelf ~=b then
	    fields.UIButton_Return.gameObject:SetActive(b)
    end

    if fields.UIButton_Close.gameObject.activeSelf ~=b then
	    fields.UIButton_Close.gameObject:SetActive(b)
    end
end

local function SetListTabActive(b)
    if fields.UIList_Tab.gameObject.activeSelf ~=b then
	    fields.UIList_Tab.gameObject:SetActive(b)
    end
end

local function SetListCurrencyActive(b)
    if fields.UIList_Currency.gameObject.activeSelf ~=b then
	    fields.UIList_Currency.gameObject:SetActive(b)
    end
end

local function ChangeCurrency(currencyIndex,currencyType)
    local item = fields.UIList_Currency:GetItemByIndex(currencyIndex)
    preCurrency = item.Data
    item.Data = currencyType
end

local function ResumeCurrency(currencyIndex)
    local item = fields.UIList_Currency:GetItemByIndex(currencyIndex)
    if not preCurrency then 
        preCurrency = item.Data
    end
    item.Data = preCurrency
end

return {

  init             = init,
  show             = show,
  hide             = hide,
  destroy          = destroy,
  refresh          = refresh,
  changebackground = changebackground,
  RefreshCurrency  = RefreshCurrency,
  ChangeCurrency   = ChangeCurrency,
  ResumeCurrency   = ResumeCurrency,
  RefreshRedDot    = RefreshRedDot,
  uishowtype       = uishowtype,
  SetReturnButtonActive = SetReturnButtonActive,
  SetListTabActive      = SetListTabActive,
  SetListCurrencyActive = SetListCurrencyActive,
}
