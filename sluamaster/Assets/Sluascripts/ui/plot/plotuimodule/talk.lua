local name, gameObject, fields
local UIManager = require("uimanager")
local currentText


local function ShowTalk(content)
    --printyellow("ShowTalk",content)
    
    currentText = content
    if fields and fields.UILabel_MovieContent then
        fields.UILabel_MovieContent.text = content
    end
end

local function HideTalk()
    currentText =""
    if fields and fields.UILabel_MovieContent then
        fields.UILabel_MovieContent.text = ""
    end
end


local function update()
    
end

local function refresh()
    fields.UILabel_MovieContent.text = currentText or ""
end

local function hide()
    fields.UILabel_MovieContent.text = currentText or ""
end

local function show(params)
    fields.UILabel_MovieContent.text = ""
end

local function init(nameIn, gameObjectIn, fieldsIn)
    name, gameObject, fields = nameIn, gameObjectIn, fieldsIn
end
local function SetTalk(mode, content)
    if mode == "Show" then
        --printyellow("aaaaaaaaaa",content)
        ShowTalk(content)
    elseif mode == "Hide" then
        HideTalk()
    end
end
return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    refresh = refresh,
  --  ShowTalk = ShowTalk,
  --  HideTalk = HideTalk,
    SetTalk = SetTalk,
}