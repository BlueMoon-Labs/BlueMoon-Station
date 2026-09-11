#define HERETIC_TIDE_RANGE 5
#define HERETIC_TIDE_WAVE_RADIUS 2
#define HERETIC_TIDE_RELEASE_COST 2
#define HERETIC_TIDE_HARVEST_TIME (6 SECONDS)
#define HERETIC_TIDE_WELL_LIFETIME (12 SECONDS)
#define HERETIC_TIDE_WELL_INTERVAL (2 SECONDS)
#define HERETIC_TIDE_ASCENDED_CAPACITY 8

/datum/heretic_path/tide
	id = PATH_TIDE
	name = "Пучина"
	desc = "Наращивайте давление в ближнем бою и выпускайте его приливными волнами."
	strengths = "Управление дистанцией, давление на группу, связки хватки и клинка."
	weaknesses = "Сильные волны расходуют запас; преграды останавливают течение, а обрушение выдаёт себя заранее."
	knowledge = list(
		/datum/eldritch_knowledge/base_tide,
		/datum/eldritch_knowledge/tide_grasp,
		/datum/eldritch_knowledge/spell/tide_undertow,
		/datum/eldritch_knowledge/tide_mark,
		/datum/eldritch_knowledge/tide_bell,
		/datum/eldritch_knowledge/tide_upgrade,
		/datum/eldritch_knowledge/spell/tide_well,
		/datum/eldritch_knowledge/tide_depth,
		/datum/eldritch_knowledge/spell/tide_deluge,
		/datum/eldritch_knowledge/final_eldritch/tide_final,
	)

/datum/eldritch_knowledge/base_tide
	name = "Берег без солнца"
	desc = "Открывает Путь Пучины. Нож и лист металла создают гарпунный клинок. Его попадания дают единицу давления раз в 6 секунд; начальный запас — 1 из 4. «Сброс давления» расходует 2 единицы: волна в двух клетках наносит врагам 5 ушибов и 12 урона выносливости, отталкивает на клетку и оставляет на них воду Пучины на 8 секунд. Стены останавливают волну."
	gain_text = "Море ушло, но я всё ещё слышал, как оно дышит под моими ногами."
	route = PATH_TIDE
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/melee/sickly_blade/tide)
	combat_resource_name = "Давление"
	combat_resource_desc = "Попадания клинком дают 1 единицу раз в 6 секунд; Хватка глубины — 2, взрыв метки — 1. Сброс и водоворот стоят 2, Обрушение расходует весь запас. Колокол меняет направление Сброса. После смерти давление теряется."
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_tide/release
	grasp_visual = /obj/effect/temp_visual/heretic_tide/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/tide_grasp.ogg'
	var/mob/living/tide_body
	var/obj/structure/heretic_tide_well/active_well
	var/list/datum/status_effect/heretic_drenched/drenched = list()
	var/list/datum/status_effect/eldritch/tide/marks = list()
	var/inward_tide = FALSE
	var/tide_generation = 0
	COOLDOWN_DECLARE(ascended_pressure)

/datum/eldritch_knowledge/base_tide/on_body_gain(mob/living/user)
	if(!user?.mind || tide_body == user)
		return
	if(tide_body)
		on_body_lose(tide_body)
	tide_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	grant_combat_power(user)
	update_capacity()

/datum/eldritch_knowledge/base_tide/on_body_lose(mob/living/user)
	if(tide_body)
		UnregisterSignal(tide_body, COMSIG_PARENT_QDELETING)
	tide_body = null
	remove_combat_power()
	clear_tide()

/datum/eldritch_knowledge/base_tide/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(tide_body)

/datum/eldritch_knowledge/base_tide/on_death(mob/user)
	clear_tide()
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_tide/Destroy()
	on_body_lose(tide_body)
	return ..()

/datum/eldritch_knowledge/base_tide/proc/clear_tide()
	tide_generation++
	QDEL_NULL(active_well)
	for(var/datum/status_effect/heretic_drenched/effect as anything in drenched.Copy())
		qdel(effect)
	drenched.Cut()
	for(var/datum/status_effect/eldritch/tide/mark as anything in marks.Copy())
		qdel(mark)
	marks.Cut()

