
local ConfigManager         = require("cfg.configmanager")
local UIManager             = require("uimanager")
local AttributeHelper       = require("attribute.attributehelper")

local Title = Class:new()

function Title:__new(id, isActive, config)
    self.m_Id           = id            --称号Id
    self.m_IsActive     = isActive      --是否已获得
    self.m_ObtainedTime = 0
    self.m_ConfigData   = ConfigManager.getConfigData("title",id)        --配置数据
    self.m_PropertyStrs = nil
    self.m_EquipTime    = 0
    self.m_Expiretime   = 0
end

function Title.GetTextColor(character)
    if character == nil then
        print("Title:GetTextColor char==nil")
        return "[ffffff]"
    end
    if character:IsMonster() then
        --怪物： ffffff
        return "[ffffff]"
    elseif character:IsNpc() then
        --NPC： eedc41
        return "[eedc41]"
    elseif character:IsPet() then
        --伙伴： f37ce4
        return "[f37ce4]"
    elseif character:IsPlayer() then
        local mainRole = PlayerRole:Instance()
        if character.m_Id == mainRole.m_Id then
            --玩家本人： 96fcb3
            return "[96fcb3]"
        else
            if character.m_FamilyName and mainRole.m_FamilyName
            and character.m_FamilyName==mainRole.m_FamilyName then
                --同家族玩家： 28d23c
                return "[28d23c]"
            else
                --其他玩家： 5fdafe
                return "[5fdafe]"
            end
        end
    else
        return "[ffffff]"
    end
end

function Title:GetName()
    return self.m_ConfigData.name
end

function Title:IsShow()
    if self.m_ConfigData.showmode == cfg.role.TitleShowMode.ShowAfterGet then
        return self.m_IsActive
    end
    return true
end

function Title:GetDisplayType()
    return self.m_ConfigData.showtype
end

function Title:GetTexturePath()
    return self.m_ConfigData.path
end

function Title:GetCondition()
    return self.m_ConfigData.condition
end

function Title:GetTitleTime()
    return self.m_ConfigData.titletime
end

function Title:GetDescription()
    return self.m_ConfigData.description
end

function Title:GetProperty()
    return self.m_ConfigData.property
end

function Title:GetPropertyStrs()
    if self.m_PropertyStrs ~= nil then
        return self.m_PropertyStrs
    end
    self.m_PropertyStrs = {}

    for i,property in ipairs(self.m_ConfigData.property) do
        local propertyName = AttributeHelper.GetAttributeName(property.propertytype)
        local prepertyValue = AttributeHelper.GetAttributeValueString(property.propertytype, property.value)
        str = "" .. propertyName .. "+" ..prepertyValue
        table.insert(self.m_PropertyStrs,str)
    end

    return self.m_PropertyStrs
end

function Title:GetRestTime()
    if self.m_ConfigData.titletime <= 0 then
        return nil
    else
        return self.m_Expiretime - timeutils.GetServerTime() -- os.time()
    end
end


function Title:GetRestTimeString()
    if self.m_IsActive == false then
        return ""
    end
    local restTime = self:GetRestTime()
    if restTime == nil or restTime < 0 then
        return ""
    end
    local sec = restTime%60
    local min,_ = math.modf((restTime%3600)/60)
    local hour,_ = math.modf(restTime/3600)
    return string.format("%02d:%02d:%02d",hour,min,sec)
end

function Title:Check()
    if self.m_IsActive == false then
        return
    end
    if self.m_ConfigData.titletime >= 0 then
        local resttime = self:GetRestTime()
        if resttime ~= nil and resttime < 0 then
            self:TimeOut()
        end
    end
end

function Title:TimeOut()
    if self.m_IsActive == true then
        self.m_IsActive = false
        if PlayerRole:Instance().m_Title ~= nil and PlayerRole:Instance().m_Title.m_Id == self.m_Id then
            PlayerRole:Instance():ChangeTitle(nil)
        end
        UIManager.refresh("title.tabtitle")
    end
end

function Title:LoadTitle(parentObj)
    local empGo = UnityEngine.GameObject("Title_Empty")
    empGo.transform.parent = parentObj.transform
    Util.Load(cfg.role.Title.TitlePrefabGroupPath,define.ResourceLoadType.LoadBundleFromFile, function(assert_obj)
        if assert_obj ~= nil and (not IsNull(assert_obj)) then
            local obj = Util.Instantiate(assert_obj, cfg.role.Title.TitlePrefabGroupPath)
            local panel = obj:GetComponent("UIPanel")
            if panel then
                UnityEngine.Object.Destroy(panel)
            end
            obj.name = "dlgheadtitle"
            obj.transform.parent = parentObj.transform
			obj.transform.localScale = Vector3(1.5,1.5,1.5)
            obj.transform.localPosition = Vector3(0,0,0)
            obj:SetActive(true)
            local trans = obj.transform:Find("UIList_Title")
            self:SetTitle(trans)
        end
    end)
