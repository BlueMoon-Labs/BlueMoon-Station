
// Stealthy Weapons

/*
	Uplink Items:
	Unlike categories, uplink item entries are automatically sorted alphabetically on server init in a global list,
	When adding new entries to the file, please keep them sorted by category.
*/

/datum/uplink_item/stealthy_weapons/telescopicbat
	name = "Telescopic Baseball Bat"
	desc = "Крепкая телескопическая бейсбольная бита — бьёт как грузовик и легко прячется в сложенном виде."
	item = /obj/item/melee/baseball_bat/telescopic
	purchasable_from = UPLINK_SYNDICATE
	cost = 2

/datum/uplink_item/stealthy_weapons/telescopicbat_inteq
	name = "Telescopic Baseball Bat"
	desc = "Раскладная бейсбольная бита с шипованым навершием. Для тех, кто в душе не ебёт какие правила у бейсбола."
	item = /obj/item/melee/baseball_bat/telescopic/inteq
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)
	cost = 2

/datum/uplink_item/stealthy_weapons/combatglovesplus
	name = "Combat Gloves Plus"
	desc = "Перчатки с огнеупорностью и защитой от тока. В отличие от обычных боевых перчаток, \
			эти используют нанотехнологии, чтобы обучить носителя приёмам крав-мага."
	item = /obj/item/clothing/gloves/krav_maga/combatglovesplus
	cost = 4
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE
	surplus = 0

/datum/uplink_item/stealthy_weapons/cqc
	name = "CQC Manual"
	desc = "Руководство по тактическому ближнему бою. Обучает одного пользователя, после чего самоуничтожается."
	item = /obj/item/book/granter/martial/cqc
	purchasable_from = ~UPLINK_CLOWN_OPS
	cost = 12
	surplus = 0

/datum/uplink_item/stealthy_weapons/dart_pistol
	name = "Dart Pistol"
	desc = "Миниатюрный шприцемёт. Очень тихий при выстреле и помещается в любое место, \
			где влезет маленький предмет."
	item = /obj/item/gun/syringe/syndicate
	cost = 4
	surplus = 50

/datum/uplink_item/stealthy_weapons/dehy_carp
	name = "Dehydrated Space Carp"
	desc = "Выглядит как плюшевый карп, но добавьте воды — и он станет настоящим космическим карпом! \
			Активируйте в руке перед использованием, чтобы он знал, что вас не надо жрать."
	item = /obj/item/toy/plush/carpplushie/dehy_carp
	cost = 1

/datum/uplink_item/stealthy_weapons/derringerpack
	name = "Compact Derringer"
	desc = "Легко скрываемый пистолет под .357. Поставляется в неприметной пачке сигарет с дополнительными боеприпасами."
	item = /obj/item/storage/fancy/cigarettes/derringer
	cost = 6
	surplus = 30

/datum/uplink_item/stealthy_weapons/derringerpack/purchase(mob/user, datum/component/uplink/U)
	if(prob(10)) //For the 10%
		item = /obj/item/storage/fancy/cigarettes/derringer/gold
	..()

/datum/uplink_item/stealthy_weapons/derringerpack_nukie
	name = "Antique Derringer"
	desc = "Легко скрываемый, но невероятно смертоносный пистолет под .45-70. Поставляется в уникальной пачке сигарет с дополнительными боеприпасами."
	item = /obj/item/storage/fancy/cigarettes/derringer/midworld
	purchasable_from = (UPLINK_NUKE_OPS | UPLINK_SYNDICATE)
	cost = 10
	surplus = 2

/datum/uplink_item/stealthy_weapons/edagger
	name = "Energy Dagger"
	desc = "Энергетический кинжал, в выключенном состоянии выглядит и работает как ручка."
	item = /obj/item/pen/edagger
	cost = 2

/datum/uplink_item/stealthy_weapons/martialarts
	name = "Sleeping Carp Scroll"
	desc = "Этот свиток содержит секреты древнего боевого искусства. Вы освоите безоружный бой, \
			получите кожу крепче стали и сможете отбивать пули руками, \
			но откажетесь от бесчестного дальнего оружия."
	item = /obj/item/book/granter/martial/carp
	cost = 18
	player_minimum = 25
	surplus = 0
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/stealthy_weapons/martialartstwo
	name = "Rising Bass Scroll"
	desc = "Этот свиток содержит секреты древнего боевого искусства. Вы станете мастером побега \
	и уклонения от любого дальнего огня, но откажетесь от бесчестного дальнего оружия."
	item = /obj/item/book/granter/martial/bass
	cost = 20
	player_minimum = 25
	surplus = 0
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/stealthy_weapons/martialartsthree
	name = "Krav Maga Scroll"
	desc = "Этот свиток содержит секреты древнего боевого искусства. Вы получите специальные безоружные атаки \
			для скрытного устранения целей."
	item = /obj/item/book/granter/martial/krav_maga
	cost = 6
	surplus = 0

