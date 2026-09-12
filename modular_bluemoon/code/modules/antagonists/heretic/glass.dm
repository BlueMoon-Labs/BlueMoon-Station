#define HERETIC_GLASS_RANGE 5
#define HERETIC_GLASS_BARRIER_LIFETIME (12 SECONDS)
#define HERETIC_GLASS_PRISM_LIFETIME (120 SECONDS)
#define HERETIC_GLASS_ATTACK_LIMIT 3
#define HERETIC_GLASS_DEED_DAMAGE 10
#define HERETIC_GLASS_BEAM_DAMAGE 30
#define HERETIC_GLASS_SPLIT_DAMAGE 24
#define HERETIC_GLASS_REFRACTION_BONUS 6

/datum/heretic_path/glass
	id = PATH_GLASS
	deed_type = /datum/heretic_deed/glass
	name = "Стекло"
	desc = "Прожигайте линию стеклянным светом. Призмы усиливают луч и позволяют стрелять из-за угла."
	strengths = "Дальний удар без подготовки, расходящиеся лучи, преломление за углы и защитные преграды."
	weaknesses = "Призмы можно разбить. Лучи заранее отмечают клетки, а стены и перестройка сети прерывают трассу."
	knowledge = list(
		/datum/eldritch_knowledge/base_glass,
		/datum/eldritch_knowledge/glass_grasp,
		/datum/eldritch_knowledge/spell/glass_shards,
		/datum/eldritch_knowledge/glass_mark,
		/datum/eldritch_knowledge/glass_relic,
		/datum/eldritch_knowledge/glass_upgrade,
		/datum/eldritch_knowledge/spell/glass_barrier,
		/datum/eldritch_knowledge/glass_temper,
		/datum/eldritch_knowledge/spell/glass_storm,
		/datum/eldritch_knowledge/final_eldritch/glass_final,
	)

/datum/eldritch_knowledge/base_glass
	name = "Первая трещина"
	desc = "Укажите цель и поразите её стеклянным лучом; выстрел не требует построек или ресурса. Призмы усиливают свет и поворачивают его за углы. Грани нужны только для строительства и восстанавливаются сами. Нож и лист стекла создают стеклянный клинок."
	gain_text = "Я смотрел сквозь стекло, пока не заметил трещину на той стороне неба."
	route = PATH_GLASS
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/glass)
	result_atoms = list(/obj/item/melee/sickly_blade/glass)
	combat_resource = 2
	combat_resource_name = "Грани"
	combat_resource_desc = "Начальный запас 2 из 4. Призма или защитная преграда стоят одну грань. Восстановление — одна каждые 8 секунд, после вознесения каждые 4. Лучи бесплатны и ограничены перезарядкой. Смерть и смена тела рассыпают запас, призмы и подготовленные лучи."
	combat_resource_action = /obj/effect/proc_holder/spell/pointed/heretic_glass/release
	grasp_visual = /obj/effect/temp_visual/heretic_glass/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/glass_grasp.ogg'
	var/mob/living/glass_body
	var/list/datum/heretic_glass_attack/attacks = list()
	var/list/obj/structure/heretic_glass_prism/prisms = list()
	var/list/obj/structure/heretic_glass_barrier/barriers = list()
	var/list/datum/status_effect/heretic_glass_fracture/fractures = list()
	var/list/datum/status_effect/eldritch/glass/marks = list()
	var/list/obj/effect/temp_visual/heretic_glass/visuals = list()
	var/datum/heretic_glass_network/active_network
	var/glass_generation = 0
	var/ascension_active = FALSE
	COOLDOWN_DECLARE(facet_regeneration)

/datum/eldritch_knowledge/base_glass/on_body_gain(mob/living/user)
	if(!user?.mind || glass_body == user)
		return
	if(glass_body)
		on_body_lose(glass_body)
	glass_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	grant_combat_power(user)
	update_temper()
	COOLDOWN_START(src, facet_regeneration, ascension_active ? 4 SECONDS : 8 SECONDS)

/datum/eldritch_knowledge/base_glass/on_body_lose(mob/living/user)
	if(glass_body)
		UnregisterSignal(glass_body, COMSIG_PARENT_QDELETING)
	glass_body = null
	ascension_active = FALSE
	remove_combat_power()
	clear_glass()
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_glass/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(glass_body)

/datum/eldritch_knowledge/base_glass/on_death(mob/user)
	clear_glass()
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_glass/Destroy()
	on_body_lose(glass_body)
	return ..()

/datum/eldritch_knowledge/base_glass/proc/clear_glass()
	glass_generation++
	QDEL_NULL(active_network)
	QDEL_LIST(attacks)
	QDEL_LIST(prisms)
	QDEL_LIST(barriers)
	QDEL_LIST(fractures)
	QDEL_LIST(marks)
	QDEL_LIST(visuals)

/datum/eldritch_knowledge/base_glass/proc/clear_knowledge_effects(datum/eldritch_knowledge/knowledge)
	for(var/datum/heretic_glass_attack/attack as anything in attacks.Copy())
		if(attack.knowledge_ref?.resolve() == knowledge)
			qdel(attack)
	for(var/obj/structure/heretic_glass_prism/prism as anything in prisms.Copy())
		if(prism.knowledge_ref?.resolve() == knowledge)
			qdel(prism)
	for(var/obj/structure/heretic_glass_barrier/barrier as anything in barriers.Copy())
		if(barrier.knowledge_ref?.resolve() == knowledge)
			qdel(barrier)

