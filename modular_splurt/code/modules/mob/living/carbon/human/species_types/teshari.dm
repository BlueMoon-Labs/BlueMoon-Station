#define TESHARI_TEMP_OFFSET -30 // K, added to comfort/damage limit etc
#define TESHARI_BURNMOD 1 // They take more damage from practically everything
#define TESHARI_BRUTEMOD 1
#define TESHARI_HEATMOD 1.3
#define TESHARI_COLDMOD 0.67 // Except cold.
#define TESHARI_DAMAGE_SLOWDOWN_THRESHOLD 30 // Минимальный порог урона для замедления


/datum/species/mammal/teshari
	name = "Teshari"
	id = SPECIES_TESHARI
	say_mod = "mars"
	eye_type = "teshari"
	mutant_bodyparts = list("mcolor" = "FFFFFF", "mcolor2" = "FFFFFF", "mcolor3" = "FFFFFF", "mam_tail" = "teshari tail, colorable", "mam_ears" = "None", "mam_body_markings" = list())
	allowed_limb_ids = null
	override_bp_icon = 'modular_splurt/icons/mob/teshari.dmi'
	damage_overlay_type = "teshari"
	species_language_holder = /datum/language_holder/teshari
	exotic_blood_color = "#D514F7"
	disliked_food = GROSS | GRAIN
	liked_food = MEAT
	payday_modifier = 0.75
	attack_verb = "claw"
	attack_sound = 'sound/weapons/slash.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'
	ass_image = 'icons/ass/asslizard.png'

	species_traits = list(MUTCOLORS,
		EYECOLOR,
		NO_UNDERWEAR,
		HAIR,
		FACEHAIR,
		MARKINGS
		)

	coldmod = TESHARI_COLDMOD
	heatmod = TESHARI_HEATMOD
	brutemod = TESHARI_BRUTEMOD
	burnmod = TESHARI_BURNMOD


/datum/species/mammal/teshari/on_species_gain(mob/living/carbon/human/C, datum/species/old_species, pref_load)
	. = ..()
	if(ishuman(C))
		C.verbs += /mob/living/carbon/human/proc/sonar_ping
		C.verbs += /mob/living/carbon/human/proc/hide
		C.setMaxHealth(50)
		C.physiology.hunger_mod *= 2
		C.add_movespeed_modifier(/datum/movespeed_modifier/teshari)

// Переопределяем spec_updatehealth для Тешари с порогом урона
/datum/species/mammal/teshari/spec_updatehealth(mob/living/carbon/human/H)
	if(HAS_TRAIT(H, TRAIT_IGNORESLOWDOWN) || HAS_TRAIT(H, TRAIT_IGNOREDAMAGESLOWDOWN))
		return

	var/scaling = H.maxHealth / 100
	var/health_deficiency = max(((H.maxHealth / scaling) - (H.health / scaling)), max(0, H.getStaminaLoss() - 39))

	// Применяем порог урона для Тешари
	health_deficiency = max(0, health_deficiency - TESHARI_DAMAGE_SLOWDOWN_THRESHOLD)

	if(health_deficiency >= 10) // Небольшой порог после основного, чтобы избежать мерцания
		H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown, TRUE, health_deficiency / 75)
		H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying, TRUE, health_deficiency / 25)
	else
		H.remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown)
		H.remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying)

/datum/movespeed_modifier/teshari
	multiplicative_slowdown = -0.2

/datum/emote/sound/teshari
	mob_type_allowed_typecache = list(/mob/living/)
	emote_type = EMOTE_AUDIBLE

/datum/language_holder/teshari
	understood_languages = list(/datum/language/common = list(LANGUAGE_ATOM),
								/datum/language/modular_splurt/avian = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/common = list(LANGUAGE_ATOM),
							/datum/language/modular_splurt/avian = list(LANGUAGE_ATOM))

/datum/language/schechi

/datum/emote/sound/teshari/teshsqueak
	key = "surprised"
	key_third_person = "surprised"
	message = "chirps in surprise!"
	message_mime = "lets out an <b>inaudible</b> chirp!"
	sound = 'modular_splurt/sound/voice/teshsqueak.ogg'
	emote_cooldown = 2.1 SECONDS

/datum/emote/sound/teshari/teshsqueak/run_emote(mob/user, params)
	var/datum/dna/D = user.has_dna()
	if(D.species.name != "Teshari")
		return
	. = ..()

/datum/emote/sound/teshari/teshchirp
	key = "tchirp"
	key_third_person = "tchirp"
	message = "chirps!"
	message_mime = "lets out an <b>inaudible</b> chirp!"
	sound = 'modular_splurt/sound/voice/teshchirp.ogg'
	emote_cooldown = 2.1 SECONDS

/datum/emote/sound/teshari/teshchirp/run_emote(mob/user, params)
	var/datum/dna/D = user.has_dna()
	if(D.species.name != "Teshari")
		return
	. = ..()

/datum/emote/sound/teshari/trill
	key = "trill"
	key_third_person = "trill"
	message = "trills!"
	message_mime = "lets out an <b>inaudible</b> chirp!"
	sound = 'modular_splurt/sound/voice/teshtrill.ogg'
	emote_cooldown = 2.1 SECONDS

/datum/emote/sound/teshari/trill/run_emote(mob/user, params)
	var/datum/dna/D = user.has_dna()
	if(D.species.name != "Teshari")
		return
	. = ..()

/datum/emote/sound/teshari/teshscream
	key = "teshscream"
	key_third_person = "teshscream"
	message = "screams!"
	message_mime = "lets out an <b>inaudible</b> screams!"
	sound = 'modular_splurt/sound/voice/teshscream.ogg'
	emote_cooldown = 2.1 SECONDS

