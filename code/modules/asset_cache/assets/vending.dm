
/datum/asset/spritesheet/vending
	name = "vending"

/datum/asset/spritesheet/vending/register()
	for (var/k in GLOB.vending_products)
		var/atom/item = k
		if (!ispath(item, /atom))
			continue

		var/icon_file
		//if (initial(item.greyscale_colors) && initial(item.greyscale_config))
		//	icon_file = SSgreyscale.GetColoredIconByType(initial(item.greyscale_config), initial(item.greyscale_colors))
		//else
		icon_file = initial(item.icon)
		var/icon_state = initial(item.icon_state)

		// BLUEMOON EDIT - Vending Update: skip items with missing icon state instead of crashing (CI)
		#ifdef UNIT_TESTS
		var/icon_states_list = icon_states(icon_file)
		if (!(icon_state in icon_states_list))
			continue
		#endif

		var/icon/I = icon(icon_file, icon_state, SOUTH)
		var/c = initial(item.color)
		if (!isnull(c) && c != "#FFFFFF")
			I.Blend(c, ICON_MULTIPLY)

		var/imgid = replacetext(replacetext("[item]", "/obj/item/", ""), "/", "-")

		Insert(imgid, I)
	return ..()
// BLUEMOON EDIT -  Vending Update: END
