#define HERETIC_ASCENSION_OMEN_DURATION (30 SECONDS)
#define HERETIC_ASCENSION_WARNING_COOLDOWN (3 MINUTES)
#define HERETIC_ASCENSION_ICON_SIZE 64
#define HERETIC_ASCENSION_BACK_DRAG 3
#define HERETIC_ASCENSION_FRONT_DRAG 1
#define HERETIC_ASCENSION_DRAG_SETTLE (0.6 SECONDS)
#define HERETIC_ASCENSION_TURN_TIME (0.15 SECONDS)
#define HERETIC_ASCENSION_MANIFEST_TIME (1.5 SECONDS)
#define HERETIC_ASCENSION_RISE 8

/datum/heretic_path
	var/ascension_title
	var/ascension_message
	var/ascension_omen
	var/ascension_sound
	/// Лист 64x64: слои `_back` (за телом), `_front` (перед ногами) и маска свечения `_glow`.
	var/ascension_aura_icon
	var/ascension_aura_state
	/// Где главная деталь нимба при взгляде на юг: -1 слева, 1 справа, 0 - симметричный нимб не зеркалится.
	var/ascension_aura_side = 0

/datum/heretic_path/ash
	ascension_title = "Пепельный Лорд"
	ascension_message = "Пепел поднимается к потолку. Последний фонарь вновь зажжён."
	ascension_omen = "Свет на мгновение кажется пламенем. Запах пепла проникает даже под герметичный шлем."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_ash.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_ash.dmi'
	ascension_aura_state = "ash_aura"

/datum/heretic_path/rust
	ascension_title = "Посланник Ржавчины"
	ascension_message = "Сталь отзывается протяжным стоном. Ржавые холмы приняли нового хозяина."
	ascension_omen = "На языке появляется привкус железа. Кажется, за каждой стеной скребутся корни."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_rust.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_rust.dmi'
	ascension_aura_state = "rust_aura"

/datum/heretic_path/flesh
	ascension_title = "Повелитель Ночи"
	ascension_message = "Под обшивкой бьётся чужое сердце. Процессия Плоти встречает своего повелителя."
	ascension_omen = "Чужой пульс на мгновение совпадает с вашим. В тёмном стекле открывается красный глаз."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_flesh.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_flesh.dmi'
	ascension_aura_state = "flesh_aura"
	ascension_aura_side = -1

/datum/heretic_path/void
	ascension_title = "Аристократ Пустоты"
	ascension_message = "Зимняя буря проходит сквозь завесу. Начинается последний вальс."
	ascension_omen = "Каждый звук приходит будто издалека. Снег мерещится даже там, где ему неоткуда взяться."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_void.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_void.dmi'
	ascension_aura_state = "void_aura"
	ascension_aura_side = -1

/datum/heretic_path/blade
	ascension_title = "Чемпион Последнего Клинка"
	ascension_message = "В воздухе звенит сталь. Последний поединок окончен, и его победитель выходит за пределы человеческого."
	ascension_omen = "На краю зрения смыкаются лезвия. Слышен звон удара, который ещё никто не нанёс."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_blade.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_blade.dmi'
	ascension_aura_state = "blade_aura"
	ascension_aura_side = -1

/datum/heretic_path/moon
	ascension_title = "Владыка Обратной Луны"
	ascension_message = "Отражения поворачиваются к невидимой луне. По ту сторону зеркала больше нет пустого места."
	ascension_omen = "Ваше отражение запаздывает на один вдох. Кажется, оно смотрит на кого-то за вашей спиной."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_moon.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_moon.dmi'
	ascension_aura_state = "moon_aura"
	ascension_aura_side = -1

/datum/heretic_path/cosmic
	ascension_title = "Живое Созвездие"
	ascension_message = "Звёздные карты утратили смысл. Новое небо раскрылось внутри станции."
	ascension_omen = "Между знакомыми предметами проступают незнакомые звёзды. Расстояние до потолка кажется бесконечным."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_cosmic.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_cosmic.dmi'
	ascension_aura_state = "cosmic_presence"

