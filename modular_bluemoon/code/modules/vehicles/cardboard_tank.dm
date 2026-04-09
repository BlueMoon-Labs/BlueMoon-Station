/// Картонный танк: сложенный предмет → мультитул → техника с входом, выстрелом пирогом, звуками.

#define CARDBOARD_TANK_ICON 'modular_bluemoon/icons/obj/vehicles/cardboard_tank.dmi'
#define SFX_CT_FIRE 'sound/bluemoon/cardboard_tank/fire.ogg'
#define SFX_CT_TRACKS 'sound/bluemoon/cardboard_tank/tracks.ogg'
#define SFX_CT_HIT 'sound/bluemoon/cardboard_tank/hit.ogg'
/// Длина tracks.ogg в десятых долях секунды; `mid_length` в looping_sound ≥ длины файла, иначе наложение.
#define CARDBOARD_TANK_TRACKS_LENGTH_DS 70
/// После fire.ogg до вылета пирога (мuzzle + снаряд).
#define CARDBOARD_TANK_FIRE_DELAY 2 SECONDS
#define CARDBOARD_TANK_INTEGRITY 85
/// HP «руин» после первого разрушения — доломать до исчезновения.
#define CARDBOARD_TANK_RUIN_INTEGRITY 50

/// Диагональ `dir` приводим к тому же кардиналу, что и riding (спрайт танка).
/obj/vehicle/sealed/cardboard_tank/proc/snap_tank_dir(dir)
	var/snap = dir
	if(dir & (dir - 1))
		if(dir & NORTH)
			snap = NORTH
		else if(dir & SOUTH)
			snap = SOUTH
		else if(dir & EAST)
			snap = EAST
		else
			snap = WEST
	return snap

/// Доп. смещение вспышки относительно якоря спрайта танка (у дула); суммируется с pixel_x/y танка.
/obj/vehicle/sealed/cardboard_tank/proc/get_muzzle_barrel_offset(snap_dir)
	switch(snap_dir)
		if(NORTH)
			return list(0, 18)
		if(SOUTH)
			return list(0, -18)
		if(EAST)
			return list(22, 0)
		if(WEST)
			return list(-22, 0)
	return list(0, 0)

/// У базового riding offsets только на N/S/E/W; при диагональном шаге ключ не находится и сносит pixel_x/y.
/datum/component/riding/cardboard_tank/handle_vehicle_offsets(dir)
	var/snap = dir
	if(dir & (dir - 1))
		if(dir & NORTH)
			snap = NORTH
		else if(dir & SOUTH)
			snap = SOUTH
		else if(dir & EAST)
			snap = EAST
		else
			snap = WEST
	return ..(snap)

/obj/item/cardboard_tank_kit
	name = "folded cardboard tank"
	desc = "Свёрстанный «танк» из картона. Разверните мультитулом. В сложенном виде можно таскать за собой."
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverycrate"
	w_class = WEIGHT_CLASS_BULKY
	/// Если задан — развернуть мультитулом может только этот ckey (без дефисов, в нижнем регистре).
	var/owner_ckey
	/// Имя персонажа владельца (для подписи при осмотре); задаётся при выдаче с маяка.
	var/owner_character_name

/obj/item/cardboard_tank_kit/examine(mob/user)
	. = ..()
	if(owner_ckey)
		if(owner_character_name)
			. += span_notice("На дне мелким шрифтом: «Собственность: [owner_character_name]».")
		else
			. += span_notice("На дне мелким шрифтом отмечено, что комплект персональный — развернуть мультитулом может только владелец.")

/obj/item/cardboard_tank_kit/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_MULTITOOL)
		try_deploy(user)
		return TRUE
	return ..()

/obj/item/cardboard_tank_kit/proc/try_deploy(mob/living/user)
	if(!istype(user))
		return
	if(owner_ckey && user.ckey != owner_ckey)
		to_chat(user, span_warning("Этот экземпляр закреплён за другим владельцем. Соберите свой из коробок и пушки для пирогов."))
		return
	if(!isturf(loc) && !user.is_holding(src))
		to_chat(user, span_warning("Поставьте коробку на пол или держите в руках."))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	user.visible_message(span_notice("[user] разворачивает картонный танк!"), span_notice("Вы разворачиваете картонный танк."))
	if(!do_after(user, 3 SECONDS, target = src))
		return
	new /obj/vehicle/sealed/cardboard_tank(T)
	playsound(T, 'sound/items/deconstruct.ogg', 50, TRUE)
	qdel(src)

/obj/effect/temp_visual/dir_setting/cardboard_tank_muzzle
	icon = CARDBOARD_TANK_ICON
	icon_state = "Fire"
	duration = 4
	layer = ABOVE_MOB_LAYER

