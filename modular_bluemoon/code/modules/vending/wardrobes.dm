/* GLOBAL_VAR_INIT(roaches_deployed, FALSE)
#define MOTHROACH_START_CHANCE 5
#define MAX_MOTHROACH_AMOUNT 3 */

/obj/item/vending_refill/wardrobe
	icon_state = "refill_clothes"

/obj/machinery/vending/wardrobe
	default_price = PRICE_ALMOST_CHEAP
	extra_price = PAYCHECK_COMMAND
	payment_department = NO_FREEBIES
	//panel_type = "panel19"
	light_mask = "wardrobe-light-mask"

/obj/machinery/vending/wardrobe/Initialize(mapload)
	. = ..()
	if(!mapload)
		return
/*	if(GLOB.roaches_deployed || !is_station_level(z) || !prob(MOTHROACH_START_CHANCE))
		return
	for(var/count in 1 to rand(1, MAX_MOTHROACH_AMOUNT))
		new /mob/living/basic/mothroach(src)
	GLOB.roaches_deployed = TRUE


/obj/machinery/vending/wardrobe/on_dispense(obj/item/clothing/food)
	if(!istype(food))
		return
	for(var/mob/living/basic/mothroach/roach in contents)
		food.take_damage(food.get_integrity() * 0.5)

/obj/machinery/vending/wardrobe/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	for(var/mob/living/basic/mothroach/roach in contents)
		roach.ai_controller.set_blackboard_key(BB_BASIC_MOB_FLEE_TARGET, src) //scatter away!
		roach.forceMove(drop_location())*/

/obj/machinery/vending/wardrobe/sec_wardrobe
	name = "\improper SecDrobe"
	desc = "A vending machine for security and security-related clothing!"
	icon_state = "secdrobe"
	product_slogans = "Лови преступников стильно!;Мы пачкаем форму кровью, чтобы станция оставалась чистой!;У вас есть право соблюдать моду!;Дорогой, не забудь надеть бронежилет!"
	vend_reply = "Удачной службы!"
	products = list(
		/obj/item/clothing/accessory/armband/deputy = 5,
		/obj/item/clothing/suit/hooded/wintercoat/security = 2,
		/obj/item/storage/backpack/security = 3,
		/obj/item/storage/backpack/satchel/sec = 3,
		/obj/item/storage/backpack/duffelbag/sec = 3,
		/obj/item/clothing/under/rank/security/officer = 5,
		/obj/item/clothing/shoes/jackboots/sec = 3,
		/obj/item/clothing/shoes/jackboots/tall = 3,
		/obj/item/clothing/shoes/jackboots/tall_default = 2,
		/obj/item/clothing/head/beret/sec = 5,
		/obj/item/clothing/head/soft/sec = 5,
		/obj/item/clothing/mask/bandana/red = 5,
		/obj/item/clothing/mask/balaclava/breath/redscarf = 4,
		/obj/item/clothing/mask/balaclava/breath/alliance = 6,
		/obj/item/clothing/mask/gas/sechailer = 4,
		/obj/item/clothing/mask/gas/nri = 2,
		/obj/item/clothing/under/rank/security/officer/skirt = 5,
		/obj/item/clothing/under/rank/security/officer/grey = 5,
		/obj/item/clothing/under/rank/security/officer/tacticool = 3,
		/obj/item/clothing/under/rank/security/officer/urban_camo = 3,
		/obj/item/clothing/under/rank/security/officer/solfed_military = 4,
		/obj/item/clothing/under/rank/security/officer/nri_military = 4,
		/obj/item/clothing/head/HoS/beret/sol/security = 2,
		/obj/item/clothing/head/HoS/beret/nri/security = 2,
		/obj/item/clothing/head/helmet/flakhelm = 3,
		/obj/item/clothing/head/helmet/aviator_helmet = 2,
		/obj/item/clothing/head/helmet/blast_helmet = 2,
		/obj/item/clothing/head/helmet/russian_green_helmet = 3,
		/obj/item/clothing/under/pants/khaki = 5,
		/obj/item/clothing/suit/toggle/labcoat/depjacket/sec = 5,
		/obj/item/clothing/suit/armor/secjacket = 5,
		/obj/item/clothing/under/rank/security/officer/util = 5,
		/obj/item/clothing/under/rank/security/officer/blueshirt/seccorp = 5,
		/obj/item/clothing/neck/cloak/security = 6,
		/obj/item/clothing/head/beret/sec/peacekeeper/cap = 5,
		/obj/item/clothing/head/beret/sec/peacekeeper = 5,
		/obj/item/clothing/mask/balaclava/breath = 5,
		/obj/item/clothing/mask/gas/syndicate/ds/wide = 3,
		/obj/item/clothing/mask/gas/syndicate/ds/mouth = 3,
		/obj/item/clothing/mask/gas/syndicate/ds/coif = 2,
		/obj/item/clothing/under/rank/security/officer/peacekeeper =5,
		/obj/item/clothing/under/rank/security/officer/metrocop = 2,
		/obj/item/clothing/under/rank/security/skirt/slut = 5,
		/obj/item/clothing/under/rank/security/skirt/slut/pink = 5,
		/obj/item/clothing/under/rank/security/stripper = 5,
		/obj/item/clothing/suit/hooded/corpus/s = 5,
		/obj/item/clothing/head/utilcover = 5,
		/obj/item/clothing/under/bm/utility = 5,
		/obj/item/clothing/under/bm/utility/navy = 5,
		/obj/item/clothing/under/bm/utility/tan = 5
	)
	contraband = list(
		/obj/item/clothing/under/rank/security/stripper = 5,
		/obj/item/clothing/mask/gas/sechailer/slut = 4,
		/obj/item/clothing/mask/gas/sechailer/swat/officer = 2,
		/obj/item/clothing/mask/gas/syndicate/ds = 5,
		/obj/item/clothing/mask/russian_balaclava = 5,
		/obj/item/clothing/mask/gas/sechailer/syndicate = 5,
		/obj/item/clothing/head/helmet/rus_helmet = 3,
		/obj/item/clothing/head/helmet/rus_cap = 3,
		/obj/item/clothing/suit/armor/vest/russian_winter_coat = 3,
		/obj/item/clothing/under/syndicate/rus_army = 3,
		/obj/item/clothing/mask/gas/soviet = 3,
		/obj/item/clothing/mask/gas/german = 3,
		/obj/item/clothing/under/syndicate/combat = 2,
	)
	premium = list(
		/obj/item/clothing/under/rank/security/officer/formal = 5,
		/obj/item/clothing/head/helmet/hecu = 2,
		/obj/item/clothing/mask/gas/hecu = 2,
		/obj/item/clothing/suit/armor/hecu = 2,
		/obj/item/storage/backpack/hecu = 2,
		/obj/item/storage/backpack/hecu/black = 2,
		/obj/item/storage/backpack/rucksack = 1,
		/obj/item/storage/backpack/rucksack/blue = 1,
		/obj/item/storage/backpack/rucksack/navy = 1,
		/obj/item/storage/backpack/rucksack/green = 1,
		/obj/item/storage/backpack/rucksack/tan = 1,
		/obj/item/clothing/head/beret/sec/navyofficer = 5,
		/obj/item/clothing/gloves/latexsleeves/security = 5,
		/obj/item/clothing/shoes/jackboots/tall = 5,
		/obj/item/clothing/shoes/jackboots/alliance = 5,
		/obj/item/clothing/under/custom/mw2_russian_para = 5,
		/obj/item/clothing/under/bm/sigu = 5,
		/obj/item/clothing/head/beret/sec/bitch = 5,
		/obj/item/clothing/head/helmet/justice = 5,
		/obj/item/clothing/head/helmet/justice/escape = 5,
		)
	refill_canister = /obj/item/vending_refill/wardrobe/sec_wardrobe
	payment_department = ACCOUNT_SEC
	light_color = COLOR_MOSTLY_PURE_RED

