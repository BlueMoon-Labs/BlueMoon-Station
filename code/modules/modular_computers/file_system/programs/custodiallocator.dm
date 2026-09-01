/**
 * Custodial Locator - PDA cartridge program
 *
 * Locates janitorial equipment: mop buckets, cleaning bots, trash bags.
 */
/datum/computer_file/program/custodiallocator
	filename = "custloc"
	filedesc = "Custodial Locator"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "generic"
	extended_desc = "This program tracks janitorial equipment and cleaning bots on the station."
	requires_ntnet = FALSE
	transfer_access = null
	usage_flags = PROGRAM_ON_TABLETS
	size = 4
	tgui_id = "NtosCustodialLocator"
	program_icon = "broom"
	available_on_ntnet = FALSE

/datum/computer_file/program/custodiallocator/ui_data(mob/user)
	var/list/data = get_header_data()

	var/list/items = list()
	// Janitorial devices from global list (bots, carts, mops, keys)
	for(var/atom/A in GLOB.janitor_devices)
		if(QDELETED(A))
			continue
		items += list(list(
			"name" = A.name,
			"area" = get_area_name(A, TRUE),
			"type" = istype(A, /mob) ? "bot" : "equipment",
		))
	// Mop buckets (not in janitor_devices)
	for(var/obj/structure/mopbucket/B in world)
		items += list(list(
			"name" = B.name,
			"area" = get_area_name(B, TRUE),
			"type" = "bucket",
		))

	data["items"] = items
	return data
