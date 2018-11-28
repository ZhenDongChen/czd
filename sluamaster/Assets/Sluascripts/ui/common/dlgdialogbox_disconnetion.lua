local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")


local name
local gameObject
local fields
local cdTitme = 60
local nowTime 
local cdTitmeState = false

local function refresh(params)
	if params then    
		if params.reconnect then
			fields.UILabel_Reconnect.text = params.reconnect
		end
		-- if params.tip then
		-- 	fields.UILabel_Tip.text = params.tip
		-- end
	end  
end

local function update()
	local time = cdTitme - (os.time() - nowTime)
	if not cdTitmeState then
		if time <= 0  then 
			UIManager.show("common.dlgdialogbox_reconnect")
			UIManager.hide("common.dlgdialogbox_disconnetion")
			cdTitmeState = true
		else
			fields.UILabel_Time.text = time.."s"
		end
	end
end

local function show(params)
	cdTitmeState = false
    if params then    
		if params.reconnect then
			fields.UILabel_Reconnect.text = params.reconnect
		end
		-- if params.tip then
		-- 	fields.UILabel_Tip.text = params.tip
		-- end
    end   
end

local function init(params)
	name,gameObject,fields=Unpack(params)
	nowTime = os.time();
end

local function uishowtype()
	return UIShowType.DestroyWhenHide
end

local function hide()
	cdTitmeState = false
end

return{
    show = show,
    init = init,
	refresh = refresh,
	update = update,
	uishowtype = uishowtype,
	hide = hide,
}