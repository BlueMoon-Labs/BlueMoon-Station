///NRI Combat Mech
/obj/vehicle/sealed/mecha/combat/durand/tu802
	desc = "Deep Durand modification, licensed and utilized by the manufacturers of the New Russian Empire."
	name = "\improper TU-802 Solntsepyok"
	icon_state = "shire"
	armor_type = /datum/armor/durand_tu802_and_ares
	max_temperature = 60000
	wreckage = /obj/structure/mecha_wreckage/shire
	max_equip = 6
	nominalphrase = "sound/mecha/nominal_russian.ogg"

/obj/vehicle/sealed/mecha/combat/durand/tu802/generate_actions()
	. = ..()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_smoke)
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/russian/mech_zoom)

/obj/vehicle/sealed/mecha/combat/durand/tu802/Initialize(mapload)
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/thrusters/ion(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay(src)
	ME.attach(src)
	max_ammo()

/obj/structure/mecha_wreckage/shire
	name = "\improper TU-802 wreckage"
	icon_state = "shire-broken"
	parts = list(
			/obj/item/mecha_parts/part/durand_torso,
			/obj/item/mecha_parts/part/durand_head,
			/obj/item/mecha_parts/part/durand_left_arm,
			/obj/item/mecha_parts/part/durand_right_arm,
			/obj/item/mecha_parts/part/durand_left_leg,
			/obj/item/mecha_parts/part/durand_right_leg)

///Savannah-Ivanov NRI loaded version

/obj/vehicle/sealed/mecha/combat/savannah_ivanov/loaded/Initialize(mapload)
	. = ..()
	install_titanfall_premium_parts()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/thrusters/ion(src)
	ME.detachable = FALSE
	max_equip++
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster(src)
	ME.attach(src)
	max_ammo()

///SolFed Combat Mech

/obj/vehicle/sealed/mecha/combat/durand/zeus
	desc = "The Standart Issue Solar Federation Exosuit, powered with Mark.1 tesla cannon. Designated to provide support to Solar Marines."
	name = "\improper ZEUS"
	icon = 'modular_bluemoon/kovac_shitcode/icons/mecha/solfed_mecha.dmi'
	icon_state = "zeus"
	armor_type = /datum/armor/zeus
	max_temperature = 70000
	wreckage = /obj/structure/mecha_wreckage/zeus
	max_equip = 6
	turnsound = 'modular_bluemoon/kovac_shitcode/sound/mecha/turn.ogg'
	nominalphrase = 'modular_bluemoon/kovac_shitcode/sound/mecha/nominal_sol.ogg'

/obj/vehicle/sealed/mecha/combat/durand/zeus/generate_actions()
	. = ..()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_smoke)
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/sol/mech_zoom)

/obj/vehicle/sealed/mecha/combat/durand/zeus/Initialize(mapload)
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/thrusters/ion(src)
	ME.detachable = FALSE
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/energy/tesla(src)
	ME.detachable = FALSE
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg(src)
	ME.detachable = FALSE
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay(src)
	ME.attach(src)
	max_ammo()

/obj/vehicle/sealed/mecha/combat/durand/zeus/add_cell(obj/item/stock_parts/cell/C=null)
	if(C)
		C.forceMove(src)
		cell = C
		return
	cell = new /obj/item/stock_parts/cell/bluespace(src)

/obj/structure/mecha_wreckage/zeus
	name = "\improper Zeus wreckage"
	icon = 'modular_bluemoon/kovac_shitcode/icons/mecha/solfed_mecha.dmi'
	icon_state = "zeus-broken"
	parts = list(
			/obj/item/mecha_parts/part/durand_torso,
			/obj/item/mecha_parts/part/durand_head,
			/obj/item/mecha_parts/part/durand_left_arm,
			/obj/item/mecha_parts/part/durand_right_arm,
			/obj/item/mecha_parts/part/durand_left_leg,
			/obj/item/mecha_parts/part/durand_right_leg)
