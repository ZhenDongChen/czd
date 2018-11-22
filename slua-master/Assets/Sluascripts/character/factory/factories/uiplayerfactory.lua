local Player = require("character.player")
local Define = require("define")
local CharacterManager_UI = require("character.charactermanager_ui")

local function SetPlayerInfo(player,msg)
    player.m_Name = msg.name
    player.m_Level = msg.level
    player.m_VipLevel = msg.viplevel
    player.m_Power = msg.combatpower
    if msg.title then
        player:ChangeTitle(msg.title)
    end
    if msg.familyname then
        player.m_FamilyName = msg.familyname
    end
    if msg.familyjob then
        player.m_FamilyJob = msg.familyjob
    end
    if msg.familylevel then
        player.m_FamilyLevel = msg.familylevel
    end
    if msg.lovername then
        player.m_LoverName = msg.lovername
    end
    if msg.fightattrs then
        player:ChangeAttr(msg.fightattrs)
    end
    if msg.lastonlinetime then
        player.m_LastOnlineTime = msg.lastonlinetime/1000
    end

end

local function OnLoadFinish(go, player)
    player:UIScaleModify()
end



local function CreatePlayerForUIByMsg(msgName, msg, callback, sfxScale)

    local player = Player:new()
    player.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    SetPlayerInfo(player,msg)
    player:RegisterOnLoaded(function(go)

            OnLoadFinish(go, player)
            local delayTimer = FrameTimer.New(function()                
                if callback then
					  printyellow("---------------------------------------------callback")
                    callback(player, go)
                end
            end, 1, 0)
            delayTimer:Start()
        end)
    CharacterManager_UI.AddCharacter(player)
    player:init(msg.roleid, msg.profession, msg.gender, false, msg.dressid, msg.equips, nil, sfxScale)

    return player
end

local function update()
	
	
end	


local function DestroyCharacter(character)
    CharacterManager_UI.RemoveCharacter(character.m_Id)
    character:release()
end

return {
    CreatePlayerForUIByMsg = CreatePlayerForUIByMsg,
    DestroyCharacter = DestroyCharacter,
	update = update,
}
