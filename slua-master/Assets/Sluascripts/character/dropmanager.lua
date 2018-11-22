local Network = require("network")
local CharacterManager=require"character.charactermanager"
local DropItem = require"character.dropitem"
local PickMgr=require"character.pickupmanager"
local PlayerRole=(require"character.playerrole").Instance()

local m_CurDropNum=0
local m_TotalExitNum=6

local function GetCsvId(bonus)
    local csvId=0
    for id ,value in pairs(bonus.items) do
        csvId=id
        break
    end
    return csvId
end

local function CanPick(msg)
    local result=false
    local owner=CharacterManager.GetCharacter(msg.owner)
    local csvId=GetCsvId(msg.bonus) 
    if owner and (owner.m_Id==PlayerRole.m_Id) and (csvId~=0) and PickMgr.CanPick(csvId) and (m_CurDropNum<m_TotalExitNum) then
        result=true
    end
    return result
end

local function OnMsg_SMonsterDrop(msg) 
    if CanPick(msg)==true then
        m_CurDropNum=m_CurDropNum+1      
        local item = DropItem:new()
        item:init(msg,true)   
    end
end

local function DelDrop()
    if m_CurDropNum>0 then 
        m_CurDropNum=m_CurDropNum-1
    end
end

local function init(params)
    m_CurDropNum=0
    Network.add_listeners( {
    { "map.msg.SMonsterDrop", OnMsg_SMonsterDrop},
    },"dropmanager")
end

return{
    init = init,
    DelDrop = DelDrop,
}