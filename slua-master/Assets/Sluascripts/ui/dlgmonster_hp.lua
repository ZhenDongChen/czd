local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local HeadInfoManager
local headInfoManagerSimple
local headInfoManagerComplete
local name
local Define = require"define"
local rootObj
local simpleList
local completeList


local function Add(character,isShow)
    if character:IsPet() or character:IsPlayer()  or character:IsNpc() then
        return headInfoManagerComplete:Add(character,isShow)
    else
        return headInfoManagerSimple:Add(character,isShow)
    end
end

local function Remove(character)
    if character:IsPet() or character:IsPlayer() or character:IsNpc() then
        return headInfoManagerComplete:Remove(character.m_Id)
    else
        return headInfoManagerSimple:Remove(character.m_Id)
    end
end


local function Logout()
    --if simpleList~= nil and completeList~= nil then
    --    simpleList:Clear()
    --    completeList:Clear()
    --end

end

local function late_update2()
    headInfoManagerSimple:Update()
    headInfoManagerComplete:Update()
end

local function update()

end

local function show()
    rootObj.transform.localScale = Vector3.one
end

local function hide()
    rootObj.transform.localScale = Vector3.zero
end


local function init(params)
    if rootObj ~= nil then
        return
    end
    Util.Load("ui/dlgmonster_hp.ui",Define.ResourceLoadType.LoadBundleFromFile,function(asset_obj)
        local gameObject
        local components
        if gameObject == nil then 
            gameObject = GameObject.Instantiate(asset_obj)
            components = gameObject:GetComponentsInChildren("UIList")
        end
        for i=1,components.Length do
            local component = components[i]
            if component.gameObject.name == "UIList_HeadInfoSimple" then
                simpleList = component
            elseif component.gameObject.name == "UIList_HeadInfoComplete" then
                completeList = component
            end
        end
        HeadInfoManager = require"character.headinfo.headinfomanager"
        headInfoManagerSimple = HeadInfoManager:new(simpleList)
        headInfoManagerComplete = HeadInfoManager:new(completeList)
        rootObj = GameObject("headinforoot")
        GameObject.DontDestroyOnLoad(rootObj)
        gameObject.transform.parent = rootObj.transform
        gameObject.transform.localScale = Vector3.one * (1/360)
        rootObj:SetLayerRecursively(0)
        local evtid_late_update2 = gameevent.evt_late_update2:add(late_update2)
    end)

    gameevent.evt_system_message:add("logout",Logout)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    late_update2 = late_update2,
    destroy = destroy,
    refresh = refresh,
    Add = Add,
    Remove = Remove,
}
