
local print, require    = print, require
local Monster           = require("character.monster")
local defineenum        = require("defineenum")
local CharacterType     = defineenum.CharacterType
local ConfigManager     = require("cfg.configmanager")

local Boss = Class:new(Monster)

function Boss:__new()
    Monster.__new(self)
    self.m_Type = defineenum.CharacterType.Boss
end

function Boss:IsBoss()
    return true
end

return Boss
