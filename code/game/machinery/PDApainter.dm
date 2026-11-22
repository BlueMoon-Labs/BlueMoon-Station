/obj/machinery/pdapainter
	name = "\improper PDA painter"
	desc = "Машина для покраски ПДА. Чтобы использовать, вставьте свой ПДА и выберите желаемую схему."
	icon = 'icons/obj/pda.dmi'
	icon_state = "pdapainter"
	density = TRUE
	max_integrity = 200
	var/obj/item/modular_computer/pda/storedpda = null
	var/static/list/colorlist = list()

/obj/machinery/pdapainter/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "[initial(icon_state)]-broken"
		return
	if(powered())
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]-off"

/obj/machinery/pdapainter/update_overlays()
	. = ..()
	if(machine_stat & BROKEN)
		return
	if(storedpda)
		. += "[initial(icon_state)]-closed"

/obj/machinery/pdapainter/proc/user_is_command(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/obj/item/card/id/card = H.wear_id?.GetID()
	if(!card || !card.access)
		return FALSE
	return card.access.Find(ACCESS_HEADS) > 0

/obj/machinery/pdapainter/proc/pda_skin_is_command(checked_state)
	switch(checked_state)
		if("pda-captain", "pda-hop", "pda-hos", \
		   "pda-ce", "pda-cmo", "pda-rd", "pda-qm", \
		   "pda-lieutenant")
			return TRUE
	return FALSE

/obj/machinery/pdapainter/Initialize(mapload)
	. = ..()

	if(length(colorlist))
		return

	var/static/list/blocked_parents = list(
		/obj/item/modular_computer/pda/silicon,
		/obj/item/modular_computer/pda/clear,
		/obj/item/modular_computer/pda/syndicate,
		/obj/item/modular_computer/pda/chameleon,
		/obj/item/modular_computer/pda/nukeops,
		/obj/item/modular_computer/pda/syndicate_contract_uplink,
	)

	for(var/typepath in typesof(/obj/item/modular_computer/pda))
		var/is_blocked = FALSE
		for(var/blocked_type in blocked_parents)
			if(ispath(typepath, blocked_type))
				is_blocked = TRUE
				break
		if(is_blocked)
			continue

		var/obj/item/modular_computer/pda/P = typepath
		var/PDA_icon       = initial(P.icon)
		var/PDA_icon_state = initial(P.icon_state)

		var/key = "[initial(P.name)]|[PDA_icon]|[PDA_icon_state]"
		if(colorlist[key])
			continue

		colorlist[key] = list(
			"name"            = initial(P.name),
			"icon_state"      = PDA_icon_state,
			"icon_state_menu" = initial(P.icon_state_menu) || "screen_default",
			"desc"            = initial(P.desc),
			"icon"            = PDA_icon,
			"overlays_icon"   = initial(P.overlays_icon) || PDA_icon,
		)

/obj/machinery/pdapainter/Destroy()
	if(storedpda)
		storedpda.forceMove(drop_location())
		storedpda = null
	return ..()

/obj/machinery/pdapainter/on_deconstruction()
	if(storedpda)
		storedpda.forceMove(loc)
		storedpda = null

/obj/machinery/pdapainter/contents_explosion(severity, target, origin)
	if(storedpda)
		storedpda.ex_act(severity, target, origin)

/obj/machinery/pdapainter/handle_atom_del(atom/A)
	if(A == storedpda)
		storedpda = null
		update_appearance()

/obj/machinery/pdapainter/attackby(obj/item/O, mob/user, params)
	if(default_unfasten_wrench(user, O))
		power_change()
		return

	if(istype(O, /obj/item/modular_computer/pda))
		if(storedpda)
			to_chat(user, span_warning("Внутри уже находится ПДА."))
			return
		if(istype(O, /obj/item/modular_computer/pda/chameleon))
			to_chat(user, span_warning("[O] не подходит для покраски."))
			return
		if(!user.transferItemToLoc(O, src))
			return
		storedpda = O
		O.add_fingerprint(user)
		update_appearance()
		return

	if(O.tool_behaviour == TOOL_WELDER && user.a_intent != INTENT_HARM)
		if(machine_stat & BROKEN)
			if(!O.tool_start_check(user, amount = 0))
				return
			user.visible_message("[user] чинит [src].", span_notice("Вы начинаете чинить [src]..."))
			if(O.use_tool(src, user, 40, volume = 50))
				if(!(machine_stat & BROKEN))
					return
				to_chat(user, span_notice("Вы починили [src]."))
				set_machine_stat(machine_stat & ~BROKEN)
				obj_integrity = max_integrity
				update_appearance()
		else
			to_chat(user, span_notice("[src] не нуждается в ремонте."))
		return

	return ..()

/obj/machinery/pdapainter/on_attack_hand(mob/user, act_intent = null, unarmed_attack_flags)
	if(!user)
		return
	if(act_intent == null)
		act_intent = user.a_intent

	if(!storedpda)
		to_chat(user, span_notice("[src] пуст."))
		return
	if(machine_stat & BROKEN)
		to_chat(user, span_notice("[src] сломан."))
		return
	if(!powered())
		to_chat(user, span_notice("[src] без питания."))
		return

	if(istype(storedpda, /obj/item/modular_computer/pda/chameleon))
		to_chat(user, span_warning("[storedpda] отвергает покраску."))
		return

	var/can_paint_command = user_is_command(user)

	var/list/display_map = list()
	for(var/key in colorlist)
		var/list/data = colorlist[key]

		if(pda_skin_is_command(data["icon_state"]) && !can_paint_command)
			continue

		var/display = data["name"]
		var/counter = 1
		while(display_map[display])
			counter++
			display = "[data["name"]] ([data["icon_state"]] #[counter])"
		display_map[display] = key

	if(!length(display_map))
		to_chat(user, span_warning("[src] не имеет доступных цветовых схем для вас."))
		return

	var/obj/item/modular_computer/pda/original_pda = storedpda
	var/choice = input(user, "Выберите новый цветовую схему.", "Покраска ПДА") as null|anything in sort_list(display_map)
	if(!choice || QDELETED(storedpda) || storedpda != original_pda || !in_range(src, user))
		return

	var/list/data = colorlist[display_map[choice]]
	if(!data)
		return

	var/new_icon_state = data["icon_state"]

	storedpda.icon_state = new_icon_state

	if(new_icon_state == storedpda.base_icon_state)
		storedpda.job_icon_state = null
	else
		storedpda.job_icon_state = new_icon_state

	storedpda.desc = data["desc"]

	var/has_custom_skin = FALSE
	for(var/skin in GLOB.pda_reskins)
		var/list/skin_data = GLOB.pda_reskins[skin]
		if(skin_data["icon"] == storedpda.icon)
			has_custom_skin = TRUE
			break

	if(!has_custom_skin)
		storedpda.icon = data["icon"]
		storedpda.overlays_icon = data["overlays_icon"]
		storedpda.icon_state_menu = data["icon_state_menu"]

	storedpda.update_appearance()

	eject_pda()

/obj/machinery/pdapainter/proc/eject_pda()
	if(!storedpda)
		return
	storedpda.forceMove(drop_location())
	storedpda = null
	update_appearance()

/obj/machinery/pdapainter/verb/ejectpda()
	set name = "Извлечь ПДА"
	set category = "Object"
	set src in oview(1)

	if(usr.stat || usr.restrained())
		return
	if(!storedpda)
		to_chat(usr, span_notice("[src] пуст."))
		return
	eject_pda()

/obj/machinery/pdapainter/power_change()
	..()
	update_appearance()
