
-- 颜色配置是根据\luxianres\Design\10_美术资源需求与管理\UI需求\字体类效果需求\字体颜色汇总.png配置的
local ColorType = 
{
    White          = 0,
    Green          = 1,
    Blue           = 2,
    Purple         = 3,
    Orange         = 4,
    Red_Item       = 5,
    Red_Character  = 6,
    Gray           = 7,
    Black          = 8,
    Yellow         = 9,
    Orange2        = 10,
    Gray2          = 11,
	Green_Tip	   = 12,
	Yellow_Title   = 13,
	Red	           = 14,
	Orange_Chat    = 15,
	Pink_Chat      = 16,
	Pink_Task	   = 17,
	Blue_Chat      = 18,
	Blue_Task      = 19,
	Green_Chat     = 20,
	Green_Task     = 21,

	Green_Remind   = 22,
	Red_Remind     = 23,
	Red_Award      = 24,
	RoleinfoRed    = 25,
	RoleinfoGreen  = 26,
	RoleinfoOrange = 27,


	Chat_System = 28,
	Chat_Me = 29,
	Chat_Family = 30,
	Chat_World = 31,
	Chat_Private = 32,
	Chat_Team = 33,
}



local ColorStringTable = 
{
    [ColorType.White]          = "[FEFFF0]%s[-]",
    [ColorType.Green]          = "[357700FF]%s[-]",
	[ColorType.Green_Tip]      = "[9AFE19]%s[-]",
	[ColorType.Green_Chat]     = "[A5DF7F]%s[-]",
	[ColorType.Green_Task]     = "[B7F244]%s[-]",
	[ColorType.Blue]           = "[26BEFE]%s[-]",
    [ColorType.Blue_Chat]      = "[4EDDF7]%s[-]",
	[ColorType.Blue_Task]      = "[4EDDF7]%s[-]",
    [ColorType.Purple]         = "[F43E87]%s[-]",
    [ColorType.Orange]         = "[F48E21]%s[-]",
	[ColorType.Orange_Chat]    = "[FFBA25]%s[-]",
	[ColorType.Pink_Chat]      = "[FD73C1]%s[-]",
	[ColorType.Pink_Task]      = "[FF5FF9]%s[-]",
	[ColorType.Red]            = "[FA4926]%s[-]",
    [ColorType.Red_Item]       = "[E9392C]%s[-]",
    [ColorType.Red_Character]  = "[FF4A4AFF]%s[-]",
    [ColorType.Gray]           = "[A8B1B5]%s[-]",
    [ColorType.Black]          = "[0D151C]%s[-]",
    [ColorType.Yellow]         = "[FFD74C]%s[-]",
	[ColorType.Yellow_Title]   = "[FFF354]%s[-]",
    [ColorType.Orange2]        = "[6BF520]%s[-]",
    [ColorType.Gray2]          = "[979FA2]%s[-]",
	[ColorType.Red_Award]      = "[d1502f]%s[-]",
	[ColorType.RoleinfoRed]    = "[ff0000]%s[-]",
	[ColorType.RoleinfoGreen]  = "[27970e]%s[-]",
	[ColorType.RoleinfoOrange] = "[D14826FF]%s[-]",

	[ColorType.Chat_System] = "[ff0000FF]%s[-]",
	[ColorType.Chat_Me] = "[fffaf8FF]%s[-]",
	[ColorType.Chat_Family] = "[ffcc00FF]%s[-]",
	[ColorType.Chat_World] = "[ffa94cFF]%s[-]",
	[ColorType.Chat_Private] = "[ff6afdFF]%s[-]",
	[ColorType.Chat_Team] = "[45bafdFF]%s[-]",

}

local ColorValueTable = {
	[ColorType.Green_Remind] 	    = Color(154/255, 254/255, 25/255, 1),
	[ColorType.Red_Remind] 		    = Color(250/255, 73/255, 38/255, 1),
	[ColorType.White] 		        = Color(254/255, 255/255, 240/255, 1),
	[ColorType.Gray] 		        = Color(168/255, 177/255, 181/255, 1),
	[ColorType.Yellow_Title] 		= Color(255/255, 243/255, 84/255, 1),
}
local ShadowColorValueTable = {
	[ColorType.Green_Remind] 	    = Color(17/255, 44/255, 62/255, 1),
	[ColorType.Red_Remind] 		    = Color(75/255, 13/255, 9/255, 1), 
	[ColorType.White] 		        = Color(12/255, 32/255, 46/255, 1),
	[ColorType.Gray] 		        = Color(37/255, 44/255, 51/255, 1),
	[ColorType.Yellow_Title] 		= Color(20/255, 21/255, 39/255, 1),
}


-- 仅适用于品质框
local QualityBoxColor = 
{
	[cfg.item.EItemColor.WHITE]  = Color(125/255, 62/255, 47/255, 1),
	[cfg.item.EItemColor.GREEN]  = Color(41 / 255, 1, 78 / 255, 1),
	[cfg.item.EItemColor.BLUE]   = Color(110 / 255, 214 / 255, 249 / 255, 1),
	[cfg.item.EItemColor.PURPLE] = Color(221 / 255, 130 / 255, 253 / 255, 1),
	[cfg.item.EItemColor.ORANGE] = Color(1, 164 / 255, 0, 1),
	[cfg.item.EItemColor.RED]    = Color(255 / 255, 0 / 255, 0 / 255, 1),
}

