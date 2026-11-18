/datum/component/uplink/inteq
	name = "InteQ Uplink"

/datum/component/uplink/inteq/ui_interact(mob/user, datum/tgui/ui)
	active = TRUE
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "UplinkInteQ", name)
		// This UI is only ever opened by one person,
		// and never is updated outside of user input.
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/component/uplink/syndicate
	name = "Uplink"

/datum/component/uplink/syndicate/ui_interact(mob/user, datum/tgui/ui)
	active = TRUE
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Uplink", name)
		// This UI is only ever opened by one person,
		// and never is updated outside of user input.
		ui.set_autoupdate(FALSE)
		ui.open()
