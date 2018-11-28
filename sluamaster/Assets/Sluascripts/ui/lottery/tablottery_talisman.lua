local EventHelper    = UIEventListenerHelper
local uimanager      = require("uimanager")
local lotterymanager = require "ui.lottery.lotterymanager"

local gameObject
local name
local fields
local dialogname = "lottery.dlglottery"
local tabname = "lottery.tablottery_talisman"


local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
end

local function hide()
    -- print(name, "hide")
end

local function showtab(params)
    --lotterymanager.CGetProps()
    uimanager.show(tabname,params)
end



local function refresh(params)
    -- print(name, "refresh")
    --RefreshLotteryBase()
    for index = 0,fields.UIList_LotteryMain.Count-1 do  
        local item = fields.UIList_LotteryMain:GetItemByIndex(index)
        if item.Data:IsFree() then 
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


local function init(params)
    name, gameObject, fields = unpack(params)
      --print(name, "init")
    local lotterydatas = lotterymanager.GetLotteryDatasByCurrencyType(cfg.currency.CurrencyType.FaBaoJiFen)
    for index = 0,fields.UIList_LotteryMain.Count-1 do 
        local item = fields.UIList_LotteryMain:GetItemByIndex(index)
        item.Data = lotterydatas[index+1]
        local button = item.Controls["UIButton_Lottery"]
        EventHelper.SetClick(button, function()
            lotterymanager.CPickCard(item.Data)
        end )
    end 

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
