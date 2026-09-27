/obj/machinery/fan_assembly
	name = "fan assembly"
	desc = "Стандартный сборочный микролопастной каркас."
	icon = 'icons/obj/poweredfans.dmi'
	icon_state = "mfan_assembly"
	max_integrity = 150
	use_power = NO_POWER_USE
	power_channel = ENVIRON
	idle_power_usage = 0
	active_power_usage = 0
	layer = ABOVE_NORMAL_TURF_LAYER
	anchored = FALSE
	density = FALSE
	CanAtmosPass = ATMOS_PASS_YES
	var/build_state = 1
	var/buildstacktype = /obj/item/stack/sheet/plasteel
	var/buildstackamount = 5
	/*
			1 = Wrenched in place
			2 = Welded in place
			3 = Wires attached to it, this makes it change to the full thing.
	*/

/obj/machinery/fan_assembly/attackby(obj/item/W, mob/living/user, params)
	if(istype(W, /obj/item/stack/cable_coil) && build_state == 2)
		if(!isfloorturf(loc))
			to_chat(user, span_notice("Под [src] нет пола и инфраструктуры электросети с ним же!"))
			return FALSE
		if(!W.tool_start_check(user, amount=2))
			to_chat(user, span_warning("Нужно два метра кабеля, чтобы подключить к сети [src]!"))
			return FALSE
		to_chat(user, span_notice("Вы начинаете добавлять проводку к [src]..."))
		if(W.use_tool(src, user, 30, volume=50, amount=2))
			to_chat(user, span_notice("Вы провели проводку внутри [src]."))
			build_state = 3
			var/obj/machinery/poweredfans/F = new(loc, src)
			forceMove(F)
			F.setDir(src.dir)
			return TRUE
	return ..()

/obj/machinery/fan_assembly/wrench_act(mob/user, obj/item/I)
	if(build_state != 1)
		return FALSE
	user.visible_message(span_warning("[user] разбирает [src] на части."),
		span_warning("Вы начинаете разбирать [src]..."), "Вы слышите звуки раскручивания.")
	if(I.use_tool(src, user, 30, volume=50))
		deconstruct()
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/fan_assembly/welder_act(mob/living/user, obj/item/I)
	if(build_state == 1 && !isfloorturf(loc))
		to_chat(user, span_notice("[src] невозможно приварить к космосу!"))
		return FALSE
	switch(build_state)
		if(1)
			to_chat(user, span_notice("Вы начали приваривать [src]..."))
			if(I.use_tool(src, user, 30, volume=50))
				to_chat(user, span_notice("Вы надёжно приварили [src] к месту."))
				setAnchored(TRUE)
				build_state = 2
				update_icon_state()
				AddComponent(/datum/component/requires_floor)
			return TOOL_ACT_TOOLTYPE_SUCCESS
		if(2)
			to_chat(user, span_notice("Вы начали разваривать [src]..."))
			if(I.use_tool(src, user, 30, volume=50))
				to_chat(user, span_notice("Вы отварили [src] от пола."))
				setAnchored(FALSE)
				build_state = 1
				update_icon_state()
				qdel(GetComponent(/datum/component/requires_floor))
			return TOOL_ACT_TOOLTYPE_SUCCESS
	return ..()

/obj/machinery/fan_assembly/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new buildstacktype(loc,buildstackamount)
	qdel(src)

/obj/machinery/fan_assembly/examine(mob/user)
	. = ..()
	switch(build_state)
		if(1)
			to_chat(user, span_notice("Корпус [src], похоже, <b>неприварен</b> и ослаблен."))
		if(2)
			to_chat(user, span_notice("Корпус [src], похоже, надёжно приварен, но не имеет <b>проводки</b> внутри себя."))
		if(3)
			to_chat(user, span_notice("Корпус [src] имеет надёжно протянутую <b>проводку</b> внутри себя."))

/obj/machinery/fan_assembly/update_icon_state()
	. = ..()
	switch(build_state)
		if(1)
			icon_state = "mfan_assembly"
		if(2)
			icon_state = "mfan_welded"
