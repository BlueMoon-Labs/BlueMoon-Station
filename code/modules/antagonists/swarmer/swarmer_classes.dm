#define GENERALIST_SWAP_COST 20
#define ROVER_SWAP_COST 18
#define COMBAT_SWAP_COST 30
#define BUILDER_SWAP_COST 20

/mob/living/simple_animal/hostile/swarmer/basic
	name = "Drone Swarmer"
	desc = "Хрупкий, маленький, слегка быстрый \"Свармер\"."
	icon_state = "swarmer_starter"
	icon_living = "swarmer_starter"
	melee_damage_lower = 20 * SWARMER_STAMINA_SCALE
	melee_damage_upper = 20 * SWARMER_STAMINA_SCALE
	health = 30
	maxHealth = 30
	dismantle_speed = SLOW_SWARMER_DISMANTLE_DELAY
	speed = 0.25
	pass_flags = PASSTABLE | PASSMOB
	swarmer_class_info = "Данный класс не отличается ничем особенным, и существует для того, чтобы вы его сменили в ядре на новый.\n\
		Для смены класса, нажмите по ядру в 1 интенте \"Помощь\".\n\
		Достаточно маленький для того, чтобы проползать под столами и шлюзами."

/mob/living/simple_animal/hostile/swarmer/basic/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)

/mob/living/simple_animal/hostile/swarmer/generalist
	name = "Generalist Swarmer"
	desc = "Базовая боевая единица \"Свармеров\". Оснащён пушкой и базовыми строительными устройствами."
	icon_state = "swarmer_general"
	icon_living = "swarmer_general"
	melee_damage_lower = 25 * SWARMER_STAMINA_SCALE
	melee_damage_upper = 25 * SWARMER_STAMINA_SCALE
	health = 80
	maxHealth = 80
	speed = 0
	ranged = TRUE
	projectiletype = /obj/item/projectile/beam/disabler/swarmer/generalist
	ranged_cooldown_time = 0.8 SECONDS
	projectilesound = 'sound/weapons/taser2.ogg'
	swap_resource_cost = GENERALIST_SWAP_COST
	can_swap_to = TRUE
	swarmer_class_info = "Данный класс является базовой боевой единицей, оснащённой пушкой, а также способностью строить мелкие туррели, баррикады и ловушки.\n\
		Скорость равна человеческой.\n\
		Перемещает существ и объекты без замедления."

/mob/living/simple_animal/hostile/swarmer/rover
	name = "Rover Swarmer"
	desc = "Маленький \"Свармер\" на колёсиках вместо ног. Оснащён тараном, способным опрокидывать с ног целей."
	icon_state = "swarmer_rover"
	icon_living = "swarmer_rover"
	melee_damage_lower = 30 * SWARMER_STAMINA_SCALE
	melee_damage_upper = 30 * SWARMER_STAMINA_SCALE
	health = 50
	maxHealth = 50
	speed = -0.25
	swap_resource_cost = ROVER_SWAP_COST
	can_swap_to = TRUE
	pass_flags = PASSTABLE | PASSMOB
	swarmer_class_info = "Данный класс является разведовательной единицей, оснащённой колёсами вместо ног, а также мощным тараном, способным сбивать целей с ног.\n\
		Способен строить ловушки и \"хабы\", между которыми смогут перемещаться все \"Свармеры\".\n\
		Мгновенно строит ловушки.\n\
		Достаточно маленький для того, чтобы проползать под столами и шлюзами."
	knockdown_time = 3 SECONDS

/mob/living/simple_animal/hostile/swarmer/rover/AttackingTarget()
	. = ..()
	if(!. || !isliving(target))
		return

	var/mob/living/living_target = target
	living_target.Knockdown(knockdown_time)

#define COMBAT_SWARMER_STRUCTURE_RANGE 7

