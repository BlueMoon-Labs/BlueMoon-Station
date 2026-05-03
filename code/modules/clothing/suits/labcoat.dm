/obj/item/clothing/suit/toggle/labcoat
	name = "labcoat"
	desc = "Халат, защищающий от небольших химических утечек и пролитых веществ."
	icon_state = "labcoat"
	item_state = "labcoat"
	blood_overlay_type = "coat"
	body_parts_covered = CHEST|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	allowed = list(
		/obj/item/analyzer,
		/obj/item/stack/medical,
		/obj/item/dnainjector,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/hypospray,
		/obj/item/hypospray/mkii,
		/obj/item/healthanalyzer,
		/obj/item/flashlight/pen,
		/obj/item/reagent_containers/glass/bottle,
		/obj/item/reagent_containers/glass/beaker,
		/obj/item/reagent_containers/pill,
		/obj/item/storage/pill_bottle,
		/obj/item/paper,
		/obj/item/melee/classic_baton/telescopic,
		/obj/item/soap,
		/obj/item/sensor_device,
		/obj/item/tank/internals/emergency_oxygen,
		/obj/item/tank/internals/plasmaman
		)

	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 50, RAD = 0, FIRE = 50, ACID = 50)
	togglename = "buttons"
	species_exception = list(/datum/species/golem)

/obj/item/clothing/suit/toggle/labcoat/cmo
	name = "chief medical officer's labcoat"
	desc = "Голубее чем стандартная модель."
	icon_state = "labcoat_cmo"
	item_state = "labcoat_cmo"

/obj/item/clothing/suit/toggle/labcoat/mad
	name = "\proper The Mad's labcoat"
	desc = "С ним вы выглядите как кто-то способный стукнуть кому-то по кумполу и запустить его прямиком в космос."
	icon_state = "labgreen"
	item_state = "labgreen"

/obj/item/clothing/suit/toggle/labcoat/genetics
	name = "geneticist labcoat"
	desc = "Халат, защищающий от небольших химических утечек и пролитых веществ. С синей полосой на плечах."
	icon_state = "labcoat_gen"

/obj/item/clothing/suit/toggle/labcoat/chemist
	name = "chemist labcoat"
	desc = "Халат, защищающий от небольших химических утечек и пролитых веществ. С оранжевой полосой на плечах."
	icon_state = "labcoat_chem"

/obj/item/clothing/suit/toggle/labcoat/virologist
	name = "virologist labcoat"
	desc = "Халат, защищающий от небольших химических утечек и пролитых веществ. С зелёной полосой на плечах."
	icon_state = "labcoat_vir"

/obj/item/clothing/suit/toggle/labcoat/science
	name = "scientist labcoat"
	desc = "Халат, защищающий от небольших химических утечек и пролитых веществ. С фиолетовой полосой на плечах."
	icon_state = "labcoat_tox"

/obj/item/clothing/suit/toggle/labcoat/roboticist
	name = "roboticist labcoat"
	desc = "Скорее эксцентричная роба, нежели лабораторный халат. Помогает выдать пятна крови за часть эстетики. Прилагаются красные подплечники."
	icon_state = "labcoat_robo"

// Departmental Jackets
/obj/item/clothing/suit/toggle/labcoat/depjacket
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/toggle/labcoat/depjacket/sci
	name = "science jacket"
	desc = "Комфортная научно-фиолетовая куртка."
	icon_state = "sci_dep_jacket"
	item_state = "sci_dep_jacket"
	allowed = list(/obj/item/analyzer, /obj/item/stack/medical, /obj/item/dnainjector, /obj/item/reagent_containers/dropper, /obj/item/reagent_containers/syringe, /obj/item/reagent_containers/hypospray, /obj/item/healthanalyzer, /obj/item/flashlight/pen, /obj/item/reagent_containers/glass/bottle, /obj/item/reagent_containers/glass/beaker, /obj/item/reagent_containers/pill, /obj/item/storage/pill_bottle, /obj/item/paper, /obj/item/melee/classic_baton/telescopic, /obj/item/toy, /obj/item/storage/fancy/cigarettes, /obj/item/lighter, /obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman)
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 10, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)

