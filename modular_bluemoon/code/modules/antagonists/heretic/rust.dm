#define HERETIC_RUST_INK heretic_path_ink(PATH_RUST, TRUE)
#define HERETIC_RUST_DARK_SHARE 0.5
#define HERETIC_RUST_DARK_INK BlendRGB(HERETIC_RUST_INK, COLOR_BLACK, HERETIC_RUST_DARK_SHARE)
#define HERETIC_RUST_HEART_SCALE 1.25
#define HERETIC_RUST_HEART_SWELL 1.07
#define HERETIC_RUST_HEART_ECHO 1.03
#define HERETIC_RUST_HEART_FLUSH_SHARE 0.5
#define HERETIC_RUST_HEART_GLOW 150
#define HERETIC_RUST_HEART_VEINS 120
#define HERETIC_RUST_HEART_RISE 8
#define HERETIC_RUST_HEART_EMERGE (0.8 SECONDS)
#define HERETIC_RUST_HEART_BEAT (0.15 SECONDS)
#define HERETIC_RUST_HEART_REST (0.8 SECONDS)
#define HERETIC_RUST_HEART_SHUDDER 2
#define HERETIC_RUST_HEART_SHUDDER_STEP (0.1 SECONDS)
#define HERETIC_RUST_HEART_WOUND_COOLDOWN (0.4 SECONDS)
#define HERETIC_RUST_HEART_WOUND_PULSE (0.3 SECONDS)
#define HERETIC_RUST_HEART_COLLAPSE (0.9 SECONDS)
#define HERETIC_RUST_HEART_DEATH_WAVE (0.6 SECONDS)
#define HERETIC_RUST_HEART_DEATH_FLASH (0.5 SECONDS)
#define HERETIC_RUST_HEART_DEATH_RADIUS 2
#define HERETIC_RUST_HEART_DEATH_POWER 2
#define HERETIC_RUST_COLLAPSE_SPREAD 1.3
#define HERETIC_RUST_COLLAPSE_SQUASH 0.15
#define HERETIC_RUST_COLLAPSE_SINK 10
#define HERETIC_RUST_RIPPLE_STEP (0.08 SECONDS)
#define HERETIC_RUST_RIPPLE_DISSOLVE (0.25 SECONDS)
#define HERETIC_RUST_RIPPLE_REVEAL (0.3 SECONDS)
#define HERETIC_RUST_CREEP_HOLD (0.7 SECONDS)
#define HERETIC_RUST_CREEP_FADE (0.5 SECONDS)
#define HERETIC_RUST_WAVE_TIME (0.8 SECONDS)
#define HERETIC_RUST_WAVE_FLASH_RANGE 3
#define HERETIC_RUST_WAVE_FLASH_POWER 1.5
#define HERETIC_RUST_WAVE_QUAKE 0.12
#define HERETIC_RUST_WAVE_QUAKE_TIME (0.3 SECONDS)

/turf/open/floor
	var/heretic_rustable = FALSE

/turf/open/floor/plating
	heretic_rustable = TRUE

/turf/open/floor/plasteel
	heretic_rustable = TRUE

/turf/open/floor/wood
	heretic_rustable = TRUE

/turf/open/floor/mineral/titanium
	heretic_rustable = TRUE

/turf/open/floor/mineral/plastitanium
	heretic_rustable = TRUE

/turf/open/floor/engine
	heretic_rustable = TRUE

/turf/open/floor/engine/hull
	heretic_rustable = FALSE

/turf/open/floor/engine/cult
	heretic_rustable = FALSE

/turf/open/floor/plasteel/elevated
	heretic_rustable = FALSE

/turf/open/floor/plasteel/lowered
	heretic_rustable = FALSE

/turf/open/floor/rust_heretic_act()
	if(!heretic_rustable)
		return
	if(prob(70))
		new /obj/effect/temp_visual/glowing_rune(src)
	var/turf/after = ChangeTurf(/turf/open/floor/plating/rust, flags = CHANGETURF_INHERIT_AIR)
	after?.AddElement(/datum/element/heretic_rust)
	return after

#define HERETIC_RUST_HEALING_ALERT "heretic_rust_healing"

/datum/heretic_innate/rust/bind(mob/living/user)
	. = ..()
	update_healing_alert()

/datum/heretic_innate/rust/unbind()
	body?.clear_alert(HERETIC_RUST_HEALING_ALERT)
	return ..()

/datum/heretic_innate/rust/on_move(mob/living/source, atom/old_loc, direction, forced)
	. = ..()
	update_healing_alert()

