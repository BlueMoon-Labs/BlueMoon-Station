GLOBAL_LIST_INIT(swarmer_objects_minimum_distance, list(
	/obj/structure/swarmer/acp_turret = 2,
	/obj/machinery/porta_turret/swarmer/turret = 3,
	/obj/machinery/porta_turret/swarmer/sniper = 5,
	))

#define SWARMER_BLOCKADE_COST 7
#define SWARMER_TRAP_COST 3
#define SWARMER_HUB_COST 15
#define SWARMER_PROCESSER_COST 20
#define SWARMER_ANALYZER_COST 20
#define SWARMER_REPAIR_STATION_COST 10
#define SWARMER_STORAGE_COST 10
#define SWARMER_RAPID_TURRET_COST 25
#define SWARMER_SNIPER_TURRET_COST 35
#define SWARMER_ACP_COST 30
#define SWARMER_NANOBOT_FABRICATOR_COST 250
#define SWARMER_CORE_MOVE_COST 100

/datum/action/cooldown/swarmer
	name = "Свармер что-то"
	desc = "Напишите баг-репорт, если увидели это."
	icon_icon = 'icons/mob/actions/actions_swarmer.dmi'
	var/action_cost = 0

/datum/action/cooldown/swarmer/IsAvailable()
	if(!isswarmer(owner))
		return FALSE
	return ..()

/datum/action/cooldown/swarmer/New(Target)
	. = ..()
	if(action_cost)
		desc = "[desc] Стоимость: [action_cost] ед. металла."

/datum/action/cooldown/swarmer/build
	cooldown_time = 3 SECONDS
	var/build_type = /obj/structure/swarmer
	var/build_time = 0

/datum/action/cooldown/swarmer/build/New(Target)
	. = ..()
	var/minimum_range = GLOB.swarmer_objects_minimum_distance[build_type]
	if(minimum_range)
		desc = "[desc]\n Минимальное расстояние между друг-другом — [minimum_range] тайлов."

/datum/action/cooldown/swarmer/build/Activate(atom/target)
	var/mob/living/simple_animal/hostile/swarmer/swarmer = owner
	if(!istype(swarmer) || !swarmer.team?.swarmer_core)
		return FALSE
	target = swarmer
	. = ..()
	var/turf/spawn_turf = get_turf(swarmer)
	var/list/turfs_to_check = list(spawn_turf)
	if(!turf_build_checks(target, turfs_to_check))
		return

	if(!check_for_structure_in_turfs(target, turfs_to_check))
		return

	if(!custom_build_checks(target, turfs_to_check))
		return

	if(!check_for_distance(spawn_turf))
		target.balloon_alert(target, "слишком близко!")
		var/obj/build_prototype = build_type
		to_chat(target, span_warning("Минимальное расстояние между [build_prototype::name] — [GLOB.swarmer_objects_minimum_distance[build_type]]!"))
		return

	if(!swarmer.team?.adjust_metal(-action_cost))
		target.balloon_alert(target, "недостаточно ресурсов!")
		return

	if(build_time && !do_after(swarmer, build_time, swarmer, extra_checks = CALLBACK(src, PROC_REF(check_for_structure_in_turfs), target, turfs_to_check)))
		target.balloon_alert(target, "сбито!")
		swarmer.team?.adjust_metal(action_cost)
		return

	if(!check_for_distance(spawn_turf))
		target.balloon_alert(target, "слишком близко!")
		var/obj/build_prototype = build_type
		to_chat(target, span_warning("Минимальное расстояние между [build_prototype::name] — [GLOB.swarmer_objects_minimum_distance[build_type]]!"))
		swarmer.team?.adjust_metal(action_cost)
		return

	var/obj/structure = new build_type(spawn_turf, swarmer.team)
	if(swarmer.training_origin)
		var/datum/antag_training_arena/arena = swarmer.training_origin.resolve()
		var/datum/antag_training_session/session = arena?.session_of(swarmer)
		arena?.track_supply(structure, session)
		if(arena)
			arena.placed_structures += WEAKREF(structure)
	target.balloon_alert(target, "успех!")
	return structure

