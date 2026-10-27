/datum/uplink_item/mod
    category = "MOD"
    surplus = 0

/datum/uplink_item/mod/wraith
	name = "MOD Wraith cloaking module"
	desc = "Пассивная маскировка и излучатель, перегружающий свет и электронику для зарядки MOD. Несовместим с бронеплитами и оптической системой Синдиката."
	item = /obj/item/mod/module/stealth/wraith
	cost = 2

/datum/uplink_item/mod/core //
	name = "InteQ MOD"
	desc = "Высокотехнологичный боевой костюм в зловещих тёмно-синих тонах, изготовленный для наёмников спецопераций. Конструкция представляет собой обтекаемую многослойную структуру из формованного пласталя и композитной керамики, а подкладка выполнена из лёгкого кевлара и гибридного дюратриплетения. На бирке написано: Произведено совместно Fox и Ghost inc. Все права защищены, вмешательство в конструкцию костюма приведёт к его немедленному уничтожению."
	item = /obj/item/mod/control/pre_equipped/inteq
	cost = 12 // 39 ---> 18
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/mod/core/infiltrator
	name = "Infiltrator InteQ MOD"
	desc = "Высокотехнологичный боевой костюм преспособленный для скрытных миссий для наёмников спецопераций. Конструкция представляет собой обтекаемую многослойную структуру композитной керамики и прокладок лёгкого кевлара и гибридного дюратриплетения. На бирке написано: Произведено совместно Fox и Ghost inc. НЕ ЗАЩИЩАЕТ ОТ КОСМОСА."
	item = /obj/item/mod/control/pre_equipped/infiltrator_inteq
	cost = 8
	purchasable_from = UPLINK_TRAITORS

/datum/uplink_item/mod/core/traitor
	name = "Agent InteQ MOD"
	desc = "Модный и современный боевой костюм, предназначенный для солдат ЧВК Интекью, не предпочитающих скрываться.\
	Неплохая броня и улучшенный джетпак позволяют вести уверенный бой в условиях космоса и разгерметизаций, а \
	встроенная кобура - прятать оружие, оно не помещается в рюкзак. "
	item = /obj/item/mod/control/pre_equipped/traitor/inteq
	cost = 6
	purchasable_from = UPLINK_TRAITORS

/datum/uplink_item/mod/syndie
	name = "Syndicate MOD"
	desc = "Базовая версия модулярного костюма, используемая синдикатом. Имеет предустановленный джетпак, рюкзак и ДНК-замок."
	cost = 6
	purchasable_from = (UPLINK_SYNDICATE | UPLINK_SYNDICATE_PACT_CREW)
	item = /obj/item/mod/control/pre_equipped/traitor

// /datum/uplink_item/mod/nanotrasen
// 	name = "ERT MOD"
// 	desc = "Списанный МОД костюм, побывавший во многих сражений, доказавши свою практичность, но не бронированность. Очень стильный."
// 	cost = 10
// 	item = /obj/item/mod/control/pre_equipped/responsory
// 	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/datum/uplink_item/mod/syndie_elite
	name = "Syndicate Elite MODsuit"
	desc = "Элитный костюм, модернизированный Cybersun Industries, с улучшенными показателями брони."
	cost = 12
	item = /obj/item/mod/control/pre_equipped/elite
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/mod/syndie_jet
	name = "MOD Advanced Jetpack"
	desc = "Улучшение предыдущей модели электрических двигателей.\
			Эта достигает более высоких скоростей за счёт установки \
			большего количества двигателей и нанесения красной краски."
	item = /obj/item/mod/module/jetpack/advanced
	cost = 4
	purchasable_from = (UPLINK_SYNDICATE | UPLINK_SYNDICATE_PACT_CREW)

/datum/uplink_item/mod/noslip //
	name = "MOD anti slip module"
	desc = "Модифицированная версия стандартных магнитных ботинок с пьезоэлектрическими кристаллами на подошве. \
		Две пластины на подошве автоматически выдвигаются и намагничиваются при каждом шаге — \
		притяжение слишком слабое, чтобы зацепиться за обшивку, но достаточное, чтобы не поскользнуться \
		на мокром полу. Honk Co. неоднократно протестовала против легальности этих модулей."
	item = /obj/item/mod/module/noslip
	cost = 3
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE_PACT_CREW)

