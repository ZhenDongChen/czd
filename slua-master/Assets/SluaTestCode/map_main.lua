
local function init_model()
	
	modelManager:modelManagerInit()

end

--����ȫ�ֵĺ�����C#���ǵ��ò�����
function init()

	init_model();
	print("Slua init")

end


function Update()

	modelManager:modelManagerupdate()
	--print("Update init")

end

