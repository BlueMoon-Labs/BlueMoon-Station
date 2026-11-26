/datum/gear/head
	category = LOADOUT_CATEGORY_HEAD
	subcategory = LOADOUT_SUBCATEGORY_HEAD_GENERAL
	slot = ITEM_SLOT_HEAD

/datum/gear/head/baseball
	name = "Ballcap"
	description = "Бейсболка в безвкусно-белом цвете."
	path = /obj/item/clothing/head/soft/mime

/datum/gear/head/beanie
	name = "Beanie"
	path = /obj/item/clothing/head/beanie

/datum/gear/head/empire_head
	name = "Katzen Helmet"
	path = /obj/item/clothing/head/empire_head
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#2A2A2A","#e4b829")

/datum/gear/head/campaignhat
	name = "Sheriff Department's Campaign Hat"
	description = "Парадная широкополая шляпа местного шерифа с его эмблемой. Обычно её носят шериф и его подчинённые."
	path = /obj/item/clothing/head/warden/campaignhat
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Security"
	restricted_roles = list("Head of Security", "Warden", "Security Officer")

/datum/gear/head/beret
	name = "Black beret"
	description = "Чёрный берет — идеален для ветеранов войны и мрачных задумчивых мимов-антигероев."
	path = /obj/item/clothing/head/beret/black

/datum/gear/head/beret/paramedic
	name = "Paramedic beret"
	description = "Для стильного поиска трупов!"
	path = /obj/item/clothing/head/beret/medical/paramedic

/datum/gear/head/redberet
	name = "Red beret"
	description = "Берет — любимая шапка мима."
	path = /obj/item/clothing/head/beret

/datum/gear/head/purpleberet
	name = "Purple beret"
	description = "Фиолетовый берет."
	path = /obj/item/clothing/head/beret/purple

/datum/gear/head/blueberet
	name = "Blue beret"
	description = "Синий берет."
	path = /obj/item/clothing/head/beret/blue

/datum/gear/head/flatcap
	name = "Flat cap"
	description = "Шапка рабочего человека."
	path = /obj/item/clothing/head/flatcap

/datum/gear/head/pirate
	name = "Pirate hat"
	description = "Йарр."
	path = /obj/item/clothing/head/pirate

/datum/gear/head/rice_hat
	name = "Rice hat"
	description = "Добро пожаловать на рисовые поля, мать твою."
	path = /obj/item/clothing/head/rice_hat

/datum/gear/head/ushanka
	name = "Ushanka"
	description = "Идеально для сибирской зимы, да?"
	path = /obj/item/clothing/head/ushanka

/datum/gear/head/ushanka/soviet
	name = "Soviet Ushanka"
	description = "Идеально для сибирской зимы, да?"
	path = /obj/item/clothing/head/ushanka

/datum/gear/head/slime
	name = "Slime hat"
	description = "Оно просто защёлкивается на месте!"
	path = /obj/item/clothing/head/collectable/slime

/datum/gear/head/fedora
	name = "Fedora"
	description = "Очень крутая шляпа, если ты гангстер. Очень унылая, если нет."
	path = /obj/item/clothing/head/fedora

/datum/gear/head/that
	name = "Top Hat"
	description = "Похожа на шляпу амиша."
	path = /obj/item/clothing/head/that

/datum/gear/head/maidband
	name = "Maid headband"
	description = "Сделано в Китае."
	path= /obj/item/clothing/head/maid

/datum/gear/head/maidband/poly
	name = "Polychromic maid headband"
	description = "Сделано в Китае."
	path= /obj/item/clothing/head/maid/polychromic
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#333333", "#FFFFFF")
	item_icon_state = "maid" // BLUEMOON EDIT - багованная иконка

/datum/gear/head/bunnyears
	name = "Bunny Ears"
	description = "Носишь это — и выглядишь бесполезным, годным разве что своей сексуальностью."
	path = /obj/item/clothing/head/rabbitears

/datum/gear/head/mailmanhat
	name = "Mailman's Hat"
	description = "Головной убор почтовой службы «<i>Точно-в-срок</i>»."
	path = /obj/item/clothing/head/mailman

