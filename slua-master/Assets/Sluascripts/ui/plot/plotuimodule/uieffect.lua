local name, gameObject, fields
local unpack            = unpack
local print             = print
local EventHelper       = UIEventListenerHelper
local uimanager         = require("uimanager")
local ConfigManager     = require("cfg.configmanager")
--local PlotManager       = require("plot.plotmanager")
local define            = require("define")
local PlotHelper        = require("plot.plothelper")


local function ShowEffect(cutscene, index, positionIn)
    --local uieffect = cutscene.m_Pool:Spawn(index)

    --printyellow("ShowEffect:", index)
    local plotassets = ConfigManager.getConfigData("plotassets",index)
    if plotassets == nil then
        logError("Can't find Plot Resources: " .. index)
        return
    end
    local model = ConfigManager.getConfigData("model",plotassets.path)
    if model == nil then
        logError("Can't find Model: " .. plotassets.path)
        return
    end
    local path = PlotHelper.GetBundlePath(model)
    local Position = Vector3(0,0,0)
    if positionIn ~= nil then
        Position = Vector3(positionIn.x,positionIn.y,0)
    end
    --printyellow("[[[[[[[[[[[[[[[[[")
    Util.Load(path, define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)
        if (not IsNull(asset_obj)) and (not IsNull(fields.UIGroup_UIEffect)) then
            local tempObject = Util.Instantiate(asset_obj,path)

            --Object.transform.localScale = Vector3(1,1,1)
            tempObject.transform.position = Position
            tempObject.transform.parent = fields.UIGroup_UIEffect.gameObject.transform
            tempObject.name = index
            tempObject.transform.localScale = Vector3(1,1,1)
        end
    end)
    --printyellow("]]]]]]]]]]]]]]]]]]")

   -- uieffect.transform.parent = fields.UIGroup_UIEffect.gameObject.transform
  --  uieffect.transform.localScale = Vector3(1,1,1)
  --  local Position = (vec2 ~= nil) and Vector3(vec2.x,vec2.y,0) or Vector3(0,0,0)
end

local function HideEffect(cutscene, index)
    --cutscene.m_Pool:Despawn(index)
    local trans = fields.UIGroup_UIEffect.gameObject.transform:Find(index)
    if trans then
        trans.gameObject:SetActive(false)
        Util.Destroy(trans.gameObject)
    end
end

local function update()

end

local function refresh()

end

local function hide()
    local delList = {}
    for i = 1, fields.UIGroup_UIEffect.transform.childCount do
        local childTrans = fields.UIGroup_UIEffect.transform:GetChild(i-1)
        if childTrans then
            table.insert(delList, childTrans.gameObject)
        end
    end
    for i, go in pairs(delList) do
        Util.Destroy(go)
    end
end

local function show(params)

end

local function init(nameIn, gameObjectIn, fieldsIn)
    name, gameObject, fields = nameIn, gameObjectIn, fieldsIn

end
local function SetScreenWords(params)
    if params.mode == "Show" then
        --printyellow(params.mode, params.cutscene, params.index, params.position)
        ShowEffect(params.cutscene, params.index, params.position)
    elseif params.mode == "Hide" then
        HideEffect(params.cutscene, params.index, params.position)
    end
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    refresh = refresh,
   -- ShowEffect = ShowEffect,
   -- HideEffect = HideEffect,
    SetScreenWords = SetScreenWords,
}
