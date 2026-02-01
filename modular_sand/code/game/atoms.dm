/atom/emag_act()
	. = ..()
	if(. && usr)
		balloon_alert(usr, span_balloon_warning("emagged"))
