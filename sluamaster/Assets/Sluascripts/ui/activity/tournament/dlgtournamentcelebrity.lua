local unpack        = unpack
local print         = print
local UIManager       = require("uimanager")
local EventHelper       = UIEventListenerHelper
local ConfigManager= require("cfg.configmanager")
local TournamentManager   =require("ui.activity.tournament.tournamentmanager")
local TournamentInfo = require("ui.activity.tournament.tournamentinfo")
local Utils             = require "common.utils"
local Player=require("character.player")
local Define=require("define")
local PlayerRole=require("character.playerrole"):Instance()
local name
local gameObject
local fields

local m_CurrentTerm
local m_CurrentProfession
local m_Player
local m_IsShow

local function GetLatestTermid()
    local targetTerm = TournamentInfo.GetCurrentTerm()-1
    if TournamentInfo.GetCurrentStage()==cfg.huiwu.Stage.END_BATTLE then
        targetTerm = TournamentInfo.GetCurrentTerm()
    end
    return targetTerm
end

local function RequestCelebrity(term, profession)
    if term == nil then
        ternm = 0
    end
    m_CurrentTerm = math.max(term,0)
    m_CurrentTerm = math.min(m_CurrentTerm, TournamentInfo.GetCurrentTerm())
    m_CurrentProfession = profession
    if m_CurrentTerm > 0 then
        TournamentManager.send_CGetChampion(m_CurrentTerm,m_CurrentProfession, cfg.huiwu.HuiWu.CHAMPION_CTX_CELEBRITY)
    end
end

local function hide()
    printyellow("[dlgtournamentcelebrity:hide]dlgtournamentcelebrity hide!")
    m_IsShow = false
end

local function OnUIButton_Close_Celebrity()
    -- printyellow("[dlgtournamentcelebrity:OnUIButton_Close_Celebrity] UIButton_Close_Celebrity clicked!")
    UIManager.hide("activity.tournament.dlgtournamentcelebrity")
end

local function OnUIButton_Turn()
    -- printyellow("[dlgtournamentcelebrity:OnUIButton_Turn] UIButton_Turn clicked!")
    local targetTerm = tonumber(fields.UILabel_Number.text)
    if targetTerm and targetTerm>0 and targetTerm<= GetLatestTermid() then
        RequestCelebrity(targetTerm, m_CurrentProfession)
    end
end

local function OnListItemClicked(listitem)
    printyellow("[dlgtournamentcelebrity:OnListItemClicked] UIList_Guild ListItem clicked!ListItem data = ",listitem.Data)
    RequestCelebrity(GetLatestTermid(), listitem.Data)
end

local function OnUIButton_Celebrity_Left()
     printyellow("[dlgtournamentcelebrity:OnUIButton_Celebrity_Left] UIButton_Celebrity_Left clicked!")
    if m_CurrentTerm>1 then
        RequestCelebrity(m_CurrentTerm-1, m_CurrentProfession)
    end
end

local function OnUIButton_Celebrity_Right()
     printyellow("[dlgtournamentcelebrity:OnUIButton_Celebrity_Right] UIButton_Celebrity_Right clicked!")
    if m_CurrentTerm < GetLatestTermid() then
        RequestCelebrity(m_CurrentTerm+1, m_CurrentProfession)
    end
end

local function registereventhandler()
    --printyellow("[dlgtournamentcelebrity:registereventhandler]dlgtournamentcelebrity registereventhandler!")
    EventHelper.SetClick(fields.UIButton_Close_Celebrity, OnUIButton_Close_Celebrity)
    EventHelper.SetClick(fields.UIButton_Turn, OnUIButton_Turn)
    EventHelper.SetListClick(fields.UIList_Guild,OnListItemClicked)
    EventHelper.SetClick(fields.UIButton_LeftArrows, OnUIButton_Celebrity_Left)
    EventHelper.SetClick(fields.UIButton_RightArrows, OnUIButton_Celebrity_Right)
end

local function reset()
    m_CurrentProfession = 0
    m_CurrentTerm = 0
end

local function update()
    if m_Player and m_Player.m_Object then
        m_Player.m_Avatar:Update()
    end
end

