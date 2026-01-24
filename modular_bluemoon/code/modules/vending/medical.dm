/obj/machinery/vending/medical
	name = "\improper NanoMed Plus"
	desc = "Раздатчик медпрепаратов и снаряжения."
	icon_state = "med"
	icon_deny = "med-deny"
	//panel_type = "panel11"
	product_slogans = "Иди и спаси чью-то жизнь!;Только лучшие лекарства!;Натуральные химикаты - здесь!"
	products = list(
		/obj/item/reagent_containers/syringe = 12,
		/obj/item/reagent_containers/dropper = 3,
		/obj/item/healthanalyzer = 4,
		/obj/item/sensor_device = 4,
		/obj/item/pinpointer/crew = 4,
		/obj/item/reagent_containers/medspray/sterilizine = 2,
		/obj/item/stack/medical/gauze = 8,
		/obj/item/reagent_containers/pill/patch/styptic = 5,
		/obj/item/reagent_containers/medspray/styptic = 2,
		/obj/item/reagent_containers/pill/patch/silver_sulf = 5,
		/obj/item/reagent_containers/medspray/silver_sulf = 2,
		/obj/item/reagent_containers/pill/insulin = 10,
		/obj/item/reagent_containers/pill/salbutamol = 2,
		/obj/item/reagent_containers/glass/bottle/charcoal = 4,
		/obj/item/reagent_containers/glass/bottle/epinephrine = 4,
		/obj/item/reagent_containers/glass/bottle/salglu_solution = 3,
		/obj/item/reagent_containers/glass/bottle/morphine = 4,
		/obj/item/reagent_containers/glass/bottle/toxin = 3,
		/obj/item/reagent_containers/syringe/antiviral = 6,
		/obj/item/storage/hypospraykit/fire = 3,
		/obj/item/storage/hypospraykit/toxin = 2,
		/obj/item/storage/hypospraykit/o2 = 2,
		/obj/item/storage/hypospraykit/brute = 3,
		/obj/item/storage/hypospraykit/enlarge = 2,
		/obj/item/reagent_containers/glass/bottle/vial/small = 5,
		/obj/item/storage/briefcase/medical = 2,
		/obj/item/stack/sticky_tape/surgical = 3,
		/obj/item/healthanalyzer/wound = 4,
		/obj/item/reagent_containers/hypospray/medipen = 4,
		/obj/item/stack/medical/ointment = 2,
		/obj/item/stack/medical/suture = 2,
		/obj/item/stack/medical/bone_gel = 4,
		/obj/item/stack/medical/nanogel = 4,
	)
	contraband = list(
		/obj/item/reagent_containers/pill/tox = 3,
		/obj/item/reagent_containers/pill/morphine = 4,
		/obj/item/reagent_containers/pill/charcoal = 6,
		/obj/item/storage/pill_bottle/lsdpsych = 3,
		/obj/item/storage/pill_bottle/happinesspsych = 3,
		/obj/item/storage/pill_bottle/paxpsych = 3,
		/obj/item/reagent_containers/hypospray/medipen/bimbo = 3,
	)
	premium = list(
		/obj/item/reagent_containers/medspray/synthflesh = 2,
		/obj/item/storage/box/hug/medical = 1,
		/obj/item/storage/pill_bottle/psicodine = 3, // SPLURT EDIT 2 -> 3
		/obj/item/reagent_containers/hypospray/medipen = 3,
		/obj/item/storage/belt/medical = 3,
		/obj/item/wrench/medical = 1,
		/obj/item/storage/belt/medolier/full = 2,
		/obj/item/gun/syringe/dart = 2,
		/obj/item/storage/briefcase/medical = 2,
		/obj/item/plunger/reinforced = 2
	)
	refill_canister = /obj/item/vending_refill/medical
	default_price = PRICE_ALMOST_CHEAP
	extra_price = PRICE_ABOVE_NORMAL
	payment_department = ACCOUNT_MED
	light_mask = "med-light-mask"

/obj/item/vending_refill/medical
	machine_name = "NanoMed Plus"
	icon_state = "refill_medical"

/obj/machinery/vending/medical/syndicate_access
	name = "\improper SyndiMed Plus"
	req_access = list(ACCESS_SYNDICATE)
	//initial_language_holder = /datum/language_holder/syndicate