/datum/eldritch_knowledge/base_tide/proc/can_use(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && user == tide_body && !user.incapacitated() && isturf(user.loc) && heretic?.selected_path == PATH_TIDE && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_tide/proc/update_capacity()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(tide_body)
	var/datum/eldritch_knowledge/tide_depth/depth = heretic?.get_knowledge(/datum/eldritch_knowledge/tide_depth)
	combat_resource_max = heretic?.ascended ? HERETIC_TIDE_ASCENDED_CAPACITY : depth ? depth.passive_values[depth.passive_level] : initial(combat_resource_max)
	combat_resource = min(combat_resource, combat_resource_max)
	notify_resource_changed()

/datum/eldritch_knowledge/base_tide/get_combat_resource_data()
	var/list/data = ..()
	data["description"] = "[combat_resource_desc] Сброс сейчас [inward_tide ? "притягивает" : "отталкивает"]."
	return data

/datum/eldritch_knowledge/base_tide/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!can_use(user) || !proximity_flag || !COOLDOWN_FINISHED(src, resource_harvest) || !heretic_can_affect(user, target, chargecost = 0))
		return
	gain_combat_resource()
	COOLDOWN_START(src, resource_harvest, HERETIC_TIDE_HARVEST_TIME)

/datum/eldritch_knowledge/base_tide/on_life(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || !heretic?.ascended || !COOLDOWN_FINISHED(src, ascended_pressure))
		return
	gain_combat_resource()
	COOLDOWN_START(src, ascended_pressure, 8 SECONDS)

/datum/eldritch_knowledge/base_tide/proc/line_clear(atom/start, atom/end, max_distance = HERETIC_TIDE_RANGE)
	var/turf/origin = get_turf(start)
	var/turf/destination = get_turf(end)
	if(!origin || !destination || origin.z != destination.z || get_dist(origin, destination) > max_distance)
		return FALSE
	for(var/turf/tile as anything in get_line(origin, destination))
		if(!isopenturf(tile) || tile.is_blocked_turf(exclude_mobs = TRUE))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/soak(mob/living/victim)
	return victim.apply_status_effect(/datum/status_effect/heretic_drenched, src)

/datum/eldritch_knowledge/base_tide/proc/move_with_tide(mob/living/victim, atom/center, inward, steps = 1)
	if(victim.anchored || victim.buckled || !isturf(victim.loc))
		return
	for(var/step_index in 1 to steps)
		if(inward)
			if(get_dist(victim, center) <= 1)
				break
			step_towards(victim, center)
		else
			step_away(victim, center)