/obj/item/vending_refill/wardrobe/sec_wardrobe
	machine_name = "SecDrobe"

/obj/machinery/vending/wardrobe/medi_wardrobe
	name = "\improper MediDrobe"
	desc = "Вендомат, по слухам, выдающий одежду медперсоналу."
	icon_state = "medidrobe"
	product_slogans = "Сделайте пятна крови модными!!!"
	vend_reply = "Спасибо за использование MediDrobe!"
	products = list(
		/obj/item/clothing/accessory/armband/med = 5,
		/obj/item/clothing/accessory/armband/medblue = 5,
		/obj/item/clothing/accessory/pocketprotector = 5,
		/obj/item/clothing/head/beret/med = 5,
		/obj/item/storage/backpack/medic = 5,
		/obj/item/storage/backpack/satchel/med = 5,
		/obj/item/storage/backpack/duffelbag/med = 5,
		/obj/item/clothing/suit/hooded/wintercoat/medical = 5,
		/obj/item/clothing/suit/hooded/wintercoat/paramedic = 2,
		/obj/item/clothing/under/rank/medical/doctor/nurse = 5,
		/obj/item/clothing/head/nursehat = 5,
		/obj/item/clothing/under/rank/medical/doctor/skirt= 5,
		/obj/item/clothing/under/rank/medical/doctor/blue = 5,
		/obj/item/clothing/under/rank/medical/doctor/green = 5,
		/obj/item/clothing/under/rank/medical/doctor/purple = 5,
		/obj/item/clothing/under/rank/medical/doctor = 5,
		/obj/item/clothing/under/rank/medical/paramedic = 5,
		/obj/item/clothing/under/rank/medical/paramedic/light = 5,
		/obj/item/clothing/under/rank/medical/paramedic/skirt = 5,
		/obj/item/clothing/under/rank/medical/paramedic/skirt/light = 5,
		/obj/item/clothing/under/sexynursesuit = 5,
		/obj/item/clothing/suit/toggle/labcoat = 5,
		/obj/item/clothing/suit/toggle/labcoat/paramedic = 5,
		/obj/item/clothing/suit/toggle/labcoat/emt = 5,
		/obj/item/clothing/suit/toggle/labcoat/depjacket/med = 5,
		/obj/item/clothing/shoes/sneakers/white = 5,
		/obj/item/clothing/head/soft/emt = 5,
		/obj/item/clothing/suit/apron/surgical = 5,
		/obj/item/clothing/mask/surgical = 5,
		/obj/item/clothing/mask/balaclava/breath/redscarf/bluescarf = 4,
		/obj/item/clothing/gloves/color/latex/nitrile = 5,
		/obj/item/clothing/under/rank/medical/doctor/util = 5,
		/obj/item/clothing/under/rank/medical/paramedic/red = 5,
		/obj/item/clothing/suit/toggle/labcoat/emt/red = 5,
		/obj/item/clothing/suit/toggle/labcoat/emt/highvis = 5,
		/obj/item/clothing/suit/hooded/plaguedoc_new = 2, // BlueMoon changes
		/obj/item/clothing/mask/surgical/plaguedoc_new = 2, // BlueMoon changes
		/obj/item/clothing/gloves/color/latex/nitrile/plaguedoc_new = 2, // BlueMoon changes
		/obj/item/clothing/neck/cloak/healer = 6,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/medi_wardrobe
	payment_department = ACCOUNT_MED

/obj/item/vending_refill/wardrobe/medi_wardrobe
	machine_name = "MediDrobe"

/obj/machinery/vending/wardrobe/engi_wardrobe
	name = "EngiDrobe"
	desc = "A vending machine renowned for vending industrial grade clothing."
	icon_state = "engidrobe"
	product_slogans = "Гарантированно защитит ваши ноги от несчастных случаев на производстве!;Боитесь радиации? Тогда носите жёлтое!;Жёлтое значит защита!"
	vend_reply = "Спасибо за использование EngiDrobe!"
	products = list(
		/obj/item/clothing/accessory/armband/engine = 5,
		/obj/item/clothing/accessory/pocketprotector = 5,
		/obj/item/clothing/head/beret/eng = 3,
		/obj/item/storage/backpack/industrial = 3,
		/obj/item/storage/backpack/satchel/eng = 3,
		/obj/item/storage/backpack/duffelbag/engineering = 3,
		/obj/item/clothing/suit/hooded/wintercoat/engineering = 3,
		/obj/item/clothing/under/rank/engineering/engineer = 5,
		/obj/item/clothing/under/rank/engineering/engineer/skirt = 5,
		/obj/item/clothing/under/rank/engineering/engineer/hazard = 5,
		/obj/item/clothing/under/rank/engineering/engineer/hazard/green = 5,
		/obj/item/clothing/under/rank/engineering/engineer/hazard/white = 5,
		/obj/item/clothing/under/radkini = 2,
		/obj/item/clothing/mask/gas/radmask = 2,
		/obj/item/clothing/suit/toggle/labcoat/depjacket/eng = 5,
		/obj/item/clothing/under/rank/engineering/engineer/util = 5,
		/obj/item/clothing/under/rank/engineering/engineer/mechanic = 5,
		/obj/item/clothing/suit/hazardvest = 5,
		/obj/item/clothing/shoes/workboots = 5,
		/obj/item/clothing/head/hardhat = 5,
		/obj/item/clothing/mask/balaclava/breath/redscarf/yellowscarf = 4,
		/obj/item/clothing/head/hardhat/weldhat = 3,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/engi_wardrobe
	payment_department = ACCOUNT_ENG
	light_color = COLOR_VIVID_YELLOW

/obj/item/vending_refill/wardrobe/engi_wardrobe
	machine_name = "EngiDrobe"

/obj/machinery/vending/wardrobe/atmos_wardrobe
	name = "AtmosDrobe"
	desc = "This relatively unknown vending machine delivers clothing for Atmospherics Technicians, an equally unknown job."
	icon_state = "atmosdrobe"
	product_slogans = "Приобретайте легковоспламеняющуюся одежду прямо здесь!!!"
	vend_reply = "Спасибо за использование AtmosDrobe!"
	products = list(
		/obj/item/clothing/accessory/pocketprotector = 3,
		/obj/item/clothing/head/beret/atmos = 3,
		/obj/item/storage/backpack/atmospheric = 3,
		/obj/item/storage/backpack/satchel/atmospheric = 3,
		/obj/item/storage/backpack/duffelbag/atmospheric = 3,
		/obj/item/clothing/head/hardhat/weldhat/dblue = 3,
		/obj/item/clothing/suit/hooded/wintercoat/engineering/atmos = 3,
		/obj/item/toy/plush/bm/atmosian = 1,
		/obj/item/clothing/under/rank/engineering/atmospheric_technician = 5,
		/obj/item/clothing/under/rank/engineering/atmospheric_technician/skirt = 5,
		/obj/item/clothing/shoes/sneakers/black = 5,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/atmos_wardrobe
	payment_department = ACCOUNT_ENG
	light_color = COLOR_VIVID_YELLOW

/obj/item/vending_refill/wardrobe/atmos_wardrobe
	machine_name = "AtmosDrobe"

/obj/machinery/vending/wardrobe/cargo_wardrobe
	name = "CargoDrobe"
	desc = "A highly advanced vending machine for buying cargo related clothing for free."
	icon_state = "cargodrobe"
	product_slogans = "Обновленный стиль Техника Склада!;Выбери свой стиль сегодня!;Эти шорты удобны и просты в носке, получи свои сейчас!"
	vend_reply = "Спасибо за использование CargoDrobe!"
	products = list(
		/obj/item/clothing/accessory/armband/cargo = 5,
		/obj/item/storage/bag/mail = 3,
		/obj/item/clothing/suit/hooded/wintercoat/cargo = 3,
		/obj/item/clothing/under/rank/cargo/tech = 3,
		/obj/item/clothing/under/rank/cargo/tech/skirt = 3,
		/obj/item/clothing/under/rank/cargo/util = 3,
		/obj/item/clothing/suit/toggle/labcoat/depjacket/sup = 3,
		/obj/item/clothing/under/rank/cargo/tech/long = 3,
		/obj/item/clothing/shoes/sneakers/black = 3,
		/obj/item/clothing/gloves/fingerless = 3,
		/obj/item/clothing/head/soft = 3,
		/obj/item/clothing/mask/balaclava/breath/redscarf/yellowscarf = 4,
		/obj/item/radio/headset/headset_cargo = 3,
		/obj/item/mailmat_deployer = 3,
	)
	premium = list(
		/obj/item/clothing/head/mailman = 1,
		/obj/item/clothing/under/misc/mailman = 1,
		/obj/item/clothing/under/rank/cargo/miner = 3,
		/obj/item/clothing/under/rank/cargo/miner/lavaland = 3,
	)
	contraband = list(
		/obj/item/clothing/under/suit/scarface = 2,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/cargo_wardrobe
	payment_department = ACCOUNT_CAR

/obj/item/vending_refill/wardrobe/cargo_wardrobe
	machine_name = "CargoDrobe"

/obj/machinery/vending/wardrobe/robo_wardrobe
	name = "RoboDrobe"
	desc = "A vending machine designed to dispense clothing known only to roboticists."
	icon_state = "robodrobe"
	product_slogans = "Ты превращаешь меня в TRUE, используй определения!;11010000 10111100 11010000 10110000 11010001 10000010 11010001 10001100 100000 11010000 10110101 11010000 10110001 11010000 10110000 11010000 10111011"
	vend_reply = "Спасибо за использование RoboDrobe!"
	products = list(
		/obj/item/clothing/glasses/hud/diagnostic = 3,
		/obj/item/stack/medical/nanogel = 5,
		// BLUEMOON ADD START - гидравлическая жидкость для синтетиков в двух вариациях, систем клинер
		/obj/item/reagent_containers/blood/oilblood = 5,
		/obj/item/reagent_containers/glass/bottle/synthblood_deluxe = 1,
		/obj/item/reagent_containers/glass/bottle/system_cleaner = 4,
		// BLUEMOON ADD END
		/obj/item/clothing/head/beret/robo = 3,
		/obj/item/clothing/under/rank/rnd/roboticist = 3,
		/obj/item/clothing/under/rank/rnd/roboticist/sleek = 3,
		/obj/item/clothing/under/rank/rnd/roboticist/skirt = 3,
		/obj/item/clothing/suit/hooded/wintercoat/robotics = 3,
		/obj/item/clothing/suit/toggle/labcoat/roboticist = 3,
		/obj/item/clothing/shoes/sneakers/black = 3,
		/obj/item/clothing/gloves/fingerless = 3,
		/obj/item/clothing/head/soft/black = 3,
		/obj/item/clothing/mask/bandana/skull = 2,
		/obj/item/clothing/mask/balaclava/breath/redscarf/purplescarf = 3,
		/obj/item/clothing/under/misc/mechsuitred = 1,
		/obj/item/clothing/under/misc/mechsuitwhite = 1,
		/obj/item/clothing/under/misc/mechsuitblue = 1,
	)
	contraband = list(
		/obj/item/clothing/suit/hooded/techpriest = 2,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/robo_wardrobe
	extra_price = PRICE_EXPENSIVE * 1.2
	payment_department = ACCOUNT_SCI

/obj/item/vending_refill/wardrobe/robo_wardrobe
	machine_name = "RoboDrobe"

/obj/machinery/vending/wardrobe/science_wardrobe
	name = "SciDrobe"
	desc = "A simple vending machine suitable to dispense well tailored science clothing. Endorsed by Space Cubans."
	icon_state = "scidrobe"
	product_slogans = "Тоскуете по запаху плазмы, сжигающей плоть?;Купите научную одежду прямо сейчас!;Изготовлена с использованием 10% ауксетика, так что вы можете не беспокоиться о том, что потеряете руку!"
	vend_reply = "Спасибо за использование SciDrobe!"
	products = list(
		/obj/item/clothing/accessory/armband/science = 5,
		/obj/item/clothing/accessory/pocketprotector = 5,
		/obj/item/clothing/head/beret/sci = 3,
		/obj/item/storage/backpack/science = 3,
		/obj/item/storage/backpack/satchel/tox = 3,
		/obj/item/storage/backpack/duffelbag = 3,
		/obj/item/clothing/suit/hooded/wintercoat/science = 3,
		/obj/item/clothing/under/rank/rnd/scientist = 4,
		/obj/item/clothing/under/rank/rnd/scientist/util = 4,
		/obj/item/clothing/under/rank/rnd/scientist/skirt = 4,
		/obj/item/clothing/suit/toggle/labcoat/science = 4,
		/obj/item/clothing/suit/toggle/labcoat/depjacket/sci = 4,
		/obj/item/clothing/shoes/sneakers/white = 4,
		/obj/item/radio/headset/headset_sci = 4,
		/obj/item/clothing/mask/balaclava/breath/redscarf/purplescarf = 4,
		/obj/item/clothing/mask/gas/tscmask = 3,
		/obj/item/clothing/mask/gas = 5
	)
	refill_canister = /obj/item/vending_refill/wardrobe/science_wardrobe
	payment_department = ACCOUNT_SCI
/obj/item/vending_refill/wardrobe/science_wardrobe
	machine_name = "SciDrobe"

/obj/machinery/vending/wardrobe/hydro_wardrobe
	name = "Hydrobe"
	desc = "A machine with a catchy name. It dispenses botany related clothing and gear."
	icon_state = "hydrobe"
	product_slogans = "Вы любите почву? Тогда покупайте нашу одежду!;Приобрести наряды, соответствующие вашему зеленому стилю, можно здесь!"
	vend_reply = "Спасибо за использование Hydrobe!"
	products = list(
		/obj/item/clothing/accessory/armband/hydro = 5,
		/obj/item/storage/backpack/botany = 3,
		/obj/item/storage/backpack = 3,
		/obj/item/storage/backpack/satchel/hyd = 3,
		/obj/item/storage/backpack/duffelbag = 3,
		/obj/item/clothing/suit/hooded/wintercoat/hydro = 2,
		/obj/item/clothing/suit/apron = 3,
		/obj/item/clothing/suit/apron/overalls = 5,
		/obj/item/clothing/under/rank/civilian/hydroponics = 5,
		/obj/item/clothing/under/rank/civilian/hydroponics/skirt = 5,
		/obj/item/clothing/mask/bandana = 4,
		/obj/item/clothing/gloves/botanic_leather = 5,
	)
	contraband = list(
		/obj/item/clothing/under/suit/scarface = 2,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/hydro_wardrobe
	payment_department = ACCOUNT_SRV
	light_color = LIGHT_COLOR_ELECTRIC_GREEN

/obj/item/vending_refill/wardrobe/hydro_wardrobe
	machine_name = "HyDrobe"

/obj/machinery/vending/wardrobe/curator_wardrobe
	name = "CuraDrobe"
	desc = "A lowstock vendor only capable of vending clothing for curators and librarians."
	icon_state = "curadrobe"
	product_slogans = "Очки для глаз и литература для души - в Curadrobe есть все!;Впечатлите и поразите гостей вашей библиотеки расширенной линейкой ручек Curadrob!"
	vend_reply = "Спасибо за использование CuraDrobe!"
	products = list(
		/obj/item/clothing/accessory/pocketprotector = 2,
		/obj/item/pen = 4,
		/obj/item/pen/red = 2,
		/obj/item/pen/blue = 2,
		/obj/item/pen/fourcolor = 1,
		/obj/item/pen/fountain = 2,
		/obj/item/clothing/glasses/regular = 2,
		/obj/item/clothing/glasses/regular/jamjar = 1,
		/obj/item/clothing/under/rank/civilian/curator = 1,
		/obj/item/clothing/under/rank/civilian/curator/skirt = 1,
		/obj/item/clothing/under/rank/captain/suit = 1,
		/obj/item/clothing/under/rank/captain/suit/skirt = 1,
		/obj/item/clothing/under/rank/civilian/head_of_personnel/suit = 1,
		/obj/item/clothing/under/rank/civilian/head_of_personnel/suit/skirt = 1,
		/obj/item/storage/backpack/satchel/explorer = 1,
		/obj/item/storage/backpack/explorer = 1,
		/obj/item/storage/bag/books = 1,
		/obj/item/clothing/suit/fakearmor/press = 1,
		/obj/item/clothing/head/press_helmet = 1,
	)
	premium = list(
		/obj/item/card_sticker/heresy = 5,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/curator_wardrobe
	payment_department = ACCOUNT_SRV

/obj/item/vending_refill/wardrobe/curator_wardrobe
	machine_name = "CuraDrobe"

/obj/machinery/vending/wardrobe/bar_wardrobe
	name = "BarDrobe"
	desc = "A stylish vendor to dispense the most stylish bar clothing!"
	icon_state = "bardrobe"
	product_slogans = "Гарантированно предотвращает появление пятен от пролитых напитков!"
	vend_reply = "Спасибо за использование BarDrobe!"
	products = list(
		/obj/item/clothing/head/that = 3,
		/obj/item/radio/headset/headset_srv = 3,
		/obj/item/clothing/suit/hooded/wintercoat/bar = 3,
		/obj/item/clothing/under/suit/sl = 3,
		/obj/item/clothing/under/rank/civilian/bartender = 3,
		/obj/item/clothing/under/rank/civilian/bartender/skirt = 2,
		/obj/item/clothing/under/rank/civilian/bartender/purple = 2,
		/obj/item/clothing/accessory/waistcoat = 3,
		/obj/item/clothing/suit/apron/purple_bartender = 2,
		/obj/item/clothing/head/soft/black = 4,
		/obj/item/clothing/neck/petcollar/handmade = 3,
		/obj/item/clothing/shoes/sneakers/black = 4,
		/obj/item/reagent_containers/rag = 4,
		/obj/item/storage/box/beanbag = 1,
		/obj/item/clothing/suit/armor/vest/alt = 1,
		/obj/item/circuitboard/machine/dish_drive = 1,
		/obj/item/clothing/glasses/sunglasses/reagent = 1,
		/obj/item/clothing/neck/petcollar = 3,
		/obj/item/storage/belt/bandolier = 1,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/bar_wardrobe
	payment_department = ACCOUNT_MED
	extra_price = PAYCHECK_COMMAND

/obj/item/vending_refill/wardrobe/bar_wardrobe
	machine_name = "BarDrobe"

/obj/machinery/vending/wardrobe/chef_wardrobe
	name = "ChefDrobe"
	desc = "This vending machine might not dispense meat, but it certainly dispenses chef related clothing."
	icon_state = "chefdrobe"
	product_slogans = "Наша одежда гарантированно защитит вас от брызга!;Сквирт!"
	vend_reply = "Спасибо за использование ChefDrobe!"
	products = list(
		/obj/item/clothing/under/suit/waiter = 3,
		/obj/item/radio/headset/headset_srv = 4,
		/obj/item/clothing/accessory/waistcoat = 3,
		/obj/item/clothing/suit/apron/chef = 3,
		/obj/item/clothing/head/soft/mime = 2,
		/obj/item/storage/box/mousetraps = 2,
		/obj/item/circuitboard/machine/dish_drive = 1,
		/obj/item/clothing/suit/toggle/chef = 2,
		/obj/item/clothing/under/rank/civilian/chef = 2,
		/obj/item/clothing/under/rank/civilian/chef/skirt = 2,
		/obj/item/clothing/head/chefhat = 2,
		/obj/item/reagent_containers/rag = 3,
		/obj/item/book/granter/crafting_recipe/cooking_sweets_101 = 2,
		/obj/item/book/granter/crafting_recipe/coldcooking = 2,
		/obj/item/clothing/gloves/color/white = 3,
	)
	contraband = list(
		/obj/item/card_sticker/muck = 2,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/chef_wardrobe
	payment_department = ACCOUNT_SRV

/obj/item/vending_refill/wardrobe/chef_wardrobe
	machine_name = "ChefDrobe"

/obj/machinery/vending/wardrobe/jani_wardrobe
	name = "JaniDrobe"
	desc = "A self cleaning vending machine capable of dispensing clothing for janitors."
	icon_state = "janidrobe"
	product_slogans = "Приходите и получите свою одежду для уборщиков, которую теперь одобряют все чешуйчатые мира!;Чешуйчатые, объединяйтесь!"
	vend_reply = "Спасибо за использование JaniDrobe!"
	products = list(
		/obj/item/clothing/under/rank/civilian/janitor = 2,
		/obj/item/clothing/under/rank/civilian/janitor/skirt = 2,
		/obj/item/clothing/suit/hooded/wintercoat/janitor = 3,
		/obj/item/cartridge/janitor = 3,
		/obj/item/clothing/gloves/color/black = 2,
		/obj/item/clothing/head/soft/purple = 2,
		/obj/item/broom = 2,
		/obj/item/paint/paint_remover = 2,
		/obj/item/melee/flyswatter = 2,
		/obj/item/flashlight = 2,
		/obj/item/clothing/suit/caution = 8,
		/obj/item/holosign_creator = 2,
		/obj/item/lightreplacer = 2,
		/obj/item/soap = 2,
		/obj/item/storage/bag/trash = 2,
		/obj/item/clothing/shoes/galoshes = 2,
		/obj/item/watertank/janitor = 2,
		/obj/item/storage/belt/janitor = 2,
		/obj/item/screwdriver = 2,
		/obj/item/clothing/mask/balaclava/breath/redscarf/purplescarf = 2,
		/obj/item/t_scanner/dirt_scanner = 2,
		/obj/item/stack/cable_coil/random = 4
	)
	refill_canister = /obj/item/vending_refill/wardrobe/jani_wardrobe
	default_price = PRICE_CHEAP
	extra_price = PRICE_EXPENSIVE * 0.8
	payment_department = ACCOUNT_SRV
	light_color = COLOR_STRONG_MAGENTA

/obj/item/vending_refill/wardrobe/jani_wardrobe
	machine_name = "JaniDrobe"

/obj/machinery/vending/wardrobe/law_wardrobe
	name = "LawDrobe"
	desc = "Objection! This wardrobe dispenses the rule of law... and lawyer clothing."
	icon_state = "lawdrobe"
	product_slogans = "Я ПРОТИВ!;Добейтесь верховенства закона сейчас же!"
	vend_reply = "Спасибо за использование LawDrobe!"
	products = list(
		/obj/item/clothing/accessory/armband = 5,
		/obj/item/clothing/under/rank/civilian/lawyer/bluesuit/skirt = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/purpsuit = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/purpsuit/skirt = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/female = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/female/skirt = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/really_black = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/really_black/skirt = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/blue = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/blue/skirt = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/red = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/red/skirt = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/black = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/black/skirt = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/black/alt = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/black/alt/skirt = 3,
		/obj/item/clothing/suit/toggle/lawyer = 3,
		/obj/item/clothing/suit/toggle/lawyer/purple = 3,
		/obj/item/clothing/suit/toggle/lawyer/black = 3,
		/obj/item/clothing/shoes/laceup = 3,
		/obj/item/clothing/accessory/lawyers_badge = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/galaxy_blue = 3,
		/obj/item/clothing/under/rank/civilian/lawyer/galaxy_red = 3,
		/obj/item/clothing/under/suit/black_really_collared = 3,
		/obj/item/clothing/under/suit/black_really_collared/skirt = 3,
		/obj/item/clothing/under/suit/inferno = 3,
		/obj/item/clothing/under/suit/inferno/skirt = 3,
		/obj/item/clothing/under/suit/inferno/beeze = 1,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/law_wardrobe
	payment_department = ACCOUNT_SRV

/obj/item/vending_refill/wardrobe/law_wardrobe
	machine_name = "LawDrobe"

/obj/machinery/vending/wardrobe/chap_wardrobe
	name = "DeusVend"
	desc = "God wills your purchase."
	icon_state = "chapdrobe"
	product_slogans = "Вас донимают культисты или назойливые ревенанты? Тогда приходите и оденьтесь как святой человек!;Одежда для настоящих мужчин!"
	vend_reply = "Спасибо за использование DeusVend!"
	products = list(
		/obj/item/choice_beacon/holy = 1,
		/obj/item/staff/bostaff/chaplain = 1,
		/obj/item/storage/backpack/cultpack = 2,
		/obj/item/clothing/accessory/pocketprotector/cosmetology = 2,
		/obj/item/clothing/under/rank/civilian/chaplain = 2,
		/obj/item/clothing/under/rank/civilian/chaplain/skirt = 2,
		/obj/item/clothing/shoes/sneakers/black = 2,
		/obj/item/clothing/under/rank/civilian/chaplain/nun = 10,
		/obj/item/clothing/head/nun_hood = 10,
		/obj/item/clothing/suit/chaplain/holidaypriest = 2,
		/obj/item/clothing/suit/chaplain/pharaoh = 2,
		/obj/item/clothing/head/nemes = 2,
		/obj/item/clothing/head/pharaoh = 2,
		/obj/item/clothing/neck/tie/cross = 7,
		/obj/item/storage/fancy/candle_box = 3,
		/obj/item/aspergillum = 3, // BLUEMOON ADD - инструмент для окропления святой водой
		/obj/item/toy/plush/plushvar = 1, // BLUEMOON ADD - перенесено из категории примиума,
		/obj/item/toy/plush/narplush = 1, // BLUEMOON ADD - перенесено из категории примиума,
		/obj/item/clothing/head/clownmitre = 3, //BlueMoon changes,
		/obj/item/clothing/suit/chaplain/clownpriest = 3, //BlueMoon changes,
		/obj/item/clothing/suit/chaplain/shrinehand = 3, //BlueMoon changes,
		/obj/item/clothing/suit/hooded/chaplain_hoodie/monk_robe = 2, //BlueMoon changes,
		/obj/item/clothing/neck/oldcross = 6,  //BlueMoon changes,
		/obj/item/clothing/neck/epitrachelion = 1, //BlueMoon changes,
		/obj/item/clothing/neck/cloak/bishop = 1, //BlueMoon changes,
		/obj/item/clothing/neck/cloak/bishopblack= 1, //BlueMoon changes,
		/obj/item/reagent_containers/glass/mortar/urn = 10,
	)
	contraband = list(
		/obj/item/sign/flag/ravenheart = 3, // Bluemoon edition - Флаг Воронье Сердце,
		/obj/item/sign/flag/ravenheart/alt = 3, // Bluemoon edition - Флаг-баннер Воронье Сердце,
		/obj/item/storage/box/raven_box/posters = 3, // Bluemoon edition - Постеры,
		/obj/item/card_sticker/agony = 5,
		/obj/item/choice_beacon/box/creepy_statue_kit = 6,
		/obj/item/choice_beacon/box/creepy_statue_kit/big = 1,
	)
	premium = list(
		/obj/item/storage/fancy/ringbox/silver = 4, // BLUEMOON ADD - для проведения свадеб,
		/obj/item/storage/fancy/ringbox = 4, // BLUEMOON ADD - для проведения свадеб,
		/obj/item/storage/fancy/ringbox/diamond = 4, // BLUEMOON ADD - для проведения свадеб,
		/obj/item/lighter/black = 1,
		/obj/item/reagent_containers/censer = 1,
		/obj/item/choice_beacon/ouija = 1,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/chap_wardrobe
	extra_price = PRICE_ALMOST_ONE_GRAND * 1.1
	payment_department = ACCOUNT_SRV
	vending_sound = 'sound/effects/pray.ogg' // BLUEMOON EDIT - особый звук для вендомата священника
	vending_sound_vary = FALSE // BLUEMOON EDIT - особый звук для вендомата священника

/obj/item/vending_refill/wardrobe/chap_wardrobe
	machine_name = "DeusVend"

/obj/machinery/vending/wardrobe/chem_wardrobe
	name = "ChemDrobe"
	desc = "Вендор для выдачи одежды, связанной с химической дисциплиной."
	icon_state = "chemdrobe"
	product_slogans = "Наша одежда на 0,5% более устойчива к воздействию кислот! Приобретайте прямо сейчас!"
	vend_reply = "TСпасибо за использование ChemDrobe!"
	products = list(
		/obj/item/clothing/under/rank/medical/chemist = 3,
		/obj/item/clothing/head/beret/chem = 3,
		/obj/item/clothing/under/rank/medical/chemist/skirt = 3,
		/obj/item/clothing/suit/hooded/wintercoat/chemistry = 3,
		/obj/item/clothing/shoes/sneakers/white = 3,
		/obj/item/clothing/suit/toggle/labcoat/chemist = 3,
		/obj/item/storage/backpack/chemistry = 3,
		/obj/item/storage/backpack/satchel/chem = 3,
		/obj/item/storage/bag/chemistry = 3,
		/obj/item/fermichem/pHbooklet = 3,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/chem_wardrobe
	payment_department = ACCOUNT_MED

/obj/item/vending_refill/wardrobe/chem_wardrobe
	machine_name = "ChemDrobe"

/obj/machinery/vending/wardrobe/gene_wardrobe
	name = "GeneDrobe"
	desc = "Вендор для выдачи одежды, связанной с генетической дисциплиной."
	icon_state = "genedrobe"
	product_slogans = "Идеально подходит для безумного ученого!"
	vend_reply = "Спасибо за использование GeneDrobe!"
	products = list(
		/obj/item/clothing/under/rank/medical/geneticist = 3,
		/obj/item/clothing/under/rank/medical/geneticist/skirt = 3,
		/obj/item/clothing/suit/hooded/wintercoat/genetics = 3,
		/obj/item/clothing/shoes/sneakers/white = 3,
		/obj/item/clothing/suit/toggle/labcoat/genetics = 3,
		/obj/item/storage/backpack/genetics = 3,
		/obj/item/storage/backpack/satchel/gen = 3,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/gene_wardrobe
	payment_department = ACCOUNT_SCI

/obj/item/vending_refill/wardrobe/gene_wardrobe
	machine_name = "GeneDrobe"

/obj/machinery/vending/wardrobe/viro_wardrobe
	name = "ViroDrobe"
	desc = "Нестерелизрованная машина для выдачи вирусологической одежды."
	icon_state = "virodrobe"
	product_slogans = " Вирусы донимают вас? Тогда перейдите на стерильную одежду уже сегодня!"
	vend_reply = "Спасибо за использование ViroDrobe"
	products = list(
		/obj/item/clothing/head/beret/viro = 3,
		/obj/item/clothing/under/rank/medical/virologist = 3,
		/obj/item/clothing/under/rank/medical/virologist/skirt = 3,
		/obj/item/clothing/suit/hooded/wintercoat/viro = 3,
		/obj/item/clothing/shoes/sneakers/white = 3,
		/obj/item/clothing/suit/toggle/labcoat/virologist = 3,
		/obj/item/clothing/mask/surgical = 3,
		/obj/item/storage/backpack/virology = 3,
		/obj/item/storage/backpack/satchel/vir = 3,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/viro_wardrobe
	payment_department = ACCOUNT_MED

/obj/item/vending_refill/wardrobe/viro_wardrobe
	machine_name = "ViroDrobe"

/obj/machinery/vending/wardrobe/det_wardrobe
	name = "\improper DetDrobe"
	desc = "A machine for all your detective needs, as long as you need clothes."
	icon_state = "detdrobe"
	product_slogans = "Применяйте свои блестящие дедуктивные методы в стиле!"
	vend_reply = "Спасибо за использование DetDrobe!"
	products = list(
		/obj/item/clothing/under/rank/security/detective = 2,
		/obj/item/clothing/under/rank/security/detective/skirt = 2,
		/obj/item/clothing/under/rank/security/detective/brown = 2,
		/obj/item/clothing/under/rank/security/detective/brown/brown2 = 2,
		/obj/item/clothing/under/rank/security/officer/blueshirt/seccorp/detcorp = 2,
		/obj/item/clothing/under/rank/security/officer/util = 2,
		/obj/item/clothing/shoes/sneakers/brown = 2,
		/obj/item/clothing/suit/det_suit = 2,
		/obj/item/clothing/head/fedora/det_hat = 2,
		/obj/item/clothing/under/rank/security/detective/grey = 2,
		/obj/item/clothing/under/rank/security/detective/grey/skirt = 2,
		/obj/item/clothing/accessory/waistcoat = 2,
		/obj/item/clothing/shoes/laceup = 2,
		/obj/item/clothing/suit/det_suit/grey = 1,
		/obj/item/clothing/suit/det_suit/forensicsred = 1,
		/obj/item/clothing/suit/det_suit/forensicsred/long = 1,
		/obj/item/clothing/suit/det_suit/forensicsblue = 1,
		/obj/item/clothing/suit/det_suit/forensicsblue/long = 1,
		/obj/item/clothing/suit/det_suit/lanyard = 1,
		/obj/item/clothing/head/fedora = 2,
		/obj/item/clothing/gloves/color/black = 2,
		/obj/item/clothing/gloves/color/latex = 2,
		/obj/item/reagent_containers/food/drinks/flask/det = 2,
		/obj/item/storage/fancy/cigarettes = 5,
		/obj/item/storage/backpack/detective = 2,
		/obj/item/storage/backpack/satchel/detective = 2,
		/obj/item/storage/backpack/duffelbag/detective = 2
	)
	premium = list(
		/obj/item/clothing/head/flatcap = 1,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/det_wardrobe
	extra_price = PRICE_EXPENSIVE * 1.75
	payment_department = ACCOUNT_SEC

/obj/item/vending_refill/wardrobe/det_wardrobe
	machine_name = "DetDrobe"

/obj/machinery/vending/wardrobe/cap_wardrobe
	name = "Captain's Wardrobe"
	desc = "Последние достижения в области Nanotrasen для вашего великого лидера."
	icon_state = "capsdrobe"
	icon_deny = "capsdrobe-deny"
	product_slogans = "Только лучшее для лучших."
	vend_reply = "Прекрасного Вам дня, замечательный руководитель."
	products = list(/obj/item/clothing/suit/hooded/wintercoat/captain = 1,
					/obj/item/storage/backpack/captain = 1,
					/obj/item/storage/backpack/satchel/cap = 1,
					/obj/item/storage/backpack/duffelbag/captain = 1,
					/obj/item/clothing/neck/cloak/cap = 1,
					/obj/item/clothing/neck/mantle/captain = 1, // BlueMoon Add
					/obj/item/clothing/neck/cloak/regal_cap = 1, // BlueMoon Add
					/obj/item/clothing/shoes/sneakers/brown = 2,
					/obj/item/clothing/under/rank/captain = 1,
					/obj/item/clothing/under/rank/captain/util = 1,
					/obj/item/clothing/under/rank/captain/skirt = 1,
					/obj/item/clothing/head/caphat = 1,
					/obj/item/clothing/head/caphat/parade = 1,
					/obj/item/clothing/head/caphat/beret = 1,
					/obj/item/clothing/head/caphat/beret/white = 1,
					/obj/item/clothing/under/rank/captain/parade = 1,
					/obj/item/clothing/under/bm/caprevskirt = 2, // BlueMoon Add
					/obj/item/clothing/under/bm/regaloutfit = 2, // BlueMoon Add
					/obj/item/clothing/suit/captunic = 1,
					/obj/item/clothing/under/rank/captain/femformal = 2,
					/obj/item/clothing/glasses/sunglasses/gar/supergar = 1,
					/obj/item/clothing/gloves/color/captain = 1,
					/obj/item/clothing/neck/cloak/syndiecap = 2, // BlueMoon Add
					/obj/item/clothing/neck/cloak/syndieadm = 1) // BlueMoon Add

	refill_canister = /obj/item/vending_refill/wardrobe/cap_wardrobe
	payment_department = ACCOUNT_SEC
	default_price = PRICE_ALMOST_EXPENSIVE
	extra_price = PRICE_ABOVE_EXPENSIVE

/obj/item/vending_refill/wardrobe/cap_wardrobe
	machine_name = "Captain's Wardrobe"
	icon_state = "refill_caps"

/obj/machinery/vending/wardrobe/syndie_wardrobe
	name = "\improper SynDrobe"
	desc = "A vending machine for our boys in red, now in brand new crimson!"
	icon_state = "syndrobe"
	product_slogans = "Натягивай!;Целься, Одевайся, Стреляй!;Красная Бригада за ношение лучшего!"
	vend_reply = "Спасибо за использование SynDrobe!"
	circuit = /obj/item/circuitboard/machine/vending/syndicate_clothes_vendor
	products = list(
		/obj/item/clothing/under/syndicate = 3,
		/obj/item/clothing/under/syndicate/skirt = 3,
		/obj/item/clothing/under/syndicate/tacticool = 3,
		/obj/item/clothing/under/syndicate/tacticool/skirt = 3,
		/obj/item/clothing/under/syndicate/overalls = 3,
		/obj/item/clothing/under/syndicate/overalls/skirt = 3,
		/obj/item/clothing/under/syndicate/bloodred = 3,
		/obj/item/clothing/under/syndicate/sniper = 3,
		/obj/item/clothing/under/syndicate/camo = 3,
		/obj/item/clothing/under/syndicate/combat = 3,
		/obj/item/clothing/suit/armor/vest/infiltrator/gorlex_harness = 1,
		/obj/item/clothing/shoes/combat = 3,
		/obj/item/clothing/mask/gas/syndicate = 3,
		/obj/item/clothing/mask/gas/sechailer/syndicate = 3,
		/obj/item/clothing/mask/gas/sechailer/syndicate/flektarn = 3,
		/obj/item/clothing/mask/gas/sechailer/syndicate/green = 3,
		/obj/item/clothing/mask/gas/sechailer/syndicate/tan = 3,
		/obj/item/clothing/suit/hooded/wintercoat/syndicate = 1,
		/obj/item/clothing/head/soft/sec/syndicate = 3,
		/obj/item/clothing/head/beret/sec/syndicate = 3,
		/obj/item/clothing/neck/cloak/syndiecap = 1,
		/obj/item/armorkit/syndicate = 5,
		/obj/item/armorkit/helmet/syndicate = 5,
	)
	contraband = list(
		/obj/item/kitchen/knife/combat = 4,
		/obj/item/clothing/under/syndicate/coldres = 2,
		/obj/item/clothing/shoes/combat/coldres = 2,
	)
	premium = list(
		/obj/item/kitchen/knife/combat/survival/knuckledagger = 2,
		/obj/item/storage/fancy/cigarettes/cigpack_syndicate = 5,
		/obj/item/lighter = 5,
		/obj/item/clothing/gloves/combat = 3,
		/obj/item/clothing/under/syndicate/maid = 5,
		/obj/item/clothing/gloves/combat/maid = 5,
		/obj/item/clothing/head/maid/syndicate = 5,
		/obj/item/card/id/syndicate = 5,
		/obj/item/clothing/suit/toggle/captains_parade/syndicate/winter = 1,
		/obj/item/clothing/suit/toggle/captains_parade/syndicate = 1,
		/obj/item/clothing/head/hats/warden/syndicate = 1,
		/obj/item/storage/backpack/duffelbag/syndie = 2
	)
	refill_canister = /obj/item/vending_refill/wardrobe/syndie_wardrobe
	light_color = COLOR_MOSTLY_PURE_RED

/obj/item/vending_refill/wardrobe/syndie_wardrobe
	machine_name = "SynDrobe"
	icon_state = "refill_donksoft"

/obj/machinery/vending/wardrobe/centcom_wardrobe
	name = "\improper CentDrobe"
	desc = "A vending machine for our boys in blue, now in brand new black-green!"
	icon_state = "greed"
	product_slogans = "Натягивай!;Целься, Одевайся, Стреляй!;Синяя Бригада за ношение лучшего!"
	vend_reply = "Спасибо за использование CentDrobe!"
	circuit = /obj/item/circuitboard/machine/vending/syndicate_clothes_vendor
	products = list(
		/obj/item/clothing/under/rank/centcom/officer = 3,
		/obj/item/clothing/under/rank/centcom/officer_alt = 3,
		/obj/item/clothing/under/rank/centcom/commander = 3,
		/obj/item/clothing/glasses/eyepatch = 3,
		/obj/item/storage/box/syndie_kit/centcom_costume = 2,
		/obj/item/mod/control/pre_equipped/corporate = 2,
	)
	contraband = list(
		/obj/item/kitchen/knife/combat = 4,
	)
	premium = list(
		/obj/item/lighter = 2,
		/obj/item/lighter/slime = 2,
		/obj/item/lighter/black = 2,
		/obj/item/lighter/blue = 2,
		/obj/item/lighter/cap = 2,
		/obj/item/lighter/ce = 2,
		/obj/item/lighter/cmo = 2,
		/obj/item/lighter/hos = 2,
		/obj/item/lighter/hop = 2,
		/obj/item/lighter/nt_rep = 2,
		/obj/item/lighter/rd = 2,
		/obj/item/lighter/purple = 2,
		/obj/item/lighter/donator = 2,
		/obj/item/lighter/contractor = 2,
		/obj/item/lighter/engraved = 2,
		/obj/item/lighter/qm_engraved = 2,
		/obj/item/lighter/gold = 2,
		/obj/item/lighter/gonzofist = 2,
		/obj/item/storage/fancy/cigarettes/cigars/cohiba = 2,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/centcom_wardrobe
	light_color = COLOR_NAVY

/obj/item/vending_refill/wardrobe/centcom_wardrobe
	machine_name = "CentDrobe"
	icon_state = "refill_donksoft"

/obj/machinery/vending/wardrobe/syndie_wardrobe/civil
	name = "\improper Civilian SynDrobe"
	desc = "A vending machine for our boys in red, now in brand new crimson!"
	icon_state = "syndrobe"
	product_slogans = "Натягивай!;Целься, Одевайся, Стреляй!;Красная Бригада за ношение лучшего!"
	vend_reply = "Спасибо за использование SynDrobe!"
	circuit = /obj/item/circuitboard/machine/vending/syndicate_clothes_vendor/civil
	products = list(
		/obj/item/clothing/under/syndicate/civil = 5,
		/obj/item/clothing/under/syndicate/skirt/civil = 5,
		/obj/item/clothing/under/syndicate/tacticool/civil = 5,
		/obj/item/clothing/under/syndicate/tacticool/skirt/civil = 5,
		/obj/item/clothing/under/syndicate/overalls/civil = 5,
		/obj/item/clothing/under/syndicate/overalls/skirt/civil = 5,
		/obj/item/clothing/under/syndicate/bloodred/civil = 5,
		/obj/item/clothing/under/syndicate/sniper/civil = 5,
		/obj/item/clothing/under/syndicate/camo/civil = 5,
		/obj/item/clothing/under/syndicate/combat/civil = 5,
		/obj/item/clothing/shoes/jackboots = 3,
		/obj/item/clothing/shoes/jackboots/tall = 3,
		/obj/item/clothing/mask/gas/syndicate = 5,
		/obj/item/clothing/mask/gas/sechailer/syndicate = 5,
		/obj/item/clothing/head/soft/sec/syndicate/civil = 5,
		/obj/item/clothing/head/beret/sec/syndicate/civil = 5,
		/obj/item/clothing/neck/cloak/syndiecap = 5,
	)
	contraband = list(
		/obj/item/storage/fancy/cigarettes/cigpack_syndicate = 5,
		/obj/item/lighter = 5,
	)
	premium = list(
		/obj/item/clothing/gloves/combat/fake = 5,
		/obj/item/clothing/gloves/combat/maid/civil = 5,
		/obj/item/clothing/under/syndicate/maid/civil = 5,
		/obj/item/clothing/suit/hooded/wintercoat/syndicate/civil = 5,
		/obj/item/clothing/suit/armor/vest/infiltrator/gorlex_harness/civil = 5,
		/obj/item/clothing/suit/armor/vest/fake = 5,
		/obj/item/clothing/suit/toggle/captains_parade/syndicate/winter/civil = 5,
		/obj/item/clothing/suit/toggle/captains_parade/syndicate/civil = 5,
		/obj/item/clothing/head/maid/syndicate/civil = 5,
		/obj/item/clothing/head/helmet/swat/ds/civil = 5,
		/obj/item/clothing/head/hats/warden/syndicate/civil = 5,
		/obj/item/card_sticker/syndicate = 5
	)
	refill_canister = /obj/item/vending_refill/wardrobe/syndie_wardrobe/civil
	light_color = COLOR_MOSTLY_PURE_RED

/obj/item/vending_refill/wardrobe/syndie_wardrobe/civil
	machine_name = "Civilian SynDrobe"
	icon_state = "refill_donksoft"

/*
/obj/machinery/vending/wardrobe/cent_wardrobe
	name = "\improper CentDrobe"
	desc = "A one-of-a-kind vending machine for all your centcom aesthetic needs!"
	icon_state = "centdrobe"
	product_slogans = "Show those ERTs who's the most stylish in the briefing room!"
	vend_reply = "Thank you for using the CentDrobe!"
	products = list(
		/obj/item/clothing/glasses/sunglasses = 3,
		/obj/item/clothing/head/hats/centcom_cap = 3,
		/obj/item/clothing/head/hats/centhat = 3,
		/obj/item/clothing/head/hats/intern = 3,
		/obj/item/clothing/under/rank/centcom/commander = 3,
		/obj/item/clothing/under/rank/centcom/centcom_skirt = 3,
		/obj/item/clothing/under/rank/centcom/intern = 3,
		/obj/item/clothing/under/rank/centcom/official = 3,
		/obj/item/clothing/under/rank/centcom/officer = 3,
		/obj/item/clothing/under/rank/centcom/officer_skirt = 3,
		/obj/item/clothing/suit/armor/centcom_formal = 3,
		/obj/item/clothing/suit/space/officer = 3,
		/obj/item/clothing/suit/hooded/wintercoat/centcom = 3,
		/obj/item/clothing/shoes/laceup = 3,
		/obj/item/clothing/shoes/jackboots = 3,
		/obj/item/clothing/gloves/combat = 3,
	)
	refill_canister = /obj/item/vending_refill/wardrobe/cent_wardrobe

/obj/item/vending_refill/wardrobe/cent_wardrobe
	machine_name = "CentDrobe"
	light_color = LIGHT_COLOR_ELECTRIC_GREEN
*/
/*
#undef MOTHROACH_START_CHANCE
#undef MAX_MOTHROACH_AMOUNT*/

/obj/machinery/vending/wardrobe/blueshield_wardrobe
	name = "\improper BlueDrobe"
	desc = "A vending machine for blueshield and blueshield-related clothing!"
	icon_state = "commdrobe"
	icon = 'modular_splurt/icons/obj/objects.dmi'
	product_slogans = "Защищать и служить!;Чувствуй себя хорошо, сохраняя жизнь людям!;"
	vend_reply = "Спасибо за использование BlueDrobe!"
	products = list(
		/obj/item/clothing/under/rank/blueshield = 2,
		/obj/item/clothing/under/rank/blueshield/skirt = 2,
		/obj/item/clothing/under/rank/blueshield/formal = 2,
		/obj/item/clothing/under/custom/mw2_russian_para = 2,
		/obj/item/storage/backpack/blueshield = 2,
		/obj/item/storage/backpack/satchel/blueshield = 2,
		/obj/item/storage/backpack/duffelbag/blueshield = 2,
		/obj/item/clothing/shoes/jackboots = 2,
		/obj/item/clothing/head/soft/blueshield = 2,
		/obj/item/clothing/head/blueshield = 2,
		/obj/item/clothing/head/blueshield/formal = 2,
		/obj/item/clothing/head/blueshield/officercap = 2,
		/obj/item/clothing/neck/tie/blue = 2,
		/obj/item/clothing/under/rank/blueshield/formal/skirt = 2,
		/obj/item/clothing/shoes/jackboots/tall = 2,
		/obj/item/clothing/shoes/jackboots/tall_default = 2,
		/obj/item/clothing/suit/armor/vest/bluesheid/spacecoat = 2,
		/obj/item/clothing/suit/armor/vest/bluesheid/jacket = 2,
		/obj/item/clothing/under/rank/blueshield/formal/pmc_leader_jumpsuit = 2,
		/obj/item/clothing/mask/balaclava/pmc_leader_balaclava = 2,
		/obj/item/clothing/head/HoS/pmc_leader_cap = 2,
		/obj/item/clothing/head/HoS/pmc_leader_beret = 2,
		/obj/item/clothing/suit/armor/hos/pmc_leader_armor = 2,
		/obj/item/clothing/under/syndicate/maid = 2,
		/obj/item/clothing/under/syndicate/maid_revealing = 2,
		/obj/item/clothing/gloves/combat/maid = 2,
		/obj/item/clothing/head/maid/syndicate = 2
	)
	refill_canister = /obj/item/vending_refill/wardrobe/blueshield_wardrobe
	payment_department = ACCOUNT_SEC
	light_color = COLOR_STRONG_BLUE

/obj/item/vending_refill/wardrobe/blueshield_wardrobe
	machine_name = "BlueDrobe"

/obj/machinery/vending/wardrobe/bridgeofficer_wardrobe
	name = "\improper CommDrobe"
	desc = "A vending machine for bridge officers and officer-related clothing!"
	icon_state = "commdrobe"
	icon = 'modular_splurt/icons/obj/objects.dmi'
	product_slogans = "Почувствуйте себя важным!;Служить!!;Тебе следует быть лучше, щенок!!!"
	vend_reply = "Спасибо за использование BlueDrobe!"
	products = list(
		/obj/item/clothing/under/rank/bridgeofficer = 2,
		/obj/item/clothing/under/rank/bridgeofficer/skirt = 2,
		/obj/item/clothing/under/rank/bridgeofficer/formal = 2,
		/obj/item/clothing/head/bridgeofficer = 2,
		/obj/item/clothing/head/bridgeofficer/beret = 2,
		/obj/item/clothing/suit/toggle/brigdesec = 2,
		/obj/item/storage/backpack = 2,
		/obj/item/storage/backpack/satchel = 2,
		/obj/item/storage/backpack/duffelbag = 2,
		/obj/item/clothing/gloves/color/black = 2,
		/obj/item/clothing/shoes/sneakers/brown  =2,
		/obj/item/clothing/shoes/sneakers/black = 2,
		/obj/item/clothing/shoes/sneakers/blue = 2,
		/obj/item/clothing/neck/tie/blue = 2,
		/obj/item/clothing/neck/tie/red = 2,
		/obj/item/clothing/neck/tie/black =2
	)
	refill_canister = /obj/item/vending_refill/wardrobe/blueshield_wardrobe
	payment_department = ACCOUNT_CIV
	light_color = COLOR_STRONG_BLUE

/obj/item/vending_refill/wardrobe/blueshield_wardrobe
	machine_name = "BlueDrobe"

/obj/machinery/vending/wardrobe/hos_wardrobe
	name = "\improper HOSDrobe"
	desc = "A vending machine for the head of security and security-related clothing!"
	icon_state = "secdrobe"
	product_slogans = "Бей преступников в стиле!;На красном красного не видно!;Вы имеете право быть модным!;Теперь вы можете быть полицейским моды, которым вы всегда хотели быть!"
	vend_reply = "Спасибо за использование HosDrobe!"
	products = list(
		/obj/item/clothing/neck/cloak/hos = 1,
		/obj/item/clothing/neck/mantle/head_of_security = 1,
		/obj/item/clothing/neck/cloak/regal_hos = 1,
		/obj/item/storage/backpack/security = 1,
		/obj/item/storage/backpack/satchel/sec = 1,
		/obj/item/storage/backpack/duffelbag/sec = 1,
		/obj/item/clothing/suit/toggle/captains_parade/hos_formal = 1,
		/obj/item/clothing/shoes/jackboots = 1,
		/obj/item/clothing/under/rank/security/head_of_security/parade/female = 1,
		/obj/item/clothing/under/rank/security/head_of_security/parade = 1,
		/obj/item/clothing/under/rank/security/officer/blueshirt/seccorp/hoscorp = 1,
		/obj/item/clothing/under/rank/security/head_of_security/skirt = 1,
		/obj/item/clothing/under/rank/security/head_of_security/alt = 1,
		/obj/item/clothing/under/rank/security/head_of_security/alt/skirt = 1,
		/obj/item/clothing/head/HoS = 1,
		/obj/item/clothing/glasses/hud/security/sunglasses/eyepatch = 1,
		/obj/item/clothing/glasses/hud/security/sunglasses/gars/supergars = 1,
		/obj/item/clothing/under/rank/security/head_of_security/grey = 1,
		/obj/item/clothing/suit/hooded/wintercoat/hos = 1,
		/obj/item/clothing/suit/armor/vest/leather = 1,
		/obj/item/clothing/suit/armor/hos = 1,
		/obj/item/clothing/under/rank/security/head_of_security/peacekeeper = 1,
		/obj/item/clothing/head/beret/sec/peacekeeper/hos = 1,
		/obj/item/clothing/head/HoS/peacekeeper = 1,
		/obj/item/clothing/suit/armor/hos/peacekeeper = 1, //BlueMoon Add
		/obj/item/clothing/suit/armor/hos/trenchcoat = 1, //BlueMoon Add
		/obj/item/clothing/under/rank/blueshield/formal/pmc_leader_jumpsuit = 1, //BlueMoon Add
		/obj/item/clothing/mask/balaclava/pmc_leader_balaclava = 1, //BlueMoon Add
		/obj/item/clothing/head/HoS/pmc_leader_cap = 1, //BlueMoon Add
		/obj/item/clothing/head/HoS/pmc_leader_beret = 1, //BlueMoon Add
		/obj/item/clothing/suit/armor/hos/pmc_leader_armor = 1, //BlueMoon Add
		/obj/item/clothing/neck/tie/dread_neck = 1, //BlueMoon Add
		/obj/item/clothing/suit/armor/hos/dread_armor = 1, //BlueMoon Add
		/obj/item/clothing/head/HoS/dread_helmet = 1,	//BlueMoon Add
	)
	refill_canister = /obj/item/vending_refill/wardrobe/sec_wardrobe
	payment_department = ACCOUNT_SEC
	light_color = COLOR_MOSTLY_PURE_RED

/obj/item/vending_refill/wardrobe/hos_wardrobe
	machine_name = "HOSDrobe"
