local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")

local gameObject
local name

local fields
local isLoad
local progressValue

local startTime = 0.0
local totalTime = 2.0
local callback = nil

local function destroy()
  print(name, "destroy")
end

local function show(params)
    print(name, "show")
    if params.dur > 0 then
       totalTime = params.dur
       callback = params.cb
    end
    if params.text then
        fields.UILabel_State.text = params.text
    end
end

local function hide()
  print(name, "hide")
end

local function refresh(params)
  print(name, "refresh")
end

local function update()
  --print(name, "update")
  if isLoad then
    if Time.time - startTime >= totalTime then
         progressValue = 1.0
         isLoad = false
    else
         progressValue = (Time.time - startTime) / totalTime
    end

    local UIProgressBar_BackGround=fields.UIProgressBar_BackGround
    UIProgressBar_BackGround.value=progressValue
  else
    --printyellow(tostring(totalTime),tostring(callback))
    if callback and totalTime>= 1.0  then
        callback()
    end
    progressValue = 0.0
    uimanager.destroy("dlgprogressbar")
  end
end

local function init(params)
  name, gameObject, fields = unpack(params)
  isLoad=true
  startTime = Time.time
  progressValue = 0.0
  local UIProgressBar_BackGround = fields.UIProgressBar_BackGround
  UIProgressBar_BackGround.value = progressValue
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
}
