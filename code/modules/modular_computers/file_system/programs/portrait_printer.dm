
///how much paper it takes from the printer to create a canvas.
#define CANVAS_PAPER_COST 5

/**
 * ## portrait printer!
 *
 * Program that lets the curator browse all of the portraits in the database
 * They are free to print them out as they please.
 */
/datum/computer_file/program/portrait_printer
	filename = "PortraitPrinter"
	filedesc = "Marlowe Treeby's Art Galaxy"
	category = PROGRAM_CATEGORY_CREW
	program_icon_state = "dummy"
	extended_desc = "This program connects to a Spinward Sector community art site for viewing and printing art."
	//transfer_access = ACCESS_LIBRARY // BLUEMOON EDIT commented
	usage_flags = PROGRAM_CONSOLE
	requires_ntnet = TRUE
	size = 9
	tgui_id = "NtosPortraitPrinter"
	program_icon = "paint-brush"

/datum/computer_file/program/portrait_printer/ui_data(mob/user)
	var/list/data = list()
	// BLUEMOON EDIT START
	var/static/list/categorys = list("library", "library_secure", "library_private", "library_large", "library_large_private")
	for(var/category_name in categorys)
		data[category_name] = SSpersistence.paintings[category_name]
	data["favorite_paintings_md5"] = user?.client?.prefs?.favorite_paintings_md5
	// BLUEMOON EDIT END
	return data

/datum/computer_file/program/portrait_printer/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/portraits/library),
		get_asset_datum(/datum/asset/simple/portraits/library_secure),
		get_asset_datum(/datum/asset/simple/portraits/library_private),
		get_asset_datum(/datum/asset/simple/portraits/library_large),
		get_asset_datum(/datum/asset/simple/portraits/library_large_private)
	)

/datum/computer_file/program/portrait_printer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	//BLUEMOON EDIT START
	switch(action)
		if("toggle_favorite")
			var/mob/living/L = usr
			if(!L?.client?.prefs)
				return
			var/md5 = params["md5"]
			if(!md5)
				return

			var/list/favorite_paintings_md5 = L.client.prefs.favorite_paintings_md5
			if(md5 in favorite_paintings_md5)
				favorite_paintings_md5 -= md5
			else
				favorite_paintings_md5 += md5

			L.client.prefs.save_preferences()

			return TRUE
		if("select")
			//printer check!
			var/obj/item/computer_hardware/printer/printer
			if(computer)
				printer = computer.all_components[MC_PRINT]
			if(!printer)
				to_chat(usr, span_notice("Hardware error: A printer is required to print a canvas."))
				return
			if(printer.stored_paper < CANVAS_PAPER_COST)
				to_chat(usr, span_notice("Printing error: Your printer needs at least [CANVAS_PAPER_COST] paper to print a canvas."))
				return
			printer.stored_paper -= CANVAS_PAPER_COST

			//canvas printing!
			var/asset_prefix = params["asset_prefix"]
			var/md5 = params["md5"]
			var/list/current_list = SSpersistence.paintings[asset_prefix]
			if(!current_list)
				return
			var/list/chosen_portrait
			for(var/i in 1 to current_list.len)
				var/list/entry = current_list[i]
				if(entry["md5"] == md5)
					chosen_portrait = entry
					break
			if(!chosen_portrait)
				return
			var/title = chosen_portrait["title"]
			var/png = "data/paintings/[asset_prefix]/[chosen_portrait["md5"]].png"
			var/icon/art_icon = new(png)
			var/obj/item/canvas/printed_canvas
			var/art_width = art_icon.Width()
			var/art_height = art_icon.Height()
			for(var/canvas_type in typesof(/obj/item/canvas))
				printed_canvas = canvas_type
				if(initial(printed_canvas.width) == art_width && initial(printed_canvas.height) == art_height)
					printed_canvas = new canvas_type(get_turf(computer.physical))
					break
			printed_canvas.fill_grid_from_icon(art_icon)
			printed_canvas.generated_icon = art_icon
			printed_canvas.icon_generated = TRUE
			printed_canvas.finalized = TRUE
			printed_canvas.painting_name = title
			printed_canvas.author_ckey = chosen_portrait["author"]
			printed_canvas.name = "painting - [title]"
			///this is a copy of something that is already in the database- it should not be able to be saved.
			printed_canvas.no_save = TRUE
			printed_canvas.update_icon()
			to_chat(usr, span_notice("You have printed [title] onto a new canvas."))
			playsound(computer.physical, 'sound/items/poster_being_created.ogg', 100, TRUE)
			return TRUE
	//BLUEMOON EDIT END