/datum/eldritch_knowledge/base_glass/proc/can_use(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && user == glass_body && !user.incapacitated() && isturf(user.loc) && heretic?.selected_path == PATH_GLASS && !heretic.role_removed && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_glass/proc/update_temper(ignore_temper = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(glass_body)
	var/datum/eldritch_knowledge/glass_temper/temper = heretic?.get_knowledge(/datum/eldritch_knowledge/glass_temper)
	if(ignore_temper || QDELETED(temper))
		temper = null
	combat_resource_max = ascension_active ? 8 : temper ? temper.passive_values[temper.passive_level] : initial(combat_resource_max)
	combat_resource = min(combat_resource, combat_resource_max)
	for(var/obj/structure/heretic_glass_barrier/barrier as anything in barriers.Copy())
		var/damage = barrier.max_integrity - barrier.obj_integrity
		barrier.max_integrity = temper ? 45 + 15 * temper.passive_level : 45
		barrier.obj_integrity = max(0, barrier.max_integrity - damage)
		if(!barrier.obj_integrity)
			qdel(barrier)
	notify_resource_changed()

/datum/eldritch_knowledge/base_glass/get_combat_resource_data()
	var/list/data = ..()
	data["description"] = "[combat_resource_desc] Установлено призм: [length(prisms)] из [ascension_active ? 5 : 3]."
	return data

/datum/eldritch_knowledge/base_glass/on_mark_detonated(mob/living/user, mob/living/target)
	return

/datum/eldritch_knowledge/base_glass/on_life(mob/user)
	if(!can_use(user) || !COOLDOWN_FINISHED(src, facet_regeneration))
		return
	gain_combat_resource()
	COOLDOWN_START(src, facet_regeneration, ascension_active ? 4 SECONDS : 8 SECONDS)

/datum/eldritch_knowledge/base_glass/proc/line_clear(atom/start, atom/end, max_distance = HERETIC_GLASS_RANGE, allow_prisms = FALSE)
	var/turf/origin = get_turf(start)
	var/turf/destination = get_turf(end)
	if(!origin || !destination || origin.z != destination.z || get_dist(origin, destination) > max_distance)
		return FALSE
	for(var/turf/tile as anything in get_line(origin, destination))
		if(!ray_tile_open(tile, allow_prisms))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/ray_tile_open(turf/tile, allow_prisms = TRUE)
	if(!isopenturf(tile))
		return FALSE
	for(var/obj/obstacle in tile)
		if(!obstacle.density)
			continue
		if(allow_prisms && istype(obstacle, /obj/structure/heretic_glass_prism))
			var/obj/structure/heretic_glass_prism/prism = obstacle
			if(prism.glass_ref?.resolve() == src)
				continue
		return FALSE
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/fracture(mob/living/victim)
	return victim.apply_status_effect(/datum/status_effect/heretic_glass_fracture, src)

/datum/eldritch_knowledge/base_glass/proc/prism_snapshot(obj/structure/heretic_glass_prism/prism)
	return list("ref" = WEAKREF(prism), "dir" = prism.dir, "split" = prism.split, "turf" = get_turf(prism))

/// Каждая отмеченная клетка хранит весь путь луча и положения его призм.
/datum/eldritch_knowledge/base_glass/proc/trace_ray(turf/start, direction, obj/structure/heretic_glass_prism/source_prism, turf/aimed_turf)
	var/list/result = list()
	var/list/queue = list()
	var/list/first_nodes = list()
	var/list/first_path = list(start)
	if(source_prism)
		first_nodes += list(prism_snapshot(source_prism))
		for(var/output_dir in source_prism.output_directions())
			queue += list(list("place" = start, "dir" = output_dir, "path" = first_path.Copy(), "nodes" = first_nodes.Copy(), "split" = source_prism.split))
	else
		var/aim_delta_x = aimed_turf ? aimed_turf.x - start.x : 0
		var/aim_delta_y = aimed_turf ? aimed_turf.y - start.y : 0
		queue += list(list("place" = start, "dir" = direction, "path" = first_path, "nodes" = first_nodes, "split" = FALSE, "aim_delta_x" = aim_delta_x, "aim_delta_y" = aim_delta_y))
	var/cell_budget = ascension_active ? 18 : 12
	var/refraction_limit = ascension_active ? 5 : 3
	while(length(queue) && cell_budget > 0)
		var/list/branch = queue[1]
		queue.Cut(1, 2)
		var/turf/tile = branch["place"]
		var/list/path = branch["path"]
		var/list/nodes = branch["nodes"]
		var/aim_delta_x = branch["aim_delta_x"] || 0
		var/aim_delta_y = branch["aim_delta_y"] || 0
		var/aim_steps = max(abs(aim_delta_x), abs(aim_delta_y))
		for(var/step_index in 1 to HERETIC_GLASS_RANGE)
			if(cell_budget-- <= 0)
				break
			if(aim_steps)
				var/offset_x = SIGN(aim_delta_x) * round(abs(aim_delta_x) * step_index / aim_steps + 0.5)
				var/offset_y = SIGN(aim_delta_y) * round(abs(aim_delta_y) * step_index / aim_steps + 0.5)
				tile = locate(start.x + offset_x, start.y + offset_y, start.z)
			else
				tile = get_step(tile, branch["dir"])
			if(!tile || !ray_tile_open(tile))
				break
			path += tile
			var/obj/structure/heretic_glass_prism/prism = locate() in tile
			if(prism)
				var/seen = FALSE
				for(var/list/snapshot as anything in nodes)
					var/datum/weakref/prism_ref = snapshot["ref"]
					if(prism_ref.resolve() == prism)
						seen = TRUE
						break
				if(seen || length(nodes) >= refraction_limit)
					break
				nodes += list(prism_snapshot(prism))
				for(var/output_dir in prism.output_directions())
					queue += list(list("place" = tile, "dir" = output_dir, "path" = path.Copy(), "nodes" = nodes.Copy(), "split" = branch["split"] || prism.split))
				break
			result += list(list("tile" = tile, "dir" = branch["dir"], "path" = path.Copy(), "nodes" = nodes.Copy(), "split" = branch["split"]))
	return result

/datum/eldritch_knowledge/base_glass/proc/route_valid(list/cell)
	var/list/allowed_prisms = list()
	var/list/nodes = cell["nodes"]
	for(var/list/snapshot as anything in nodes)
		var/datum/weakref/prism_ref = snapshot["ref"]
		var/obj/structure/heretic_glass_prism/prism = prism_ref.resolve()
		if(!prism || prism.glass_ref?.resolve() != src || get_turf(prism) != snapshot["turf"] || prism.dir != snapshot["dir"] || prism.split != snapshot["split"])
			return FALSE
		allowed_prisms += prism
	var/list/path = cell["path"]
	for(var/turf/tile as anything in path)
		if(!ray_tile_open(tile))
			return FALSE
		var/obj/structure/heretic_glass_prism/prism = locate() in tile
		if(prism && !(prism in allowed_prisms))
			return FALSE
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/release(mob/living/user, atom/target)
	var/turf/destination = get_turf(target)
	if(!can_use(user) || !destination || destination == get_turf(user) || destination.z != user.z || get_dist(user, target) > HERETIC_GLASS_RANGE || length(attacks) >= HERETIC_GLASS_ATTACK_LIMIT)
		return FALSE
	var/list/cells = trace_ray(get_turf(user), get_dir(user, target), aimed_turf = destination)
	if(!length(cells))
		return FALSE
	new /datum/heretic_glass_attack(src, cells, 0.6 SECONDS, src)
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/valid_prism_turf(mob/living/user, turf/place)
	if(!can_use(user) || !isopenturf(place) || isspaceturf(place) || istype(place, /turf/open/lava) || !line_clear(user, place) || length(prisms) >= (ascension_active ? 5 : 3))
		return FALSE
	for(var/mob/living/occupant in place)
		return FALSE
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/shards(mob/living/user, atom/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	if(!can_use(user) || QDELETED(required))
		return FALSE
	if(istype(target, /obj/structure/heretic_glass_prism))
		var/obj/structure/heretic_glass_prism/prism = target
		if(prism.glass_ref?.resolve() != src || !line_clear(user, prism, allow_prisms = TRUE))
			return FALSE
		prism.face_user(user)
		return TRUE
	if(!isturf(target) || !valid_prism_turf(user, target) || !spend_combat_resource())
		return FALSE
	var/obj/structure/heretic_glass_prism/prism = new(target, src)
	prism.face_user(user)
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/valid_barrier_turf(mob/living/user, turf/place)
	if(!can_use(user) || !isopenturf(place) || isspaceturf(place) || istype(place, /turf/open/lava) || !line_clear(user, place) || length(barriers) >= 2)
		return FALSE
	for(var/mob/living/occupant in place)
		return FALSE
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/create_barrier(mob/living/user, turf/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_barrier)
	if(QDELETED(required) || !valid_barrier_turf(user, place) || !spend_combat_resource())
		return null
	var/obj/structure/heretic_glass_barrier/barrier = new(place, src)
	update_temper()
	playsound(place, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 45, TRUE)
	return barrier

/datum/eldritch_knowledge/base_glass/proc/network_cells(mob/living/user)
	var/list/cells = list()
	if(!can_use(user))
		return cells
	for(var/obj/structure/heretic_glass_prism/prism as anything in prisms)
		if(line_clear(user, prism, allow_prisms = TRUE))
			cells += trace_ray(get_turf(prism), prism.dir, prism)
	return cells

/datum/eldritch_knowledge/base_glass/proc/radial_cells(mob/living/user)
	var/list/cells = list()
	if(!can_use(user))
		return cells
	for(var/direction in GLOB.alldirs)
		cells += trace_ray(get_turf(user), direction)
	return cells

/datum/eldritch_knowledge/base_glass/proc/storm(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_storm)
	if(!can_use(user) || QDELETED(required) || length(attacks) >= HERETIC_GLASS_ATTACK_LIMIT)
		return FALSE
	var/list/cells = radial_cells(user) + network_cells(user)
	if(!length(cells))
		return FALSE
	new /datum/heretic_glass_attack(src, cells, 1 SECONDS, required, bonus_damage = 10)
	user.visible_message(span_danger("[user] соединяет пальцы. Вокруг вспыхивают расходящиеся лучи!"))
	return TRUE

/datum/eldritch_knowledge/base_glass/proc/crown(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/final_eldritch/glass_final/required = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/glass_final)
	if(!can_use(user) || !ascension_active || !required?.finished || required.applied_body != user || active_network || length(attacks) >= HERETIC_GLASS_ATTACK_LIMIT)
		return FALSE
	if(!length(radial_cells(user)) && !length(network_cells(user)))
		return FALSE
	active_network = new(src, required)
	return TRUE

/datum/heretic_glass_attack
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref
	var/datum/weakref/body_ref
	var/datum/weakref/network_ref
	var/network_id
	var/turf/origin
	var/list/cells
	var/list/obj/effect/temp_visual/heretic_glass/warnings = list()
	var/generation
	var/release_timer
	var/stationary
	var/resolved = FALSE
	var/damage_bonus = 0

/datum/heretic_glass_attack/New(datum/eldritch_knowledge/base_glass/glass, list/beam_cells, delay, datum/eldritch_knowledge/required, must_stay = FALSE, datum/heretic_glass_network/network, bonus_damage = 0)
	. = ..()
	glass_ref = WEAKREF(glass)
	knowledge_ref = WEAKREF(required)
	body_ref = WEAKREF(glass.glass_body)
	origin = get_turf(glass.glass_body)
	cells = beam_cells
	generation = glass.glass_generation
	stationary = must_stay
	damage_bonus = bonus_damage
	if(network)
		network_ref = WEAKREF(network)
		network_id = REF(network)
	glass.attacks += src
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_source_deleted))
	if(stationary)
		RegisterSignal(glass.glass_body, COMSIG_MOVABLE_MOVED, PROC_REF(on_source_deleted))
	var/list/warned = list()
	for(var/list/cell as anything in cells)
		var/turf/tile = cell["tile"]
		if(tile in warned)
			continue
		warned += tile
		warnings += new /obj/effect/temp_visual/heretic_glass/warning(tile, glass, delay)
	playsound(origin, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 40, FALSE)
	release_timer = addtimer(CALLBACK(src, PROC_REF(resolve)), delay, TIMER_STOPPABLE)

/datum/heretic_glass_attack/proc/on_source_deleted(datum/source)
	SIGNAL_HANDLER
	var/datum/heretic_glass_network/network = network_ref?.resolve()
	if(network)
		qdel(network)
	qdel(src)

/datum/heretic_glass_attack/proc/resolve()
	if(QDELETED(src) || resolved)
		return FALSE
	resolved = TRUE
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	var/mob/living/user = body_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!glass?.can_use(user) || glass.glass_generation != generation || !required || heretic.get_knowledge(required.type) != required || (stationary && get_turf(user) != origin) || (network_ref && !network_ref.resolve()) || (!network_ref && !glass.line_clear(user, origin, allow_prisms = TRUE)))
		qdel(src)
		return FALSE
	QDEL_LIST(warnings)
	var/list/mob/living/hit_damage = list()
	var/list/rendered = list()
	var/datum/eldritch_knowledge/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/glass_upgrade)
	for(var/list/cell as anything in cells)
		if(!glass.route_valid(cell))
			continue
		var/list/nodes = cell["nodes"]
		if(network_ref && !length(nodes) && !glass.line_clear(user, origin, allow_prisms = TRUE))
			continue
		if(network_ref && length(nodes))
			var/list/source_snapshot = nodes[1]
			var/datum/weakref/source_ref = source_snapshot["ref"]
			if(!glass.line_clear(user, source_ref.resolve(), allow_prisms = TRUE))
				continue
		var/turf/tile = cell["tile"]
		if(!(tile in rendered))
			rendered += tile
			var/obj/effect/temp_visual/heretic_glass/shard/visual = new(tile, glass)
			visual.setDir(cell["dir"])
		for(var/mob/living/victim in tile)
			var/damage = (cell["split"] ? HERETIC_GLASS_SPLIT_DAMAGE : HERETIC_GLASS_BEAM_DAMAGE) + damage_bonus
			if(length(nodes))
				damage += HERETIC_GLASS_REFRACTION_BONUS
			var/datum/status_effect/heretic_glass_fracture/fracture = victim.has_status_effect(/datum/status_effect/heretic_glass_fracture)
			if(fracture?.glass_ref?.resolve() == glass)
				damage += !QDELETED(upgrade) ? 14 : 8
			hit_damage[victim] = max(hit_damage[victim], damage)
	for(var/mob/living/victim as anything in hit_damage)
		if(!heretic_can_affect(user, victim))
			continue
		victim.adjustBruteLoss(hit_damage[victim])
		log_combat(user, victim, "поражает преломлённым лучом")
	playsound(origin, stationary || network_ref ? 'modular_bluemoon/sound/heretic/glass_storm.ogg' : 'modular_bluemoon/sound/heretic/glass_release.ogg', 55, TRUE)
	qdel(src)
	return TRUE

