/obj/machinery/rnd/production/protolathe
	name = "Hacked Protolathe"
	desc = "Принтер с абсолютным доступом к большинству технологий. Запрещён к использованию во многих корпорациях с делением власти между множеством отделов."
	icon_state = "protolathe"
	circuit = /obj/item/circuitboard/machine/protolathe
	categories = list(
								"Power Designs",
								"Medical Designs",
								"Bluespace Designs",
								"Stock Parts",
								"Equipment",
								"Tool Designs",
								"Mining Designs",
								"Electronics",
								"Weapons",
								"Ammo",
								"Firing Pins",
								"Computer Parts",
								"MODsuit Designs",
								"Organic Designs" //BLUEMOON ADD: New category for fleshcrafting and some heinous shit to ever exist.
								)
	production_animation = "protolathe_n"
	allowed_buildtypes = PROTOLATHE

/obj/machinery/rnd/production/protolathe/disconnect_console()
	linked_console.linked_lathe = null
	..()
