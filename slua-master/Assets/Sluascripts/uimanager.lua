local pairs             = pairs
local format            = string.format
local printt            = printt
local logError          = logError
local Vector3           = Vector3
local print             = print
local GameObject        = GameObject
local require           = require
local gameevent         = require "gameevent"
local utils             = require "common.utils"
local event             = require "common.event"
local viewutil          = require "common.viewutil"
local ConfigManager     = require("cfg.configmanager")
local evt               = event:new("uimanager")

local Camera            = UnityEngine.Camera.main
local define = require "define"
local ResourceLoadType = define.ResourceLoadType

local LOAD_ING          = 1
local LOAD_SUCC         = 2
local views             = {} -- viewname -> { status = ? , isshow = ?, depth = ?, hide_time = ? }
local ui_root
local charactermanager  = nil
local CharacterType     = nil
local NpcStatusType     = nil
local MAX_HIDE_VIEW_NUM = 0

local DialogStack
local DialogConfigs     = nil
local needrefresh               --是否需要刷新
local destroy                   --页面资源销毁
local onshow                    --页面显示回调
local onhide                    --页面隐藏回调
local showloading               --显示加载中提示
local hideloading               --隐藏加载中提示
local showloadedview            --显示已经加载的页面 用于弹出堆栈 或者tab页切换
local hideloadedview            --隐藏已经加载的页面 用于弹出堆栈 或者tab页切换
local CallBack_DestroyAllDlgs
local playingParticleSystems
local isLocked = false
local batterylevel = 0

local dlgShowMode = nil

UIShowType =
{
    Default = 0,                     --默认策略显示
    ShowImmediate = 1,                  --直接调用show 不会回调showdialog 和showtab,当确认页面数据已经准备好时 可以以此策略显示页面，这样不会重复发送协议
    Refresh = bit.lshift (1,1) ,    --强制调用show 默认切换tab页 或者 弹出堆栈显示页面时不会 回调show 如果以此策略显示则会回调show
    DestroyWhenHide = bit.lshift (1,2) ,  --Hide时释放资源


    RefreshAndShowImmediate = 3,         -- bit.bor(UIShowType.ShowImmediate,UIShowType.Refresh)

}


--[[
    filename
    isshow
    status
    loaded
    gameobject
    isdialog
    tabs
    initedtabs -- tab_name,true
    tabindex
    tabgroupstates -- tabindex,map{tab_name,ishow}
--]]

local function get_view_data(view_name)
    local data = views[view_name]
    if not data then
        data = {}
        local foldername,filename = string.match(view_name,"^(.*)%.(.*)$")
        data.filename = mathutils.TernaryOperation(filename,filename,view_name)
        views[view_name] = data
    end
    return data
end

local function get_module_name(view_name)
    return "ui." .. view_name
end

local function get_view_module(view_name)
    local view = require(get_module_name(view_name))
    if not view then
        logError("view:%s script file not find!", view_name)
    end
    return view
end

local function hasscript(view_name)
    return LuaHelper.ScriptExists(string.format("ui.%s",view_name))
end

local function hasmethod(view_name, method_name)
    local view = get_view_module(view_name)
    if not view then
        return false
    end
    local method = view[method_name]
    if not method then
        return false
    end
    return true
end


local function isshow(view_name)
    local data = views[view_name]
    if data and data.isshow then
        return data.isshow
    end
    return false
end

local function hasloaded(view_name)
--    local viewObj=LuaHelper.FindGameObject("/UI Root (2D)/UI_Root/"..(view_name))
--    return viewObj~=nil
    local view_data = get_view_data(view_name)
    return view_data.status == LOAD_SUCC
end

local function call(view_name, method_name, params)
    local view = get_view_module(view_name)
    if not view then return end
    local method = view[method_name]
    if not method then
        printyellow(format(">>>>>>>>>>>>>>>>>>>>>>view. %s.%s not find.", view_name, method_name))
        return
    end
    local view_data = get_view_data(view_name)
    if view_data.status ~= LOAD_SUCC and method_name ~= "show" and method_name ~= "showdialog" and method_name ~= "tabs" and method_name ~= "showtabbyindex"and method_name ~= "showtab" then
        logError(">>>>>>>>>>>>>>>>>>>>>>uimanager. view:%s not loaded! can't call method:%s", view_name, method_name)
        return
    end
    local succ = utils.xpcall(method, params)
    if succ then
        --evt:trigger(method_name, view_name)
        --evt:trigger("*", {method_name, view_name})
        return true
    else
        logError(">>>>>>>>>>>>>>>>>>>>>>view.call  %s.%s fail.", view_name, method_name)
        return
    end
end

local function callwithreturn(view_name, method_name, params)
    local view = get_view_module(view_name)
    if not view then return nil end
    local method = view[method_name]
    if not method then
        print(format("view. %s.%s not find.param1:%s param2:%s", view_name, method_name,(params and  params[1]) or "",(params and params[2]) or ""))
        return nil
    end
    local ret = method(params)
    return  method(params)