/datum/heretic_path/lock
	ascension_title = "Хранитель Последнего Порога"
	ascension_message = "Все замки отвечают одним щелчком. За знакомыми дверями проступает дом без выхода."
	ascension_omen = "Вы на мгновение забываете, с какой стороны двери стоите. Из замочной скважины доносится чужой вдох."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_lock.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_lock.dmi'
	ascension_aura_state = "lock_presence"
	ascension_aura_side = 1

/datum/heretic_path/tide
	ascension_title = "Владыка Бездонного Прилива"
	ascension_message = "За стенами звучит погребальный колокол. Невидимое море достигло станции, и его глубина больше не имеет дна."
	ascension_omen = "Уши закладывает от чужой глубины. Сквозь пол на мгновение видны тёмные волны."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_tide.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_tide.dmi'
	ascension_aura_state = "tide_aura"
	ascension_aura_side = 1

/datum/eldritch_knowledge/final_eldritch
	var/obj/effect/heretic_ascension_aura/ascension_aura
	var/obj/effect/heretic_ascension_aura/ascension_aura_front
	COOLDOWN_DECLARE(ascension_warning)

/datum/heretic_path/glass
	ascension_title = "Владыка Тысячи Граней"
	ascension_message = "Каждый витраж раскололся в другом мире. Здесь слышен только звон: разбитый свет обрёл своего хозяина."
	ascension_omen = "Свет распадается на острые полосы. Вы слышите, как трескается стекло, хотя всё вокруг цело."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_glass.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_glass.dmi'
	ascension_aura_state = "glass_aura"
	ascension_aura_side = -1

/datum/heretic_path/blood
	ascension_title = "Святой Алой Десятины"
	ascension_message = "Алая печать проступает за закрытыми веками. Десятина уплачена; её сборщик больше не принадлежит этому миру."
	ascension_omen = "На языке остаётся вкус железа. На мгновение кажется, что под кожей начертаны незнакомые письмена."
	ascension_sound = 'modular_bluemoon/sound/heretic/ascend_blood.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_blood.dmi'
	ascension_aura_state = "blood_aura"

/datum/heretic_path/echo
	ascension_title = "Регент Последнего Хора"
	ascension_message = "Оборванные голоса возвращаются погребальным хором. Тот, кто задал им тон, поднимает руку для последнего такта."
	ascension_omen = "Ваш последний шаг звучит снова. Из стен отвечает многоголосый шёпот, и на мгновение вы узнаёте в нём собственный голос."
	ascension_sound = 'modular_bluemoon/sound/heretic/echo_ascend.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_echo.dmi'
	ascension_aura_state = "echo_ascend"

/datum/heretic_path/sand
	ascension_title = "Хранитель Истёкшего Часа"
	ascension_message = "Звёзды осыпаются за стеклом. Последний час уже истёк, но его хранитель перевернул часы."
	ascension_omen = "Сквозь пальцы сыплется невидимый песок. Часы на мгновение идут назад; следующий шаг звучит раньше, чем вы его делаете."
	ascension_sound = 'modular_bluemoon/sound/heretic/sand_ascend.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_sand.dmi'
	ascension_aura_state = "sand_aura"
	ascension_aura_side = 1

/datum/heretic_path/wax
	ascension_title = "Святитель Негаснущей Свечи"
	ascension_message = "За иллюминаторами проступает погребальная процессия. Свечи горят без воздуха; ни одна не погаснет, пока идёт их святитель."
	ascension_omen = "Воздух пахнет воском. Тени склоняют головы перед бледным огоньком, которого никто не зажигал."
	ascension_sound = 'modular_bluemoon/sound/heretic/wax_ascend.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_wax.dmi'
	ascension_aura_state = "wax_aura"

/datum/eldritch_knowledge/final_eldritch/sand_final
	parallax_scene = ANTAG_SCENE_HERETIC_SAND

/datum/eldritch_knowledge/final_eldritch/wax_final
	parallax_scene = ANTAG_SCENE_HERETIC_WAX