/datum/emote/sound/teshari/teshscream/run_emote(mob/user, params)
	var/datum/dna/D = user.has_dna()
	if(D.species.name != "Teshari")
		return
	. = ..()

/mob/living/carbon/human
	var/next_sonar_ping = 0
	var/hiding = 0
	var/list/sonar_markers // Список активных маркеров для очистки

/mob/living/carbon/human/proc/hide()
	set name = "Hide"
	set desc = "Allows to hide beneath tables or certain items. Toggled on or off."
	set category = "Abilities"

	if(stat == DEAD || restrained() || buckled|| has_buckled_mobs())
		return

	if(hiding)
		plane = initial(plane)
		layer = initial(layer)
		to_chat(usr, "<span class='notice'>You have stopped hiding.</span>")
		hiding = 0
	else
		hiding = 1
		layer = BELOW_OBJ_LAYER
		plane = GAME_PLANE
		to_chat(src,"<span class='notice'>You are now hiding.</span>")


/mob/living/carbon/human/proc/sonar_ping()
	set name = "Listen In"
	set desc = "Allows you to listen in to movement and noises around you."
	set category = "Abilities"

	if(incapacitated())
		to_chat(src, "<span class='warning'>Вам нужно восстановить силы чтобы снова слушать.</span>")
		return

	if(world.time < next_sonar_ping)
		to_chat(src, "<span class='warning'>Вам нужно время сфокусироваться.</span>")
		return

	var/obj/item/organ/ears/ears = getorganslot(ORGAN_SLOT_EARS)
	if(ears && ears.deaf > 0)
		to_chat(src, "<span class='warning'>Вы оглохли достаточно сильно или вовсе чтобы ловить шум</span>")
		return

	next_sonar_ping = world.time + 10 SECONDS

	to_chat(src, "<span class='notice'>Вы останавливаетесь чтобы прислушаться к окружению...</span>")

	var/heard_something = FALSE
	var/list/markers = list()

	if(!client)
		return

	// Запоминаем начальную позицию игрока
	var/start_x = src.x
	var/start_y = src.y
	var/start_z = src.z

	for(var/mob/living/L in range(7, src))
		if(L == src || L.stat == DEAD)
			continue

		heard_something = TRUE

		// Запоминаем абсолютную позицию цели
		var/target_x = L.x
		var/target_y = L.y
		var/target_z = L.z

		// Создаём screen object - он ВСЕГДА виден
		var/atom/movable/screen/sonar_ping/marker = new()
		marker.icon = 'icons/effects/effects.dmi'
		marker.icon_state = "medi_holo"

		// Сохраняем координаты для обновления позиции
		marker.target_x = target_x
		marker.target_y = target_y
		marker.target_z = target_z

		client.screen += marker
		markers += marker

		// Обновляем позицию маркера на экране
		marker.update_position(src, start_x, start_y, start_z)

	// Сохраняем список маркеров
	sonar_markers = markers

	// Обновляем позиции маркеров
	addtimer(CALLBACK(src, PROC_REF(update_sonar_positions), markers, start_x, start_y, start_z, 0), 0.1 SECONDS)

	// Удаляем через 3 секунды
	addtimer(CALLBACK(src, PROC_REF(remove_sonar_markers), markers), 3 SECONDS)

	if(!heard_something)
		to_chat(src, "<span class='notice'>Вы ничего не слышите кроме как себя.</span>")
	else
		to_chat(src, "<span class='notice'>Вы улавливаете звуки движения поблизости...</span>")

// Рекурсивное обновление позиций маркеров
/mob/living/carbon/human/proc/update_sonar_positions(list/markers, start_x, start_y, start_z, iteration)
	if(iteration >= 30 || !client) // 30 итераций = 3 секунды
		return

	for(var/atom/movable/screen/sonar_ping/marker in markers)
		if(!QDELETED(marker))
			marker.update_position(src, start_x, start_y, start_z)

	// Следующая итерация через 0.1 секунды
	addtimer(CALLBACK(src, PROC_REF(update_sonar_positions), markers, start_x, start_y, start_z, iteration + 1), 0.1 SECONDS)

// Удаление маркеров
/mob/living/carbon/human/proc/remove_sonar_markers(list/markers)
	if(client)
		client.screen -= markers
	for(var/atom/movable/screen/S in markers)
		qdel(S)

/atom/movable/screen/sonar_ping
	name = ""
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_HUD_PLANE
	layer = ABOVE_HUD_LAYER
	var/target_x
	var/target_y
	var/target_z

/atom/movable/screen/sonar_ping/proc/update_position(mob/observer, start_x, start_y, start_z)
	if(!observer || observer.z != start_z || target_z != start_z)
		alpha = 0 // Скрываем если на другом Z-уровне
		return

	// Вычисляем смещение от начальной позиции активации
	var/x_offset = target_x - start_x
	var/y_offset = target_y - start_y

	// Корректируем на текущее положение наблюдателя
	var/current_x_offset = x_offset - (observer.x - start_x)
	var/current_y_offset = y_offset - (observer.y - start_y)

	// Скрываем маркеры которые слишком далеко от центра экрана (за пределами ~7 клеток)
	if(abs(current_x_offset) > 9 || abs(current_y_offset) > 7)
		alpha = 0
		return
	else
		alpha = 255 // Показываем маркер

	screen_loc = "CENTER[current_x_offset >= 0 ? "+" : ""][current_x_offset],CENTER[current_y_offset >= 0 ? "+" : ""][current_y_offset]"
