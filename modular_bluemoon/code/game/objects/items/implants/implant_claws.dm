// ============================================================================
// БАЗОВЫЙ НОЖ С КОГТЯМИ (для квирка)
// ============================================================================

/obj/item/kitchen/knife/claws
	name = "Claws"
	desc = "У вас есть острые когти, они втягиваются и вытягиваются на ваших кончиках пальцев с помощью ваших же мышц. Довольно опасные если еще и заточить их."
	icon = 'modular_bluemoon/icons/mob/actions/razorclaws.dmi'
	icon_state = "wolverine"
	item_state = "wolverine"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/razorclaws_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/razorclaws_righthand.dmi'

	flags_1 = CONDUCT_1
	force = 13
	throwforce = 10
	w_class = WEIGHT_CLASS_HUGE
	throw_speed = 3
	throw_range = 6

	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("slashed", "sliced", "cut", "clawed", "ripped")
	sharpness = SHARP_EDGED
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)

	wound_bonus = 5
	bare_wound_bonus = 5

	tool_behaviour = TOOL_KNIFE
	toolspeed = 1

	bayonet = FALSE

	// Внутренние переменные для переключения режимов
	var/knife_mode = TRUE
	var/knife_force = 13
	var/knife_wound_bonus = 5
	var/knife_bare_wound_bonus = 5

	var/cutter_force = 5
	var/cutter_wound_bonus = 0
	var/cutter_bare_wound_bonus = 0

	// Переменные для емага
	var/emag_force = 30 // Как у энергомеча

/obj/item/kitchen/knife/claws/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 80 - force, 100, force - 10)

/obj/item/kitchen/knife/claws/attack_self(mob/user)
	if(obj_flags & EMAGGED)
		to_chat(user, "<span class='warning'>Протоколы взломаны и режим заблокирован в режиме нарезки!</span>")
		return

	playsound(get_turf(user), 'sound/items/unsheath.ogg', 10, TRUE)

	if(knife_mode)
		// Переключаемся в режим кусачек
		knife_mode = FALSE
		tool_behaviour = TOOL_WIRECUTTER
		to_chat(user, "<span class='notice'>Вы втягиваете [src] в более точную позицию, что позволяет вам обрезать проводку.</span>")

		icon_state = "precision_wolverine"
		item_state = "precision_wolverine"
		force = cutter_force
		wound_bonus = cutter_wound_bonus
		bare_wound_bonus = cutter_bare_wound_bonus
		sharpness = SHARP_NONE
		hitsound = 'sound/items/wirecutter.ogg'
		attack_verb = list("pinched", "nipped")
	else
		// Переключаемся в режим ножа
		knife_mode = TRUE
		tool_behaviour = TOOL_KNIFE
		to_chat(user, "<span class='notice'>Вы вытягиваете [src] на полную, чтобы резать.</span>")

		icon_state = "wolverine"
		item_state = "wolverine"
		force = knife_force
		wound_bonus = knife_wound_bonus
		bare_wound_bonus = knife_bare_wound_bonus
		sharpness = SHARP_EDGED
		hitsound = 'sound/weapons/bladeslice.ogg'
		attack_verb = list("slashed", "sliced", "cut", "clawed", "ripped")

	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