local function OnPlayerLoaded(params)
    -- printyellow("[dlgtournamentcelebrity:OnPlayerLoaded]", params)
    if not m_Player.m_Object then return end
    local playerObj = m_Player.m_Object
    local playerTrans           = playerObj.transform
    playerTrans.parent          = fields.UITexture_PlayerCelebrity.gameObject.transform
	playerTrans.localScale      = Vector3.one*220
    playerTrans.localPosition   = Vector3(-150,-190,-1500)
    playerTrans.rotation   =  Quaternion.Euler(-90,0,0)
    ExtendedGameObject.SetLayerRecursively(playerObj,Define.Layer.LayerUICharacter)
    playerObj:SetActive(true)
    m_Player:PlayLoopAction(cfg.skill.AnimType.Stand)

    EventHelper.SetDrag(fields.UITexture_PlayerCelebrity,function(o,delta)
        local vecRotate = Vector3(0,-delta.x,0)
        playerObj.transform.localEulerAngles = playerObj.transform.localEulerAngles + vecRotate
    end)
end

local function ShowPlayer(id,profession,gender,showheadinfo,dress,equips,iscreat)
    if m_Player then
        m_Player:release()
        m_Player=nil
    end

    if id and id>0 then
        m_Player = Player:new(true)
        m_Player.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
        m_Player:init(id, profession, gender, showheadinfo, dress, equips, iscreat)
        m_Player:RegisterOnLoaded(OnPlayerLoaded)
    end
end

local function GetServerName(serverid)
    local server
    if serverid and serverid>=0 then
        --printyellow(string.format("[dlgtournamentcelebrity:GetServerName] GetServerName for serverid [%d].", serverid))
        local serverlist
        -- local serverInfos = GetServerInfos()
        -- if serverInfos then
            --printyellow(string.format("[dlgtournamentcelebrity:GetServerName] serverInfos: %s.", dump_table(serverInfos) ))
            -- local channelid = Game.Platform.Interface.Instance:GetSDKPlatform()
            -- serverlist = serverInfos.servers[channelid]
            -- if not serverlist then
            --     serverlist = serverInfos.servers.others
            -- end
        serverlist = GetServerList()
            --printyellow(string.format("[dlgtournamentcelebrity:GetServerName] serverlist: %s.", dump_table(serverlist) ))
        -- end
        -- serverlist = GetServerInfos()
        server = serverlist and serverlist[serverid] or nil
        --printyellow(string.format("[dlgtournamentcelebrity:GetServerName] server: %s.", serverlist and dump_table(serverlist) or "nil" ))
    end
    return server and server.name or ""
end

