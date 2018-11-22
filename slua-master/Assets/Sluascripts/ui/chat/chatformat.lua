local string = string
--local ConfigManager = require"cfg.configmanager"
local function GetColorCode(Type)    --获取品质的颜色
	if Type == cfg.item.EItemColor.WHITE then
		return "[E6EEF1]"
	elseif Type == cfg.item.EItemColor.GREEN then
		return "[C4EE1B]"
	elseif Type == cfg.item.EItemColor.BLUE then
		return "[26BEFE]"
	elseif Type == cfg.item.EItemColor.PURPLE then
		return "[F43E87]"
	elseif Type == cfg.item.EItemColor.ORANGE then
		return "[F48E21]"
	elseif Type == cfg.item.EItemColor.RED then
		return "[E9392C]"
	else
		return ""
	end
end


--local function ReplaceEmoji(emoji_name)
--	if emoji_name then
--		return "[".. string.sub(emoji_name,7,11).."]"
--	else
--		return ""
--	end
--end

local function RestoreEmoji(text)
end

local function RetainEmoji(str)
	local length = string.len(str)
	local tb = {}
	for i = 1,length do
		tb[i] = false
	end
	for index = 1,length do
		local a,b = string.find(str,"emoji_.....",index)
		if a and b then
			for index1 = a, b do
				tb[index1] = true
			end
			index = b + 1
		else
			break
		end
	end
	local str1 = ""

	for index = 1,length do
		if tb[index] then
			str1 = str1 .. string.sub(str,index,index)
		else
			str1 = str1.." "
		end
	end
	return str1
end

local function FormatChatItem(content,ItemTableChat)
    local format_str = content
--    local SenseWords = ConfigManager.getConfig("senseword")
--    printt(SenseWords)
--		for _,word in pairs(SenseWords.words) do
--			-- printyellow(word)
--		end
		-- printyellow("ItemTableChat")
		-- printt(ItemTableChat)
        for k,v in pairs (ItemTableChat) do
            local index = 1
			-- printyellow("ItemTableChat",ItemTableChat)
			-- printyellow("len",string.len(format_str))
            while index <= string.len(format_str) do
                local i,j = string.find(format_str, k ,index)
--				-- printyellow("k",k)
--				-- printyellow("i",i)
--		        -- printyellow("j",j)
                if i ~= nil and j ~= nil then
                    local item_index = string.sub(format_str,i,j) -- "eg. [bag1]"
					-- printyellow("key",item_index)
					local item =  ItemTableChat[item_index]
                    local str_a = string.sub(format_str,1,i - 1)
                    local str_b = GetColorCode(item.ConfigData.quality) .. "【"..item.ConfigData.displayname .."】"  --颜色  物品名称 加强等级
							if item.ConfigData.EquipmentType == itemnum.ItemBaseType.Equipment then          --如果是武器，则需加上加强等级
								str_b = str_b .. "+"..item.AnnealLevel
							end
					      str_b = str_b .. "[-]"
                    local str_c = string.sub(format_str,j + 1,string.len(format_str))
                    index = string.len(str_a .. str_b) + 1
                    format_str = str_a ..  str_b  .. str_c
                    -- printyellow("content")
                    -- printyellow(format_str)
                else
                    break
                end
            end
        end
    return format_str
end



return {
	FormatChatItem = FormatChatItem,
	GetColorCode = GetColorCode,
--	ReplaceEmoji = ReplaceEmoji,
	RetainEmoji = RetainEmoji,
}