/mob/living/simple_animal/hostile/swarmer/combat
	name = "Combat Swarmer"
	desc = "Защитная единица \"Свармеров\". Оснащён пушкой и базовыми строительными устройствами."
	icon_state = "swarmer_combat"
	icon_living = "swarmer_combat"
	melee_damage_lower = 30 * SWARMER_STAMINA_SCALE
	melee_damage_upper = 30 * SWARMER_STAMINA_SCALE
	health = 120
	maxHealth = 120
	dismantle_speed = SLOW_SWARMER_DISMANTLE_DELAY
	speed = 0.25
	ranged = TRUE
	projectiletype = /obj/item/projectile/beam/disabler/swarmer/double
	projectilesound = 'sound/weapons/taser2.ogg'
	ranged_cooldown_time = 1.2 SECONDS
	rapid = 2
	rapid_fire_delay = 0.2 SECONDS
	swap_resource_cost = COMBAT_SWAP_COST
	can_swap_to = TRUE
	swarmer_class_info = "Данный класс является защитной единицей, оснащённой более сильной защитой и пушками.\n\
		Оснащён следующими типами выстрелов: \n\
		1. Двойной выстрел — как обычный, но выпускает сразу два снаряда; \n\
		2. Сильный выстрел — наносит больший урон по стамине и сбивает с ног; \n\
		3. Саботажный выстрел — разряжает баллистическое оружие, расходует заряд энергетического и переключает его в режим дизейблера, если такой режим есть.\n\
		Выберите тип выстрела кнопкой «Режим стрельбы» или вторым действием по себе. Стреляйте ЛКМ по цели на расстоянии.\n\
		Способен строить баррикады.\n\
		Чинится автоматически у ядра, становится быстрее, находясь рядом с любой из структур Свармеров."
	var/increased_speed = -0.15
	var/datum/weakref/cached_swarmer_obj

/mob/living/simple_animal/hostile/swarmer/combat/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	ADD_TRAIT(src, TRAIT_HEALS_FROM_SWARMER_CORES, INNATE_TRAIT)

/mob/living/simple_animal/hostile/swarmer/combat/Destroy()
	cached_swarmer_obj = null
	return ..()

/mob/living/simple_animal/hostile/swarmer/combat/Life(seconds, times_fired)
	. = ..()
	if(!.)
		return

	var/obj/nearby = cached_swarmer_obj?.resolve()
	if(nearby && nearby.z == z && get_dist(src, nearby) <= COMBAT_SWARMER_STRUCTURE_RANGE)
		return
	cached_swarmer_obj = null
	for(var/structure_type in team?.swarmer_objects)
		for(var/structure_uid in team.swarmer_objects[structure_type])
			var/obj/structure = locateUID(structure_uid)
			if(structure?.z == z && get_dist(src, structure) <= COMBAT_SWARMER_STRUCTURE_RANGE)
				cached_swarmer_obj = WEAKREF(structure)
				if(speed != increased_speed)
					set_varspeed(increased_speed)
				return
	if(speed != initial(speed))
		set_varspeed(initial(speed))

/mob/living/simple_animal/hostile/swarmer/combat/AltUnarmedAttack(atom/A, proximity_flag)
	if(A != src)
		return ..()
	select_fire_mode()
	return TRUE

/mob/living/simple_animal/hostile/swarmer/combat/proc/select_fire_mode()
	if(!client || incapacitated() || rapid_fire_shots_left)
		return
	var/mode = tgui_input_list(src, "Выберите режим стрельбы.", "Режим стрельбы", list("Двойной выстрел", "Сильный выстрел", "Саботажный выстрел"))
	if(!mode || QDELETED(src) || !client || incapacitated() || rapid_fire_shots_left)
		return
	switch(mode)
		if("Двойной выстрел")
			projectiletype = /obj/item/projectile/beam/disabler/swarmer/double
			rapid = 2
			ranged_cooldown_time = 1.2 SECONDS
		if("Сильный выстрел")
			projectiletype = /obj/item/projectile/beam/disabler/swarmer/empowered
			rapid = 0
			ranged_cooldown_time = 1.5 SECONDS
		if("Саботажный выстрел")
			projectiletype = /obj/item/projectile/beam/disabler/swarmer/sabotage
			rapid = 0
			ranged_cooldown_time = 1.5 SECONDS
	balloon_alert(src, mode)

#undef COMBAT_SWARMER_STRUCTURE_RANGE

/mob/living/simple_animal/hostile/swarmer/builder
	name = "Builder Swarmer"
	desc = "Строительная единица \"Свармеров\". Оснащён мощными нанитами, способными как строить, так и чинить, за крайне малое время."
	icon_state = "swarmer_builder"
	icon_living = "swarmer_builder"
	melee_damage_lower = 40 * SWARMER_STAMINA_SCALE
	melee_damage_upper = 40 * SWARMER_STAMINA_SCALE
	health = 120
	maxHealth = 120
	dismantle_speed = FAST_SWARMER_DISMANTLE_DELAY
	swap_resource_cost = BUILDER_SWAP_COST
	can_swap_to = TRUE
	mob_size = MOB_SIZE_HUMAN
	swarmer_class_info = "Данный класс является строительной единицей, способной строить множество различных конструкций.\n\
		Является самым важным классом среди \"Свармеров\", без которого выполнение цели является невозможным.\n\
		Чинит в два раза быстрее и больше остальных, а также способен перемещать структуры, включая ядро.\n\
		Медленно чинится сам по себе, и обладает наибольшим уроном вблизи.\n\
		Не замедляется от переноски существ и объектов."
	var/auto_repair_amount = 1

