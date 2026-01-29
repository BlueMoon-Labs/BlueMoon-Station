/obj/machinery/rnd/production/techfab
	name = "Hacked Fabricator"
	desc = "Принтер с абсолютным доступом к большинству технологий. Запрещён к использованию во многих корпорациях с делением власти между множеством отделов."
	icon_state = "protolathe"
	circuit = /obj/item/circuitboard/machine/techfab
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
								"AI Modules",
								"Computer Boards",
								"Teleportation Machinery",
								"Medical Machinery",
								"Engineering Machinery",
								"Exosuit Modules",
								"Hydroponics Machinery",
								"Subspace Telecomms",
								"Research Machinery",
								"Misc. Machinery",
								"Organic Designs", //BLUEMOON ADD: New category for fleshcrafting.
								"Computer Parts",
								"MODsuit Designs",
								"Shuttle Machinery",
								)
	console_link = FALSE
	production_animation = "protolathe_n"
	requires_console = FALSE
	allowed_buildtypes = PROTOLATHE | IMPRINTER

/obj/machinery/rnd/production/techfab/Initialize(mapload)
	// Да, это костыль, т.к. этот тип используется как реальный объект. Но я не хочу править все пути и платы
	if(src.type == /obj/machinery/rnd/production/techfab)
		obj_flags |= EMAGGED
	. = ..()
