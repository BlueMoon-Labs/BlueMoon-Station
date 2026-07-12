/obj/docking_port/mobile/assault_pod
	name = "assault pod"
	shuttle_id = "steel_rain"
	dwidth = 3
	width = 7
	height = 7

/obj/docking_port/mobile/assault_pod/request(obj/docking_port/stationary/S)
	if(!(z in SSmapping.levels_by_trait(ZTRAIT_STATION))) //No launching pods that have already launched
		return ..()

// Глобальная переменная для направления следа (устанавливается при первом запуске)
var/global/pod_attack_direction = 0

/obj/docking_port/mobile/assault_pod/initiate_docking(obj/docking_port/stationary/S1)
    if(!istype(S1, /obj/docking_port/stationary/transit))
        var/turf/end = get_turf(S1)
        if(end)
            // Если направление ещё не задано, выбираем случайное
            if(!pod_attack_direction)
                pod_attack_direction = pick(NORTH, SOUTH, EAST, WEST)
            var/dir = pod_attack_direction

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
                for(var/turf/neighbor in view(3, T))
                    if(neighbor && (neighbor.z in SSmapping.levels_by_trait(ZTRAIT_STATION)) && !isspaceturf(neighbor))
                        turfs_to_destroy |= neighbor

            // Разрушаем собранные турфы и гибаем людей
            for(var/turf/T in turfs_to_destroy)
                // Сначала гибаем всех живых людей на этом турфе
                for(var/mob/living/carbon/human/H in T)
                    if(H.stat != DEAD) // только живые
                        H.gib() // разрывает на органы
                // Затем разрушаем турф
                destroy_turf(T)

    . = ..()
    if(!istype(S1, /obj/docking_port/stationary/transit))
        playsound(get_turf(src.loc), 'sound/effects/explosion1.ogg', 50, 1)

/obj/docking_port/mobile/assault_pod/proc/destroy_turf(turf/T)
    if(isspaceturf(T))
        return
    // Удаляем все объекты на турфе (кроме решёток и латтисов)
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
