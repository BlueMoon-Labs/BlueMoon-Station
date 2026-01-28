/obj/item/choice_beacon/pact_mecha
	name = "Combat Mech Beacon"
	desc = "Благодаря этому маячку вы сможете вызвать один из мехов с Фрегатов Туманности Синие Луны. За ПАКТ!"
	var/pact_mecha_list = list("Main Battle Mech Durand Mk1A1" = /obj/vehicle/sealed/mecha/combat/durand/loaded,
					"Main Battle Mech mk. I" = /obj/vehicle/sealed/mecha/combat/gygax/loaded)

/obj/item/choice_beacon/pact_mecha/generate_display_names()
	if(!pact_mecha_list)
		pact_mecha_list = list()
		var/list/templist = typesof(/obj/item/storage/box/hero) //we have to convert type = name to name = type, how lovely!
		for(var/V in templist)
			var/atom/A = V
			pact_mecha_list[initial(A.name)] = A
	return pact_mecha_list

/obj/item/choice_beacon/pact_mecha/spawn_option(atom/choice, mob/living/M)
	. = ..()
	var/obj/effect/pod_landingzone/effect = .
	effect.say("Stand by for TitanFall!")

/obj/item/choice_beacon/pact_mecha/medical
	name = "Medical Pact Mech Beacon"
	pact_mecha_list = list("Vey-Med Odysseus" = /obj/vehicle/sealed/mecha/medical/odysseus/loaded,
					"Vey-Med Gygax" = /obj/vehicle/sealed/mecha/medical/medigax/loaded)

/obj/item/choice_beacon/pact_mecha/cargo
	name = "Cargo Pact Mech Beacon"
	pact_mecha_list = list("Autonomous Power Loader Unit MK-I" = /obj/vehicle/sealed/mecha/working/ripley/loaded,
					"Autonomous Power Loader Unit MK-II" = /obj/vehicle/sealed/mecha/working/ripley/mkii/loaded)

/obj/item/choice_beacon/pact_mecha/engineer
	name = "Engineer Pact Mech Beacon"
	pact_mecha_list = list("Autonomous Power Loader Unit MK-II-F" = /obj/vehicle/sealed/mecha/working/ripley/firefighter/loaded)