/obj/item/kitchen/knife/claws/attackby(obj/item/weapon, mob/user, params)
	// Поддержка точильных камней
	if(istype(weapon, /obj/item/sharpener))
		if(obj_flags & EMAGGED)
			to_chat(user, "<span class='warning'>Протоколы безопасности уже взломаны!</span>")
			return TRUE

		var/obj/item/sharpener/whetstone = weapon

		if(whetstone.used)
			to_chat(user, "<span class='warning'>Точильный камень слишком изношен для повторного использования!</span>")
			return TRUE

		if(knife_force > initial(knife_force))
			to_chat(user, "<span class='warning'>[capitalize(src.name)] уже затачивались ранее. Дальнейшая заточка невозможна!</span>")
			return TRUE

		if(knife_force >= whetstone.max)
			to_chat(user, "<span class='warning'>[capitalize(src.name)] слишком мощные для дальнейшей заточки!</span>")
			return TRUE

		knife_force = clamp(knife_force + whetstone.increment, 0, whetstone.max)
		knife_wound_bonus += whetstone.increment
		knife_bare_wound_bonus += whetstone.increment
		armour_penetration += 20

		if(knife_mode)
			force = knife_force
			wound_bonus = knife_wound_bonus
			bare_wound_bonus = knife_bare_wound_bonus

		name = "[whetstone.prefix] [initial(name)]"
		desc += "<span class='warning'>\n\nОни прошли специальный процесс заточки; теперь они убивают людей ещё быстрее, чем раньше.</span>"

		user.visible_message(
			"<span class='notice'>[user] затачивает [src] с помощью [whetstone]!</span>",
			"<span class='notice'>Вы затачиваете [src], делая их намного более смертоносными, чем раньше.</span>"
		)

		playsound(src, 'sound/items/unsheath.ogg', 25, TRUE)

		whetstone.name = "worn out [initial(whetstone.name)]"
		whetstone.desc = "[initial(whetstone.desc)] At least, it used to."
		whetstone.used = 1
		whetstone.update_icon()

		return TRUE

	return ..()

/obj/item/kitchen/knife/claws/emag_act()
	. = ..()
	if(obj_flags & EMAGGED || !(flags_1 & CONDUCT_1))
		return

	obj_flags |= EMAGGED
	knife_mode = TRUE
	tool_behaviour = TOOL_KNIFE

	// Устанавливаем параметры как у энергомеча
	knife_force = emag_force
	force = emag_force
	knife_wound_bonus = 15
	wound_bonus = 15
	knife_bare_wound_bonus = 15
	bare_wound_bonus = 15
	armour_penetration = 35

	icon_state = "wolverine_emag"
	item_state = "wolverine_emag"

	name = "взломанные [initial(name)]"
	desc = "[initial(desc)] <span class='warning'>Они излучают опасную энергию!</span>"

	var/mob/user = usr
	if(user)
		to_chat(user, "<span class='warning'>Вы подключаете провода к плате когтей! Защитные протоколы отключены!</span>")
		log_admin("[key_name(user)] emagged [src] at [AREACOORD(src)]")

	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

/obj/item/kitchen/knife/claws/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(user.zone_selected == BODY_ZONE_PRECISE_EYES)
		return eyestab(M, user)
	else
		return ..()

/obj/item/kitchen/knife/claws/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] разрезает [user.ru_ego()] горло с помощью [src]! Похоже, [user.p_theyre()] пытается совершить самоубийство.</span>")
	return BRUTELOSS

// Натуральные когти для квирка (без механических звуков)
/obj/item/kitchen/knife/claws/natural
	name = "Retractable claws"
	desc = "У вас есть острые когти, они втягиваются и вытягиваются на ваших кончиках пальцев с помощью ваших же мышц. Довольно опасные если еще и заточить их."
	icon_state = "claw"
	item_state = "claw"
	flags_1 = NONE

/obj/item/kitchen/knife/claws/natural/attack_self(mob/user)
	// Квирковые когти не имеют звуков и не меняют визуал
	if(knife_mode)
		knife_mode = FALSE
		icon_state = "precision_claw"
		item_state = "precision_claw"
		tool_behaviour = TOOL_WIRECUTTER
		to_chat(user, "<span class='notice'>Вы втягиваете когти для более точной работы.</span>")
	else
		knife_mode = TRUE
		icon_state = "claw"
		item_state = "claw"
		tool_behaviour = TOOL_KNIFE
		to_chat(user, "<span class='notice'>Вы выпускаете когти для боя.</span>")


	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

// ============================================================================
// ИМПЛАНТ ВЕРСИЯ (для покупки в аплинке и т.д.)
// ============================================================================

