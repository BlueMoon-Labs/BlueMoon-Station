/datum/gear/uniform/tunic
	name = "Tunic"
	description = "Простая туника."
	path = /obj/item/clothing/under/tunic

/datum/gear/uniform/raccveralls_alt
	name = "Loose Overalls"
	description = "Не такой уже тесный и точно не облегающий комбинезон."
	path = /obj/item/clothing/under/raccveralls_alt

/datum/gear/uniform/lumberjack
	name = "Lumberjack Outfit"
	description = "Хочется устроить геноцид деревьям."
	path = /obj/item/clothing/under/lumberjack

/datum/gear/uniform/halfsuit
	name = "Half Latex Catsuit"
	description = "Плотно облегающий наряд из латекса, покрывающий торс владельца."
	path = /obj/item/clothing/under/latex/half

/datum/gear/uniform/latex
	name = "Full Latex Catsuit"
	description = "Блестящая форма, плотно сидящая на коже."
	path = /obj/item/clothing/under/misc/latex_catsuit

/datum/gear/uniform/shorts/redwshort
	name = "Red workout short"
	description = "95% полиэстера, 5% спандекса!"
	path = /obj/item/clothing/under/shorts/redwshort

/datum/gear/uniform/shorts/yellowwshort
	name = "Yellow workout short"
	description = "95% полиэстера, 5% спандекса!"
	path = /obj/item/clothing/under/shorts/yellowwshort

/datum/gear/uniform/shorts/pinkwshort
	name = "Pink workout short"
	description = "95% полиэстера, 5% спандекса!"
	path = /obj/item/clothing/under/shorts/pinkwshort

/datum/gear/uniform/domina
	name = "Dominatrix Dress"
	description = "Это платье заставляет хотеть встать на четвереньки и просить ещё!"
	path = /obj/item/clothing/under/domina

/datum/gear/uniform/bluedress
	name = "Blue Royal Dress"
	description = "Это платье сшито из тончайшего синего шёлка и пахнет дорогими духами и маслами."
	path = /obj/item/clothing/under/bluedress

/datum/gear/uniform/performer
	name = "Performers one piece"
	description = "От этого наряда слегка пахнет спермой и смазкой."
	path = /obj/item/clothing/under/performer

/datum/gear/uniform/lewdmaid
	name = "Lewd maid uniform"
	description = "Для всех ваших похотливых нужд горничной."
	path = /obj/item/clothing/under/lewdmaid

/datum/gear/uniform/blutigen_undergarment
	name = "Blutigen Undergarments"
	description = "Едва прикроет грудь и пах."
	path = /obj/item/clothing/under/blutigen_undergarment

/datum/gear/uniform/blackstripper
	name = "Black stripper outfit"
	path = /obj/item/clothing/under/misc/stripper/black

/datum/gear/uniform/whitestripper
	name = "White stripper outfit"
	path = /obj/item/clothing/under/misc/stripper/white

// Suggestion #151
/datum/gear/uniform/waiter
	name = "waiter's outfit"
	description = "Очень солидная форма со специальным карманом для чаевых."
	path = /obj/item/clothing/under/suit/waiter

// Suggestion #3278
/datum/gear/uniform/amish
	name = "Amish suit"
	description = "Очень похожий на амишский костюм."
	path = /obj/item/clothing/under/suit/sl

/datum/gear/uniform/bunnysuit
	name = "bunny outfit"
	description = "Простой чёрный костюм кролика."
	path = /obj/item/clothing/under/bunnysuit

/datum/gear/uniform/bunnysuitwhite
	name = "white bunny outfit"
	description = "Простой белый костюм кролика."
	path = /obj/item/clothing/under/bunnysuit/white

/datum/gear/uniform/raccveralls
	name = "form fitting overalls"
	description = "Плотно облегающий комбинезон."
	path = /obj/item/clothing/under/raccveralls

