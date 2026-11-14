#define MAX_NOTICES 5

/obj/structure/noticeboard
	name = "notice board"
	desc = "A board for pinning important notices upon. It is made of the finest Spanish cork."
	icon = 'icons/obj/wallmounts.dmi'
	icon_state = "noticeboard"
	density = FALSE
	anchored = TRUE
	max_integrity = 100
	/// Current number of a pinned notices
	var/notices = 0

/obj/structure/noticeboard/Initialize(mapload, ndir, building)
	. = ..()

	if(building)
		setDir(ndir)

	var/static/list/tool_behaviors = list(
		TOOL_WRENCH = list(
			SCREENTIP_CONTEXT_LMB = list(INTENT_ANY = "Снять"),
		)
	)
	AddElement(/datum/element/contextual_screentip_tools, tool_behaviors)

	for(var/obj/item/I in loc)
		if(notices >= MAX_NOTICES)
			break
		if(istype(I, /obj/item/paper))
			I.forceMove(src)
			notices++
	update_appearance(UPDATE_ICON)

//attaching papers!!
/obj/structure/noticeboard/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/paper) || istype(O, /obj/item/photo))
		if(!allowed(user))
			to_chat(user, span_warning("You are not authorized to add notices!"))
			return
		if(notices < MAX_NOTICES)
			if(!user.transferItemToLoc(O, src))
				return
			notices++
			update_appearance(UPDATE_ICON)
			to_chat(user, span_notice("You pin the [O] to the [src]."))
		else
			to_chat(user, span_warning("There is no space left on the [src]!"))
	else if(O.tool_behaviour == TOOL_WRENCH)
		user.visible_message("<span class='notice'>[user] starts unsecuring [src]...</span>", "<span class='notice'>You start unsecuring [src]...</span>")
		O.play_tool_sound(src)
		if(O.use_tool(src, user, 80))
			user.visible_message("<span class='notice'>[user] unsecures [src]!</span>", "<span class='notice'>You detach [src] from the wall.</span>")
			playsound(src, 'sound/items/deconstruct.ogg', 50, 1)
			deconstruct()
		return
	else
		return ..()
	return ..()

/obj/structure/noticeboard/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/noticeboard/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NoticeBoard", name)
		ui.open()

/obj/structure/noticeboard/ui_data(mob/user)
	var/list/data = list()
	data["allowed"] = allowed(user)
	data["items"] = list()
	for(var/obj/item/content in contents)
		var/list/content_data = list(
			name = content.name,
			ref = REF(content)
		)
		data["items"] += list(content_data)
	return data

/obj/structure/noticeboard/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/obj/item/item = locate(params["ref"]) in contents
	if(!istype(item) || item.loc != src)
		return

	var/mob/user = usr

	switch(action)
		if("examine")
			if(istype(item, /obj/item/paper))
				item.ui_interact(user)
			else
				user.examinate(item)
			return TRUE
		if("remove")
			if(!allowed(user))
				return
			remove_item(item, user)
			return TRUE

/**
 * Removes an item from the notice board
 *
 * Arguments:
 * * item - The item that is to be removed
 * * user - The mob that is trying to get the item removed, if there is one
 */

/obj/structure/noticeboard/proc/remove_item(obj/item/item, mob/user)
	item.forceMove(drop_location())
	if(user)
		user.put_in_hands(item)
		to_chat(user, span_notice("You tear the [item] off the [src]."))
		balloon_alert(user, "removed from board")
	notices--
	update_appearance(UPDATE_ICON)

/obj/structure/noticeboard/deconstruct(disassembled = TRUE)
	if(!disassembled)
		new /obj/item/stack/sheet/mineral/wood(loc, 2)
	else
		new /obj/item/wallframe/noticeboard(loc)
	for(var/obj/item/content in contents)
		remove_item(content)
	qdel(src)

/obj/item/wallframe/noticeboard
	name = "notice board"
	desc = "Right now it's more of a clipboard. Attach to a wall to use."
	icon = 'icons/obj/wallframe.dmi'
	icon_state = "noticeboard"
	pixel_shift = -32
	custom_materials = list(
		/datum/material/wood = SHEET_MATERIAL_AMOUNT,
	)
	resistance_flags = FLAMMABLE
	result_path = /obj/structure/noticeboard

/obj/structure/noticeboard/update_overlays()
	. = ..()
	if(notices)
		. += "notices_[notices]"

/obj/structure/noticeboard/directional/north
	pixel_y = 32

/obj/structure/noticeboard/directional/south
	pixel_y = -32

/obj/structure/noticeboard/directional/east
	pixel_x = 32

/obj/structure/noticeboard/directional/west
	pixel_x = -32

/obj/structure/noticeboard/captain
	name = "Captain's Notice Board"
	desc = "Important notices from the Captain."
	req_access = list(ACCESS_CAPTAIN)

/obj/structure/noticeboard/hop
	name = "Head of Personnel's Notice Board"
	desc = "Important notices from the Head of Personnel."
	req_access = list(ACCESS_HOP)

/obj/structure/noticeboard/ce
	name = "Chief Engineer's Notice Board"
	desc = "Important notices from the Chief Engineer."
	req_access = list(ACCESS_CE)

/obj/structure/noticeboard/hos
	name = "Head of Security's Notice Board"
	desc = "Important notices from the Head of Security."
	req_access = list(ACCESS_HOS)

/obj/structure/noticeboard/cmo
	name = "Chief Medical Officer's Notice Board"
	desc = "Important notices from the Chief Medical Officer."
	req_access = list(ACCESS_CMO)

/obj/structure/noticeboard/rd
	name = "Research Director's Notice Board"
	desc = "Important notices from the Research Director."
	req_access = list(ACCESS_RD)

/obj/structure/noticeboard/qm
	name = "Quartermaster's Notice Board"
	desc = "Important notices from the Quartermaster."
	req_access = list(ACCESS_QM)

/obj/structure/noticeboard/staff
	name = "Staff Notice Board"
	desc = "Important notices from the heads of staff."
	req_access = list(ACCESS_HEADS)

#undef MAX_NOTICES