/datum/heretic_innate/rust/on_death()
	. = ..()
	body?.clear_alert(HERETIC_RUST_HEALING_ALERT)

/datum/heretic_innate/rust/proc/update_healing_alert()
	if(!valid())
		body?.clear_alert(HERETIC_RUST_HEALING_ALERT)
		return
	var/on_rust = istype(body.loc, /turf/open/floor/plating/rust)
	var/in_grove = FALSE
	var/datum/eldritch_knowledge/knowledge = knowledge_ref.resolve()
	if(on_rust)
		for(var/obj/effect/heretic_combat_zone/rust/zone in list(knowledge.combat_zone, knowledge.relic_zone))
			if(!QDELETED(zone) && (body.loc in zone.field_turfs))
				in_grove = TRUE
				break
	var/atom/movable/screen/alert/heretic_rust_healing/indicator = body.throw_alert(HERETIC_RUST_HEALING_ALERT, /atom/movable/screen/alert/heretic_rust_healing, no_anim = TRUE)
	indicator.update_healing(on_rust, in_grove)

/atom/movable/screen/alert/heretic_rust_healing
	name = "Лечение Ржавчины"
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_rust"
	maptext_width = 32
	maptext_height = 12
	maptext_y = 1
	var/healing_state

/atom/movable/screen/alert/heretic_rust_healing/proc/update_healing(on_rust, in_grove)
	var/new_state = in_grove ? "grove" : (on_rust ? "floor" : "inactive")
	if(healing_state == new_state)
		return
	healing_state = new_state
	var/label
	switch(healing_state)
		if("grove")
			name = "Ржавчина: пол и очаг лечат"
			desc = "Вы стоите на ржавом полу внутри своего очага. Работают врождённое лечение и дополнительное лечение очага. Ржавая поступь добавляет лечение, если изучена."
			label = "ОЧАГ"
			color = "#b5ffc5"
		if("floor")
			name = "Ржавчина: пол лечит"
			desc = "Работает врождённое лечение. Ржавая поступь добавляет лечение, если изучена. Дополнительное лечение очага здесь не действует: вернитесь в его отмеченную область или создайте новый."
			label = "ПОЛ"
			color = "#e7ad64"
		else
			name = "Ржавчина: лечение не действует"
			desc = "Под ногами нет ржавого пола. Заржавьте подходящий пол Хваткой или разрастанием. Очаг тоже лечит только на ржавом полу; одного нахождения рядом с ним недостаточно."
			label = "НЕТ"
			color = "#ff9e88"
	desc += " Лечение постепенно восстанавливает здоровье, но само по себе не устраняет переломы, вывихи и другие раны."
	maptext = MAPTEXT("<div style='text-align:center;color:#ffffff;font-size:8px;background-color:#17111d'>[label]</div>")

#undef HERETIC_RUST_HEALING_ALERT

/// Пока сердце вознесения цело, ржавый пол вдвое снижает урон выносливости вознесённому.
/datum/component/heretic_rust_ascension
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/knowledge_ref
	var/stamina_applied = FALSE

/datum/component/heretic_rust_ascension/Initialize(datum/eldritch_knowledge/final_eldritch/rust_final/knowledge)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	knowledge_ref = WEAKREF(knowledge)
	update_stamina()

/datum/component/heretic_rust_ascension/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_rust_ascension/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_EXAMINE))
	set_stamina(FALSE)

/datum/component/heretic_rust_ascension/proc/rust_empowered()
	var/mob/living/owner = parent
	var/datum/eldritch_knowledge/final_eldritch/rust_final/knowledge = knowledge_ref?.resolve()
	return knowledge?.heart_alive() && owner.stat != DEAD && istype(get_turf(owner), /turf/open/floor/plating/rust)

/datum/component/heretic_rust_ascension/proc/update_stamina()
	set_stamina(rust_empowered())

/datum/component/heretic_rust_ascension/proc/set_stamina(active)
	active = !!active
	if(active == stamina_applied || !ishuman(parent))
		return
	var/mob/living/carbon/human/owner = parent
	stamina_applied = active
	if(!owner.physiology)
		return
	if(active)
		owner.physiology.heretic_stamina_mod *= HERETIC_RUST_ASCENDED_STAMINA_MOD
	else
		owner.physiology.heretic_stamina_mod /= HERETIC_RUST_ASCENDED_STAMINA_MOD

