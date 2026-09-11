#define HERETIC_ASCENSION_OMEN_DURATION (30 SECONDS)
#define HERETIC_ASCENSION_WARNING_COOLDOWN (3 MINUTES)

/datum/heretic_path
	var/ascension_title
	var/ascension_message
	var/ascension_omen
	var/ascension_sound
	var/ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
	var/ascension_aura_state
	var/ascension_aura_color
	var/ascension_aura_height = 12
	var/ascension_aura_scale = 1
	var/ascension_aura_background = FALSE

/datum/heretic_path/ash
	ascension_title = "Пепельный Лорд"
	ascension_message = "Пепел поднимается к потолку. Последний фонарь вновь зажжён."
	ascension_omen = "Свет на мгновение кажется пламенем. Запах пепла проникает даже под герметичный шлем."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_ash.ogg'
	ascension_aura_icon = 'icons/effects/turf_fire.dmi'
	ascension_aura_state = "red_big"
	ascension_aura_color = COLOR_WHITE
	ascension_aura_height = 4
	ascension_aura_scale = 1.5
	ascension_aura_background = TRUE

/datum/heretic_path/rust
	ascension_title = "Посланник Ржавчины"
	ascension_message = "Сталь отзывается протяжным стоном. Ржавые холмы приняли нового хозяина."
	ascension_omen = "На языке появляется привкус железа. Кажется, за каждой стеной скребутся корни."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_rust.ogg'
	ascension_aura_icon = 'icons/effects/eldritch.dmi'
	ascension_aura_state = "cloud_swirl"
	ascension_aura_color = COLOR_WHITE
	ascension_aura_height = 0
	ascension_aura_scale = 1.5
	ascension_aura_background = TRUE

/datum/heretic_path/flesh
	ascension_title = "Повелитель Ночи"
	ascension_message = "Под обшивкой бьётся чужое сердце. Процессия Плоти встречает своего повелителя."
	ascension_omen = "Чужой пульс на мгновение совпадает с вашим. В тёмном стекле открывается красный глаз."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_flesh.ogg'
	ascension_aura_state = "eye_pulse"
	ascension_aura_height = 22

/datum/heretic_path/void
	ascension_title = "Аристократ Пустоты"
	ascension_message = "Зимняя буря проходит сквозь завесу. Начинается последний вальс."
	ascension_omen = "Каждый звук приходит будто издалека. Снег мерещится даже там, где ему неоткуда взяться."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_void.ogg'
	ascension_aura_state = "cloud_swirl"
	ascension_aura_height = 0

/datum/heretic_path/blade
	ascension_title = "Чемпион Последнего Клинка"
	ascension_message = "В воздухе звенит сталь. Последний поединок окончен, и его победитель выходит за пределы человеческого."
	ascension_omen = "На краю зрения смыкаются лезвия. Слышен звон удара, который ещё никто не нанёс."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_blade.ogg'
	ascension_aura_state = "ring_leader_effect"
	ascension_aura_height = 0
	ascension_aura_background = TRUE

/datum/heretic_path/moon
	ascension_title = "Владыка Обратной Луны"
	ascension_message = "Отражения поворачиваются к невидимой луне. По ту сторону зеркала больше нет пустого места."
	ascension_omen = "Ваше отражение запаздывает на один вдох. Кажется, оно смотрит на кого-то за вашей спиной."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_moon.ogg'
	ascension_aura_state = "moon_insanity_overlay"
	ascension_aura_height = 12

/datum/heretic_path/cosmic
	ascension_title = "Живое Созвездие"
	ascension_message = "Звёздные карты утратили смысл. Новое небо раскрылось внутри станции."
	ascension_omen = "Между знакомыми предметами проступают незнакомые звёзды. Расстояние до потолка кажется бесконечным."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_cosmic.ogg'
	ascension_aura_state = "cosmic_presence"
	ascension_aura_color = COLOR_WHITE
	ascension_aura_height = 0
	ascension_aura_scale = 1.5
	ascension_aura_background = TRUE

/datum/heretic_path/lock
	ascension_title = "Хранитель Последнего Порога"
	ascension_message = "Все замки отвечают одним щелчком. За знакомыми дверями проступает дом без выхода."
	ascension_omen = "Вы на мгновение забываете, с какой стороны двери стоите. Из замочной скважины доносится чужой вдох."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_lock.ogg'
	ascension_aura_state = "lock_presence"
	ascension_aura_color = COLOR_WHITE
	ascension_aura_height = 0
	ascension_aura_scale = 1.5
	ascension_aura_background = TRUE