end

local LAYER_UI = 20
local function init_view_obj(view_obj, filename)
    local trans = view_obj.transform
    trans.parent = ui_root.transform
	if filename == "DlgAlert_tempDialog" then
		trans.localPosition =Vector3(0,0,-3000)
	else
		trans.localPosition = Vector3.zero
	end
    
    trans.localScale = Vector3.one
	
    view_obj.name = filename
    view_obj.layer = LAYER_UI
    view_obj:SetActive(false)
end

local UI_LOAD_TYPE = ResourceLoadType.LoadBundleFromFile -- www方式加载
local function loader(path, callback)
    Util.Load(path, UI_LOAD_TYPE, callback)
end

local function getuishowtype(view_name)
    local uishowtype = UIShowType.Default
    if(hasmethod(view_name,"uishowtype")) then
        uishowtype = callwithreturn(view_name, "uishowtype")
    end
    return uishowtype
end

--view_name的页面是否包含uishowtype
local function isuishowtype(view_name,uishowtype)
    local viewuishowtype = getuishowtype(view_name)
    return bit.band(uishowtype,viewuishowtype)>0
end

local function getdialog(view_name)
    if DialogConfigs == nil then
        print("getdialog error! Dialog csv not loaded!",view_name,tabindex)
        return nil
    end
    return DialogConfigs[view_name]
end

local function gettabgroup(view_name,tabindex)
    local dialog = getdialog(view_name)

    if dialog == nil then
        print("gettabgroup error! no tabgroup!",view_name,tabindex)
        return nil
    end
    return dialog.tabgroups[tabindex]
end

local function getalltabs(view_name)

    local alltab_names = {}
    local dialog = getdialog(view_name)
    for _,tabgroup in pairs(dialog.tabgroups) do
        for _,tab in ipairs(tabgroup.tabs) do
            table.concat(alltab_names,tab.tabname)
        end
    end
    return alltab_names

end

local function refresh(view_name, params)
    if Local.LogModuals.UIManager then
        printyellow("refresh",view_name)
    end
	--printyellow("uimanager refresh view_name",view_name)
    if needrefresh(view_name) then
        local data = get_view_data(view_name)
		--printyellow("data = get_view_data(view_name)")
        data.needrefresh = true
        data.refreshparams = params
    end
end



local function show(view_name, params)
    if Local.LogModuals.UIManager then
        printyellow("show",view_name)
        printt(params)
    end
    local data = get_view_data(view_name)
    if data.isshow then
        return
    end
    if data.status ~= LOAD_SUCC then
        if not data.loaded then
            print(format("view:", view_name, "not loaded!"))
            data.loaded = LOAD_ING
            showloading()
            loader(format("ui/%s.ui", data.filename), function (asset_obj)
                if IsNull(asset_obj) then
                    return
                end
                local view_obj = GameObject.Instantiate(asset_obj)
                GameObject.DontDestroyOnLoad(view_obj)
                if not view_obj then
                    data.loaded = nil
                    logError(format("view %s prefab load fail!", view_name))
                    --evt:trigger("load_end", {false, view_name})
                    return
                end
                data.status = LOAD_SUCC
                data.gameobject = view_obj
                data.uifadein = LuaHelper.GetComponent(data.gameobject,"UIFadeIn")
                data.uifadeout = LuaHelper.GetComponent(data.gameobject,"UIFadeOut")
				data.fields = viewutil.export_fields(view_obj)
                init_view_obj(view_obj, data.filename)
                view_obj:SetActive(true)

				
                if call(view_name, "init", {view_name, view_obj, data.fields,params})
                    and call(view_name, "show", params) then
                    data.isshow = true
                    onshow(view_name, params)
                else
                    view_obj:SetActive(false)
                end
            end)

            --evt:trigger("load_start", view_name)
        end
        return
    end
    data.gameobject:SetActive(true)
    if call(view_name, "show", params) then
        data.isshow = true
        onshow(view_name, params)
    else
        data.gameobject:SetActive(false)
    end

end

local function showorrefresh(view_name, params)
    if isshow(view_name) then
        refresh(view_name,params)
    else
        show(view_name,params)
    end
end

local function ifshowthencall(view_name, method_name, params)
    if isshow(view_name) then
        call(view_name, method_name, params)
    end
end



local function hide(view_name)
    if Local.LogModuals.UIManager then
        printyellow("hide",view_name)
    end
    local data = get_view_data(view_name)
    data.hide_time = Time.time
    if not data.isshow then
        print(format("view:%s not show!", view_name))
        return
    end
    if data.uifadeout ~=nil then
        local dlghiding = require "ui.dlghiding"
        UIEventListenerHelper.SetPlayTweenFinish(data.uifadeout, function(uifadeout)
            dlghiding.OnFadeOutEnd()
            onhide(view_name)
        end)
        data.uifadeout:Play(true)
        dlghiding.OnFadeOutBegin()
    else
        onhide(view_name)
    end
    local NoviceGuideTrigger=require"noviceguide.noviceguide_trigger"
    NoviceGuideTrigger.HideDialog(view_name)
