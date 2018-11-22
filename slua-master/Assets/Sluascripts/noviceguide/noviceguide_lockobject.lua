local ConfigManager=require"cfg.configmanager"
local NoviceGuideManager
local NoviceGuideTrigger
local NoviceGuideFsm
local m_ClickFunc=nil

local function FindObject(objId)
    --printyellow("FindObject:",objId)
    local targetObj
    local lockobjectData = ConfigManager.getConfigData("lockobject",objId)
    --printt(lockobjectData)
    --printyellow("lockobjectData.class:",lockobjectData.class)
    if (lockobjectData) then
        local UIManager=require"uimanager"
        --printyellow("isshow:",UIManager.isshow(lockobjectData.controldlg))
        --printyellow("name:",("/UI Root (2D)/UI_Root/"..(lockobjectData.controldlg).."/"..(lockobjectData.controluiobject)))
        targetObj=LuaHelper.FindGameObject("/UI Root (2D)/UI_Root/"..(lockobjectData.controldlg).."/"..(lockobjectData.controluiobject))     
        if targetObj and (lockobjectData.class~="cfg.guide.Normal") then
            local UIList=targetObj.gameObject:GetComponent("UIList")
            if UIList then
                if (lockobjectData.class=="cfg.guide.List") then
                    if objId==201 then
                        if UIManager.isshow("dlguimain") then
                            local DlgUIMain=require"ui.dlguimain"
                            local index=DlgUIMain.GetCurTaskTabIndex()
                            if index~=0 then
                                NoviceGuideFsm.SkipGuide()
                                return
                            end
                        else
                            NoviceGuideFsm.SkipGuide()
                            return 
                        end
                    end
                    targetObj=UIList:GetItemByIndex(lockobjectData.index)
                elseif (lockobjectData.class=="cfg.guide.WidgetOfList") then
                    local tempTarget=UIList:GetItemByIndex(lockobjectData.index)
                    if tempTarget then
                        targetObj=tempTarget.gameObject.transform:Find(lockobjectData.widgetname) 
                    else
                        targetObj=nil
                    end
                elseif (lockobjectData.class=="cfg.guide.ItemOfList") then
                    local itemId=0
                    if  lockobjectData.itemid then
                        if #(lockobjectData.itemid)==1 then
                            itemId=lockobjectData.itemid[1]
                        else
                            local PlayerRole=require"character.playerrole"
                            itemId=lockobjectData.itemid[PlayerRole:Instance().m_Profession]
                        end 
                    end  
                    if itemId then     
                        --背包界面需要滑动到指定位置                            
                        if (lockobjectData.controldlg=="tabbag") and (lockobjectData.controluiobject=="Tween/UIGroup_Bag/Group_BagBG/UIScrollView_Bag/UIList_Bag") then
                            local ItemManager=require"item.itemmanager"                           
                            local BagManager=require"character.bagmanager"
                            local items=BagManager.GetItemById(itemId)
                            if items and #items>0 then
                                local item=items[1]
                                if item then
                                    local pos=item:GetBagPos()
                                    if pos then
                                        local type=item:GetBaseType()
                                        local ItemEnum=require"item.itemenum"
                                        local baseType
                                        if type==ItemEnum.ItemBaseType.Item then
                                            baseType=cfg.bag.BagType.ITEM
                                        elseif type==ItemEnum.ItemBaseType.Equipment then
                                            baseType=cfg.bag.BagType.EQUIP
                                        elseif type==ItemEnum.ItemBaseType.Fragment then
                                            baseType=cfg.bag.BagType.FRAGMENT
                                        elseif type==ItemEnum.ItemBaseType.Talisman then
                                            baseType=cfg.bag.BagType.TALISMAN
                                        end
                                        local totalSize=BagManager.GetTotalSize(baseType)
                                        local value=0
                                        local index=(pos-7)
                                        if (index>0) then
                                            value=math.floor(index/4)*120
                                        end
                                        if UIManager.isshow("playerrole.bag.tabbag") then
                                            if (value>0) then
                                                local tabBag=require"ui.playerrole.bag.tabbag"
                                                tabBag.RefreshBagItemPos(value,true)                                                
                                            end
                                        end
                                        targetObj=UIList:GetItemById(itemId)                                       
                                    end
                                end
                            end
                        elseif (lockobjectData.controldlg=="dlgpartner_attained") and (lockobjectData.controluiobject=="Tween_Choose/UISprite_Background/UIScrollView_Partner/UIList_Partner01") then
                            --伙伴界面
                            local item=UIList:GetItemById(itemId)
                            if item then
                                targetObj=item
                                if UIList.Count and UIList.Count~=0 then
                                    local value=0
                                    local index=(item.Index-5)
                                    if (index>0) then
                                        value=math.ceil(index/2)*144
                                    end
                                    if (value>=0) then
                                        local DlgPartner_Attained=require"ui.partner.dlgpartner_attained"
                                        DlgPartner_Attained.RefreshScrollPos(value)
                                    end
                                end
                            end
                        elseif (lockobjectData.controldlg=="dlgpartner_assist") and (lockobjectData.controluiobject=="Tween_Assist/UIGroup_HelpBattle/UISprite_Background/UISprite_PartnerBackground/UIScrollView_Partner/UIList_Partner") then
                            local item=UIList:GetItemById(itemId)
                            if item then
                                targetObj=item
                                if UIList.Count and UIList.Count~=0 then
                                    local value=0
                                    local index=(item.Index-3)
                                    if (index>0) then
                                        value=math.ceil(index/2)*144
                                    end
                                    if value>=0 then
                                        local DlgPartner_Assist=require"ui.partner.dlgpartner_assist"
                                        DlgPartner_Assist.RefreshScrollPos(value)
                                    end
                                end
                            end                          
                        else
                           targetObj=UIList:GetItemById(itemId) 
                        end
                    end
                end
            end
        end
    end
    if targetObj and targetObj.gameObject.activeSelf==true then
        return targetObj
    end
