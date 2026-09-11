/obj/effect/temp_visual/heretic_path_feedback
	icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
	randomdir = FALSE
	duration = 6

/obj/effect/temp_visual/heretic_path_feedback/Initialize(mapload, effect_state, effect_color, lifetime, direction = SOUTH)
	if(effect_state)
		icon_state = effect_state
	if(effect_color)
		color = effect_color
	if(!isnull(lifetime))
		duration = lifetime
	setDir(direction)
	return ..()

/obj/effect/temp_visual/heretic_path_feedback/blade_mark
	icon_state = "cleave"
	color = "#c5b5f4"

/obj/effect/temp_visual/heretic_path_feedback/moon_mark
	icon_state = "moon_insanity_overlay"
	color = "#dce3ff"
	duration = 12

/obj/effect/temp_visual/heretic_path_feedback/cosmic_mark
	icon_state = "cosmic_gem"
	color = "#b5eaff"
	duration = 12

/// Снимок облика живёт долю секунды и не хранит ссылку на исходное тело.
/obj/effect/temp_visual/heretic_afterimage
	randomdir = FALSE
	duration = 5

/obj/effect/temp_visual/heretic_afterimage/Initialize(mapload, atom/model, tint = "#b6d8ee")
	if(model)
		appearance = model.appearance
	color = tint
	alpha = 120
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = BELOW_MOB_LAYER
	. = ..()
	animate(src, alpha = 0, time = duration)

/datum/eldritch_knowledge
	var/datum/weakref/new_path_relic_ref

/datum/eldritch_knowledge/proc/new_path_relic_available()
	return !new_path_relic_ref?.resolve()

/datum/eldritch_knowledge/proc/make_new_path_relic(mob/living/user, turf/location, relic_type)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!new_path_relic_available() || heretic?.get_knowledge(type) != src)
		return FALSE
	var/obj/item/heretic_path_relic/relic = new relic_type(location)
	relic.creator = WEAKREF(user.mind)
	relic.knowledge_ref = WEAKREF(src)
	new_path_relic_ref = WEAKREF(relic)
	return TRUE

/// При переселении вещь следует за разумом; после потери знания остаётся обычным предметом.
/obj/item/heretic_path_relic
	icon = 'modular_bluemoon/icons/obj/heretic_relics.dmi'
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_relics_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_relics_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/datum/weakref/creator
	var/datum/weakref/knowledge_ref
	var/busy = FALSE
	COOLDOWN_DECLARE(relic_cooldown)

/obj/item/heretic_path_relic/proc/authorized(mob/living/user)
	if(QDELETED(src) || !isliving(user) || !user.mind || user.mind != creator?.resolve() || user.incapacitated() || !user.is_holding(src))
		return FALSE
	var/datum/eldritch_knowledge/knowledge = knowledge_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return knowledge && heretic?.get_knowledge(knowledge.type) == knowledge

/obj/item/heretic_path_relic/examine(mob/user)
	. = ..()
	if(user.mind != creator?.resolve())
		. += span_warning("Вещь настроена на чужой разум.")
	else if(!COOLDOWN_FINISHED(src, relic_cooldown))
		. += span_notice("До следующего применения: [CEILING(COOLDOWN_TIMELEFT(src, relic_cooldown) / (1 SECONDS), 1)] с.")

/obj/item/heretic_path_relic/tuning_fork
	name = "камертон дуэлянта"
	desc = "Камертон с лезвиями вместо зубцов. Сожмите его, держа собственный тёмный клинок во второй руке: две секунды неподвижной настройки причинят 8 ушибов и дадут 1 Темп. Работает только при пустом Темпе и вне стойки; перезарядка 25 секунд."
	icon_state = "tuning_fork"
	var/tuning_time = 2 SECONDS