end


local function hideimmediate(view_name)
    if Local.LogModuals.UIManager then
        printyellow("hideimmdiate",view_name)
    end
    local data = get_view_data(view_name)
    data.hide_time = Time.time
    if not data.isshow then
        print(format("view:%s not show!", view_name))
        return
    end
    onhide(view_name)
end


local function showmaincitydlgs()
    if Local.LogModuals.UIManager then
        printyellow("showmaincitydlgs")
    end
    for _,dlg in pairs(Local.MaincityDlgList) do
        if not isshow(dlg) then
            show(dlg)
        end
    end
end

local function hidemaincitydlgs()
    if Local.LogModuals.UIManager then
        printyellow("hidemaincitydlgs")
    end
    for _,dlg in pairs(Local.MaincityDlgList) do
        if isshow(dlg) then
            hide(dlg)
        end
    end
end

local function _showtab(view_name,tab_name, params)
    if Local.LogModuals.UIManager then
        printyellow("_showtab",view_name,tab_name)
    end
    local data = get_view_data(view_name)
    local tab_data = get_view_data(tab_name)
    if tab_data.isshow then
        return
    end


    if data.initedtabs[tab_name] then
        tab_data.params = params
        showloadedview(tab_name, params)
    else
        --showloading()
        if(hasmethod(tab_name,"showtab")) and not isuishowtype(tab_name,UIShowType.ShowImmediate) then
            call(tab_name, "showtab", params)
        else
            show(tab_name, params)
        end

        data.initedtabs[tab_name]  = true
		tab_data.dialog_view_name = view_name
    end
end

local function _hidetab(view_name,tab_name)
    if Local.LogModuals.UIManager then
        printyellow("_hidetab",view_name,tab_name)
    end
    local data = get_view_data(view_name)
    if Local.LogModuals.UIManager then
        printt(data.tabgroupstates)
    end
    local tab_data = get_view_data(tab_name)
    if not tab_data.isshow then
        return
    end
    if Local.LogModuals.UIManager then
        printyellow("tab_name:",tab_name,"inited:",data.initedtabs[tab_name])
    end
    if data.initedtabs[tab_name] then
        hideloadedview(tab_name)
    end

end



local function showtab(tab_name, params)
    if not DialogStack:IsEmpty() then
        local view_name = DialogStack:Top()
		
        if Local.LogModuals.UIManager then
            printyellow("showtab",view_name,tab_name)
            printt(params)
        end
		
        local data = get_view_data(view_name)
        data.tabgroupstates[data.tabindex][tab_name] = true
        _showtab(view_name,tab_name, params)
    end
end

local function hidetab(tab_name)
    if not DialogStack:IsEmpty() then
        local view_name = DialogStack:Top()
        if Local.LogModuals.UIManager then
            printyellow("hidetab",view_name,tab_name)
        end
        local data = get_view_data(view_name)
        if Local.LogModuals.UIManager then
            printt(data.tabgroupstates)
        end
        data.tabgroupstates[data.tabindex][tab_name] = false
        _hidetab(view_name,tab_name)
    end

end

local function showtabbyindex(view_name, tabindex, params)
    if Local.LogModuals.UIManager then
        printyellow("showtabbyindex",view_name, tabindex)
    end
    local data = get_view_data(view_name)
    local tabgroup =  gettabgroup(view_name, tabindex)
    if tabgroup then
        data.tabindex = tabindex
        if data.tabgroupstates[data.tabindex] == nil then
            data.tabgroupstates[data.tabindex] = {}
            for _,tab in ipairs(tabgroup.tabs) do
                data.tabgroupstates[data.tabindex][tab.tabname] = not tab.hide
            end
        end
        if Local.LogModuals.UIManager then
            printt(data.tabgroupstates)
        end
        for tabname,isshow in pairs(data.tabgroupstates[data.tabindex]) do
            if isshow then
                _showtab(view_name,tabname,params)
            end
        end
    end
end

local function hidetabbyindex(view_name, tabindex)
    if Local.LogModuals.UIManager then
        printyellow("hidetabbyindex",view_name, tabindex)
    end
    local tabgroup =  gettabgroup(view_name, tabindex)
    if tabgroup then
        for _,tab in ipairs(tabgroup.tabs) do
            _hidetab(view_name,tab.tabname)
        end
    end
    local NoviceGuideTrigger=require"noviceguide.noviceguide_trigger"
    NoviceGuideTrigger.HideDialog(view_name)
end

local function changetabbyindex(view_name, tabindex,params)
    if Local.LogModuals.UIManager then
        printyellow("changetabbyindex",view_name,tabindex)
        printt(params)
    end
    local data = get_view_data(view_name)
    if data.tabindex~= tabindex then
        local tabgroup =  gettabgroup(view_name, tabindex)
        if tabgroup then
            hidetabbyindex(view_name, data.tabindex)
            showtabbyindex(view_name, tabindex ,params)
        end
    end

