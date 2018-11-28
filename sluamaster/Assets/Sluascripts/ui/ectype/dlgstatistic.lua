local unpack, print     = unpack, print
local UIManager 	    = require("uimanager")
local BonusManager      = require("item.bonusmanager")
local EventHelper 	    = UIEventListenerHelper

local name, gameObject, fields
local groups = {}

local bHideKill
local playerRoleRank = -1
local playerRoleTeam = -1

local function IsPlayer(memberInfo)
    if memberInfo.ownername == nil or memberInfo.ownername == "" then
        return true
    else
        return false
    end
end

local function IsPlayerRole(memberInfo)
    if IsPlayer(memberInfo) then
        if memberInfo.name == PlayerRole:Instance().m_Name then
            return true
        end
    end
    return false
end

local function ExistPlayerRole(teamInfo)
    local exist = false
    for i, member in pairs(teamInfo.members) do
        if IsPlayerRole(member) then
            exist = true
            break
        end
    end
    return exist
end

local function SortMembers(members)
    utils.table_sort( members, function(memA, memB)
        if memA.damage > memB.damage then
            return true
        end
        return false
    end )
    return members
end

local function SortTeams(teams)
    utils.table_sort( teams, function(teamA, teamB)
        if ExistPlayerRole(teamA) then
            return true
        end
        if ExistPlayerRole(teamB) then
            return false
        end
        return false
    end)
    return teams
end

local function GetPlayerMembers(members)
    local players = {}
    for _,member in ipairs(members) do
        if IsPlayer(member) then
            local player ={}
            utils.deep_copy_to(member,player)
            table.insert(players,player)
        end
    end

    for _,member in ipairs(members) do
        if not IsPlayer(member) then
            for _,player in ipairs(players) do
                if player.name == member.ownername then
                    player.damage = player.damage + member.damage
                    break
                end
            end
        end
    end
    return SortMembers(players)
end

--=====================================================================================
local function ShowMember(number, uiItemOfMember, memberInfo)
    local spriteFirst = uiItemOfMember.Controls["UISprite_ONE"]
    local labelNumber = uiItemOfMember.Controls["UILabel_Num"]

    if number == 1 then
        spriteFirst.gameObject:SetActive(true)
        uiItemOfMember:SetText("UILabel_Num",tostring(number))

    else
        spriteFirst.gameObject:SetActive(false)
        uiItemOfMember:SetText("UILabel_Num",tostring(number))
    end
    local showName = (memberInfo.ownername == nil or memberInfo.ownername == "")
                        and memberInfo.name
                        or (memberInfo.name .. " (" .. memberInfo.ownername .. ")")

    uiItemOfMember:SetText("UILabel_Name", showName)
    uiItemOfMember:SetText("UILabel_Hurt", tostring(memberInfo.damage))
    local labelKill = uiItemOfMember.Controls["UILabel_Kill"]
    if bHideKill then
        labelKill.gameObject:SetActive(false)
    else
        labelKill.gameObject:SetActive(true)
        labelKill.text = tostring(memberInfo.kill)
    end

    return memberInfo.damage
end