/obj/item/reagent_containers/food/snacks/pie/cream/nostun/cardboard_slug
	name = "cardboard slug"
	desc = "Пирог, вылетевший из картонной пушки."
	icon = CARDBOARD_TANK_ICON
	icon_state = "Cake"
	tastes = list("картон" = 1, "крем" = 1)
	foodtype = GRAIN | SUGAR

/obj/vehicle/sealed/cardboard_tank
	name = "cardboard tank"
	desc = "Шедевр инженерной мысли из гофрокартона. Внутри тесно, но зато есть «пушка»."
	icon = CARDBOARD_TANK_ICON
	icon_state = "Open"
	layer = ABOVE_MOB_LAYER
	anchored = FALSE
	max_integrity = CARDBOARD_TANK_INTEGRITY
	damage_deflection = 7
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)
	movedelay = 1
	default_driver_move = FALSE
	key_type = null
	enter_delay = 15
	max_occupants = 1
	/// Подгонка к клетке: в DMI якорь — нижний левый угол кадра; крупный кадр с танком «вверху-справа» визуально смещает модель. Отрицательные — влево/вниз.
	var/sprite_nudge_x = -32
	var/sprite_nudge_y = -20
	/// Сломанный корпус (остов); дальше можно доломать до 0 HP или подлатать бумагой.
	var/tank_broken = FALSE
	/// Один канал гусениц, только пока кто-то внутри (без спама playsound на каждый тайл).
	var/datum/looping_sound/cardboard_tank_tracks/tracks_loop
	COOLDOWN_DECLARE(fire_cooldown)

/obj/vehicle/sealed/cardboard_tank/Initialize(mapload)
	. = ..()
	var/datum/component/riding/R = LoadComponent(/datum/component/riding/cardboard_tank)
	var/walk_base = CONFIG_GET(number/movedelay/walk_delay)
	R.vehicle_move_delay = isnum(walk_base) ? walk_base : 1
	for(var/dir_nudge in list(NORTH, SOUTH, EAST, WEST))
		R.set_vehicle_dir_offsets(dir_nudge, sprite_nudge_x, sprite_nudge_y)
	R.handle_vehicle_offsets(dir)
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_tank_moved))

/obj/vehicle/sealed/cardboard_tank/Destroy()
	stop_tracks_loop()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/vehicle/sealed/cardboard_tank/examine(mob/user)
	. = ..()
	if(tank_broken)
		. += span_warning("Развалено в остов. Можно подлатать листом бумаги или доломать в щепки.")

/obj/vehicle/sealed/cardboard_tank/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	if(!tank_broken)
		playsound(src, SFX_CT_HIT, 55, TRUE)
	else
		playsound(src, 'sound/weapons/tap.ogg', 30, TRUE)

/obj/vehicle/sealed/cardboard_tank/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	return ..()

/// Не даём ex_act мгновенно qdel — только ломаем в остов; в остове бьём по руинам.
/obj/vehicle/sealed/cardboard_tank/ex_act(severity, target, origin)
	if(tank_broken)
		SEND_SIGNAL(src, COMSIG_ATOM_EX_ACT, severity, target, origin)
		if(QDELETED(src))
			return
		var/dmg = 0
		switch(severity)
			if(1)
				dmg = 80
			if(2)
				dmg = rand(18, 35)
			if(3)
				dmg = rand(6, 14)
		if(dmg)
			take_damage(dmg, BRUTE, BOMB, 0)
		return
	contents_explosion(severity, target, origin)
	SEND_SIGNAL(src, COMSIG_ATOM_EX_ACT, severity, target, origin)
	if(QDELETED(src))
		return
	var/dmg = 0
	switch(severity)
		if(1)
			dmg = 250
		if(2)
			dmg = rand(45, 95)
		if(3)
			dmg = rand(10, 40)
	if(dmg)
		take_damage(dmg, BRUTE, BOMB, 0)

/obj/vehicle/sealed/cardboard_tank/wave_ex_act(power, datum/wave_explosion/explosion, dir)
	if(tank_broken)
		if(!QDELETED(src))
			take_damage(wave_explosion_damage(power * 0.45, explosion), BRUTE, BOMB, 0)
		return power * wave_explosion_multiply - wave_explosion_block
	. = power * wave_explosion_multiply - wave_explosion_block
	if(explosion.source == src)
		take_damage(max_integrity * 2, BRUTE, BOMB, 0)
		return .
	if(!QDELETED(src))
		take_damage(wave_explosion_damage(power, explosion), BRUTE, BOMB, 0)
	return .

