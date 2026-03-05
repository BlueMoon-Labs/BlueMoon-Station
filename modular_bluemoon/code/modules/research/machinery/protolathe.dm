/obj/machinery/rnd/production/protolathe/bioaegis
	name = "Experimental Bio-Organical Printer"
	desc = "Experimental printer that can print advanced biological designs. Ruled illegal in several sectors under Nanotrasen banner."
	icon = 'modular_bluemoon/icons/obj/machines/research.dmi'
	icon_state = "protolathe"
	circuit = /obj/item/circuitboard/machine/protolathe/bioaegis
	categories = list(
								"Baseline Designs", //Very simple organs.
								"Advanced Designs", //Somewhat useful when you have resources.
								"Experimental Designs", //High-end stuff for extended with 7+ hours.
								"Xenochimeric Designs", //Xeno
								"Species-specific Designs", //Can be used for species with 'issues'.
								"Dangerous Designs" //High-risk, high-reward. If you die - it is on you. I will make some in the future, since otherwise project will be too big to be even released.
								)
	production_animation = "protolathe_n"
	allowed_buildtypes = BIOAEGIS
	console_link = FALSE
	requires_console = FALSE
	emaggable = TRUE

/obj/item/circuitboard/machine/protolathe/bioaegis //Very experimental piece of tech, with heavy reliance on cutting-edge parts.
	name = "Bio-organical Printer (Machine Board)"
	icon_state = "abductor_mod"
	build_path = /obj/machinery/rnd/production/protolathe/bioaegis

/obj/machinery/rnd/production/protolathe/bioaegis/syndicate
	name = "Syndicate Bio-Organical Printer"
	desc = "Experimental printer that can print advanced biological designs. Ruled illegal in several sectors under Nanotrasen banner. This one was modified by Bioaegis Directive and 'accepted' by Cybersun."
	icon = 'modular_bluemoon/icons/obj/machines/research.dmi'
	icon_state = "protolathe-syn"
	production_animation = "protolathe_n-syn"
	flags_1 = NODECONSTRUCT_1 //Should prevent any attempt to take t6 parts or something else. Same with chem dispensers in all honesty.

/obj/item/circuitboard/machine/protolathe/bioaegis/syndicate //I make it so some tests/checks don't fuck up. You can't get it anyway without debug/spawn
	name = "Syndicate Bio-organical Printer (Machine Board)"
	icon_state = "command"
	build_path = /obj/machinery/rnd/production/protolathe/bioaegis/syndicate
	req_components = list(
		/obj/item/stock_parts/matter_bin/replicantmatter = 2,
		/obj/item/stock_parts/manipulator/zepto = 2,
		/obj/item/reagent_containers/glass/beaker/ultimate = 2)

/obj/machinery/rnd/production/protolathe/bioaegis/syndicate/Initialize(mapload) //It took me soo fucking long since other stuff just runtimed or said 'fuck you' and shat itself.
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/stock_parts/matter_bin/replicantmatter(null)
	component_parts += new /obj/item/stock_parts/matter_bin/replicantmatter(null)
	component_parts += new /obj/item/stock_parts/manipulator/zepto(null)
	component_parts += new /obj/item/stock_parts/manipulator/zepto(null)
	component_parts += new /obj/item/reagent_containers/glass/beaker/ultimate(null)
	component_parts += new /obj/item/reagent_containers/glass/beaker/ultimate(null)
	RefreshParts()
