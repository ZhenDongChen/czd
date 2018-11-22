local unpack = unpack
local EventHelper       = UIEventListenerHelper
local uimanager         = require("uimanager")
local BroadcastManager  = require"broadcastmanager"
local gameObject
local name
local fields

local currIndex
local broadcasts

local function destroy()
end

local function show(params)
    local isLogin = not params
    fields.UILabel_NoticeContent.text = ""
    broadcasts = nil
end

local function hide()
	local DlgDialog = require "ui.dlgdialog"
	if uimanager.isshow("dlgdialog") then
		DlgDialog.SetReturnButtonActive(true)
		DlgDialog.SetListTabActive(true)
	end
	uimanager.hidedialog("dlgdialog")
end

local function RefreshContents(idx)
    printyellow("refresh contents",idx)
    if not broadcasts then return end
    local broadcast = broadcasts[idx]
    if broadcast then
        fields.UILabel_NoticeContent.text   = broadcast.content
        fields.UILabel_Announcement.text    = broadcast.time
    end
end

local function ShowContents()
    printyellow("show contents")
    broadcasts = BroadcastManager.GetBroadcast()
    fields.UIList_NoticeList:ResetListCount(#broadcasts)
    printyellow()
    for i=1,#broadcasts do
        local item = fields.UIList_NoticeList:GetItemByIndex(i-1)
        item:SetText("UILabel_Notice",broadcasts[i].title)
    end
    RefreshContents(currIndex)
end


local function refresh(params)
    ShowContents()
end

local function init(params)
  name, gameObject, fields = unpack(params)
  currIndex = 1

  EventHelper.SetClick(fields.UIButton_Return,function()
      uimanager.hide(name)
      if isLogin then
        uimanager.show("dlglogin")
      end
  end)

  EventHelper.SetListClick(fields.UIList_NoticeList,function(item)
    currIndex = item.m_nIndex + 1
    RefreshContents(currIndex)
  end)

  EventHelper.SetClick(fields.UISprite_Close,function()
      uimanager.hide(name)
      if isLogin then
          uimanager.show("dlglogin")
      end
  end)
end

local function showdialog(params)
     uimanager.show("dlgnotice",params)
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
  init          = init,
  show          = show,
  hide          = hide,
  destroy       = destroy,
  refresh       = refresh,
  uishowtype    = uishowtype,
  showdialog    = showdialog,
  ShowContents  = ShowContents,
}
