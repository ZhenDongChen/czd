local format            = string.format
local ItemManager       = require("item.itemmanager")
local ItemEnum          = require("item.itemenum")
local BonusManager      = require("item.bonusmanager")
local ItemIntroduct     = require("item.itemintroduction")
local Define            = require("define")
local EventHelper       = UIEventListenerHelper

local name, gameObject, fields

local equipPos = {
    [ItemEnum.EquipType.Weapon] = {1},
    [ItemEnum.EquipType.Hat] = {2},
    [ItemEnum.EquipType.Cloth] = {3},
    [ItemEnum.EquipType.Shoe] = {4},
    [ItemEnum.EquipType.Ring] = {5,6},
    [ItemEnum.EquipType.Necklace] = {7},
    [ItemEnum.EquipType.Bangle] = {8},
}

local function ResetPlayerEquipSlotList()
	for i = 1, fields.UIList_Equipment.Count do
		local listItem = fields.UIList_Equipment:GetItemByIndex(i - 1)
		listItem:SetIconTexture("null")
		listItem:SetText("UILabel_AnnealLevel", "+0")
		listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
		listItem.Controls["UISprite_Binding"].gameObject:SetActive(false)
		listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
		listItem:GetLabel(format("UILabel_%02d", i)).gameObject:SetActive(true)
	end
end

local function ShowPlayerInfo(player)
    fields.UILabel_PlayerName.text = player.m_Name
    fields.UILabel_PlayerLV.text = player.m_Level
    fields.UILabel_Power.text = player.m_Power
end

local function GetEquipment(msgEquipInfo)
    
    local equipItem = ItemManager.CreateItemBaseById(msgEquipInfo.modelid, msgEquipInfo,1)
    
    return equipItem
end

local function ShowEquipInfo(roleInfo, player)
    local equipsMsg = roleInfo.equipsdetail
    local equipItems = {}
    for i, equipMsg in ipairs(equipsMsg) do

        local equipItem = GetEquipment(equipMsg)
        local type = equipItem:GetDetailType()

        local allpos = equipPos[type]
        if #allpos == 1 then
            equipItems[allpos[1]] = equipItem
        else
            if equipItems[allpos[1]] == nil then
                equipItems[allpos[1]] = equipItem
            else
                equipItems[allpos[2]] = equipItem
            end
        end
    end
--    for i = 1, 8 do
--        local uiItem = fields.UIList_Equipment:GetItemByIndex(i-1)
--        local equipItem = equipItems[i]
--        if equipItem then
--            BonusManager.SetRewardItem(uiItem,equipItem,{notShowAmount=true})
--        else
--            BonusManager.SetEmptyItem(uiItem)
--        end
--    end
	ResetPlayerEquipSlotList()
	for equipSlot = 1, fields.UIList_Equipment.Count do
		local listItem = fields.UIList_Equipment:GetItemByIndex(equipSlot - 1)
		local equip = equipItems[equipSlot]
		if equip ~= nil then

			-- ����װ����������
			listItem:GetLabel(format("UILabel_%02d", equipSlot)).gameObject:SetActive(false)
			listItem:SetIconTexture(equip:GetTextureName())

			if equip:GetAnnealLevel() ~= 0 then 
				listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(true)
				listItem:SetText("UILabel_AnnealLevel", "+" .. equip:GetAnnealLevel())
			else
				listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
				listItem:SetText("UILabel_AnnealLevel", "")
			end
			-- �趨��������
			listItem.Controls["UISprite_Binding"].gameObject:SetActive(equip:IsBound())

			-- ����Ʒ��
			listItem.Controls["UISprite_Quality"].gameObject:SetActive(true)
			listItem.Controls["UISprite_Quality"].spriteName = "Sprite_ItemQuality"
			listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(equip:GetQuality())

		end
	end
	EventHelper.SetListClick(fields.UIList_Equipment, function(listItem)
			local playerEquip = equipItems[listItem.Index + 1]
			if playerEquip then 
				ItemIntroduct.DisplayItem( {
				item = playerEquip,
				buttons =
					{
						{ display = false, text = "", callFunc = nil },
						{ display = false, text = "", callFunc = nil },
						{ display = false, text = "", callFunc = nil },
					}
				} )
			end
	end )
end

local function ShowPlayerModel(player)
    local playerTrans         = player.m_Object.transform
    
    playerTrans.parent        = fields.UITexture_PlayerModel.transform

	playerTrans.localScale = Vector3.one * 155
	playerTrans.localPosition = Vector3(-5, -200, -170)
	playerTrans.rotation = Quaternion.Euler(-90,0,0)
    --player:SetUIScale(220)

    ExtendedGameObject.SetLayerRecursively(player.m_Object, Define.Layer.LayerUICharacter)
    EventHelper.SetDrag(fields.UITexture_PlayerModel,function(o,delta)
        if player.m_Object ~= nil then
            local vecRotate = Vector3(0,-delta.x,0)
            player.m_Object.transform.localEulerAngles = player.m_Object.transform.localEulerAngles + vecRotate
        end
    end)
end

local function show(roleId, roleInfo, player)
    ShowPlayerInfo(player)
    ShowEquipInfo(roleInfo, player)
    ShowPlayerModel(player)
end

local function refresh(roleId, roleInfo, player)
    ShowPlayerInfo(player)
    ShowEquipInfo(roleInfo, player)
    ShowPlayerModel(player)
end

local function update()

end

local function hide()

end

local function destroy()

end

local function init(name_in, gameObject_in, fields_in)
    name, gameObject, fields = name_in, gameObject_in, fields_in
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}