end

local function gettabindex(view_name)
    local data = get_view_data(view_name)
    return data.tabindex
end



local function beforeshowdialog()
	
    if isshow("dlgstorycopy_talk")then
        hide("dlgstorycopy_talk")
    end
	
    if isshow("dlgjoystick") then
        Game.JoyStickManager.singleton:Reset()
    end
end

local function refreshdlgdialog(dialog_view_name,tabindex)
	local dialog_data = get_view_data("dlgdialog")
	if dialog_data ~=nil and dialog_data.uifadeout ~=nil then
        dialog_data.uifadeout:Stop()
    end
	showorrefresh("dlgdialog",{view_name = dialog_view_name,tab_index = tabindex})
end


local function showdialog(view_name, params,tabindex)
    if Local.LogModuals.UIManager then
        printyellow("showdialog",view_name)
        printt(params)
    end
    -- 在showdialog之前隐藏其它窗口
    beforeshowdialog()

    if tabindex == nil then tabindex = 1 end
    local data = get_view_data(view_name)
    data.isdialog = true
    data.initedtabs = {} -- tab_name,true
    data.tabgroupstates = {}
	data.dialog_view_name = view_name

    if not DialogStack:IsEmpty() then
        local lastview_name = DialogStack:Top()
        if lastview_name == view_name then
            return
        end
        hideloadedview(lastview_name)
    else
        hidemaincitydlgs()
    end

    DialogStack:Push(view_name)
    if Local.LogModuals.UIManager then
        DialogStack:Print()
    end

    if hasscript(view_name) then
        showloading()
        if(hasmethod(view_name,"showdialog")) and not isuishowtype(view_name,UIShowType.ShowImmediate)  then
            call(view_name, "showdialog", params)
        else
            show(view_name, params)
        end
    else
        onshow(view_name,params)
    end

    showtabbyindex(view_name, tabindex ,params)
    refreshdlgdialog(view_name,data.tabindex)

end



local function hidedialog(view_name, is_immediate)
    if Local.LogModuals.UIManager then
        printyellow("hidedialog",view_name)
    end
    if DialogStack:IsEmpty() then
        return
    else
        local currentview_name = DialogStack:Top()
        if currentview_name ~= view_name then
            return
        end
    end
    local data = get_view_data(view_name)
    local tabgroup =  gettabgroup(view_name, data.tabindex)
    if tabgroup then
        hidetabbyindex(view_name, data.tabindex)
    end
    if hasscript(view_name) then
        if(hasmethod(view_name,"hidedialog")) then
            call(view_name, "hidedialog")
        else
            hide(view_name)
        end
    end



    DialogStack:Pop()

    if not DialogStack:IsEmpty() then
        local lastview_name = DialogStack:Top()
        showloadedview(lastview_name)
    else
        showmaincitydlgs()
        if is_immediate and true == is_immediate then
            --printyellow(string.format("[uimanager:hidedialog] hideimmediate dlgdialog.", view_name))
            hideimmediate("dlgdialog")
        else
            --printyellow(string.format("[uimanager:hidedialog] hide dlgdialog.", view_name))
            hide("dlgdialog")
        end
    end
    if Local.LogModuals.UIManager then
        DialogStack:Print()
    end
    local NoviceGuideTrigger=require"noviceguide.noviceguide_trigger"
    NoviceGuideTrigger.HideDialog(view_name)
end

local function hidecurrentdialog()
    if DialogStack:IsEmpty() then
        return
    else
        local currentview_name = DialogStack:Top()
        hidedialog(currentview_name)
        if currentview_name == "family.dlgfamily" then
            local familymgr = require("family.familymanager")
            familymgr.CheckAllFamilyDlgHide()
        end
		gameevent.evt_resetnewstatus:trigger({ name = currentview_name })
    end
end

local function currentdialogname()
    if DialogStack:IsEmpty() then
        return nil
    else
        return DialogStack:Top()
    end
end



local function closealldialog()

    if not DialogStack:IsEmpty() then
        local lastview_name = DialogStack:Top()
        if(hasmethod(lastview_name,"hidedialog")) then
            call(lastview_name, "hidedialog")
        else
            hide(lastview_name)
        end
        DialogStack:Clear()
        showmaincitydlgs()
        hide("dlgdialog")
    end
end


onshow = function (view_name, params)
    if Local.LogModuals.UIManager then
        printyellow("onshow",view_name)
    end
    local data = get_view_data(view_name)
    data.params = params
    if view_name ~= "dlgopenloading" then hideloading() end
	if data.dialog_view_name ~=nil and data.dialog_view_name ~=currentdialogname() then
		printyellow("==============>dialog has been hide","dialog name:",data.dialog_view_name,"current dialog name:",currentdialogname())
		hideloadedview(view_name)
	elseif hasscript(view_name) then
        refresh(view_name, params)
        if data.uifadein ~=nil then
            data.uifadein:Play(true)
			--printyellow("fadein",data.uifadein)
        end
    end

end

