/obj/machinery/vending/wallmed
	name = "\improper NanoMed"
	desc = "Настенный раздатчики медицинского снаряжения."
	icon_state = "wallmed"
	icon_deny = "wallmed-deny"
	//panel_type = "wallmed-panel"
	density = FALSE
	products = list(
		/obj/item/reagent_containers/syringe = 3,
		/obj/item/reagent_containers/pill/patch/styptic = 5,
		/obj/item/reagent_containers/pill/patch/silver_sulf = 5,
		/obj/item/reagent_containers/medspray/styptic = 2,
		/obj/item/reagent_containers/medspray/silver_sulf = 2,
		/obj/item/reagent_containers/hypospray/medipen = 3,
		/obj/item/reagent_containers/pill/charcoal = 2,
		/obj/item/reagent_containers/medspray/sterilizine = 1,
		/obj/item/healthanalyzer/wound = 2,
		/obj/item/stack/medical/bone_gel = 2,
		/obj/item/stack/medical/nanogel = 2,
		/obj/item/reagent_containers/syringe/dart = 10
	)
	contraband = list(
		/obj/item/reagent_containers/pill/tox = 2,
		/obj/item/reagent_containers/pill/morphine = 2,
		/obj/item/storage/box/gum/happiness = 1,
	)
	refill_canister = /obj/item/vending_refill/wallmed
	default_price = PAYCHECK_COMMAND //Double the medical price due to being meant for public consumption, not player specfic
	extra_price = PAYCHECK_COMMAND * 1.5
	payment_department = ACCOUNT_MED
	tiltable = FALSE
	light_mask = "wallmed-light-mask"

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/vending/wallmed, 32)

/obj/item/vending_refill/wallmed
	machine_name = "NanoMed"
	icon_state = "refill_medical"

/obj/machinery/vending/wallmed/pubby
	products = list(
		/obj/item/reagent_containers/syringe = 3,
		/obj/item/reagent_containers/pill/patch/styptic = 1,
		/obj/item/reagent_containers/pill/patch/silver_sulf = 1,
		/obj/item/reagent_containers/medspray/sterilizine = 1
	)
	premium = list(
		/obj/item/reagent_containers/medspray/synthflesh = 2
	)
