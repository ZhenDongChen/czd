--local tabachievement       = require "ui.achievement.tabachievement"
local EventHelper        = UIEventListenerHelper
local uimanager          = require "uimanager"
local network            = require "network"
local achievementmanager
local gameObject
local name
local fields

local tabname = "achievement.tabachievement"


local function RefreshMoney()
    if uimanager.isshow(name) then 
        fields.UILabel_AchievementAmount.text =  PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ChengJiu)
        fields.UILabel_CompletedAmount.text = string.format("%s/%s",achievementmanager.GetSum(),achievementmanager.GetTotalSum())
    end
end

local function RefreshAchievementListItem(item,index,realIndex)
    local data =  achievementmanager.GetAllAchievement()[fields.UIList_TitleSelect:GetSelectedItem().Id][realIndex]
    local UIButton_Receive = item.Controls["UIButton_Receive"]
    local UISprite_Receive = item.Controls["UISprite_Receive"]
    local UIProgressBar_Achievement = item.Controls["UIProgressBar_Achievement"]
    item.Id = data.id
    item:SetIconTexture(data.icon)
    item:SetText("UILabel_Condition",data.name)
    item:SetText("UILabel_Detail",data.detail)
    local State = achievementmanager.GetStateById(data.id)
    if State == 0 then  --- 未完成隐藏
        UISprite_Receive.gameObject:SetActive(false)
        UIButton_Receive.gameObject:SetActive(false)
    elseif State == 1 then 
        UISprite_Receive.gameObject:SetActive(false)
        UIButton_Receive.gameObject:SetActive(true)
    else
        UISprite_Receive.gameObject:SetActive(true)
        UIButton_Receive.gameObject:SetActive(false)
    end
    item:SetText("UILabel_Receive",LocalString.DlgAchievement_StateName [achievementmanager.GetStateById(data.id)])
    

    item:SetText("UILabel_Progress",string.format("%s/%s",
                                                  mathutils.NumberToLabel(achievementmanager.GetCountById(data.id)),
                                                  mathutils.NumberToLabel(achievementmanager.GetTotalCountById(data.id))))
    
    item:SetText("UILabel_Achievement",data.chengjiupoint.amount)
    item:SetText("UILabel_Money",data.bindyuanbao.amount)
    
    UIProgressBar_Achievement.value = achievementmanager.GetCountById(data.id)/achievementmanager.GetTotalCountById(data.id)
    --printyellow(" UITools.SetButtonEnabled",data.detail,achievementmanager.GetStateById(data.id),cfg.achievement.Status.COMPLETED)
    UITools.SetButtonEnabled(UIButton_Receive,achievementmanager.GetStateById(data.id) == cfg.achievement.Status.COMPLETED)
    

    EventHelper.SetClick(UIButton_Receive, function()
        achievementmanager.CGetReward(data.id)
        fields.UIGroup_chengjiulingqu.transform.position = item.transform.position
        --uimanager.StopUIParticleSystem(fields.UIGroup_fx_01.gameObject)
        uimanager.PlayUIParticleSystem(fields.UIGroup_fx_01.gameObject)
    end )
end 

local function RefreshRedDot()
    for i = 0,fields.UIList_TitleSelect.Count-1 do 
        local item = fields.UIList_TitleSelect:GetItemByIndex(i)
        local showreddot = false
        for _,achievement in pairs(achievementmanager.GetAllAchievement()[item.Id]) do 
            --printyellow("RefreshTitle",achievementmanager.GetStateById(achievement.id), cfg.achievement.Status.COMPLETED)
            if achievementmanager.GetStateById(achievement.id) == cfg.achievement.Status.COMPLETED then 
                showreddot = true
                break
            end
        end
        item.Controls["UISprite_Warning"].gameObject:SetActive(showreddot)
    end
end


local function RefreshTitle()
    local achievementlist =  achievementmanager.GetAllAchievement()[fields.UIList_TitleSelect:GetSelectedItem().Id]
    local wrapList = LuaHelper.GetComponent(fields.UIList_Achievement.gameObject,"UIWrapContentList")
    EventHelper.SetWrapListRefresh(wrapList,RefreshAchievementListItem)
    wrapList:CenterOnIndex(-0.5)
    wrapList:SetDataCount(#achievementlist)
    wrapList:SortAlphabetically()
end

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
     fields.UIList_TitleSelect:SetSelectedIndex(0)
     fields.UIGroup_fx_01.gameObject:SetActive(false)
end

local function hide()
    -- print(name, "hide")
end



local function refresh(params)
    -- print(name, "refresh")
    RefreshMoney()
    RefreshTitle()
    RefreshRedDot()
end


local function update()
    -- print(name, "update")
end



local function init(params)
    name, gameObject, fields = unpack(params)
    --print(name, "init")
    achievementmanager = require "ui.achievement.achievementmanager"
    --选择成就类型
    EventHelper.SetListSelect(fields.UIList_TitleSelect, function(selecteditem)
        --printyellow("fields.UIList_TitleSelect selected : index:",selecteditem.Index)
        RefreshTitle()
    end )

    local allachievement = achievementmanager.GetAllAchievement()
    for achievementtype,achievement in pairs(allachievement) do 
        if achievementmanager.CanGetReward(achievementtype) then
            local item = fields.UIList_TitleSelect:AddListItem()
            item.Id    = achievementtype
            --item.Data  = allachievement[achievementtype]
            item:SetText("UILabel_TypeName",achievementmanager.GetAchievementTypeName(achievementtype))
        end 
    end 
   
end




return {
    init            = init,
    show            = show,
    hide            = hide,
    update          = update,
    destroy         = destroy,
    refresh         = refresh,
    RefreshMoney    = RefreshMoney,
    --showdialog      = showdialog,
}