/obj/vehicle/sealed/cardboard_tank/obj_destruction(damage_flag)
	if(tank_broken)
		destroy_cardboard_ruin()
		return
	shatter_tank()
	return

/// Остов доломан — убираем с тайла.
/obj/vehicle/sealed/cardboard_tank/proc/destroy_cardboard_ruin()
	playsound(src, 'sound/effects/glassbr3.ogg', 25, TRUE)
	visible_message(span_warning("[src] превращается в лишь кучу мокрого картона!"))
	var/turf/T = get_turf(src)
	if(T)
		new /obj/effect/decal/cleanable/shreds(T)
	qdel(src)

/obj/vehicle/sealed/cardboard_tank/proc/shatter_tank()
	if(tank_broken)
		return
	tank_broken = TRUE
	canmove = FALSE
	stop_tracks_loop()
	max_integrity = CARDBOARD_TANK_RUIN_INTEGRITY
	obj_integrity = CARDBOARD_TANK_RUIN_INTEGRITY
	icon_state = "Broken"
	playsound(src, 'sound/effects/glassbr3.ogg', 40, TRUE)
	visible_message(span_warning("[src] рассыпается!"))
	dump_mobs_no_stun()
	STOP_PROCESSING(SSobj, src)

/obj/vehicle/sealed/cardboard_tank/proc/dump_mobs_no_stun()
	for(var/i in occupants)
		mob_exit(i, null, FALSE)

/obj/vehicle/sealed/cardboard_tank/dump_mobs(randomstep = TRUE)
	dump_mobs_no_stun()

/obj/vehicle/sealed/cardboard_tank/dump_specific_mobs(flag, randomstep = TRUE)
	dump_mobs_no_stun()

/obj/vehicle/sealed/cardboard_tank/attackby(obj/item/I, mob/user, params)
	if(tank_broken && istype(I, /obj/item/paper))
		if(!do_after(user, 2 SECONDS, target = src))
			return TRUE
		to_chat(user, span_notice("Вы подклеиваете бумагу и поднимаете конструкцию с колен."))
		playsound(src, 'sound/items/handling/paper_pickup.ogg', 40, TRUE)
		tank_broken = FALSE
		canmove = TRUE
		max_integrity = CARDBOARD_TANK_INTEGRITY
		obj_integrity = max_integrity
		icon_state = occupant_amount() ? "Close" : "Open"
		qdel(I)
		return TRUE
	return ..()

/obj/vehicle/sealed/cardboard_tank/mob_enter(mob/M, silent = FALSE)
	. = ..()
	if(. && !tank_broken)
		icon_state = "Close"
		start_tracks_loop()

/obj/vehicle/sealed/cardboard_tank/mob_exit(mob/M, silent = FALSE, randomstep = FALSE)
	. = ..()
	if(. && !tank_broken && !occupant_amount())
		icon_state = "Open"
	if(!occupant_amount())
		stop_tracks_loop()

/obj/vehicle/sealed/cardboard_tank/proc/start_tracks_loop()
	if(tank_broken || tracks_loop || !occupant_amount())
		return
	tracks_loop = new /datum/looping_sound/cardboard_tank_tracks(src, TRUE)

/obj/vehicle/sealed/cardboard_tank/proc/stop_tracks_loop()
	if(tracks_loop)
		tracks_loop.stop()
		QDEL_NULL(tracks_loop)