/datum/heretic_glass_attack/Destroy()
	deltimer(release_timer)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.attacks.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	var/mob/living/user = body_ref?.resolve()
	if(stationary && user)
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	QDEL_LIST(warnings)
	cells = null
	origin = null
	glass_ref = null
	knowledge_ref = null
	body_ref = null
	network_ref = null
	return ..()

/datum/heretic_glass_network
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref
	var/list/datum/weakref/node_refs = list()
	var/list/watched_nodes = list()
	var/pulse_timer
	var/pulses = 0
	var/generation

/datum/heretic_glass_network/New(datum/eldritch_knowledge/base_glass/glass, datum/eldritch_knowledge/required)
	. = ..()
	glass_ref = WEAKREF(glass)
	knowledge_ref = WEAKREF(required)
	generation = glass.glass_generation
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_node_deleted))
	for(var/obj/structure/heretic_glass_prism/prism as anything in glass.prisms)
		if(!glass.line_clear(glass.glass_body, prism, allow_prisms = TRUE))
			continue
		node_refs += WEAKREF(prism)
		watch_node(prism)
	pulse()

/datum/heretic_glass_network/proc/watch_node(obj/structure/heretic_glass_prism/prism)
	if(QDELETED(prism) || watched_nodes[REF(prism)])
		return
	watched_nodes[REF(prism)] = WEAKREF(prism)
	RegisterSignal(prism, COMSIG_PARENT_QDELETING, PROC_REF(on_node_deleted))

