

local characters = {}

local function update()
    for _, char in pairs(characters) do
        if char.m_Avatar then
            char.m_Avatar:Update()
        end
    end
end

local function AddCharacter(char)
    while characters[char.m_Id] ~= nil do
        char.m_Id = char.m_Id + 1
    end
    characters[char.m_Id] = char
    return char
end

local function RemoveCharacter(id)
    character[id] = nil
end


local function init()

end

return {
    update = update,
    init = init,
    AddCharacter = AddCharacter,
    RemoveCharacter = RemoveCharacter,
}