onhide = function (view_name)
    if Local.LogModuals.UIManager then
        printyellow("onhide",view_name)
    end
    local data = get_view_data(view_name)
    if call(view_name, "hide") then
        data.isshow = false
		if view_name == "tabequip" then
			printyellow("tabequip    onhide")
		end
        data.gameobject:SetActive(false)
		data.dialog_view_name = nil
        if isuishowtype(view_name,UIShowType.DestroyWhenHide) then
            destroy(view_name, "destroy")
        end
    end
end

--显示已经加载的页面 用于弹出堆栈 或者tab页切换
showloadedview =  function (view_name)
    if Local.LogModuals.UIManager then
        printyellow("showloadedview",view_name)
    end
    local data = get_view_data(view_name)
    local params = data.params
	local temp = hasscript(view_name)
	printyellow("view_name:",view_name)
    if not data.isshow and hasscript(view_name) then
        if isuishowtype(view_name,UIShowType.Refresh) then
            if(hasmethod(view_name,"showtab")) and not isuishowtype(view_name,UIShowType.ShowImmediate)  then
                call(view_name, "showtab", params)
            else
                show(view_name, params)
            end
        else
            data.gameobject:SetActive(true)
            data.isshow = true
        end
    end

    if data.isdialog then
		refreshdlgdialog(view_name,data.tabindex)
		data.dialog_view_name = view_name
        local tabgroup =  gettabgroup(view_name, data.tabindex)
        if tabgroup then
            for tabname,isshow in pairs(data.tabgroupstates[data.tabindex]) do
                if isshow then
                    local tab_data = get_view_data(tabname)
					tab_data.dialog_view_name = view_name
                    showloadedview(tabname,tab_data.params)
                end
            end
        end
    end
end


--隐藏已经加载的页面 用于弹出堆栈 或者tab页切换
hideloadedview =  function (view_name)
    if Local.LogModuals.UIManager then
        printyellow("hideloadedview",view_name)
    end
    local data = get_view_data(view_name)
    if data.isshow and hasscript(view_name) then
        if isuishowtype(view_name,UIShowType.Refresh) then
            if(hasmethod(view_name,"hidetab")) and not isuishowtype(view_name,UIShowType.ShowImmediate)  then
                call(view_name, "hidetab")
            else
                hide(view_name)
            end
        else
            data.hide_time = Time.time
            data.gameobject:SetActive(false)
            data.isshow = false
        end
    end

    if data.isdialog then
        local tabgroup =  gettabgroup(view_name, data.tabindex)
        if tabgroup then
            for tabname,isshow in pairs(data.tabgroupstates[data.tabindex]) do
                if isshow then
                    hideloadedview(tabname)
                end
            end
        end
    end
end

local loaded = package.loaded
destroy =  function (view_name)
    local data = get_view_data(view_name)
    if data.isshow then
        hideimmediate(view_name)
    end
    
	if data.fields then 
		call(view_name, "destroy")
		for k,_ in pairs(data.fields) do 
			data.fields[k] = nil
		end
		data.fields = nil
	end
    views[view_name] = nil
    loaded[get_module_name(view_name)] = nil
    GameObject.Destroy(data.gameobject)
end


local function update()	
    for view_name, info in pairs(views) do
        if info.isshow then
            if(hasmethod(view_name,"update")) then
                call(view_name, "update")
            end
        end
    end
    for i=#playingParticleSystems,1,-1 do
        local particle = playingParticleSystems[i].particle
        if not particle.isPlaying then
            local callback = playingParticleSystems[i].callback
            if callback then
                callback()
            end
            table.remove(playingParticleSystems,i)
        else
            playingParticleSystems[i].time = playingParticleSystems[i].time + Time.deltaTime
        end
    end
end

local function late_update()
    for view_name, info in pairs(views) do
        if info.isshow then
            if(hasmethod(view_name,"late_update")) then
                call(view_name, "late_update")
            end

        end

        if info.needrefresh and needrefresh(view_name) then
            if Local.LogModuals.UIManager then
                printyellow("late_update refresh",view_name)
                printt(info.refreshparams)
            end
            info.needrefresh = false
			--printyellow("view_name",view_name)
            call(view_name, "refresh", info.refreshparams)
        end

    end

    --late_updateCharacterInfoOnUI()
end

local function late_update2()
    for view_name, info in pairs(views) do
        if info.isshow then
            if(hasmethod(view_name,"late_update2")) then
                call(view_name, "late_update2")
            end
        end
    end
    --late_updateCharacterInfoOnUI()
end

local function is_persistent(view_name)
    return Local.UIPersistentMap[view_name] ==  true
end

local function is_instack(view_name)
    if not DialogStack:IsEmpty() then
        local it = DialogStack:CreateIterator()
        while not it:IsEnd() do
            if it:Cur().value == view_name then
                return true
            else
                local data = get_view_data(it:Cur().value)
                if data.initedtabs and data.initedtabs[view_name] then
                    return true
                end
            end
            it:MoveNext()
        end
    end
    return false