/datum/heretic_path/spirit
	ascension_title = "Перевозчик Непришедших"
	ascension_message = "За иллюминаторами загораются бледные огни. Последняя переправа открыта; живые слышат, как называют их имена."
	ascension_omen = "В груди остаётся пустота от пропущенного удара сердца. Вдалеке качается фонарь, хотя коридор пуст."
	ascension_sound = 'modular_bluemoon/sound/heretic/spirit_ascend.ogg'
	ascension_aura_icon = 'modular_bluemoon/icons/obj/heretic_ascension_spirit.dmi'
	ascension_aura_state = "spirit_aura"

/datum/eldritch_knowledge/final_eldritch/spirit_final
	parallax_scene = ANTAG_SCENE_HERETIC_SPIRIT

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
	if(heretic.simulated)
		to_chat(user, span_notice("Учебный обряд вознесения начался. Удерживайте позицию до его завершения."))
		return TRUE
	priority_announce("В секторе «[get_area(rune)]» начался обряд пути [path.name]. До разрыва завесы — [DisplayTimeText(ritual_time)]. Обряд можно прервать: не дайте заклинателю закончить или унесите тела с руны.", "Разрыв завесы — начало обряда", 'sound/misc/notice1.ogg')
	return TRUE

/datum/eldritch_knowledge/final_eldritch/proc/abort_ascension_ritual(area/ritual_area, ritual_elapsed)
	if(istype(ritual_area, /area/antag_training))
		return TRUE
	if(finished || !isnum(ritual_elapsed) || ritual_elapsed < 0)
		return FALSE
	priority_announce("Обряд в секторе «[ritual_area]» прерван. Завеса удержалась; заклинатель может попытаться снова.", "Разрыв завесы — обряд прерван", 'sound/misc/notice2.ogg')
	return TRUE

/// Повторная привязка к телу переносит нимб, но не повторяет событие для всей станции.
/datum/eldritch_knowledge/final_eldritch/proc/announce_ascension(mob/living/user)
	var/datum/heretic_path/path = GLOB.heretic_paths[route]
	if(!path || !finished)
		return
	if(simulated)
		to_chat(user, span_boldnotice("Учебное вознесение завершено: [path.ascension_title]."))
		user.playsound_local(get_turf(user), path.ascension_sound, 75, FALSE)
		new /obj/effect/temp_visual/heretic_ascension_echo(get_turf(user), route)
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
	var/datum/heretic_path/path = GLOB.heretic_paths[route]
	if(!path)
		return
	ascension_aura = new(null, route)
	ascension_aura_front = new(null, route, TRUE)
	ascension_aura.follow(user)
	ascension_aura_front.follow(user)
	user.vis_contents += list(ascension_aura, ascension_aura_front)
	ascension_aura.manifest()
	ascension_aura_front.manifest()
	RegisterSignal(user, COMSIG_PARENT_EXAMINE, PROC_REF(on_ascended_examine))
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_ascended_body_deleted))

/datum/eldritch_knowledge/final_eldritch/proc/remove_ascension_presence()
	if(applied_body)
		UnregisterSignal(applied_body, list(COMSIG_PARENT_EXAMINE, COMSIG_PARENT_QDELETING))
		var/turf/last_turf = get_turf(applied_body)
		if(last_turf && ascension_aura)
			new /obj/effect/temp_visual/heretic_ascension_fade(last_turf, route, ascension_aura.transform)
		applied_body.vis_contents -= ascension_aura
		applied_body.vis_contents -= ascension_aura_front
	QDEL_NULL(ascension_aura)
	QDEL_NULL(ascension_aura_front)

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
	plane = GAME_PLANE
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART | PIXEL_SCALE
	vis_flags = VIS_INHERIT_ID | VIS_INHERIT_PLANE
	var/drag = HERETIC_ASCENSION_BACK_DRAG
	var/side = 0
	var/mirrored = FALSE

