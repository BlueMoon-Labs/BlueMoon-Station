/obj/vehicle/sealed/mecha/combat/reticence
	desc = "Бесшумный, быстрый и почти невидимый мимский экзокостюм. Популярен среди мимов и мим-убийц."
	name = "\improper reticence"
	icon_state = "reticence"
	movedelay = 2
	dir_in = 1 //Facing North.
	max_integrity = 250
	deflect_chance = 5
	armor_type = /datum/armor/gygax_reticence_and_medigax
	max_temperature = 25000
	force = 25
	wreckage = /obj/structure/mecha_wreckage/reticence
	operation_req_access = list(ACCESS_THEATRE)
	internals_req_access = list(ACCESS_ROBOTICS, ACCESS_THEATRE)
	mecha_flags =  CANSTRAFE | IS_ENCLOSED | HAS_LIGHTS | MMI_COMPATIBLE
	internal_damage_threshold = 25
	max_equip = 3
	normal_step_energy_drain = 3
	color = "#87878715"
	stepsound = null
	turnsound = null
	destruction_sleep_duration = 20

/obj/vehicle/sealed/mecha/combat/reticence/loaded/Initialize(mapload)
	. = ..()
	install_titanfall_premium_parts()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/silenced
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/rcd //HAHA IT MAKES WALLS GET IT
	ME.attach(src)