/datum/gear/uniform/sexyoffice
	name = "Revealing office uniform"
	description = "Сексуальная офисная форма с низким вырезом спереди, чтобы показать грудь или бюстгальтер. И высокое платье, прикрывающее живот, с набором пуговиц."
	path = /obj/item/clothing/under/officesexy

/datum/gear/uniform/vaultsuit
	name = "vault suit"
	description = "Плотно облегающий стандартный комбинезон Vault-Tec! Броско!"
	path = /obj/item/clothing/under/vaultsuit

// Updates restrictions to accomodate new jobs (mostly trekkie stuff)
/datum/gear/uniform/grey/sec
description = "Скучная серая форма."
	restricted_roles = list("Detective", "Security Officer", "Warden", "Head of Security", "Brig Physician")

/datum/gear/uniform/grey/med
description = "Скучная серая форма."
	restricted_roles = list("Medical Doctor", "Virologist", "Chemist", "Geneticist", "Paramedic", "Brig Physician")

/datum/gear/uniform/grey/com
description = "Скучная серая форма."
	restricted_roles = list("Quartermaster", "Research Director", "Chief Medical Officer", "Head Of Security", "Head Of Personnel","Bridge Officer", "Captain", "Blueshield", "Bridge Officer")

/datum/gear/uniform/trekcmdtos
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Bridge Officer")

/datum/gear/uniform/trekmedscitos
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist", "Brig Physician")

/datum/gear/uniform/trekengtos
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer","Warden","Detective","Security Officer","Brig Physician","Head of Security","Blueshield","Cargo Technician", "Shaft Miner", "Quartermaster")

/datum/gear/uniform/trekcmdtng
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Bridge Officer")

/datum/gear/uniform/trekmedscitng
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist", "Brig Physician")

/datum/gear/uniform/trekengtng
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer","Warden","Detective","Security Officer","Brig Physician","Head of Security","Blueshield","Cargo Technician", "Shaft Miner", "Quartermaster")

/datum/gear/uniform/trekcmdvoy
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Bridge Officer")

/datum/gear/uniform/trekmedscivoy
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist", "Brig Physician")

/datum/gear/uniform/trekengvoy
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer","Warden","Detective","Security Officer","Brig Physician","Head of Security","Blueshield","Cargo Technician", "Shaft Miner", "Quartermaster")

/datum/gear/uniform/trekcmdds9
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Bridge Officer")

/datum/gear/uniform/trekmedscids9
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist", "Brig Physician")

/datum/gear/uniform/trekengds9
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer","Warden","Detective","Security Officer","Brig Physician","Head of Security","Blueshield","Cargo Technician", "Shaft Miner", "Quartermaster")

/datum/gear/uniform/trekcmdent
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Bridge Officer")

/datum/gear/uniform/trekmedscient
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist", "Brig Physician")

/datum/gear/uniform/trekengent
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer","Warden","Detective","Security Officer","Brig Physician","Head of Security","Blueshield","Cargo Technician", "Shaft Miner", "Quartermaster")

/datum/gear/uniform/trekfedutil
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Blueshield","Bridge Officer",
							"Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Scientist", "Roboticist",
							"Atmospheric Technician","Station Engineer","Warden","Detective","Security Officer","Brig Physician",
							"Cargo Technician", "Shaft Miner")

/datum/gear/uniform/orvcmd
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Bridge Officer")

/datum/gear/uniform/orvmedsci
	restricted_roles = list("Chief Medical Officer", "Medical Doctor", "Chemist", "Virologist", "Paramedic", "Geneticist", "Research Director", "Scientist", "Roboticist", "Brig Physician")

/datum/gear/uniform/orvsec
	restricted_roles = list("Warden", "Detective", "Security Officer", "Head of Security", "Brig Physician", "Blueshield")

// Polychrome GWTB
/datum/gear/uniform/gonercloth
	name = "polychromic trencher uniform"
	description = "Утилитарная форма с полихромными пятнами."
	path = /obj/item/clothing/under/goner/fake/poly
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#E6E6E6")

