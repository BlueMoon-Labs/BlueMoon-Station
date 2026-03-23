
/*
	Uplink Items:
	Unlike categories, uplink item entries are automatically sorted alphabetically on server init in a global list,
	When adding new entries to the file, please keep them sorted by category.
*/

// Devices and Tools

/datum/uplink_item/device_tools/emag
	name = "Cryptographic Sequencer"
	desc = "Криптографический секвенсор, электромагнитная карта, он же имаг — небольшая карточка, \
			которая разблокирует скрытые функции электронных устройств, подрывает их функции и легко ломает защитные механизмы."
	item = /obj/item/card/emag
	cost = 6

/datum/uplink_item/device_tools/emagrecharge
	name = "Electromagnet Charging Device"
	desc = "Небольшое устройство для подзарядки криптографических секвенсоров. При использовании добавляет пять дополнительных зарядов."
	item = /obj/item/emagrecharge
	cost = 2

/datum/uplink_item/device_tools/bluespacerecharge
	name = "Bluespace Crystal Recharging Device"
	desc = "Небольшое устройство для подзарядки ботинок блюспейс-ходьбы. Добавляет шесть зарядов. Используйте десять блюспейс-кристаллов на заряднике, чтобы добавить ещё три заряда."
	item = /obj/item/bluespacerecharge
	cost = 2

/datum/uplink_item/device_tools/phantomthief
	name = "Adrenaline Mask"
	desc = "Дешёвая пластиковая маска со встроенным адреналиновым автоинъектором, который активируется простым напряжением мышц."
	item = /obj/item/clothing/glasses/phantomthief/syndicate
	cost = 2

/datum/uplink_item/device_tools/cutouts
	name = "Adaptive Cardboard Cutouts"
	desc = "Картонные фигуры, покрытые тонким материалом, предотвращающим выцветание и делающим изображения реалистичными. \
			В наборе три штуки и карандаш для смены внешнего вида."
	item = /obj/item/storage/box/syndie_kit/cutouts
	cost = 1
	surplus = 20

/datum/uplink_item/device_tools/assault_pod
	name = "Assault Pod Targeting Device"
	desc = "Используйте, чтобы выбрать зону посадки вашего штурмового пода."
	item = /obj/item/assault_pod
	cost = 30
	surplus = 0
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS
	restricted = TRUE

/datum/uplink_item/device_tools/binary
	name = "Binary Translator Key"
	desc = "Ключ шифрования, который при установке в гарнитуру позволяет слушать и говорить \
			с кремниевыми формами жизни, такими как ИИ и киборги, по их приватному бинарному каналу. \
			Осторожно: если они не на вашей стороне, то запрограммированы сообщать о таких вторжениях."
	item = /obj/item/encryptionkey/binary
	cost = 2
	surplus = 75
	restricted = TRUE

/datum/uplink_item/device_tools/magboots
	name = "Blood-Red Magboots"
	desc = "Магнитные ботинки с красноватой покраской для свободного передвижения в космосе или на станции \
			при отключении гравитации. Эти реверс-инжениринговые копии магботинок Nanotrasen \
			замедляют вас в условиях искусственной гравитации, как и стандартные."
	item = /obj/item/clothing/shoes/magboots/syndie
	cost = 2
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/device_tools/magboots/advance
	name = "Advanced Blood-Red Magboots"
	desc = "Магнитные ботинки с покраской Syndicate для передвижения в космосе и на станции при отключении гравитации. \
	Эти реверс-инжениринговые копии магботинок Nanotrasen НЕ замедляют вас и защищают от скольжения на космосмазке."
	item = /obj/item/clothing/shoes/magboots/syndie/advance
	cost = 6
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/device_tools/compressionkit
	name = "Bluespace Compression Kit"
	desc = "Модифицированная версия BSRPED, может уменьшать размер большинства предметов, сохраняя их функции! \
			Не работает на контейнерах для хранения. \
			Перезарядка через блюспейс-кристаллы. \
			5 зарядов в комплекте."
	item = /obj/item/compressionkit
	cost = 5

