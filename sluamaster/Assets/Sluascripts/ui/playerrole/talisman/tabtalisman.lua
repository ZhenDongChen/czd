local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local DlgAdvance = require("ui.playerrole.talisman.dlgtalisman_advanced")

local gameObject
local name
local fields

local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")

local PageTalismanEquip = require("ui.playerrole.talisman.talismanpages.pagetalismanequip")
local PageTalismanInfo  = require("ui.playerrole.talisman.talismanpages.pagetalismaninfo")
local PageTalismanSkill = require("ui.playerrole.talisman.talismanpages.pagetalismanskill")
local PageTalismanBag   = require("ui.playerrole.talisman.talismanpages.pagetalismanbag")

local LeftPage = PageTalismanEquip
local RightPages = {
    [1] = PageTalismanInfo,
    [2] = PageTalismanSkill,
    [3] = PageTalismanBag,
}
local CurrentRightPage = nil

local CurrentRightPageIndex = 1
local CurrentTalisman = nil

---------------------------------------------------------------------------------------------
local function ToggleSet(num)
    for i =1, 3 do
        local uiItem = fields.UIList_RadioButton:GetItemByIndex(i-1)
        local uiToggle = uiItem.gameObject:GetComponent("UIToggle")
        uiToggle.startsActive = (((i == num) and true) or false)
        uiToggle.value = (((i == num) and true) or false)
        if i == 2 then
            local spriteWarning = uiItem.Controls["UISprite_SkillWarning"]
            if spriteWarning then
                local talisman = TalismanManager.GetCurrentTalisman()
                if talisman then
                    local re = PageTalismanSkill:ShowRedDot(talisman)
                    if re then
                        spriteWarning.gameObject:SetActive(true)
                    else
                        spriteWarning.gameObject:SetActive(false)
                    end
                else
                    spriteWarning.gameObject:SetActive(false)
                end
            end
        end
    end
    fields.UIList_RadioButton:SetSelectedIndex(num-1)

end

local function OnMsgUpdateSkill(params)
    if params and params.skillId and params.curTalisman then
        RightPages[2]:OnMsgUpdateSkill(params.curTalisman, params.skillId)
    end
end
---------------------------------------------------------------------------------------------


local function refresh(params)
    
    CurrentTalisman = TalismanManager.GetCurrentTalisman()

    if CurrentTalisman == nil then
        CurrentRightPageIndex = 3
    end
    ToggleSet(CurrentRightPageIndex)
    
    CurrentRightPage = RightPages[CurrentRightPageIndex]

    for i = 1, 3 do
        if i == CurrentRightPageIndex then
            RightPages[i]:show()
        else
            RightPages[i]:hide()
        end
    end

    PageTalismanEquip:refresh(CurrentTalisman)
    CurrentRightPage:refresh(CurrentTalisman)
    if UIManager.isshow("dlgdialog") then
        UIManager.call("dlgdialog","RefreshRedDot","playerrole.dlgplayerrole")
    end
end

local function update()
    PageTalismanEquip:update()
end

local function destroy()

end

local function show(params)
    PageTalismanEquip:show()
end

local function hide()
    PageTalismanEquip:hide()
--    PageTalismanInfo:hide()
--    PageTalismanSkill:hide()
--    PageTalismanBag:hide()
end

local function hidetab()
    UIManager.hide("playerrole.talisman.tabtalisman")
end

local function showtab(params)
    UIManager.show("playerrole.talisman.tabtalisman",params)
end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    name, gameObject, fields    = unpack(params)

    PageTalismanEquip:init(name, gameObject, fields)
    PageTalismanInfo:init(name, gameObject, fields)
    PageTalismanSkill:init(name, gameObject, fields)
    PageTalismanBag:init(name, gameObject, fields)

    PageTalismanEquip:hide()
    PageTalismanInfo:hide()
    PageTalismanSkill:hide()
    PageTalismanBag:hide()
    
    EventHelper.SetListClick(fields.UIList_RadioButton, function(uiItem)
        CurrentRightPageIndex = uiItem.Index +1
        UIManager.refresh("playerrole.talisman.tabtalisman")
    end)
end

local function UnRead()
    

    local talisman = TalismanManager.GetCurrentTalisman()
    if talisman then
        local upgradeUnRead = PageTalismanEquip:UpgradeRedDot(talisman)
        local skillUnRead = PageTalismanSkill:ShowRedDot(talisman)
        local advaneUnRead = DlgAdvance.UnRead(talisman)
        return upgradeUnRead or skillUnRead or advaneUnRead
    end
    
    return false
end


return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  showtab = showtab,
  hidetab = hidetab,
  uishowtype = uishowtype,
  OnMsgUpdateSkill = OnMsgUpdateSkill,
  UnRead = UnRead,
}
