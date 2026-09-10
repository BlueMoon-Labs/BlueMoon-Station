/obj/machinery/vending/brigdoc_vendomat
	name = "\improper MeDSec"
	desc = "Stay alive until the end. Dispenses stuff for brig physicians."
	icon = 'modular_bluemoon/icons/obj/vending.dmi'
	icon_state = "brigdoc"
	product_slogans = "А вы знаете, что такое Женевская конвенция?;Террористы ведь не будут стрелять в офицеров с красным крестом, правда?;Иди и спаси чью-то жизнь!"
	vend_reply = "Медицинское снаряжение выдано. Удачной службы."
	req_access = list(ACCESS_MEDICAL)
	products = list(/obj/item/reagent_containers/syringe = 3,
					/obj/item/reagent_containers/dropper = 2,
					/obj/item/storage/ifak = 3,
					/obj/item/sensor_device = 2,
					/obj/item/pinpointer/crew = 2,
					/obj/item/healthanalyzer = 2,
					/obj/item/reagent_containers/medspray/sterilizine = 2,
					/obj/item/stack/medical/gauze = 2,
					/obj/item/reagent_containers/pill/patch/styptic = 5,
					/obj/item/reagent_containers/medspray/styptic = 4,
					/obj/item/reagent_containers/pill/patch/silver_sulf = 5,
					/obj/item/reagent_containers/medspray/silver_sulf = 4,
					/obj/item/reagent_containers/glass/bottle/charcoal = 3,
					/obj/item/reagent_containers/glass/bottle/epinephrine = 3,
					/obj/item/reagent_containers/glass/bottle/salglu_solution = 3,
					/obj/item/reagent_containers/glass/bottle/morphine = 4,
					/obj/item/storage/hypospraykit/fire = 2,
					/obj/item/storage/hypospraykit/toxin = 2,
					/obj/item/storage/hypospraykit/o2 = 2,
					/obj/item/storage/hypospraykit/brute = 2,
					/obj/item/reagent_containers/glass/bottle/vial/small = 2,
					/obj/item/reagent_containers/hypospray/medipen = 4,
					/obj/item/stack/medical/ointment = 4,
					/obj/item/stack/medical/suture = 4,
					/obj/item/stack/medical/bone_gel = 2,
					/obj/item/stack/medical/nanogel = 2)
	refill_canister = /obj/item/vending_refill/brigdoc_vendomat
	payment_department = ACCOUNT_SEC

/obj/item/vending_refill/brigdoc_vendomat
	machine_name = "SecMedDrobe"
