local unpack = unpack
local name
local gameObject
local fields

local function show(params)
	fields.UITexture_Speak:SetIconTexture("Texture_SendVoice")
end

local function refresh(params)
end

local function hide()
end

local function destroy()
end

local function init(params)
    name, gameObject, fields = unpack(params)
end

return {
	init = init,
	hide = hide,
	destroy = destroy,
	refresh = refresh,
	show = show,
}

