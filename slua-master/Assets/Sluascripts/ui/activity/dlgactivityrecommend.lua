local unpack = unpack
local print = print
local format = string.format
local ItemIntroduct = require("item.itemintroduction")
local ItemEnum = require("item.itemenum")
local WelfareManager = require("ui.welfare.welfaremanager")
local BonusManager = require("item.bonusmanager")
local EventHelper = UIEventListenerHelper
local uimanager = require "uimanager"
local network = require "network"
local os = require 'cfg.structs'
local create_datastream = create_datastream
local charactermanager = require "character.charactermanager"
local configmanager = require "cfg.configmanager"
local PlayerRole = require "character.playerrole"
local defineenum = require "defineenum"
local itemmanager = require "item.itemmanager"
local scenemanager = require "scenemanager"
local gameObject
local name
local fields


local function second_update(now)
end

local function destroy()
end

local function show(params)
end

local function hide()
end

local function refresh(params)
end

local function update()
end

local function init(params)
	name, gameObject, fields = unpack(params)
	EventHelper.SetClick(fields.UIButton_Close, function()
        uimanager.hidedialog("activity.dlgactivityrecommend")
        uimanager.show("dlguimain")
	end)
	EventHelper.SetClick(fields.UIButton_GO, function()
        uimanager.hidedialog("activity.dlgactivityrecommend")
        uimanager.GoToDlg("operationactivity.dlgoperationactivity", 2, -1, -1)
    end)
    -- UITexture_BG
    -- UILabel_Desc
    fields.UILabel_Desc.text = ""
end

return {
    init = init,
    show = show,
    hide = hide,
	update = update,
	second_update = second_update,
    destroy = destroy,
    refresh = refresh,
}