/datum/uplink_item/mod/thermal //
	name = "MOD thermal visor module"
	desc = "Нашлемный дисплей, встроенный в визор костюма. Использует небольшой ИК-сканер для обнаружения \
		теплового излучения объектов вблизи пользователя. Способен засечь тепло даже чего-то размером с грызуна, \
		но при этом создаёт раздражающий красный фильтр. Говорят, с ним можно видеть даже то, что за спиной."
	item = /obj/item/mod/module/visor/thermal
	cost = 3
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_TRAITORS | UPLINK_SYNDICATE)

/datum/uplink_item/mod/emp_shield //
	name = "MOD advanced EMP shield module"
	desc = "Продвинутый полевой ингибитор, встроенный в костюм. Защищает от электромагнитных импульсов, \
		которые могли бы повредить электронные системы костюма или устройства на владельце, \
		включая аугментации. Однако для этого расходуется энергия костюма."
	item = /obj/item/mod/module/emp_shield/advanced
	cost = 4
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_TRAITORS | UPLINK_SYNDICATE | UPLINK_SYNDICATE_PACT_CREW)

/datum/uplink_item/mod/storage_upgrader
	name = "MOD Storage Upgrader"
	desc = "Модуль расширения для хранилища МОДа, работающий за счёт технологии BLUESPACE.\
	Позволяет увеличить размер встроенного рюкзака до уровня БС сумки. Но не более.\
	Покупать больше одной штуки смысла не имеет, они не складываются."
	item = /obj/item/mod/module/storage_upgrader
	cost = 2
	purchasable_from = (UPLINK_SYNDICATE | UPLINK_SYNDICATE_PACT_CREW)

/datum/uplink_item/mod/syndie_shield
	name = "MOD Syndie Energy Shield"
	desc = "Одна из совершенных версий модулярных энергощитов, способная выдерживать до 5-ти попаданий. \
	Является разработкой Синдиката в соответствующем стиле, со встроенным микро-ядерным реактором, почти полностью \
	покрывающим затраты щита."
	item = /obj/item/mod/module/energy_shield/syndie
	cost = 4
	purchasable_from = (UPLINK_SYNDICATE)

/datum/uplink_item/mod/launch_kick
	name = "MOD Launch Kick Module"
	desc = "Модуль удара ногой с прыжка: разгоняет носителя в направлении цели."
	item = /obj/item/mod/module/launch_kick
	cost = 3
	purchasable_from = UPLINK_SYNDICATE | UPLINK_NUKE_OPS | UPLINK_TRAITORS

/datum/uplink_item/mod/emp_pulse
	name = "MOD EMP pulse module"
	desc = "Создаёт электромагнитный импульс вокруг носителя, защищая его от собственного разряда."
	item = /obj/item/mod/module/emp_shield/pulse
	cost = 2
	purchasable_from = ALL

/datum/uplink_item/mod/flamethrower
	name = "MOD flamethrower module"
	desc = "Выдвижной огнемёт с питанием от MOD. Активируйте модуль и стреляйте оружием в руке."
	item = /obj/item/mod/module/flamethrower
	cost = 3
	purchasable_from = ALL

/datum/uplink_item/mod/jaeger_sprint
	name = "MOD Jaeger sprint module"
	desc = "Усиленные приводы временно повышают скорость движения носителя."
	item = /obj/item/mod/module/jaeger_sprint
	cost = 5
	purchasable_from = ALL

/datum/uplink_item/mod/plate_compression
	name = "MOD Plate Compression Module"
	desc = "Сжимает костюм до обычного размера. Несовместим с модулем хранилища."
	item = /obj/item/mod/module/plate_compression
	cost = 1
	purchasable_from = UPLINK_SYNDICATE | UPLINK_TRAITORS | UPLINK_NUKE_OPS

/datum/uplink_item/mod/medbeam
	name = "MOD Medical Beamgun Module"
	desc = "Встроенный медицинский луч для лечения союзников."
	item = /obj/item/mod/module/medbeam
	cost = 15
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS

/datum/uplink_item/mod/chameleon
	name = "MOD Chameleon Module"
	desc = "Маскирует выключенный MOD под рюкзак или пояс. Внешний вид выбирается в настройках модуля."
	item = /obj/item/mod/module/chameleon
	cost = 1
	purchasable_from = UPLINK_SYNDICATE | UPLINK_TRAITORS | UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS

/datum/uplink_item/mod/shock_absorber
	name = "MOD Shock Absorber Module"
	desc = "Защищает носителя включённого MOD от оглушающих ударов дубинкой, расходуя энергию."
	item = /obj/item/mod/module/shock_absorber
	cost = 1
	purchasable_from = UPLINK_SYNDICATE | UPLINK_TRAITORS | UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS
