/obj/effect/landmark/start/prisoner
	jobspawn_override = TRUE
	delete_after_roundstart = FALSE

//------ Station Room Spawns (как в инженерке) ------
// Универсальный landmark для спавна локаций. Наследуй и задай template_names.
// Либо используй config_key для настройки через config (как box_random_engine).
// Размести landmark на карте в нужном месте - при старте раунда загрузится случайный шаблон.

/obj/effect/landmark/stationroom/bluemoon
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "x"

/// Спавн с настройкой через config. Добавь DEPARTMENT_SPAWN_LOCATIONS в config/bluemoon.
/obj/effect/landmark/stationroom/bluemoon/configurable
	template_names = list("Maint 2storage" = 3, "Maint boxbedroom" = 2, "Maint medicloset" = 2) // fallback если config пуст

/obj/effect/landmark/stationroom/bluemoon/configurable/Initialize(mapload)
	. = ..()
	var/list/config_templates = CONFIG_GET(keyed_list/department_spawn_locations)
	if(config_templates && length(config_templates))
		template_names = config_templates.Copy()

/// Аванпост 1 — малый объект (руины из папки avpost/1/). unique = FALSE — может загружаться несколько раз.
/obj/effect/landmark/stationroom/bluemoon/avpost1
	template_names = list("Аванпост 1" = 1)

/// Аванпост 2 — средний объект (руины из папки avpost/2/). unique = FALSE — может загружаться несколько раз.
/obj/effect/landmark/stationroom/bluemoon/avpost2
	template_names = list("Аванпост 2" = 1)
