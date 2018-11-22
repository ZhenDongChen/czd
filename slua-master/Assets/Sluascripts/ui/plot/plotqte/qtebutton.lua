

local QteButton = Class:new()

function QteButton:__new(buttonCfg, number)
    self.m_Mode = buttonCfg.mode
    self.m_Number = number
    self.m_MaxCount = buttonCfg.count
    self.m_Position = Vector2(buttonCfg.posx, buttonCfg.posy)
    self.m_UIItem = nil
    self.m_Button = nil
    self.m_Count = 0
    self.m_IsStart = false
    self.m_IsFinish = false
    self.m_ListNumber = 1
    self.m_Clicked = false

    self.m_FinishTime = -1
end

function QteButton:SetUIItem(uiItem)
    self.m_UIItem = uiItem
end

function QteButton:SetButton(button)
    self.m_Button = button
    self.m_Button.gameObject:SetActive(true)
end

function QteButton:SetListNumber(num)
    self.m_ListNumber = num
end

function QteButton:IsStart()
    return self.m_IsStart
end

function QteButton:Start()
    self.m_IsStart = true
    self.m_UIItem.gameObject:SetActive(true)
end

function QteButton:SetFinfish()
    self.m_IsFinish = true
    self.m_UIItem.gameObject:SetActive(false)
end

function QteButton:OnClick(set)
    self.m_Clicked = true
    self.m_Count = self.m_Count + 1
    if self.m_Mode == cfg.plot.QTEModeType.Combo then
        if self:IsFinish() then
            self.m_Button.gameObject:SetActive(false)
        end
    else
        self.m_Button.gameObject:SetActive(false)
        self.m_FinishTime = 0.5
    end
end

function QteButton:Update()
    if self:CanNext() then
        self.m_FinishTime = self.m_FinishTime - UnityEngine.Time.unscaledDeltaTime
        if self.m_FinishTime < 0 then
            self:SetFinfish()
        end
    end
end


function QteButton:GetPosition()
    return self.m_Position
end

function QteButton:IsFinish()
    if self.m_Mode == cfg.plot.QTEModeType.Combo then
        if self.m_Count >= self.m_MaxCount then
            return true
        else
            return false
        end
    else
        return self.m_IsFinish
    end
end



function QteButton:CanNext()
    if self.m_Mode == cfg.plot.QTEModeType.Combo then
        return self:IsFinish()
    else
        return self.m_Clicked
    end
end

return QteButton