end

local function FindTargetObj(objectId)
    --printyellow("FindTargetObj:",objectId)
    local lockedObj=nil
    local lockObjectData = ConfigManager.getConfigData("lockobject",objectId)
    local uiObjectTarget=FindObject(objectId) 
    --printyellow("uiObjectTarget:",uiObjectTarget) 
    if uiObjectTarget then     
        lockedObj={}
        lockedObj.targetUIObject=uiObjectTarget
        lockedObj.lockedObjectData=lockObjectData
    end
    return lockedObj
end

local function FindLockedObject(controlObjId)
    --printyellow("FindLockedObject")
    local found = false
    if controlObjId then
        local lockObj=FindTargetObj(controlObjId)
        if lockObj then
            NoviceGuideManager.SetLockedObj(lockObj)      
            found = true
        end
    end
    return found
end

local function LockUIObj()
    local lockedObj=NoviceGuideManager.GetLockedObj()  
    lockedObj.parent = lockedObj.targetUIObject.gameObject.transform.parent
    --lockedObj.targetPosOld = lockedObj.targetUIObject.gameObject.transform.position
    local uiEffectData=NoviceGuideManager.GetEffectByType("cfg.guide.LockUI")
    local colliderId=uiEffectData.controlboxcollider
    local collider = FindObject(colliderId)
    if (collider) then
        local bc = collider:GetComponent("BoxCollider")
        if bc then
            bc.enabled=true
            lockedObj.collider = bc        
            m_ClickFunc = UIEventListenerHelper.AddClick(bc,function(o)
                if not IsNull(o) then
                    NoviceGuideTrigger.ClickUIObject(o.transform)
                end
            end)
        end
    end
end

local function FreeUIObj()
    local lo=NoviceGuideManager:GetLockedObj()
    if (lo and (not IsNull(lo.targetUIObject)) and (not IsNull(lo.targetUIObject.gameObject))) and (not IsNull(lo.targetUIObject.gameObject.transform)) then
--        if m_ClickFunc then
--            printyellow("m_ClickFunc:",m_ClickFunc)
--            UIEventListenerHelper.DelClick(bc,m_ClickFunc)
--            m_ClickFunc=nil
--            printyellow("m_ClickFunc2:",m_ClickFunc)
--        end
        if (lo.lockedObjectData) and (lo.lockedObjectData.addcomponent==true) then
            local panel=lo.targetUIObject.gameObject.transform:GetComponent("UIPanel")
            if not IsNull(panel) then
                GameObject.Destroy(panel)
            end
        else       
            if (lo.targetUIObject.gameObject.transform.parent ~= lo.parent) then
                local tempParent = lo.targetUIObject.gameObject.transform.parent
                lo.targetUIObject.gameObject.transform.parent = lo.parent
                if (not IsNull(tempParent)) and (not IsNull(tempParent.gameObject)) then
                    GameObject.Destroy(tempParent.gameObject)
                end
            end
