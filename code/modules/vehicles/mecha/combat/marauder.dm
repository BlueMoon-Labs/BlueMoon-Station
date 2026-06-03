/obj/vehicle/sealed/mecha/combat/marauder
	desc = "Тяжёлый боевой экзокостюм, разработанный на основе модели Durand. Редко встречается среди гражданских."
	name = "\improper Marauder"
	icon_state = "marauder"
	movedelay = 5
	max_integrity = 500
	deflect_chance = 25
	armor = list(MELEE = 50, BULLET = 55, LASER = 40, ENERGY = 30, BOMB = 30, BIO = 0, RAD = 60, FIRE = 100, ACID = 100)
	max_temperature = 60000
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	operation_req_access = list(ACCESS_CENT_SPECOPS)
	internals_req_access = list(ACCESS_CENT_SPECOPS)
	wreckage = /obj/structure/mecha_wreckage/marauder
	mecha_flags = CANSTRAFE | IS_ENCLOSED | HAS_LIGHTS
	internal_damage_threshold = 25
	force = 45
	max_equip = 5
	bumpsmash = TRUE

/obj/vehicle/sealed/mecha/combat/marauder/generate_actions()
	. = ..()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_smoke)

/obj/vehicle/sealed/mecha/combat/marauder/loaded/Initialize(mapload)
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/thrusters/ion(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/energy/pulse(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster(src)
	ME.attach(src)
	max_ammo()

/obj/vehicle/sealed/mecha/combat/marauder/seraph
	desc = "Тяжёлый командный экзокостюм. Это уникальная модель, используемая только высокопоставленными военными."
	name = "\improper Seraph"
	icon_state = "seraph"
	operation_req_access = list(ACCESS_CENT_SPECOPS)
	internals_req_access = list(ACCESS_CENT_SPECOPS)
	movedelay = 3
	max_integrity = 550
	wreckage = /obj/structure/mecha_wreckage/seraph
	internal_damage_threshold = 20
	force = 55
	max_equip = 6

/obj/vehicle/sealed/mecha/combat/marauder/seraph/Initialize(mapload)
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/thrusters/ion(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/energy/pulse(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/teleporter(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster(src)
	ME.attach(src)
	max_ammo()

/obj/vehicle/sealed/mecha/combat/marauder/seraph/generate_actions()
	. = ..()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_zoom)

/obj/vehicle/sealed/mecha/combat/marauder/mauler
	desc = "Тяжёлый боевой экзокостюм, разработанный на основе существующей модели Marauder."
	name = "\improper Mauler"
	icon_state = "mauler"
	operation_req_access = list(ACCESS_SYNDICATE)
	internals_req_access = list(ACCESS_SYNDICATE)
	wreckage = /obj/structure/mecha_wreckage/mauler
	max_equip = 6
	destruction_sleep_duration = 20
	nominalphrase = "sound/mecha/nominal_syndicate.ogg"
	imagenhphrase = "sound/mecha/imag_enh_syndicate.ogg"

/obj/vehicle/sealed/mecha/combat/marauder/mauler/Initialize(mapload)
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/thrusters/ion(src)
	ME.attach(src)

/obj/vehicle/sealed/mecha/combat/marauder/mauler/generate_actions()
	. = ..()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/syndicate/mech_zoom)

/obj/vehicle/sealed/mecha/combat/marauder/mauler/loaded/Initialize(mapload)
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster(src)
	ME.attach(src)
	max_ammo()