local function UpdateCelebrity(msg)
    -- printyellow("[dlgtournamentcelebrity:UpdateCelebrity] update dlgtournamentcelebrity!")

    --[[
    --test
    msg = {}
    msg.termid = 0
    msg.profession = PlayerRole.m_Profession
    msg.championinfo = {}
    msg.championinfo.awardword = "test!"
    msg.championinfo.worshipnum = 520
    msg.championinfo.createtime = 0
    msg.championinfo.showinfo=
    {
        name = PlayerRole.m_Name,
        roleid=PlayerRole.m_Id,
        profession=PlayerRole.m_Profession,
        gender=PlayerRole.m_Gender,
        dressid=PlayerRole.m_Dress,
        equips=PlayerRole.m_Equips,
        serverid = 520
    }

    if msg then
        printyellow("[dlgtournamentcelebrity:UpdateCelebrity] msg.championinfo.showinfo.roleid:", msg.championinfo.showinfo.roleid)
    else
        printyellow("[dlgtournamentcelebrity:UpdateCelebrity] msg nil!")
    end
    --]]
	local huiwuCfg = ConfigManager.getConfig("huiwu")
    if msg and msg.championinfo.showinfo.roleid>0 then
        m_CurrentProfession = msg.profession
        m_CurrentTerm = msg.termid

        fields.UILabel_Term.text = msg.termid
        fields.UILabel_Empty01.gameObject:SetActive(false)
        fields.UILabel_Server.gameObject:SetActive(false)--���ط�����
        --fields.UILabel_ServerName.text = GetServerName(msg.championinfo.showinfo.serverid)
        fields.UILabel_PlayerName.text = msg.championinfo.showinfo.name
        fields.UILabel_Time01.text = Utils.strtime(LocalString.Tournament_Celebrity_Time_Format, msg.championinfo.createtime/1000)

        --testimonials
        local faction = ConfigManager.getConfigData("profession", msg.profession)
        local factionname = faction and faction.name or ""
        local testimonials = msg.championinfo.awardword
		
        if IsNullOrEmpty(testimonials) then
            testimonials = string.format(huiwuCfg.acceptancespeech, msg.championinfo.showinfo.name, factionname)
        end
        --printyellow("[dlgtournamentcelebrity:registereventhandler] testimonials=", testimonials)
        fields.UILabel_Testimonials.text = testimonials and testimonials or ""

        fields.UISprite_Fighting_Show.gameObject:SetActive(true)
        fields.UILabel_Power_Show.gameObject:SetActive(true)
        fields.UILabel_Name_Show.gameObject:SetActive(true)
        fields.UISprite_LV_Show.gameObject:SetActive(true)
        fields.UILabel_Name_Show.text = msg.championinfo.showinfo.name   --role name
        fields.UILabel_Power_Show.text = msg.championinfo.showinfo.combatpower   --fightpowder
        fields.UILabel_Level_Show.text = msg.championinfo.showinfo.level
        --show model
        local showinfo = msg.championinfo.showinfo
        ShowPlayer(showinfo.roleid, showinfo.profession, showinfo.gender, false, showinfo.dressid, showinfo.equips)
    else
        --printyellow("[dlgtournamentcelebrity:UpdateCelebrity] clear dlgtournamentcelebrity!")
        if msg then
            fields.UILabel_Term.text = msg.termid
        else
            fields.UILabel_Term.text = ""
        end
        fields.UILabel_PlayerName.text = LocalString.Tournament_Celebrity_Empty
        fields.UILabel_Time01.text = LocalString.Tournament_Celebrity_Empty
        fields.UILabel_ServerName.text = LocalString.Tournament_Celebrity_Empty
        fields.UILabel_Testimonials.text = LocalString.Tournament_Celebrity_Empty
		--fields.UILabel_Testimonials.text = string.format(huiwuCfg.acceptancespeech, "bb", "aa")
        fields.UILabel_Empty01.gameObject:SetActive(true)

        fields.UILabel_Server.gameObject:SetActive(false)--���ط�����
        fields.UISprite_Fighting_Show.gameObject:SetActive(false)
        fields.UILabel_Power_Show.gameObject:SetActive(false)
        fields.UILabel_Name_Show.gameObject:SetActive(false)
        fields.UISprite_LV_Show.gameObject:SetActive(false)
        if m_Player then
            m_Player:release()
            m_Player=nil
        end
    end

    --test
    --ShowPlayer(PlayerRole.m_Id, PlayerRole.m_Profession, PlayerRole.m_Gender, false, PlayerRole.m_Dress, PlayerRole.m_Equips)
end

local function ShowFactions()
    fields.UIList_Guild:Clear()
    local professions = ConfigManager.getConfig("profession")
    if professions then
        local showindex = 1
        for i=1,#professions do
            local profession = professions[i]
            if profession and true==profession.isopen then
                local listItem = fields.UIList_Guild:AddListItem()
                local UILabel_PartyName = listItem.Controls["UILabel_PartyName"]
                local UISprite_Icon = listItem.Controls["UISprite_Icon"]
                UILabel_PartyName.text = profession.name
                UISprite_Icon.spriteName = profession.icon
                listItem.Data = profession.faction

                if PlayerRole and profession.faction ==  PlayerRole.m_Profession then
                    showindex = i
                end
            end
        end

        fields.UIList_Guild:SetSelectedIndex(showindex)
    end
end

local function on_SGetChampion(msg)
    if true==m_IsShow and msg and msg.ctx == cfg.huiwu.HuiWu.CHAMPION_CTX_CELEBRITY then
        UpdateCelebrity(msg)
    end
end

local function init(params)
    --printyellow("[dlgtournamentcelebrity:init]dlgtournamentcelebrity init!")
    name, gameObject, fields    = unpack(params)
    registereventhandler()
    m_IsShow = false
end

local function show()
    printyellow("[dlgtournamentcelebrity:show]dlgtournamentcelebrity show!")
    reset()
    m_IsShow = true
    --fields.UIGroup_Celebrity.gameObject:SetActive(true)
    ShowFactions()
    UpdateCelebrity(nil)
    if PlayerRole then
        RequestCelebrity(GetLatestTermid(), PlayerRole.m_Profession)
    end
end

return{
    init = init,
    show = show,
    hide = hide,
    update = update,
    --UpdateCelebrity = UpdateCelebrity,
    on_SGetChampion = on_SGetChampion,
}
