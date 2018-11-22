local ItemEnum      = require("item.itemenum")
local UIManager     = require("uimanager")
--local DlgAlertTitle = require("ui.title.dlgalerttitle")
--local TitleManager  = require("ui.title.titlemanager")
--物品展示调用框
local function DisplayItem(params)
    if params and params.item then
            if params.item:GetBaseType() == ItemEnum.ItemBaseType.Item and params.item:GetDetailType() == ItemEnum.ItemType.Title then
                local titleInfo = TitleManager.GetTitleById(params.item:GetTitleId())
                if titleInfo ~= nil then
                    DlgAlertTitle.Show(titleInfo)
                end
            else
                UIManager.show("dlgalert_equipment",params)
            end
    end
end

local function DisplayBriefItem(params)
	UIManager.show("dlgalert_briefitemdiscription",params)
end

return {
    DisplayItem      = DisplayItem,
	DisplayBriefItem = DisplayBriefItem,
}
