local unpack, print = unpack, print

local name, gameObject, fields



local function refresh(params)

end

local function update()

end

local function show(params)

end

local function hide()

end



local function init(params)
    name, gameObject, fields    = unpack(params)

end

local function destroy()

end


return {
  init                  = init,
  show                  = show,
  hide                  = hide,
  update                = update,
  destroy               = destroy,
  refresh               = refresh,

}