/datum/uplink_item/device_tools/briefcase_launchpad
	name = "Briefcase Launchpad"
	desc = "Дипломат с телепортационной платформой, способной телепортировать предметы и людей на расстояние до 20 тайлов. \
			В комплекте пульт управления, замаскированный под обычную папку. Прикосните пульт к дипломату для привязки."
	surplus = 0
	item = /obj/item/storage/briefcase/launchpad
	cost = 6

/datum/uplink_item/device_tools/camera_bug
	name = "Camera Bug"
	desc = "Позволяет просматривать все камеры основной сети, настраивать оповещения о движении и отслеживать цель. \
			Взлом камер позволяет отключать их удалённо."
	item = /obj/item/camera_bug
	cost = 1
	surplus = 90

/datum/uplink_item/device_tools/military_belt
	name = "Chest Rig"
	desc = "Крепкая разгрузка на семь слотов, способная вместить всевозможное тактическое снаряжение."
	item = /obj/item/storage/belt/military
	cost = 1
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/device_tools/military_belt/inteq
	item = /obj/item/storage/belt/military/inteq
	purchasable_from = UPLINK_TRAITORS

/datum/uplink_item/device_tools/ammo_pouch
	name = "Ammo Pouch"
	desc = "Небольшой, но достаточно вместительный подсумок, влезающий в карман. Вмещает три магазина."
	item = /obj/item/storage/bag/ammo
	cost = 1

/datum/uplink_item/device_tools/fakenucleardisk
	name = "Decoy Nuclear Authentication Disk"
	desc = "Обычный диск. Визуально идентичен настоящему, но при близком рассмотрении Капитаном не выдержит проверку. \
			Даже не пытайтесь сдать его нам для выполнения задания — мы не настолько тупые!"
	item = /obj/item/disk/nuclear/fake
	cost = 1
	surplus = 1

/datum/uplink_item/device_tools/frame
	name = "F.R.A.M.E. PDA Cartridge"
	desc = "При установке в КПК этот картридж даёт пять PDA-вирусов, которые \
			превращают целевой КПК в новый аплинк с нулём TC, мгновенно разблокированный. \
			Код разблокировки придёт при активации вируса, а новый аплинк можно пополнять \
			телекристаллами как обычно."
	item = /obj/item/cartridge/virus/frame
	cost = 2
	restricted = TRUE

/datum/uplink_item/device_tools/toolbox
	name = "Full Illegal Toolbox"
	desc = "Подозрительный чёрно-красный ящик с инструментами. Включает полный набор вместе с \
			мультитулом и боевыми перчатками, устойчивыми к ударам током и жаром."
	item = /obj/item/storage/toolbox/syndicate
	purchasable_from = UPLINK_SYNDICATE
	cost = 1

/datum/uplink_item/device_tools/tools_inteq
	name = "Brown toolbox"
	desc = "Набор базовых инструментов."
	item = /obj/item/storage/toolbox/inteq
	cost = 1
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/device_tools/tools_inteq_coller
	name = "Deluxe Brown toolbox"
	desc = "Улучшеный набор инструментов. Для тех, кто знает себе цену"
	item = /obj/item/storage/toolbox/inteq/cooler
	cost = 3
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/device_tools/syndie_glue
	name = "Glue"
	desc = "Дешёвый тюбик одноразового суперклея марки Syndicate. \
			Примените к любому предмету, чтобы сделать его невыбрасываемым. \
			Осторожно — не приклейте то, что уже держите в руках!"
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)
	item = /obj/item/syndie_glue
	cost = 2

/datum/uplink_item/device_tools/hacked_module
	name = "Hacked AI Law Upload Module"
	desc = "При использовании с консолью загрузки этот модуль позволяет заливать приоритетные законы в ИИ. \
			Будьте осторожны с формулировками — ИИ обожают искать лазейки."
	item = /obj/item/ai_module/syndicate
	cost = 9

/datum/uplink_item/device_tools/damaged_module
	name = "Damaged AI Law Upload Module"
	desc = "Этот модуль загрузки законов ИИ валялся на нашем складе хрен знает сколько. Мы понятия не имеем, зачем вам это."
	item = /obj/item/ai_module/core/full/damaged
	cost = 5

