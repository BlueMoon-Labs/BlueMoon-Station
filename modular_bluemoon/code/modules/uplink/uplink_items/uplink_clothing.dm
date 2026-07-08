/datum/uplink_item/mod
    category = "MOD"
    surplus = 0

/datum/uplink_item/mod/core //
	name = "InteQ MOD"
	desc = "Высокотехнологичный боевой костюм в зловещих тёмно-синих тонах, изготовленный для наёмников спецопераций. Конструкция представляет собой обтекаемую многослойную структуру из формованного пласталя и композитной керамики, а подкладка выполнена из лёгкого кевлара и гибридного дюратриплетения. На бирке написано: Произведено совместно Fox и Ghost inc. Все права защищены, вмешательство в конструкцию костюма приведёт к его немедленному уничтожению."
	item = /obj/item/mod/control/pre_equipped/inteq
	cost = 18 // 39 ---> 18
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/mod/syndie
	name = "Syndicate MOD"
	desc = "Базовая версия модулярного костюма, используемая синдикатом. Имеет предустановленный джетпак, рюкзак и ДНК-замок."
	cost = 6
	purchasable_from = (UPLINK_SYNDICATE | UPLINK_SYNDICATE_PACT_CREW)
	item = /obj/item/mod/control/pre_equipped/traitor

/datum/uplink_item/mod/nanotrasen
	name = "ERT MOD"
	desc = "Списанный МОД костюм, побывавший во многих сражений, доказавши свою практичность, но не бронированность. Очень стильный."
	cost = 10
	item = /obj/item/mod/control/pre_equipped/responsory
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/datum/uplink_item/mod/syndie_jet
	name = "MOD Advanced Jetpack"
	desc = "Улучшение предыдущей модели электрических двигателей.\
			Эта достигает более высоких скоростей за счёт установки \
			большего количества двигателей и нанесения красной краски."
	item = /obj/item/mod/module/jetpack/advanced
	cost = 4
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

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
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/mod/emp_shield //
	name = "MOD advanced EMP shield module"
	desc = "Продвинутый полевой ингибитор, встроенный в костюм. Защищает от электромагнитных импульсов, \
		которые могли бы повредить электронные системы костюма или устройства на владельце, \
		включая аугментации. Однако для этого расходуется энергия костюма."
	item = /obj/item/mod/module/emp_shield/advanced
	cost = 6
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE_PACT_CREW)