/datum/eldritch_knowledge/base_tide/proc/release(mob/living/user, ascended_wave = FALSE)
	if(!can_use(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(ascended_wave)
		if(!heretic.ascended)
			return FALSE
	else if(!spend_combat_resource(HERETIC_TIDE_RELEASE_COST))
		return FALSE
	var/wave_radius = ascended_wave ? 3 : HERETIC_TIDE_WAVE_RADIUS
	var/turf/center = get_turf(user)
	for(var/mob/living/victim in range(wave_radius, center))
		if(!isturf(victim.loc) || !line_clear(center, victim, wave_radius) || !heretic_can_affect(user, victim))
			continue
		victim.adjustBruteLoss(ascended_wave ? 12 : 5)
		victim.adjustStaminaLoss(ascended_wave ? 30 : 12)
		soak(victim)
		move_with_tide(victim, center, inward_tide)
		log_combat(user, victim, "поражает приливной волной")
	new /obj/effect/temp_visual/heretic_tide/wave(center)
	playsound(center, 'modular_bluemoon/sound/heretic/tide_release.ogg', 65, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/undertow(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/tide_undertow) || !isliving(victim) || victim.stat == DEAD || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || !isturf(victim.loc) || !line_clear(user, victim))
		return FALSE
	if(!heretic_can_affect(user, victim))
		return TRUE
	var/turf/origin = get_turf(victim)
	victim.adjustStaminaLoss(12)
	soak(victim)
	move_with_tide(victim, user, TRUE, 2)
	for(var/turf/tile as anything in get_line(get_turf(user), origin))
		new /obj/effect/temp_visual/heretic_tide/wave(tile)
	playsound(victim, 'modular_bluemoon/sound/heretic/tide_grasp.ogg', 45, TRUE)
	log_combat(user, victim, "подтягивает отливом")
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/create_well(mob/living/user, turf/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/tide_well) || !isopenturf(place) || isspaceturf(place) || istype(place, /turf/open/lava) || !line_clear(user, place) || !spend_combat_resource(HERETIC_TIDE_RELEASE_COST))
		return FALSE
	QDEL_NULL(active_well)
	active_well = new(place, src)
	playsound(place, 'modular_bluemoon/sound/heretic/tide_release.ogg', 45, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_tide/proc/deluge_turfs(mob/living/user, turf/center)
	var/list/affected = list()
	if(!can_use(user) || !line_clear(user, center))
		return affected
	for(var/turf/tile in range(HERETIC_TIDE_WAVE_RADIUS, center))
		if(line_clear(center, tile, HERETIC_TIDE_WAVE_RADIUS))
			affected += tile
	return affected

/// Обрушение поражает только предупреждённые клетки, оставшиеся доступными после подготовки.
/datum/eldritch_knowledge/base_tide/proc/deluge(mob/living/user, turf/center, list/telegraphed_turfs, expected_generation)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user) || tide_generation != expected_generation || !heretic.get_knowledge(/datum/eldritch_knowledge/spell/tide_deluge) || !length(telegraphed_turfs) || !line_clear(user, center) || combat_resource < HERETIC_TIDE_RELEASE_COST)
		return FALSE
	var/pressure = combat_resource
	spend_combat_resource(pressure)
	for(var/mob/living/victim in range(HERETIC_TIDE_WAVE_RADIUS, center))
		if(!isturf(victim.loc) || !(get_turf(victim) in telegraphed_turfs) || !line_clear(center, victim, HERETIC_TIDE_WAVE_RADIUS) || !heretic_can_affect(user, victim))
			continue
		victim.adjustBruteLoss(8 + pressure * 4)
		victim.adjustStaminaLoss(10 + pressure * 3)
		soak(victim)
		new /obj/effect/temp_visual/heretic_tide/burst(get_turf(victim))
		log_combat(user, victim, "обрушивает толщу Пучины на")
	new /obj/effect/temp_visual/heretic_tide/burst(center)
	playsound(center, 'modular_bluemoon/sound/heretic/tide_deluge.ogg', 80, TRUE)
	return TRUE

/datum/status_effect/heretic_drenched
	id = "heretic_drenched"
	duration = 8 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_drenched
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/tide_ref
	var/mutable_appearance/water_overlay

/datum/status_effect/heretic_drenched/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_tide/tide)
	if(QDELETED(tide))
		qdel(src)
		return
	tide_ref = WEAKREF(tide)
	water_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_tide_effects.dmi', "tide_mark", BELOW_MOB_LAYER)
	return ..()

/datum/status_effect/heretic_drenched/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide || owner.stat == DEAD || IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner))
		return FALSE
	tide.drenched += src
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_water_overlay))
	owner.update_icon()
	return TRUE

/datum/status_effect/heretic_drenched/proc/update_water_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += water_overlay

/datum/status_effect/heretic_drenched/on_remove()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	tide?.drenched.Remove(src)
	UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
	owner.update_icon()
	return ..()

/datum/status_effect/heretic_drenched/be_replaced()
	on_remove()
	return ..()

/datum/status_effect/heretic_drenched/Destroy()
	. = ..()
	QDEL_NULL(water_overlay)
	tide_ref = null
	return .

/atom/movable/screen/alert/status_effect/heretic_drenched
	name = "Вода Пучины"
	desc = "Чужая вода стекает с одежды. Усиленный клинок Пучины наносит вам ещё 5 ушибов. Вода исчезнет через 8 секунд после последнего попадания магии."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_tide"

/datum/status_effect/eldritch/tide
	id = "tide_mark"
	mark_name = "Метка Пучины"
	mark_alert_state = "sigil_tide"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_tide_effects.dmi'
	effect_sprite = "tide_mark"
	detonation_sound = 'modular_bluemoon/sound/heretic/tide_release.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_tide/burst
	var/datum/weakref/tide_ref