/datum/action/cooldown/swarmer/build/proc/turf_build_checks(mob/living/user, list/turfs_to_check)
	if(!length(turfs_to_check) || !user)
		return FALSE

	. = TRUE
	for(var/turf/target_turf as anything in turfs_to_check)
		if(!target_turf || (!is_station_level(target_turf.z) && !user.training_origin))
			user.balloon_alert(user, "вне станции!")
			return FALSE
		if(user.training_origin)
			var/datum/antag_training_arena/arena = user.training_origin.resolve()
			var/refusal = arena?.construction_error(target_turf)
			if(!arena || refusal)
				to_chat(user, span_warning(refusal || "Полигон недоступен."))
				return FALSE
		if(isspaceturf(target_turf))
			user.balloon_alert(user, "космос!")
			target_turf.balloon_alert(user, "здесь!")
			return FALSE
		if(iswallturf(target_turf))
			user.balloon_alert(user, "стена!")
			target_turf.balloon_alert(user, "здесь!")
			return FALSE

/datum/action/cooldown/swarmer/build/proc/check_for_structure_in_turfs(mob/living/user, list/turfs_to_check)
	if(!length(turfs_to_check) || !user)
		return FALSE

	. = TRUE
	for(var/turf/target_turf as anything in turfs_to_check)
		for(var/atom in target_turf.contents)
			if(is_swarmer_object(atom))
				user.balloon_alert(user, "нельзя строить сверху существующего!")
				return FALSE

/datum/action/cooldown/swarmer/build/proc/check_for_distance(turf/spawn_turf)
	var/required_range = GLOB.swarmer_objects_minimum_distance[build_type]
	if(!required_range)
		return TRUE

	var/mob/living/simple_animal/hostile/swarmer/swarmer = owner
	var/datum/team/swarmer_team/team = swarmer.team
	if(!team)
		return TRUE

	return team.check_objs_of_type_in_range(spawn_turf, required_range, build_type)

/datum/action/cooldown/swarmer/build/proc/custom_build_checks(mob/living/user, list/turfs_to_check)
	return TRUE

/datum/action/cooldown/swarmer/build/barricade
	name = "Создать баррикаду"
	desc = "Создаёт баррикаду, через которую могут проходить \"Свармеры\", и пролетать их лазеры."
	button_icon_state = "swarmer_barricade"
	build_type = /obj/structure/swarmer/blockade
	action_cost = SWARMER_BLOCKADE_COST
	build_time = SWARMER_FAST_BUILD_DELAY

/datum/action/cooldown/swarmer/build/trap
	name = "Создать ловушку"
	desc = "Создаёт ловушку, которая будет оглушать всех, кроме \"Свармеров\"."
	button_icon_state = "swarmer_trap"
	build_type = /obj/structure/swarmer/trap
	action_cost = SWARMER_TRAP_COST
	build_time = SWARMER_FAST_BUILD_DELAY

/datum/action/cooldown/swarmer/build/trap/Grant(mob/granted_to)
	. = ..()
	if(!is_roverswarmer(granted_to))
		return

	build_time = 0

/datum/action/cooldown/swarmer/build/transport_hub
	name = "Создать Хаб"
	desc = "Создаёт Хаб, между которыми смогут перемещаться все \"Свармеры\"."
	button_icon_state = "swarmer_hub"
	build_type = /obj/structure/swarmer/transport_hub
	action_cost = SWARMER_HUB_COST
	build_time = SWARMER_SLOW_BUILD_DELAY

/datum/action/cooldown/swarmer/build/transport_hub/Activate(atom/target)
	var/mob/living/simple_animal/hostile/swarmer/swarmer = owner
	if(!istype(swarmer) || !swarmer.team?.swarmer_core)
		return FALSE
	target = swarmer
	. = ..()
	if(!.)
		return
	var/keyword = tgui_input_text(target, "Пожалуйста, введите название для постройки.", "Ввод названия")
	if(!keyword)
		return
	var/obj/structure/swarmer/transport_hub/hub = .
	hub.listkey = "[keyword] ([hub.listkey])"

/datum/action/cooldown/swarmer/build/processer
	name = "Создать переработчик органики"
	desc = "Обрабатывает неживую материю."
	button_icon_state = "swarmer_processor"
	build_type = /obj/structure/swarmer/organic_processer
	action_cost = SWARMER_PROCESSER_COST
	build_time = SWARMER_NORMAL_BUILD_DELAY

/datum/action/cooldown/swarmer/build/analyzer
	name = "Создать анализатор органики"
	desc = "Обрабатывает живую и металлическую материю."
	button_icon_state = "swarmer_analyzer"
	build_type = /obj/structure/swarmer/organic_analyzer
	action_cost = SWARMER_ANALYZER_COST
	build_time = SWARMER_NORMAL_BUILD_DELAY

