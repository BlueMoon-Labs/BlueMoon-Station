
/*
	Uplink Items:
	Unlike categories, uplink item entries are automatically sorted alphabetically on server init in a global list,
	When adding new entries to the file, please keep them sorted by category.
*/

// Stealth Items

/datum/uplink_item/stealthy_tools/agent_card
	name = "Agent Identification Card"
	desc = "Агентская карта не позволяет ИИ отслеживать носителя и может копировать доступ с других ID-карт. \
			Доступ накапливается — сканирование одной карты не стирает доступ от другой. \
			Кроме того, карту можно подделать: изменить имя и должность бесконечное количество раз. \
			Некоторые зоны и устройства Syndicate доступны только с такими картами."
	item = /obj/item/card/id/syndicate
	cost = 2
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/stealthy_tools/agent_card_inteq
	name = "Agent Identification Card"
	desc = "Агентская карта не позволяет ИИ отслеживать носителя и может копировать доступ с других ID-карт. \
			Доступ накапливается — сканирование одной карты не стирает доступ от другой. \
			Кроме того, карту можно подделать: изменить имя и должность неограниченное количество раз. \
			Некоторые зоны и устройства Syndicate доступны только с такими картами."
	item = /obj/item/card/id/inteq
	cost = 2
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/stealthy_tools/ai_detector
	name = "Artificial Intelligence Detector"
	desc = "Рабочий мультитул, краснеющий при обнаружении наблюдающего ИИ. \
			При активации показывает точное место наблюдения ИИ и слепые зоны ближайших камер. \
			Полезно для поддержания прикрытия и поиска путей отхода."
	item = /obj/item/multitool/ai_detect
	cost = 1

/datum/uplink_item/stealthy_tools/chameleon
	name = "Chameleon Kit"
	desc = "Набор предметов с технологией хамелеона, позволяющий маскироваться под почти всё на станции и не только! \
			Из-за сокращения бюджета обувь не защищает от поскальзывания."
	item = /obj/item/storage/box/syndie_kit/chameleon
	cost = 2
	purchasable_from = ~(UPLINK_CLOWN_OPS)

/datum/uplink_item/stealthy_tools/chameleon_proj
	name = "Chameleon Projector"
	desc = "Проецирует образ на пользователя, маскируя его под отсканированный объект, \
			пока проектор не убран из руки. Замаскированные двигаются медленно, а снаряды пролетают мимо."
	item = /obj/item/chameleon
	cost = 7

/datum/uplink_item/stealthy_tools/codespeak_manual
	name = "Codespeak Manual"
	desc = "Агенты Syndicate могут быть обучены кодовому языку для передачи сложной информации, \
			который звучит как случайный набор слов для посторонних. \
			Это эксклюзивное издание с неограниченным количеством использований. Можно ударить книгой кого-то для обучения."
	item = /obj/item/codespeak_manual/unlimited
	cost = 3
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/stealthy_tools/codespeak_manual //bluemoon add
	name = "Fast codes guide"
	desc = "Толстый мануал, описывающий краткие коды для обозначения любой ситуации. Эти коды использовались военными ещё в ранних космических войнах, но со временем стали заменяться на более простые вариации."
	item = /obj/item/fastcodes_guide/inf
	cost = 3
	purchasable_from = UPLINK_TRAITORS

/datum/uplink_item/stealthy_tools/combatbananashoes
	name = "Combat Banana Shoes"
	desc = "While making the wearer immune to most slipping attacks like regular combat clown shoes, these shoes \
		can generate a large number of synthetic banana peels as the wearer walks, slipping up would-be pursuers. They also \
		squeak significantly louder."
	item = /obj/item/clothing/shoes/clown_shoes/banana_shoes/combat
	cost = 6
	surplus = 0
	purchasable_from = UPLINK_CLOWN_OPS

/datum/uplink_item/stealthy_tools/emplight
	name = "EMP Flashlight"
	desc = "Небольшое самоподзаряжающееся ЭМИ-устройство ближнего действия, замаскированное под рабочий фонарик. \
		Полезно для вывода из строя гарнитур, камер, дверей, шкафчиков и боргов при скрытных операциях. \
		Удар по цели направляет ЭМИ на неё и расходует заряд."
	item = /obj/item/flashlight/emp
	cost = 2
	surplus = 30

/datum/uplink_item/stealthy_tools/failsafe
	name = "Failsafe Uplink Code"
	desc = "При вводе аплинк немедленно самоуничтожится."
	item = /obj/effect/gibspawner/generic
	cost = 1
	surplus = 0
	restricted = TRUE
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/stealthy_tools/failsafe/spawn_item(spawn_path, mob/user, datum/component/uplink/U)
	if(!U)
		return
	U.failsafe_code = U.generate_code()
	to_chat(user, "The new failsafe code for this uplink is now : [U.failsafe_code].")
	if(user.mind)
		user.mind.store_memory("Failsafe code for [U.parent] : [U.failsafe_code]")
	return U.parent //For log icon

/datum/uplink_item/stealthy_tools/mulligan
	name = "Mulligan"
	desc = "Облажались и СБ на хвосте? Этот удобный шприц даст вам совершенно новую личность \
			и внешность."
	item = /obj/item/reagent_containers/syringe/mulligan
	cost = 3
	surplus = 30
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/stealthy_tools/syndigaloshes
	name = "No-Slip Chameleon Shoes"
	desc = "Эти ботинки позволяют носителю бегать по мокрым полам и скользким предметам без падений. \
			Не работают на сильно смазанных поверхностях."
	item = /obj/item/clothing/shoes/chameleon/noslip
	cost = 2
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/stealthy_tools/syndigaloshes/nuke
	item = /obj/item/clothing/shoes/chameleon/noslip
	cost = 4
	purchasable_from = UPLINK_NUKE_OPS

/datum/uplink_item/stealthy_tools/jammer
	name = "Radio Jammer"
	desc = "При активации подавляет любую исходящую радиосвязь поблизости. Не влияет на бинарный чат."
	item = /obj/item/jammer
	cost = 2

/datum/uplink_item/stealthy_tools/smugglersatchel
	name = "Smuggler's Satchel"
	desc = "Эта сумка достаточно тонкая, чтобы спрятать её в щель между обшивкой и плиткой — отлично подходит для хранения \
			краденого. В комплекте монтировка и плитка пола. Ходят слухи, что спрятанные сумки \
			переживают смену, но это лишь миф."
	item = /obj/item/storage/backpack/satchel/flat/with_tools
	cost = 1
	surplus = 30
