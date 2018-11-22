

local require = require

local model = require("model")


local function init_model()
	
	for _, modelItem in pairs(model) do
		print(modelItem)
		local mod = require(modelItem)
		mod.init()
	end

end

--不是全局的函数在C#中是调用不到的
function init()

	init_model();
	print("Slua init")

end


function Update()

	--print("Update init")

end

