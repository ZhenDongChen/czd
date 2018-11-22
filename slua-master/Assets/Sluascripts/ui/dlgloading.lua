local unpack = unpack
local print = print
local uimanager = require("uimanager")
local ConfigManager = require"cfg.configmanager"
local SceneManager = require("scenemanager")  --Game.SceneMgr
local fields,gameObject,name
local waitFrames = nil
local listTextures
local cfgMapLoading
local m_Progress=0

local function AlterTexture()
    listTextures = {}
    for texture,v in pairs(cfgMapLoading) do
        table.insert(listTextures,texture)
    end
    local idx = math.random(#listTextures)
    local texture = listTextures[idx]
    table.remove(listTextures,idx)
    fields.UITexture_Background:SetIconTexture(texture)
    local texts = cfgMapLoading[texture].texts
    if #texts > 0 then 
        idx = math.random(#texts)
        fields.UILabel_Texts.text = texts[idx] 
    end
end

local function hide()
    m_Progress=1
    fields.UISlider_Loading.value = 1
    gameObject:SetActive(false)    
    AlterTexture()
end

local function destroy()
    gameObject:SetActive(false)
end

local function show(params)
    fields.UILabel_Speed.gameObject:SetActive(false)
    fields.UILabel_Work.gameObject:SetActive(false)
    uimanager.SetUITextureFit(fields.UITexture_Background)

    fields.UISlider_Loading.value = 0
    gameObject:SetActive(true)
    m_Progress=0
end

local function update()
   local progress = SceneManager.GetLoadingProgress()
   if gameObject.activeSelf then
        if (progress and progress<1) then           
            m_Progress=m_Progress+0.02
            if m_Progress<1 then
                fields.UISlider_Loading.value = m_Progress
            else
                fields.UISlider_Loading.value = 1
            end       
        end
   end
end

local function SetLoadingProgress(progress)
    m_Progress=progress
    fields.UISlider_Loading.value = progress
end

local function refresh(params)
    waitFrames = params
end

local function init(params)
    name, gameObject, fields = unpack(params)
    gameObject:SetActive(false)
    cfgMapLoading = ConfigManager.getConfig("maploading")
    AlterTexture()
    m_Progress=0
end



return {
    init = init,
    show = show,
    update = update,
    destroy = destroy,
    refresh = refresh,
    hide = hide,
    SetLoadingProgress = SetLoadingProgress,
}