/obj/effect/heretic_ascension_aura/Initialize(mapload, path_id, foreground = FALSE)
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(!path)
		return INITIALIZE_HINT_QDEL
	icon = path.ascension_aura_icon
	icon_state = "[path.ascension_aura_state]_[foreground ? "front" : "back"]"
	pixel_x = (world.icon_size - HERETIC_ASCENSION_ICON_SIZE) / 2
	pixel_y = pixel_x
	side = path.ascension_aura_side
	if(foreground)
		drag = HERETIC_ASCENSION_FRONT_DRAG
		return
	vis_flags |= VIS_UNDERLAY
	// Маска свечения общая на оба слоя: в темноте видно только то, что светится само.
	add_overlay(emissive_appearance(icon, "[path.ascension_aura_state]_glow", src))

/// Нимб отстаёт от шага и перекладывает главную деталь за спину при повороте.
/obj/effect/heretic_ascension_aura/proc/follow(mob/living/body)
	RegisterSignal(body, COMSIG_MOVABLE_MOVED, PROC_REF(on_body_moved))
	if(!side)
		return
	RegisterSignal(body, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_body_turned))
	face(body.dir, instant = TRUE)

/// Нимб поднимается из пола и проступает, а не появляется разом.
/obj/effect/heretic_ascension_aura/proc/manifest()
	var/rest = pixel_y
	alpha = 0
	pixel_y = rest - HERETIC_ASCENSION_RISE
	animate(src, alpha = 255, pixel_y = rest, time = HERETIC_ASCENSION_MANIFEST_TIME, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)

/obj/effect/heretic_ascension_aura/proc/on_body_moved(atom/movable/body, atom/old_loc, move_dir, forced)
	SIGNAL_HANDLER
	if(forced || !move_dir || !isturf(old_loc) || get_dist(old_loc, body) != 1)
		return
	var/rest = (world.icon_size - HERETIC_ASCENSION_ICON_SIZE) / 2
	var/dx = (move_dir & EAST) ? 1 : ((move_dir & WEST) ? -1 : 0)
	var/dy = (move_dir & NORTH) ? 1 : ((move_dir & SOUTH) ? -1 : 0)
	animate(src, pixel_x = rest - dx * drag, pixel_y = rest - dy * drag, time = 1, flags = ANIMATION_PARALLEL)
	animate(pixel_x = rest, pixel_y = rest, time = HERETIC_ASCENSION_DRAG_SETTLE, easing = SINE_EASING | EASE_OUT)

/obj/effect/heretic_ascension_aura/proc/on_body_turned(atom/body, old_dir, new_dir)
	SIGNAL_HANDLER
	face(new_dir)

/obj/effect/heretic_ascension_aura/proc/face(new_dir, instant = FALSE)
	if(!side)
		return
	var/wanted = side
	switch(new_dir)
		if(NORTH)
			wanted = -side
		if(EAST)
			wanted = -1
		if(WEST)
			wanted = 1
	var/flip = (wanted != side)
	if(flip == mirrored)
		return
	mirrored = flip
	// Холст зеркалится вокруг x = 32, а ось тела - столбец 31: сдвиг на пиксель держит её на месте.
	var/matrix/target = flip ? matrix(-1, 0, -1, 0, 1, 0) : matrix()
	if(instant)
		transform = target
		return
	animate(src, transform = matrix(0.1, 0, 0, 0, 1, 0), time = HERETIC_ASCENSION_TURN_TIME, easing = SINE_EASING | EASE_IN, flags = ANIMATION_PARALLEL)
	animate(transform = target, time = HERETIC_ASCENSION_TURN_TIME, easing = SINE_EASING | EASE_OUT)

/obj/effect/temp_visual/heretic_ascension_echo
	plane = ABOVE_LIGHTING_PLANE
	layer = ABOVE_LIGHTING_LAYER
	appearance_flags = TILE_BOUND | PIXEL_SCALE
	duration = 3 SECONDS
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/heretic_ascension_echo/Initialize(mapload, path_id)
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(!path)
		return INITIALIZE_HINT_QDEL
	icon = path.ascension_aura_icon
	icon_state = "[path.ascension_aura_state]_back"
	add_overlay(mutable_appearance(icon, "[path.ascension_aura_state]_front"))
	pixel_x = (world.icon_size - HERETIC_ASCENSION_ICON_SIZE) / 2
	pixel_y = pixel_x
	animate(src, transform = matrix(3, 0, 0, 0, 3, 0), alpha = 0, pixel_y = pixel_y + 12, time = duration, easing = CUBIC_EASING | EASE_OUT)

