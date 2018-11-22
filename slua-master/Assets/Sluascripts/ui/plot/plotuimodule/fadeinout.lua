local name, gameObject, fields

local function SetFadeInEdge(rate)
    fields.UIProgressBar_BlackEdgeTop.value     = rate
    fields.UIProgressBar_BlackEdgeBottom.value  = rate   
end

local function SetFadeOutEdge(rate)
    fields.UIProgressBar_BlackEdgeTop.value     = 1 - rate
    fields.UIProgressBar_BlackEdgeBottom.value  = 1 - rate 
end

local function SetFadeInCurtain(rate)
    fields.UIProgressBar_BlackCurtain.alpha = rate
end

local function SetFadeOutCurtain(rate)
    fields.UIProgressBar_BlackCurtain.alpha = 1 - rate
end

local function SetFadeInCurtain2(rate)
    --printyellow("+++++++++++++",rate)
    fields.UIProgressBar_BlackCurtain2.alpha = rate
end

local function SetFadeOutCurtain2(rate)
    fields.UIProgressBar_BlackCurtain2.alpha = 1 - rate
end


local function update()

end
local function refresh()

end

local function hide()
    fields.UIProgressBar_BlackEdgeTop.value = 0
    fields.UIProgressBar_BlackEdgeBottom.value = 0
    fields.UIProgressBar_BlackCurtain.alpha = 0
    if fields.UIProgressBar_BlackCurtain2 then
        fields.UIProgressBar_BlackCurtain2.alpha = 0
    end
end

local function show(params)
    fields.UIProgressBar_BlackEdgeTop.value = 1
    fields.UIProgressBar_BlackEdgeBottom.value = 1
    fields.UIProgressBar_BlackCurtain.alpha = 0
    if fields.UIProgressBar_BlackCurtain2 then
        fields.UIProgressBar_BlackCurtain2.alpha = 0
    end
end

local function init(nameIn, gameObjectIn, fieldsIn)
    name, gameObject, fields = nameIn, gameObjectIn, fieldsIn
end

local function SetFadeInOutEdge(params)
    local value = (params.value < 1) and ((params.value > 0) and params.value or 0) or 1
    if params.mode == "In" then
        SetFadeInEdge(value)
    elseif params.mode == "Out" then
        SetFadeOutEdge(value)
    end
end


local function SetFadeInOutCurtain2(params)
    --printyellow("SetFadeInOutCurtain",params.mode, params.value)
    if params.mode == "In" then
        SetFadeInCurtain2(params.value)
    elseif params.mode == "Out" then
        SetFadeOutCurtain2(params.value)
    end
end

local function SetFadeInOutCurtain(params)
    --printyellow("SetFadeInOutCurtain",params.mode, params.value)
    if params.mode == "In" then
        SetFadeInCurtain(params.value)
    elseif params.mode == "Out" then
        SetFadeOutCurtain(params.value)
    end
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    refresh = refresh,
    
    --SetFadeInEdge = SetFadeInEdge,
    --SetFadeOutEdge = SetFadeOutEdge,
    --SetFadeInCurtain = SetFadeInCurtain,
    --SetFadeOutCurtain = SetFadeOutCurtain,
    
    SetFadeInOutEdge = SetFadeInOutEdge,
    SetFadeInOutCurtain = SetFadeInOutCurtain,
    SetFadeInOutCurtain2 = SetFadeInOutCurtain2,
}