/datum/heretic_glass_network/proc/on_node_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/heretic_glass_network/proc/pulse()
	if(QDELETED(src) || pulses >= 3)
		return FALSE
	deltimer(pulse_timer)
	pulse_timer = null
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	var/mob/living/user = glass?.glass_body
	if(!glass?.can_use(user) || !glass.ascension_active || glass.glass_generation != generation || !required)
		qdel(src)
		return FALSE
	var/list/cells = glass.radial_cells(user)
	for(var/datum/weakref/prism_ref as anything in node_refs)
		var/obj/structure/heretic_glass_prism/prism = prism_ref.resolve()
		if(prism && glass.line_clear(user, prism, allow_prisms = TRUE))
			cells += glass.trace_ray(get_turf(prism), prism.dir, prism)
	if(!length(cells) || length(glass.attacks) >= HERETIC_GLASS_ATTACK_LIMIT)
		qdel(src)
		return FALSE
	for(var/list/cell as anything in cells)
		var/list/nodes = cell["nodes"]
		for(var/list/snapshot as anything in nodes)
			var/datum/weakref/prism_ref = snapshot["ref"]
			watch_node(prism_ref.resolve())
	new /datum/heretic_glass_attack(glass, cells, 1 SECONDS, required, FALSE, src, 14)
	for(var/prism_id in watched_nodes)
		var/datum/weakref/prism_ref = watched_nodes[prism_id]
		var/obj/structure/heretic_glass_prism/prism = prism_ref.resolve()
		if(prism)
			new /obj/effect/temp_visual/heretic_glass/storm(get_turf(prism), glass)
	pulses++
	if(pulses < 3)
		pulse_timer = addtimer(CALLBACK(src, PROC_REF(pulse)), 4 SECONDS, TIMER_STOPPABLE)
	else
		pulse_timer = addtimer(CALLBACK(src, PROC_REF(expire)), 3 SECONDS, TIMER_STOPPABLE)
	return TRUE