/datum/status_effect/eldritch/tide/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_tide/tide)
	if(tide)
		tide_ref = WEAKREF(tide)
	return ..()

/datum/status_effect/eldritch/tide/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide)
		return FALSE
	tide.marks += src
	return TRUE

/datum/status_effect/eldritch/tide/on_remove()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	tide?.marks.Remove(src)
	return ..()

/datum/status_effect/eldritch/tide/on_effect()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.can_use(tide.tide_body) && heretic_can_affect(tide.tide_body, owner, chargecost = 0))
		owner.adjustBruteLoss(8)
		owner.adjustStaminaLoss(12)
	return ..()

/obj/structure/heretic_tide_well
	name = "abyssal whirlpool"
	desc = "Вода вращается над сухим полом и тянет всё живое к чёрной воронке. Разбейте её или коснитесь нулевым жезлом, чтобы оборвать течение."
	icon = 'icons/effects/96x96.dmi'
	icon_state = "whirlpool"
	pixel_x = -32
	pixel_y = -32
	anchored = TRUE
	density = FALSE
	max_integrity = 35
	layer = BELOW_MOB_LAYER
	var/datum/weakref/tide_ref
	var/expires_at
	COOLDOWN_DECLARE(well_pulse)

/obj/structure/heretic_tide_well/Initialize(mapload, datum/eldritch_knowledge/base_tide/tide)
	. = ..()
	if(QDELETED(tide))
		return INITIALIZE_HINT_QDEL
	tide_ref = WEAKREF(tide)
	expires_at = world.time + HERETIC_TIDE_WELL_LIFETIME
	COOLDOWN_START(src, well_pulse, HERETIC_TIDE_WELL_INTERVAL)
	START_PROCESSING(SSobj, src)

/obj/structure/heretic_tide_well/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(tide?.active_well == src)
		tide.active_well = null
	tide_ref = null
	return ..()

/obj/structure/heretic_tide_well/process()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	if(!tide || QDELETED(tide.tide_body) || tide.tide_body.stat == DEAD || !IS_HERETIC(tide.tide_body) || world.time >= expires_at)
		qdel(src)
		return PROCESS_KILL
	if(!COOLDOWN_FINISHED(src, well_pulse))
		return
	COOLDOWN_START(src, well_pulse, HERETIC_TIDE_WELL_INTERVAL)
	pulse()

/obj/structure/heretic_tide_well/proc/pulse()
	var/datum/eldritch_knowledge/base_tide/tide = tide_ref?.resolve()
	var/mob/living/user = tide?.tide_body
	if(!tide || QDELETED(user) || user.stat == DEAD || !IS_HERETIC(user) || !tide.line_clear(user, src, 7) || world.time >= expires_at)
		return FALSE
	for(var/mob/living/victim in range(HERETIC_TIDE_WAVE_RADIUS, src))
		if(!isturf(victim.loc) || !tide.line_clear(src, victim, HERETIC_TIDE_WAVE_RADIUS) || !heretic_can_affect(user, victim))
			continue
		victim.adjustStaminaLoss(6)
		tide.soak(victim)
		tide.move_with_tide(victim, src, TRUE)
		log_combat(user, victim, "затягивает водоворотом")
	new /obj/effect/temp_visual/heretic_tide/wave(get_turf(src))
	return TRUE

/obj/structure/heretic_tide_well/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/item/melee/sickly_blade/tide
	name = "abyssal harpoon"
	desc = "Изогнутый гарпун с бронзовой рукоятью. Внутри лезвия колышется чёрная вода, которой неведомы берега."
	icon = 'modular_bluemoon/icons/obj/heretic_tide.dmi'
	icon_state = "tide_blade"
	item_state = "tide_blade"
	route = PATH_TIDE
	mark_type = /datum/status_effect/eldritch/tide

/obj/item/heretic_path_relic/tide_bell
	name = "drowned bell"
	desc = "Водолазный колокол, умещающийся в ладони. Звон меняет направление Сброса давления своего создателя: отталкивание сменяется притяжением и обратно. Перезарядка — 10 секунд."
	icon_state = "tide_bell"

/obj/item/heretic_path_relic/tide_bell/attack_self(mob/living/user)
	ring(user)

