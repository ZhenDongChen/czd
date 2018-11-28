local BagManager = require("character.bagmanager")
local ItemEnum = require("item.itemenum")
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")

local PageTalismanBag = {
    SelectState = false
}



function PageTalismanBag:refresh(talisman)
    if not UIManager.isshow("playerrole.talisman.tabtalisman") then
        return
    end
    if UIManager.isshow("playerrole.bag.tabbag") then
        UIManager.refresh("playerrole.bag.tabbag",{BagSelectMenu = false, BagSelectIndex = cfg.bag.BagType.TALISMAN })
    else
        UIManager.showtab("playerrole.bag.tabbag",{BagSelectMenu = false, BagSelectIndex = cfg.bag.BagType.TALISMAN })
    end
end

function PageTalismanBag:show()
    if not UIManager.isshow("playerrole.talisman.tabtalisman") then
        return
    end
    if UIManager.isshow("playerrole.bag.tabbag") then
        UIManager.refresh("playerrole.bag.tabbag",{BagSelectMenu = false, BagSelectIndex = cfg.bag.BagType.TALISMAN })
    else
        UIManager.showtab("playerrole.bag.tabbag",{BagSelectMenu = false, BagSelectIndex = cfg.bag.BagType.TALISMAN })
    end
end

function PageTalismanBag:update()

end


function PageTalismanBag:hide()
    if UIManager.isshow("playerrole.bag.tabbag") then
        UIManager.hidetab("playerrole.bag.tabbag")
    end
end

function PageTalismanBag:init(name, gameObject, fields)
    self.fields = fields
end

return PageTalismanBag