/datum/component/heretic_rust_ascension/proc/on_moved(mob/living/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	update_stamina()

/datum/component/heretic_rust_ascension/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/final_eldritch/rust_final/knowledge = knowledge_ref?.resolve()
	if(knowledge?.heart_alive())
		examine_list += span_warning("Ржавчина под ногами кормит это тело. Выманите его с ржавого пола или разбейте Ржавое сердце.")
	else
		examine_list += span_notice("Ржавчина под ногами больше не отзывается: сердце разбито.")

/obj/structure/heretic_rust_ascension_heart
	name = "heart of the rusted garden"
	desc = "Ржавое сердце: огромный пульсирующий ком металла, вросший в пол на месте вознесения еретика. Пока оно бьётся, ржавчина расползается по станции, а вознесённый лечится на ржавом полу и получает там вдвое меньше урона выносливости. Разбейте его обычным оружием, и ржавчина остановится навсегда."
	icon = 'modular_bluemoon/icons/obj/heretic_rust_heart.dmi'
	icon_state = "tumor"
	pixel_x = -16
	color = "#a8552e"
	anchored = TRUE
	density = FALSE
	max_integrity = HERETIC_RUST_HEART_INTEGRITY
	armor = list(MELEE = 20, BULLET = 20, LASER = 20, ENERGY = 20, BOMB = 20, BIO = 100, RAD = 100, FIRE = 50, ACID = 50)
	appearance_flags = PIXEL_SCALE
	var/obj/effect/abstract/heretic_particle_holder/flakes
	COOLDOWN_DECLARE(wound_cooldown)

/obj/structure/heretic_rust_ascension_heart/Initialize(mapload)
	. = ..()
	transform = matrix() * HERETIC_RUST_HEART_SCALE
	var/mutable_appearance/veins = mutable_appearance(icon, "tumor_glow")
	veins.color = HERETIC_RUST_INK
	veins.alpha = HERETIC_RUST_HEART_VEINS
	veins.appearance_flags = RESET_COLOR
	add_overlay(veins)
	add_overlay(emissive_appearance(icon, "tumor_glow", alpha = HERETIC_RUST_HEART_GLOW))
	flakes = heretic_vfx_attach_particles(src, /particles/heretic_ascension/rust/heart, FALSE)
	if(flakes)
		flakes.pixel_x = -pixel_x
	beat()
	var/rest_y = pixel_y
	alpha = 0
	pixel_y = rest_y - HERETIC_RUST_HEART_RISE
	animate(src, alpha = 255, pixel_y = rest_y, time = HERETIC_RUST_HEART_EMERGE, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	new /obj/effect/temp_visual/heretic_oldpath/rust(get_turf(src))
	heretic_vfx_burst(src, /particles/heretic_ascension/rust)
	playsound(src, 'sound/effects/clangsmall1.ogg', 80, TRUE)

/// Медленный двойной удар: сердце набухает и темнеет в такт, свечение дышит вместе с ним.
/obj/structure/heretic_rust_ascension_heart/proc/beat()
	var/matrix/rest = matrix() * HERETIC_RUST_HEART_SCALE
	var/flush = BlendRGB(initial(color), HERETIC_RUST_INK, HERETIC_RUST_HEART_FLUSH_SHARE)
	animate(src, transform = matrix() * (HERETIC_RUST_HEART_SCALE * HERETIC_RUST_HEART_SWELL), color = flush, time = HERETIC_RUST_HEART_BEAT, easing = SINE_EASING | EASE_OUT, loop = -1)
	animate(transform = rest, color = initial(color), time = HERETIC_RUST_HEART_BEAT * 2, easing = SINE_EASING | EASE_IN)
	animate(transform = matrix() * (HERETIC_RUST_HEART_SCALE * HERETIC_RUST_HEART_ECHO), color = flush, time = HERETIC_RUST_HEART_BEAT, easing = SINE_EASING | EASE_OUT)
	animate(transform = rest, color = initial(color), time = HERETIC_RUST_HEART_BEAT * 2, easing = SINE_EASING | EASE_IN)
	animate(transform = rest, time = HERETIC_RUST_HEART_REST)

/obj/structure/heretic_rust_ascension_heart/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	. = ..()
	if(!. || QDELETED(src) || !COOLDOWN_FINISHED(src, wound_cooldown))
		return
	COOLDOWN_START(src, wound_cooldown, HERETIC_RUST_HEART_WOUND_COOLDOWN)
	shudder()
	heretic_vfx_burst(src, /particles/heretic_ascension/rust/heart_wound)
	heretic_vfx_pulse(src, HERETIC_RUST_DARK_INK, 1, HERETIC_RUST_HEART_WOUND_PULSE)

/// Дрожь сдвигом, а не поворотом: поворот сбил бы такт сердца.
/obj/structure/heretic_rust_ascension_heart/proc/shudder()
	var/rest_x = initial(pixel_x)
	animate(src, pixel_x = rest_x + HERETIC_RUST_HEART_SHUDDER, time = HERETIC_RUST_HEART_SHUDDER_STEP / 2, flags = ANIMATION_PARALLEL)
	animate(pixel_x = rest_x - HERETIC_RUST_HEART_SHUDDER, time = HERETIC_RUST_HEART_SHUDDER_STEP)
	animate(pixel_x = rest_x + HERETIC_RUST_HEART_SHUDDER / 2, time = HERETIC_RUST_HEART_SHUDDER_STEP)
	animate(pixel_x = rest_x, time = HERETIC_RUST_HEART_SHUDDER_STEP, easing = SINE_EASING | EASE_OUT)

/obj/structure/heretic_rust_ascension_heart/rust_heretic_act()
	return

/obj/structure/heretic_rust_ascension_heart/Destroy()
	visible_message(span_danger("[src] лопается, осыпаясь ржавой трухой!"))
	var/turf/place = get_turf(src)
	if(place)
		new /obj/effect/temp_visual/heretic_oldpath/rust(place)
		new /obj/effect/temp_visual/heretic_rust_heart_collapse(place)
		heretic_vfx_burst(place, /particles/heretic_ascension/rust/collapse)
		heretic_vfx_shockwave(place, HERETIC_RUST_DARK_INK, HERETIC_RUST_HEART_DEATH_RADIUS, HERETIC_RUST_HEART_DEATH_WAVE)
		heretic_vfx_flash(place, HERETIC_RUST_DARK_INK, HERETIC_RUST_HEART_DEATH_RADIUS + 1, HERETIC_RUST_HEART_DEATH_POWER, HERETIC_RUST_HEART_DEATH_FLASH)
	playsound(src, 'sound/effects/clangsmall2.ogg', 80, TRUE)
	heretic_vfx_release_particles(src, flakes)
	flakes = null
	return ..()

/// Разбитое сердце вздрагивает последний раз и оседает в пол, темнея.
/obj/effect/temp_visual/heretic_rust_heart_collapse
	icon = 'modular_bluemoon/icons/obj/heretic_rust_heart.dmi'
	icon_state = "tumor"
	pixel_x = -16
	layer = OBJ_LAYER
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE
	duration = HERETIC_RUST_HEART_COLLAPSE

/obj/effect/temp_visual/heretic_rust_heart_collapse/Initialize(mapload)
	. = ..()
	var/obj/structure/heretic_rust_ascension_heart/heart_type = /obj/structure/heretic_rust_ascension_heart
	color = initial(heart_type.color)
	transform = matrix() * HERETIC_RUST_HEART_SCALE
	animate(src, transform = matrix() * (HERETIC_RUST_HEART_SCALE * HERETIC_RUST_HEART_SWELL * HERETIC_RUST_HEART_SWELL), time = duration / 6, easing = SINE_EASING | EASE_OUT)
	animate(transform = matrix(HERETIC_RUST_HEART_SCALE * HERETIC_RUST_COLLAPSE_SPREAD, 0, 0, 0, HERETIC_RUST_HEART_SCALE * HERETIC_RUST_COLLAPSE_SQUASH, -HERETIC_RUST_COLLAPSE_SINK), color = HERETIC_RUST_DARK_INK, alpha = 0, time = duration * 5 / 6, easing = QUAD_EASING | EASE_IN)

/obj/effect/proc_holder/spell/self/rust_corrosive_wave
	name = "Коррозийный вал"
	desc = "Обрушьте волну ржавчины на всё, что видно в пяти клетках вокруг себя: за стены и глухие двери вал не проходит. Враги получают 20 урона коррозией: треть ожогами, остальное отравлением или повреждением систем синтетика. Полы ржавеют, обычные стены рушатся. Наружные стены, за которыми космос, пропасть, лава или вода, вал не трогает вовсе. Укреплённые стены могут лишь заржаветь, корпус шаттлов не поддаётся. Еретики, их слуги и защищённые от магии не страдают. Вал не оглушает. Перезарядка 40 секунд."
	school = "transmutation"
	charge_max = HERETIC_RUST_WAVE_COOLDOWN
	clothes_req = FALSE
	invocation = "FERR'UM UN'DA"
	invocation_type = "shout"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "corrode"
	action_background_icon_state = "bg_ecult"
	var/static/list/hull_walls = typecacheof(list(/turf/closed/wall/mineral/titanium, /turf/closed/wall/mineral/plastitanium))

/obj/effect/proc_holder/spell/self/rust_corrosive_wave/cast(list/targets, mob/living/user)
	var/turf/origin = get_turf(user)
	if(!origin)
		return
	var/list/field = heretic_field_view(HERETIC_RUST_WAVE_RANGE, origin)
	for(var/mob/living/victim in field)
		if(!heretic_can_affect(user, victim))
			continue
		heretic_corrosion(victim, HERETIC_RUST_WAVE_CORROSION)
		log_combat(user, victim, "поражает Коррозийным валом")
	var/list/rings = list()
	for(var/turf/surface in field)
		if(istype(surface, /turf/closed/wall/r_wall/rust) || is_type_in_typecache(surface, hull_walls) || (iswallturf(surface) && faces_void(surface)))
			continue
		if(iswallturf(surface) && !istype(surface, /turf/closed/wall/r_wall))
			var/turf/closed/wall/wall = surface
			wall.dismantle_wall()
			heretic_vfx_burst(surface, /particles/heretic_ascension/rust/heart_wound)
			continue
		var/was_rust = is_heretic_rust_turf(surface)
		var/mutable_appearance/old_look = (isopenturf(surface) && !was_rust) ? new /mutable_appearance(surface) : null
		var/surface_x = surface.x
		var/surface_y = surface.y
		var/surface_z = surface.z
		surface.rust_heretic_act()
		var/turf/changed = locate(surface_x, surface_y, surface_z)
		if(was_rust || !is_heretic_rust_turf(changed))
			continue
		var/distance = max(0, get_dist(origin, changed))
		var/delay = distance * HERETIC_RUST_RIPPLE_STEP
		if(old_look)
			new /obj/effect/temp_visual/heretic_rust_veil(changed, old_look, delay)
			LAZYADDASSOCLIST(rings, "[distance]", changed)
		for(var/obj/effect/temp_visual/glowing_rune/rune in changed)
			rune.alpha = 0
			animate(rune, alpha = 255, time = HERETIC_RUST_RIPPLE_REVEAL, delay = delay, easing = SINE_EASING | EASE_OUT)
	for(var/distance in rings)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_rust_creep_ring), rings[distance]), text2num(distance) * HERETIC_RUST_RIPPLE_STEP)
	new /obj/effect/temp_visual/heretic_oldpath/rust(origin)
	heretic_vfx_shockwave(origin, HERETIC_RUST_INK, HERETIC_RUST_WAVE_RANGE, HERETIC_RUST_WAVE_TIME)
	heretic_vfx_burst(origin, /particles/heretic_ascension/rust)
	heretic_vfx_flash(origin, HERETIC_RUST_INK, HERETIC_RUST_WAVE_FLASH_RANGE, HERETIC_RUST_WAVE_FLASH_POWER)
	heretic_vfx_quake(origin, HERETIC_RUST_WAVE_RANGE, HERETIC_RUST_WAVE_QUAKE, HERETIC_RUST_WAVE_QUAKE_TIME)
	playsound(origin, 'sound/effects/clangsmall2.ogg', 90, TRUE)
	user.visible_message(span_danger("От [user] расходится волна ржавчины, разъедая всё вокруг!"))