/// Потерянный нимб оседает в пол и гаснет на месте тела.
/obj/effect/temp_visual/heretic_ascension_fade
	layer = BELOW_MOB_LAYER
	appearance_flags = TILE_BOUND | PIXEL_SCALE
	duration = 1.2 SECONDS
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/heretic_ascension_fade/Initialize(mapload, path_id, matrix/facing)
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(!path)
		return INITIALIZE_HINT_QDEL
	icon = path.ascension_aura_icon
	icon_state = "[path.ascension_aura_state]_back"
	add_overlay(mutable_appearance(icon, "[path.ascension_aura_state]_front"))
	pixel_x = (world.icon_size - HERETIC_ASCENSION_ICON_SIZE) / 2
	pixel_y = pixel_x
	if(facing)
		transform = facing
	animate(src, alpha = 0, pixel_y = pixel_y - HERETIC_ASCENSION_RISE, time = duration, easing = SINE_EASING | EASE_IN)

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
		personal_echo = image(path.ascension_aura_icon, owner, "[path.ascension_aura_state]_back", ABOVE_LIGHTING_LAYER)
		personal_echo.overlays += mutable_appearance(path.ascension_aura_icon, "[path.ascension_aura_state]_front")
		personal_echo.plane = ABOVE_LIGHTING_PLANE
		personal_echo.appearance_flags = PIXEL_SCALE | RESET_COLOR
		personal_echo.pixel_x = (world.icon_size - HERETIC_ASCENSION_ICON_SIZE) / 2
		personal_echo.pixel_y = personal_echo.pixel_x
		personal_echo.alpha = 200
		echo_viewer_ref = REF(owner.client)
		owner.client.images += personal_echo
		animate(personal_echo, transform = matrix(3, 0, 0, 0, 3, 0), alpha = 0, pixel_y = personal_echo.pixel_y + 12, time = 3 SECONDS)

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
	desc = "Нанесите видимым врагам в пределах 5 клеток 30 холодовых ожогов, замедлите на 4 секунды, оттесните на две клетки, охладите и наложите метки Пустоты. Вокруг вас на 12 секунд остаётся зимний круг радиусом три клетки, поддерживающий скованность. Защита от магии останавливает воздействие."
	clothes_req = FALSE
	charge_max = 40 SECONDS
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "void_waltz"
	action_background_icon_state = "bg_ecult"
	var/obj/effect/heretic_combat_zone/void/last_waltz/winter_circle
	var/burst_damage = 30

/obj/effect/proc_holder/spell/self/heretic_last_waltz/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return ..() && heretic_check(user, heretic?.ascended && heretic.selected_path == PATH_VOID && isfloorturf(user.loc), silent, "Нужно вознесение Пустоты; встаньте на пол вне контейнера.")

/obj/effect/proc_holder/spell/self/heretic_last_waltz/cast(list/targets, mob/living/user)
	if(!isfloorturf(user.loc))
		heretic_revert_cast(user)
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
		victim.adjustFireLoss(burst_damage)
		victim.adjust_bodytemperature(-35)
		victim.apply_status_effect(/datum/status_effect/heretic_void_chill)
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
#undef HERETIC_ASCENSION_ICON_SIZE
#undef HERETIC_ASCENSION_BACK_DRAG
#undef HERETIC_ASCENSION_FRONT_DRAG
#undef HERETIC_ASCENSION_DRAG_SETTLE
#undef HERETIC_ASCENSION_TURN_TIME
#undef HERETIC_ASCENSION_MANIFEST_TIME
#undef HERETIC_ASCENSION_RISE
