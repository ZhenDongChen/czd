local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local bonusmgr = require("item.bonusmanager")
local mgr = require("family.familymanager")
local welfaremgr = require("family.welfaremanager")
local mallmgr = require("family.mallmanager")
local skillmgr = require("family.skillmanager")
local levelmgr = require("family.levelwelfaremanager")
local player = require("character.playerrole"):Instance()
local itemmgr = require("item.itemmanager")
local limitmgr = require("limittimemanager")
local ItemEnum = require("item.itemenum")

local fields
local msgids
local m_GoodIDList = {}

local function showtab(params)
    welfaremgr.GetReady(function()
        uimanager.show("family.tabwelfare", params)
    end)
end

local function show()
    mgr.CheckAllFamilyDlgHide()
    msgids = network.add_listeners({
        {"lx.gs.role.msg.SCurrencyChange", function(msg)
             -- printyellow("on scurrencychange")
             -- printt(msg)
             if msg.currencys[cfg.currency.CurrencyType.BangGong] then
                 fields.UILabel_Contrib.text = msg.currencys[cfg.currency.CurrencyType.BangGong]
             end
        end},
    })
    fields.UIToggle_Mall.value = true
end

-- local function hidetab()
-- end

local function hide()
    network.remove_listeners(msgids)
    welfaremgr.Release()
end

local function destroy()
end

