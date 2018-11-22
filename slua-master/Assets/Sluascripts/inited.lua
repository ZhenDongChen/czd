local require = require
local ConfigManager = require"cfg.configmanager"
local uimanager = require "uimanager"
local SceneManager = require"scenemanager"
local os = require "common.octets"

local function init()
	Game.Platform.Interface.Instance:Login();
	SceneManager.RegisteOnLoginFinish(true)
end

return {
	init = init,
}
