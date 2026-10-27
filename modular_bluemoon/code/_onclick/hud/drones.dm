/datum/hud/dextrous/drone/New(mob/owner)
	. = ..()
	var/atom/movable/screen/using

	using = new /atom/movable/screen/language_menu(null, src)
	using.icon = ui_style
	static_inventory += using
