/// "[z]" -> world.time, до которого HK-50 этого уровня молчат: стая не звучит хором, а соседний уровень слышит своих.
GLOBAL_LIST_EMPTY(hk50_voice_quiet_until)

/mob/living/simple_animal/hostile/hk50
	name = "HK-50 assassin droid"
	desc = "Серийный дроид-ассасин HK-50: дешёвая копия HK-47 в серо-зелёном оружейном корпусе. Косые янтарные фотоприёмники не мигают. Как любой дроид, боится ЭМИ: импульс прожигает схемы и ненадолго его отключает."
	icon = 'modular_bluemoon/icons/mob/hk_droids/hk50.dmi'
	icon_state = "hk50"
	icon_living = "hk50"
	icon_dead = "hk50_dead"
	mob_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	sentience_type = SENTIENCE_ARTIFICIAL
	speak_emote = list("констатирует")
	speed = 0
	maxHealth = 120
	health = 120
	harm_intent_damage = 5
	melee_damage_lower = 10
	melee_damage_upper = 10
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/weapons/punch1.ogg'
	a_intent = INTENT_HARM
	ranged = TRUE
	projectiletype = /obj/item/projectile/beam/laser
	projectilesound = 'sound/weapons/laser.ogg'
	ranged_cooldown_time = 2.5 SECONDS
	retreat_distance = 4
	minimum_distance = 4
	check_friendly_fire = TRUE
	faction = list(FACTION_HK_DROIDS)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	deathmessage = "разваливается грудой лома, рассыпая искры."
	loot = list(/obj/effect/decal/cleanable/robot_debris/hk50, /obj/item/stack/sheet/metal/five)
	del_on_death = TRUE
	footstep_type = FOOTSTEP_MOB_SHOE
	light_system = OVERLAY_LIGHT
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	light_power = 0.1
	light_color = "#FFFFFF"
	/// Реплики в чат не чаще HK50_LINE_COOLDOWN, кроме обязательных.
	var/next_line_time = 0
	/// Конвейер фабрики, на учёте которого дроид: собравший его или принявший стражу с карты.
	var/datum/weakref/factory_ref
	var/photoreceptor_chance = HK50_PHOTORECEPTOR_CHANCE
	/// Страж фабрики: шасси серии HK для него свои.
	var/spares_series = FALSE
	/// Гибель без предсмертной строки: самоликвидацию слуга уже озвучил.
	var/silent_death = FALSE
	var/static/list/voice_lines = list(
		"hk50_foolish" = 'modular_bluemoon/sound/hk_droids/hk50_foolish.ogg',
		"hk50_numbers_grow" = 'modular_bluemoon/sound/hk_droids/hk50_numbers_grow.ogg',
		"hk50_photoreceptors" = 'modular_bluemoon/sound/hk_droids/hk50_photoreceptors.ogg',
		"hk50_selfdestruct" = 'modular_bluemoon/sound/hk_droids/hk50_selfdestruct.ogg',
	)

/mob/living/simple_animal/hostile/hk50/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/mob/living/simple_animal/hostile/hk50/update_overlays()
	. = ..()
	if(stat == DEAD)
		return
	. += emissive_appearance(icon, "hk50_eyes", offset_spokesman = src)

/mob/living/simple_animal/hostile/hk50/emp_act(severity)
	. = ..()
	if((. & EMP_PROTECT_SELF) || stat == DEAD)
		return
	var/heavy = severity >= HK50_EMP_HEAVY_SEVERITY
	adjustFireLoss(heavy ? HK50_EMP_HEAVY_BURN : HK50_EMP_LIGHT_BURN)
	if(QDELETED(src) || stat == DEAD)
		return
	Stun(heavy ? HK50_EMP_HEAVY_STUN : HK50_EMP_LIGHT_STUN, ignore_canstun = TRUE)
	ai_controller?.PauseAi(AmountStun())
	do_sparks(3, FALSE, src)
	visible_message(span_warning("[src] искрит и замирает: ЭМИ сбил его системы."))

/// Слуга бьёт только разрешённое хозяином; стража фабрики не трогает шасси своей серии.
/mob/living/simple_animal/hostile/hk50/CanAttack(atom/the_target)
	var/datum/component/hk50_servant/servitude = GetComponent(/datum/component/hk50_servant)
	if(servitude)
		if(!servitude.allows_target(the_target))
			return FALSE
	else if(spares_series && is_species(the_target, /datum/species/ipc/hk))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/hk50/GiveTarget(new_target)
	var/had_target = !isnull(target)
	. = ..()
	if(had_target || !isliving(target))
		return
	if(factory_ref)
		hk50_say("Глупо думать, что мы выпустим вас из цеха.", voice = "hk50_foolish")
	else
		hk50_say("Глупо думать, что мы позволим вам унести эти сведения своему хозяину.", voice = "hk50_foolish")