/obj/item/kitchen/knife/razor_claws
	name = "Implanted razor claws"
	desc = "Набор острых втягивающихся когтей, встроенных в кончики пальцев, пять обоюдоострых лезвий гарантированно превратят людей в фарш. Способны переключаться в 'Точный' режим, действуя как кусачки."
	icon = 'modular_bluemoon/icons/mob/actions/razorclaws.dmi'
	icon_state = "wolverine"
	item_state = "wolverine"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/razorclaws_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/razorclaws_righthand.dmi'

	flags_1 = CONDUCT_1
	force = 15
	throwforce = 10
	w_class = WEIGHT_CLASS_HUGE
	throw_speed = 3
	throw_range = 6

	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("slashed", "sliced", "cut", "clawed", "ripped")
	sharpness = SHARP_EDGED
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)

	wound_bonus = 5
	bare_wound_bonus = 5

	tool_behaviour = TOOL_KNIFE
	toolspeed = 1

	item_flags = NEEDS_PERMIT
	bayonet = FALSE

	var/knife_mode = TRUE
	var/knife_force = 15
	var/knife_wound_bonus = 5
	var/knife_bare_wound_bonus = 5

	var/cutter_force = 5
	var/cutter_wound_bonus = 0
	var/cutter_bare_wound_bonus = 0

	var/emag_force = 30

/obj/item/kitchen/knife/razor_claws/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 80 - force, 100, force - 10)

/obj/item/kitchen/knife/razor_claws/attack_self(mob/user)
	if(obj_flags & EMAGGED)
		to_chat(user, "<span class='warning'>Подключаясь к карте [src], вы сломали защитные протоколы, ломая при этом режим резки проводов!</span>")
		return

	playsound(get_turf(user), 'sound/items/change_drill.ogg', 50, TRUE)

	if(knife_mode)
		knife_mode = FALSE
		tool_behaviour = TOOL_WIRECUTTER
		to_chat(user, "<span class='notice'>Вы переключаете [src] в Точный режим для резки проводов.</span>")

		icon_state = "precision_wolverine"
		item_state = "precision_wolverine"
		force = cutter_force
		wound_bonus = cutter_wound_bonus
		bare_wound_bonus = cutter_bare_wound_bonus
		sharpness = SHARP_NONE
		hitsound = 'sound/items/wirecutter.ogg'
		attack_verb = list("pinched", "nipped")
	else
		knife_mode = TRUE
		tool_behaviour = TOOL_KNIFE
		to_chat(user, "<span class='notice'>Вы переключаете [src] в Боевой режим для нарезки.</span>")

		icon_state = "wolverine"
		item_state = "wolverine"
		force = knife_force
		wound_bonus = knife_wound_bonus
		bare_wound_bonus = knife_bare_wound_bonus
		sharpness = SHARP_EDGED
		hitsound = 'sound/weapons/bladeslice.ogg'
		attack_verb = list("slashed", "sliced", "cut", "clawed", "ripped")

	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

