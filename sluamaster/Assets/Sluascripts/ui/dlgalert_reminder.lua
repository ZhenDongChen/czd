-- region *.lua
-- Date
-- 此文件由[BabeLua]插件自动生成



-- endregion

local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local login = require("login")

local gameObject
local name

local fields
local DlgInfo
local m_NeedCountDown=false
local m_Time=0

local function destroy()
    -- print(name, "destroy")
end

local function DisplayCountDown()
    m_Time=DlgInfo.time
    m_NeedCountDown=true
end

local function show(params)
    DlgInfo = params and params or { title = LocalString.TipText, content = "" }
	 if DlgInfo.content then
        fields.UILabel_Content.text = DlgInfo.content
    end
    if DlgInfo.title then
        fields.UILabel_Title.text = DlgInfo.title
    end
	
    EventHelper.SetClick(fields.UIButton_Sure, function()
        uimanager.hide(name)
        if DlgInfo.callBackFunc then
            DlgInfo.callBackFunc(params)
        end
    end )
    
    EventHelper.SetClick(fields.UIButton_Return,function()          
        uimanager.hide(name)
        if DlgInfo.callBackFunc1 then
            DlgInfo.callBackFunc1(params)
        end
    end)
	--[[
   
  
    if DlgInfo.sureText then
        fields.UILabel_Sure.text=DlgInfo.sureText
    else
        fields.UILabel_Sure.text=LocalString.SureText
    end
    if DlgInfo.cancelText then
        fields.UILabel_Return.text=DlgInfo.cancelText
    else
        fields.UILabel_Return.text=LocalString.CancelText
    end    
    if DlgInfo.time then
        DisplayCountDown()
    else
        m_NeedCountDown=false
    end
    if DlgInfo.showCloseButton==true then
        fields.UIButton_Close.gameObject:SetActive(true)
        EventHelper.SetClick(fields.UIButton_Close,function()
            uimanager.hide(name)
        end)
    else
        fields.UIButton_Close.gameObject:SetActive(false)
    end
    -- print(name, "show")
	
	]]
end

local function hide()
    -- print(name, "hide")
end

local function update()
    if m_NeedCountDown then
        m_Time=m_Time-Time.deltaTime
        if m_Time<=0 then
            m_NeedCountDown=false
            uimanager.hide(name) 
            DlgInfo.callBackFunc()
            return
        end
        local text=""
        if DlgInfo.sureText then
            text=(DlgInfo.sureText).."("..(math.ceil(m_Time))..")"
        else
            text=(LocalString.SureText).."("..(math.ceil(m_Time))..")"
        end
        fields.UILabel_Sure.text=text        
    end
    -- print(name, "update")
end

local function refresh(params)
    gameObject.transform.position = Vector3.forward * -500
    --  fields.UIButton_Sure.Label_Sure.text = "OK"
    --  fields.UIButton_Return.Label_Return.text = "Return"
    -- fields.UILabel_Content.text = params
end


local function init(params)
    name, gameObject, fields = unpack(params)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