end

needrefresh =  function(view_name)
--	printyellow("needrefresh function",view_name)
--	printyellow("needrefresh is show view nmae",isshow(view_name))
--	printyellow("needrefresh is instack view nmae",is_instack(view_name))
    return isshow(view_name) or is_instack(view_name)
end

local function unload_expire_view(now)
    local unshow_view_num = 0
    local to_destroy_view_name
    local min_hide_time = now
    for name, data in pairs(views) do
        if data~=nil and data.status == LOAD_SUCC and not data.isshow and not is_persistent(name) and not is_instack(name) then
            unshow_view_num = unshow_view_num + 1
            --printt(data)
            if data.hide_time~=nil  and data.hide_time  < min_hide_time then
                to_destroy_view_name = name
                min_hide_time = data.hide_time
            end
        end
    end
    if to_destroy_view_name and unshow_view_num > MAX_HIDE_VIEW_NUM then
        destroy(to_destroy_view_name)
    end
end

local function second_update(now)
    unload_expire_view(now)
    for view_name, info in pairs(views) do
        if info.isshow and hasmethod(view_name,"second_update") then
            call(view_name, "second_update", now)
        end
    end
end

local function hide_all()
    for name,data in pairs(views) do
        hide(name)
    end
end

local function NotifySceneLoginLoaded()
    hide_all()
end

local function monitorbattery(data)
	batterylevel = data
	if isshow("dlguimain") then
        call("dlguimain","RefreshBatteryLevel")
    end
end

local function OnLogout()
    hide_all()
end

local function init()
    ui_root = LuaHelper.FindGameObject("/UI Root (2D)/UI_Root")
    if ui_root and ui_root.transform.parent then
        GameObject.DontDestroyOnLoad(ui_root.transform.parent)
    end

    playingParticleSystems = {}
    local evtid_update = gameevent.evt_update:add(update)
    local evtid_late_update = gameevent.evt_late_update:add(late_update)
    local evtid_late_update2 = gameevent.evt_late_update2:add(late_update2)
    status.AddStatusListener("uimgr",gameevent.evt_update,evtid_update)
    status.AddStatusListener("uimgr",gameevent.evt_late_update,evtid_late_update)
    status.AddStatusListener("uimgr",gameevent.evt_late_update2,evtid_late_update2)
    gameevent.evt_second_update:add(second_update)
    DialogStack = Stack:new()
    DialogConfigs = ConfigManager.getConfig("dialog")
    if Local.LogModuals.UIManager then
        printyellow("UIManager init()")
        printt(DialogConfigs)
    end
	gameevent.evt_system_message:add("Battery", monitorbattery)
	gameevent.evt_system_message:add("logout", OnLogout)
end



local function GetBatteryLevel()
    if Application.platform == UnityEngine.RuntimePlatform.WindowsPlayer then
        return 100
    else
	    return batterylevel
    end
end

local function GetDlgsShow()
    local list = {}
    for name,data in pairs(views) do
        if data.isshow then
            table.insert(list,name)
        end
    end
    return list
end

local function RegistCallBack_DestroyAllDlgs(callback)
    printyellowmodule("RegistCallBack_DestroyAllDlgs",RegistCallBack_DestroyAllDlgs)
    CallBack_01Dlgs = callback
end

local function DestroyAllDlgs()
    printyellowmodule("DestroyAllDlgs",DestroyAllDlgs)
    local list=GetDlgsShow()
    local d=false
    for _,name in pairs(list) do
        d=false
        for _,persistentName in pairs(Local.UIPersistentList) do
            if  name==persistentName then
                hide(name)
                d=true
                break
            end
        end
        if not d and name~="ectype.dlguiectypeeffects" then
            destroy(name)
        end
    end
    DialogStack:Clear()
    if CallBack_DestroyAllDlgs then
        CallBack_DestroyAllDlgs()
        CallBack_DestroyAllDlgs = nil
    end
end

local function RefreshRedDot()
    if hasloaded("dlgdialog")==true then
        local view_name = DialogStack:Top()
        call("dlgdialog","RefreshRedDot",view_name)
    end
end
------------------------------------------------------------------
---下面是公用弹窗的用法
--------------------------------------------------------------------
showloading =  function (begintime,endtime)
    if isLocked == true then
        return
    end
    if Local.LogModuals.UIManager then
        printyellow("showloading")
    end
    local params = {begintime = mathutils.TernaryOperation(begintime,begintime,0.5),endtime = mathutils.TernaryOperation(endtime,endtime,3)}
    if isshow("dlgopenloading") then
        refresh("dlgopenloading",params)
    else
        show("dlgopenloading",params)
    end
end

hideloading = function ()
    if isLocked == true then
        return
    end
    if Local.LogModuals.UIManager then
        printyellow("hideloading")
    end
    hide("dlgopenloading")
end

local function ShowAlertDlg(params)
    local InfoManager=require"assistant.infomanager"
    if isLocked == true then
        return InfoManager.AddInfo(params)
    end
    return InfoManager.ShowInfo(params)