/obj/item/kitchen/knife/razor_claws/attackby(obj/item/weapon, mob/user, params)
	if(istype(weapon, /obj/item/sharpener))
		if(obj_flags & EMAGGED)
			to_chat(user, "<span class='warning'>Протоколы безопасности уже взломаны!</span>")
			return TRUE

		var/obj/item/sharpener/whetstone = weapon

		if(whetstone.used)
			to_chat(user, "<span class='warning'>Точильный камень непригоден для дальнейших заточек!</span>")
			return TRUE

		if(knife_force > initial(knife_force))
			to_chat(user, "<span class='warning'>[capitalize(src.name)] уже затачивались, дополнительная заточка не требуется!</span>")
			return TRUE

		if(knife_force >= whetstone.max)
			to_chat(user, "<span class='warning'>[capitalize(src.name)] и так достаточно мощные, заточка невозможна!</span>")
			return TRUE

		knife_force = clamp(knife_force + whetstone.increment, 0, whetstone.max)
		knife_wound_bonus += whetstone.increment
		knife_bare_wound_bonus += whetstone.increment
		armour_penetration += 20

		if(knife_mode)
			force = knife_force
			wound_bonus = knife_wound_bonus
			bare_wound_bonus = knife_bare_wound_bonus

		name = "[whetstone.prefix] [initial(name)]"
		desc += "<span class='warning'>\n\nОни прошли специальный процесс заточки; теперь они убивают людей ещё быстрее.</span>"

		user.visible_message(
			"<span class='notice'>[user] точит [src] с помощью [whetstone]!</span>",
			"<span class='notice'>Вы затачиваете [src], делая их намного смертоноснее, чем сейчас.</span>"
		)

		playsound(src, 'sound/items/unsheath.ogg', 25, TRUE)

		whetstone.name = "worn out [initial(whetstone.name)]"
		whetstone.desc = "[initial(whetstone.desc)] At least, it used to."
		whetstone.used = 1
		whetstone.update_icon()

		return TRUE

	return ..()

/obj/item/kitchen/knife/razor_claws/emag_act()
	. = ..()
	if(obj_flags & EMAGGED)
		return

	obj_flags |= EMAGGED
	knife_mode = TRUE
	tool_behaviour = TOOL_KNIFE

	knife_force = emag_force
	force = emag_force
	knife_wound_bonus = 15
	wound_bonus = 15
	knife_bare_wound_bonus = 15
	bare_wound_bonus = 15
	armour_penetration = 35

	icon_state = "wolverine_emag"
	item_state = "wolverine_emag"

	name = "Перегруженные [initial(name)]"
	desc = "[initial(desc)] <span class='warning'>Они потрескивают от опасной энергии!</span>"

	var/mob/user = usr
	if(user)
		to_chat(user, "<span class='warning'>Вы перегружаете [src]! Защитные ограничители отключены!</span>")
		log_admin("[key_name(user)] emagged [src] at [AREACOORD(src)]")

	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

/obj/item/kitchen/knife/razor_claws/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(user.zone_selected == BODY_ZONE_PRECISE_EYES)
		return eyestab(M, user)
	else
		return ..()

/obj/item/kitchen/knife/razor_claws/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] разрезает [user.ru_ego()] горло с помощью [src]! Похоже, [user.p_theyre()] пытается совершить самоубийство.</span>")
	return BRUTELOSS

// ============================================================================
// ИМПЛАНТЫ
// ============================================================================

/obj/item/organ/cyberimp/arm/razor_claws
	name = "Claws implant"
	desc = "Набор из двух пар острых когтей, созданных из лёгких сплавов. Когда хочешь стать тем самым героем из старых фильмов."
	icon = 'modular_bluemoon/icons/mob/actions/razorclaws.dmi'
	icon_state = "wolverine"
	zone = BODY_ZONE_R_ARM
	holder = /obj/item/kitchen/knife/razor_claws

/obj/item/organ/cyberimp/arm/razor_claws/ExtendPlaySound(obj/item/I)
	. = ..()
	if(obj_flags & EMAGGED)
		playsound(get_turf(owner), 'sound/items/unsheath.ogg', 100, TRUE)
		playsound(get_turf(owner), 'sound/machines/warning-buzzer.ogg', 35, TRUE)
	else
		playsound(get_turf(owner), 'sound/items/unsheath.ogg', 100, TRUE)

/obj/item/organ/cyberimp/arm/razor_claws/RetractPLaySound()
	// Громкие звуки если имплант взломан
	if(obj_flags & EMAGGED)
		playsound(get_turf(owner), 'sound/items/sheath.ogg', 75, TRUE)
	else
		playsound(get_turf(owner), 'sound/items/sheath.ogg', 50, TRUE)
	return ..()

