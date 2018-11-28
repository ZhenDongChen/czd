
local listChatItem = {}

local function InitEmoji()
    local EmojiTable =
    {
        "1f44a" ,
        "1f44b" ,
        "1f44c" ,
        "1f44d" ,
        "1f44e" ,
        "1f44f" ,
        "1f601" ,
        "1f602" ,
        "1f603" ,
        "1f604" ,--10
        "1f605" ,
        "1f607" ,
        "1f608" ,
        "1f609" ,
        "1f60a" ,--15 ����С��������ʾ������
        "1f60b" ,
        "1f60c" ,
        "1f60d" ,
        "1f60e" ,
        "1f60f" ,
        "1f610" ,
        "1f611" ,
        "1f612" ,
        "1f613" ,
        "1f614" ,
        "1f615" ,
        "1f616" ,
        "1f618" ,
        "1f619" ,
        "1f61a" ,
        "1f61c" ,
        "1f61d" ,
        "1f61e" ,
        "1f61f" ,
        "1f620" ,
        "1f621" ,
        "1f622" ,
        "1f623" ,
        "1f624" ,
        "1f627" ,
        "1f628" ,
        "1f629" ,
        "1f62a" ,
        "1f62b" ,
        "1f62c" ,
        "1f62d" ,
        "1f62e" ,
        "1f630" ,
        "1f631" ,
        "1f632" ,--50
        "1f633" ,
        "1f634" ,
        "1f636" ,
        "1f637" ,
        "1f638" ,
        "1f639" ,
        "1f63a" ,
        "1f63b" ,
        "1f63c" ,
        "1f63d" ,
        "1f63e" ,
        "1f63f" ,
        "1f640" ,
        "1f64a" ,

    }
	return EmojiTable
end

local function InitFaceBY()  --BiYao zhaoliying
	local EmojiTable =
	{
		"Face_BY_001",
		"Face_BY_002",
		"Face_BY_003",
		"Face_BY_004",
		"Face_BY_005",
		"Face_BY_006",
		"Face_BY_007",
		"Face_BY_008",
		"Face_BY_009",
		"Face_BY_010",
		"Face_BY_011",
		"Face_BY_012",
		"Face_BY_013",
		"Face_BY_014",
		"Face_BY_015",
		"Face_BY_016",
		"Face_BY_017",
	}
	return EmojiTable
end

local function InitFaceLXQ() --LuXueQi yangzi
	local EmojiTable =
	{
		"Face_LXQ_001",
		"Face_LXQ_002",
		"Face_LXQ_003",
		"Face_LXQ_004",
		"Face_LXQ_005",
		"Face_LXQ_006",
		"Face_LXQ_007",
		"Face_LXQ_008",
		"Face_LXQ_009",
		"Face_LXQ_010",
		"Face_LXQ_011",
		"Face_LXQ_012",
		"Face_LXQ_013",
		"Face_LXQ_014",
		"Face_LXQ_015",
		"Face_LXQ_016",
		"Face_LXQ_017",
	}
	return EmojiTable
end

local function InitFaceZXF() --ZhangXiaoFeng liyifeng
	local EmojiTable =
	{
		"Face_ZXF_001",
		"Face_ZXF_002",
		"Face_ZXF_003",
		"Face_ZXF_004",
		"Face_ZXF_005",
		"Face_ZXF_006",
		"Face_ZXF_007",
		"Face_ZXF_008",
		"Face_ZXF_009",
		"Face_ZXF_010",
		"Face_ZXF_011",
		"Face_ZXF_012",
		"Face_ZXF_013",
		"Face_ZXF_014",
		"Face_ZXF_015",
		"Face_ZXF_016",
		"Face_ZXF_017",
	}
	return EmojiTable
end

local function CalcStrWidth(isemoji) 
	return function(str)
		if isemoji then
			NGUIText.fontSize = 32
		else
			NGUIText.fontSize = 24
		end
		NGUIText.fontStyle = 0
		NGUIText.finalSize = NGUIText.fontSize
		NGUIText.fontScale = 1
		NGUIText.pixelDensity = 1
		NGUIText.useSymbols = true
		if isemoji then
			NGUIText.bitmapFont = InitEngFontWidth.instance.bitmapFont
			listChatItem[4].text = str
			return listChatItem[4].printedSize.x
		else
			NGUIText.dynamicFont = InitEngFontWidth.instance.font
			listChatItem[3].text = str
			return listChatItem[3].printedSize.x
		end
		
	end

end


local function InitEngFontWidth2()
	NGUIText.fontSize = 20
	NGUIText.fontStyle = 0
	NGUIText.finalSize = NGUIText.fontSize
	NGUIText.fontScale = 1
	NGUIText.pixelDensity = 1


	local inst = InitEngFontWidth.instance

	NGUIText.dynamicFont = InitEngFontWidth.instance.font
	NGUIText.bitmapFont = nil

	for i = 1,256 do
--		printyellow("string",string.char(i))
		engfontw[i] = math.ceil(NGUIText.GetGlyphWidth(i - 1, 0))
--		printyellow("engfontw[i]",engfontw[i])
	end
end



local function IsEmojiFunc(content)  -- input "abcde" , output "true or false"
--	local length = string.len(content)
--	content = string.sub(content,2,length - 1)
	for _,emojiname in pairs(InitEmoji()) do
		if content == emojiname then
			return true
		end
	end 
	return false
end

local function EmojiConvertFunc(content)  -- input "[abcde]",output "emoji_abcde"
--	local length = string.len(content)
--	local emojiname = string.sub(content,2,length - 1)
	return "emoji_"..content
end

local function InitEmojiSprite(fields,index)
--	printyellow("InitEmojiSprite")
   local num
   local EmojiTable 
	if index == 0 then
		num = 17
		EmojiTable =   InitFaceZXF()
	elseif index == 1 then
		num = 17
		EmojiTable =   InitFaceBY()
	elseif index == 2 then
		num = 17
		EmojiTable =   InitFaceLXQ()
	elseif index == 3 then 
		num = 64
		EmojiTable =  InitEmoji()
	end 

	if index == 0 or index == 1 or index == 2 then
		fields.UIList_EmojiBig:Clear()
		local i
		for i = 1 , num do
		    fields.UIList_EmojiBig:AddListItem()
		end

		for i = 1 , num do
		    local Emoji = fields.UIList_EmojiBig:GetItemByIndex( i - 1 )

		    local EmojiUISprite = Emoji.gameObject:GetComponent(UISprite)
		    EmojiUISprite.spriteName = EmojiTable[i]
		end
	else
		fields.UIList_Emoji:Clear()
		local i
		for i = 1 , num do
		    fields.UIList_Emoji:AddListItem()
		end

		for i = 1 , num do
		    local Emoji = fields.UIList_Emoji:GetItemByIndex( i - 1 )

		    local EmojiUISprite = Emoji.gameObject:GetComponent(UISprite)
		    EmojiUISprite.spriteName = "emoji_"..EmojiTable[i]
		end
	end
	return EmojiTable
end

local function IsEmojiContext(content)
	local i,j = string.find(content,"emoji_")
	if i and j then
		return true
	else
		return false
	end
end




local function init()
end

return {
	InitEmojiSprite  = InitEmojiSprite,
	IsEmojiContext   = IsEmojiContext,
	IsEmojiFunc      = IsEmojiFunc,
	EmojiConvertFunc = EmojiConvertFunc,
	InitEngFontWidth = InitEngFontWidth2,
	CalcStrWidth = CalcStrWidth,
	listChatItem = listChatItem,
}