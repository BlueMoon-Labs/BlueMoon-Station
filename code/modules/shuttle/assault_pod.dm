// Глобальная переменная для фиксации направления следа (устанавливается при первом запуске)
GLOBAL_VAR_INIT(pod_attack_direction, 0)

/obj/docking_port/mobile/assault_pod
	name = "assault pod"
	shuttle_id = "steel_rain"
	dwidth = 3
	width = 7
	height = 7

/obj/docking_port/mobile/assault_pod/request(obj/docking_port/stationary/S)
	if(!(z in SSmapping.levels_by_trait(ZTRAIT_STATION))) // Не даём запускать уже запущенный под
		return ..()

/obj/docking_port/mobile/assault_pod/initiate_docking(obj/docking_port/stationary/S1)
	. = ..()  // Сначала выполняем стыковку (перемещение)

	// Логика разрушения — только после успешной стыковки
	if(!istype(S1, /obj/docking_port/stationary/transit))
		var/turf/end = get_turf(S1)
		if(end)
			// Если направление ещё не задано, выбираем случайное
			if(!GLOB.pod_attack_direction)
				GLOB.pod_attack_direction = pick(NORTH, SOUTH, EAST, WEST)
			var/dir = GLOB.pod_attack_direction

			// Строим линию из 5 турфов, начиная с цели и уходя в этом направлении
			var/turf/current = end
			var/list/line_turfs = list(current)
			for(var/i in 1 to 4) // всего 5 турфов (включая цель)
				var/turf/next = get_step(current, dir)
				if(!next) break
				if(!(next.z in SSmapping.levels_by_trait(ZTRAIT_STATION))) break
				line_turfs += next
				current = next

			// Собираем все турфы в радиусе 3 вокруг каждого турфа линии (ширина = 7)
			var/list/turfs_to_destroy = list()
			for(var/turf/T in line_turfs)
				for(var/turf/neighbor in range(3, T))  // range — без учёта видимости
					if(neighbor && (neighbor.z in SSmapping.levels_by_trait(ZTRAIT_STATION)) && !isspaceturf(neighbor))
						turfs_to_destroy |= neighbor

			// Исключаем турфы, занятые самим шаттлом (чтобы не ломать под)
			var/list/shuttle_turfs = return_turfs()  // <-- ИСПРАВЛЕНО
			turfs_to_destroy -= shuttle_turfs

			// Разрушаем собранные турфы и гибаем всех живых мобов
			for(var/turf/T in turfs_to_destroy)
				// Гибаем всех живых существ (людей, обезьян, боргов, животных)
				for(var/mob/living/L in T)
					if(L.stat != DEAD)
						L.gib()
				// Разрушаем турф
				destroy_turf(T)

		playsound(get_turf(src.loc), 'sound/effects/wall_crash1.ogg', 50, 1)

/obj/docking_port/mobile/assault_pod/proc/destroy_turf(turf/T)
	if(isspaceturf(T))
		return
	// Удаляем все объекты на турфе, кроме решёток и латтисов
	for(var/atom/A in T)
		if(istype(A, /obj/structure/grille) || istype(A, /obj/structure/lattice))
			continue
		qdel(A)
	T.ChangeTurf(/turf/open/space)
	new /obj/structure/lattice(T)

/obj/item/assault_pod
	name = "Assault Pod Targeting Device"
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-red"
	item_state = "radio"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	desc = "Used to select a landing zone for assault pods."
	var/shuttle_id = "steel_rain"
	var/dwidth = 3
	var/dheight = 0
	var/width = 7
	var/height = 7
	var/lz_dir = 1

/obj/item/assault_pod/attack_self(mob/living/user)
	var/target_area
	target_area = input("Area to land", "Select a Landing Zone", target_area) as null|anything in GLOB.teleportlocs
	if(!target_area)
		return
	var/area/picked_area = GLOB.teleportlocs[target_area]
	if(!src || QDELETED(src))
		return

	var/turf/T = safepick(get_area_turfs(picked_area))
	if(!T)
		return
	var/obj/docking_port/stationary/landing_zone = new /obj/docking_port/stationary(T)
	landing_zone.shuttle_id = "assault_pod([REF(src)])"
	landing_zone.name = "Landing Zone"
	landing_zone.dwidth = dwidth
	landing_zone.dheight = dheight
	landing_zone.width = width
	landing_zone.height = height
	landing_zone.setDir(lz_dir)

	for(var/obj/machinery/computer/shuttle/S in GLOB.machines)
		if(S.shuttleId == shuttle_id)
			S.possible_destinations = "[landing_zone.shuttle_id]"

	to_chat(user, "Landing zone set.")
	qdel(src)
