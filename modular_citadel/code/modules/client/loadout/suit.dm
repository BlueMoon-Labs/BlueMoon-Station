/datum/gear/suit
	category = LOADOUT_CATEGORY_SUIT
	subcategory = LOADOUT_SUBCATEGORY_SUIT_GENERAL
	slot = ITEM_SLOT_OCLOTHING

/datum/gear/suit/cmo_tailcoat
	name = "Chief medical officer's tailcoat"
	description = "Стерильный синий фрак, который носят главные врачи."
	path = /obj/item/clothing/suit/toggle/labcoat/cmo/doctor_tailcoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Chief Medical Officer"
	restricted_roles = list("Chief Medical Officer")

/datum/gear/suit/doctor_tailcoat
	name = "Medical tailcoat"
	description = "Стерильный бело-синий халат врачей в тематике кроликов. Отлично помогает не испачкаться кровью."
	path = /obj/item/clothing/suit/toggle/labcoat/doctor_tailcoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Medical Doctor"
	restricted_roles = list("Medical Doctor")

/datum/gear/suit/chemist_tailcoat
	name = "Chemist's tailcoat"
	description = "Стерильный бело-оранжевый халат химиков в тематике кроликов. Открытая грудь — не лучшее при работе с опасными веществами."
	path = /obj/item/clothing/suit/toggle/labcoat/chemist/doctor_tailcoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Chemist"
	restricted_roles = list("Chemist")

/datum/gear/suit/edgelord_trenchcoat
	name = "Edgelord trenchcoat"
	path = /obj/item/clothing/suit/jacket/leather_trenchcoat

/datum/gear/suit/poncho
	name = "Poncho"
	description = "Классическое политкорректное пончо."
	path = /obj/item/clothing/suit/poncho

/datum/gear/suit/aged_robe
	name = "Aged Robe"
	path = /obj/item/clothing/suit/donator/bm/cultist_poly
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#2A2A2A","#A52F29")

/datum/gear/suit/empire_suit
	name = "Katzen Suit"
	path = /obj/item/clothing/suit/empire_suit
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#2A2A2A","#e42929", "#e0bf28")

/datum/gear/suit/ponchogreen
	name = "Green poncho"
	description = "Классическое политкорректное пончо. Это — зелёное."
	path = /obj/item/clothing/suit/poncho/green

/datum/gear/suit/poly_armored_poncho
	name = "Poly Nanotech Poncho"
	description = "Пончо, чёрт возьми, пончо."
	path = /obj/item/clothing/suit/poly_armored_poncho
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#2A2A2A","#e42929")

/datum/gear/suit/poly_poncho
	name = "Poly Poncho"
	description = "Пончо, чёрт возьми, пончо."
	path = /obj/item/clothing/suit/poly_poncho
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#2A2A2A")

/datum/gear/suit/ponchored
	name = "Red poncho"
	description = "Классическое политкорректное пончо. Это — красное."
	path = /obj/item/clothing/suit/poncho/red

/datum/gear/suit/redhood
	name = "Red cloak"
	description = "Хочешь выглядеть круто безо всяких усилий? Примерь этот красный плащ от NanoTrasen — идеален для детей."
	path = /obj/item/clothing/suit/hooded/cloak/david