/obj/machinery/vending/medical/syndicate_access/cybersun
	name = "\improper CyberMed ++"
	desc = "Продвинутый раздатчик препаратов и лекарств, как \"рекреационных\", так и медицинских."
	products = list(
		/obj/item/reagent_containers/syringe = 4,
		/obj/item/healthanalyzer/advanced = 4,
		/obj/item/reagent_containers/pill/patch/silver_sulf = 5,
		/obj/item/reagent_containers/pill/patch/styptic = 5,
		/obj/item/reagent_containers/glass/bottle/charcoal = 3,
		/obj/item/reagent_containers/glass/bottle/dexalin = 2,
		/obj/item/reagent_containers/glass/bottle/epinephrine = 3,
		/obj/item/reagent_containers/glass/bottle/morphine = 3,
		/obj/item/reagent_containers/glass/bottle/potass_iodide = 5,
		/obj/item/reagent_containers/glass/bottle/salglu_solution = 3,
		/obj/item/reagent_containers/syringe/antiviral = 5,
		/obj/item/reagent_containers/hypospray/medipen = 4,
		/obj/item/stack/medical/ointment = 2,
		/obj/item/stack/medical/suture = 2,
		/obj/item/stack/medical/bone_gel = 4,
		/obj/item/stack/medical/nanogel = 4,
		/obj/item/storage/hypospraykit/fire = 3,
		/obj/item/storage/hypospraykit/toxin = 2,
		/obj/item/storage/hypospraykit/o2 = 2,
		/obj/item/storage/hypospraykit/brute = 3,
		/obj/item/storage/hypospraykit/enlarge = 2,
		/obj/item/reagent_containers/medspray/styptic = 2,
		/obj/item/reagent_containers/medspray/silver_sulf = 2,
		/obj/item/reagent_containers/medspray/sterilizine = 2,
	)
	contraband = list(
		/obj/item/reagent_containers/glass/bottle/cold = 2,
		/obj/item/restraints/handcuffs = 4,
		/obj/item/storage/backpack/duffelbag/syndie/surgery = 1,
		/obj/item/storage/firstaid/tactical = 1,
	)
	premium = list(
		/obj/item/storage/pill_bottle/psicodine = 2,
		/obj/item/reagent_containers/hypospray/medipen = 3,
		/obj/item/reagent_containers/hypospray/medipen/atropine = 2,
		/obj/item/storage/firstaid/regular = 3,
		/obj/item/storage/firstaid/brute = 2,
		/obj/item/storage/firstaid/fire = 2,
		/obj/item/storage/firstaid/toxin = 2,
		/obj/item/storage/firstaid/o2 = 2,
		/obj/item/defibrillator/loaded = 1,
		/obj/item/wallframe/defib_mount = 1,
		/obj/item/clothing/glasses/hud/health/sunglasses = 6,
		/obj/item/sensor_device = 3,
		/obj/item/reagent_containers/blood/oilblood = 6,
		/obj/item/pinpointer/crew = 3,
	)

/obj/machinery/vending/medical/syndicate_access/Initialize(mapload)
	. = ..()
	cost_multiplier_per_dept = list("[ACCESS_SYNDICATE]" = 0)


//Created out of a necessity to get these dumb chems out of the medical tools vendor.
/obj/machinery/vending/drugs
	name = "\improper NanoDrug Plus"
	desc = "Раздатчик медпрепаратов и снаряжения."
	icon_state = "drug"
	icon_deny = "drug-deny"
	//panel_type = "panel11"
	product_slogans = "Иди и спаси чью-то жизнь!;Только лучшие лекарства!;Натуральные химикаты - здесь!"
	products = list(
		/obj/item/reagent_containers/pill/patch/silver_sulf = 5,
		/obj/item/reagent_containers/pill/patch/styptic = 5,
		/obj/item/reagent_containers/pill/insulin = 5,
		/obj/item/reagent_containers/glass/bottle/charcoal = 2,
		/obj/item/reagent_containers/glass/bottle/epinephrine = 3,
		/obj/item/reagent_containers/glass/bottle/morphine = 4,
		/obj/item/reagent_containers/glass/bottle/potass_iodide = 5,
		/obj/item/reagent_containers/glass/bottle/salglu_solution = 3,
		/obj/item/reagent_containers/glass/bottle/toxin = 3,
		/obj/item/reagent_containers/syringe/antiviral = 6,
		/obj/item/reagent_containers/medspray/styptic = 2,
		/obj/item/reagent_containers/medspray/silver_sulf = 2,
		/obj/item/reagent_containers/medspray/sterilizine = 2,
	)
	contraband = list(
		/obj/item/reagent_containers/pill/tox = 3,
		/obj/item/reagent_containers/pill/morphine = 4,
		/obj/item/reagent_containers/pill/charcoal = 6,
	)
	premium = list(
		/obj/item/reagent_containers/medspray/synthflesh = 2,
		/obj/item/storage/pill_bottle/psicodine = 2,
	)
	default_price = PRICE_ALMOST_CHEAP
	extra_price = PRICE_ABOVE_NORMAL
	payment_department = ACCOUNT_MED
	light_mask = "drug-light-mask"
	refill_canister = /obj/item/vending_refill/drugs

/obj/item/vending_refill/drugs
	machine_name = "NanoDrug Plus"
	icon_state = "refill_medical"