///datum/uplink_item/device_tools/headsetupgrade
// 	name = "Headset Upgrader"
// 	desc = "A device that can be used to make one headset immune to flashbangs."
// 	item = /obj/item/headsetupgrader
// 	cost = 1

/datum/uplink_item/device_tools/medgun
	name = "Medbeam Gun"
	desc = "Чудо инженерии Syndicate. Медпушка позволяет медику держать союзников \
			в строю даже под огнём. Не скрещивайте лучи!"
	item = /obj/item/gun/medbeam
	cost = 15
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/device_tools/nutcracker
	name = "Nutcracker"
	desc = "Увеличенная версия того, что вы себе представили. Достаточно большой, чтобы давить черепа."
	item = /obj/item/nutcracker
	cost = 1

/datum/uplink_item/device_tools/singularity_beacon
	name = "Power Beacon"
	desc = "При прикручивании к проводке под напряжением и активации это устройство притягивает \
			активные гравитационные сингулярности или шары Теслы (если они не в контейнменте), \
			а также повышает шансы метеоритных волн. \
			Из-за размера его нельзя носить. При заказе вы получите маленький маяк, \
			который телепортирует большой маяк к вам при активации."
	item = /obj/item/sbeacondrop
	cost = 14

/datum/uplink_item/device_tools/powersink
	name = "Power Sink"
	desc = "При прикручивании к проводке под напряжением и активации это устройство создаёт чрезмерную \
			нагрузку на сеть, вызывая блэкаут по всей станции. Устройство громоздкое и не влезет \
			в большинство сумок. Осторожно: взорвётся, если в сети слишком много энергии."
	item = /obj/item/powersink
	cost = 6

/datum/uplink_item/device_tools/rad_laser
	name = "Radioactive Microlaser"
	desc = "Радиоактивный микролазер, замаскированный под стандартный анализатор здоровья Nanotrasen. \
			При использовании выпускает мощный всплеск радиации, который после небольшой задержки \
			вырубает почти любого. Два режима: интенсивность (сила облучения) \
			и длина волны (задержка эффекта)."
	item = /obj/item/healthanalyzer/rad_laser
	cost = 3

///datum/uplink_item/device_tools/shadowcloak
//	name = "Cloaker Belt"
//	desc = "Makes you invisible for short periods of time. Recharges in darkness."
//	item = /obj/item/shadowcloak
//	cost = 10
//	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/device_tools/riflery_primer
	name = "Riflery Primer"
	desc = "Старая книжка в пятнах крови и водки. Только что извлечена из пыльного ящика на старом складе. \
			По слухам, пятикратно ускоряет работу затвором и помпой. \
			Правда, техники работают только с болтовками и помповыми..."
	item = /obj/item/book/granter/trait/rifleman
	cost = 3 // fuck it available for everyone

/datum/uplink_item/device_tools/stimpack
	name = "Stimpack"
	desc = "Стимпаки, инструмент многих героев. После инъекции делает вас почти невосприимчивым \
			к нелетальному оружию на примерно 5 минут."
	item = /obj/item/reagent_containers/hypospray/medipen/stimulants
	cost = 5
	surplus = 90

/datum/uplink_item/device_tools/medkit
	name = "Сombat Medic Kit"
	desc = "Подозрительно коричнево-красная аптечка. Включает боевой стимулятор \
			для быстрого исцеления, медицинский ночной HUD для опознания раненых \
			и другие полезные припасы для полевого медика."
	item = /obj/item/storage/firstaid/tactical/nukeop
	cost = 4
	surplus = 75
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/device_tools/surgerybag
	name = "Illegal Surgery Duffel Bag"
	desc = "Нелегальная хирургическая сумка, содержащая все хирургические инструменты, операционные простыни, \
			краденый Syndicate ИММ, смирительную рубашку и намордник."
	item = /obj/item/storage/backpack/duffelbag/syndie/surgery
	cost = 1  ///bluemoon change
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/device_tools/surgerybag/inteq
	item = /obj/item/storage/backpack/duffelbag/syndie/inteq/surgery
	purchasable_from = ~UPLINK_SYNDICATE