/datum/heretic_glass_network/proc/expire()
	qdel(src)

/datum/heretic_glass_network/Destroy()
	deltimer(pulse_timer)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(glass)
		if(glass.active_network == src)
			glass.active_network = null
		for(var/datum/heretic_glass_attack/attack as anything in glass.attacks.Copy())
			if(attack.network_id == REF(src))
				qdel(attack)
	for(var/prism_id in watched_nodes)
		var/datum/weakref/prism_ref = watched_nodes[prism_id]
		var/obj/structure/heretic_glass_prism/prism = prism_ref.resolve()
		if(prism)
			UnregisterSignal(prism, COMSIG_PARENT_QDELETING)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	node_refs.Cut()
	watched_nodes.Cut()
	glass_ref = null
	knowledge_ref = null
	return ..()

/datum/status_effect/heretic_glass_fracture
	id = "heretic_glass_fracture"
	duration = 12 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_glass_fracture
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/glass_ref
	var/mutable_appearance/fracture_overlay

/datum/status_effect/heretic_glass_fracture/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_glass/glass)
	if(QDELETED(glass))
		qdel(src)
		return
	glass_ref = WEAKREF(glass)
	fracture_overlay = mutable_appearance('modular_bluemoon/icons/obj/heretic_glass_effects.dmi', "glass_mark", BELOW_MOB_LAYER)
	return ..()

/datum/status_effect/heretic_glass_fracture/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(!glass || owner.stat == DEAD || IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner))
		return FALSE
	glass.fractures += src
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_fracture))
	owner.update_icon()
	return TRUE

/datum/status_effect/heretic_glass_fracture/proc/update_fracture(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += fracture_overlay

/datum/status_effect/heretic_glass_fracture/on_remove()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.fractures.Remove(src)
	UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
	owner.update_icon()
	return ..()

/datum/status_effect/heretic_glass_fracture/be_replaced()
	on_remove()
	return ..()

/datum/status_effect/heretic_glass_fracture/Destroy()
	. = ..()
	QDEL_NULL(fracture_overlay)
	glass_ref = null
	return .

/atom/movable/screen/alert/status_effect/heretic_glass_fracture
	name = "Стеклянные трещины"
	desc = "Любой луч заклинателя нанесёт вам ещё 8 ушибов, с усилением — 14. Трещины исчезают через 12 секунд после последней хватки или взрыва метки."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_glass"

/datum/status_effect/eldritch/glass
	id = "glass_mark"
	mark_name = "Метка Стекла"
	mark_alert_state = "sigil_glass"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_glass_effects.dmi'
	effect_sprite = "glass_mark"
	detonation_sound = 'modular_bluemoon/sound/heretic/glass_release.ogg'
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref

/datum/status_effect/eldritch/glass/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_glass/glass)
	if(glass)
		glass_ref = WEAKREF(glass)
	return ..()

/datum/status_effect/eldritch/glass/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(!glass)
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(glass.glass_body)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/glass_mark)
	if(QDELETED(required))
		return FALSE
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	glass.marks += src
	return TRUE

/datum/status_effect/eldritch/glass/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/eldritch/glass/on_remove()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.marks.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	return ..()

/datum/status_effect/eldritch/glass/on_effect()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(glass?.can_use(glass.glass_body) && heretic_can_affect(glass.glass_body, owner, chargecost = 0))
		owner.adjustBruteLoss(8)
		glass.fracture(owner)
		new /obj/effect/temp_visual/heretic_glass/burst(get_turf(owner), glass)
	return ..()

/obj/structure/heretic_glass_prism
	name = "refracting prism"
	desc = "Стеклянный узел на тонкой оправе. Поворачивает луч своего создателя по светящейся стрелке; в раздвоенном режиме выпускает два луча под углом 45°. Призму можно разбить или разрушить нулевым жезлом."
	icon = 'modular_bluemoon/icons/obj/heretic_glass_effects.dmi'
	icon_state = "glass_prism"
	density = TRUE
	anchored = TRUE
	max_integrity = 45
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref
	var/split = FALSE
	var/expires_at

/obj/structure/heretic_glass_prism/Initialize(mapload, datum/eldritch_knowledge/base_glass/glass)
	. = ..()
	if(QDELETED(glass))
		return INITIALIZE_HINT_QDEL
	glass_ref = WEAKREF(glass)
	glass.prisms += src
	var/datum/antagonist/heretic/heretic = IS_HERETIC(glass.glass_body)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	if(QDELETED(required))
		return INITIALIZE_HINT_QDEL
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	expires_at = world.time + HERETIC_GLASS_PRISM_LIFETIME
	START_PROCESSING(SSobj, src)

/obj/structure/heretic_glass_prism/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/heretic_glass_prism/proc/face_user(mob/living/user)
	setDir(user.dir & NORTH ? NORTH : user.dir & SOUTH ? SOUTH : user.dir)
	playsound(src, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 30, TRUE)

/obj/structure/heretic_glass_prism/proc/output_directions()
	return split ? list(turn(dir, 45), turn(dir, -45)) : list(dir)

/obj/structure/heretic_glass_prism/proc/toggle_split()
	split = !split
	icon_state = split ? "glass_prism_split" : "glass_prism"

/obj/structure/heretic_glass_prism/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(glass?.can_use(user) && user.Adjacent(src))
		face_user(user)
		return
	return ..()

/obj/structure/heretic_glass_prism/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/structure/heretic_glass_prism/process()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(!glass || QDELETED(glass.glass_body) || glass.glass_body.stat == DEAD || world.time >= expires_at)
		qdel(src)
		return PROCESS_KILL

/obj/structure/heretic_glass_prism/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.prisms.Remove(src)
	glass?.notify_resource_changed()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	glass_ref = null
	knowledge_ref = null
	return ..()