--            local pos = lo.targetUIObject.gameObject.transform.position
--            if pos then
--                if lo.targetPosOld and lo.targetPosOld.z then
--                    lo.targetUIObject.gameObject.transform.position = Vector3(pos.x, pos.y, lo.targetPosOld.z)
--                else
--                    lo.targetUIObject.gameObject.transform.position = Vector3(pos.x, pos.y, pos.z)
--                end
--            end               
        end
        if not IsNull(lo.tempCollider) then
            GameObject.Destroy(lo.tempCollider)
        end
   end
   NoviceGuideManager.SetLockedObj(nil)
end

local function AddPanel(go,depth)
    local DlgNoviceGuide=require"ui.noviceguide.dlgnoviceguide"
    local UIPanel_Prototype=DlgNoviceGuide.GetPanel()
    local newObj=nil
    local panel=nil
    if go.lockedObjectData.needclip==true then
        newObj=GameObject.Instantiate(UIPanel_Prototype.gameObject)
        panel=newObj.transform:GetComponent("UIPanel")
        panel.clipOffset=Vector2(go.lockedObjectData.clipoffset[1],go.lockedObjectData.clipoffset[2])
    else
        newObj = UnityEngine.GameObject(("UIPanel_")..(go.targetUIObject.gameObject.name))
        panel=newObj:AddComponent(UIPanel)
    end
    newObj.transform.parent = go.targetUIObject.transform.parent    
	newObj.transform.localScale = Vector3.one
    newObj.transform.localPosition = Vector3.zero
    newObj.transform.localRotation = Quaternion.identity
    panel.depth = depth
    panel.sortingOrder = depth
    return newObj
end

local function AddComponentPanel(go,depth)
    local panel= go.targetUIObject.gameObject:AddComponent(UIPanel)
    panel.depth = depth
    panel.sortingOrder = depth
    go.targetUIObject.gameObject:SetActive(false)
    go.targetUIObject.gameObject:SetActive(true)
end

local function DealLockedObject()
    --printyellow("DealLockedObject")
    local lockedObj=NoviceGuideManager.GetLockedObj()
    if (lockedObj and lockedObj.collider) then
        --printyellow("-------------")
        local panel=nil
        if (lockedObj.targetUIObject.gameObject.transform.parent == lockedObj.parent) then
            if (lockedObj.lockedObjectData.addcomponent==true) then
                AddComponentPanel(lockedObj,cfg.guide.NoviceGuide.TARGETPANELDEPTH)
            else
                panel = AddPanel(lockedObj,cfg.guide.NoviceGuide.TARGETPANELDEPTH)
                panel:SetActive(false)
                NGUITools.SetLayer(panel, define.Layer.LayerUI)
                lockedObj.targetUIObject.gameObject.transform.parent = panel.transform
                panel:SetActive(true)
                lockedObj.tempPanel = panel.transform
            end
            if lockedObj.lockedObjectData.id~=101 then  --摇杆特殊处理
                local tempObj=UnityEngine.GameObject(("UIWidget_Temp_")..(lockedObj.targetUIObject.gameObject.name))
                if tempObj and panel then
                    tempObj.transform.parent=panel.transform
                    tempObj.transform.position=lockedObj.collider.transform.position
                    local uiwidget=tempObj:AddComponent(UIWidget)
                    local oriWidget=lockedObj.collider.gameObject:GetComponent(UIWidget)
                    if oriWidget then
                        uiwidget.depth=oriWidget.depth+1
                    else
                        uiwidget.depth=0
                    end
                    local tempCollider=tempObj:AddComponent("UnityEngine.BoxCollider")
                    tempCollider.size=lockedObj.collider.size
                    if tempCollider then
                        lockedObj.tempCollider=tempCollider
                        UIEventListenerHelper.SetClick(tempCollider,function(o)
                            if NoviceGuideManager.IsGuiding() then
                                if not IsNull(o) then
                                    NoviceGuideTrigger.ClickUIObject(o.transform)
                                    UICamera.Notify(lockedObj.collider.gameObject,"OnClick",nil)
                                end
                            else
                                GameObject.Destroy(tempCollider)
                            end
                        end)
                        
                    end
                end
             end
        else
            panel = lockedObj.parent.gameObject
        end
    end
end

local function init()
    NoviceGuideManager=require"noviceguide.noviceguidemanager"
    NoviceGuideTrigger=require"noviceguide.noviceguide_trigger"
    NoviceGuideFsm=require"noviceguide.noviceguide_fsm"
end

return{
    init = init,
    FreeUIObj = FreeUIObj,
    LockUIObj = LockUIObj,
    DealLockedObject = DealLockedObject,
    FindLockedObject = FindLockedObject,
}