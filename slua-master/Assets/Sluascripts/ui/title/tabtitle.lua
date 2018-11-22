local unpack, print = unpack, print
local EventHelper   = UIEventListenerHelper
local UIManager     = require("uimanager")
local TitleManager  = require("ui.title.titlemanager")
local Configmanager = require("cfg.configmanager")
local DlgAlertTitle = require("ui.title.dlgalerttitle")

local name, gameObject, fields
local currentGroup


local function TitleItemRefresh(uiItem,titleInfo)

 --   local titleInfo = currentGroup:GetTitle(realIndex)

    if titleInfo == nil then
        return
    end

    local UIButton_Equip    = uiItem.Controls["UIButton_Equip"]

    local UIButton_Title    = uiItem.Controls["UIButton_Title"]
    local UILabel_Title     = uiItem.Controls["UILabel_Title"]
    local UISprite_Title    = uiItem.Controls["UISprite_Icon"]
    local UITexture_Icon    = uiItem.Controls["UITexture_Icon"]
    
    local UIList_Property   = uiItem.Controls["UIList_Property"]
    local UILabel_Introduction = uiItem.Controls["UILabel_Introduction"]


  --  EventHelper.SetClick(UIButton_Title, function()
 --       DlgAlertTitle.Show(titleInfo)
  --  end)
    UILabel_Introduction.text = titleInfo:GetDescription()
    --uiTexture, uiSprite, uiLabel
    titleInfo:SetTitleShow(UITexture_Icon, UISprite_Title, UILabel_Title)
    
    
    --设置称号属性
    local propertyStrs = titleInfo:GetPropertyStrs()

    local propertyNum = #propertyStrs
    UIHelper.ResetItemNumberOfUIList(UIList_Property,propertyNum)
    for i = 1,propertyNum do
        local propItem = UIList_Property:GetItemByIndex(i-1)
        local propLabel =propItem.gameObject:GetComponent("UILabel")
        if propLabel ~= nil then
            propLabel.text = propertyStrs[i]
        end
    end

    --设置称号剩余时间
    local restTimeStr = titleInfo:GetRestTimeString()
    uiItem:SetText("UILabel_LastTime", restTimeStr)

    --装备按钮
    local currentTitle = TitleManager.GetCurrentEquipedTitle()
    if titleInfo.m_IsActive == true then
        UIButton_Equip.isEnabled = true
        if currentTitle ~= nil and titleInfo.m_Id == currentTitle.m_Id then
            uiItem:SetText("UILabel_Equip",LocalString.TitleSystem.EquipStr[3])
            EventHelper.SetClick(UIButton_Equip,function()
                TitleManager.DeActiveTitle(titleInfo)
            end)
        else
            uiItem:SetText("UILabel_Equip",LocalString.TitleSystem.EquipStr[1])

            EventHelper.SetClick(UIButton_Equip,function()
                TitleManager.ActiveTitle(titleInfo)
                -- local NoviceGuideTrigger=require"noviceguide.noviceguide_trigger"
                -- NoviceGuideTrigger.ClickUIObject(UIButton_Equip.transform)
            end)
        end
    else
        UIButton_Equip.isEnabled = false
        uiItem:SetText("UILabel_Equip",LocalString.TitleSystem.EquipStr[2])
        EventHelper.SetClick(UIButton_Equip,function()
            UIManager.refresh("title.tabtitle")
        end)

    end

end

local function RefreshTitleList(groupNum)
    currentGroup = TitleManager.TitleGroupList[groupNum]
    local titleList = currentGroup:GetTitleList()
    local titleListShow = {}
    for i, title in ipairs(titleList) do
        if title:IsShow() then
            table.insert( titleListShow, title )
        end
    end
    local titleNum = #titleListShow --currentGroup:GetNumber()
    local wrapList = fields.UIList_Title.gameObject:GetComponent("UIWrapContentList")
    EventHelper.SetWrapListRefresh(wrapList, function(uiItem,index,realIndex)
        local titleInfo = titleListShow[realIndex]
        TitleItemRefresh(uiItem, titleInfo)
    end)

    wrapList:SetDataCount(titleNum)
    wrapList:CenterOnIndex(-0.2)

end
---------------------------------------------------------------------------------------------
local function refresh(params)

    --设置标题组名称
    local groupNum = TitleManager.GetGroupNumber()
    UIHelper.ResetItemNumberOfUIList(fields.UIList_TitleTab, groupNum)

    local selectGroupNum = fields.UIList_TitleTab:GetSelectedIndex()

    for i = 1, groupNum do
        uiItem = fields.UIList_TitleTab:GetItemByIndex(i-1)
        uiItem:SetText("UILabel_Theme",TitleManager.TitleGroupList[i].m_GroupName)
        local sprite = uiItem.Controls["UISprite_Warning"]
        if sprite and TitleManager.TitleGroupList[i] and TitleManager.TitleGroupList[i].m_ExistNew == true then
            if i == selectGroupNum + 1 then
                sprite.gameObject:SetActive(false)
            else
                sprite.gameObject:SetActive(true)
            end
        else
            sprite.gameObject:SetActive(false)
        end
    end

    

    if selectGroupNum < 0 then
        fields.UIList_TitleTab:SetSelectedIndex(0)
        selectGroupNum = 0
    end

    TitleManager.TitleGroupList[selectGroupNum+1].m_ExistNew = false
    local existNew = false
    for i = 1, groupNum do
        if TitleManager.TitleGroupList[i].m_ExistNew == true then
            existNew = true
        end
    end

   --[[
    if existNew  ==  true then
        fields.UISprite_Warning.gameObject:SetActive(true)
    else
        fields.UISprite_Warning.gameObject:SetActive(false)
    end
   ]]
    RefreshTitleList(selectGroupNum+1)
end

local function RefreshWithoutSort()
    local wrapList = fields.UIList_Title.gameObject:GetComponent("UIWrapContentList")
    wrapList:RefreshWithOutSort()
end

local function second_update()
    local wrapList = fields.UIList_Title.gameObject:GetComponent("UIWrapContentList")
    wrapList:RefreshWithOutSort()
end

local function destroy()

end

local function show(params)
    EventHelper.SetListClick(fields.UIList_TitleTab,function(item)
        UIManager.refresh("title.tabtitle")
    end)
end

local function hide()

end

local function update()

end



local function showtab(params)
    UIManager.show("title.tabtitle",params)
end

local function init(params)
    name, gameObject, fields    = unpack(params)
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  showtab = showtab,
  second_update = second_update,
  RefreshWithoutSort = RefreshWithoutSort
}