/obj/item/clothing/suit/toggle/labcoat/depjacket/med
	name = "medical jacket"
	desc = "Комфортная медицинско-синяя куртка."
	icon_state = "med_dep_jacket"
	item_state = "med_dep_jacket"
	allowed = list(/obj/item/analyzer, /obj/item/sensor_device, /obj/item/stack/medical, /obj/item/dnainjector, /obj/item/reagent_containers/dropper, /obj/item/reagent_containers/syringe, /obj/item/reagent_containers/hypospray, /obj/item/healthanalyzer, /obj/item/flashlight/pen, /obj/item/reagent_containers/glass/bottle, /obj/item/reagent_containers/glass/beaker, /obj/item/reagent_containers/pill, /obj/item/storage/pill_bottle, /obj/item/paper, /obj/item/melee/classic_baton/telescopic, /obj/item/toy, /obj/item/storage/fancy/cigarettes, /obj/item/lighter, /obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman)
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 50, RAD = 0, FIRE = 0, ACID = 45)

/obj/item/clothing/suit/toggle/labcoat/depjacket/sec
	name = "Security Jacket"
	desc = "Комфортная охранно-красная куртка."
	icon_state = "sec_dep_jacket"
	item_state = "sec_dep_jacket"
	armor = list(MELEE = 25, BULLET = 15, LASER = 30, ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 0, ACID = 45)
	allowed = list(/obj/item/gun/energy, /obj/item/melee/baton, /obj/item/restraints/handcuffs, /obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman)

/obj/item/clothing/suit/toggle/labcoat/depjacket/sup
	name = "supply jacket"
	desc = "Комфортная погрузочно-коринчевая куртка."
	icon_state = "supply_dep_jacket"
	item_state = "supply_dep_jacket"

/obj/item/clothing/suit/toggle/labcoat/depjacket/sup/qm
	name = "quartermaster's jacket"
	desc = "Свободная накидка. Часто встречается на станционных завхозах."
	icon_state = "qmjacket"
	item_state = "qmjacket"

/obj/item/clothing/suit/toggle/labcoat/depjacket/eng
	name = "engineering jacket"
	desc = "Комфортная инженерно-жёлтая куртка."
	icon_state = "engi_dep_jacket"
	item_state = "engi_dep_jacket"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 20, FIRE = 30, ACID = 45)
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman,
		/obj/item/t_scanner, /obj/item/construction/rcd, /obj/item/pipe_dispenser, /obj/item/toy,
		/obj/item/storage/fancy/cigarettes, /obj/item/lighter, /obj/item/device/cooler
	)

/obj/item/clothing/suit/toggle/labcoat/depjacket/eng/chief_engineer
	name = "chief engineer's jacket"
	desc = "Комфортная серебряно-белая куртка. На бирке надпись: \"Не проводить стирку урановым порошком\"."
	icon = 'modular_bluemoon/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/mob/clothing/suit.dmi'
	icon_state = "chiefengi_dep_jacket"
	item_state = "labcoat"
	armor = list(MELEE = 10, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 10, BIO = 0, RAD = 40, FIRE = 60, ACID = 65)
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/clothing/suit/toggle/labcoat/depjacket/eng/chief_engineer/Initialize(mapload)
	. = ..()
	allowed += list(/obj/item/melee/classic_baton/telescopic, /obj/item/areaeditor/blueprints)

/obj/item/clothing/suit/toggle/labcoat/syndicate
	name = "DS Labcoat"
	desc = "Скорее эксцентричная роба, нежели лабораторный халат. Помогает выдать пятна крови за часть эстетики. Прилагаются красные подплечники."
	icon_state = "labcoat_robo"
