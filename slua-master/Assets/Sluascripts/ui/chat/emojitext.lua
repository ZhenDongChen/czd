--------------------------------------------------------
--- 图文混排，
--- 输入text, emoji以[xx]标记，然后isemojifunc(xx)为true，则视为emoji
--- 输出text_with_space和一个emoji_with_space

local tagstartbyte = string.byte("[", 1)
local tagendbyte = string.byte("]", 1)

local function _charbytesAndFirstByte(s, i)
    local c = string.byte(s, i)

    -- determine bytes needed for character, based on RFC 3629
    if c > 0 and c <= 127 then
        -- UTF8-1
        return 1, c
    elseif c >= 194 and c <= 223 then
        -- UTF8-2
        return 2, c
    elseif c >= 224 and c <= 239 then
        -- UTF8-3
        return 3, c
    elseif c >= 240 and c <= 244 then
        -- UTF8-4
        return 4, c
    end
end


local emojitext = {}

--------------------------------------------------------
--- 保证emoji的高度+emoji的行间间距 也正好是 text的高度和text的行间距
--- emojiconvertfunc(emoji) emoji返回使用font的emoji字符串
function emojitext:New(maxlinew, txt_calcstrwidth_func, emoji_calcstrwidth_func, isemojifunc, emojiconvertfunc)
    local instance = {}
    setmetatable(instance, self)
    self.__index = self
    instance.maxlinew = maxlinew
    instance.txt_calcstrwidth_func = txt_calcstrwidth_func
    instance.emoji_calcstrwidth_func = emoji_calcstrwidth_func

    instance.isemojifunc = isemojifunc
    instance.emojiconvertfunc = emojiconvertfunc
    return instance
end

--------------------------------------------------------
-------- 这个只用状态机解析文本
function emojitext:Parse(text, is_right2left)
    self.is_right2left = is_right2left

    --- 这2个是返回值，使用里面的txt就行了
    self.txtresult = { has = false,  txt = "", curline = "", calc = self.txt_calcstrwidth_func }
    self.emjresult = { has = false,  txt = "", curline = "", calc = self.emoji_calcstrwidth_func }

    self.curlinew = 0
    self.multiline = false
    self.lastresult = nil
    self.lastother = nil

    local i = 1
    local len = #text
    local state = "out"
    local state_in_startidx = 1
    local state_in_last_startidx = 1
    local state_out_startidx = 1

    while true do
        if i > len then
            if state == "out" then
                self:_addNoramlText(text, state_out_startidx, len)
            else
                self:_addNoramlText(text, state_in_startidx, len)
            end
            break
        end

        local cnt, c = _charbytesAndFirstByte(text, i)
        if state == "out" then
            if c == tagstartbyte then
                state = "in"
                self:_addNoramlText(text, state_out_startidx, i-1)
                state_in_startidx = i
                state_in_last_startidx = i
            end
        else
            if c == tagstartbyte then
                state = "in"
                state_in_last_startidx = i
            elseif c == tagendbyte then
                local emojiid = string.sub(text, state_in_last_startidx + 1, i-1)
                if self.isemojifunc(emojiid) then
                    self:_addNoramlText(text, state_in_startidx, state_in_last_startidx - 1)
                    self:_addEmojiid(emojiid)
                else
                    self:_addNoramlText(text, state_in_startidx, i)
                end
                state = "out"
                state_out_startidx = i + 1
            end
        end
        i = i + cnt
    end
    self:_fix(self.txtresult)
    self:_fix(self.emjresult)
end


function emojitext:_addNoramlText(text, starti, includedendi)
    --print("addnormal", string.sub(text, starti, includedendi))
    local i = starti
    while i <= includedendi do
        local cnt, c = _charbytesAndFirstByte(text, i)
        local char = string.sub(text, i, i+cnt-1)
        self:_addChar(char, self.txtresult, self.emjresult)
        i = i + cnt
    end
end

function emojitext:_addEmojiid(emojiid)
    local symbol = self.emojiconvertfunc(emojiid)
    self:_addChar(symbol, self.emjresult, self.txtresult)
end

--------------------------------------------------------
-------- 这里加空格和换行
function emojitext:_addChar(char, result, other)
    self.lastresult = result
    self.lastother = other
    result.has = true
    self:_padspace(self.curlinew, result)
    local tmp = result.curline..char
    local tmpw = result.calc(tmp)
    if  tmpw <= self.maxlinew then
        result.curline = tmp
        self.curlinew = tmpw
    else
        ---换行
        self:_newline(result)
        self:_newline(other)
        self:_addChar(char, result, other)
    end
end

function emojitext:_newline(result)
    self.multiline = true
    self.curlinew = 0
    if self.is_right2left then
        self:_padspace(self.maxlinew, result)
    end
    result.txt = result.txt..result.curline.."\n"
    result.curline = ""
end

function emojitext:_padspace(towidth, result)
    local tmp = result.curline
    while true do
        local w = result.calc(tmp)
        if w <= towidth and w <= self.maxlinew then
            result.curline = tmp
            tmp = tmp.." "
            if w == towidth then
                break
            end
        else
            if w > towidth and w <= self.maxlinew then
                result.curline  = tmp
            end
            break
        end
    end
end

function emojitext:_fix(result)
    if self.is_right2left and self.lastother and self.lastother.has then
        self:_padspace(self.curlinew, self.lastother)
    end
    result.txt = result.txt..result.curline
    result.curline = ""
end


--------------------------------------------------------
--- 测试
local function parse(et, a, is_right2left)
    print(a)
    et:Parse(a, is_right2left)
    print("----txt")
    print("#"..et.txtresult.txt.."#")
    print("----emj")
    print("#"..et.emjresult.txt.."#")

    print("==========")
    print()
end

local function test()
    local et = emojitext:New(200,
        function(txt) return #txt*10 end,
        function(emj) return #emj*15 end,
        function(e) return e=="abcd" end,
        function(e) return e end)
    --parse(et, "123[abc][abc]")
    --parse(et, "123456[abcd]aaa[abcd]456", true)
    --parse(et, "123[abc]123", false)
    --parse(et, "aa[abc]中国，[[[[emoji_123]]]]abc[[abc]]我爱图文混排[abc]")
end

--test()


return emojitext