/datum/gear/suit/harley_jacket
	name = "Harley Jacket"
	path = /obj/item/clothing/suit/jacket/harley
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketbomber
	name = "Bomber jacket"
	description = "Авиаторы не включены."
	path = /obj/item/clothing/suit/jacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketflannelblack // all of these are reskins of bomber jackets but with the vibe to make you look like a true lumberjack
	name = "Black flannel jacket"
	path = /obj/item/clothing/suit/toggle/jacket/flannel
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketflannelred
	name = "Red flannel jacket"
	description = "Удобное и, по слухам, легковоспламеняющееся."
	path = /obj/item/clothing/suit/toggle/jacket/flannel/red
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketflannelaqua
	name = "Aqua flannel jacket"
	description = "Удобное и, по слухам, легковоспламеняющееся."
	path = /obj/item/clothing/suit/toggle/jacket/flannel/aqua
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketflannelbrown
	name = "Brown flannel jacket"
	description = "Удобное и, по слухам, легковоспламеняющееся."
	path = /obj/item/clothing/suit/toggle/jacket/flannel/brown
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketflannelwhite
	name = "White flannel jacket"
	description = "Удобное и, по слухам, легковоспламеняющееся."
	path = /obj/item/clothing/suit/toggle/jacket/flannel/white
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/hawaiianshirtblack
	name = "Black hawaiian shirt"
	path = /obj/item/clothing/suit/toggle/jacket/hawaiian
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/hawaiianshirtfuch
	name = "Fuch hawaiian shirt"
	path = /obj/item/clothing/suit/toggle/jacket/hawaiian/fuch
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/hawaiianshirtvine
	name = "Vine hawaiian shirt"
	path = /obj/item/clothing/suit/toggle/jacket/hawaiian/vine
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/hawaiianshirtorange
	name = "Orange hawaiian shirt"
	path = /obj/item/clothing/suit/toggle/jacket/hawaiian/orange
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/hawaiianshirtmotu
	name = "Motu hawaiian shirt"
	path = /obj/item/clothing/suit/toggle/jacket/hawaiian/motu
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/hawaiianshirtvice
	name = "Vice hawaiian shirt"
	path = /obj/item/clothing/suit/toggle/jacket/hawaiian/vice
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketleather
	name = "Leather jacket"
	description = "Помпадур не включён."
	path = /obj/item/clothing/suit/jacket/leather
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/overcoatleather
	name = "Leather overcoat"
	description = "Чёрт возьми, славное пальто."
	path = /obj/item/clothing/suit/jacket/leather/overcoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketpuffer
	name = "Puffer jacket"
	description = "Толстая куртка с резиновой водостойкой оболочкой."
	path = /obj/item/clothing/suit/jacket/puffer
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/vestpuffer
	name = "Puffer vest"
	description = "Толстый жилет с резиновой водостойкой оболочкой."
	path = /obj/item/clothing/suit/jacket/puffer/vest
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketlettermanbrown
	name = "Brown letterman jacket"
	description = "Классическая коричневая куртка «letterman». Выглядит жарковато и тяжеловато."
	path = /obj/item/clothing/suit/jacket/letterman
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketlettermanred
	name = "Red letterman jacket"
	description = "Куртка «letterman» в больном красном цвете. Круто."
	path = /obj/item/clothing/suit/jacket/letterman_red
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketlettermanNT
	name = "Nanotrasen letterman jacket"
	description = "Синяя куртка «letterman» с гордым N NanoTrasen на спине. На бирке указано, что сделано в Космическом Китае."
	path = /obj/item/clothing/suit/jacket/letterman_nanotrasen
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/coat
	name = "Winter coat"
	description = "Тяжёлая куртка из «синтетического» меха."
	path = /obj/item/clothing/suit/hooded/wintercoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS

/datum/gear/suit/coat/aformal
	name = "Assistant's formal winter coat"
	description = "Чёрное зимнее пальто на пуговицах."
	path = /obj/item/clothing/suit/hooded/wintercoat/aformal

/datum/gear/suit/coat/runed
	name = "Runed winter coat"
	description = "Пыльное зимнее пальто на пуговицах в тонах забвения и пепла. Бегунок молнии выглядит как единственная капля крови."
	path = /obj/item/clothing/suit/hooded/wintercoat/narsie/fake

/datum/gear/suit/coat/brass
	name = "Brass winter coat"
	description = "Зимнее пальто на пуговицах с латунной отделкой. Вместо бегунка молнии — латунная шестерёнка с крошечной красной пластинкой вставкой."
	path = /obj/item/clothing/suit/hooded/wintercoat/ratvar/fake

/datum/gear/suit/whitehoodie
	name = "Soft hoodie"
	description = "Мягкий худи с биркой TailorCo."
	path = /obj/item/clothing/suit/toggle/jacket/whitehoodie
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketbluehoodie
	name = "Blue hoodie"
	description = "Мягкий синий худи с биркой TailorCo."
	path = /obj/item/clothing/suit/jacket/bluehoodie
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
/datum/gear/suit/jacketpurplehoodie
	name = "Purple hoodie"
	description = "Мягкий фиолетовый худи с биркой TailorCo."
	path = /obj/item/clothing/suit/jacket/purplehoodie
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketheartcoat
	name = "Heart coat"
	description = "Мягкое зимнее пальто с биркой TailorCo."
	path = /obj/item/clothing/suit/jacket/heartcoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketgothiccoat
	name = "Long black coat with cuffs"
	description = "Пальто сурового вида с биркой TailorCo."
	path = /obj/item/clothing/suit/jacket/gothiccoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketgothshirt
	name = "Black shirt with cuffs"
	description = "Чёрная рубашка с воротником и манжетами в готическом стиле. На бирке указан бренд TailorCo."
	path = /obj/item/clothing/suit/jacket/gothicshirt
	subcategory = LOADOUT_SUBCATEGORY_SUIT_GENERAL