end

function Title:SetTitle(trans)
    if trans == nil then
        return false
    end
    for i = 1, trans.childCount do
        local itemTrans = trans:GetChild(i-1)
        if itemTrans.gameObject.name == self:GetTexturePath() then
            itemTrans.gameObject:SetActive(true)
        else
            itemTrans.gameObject:SetActive(false)
        end
    end
    return true
end

function Title:SetCharacter(char)
    self.m_Character = char
end

function Title:GetSpliceText()
    local TitleManager = require("ui.title.titlemanager")
    local originalText = self:GetTexturePath()
    local newText = string.gsub( originalText, "<text='BanLvName'>", LocalString.TitleSystem.SomeOne )
    local txt_ex = string.find( originalText,"<text='BanLvName'>")
    if TitleManager:GetLoveName() and TitleManager:GetLoveName() ~= nil and TitleManager:GetLoveName() ~= "" then
        if txt_ex then
            return string.gsub( originalText, "<text='BanLvName'>", TitleManager:GetLoveName() ) 
        else
            return newText
        end
    else
        return newText
    end
    -- local originalText = self:GetTexturePath()
    -- local newText = string.gsub( originalText, "<text='BanLvName'>", LocalString.TitleSystem.SomeOne )
    -- local txt_ex = string.find( originalText,"<text='BanLvName'>")
    -- if not self.m_IsActive then
    --     if txt_ex then
    --         return newText
    --     else
    --         return originalText
    --     end
    -- else
    --     local txt_ex = string.find( originalText,"<text='BanLvName'>")
    --     if txt_ex then
    --         local MaimaiManager = require("ui.maimai.maimaimanager")
    --         local mmInfo = MaimaiManager.GetMaimaiInfo()
    --         if mmInfo then
    --             local banLvRole1 = mmInfo:Get(cfg.friend.MaimaiRelationshipType.BanLvNan, 1)
    --             local banLvRole2 = mmInfo:Get(cfg.friend.MaimaiRelationshipType.BanLvNv, 1)
    --             local banLvRole = (banLvRole1 ~= nil) and banLvRole1 or banLvRole2
    --   --          printyellow(banLvRole1,banLvRole2,banLvRole)
    --             if banLvRole then
    --                 if banLvRole:GetRole():GetId() == PlayerRole:Instance().m_Id then

    --                 else
    --                     return string.gsub( originalText, "<text='BanLvName'>", banLvRole:GetRole():GetName() )
    --                 end
    --             end
    --         end
    --         return newText
    --     end
    --     return originalText
    -- end
end

function Title:SetTitleShow(uiTexture, uiSprite, uiLabel)
    local showtype = self:GetDisplayType()

    if showtype == cfg.role.TitleShowType.Text then
        uiTexture.gameObject:SetActive(false)
        -- uiSprite.gameObject:SetActive(false)
        uiLabel.gameObject:SetActive(true)
        uiLabel.text = Title.GetTextColor(self.m_Character)..self:GetTexturePath().."[-]"
    elseif showtype == cfg.role.TitleShowType.SpliceText then
        uiTexture.gameObject:SetActive(false)
        -- uiSprite.gameObject:SetActive(false)
        uiLabel.gameObject:SetActive(true)
        uiLabel.text = self:GetSpliceText()
    elseif showtype == cfg.role.TitleShowType.Sprite then
        uiTexture.gameObject:SetActive(false)
        -- uiSprite.gameObject:SetActive(true)
        uiLabel.gameObject:SetActive(false)

        uiSprite.spriteName = self:GetTexturePath()

    elseif showtype == cfg.role.TitleShowType.Texture then
        uiTexture.gameObject:SetActive(true)
        -- uiSprite.gameObject:SetActive(false)
        uiLabel.gameObject:SetActive(false)

        uiTexture:SetIconTexture(self:GetTexturePath())

    elseif showtype == cfg.role.TitleShowType.Prefab then
        uiTexture.gameObject:SetActive(true)
        -- uiSprite.gameObject:SetActive(false)
        uiLabel.gameObject:SetActive(false)

        uiTexture:SetIconTexture("")
        uiTexture.gameObject:SetActive(true)
        local exTrans = uiTexture.gameObject.transform:Find("Title_Empty")
        local trans = uiTexture.gameObject.transform:Find("dlgheadtitle/UIList_Title")
        if exTrans == nil then
            self:LoadTitle(uiTexture.gameObject)
        else
            self:SetTitle(trans)
        end
    end
end

return Title