//trek fancy Hats!
/datum/gear/head/trekcap
	name = "Federation Officer's Cap (White)"
	description = "Офицерская фуражка, требующая дисциплины от того, кто её носит."
	path = /obj/item/clothing/head/caphat/formal/fedcover
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_roles = list("Captain","Head of Personnel")

/datum/gear/head/trekcapcap
	name = "Federation Officer's Cap (Black)"
	description = "Офицерская фуражка, требующая дисциплины от того, кто её носит."
	path = /obj/item/clothing/head/caphat/formal/fedcover/black
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_roles = list("Captain","Head of Personnel")

/datum/gear/head/trekcapmedisci
	name = "Federation Officer's Cap (Blue)"
	description = "Офицерская фуражка, требующая дисциплины от того, кто её носит."
	path = /obj/item/clothing/head/caphat/formal/fedcover/medsci
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Medical and Science"
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist")

/datum/gear/head/trekcapeng
	name = "Federation Officer's Cap (Yellow)"
	description = "Офицерская фуражка, требующая дисциплины от того, кто её носит."
	path = /obj/item/clothing/head/caphat/formal/fedcover/eng
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Engineering, Security, and Cargo"
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer","Warden","Detective","Security Officer","Head of Security","Cargo Technician", "Shaft Miner", "Quartermaster")

/datum/gear/head/trekcapsec
	name = "Federation Officer's Cap (Red)"
	description = "Офицерская фуражка, требующая дисциплины от того, кто её носит."
	path = /obj/item/clothing/head/caphat/formal/fedcover/sec
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Engineering, Security, and Cargo"
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer","Warden","Detective","Security Officer","Head of Security","Cargo Technician", "Shaft Miner", "Quartermaster")

// orvilike "original" kepi
/datum/gear/head/orvkepicom
	name = "Federation Kepi, command"
	description = "Фуражка с козырьком. Предназначена для формы ORV."
	path = /obj/item/clothing/head/kepi/orvi/command
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Heads of Staff"
	restricted_roles = list("Head of Security","Bridge Officer", "Captain", "Head of Personnel", "Chief Engineer", "Research Director", "Chief Medical Officer", "Quartermaster")

/datum/gear/head/orvkepieng
	name = "Federation Kepi, eng"
	description = "Фуражка с козырьком. Предназначена для формы ORV."
	path = /obj/item/clothing/head/kepi/orvi/eng
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Engineering"
	restricted_roles = list("Chief Engineer", "Atmospheric Technician", "Station Engineer")

/datum/gear/head/orvkepisec
	name = "Federation Kepi, sec"
	description = "Фуражка с козырьком. Предназначена для формы ORV."
	path = /obj/item/clothing/head/kepi/orvi/sec
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Security"
	restricted_roles = list("Warden", "Detective", "Security Officer", "Head of Security")

/datum/gear/head/sallet
	name = "Helmet with visor"
	description = "Стандартный шлем с защитным козырьком. Когда девушки хотят сохранить лицо!"
	path = /obj/item/clothing/head/helmet/sec/sallet
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Security"
	restricted_roles = list("Warden", "Detective", "Security Officer", "Head of Security")

/datum/gear/head/officer_hat
	name = "Officer’s beret"
	description = "Хочешь выделиться из толпы? Сними этот берет с трупа офицера!"
	path = /obj/item/clothing/head/helmet/sec/officer_hat
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Capitan, Head of Security and Nanotrasen Representative"
	restricted_roles = list("Captain", "Head of Security", "Nanotrasen Representative")

/datum/gear/head/orvkepimedsci
	name = "Federation Kepi, medsci"
	description = "Фуражка с козырьком. Предназначена для формы ORV."
	path = /obj/item/clothing/head/kepi/orvi/medsci
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Medical and Science"
	restricted_roles = list("Chief Medical Officer", "Medical Doctor", "Chemist", "Virologist", "Paramedic", "Geneticist", "Research Director", "Scientist", "Roboticist")

/datum/gear/head/orvkepisrv
	name = "Federation Kepi, service"
	description = "Фуражка с козырьком. Предназначена для формы ORV."
	path = /obj/item/clothing/head/kepi/orvi/service
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Service, Cargo and Civilian, barring Clown, Mime and Internal Affairs Agent"
	restricted_roles = list("Bartender", "Botanist", "Cook", "Curator", "Janitor", "Chaplain", "Cargo Technician", "Shaft Miner")

