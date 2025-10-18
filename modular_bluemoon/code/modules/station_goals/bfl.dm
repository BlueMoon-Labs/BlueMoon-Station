#define COUNT_PLASMA_QUESTS 3

/datum/station_goal/bfl
	name = "BFL Mining laser"

/datum/station_goal/bfl/can_be_selected()
	. = ..()
	var/list/L = SSmapping.levels_by_all_trait(list(ZTRAIT_MINING, ZTRAIT_LAVA_RUINS))
	if(isemptylist(L))
		return FALSE
	var/lava_z = pick(L)
	var/station_z = pick(SSmapping.levels_by_trait(ZTRAIT_STATION))
	if(is_mining_level(station_z) || station_z == lava_z || SSmapping.config.minetype == "none" || SSmapping.config.planetary)
		return FALSE

/datum/station_goal/bfl/get_report()
	return {"<b>Сооружение добывающего лазера</b><br> \
	Наш разведывательный дрон обнаружил на астероиде огромную жилу, изобилующей плазмой. Нам нужно, чтобы вы построили BFL систему для \
	добычи плазмы и отправки её на ЦК через шаттл карго. Благодаря нашему дрону точная геопозиция жилы доступна на GPS устройствах.<br> \
	Базовые компоненты конструкции должны быть доступны для покупки через шаттл карго.<br> \
	После установки и правильной настройки конструкции вам будет доступен для заказа особый карго груз, именуемый "BFL Mission goal". Для \
	завершения цели вы должны доставить его на станцию, а после можете насладиться вашей наградой.<br> \
	<br>
	Не подведите нас.
	<br><br>
	-Nanotrasen Naval Command"}


/datum/station_goal/bfl/on_report()
	//Unlock BFL related things
	var/datum/supply_pack/engineering/P = SSshuttle.supply_packs[/datum/supply_pack/engineering/bfl]
	P.special_enabled = TRUE

	P =  SSshuttle.supply_packs[/datum/supply_pack/engineering/bfl_lens]
	P.special_enabled = TRUE

	// P =  SSshuttle.supply_packs[/datum/supply_pack/engineering/bfl_goal]
	// P.special_enabled = TRUE

/obj/item/paper/bfl
	name = "Методичка - 'BFL Mining laser'"
	default_raw_text = "<h1>Потезисная методичка по установке и настройке добывающей конструкции.</h1><br>\
	Конструкция состоит из трёх компонентов: Излучателя, Приемника и Линзы. <br>\
	Излучатель устанавливается на станции и требует прямого подключения к энергосети, Приемник сооружается прямо \
	над центром жилы, а Линза устанавливается на Приемник. Шахта Приемника должна быть открыта для лазера. <br>\
	Если конструкция установлена и настроена правильно, Излучатель сможет направлять лазер точно в Приемник и тот \
	будет собирать добытую лазером руду, в противном случае возможно незначительное смещение лазера относительно местонахождения жилы. <br>\
	Условия выполнения цели станции уточняйте у командного состава."

////////////
//Building//
////////////
/obj/item/circuitboard/machine/bfl_emitter
	name = "BFL Emitter (Machine Board)"
	desc = "Be cautious, when emitter will be done it move up by one step"
	build_path = /obj/machinery/power/bfl_emitter
	// origin_tech = "engineering=4;combat=4;bluespace=4"
	req_components = list(
					/obj/item/stack/sheet/plasteel = 10,
					/obj/item/stack/sheet/plasmaglass = 4,
					/obj/item/stock_parts/capacitor/quadratic = 5,
					/obj/item/stock_parts/micro_laser/quadultra = 10,
					/obj/item/stack/sheet/mineral/diamond = 2)

/obj/item/circuitboard/machine/bfl_receiver
	name = "BFL Receiver (Machine Board)"
	desc = "Must be built in the middle of the deposit"
	build_path = /obj/machinery/bfl_receiver
	// origin_tech = "engineering=4;combat=4;bluespace=4"
	req_components = list(
					/obj/item/stack/sheet/metal = 20,
					/obj/item/stack/sheet/plasteel = 10,
					/obj/item/stack/sheet/plasmaglass = 20)

///////////
//Emitter//
///////////
/obj/machinery/power/bfl_emitter
	name = "BFL Emitter"
	icon = 'modular_bluemoon/icons/obj/machines/BFL_mission/Emitter.dmi'
	icon_state = "Emitter_Off"
	anchored = TRUE
	density = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 100000
	active_power_usage = 400000 // в сумме будет 500kW, так как idle присутствует всегда
	var/state = FALSE
	var/first_connection = TRUE // for goal crate unlocking
	var/obj/singularity/bfl_red/laser = null
	var/obj/machinery/bfl_receiver/receiver = null
	var/list/obj/effect/bfl_laser/turf_lasers = list()
	var/deactivate_time = 0
	var/list/obj/structure/fillers = list()
	var/lavaland_z_lvl = null // у нас 2 лаваленда

//code stolen from bluespace_tap, including comment below. He was right about the new datum
//code stolen from dna vault, inculding comment below. Taking bets on that datum being made ever.
//TODO: Replace this,bsa and gravgen with some big machinery datum
/obj/machinery/power/bfl_emitter/Initialize()
	. = ..()
	var/list/possible_lvls = SSmapping.levels_by_all_trait(list(ZTRAIT_MINING, ZTRAIT_LAVA_RUINS))
	if(!isemptylist(possible_lvls))
		lavaland_z_lvl = pick(possible_lvls)
	else
		possible_lvls = SSmapping.levels_by_trait(ZTRAIT_MINING)
		if(!isemptylist(possible_lvls))
			lavaland_z_lvl = pick(possible_lvls)
		else
			lavaland_z_lvl = loc.z
			WARNING("No mining levels detected but BFL Emitter has been created anyway. Hereby I disclaim all responsibility for anything that might happen later.")
	pixel_x = -32
	pixel_y = 0
	playsound(src, 'modular_bluemoon/sound/BFL/drill_sound.ogg', 100, TRUE)
	var/list/occupied = list()
	for(var/direction in list(NORTH, NORTHWEST, NORTHEAST, EAST, WEST))
		occupied += get_step(src, direction)
	occupied += locate(x, y + 2, z)
	occupied += locate(x + 1, y + 2, z)
	occupied += locate(x - 1, y + 2, z)
	for(var/T in occupied)
		var/obj/structure/filler/F = new(T)
		F.parent = src
		fillers += F
	if(!powernet)
		connect_to_network()

/obj/machinery/power/bfl_emitter/Destroy()
	emitter_deactivate()
	QDEL_LIST(fillers)
	return ..()

/obj/machinery/power/bfl_emitter/attack_hand(mob/user as mob)
	if(..())
		return TRUE
	var/response
	src.add_fingerprint(user)
	if(state)
		response = tgui_alert(user, "Вы пытаетесь деактивировать излучатель BFL. Уверены?", "Излучатель BFL", list("Деактивировать", "Отмена"))
	else
		response = tgui_alert(user, "Вы пытаетесь активировать излучатель BFL. Уверены?", "Излучатель BFL", list("Активировать", "Отмена"))

	switch(response)
		if("Деактивировать")
			if(obj_flags & EMAGGED)
				visible_message(span_notice("Обновление ПО BFL, пожалуйста подождите.<br>Завершено на 99%"))
				playsound(src, 'modular_bluemoon/sound/BFL/prank.ogg', 100, FALSE)
			else
				emitter_deactivate()
				deactivate_time = world.time
		if("Активировать")
			if(!powernet)
				connect_to_network()
			if(!powernet)
				to_chat(user, span_warning("Энергосеть не обнаружена."))
				return
			if(surplus() < active_power_usage)
				to_chat(user, span_warning("Недостаточно напряжения в подключенном проводе."))
				return
			if(world.time - deactivate_time > 30 SECONDS)
				emitter_activate()
			else
				visible_message(span_warning("Ошибка: излучатель всё ещё охлаждается"))


/obj/machinery/power/bfl_emitter/emag_act(mob/user)
	. = ..()
	if(!(obj_flags & EMAGGED))
		log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
		obj_flags |= EMAGGED
		if(user)
			to_chat(user, span_notice("Излучатель успешно саботирован"))

/obj/machinery/power/bfl_emitter/process()
	if(!state)
		add_load(idle_power_usage)
		return
	if(surplus() < active_power_usage)
		emitter_deactivate()
		return
	add_load(active_power_usage)
	if(src.z == lavaland_z_lvl)
		return
	if(laser)
		return
	if(!receiver || !receiver.state || (obj_flags & EMAGGED) || !receiver.lens || !receiver.lens.anchored)
		var/turf/rand_location = locate(rand(50, 150), rand(50, 150), lavaland_z_lvl)
		laser = new (rand_location)
		log_admin("BFL emitter has been activated without proper BFL receiver connection or it has been emagged at [AREACOORD(src)]")
		var/mutable_appearance/alert_overlay = mutable_appearance('modular_bluemoon/icons/obj/machines/BFL_Mission/Laser_small_icon.dmi', "Laser_Red")
		notify_ghosts("BFL выжигает лаваленд!", source = laser, alert_overlay = alert_overlay, action = NOTIFY_ORBIT, header = "BFL")
		for(var/M in GLOB.alive_mob_list)
			var/turf/mob_turf = get_turf(M)
			if(mob_turf?.z == lavaland_z_lvl && !is_blind(M))
				to_chat(M, span_userdanger("Вы видите яркую красную вспышку в небе. Затем клубы дыма рассеиваются, открывая гигантский красный луч, бьющий с небес."))
		if(receiver)
			receiver.mining = FALSE
			if(receiver.lens)
				receiver.lens.deactivate_lens()

/obj/machinery/power/bfl_emitter/proc/receiver_test()
	if(receiver)
		if(receiver.state && receiver.lens)
			receiver.lens.activate_lens()
			receiver.mining = TRUE
		return TRUE


/obj/machinery/power/bfl_emitter/proc/emitter_activate()
	state = TRUE
	log_admin("[key_name(usr)] activated BFL at [AREACOORD(src)]")
	update_icon(UPDATE_ICON_STATE)
	var/turf/location = get_step(src, NORTH)
	location.ScrapeAway(INFINITY)
	if(istype(location))
		for(var/atom/thing in location)
			if(!isobj(thing) && !isliving(thing))
				continue
			if(isliving(thing))
				var/mob/living/L = thing
				L.dust(TRUE, TRUE)
			else
				thing.singularity_act()
	working_sound()
	var/turf/below = SSmapping.get_turf_below(location)
	while(below)
		var/obj/effect/bfl_laser/turf_laser = new(below)
		turf_lasers += turf_laser
		below = SSmapping.get_turf_below(below) // dig deeper and try another laser
	if(QDELETED(receiver))
		receiver = null
	if(!receiver)
		for(var/obj/machinery/bfl_receiver/bfl_receiver in SSmachines.get_machines_by_type(/obj/machinery/bfl_receiver))
			var/turf/receiver_turf = get_turf(bfl_receiver)
			if((receiver_turf.z == lavaland_z_lvl) && (src.z != bfl_receiver.z))
				receiver = bfl_receiver
				break
	receiver_test()
	if(first_connection && receiver?.mining)
		first_connection = FALSE
		var/datum/supply_pack/engineering/P = SSshuttle.supply_packs[/datum/supply_pack/engineering/bfl_goal]
		P.special_enabled = TRUE


/obj/machinery/power/bfl_emitter/proc/emitter_deactivate()
	state = FALSE
	update_icon(UPDATE_ICON_STATE)
	if(receiver)
		receiver.mining = FALSE
		if(receiver.lens?.state)
			receiver.lens.deactivate_lens()
	if(laser)
		qdel(laser)
		laser = null
	for(var/obj/effect/bfl_laser/turf_laser in turf_lasers)
		turf_laser.remove_self()

/obj/machinery/power/bfl_emitter/proc/working_sound()
	set waitfor = FALSE
	while(state)
		playsound(src, 'modular_bluemoon/sound/BFL/emitter.ogg', 100, TRUE)
		stoplag(25)


/obj/machinery/power/bfl_emitter/update_icon_state()
	icon_state = "Emitter_[state ? "On" : "Off"]"

////////////
//Receiver//
////////////

/obj/machinery/bfl_receiver
	name = "BFL Receiver"
	desc = "Кнопка активации выглядит подозрительно. Возможно, следует открыть шахту вручную с помощью лома."
	icon = 'modular_bluemoon/icons/obj/machines/BFL_mission/Hole.dmi'
	icon_state = "Receiver_Off"
	anchored = TRUE
	interaction_flags_machine = INTERACT_MACHINE_OFFLINE | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_SET_MACHINE
	resistance_flags = LAVA_PROOF|FIRE_PROOF|ACID_PROOF
	pixel_x = -32
	pixel_y = -32
	base_pixel_x = -32
	base_pixel_y = -32
	var/state = FALSE
	var/mining = FALSE
	var/obj/machinery/bfl_lens/lens = null
	var/ore_type_mining = null
	var/list/ore_type_contained = list(
		/obj/item/stack/ore/plasma = 0,
		/obj/item/stack/ore/glass/basalt = 0,
	)
	var/max_ore_storage_capacity = 1000
	///An "overlay"-like light for receiver to indicate storage filling
	var/atom/movable/bfl_receiver_light/receiver_light = null
	///Used to define bits of ore mined, instead of stacks.
	var/ore_count = 0
	///Used for storing last icon update for receiver lights on borders of receiver
	var/last_light_state_number = 0


/obj/machinery/bfl_receiver/Initialize(mapload)
	. = ..()
	//it just works ¯\_(ツ)_/¯
	receiver_light = new (loc)
	playsound(src, 'modular_bluemoon/sound/BFL/drill_sound.ogg', 100, TRUE)
	var/turf/turf_under = get_turf(src)
	if(locate(/obj/bfl_crack) in turf_under)
		ore_type_mining = /obj/item/stack/ore/plasma
	else if(istype(turf_under, /turf/open/floor/plating/asteroid/basalt/lava_land_surface))
		ore_type_mining = /obj/item/stack/ore/glass/basalt
	else
		ore_type_mining = null
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)


