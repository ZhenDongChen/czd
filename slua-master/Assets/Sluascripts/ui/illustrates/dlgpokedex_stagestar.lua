local print,printt,unpack   = print,printt,unpack
local ConfigManager         = require"cfg.configmanager"
local PetManager            = require"character.pet.petmanager"
local EventHelper           = UIEventListenerHelper
local BagManager            = require"character.bagmanager"
local uimanager             = require"uimanager"
local cfgConsume
local cfgAward
local name,gameObject,fields
local pet
local itemid
local itemCnt
local nextlevel

local function destroy()

end

local function hide()

end

local function DisplayAwardItem(item,data,ridx)
    local b = nextlevel == data.stagestarlevel
    if b then
        if data.stagestarlevel <= pet.PetStageStar then
            item.Controls["UIButton_Add"].isEnabled = true
            item.Controls["UILabel_Add"].text = LocalString.PartnerText.Active
            EventHelper.SetClick(item.Controls["UIButton_Add"],function()
                if data.costitems <= itemCnt then
                    PetManager.RequestActiveStagestarAward(pet.ConfigId,nextlevel)
                else
                    uimanager.ShowSingleAlertDlg{content=LocalString.NOT_ENOUGH_WUFADAN}
                end
            end)
        else
            item.Controls["UIButton_Add"].isEnabled = false
            item.Controls["UILabel_Add"].text = LocalString.PartnerText.Active
        end
    else
        item.Controls["UIButton_Add"].isEnabled = false
        if nextlevel > data.stagestarlevel then
            item.Controls["UILabel_Add"].text = LocalString.PartnerText.Actived
        else
            item.Controls["UILabel_Add"].text = LocalString.PartnerText.Active
        end
    end
    item.Controls["UILabel_Desc"].text = data.desc
    item.Controls["UILabel_WuFaDan"].text = tostring(data.costitems)
    item.Controls["UILabel_Level"].text = LocalString.PartnerText.StageStar .. tostring(math.floor(data.stagestarlevel/10))
end

local function DisplayPet()
    fields.UIList_Award:ResetListCount(#cfgAward.propertylist)
    for idx,data in ipairs(cfgAward.propertylist) do
        local item = fields.UIList_Award:GetItemByIndex(idx-1)
        DisplayAwardItem(item,data,idx)
    end
end

local function GetNextLevel()
    local ret = 1e8
    for _,v in pairs(cfgAward.propertylist) do
        if v.stagestarlevel > pet.PetAwardStar then
            ret = ret > v.stagestarlevel and v.stagestarlevel or ret
        end
    end
    return ret
end

local function refresh(params)
    nextlevel = GetNextLevel()
    itemCnt = BagManager.GetItemNumById(itemid)
    fields.UILabel_WuFaDanNum.text = tostring(itemCnt)
    DisplayPet()
end

local function show(params)
    pet = params.pet
    fields.UILabel_DlgTitle.text = LocalString.PartnerText.AwardStagestar
    cfgConsume = ConfigManager.getConfig("maunalconfig")
    itemid = cfgConsume.petcostitemid
    cfgAward = ConfigManager.getConfigData("petstagestarbonus",pet.ConfigId)
end

local function update()

end

local function init(oname,ogameObject,ofields)
    name,gameObject,fields = oname,ogameObject,ofields
end

return {
    destroy             = destroy,
    hide                = hide,
    refresh             = refresh,
    show                = show,
    update              = update,
    init                = init,
}