/obj/effect/proc_holder/spell/self/rust_corrosive_wave/proc/faces_void(turf/wall)
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(wall, direction)
		if(!neighbor || isgroundlessturf(neighbor))
			return TRUE
	return FALSE

/proc/heretic_rust_creep_ring(list/turfs)
	for(var/turf/place as anything in turfs)
		new /obj/effect/temp_visual/heretic_rust_creep(place)

/// Прежний пол держится поверх ржавого и растворяется, когда до клетки доходит волна вала.
/obj/effect/temp_visual/heretic_rust_veil
	randomdir = FALSE
	duration = HERETIC_RUST_RIPPLE_DISSOLVE

/obj/effect/temp_visual/heretic_rust_veil/Initialize(mapload, mutable_appearance/old_look, delay = 0)
	duration = delay + HERETIC_RUST_RIPPLE_DISSOLVE
	. = ..()
	if(!old_look)
		return INITIALIZE_HINT_QDEL
	appearance = old_look
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FLOOR_PLANE
	layer = TURF_LAYER
	animate(src, alpha = 255, time = delay)
	animate(alpha = 0, time = HERETIC_RUST_RIPPLE_DISSOLVE, easing = SINE_EASING | EASE_IN)

/// Ржавчина проедает клетку пятнами от нескольких очагов, хлопья приподнимаются и гаснут.
/obj/effect/temp_visual/heretic_rust_creep
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "rust_creep"
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE
	duration = HERETIC_RUST_CREEP_HOLD + HERETIC_RUST_CREEP_FADE