-- 仅适用于品质相关字体描边
local OutlineColor = 
{
	[cfg.item.EItemColor.WHITE]  = Color(142 / 255, 86 / 255, 75 / 255, 1),
	[cfg.item.EItemColor.GREEN]  = Color(64 / 255, 86 / 255, 48 / 255, 1),
	[cfg.item.EItemColor.BLUE]   = Color(47 / 255, 76 / 255, 79 / 255, 1),
	[cfg.item.EItemColor.PURPLE] = Color(102 / 255, 62 / 255, 98 / 255, 1),
	[cfg.item.EItemColor.ORANGE] = Color(103 / 255, 57 / 255, 36 / 255, 1),
	[cfg.item.EItemColor.RED]    = Color(101 / 255, 27 / 255, 17 / 255, 28/255),
}
-- 仅适用于品质属性文字
local QualityColorText = 
{
	[cfg.item.EItemColor.WHITE]  = "[FFFFFFFF]%s[-]",
	[cfg.item.EItemColor.GREEN]  = "[00FF00]%s[-]",
	[cfg.item.EItemColor.BLUE]   = "[00D2FF]%s[-]",
	[cfg.item.EItemColor.PURPLE] = "[FA00EE]%s[-]",
	[cfg.item.EItemColor.ORANGE] = "[FF783D]%s[-]",    
	[cfg.item.EItemColor.RED]    = "[FF0000]%s[-]",
}
--主界面主角hp值变化
local RoleHpColor = 
{
  [cfg.item.EItemColor.GREEN] = Color(0,1,0,1),
  [cfg.item.EItemColor.PURPLE] = Color(1,235 / 255,4 / 255,1),
  [cfg.item.EItemColor.ORANGE] = Color(1,134 / 255,0,1),
  [cfg.item.EItemColor.RED] = Color(1,0,0,1),
}

-- 仅适用于品质框
local QualitySprite = 
{
	[cfg.item.EItemColor.WHITE]  = "N_CoverweapongrayFram",
	[cfg.item.EItemColor.GREEN]  = "N_CoverGreenFram",
	[cfg.item.EItemColor.BLUE]   = "N_CoverBlueFram",
	[cfg.item.EItemColor.PURPLE] = "N_CoverPurpleFram",
	[cfg.item.EItemColor.ORANGE] = "N_CoverYellowFram",
	[cfg.item.EItemColor.RED]    = "N_CoverRedFram",
}

-- 仅适用于圆形品质框
local QualitySpriteYuan = 
{
	[cfg.item.EItemColor.WHITE]  = "N_Frame_Grey",
	[cfg.item.EItemColor.GREEN]  = "N_Frame_Green",
	[cfg.item.EItemColor.BLUE]   = "N_Frame_Blue",
	[cfg.item.EItemColor.PURPLE] = "N_Frame_PurpleRed",
	[cfg.item.EItemColor.ORANGE] = "N_Frame_Orange",
	[cfg.item.EItemColor.RED]    = "N_Frame_Red",
}



-- 根据品质类型返回品质颜色
local function GetQualityColor(quality)
	if quality then
		if QualityBoxColor[quality] then 
			return QualityBoxColor[quality]
		else
			logError("Item quality error")
			return Color(255 / 255, 255 / 255, 255 / 255, 1)
		end
	else
		return Color(255 / 255, 255 / 255, 255 / 255, 1)
	end
end

-- 根据品质类型返回相应颜色文本
local function GetQualityColorText(quality,originalText)
	if QualityColorText[quality] then 
		return string.format(QualityColorText[quality],originalText)
	else
		logError("Item quality error")
		return originalText
	end
end
-- 此函数将描边和字体颜色一起设置
local function SetQualityColorText(uiLabel,quality,originalText)
	if QualityColorText[quality] then 
		uiLabel.text = string.format(QualityColorText[quality],originalText)
	    uiLabel.effectColor = OutlineColor[quality]
	else
		uiLabel.text = originalText
		logError("Item quality error")
	end
end
-- 文字颜色和描边置成灰色
local function SetTextColor2Gray(uiLabel,originalText)
	uiLabel.text = string.format(ColorStringTable[ColorType.Gray],originalText)
	uiLabel.effectColor = ShadowColorValueTable[ColorType.Gray]
end

local function SetLabelColorText(uiLabel, colorType, content)
	uiLabel.text = tostring(content)
	if ColorValueTable[colorType] and ShadowColorValueTable[colorType] then
		uiLabel.color = ColorValueTable[colorType]
		uiLabel.effectColor = ShadowColorValueTable[colorType]
	else
		logError("Can't find value of color type.'")
	end
end

local function GetColorStr(colorType, str)
    return string.format(ColorStringTable[colorType], str)
end

local function GetQualityStr(quality)
    local color = GetQualityColor(quality)
    local colorstr = string.format("%x",math.round(color.r*255*256*256+color.g*255*256+color.b*255))
    return colorstr
end



local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")

local function SetTextureColorGray(uiTexture, isGray)
    if isGray then
        uiTexture.shader = inactiveShader
    else
        uiTexture.shader = activeShader
    end
end


---品质底宽
local function GetQualitySprite(quality)
	if quality then 
		return QualitySprite[quality] 
	else
		return QualitySprite[cfg.item.EItemColor.WHITE]
	end 
end

---元神品质底宽
local function GetQualitySpriteYuan(quality)
	if quality then 
		return QualitySpriteYuan[quality] 
	else
		return "N_Frame_Gold"
	end 
end


return {
    ColorType            = ColorType,
    GetColorStr          = GetColorStr,
	GetQualityStr		 = GetQualityStr,
	GetQualityColorText  = GetQualityColorText,
	GetQualityColor      = GetQualityColor,
	SetQualityColorText  = SetQualityColorText,
	SetTextColor2Gray	 = SetTextColor2Gray,
	SetTextureColorGray  = SetTextureColorGray,
	SetLabelColorText    = SetLabelColorText,
	GetQualitySprite     = GetQualitySprite,
	GetQualitySpriteYuan = GetQualitySpriteYuan,
	RoleHpColor = RoleHpColor,
}