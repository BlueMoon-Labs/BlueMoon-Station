/obj/item/choice_beacon/vehicle
	name = "Vehicle Beacon"
	desc = "Благодаря этому маячку вы сможете вызвать транспорт"
	var/list/vehicle_list = list()
	var/group_path = /obj/item/choice_beacon/vehicle // Маяки этого типа будут содержать все vehicle_list своих подтипов

/obj/item/choice_beacon/vehicle/Initialize(mapload)
	// Понятия не имею, как написать это по другому. Ни через оператор : ни через initial нельзя получить переменную /list
	var/static/list/vehicle_list_cache
	if(!vehicle_list_cache)
		vehicle_list_cache = list()
		var/list/created_beacons = list()
		for(var/path in typesof(/obj/item/choice_beacon/vehicle))
			var/obj/item/choice_beacon/vehicle/beacon = new path(null)
			created_beacons += beacon

			vehicle_list_cache[beacon.type] = LAZYCOPY(beacon.vehicle_list)
		QDEL_LIST(created_beacons)

	if(type == group_path)
		for(var/path in typesof(type))
			merge_assoc_list(vehicle_list, vehicle_list_cache[path])
	return ..()

/obj/item/choice_beacon/vehicle/generate_display_names()
	return vehicle_list

/obj/item/choice_beacon/vehicle/spawn_option(atom/choice, mob/living/M)
	. = ..()
	if(ispath(choice, /obj/vehicle/sealed/mecha) || istype(choice, /obj/vehicle/sealed/mecha))
		var/obj/effect/pod_landingzone/effect = .
		effect.say("Stand by for TitanFall!")

/obj/item/choice_beacon/vehicle/clown_car
	name = "Clown Car Beacon"
	vehicle_list = list(
		"Clown car" = /obj/vehicle/sealed/car/clowncar
	)

//////////////////////// МЕХИ ////////////////////////
/obj/item/choice_beacon/vehicle/pact_mech
	name = "Mech Beacon"
	desc = "Благодаря этому маячку вы сможете вызвать один из мехов с Фрегатов Туманности Синие Луны. За ПАКТ!"
	group_path = /obj/item/choice_beacon/vehicle/pact_mech

/obj/item/choice_beacon/vehicle/pact_mech/combat
	name = "Combat Mech Beacon"
	vehicle_list = list(
		"Main Battle Mech Durand Mk1A1" = /obj/vehicle/sealed/mecha/combat/durand/loaded,
		"Main Battle Mech mk. I" = /obj/vehicle/sealed/mecha/combat/gygax/loaded
	)

/obj/item/choice_beacon/vehicle/pact_mech/medical
	name = "Medical Pact Mech Beacon"
	vehicle_list = list(
		"Vey-Med Odysseus" = /obj/vehicle/sealed/mecha/medical/odysseus/loaded,
		"Vey-Med Gygax" = /obj/vehicle/sealed/mecha/medical/medigax/loaded
	)

/obj/item/choice_beacon/vehicle/pact_mech/cargo
	name = "Cargo Pact Mech Beacon"
	vehicle_list = list(
		"Autonomous Power Loader Unit MK-I" = /obj/vehicle/sealed/mecha/working/ripley/loaded,
		"Autonomous Power Loader Unit MK-II" = /obj/vehicle/sealed/mecha/working/ripley/mkii/loaded
	)

/obj/item/choice_beacon/vehicle/pact_mech/engineer
	name = "Engineer Pact Mech Beacon"
	vehicle_list = list(
		"Autonomous Power Loader Unit MK-II-F" = /obj/vehicle/sealed/mecha/working/ripley/firefighter/loaded
	)

/obj/item/choice_beacon/vehicle/misc_mech
	name = "Mech Beacon"
	desc = "To summon your own steel titan."
	group_path = /obj/item/choice_beacon/vehicle/misc_mech

/obj/item/choice_beacon/vehicle/misc_mech/ert
	name = "ERT Mech Beacon"
	desc = "To summon your own steel titan."
	vehicle_list = list(
		"Marauder" = /obj/vehicle/sealed/mecha/combat/marauder/loaded,
		"Seraph" = /obj/vehicle/sealed/mecha/combat/marauder/seraph
	)

/obj/item/choice_beacon/vehicle/misc_mech/nri
	name = "NRI Mech Beacon"
	desc = "To summon your own steel titan. For the Emperor!"
	vehicle_list = list(
		"TU-802 Solntsepyok" = /obj/vehicle/sealed/mecha/combat/durand/tu802,
		"Savannah-Ivanov" = /obj/vehicle/sealed/mecha/combat/savannah_ivanov/loaded
	)

/obj/item/choice_beacon/vehicle/misc_mech/sol
	name = "SolFed Mech Beacon"
	desc = "Feel the power of the tesla. Glory to the Humanity!"
	vehicle_list = list(
		"TU-802 Solntsepyok" = /obj/vehicle/sealed/mecha/combat/durand/tu802,
		"Savannah-Ivanov" = /obj/vehicle/sealed/mecha/combat/savannah_ivanov/loaded
	)