/obj/machinery/bfl_receiver/Destroy()
	QDEL_NULL(receiver_light)
	QDEL_NULL(lens)
	return ..()

/obj/machinery/bfl_receiver/singularity_act()
	return

/obj/machinery/bfl_receiver/examine(mob/user)
	. = ..()
	. += "Контейнер вмещает до [max_ore_storage_capacity] единиц руды."
	. += "Счетчик добытой руды: [ore_count]"

/obj/machinery/bfl_receiver/attack_hand(mob/user)
	if(..())
		return TRUE
	var/response
	src.add_fingerprint(user)
	if(state)
		response = tgui_alert(user, "Вы пытаетесь деактивировать приёмник BFL. Уверены?", "Приёмник BFL", list("Деактивировать", "Очистить хранилище руды", "Отмена"))
	else
		response = tgui_alert(user, "Вы пытаетесь активировать приёмник BFL. Уверены?", "Приёмник BFL", list("Активировать", "Очистить хранилище руды", "Отмена"))
	switch(response)
		if("Деактивировать")
			to_chat(user, span_warning("Потускневшая кнопка звонко кликает. Ничего не происходит.<br>Попробуйте закрыть шахту вручную с помощью лома."))
		if("Активировать")
			to_chat(user, span_warning("Потускневшая кнопка звонко кликает. Ничего не происходит.<br>Попробуйте открыть шахту вручную с помощью лома."))
		if("Очистить хранилище руды")
			if(lens)
				to_chat(user, span_warning("Линза создаёт помехи - невозможно получить руду из хранилища."))
				return
			if(state)
				to_chat(user, span_warning("Сначала нужно закрыть шахту."))
				return
			var/drop_where = drop_location()
			for(var/ore_type in ore_type_contained)
				if(ore_type_contained[ore_type] > 0)
					new ore_type(drop_where, ore_type_contained[ore_type])
					ore_type_contained[ore_type] = 0
					CHECK_TICK
			ore_count = 0
			update_state()