/datum/gear/suit/jacketgothshirtcross
	name = "Black shirt with cross"
	description = "Чёрная рубашка с тонко вытканным крестом на спине. На бирке указан бренд TailorCo."
	path = /obj/item/clothing/suit/jacket/gothicshirtcross
	subcategory = LOADOUT_SUBCATEGORY_SUIT_GENERAL

/datum/gear/suit/gentlecoat
	name = "Grey coat"
	description = "Серое пальто с биркой TailorCo. Выглядит дорого."
	path = /obj/item/clothing/suit/jacket/gentlecoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS

/datum/gear/suit/greenjacket
	name = "Green outdoorsman jacket"
	description = "Зелёная куртка с биркой TailorCo. Выглядит дорого."
	path = /obj/item/clothing/suit/toggle/jacket/greenjacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/fancytrench
	name = "Grey trenchcoat"
	description = "Тренч по индивидуальному заказу с биркой TailorCo."
	path = /obj/item/clothing/suit/toggle/jacket/fancytrench
	subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS


/datum/gear/suit/coat/polycoat
	name = "Polychromic winter coat"
	description = "Тяжёлая куртка из «синтетического» меха."
	path = /obj/item/clothing/suit/hooded/wintercoat/polychromic
	cost = 2 //too many people with neon green coats is hard on the eyes // it's probably fine now
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#6A6964", "#C4B8A6", "#0000FF")

/datum/gear/suit/coat/wbreakpoly
	name = "Polychromic windbreaker"
	description = "Идеально для ветреных дней."
	path = /obj/item/clothing/suit/toggle/wbreakpoly/polychromic
	cost = 2
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#464F65", "#916035", "#474747")

/datum/gear/suit/coat/med
	name = "Medical winter coat"
	description = "Арктически-белое зимнее пальто с маленьким синим кадуцеем вместо бегунка молнии. Броско."
	path = /obj/item/clothing/suit/hooded/wintercoat/medical
	restricted_roles = list("Chief Medical Officer", "Medical Doctor") // Reserve it to Medical Doctors and their boss, the Chief Medical Officer

/datum/gear/suit/coat/paramedic
	name = "Paramedic winter coat"
	description = "Зимнее пальто с синими метками. Тёплое, но вряд ли защитит от биологических агентов. Для уютного врача в пути."
	path = /obj/item/clothing/suit/hooded/wintercoat/paramedic
	restricted_roles = list("Chief Medical Officer", "Paramedic") // Reserve it to Paramedics and their boss, the Chief Medical Officer

/datum/gear/suit/coat/robotics
	name = "Robotics winter coat"
	description = "Чёрное зимнее пальто с жутко крутым огненным роботизированным черепом вместо бегунка молнии. У этого — ярко-красные узоры и несколько бесполезных пуговиц."
	path = /obj/item/clothing/suit/hooded/wintercoat/robotics
	restricted_roles = list("Research Director", "Roboticist")

/datum/gear/suit/coat/sci
	name = "Science winter coat"
	description = "Белое зимнее пальто с устаревшей атомной моделью вместо бегунка молнии."
	path = /obj/item/clothing/suit/hooded/wintercoat/science
	restricted_roles = list("Research Director", "Scientist", "Roboticist") // Reserve it to the Science Departement

/datum/gear/suit/coat/eng
	name = "Engineering winter coat"
	description = "Удивительно тяжёлое жёлтое зимнее пальто со светоотражающими оранжевыми полосами. Для молнии — маленький гаечный ключ, а внутренний слой покрыт серебристо-нейлоновой смесью, устойчивой к радиации. Потому что ты этого стоишь."
	path = /obj/item/clothing/suit/hooded/wintercoat/engineering
	restricted_roles = list("Chief Engineer", "Station Engineer") // Reserve it to Station Engineers and their boss, the Chief Engineer

/datum/gear/suit/coat/eng/atmos
	name = "Atmospherics winter coat"
	description = "Жёлто-синее зимнее пальто. Бегунок молнии сделан в виде миниатюрной дыхательной маски."
	path = /obj/item/clothing/suit/hooded/wintercoat/engineering/atmos
	restricted_roles = list("Chief Engineer", "Atmospheric Technician") // Reserve it to Atmos Techs and their boss, the Chief Engineer

