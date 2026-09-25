//WHITE-STEEL PORT - Рейнджеры: протонный резак
//Перенесено из билда WhiteDream (white/Feline/code/rangers/voucher.dm)

/datum/movespeed_modifier/proton_cutter
	multiplicative_slowdown = 0.5

/datum/movespeed_modifier/proton_cutter_heavy
	multiplicative_slowdown = 0.1

/mob/living/simple_animal/proc/re_ai()
	toggle_ai(AI_ON)

/obj/item/melee/sabre/proton_cutter
	name = "Proton cutter"
	desc = "A massive boarding sword equipped with a gamma radiation generator, which has a negative effect on the nervous system of primitive life forms. The generator can also be further boosted to achieve complete paralysis. The effect on intelligent life forms is significantly reduced."

	force = 15
	block_chance = 30
	armour_penetration = 10
	wound_bonus = 0
	bare_wound_bonus = 5
	item_flags = ITEM_CAN_PARRY

	icon = 'modular_bluemoon/white/Feline/icons/proton_cutter.dmi'
	icon_state = "proton"
	lefthand_file = 'modular_bluemoon/white/Feline/icons/proton_cutter_left.dmi'
	righthand_file = 'modular_bluemoon/white/Feline/icons/proton_cutter_right.dmi'
	item_state = "proton"
	light_color = "#41f4e5"
	light_power = 2
	light_range = 3
	light_on = FALSE

	var/amplification = FALSE
	var/last_activation = 0
	var/recharge = 10 SECONDS
	var/static/mutable_appearance/stun_overlay = mutable_appearance('modular_bluemoon/white/Feline/icons/proton_cutter_stun.dmi', "stun", LYING_MOB_LAYER)

	var/datum/effect_system/spark_spread/sparks

/obj/item/melee/sabre/proton_cutter/Initialize()	// 	Искры
	. = ..()
	sparks = new
	sparks.set_up(5, 0, src)
	sparks.attach(src)

/obj/item/melee/sabre/proton_cutter/Destroy()
	if(sparks)
		qdel(sparks)
	sparks = null
	. = ..()

/obj/item/melee/sabre/proton_cutter/on_exit_storage(datum/component/storage/concrete/S)		//	Выхватывание из ножен, звуки
	var/obj/item/storage/belt/avangard_belt/B = S.real_location()
	if(istype(B))
		playsound(B, 'sound/items/unsheath.ogg', 25, TRUE)

/obj/item/melee/sabre/proton_cutter/on_enter_storage(datum/component/storage/concrete/S)
	var/obj/item/storage/belt/avangard_belt/B = S.real_location()
	if(istype(B))
		playsound(B, 'sound/items/sheath.ogg', 25, TRUE)
		if(amplification)
			proton_off()
			playsound(B, 'modular_bluemoon/white/Feline/sounds/proton_cutter_off.ogg', 100, TRUE)

/obj/item/melee/sabre/proton_cutter/attack_self(mob/user)	//	Зарядка
	if(!amplification)
		if(last_activation + recharge < world.time)
			icon_state = "proton-on"
			item_state = "proton-on"
			light_range = 3
			playsound(user, 'modular_bluemoon/white/Feline/sounds/proton_cutter.ogg', 100, TRUE)
			user.visible_message(span_warning("Протонный резак в руках [user] выплескивает шквал искр!"), span_notice("Форсирую генератор гамма излучения. Протонный резак выплескивает шквал искр!"))
			sparks.start()
			amplification = TRUE
			set_light_on(amplification)
		else
			to_chat(user, span_warning("Генератор перегружен! Необходимо охлаждение перед повторным применением."))
	else
		proton_off()
		playsound(user, 'modular_bluemoon/white/Feline/sounds/proton_cutter_off.ogg', 100, TRUE)
		to_chat(user, span_notice("Приглушаю генератор гамма излучения!"))

/obj/item/melee/sabre/proton_cutter/proc/proton_off()	//	Стандартное выключение
	amplification = FALSE
	set_light_on(amplification)
	icon_state = "proton"
	item_state = "proton"
	light_range = 0

/obj/item/melee/sabre/proton_cutter/proc/proton_attack(mob/living/M, mob/living/user, T)	// 	+ После удара
	M.add_overlay(stun_overlay)
	addtimer(CALLBACK(M, /atom/proc/cut_overlay, stun_overlay), T SECONDS)
	last_activation = world.time
	if(prob(50))
		playsound(user, 'modular_bluemoon/white/Feline/sounds/proton_cutter_amp_hit_1.ogg', 100, TRUE)
	else
		playsound(user, 'modular_bluemoon/white/Feline/sounds/proton_cutter_amp_hit_2.ogg', 100, TRUE)

/obj/item/melee/sabre/proton_cutter/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)	// 	Атака
	// 	Мобы
	if(!iscarbon(M) && !iscyborg(M))
		if(amplification && !ismegafauna(M) && !M.mind)
			if(ishostile(M))
				var/mob/living/simple_animal/stun_target = M
				stun_target.toggle_ai(AI_OFF)
				addtimer(CALLBACK(stun_target, /mob/living/simple_animal/proc/re_ai), 5 SECONDS)

			force = 60
			M.Paralyze(5 SECONDS, ignore_canstun = TRUE)
			M.Jitter(5 SECONDS)
			proton_off()
			proton_attack(M, user, 5)
		else if(amplification && M.mind && !ismegafauna(M))
			force = 60
			proton_off()
			proton_attack(M, user, 5)
		else if(amplification)
			force = 60
		else
			force = 30
		..(M, user, attackchain_flags, damage_multiplier)
		return