/datum/gear/uniform/leia_outfit
	name = "Princess Leia Outfit"
	description = "Цепь для эротического удушья вашего Хозяина не включена."
	path = /obj/item/clothing/under/misc/leia_outfit
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#C61818", "#D4AF37")

/datum/gear/uniform/performer/polychromic
	name = "Polychromic performers one piece"
	description = "От этого наряда слегка пахнет спермой и смазкой."
	path = /obj/item/clothing/under/performer/polychromic
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#ffffff")

/datum/gear/uniform/stripper/security
	name = "Security Stripper Outfit"
	description = "Это никак не может соответствовать дресс-коду, правда?"
	path = /obj/item/clothing/under/rank/security/stripper
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_roles = list("Security Officer", "Warden", "Head Of Security")

/datum/gear/uniform/stripper/explorer
	name = "Explorer Stripper Outfit"
	description = "Это никак не может соответствовать дресс-коду, правда?"
	path = /obj/item/clothing/under/rank/cargo/miner/lavaland/stripper
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_roles = list("Shaft Miner")

/datum/gear/uniform/suit/tuxedo
	name = "Tuxedo suit"
	description = "Парадный чёрный смокинг. Излучает класс."
	path = /obj/item/clothing/under/suit/tuxedo

/datum/gear/uniform/suit/tuxedo/carp
	name = "Carpskin suit"
	description = "Роскошный костюм, сшитый только из лучшей чешуи, — идеален для сомнительных сделок."
	path = /obj/item/clothing/under/suit/carpskin

/datum/gear/uniform/suit/pencil
	name = "Black Pencilskirt"
	description = "Чистая белая рубашка с плотно сидящей чёрной юбкой-карандашом."
	path = /obj/item/clothing/under/suit/pencil

/datum/gear/uniform/suit/pencil/black_really
	name = "Executive Pencilskirt"
	description = "Сглаженный костюм с плотно сидящей чёрной юбкой-карандашом."
	path = /obj/item/clothing/under/suit/pencil/black_really

/datum/gear/uniform/suit/pencil/charcoal
	name = "Charcoal Pencilskirt"
	description = "Чистая белая рубашка с плотно сидящей графитовой юбкой-карандашом."
	path = /obj/item/clothing/under/suit/pencil/charcoal

/datum/gear/uniform/suit/pencil/navy
	name = "Navy Pencilskirt"
	description = "Чистая белая рубашка с плотно сидящей тёмно-синей юбкой-карандашом."
	path = /obj/item/clothing/under/suit/pencil/navy

/datum/gear/uniform/suit/pencil/burgandy
	name = "Burgandy Pencilskirt"
	description = "Чистая белая рубашка с плотно сидящей бордово-красной юбкой-карандашом."
	path = /obj/item/clothing/under/suit/pencil/burgandy

/datum/gear/uniform/suit/pencil/checkered
	name = "Checkered Pencilskirt"
	description = "Чистая белая рубашка с плотно сидящей серой клетчатой юбкой-карандашом."
	path = /obj/item/clothing/under/suit/pencil/checkered

/datum/gear/uniform/suit/pencil/tan
	name = "Tan Pencilskirt"
	description = "Чистая белая рубашка с плотно сидящей бежевой юбкой-карандашом."
	path = /obj/item/clothing/under/suit/pencil/tan

/datum/gear/uniform/suit/pencil/green
	name = "Green Pencilskirt"
	description = "Чистая белая рубашка с плотно сидящей зелёной юбкой-карандашом."
	path = /obj/item/clothing/under/suit/pencil/green

/datum/gear/uniform/suit/executive_suit_alt
	name = "Wide-collared Executive Suit"
	description = "Парадный чёрный костюм с широко расстёгнутым воротником — для лучших сотрудников станции."
	path = /obj/item/clothing/under/suit/black_really_collared

/datum/gear/uniform/suit/executive_skirt_alt
	name = "Wide-collared Executive Suitskirt"
	description = "Парадный чёрный костюм с широко расстёгнутым воротником — для лучших сотрудников станции."
	path = /obj/item/clothing/under/suit/black_really_collared/skirt