local function RefreshPageMall(notTurnStart)
    -- printyellow("on refreshpagemall")

    fields.UILabel_Contrib.text = player:GetCurrency(cfg.currency.CurrencyType.BangGong)
    fields.UILabel_FamilyLevel_Mall.text = string.format(LocalString.Family.TagLevel, mgr.Info().flevel)
    fields.UILabel_MallLevel.text = string.format(LocalString.Family.TagLevel, mgr.Info().malllevel)

    
    local wrapContent = fields.UIList_Mall.gameObject:GetComponent("UIWrapContentList")
    if not notTurnStart then
        m_GoodIDList = {}
        for id,good in pairs(mallmgr.Goods()) do
            if checkcmd.CheckData({data=good.minfamilylevel}) then
                m_GoodIDList[#m_GoodIDList+1] = id
            end
        end

        utils.table_sort(m_GoodIDList, function(a,b)       
            local gooda = mallmgr.GetGood(a)
            local goodb = mallmgr.GetGood(b)
            if gooda.minfamilylevel.level < goodb.minfamilylevel.level then
                return false
            end
            return true
        end) 
        wrapContent:SetDataCount(#m_GoodIDList)
        wrapContent:CenterOnIndex(0)
    else
        wrapContent:RefreshWithOutSort()
    end
end

local function GetSkillAttrStr(property)
    local attrType = property.propertytype
    local attrValue = property.value

    local attrTypeToText = ConfigManager.getConfigData("statustext", attrType)
    local attrText = attrTypeToText.text
    local attributeText = ""

    if attrTypeToText.displaytype == cfg.fight.DisplayType.NORMAL then
        attributeText = string.format("%s %+.1f", attrText, attrValue)
    elseif attrTypeToText.displaytype == cfg.fight.DisplayType.ROUND then
        attributeText = string.format("%s %+d", attrText, attrValue)
    elseif attrTypeToText.displaytype == cfg.fight.DisplayType.PERCENT then
        attributeText = string.format("%s %+.1f%%", attrText, 100 * attrValue)
    else
        logError("attribute display type error!")
    end

    return attributeText
end

local function RefreshPageSkill()
    fields.UILabel_FamilyLevel_Skill.text = string.format(LocalString.Family.TagLevel, mgr.Info().flevel)
    fields.UILabel_SkillMaxLevel.text = string.format(LocalString.Family.TagLevel, skillmgr.MaxLevel())

    for i = 1,fields.UIList_Skill.Count do
        local item = fields.UIList_Skill:GetItemByIndex(i-1)
        local dataskill = item.Data
        local skillid = item.Id

        local skill = skillmgr.GetSkill(skillid)
        local dataskilllevel = dataskill.skillinfo[skill.level]
        local dataskilllevelnext = dataskill.skillinfo[skill.level+1]
        -- printyellow("skill "..i)
        -- printt(skill)
        item.Controls["UILabel_Descrip"].text = dataskilllevel and GetSkillAttrStr(dataskilllevel.property) or ""
        item.Controls["UILabel_SkillLevel"].text = string.format("%d/%d", skill.level, skillmgr.MaxLevel())
        item.Controls["UIButton_Learn"].gameObject:SetActive(mgr.SelfDataJob().familyskillperm)
        if mgr.SelfDataJob().familyskillperm then
            item.Controls["UIButton_Learn"].isEnabled = skill.level < skillmgr.MaxLevel()
                and dataskilllevelnext and checkcmd.CheckData({data=dataskilllevelnext}) or false
        end
    end
end

local function RefreshPageLevelWelfare()
    -- printyellow("on refresh page levelfare")

    for i = 1,fields.UIList_LevelWelfare.Count do
        local item = fields.UIList_LevelWelfare:GetItemByIndex(i-1)
        if not item then return end
        local data = item.Data
        item.Controls["UIButton_Receive"].isEnabled = checkcmd.Check({moduleid=cfg.cmd.ConfigId.FAMILY_LEVEL_BONUS,cmdid=data.bonusid, showsysteminfo=false})
    end
end

local function refresh(params)
    fields.UIGroup_Mall.gameObject:SetActive(fields.UIToggle_Mall.value)
    fields.UIGroup_Skill.gameObject:SetActive(fields.UIToggle_Skill.value)
    fields.UIGroup_LevelWelfare.gameObject:SetActive(fields.UIToggle_LevelWelfare.value)

    fields.UISprite_UnRead_LevelWelfare.gameObject:SetActive(levelmgr.UnRead())

    if fields.UIToggle_Mall.value then
        RefreshPageMall()
    elseif fields.UIToggle_Skill.value then
        RefreshPageSkill()
    elseif fields.UIToggle_LevelWelfare.value then
        RefreshPageLevelWelfare()
    end
end

-- local function update()
-- end

local function OnToggle(uitoggle, toggled)
    if toggled then
        -- printyellow("On toggle")
        refresh()
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)
    fields.UIToggle_Skill.gameObject:SetActive(false) --先将家族技能功能隐藏

    EventHelper.SetToggle(fields.UIToggle_Mall, OnToggle)
    EventHelper.SetToggle(fields.UIToggle_Skill, OnToggle)
    EventHelper.SetToggle(fields.UIToggle_LevelWelfare, OnToggle)

    EventHelper.SetClick(fields.UIButton_LevelupMall, function()
        local data = ConfigManager.getConfigData("familyshop", mgr.Info().malllevel)
        uimanager.ShowAlertDlg({title=LocalString.Family.TitleLevelupMall,
                                immediate = true,
                                content=string.format(LocalString.Family.ContentLevelupMall, data.shoprequirecapital.money, mgr.Info().malllevel+1),
                                callBackFunc=function()
                                    if  mgr.Info().money < data.shoprequirecapital.money  then
                                        uimanager.ShowSystemFlyText(LocalString.Family.NoEnoughFamilyMoney)
                                    else
                                        if checkcmd.CheckData({data=data, showsysteminfo=false}) then
                                            mallmgr.LevelupMall(function()
                                                RefreshPageMall()
                                            end)
                                        end
                                    end                                    
                                end
        })
    end)

    EventHelper.SetClick(fields.UIButton_LevelupSkillMax, function()
        local data = ConfigManager.getConfigData("familyskill", skillmgr.MaxLevel()+1)
        uimanager.ShowAlertDlg({title=LocalString.Family.TitleLevelupSkillMax,
                                immediate = true,
                                content=string.format(LocalString.Family.ContentLevelupSkillMax, data.requirefamilycapital.money, skillmgr.MaxLevel()+1),
                                callBackFunc=function()
                                    if checkcmd.CheckData({data=data, showsysteminfo=false}) then
                                        skillmgr.LevelupMax(function()
                                                -- printyellow("on level up skill max")
                                                RefreshPageSkill()
                                        end)
                                    else
                                        uimanager.ShowSingleAlertDlg({content=LocalString.Family.HintSkillMaxLevelup})
                                    end
                                end
        })
    end)

    -- mall
    EventHelper.SetWrapListRefresh(fields.UIList_Mall.gameObject:GetComponent("UIWrapContentList"), function(item, itemi, i)
        if not m_GoodIDList or i > #m_GoodIDList then return end
        local good = mallmgr.GetGood(m_GoodIDList[i])
        if not good then return end
        item.Data = good
        local data = itemmgr.CreateItemBaseById(good.itemid.itemid, nil, 1)
        --item.Controls["UITexture_Icon"]:SetIconTexture(data:GetIconPath())
        bonusmgr.SetRewardItem(item, data, {notSetClick=true})
        item.Controls["UILabel_Contrib"].text = good.cost.amount
        item.Controls["UILabel_Descrip"].text = good.introduce
        local limit = limitmgr.GetDayLimitTotal(good.limitlist.limits)
        item.Controls["UILabel_Limit"].text = limit > 0
            and string.format(LocalString.Family.HintMallLimit, limit-limitmgr.GetDayLimitTime(cfg.cmd.ConfigId.MALL, good.id))
            or ""
        item.Controls["UIButton_Exchange"].isEnabled = checkcmd.Check({moduleid=cfg.cmd.ConfigId.MALL, cmdid=good.id, showsysteminfo=false})
        EventHelper.SetClick(item.Controls["UIGroup_Reward"], function()
            local ItemIntroduc = require("item.itemintroduction")
            ItemIntroduc.DisplayBriefItem({item = data})
        end)
        EventHelper.SetClick(item.Controls["UIButton_Exchange"], function()
            local good = item.Data
            local data = itemmgr.CreateItemBaseById(good.itemid.itemid, nil, 1)
            if checkcmd.Check({moduleid=cfg.cmd.ConfigId.MALL, cmdid=good.id}) then
                mallmgr.Buy(good.id, function()
                    --printyellow("on buy callback")
                    RefreshPageMall(true)
                end)
            end
        end)
    end)

    -- skill
    local skilllist = ConfigManager.getConfig("familyskillcost")
    for skillid,dataskill in pairs(skilllist) do
        local item = fields.UIList_Skill:GetItemById(skillid) or fields.UIList_Skill:AddListItem()
        item.Id = skillid
        item.Data = dataskill

        item.Controls["UITexture_Icon"]:SetIconTexture(dataskill.icon)
        item.Controls["UILabel_Name"].text = dataskill.name
        EventHelper.SetClick(item.Controls["UIButton_Learn"], function()
            local skill = skillmgr.GetSkill(skillid)
            local dataskilllevelnext = dataskill.skillinfo[skill.level+1]
            if not dataskilllevelnext then return end
            local cost = dataskilllevelnext.requirefamilycapital.money
            uimanager.ShowAlertDlg({title=LocalString.Family.TitleLevelupSkill,
                                    immediate = true,
                                    content=string.format(LocalString.Family.ContentLevelupSkill, cost, dataskill.name),
                                    callBackFunc=function()
                                        if checkcmd.CheckData({data=dataskilllevelnext, showsysteminfo=false}) then
                                            skillmgr.LevelupSkill(item.Id, function()
                                                                      --printyellow("on callback")
                                                                      RefreshPageSkill()
                                            end)
                                        end
                                    end
            })
        end)
    end

    -- level welfare
    local welfarelist = ConfigManager.getConfig("familybonus")
    for id,data in pairs(welfarelist) do
        local item = fields.UIList_LevelWelfare:GetItemById(id) or fields.UIList_LevelWelfare:AddListItem()
        local level = data.requirefamilylvl.level
        item.Id = level
        item.Data = data

        local awards = bonusmgr.GetItemsOfBonus({bonustype="cfg.bonus.FamilyBonus", csvid=data.bonusid})
        local listReward = item.Controls["UIList_Reward"]
        while listReward.Count < getn(awards) do
            listReward:AddListItem()
        end
        for ia,award in ipairs(awards) do
            local itema = listReward:GetItemByIndex(ia-1)
            itema.gameObject:SetActive(true)
            bonusmgr.SetRewardItem(itema, award)
        end

        item.Controls["UILabel_Level"].text = string.format(LocalString.Family.TagLevel, data.requirefamilylvl.level)
        EventHelper.SetClick(item.Controls["UIButton_Receive"], function()
            levelmgr.GetLevelWelfare(level, function()
                                         item.Controls["UIButton_Receive"].isEnabled = false
                                         -- 刷新红点提示
                                         fields.UISprite_UnRead_LevelWelfare.gameObject:SetActive(levelmgr.UnRead())
                                         require("ui.dlguimain").RefreshRedDotType(cfg.ui.FunctionList.FAMILY)                                        
                                         require("ui.dlgdialog").RefreshRedDot("family.dlgfamily")
                                         -- uimanager.show("dlgalert_getrewards", {items=awards, title=string.format(LocalString.Family.TitleGetLevelBonus, level)})
                                         -- 奖励内容飘字
                                         --[[for i = 1, #awards do
		                                     -- 不显示钱币，由其他模块负责显示
		                                     if awards[i]:GetDetailType() ~= ItemEnum.ItemType.Currency then
			                                     uimanager.ShowSystemFlyText(string.format(LocalString.FlyText_Reward,awards[i]:GetNumber(),awards[i]:GetName()))
		                                     end
                                         end]]
            end)
        end)
    end
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    showtab      = showtab,
    show         = show,
    hide         = hide,
    refresh      = refresh,
    destory      = destory,
    init         = init,
    uishowtype   = uishowtype,
}
