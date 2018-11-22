local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local EctypeManager = require "ectype.ectypemanager"
local AudioManager = require"audiomanager"
local ConfigManager = require"cfg.configmanager"
local gameObject
local name
local PlayerRole = require "character.playerrole"
local playerRole
local fields
local DlgInfo
local uiEctype
local DialogFrame
local frameid
local DialogName
local DialogContent
local DialogIcon
local DialogStop

local audioSource = nil

local function destroy()
  if DialogStop then
      uiEctype.ContinueNav()
  end
end

local function Clear()
    -- for i,v in pairs(DialogFrame) do
    --     printyellow(v.frame,fields)
        -- fields[UISprite_Background].gameObject:SetActive(false)
    -- end
end

local function show(params)
    -- DialogFrame = ConfigManager.getConfig("dialogframe")
    Clear()
    frameid = params.frameid
    DialogName = params.name
    DialogContent = params.content
    DialogIcon = params.icon
    DialogStop = params.stop
    if DialogStop then
        uiEctype = require"ui.ectype.dlguiectype"
        uiEctype.StopNav()
    end
    fields.UILabel_Name.text = DialogName
    fields.UILabel_Content.text = DialogContent
    if not DialogIcon or DialogIcon == "" then
        fields.UITexture_NPCHead.gameObject:SetActive(false)
    else
        fields.UITexture_NPCHead.gameObject:SetActive(true)
        fields.UITexture_NPCHead:SetIconTexture(DialogIcon)
    end
    --fields[DialogFrame[frameid].frame].gameObject:SetActive(true)

    if params.audioclipid and params.audioclipid > 0 then
        AudioManager.Play2dSound(params.audioclipid)
    end

    if params.callbackClose then
        EventHelper.SetClick(fields.UIButton_Close,function()
            local callback = params.callbackClose
            callback()
        end)
    end
end

local function hide()
    if DialogStop then
        uiEctype.ContinueNav()
    end

    if audioSource then
        audioSource:Stop()
    end
end

local function update()
end

local function refresh(params)

end
local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_Bottom)
end

local function init(params)
    name, gameObject, fields = unpack(params)
    SetAnchor(fields)
    if fields.UISprite_Background and fields.UISprite_Background.gameObject then
        audioSource = fields.UISprite_Background.gameObject:GetComponent(AudioSource)
        if not audioSource then
            audioSource = fields.UISprite_Background.gameObject:AddComponent(AudioSource)
        end
    end
end


return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
}
