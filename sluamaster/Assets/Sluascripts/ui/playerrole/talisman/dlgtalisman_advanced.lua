local unpack            = unpack
local print             = print
local require           = require

local UIManager         = require("uimanager")
local EventHelper       = UIEventListenerHelper
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")

----------------------------------------------------------------------------------------------------
local name
local gameObject
local fields

local PageTalismanStar          = require("ui.playerrole.talisman.advancepages.pagetalismanstar")
local PageTalismanAwake         = require("ui.playerrole.talisman.advancepages.pagetalismanawake")
local PageTalismanWuxing        = require("ui.playerrole.talisman.advancepages.pagetalismanwuxing")
local PageTalismanDecomposition = require("ui.playerrole.talisman.advancepages.pagetalismandecomposition")
local Pages = {
    [1] = PageTalismanStar,
    [2] = PageTalismanAwake,
    [3] = PageTalismanWuxing,
    [4] = PageTalismanDecomposition,
}
local CurrentPageIndex = 1
local CurrentPage
local selectedTalisman
local showRedDot = false

local function destroy()

end

local function hide()

end

local function OnMsgStarOrder(params)
    if CurrentPageIndex == 1 then
        Pages[1]:OnMsgStarOrder(params)
    end
end

local function OnMsgAwake(params)
    if CurrentPageIndex == 2 then
        Pages[2]:OnMsgAwake(params)
    end
end

local function OnMsgWash(params)
    if CurrentPageIndex == 3 then
        Pages[3]:OnMsgWash(params)
    end
end

local function ChangeEnd(params)
    if CurrentPageIndex == 3 then
        Pages[3]:ChangeEnd(params)
    end
end

local function OnMsgDecom(params)
    if CurrentPageIndex == 4 then
        Pages[4]:OnMsgDecom(params)
    end
end

local function ShowRedDot(talisman)
    local starRedDot = PageTalismanStar:ShowRedDot(talisman)
    local awakeRedDot = PageTalismanAwake:ShowRedDot(talisman)
    local wuxingRedDot = PageTalismanWuxing:ShowRedDot(talisman)
    fields.UISprite_StarTip.gameObject:SetActive(starRedDot)
    fields.UISprite_AwakTip.gameObject:SetActive(awakeRedDot)
    fields.UISprite_WuxingTip.gameObject:SetActive(wuxingRedDot)
end



local function refresh(params)

  --  local CurrentPage = Pages[CurrentPageIndex]
    for i, page in ipairs(Pages) do
        if i == CurrentPageIndex then
            page:show()
            page:refresh(selectedTalisman)
        else
            page:hide()
        end
    end
    if showRedDot then
        ShowRedDot(selectedTalisman)
    end
end

local function setbuttons(selectedTalisman)

    EventHelper.SetClick(fields.UIToggle_Star, function()
        CurrentPageIndex = 1
        UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")
    end)
    EventHelper.SetClick(fields.UIToggle_Awakening, function()
        CurrentPageIndex = 2
        UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")
    end)

    EventHelper.SetClick(fields.UIToggle_Returning, function()
        CurrentPageIndex = 4
        UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")
    end)
    if selectedTalisman then
        EventHelper.SetClick(fields.UIToggle_WuXing, function()
            if selectedTalisman:GetNormalLevel() >= cfg.talisman.TalismanFeed.WUXING_OPEN_LEVEL then
                CurrentPageIndex = 3
                UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")
            else
                UIManager.ShowSingleAlertDlg({ content = string.format(LocalString.Talisman.WuXing[1],cfg.talisman.TalismanFeed.WUXING_OPEN_LEVEL) })
            end
        end)
    end
end

local function show(params)
    selectedTalisman = params.talisman
    if params and params.showRedDot then
        showRedDot = true
    else
        showRedDot = false
    end
    TalismanManager.TalismanSystemConfig.ConsumeTalismans = {}
    fields.UIGroup_RadioButtonRight.gameObject:SetActive(true)
    setbuttons(selectedTalisman)
end

local function update()
    if CurrentPageIndex == 3 then
        PageTalismanWuxing:update()
    end
end


local function init(params)
    name, gameObject, fields = unpack(params)

    for i, page in ipairs(Pages) do
        page:init(name, gameObject, fields)
        page:hide()
    end
    gameObject.transform.position = Vector3(0,0,-1000)
    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide("playerrole.talisman.dlgtalisman_advanced")
    end)


end

local function UnRead(currentTalisman)
  --  local talisman = currentTalisman or TalismanManager.GetCurrentTalisman()
  --  if talisman then
  --      local starUnRead = PageTalismanStar:ShowRedDot(talisman)
  --      local awakeUnRead = PageTalismanAwake:ShowRedDot(talisman)
  --      return starUnRead or awakeUnRead
  --  end
    local starRedDot = PageTalismanStar:ShowRedDot(currentTalisman)
    local awakeRedDot = PageTalismanAwake:ShowRedDot(currentTalisman)
    local wuxingRedDot = PageTalismanWuxing:ShowRedDot(currentTalisman)
    return starRedDot or awakeRedDot or wuxingRedDot
end


return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,

    UnRead = UnRead,

    OnMsgStarOrder = OnMsgStarOrder,
    OnMsgAwake = OnMsgAwake,
    OnMsgWash = OnMsgWash,
    ChangeEnd = ChangeEnd,
    OnMsgDecom = OnMsgDecom,

}