/obj/machinery/bfl_receiver/crowbar_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = 0))
		return
	if(state)
		receiver_deactivate()
	else
		receiver_activate()

///This proc handles light updating on borders of BFL receiver.
/obj/machinery/bfl_receiver/proc/update_state()
	var/light_state = clamp(round(20*ore_count/max_ore_storage_capacity), 0, 20)
	if(last_light_state_number == light_state)
		return
	receiver_light.light_amount = light_state
	last_light_state_number = light_state
	receiver_light.update_icon(UPDATE_ICON_STATE)


/obj/machinery/bfl_receiver/process()
	if(!(mining && state) || isnull(ore_type_mining))
		return
	if(ore_count >= max_ore_storage_capacity)
		return
	ore_type_contained[ore_type_mining]++
	ore_count++
	update_state()


/obj/machinery/bfl_receiver/update_icon_state()
	icon_state = "Receiver_[state ? "On" : "Off"]"


/obj/machinery/bfl_receiver/proc/receiver_activate()
	state = TRUE
	update_icon(UPDATE_ICON_STATE)
	var/turf/T = get_turf(src)
	if(is_mining_level(T.z))
		T.ChangeTurf(/turf/open/chasm/lavaland)
	else
		T.ScrapeAway(INFINITY, flags = CHANGETURF_INHERIT_AIR)