/obj/item/heretic_path_relic/tide_bell/proc/ring(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!authorized(user) || !tide?.can_use(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	tide.inward_tide = !tide.inward_tide
	tide.notify_resource_changed()
	COOLDOWN_START(src, relic_cooldown, 10 SECONDS)
	to_chat(user, span_eldritch("Колокол зовёт [tide.inward_tide ? "прилив: Сброс притягивает противников" : "отлив: Сброс отталкивает противников"]."))
	new /obj/effect/temp_visual/heretic_tide/wave(get_turf(user))
	flick("tide_bell_ring", src)
	playsound(user, 'modular_bluemoon/sound/heretic/tide_bell.ogg', 45, FALSE)
	return TRUE

/obj/effect/temp_visual/heretic_tide
	icon = 'modular_bluemoon/icons/obj/heretic_tide_effects.dmi'
	icon_state = "tide_wave"
	duration = 0.8 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_tide/grasp
	icon_state = "tide_grasp"

/obj/effect/temp_visual/heretic_tide/wave

/obj/effect/temp_visual/heretic_tide/burst
	icon_state = "tide_burst"
	duration = 1.9 SECONDS

/obj/effect/temp_visual/heretic_tide/warning
	icon_state = "tide_warning"
	duration = 2 SECONDS

/obj/effect/proc_holder/spell/self/heretic_tide
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "tide_release"
	action_background_icon_state = "bg_ecult"
	charge_max = 20 SECONDS

/obj/effect/proc_holder/spell/self/heretic_tide/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	return ..() && tide?.can_use(user)

/obj/effect/proc_holder/spell/self/heretic_tide/release
	name = "Сброс давления"
	desc = "Расходует 2 единицы давления: волна в двух клетках наносит 5 ушибов и 12 урона выносливости, сдвигает врагов на клетку и покрывает водой Пучины на 8 секунд. Колокол меняет направление волны."
	charge_max = 15 SECONDS

/obj/effect/proc_holder/spell/self/heretic_tide/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!tide?.release(user))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_tide/leviathan
	name = "Голос Пучины"
	desc = "Волна в трёх клетках наносит 12 ушибов и 30 урона выносливости, сдвигает врагов на клетку и покрывает водой Пучины. Не расходует давление. Доступно после вознесения."
	charge_max = 30 SECONDS
	action_icon_state = "tide_ascend"

/obj/effect/proc_holder/spell/self/heretic_tide/leviathan/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!tide?.release(user, ascended_wave = TRUE))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_tide
	clothes_req = FALSE
	invocation_type = "none"
	range = HERETIC_TIDE_RANGE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "tide_undertow"
	action_background_icon_state = "bg_ecult"
	charge_max = 20 SECONDS
	active_msg = "Укажите цель для магии Пучины."
	deactive_msg = "Вы отпускаете течение."

/obj/effect/proc_holder/spell/pointed/heretic_tide/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	return ..() && tide?.can_use(user)

/obj/effect/proc_holder/spell/pointed/heretic_tide/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	return tide?.line_clear(user, target)

/obj/effect/proc_holder/spell/pointed/heretic_tide/undertow
	name = "Отлив"
	desc = "Притягивает видимого противника в пяти клетках на две клетки ближе, наносит 12 урона выносливости и оставляет воду Пучины на 8 секунд. Стены, закрепление и пристёгивание мешают перемещению."

/obj/effect/proc_holder/spell/pointed/heretic_tide/undertow/can_target(atom/target, mob/user, silent)
	return ..() && heretic_can_affect(user, target, chargecost = 0)

/obj/effect/proc_holder/spell/pointed/heretic_tide/undertow/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!length(targets) || !tide?.undertow(user, targets[1]))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_tide/well
	name = "Чёрный водоворот"
	desc = "Расходует 2 единицы давления и создаёт на открытом полу в пяти клетках водоворот на 12 секунд. Каждые 2 секунды он наносит врагам в двух клетках 6 урона выносливости, покрывает водой и притягивает на клетку. Работает, пока вы в пределах семи клеток и между вами нет преград. Одновременно существует один водоворот с 35 прочности."
	charge_max = 30 SECONDS
	action_icon_state = "tide_well"

