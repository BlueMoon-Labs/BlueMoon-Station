/obj/structure/fulton_beacon
	name = "Vanguard fulton beacon"
	desc = "Приёмник фултон-системы авангарда. Сюда доставляются тела участников экспедиции, погибших на миссии."
	icon = 'icons/obj/fulton.dmi'
	icon_state = "extraction_point"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/fulton_beacon/Initialize(mapload)
	. = ..()
	GLOB.expedition_body_beacons += src

/obj/structure/fulton_beacon/Destroy()
	GLOB.expedition_body_beacons -= src
	return ..()

/// Тайл, куда доставляется тело: свободный пол рядом с маяком. Если пола рядом нет - сам маяк.
/obj/structure/fulton_beacon/proc/get_delivery_turf()
	var/list/floors = list()
	for(var/turf/open/floor in orange(1, src))
		floors += floor
	if(floors.len)
		return pick(floors)
	return get_turf(src)