/datum/action/cooldown/swarmer/build/repair_station
	name = "Создать станцию починки"
	desc = "Быстрая починка для \"Свармеров\"."
	button_icon_state = "swarmer_repair"
	build_type = /obj/structure/swarmer/repair_station
	action_cost = SWARMER_REPAIR_STATION_COST
	build_time = SWARMER_NORMAL_BUILD_DELAY

/datum/action/cooldown/swarmer/build/storage
	name = "Создать хранилище для ресурсов"
	desc = "Ускоряет ручной сбор материалов."
	button_icon_state = "swarmer_storage"
	build_type = /obj/structure/swarmer/resource_storage
	action_cost = SWARMER_STORAGE_COST
	build_time = SWARMER_FAST_BUILD_DELAY

/datum/action/cooldown/swarmer/build/storage/custom_build_checks(mob/living/user, list/turfs_to_check)
	var/mob/living/simple_animal/hostile/swarmer/swarmer = user
	var/datum/team/swarmer_team/swarmer_team = swarmer.team
	if(swarmer_team.metal_modifier < swarmer_team.get_metal_modifier_limit())
		return TRUE

	var/choice = tgui_alert(user, "Предупреждение! Лимит модификатора сбора ресурсов уже достигнут, постройка нового хранилища ничего не даст, \
		однако послужит защитой, если сломают другое хранилище. Продолжить стройку?", "Постройка хранилища", list("Да", "Нет"))
	if(choice == "Да")
		return TRUE

	return FALSE

/datum/action/cooldown/swarmer/build/rapid_turret
	name = "Создать штурмовую турель"
	desc = "Турель, стреляющая залпами лучей."
	button_icon_state = "swarmer_rapid_turret"
	build_type = /obj/machinery/porta_turret/swarmer/turret
	action_cost = SWARMER_RAPID_TURRET_COST
	build_time = SWARMER_NORMAL_BUILD_DELAY

/datum/action/cooldown/swarmer/build/sniper_turret
	name = "Создать снайперскую турель"
	desc = "Турель, стреляющая сильным, пробивающим лучом."
	button_icon_state = "swarmer_sniper_turret"
	build_type = /obj/machinery/porta_turret/swarmer/sniper
	action_cost = SWARMER_SNIPER_TURRET_COST
	build_time = SWARMER_SLOW_BUILD_DELAY

/datum/action/cooldown/swarmer/build/acp_turret
	name = "Создать установку ACP"
	desc = "Турель, бьющая целей по области, накладывая дебаффы."
	button_icon_state = "swarmer_acp"
	build_type = /obj/structure/swarmer/acp_turret
	action_cost = SWARMER_ACP_COST
	build_time = SWARMER_NORMAL_BUILD_DELAY

/datum/action/cooldown/swarmer/build/nanobot_fabricator
	name = "Создать фабрикатор наноботов"
	desc = "Для постройки требуются ванометрические батареи в видимости нескольких тайлов. Является финальной конструкцией \"Свармеров\"."
	build_type = /obj/structure/swarmer/nanobot_fabricator
	action_cost = SWARMER_NANOBOT_FABRICATOR_COST
	build_time = SWARMER_SLOW_BUILD_DELAY

/datum/action/cooldown/swarmer/move_core
	name = "Переместить ядро"
	desc = "Используйте перед ядром для телепортации его на любой из хабов. Хаб будет уничтожен."
	button_icon_state = "swarmer_core_swap"
	cooldown_time = 1 MINUTES
	action_cost = SWARMER_CORE_MOVE_COST
	var/core_move_delay = 25 SECONDS
	var/forcefield_radius = 2
	var/forcefield_duration = 5 SECONDS

