local unpack        = unpack
local require       = require
local format        = string.format
local network       = require("network")
local UIManager     = require("uimanager")
local ConfigManager = require("cfg.configmanager")
local ItemManager   = require("item.itemmanager")

local g_SelectedEquip

local function SetEquip(equip)
	g_SelectedEquip = equip
end

local function GetEquip()
	return g_SelectedEquip
end

local function init()


end

return {
	init     = init,
	SetEquip = SetEquip,
	GetEquip = GetEquip,
}