/mob/living/simple_animal/hostile/swarmer/builder/Life(seconds, times_fired)
	. = ..()
	adjustHealth(-auto_repair_amount)

/mob/living/simple_animal/hostile/swarmer/mega
	name = "Mega Swarmer"
	desc = "Лучшая боевая единица \"Свармеров\", оснащённая рефлекторными пластинами, миниганом, и встроенной турелью ACP."
	icon_state = "swarmer_mega"
	icon_living = "swarmer_mega"
	melee_damage_lower = 60 * SWARMER_STAMINA_SCALE
	melee_damage_upper = 60 * SWARMER_STAMINA_SCALE
	ranged = TRUE
	projectiletype = /obj/item/projectile/beam/disabler/swarmer/minigun
	ranged_cooldown_time = 1.5 SECONDS
	projectilesound = 'sound/weapons/taser2.ogg'
	rapid = 6
	rapid_fire_delay = 1
	health = 500
	maxHealth = 500
	dismantle_speed = FAST_SWARMER_DISMANTLE_DELAY
	swarmer_class_info = "Вы — финальная боевая единица \"Свармеров\", оснащённая миниганом, встроенной ACP турелью, а также защитными пластинами.\n\
		Ваша цель — окончательно захватить станцию под ваш контроль."
	knockdown_time = 5 SECONDS
	var/reflection_chance = 50
	var/obj/structure/swarmer/acp_turret/acp
	var/acp_range = 5

/mob/living/simple_animal/hostile/swarmer/mega/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	acp = new(src, team)
	configure_acp()

/mob/living/simple_animal/hostile/swarmer/mega/Destroy(force)
	QDEL_NULL(acp)
	return ..()

/mob/living/simple_animal/hostile/swarmer/mega/AttackingTarget()
	. = ..()
	if(!. || !isliving(target))
		return

	var/mob/living/living_target = target
	living_target.Knockdown(knockdown_time)

/mob/living/simple_animal/hostile/swarmer/mega/bullet_act(obj/item/projectile/P, def_zone, piercing_hit = FALSE)
	if(!is_energy_reflectable_projectile(P) || !prob(reflection_chance))
		return ..()
	if(P.damage_type == BRUTE || P.damage_type == BURN)
		adjustHealth(P.damage * 0.5)
	visible_message(span_danger("[src] отражает [P.name]!"))
	handle_projectile_attack_redirection(P, REDIRECT_METHOD_REFLECT)
	return BULLET_ACT_FORCE_PIERCE

/mob/living/simple_animal/hostile/swarmer/mega/proc/configure_acp()
	QDEL_NULL(acp.proximity_monitor)
	acp.proximity_monitor = new(src, acp_range)
	acp.range = acp_range

/mob/living/simple_animal/hostile/swarmer/mega/HasProximity(atom/movable/AM)
	acp?.handle_interloper(AM)

/mob/living/simple_animal/hostile/swarmer/mega/damage_object(atom/movable/target)
	var/obj/effect/temp_visual/swarmer/disintegration/disintegrate_effect = new(get_turf(target))
	disintegrate_effect.adjust_size(target)
	target.ex_act(EXPLODE_HEAVY)
	do_attack_animation(target)

/mob/living/simple_animal/hostile/swarmer/mega/add_datum_if_not_exist()
	if(mind && team && !mind.has_antag_datum(/datum/antagonist/swarmer))
		mind.add_antag_datum(/datum/antagonist/swarmer/mega, team)

/mob/living/simple_animal/hostile/swarmer/mega/Life(seconds, times_fired)
	. = ..()
	if(!.)
		return

	if(times_fired % 10 == 0)
		playsound(src, 'sound/swarmer/megaswarmer_ambient.ogg', 100, TRUE)

/mob/living/simple_animal/hostile/swarmer/get_eye_protection()
	return 2

#undef GENERALIST_SWAP_COST
#undef ROVER_SWAP_COST
#undef COMBAT_SWAP_COST
#undef BUILDER_SWAP_COST
