
local function init_model()
	
	modelManager:modelManagerInit()

end

--不是全局的函数在C#中是调用不到的
function init()

	init_model();
	print("Slua init")

end


function Update()

	modelManager:modelManagerupdate()
	--print("Update init")

end