/datum/uplink_item/stealthy_weapons/crossbow
	name = "Miniature Energy Crossbow"
	desc = "Миниатюрный энергетический арбалет. Достаточно мал, чтобы влезть в карман \
		или незаметно спрятать в сумку. Стреляет болтами с парализующим токсином, \
		который ненадолго оглушает цель и заставляет заплетаться языком. \
		Бесконечные болты, но требуется время на перезарядку."
	item = /obj/item/gun/energy/kinetic_accelerator/crossbow
	cost = 12
	surplus = 50
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/stealthy_weapons/traitor_chem_bottle
	name = "Poison Kit"
	desc = "Набор смертоносных химикатов в компактной коробке. В комплекте шприц для точного применения."
	item = /obj/item/storage/box/syndie_kit/chemical
	cost = 6
	surplus = 50

/datum/uplink_item/stealthy_weapons/romerol_kit
	name = "Romerol"
	desc = "Высокоэкспериментальный биотеррористический агент, создающий спящие узелки в сером веществе мозга. \
			После смерти носителя узелки берут контроль над телом, вызывая ограниченную реанимацию, \
			невнятную речь, агрессию и способность заражать других."
	item = /obj/item/storage/box/syndie_kit/romerol
	cost = 25
	player_minimum = 25
	cant_discount = TRUE
	hijack_only = TRUE
	purchasable_from = ~UPLINK_NUKE_OPS

/datum/uplink_item/stealthy_weapons/sleepy_pen
	name = "Sleepy Pen"
	desc = "Шприц, замаскированный под рабочую ручку, заполненный мощным коктейлем препаратов, \
			включая сильный анестетик и вещество, лишающее цель речи. \
			Вмещает одну дозу, можно перезаполнить любыми химикатами. \
			Учтите: до того как цель уснёт, она ещё сможет двигаться и действовать."
	item = /obj/item/pen/sleepy
	cost = 4
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/stealthy_weapons/taeclowndo_shoes
	name = "Tae-clown-do Shoes"
	desc = "A pair of shoes for the most elite agents of the honkmotherland. They grant the mastery of taeclowndo with some honk-fu moves as long as they're worn."
	cost = 6
	item = /obj/item/clothing/shoes/clown_shoes/taeclowndo
	purchasable_from = UPLINK_CLOWN_OPS

/datum/uplink_item/stealthy_weapons/suppressor
	name = "Suppressor"
	desc = "Глушитель для повышенной скрытности и превосходных засад. \
			Совместим со многими малыми огнестрелами, включая Стечкин и C-20r, но не револьверы и энергопушки."
	item = /obj/item/suppressor
	cost = 1
	surplus = 10

/datum/uplink_item/stealthy_weapons/soap
	name = "Syndicate Soap"
	desc = "Зловещее мыло, используемое для очистки пятен крови, сокрытия убийств и предотвращения анализа ДНК. \
			Можно также бросить под ноги, чтобы подскользнуть народ."
	item = /obj/item/soap/syndie
	cost = 1
	surplus = 50
	purchasable_from = UPLINK_SYNDICATE // Bluemoon Changes

/datum/uplink_item/stealthy_weapons/soap_inteq // Bluemoon Changes
	name = "InteQ Soap"
	desc = "Зловещего вида мыло, используемое для очистки пятен крови, сокрытия убийств и предотвращения анализа ДНК. \
			Можно также бросить под ноги, чтобы поскользнувшийся улетел в закат."
	item = /obj/item/soap/inteq
	cost = 1
	surplus = 50
	purchasable_from = ~(UPLINK_SYNDICATE)

/datum/uplink_item/stealthy_weapons/soap_clusterbang
	name = "Slipocalypse Clusterbang"
	desc = "Традиционная кассетная граната, начинённая исключительно мылом. Полезна в любой ситуации!"
	item = /obj/item/grenade/clusterbuster/soap
	cost = 3
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/stealthy_weapons/soap_clusterbang/inteq
	item = /obj/item/grenade/clusterbuster/soap/inteq
	purchasable_from = ~(UPLINK_SYNDICATE)

//BLUEMOON add добавил набор оригами в аплинк.

/datum/uplink_item/stealthy_weapons/origami_bundle
	name = "Boxed Origami Kit"
	desc = "Набор содержит руководство по мастерскому оригами, позволяющее превращать обычные листы бумаги \
			в идеально аэродинамичные (и потенциально смертоносные) бумажные самолётики."
	item = /obj/item/storage/box/inteq_kit/origami_bundle
	cost = 4
	surplus = 0
	purchasable_from = ~UPLINK_NUKE_OPS

//BLUEMOON add end
