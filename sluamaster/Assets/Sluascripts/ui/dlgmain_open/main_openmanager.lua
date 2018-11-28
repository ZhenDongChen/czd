local RideManager=require "ui.ride.ridemanager"
local ExchangeMgr=require"ui.exchange.exchangemanager"
local MailManager = require("ui.mail.mailmanager")
local FashionManager = require"character.fashionmanager"
local MaimaiManager = require("ui.maimai.maimaimanager")
local FriendManager = require("ui.friend.friendmanager")
local PlayerRoleManager = require("ui.playerrole.playerrolemanager")
local TitleManager = require("ui.title.titlemanager")
local AchievementManager = require "ui.achievement.achievementmanager"
local RoleSkill       = require "character.skill.roleskill"
local ShopManager = require("shopmanager")
local ExchangeManager = require("ui.exchange.exchangemanager")
local ConfigManager = require("cfg.configmanager")
local m_RedDotList={}

local function RegisterAllRedDot()
    m_RedDotList={
        [cfg.ui.FunctionList.MAIL]={func=(MailManager.UnRead)},
        [cfg.ui.FunctionList.MOUNT]={func=(RideManager.UnRead)},
        [cfg.ui.FunctionList.FASHION]={func=(FashionManager.UnRead)},
        [cfg.ui.FunctionList.TITLE]={func=(TitleManager.UnRead)},        
        [cfg.ui.FunctionList.ROLE]={func=(PlayerRoleManager.UnRead)},
        [cfg.ui.FunctionList.ACHIEVEMENT]={func=(AchievementManager.UnRead)},
        [cfg.ui.FunctionList.SKILL]={func=(RoleSkill.UnRead)},
        [cfg.ui.FunctionList.EXCHANGE]={func=(ExchangeManager.UnRead)},      
--        [cfg.ui.FunctionList.CORNUCOPIA]={icon=fields.UISprite_Achievement_Warning,func=(CornucopiaManager.UnRead)},
    }
end

local function init()
    
end

local function UnRead()
    RegisterAllRedDot()
    local result=false
    for id,redDot in pairs(m_RedDotList) do
        if redDot then
            local configData=ConfigManager.getConfigData("uimainreddot",id)
            if configData and (configData.dottype~=cfg.ui.DotType.NONE) then
                if redDot.func()==true then
                    result=true
                    break
                end
            end
        end
    end
    return result
end

return{
    init = init,
    UnRead = UnRead,
}