/obj/structure/heretic_glass_barrier
	name = "refracted pane"
	desc = "Острое стекло застыло поперёк прохода. Оно задерживает всех, включая создателя. Разбейте преграду или коснитесь её нулевым жезлом. Создатель может убрать её рукой."
	icon = 'modular_bluemoon/icons/obj/heretic_glass_effects.dmi'
	icon_state = "glass_barrier"
	anchored = TRUE
	density = TRUE
	opacity = FALSE
	max_integrity = 45
	var/datum/weakref/glass_ref
	var/datum/weakref/knowledge_ref
	var/expires_at

/obj/structure/heretic_glass_barrier/Initialize(mapload, datum/eldritch_knowledge/base_glass/glass)
	. = ..()
	if(QDELETED(glass))
		return INITIALIZE_HINT_QDEL
	glass_ref = WEAKREF(glass)
	glass.barriers += src
	var/datum/antagonist/heretic/heretic = IS_HERETIC(glass.glass_body)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/glass_barrier)
	if(!required)
		return INITIALIZE_HINT_QDEL
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	expires_at = world.time + HERETIC_GLASS_BARRIER_LIFETIME
	START_PROCESSING(SSobj, src)

/obj/structure/heretic_glass_barrier/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/heretic_glass_barrier/process()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(!glass || QDELETED(glass.glass_body) || glass.glass_body.stat == DEAD || world.time >= expires_at)
		qdel(src)
		return PROCESS_KILL

/obj/structure/heretic_glass_barrier/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(glass?.can_use(user) && user.Adjacent(src))
		playsound(src, 'modular_bluemoon/sound/heretic/glass_release.ogg', 40, TRUE)
		qdel(src)
		return
	return ..()

/obj/structure/heretic_glass_barrier/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/structure/heretic_glass_barrier/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.barriers.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	glass_ref = null
	knowledge_ref = null
	return ..()

/obj/item/melee/sickly_blade/glass
	name = "refracted blade"
	desc = "Полупрозрачный клинок с лезвием, расколотым на десятки острых граней. В каждой из них отражается свой оттенок пустого неба."
	icon = 'modular_bluemoon/icons/obj/heretic_glass.dmi'
	icon_state = "glass_blade"
	item_state = "glass_blade"
	route = PATH_GLASS
	mark_type = /datum/status_effect/eldritch/glass

/obj/item/heretic_path_relic/glass
	name = "widow's prism"
	desc = "Ручная линза в потемневшей оправе. Меняет ближайшую вашу призму в пяти клетках: один выход по стрелке или два под углом 45° к ней. Раздвоенный свет наносит 30 ушибов вместо 36. Перезарядка переключения 5 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_glass.dmi'
	icon_state = "glass_relic"

/obj/item/heretic_path_relic/glass/attack_self(mob/living/user)
	return rotate_prism(user)

/obj/item/heretic_path_relic/glass/proc/rotate_prism(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!authorized(user) || !glass?.can_use(user) || !COOLDOWN_FINISHED(src, relic_cooldown))
		return FALSE
	var/obj/structure/heretic_glass_prism/nearest
	var/nearest_distance = HERETIC_GLASS_RANGE + 1
	for(var/obj/structure/heretic_glass_prism/prism as anything in glass.prisms)
		var/distance = get_dist(user, prism)
		if(distance < nearest_distance && glass.line_clear(user, prism, allow_prisms = TRUE))
			nearest = prism
			nearest_distance = distance
	if(!nearest)
		return FALSE
	nearest.toggle_split()
	COOLDOWN_START(src, relic_cooldown, 5 SECONDS)
	to_chat(user, span_eldritch("Ближайшая призма теперь [nearest.split ? "расщепляет луч надвое" : "поворачивает луч по стрелке"]."))
	playsound(user, 'modular_bluemoon/sound/heretic/glass_grasp.ogg', 35, TRUE)
	return TRUE

/obj/effect/temp_visual/heretic_glass
	icon = 'modular_bluemoon/icons/obj/heretic_glass_effects.dmi'
	icon_state = "glass_shard"
	duration = 0.8 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	var/datum/weakref/glass_ref

/obj/effect/temp_visual/heretic_glass/Initialize(mapload, datum/eldritch_knowledge/base_glass/glass, lifetime)
	if(!QDELETED(glass))
		glass_ref = WEAKREF(glass)
		glass.visuals += src
	if(!isnull(lifetime))
		duration = lifetime
	return ..()

/obj/effect/temp_visual/heretic_glass/Destroy()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.visuals.Remove(src)
	glass_ref = null
	return ..()

/obj/effect/temp_visual/heretic_glass/grasp
	icon_state = "glass_grasp"

/obj/effect/temp_visual/heretic_glass/shard

/obj/effect/temp_visual/heretic_glass/burst
	icon_state = "glass_burst"

/obj/effect/temp_visual/heretic_glass/warning
	icon_state = "glass_warning"
	duration = 2 SECONDS
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_glass/storm
	icon_state = "glass_storm"
	duration = 1.5 SECONDS

/datum/eldritch_knowledge/base_glass/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !proximity_flag || !isturf(target.loc))
		return FALSE
	var/obj/structure/pane = target
	if(istype(pane, /obj/structure/mirror))
		if(pane.broken)
			return FALSE
	else if(!istype(pane, /obj/structure/window) || pane.obj_integrity <= 0)
		return FALSE
	pane.take_damage(HERETIC_GLASS_DEED_DAMAGE, BRUTE, MELEE, FALSE)
	playsound(pane, 'sound/effects/Glasshit.ogg', 40, TRUE)
	heretic.advance_deed(heretic.deed_key_for(pane), get_turf(user))
	return TRUE

/datum/eldritch_knowledge/glass_grasp
	name = "Стеклянная ладонь"
	desc = "Хватка Мансуса оставляет стеклянные трещины на 12 секунд. Любой ваш луч наносит такой цели ещё 8 ушибов: хватка и прямой выстрел работают без установки призм."
	gain_text = "На ладони проступили линии. Каждая разделяла мир на две неравные части."
	cost = 1
	route = PATH_GLASS

/datum/eldritch_knowledge/glass_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!proximity_flag || !glass?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	glass.fracture(target)
	return TRUE

