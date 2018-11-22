local ConfigManager = require("cfg.configmanager")
local UIManager     = require("uimanager")
local Network       = require("network")
local CharacterManager = require("character.charactermanager")

local listenerId 
local EctypePlayerData = {
    m_EctypePlayers = {}
}

local EctypePlayer = Class:new()


function EctypePlayer:__new(msg)
    self:SetServerMsg(msg)
    self.m_Attributes = {
        [cfg.fight.AttrId.HP_VALUE] = 100,
        [cfg.fight.AttrId.HP_FULL_VALUE] = 100,
    }
    self:SetPlayerAttr()
end

function EctypePlayer:SetPlayerAttr()
    local player = CharacterManager.GetCharacter(self.m_Id)
    if player then
        if player.m_Attributes[cfg.fight.AttrId.HP_VALUE] then
            self.m_Attributes[cfg.fight.AttrId.HP_VALUE] = player.m_Attributes[cfg.fight.AttrId.HP_VALUE]
        end
        if player.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE] then
            self.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE] = player.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
        end
    end
end

function EctypePlayer:SetServerMsg(msg)
    self.m_Id           = msg.id
    self.m_Name         = msg.name
    self.m_Level        = msg.level
    self.m_VipLevel     = msg.viplevel
    self.m_Profession   = msg.profession
    self.m_Gender       = msg.gender
    self.m_FamilyName   = msg.familyname
    self.m_ServerId     = msg.serverid
end

function EctypePlayer:GetHeadIcon()
    local professionData = ConfigManager.getConfigData("profession",self.m_Profession)
    local modelName = (self.m_Gender == cfg.role.GenderType.MALE) and professionData.modelname or professionData.modelname2
    local model = ConfigManager.getConfigData("model",modelName)
    return model.headicon or ""
end

function EctypePlayer:GetId()
    return self.m_Id
end

function EctypePlayer:GetName()
    return self.m_Name
end

function EctypePlayer:GetLevel()
    return self.m_Level
end

function EctypePlayer:GetVipLevel()
    return self.m_VipLevel
end

function EctypePlayer:GetHpPercent()
    local re = self.m_Attributes[cfg.fight.AttrId.HP_VALUE] / self.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
    return re
end
--=============================================================================================
local function GetPlayerInfo(roleId)
    for i, playerInfo in pairs(EctypePlayerData.m_EctypePlayers) do
        if playerInfo:GetId() == roleId then
            return playerInfo
        end
    end
    return nil
end

--=============================================================================================


local function RefreshUI()
    if UIManager.isshow("ectype.dlgectypeothers") then
        UIManager.refresh("ectype.dlgectypeothers")
    end
end

--=====================================================================================
--接受地图信息中的血量变化信息
local function OnMsgNearByPlayerEnter(msg)
    local playerInfo = GetPlayerInfo(msg.roleid)
    if playerInfo then
        playerInfo:SetPlayerAttr()
        local attrs = msg.fightercommon.attrs
        if attrs[cfg.fight.AttrId.HP_VALUE] then
            
            playerInfo.m_Attributes[cfg.fight.AttrId.HP_VALUE] = attrs[cfg.fight.AttrId.HP_VALUE]
        end
        if attrs[cfg.fight.AttrId.HP_FULL_VALUE] then
            
            playerInfo.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE] = attrs[cfg.fight.AttrId.HP_FULL_VALUE]
        end
    end
    RefreshUI()
end

local function OnMsgChangeAttr(msg)
    local playerInfo = GetPlayerInfo(msg.roleid)
    if playerInfo then
        playerInfo:SetPlayerAttr()
        if msg.attrs[cfg.fight.AttrId.HP_VALUE] then
            playerInfo.m_Attributes[cfg.fight.AttrId.HP_VALUE] = msg.attrs[cfg.fight.AttrId.HP_VALUE]
        end
        if msg.attrs[cfg.fight.AttrId.HP_FULL_VALUE] then
            playerInfo.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE] = msg.attrs[cfg.fight.AttrId.HP_FULL_VALUE]
        end
    end
    RefreshUI()
end

local function OnMsgChangeHp(msg)
    local playerInfo = GetPlayerInfo(msg.roleid)
    if playerInfo and msg.hp then
        playerInfo:SetPlayerAttr()
        playerInfo.m_Attributes[cfg.fight.AttrId.HP_VALUE] =  msg.hp
    end
    RefreshUI()
end

local function OnMsgBeSkillAttack(msg)
    local playerInfo = GetPlayerInfo(msg.roleid)
    if playerInfo and msg.hp then
        playerInfo:SetPlayerAttr()
        playerInfo.m_Attributes[cfg.fight.AttrId.HP_VALUE] =  msg.hp
    end
    RefreshUI()
end

local function OnMsgSEctypeMemberEnter(msg)
    local playerInfo = GetPlayerInfo(msg.id)
    if playerInfo then
        playerInfo:SetServerMsg(msg)
    else
        local newPlayerInfo = EctypePlayer:new(msg)
        table.insert( EctypePlayerData.m_EctypePlayers, newPlayerInfo )
    end
    RefreshUI()
end

local function OnMsgSPraiseMember(msg)
    --别人给你点赞
    if PlayerRole:Instance().m_Id == msg.to then
        local playerInfo = GetPlayerInfo(msg.from)
        if playerInfo then 
            local content = string.format( LocalString.ClickLike_Other, playerInfo.m_Name )
            UIManager.ShowSystemFlyText(content)
        end
    end
    --你给别人点赞
    if PlayerRole:Instance().m_Id == msg.from then
        local playerInfo = GetPlayerInfo(msg.to)
        if playerInfo then 
            local content = string.format( LocalString.ClickLike_Self, playerInfo.m_Name )
            UIManager.ShowSystemFlyText(content)
        end 
    end
end

--=====================================================================================

local function ClickLike(id)
    local re = map.msg.CPraiseMember({member = id})
    Network.send(re)
end

local function InitProtocal()
    if listenerId then
        Network.remove_listeners(listenerId)
        listenerId = nil
    end
    
    listenerId = Network.add_listeners( {
        { "map.msg.SNearbyPlayerEnter",   OnMsgNearByPlayerEnter    },
        { "map.msg.SChangeAttrs",         OnMsgChangeAttr           },
        { "map.msg.SChangeHp",            OnMsgChangeHp             },
        { "map.msg.SBeSkillAttack",       OnMsgBeSkillAttack        },
        { "map.msg.SEctypeMemberEnter",   OnMsgSEctypeMemberEnter   },
        { "map.msg.SPraiseMember",        OnMsgSPraiseMember        },
    },"ectypeothersmanager")
    EctypePlayerData.m_EctypePlayers = {}
end

local function RemoveProtocal()
    if listenerId then
        Network.remove_listeners(listenerId)
        listenerId = nil
    end
end

local function ShowUI()

    InitProtocal()
    UIManager.showorrefresh("ectype.dlgectypeothers")
end

local function HideUI()

    RemoveProtocal()
    if UIManager.isshow("ectype.dlgectypeothers") then
        UIManager.hide("ectype.dlgectypeothers")
    end
end

local function GetEctypePlayers()
    return EctypePlayerData.m_EctypePlayers
end

--=====================================================================================
return {
    ShowUI = ShowUI,
    HideUI = HideUI,
    ClickLike = ClickLike,
    GetEctypePlayers = GetEctypePlayers,
}
