// ============================================================================
// БАЗОВЫЙ НОЖ С КОГТЯМИ (для квирка)
// ============================================================================

/obj/item/kitchen/knife/claws
	name = "когти"
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
	var/emagged = FALSE

/obj/item/kitchen/knife/claws/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 80 - force, 100, force - 10)
	ADD_TRAIT(src, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)

/obj/item/kitchen/knife/claws/attack_self(mob/user)
	if(emagged)
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
		if(emagged)
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

/obj/item/kitchen/knife/claws/emag_act(mob/user)
	if(emagged)
		return

	emagged = TRUE
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

	to_chat(user, "<span class='warning'>Вы подключаете провода к плате когтей! Защитные протоколы отключены!</span>")

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
	name = "Втягиваемые когти"
	desc = "У вас есть острые когти, они втягиваются и вытягиваются на ваших кончиках пальцев с помощью ваших же мышц. Довольно опасные если еще и заточить их."
	icon_state = "claw"
	item_state = "claw"
	emagged = FALSE

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

/obj/item/kitchen/knife/claws/natural/emag_act(mob/user)
	to_chat(user, "<span class='warning'>Эти когти являются частью тела и не имеют электроники.</span>")
	return FALSE

// ============================================================================
// ИМПЛАНТ ВЕРСИЯ (для покупки в аплинке и т.д.)
// ============================================================================

/obj/item/kitchen/knife/razor_claws
	name = "Имплантированные бритвенные когти"
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
	var/emagged = FALSE

/obj/item/kitchen/knife/razor_claws/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 80 - force, 100, force - 10)
	// Добавляем TRAIT_NODROP чтобы нельзя было выбросить/передать
	ADD_TRAIT(src, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)

/obj/item/kitchen/knife/razor_claws/attack_self(mob/user)
	if(emagged)
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
		if(emagged)
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

/obj/item/kitchen/knife/razor_claws/emag_act(mob/user)
	if(emagged)
		return

	emagged = TRUE
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

	to_chat(user, "<span class='warning'>Вы перегружаете [src]! Защитные ограничители отключены!</span>")

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
	name = "Имплант когтей"
	desc = "Набор из двух пар острых когтей, созданных из лёгких сплавов. Когда хочешь стать тем самым героем из старых фильмов."
	icon = 'modular_bluemoon/icons/mob/actions/razorclaws.dmi'
	icon_state = "wolverine"
	zone = BODY_ZONE_R_ARM
	holder = /obj/item/kitchen/knife/razor_claws
	var/emagged = FALSE

/obj/item/organ/cyberimp/arm/razor_claws/Extend(obj/item/item)
	. = ..()
	if(.)
		// Громкие звуки если имплант взломан
		if(emagged)
			playsound(get_turf(owner), 'sound/items/unsheath.ogg', 100, TRUE)
			playsound(get_turf(owner), 'sound/machines/warning-buzzer.ogg', 35, TRUE)
		else
			playsound(get_turf(owner), 'sound/items/unsheath.ogg', 100, TRUE)

/obj/item/organ/cyberimp/arm/razor_claws/Retract()
	if(holder && !(holder in src))
		// Громкие звуки если имплант взломан
		if(emagged)
			playsound(get_turf(owner), 'sound/items/sheath.ogg', 75, TRUE)
		else
			playsound(get_turf(owner), 'sound/items/sheath.ogg', 50, TRUE)
	return ..()

/obj/item/organ/cyberimp/arm/razor_claws/emag_act(mob/user)
	if(emagged)
		return

	emagged = TRUE

	// Если когти уже выдвинуты, взламываем их прямо сейчас
	if(holder && !(holder in src))
		var/obj/item/kitchen/knife/razor_claws/claws = holder
		if(istype(claws))
			claws.emag_act(user)

	to_chat(user, "<span class='warning'>Вы взламываете [src]! Теперь имплант работает на максимальной мощности и издаёт громкие звуки!</span>")
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

	// Создаем имплант для ЛЕВОЙ руки
	var/obj/item/organ/cyberimp/arm/claws/left/L = new()
	L.Insert(H)

	// Создаем имплант для ПРАВОЙ руки
	var/obj/item/organ/cyberimp/arm/claws/R = new()
	R.Insert(H)