/obj/item/organ/cyberimp/arm/razor_claws/emag_act()
	. = ..()
	if(obj_flags & EMAGGED)
		return

	obj_flags |= EMAGGED

	for(var/obj/item/I in items_list)
		I.emag_act()

	var/mob/user = usr
	if(user)
		to_chat(user, "<span class='warning'>Вы взламываете [src]! Теперь имплант работает на максимальной мощности и издаёт громкие звуки!</span>")
		log_admin("[key_name(user)] emagged [src] at [AREACOORD(src)]")
		playsound(get_turf(user), 'sound/machines/warning-buzzer.ogg', 50, TRUE)

/obj/item/organ/cyberimp/arm/razor_claws/left
	zone = BODY_ZONE_L_ARM

// ============================================================================
// КВИРК
// ============================================================================

/datum/quirk/retractable_claws
	name = "Когтистые ручки"
	desc = "У вас врождённые, а может мутировавшие пальчики, что имеют острые когти. Всё довольно просто. Достаточно острые, чтобы что-то перерезать или оставить на врагах раны. Не забудьте поточить их, если каким-то чудом найдёте точильный камень."
	value = 1
	mob_trait = TRAIT_RETRACTABLE_CLAWS
	gain_text = "<span class='notice'>Ваши пальчики ощущают когти внутри...</span>"
	lose_text = "<span class='notice'>Ваши пальцы снова кажутся обычными.</span>"
	medical_record_text = "Пациент имеет органические острые и длинные когти."

/datum/quirk/retractable_claws/add()
	var/mob/living/carbon/human/H = quirk_holder

	var/arm = H.get_bodypart(BODY_ZONE_L_ARM)
	if(arm)
		var/impl = H.getorganslot(ORGAN_SLOT_LEFT_ARM_AUG)
		if(!impl)
			// Создаем имплант для ЛЕВОЙ руки
			var/obj/item/organ/cyberimp/arm/claws/left/L = new()
			L.Insert(H)

	arm = H.get_bodypart(BODY_ZONE_R_ARM)
	if(arm)
		var/impl = H.getorganslot(ORGAN_SLOT_RIGHT_ARM_AUG)
		if(!impl)
			// Создаем имплант для ПРАВОЙ руки
			var/obj/item/organ/cyberimp/arm/claws/R = new()
			R.Insert(H)

/datum/quirk/retractable_claws/remove()
	var/mob/living/carbon/human/H = quirk_holder

	// Удаляем имплант из ЛЕВОЙ руки
	var/obj/item/organ/cyberimp/arm/claws/L = H.getorganslot(ORGAN_SLOT_LEFT_ARM_AUG)
	if(istype(L))
		L.Remove(H)
		qdel(L)

	// Удаляем имплант из ПРАВОЙ руки
	var/obj/item/organ/cyberimp/arm/claws/R = H.getorganslot(ORGAN_SLOT_RIGHT_ARM_AUG)
	if(istype(R))
		R.Remove(H)
		qdel(R)

// ============================================================================
// ИМПЛАНТЫ ДЛЯ КВИРКА (используют натуральные когти)
// ============================================================================

/obj/item/organ/cyberimp/arm/claws
	name = "Retractable claws"
	desc = "У вас есть острые когти, они втягиваются и вытягиваются на ваших кончиках пальцев с помощью ваших же мышц."
	icon = 'modular_bluemoon/icons/mob/actions/razorclaws.dmi'
	icon_state = "claw"
	zone = BODY_ZONE_R_ARM
	holder = /obj/item/kitchen/knife/claws/natural

// Тихий органический звук вместо механического
/obj/item/organ/cyberimp/arm/claws/ExtendPlaySound(obj/item/I)
	playsound(get_turf(owner), 'sound/items/unsheath.ogg', 5, TRUE)

// Тихий органический звук вместо механического
/obj/item/organ/cyberimp/arm/claws/RetractPLaySound()
	playsound(get_turf(owner), 'sound/items/sheath.ogg', 5, TRUE)

/obj/item/organ/cyberimp/arm/claws/left
	zone = BODY_ZONE_L_ARM