/obj/vehicle/sealed/cardboard_tank/proc/on_tank_moved(datum/source, atom/oldloc, movement_dir, forced)
	SIGNAL_HANDLER
	if(tank_broken || !occupant_amount())
		return
	if(icon_state == "Close")
		icon_state = "Movement"
		addtimer(CALLBACK(src, PROC_REF(reset_move_icon)), 2, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/vehicle/sealed/cardboard_tank/proc/reset_move_icon()
	if(tank_broken)
		return
	if(occupant_amount())
		icon_state = "Close"
	else
		icon_state = "Open"

/obj/vehicle/sealed/cardboard_tank/driver_move(mob/user, direction)
	if(tank_broken)
		to_chat(user, span_warning("Танк развален — сначала почините бумагой."))
		return FALSE
	var/datum/component/riding/R = GetComponent(/datum/component/riding)
	if(!R)
		return FALSE
	if(isliving(user))
		R.vehicle_move_delay = max(user.movement_delay(), 0.5)
	else
		var/walk_base = CONFIG_GET(number/movedelay/walk_delay)
		if(isnum(walk_base))
			R.vehicle_move_delay = walk_base
	R.handle_ride(user, direction)
	return TRUE

/obj/vehicle/sealed/cardboard_tank/generate_actions()
	. = ..()
	initialize_controller_action_type(/datum/action/vehicle/sealed/cardboard_tank_fire, VEHICLE_CONTROL_DRIVE)

/obj/vehicle/sealed/cardboard_tank/proc/fire_main_gun(mob/living/user)
	if(tank_broken)
		return
	if(!COOLDOWN_FINISHED(src, fire_cooldown))
		to_chat(user, span_warning("Пушка остывает!"))
		return
	COOLDOWN_START(src, fire_cooldown, 4 SECONDS)
	playsound(src, SFX_CT_FIRE, 80, FALSE)
	user.say("ВЫСТРЕЕЕЛ!", forced = "cardboard tank")
	addtimer(CALLBACK(src, PROC_REF(fire_main_gun_after_sound), user), CARDBOARD_TANK_FIRE_DELAY)

/// Вспышка ствола и пирог после CARDBOARD_TANK_FIRE_DELAY (fire.ogg уже сыгран при нажатии).
/obj/vehicle/sealed/cardboard_tank/proc/fire_main_gun_after_sound(mob/living/user)
	if(QDELETED(src) || tank_broken || QDELETED(user) || !isliving(user) || !is_occupant(user))
		return
	if(!isturf(loc))
		return
	var/snap_dir = snap_tank_dir(dir)
	var/obj/effect/temp_visual/dir_setting/cardboard_tank_muzzle/muzzle = new(get_turf(src), snap_dir)
	var/list/barrel = get_muzzle_barrel_offset(snap_dir)
	muzzle.pixel_x = pixel_x + barrel[1]
	muzzle.pixel_y = pixel_y + barrel[2]
	var/turf/T = get_turf(src)
	var/turf/target = get_ranged_target_turf(T, snap_dir, 5)
	var/obj/item/reagent_containers/food/snacks/pie/cream/nostun/cardboard_slug/pie = new(T)
	pie.pixel_x = pixel_x + barrel[1]
	pie.pixel_y = pixel_y + barrel[2]
	pie.throw_at(target, 8, 4, user, FALSE)

/// Один непрерываемый цикл гусениц: не плодит отдельный playsound на каждый шаг (длинный tracks.ogg).
/datum/looping_sound/cardboard_tank_tracks
	mid_sounds = list(SFX_CT_TRACKS = 1)
	mid_length = CARDBOARD_TANK_TRACKS_LENGTH_DS
	volume = 20
	vary = TRUE
	extra_range = -5

/datum/action/vehicle/sealed/cardboard_tank_fire
	name = "Main gun (pie)"
	desc = "Выстрелить пирогом."
	icon_icon = 'icons/obj/food/piecake.dmi'
	button_icon_state = "pie"

/datum/action/vehicle/sealed/cardboard_tank_fire/Trigger()
	. = ..()
	if(!.)
		return
	if(!istype(vehicle_entered_target, /obj/vehicle/sealed/cardboard_tank))
		return
	var/obj/vehicle/sealed/cardboard_tank/CT = vehicle_entered_target
	CT.fire_main_gun(owner)

/// Маяк призыва: выдаёт комплект с привязкой к ckey при использовании.
/obj/item/choice_beacon/bm_cardboard_tank
	name = "personal cardboard tank beacon"
	desc = "Закажите складной картонный танк. Только вы сможете развернуть его мультитулом."
	icon_state = "gangtool-green"

/obj/item/choice_beacon/bm_cardboard_tank/generate_display_names()
	return list("Folded cardboard tank (personal)" = /obj/item/cardboard_tank_kit)

/obj/item/choice_beacon/bm_cardboard_tank/create_choice_atom(atom/choice, mob/owner)
	var/obj/item/cardboard_tank_kit/K = new choice()
	if(istype(owner))
		K.owner_ckey = owner.ckey
		K.owner_character_name = owner.real_name ? owner.real_name : owner.name
	return K

/datum/crafting_recipe/cardboard_tank_kit
	name = "Folded cardboard tank"
	result = /obj/item/cardboard_tank_kit
	reqs = list(
		/obj/item/storage/box = 5,
		/obj/item/pneumatic_cannon/pie = 1,
	)
	time = 6 SECONDS
	category = CAT_MISCELLANEOUS
	subcategory = CAT_MISCELLANEOUS

/// Притягивание и Ctrl+клик с соседних тайлов, пока вы внутри танка.
/mob/living/Adjacent(atom/neighbor)
	if(istype(loc, /obj/vehicle/sealed/cardboard_tank))
		var/turf/T = get_turf(loc)
		if(T?.Adjacent(neighbor, neighbor, src))
			return TRUE
	return ..()