/datum/heretic_path/tide
	ascension_title = "Владыка Бездонного Прилива"
	ascension_message = "За стенами звучит погребальный колокол. Невидимое море достигло станции, и его глубина больше не имеет дна."
	ascension_omen = "Уши закладывает от чужой глубины. Сквозь пол на мгновение видны тёмные волны."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_tide.ogg'
	ascension_aura_state = "tide_aura"
	ascension_aura_height = 10

/datum/eldritch_knowledge/final_eldritch
	var/obj/effect/heretic_ascension_aura/ascension_aura
	COOLDOWN_DECLARE(ascension_warning)

/datum/heretic_path/glass
	ascension_title = "Владыка Тысячи Граней"
	ascension_message = "Каждый витраж раскололся в другом мире. Здесь слышен только звон: разбитый свет обрёл своего хозяина."
	ascension_omen = "Свет распадается на острые полосы. Вы слышите, как трескается стекло, хотя всё вокруг цело."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_glass.ogg'
	ascension_aura_state = "glass_aura"
	ascension_aura_height = 18

/datum/heretic_path/blood
	ascension_title = "Святой Алой Десятины"
	ascension_message = "Алая печать проступает за закрытыми веками. Десятина уплачена; её сборщик больше не принадлежит этому миру."
	ascension_omen = "На языке остаётся вкус железа. На мгновение кажется, что под кожей начертаны незнакомые письмена."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_blood.ogg'
	ascension_aura_state = "blood_aura"
	ascension_aura_color = COLOR_WHITE
	ascension_aura_height = 0
	ascension_aura_scale = 1.5
	ascension_aura_background = TRUE

/// Объявление появляется только после подбора и резервирования настоящих компонентов.
/datum/eldritch_knowledge/final_eldritch/proc/begin_ascension_ritual(mob/living/user, obj/effect/eldritch/rune)
	var/datum/heretic_path/path = GLOB.heretic_paths[route]
	if(!path || finished || !COOLDOWN_FINISHED(src, ascension_warning))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return FALSE
	heretic.announce_threat()
	if(world.time < heretic.ascension_ready_at)
		return FALSE
	COOLDOWN_START(src, ascension_warning, HERETIC_ASCENSION_WARNING_COOLDOWN)
	priority_announce("В секторе «[get_area(rune)]» начался обряд пути [path.name]. До разрыва завесы — [DisplayTimeText(ritual_time)]. Обряд можно прервать: не дайте заклинателю закончить или унесите тела с руны.", "Разрыв завесы — начало обряда", 'sound/misc/notice1.ogg')
	return TRUE

/datum/eldritch_knowledge/final_eldritch/proc/abort_ascension_ritual(area/ritual_area, ritual_elapsed)
	if(finished || !isnum(ritual_elapsed) || ritual_elapsed < 0)
		return FALSE
	priority_announce("Обряд в секторе «[ritual_area]» прерван. Завеса удержалась; заклинатель может попытаться снова.", "Разрыв завесы — обряд прерван", 'sound/misc/notice2.ogg')
	return TRUE

/// Повторная привязка к телу переносит нимб, но не повторяет событие для всей станции.
/datum/eldritch_knowledge/final_eldritch/proc/announce_ascension(mob/living/user)
	var/datum/heretic_path/path = GLOB.heretic_paths[route]
	if(!path || !finished)
		return
	priority_announce("[path.ascension_message] [path.ascension_title] — [user.real_name]. Вознесение завершено в секторе «[get_area(user)]».", "Разрыв завесы — вознесение", sound(path.ascension_sound, channel = CHANNEL_EVENT_MUSIC))
	user.visible_message(span_userdanger("[path.ascension_title] предстаёт перед вами. Вокруг [user] раскрывается чужая реальность!"))
	new /obj/effect/temp_visual/heretic_ascension_echo(get_turf(user), route)
	for(var/mob/living/carbon/witness as anything in GLOB.player_list)
		if(!istype(witness) || !witness.client || witness.stat == DEAD)
			continue
		var/turf/witness_turf = get_turf(witness)
		if(!witness_turf || (!is_station_level(witness_turf.z) && witness_turf.z != user.z))
			continue
		witness.apply_status_effect(/datum/status_effect/heretic_ascension_omen, route)
	notify_ghosts("[user.real_name] завершает вознесение: [path.ascension_title].", source = user, action = NOTIFY_ORBIT, header = "Разрыв завесы")