/obj/machinery/bfl_receiver/proc/receiver_deactivate()
	var/turf/turf_under = get_step(src, SOUTH)
	var/turf/T = get_turf(src)
	state = FALSE
	update_icon(UPDATE_ICON_STATE)
	T.ChangeTurf(turf_under.type)


/obj/machinery/bfl_receiver/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	if(istype(arrived, /obj/machinery/bfl_lens))
		var/obj/machinery/bfl_lens/bfl_lens = arrived
		bfl_lens.step_count = 0

/atom/movable/bfl_receiver_light
	name = ""
	icon = 'modular_bluemoon/icons/obj/machines/BFL_Mission/Hole.dmi'
	icon_state = "Receiver_Light_0"
	layer = LOW_ITEM_LAYER
	appearance_flags = TILE_BOUND|PIXEL_SCALE|LONG_GLIDE
	// resistance_flags = INDESTRUCTIBLE
	anchored = TRUE
	var/light_amount = 0


/atom/movable/bfl_receiver_light/Initialize(mapload)
	. = ..()
	pixel_x = -32
	pixel_y = -32


/atom/movable/bfl_receiver_light/update_icon_state()
	icon_state = "Receiver_Light_[light_amount]"


////////
//Lens//
////////
/obj/machinery/bfl_lens
	name = "High-precision lens"
	desc = "Чрезвычайно хрупкая, обращайтесь осторожно."
	icon = 'modular_bluemoon/icons/obj/machines/BFL_Mission/Hole.dmi'
	icon_state = "Lens_Pull"
	max_integrity = 10
	layer = ABOVE_MOB_LAYER
	density = TRUE
	anchored = FALSE
	armor = list(MELEE = 0, BULLET = 0, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	throwforce = 10 // when lens falls down through the floor
	var/step_count = 0
	var/state = FALSE

/obj/machinery/bfl_lens/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NO_TELEPORT, INNATE_TRAIT)
	pixel_x = -32
	pixel_y = -32