/obj/effect/proc_holder/spell/pointed/heretic_tide/well/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!length(targets) || !tide?.create_well(user, get_turf(targets[1])))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_tide/deluge
	name = "Обрушение толщи"
	desc = "Укажите центр в пяти клетках. После двух секунд неподвижной подготовки весь запас давления обрушится на предупреждённую область радиусом две клетки. Урон: 8 ушибов + 4 за единицу давления; выносливость: 10 + 3 за единицу. Нужно хотя бы 2 единицы. Из подсвеченной области можно выйти."
	charge_max = 40 SECONDS
	action_icon_state = "tide_deluge"

/obj/effect/proc_holder/spell/pointed/heretic_tide/deluge/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/turf/center = length(targets) ? get_turf(targets[1]) : null
	if(!tide?.can_use(user) || tide.combat_resource < HERETIC_TIDE_RELEASE_COST || !tide.line_clear(user, center))
		revert_cast(user)
		return
	var/list/telegraphed_turfs = tide.deluge_turfs(user, center)
	var/expected_generation = tide.tide_generation
	for(var/turf/tile as anything in telegraphed_turfs)
		new /obj/effect/temp_visual/heretic_tide/warning(tile)
	user.visible_message(span_danger("[user] поднимает руки. Над полом проступает чёрная вода — сейчас обрушится прилив!"))
	playsound(center, 'modular_bluemoon/sound/heretic/tide_charge.ogg', 50, FALSE)
	if(!do_after(user, 2 SECONDS, target = user) || QDELETED(src) || QDELETED(tide) || !tide.deluge(user, center, telegraphed_turfs, expected_generation))
		revert_cast(user)

/datum/eldritch_knowledge/tide_grasp
	name = "Хватка глубины"
	desc = "Хватка Мансуса по противнику даёт 2 единицы давления и покрывает цель водой Пучины на 8 секунд. Антимагия и союзники не дают давления."
	gain_text = "На дне нет воздуха, но ладонь помнит вес каждого вдоха."
	cost = 1
	route = PATH_TIDE

/datum/eldritch_knowledge/tide_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!proximity_flag || !tide?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	tide.gain_combat_resource(2)
	tide.soak(target)
	return TRUE

/datum/eldritch_knowledge/spell/tide_undertow
	name = "Отлив"
	desc = "Открывает Отлив: притягивайте врага в пяти клетках на две клетки ближе, изматывая на 12 и покрывая водой Пучины на 8 секунд. Не требует давления, перезарядка — 20 секунд. Преграды останавливают течение."
	gain_text = "Я звал с берега. Ответ пришёл из-под ног."
	cost = 1
	route = PATH_TIDE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_tide/undertow

/datum/eldritch_knowledge/tide_mark
	name = "Метка Пучины"
	desc = "Хватка Мансуса оставляет на противнике метку на 15 секунд. Попадание гарпунным клинком взрывает её: 8 ушибов, 12 урона выносливости и единица давления владельцу клинка."
	gain_text = "Вода отступила, оставив на коже очертания невозможного берега."
	cost = 2
	route = PATH_TIDE

/datum/eldritch_knowledge/tide_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!proximity_flag || !tide?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/tide, tide)
	return TRUE

/datum/eldritch_knowledge/tide_bell
	name = "Звон затонувшего храма"
	desc = "Лист золота и металлический прут создают затонувший колокол. Держа его в руке, меняйте направление Сброса давления: отталкивание или притяжение. Звон не расходует давление, перезарядка — 10 секунд. Можно иметь один колокол; он слушается только своего создателя."
	gain_text = "В затонувшем храме всё ещё звонят к утренней службе."
	cost = 1
	route = PATH_TIDE
	required_atoms = list(/obj/item/stack/sheet/mineral/gold, /obj/item/stack/rods)
	result_atoms = list(/obj/item/heretic_path_relic/tide_bell)

/datum/eldritch_knowledge/tide_bell/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/tide_bell/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/tide_bell)

/datum/eldritch_knowledge/tide_upgrade
	name = "Гарпун утопленника"
	desc = "Попадания гарпунным клинком по противнику, покрытому водой Пучины, дополнительно наносят 5 ушибов. Вода остаётся после хватки, Отлива, волн и водоворота."
	gain_text = "Лезвие узнало тех, кого однажды коснулось море."
	cost = 2
	route = PATH_TIDE

