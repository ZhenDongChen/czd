local UIManager = require("uimanager")

local Anchor_Widgets = {}

local function FindAllWidget(fields)
    Anchor_Widgets["TopLeft"]       = fields.UIWidget_TopLeft
    Anchor_Widgets["TopCenter"]     = fields.UIWidget_TopCenter
    Anchor_Widgets["TopRight"]      = fields.UIWidget_TopRight

    Anchor_Widgets["Left"]          = fields.UIWidget_Left
    Anchor_Widgets["Center"]        = fields.UIWidget_Center
    Anchor_Widgets["Right"]         = fields.UIWidget_Right

    Anchor_Widgets["BottomLeft"]    = fields.UIWidget_BottomLeft
    Anchor_Widgets["BottomCenter"]  = fields.UIWidget_BottomCenter
    Anchor_Widgets["BottomRight"]   = fields.UIWidget_BottomRight
end

local function ResetWidget(fields)
    FindAllWidget(fields)
    for pivot, widget in pairs(Anchor_Widgets) do
        UIManager.SetAnchor(widget)
    end
end

return {
    ResetWidget = ResetWidget,
}