/datum/gear/head/orvkepiass
	name = "Federation Kepi, assistant"
	description = "Фуражка с козырьком. Предназначена для формы ORV."
	path = /obj/item/clothing/head/kepi/orvi
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_roles = list("Assistant", "Stowaway")

/datum/gear/head/santahatr
	name = "Red Santa Hat"
	description = "Красная рождественская шапка! Как празднично!"
	path = /obj/item/clothing/head/christmashat

/datum/gear/head/santahatg
	name = "Green Santa Hat"
	description = "Зелёная рождественская шапка! Как празднично!"
	path = /obj/item/clothing/head/christmashatg

//Cowboy Stuff
/datum/gear/head/cowboyhat
	name = "Cowboy Hat, Brown"
	description = "Обычная коричневая ковбойская шляпа, йи-хау."
	path = /obj/item/clothing/head/cowboyhat

/datum/gear/head/cowboyhat/black
	name = "Cowboy Hat, Black"
	description = "Чёрная ковбойская шляпа — идеальна для любого выводка."
	path = /obj/item/clothing/head/cowboyhat/black

/datum/gear/head/cowboyhat/white
	name = "Cowboy Hat, White"
	description = "Белая ковбойская шляпа — идеальна для фермера каждый день."
	path = /obj/item/clothing/head/cowboyhat/white

/datum/gear/head/cowboyhat/pink
	name = "Cowboy Hat, Pink"
	description = "Розовая ковбойская шляпа? Скорее ковгёрл — только не будь «застёжным кроликом»."
	path = /obj/item/clothing/head/cowboyhat/pink

/datum/gear/head/cowboyhat/sec
	name = "Cowboy Hat, Security"
	description = "Ковбойская шляпа охранника — идеальна для любого настоящего законника."
	path = /obj/item/clothing/head/cowboyhat/sec
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_desc = "Security"
	restricted_roles = list("Warden","Detective","Security Officer","Head of Security")

/datum/gear/head/cowboyhat/polychromic
	name = "Cowboy Hat, Polychromic"
	description = "Полихромная ковбойская шляпа — идеальна для нерешительного фермера."
	path = /obj/item/clothing/head/cowboyhat/polychromic
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#5F5F5F", "#DDDDDD")
	item_icon_state = "cowboyhat" // BLUEMOON EDIT - багованная иконка

/datum/gear/head/wkepi
	name = "white kepi"
	description = "Белая фуражка с козырьком. Уи-уи, mon capitane!"
	path = /obj/item/clothing/head/kepi

/datum/gear/head/widered
	name = "Wide red hat"
	description = "И широкая, и красная. Стильно!"
	path = /obj/item/clothing/head/widered

/datum/gear/head/kabuto
	name = "Kabuto helmet"
	description = "Традиционный шлем кабуто."
	path = /obj/item/clothing/head/kabuto

/datum/gear/head/maid_headband
	name = "Tactical Maid Headband"
	description = "Тактикутя."
	path = /obj/item/clothing/head/maid/syndicate

/datum/gear/head/
	name = "Tactical Maid Headband"
	description = "Тактикутя."
	path = /obj/item/clothing/head/maid/syndicate

/datum/gear/head/geraniumcrown
	name = "Geranium Crown"
	description = "Венок из множества ярко-фиолетовых гераней."
	path = /obj/item/clothing/head/geranium_crown

/datum/gear/head/lilycrown
	name = "Lily Crown"
	description = "Лиственный венок с пучком крупных белых лилий спереди."
	path = /obj/item/clothing/head/lily_crown

/datum/gear/head/poppycrown
	name = "Poppy Crown"
	description = "Венок, сплетенный из ярко-красных маков."
	path = /obj/item/clothing/head/poppy_crown

/datum/gear/head/sunflowercrown
	name = "Sunflower Crown"
	description = "Яркий венок из подсолнухов, который обязательно поднимет настроение любому!"
	path = /obj/item/clothing/head/sunflower_crown

/datum/gear/head/flowercrown
	name = "Flower Crown"
	description = "Разноцветный венок из лилий, подсолнухов и маков."
	path = /obj/item/clothing/head/flower_crown