/mob/living/simple_animal/hostile/hk50/death(gibbed)
	if(stat != DEAD)
		if(!silent_death)
			hk50_say("Мои фотоприёмники!", forced = TRUE, prefix = HK_PREFIX_EXCLAMATION, voice = "hk50_photoreceptors")
		do_sparks(4, FALSE, src)
		if(!GetComponent(/datum/component/hk50_servant) && prob(photoreceptor_chance))
			new /obj/item/organ/eyes/robotic/hk50(drop_location())
	set_light_on(FALSE)
	. = ..()
	if(!QDELETED(src))
		update_appearance(UPDATE_OVERLAYS)

/// Реплика в чат с префиксом HK и голосовой строкой voice из voice_lines; TRUE, если прозвучала.
/mob/living/simple_animal/hostile/hk50/proc/hk50_say(message, forced = FALSE, prefix = HK_PREFIX_STATEMENT, voice)
	if(!forced && world.time < next_line_time)
		return FALSE
	next_line_time = world.time + HK50_LINE_COOLDOWN
	INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, say), "[prefix] [message]")
	if(voice)
		hk50_voice(voice, forced)
	return TRUE

/// Голосовая строка; кроме обязательных, одна на всех HK-50 уровня за HK50_LINE_COOLDOWN.
/mob/living/simple_animal/hostile/hk50/proc/hk50_voice(sound_key, forced = FALSE)
	var/voice = voice_lines[sound_key]
	var/turf/here = get_turf(src)
	if(!voice || !here)
		return FALSE
	var/level = "[here.z]"
	if(!forced && world.time < GLOB.hk50_voice_quiet_until[level])
		return FALSE
	if(!hk_voice_line(src, voice, volume = HK50_VOICE_VOLUME, extra_range = 0))
		return FALSE
	GLOB.hk50_voice_quiet_until[level] = world.time + HK50_LINE_COOLDOWN
	return TRUE

/obj/effect/decal/cleanable/robot_debris/hk50
	name = "HK-50 wreck"
	desc = "Груда лома, оставшаяся от дроида-ассасина HK-50: обгоревшая проводка и смятые пластины корпуса. Фотоприёмники иногда переживают своего дроида - такие ставят вместо глаз."
	icon = 'modular_bluemoon/icons/mob/hk_droids/hk50.dmi'
	icon_state = "hk50_dead"
	random_icon_states = null

/// Фотоприёмники с обломков HK-50: кибер-глаза со светофильтром.
/obj/item/organ/eyes/robotic/hk50
	name = "HK-50 photoreceptors"
	desc = "Косые янтарные фотоприёмники, снятые с обломков HK-50. Ставятся вместо глаз как обычные кибернетические: встроенный светофильтр гасит вспышки, как солнечные очки. ЭМИ сбивает им картинку, как любым кибер-глазам."
	left_eye_color = "ffa31a"
	right_eye_color = "ffa31a"
	flash_protect = 1

/// Боёк лазера HK-50: сверяет сигнатуру шасси серии HK.
/obj/item/firing_pin/hk_chassis
	name = "HK chassis firing pin"
	desc = "Боёк встроенного лазера HK-50: стреляет, только пока стоит в шасси серии HK."
	fail_message = "<span class='warning'>СИГНАТУРА ШАССИ HK НЕ ОПОЗНАНА.</span>"
	pin_removeable = FALSE

/obj/item/firing_pin/hk_chassis/pin_auth(mob/living/user)
	return is_species(user, /datum/species/ipc/hk)

/obj/item/gun/energy/laser/mounted/hk50
	name = "HK-50 arm laser"
	desc = "Лазер в предплечье HK-50. Выдвигается из руки и сам перезаряжается, но боёк сверяет сигнатуру: стреляет только у дроидов серии HK."
	icon = 'modular_bluemoon/icons/obj/hk_droids/hk50_laser.dmi'
	icon_state = "hk50_laser"
	item_state = "hk50_laser"
	lefthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk50_laser_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk50_laser_righthand.dmi'
	pin = /obj/item/firing_pin/hk_chassis

/obj/item/gun/energy/e_gun/advtaser/mounted/hk51
	name = "HK-51 arm taser"
	desc = "Тазер в предплечье HK-51: дизейблер, а правым кликом в боевом режиме - электрод. Сам перезаряжается, но боёк сверяет сигнатуру шасси: стреляет только у дроидов серии HK."
	pin = /obj/item/firing_pin/hk_chassis

/obj/item/organ/cyberimp/arm/gun/taser/hk51
	name = "HK-51 arm taser implant"
	desc = "Встроенный тазер HK-51. Боёк сверяет сигнатуру шасси: в руке человека ствол выдвигается и молчит."
	zone = BODY_ZONE_L_ARM
	aug_overlay = null
	contents = newlist(/obj/item/gun/energy/e_gun/advtaser/mounted/hk51)

/obj/item/organ/cyberimp/arm/gun/laser/hk50
	name = "HK-50 arm laser implant"
	desc = "Встроенный лазер HK-50, снятый со сборочной линии. Ставится в руку как обычный имплант, но боёк сверяет сигнатуру шасси: стреляет только у дроидов серии HK - HK-47, HK-50 и HK-51. В руке человека ствол выдвигается и молчит."
	contents = newlist(/obj/item/gun/energy/laser/mounted/hk50)
