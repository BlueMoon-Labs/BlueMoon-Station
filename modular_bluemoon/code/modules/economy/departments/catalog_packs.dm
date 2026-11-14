/datum/supply_pack/department
	group = "Каталог отдела"
	crate_type = /obj/structure/closet/crate/secure
	can_private_buy = FALSE

/datum/supply_pack/department/engineering_export_node
	name = "Power Export Node Crate"
	desc = "Плата межсекторного энергоузла, конденсаторы и кабель для его сборки."
	department_catalog = ACCOUNT_ENG
	access = ACCESS_ENGINE
	cost = 3500
	contains = list(
		/obj/item/circuitboard/machine/power_export_node,
		/obj/item/stock_parts/capacitor,
		/obj/item/stock_parts/capacitor,
		/obj/item/stock_parts/capacitor,
		/obj/item/stock_parts/capacitor,
		/obj/item/stack/cable_coil,
	)
	crate_name = "power export node crate"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/department/medical_surgery_kit
	name = "Advanced Surgical Kit"
	desc = "Полный хирургический набор в медицинской сумке."
	department_catalog = ACCOUNT_MED
	access = ACCESS_MEDICAL
	cost = 2500
	contains = list(/obj/item/storage/backpack/duffelbag/med/surgery)
	crate_name = "surgery kit crate"
	crate_type = /obj/structure/closet/crate/secure/medical

/datum/supply_pack/department/science_xenobio
	name = "Xenobiology Starter Kit"
	desc = "Два анализатора слаймов и коробка обезьяньих кубиков для ксенобиологии."
	department_catalog = ACCOUNT_SCI
	access = ACCESS_RESEARCH
	cost = 2000
	contains = list(
		/obj/item/slime_scanner,
		/obj/item/slime_scanner,
		/obj/item/storage/box/monkeycubes,
	)
	crate_name = "xenobiology crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/department/security_evidence
	name = "Evidence Locker Crate"
	desc = "Плата и материальные контейнеры хранилища улик, через которое изъятая контрабанда передаётся NT."
	department_catalog = ACCOUNT_SEC
	access = ACCESS_SECURITY
	cost = 1500
	contains = list(
		/obj/item/circuitboard/machine/evidence_locker,
		/obj/item/stock_parts/matter_bin,
		/obj/item/stock_parts/matter_bin,
	)
	crate_name = "evidence locker crate"
	crate_type = /obj/structure/closet/crate/secure/gear

/datum/supply_pack/department/service_exotic
	name = "Exotic Ingredients Crate"
	desc = "Редкие специи и продукты для кухни и бара: ваниль, какао, соль и перец."
	department_catalog = ACCOUNT_SRV
	cost = 1200
	contains = list(
		/obj/item/reagent_containers/food/condiment/saltshaker,
		/obj/item/reagent_containers/food/condiment/peppermill,
		/obj/item/reagent_containers/food/snacks/grown/vanillapod,
		/obj/item/reagent_containers/food/snacks/grown/vanillapod,
		/obj/item/reagent_containers/food/snacks/grown/cocoapod,
		/obj/item/reagent_containers/food/snacks/grown/cocoapod,
	)
	crate_name = "exotic ingredients crate"
	crate_type = /obj/structure/closet/crate/freezer

/datum/supply_pack/department/service_cash_register
	name = "Cash Register Crate"
	desc = "Плата кассы заведения и сканирующий модуль для её сборки."
	department_catalog = ACCOUNT_SRV
	cost = 800
	contains = list(
		/obj/item/circuitboard/machine/cash_register,
		/obj/item/stock_parts/scanning_module,
	)
	crate_name = "cash register crate"

/datum/supply_pack/department/cargo_mining_kit
	name = "Mining Expedition Kit"
	desc = "Шахтёрский бур, сумка для руды и сканер для вылазки на астероид."
	department_catalog = ACCOUNT_CAR
	access = ACCESS_MINING
	cost = 1800
	contains = list(
		/obj/item/pickaxe/drill,
		/obj/item/storage/bag/ore,
		/obj/item/t_scanner/adv_mining_scanner/lesser,
	)
	crate_name = "mining kit crate"
