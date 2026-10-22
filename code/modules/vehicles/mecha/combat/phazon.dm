/obj/vehicle/sealed/mecha/combat/phazon
	desc = "Это экзокостюм Phazon. Венец научных исследований и гордость Nanotrasen, использует передовую блюспейс-технологию и дорогие материалы."
	name = "\improper Phazon"
	icon_state = "phazon"
	movedelay = 2
	dir_in = 2 //Facing South.
	normal_step_energy_drain = 3
	max_integrity = 100
	deflect_chance = 30
	armor_type = /datum/armor/phazon
	max_temperature = 25000
	wreckage = /obj/structure/mecha_wreckage/phazon
	internal_damage_threshold = 25
	force = 15
	max_equip = 3
	phase_state = "phazon-phase"
	ui_theme = "science"

/obj/vehicle/sealed/mecha/combat/phazon/generate_actions()
	. = ..()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_toggle_phasing)
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_switch_damtype)
