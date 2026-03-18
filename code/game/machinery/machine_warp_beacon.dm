/obj/item/warp_machine_beacon
	name = "Machine Warp Beacon"
	desc = "Устройство позволяющее телепортировать уже собранную машину, по сигнатуре платы, что в нее установили. Не подходит для машин, требующих сложных в производстве деталей."
	icon = 'icons/obj/warp_beacon.dmi'
	icon_state = "warp_beacon"
	item_state = "radio"

	vocal_bark_id = "synthgrunt"
	vocal_pitch = 0.6
	vocal_volume = 40
	vocal_speed = 4

	w_class = WEIGHT_CLASS_NORMAL

	custom_materials = list(/datum/material/iron = MINERAL_MATERIAL_AMOUNT*6, /datum/material/glass = MINERAL_MATERIAL_AMOUNT*5)

	COOLDOWN_DECLARE(cooldown_say)
	var/const/cooldown_say_time = 2 SECONDS

	var/obj/item/circuitboard/circuit

/obj/item/warp_machine_beacon/examine(mob/user)
	. = ..()
	if(circuit)
		. += span_notice("Загружена плата: [circuit]")
		. += span_notice("Alt-Click для извлечения платы.")
	else
		. += span_warning("Плата машинерии не загружена.")

/obj/item/warp_machine_beacon/update_name(updates)
	. = ..()
	name = initial(name)
	if(circuit?.build_path)
		name += " ([capitalize(circuit.build_path:name)])"

/obj/item/warp_machine_beacon/update_icon_state()
	. = ..()
	icon_state = initial(icon_state)
	if(circuit)
		icon_state += "-load"

/obj/item/warp_machine_beacon/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/circuitboard))
		if(circuit)
			user.balloon_alert(user, "Нет места")
			return
		if(!check_circuit(I))
			return
		if(!user.temporarilyRemoveItemFromInventory(I))
			return
		circuit = I
		I.forceMove(src)
		user.balloon_alert(user, "Загружено")
		update_appearance()
	else
		return ..()

/obj/item/warp_machine_beacon/AltClick(mob/user)
	. = ..()
	if(!anchored && circuit && user.canUseTopic(src, TRUE, no_tk = TRUE, check_resting = FALSE))
		if(!user.put_in_hands(circuit))
			return
		user.balloon_alert(user, "Извлечено")
		circuit = null
		update_appearance()

/obj/item/warp_machine_beacon/proc/check_circuit(obj/item/circuitboard/board, silent = FALSE)
	. = FALSE
	if(!board?.build_path)
		if(!silent)
			say("ОШИБКА: Плата не содержит информацию о машине")
		return
	if(istype(board, /obj/item/circuitboard/machine))
		var/obj/item/circuitboard/machine/machine_board = board
		var/good_board = TRUE
		var/const/max_stock_parts_rating = 1
		var/static/list/allowed_types = typesof(
			/obj/item/stack/cable_coil,
			/obj/item/reagent_containers/glass/beaker, 
			/obj/item/assembly/igniter,
			/obj/item/stack/sheet/glass,
			/obj/item/stack/sheet/metal
		)

		for(var/req in machine_board.req_components) // ispath
			if(ispath(req, /obj/item/stock_parts))
				var/obj/item/stock_parts/req_stock = req // ispath
				if(req_stock:rating > max_stock_parts_rating)
					good_board = FALSE
			else if(req in allowed_types)
				continue
			else
				good_board = FALSE

			if(!good_board)
				if(!silent)
					say("ОШИБКА: Машина слишком сложна в производстве")
				return

		return TRUE

	else if(istype(board, /obj/item/circuitboard/computer))
		return TRUE
	else
		if(!silent)
			say("ОШИБКА: Неизвестный тип машинерии")
		return

/obj/item/warp_machine_beacon/attack_self(mob/user)
	. = ..()
	if(!deploy_check())
		return
	user.balloon_alert(user, "Установка...")
	if(!do_after(user, 1.3 SECONDS, user))
		return
	if(!deploy_check())
		return
	item_flags |= NO_PIXEL_RANDOM_DROP
	if(!user.temporarilyRemoveItemFromInventory(src))
		item_flags &= ~NO_PIXEL_RANDOM_DROP
		return
	forceMove(get_turf(src))
	anchored = TRUE
	say("Начало развертывания...")
	addtimer(CALLBACK(src, PROC_REF(start_warping), user.dir), 2 SECONDS)

