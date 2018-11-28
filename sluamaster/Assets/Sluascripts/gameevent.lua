local event              = require "common.event"

local evt_update         = event.new_simple("evt_update")
local evt_late_update    = event.new_simple("evt_late_update")
local evt_late_update2	 = event.new_simple("evt_late_update2")

local evt_second_update  = event.new_simple("evt_second_update")
local evt_cdchange       = event.new_simple("evt_cdchange")
local evt_limitchange    = event.new_simple("evt_limitchange")
local evt_resetnewstatus = event.new_simple("evt_resetnewstatus")
local evt_fixed_update 	 = event.new_simple("evt_fixed_update")
local evt_system_message = event:new("evt_system_message")
local evt_dlgdialogrefresh = event.new_simple("evt_dlgdialogrefresh")
local evt_notify		 = event:new("evt_notify")

return {
	evt_update          = evt_update,
	evt_late_update     = evt_late_update,
	evt_late_update2	= evt_late_update2,
	evt_fixed_update	= evt_fixed_update,
	evt_second_update   = evt_second_update,
	evt_cdchange		= evt_cdchange,
	evt_limitchange		= evt_limitchange,
	evt_resetnewstatus	= evt_resetnewstatus,

	evt_system_message  = evt_system_message,
    evt_dlgdialogrefresh = evt_dlgdialogrefresh,

	evt_notify			= evt_notify,
}