/datum/eldritch_knowledge/final_eldritch/proc/apply_ascension_presence(mob/living/user)
	if(!GLOB.heretic_paths[route])
		return
	ascension_aura = new(null, route)
	user.vis_contents += ascension_aura
	RegisterSignal(user, COMSIG_PARENT_EXAMINE, PROC_REF(on_ascended_examine))
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_ascended_body_deleted))

/datum/eldritch_knowledge/final_eldritch/proc/remove_ascension_presence()
	if(applied_body)
		UnregisterSignal(applied_body, list(COMSIG_PARENT_EXAMINE, COMSIG_PARENT_QDELETING))
		applied_body.vis_contents -= ascension_aura
	QDEL_NULL(ascension_aura)

/datum/eldritch_knowledge/final_eldritch/proc/on_ascended_body_deleted(mob/living/source)
	SIGNAL_HANDLER
	on_body_lose(source)

/datum/eldritch_knowledge/final_eldritch/proc/on_ascended_examine(datum/source, mob/examiner, list/examine_list)
	SIGNAL_HANDLER
	var/datum/heretic_path/path = GLOB.heretic_paths[route]
	if(path)
		examine_list += span_eldritch("[path.ascension_title]. Человеческий облик больше не скрывает то, что смотрит на вас из-за завесы.")

/obj/effect/heretic_ascension_aura
	name = "нимб вознесённого"
	icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
	plane = ABOVE_LIGHTING_PLANE
	layer = ABOVE_LIGHTING_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_TRANSFORM
	alpha = 175
	vis_flags = VIS_INHERIT_ID

/obj/effect/heretic_ascension_aura/Initialize(mapload, path_id)
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(!path)
		return INITIALIZE_HINT_QDEL
	icon = path.ascension_aura_icon
	icon_state = path.ascension_aura_state
	color = path.ascension_aura_color || path.book_tint
	pixel_y = path.ascension_aura_height
	transform = matrix() * path.ascension_aura_scale
	if(path.ascension_aura_background)
		plane = GAME_PLANE
		layer = FLOAT_LAYER
		vis_flags |= VIS_INHERIT_PLANE | VIS_UNDERLAY
		appearance_flags |= KEEP_APART | PIXEL_SCALE
	if(path_id == PATH_BLADE)
		for(var/blade_index in 1 to 8)
			var/blade_angle = blade_index * 45
			var/mutable_appearance/blade = mutable_appearance('modular_bluemoon/icons/obj/heretic_grasp.dmi', "blade_grasp")
			blade.transform = matrix(blade_angle, MATRIX_ROTATE) * 0.5
			blade.pixel_x = round(sin(blade_angle) * 18)
			blade.pixel_y = round(cos(blade_angle) * 18)
			add_overlay(blade)
	animate(src, pixel_y = pixel_y + (path.ascension_aura_background ? 0 : 3), alpha = 220, time = 2 SECONDS, loop = -1, easing = SINE_EASING)
	animate(pixel_y = path.ascension_aura_height, alpha = 175, time = 2 SECONDS, easing = SINE_EASING)

/obj/effect/temp_visual/heretic_ascension_echo
	icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
	layer = ABOVE_MOB_LAYER
	duration = 3 SECONDS
	alpha = 180
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/heretic_ascension_echo/Initialize(mapload, path_id)
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(!path)
		return INITIALIZE_HINT_QDEL
	icon = path.ascension_aura_icon
	icon_state = path.ascension_aura_state
	color = path.ascension_aura_color || path.book_tint
	animate(src, transform = matrix(3, 0, 0, 0, 3, 0), alpha = 0, pixel_y = 12, time = duration)

/// Короткое знамение не меняет зрение, здоровье, управление или постоянный цвет клиента.
/datum/status_effect/heretic_ascension_omen
	id = "heretic_ascension_omen"
	duration = HERETIC_ASCENSION_OMEN_DURATION
	tick_interval = 10 SECONDS
	alert_type = null
	on_remove_on_mob_delete = TRUE
	var/path_id
	var/fullscreen_key
	var/image/personal_echo
	var/echo_viewer_ref

/datum/status_effect/heretic_ascension_omen/on_creation(mob/living/new_owner, chosen_path)
	path_id = chosen_path
	fullscreen_key = "heretic_ascension-[REF(src)]"
	return ..()

