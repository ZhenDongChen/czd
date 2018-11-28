local Unpack = unpack
local EventHelper = UIEventListenerHelper
local ConfigManager= require("cfg.configmanager")
local HeroChallengeManager = require("ui.activity.herochallenge.herochallengemanager")
local BonusManager = require("item.bonusmanager")
local TaskManager = require("taskmanager")
local UIManager = require("uimanager")

local m_GameObject
local m_Name
local m_Fields

local function destroy()
end

local function refresh()
end

local function show(params)
    m_Fields.UILabel_Content.text = params.content
    local npc = TaskManager.GetNpcData(params.npcId)
    local npcModelData = nil
    if npc then
        npcModelData = ConfigManager.getConfigData("model", npc.modelname) 
        m_Fields.UILabel_NPCName.text = npc.name
        m_Fields.UITexture_NPChead:SetIconTexture(npcModelData.headicon)
    end
    EventHelper.SetClick(m_Fields.UISprite_Click,function()
        UIManager.hidedialog(m_Name)
        params.callBackFunc()
    end)
end

local function hide()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)      
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    init = init,
    show = show,
    hide = hide,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
}