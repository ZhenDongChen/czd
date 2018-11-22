local unpack, print = unpack, print
local math = math
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")

local name, gameObject, fields

local countDownTime = -10

local lastCount = nil

local function destroy()

end

local function hide()
    countDownTime = -10
end

local function CountDown(timeInt)
    fields.UIGroup_Stage2.gameObject:SetActive(true)
    if timeInt >= 1 then
        fields.UILabel_CountDown2.gameObject:SetActive(true)
        fields.UIPlayTweens_Start.gameObject:SetActive(false)
        fields.UILabel_CountDown2.text = tostring(timeInt)
    end
    if timeInt == 0 then
        fields.UILabel_CountDown2.gameObject:SetActive(false)
    end
    if timeInt == 0 then
        fields.UIPlayTweens_Start.gameObject:SetActive(true)
        fields.UIPlayTweens_Start:Play(true)
    end

--[[
    if timeInt > 10 then
        fields.UIGroup_Stage3.gameObject:SetActive(true)
        fields.UIGroup_Stage2.gameObject:SetActive(false)
        fields.UIGroup_Stage1.gameObject:SetActive(false)
        
        fields.UILabel_CountDown1.text = tostring(timeInt)
    elseif timeInt > 3 then
        fields.UIGroup_Stage3.gameObject:SetActive(false)
        fields.UIGroup_Stage2.gameObject:SetActive(true)
        fields.UIGroup_Stage1.gameObject:SetActive(false)
        
        
    else
        fields.UIGroup_Stage3.gameObject:SetActive(false)
        fields.UIGroup_Stage2.gameObject:SetActive(false)
        fields.UIGroup_Stage1.gameObject:SetActive(true)
        
        if timeInt == 3 then
            fields.UIPlayTweens_3.gameObject:SetActive(true)
            fields.UIPlayTweens_3:Play(true)
        elseif timeInt == 2 then
            fields.UIPlayTweens_2.gameObject:SetActive(true)           
            fields.UIPlayTweens_2:Play(true)
        elseif timeInt == 1 then
            fields.UIPlayTweens_1.gameObject:SetActive(true)            
            fields.UIPlayTweens_1:Play(true)
        else

        end
    end
    ]]
end

local function update()
    countDownTime = countDownTime - Time.deltaTime
    if countDownTime < -3 then
        UIManager.hide(name)
    end
    if countDownTime < 0 then
        return
    end

    local timeInt = math.floor( countDownTime )
    
    if timeInt ~= lastCount then
        CountDown(timeInt)
        lastCount = timeInt
    end
end

local function late_update()

end

local function refresh(params)

end

local function show(params)
    if params.countDownTime == nil then
        UIManager.hide(name)
    end
    countDownTime = params.countDownTime
    lastCount = nil
    fields.UIGroup_Stage3.gameObject:SetActive(false)
    fields.UIGroup_Stage2.gameObject:SetActive(false)
    fields.UIGroup_Stage1.gameObject:SetActive(false)
    
    fields.UIPlayTweens_3.gameObject:SetActive(false)
    fields.UIPlayTweens_2.gameObject:SetActive(false)
    fields.UIPlayTweens_1.gameObject:SetActive(false)
    fields.UIPlayTweens_Start.gameObject:SetActive(false)
end


local function init(params)
    name, gameObject, fields = unpack(params)
    
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    late_update = late_update,
    destroy = destroy,
    refresh = refresh,
}
