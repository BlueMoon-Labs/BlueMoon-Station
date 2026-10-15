///InteQ "Durand" Mecha
/obj/vehicle/sealed/mecha/combat/marauder/mauler/loaded/ares
	desc = "Бог Войны среди Мехов. Разработки Солнечной Федерации дали нам Ареса. Бронированная машина будет давить ваших врагов."
	name = "\improper MIB-02 Ares"
	icon = 'modular_bluemoon/krashly/icons/obj/mecha/ares.dmi'
	icon_state = "ares"
	operation_req_access = list(ACCESS_INTEQ)
	internals_req_access = list(ACCESS_INTEQ)
	armor_type = /datum/armor/durand_tu802_and_ares
	wreckage = /obj/structure/mecha_wreckage/ares

/obj/vehicle/sealed/mecha/combat/marauder/mauler/ares/generate_actions()
	. = ..()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_smoke)

/obj/structure/mecha_wreckage/ares
	name = "\improper MIB-02 Ares wreckage"
	icon = 'modular_bluemoon/krashly/icons/obj/mecha/ares.dmi'
	icon_state = "ares-broken"
	parts = list(
			/obj/item/mecha_parts/part/durand_torso,
			/obj/item/mecha_parts/part/durand_head,
			/obj/item/mecha_parts/part/durand_left_arm,
			/obj/item/mecha_parts/part/durand_right_arm,
			/obj/item/mecha_parts/part/durand_left_leg,
			/obj/item/mecha_parts/part/durand_right_leg)

///InteQ "Gygax" Mecha
/obj/vehicle/sealed/mecha/combat/gygax/dark/loaded/hermes
	desc = "Отличный для быстрых атак Мех. Разработки Солнечной Федерации позволили нападать с флангов на металлической коннице. Гермес не заменим своей маневренностью и скоростью."
	name = "\improper MIB-01 Hermes"
	icon = 'modular_bluemoon/krashly/icons/obj/mecha/hermes.dmi'
	icon_state = "hermes"
	operation_req_access = list(ACCESS_INTEQ)
	internals_req_access = list(ACCESS_INTEQ)
	armor_type = /datum/armor/hermes
	max_temperature = 60000
	wreckage = /obj/structure/mecha_wreckage/hermes

/obj/vehicle/sealed/mecha/combat/gygax/dark/hermes/generate_actions()
	. = ..()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_smoke)
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/syndicate/mech_zoom)

/obj/structure/mecha_wreckage/hermes
	name = "\improper MIB-01 Hermes wreckage"
	icon = 'modular_bluemoon/krashly/icons/obj/mecha/hermes.dmi'
	icon_state = "hermes-broken"
	parts = list(
			/obj/item/mecha_parts/part/durand_torso,
			/obj/item/mecha_parts/part/durand_head,
			/obj/item/mecha_parts/part/durand_left_arm,
			/obj/item/mecha_parts/part/durand_right_arm,
			/obj/item/mecha_parts/part/durand_left_leg,
			/obj/item/mecha_parts/part/durand_right_leg)
