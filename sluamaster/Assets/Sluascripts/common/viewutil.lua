local ipairs = ipairs
local setmetatable = setmetatable
local print = print
local error = error

local export_suffixs =
{
	UILabel = 1, -- 1 表示需要递归导出子GameObject的fields
	UISprite = 1,
	UIButton = 1,
	UIGroup = 1,
    UIToggle = 1,
    UIGrid  = 1,
	UIInput = 1,
    UITexture=1,
    UISlider=1,
    UITweener = 1,
	UIAnchor=1,
    TweenRotation = 1,
    TweenPosition = 1,
    TweenScale =1,
    TweenAlpha = 1,
    UIWidget = 1,
    UIProgressBar=1,
    UIPanel=1,
	UIScrollView=1,
    UIPlayTweens = 1,
	UIPlayTween = 1,
	UIList = 2, -- 2 表示只导到当前GameObject,不再导出子GameObject
}


local function collect_exported_gameobjects(transform, export_sets)
	for i = 0, transform.childCount-1 do

		local childT = transform:GetChild(i)
		local child = childT.gameObject
		local name = child.name

		local _, pos = name:find('_', 2, true)
		local isGroup = false
		if pos and pos > 1 then

			local suffix = name:sub(1, pos - 1)
			local ftype = export_suffixs[suffix]
			if ftype then
				if export_sets[name] then
				else
				  local com = LuaHelper.GetComponent(child,suffix)
				  if com then
				    export_sets[name] = com
				  end
				  isGroup = (ftype == 2)
				end
			end
		end
		if not isGroup then
			collect_exported_gameobjects(childT, export_sets)
		end
	end
end

local function export_fields(gameObject)
	local fields = {}
	collect_exported_gameobjects(gameObject.transform, fields)
	return fields
end

local function set_prefab_all_labels_default_font(go)
    local DefaultFont = DefaultFont
    local labels = go:GetComponentsInChildren(UILabel, true)
    for i = 1, labels.Length do
        labels[i].trueTypeFont = DefaultFont
    end
end

local function SetTextureGray(texture,isgray)
    if texture then 
        if isgray then
            texture.shader=Shader.Find("Unlit/Transparent Colored Gray")
        else
            texture.shader=Shader.Find("Unlit/Transparent Colored")
        end
    end 
    
end 

return {
	export_fields = export_fields,
	set_prefab_all_labels_default_font = set_prefab_all_labels_default_font,
    SetTextureGray = SetTextureGray,
}