/obj/item/warp_machine_beacon/proc/deploy_check(silent = FALSE)
	. = FALSE
	if(!circuit)
		if(!silent)
			say("Плата не загружена, развертывание невозможно")
		return
	var/turf/T = get_turf(src)
	if(isspaceturf(T))
		if(!silent)
			say("Неподходящая локация")
		return
	for(var/obj/object in T)
		if(object.density && !(object.obj_flags & IGNORE_DENSITY) || object.obj_flags & BLOCKS_CONSTRUCTION)
			if(!silent)
				say("Недостаточно места для развертывания")
			return
	if(!zone_check())
		if(!silent)
			say("Отсутствует питание, развертывание невозможно")
		return

	return TRUE

/obj/item/warp_machine_beacon/proc/zone_check()
	var/area/A = get_area(src)
	if(!A)
		return FALSE
	return A.powered(/obj/machinery/warping_machine::power_channel)

/obj/item/warp_machine_beacon/proc/start_warping(warp_dir)
	if(QDELETED(src))
		return
	var/obj/machinery/warping_machine/WA = new /obj/machinery/warping_machine(get_turf(src), circuit)
	if(WA)
		WA.setDir(warp_dir)
	circuit = null
	qdel(src)

/obj/item/warp_machine_beacon/Destroy()
	QDEL_NULL(circuit)
	return ..()

/obj/item/warp_machine_beacon/send_speech(message, range, atom/movable/source, bubble_type, list/spans, datum/language/message_language, message_mode)
	. = ..()
	COOLDOWN_START(src, cooldown_say, cooldown_say_time)

/obj/item/warp_machine_beacon/can_speak()
	. = ..()
	if(!.)
		return

	return COOLDOWN_FINISHED(src, cooldown_say)

/// WARPING STAGE ///

#define PRE_WARP_TIME 3 SECONDS
#define START_WARP_TIME 10.1 SECONDS
#define WARP_PROCESS_TIME 100 SECONDS
#define END_WARP_TIME 4.8 SECONDS
#define TRANSFORM_LINE_MA mutable_appearance('modular_splurt/icons/effects/effects.dmi', "transform_effect", layer = layer - 0.1, color = LIGHT_COLOR_LIGHT_CYAN, alpha = 160)
#define ENERGY_BALL_MA mutable_appearance('icons/obj/tesla_engine/energy_ball.dmi', "energy_ball_fast", FLY_LAYER, color = LIGHT_COLOR_LIGHT_CYAN)

/obj/machinery/warping_machine
	name = "Warping machine"
	desc = "Устройство, проходящее процесс телепортации, пожалуйста ожидайте и не допускайте потерю питания..."
	icon = 'icons/obj/warp_beacon.dmi'
	icon_state = "forming"

	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	light_color = LIGHT_COLOR_LIGHT_CYAN
	max_integrity = 10

	flags_1 = NODECONSTRUCT_1

	use_power = ACTIVE_POWER_USE
	active_power_usage = 2000

	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)

	density = TRUE
	anchored = TRUE

	var/obj/item/circuitboard/warp_circuit
	var/datum/looping_sound/warping/soundloop

/obj/machinery/warping_machine/Initialize(mapload, obj/item/circuitboard/_warp_circuit)
	. = ..()
	warp_circuit = _warp_circuit
	if(!istype(warp_circuit))
		return INITIALIZE_HINT_QDEL_FORCE
	warp_circuit.forceMove(src)
	set_light(1)
	soundloop = new(src)
	name = "Warping [capitalize(warp_circuit.build_path:name)]"

	INVOKE_ASYNC(src, PROC_REF(pre_warp))

/obj/machinery/warping_machine/proc/pre_warp()
	if(QDELETED(src))
		return
	var/mutable_appearance/energy_ball = ENERGY_BALL_MA
	energy_ball.pixel_x = -32
	energy_ball.pixel_y = -32
	flick_overlay_static(energy_ball, loc, PRE_WARP_TIME)
	playsound(loc, 'sound/magic/lightningbolt.ogg', rand(20, 40), TRUE)
	addtimer(CALLBACK(src, PROC_REF(start_warp)), PRE_WARP_TIME)