// 	Киборги
	if(iscyborg(M))
		if(amplification)
			force = 30
			M.Paralyze(5 SECONDS)
			proton_off()
			proton_attack(M, user, 5)
		else
			force = 15
		..(M, user, attackchain_flags, damage_multiplier)
		return
// 	Космонавтики
	if(iscarbon(M) && !isalien(M))
		if(amplification)
			force = 25
			M.add_movespeed_modifier(/datum/movespeed_modifier/proton_cutter)
			addtimer(CALLBACK(M, /mob/proc/remove_movespeed_modifier, /datum/movespeed_modifier/proton_cutter), 5 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
			proton_off()
			proton_attack(M, user, 5)
		else
			force = 15
		..(M, user, attackchain_flags, damage_multiplier)
		return
// 	Чужие
	if(isalienadult(M))
		if(amplification)
			force = 60

			if(ishostile(M) && !isalienroyal(M) && !M.mind)
				var/mob/living/simple_animal/stun_target = M
				stun_target.toggle_ai(AI_OFF)
				addtimer(CALLBACK(stun_target, /mob/living/simple_animal/proc/re_ai), 5 SECONDS)
				addtimer(CALLBACK(M, /atom/proc/cut_overlay, stun_overlay), 5 SECONDS)

			if(!isalienroyal(M) && !M.mind)
				M.Paralyze(5 SECONDS, ignore_canstun = TRUE)
			else if(isalienroyal(M))
				M.add_movespeed_modifier(/datum/movespeed_modifier/proton_cutter_heavy)
				addtimer(CALLBACK(M, /mob/proc/remove_movespeed_modifier, /datum/movespeed_modifier/proton_cutter_heavy), 5 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

			proton_off()
			proton_attack(M, user, 5)
		else
			force = 30
		..(M, user, attackchain_flags, damage_multiplier)
		return
//	Неспециализированные цели (например, личинки): базовый урон
	force = initial(force)
	..(M, user, attackchain_flags, damage_multiplier)

/obj/item/melee/sabre/proton_cutter/get_damage_to_obj(obj/O, mob/living/user)
	return 60

/obj/item/storage/belt/avangard_belt
	name = "Vanguard belt"
	desc = "Special tactical sheaths for the proton cutter and magnetic tomahawk, equipped with convenient pockets for equipment."
	icon = 'modular_bluemoon/white/Feline/icons/rangers_belt.dmi'
	icon_state = "avangard"
	item_state = "avangard"
	mob_overlay_icon = 'modular_bluemoon/white/Feline/icons/rangers_belt_back.dmi'
	content_overlays = FALSE
	w_class = WEIGHT_CLASS_NORMAL

	var/recharge_interval = 10 SECONDS
	var/last_recharge = 0

/obj/item/storage/belt/avangard_belt/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/storage/belt/avangard_belt/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/storage/belt/avangard_belt/process()
	if(world.time < last_recharge + recharge_interval)
		return
	last_recharge = world.time
	for(var/obj/item/melee/tomahawk/T in contents)
		var/obj/item/stock_parts/cell/C = T.get_cell()
		if(!C || C.charge >= C.maxcharge)
			continue
		C.give(C.maxcharge * 0.05)

/obj/item/storage/belt/avangard_belt/update_icon_state()
	if(locate(/obj/item/melee/sabre/proton_cutter) in contents)
		icon_state = "avangard-on"
		item_state = "avangard-on"
	else
		icon_state = "avangard"
		item_state = "avangard"
	return ..()

/obj/item/storage/belt/avangard_belt/examine(mob/user)
	. = ..()
	. += "<hr>"
	if(length(contents))
		. += span_notice("Активируйте пояс в руке, чтобы мгновенно выхватить резак.")

/obj/item/storage/belt/avangard_belt/attack_self(mob/user)
	for(var/obj/item/melee/sabre/proton_cutter/proton_cutter in contents)
		user.visible_message(span_notice("[user] достаёт из ножен [proton_cutter]."), span_notice("Достаю [proton_cutter] из ножен."))
		user.put_in_hands(proton_cutter)
		update_appearance()
		playsound(user, 'sound/items/unsheath.ogg', 40, TRUE)
		return
	..()

/obj/item/storage/belt/avangard_belt/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 7
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.silent = TRUE
	STR.can_hold = typecacheof(list(
		/obj/item/melee/sabre/proton_cutter,
		/obj/item/melee/classic_baton,
		/obj/item/kitchen/knife,
		/obj/item/ammo_box,
		/obj/item/ammo_casing/shotgun,
		/obj/item/grenade,
		/obj/item/forcefield_projector,
		/obj/item/shield/riot/tele,
		/obj/item/clothing/glasses,
		/obj/item/clothing/gloves,
		/obj/item/gps,
		/obj/item/healthanalyzer,
		/obj/item/storage/pill_bottle,
		/obj/item/reagent_containers/pill,
		/obj/item/reagent_containers/hypospray,
		/obj/item/stack/medical,
		/obj/item/reagent_containers/food/drinks,
		/obj/item/melee/tomahawk
		))

/obj/item/storage/belt/avangard_belt/PopulateContents()
	new /obj/item/melee/sabre/proton_cutter(src)
	new /obj/item/melee/tomahawk(src)
	update_appearance()