/obj/effect/temp_visual/heretic_rust_creep/Initialize(mapload)
	. = ..()
	transform = matrix(pick(-1, 1), 0, 0, 0, pick(-1, 1), 0)
	animate(src, alpha = 255, time = HERETIC_RUST_CREEP_HOLD)
	animate(alpha = 0, time = HERETIC_RUST_CREEP_FADE, easing = SINE_EASING | EASE_IN)

/// Ржавчина: хлопья лениво осыпаются с бьющегося сердца.
/particles/heretic_ascension/rust/heart
	count = 8
	spawning = 0.15
	position = generator("box", list(-18, 0, 0), list(18, 14, 0))
	velocity = generator("box", list(-0.3, -0.2, 0), list(0.3, 0.3, 0))
	gravity = list(0, -0.08)
	friction = 0.02
	lifespan = 2.2 SECONDS
	fade = 0.8 SECONDS
	fadein = 0.3 SECONDS

/// Ржавчина: горсть хлопьев от удара по сердцу или рухнувшей стены.
/particles/heretic_ascension/rust/heart_wound
	count = 10
	spawning = 10
	velocity = generator("circle", 1.5, 3.5)
	gravity = list(0, -0.25)
	lifespan = 0.9 SECONDS
	fade = 0.4 SECONDS