/datum/quirk/retractable_claws/remove()
	var/mob/living/carbon/human/H = quirk_holder

	// Удаляем имплант из ЛЕВОЙ руки
	var/obj/item/organ/cyberimp/arm/claws/left/L = H.getorganslot(ORGAN_SLOT_LEFT_ARM_AUG)
	if(L)
		L.Remove(H)
		qdel(L)

	// Удаляем имплант из ПРАВОЙ руки
	var/obj/item/organ/cyberimp/arm/claws/R = H.getorganslot(ORGAN_SLOT_RIGHT_ARM_AUG)
	if(R)
		R.Remove(H)
		qdel(R)

// ============================================================================
// ИМПЛАНТЫ ДЛЯ КВИРКА (используют натуральные когти)
// ============================================================================

/obj/item/organ/cyberimp/arm/claws
	name = "Втягиваемые когти"
	desc = "У вас есть острые когти, они втягиваются и вытягиваются на ваших кончиках пальцев с помощью ваших же мышц."
	icon = 'modular_bluemoon/icons/mob/actions/razorclaws.dmi'
	icon_state = "claw"
	zone = BODY_ZONE_R_ARM
	holder = /obj/item/kitchen/knife/claws/natural

// Полностью переопределяем Extend для натуральных когтей (без механических звуков)
/obj/item/organ/cyberimp/arm/claws/Extend(obj/item/item)
	if(!(item in src))
		return

	holder = item

	holder.resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	holder.slot_flags = null
	holder.set_custom_materials(null)

	var/obj/item/arm_item = owner.get_active_held_item()

	if(arm_item)
		if(!owner.dropItemToGround(arm_item))
			to_chat(owner, "<span class='warning'>Ваш [arm_item] мешает выдвинуть [src]!</span>")
			return
		else
			to_chat(owner, "<span class='notice'>Вы роняете [arm_item], чтобы выдвинуть [src]!</span>")

	var/result = (zone == BODY_ZONE_R_ARM ? owner.put_in_r_hand(holder) : owner.put_in_l_hand(holder))
	if(!result)
		to_chat(owner, "<span class='warning'>Ваши [name] не удалось выдвинуть!</span>")
		return

	owner.swap_hand(result)

	owner.visible_message(
		"<span class='notice'>[owner] выпускает [holder] из [owner.ru_ego()] [zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руки.</span>",
		"<span class='notice'>Вы выпускаете [holder] из вашей [zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руки.</span>"
	)
	// Тихий органический звук вместо механического
	playsound(get_turf(owner), 'sound/items/unsheath.ogg', 5, TRUE)
	return TRUE

// Полностью переопределяем Retract для натуральных когтей (без механических звуков)
/obj/item/organ/cyberimp/arm/claws/Retract()
	if(!holder || (holder in src))
		return

	owner.visible_message(
		"<span class='notice'>[owner] втягивает [holder] обратно в [owner.ru_ego()] [zone == BODY_ZONE_R_ARM ? "правую" : "левую"] руку.</span>",
		"<span class='notice'>[capitalize(holder.name)] скользят обратно в вашу [zone == BODY_ZONE_R_ARM ? "правую" : "левую"] руку.</span>"
	)

	owner.transferItemToLoc(holder, src, TRUE)
	holder = null
	// Тихий органический звук вместо механического
	playsound(get_turf(owner), 'sound/items/sheath.ogg', 5, TRUE)

/obj/item/organ/cyberimp/arm/claws/left
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/claws/right
	zone = BODY_ZONE_R_ARM