/datum/eldritch_knowledge/tide_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	if(!proximity_flag || !tide?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return
	var/mob/living/victim = target
	if(victim.has_status_effect(/datum/status_effect/heretic_drenched))
		victim.adjustBruteLoss(5)

/datum/eldritch_knowledge/spell/tide_well
	name = "Чёрный водоворот"
	desc = "Открывает Чёрный водоворот: за 2 единицы давления создайте в пяти клетках разрушаемую воронку с 35 прочности на 12 секунд. Каждые 2 секунды она покрывает врагов в двух клетках водой, наносит 6 урона выносливости и притягивает на клетку. Работает, пока вы в семи клетках без преград; второй водоворот заменяет первый. Нулевой жезл уничтожает воронку. Перезарядка — 30 секунд."
	gain_text = "Воронка ведёт не вниз. Она ведёт домой."
	cost = 1
	route = PATH_TIDE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_tide/well

/datum/eldritch_knowledge/tide_depth
	name = "Тысяча саженей"
	desc = "Предел давления возрастает до 5. Дополнительные улучшения пассивки увеличивают его до 6 и 7. Улучшение не создаёт давление само по себе."
	gain_text = "У глубины нет дна. Есть лишь предел того, что я готов вместить."
	cost = 2
	route = PATH_TIDE
	passive_values = list(5, 6, 7)
	passive_desc = "Запас давления составляет 5 / 6 / 7 единиц. Вознесение увеличивает предел до 8."

/datum/eldritch_knowledge/tide_depth/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide?.update_capacity()

/datum/eldritch_knowledge/tide_depth/on_passive_upgrade(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide?.update_capacity()

/datum/eldritch_knowledge/spell/tide_deluge
	name = "Обрушение толщи"
	desc = "После двух секунд неподвижной подготовки весь запас давления обрушивается на заранее подсвеченную область радиусом две клетки в пяти клетках от вас. Урон — 8 ушибов плюс 4 за каждую единицу давления и 10 выносливости плюс 3 за единицу. Требует хотя бы 2 давления. Стены защищают, из области можно выйти; сорванная подготовка сохраняет запас. Перезарядка — 40 секунд."
	gain_text = "Я услышал треск стекла. Между нами и морем никогда не было ничего прочнее."
	cost = 2
	sacs_needed = 3
	route = PATH_TIDE
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_tide/deluge

/datum/eldritch_knowledge/final_eldritch/tide_final
	parallax_scene = ANTAG_SCENE_HERETIC_TIDE
	name = "Владыка Пучины"
	desc = "После пяти назначенных душ принесите на руну три человеческих трупа. Обряд раскроет место всей станции и даст экипажу 30 секунд, чтобы помешать. Вознесение увеличивает запас давления до 8 и восстанавливает единицу каждые 8 секунд, пока вы способны действовать. Вы больше не нуждаетесь в дыхании, защищены от высокого и низкого давления и получаете на четверть меньше ушибов и ожогов. «Голос Пучины» раз в 30 секунд выпускает бесплатную волну радиусом три клетки: 12 ушибов и 30 урона выносливости, сдвиг и вода Пучины."
	gain_text = "Берег исчез. Осталось только моё дыхание, и море дышало вместе со мной."
	route = PATH_TIDE
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_traits = list(TRAIT_NOBREATH, TRAIT_RESISTHIGHPRESSURE, TRAIT_RESISTLOWPRESSURE)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_tide/leviathan)

/datum/eldritch_knowledge/final_eldritch/tide_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/tide_final/on_body_gain(mob/living/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_tide/tide = heretic?.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide?.update_capacity()

#undef HERETIC_TIDE_RANGE
#undef HERETIC_TIDE_WAVE_RADIUS
#undef HERETIC_TIDE_RELEASE_COST
#undef HERETIC_TIDE_HARVEST_TIME
#undef HERETIC_TIDE_WELL_LIFETIME
#undef HERETIC_TIDE_WELL_INTERVAL
#undef HERETIC_TIDE_ASCENDED_CAPACITY