/datum/action/cooldown/swarmer/move_core/Activate(atom/target)
	var/mob/living/simple_animal/hostile/swarmer/swarmer = owner
	if(!istype(swarmer) || !swarmer.team?.swarmer_core)
		return FALSE
	target = swarmer
	. = ..()
	var/datum/team/swarmer_team/swarmer_team = swarmer.team
	var/obj/structure/swarmer/core/core = swarmer_team.swarmer_core
	if(!core || !in_range(core, target))
		owner.balloon_alert(target, "далеко от ядра!")
		return

	var/list/potential_hubs = swarmer_team.get_transport_hub_list()
	if(!length(potential_hubs))
		owner.balloon_alert(owner, "отсутствуют другие хабы!")
		return

	var/input_hub_key = tgui_input_list(owner, "Выберите хаб для телепорта ядра.", "Выбор хаба", potential_hubs)
	var/obj/structure/swarmer/transport_hub/actual_selected_hub = potential_hubs[input_hub_key]
	if(QDELETED(src) || QDELETED(core) || QDELETED(actual_selected_hub) || !actual_selected_hub.enabled || !core.Adjacent(owner))
		return

	if(!swarmer.team?.adjust_metal(-action_cost))
		owner.balloon_alert(owner, "недостаточно ресурсов!")
		return

	if(!do_after(owner, core_move_delay, core) || QDELETED(actual_selected_hub) || !actual_selected_hub.enabled || !get_turf(actual_selected_hub))
		owner.balloon_alert(owner, "нельзя двигаться!")
		swarmer.team?.adjust_metal(action_cost)
		return

	owner.balloon_alert(owner, "успешно телепортировано!")
	do_sparks(4, TRUE, core)
	var/turf/target_turf = get_turf(actual_selected_hub)
	core.forceMove(target_turf)
	qdel(actual_selected_hub)
	swarmer_shield_around_turf(target_turf, forcefield_radius, forcefield_duration, swarmer.team)

/datum/action/cooldown/swarmer/core_location
	name = "Локация ядра"
	desc = "Узнать, где находится ядро."
	button_icon_state = "swarmer_core_location"

/datum/action/cooldown/swarmer/core_location/Activate(atom/target)
	var/mob/living/simple_animal/hostile/swarmer/swarmer = owner
	if(!istype(swarmer) || !swarmer.team?.swarmer_core)
		return FALSE
	target = swarmer
	. = ..()
	var/datum/team/swarmer_team/team = swarmer.team
	if(!team)
		return

	if(!team.swarmer_core)
		return

	var/dir_to_core = get_dir(target, team.swarmer_core)
	var/area/core_area = get_area(team.swarmer_core)
	var/locname = initial(core_area.name)
	target.balloon_alert(target, "[dir2text_ru(dir_to_core)]!")
	to_chat(target, "[span_bold("Местоположение ядра:")] [span_boldnotice("[locname]")] \n\
		[span_bold("Направление от вас:")] [span_boldnotice("[dir2text_ru(dir_to_core)]")]")

#undef SWARMER_BLOCKADE_COST
#undef SWARMER_TRAP_COST
#undef SWARMER_HUB_COST
#undef SWARMER_PROCESSER_COST
#undef SWARMER_ANALYZER_COST
#undef SWARMER_REPAIR_STATION_COST
#undef SWARMER_STORAGE_COST
#undef SWARMER_RAPID_TURRET_COST
#undef SWARMER_SNIPER_TURRET_COST
#undef SWARMER_ACP_COST
#undef SWARMER_NANOBOT_FABRICATOR_COST
#undef SWARMER_CORE_MOVE_COST

/datum/action/innate/swarmer_hide
	name = "Hide"
	desc = "Прижаться к полу, чтобы спрятаться под предметами."
	icon_icon = 'icons/mob/actions/actions_xeno.dmi'
	button_icon_state = "alien_hide"

/datum/action/innate/swarmer_hide/Activate()
	var/mob/living/simple_animal/hostile/swarmer/swarmer = owner
	if(!istype(swarmer) || swarmer.incapacitated())
		return
	swarmer.layer = ABOVE_NORMAL_TURF_LAYER
	swarmer.sliding_under_doors = TRUE
	active = TRUE

/datum/action/innate/swarmer_hide/Deactivate()
	var/mob/living/simple_animal/hostile/swarmer/swarmer = owner
	if(istype(swarmer))
		swarmer.layer = initial(swarmer.layer)
		swarmer.sliding_under_doors = FALSE
	active = FALSE

/datum/action/innate/swarmer_fire_mode
	name = "Режим стрельбы"
	desc = "Выбрать тип выстрела. После выбора стреляйте ЛКМ по цели на расстоянии."
	icon_icon = 'icons/mob/actions/actions_swarmer.dmi'
	button_icon_state = "double"

/datum/action/innate/swarmer_fire_mode/Activate()
	var/mob/living/simple_animal/hostile/swarmer/combat/swarmer = owner
	swarmer?.select_fire_mode()
