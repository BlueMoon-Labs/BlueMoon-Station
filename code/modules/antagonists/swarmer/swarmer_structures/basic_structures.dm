/obj/structure/swarmer/trap
	name = "swarmer trap"
	desc = "Ловушка быстрой сборки, которая бьёт током живых существ и глушит сенсоры машин. Довольно хрупкая."
	icon_state = "trap"
	max_integrity = 10
	alpha = 125
	density = FALSE
	swarmers_pass = TRUE
	var/stamina_damage = 40
	var/knockdown_duration = 4 SECONDS

/obj/structure/swarmer/trap/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/swarmer/trap/proc/on_entered(datum/source, mob/living/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(!anchored)
		return

	if(!isliving(arrived) || isswarmer(arrived) || swarmer_actions_blocked(src))
		return

	playsound(loc, 'sound/effects/snap.ogg', 50, TRUE)
	arrived.apply_effects(knockdown = knockdown_duration, stamina = stamina_damage * SWARMER_STAMINA_SCALE, jitter = 10 SECONDS)
	qdel(src)

/obj/structure/swarmer/trap/swarmer_grab_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	. = ..()
	if(!.)
		return

	alpha = anchored ? initial(alpha) : 255

/obj/structure/swarmer/blockade
	name = "swarmer blockade"
	desc = "Баррикада быстрой сборки."
	icon_state = "barricade"
	swarmer_examine = "Свободно пропускает свармеров и их выстрелы."
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	max_integrity = 75
	swarmers_pass = TRUE

/obj/structure/swarmer/resource_storage
	name = "swarmer resource storage"
	desc = "Хранилище ресурсов \"Свармеров\", позволяющее собирать больше материалов с объектов."
	icon_state = "metal_storage"
	swarmer_examine = "Увеличивает количество ресурсов, полученных с ручного собирания."
	max_integrity = 100
	var/static/metal_modifier_adjust = 0.15

/obj/structure/swarmer/resource_storage/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	var/datum/team/swarmer_team/swarmer_team = team
	if(!swarmer_team)
		return INITIALIZE_HINT_QDEL

	swarmer_team.adjust_modifier(metal_modifier_adjust)

/obj/structure/swarmer/resource_storage/Destroy(force)
	var/datum/team/swarmer_team/swarmer_team = team
	if(swarmer_team)
		swarmer_team.adjust_modifier(-metal_modifier_adjust)
	return ..()

/obj/structure/swarmer/swarmer_core_field
	name = "core field"
	desc = "Защищает ядро Свармеров. Видно, что оно ослабевает с каждой прошедшей секундой."
	icon_state = "core_field"
	layer = HIGH_OBJ_LAYER
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	swarmer_examine = "Временно защищает ядро от недоброжелателей. Пропадёт через время."
	swarmers_pass = TRUE

/obj/structure/swarmer/swarmer_core_field/Initialize(mapload, datum/team/swarmer_team/swarm_team, duration, new_dir)
	. = ..()
	if(new_dir)
		dir = new_dir
	if(duration)
		QDEL_IN(src, duration)
	if(iswallturf(loc))
		SET_PLANE(src, FLOOR_PLANE, loc)

/obj/structure/swarmer/swarmer_core_field/Destroy(force)
	if(prob(30))
		do_sparks(5, FALSE, loc)
	return ..()

/obj/structure/swarmer/swarmer_core_field/swarmer_help_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	swarmer.balloon_alert(swarmer, "нельзя взаимодействовать!")

/obj/structure/swarmer/swarmer_core_field/swarmer_disarm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	swarmer.balloon_alert(swarmer, "это нельзя починить!")

/obj/structure/swarmer/swarmer_core_field/swarmer_grab_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	swarmer.balloon_alert(swarmer, "это нельзя открутить!")

/obj/structure/swarmer/swarmer_core_field/swarmer_harm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	swarmer.balloon_alert(swarmer, "это нельзя уничтожить!")

/proc/swarmer_shield_around_turf(turf/target_turf, shield_radius, shield_duration, datum/team/swarmer_team/team)
	// Угловые кадры названы по направлениям DMI, а не по сторонам их соединений.
	var/static/list/corner_sprite_dirs = list(
		"[SOUTHEAST]" = NORTHEAST,
		"[SOUTHWEST]" = SOUTHEAST,
		"[NORTHEAST]" = NORTHWEST,
		"[NORTHWEST]" = SOUTHWEST,
	)
	for(var/turf/edge in range(shield_radius, target_turf))
		if(get_dist(edge, target_turf) != shield_radius || edge.density || isspaceturf(edge))
			continue
		var/x_distance = abs(edge.x - target_turf.x)
		var/y_distance = abs(edge.y - target_turf.y)
		var/sprite_dir = y_distance > x_distance ? EAST : NORTH
		if(x_distance == y_distance)
			sprite_dir = corner_sprite_dirs["[get_dir(edge, target_turf)]"]
		new /obj/structure/swarmer/swarmer_core_field(edge, team, shield_duration, sprite_dir)

/obj/structure/swarmer/power_cell
	name = "vanometric swarmer power cell"
	desc = "Энергетическая ячейка \"Свармеров\", способная извлекать энергию напрямую из квантовых флуктуаций."
	max_integrity = 200
	swarmer_examine = "Обеспечивает питание фабрикатора наноботов. При разрушении взрывается. Лимит на один фабрикатор — пять штук."
	projectiles_pass = FALSE
	var/datum/beam/fabricator_beam

/obj/structure/swarmer/power_cell/Destroy(force)
	QDEL_NULL(fabricator_beam)
	explosion(get_turf(src), devastation_range = 0, heavy_impact_range = 0, light_impact_range = 2, flame_range = 3)
	return ..()

/obj/structure/swarmer/power_cell/proc/link_to_fabricator(obj/structure/swarmer/nanobot_fabricator/fabricator)
	fabricator_beam = Beam(get_step(fabricator, NORTHEAST), icon_state = "sm_arc_supercharged")
	anchored = TRUE

/obj/structure/swarmer/power_cell/swarmer_disarm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!fabricator_beam)
		return ..()

	swarmer.balloon_alert(swarmer, "нельзя, работает!")

/obj/structure/swarmer/power_cell/swarmer_grab_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!fabricator_beam)
		return ..()

	swarmer.balloon_alert(swarmer, "нельзя, работает!")