/datum/status_effect/heretic_ascension_omen/on_apply()
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(!iscarbon(owner) || !path)
		return FALSE
	to_chat(owner, span_eldritch(path.ascension_omen))
	owner.playsound_local(get_turf(owner), 'sound/effects/ghost2.ogg', 25, FALSE)
	var/atom/movable/screen/fullscreen/omen = owner.overlay_fullscreen(fullscreen_key, /atom/movable/screen/fullscreen/heretic_omen)
	omen.color = path.book_ink
	animate(omen, alpha = 35, time = 4 SECONDS)
	animate(alpha = 20, time = 18 SECONDS)
	animate(alpha = 0, time = 8 SECONDS)
	return TRUE

/datum/status_effect/heretic_ascension_omen/tick()
	clear_echo()
	if(owner.client && owner.stat != DEAD)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		personal_echo = image(path.ascension_aura_icon, owner, path.ascension_aura_state, ABOVE_LIGHTING_LAYER)
		personal_echo.plane = ABOVE_LIGHTING_PLANE
		personal_echo.color = path.ascension_aura_color || path.book_tint
		personal_echo.alpha = 180
		echo_viewer_ref = REF(owner.client)
		owner.client.images += personal_echo
		animate(personal_echo, transform = matrix(3, 0, 0, 0, 3, 0), alpha = 0, pixel_y = 12, time = 3 SECONDS)

/datum/status_effect/heretic_ascension_omen/proc/clear_echo()
	var/client/echo_viewer = locate(echo_viewer_ref)
	if(istype(echo_viewer))
		echo_viewer.images -= personal_echo
	echo_viewer_ref = null
	QDEL_NULL(personal_echo)

/datum/status_effect/heretic_ascension_omen/on_remove()
	clear_echo()
	owner.clear_fullscreen(fullscreen_key, 0)
	return ..()

/atom/movable/screen/fullscreen/heretic_omen
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "cloudy"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	alpha = 0

/atom/movable/screen/fullscreen/heretic_omen/SetSeverity(severity)
	src.severity = severity
	icon_state = initial(icon_state)

/obj/effect/proc_holder/spell/self/heretic_last_waltz
	name = "Последний такт"
	desc = "Оттесните видимых врагов на две клетки, охладите их и наложите метки Пустоты. Вокруг вас на 12 секунд остаётся зимний круг радиусом три клетки. Защита от магии останавливает воздействие."
	clothes_req = FALSE
	charge_max = 40 SECONDS
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "void_waltz"
	action_background_icon_state = "bg_ecult"
	var/obj/effect/heretic_combat_zone/void/last_waltz/winter_circle

/obj/effect/proc_holder/spell/self/heretic_last_waltz/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return ..() && heretic?.ascended && heretic.selected_path == PATH_VOID && isfloorturf(user.loc)

/obj/effect/proc_holder/spell/self/heretic_last_waltz/cast(list/targets, mob/living/user)
	if(!isfloorturf(user.loc))
		revert_cast(user)
		return
	QDEL_NULL(winter_circle)
	winter_circle = new(get_turf(user), user.mind)
	RegisterSignal(winter_circle, COMSIG_PARENT_QDELETING, PROC_REF(on_circle_deleted))
	user.visible_message(span_danger("[user] завершает такт. Из-под ног расходится белая печать, оттесняя окружающих!"))
	playsound(user, 'sound/magic/voidblink.ogg', 70, FALSE)
	for(var/mob/living/victim in view(5, user))
		if(!heretic_can_affect(user, victim))
			continue
		victim.apply_status_effect(/datum/status_effect/eldritch/void)
		victim.adjust_bodytemperature(-35)
		new /obj/effect/temp_visual/voidpush(get_turf(victim), get_dir(user, victim))
		if(victim.anchored || victim.buckled || !isturf(victim.loc))
			continue
		for(var/step_index in 1 to 2)
			var/turf/destination = get_step(victim, get_dir(user, victim))
			if(!isopenturf(destination) || is_blocked_turf(destination, TRUE) || !step(victim, get_dir(user, victim)))
				break

/obj/effect/proc_holder/spell/self/heretic_last_waltz/Destroy()
	QDEL_NULL(winter_circle)
	return ..()

/obj/effect/proc_holder/spell/self/heretic_last_waltz/proc/on_circle_deleted(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	if(winter_circle == source)
		winter_circle = null

/obj/effect/heretic_combat_zone/void/last_waltz
	name = "последний вальс"
	desc = "Широкая зимняя печать хранит последний шаг Аристократа. За её границей холод отступает."
	radius = 3
	duration = 12 SECONDS

#undef HERETIC_ASCENSION_OMEN_DURATION
#undef HERETIC_ASCENSION_WARNING_COOLDOWN