/// Ржавчина: обвал хлопьев на месте разбитого сердца.
/particles/heretic_ascension/rust/collapse
	count = HERETIC_VFX_MAX_PARTICLES
	spawning = HERETIC_VFX_MAX_SPAWNING
	position = generator("box", list(-16, -4, 0), list(16, 12, 0))
	velocity = generator("circle", 2, 5)
	gravity = list(0, -0.25)
	lifespan = 1.6 SECONDS
	fade = 0.6 SECONDS

#undef HERETIC_RUST_INK
#undef HERETIC_RUST_DARK_SHARE
#undef HERETIC_RUST_DARK_INK
#undef HERETIC_RUST_HEART_SCALE
#undef HERETIC_RUST_HEART_SWELL
#undef HERETIC_RUST_HEART_ECHO
#undef HERETIC_RUST_HEART_FLUSH_SHARE
#undef HERETIC_RUST_HEART_GLOW
#undef HERETIC_RUST_HEART_VEINS
#undef HERETIC_RUST_HEART_RISE
#undef HERETIC_RUST_HEART_EMERGE
#undef HERETIC_RUST_HEART_BEAT
#undef HERETIC_RUST_HEART_REST
#undef HERETIC_RUST_HEART_SHUDDER
#undef HERETIC_RUST_HEART_SHUDDER_STEP
#undef HERETIC_RUST_HEART_WOUND_COOLDOWN
#undef HERETIC_RUST_HEART_WOUND_PULSE
#undef HERETIC_RUST_HEART_COLLAPSE
#undef HERETIC_RUST_HEART_DEATH_WAVE
#undef HERETIC_RUST_HEART_DEATH_FLASH
#undef HERETIC_RUST_HEART_DEATH_RADIUS
#undef HERETIC_RUST_HEART_DEATH_POWER
#undef HERETIC_RUST_COLLAPSE_SPREAD
#undef HERETIC_RUST_COLLAPSE_SQUASH
#undef HERETIC_RUST_COLLAPSE_SINK
#undef HERETIC_RUST_RIPPLE_STEP
#undef HERETIC_RUST_RIPPLE_DISSOLVE
#undef HERETIC_RUST_RIPPLE_REVEAL
#undef HERETIC_RUST_CREEP_HOLD
#undef HERETIC_RUST_CREEP_FADE
#undef HERETIC_RUST_WAVE_TIME
#undef HERETIC_RUST_WAVE_FLASH_RANGE
#undef HERETIC_RUST_WAVE_FLASH_POWER
#undef HERETIC_RUST_WAVE_QUAKE
#undef HERETIC_RUST_WAVE_QUAKE_TIME