/datum/uplink_item/device_tools/surgerybag_adv
	name = "Advanced Illegal Surgery Duffel Bag"
	desc = "Краденая хирургическая сумка Syndicate с набором улучшенных хирургических инструментов в придачу."
	item = /obj/item/storage/backpack/duffelbag/syndie/surgery_adv
	cost = 3  ///bluemoon change
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/device_tools/surgerybag_adv/inteq
	item = /obj/item/storage/backpack/duffelbag/syndie/inteq/surgery_adv
	purchasable_from = ~UPLINK_SYNDICATE

///datum/uplink_item/device_tools/encryptionkey
// 	name = "InteQ Encryption Key"
// 	desc = "A key that, when inserted into a radio headset, allows you to listen to all station department channels
// 			as well as talk on an encrypted InteQ channel with other agents that have the same key, and even communicate with raiders and nukies teams."
// 	item = /obj/item/encryptionkey/inteq
// 	cost = 2
// 	surplus = 75
// 	restricted = TRUE
// 	purchasable_from = ~(UPLINK_SYNDICATE)

/datum/uplink_item/device_tools/syndietome
	name = "Syndicate Tome"
	desc = "Используя редкие артефакты, добытые с огромным риском, Syndicate провел обратный инжиниринг \
			магических книг одного культа. Хотя копиям не хватает эзотерических способностей оригиналов, \
			они всё ещё полезны на поле боя — могут как исцелять, так и калечить. \
			Правда, иногда могут откусить палец-другой."
	item = /obj/item/storage/book/bible/syndicate
	purchasable_from = UPLINK_SYNDICATE
	cost = 9

/datum/uplink_item/device_tools/inteqtome
	name = "InteQ Tome"
	desc = "Магический том, позволяющий использовать силу божеств даже самым неверующим и грешным существам.\
			 Проведи пальцем по острию страниц, окрапи их своей кровью и книга будет связана со своим хозяином до самой смерти, \
			а замен божества одолжат частичку своей силы, позволяя залечивать любые раны своих товарищей, \"аккуратно\" прикладывая её к голове пострадавшего. (Лучше бы ему быть в шлеме)."
	item = /obj/item/storage/book/bible/syndicate/inteq
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)
	cost = 7

/datum/uplink_item/device_tools/thermal
	name = "Thermal Imaging Glasses"
	desc = "Эти очки можно замаскировать под обычные очки со станции. \
			Позволяют видеть организмы сквозь стены, улавливая инфракрасное излучение. \
			Тёплые объекты — тела, киборги, ядра ИИ — светятся ярче холодных стен и шлюзов."
	item = /obj/item/clothing/glasses/thermal/syndi
	cost = 4

/datum/uplink_item/device_tools/potion
	name = "Sentience Potion"
	item = /obj/item/slimepotion/slime/sentience/nuclear
	desc = "Зелье, добытое с огромным риском агентами Syndicate под прикрытием и модифицированное технологиями Syndicate. \
			Сделает любое животное разумным и подчинённым вам, а также встроит внутреннее радио и ID-карту."
	cost = 2
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE
	restricted = TRUE

/datum/uplink_item/device_tools/suspiciousphone
	name = "Protocol CRAB-17 Phone"
	desc = "Телефон Протокола CRAB-17, одолженный у неизвестной третьей стороны. Может обрушить космический рынок, \
	перенаправляя убытки экипажа на ваш счёт. Экипаж может перевести средства на новый банковский сайт, \
	но если они HODL — сами виноваты."
	item = /obj/item/suspiciousphone
	cost = 7
	restricted = TRUE
	limited_stock = 1
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS) // Никакого CRAB-17 через ВР
	surplus = 0 // Никакого CRAB-17 через ВР

/datum/uplink_item/device_tools/syndicate_teleporter
	name = "Experimental Syndicate Teleporter"
	desc = "Портативный телепортер Syndicate, перемещает пользователя на 4-8 метров вперёд. \
			Телепорт в стену вызовет аварийный параллельный телепорт, \
			но если и он не сработает — вы умрёте. \
			4 заряда, автоподзарядка, гарантия аннулируется при воздействии ЭМИ."
	item = /obj/item/storage/box/syndie_kit/teleporter
	cost = 4
