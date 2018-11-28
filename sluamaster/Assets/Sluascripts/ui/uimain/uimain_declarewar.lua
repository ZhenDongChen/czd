local EventHelper = UIEventListenerHelper
local name, gameObject, fields

local function OnNotifyFamilyWarStateChange()

    local declarewarManager = require("family.declarewarmanager")
    local declaredFamilys = {}
    local warFamilyInfos = declarewarManager.GetWarFamilys()
    for familyId, re in pairs(PlayerRole:Instance().m_DeclareWarFamilys) do
        if warFamilyInfos[familyId] ~= nil then
            table.insert( declaredFamilys, warFamilyInfos[familyId] )
        end
    end
    
    local isDeclareWarOpen = declarewarManager.GetIsOpen()
    if isDeclareWarOpen then
        local beDecalreFamilys = declarewarManager.GetFamilyDeclareMine()
        for familyId, familyInfo in pairs(beDecalreFamilys) do
            table.insert( declaredFamilys, familyInfo )
        end
    end

    local familyCount = #declaredFamilys
    --printyellow("=============================================>", familyCount)
    --printt(declaredFamilys)
    fields.UIGroup_EnemyFamily.gameObject:SetActive(familyCount > 0)
    local isOpen = fields.UIButton_DeclarewarInfoOpen.gameObject.activeSelf
    fields.UIButton_DeclarewarInfoClose.gameObject:SetActive(not isOpen)
    EventHelper.SetClick(fields.UIButton_DeclarewarInfoOpen, function()
        fields.UIButton_DeclarewarInfoOpen.gameObject:SetActive(false)
        fields.UIButton_DeclarewarInfoClose.gameObject:SetActive(true)
        OnNotifyFamilyWarStateChange()
    end)
    EventHelper.SetClick(fields.UIButton_DeclarewarInfoClose, function()
        fields.UIButton_DeclarewarInfoOpen.gameObject:SetActive(true)
        fields.UIButton_DeclarewarInfoClose.gameObject:SetActive(false)
        OnNotifyFamilyWarStateChange()
    end)
    fields.UIList_EnemyFamily.gameObject:SetActive(isOpen)

    UIHelper.ResetItemNumberOfUIList(fields.UIList_EnemyFamily, familyCount)

    for i = 1, familyCount do
        local uiItem = fields.UIList_EnemyFamily:GetItemByIndex(i-1)
        if uiItem then
            local labelFamilyName = uiItem.Controls["UILabel_EnemyFamilyName"]
            if labelFamilyName and declaredFamilys[i] then
                labelFamilyName.text = declaredFamilys[i].m_FamilyName
            end
        end
    end

end

local function refresh()
    OnNotifyFamilyWarStateChange()
end

local function init(dlgname,dlggameObject,dlgfields)
    name, gameObject, fields = dlgname, dlggameObject, dlgfields
    gameevent.evt_notify:add(defineenum.NotifyType.FamilyWarStateChange, OnNotifyFamilyWarStateChange)
end



return {
    init = init,
    refresh = refresh,
}