/datum/gear/uniform/suit/inferno
	name = "Inferno Suit"
	description = "Достаточно стильно, чтобы произвести впечатление на дьявола."
	path = /obj/item/clothing/under/suit/inferno

/datum/gear/uniform/suit/inferno_skirt
	name = "Inferno Skirt"
	description = "Достаточно стильно, чтобы произвести впечатление на дьявола."
	path = /obj/item/clothing/under/suit/inferno/skirt

/datum/gear/uniform/suit/designer_inferno
	name = "Designer Inferno Suit"
	description = "Нарядный костюм с фраком и пушистым бантом на груди, с заколкой NT в комплекте."
	path = /obj/item/clothing/under/suit/inferno/beeze

/datum/gear/uniform/suit/helltaker
	name = "Red Shirt with White Trousers"
	description = "Некогда. Собираю девушек."
	path = /obj/item/clothing/under/suit/helltaker

/datum/gear/uniform/suit/helltaker/skirt
	name = "Red Shirt with White Skirt"
	description = "Некогда. Собираю парней."
	path = /obj/item/clothing/under/suit/helltaker/skirt

/datum/gear/uniform/suit/bm/skirt
	name = "Black Skirt with Ryodan Spider"
	path = /obj/item/clothing/under/bm/ryodan

/datum/gear/uniform/suit/clussy_outfit
	name = "Clussy outfit"
	description = "Форма для клоунов, которые обожают, когда им гудят в рожок."
	path = /obj/item/clothing/under/rank/civilian/clown/clussy_outfit
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_roles = list("Clown")
	restricted_desc = "Clown"

//BM add
/datum/gear/uniform/syndiemaid/civil
    name = "Tactical Maid Outfit"
    description = "«Тактическая» юбка-водолазка, сделанная под подобие формы горничной. Зачем у Синдиката такое — тебе никогда не узнать."
    path = /obj/item/clothing/under/syndicate/maid/civil

/datum/gear/uniform/syndiecombat/civil
    name = "combat uniform"
    description = "С костюмом, подшитым таким количеством карманов, ты готов к работе."
    path = /obj/item/clothing/under/syndicate/combat/civil

/datum/gear/uniform/syndiecamo/civil
    name = "camouflage fatigues"
    description = "Зелёная военная форма с камуфляжем."
    path = /obj/item/clothing/under/syndicate/camo/civil

/datum/gear/uniform/sneaksuit/civil
    name = "blood-red sneaksuit"
    description = "Коварный бронированный комбинезон, подшитый нанофибрами Синдиката и прототипными пластинами; слегка устойчив к большинству типов урона, но слишком громоздкий, чтобы что-то к нему крепить. Всё равно считается stealth, если нет свидетелей."
    path = /obj/item/clothing/under/syndicate/bloodred/civil

/datum/gear/uniform/syndiesniper/civil
    name = "Tactical suit"
    description = "Двойная прострочка тактического обмундирования, замаскированная под гражданский шёлковый костюм. Для самого парадного оперативника. Воротник реально острый."
    path = /obj/item/clothing/under/syndicate/sniper/civil
    subcategory = LOADOUT_SUBCATEGORY_UNIFORM_SUITS

/datum/gear/uniform/syndieoveralls/civil
    name = "Utility Overalls Turtleneck"
    description = "Пара нарядных комбинезонов с водолазкой внизу — одинаково полезны и в инженерии, и в ботанике."
    path = /obj/item/clothing/under/syndicate/overalls/civil

/datum/gear/uniform/syndieoveralls/skirt/civil
    name = "Utility Overalls Skirtleneck"
    description = "Пара нарядных комбинезонов с водолазкой внизу, только вместо брюк юбка — дышится легко."
    path = /obj/item/clothing/under/syndicate/overalls/skirt/civil

