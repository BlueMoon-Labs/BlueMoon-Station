/obj/item/poster/wanted
	icon_state = "rolled_poster"
	/// Unique ID for this wanted poster (matches criminal's record ID). Used for area limit checks.
	var/poster_id = null

/obj/item/poster/wanted/Initialize(mapload, icon/person_icon, wanted_name, description)
	. = ..(mapload, new /obj/structure/sign/poster/wanted(src, person_icon, wanted_name, description))
	name = "Разыскивается ([wanted_name])"
	desc = "Постер с разыскиваемым лицом: [wanted_name]."

/obj/structure/sign/poster/wanted
	var/wanted_name
	poster_item_type = /obj/item/poster/wanted

/obj/structure/sign/poster/wanted/Initialize(mapload, icon/person_icon, person_name, description)
	. = ..()
	if(!person_icon)
		return INITIALIZE_HINT_QDEL
	name = "Разыскивается ([person_name])"
	wanted_name = person_name
	desc = description

	person_icon = icon(person_icon, dir = SOUTH)//copy the image so we don't mess with the one in the record.
	var/icon/the_icon = icon("icon" = 'icons/obj/poster_wanted.dmi', "icon_state" = "wanted_background")
	var/icon/icon_foreground = icon("icon" = 'icons/obj/poster_wanted.dmi', "icon_state" = "wanted_foreground")
	person_icon.Shift(SOUTH, 7)
	person_icon.Crop(7,4,26,30)
	person_icon.Crop(-5,-2,26,29)
	the_icon.Blend(person_icon, ICON_OVERLAY)
	the_icon.Blend(icon_foreground, ICON_OVERLAY)

	the_icon.Insert(the_icon, "wanted")
	the_icon.Insert(icon('icons/obj/contraband.dmi', "poster_being_set"), "poster_being_set")
	the_icon.Insert(icon('icons/obj/contraband.dmi', "poster_ripped"), "poster_ripped")
	icon = the_icon

/obj/structure/sign/poster/wanted/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_WIRECUTTER && poster_id && isliving(user))
		var/ckey = user.ckey
		if(ckey)
			var/list/remove_tasks = GLOB.brig_assistant_remove_tasks[ckey]
			if(remove_tasks && (poster_id in remove_tasks))
				remove_tasks -= poster_id
				if(remove_tasks.len == 0)
					GLOB.brig_assistant_remove_tasks -= ckey
				var/mob/living/living_user = user
				var/datum/bank_account/account = living_user.get_bank_account()
				if(account)
					var/reward = rand(75, 100)
					account.adjust_money(reward, "Brig: Remove wanted poster task")
					playsound(user, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 50, TRUE)
					to_chat(user, span_green("За снятие плаката начислено [reward] кредитов."))
	. = ..()

/obj/structure/sign/poster/wanted/roll_and_drop(turf/location)
	var/obj/item/poster/P = ..(location)
	P.name = "wanted poster ([wanted_name])"
	P.desc = "A wanted poster for [wanted_name]."
	if(istype(P, /obj/item/poster/wanted))
		var/obj/item/poster/wanted/W = P
		W.poster_id = poster_id
	return P

/obj/item/poster/wanted/poster_place_check(mob/user, turf/closed/wall)
	var/check_id = poster_id || (poster_structure && poster_structure.poster_id)
	if(!check_id)
		return TRUE // Legacy posters without ID - no limit
	var/area/A = get_area(src)
	if(!A)
		return TRUE
	var/count = 0
	for(var/turf/T in A)
		for(var/obj/structure/sign/poster/wanted/W in T.contents)
			if(W.poster_id == check_id)
				count++
	if(count >= WANTED_POSTER_MAX_PER_AREA)
		to_chat(user, span_warning("В этой зоне уже достаточно плакатов с этим разыскиваемым (макс. [WANTED_POSTER_MAX_PER_AREA])."))
		return FALSE
	return TRUE