local function ShowTeamStatistic(number, uiItemOfTeam, team)
    local uiListOfTeam = uiItemOfTeam.Controls["UIList_Ranklist"]
    local labelTitleKill = uiItemOfTeam.Controls["UILabel_TitleKill"]
    labelTitleKill.gameObject:SetActive(not bHideKill)
    local members = SortMembers(team.members)
    --local myRanking = -1
    local myName = PlayerRole:Instance().m_Name
    local totalDamage = 0
    if uiListOfTeam then
        UIHelper.ResetItemNumberOfUIList(uiListOfTeam, #members)
        for i = 1, #members do
            local uiItemOfMember = uiListOfTeam:GetItemByIndex(i-1)
            local memberInfo = members[i]
            local memberDamage = ShowMember(i, uiItemOfMember, memberInfo)
            totalDamage = totalDamage + memberDamage

            if IsPlayerRole(memberInfo) then
                playerRoleRank = i
                playerRoleTeam = number
            end

        end
    end
    return totalDamage
end

local function ShowGuardTowerStatistic(params)
    local team = params.statisticMsg.teams[1]
    local grade = params.grade
    local success = params.success
    local members = GetPlayerMembers(team.members)
    local maxdmg = members[1].damage
    for i = 1,fields.UIList_Ranklist.Count do
        local item = fields.UIList_Ranklist:GetItemByIndex(i-1)
        local memberInfo = members[i]
        item.gameObject:SetActive(memberInfo~=nil)
        if memberInfo then
            --printt(memberInfo)
            item:SetText("UILabel_Name", memberInfo.name)
            item:SetText("UILabel_Hurt", tostring(memberInfo.damage))
            item:SetText("UILabel_Amound", string.format(LocalString.GuardTower.RuneCount,memberInfo.rune))
            local UISlider_Hurt = item.Controls["UISlider_Hurt"]
            if UISlider_Hurt and maxdmg ~=0 then
                UISlider_Hurt.value = memberInfo.damage/maxdmg
            end
        end

        if i==1 then
            item.Controls["UIButton_Reward"].gameObject:SetActive(success)
            EventHelper.SetClick(item.Controls["UIButton_Reward"], function()
                 UIManager.show( "common.dlgdialogbox_reward",
                    { type          = 1,
                      callBackFunc  = function (params,fields)
                                            fields.UILabel_Title.text = LocalString.GuardTower.Rewards
                                            fields.UIGroup_Button.gameObject:SetActive(false)
                                            local rewardItem = BonusManager.GetItemsOfServerBonus(grade.maxkill)
                                            local wrapList = fields.UIList_ItemShow.gameObject:GetComponent("UIWrapContentList")
                                            EventHelper.SetWrapListRefresh(wrapList,function (uiItem,index,realIndex)
                                                                                        local item = rewardItem[realIndex]
                                                                                        uiItem:SetText("UILabel_ItemName", item:GetName())
                                                                                        uiItem:SetText("UILabel_ItemIntroduce", item:GetIntroduction())
                                                                                        BonusManager.SetRewardItem(uiItem, item, { notSetClick = true })
                                                                                    end)
                                            wrapList:SetDataCount(#rewardItem)
                                            wrapList:CenterOnIndex(-0.2)
                                       end,
                    })
            end)
        end
    end
end

local function ShowTeamTotalDamage(teams)
    if #teams ~= 2 or playerRoleTeam <= 0 then
        fields.UILabel_TotalDamage1.gameObject:SetActive(false)
        fields.UILabel_TotalDamage2.gameObject:SetActive(false)
        fields.UILabel_MyListName.gameObject:SetActive(false)
        fields.UILabel_MyList.gameObject:SetActive(false)
    else
        fields.UILabel_TotalDamage1.gameObject:SetActive(true)
        fields.UILabel_TotalDamage2.gameObject:SetActive(true)
        fields.UILabel_MyListName.gameObject:SetActive(true)
        fields.UILabel_MyList.gameObject:SetActive(true)
        fields.UILabel_DamageNumber1.text = teams[1].totalDamage
        fields.UILabel_DamageNumber2.text = teams[2].totalDamage
    end
    if playerRoleRank > 0 then
        fields.UILabel_MyList.text = tostring(playerRoleRank)
    else
        fields.UILabel_MyList.text = ""
    end


end


-- family arena

local function CmpFamilyMembers(a,b)
    if a.damage == b.damage then
        if a.kill == b.kill then
            return a.dead < b.dead
        else
            return a.kill > b.kill
        end
    else
        return a.damage > b.damage
    end
end

local function FamilyTeams(msgTeam)
    local ret = {}
    for _,team in pairs(msgTeam) do
        local teamInfo = {}
        teamInfo.dmg = 0
        -- teamInfo.heal = 0
        teamInfo.isRoleTeam = false
        teamInfo.members = {}
        -- teamInfo.towerInfo = msgTeam.towerinfo
        for _,memberInfo in pairs(team.members) do
            teamInfo.dmg = memberInfo.damage + teamInfo.dmg
            -- teamInfo.heal = memberInfo.heal + teamInfo.heal
            if memberInfo.name == PlayerRole.Instance().m_Name then
                memberInfo.isRole = true
                teamInfo.isRoleTeam = true
            end
            table.insert(teamInfo.members,memberInfo)
        end
        table.sort(teamInfo.members,CmpFamilyMembers)
        table.insert(ret,teamInfo)
    end
    table.sort(ret,function(a,b) return a.isRoleTeam end)
    return ret
end

local function ShowFamilyArenaTeam(item,team)
    local memberList = item.Controls["UIList_Ranklist"]
    memberList:ResetListCount(#team.members)
    for i=1,#team.members do
        local member = team.members[i]
        local memberItem = memberList:GetItemByIndex(i-1)
        memberItem.Controls["UISprite_ONE"].spriteName = "Family_Rank_" .. tostring(i>3 and 4 or i)
        memberItem.Controls["UILabel_Num"].text  = tostring(i)
        memberItem.Controls["UILabel_Name"].text = member.name
        memberItem.Controls["UILabel_Hurt"].text = string.format("%d%%",math.floor(member.damage*100/team.dmg))
        memberItem.Controls["UILabel_Kill"].text = string.format("%d",member.kill)
    end
end

local function GetTower(teamIndex,towerIndex)
    local suffix = tostring(teamIndex) .. '_' .. tostring(towerIndex)
    return fields["UISprite_Base"..suffix],fields["UILabel_Base"..suffix]
end

local function ShowTowerInfo(towerhps,isRoleTeam)
    local teamIndex = isRoleTeam and 1 or 2
    for i=1,3 do
        local teamTower = towerhps[i]
        local spriteTower
        local labelTower
        spriteTower,labelTower = GetTower(teamIndex,i)
        -- labelTower.text = tostring(teamTower*100) .. "%"
        labelTower.text = string.format("%.2f%%",teamTower*100)
        if teamTower<=0 then
            spriteTower.spriteName = i==3 and "Tower_Base_Grey" or "Tower_Grey"
        end
    end
end
--[[
groupindex : 1 默认 2 血战青云结算
callback:点击空白处回调

--]]
local function show(params)
    local groupindex = params.groupindex or 1
    bHideKill = params.hidekill
    -- fields.UILabel_TitleKill.gameObject:SetActive(not bHideKill)
    for index,uigroup in pairs(groups) do
        uigroup.gameObject:SetActive(index == groupindex)
    end
    if groupindex == 1 then
        local teams = SortTeams(params.statisticMsg.teams)
        UIHelper.ResetItemNumberOfUIList(fields.UIList_Team, #teams)

        for i = 1, #teams do
            local uiItemOfTeam = fields.UIList_Team:GetItemByIndex(i-1)
            local teamInfo = teams[i]
            teams[i].totalDamage = ShowTeamStatistic(i, uiItemOfTeam, teamInfo)
        end
        ShowTeamTotalDamage(teams)
    elseif groupindex == 2 then
        ShowGuardTowerStatistic(params)
    end
    if groupindex == 2 then
        EventHelper.SetClick(fields.UIButton_Close, function()
            UIManager.hidedialog(name)
            if params.callback then
                params.callback()
            end
        end)
    else
        EventHelper.SetClick(fields.UISprite_CloseResult, function()
            UIManager.hidedialog(name)
            if params.callback then
                params.callback()
            end
        end)
    end
    if groupindex == 3 then
        fields.UIGroup_Record.gameObject:SetActive(true)
        local teams = FamilyTeams(params.statisticMsg.teams)
        -- printyellow("teams")
        -- printt(teams)
        fields.UILabel_DamageNumber1.text = teams[1].dmg
        fields.UILabel_DamageNumber2.text = teams[2].dmg
        fields.UIList_Team:ResetListCount(#teams)
        fields.UILabel_MyListName.gameObject:SetActive(false)
        for i=1,#teams do
            local team = teams[i]
            local teamItem = fields.UIList_Team:GetItemByIndex(i-1)
            -- printyellow("team")
            -- printt(team)
            ShowFamilyArenaTeam(teamItem,team)
        end

        ShowTowerInfo(params.towerInfo.ally.towerhps,true)
        ShowTowerInfo(params.towerInfo.enemy.towerhps,false)
    end
end

local function hide()

end

local function update()

end

local function refresh(params)

end

local function destroy()

end

local function init(params)
    name, gameObject, fields = unpack(params)
    groups = {fields.UIGroup_Record,fields.UIGroup_GuardTower,fields.UIGroup_FamilyArena}

end

return {
    init    = init,
    show    = show,
    hide    = hide,
    update  = update,
    destroy = destroy,
    refresh = refresh,
}
