/obj/item/choice_beacon/vehicle
	name = "Vehicle Beacon"
	desc = "Благодаря этому маячку вы сможете вызвать транспорт"
	var/vehicle_list = list()

/obj/item/choice_beacon/vehicle/generate_display_names()
	return vehicle_list

/obj/item/choice_beacon/vehicle/spawn_option(atom/choice, mob/living/M)
	. = ..()
	if(ispath(choice, /obj/vehicle/sealed/mecha) || istype(choice, /obj/vehicle/sealed/mecha))
		var/obj/effect/pod_landingzone/effect = .
		effect.say("Stand by for TitanFall!")

/obj/item/choice_beacon/vehicle/clown_car
	name = "Clown Car Beacon"
	vehicle_list = list("Clown car" = /obj/vehicle/sealed/car/clowncar)

//////////////////////// МЕХИ ////////////////////////
/obj/item/choice_beacon/vehicle/pact_mech
	name = "Mech Beacon"
	desc = "Благодаря этому маячку вы сможете вызвать один из мехов с Фрегатов Туманности Синие Луны. За ПАКТ!"

/obj/item/choice_beacon/vehicle/pact_mech/combat
	name = "Combat Mech Beacon"
	vehicle_list = list("Main Battle Mech Durand Mk1A1" = /obj/vehicle/sealed/mecha/combat/durand/loaded,
					"Main Battle Mech mk. I" = /obj/vehicle/sealed/mecha/combat/gygax/loaded)

/obj/item/choice_beacon/vehicle/pact_mech/medical
	name = "Medical Pact Mech Beacon"
	vehicle_list = list("Vey-Med Odysseus" = /obj/vehicle/sealed/mecha/medical/odysseus/loaded,
					"Vey-Med Gygax" = /obj/vehicle/sealed/mecha/medical/medigax/loaded)

/obj/item/choice_beacon/vehicle/pact_mech/cargo
	name = "Cargo Pact Mech Beacon"
	vehicle_list = list("Autonomous Power Loader Unit MK-I" = /obj/vehicle/sealed/mecha/working/ripley/loaded,
					"Autonomous Power Loader Unit MK-II" = /obj/vehicle/sealed/mecha/working/ripley/mkii/loaded)

/obj/item/choice_beacon/vehicle/pact_mech/engineer
	name = "Engineer Pact Mech Beacon"
	vehicle_list = list("Autonomous Power Loader Unit MK-II-F" = /obj/vehicle/sealed/mecha/working/ripley/firefighter/loaded)