/obj/machinery/bfl_lens/Destroy()
	visible_message(span_danger("Линза разлетается на миллионы осколков!"))
	playsound(src, "shatter", 70, 1)
	new /obj/effect/decal/cleanable/glass(get_turf(src))
	new /obj/effect/decal/cleanable/glass/titanium(get_turf(src))
	new /obj/effect/decal/cleanable/glass/plastitanium(get_turf(src))
	return ..()

/obj/machinery/bfl_lens/singularity_act()
	return

/obj/machinery/bfl_lens/update_icon_state()
	if(state)
		icon_state = "Lens_On"
	else if(anchored)
		icon_state = "Lens_Off"
	else
		icon_state = "Lens_Pull"


/obj/machinery/bfl_lens/update_overlays()
	. = ..()
	if(state)
		. += image('modular_bluemoon/icons/obj/machines/BFL_Mission/Laser.dmi', icon_state = "Laser_Blue", pixel_y = 64, layer = GASFIRE_LAYER)


/obj/machinery/bfl_lens/proc/activate_lens()
	state = TRUE
	update_icon()
	set_light(8)
	working_sound()


/obj/machinery/bfl_lens/proc/deactivate_lens()
	state = FALSE
	update_icon()
	set_light(FALSE)


/obj/machinery/bfl_lens/proc/working_sound()
	set waitfor = FALSE
	while(state)
		playsound(src, 'modular_bluemoon/sound/BFL/receiver.ogg', 100, TRUE)
		stoplag(25)


/obj/machinery/bfl_lens/wrench_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = 0))
		return
	if(default_unfasten_wrench(user, I, time = 140))
		var/obj/machinery/bfl_receiver/receiver = locate() in get_turf(src)
		if(receiver)
			receiver.lens = anchored ? src : null
			var/turf/T = get_turf(src)
			if(ischasm(T))
				var/turf/open/chasm/C = T
				if(anchored)
					ADD_TRAIT(C, TRAIT_CHASM_STOPPED, src)
				else
					REMOVE_TRAIT(C, TRAIT_CHASM_STOPPED, src)
					var/datum/component/chasm/ch = C.GetComponent(/datum/component/chasm)
					ch?.drop_stuff()
			else if(istype(T, /turf/open/openspace))
				T.Entered(src)
	if(!QDELETED(src))
		update_icon()

