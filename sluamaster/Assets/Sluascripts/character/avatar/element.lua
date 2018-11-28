

local Element = Class:new()

function Element:__new()
    self.m_Object = nil
    self.m_ModelFile = ""
	self.m_ModelOriginalFile = ""
    self.m_LoadTaskID = 0
    self.m_ObjectType = 0
    self.m_ObjectID = 0
    self.m_bIsLoading = false
end

function Element:Release()
    self:RemoveTask(self.m_LoadTaskID)
    if self.m_Object then
        GameObject.Destroy(self.m_Object)
        self.m_Object=nil
    end
end

function Element:Add(filename)
    if self.m_bIsLoading then

    end
    self.m_ModelFile = filename
    self.m_bIsLoading = true
	--����C#�еļ��غ��������Ǽ����������෵�ض���
    self.m_LoadTaskID = Util.LoadAvatar(self.m_ModelFile,function(obj)
        self.m_bIsLoading = false
        if IsNull(obj) then
            printyellow("load avatar component \""..self.m_ModelFile.."\" failed!")
        else
            if not IsNull(self.m_Object) then

                GameObject.Destroy(self.m_Object)
                self.m_Object=nil
            end
            self.m_Object = GameObject.Instantiate(obj)
            if self.m_Object then
                SetDontDestroyOnLoad(self.m_Object.transform.gameObject)
                self.m_Object:SetActive(false)
            else
            end
        end
    end)
end

function Element:Remove()
    if self.m_bIsLoading then
        self:RemoveTask(self.m_LoadTaskID)
    end
    if self.m_Object then
        GameObject.Destroy(self.m_Object)
        self.m_Object=nil
    end
end

function Element:RemoveTask(taskID)
    Util.RemoveTask(taskID,function(obj)
        self.m_bIsLoading = false
        if IsNull(obj) then printyellow("load avatar component"..self.m_ModelFile.."failed!")
        else
            if self.m_Object then
                GameObject.Destroy(self.m_Object)
                self.m_Object=nil
            end
            self.m_Object = GameObject.Instantiate(obj)
            if self.m_Object then
                SetDontDestroyOnLoad(self.m_Object.transform.gameObject)
                self.m_Object:SetActive(false)
            end
        end
    end)
end

return Element