/obj/item/heretic_path_relic/tuning_fork/proc/can_tune(mob/living/user)
	if(!authorized(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	return knowledge?.held_blade(user) && !knowledge.combat_resource && QDELETED(knowledge.active_parry)

/obj/item/heretic_path_relic/tuning_fork/attack_self(mob/living/user)
	return tune(user)

/obj/item/heretic_path_relic/tuning_fork/proc/tune(mob/living/user)
	if(busy || !can_tune(user))
		return FALSE
	busy = TRUE
	user.visible_message(span_warning("[user] прижимает звенящий камертон к ладони. Лезвия медленно входят в кожу."))
	playsound(user, 'sound/effects/clangsmall1.ogg', 40, FALSE)
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(user), "ring_leader_effect", "#95c5e8", tuning_time)
	var/completed = do_after(user, tuning_time, target = user, extra_checks = CALLBACK(src, PROC_REF(can_tune), user))
	busy = FALSE
	if(!completed || !can_tune(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	user.adjustBruteLoss(8)
	knowledge.gain_combat_resource()
	COOLDOWN_START(src, relic_cooldown, 25 SECONDS)
	playsound(user, 'sound/block_parry/sfx-parry.ogg', 45, FALSE)
	return TRUE

/datum/eldritch_knowledge/blade_guard/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/blade_guard/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/tuning_fork)

/obj/item/heretic_path_relic/silver_mirror
	name = "серебряное ручное зеркало"
	desc = "Направьте зеркало на собственное отражение, затем на видимый свободный пол в пяти клетках. После секунды мерцания копия переместится туда, сохранив срок жизни. Владелец остаётся на месте. Отражение можно разбить во время подготовки; перезарядка 15 секунд."
	icon_state = "silver_mirror"
	var/datum/weakref/selected_reflection
	var/focusing_time = 1 SECONDS

/obj/item/heretic_path_relic/silver_mirror/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(!authorized(user) || busy)
		return
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	if(istype(target, /mob/living/simple_animal/hostile/illusion/heretic_moon) && (target in knowledge?.reflections))
		selected_reflection = WEAKREF(target)
		to_chat(user, span_notice("Отражение поймано. Теперь укажите свободный пол."))
		new /obj/effect/temp_visual/heretic_path_feedback(get_turf(target), "cosmic_ring", "#d9e8ff", 8)
	else if(isturf(target))
		redirect(user, target)

/obj/item/heretic_path_relic/silver_mirror/proc/can_redirect(mob/living/user, turf/target)
	if(!authorized(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = selected_reflection?.resolve()
	if(!knowledge || QDELETED(reflection) || !(reflection in knowledge.reflections) || reflection.knowledge_ref?.resolve() != knowledge || get_turf(reflection) == target)
		return FALSE
	if(!isturf(reflection.loc) || reflection.buckled)
		return FALSE
	if(!knowledge.valid_reflection_turf(get_turf(reflection), user, ignored_reflection = reflection) || !knowledge.valid_reflection_turf(target, user))
		return FALSE
	for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/other as anything in knowledge.reflections)
		if(get_turf(other) == target)
			return FALSE
	return TRUE

/obj/item/heretic_path_relic/silver_mirror/proc/redirect(mob/living/user, turf/target)
	if(busy || !can_redirect(user, target))
		return FALSE
	busy = TRUE
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = selected_reflection.resolve()
	new /obj/effect/temp_visual/heretic_path_feedback(target, "cosmic_ring", "#d9e8ff", focusing_time)
	playsound(target, 'modular_bluemoon/sound/heretic/moon_reflection.ogg', 35, TRUE)
	var/completed = do_after(user, focusing_time, target = user, extra_checks = CALLBACK(src, PROC_REF(can_redirect), user, target))
	busy = FALSE
	if(!completed || !can_redirect(user, target))
		return FALSE
	var/turf/origin = get_turf(reflection)
	new /obj/effect/temp_visual/heretic_afterimage(origin, reflection, "#b7c9ee")
	reflection.forceMove(target)
	new /obj/effect/temp_visual/heretic_path_feedback(target, "cosmic_ring", "#d9e8ff", 8)
	COOLDOWN_START(src, relic_cooldown, 15 SECONDS)
	return TRUE

/datum/eldritch_knowledge/moon_shroud/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/moon_shroud/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/silver_mirror)

/obj/item/heretic_path_relic/astrolabe
	name = "звёздная астролябия"
	desc = "Стоя рядом с первой звездой, сожмите астролябию: после полутора секунд подготовки созвездие повернётся на четверть оборота по часовой стрелке. Все звёзды должны быть в семи клетках; стены, занятые клетки и разорванные линии мешают повороту. Прочность и срок жизни звёзд сохраняются. Перезарядка 25 секунд."
	icon_state = "astrolabe"
	var/alignment_time = 1.5 SECONDS

/obj/item/heretic_path_relic/astrolabe/attack_self(mob/living/user)
	return realign(user)

/obj/item/heretic_path_relic/astrolabe/proc/realign(mob/living/user)
	if(busy || !authorized(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/list/plan = knowledge?.rotation_targets(user)
	if(!length(plan))
		to_chat(user, span_warning("Встаньте рядом с первой звездой. Для поворота нужны свободные клетки и не менее двух звёзд."))
		return FALSE
	busy = TRUE
	for(var/obj/structure/heretic_star/star as anything in plan)
		new /obj/effect/temp_visual/heretic_path_feedback(plan[star], "cosmic_carpet", "#a7ddeb", alignment_time)
	playsound(user, 'modular_bluemoon/sound/heretic/cosmic_align.ogg', 35, FALSE)
	var/completed = do_after(user, alignment_time, target = user, extra_checks = CALLBACK(src, PROC_REF(authorized), user))
	busy = FALSE
	if(!completed || !authorized(user) || QDELETED(knowledge) || !knowledge.rotate_constellation(user, plan))
		return FALSE
	COOLDOWN_START(src, relic_cooldown, 25 SECONDS)
	return TRUE

/datum/eldritch_knowledge/cosmic_resonance/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/cosmic_resonance/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/astrolabe)