/obj/machinery/bfl_lens/Move(atom/newloc, direct = NONE, glide_size_override = 0, update_dir = TRUE)
	. = ..()
	if(!.)
		return
	if(step_count > 5)
		Destroy()
	step_count++
	pixel_x = -32
	pixel_y = -32 //Explictly stating, that pixel_x and pixel_y will ALWAYS be -32/-32 when moved, because moving objects reset their offset.


//everything else
/obj/bfl_crack
	name = "rich plasma deposit"
	anchored = TRUE
	icon = 'modular_bluemoon/icons/obj/machines/BFL_Mission/Hole.dmi'
	icon_state = "Crack"
	pixel_x = -32
	pixel_y = -32
	layer = HIGH_TURF_LAYER
	resistance_flags = INDESTRUCTIBLE|LAVA_PROOF|FIRE_PROOF|ACID_PROOF
	obj_flags = NONE
	var/obj/item/gps/internal/bfl_crack/internal

/obj/bfl_crack/Initialize(mapload)
	. = ..()
	internal = new(src)

/obj/bfl_crack/Destroy(force)
	QDEL_NULL(internal)
	. = ..()

/obj/bfl_crack/singularity_act()
	return

/obj/item/gps/internal/bfl_crack
	gpstag = "Deep plasma signal"
	desc = "Deep rich plasma deposit has been pinpointed by surveillance drone."

/obj/singularity/bfl_red
	name = "BFL"
	desc = "Гигантский лазер, предназначенный для добычи руды."
	icon = 'modular_bluemoon/icons/obj/machines/BFL_Mission/Laser.dmi'
	icon_state = "Laser_Red"
	pixel_x = -32
	pixel_y = 0
	base_pixel_x = -32
	base_pixel_y = 0
	dissipate = FALSE
	grav_pull = 0
	move_force = INFINITY
	move_resist = INFINITY
	pull_force = INFINITY
	var/list/go_to_coords = list()
	var/devastation_range = 1
	var/initial_z_lvl = null
	// Выжигать некрополис и эшовские дома забавно, но что-то на грани гриферства))
	var/x_lower_border = 2*TRANSITIONEDGE
	var/x_upper_border = 255 - (2*TRANSITIONEDGE)
	var/y_lower_border = 2*TRANSITIONEDGE
	var/y_upper_border = 195

/obj/singularity/bfl_red/New(loc, starting_energy = 50, temp = 0)
	// world.maxx works only afer initialization, so better safe than sorry
	x_upper_border = world.maxx - (2*TRANSITIONEDGE)
	go_to_coords = list(rand(x_lower_border, x_upper_border), rand(y_lower_border, y_upper_border))
	starting_energy = 250
	. = ..(loc, starting_energy, temp)

/obj/singularity/bfl_red/Initialize(mapload, starting_energy)
	initial_z_lvl = loc.z
	. = ..()
	STOP_PROCESSING(SSobj, src)
	START_PROCESSING(SSfastprocess, src)

/obj/singularity/bfl_red/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	. = ..()

/obj/singularity/bfl_red/process(delta_time)
	move()

/obj/singularity/bfl_red/proc/devastate() // almost like /eat() but without pulling
	set waitfor = FALSE
	var/turf/T = get_turf(src)
	if(!T || !isturf(loc))
		return
	for(var/thing in T)
		if(isturf(loc) && thing != src)
			consume(thing)
		CHECK_TICK
	for(var/i = 1 to 5) // prevent potential loops
		if(T.type == T.baseturfs)
			break
		consume(T)