end

local function ShowSingleAlertDlg(params)
    if isLocked == true then
        return
    end
    show("dlgalert_reminder_singlebutton",params)
end

local function ShowSystemFlyText(message)
    if isLocked == true then
        return
    end
    if isshow("dlgloading") then
        return
    end
    if isshow("dlgflytext") then
        local dlgflytext=require "ui.dlgflytext"
        dlgflytext.AddSystemInfo(message)
    end
end

local function ShowSyncItem(newitem,getnumber)
    if isLocked == true then
        return
    end
    if isshow("dlgloading") then
        return
    end
    if isshow("dlgdynamicflyitem") then
        local dlgdynamicflyitem=require "ui.dlgdynamicflyitem"
        dlgdynamicflyitem.AddSyncItem(newitem,getnumber)
    end
end

local function ShowItemFlyText(message)
    if isLocked == true then
        return
    end
    if isshow("dlgloading") then
        return
    end
    if isshow("dlgflytext") then
        local dlgflytext=require "ui.dlgflytext"
        dlgflytext.AddItemInfo(message)
    end
end
local function ShowCountDownFlyText(time)
    if isLocked == true then
        return
    end
    show("common.dlgcountdown", {countDownTime = time})
    --local dlgflytext=require "ui.dlgflytext"
    --dlgflytext.ShowCountDown(time)
end
local function SetLock(lock)
    isLocked = lock
end
local function GetIsLock()
    return isLocked
end
local function SetShowMode()
   -- local showModeCfg = ConfigManager.getConfigData("")

end


-- 播放粒子系统及子节点中粒子系统
local function PlayUIParticleSystem(go,callback)
	go:SetActive(false)
	go:SetActive(true)
	local particles = go:GetComponentsInChildren(UnityEngine.ParticleSystem)
	if particles and particles.Length ~= 0 and particles[1] then
		particles[1]:Stop(true)
		particles[1]:Play(true)
		if callback then 
			table.insert(playingParticleSystems,{particle=particles[1],callback=callback,time=0})
		end
	end
end
-- 停止粒子系统及子节点中粒子系统
local function StopUIParticleSystem(go)
	local particle = go:GetComponent("ParticleSystem")
	if particle then
		particle:Stop(true)
	end
	go:SetActive(false)
end
-- 遍历子节点中粒子系统
local function IsPlaying(go)
	local particles = go:GetComponentsInChildren(UnityEngine.ParticleSystem)
	for i = 1, particles.Length do
		local particle = particles[i]
		if particle.isPlaying then
			return true
		end
	end
	return false
end
-- 遍历子节点中粒子系统
local function IsStopped(go)
	local particles = go:GetComponentsInChildren(UnityEngine.ParticleSystem)
	for i = 1,particles.Length do
		local particle = particles[i]
		if not particle.isStopped then
			return false
		end
	end
	return true
end


local function SetAnchor(widget)
    local root = UnityEngine.GameObject.Find("UI Root (2D)")
    if root then
        widget:SetAnchor(root.transform)
    end
end

local function GoToDlg(view_name, curtabindex1, curtabindex2, curtabindex3)
    local tabIndex1 = (curtabindex1 ~= cfg.Const.NULL) and curtabindex1 or nil
	local tabIndex2 = (curtabindex2 ~= cfg.Const.NULL) and curtabindex2 or nil
	local tabIndex3 = (curtabindex3 ~= cfg.Const.NULL) and curtabindex3 or nil

    local allDialogs = ConfigManager.getConfig("dialog")
    local familymgr = require "family.familymanager"
    if  string.find(view_name, "family") and not familymgr.InFamily() then
        --ShowSystemFlyText(LocalString.Open_Need_Family)
		
		ShowSingleAlertDlg({content = LocalString.Open_Need_Family})
        return
    end

    if string.find(view_name, "dlgtask") then --任务界面特殊处理
        if tabIndex1 == 1  then
            showdialog("dlgtask", {isShowFamilyInfo = false})
        elseif tabIndex1 == 2 then 
            if familymgr.InFamily() then
                showdialog("dlgtask", {isShowFamilyInfo = true})
            else
                ShowSystemFlyText(LocalString.Open_Need_Family)
            end       
        end       
        return
    end

    local bShowRetunBtn = allDialogs[view_name].showreturn
    local ModuleLockManager  = require("ui.modulelock.modulelockmanager")
    if bShowRetunBtn then 		
		-- 界面开启等级限制
		if tabIndex1 then
			local status = ModuleLockManager.GetModuleStatusByIndex(view_name,tabIndex1)
			if status == defineenum.ModuleStatus.UNLOCK then
				-- 已经开启
				showdialog(view_name,{tabindex2 = tabIndex2,tabindex3 = tabIndex3},tabIndex1) 

			elseif status==defineenum.ModuleStatus.LOCKED then
				-- 未开启，飘字						
				local configData = gettabgroup(view_name,tabIndex1)
				if configData then
					local conditionData = ConfigManager.getConfigData("moduleunlockcond",configData.conid)
					if conditionData then 
						local text = ""
						if conditionData.openlevel ~= 0 then
							text = (conditionData.openlevel)..(LocalString.WorldMap_OpenLevel)
						elseif conditionData.opentaskid ~= 0 then
							local taskData = ConfigManager.getConfigData("task",conditionData.opentaskid)
							if taskData then
								text = string.format(LocalString.CompleteTaskOpen,taskData.basic.name)
							end
						end
						ShowSystemFlyText(text)
                    else
						ShowSystemFlyText(LocalString.ItemSource_Locked)
					end
                else
                    local status = ModuleLockManager.GetModuleStatusByType(allDialogs[view_name].parenttype)
                    if status==defineenum.ModuleStatus.LOCKED then
                        ShowSystemFlyText(LocalString.ItemSource_Locked)
                    else
                        showdialog(view_name,{tabindex2 = tabIndex2,tabindex3 = tabIndex2},tabIndex1) 
					end
				end
			end
		else
			-- 界面无开启等级限制
			showdialog(view_name,{tabindex2 = tabIndex2,tabindex3 = tabIndex2},tabIndex1) 
		end
	else
        if allDialogs[view_name].parenttype == cfg.ui.FunctionList.NONE then
            show(view_name) 
        else
            local status = ModuleLockManager.GetModuleStatusByType(allDialogs[view_name].parenttype)
            if status==defineenum.ModuleStatus.LOCKED then
                ShowSystemFlyText(LocalString.ItemSource_Locked)
            else
                if string.find(view_name, "dlgdailyexp") then --特殊处理
                    showdialog("dlgdailyexp")
                else
                    -- 弹窗，目前无开启等级限制
		            show(view_name) 
                end
            end		
        end        
	end