/datum/gear/suit/coat/hydro
	name = "Hydroponics winter coat"
	description = "Зелёно-синее зимнее пальто. Бегунок молнии выглядит как цветок розы Rosa Hesperrhodos — красивой розово-белой розы. Цвета абсолютно не сочетаются."
	path = /obj/item/clothing/suit/hooded/wintercoat/hydro
	restricted_roles = list("Head of Personnel", "Botanist") // Reserve it to Botanists and their boss, the Head of Personnel

/datum/gear/suit/coat/bar
	name = "Bar winter coat"
	description = "Нарядное зимнее пальто с жилетом и кричащим галстуком-бабочкой. Бегунок молнии — собственно галстук-бабочка."
	path = /obj/item/clothing/suit/hooded/wintercoat/bar
	restricted_roles = list("Bartender") // Reserve it to Bartenders and not the Head of Personnel because he doesnt deserve to look as fancy as them

/datum/gear/suit/coat/cargo
	name = "Cargo winter coat"
	description = "Бежево-серое зимнее пальто, у которого вместо бегунка молнии ящик. Оно наполняет тебя теплом яростной независимости."
	path = /obj/item/clothing/suit/hooded/wintercoat/cargo
	restricted_roles = list("Quartermaster", "Cargo Technician") // Reserve it to Cargo Techs and their boss, the Quartermaster

/datum/gear/suit/coat/miner
	name = "Mining winter coat"
	description = "Пыльное зимнее пальто на пуговицах. Бегунок молнии выглядит как крошечная кирка."
	path = /obj/item/clothing/suit/hooded/wintercoat/miner
	restricted_roles = list("Quartermaster", "Shaft Miner") // Reserve it to Miners and their boss, the Quartermaster

/datum/gear/suit/militaryjacket
	name = "Military Jacket"
	description = "Куртка из брезента в стиле классической американской военной формы. Выглядит прочной, но удобной."
	path = /obj/item/clothing/suit/jacket/miljacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/urbanjacket
	name = "Urban Jacket"
	description = "Куртка из брезента с меховой деталью на шее — стильно."
	path = /obj/item/clothing/suit/jacket/urbanjacket/polychromic
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#3B4B2E", "#CBBDAF", "#444444")

/datum/gear/suit/ianshirt
	name = "Ian Shirt"
	description = "Потёртая, удивительно удобная футболка с картинкой Иэна. Не скажешь, что в ней тебя будто обнимают, но почти так. Хороша для сна."
	path = /obj/item/clothing/suit/ianshirt

/datum/gear/suit/flakjack
	name = "Flak Jacket"
	description = "Ветхая куртка из «пуленепробиваемого» материала (спойлер: нет). Слабо пахнет напалмом."
	path = /obj/item/clothing/suit/flakjack
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS
	cost = 2

/datum/gear/suit/trekds9_coat
	name = "DS9 Overcoat (use uniform)"
	description = "Пальто, которое носили все офицеры 2380-х."
	path = /obj/item/clothing/suit/storage/trek/ds9
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "All, barring Service and Civilian"
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster",
							"Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Scientist", "Roboticist",
							"Atmospheric Technician","Station Engineer","Warden","Detective","Security Officer",
							"Cargo Technician", "Shaft Miner") //everyone who actually deserves a job.
//Federation jackets from movies
/datum/gear/suit/trekcmdcap
	name = "Fed (movie) uniform, Black"
	description = "Куртка-форма Объединённой Федерации. Переведи фазеры на «круто»."
	path = /obj/item/clothing/suit/storage/fluff/fedcoat/capt
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Captain","Head of Personnel")

/datum/gear/suit/trekcmdmov
	name = "Fed (movie) uniform, Red"
	description = "Куртка-форма Объединённой Федерации. Переведи фазеры на «круто»."
	path = /obj/item/clothing/suit/storage/fluff/fedcoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Heads of Staff and Security"
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Warden","Detective","Security Officer")

/datum/gear/suit/trekmedscimov
	name = "Fed (movie) uniform, Blue"
	description = "Куртка-форма Объединённой Федерации. Переведи фазеры на «круто»."
	path = /obj/item/clothing/suit/storage/fluff/fedcoat/medsci
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Medical and Science"
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist")

/datum/gear/suit/trekengmov
	name = "Fed (movie) uniform, Yellow"
	description = "Куртка-форма Объединённой Федерации. Переведи фазеры на «круто»."
	path = /obj/item/clothing/suit/storage/fluff/fedcoat/eng
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Engineering and Cargo"
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer","Cargo Technician", "Shaft Miner", "Quartermaster")

