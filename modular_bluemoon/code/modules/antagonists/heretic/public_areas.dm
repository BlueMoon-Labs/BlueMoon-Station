/// Общие отсеки станции, куда дойдёт любой из экипажа: коридоры, уборные, залы отдыха, бар, столовая, кофейня, библиотека, сцена, парк и сад; не каюты, не отделы и не шаттлы.
/proc/heretic_station_public_area(area/place)
	var/static/list/public_types = typecacheof(list(
		/area/hallway,
		/area/commons,
		/area/service/bar,
		/area/service/cafeteria,
		/area/service/library,
		/area/service/chapel/main,
		/area/service/barbershop,
		/area/service/coffeehouse,
		/area/service/kitchen/diner,
		/area/service/theater,
		/area/service/park,
		/area/service/sauna,
		/area/service/hydroponics/garden,
		/area/service/hydroponics/lobby,
	))
	var/static/list/private_types = typecacheof(list(
		/area/shuttle,
		/area/commons/dorms,
		/area/commons/vacant_room,
		/area/service/bar/backroom,
		/area/service/library/private,
		/area/service/library/abandoned,
		/area/service/chapel/office,
		/area/service/theater/abandoned,
		/area/service/theater/clown,
		/area/service/theater/mime,
		/area/service/hydroponics/garden/abandoned,
	))
	if(!istype(place) || place.outdoors || is_type_in_typecache(place, private_types))
		return FALSE
	return is_type_in_typecache(place, public_types) || place.nightshift_public_area == NIGHTSHIFT_AREA_PUBLIC || place.nightshift_public_area == NIGHTSHIFT_AREA_RECREATION