/datum/gear/uniform/tactical/civil
    name = "tactical turtleneck"
    description = "Неприметная и слегка подозрительная водолазка с цифровым камуфляжом и грузовыми брюками."
    path = /obj/item/clothing/under/syndicate/civil

/datum/gear/uniform/tactical/skirt/civil
    name = "tactical skirtleneck"
    description = "Неприметная и слегка подозрительная юбка-водолазка."
    path = /obj/item/clothing/under/syndicate/skirt/civil

//BM add end
// Vore station import/improvement

/datum/gear/uniform/wench
	name = "Wench's Dress"
	description = "Белое платье в стиле «старой доброй барменши». Пикантно!"
	path = /obj/item/clothing/under/misc/wench
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_DRESSES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#ffffff", "#242424", "96710f")

/datum/gear/uniform/tian_dress
	name = "Tian Dress"
	description = "Простое плотно сидящее фиолетовое платье."
	path = /obj/item/clothing/under/misc/tian_dress
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_DRESSES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#7c1649", "#006cec")

/datum/gear/uniform/vneck
	name = "V-neck Dress"
	description = "Чёрное платье с V-образным вырезом с преувеличенной линией горловины, покрытое прозрачной сеткой."
	path = /obj/item/clothing/under/misc/vneck
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_DRESSES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#1c1c1c")

/datum/gear/uniform/revealingdress
	name = "Revealing Dress"
	description = "Очень откровенное полихромное платье. Уместно ли это на работе?"
	path = /obj/item/clothing/under/misc/revealingdress
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_DRESSES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#211919", "#4ce2ff")

/datum/gear/uniform/rippedpunk
	name = "Ripped Punk"
	description = "Рваные чёрные джинсы и сетчатый топ. Как панк."
	path = /obj/item/clothing/under/misc/rippedpunk
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_GENERAL
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#211919", "#4ce2ff")

/datum/gear/uniform/gothic
	name = "gothic dress"
	description = "Полихромное платье с прозрачной сеткой сверху — со вкусом старомодный гот."
	path = /obj/item/clothing/under/misc/gothic
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_DRESSES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#232323", "#232323", "#232323", "#232323")

/datum/gear/uniform/pentagram
	name = "pentagram dress"
	description = "Полихромное платье с бретелями на груди в форме пентаграммы."
	path = /obj/item/clothing/under/misc/pentagram
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_DRESSES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#211919", "#232323")

/datum/gear/uniform/swoop
	name = "swooped dress"
	description = "Полихромное платье, спадающее на бок."
	path = /obj/item/clothing/under/misc/swoop
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_DRESSES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#f2ce66", "#272525")

/datum/gear/uniform/asym
	name = "asymmetrical slit skirt"
	description = "Футуристичная форма с асимметричной юбкой с разрезом. Модно!"
	path = /obj/item/clothing/under/misc/asym
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_DRESSES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#8abe67", "#8abe67")

/datum/gear/uniform/sheer
	name = "sheer dress"
	description = "Платье полностью из прозрачной ткани. Лучше всего носить вообще без ничего!"
	path = /obj/item/clothing/under/misc/sheer
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_DRESSES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#3e769c")

/datum/gear/uniform/corsetdress
	name = "corset dress"
	description = "Полихромное платье с корсетом — реально делает девушек «объёмнее»."
	path = /obj/item/clothing/under/misc/corsetdress
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_DRESSES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#1e1b1e", "#f6efdb", "#4b6c5a", "#d4ccb3")

/datum/gear/uniform/miniskirt_sheer
	name = "fashionable sheer miniskirt"
	description = "Непрактично короткая мини-юбка, но можно ли это вообще назвать одеждой?"
	path = /obj/item/clothing/under/misc/miniskirt_sheer
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_SKIRTS
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#0e0e0e")

/datum/gear/uniform/miniskirt
	name = "fashionable miniskirt"
	description = "Непрактично короткая мини-юбка, которая, по слухам, поднимает волну в местной модной сцене."
	path = /obj/item/clothing/under/misc/miniskirt
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_SKIRTS
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#0e0e0e")