/datum/gear/suit/trekcmdcapmod
	name = "Fed (Modern) uniform, White"
	description = "Современная куртка-форма Объединённой Федерации."
	path = /obj/item/clothing/suit/storage/fluff/modernfedcoat
	restricted_roles = list("Captain","Head of Personnel")

/datum/gear/suit/trekcmdmod
	name = "Fed (Modern) uniform, Red"
	description = "Современная куртка-форма Объединённой Федерации."
	path = /obj/item/clothing/suit/storage/fluff/modernfedcoat/sec
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Heads of Staff and Security"
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Warden","Detective","Security Officer")

/datum/gear/suit/trekmedscimod
	name = "Fed (Modern) uniform, Blue"
	description = "Современная куртка-форма Объединённой Федерации."
	path = /obj/item/clothing/suit/storage/fluff/modernfedcoat/medsci
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Medical and Science"
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist")

/datum/gear/suit/trekengmod
	name = "Fed (Modern) uniform, Yellow"
	description = "Современная куртка-форма Объединённой Федерации."
	path = /obj/item/clothing/suit/storage/fluff/modernfedcoat/eng
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Engineering and Cargo"
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer","Cargo Technician", "Shaft Miner", "Quartermaster")

/datum/gear/suit/wy_expensive_fur_trenchcoat
	name = "Expensive trenchcoat"
	description = "Пальто, созданное для исследования враждебных планет. Исследуй новые миры со стилем!"
	path = /obj/item/clothing/suit/armor/wy_expensive_fur_trenchcoat
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Security and Vanguard Operative"
	restricted_roles = list("Detective", "Security Officer", "Warden", "Head of Security", "Vanguard Operative")

/datum/gear/suit/wy_expensive_fur_trenchcoat_alt
	name = "Expensive trenchcoat Alt"
	description = "Пальто, созданное для исследования враждебных планет. Исследуй новые миры со стилем!"
	path = /obj/item/clothing/suit/armor/wy_expensive_fur_trenchcoat_alt
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_desc = "Security and Vanguard Operative"
	restricted_roles = list("Detective", "Security Officer", "Warden", "Head of Security", "Vanguard Operative")

/datum/gear/suit/officer_armor
	name = "Officer’s Armor"
	description = "Комплект брони элитного офицера, созданный для защиты высокоприоритетного персонала."
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	path = /obj/item/clothing/suit/armor/vest/capcarapace/officer_armor
	restricted_desc = "Capitan, Head of Security and Nanotrasen Representative"
	restricted_roles = list("Captain", "Head of Security", "Nanotrasen Representative")

/datum/gear/suit/ppo_armor_strong_heavy
	name = "Heavy SPO Armor Set"
	description = "Усиленный комплект брони SPO, созданный для защиты колоний от ксеноновых угроз."
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	path = /obj/item/clothing/suit/armor/vest/capcarapace/ppo_armor_strong_heavy
	restricted_desc = "Capitan, Head of Security and Nanotrasen Representative"
	restricted_roles = list("Captain", "Head of Security", "Nanotrasen Representative")

/datum/gear/suit/christmascoatr
	name = "Red Christmas Coat"
	description = "Праздничное красное рождественское пальто! Пахнет леденцом «Candy Cane»!"
	path = /obj/item/clothing/suit/hooded/wintercoat/christmascoatr
	subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS

/datum/gear/suit/christmascoatg
	name = "Green Christmas Coat"
	description = "Праздничное зелёное рождественское пальто! Пахнет леденцом «Candy Cane»!"
	path = /obj/item/clothing/suit/hooded/wintercoat/christmascoatg
	subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS

/datum/gear/suit/christmascoatrg
	name = "Red and Green Christmas Coat"
	description = "Праздничное красно-зелёное рождественское пальто! Пахнет леденцом «Candy Cane»!"
	path = /obj/item/clothing/suit/hooded/wintercoat/christmascoatrg
	subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS

/datum/gear/suit/samurai
	name = "Samurai outfit"
	description = "Наряд традиционных японских воинов."
	path = /obj/item/clothing/suit/samurai

/datum/gear/suit/syndie_jacket
	name = "Cybertechnical Jacket"
	description = "Кибернетическая куртка для гражданских. Удобство, роскошь, технологии, жестокость!"
	path = /obj/item/clothing/suit/syndie_jacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/cropped_jacket_main
	name = "Cropped jacket"
	description = "Укороченная куртка."
	path = /obj/item/clothing/suit/toggle/cropped_jacket_main
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/shoulder_sweater
	name = "Off shoulder sweater"
	description = "Свитер с открытыми плечами."
	path = /obj/item/clothing/suit/shoulder_sweater
