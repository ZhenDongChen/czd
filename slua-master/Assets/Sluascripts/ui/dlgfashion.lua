
local unpack = unpack
local print = print

local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local ConfigManager = require"cfg.configmanager"
local Player = require"character.player"
local PlayerRole = require"character.playerrole"
local mathutils = require"common.mathutils"
local CheckCmd=require("common.checkcmd")

local gameObject,name,fields

local parent
local ArmourList
local DressInfo
local FashionInfo = nil
local Model
local currentState=nil
local dressing
local states = {"UILabel_Unacquired","UILabel_Acquired","UILabel_Activited"}
local isSend = false
local lastSelect
local currentSelect
local listeners = {}
local FashionList = {}
local CurrentEquipping = nil
local cnt
local UnEquiping
local showName = "UISprite_FashionHighlight"
local isReady
local HumanoidAvatar = require"character.avatar.humanoidavatar"
local FashionData = nil
local FashionState = nil
local selectedIndex = 0
local FashionManager = require"character.fashionmanager"
local CameraManager = require"cameramanager"
local currType
local subDlg

local FashionType = {
    --["partner"] = "ui.partner.dlgpartnerfashion",
    ["role"] = "ui.playerrole.dlgrolefashion",
    ["pet"] = "ui.partner.dlgpartner_skin",
}


local function destroy()
    subDlg.destroy()
end

local function show(params)
    currType = params.fashiontype
    subDlg = require(FashionType[currType])
    subDlg.show(params)
end

local function hide()
    subDlg.hide()
end

local function update()
    subDlg.update(params)
end

local function refresh(params)
    subDlg.refresh(params)
end

local function showdialog(params)
    show(params)
end

local function uishowtype()
    return UIShowType.Refresh
end

local function second_update ()
    subDlg.second_update()
end

local function RefreshScroll()
    -- fields.UIScrollView_Fashionlist:ResetPosition()
    local wrapContent = fields.UIList_Fashion.gameObject:GetComponent("UIWrapContentList")
    wrapContent:CenterOnIndex(0)
end

local function init(params)
    name, gameObject, fields = unpack(params)
    for _,v in pairs(FashionType) do
        local t = require(v)
        t.init(name,gameObject,fields)
    end

    EventHelper.SetDrag(fields.UITexture_3DModel,function(o,delta)
        subDlg.RotateModel(delta)
    end)
end

return {
    init                = init,
    show                = show,
    hide                = hide,
    update              = update,
    destroy             = destroy,
    refresh             = refresh,
    uishowtype          = uishowtype,
    second_update       = second_update,
    RefreshScroll       = RefreshScroll,
}
