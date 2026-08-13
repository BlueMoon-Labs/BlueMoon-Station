GLOBAL_DATUM_INIT(medals_view_tgui, /datum/medals_view_tgui, new)

/datum/medals_view_tgui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MedalsViewer", "[user.ckey]'s Medals")
		ui.open()

/datum/medals_view_tgui/ui_static_data(mob/user)
	. = ..()
	.["medals"] = list()

	for(var/list/medal in SSpersistence.medals)
		if(medal["ckey"] != user.ckey)
			continue
		.["medals"] += list(medal)

/datum/medals_view_tgui/ui_state(mob/user)
	return GLOB.always_state

/datum/medals_view_tgui/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/medal)
	)

/client/verb/view_own_medals()
	set name = "View Own Medals"
	set category = "OOC"

	GLOB.medals_view_tgui.ui_interact(mob)

/datum/asset/spritesheet/medal
	name = "medal"

/datum/asset/spritesheet/medal/register()
	for(var/obj/item/clothing/accessory/medal/medal as anything in subtypesof(/obj/item/clothing/accessory/medal))
		var/icon/current_icon = icon(initial(medal.icon), initial(medal.icon_state), SOUTH)
		var/imgid = replacetext("[initial(medal.name)]", " ", "-")

		Insert(imgid, current_icon)
	return ..()