/obj/machinery/warping_machine/proc/start_warp()
	if(QDELETED(src))
		return
	var/mutable_appearance/machine_ma = get_machine_ma()
	machine_ma.alpha = 100
	machine_ma.color = LIGHT_COLOR_LIGHT_CYAN
	machine_ma.layer = layer - 0.1

	var/mutable_appearance/transform_scanline = TRANSFORM_LINE_MA
	transformation_animation(machine_ma, time = START_WARP_TIME, transform_overlay = transform_scanline, reset_after = FALSE, replace_icon = FALSE)
	playsound(src, 'sound/effects/warping/warp_start.ogg', 100, FALSE)
	addtimer(CALLBACK(src, PROC_REF(warp_process)), START_WARP_TIME)

/obj/machinery/warping_machine/proc/warp_process()
	if(QDELETED(src))
		return

	soundloop.start()

	icon_state = "warping"

	addtimer(CALLBACK(src, PROC_REF(end_warp)), WARP_PROCESS_TIME)

/obj/machinery/warping_machine/proc/end_warp()
	if(QDELETED(src))
		return

	soundloop.stop()

	icon = initial(icon)
	icon_state = "materialization"

	var/mutable_appearance/machine_ma = get_machine_ma()
	machine_ma.layer = layer - 0.1

	var/mutable_appearance/transform_scanline = TRANSFORM_LINE_MA
	transformation_animation(machine_ma, time = END_WARP_TIME, transform_overlay = transform_scanline, reset_after = FALSE, replace_icon = FALSE)
	playsound(src, 'sound/effects/warping/warp_end.ogg', 100, FALSE)
	addtimer(CALLBACK(src, PROC_REF(materialize)), END_WARP_TIME)

/obj/machinery/warping_machine/proc/materialize()
	if(QDELETED(src))
		return
	var/atom/A = new warp_circuit.build_path(loc)
	A?.dir = dir
	QDEL_NULL(warp_circuit)
	qdel(src)

/obj/machinery/warping_machine/process(delta_time)
	if(!is_operational())
		interrupt_warp()

/obj/machinery/warping_machine/proc/get_machine_ma()
	var/mutable_appearance/app = new /mutable_appearance()
	if(istype(warp_circuit, /obj/item/circuitboard/computer) && ispath(warp_circuit.build_path, /obj/machinery/computer))
		var/obj/item/circuitboard/computer/co = warp_circuit
		var/comp_path = co.build_path
		var/icon_file = comp_path:icon
		app.icon = icon_file
		app.icon_state = comp_path:icon_state
		app.name = co.name

		if(!comp_path:unique_icon)
			// overlays
			var/mutable_appearance/ov = new /mutable_appearance()
			ov.icon = icon_file
			ov.icon_state = comp_path:icon_screen
			app.overlays += ov

			ov = new /mutable_appearance()
			ov.icon = icon_file
			ov.icon_state = comp_path:icon_keyboard
			app.overlays += ov
	else
		app = mutable_appearance(warp_circuit.build_path:icon, warp_circuit.build_path:icon_state)
	app.dir = dir
	return app

/obj/machinery/warping_machine/proc/interrupt_warp_effect()
	var/mutable_appearance/energy_ball = ENERGY_BALL_MA
	energy_ball.pixel_x = -32
	energy_ball.pixel_y = -32
	flick_overlay_static(energy_ball, loc, PRE_WARP_TIME)
	var/mutable_appearance/storm = mutable_appearance(icon, "storm", FLY_LAYER)
	flick_overlay_static(storm, loc, PRE_WARP_TIME)

	playsound(loc, 'sound/magic/lightningbolt.ogg', rand(20, 40), TRUE)

/obj/machinery/warping_machine/obj_destruction(damage_flag)
	interrupt_warp_effect()
	. = ..()

/obj/machinery/warping_machine/proc/interrupt_warp()
	interrupt_warp_effect()
	qdel(src)

/obj/machinery/warping_machine/Destroy()
	if(warp_circuit)
		warp_circuit.forceMove(drop_location())
		warp_circuit = null
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/warping_machine/play_attack_sound(damage_amount, damage_type, damage_flag)
	switch(damage_type)
		if(BRUTE)
			playsound(src, 'sound/weapons/egloves.ogg', 80, 1)
		if(BURN)
			playsound(src, 'sound/items/welder.ogg', 100, 1)

/obj/machinery/warping_machine/emp_act()
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	interrupt_warp()

#undef PRE_WARP_TIME
#undef START_WARP_TIME
#undef WARP_PROCESS_TIME
#undef END_WARP_TIME
#undef TRANSFORM_LINE_MA
#undef ENERGY_BALL_MA
