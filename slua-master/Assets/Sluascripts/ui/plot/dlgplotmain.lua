
local unpack, print = unpack, print
local EventHelper   = UIEventListenerHelper
local UIManager     = require("uimanager")
local ModFadeInOut  = require("ui.plot.plotuimodule.fadeinout")
local ModTalk       = require("ui.plot.plotuimodule.talk")
local ModUIEffect   = require("ui.plot.plotuimodule.uieffect")
local ModQTE        = require("ui.plot.plotuimodule.qte")


local PlotDirector  = require("plot.base.plotdirector")
local name, gameObject, fields
local cutsceneName

----------------------------------------------------------------------
local function StopCutscene()
    local PlotManager = require("plot.plotmanager")
    --printyellow("Stop")
    PlotManager.CutsceneStop(cutsceneName)

end
----------------------------------------------------------------------

local function refresh(params)
    ModFadeInOut.refresh(params)
    ModTalk.refresh(params)
    ModUIEffect.refresh(params)
    ModQTE.refresh(params)
end

local function update()
    ModFadeInOut.update()
    ModTalk.update()
    ModUIEffect.update()
    ModQTE.update()
end

local function show(params)
    ModFadeInOut.show(params)
    ModTalk.show(params)
    ModUIEffect.show(params)
    ModQTE.show(params)
    
    cutsceneName = ((params ~= nil) and params.cutsceneName) or ""
    
    --fields.UIButton_Skip.gameObject:SetActive(true)
    fields.UIProgressBar_BlackEdgeBottom.value = 0
    fields.UIProgressBar_BlackCurtain.alpha = 0
    fields.UIProgressBar_BlackEdgeTop.value = 0
    fields.UILabel_MovieContent.text = ""
    local skippable = params.isSkippable
    EventHelper.SetClick(fields.UIButton_Background, function()
        if params == nil or params.isSkippable == true then
            fields.UIButton_Skip.gameObject:SetActive(true)
            EventHelper.SetClick(fields.UIButton_Skip, function()
                StopCutscene()
            end)
        end
    end)
    if params == nil or params.isSkippable == true then
        fields.UIButton_Skip.gameObject:SetActive(true)
        EventHelper.SetClick(fields.UIButton_Skip, function()
            StopCutscene()
        end)
    else
        fields.UIButton_Skip.gameObject:SetActive(false)
    end
end

local function SetSkippable()
    fields.UIButton_Skip.gameObject:SetActive(true)
    EventHelper.SetClick(fields.UIButton_Skip, function()
        StopCutscene()
    end)
    EventHelper.SetClick(fields.UIButton_Background, function()
        fields.UIButton_Skip.gameObject:SetActive(true)
        EventHelper.SetClick(fields.UIButton_Skip, function()
            StopCutscene()
        end)    
    end)
end

local function hide()
    ModFadeInOut.hide()
    ModTalk.hide()
    ModUIEffect.hide()
    ModQTE.hide()
end

--[[
    E/Unity   (30259): stack traceback: 
    E/Unity   (30259): 	[string "common.utils"]: in function '__index' 
    E/Unity   (30259): 	[string "ui.plot.dlgplotmain"]: in function '' 
    E/Unity   (30259): 	[string "common.utils"]: in function < 
    [string "common.utils"]:0> 
    E/Unity   (30259): 	[C]: in function 'xpcall' 
    E/Unity   (30259): 	[string "uimanager"]: in function '' 
    E/Unity   (30259): 	[string "uimanager"]: in function <[string "uimanager"]:0> 
    E/Unity   (30259):   E/Unity   (3
]]

local function SetPlotUIAnchor(uiComponent)
    if uiComponent == nil then
        return
    end
    if uiComponent.gameObject then
        local widget = uiComponent.gameObject:GetComponent("UIWidget")
        if widget then
            UIManager.SetAnchor(widget)
        end
    end
end

local function init(params)
    name, gameObject, fields    = unpack(params)
    
    SetPlotUIAnchor(fields.UIGroup_Skip)
    SetPlotUIAnchor(fields.UIProgressBar_BlackEdgeTop)
    SetPlotUIAnchor(fields.UIProgressBar_BlackEdgeBottom)
    SetPlotUIAnchor(fields.UIProgressBar_BlackCurtain)
    SetPlotUIAnchor(fields.UIProgressBar_BlackCurtain2)
    SetPlotUIAnchor(fields.UIGroup_Talk)
    SetPlotUIAnchor(fields.UIGroup_UIEffect)

    ModFadeInOut.init(name, gameObject, fields)
    ModTalk.init(name, gameObject, fields)
    ModUIEffect.init(name, gameObject, fields)
    ModQTE.init(name, gameObject, fields)
end

local function destroy()

end


return {
  init                  = init,
  show                  = show,
  hide                  = hide,
  update                = update,
  destroy               = destroy,
  refresh               = refresh,
  
  SetFadeInOutEdge      = ModFadeInOut.SetFadeInOutEdge,
  SetFadeInOutCurtain   = ModFadeInOut.SetFadeInOutCurtain,

  SetFadeInOutCurtain2     = ModFadeInOut.SetFadeInOutCurtain2,

  SetTalk               = ModTalk.SetTalk,
  SetScreenWords        = ModUIEffect.SetScreenWords,

  SetSkippable          = SetSkippable,
}




