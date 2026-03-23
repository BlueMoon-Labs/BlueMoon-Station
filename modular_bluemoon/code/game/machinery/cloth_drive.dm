/obj/structure/cloth_drive
	name = "cloth drive"
	desc = "Dish drive big brother. It's just looking at all this dirt that you're leaving behind."
	icon = 'modular_bluemoon/icons/obj/machines/cloth_drive.dmi'
	icon_state = "cloth_drive"
	resistance_flags = INDESTRUCTIBLE
	density = TRUE
	anchored = TRUE
	var/z_times_changed
	var/static/list/item_types = list(/obj/item/clothing,
		/obj/item/choice_beacon,
		/obj/item/musicaltuner,
		/obj/item/storage)

/obj/structure/cloth_drive/examine(mob/user)
	. = ..()
	if(user.Adjacent(src))
		. += "<span class='notice'>Click it to get collected items.</span>"

/obj/structure/cloth_drive/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(collect_items))

/datum/move_loop/has_target/move_towards/Destroy()
	UnregisterSignal(src, COMSIG_MOVABLE_Z_CHANGED)
	return ..()

/obj/structure/cloth_drive/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!contents.len)
		to_chat(user, "<span class='warning'>There's nothing in [src]!</span>")
		return
	var/obj/item/choice = tgui_input_list(user, "Need something?", "Cloth drive", contents)
	if(choice)
		user.put_in_hands(choice)
		to_chat(user, "<span class='notice'>You take out [choice] from [src].</span>")
		playsound(src, 'sound/items/pshoom.ogg', 50, TRUE)
		flick("cloth_drive_beam", src)

/obj/structure/cloth_drive/attackby(obj/item/I, mob/living/user, params)
	if(is_type_in_list(I, item_types) && user.a_intent != INTENT_HARM)
		if(!user.transferItemToLoc(I, src))
			return
		to_chat(user, "<span class='notice'>You put [I] in [src], and it's beamed into energy!</span>")
		playsound(src, 'sound/items/pshoom.ogg', 50, TRUE)
		flick("cloth_drive_beam", src)
		return

/obj/structure/cloth_drive/proc/collect_items()
	if(is_station_level(src.z))
		return
	z_times_changed++
	if(z_times_changed % 10 != 0)
		return

	var/area/area_to_check = get_area(src)
	for(var/turf/open/floor/Turfo in area_to_check.contents) // получаем список открытых турфов в шатлле
		var/protected_turf = FALSE
		for(var/obj/O in Turfo.contents) // убираем все турфы где есть стол или шкаф
			if(istype(O, /obj/structure/table) || istype(O, /obj/structure/closet))
				protected_turf = TRUE
				break
		if(protected_turf)
			continue
		for(var/obj/O in Turfo.contents) // уже точно собираем вещи в турфе
			if(is_type_in_list(O, item_types))
				O.forceMove(src)