/datum/eldritch_knowledge/spell/glass_shards
	name = "Оправа для света"
	desc = "За одну грань поставьте на свободном полу в пяти клетках призму с 45 прочности на 2 минуты. Она поворачивает ваш луч по стрелке и добавляет ему 6 ушибов один раз за выстрел. Можно иметь три призмы. Повторный выбор поворачивает её туда, куда вы смотрите; рядом можно повернуть рукой. Перезарядка 4 секунды. Призмы разрушаются ударами и нулевым жезлом."
	gain_text = "Я поднял осколок. Разрез на пальце появился раньше, чем я коснулся края."
	cost = 1
	route = PATH_GLASS
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_glass/shards

/datum/eldritch_knowledge/spell/glass_shards/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/glass_mark
	name = "Метка Стекла"
	desc = "Хватка Мансуса оставляет метку на 15 секунд. Удар стеклянного клинка взрывает её: 8 ушибов и стеклянные трещины на 12 секунд. Трещины подготавливают цель к преломлённым лучам; метка не создаёт строительного ресурса."
	gain_text = "Трещина обогнула сердце и замкнулась. Стекло ждало первого удара."
	cost = 2
	route = PATH_GLASS

/datum/eldritch_knowledge/glass_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!proximity_flag || !glass?.can_use(user) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/glass, glass)
	return TRUE

/datum/eldritch_knowledge/glass_mark/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(glass)
		QDEL_LIST(glass.marks)

/datum/eldritch_knowledge/glass_relic
	name = "Призма вдовы"
	desc = "Лист стекла и лист серебра создают ручную линзу. В руке она переключает ближайшую вашу призму в пяти клетках: один луч по стрелке или два под углом 45°. Раздвоенный свет наносит 30 ушибов вместо 36; каждая цель получает урон один раз за залп. Перезарядка 5 секунд, можно иметь одну линзу."
	gain_text = "Вдова держала призму перед свечой. На стене горели три огня, и ни один не грел."
	cost = 1
	route = PATH_GLASS
	required_atoms = list(/obj/item/stack/sheet/glass, /obj/item/stack/sheet/mineral/silver)
	result_atoms = list(/obj/item/heretic_path_relic/glass)
	var/datum/weakref/glass_ref

/datum/eldritch_knowledge/glass_relic/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(glass)
		glass_ref = WEAKREF(glass)

/datum/eldritch_knowledge/glass_relic/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/glass_relic/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/glass)

/datum/eldritch_knowledge/glass_relic/on_lose(mob/user)
	reset_prism()
	return ..()

/datum/eldritch_knowledge/glass_relic/proc/reset_prism()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	if(glass)
		for(var/obj/structure/heretic_glass_prism/prism as anything in glass.prisms)
			if(prism.split)
				prism.toggle_split()

/datum/eldritch_knowledge/glass_relic/Destroy()
	reset_prism()
	glass_ref = null
	return ..()

/datum/eldritch_knowledge/glass_upgrade
	name = "Резонанс трещины"
	desc = "Бонус любого вашего луча по цели со стеклянными трещинами возрастает с 8 до 14 ушибов. Прямой выстрел наносит такой цели 44 ушиба; преломлённый своей призмой — 50."
	gain_text = "Стекольщик провёл черту, и целая плоскость послушно разделилась надвое."
	cost = 2
	route = PATH_GLASS

/datum/eldritch_knowledge/spell/glass_barrier
	name = "Хрупкая преграда"
	desc = "За одну грань поднимите на свободном полу в пяти клетках прозрачную преграду на 12 секунд. Она имеет 45 прочности и задерживает всех, включая вас. Можно держать две преграды; уберите свою рукой или разбейте. Нулевой жезл разрушает её сразу. Перезарядка 8 секунд."
	gain_text = "Достаточно одной тонкой плоскости, чтобы разлучить протянутые руки."
	cost = 1
	route = PATH_GLASS
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_glass/barrier

/datum/eldritch_knowledge/spell/glass_barrier/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/glass_temper
	name = "Закалка"
	desc = "Запас граней увеличивается до пяти, а прочность преград — до 60. Уже полученный урон и оставшийся срок жизни преград сохраняются."
	gain_text = "Огонь не расплавил стекло. Он выжег из него право гнуться."
	cost = 2
	route = PATH_GLASS
	passive_values = list(5, 6, 7)
	passive_desc = "Вместимость составляет 5 / 6 / 7 граней, прочность преград — 60 / 75 / 90. Вознесение даёт вместимость 8. Улучшение не заполняет запас и не чинит прежний урон."
	var/datum/weakref/glass_ref

/datum/eldritch_knowledge/glass_temper/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(glass)
		glass_ref = WEAKREF(glass)
	on_passive_upgrade(user)

/datum/eldritch_knowledge/glass_temper/on_passive_upgrade(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass?.update_temper()

/datum/eldritch_knowledge/glass_temper/on_lose(mob/user)
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.update_temper(ignore_temper = TRUE)
	return ..()

/datum/eldritch_knowledge/glass_temper/Destroy()
	var/datum/eldritch_knowledge/base_glass/glass = glass_ref?.resolve()
	glass?.update_temper(ignore_temper = TRUE)
	glass_ref = null
	return ..()

/datum/eldritch_knowledge/spell/glass_storm
	name = "Перекрёстный свет"
	desc = "Выпустите восемь лучей вокруг себя и лучи из своих призм в пяти клетках. Предупреждение длится секунду, вы можете двигаться. Прямой луч наносит 40 ушибов, преломлённый — 46, раздвоенный — 40; трещины добавляют свой бонус. Пересечения бьют один раз. Работает без призм и граней, перезарядка 35 секунд."
	gain_text = "Венец лежал на пустом троне. Кровь на его краях была ещё тёплой."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_GLASS
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_glass/storm

/datum/eldritch_knowledge/spell/glass_storm/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass?.clear_knowledge_effects(src)
	return ..()

/datum/eldritch_knowledge/final_eldritch/glass_final
	parallax_scene = ANTAG_SCENE_HERETIC_GLASS
	name = "Расколоть небосвод"
	desc = "После трёх назначенных душ принесите три человеческих трупа. Обряд раскрывает место станции и длится 30 секунд. Вознесение даёт пять призм, запас граней 8 и восстановление за 4 секунды. Луч допускает пять преломлений и 18 клеток вместо трёх и 12. Вы не нуждаетесь в дыхании, получаете на четверть меньше ушибов и ожогов. Вечный витраж трижды выпускает восемь лучей вокруг вас и свет из сети с интервалом 4 секунды. Каждая волна предупреждает за секунду; можно двигаться. Урон 44, через призму 50, после раздвоения 44; трещины усиливают свет. Разрушение участвующей призмы отменяет витраж. Перезарядка 45 секунд."
	gain_text = "Небо раскололось без звука. Осколки остановились передо мной, ожидая, какую форму я придам пустоте."
	route = PATH_GLASS
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_traits = list(TRAIT_NOBREATH)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_glass/crown)

