local unpack = unpack
local print  = print
local type   = type
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local ConfigManager = require "cfg.configmanager"
local ectypemanager = require "ectype.ectypemanager"

local StoryEctypeCfg
local EctypeChapterInfo
local BasicEctypeCfg
local gameObject

local UIWidget_Chapter
--endregion
local function destroy()
  --print(name, "destroy")
end

local function show(params)
  --print(name, "show")

end

local function hide()
  --print(name, "hide")
end

local function refresh(params)
  --print(name, "refresh")
end

local function update()

  --print(name, "update")
end



local function SetStars(cid,sid,num,gameObject)  --根据章数节数设置星星的数量 0-3 颗星星
--        printyellow("SetStars")
--        printyellow(sid)
--
--        printyellow(num)
        for i = 1, num do
            local str =  "UISprite_Chapter/UISprite_Story" .. sid .. "/UISprite_Story"..sid .."Star"..i .."/UISprite_Story"..sid .."Star"..i .."Light"
           -- printyellow(str)

            local curStar = gameObject.transform:Find(str)
            --printyellow(curStar)
            curStar.gameObject:SetActive(true)
        end
end

local function SetAllStars(obj)
    if EctypeChapterInfo == nil or getn(EctypeChapterInfo) then
        return
    end

    local chapters = EctypeChapterInfo.chapters
    for k , chapter in pairs (chapters) do
       for key,value  in pairs (chapter) do
          SetStars(k + 1,key + 1,value,obj)
       end
    end
end



local function GetTotalStarsByChapterId(id)
    --printyellow("GetTotalStarsByChapterId id")
    local num = 0
    if EctypeChapterInfo == nil or getn(EctypeChapterInfo) == 0 then
        return num
    end

    --printt(EctypeChapterInfo[id + 1])

    for k,v in pairs (EctypeChapterInfo[id].sectionstars) do
        num = num + v
    end
    return num
end

local function GetEctypeByIndex(chapter, section)
    if type(section) ~= "number" or section <= 0 then
        return nil
    end

     if type(chapter) ~= "number" or chapter <= 0 then
        return nil
    end

    if StoryEctypeCfg == nil or getn(StoryEctypeCfg) == 0 then
        return nil
    end
    --printyellow("GetEcypeId")
    for i,v in pairs(StoryEctypeCfg) do
        if v.chapter == chapter and v.section == section  then
            return v
        end
    end
    return nil
end

local function GetBasicByIndex(id) --副本id
    for k,v in pairs (BasicEctypeCfg) do
        if v.id == id then
            return v
        end
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)

    StoryEctypeCfg  = ConfigManager.getConfig("storyectype")
    BasicEctypeCfg  = ConfigManager.getConfig("ectypebasic")


    --EctypeChapterInfo = ectypemanager.GetChapterInfo()
    local curNumOfStars    = GetTotalStarsByChapterId(0)   -- 当前章星星数量
    local totalNumOfStarts = 18  -- 当前章节星星总数
    local totalLength      = 537 -- 进度条总长度
    local curLength        = totalLength * (curNumOfStars / totalNumOfStarts) --当前进度条长度
    SetAllStars(fields.UIScrollView_Chapter.gameObject)

    fields.UILabel_TotalStarNum.text = curNumOfStars .. "/" .. totalNumOfStarts

    local BarBackground = fields.UIProgressBar_Awards.transform:GetComponent("UISprite")
    local BarProgress  = fields.UISprite_Foreground.transform:GetComponent("UISprite")


    BarProgress.width =  curLength




    EventHelper.SetClick(fields.UIButton_Return, function() -- 表情包
        --printyellow(list_item.Index)
        uimanager.hide("dlgstorydungeon")
        uimanager.show("dlguimain")
        uimanager.show("dlgjoystick")

    end)

    EventHelper.SetClick(fields.UISprite_Story1, function() -- 打开第一章第一关
        --printyellow(list_item.Index)
        --printyellow("fields.UISprite_Story1")
        local section_data = GetEctypeByIndex(1, 1)
        local basic_data   = GetBasicByIndex(section_data.id)
        uimanager.showdialog("ectype.dlgstorydungeonsub",{section_data = section_data, basic_data = basic_data})

    end)

end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
}