end

local function SetUITextureFit(uiTex)
    local baseW = 1280.0
    local baseH = 720.0
    local realW = UnityEngine.Screen.width*1.0
    local realH = UnityEngine.Screen.height*1.0
    local baseRate = baseW / baseH
    local realRate = realW / realH
    local realSize = Util.GetScreenSize()
    -- print("SetUITextureFit base:"..baseRate.."==== real:"..realRate)
    if realRate < baseRate then
        -- fitWidth = true;
        uiTex.height = realSize.y
        uiTex.width = baseRate*realSize.y
    else
        -- fitHeight = true;
        uiTex.width = realSize.x
        uiTex.height = realSize.x/baseRate
    end
end

return {
    evt_view             = evt,
    init                 = init,
    destroy              = destroy,

    show                 = show,
    hide                 = hide,
    hideimmediate         = hideimmediate,
    refresh              = refresh,
    showorrefresh        = showorrefresh,
    --update             = update,
    ifshowthencall       = ifshowthencall,
    hasmethod            = hasmethod,
    call                 = call,
    isshow               = isshow,
    hasloaded            = hasloaded,
    showdialog           = showdialog,
    hidedialog           = hidedialog,
    hidecurrentdialog    = hidecurrentdialog,
    currentdialogname    = currentdialogname,


    gettabindex          = gettabindex,
    changetabbyindex     = changetabbyindex,
    showtab              = showtab,
    hidetab              = hidetab,
    needrefresh          = needrefresh,

    getdialog            = getdialog,
    gettabgroup          = gettabgroup,
    GetDlgsShow          = GetDlgsShow,
    DestroyAllDlgs       = DestroyAllDlgs,
    --------------------------------------------------------------------
    --以下是公用弹窗的用法
    --------------------------------------------------------------------
    showloading          = showloading,
    hideloading          = hideloading,
    ShowAlertDlg         = ShowAlertDlg,
	ShowSingleAlertDlg   = ShowSingleAlertDlg,
	ShowSystemFlyText    = ShowSystemFlyText,
	ShowSyncItem         = ShowSyncItem,
	ShowItemFlyText      = ShowItemFlyText,
    RegistCallBack_DestroyAllDlgs = RegistCallBack_DestroyAllDlgs,
    ShowCountDownFlyText = ShowCountDownFlyText,
	GetBatteryLevel = GetBatteryLevel,
	RefreshRedDot        = RefreshRedDot,
    GoToDlg              = GoToDlg,
    hidemaincitydlgs     = hidemaincitydlgs,
    showmaincitydlgs     = showmaincitydlgs,
    ------------------------------------------------------------------------
	-- 播放UI界面粒子效果
    PlayUIParticleSystem = PlayUIParticleSystem,
	StopUIParticleSystem = StopUIParticleSystem,
	IsPlaying			 = IsPlaying,
    ------------------------------------------------------------------------
    --锁定，禁止弹窗
    SetLock = SetLock,
    GetIsLock = GetIsLock,

    NotifySceneLoginLoaded  = NotifySceneLoginLoaded,


    SetAnchor = SetAnchor,
    SetUITextureFit = SetUITextureFit,
	closealldialog  =closealldialog,

}