/datum/eldritch_knowledge/final_eldritch/glass_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/glass_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(glass)
		glass.ascension_active = TRUE
		glass.update_temper()

/datum/eldritch_knowledge/final_eldritch/glass_final/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(glass)
		glass.ascension_active = FALSE
		glass.clear_glass()
		glass.update_temper()
	return ..()

/obj/effect/proc_holder/spell/pointed/heretic_glass
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	range = HERETIC_GLASS_RANGE
	selection_type = "view"
	aim_assist = FALSE
	active_msg = "Укажите цель для стеклянных граней."
	deactive_msg = "Грани возвращаются в ладонь."

/obj/effect/proc_holder/spell/pointed/heretic_glass/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	return ..() && glass?.can_use(user)

/obj/effect/proc_holder/spell/pointed/heretic_glass/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	return glass?.can_use(user) && glass.line_clear(user, target)

/obj/effect/proc_holder/spell/pointed/heretic_glass/release
	name = "Преломлённый луч"
	desc = "Выберите цель или клетку: через 0,6 секунды луч нанесёт 30 ушибов по отмеченной линии. Призмы не требуются; своя призма добавляет 6 ушибов и поворачивает свет. Каждый участок до пяти клеток, всего до трёх преломлений и 12 клеток. Трещины усиливают и прямой выстрел."
	action_icon_state = "glass_release"
	charge_max = 12 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_glass/release/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/turf/destination = get_turf(target)
	return glass?.can_use(user) && destination && destination != get_turf(user) && destination.z == user.z && get_dist(user, destination) <= range && (!isliving(target) || heretic_can_affect(user, target, chargecost = 0))

/obj/effect/proc_holder/spell/pointed/heretic_glass/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!length(targets) || !glass?.release(user, targets[1]))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_glass/shards
	name = "Поставить призму"
	desc = "За грань поставьте призму на свободный пол в пяти клетках. Она поворачивает луч по стрелке и добавляет 6 ушибов. Повторный выбор поворачивает её в сторону вашего взгляда. Максимум три призмы, 45 прочности, срок 2 минуты."
	action_icon_state = "glass_shards"
	charge_max = 4 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_glass/shards/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!glass?.can_use(user))
		return FALSE
	if(istype(target, /obj/structure/heretic_glass_prism))
		var/obj/structure/heretic_glass_prism/prism = target
		return prism.glass_ref?.resolve() == glass && glass.line_clear(user, prism, allow_prisms = TRUE)
	return isturf(target) && glass.combat_resource >= 1 && glass.valid_prism_turf(user, target)

/obj/effect/proc_holder/spell/pointed/heretic_glass/shards/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!length(targets) || !glass?.shards(user, targets[1]))
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_glass/barrier
	name = "Хрупкая преграда"
	desc = "За грань создайте прозрачную преграду на свободном полу в пяти клетках. Она задерживает всех, имеет 45 прочности и исчезает через 12 секунд. Одновременно можно держать две. Свою преграду можно убрать рукой."
	action_icon_state = "glass_barrier"
	charge_max = 8 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_glass/barrier/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	return isturf(target) && glass?.combat_resource >= 1 && glass.valid_barrier_turf(user, target)

/obj/effect/proc_holder/spell/pointed/heretic_glass/barrier/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!length(targets) || !isturf(targets[1]) || !glass?.create_barrier(user, targets[1]))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_glass
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_glass/storm
	name = "Перекрёстный свет"
	desc = "За секунду отметьте восемь лучей вокруг себя и лучи из своих призм. Урон: 40 напрямую, 46 через призму, 40 после раздвоения. Можно двигаться; призмы и грани не требуются. Пересечения не умножают урон."
	action_icon_state = "glass_storm"
	charge_max = 35 SECONDS

/obj/effect/proc_holder/spell/self/heretic_glass/storm/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!glass?.storm(user))
		revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_glass/crown
	name = "Вечный витраж"
	desc = "Три волны света с интервалом четыре секунды: восемь лучей вокруг вас и свет из призм. Каждая предупреждает за секунду. Можно двигаться; урон 44 напрямую, 50 через призму, 44 после раздвоения. Разрушение участвующего узла отменяет весь витраж."
	action_icon_state = "glass_ascend"
	charge_max = 45 SECONDS

/obj/effect/proc_holder/spell/self/heretic_glass/crown/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	return ..() && glass?.can_use(user) && glass.ascension_active

/obj/effect/proc_holder/spell/self/heretic_glass/crown/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic?.get_knowledge(/datum/eldritch_knowledge/base_glass)
	if(!glass?.crown(user))
		revert_cast(user)

#undef HERETIC_GLASS_RANGE
#undef HERETIC_GLASS_BARRIER_LIFETIME
#undef HERETIC_GLASS_PRISM_LIFETIME
#undef HERETIC_GLASS_ATTACK_LIMIT
#undef HERETIC_GLASS_DEED_DAMAGE
#undef HERETIC_GLASS_BEAM_DAMAGE
#undef HERETIC_GLASS_SPLIT_DAMAGE
#undef HERETIC_GLASS_REFRACTION_BONUS