/obj/singularity/bfl_red/move(force_move)
	if(!move_self)
		return FALSE
	if(force_move)
		return ..()
	if(isemptylist(go_to_coords) || (loc.x == go_to_coords[1] && loc.y == go_to_coords[2]))
		go_to_coords = list(rand(x_lower_border, x_upper_border), rand(y_lower_border, y_upper_border))
	var/movement_dir = get_dir(src, locate(go_to_coords[1], go_to_coords[2], initial_z_lvl))
	if(prob(50))
		var/ang = dir2angle(movement_dir)
		ang += rand() ? 90 : -90
		movement_dir = angle2dir(ang)
	switch(movement_dir) // диагонально расположенная лава выглядит ущербно с этими сраными ромбиками
		if(NORTHEAST)
			forceMove(get_step(src, EAST))
			forceMove(get_step(src, NORTH))
		if(NORTHWEST)
			forceMove(get_step(src, WEST))
			forceMove(get_step(src, NORTH))
		if(SOUTHEAST)
			forceMove(get_step(src, EAST))
			forceMove(get_step(src, SOUTH))
		if(SOUTHWEST)
			forceMove(get_step(src, WEST))
			forceMove(get_step(src, SOUTH))
		else
			forceMove(get_step(src, movement_dir))

/obj/singularity/bfl_red/Moved(atom/OldLoc, Dir)
	. = ..()
	devastate()

/obj/singularity/bfl_red/consume(atom/A)
	if(istype(A, /obj/machinery/power/supermatter_crystal))
		var/obj/machinery/power/supermatter_crystal/SM = A
		SM.explode()
	else
		. = ..()

/obj/singularity/bfl_red/singularity_act()
	return FALSE

/obj/singularity/bfl_red/event()
	return FALSE

/obj/singularity/bfl_red/attack_tk(mob/user)
	return

/obj/singularity/bfl_red/ex_act(severity, target, origin)
	return

/obj/singularity/bfl_red/bullet_act(obj/item/projectile/P)
	qdel(P)
	return BULLET_ACT_HIT //Will there be an impact? Who knows.  Will we see it? No.

/obj/effect/bfl_laser
	name = "big laser beam"
	desc = "Огромный сияющий луч, бьющий сверху вниз. Лучше не касаться."
	icon = 'modular_bluemoon/icons/obj/machines/BFL_Mission/laser_tile.dmi'
	icon_state = "laser"

/obj/effect/bfl_laser/Initialize(mapload)
	. = ..()
	RegisterSignal(get_turf(src), COMSIG_ATOM_ENTERED, PROC_REF(burn_stuff)) // /datum/element/connect_loc почему то не работает
	START_PROCESSING(SSprocessing, src)

/obj/effect/bfl_laser/proc/remove_self()
	UnregisterSignal(get_turf(src), COMSIG_ATOM_ENTERED)
	STOP_PROCESSING(SSprocessing, src)
	qdel(src)

/obj/effect/bfl_laser/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	SEND_SIGNAL(src, COMSIG_ATOM_HITBY, AM, skipcatch, hitpush, blocked, throwingdatum)
	burn_stuff(AM)

/obj/effect/bfl_laser/process()
	burn_stuff()

/obj/effect/bfl_laser/proc/burn_stuff(atom/movable/AM)
	SIGNAL_HANDLER
	. = FALSE
	var/turf/T = get_turf(src)
	if(!istransparentturf(T) && !isspaceturf(T)) //we're not open. REOPEN
		T.ScrapeAway(INFINITY)
	var/thing_to_check = get_turf(src)
	if(AM && !isspaceturf(AM))
		thing_to_check = list(AM)
	for(var/thing in thing_to_check)
		if(thing == src)
			continue
		if(!isobj(thing) && !isliving(thing))
			continue
		if(isliving(thing))
			var/mob/living/L = thing
			L.dust(TRUE, TRUE)
		else
			var/atom/movable/M = thing
			M.singularity_act()
		. = TRUE
		// if(isobj(thing))
		// 	var/obj/O = thing
		// 	if(O.invisibility >= INVISIBILITY_ABSTRACT)
		// 		continue
		// 	if(isitem(thing))
		// 		var/obj/item/I = thing
		// 		if(I.item_flags & ABSTRACT)
		// 			continue
		// 	. = TRUE
		// 	O.fire_act(2000, 1000)
		// if(isliving(thing))
		// 	var/mob/living/L = thing
		// 	if(L.invisibility >= INVISIBILITY_ABSTRACT)
		// 		continue
		// 	. = TRUE
		// 	L.fire_act(2000, 1000)

	if(.)
		playsound(src, 'sound/weapons/sear.ogg', 50, TRUE)

/obj/effect/bfl_laser/ex_act(severity)
	return
