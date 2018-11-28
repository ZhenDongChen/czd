--=============================================
--剧情播放的准备工作及善后工作
--=============================================
local CharacterManager  = require("character.charactermanager")
local GraphicSettingMgr = require("ui.setting.graphicsettingmanager")
local EctypeManager     = require("ectype.ectypemanager")
local Define            = require("define")
local NetWork           = require("network")
local GameEvent         = require("gameevent")
local defineenum        = require "defineenum"
local GrahpicQuality    = defineenum.GrahpicQuality

local PlotUtil = Class:new()

function PlotUtil:__new(cutscene, config)
    
    self.m_Cutscene = cutscene
    self.m_Config = config
    self:OnLoad()
end

function PlotUtil:HideLayer(camera, layers)
    --printyellow("HideLayer")
    local re = bit.band(bit.lshift(1,0),bit.lshift(1,2))
    for i,layer in pairs(layers) do
        re = bit.bor(re,bit.lshift(1,layer))
    end
    camera.cullingMask = bit.band(camera.cullingMask,bit.bnot(re))
end
function PlotUtil:ShowLayer(camera, layers)

    local re = bit.band(bit.lshift(1,0),bit.lshift(1,2))
    for i,layer in pairs(layers) do
        re = bit.bor(re,bit.lshift(1,layer))
    end
    camera.cullingMask = bit.bor(camera.cullingMask,re)
end

--[[
    剧情播放前隐藏所有角色
]]
function PlotUtil:ObjectSetOnStart(isHideCharacter)
    if isHideCharacter == false then
        return
    end
    self:HideLayer(UnityEngine.Camera.main, {Define.Layer.LayerEffect})
    CharacterManager.SetCharactersActive(false)
    EctypeManager.SetAirWallActive(false)
  --  CharacterManager.Notify(nil, {   
  --                          m_Name = "PlotCutsceneStart", 
  --                          m_Info = { m_Id = self.m_Cutscene.m_CsvConfig.id, m_Index = self.m_Cutscene.m_CsvConfig.index },
  --                      })
end
--[[
    剧情播放完成后显示相关角色
]]
function PlotUtil:ObjectSetOnEnd(isHideCharacter)
    if isHideCharacter == false then
        return
    end
    self:ShowLayer(UnityEngine.Camera.main, {Define.Layer.LayerEffect})
    CharacterManager.SetCharactersActive(true)
    EctypeManager.SetAirWallActive(true)
  --  CharacterManager.Notify(nil, {
  --                          m_Name = "PlotCutsceneEnd", 
  --                          m_Info = { m_Id = self.m_Cutscene.m_CsvConfig.id, m_Index = self.m_Cutscene.m_CsvConfig.index },
  --                      })
end
--=================================================================================================================
function PlotUtil:OnLoad()
    GameEvent.evt_notify:trigger("plotcutscene_load", { m_Id = self.m_Cutscene.m_CsvConfig.id, m_Index = self.m_Cutscene.m_CsvConfig.index })
end

--=================================================================================================================
--[[
    开始播放剧情之前的准备
]]
function PlotUtil:OnStart()
    
    GameEvent.evt_notify:trigger("plotcutscene_start", { m_Id = self.m_Cutscene.m_CsvConfig.id, m_Index = self.m_Cutscene.m_CsvConfig.index })
    self:ObjectSetOnStart(self.m_Config.hideCharacter)
    GraphicSettingMgr.UseTmpQuality(GrahpicQuality.Extreme)
end
--[[
    剧情播放完成后的善后
]]
function PlotUtil:OnEnd()
	print(" PlotUtil:OnEnd()")
    self:ObjectSetOnEnd(self.m_Config.hideCharacter)
    GameEvent.evt_notify:trigger("plotcutscene_end", { m_Id = self.m_Cutscene.m_CsvConfig.id, m_Index = self.m_Cutscene.m_CsvConfig.index })
    local re = map.msg.CPlayCGOver({})
    NetWork.send(re)
    GraphicSettingMgr.ResumeQuality()
end

return PlotUtil