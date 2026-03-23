
/*
	Uplink Items:
	Unlike categories, uplink item entries are automatically sorted alphabetically on server init in a global list,
	When adding new entries to the file, please keep them sorted by category.
*/

//Support and Mechs

/datum/uplink_item/support/clown_reinforcement
	name = "Clown Reinforcements"
	desc = "Call in an additional clown to share the fun, equipped with full starting gear, but no credits."
	item = /obj/item/antag_spawner/nuke_ops/clown
	cost = 20
	purchasable_from = UPLINK_CLOWN_OPS
	restricted = TRUE

/datum/uplink_item/support/reinforcement
	name = "Reinforcements"
	desc = "Вызовите дополнительного члена команды. Придёт без снаряжения, так что придётся \
			приберечь кредиты на его вооружение."
	item = /obj/item/antag_spawner/nuke_ops
	cost = 25
	refundable = TRUE
	purchasable_from = UPLINK_NUKE_OPS
	restricted = TRUE

/datum/uplink_item/support/reinforcement/assault_borg
	name = "InteQ Assault Cyborg"
	desc = "Киборг, спроектированный и запрограммированный для систематического уничтожения невинного персонала. \
			Оснащён самовосполняющимся пулемётом, гранатомётом, энергетическим мечом, емагом, пинпоинтером, вспышкой и ломом."
	item = /obj/item/antag_spawner/nuke_ops/borg_tele/assault
	refundable = TRUE
	cost = 65
	restricted = TRUE

/datum/uplink_item/support/reinforcement/assault_borg/syndicate
	name = "Syndicate Assault Cyborg"
	item = /obj/item/antag_spawner/synd_borg/assault
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/support/reinforcement/medical_borg
	name = "InteQ Medical Cyborg"
	desc = "Боевой медицинский киборг. Ограниченный наступательный потенциал с лихвой компенсируется возможностями поддержки. \
			Оснащён нанитным гипоспреем, медицинским лучевым пистолетом, боевым дефибриллятором, полным хирургическим набором с энергопилой, \
			емагом, пинпоинтером и вспышкой. Благодаря сумке для хранения органов может проводить операции не хуже любого гуманоида."
	item = /obj/item/antag_spawner/nuke_ops/borg_tele/medical
	refundable = TRUE
	cost = 35
	restricted = TRUE

/datum/uplink_item/support/reinforcement/medical_borg/syndicate
	name = "Syndicate Medical Cyborg"
	item = /obj/item/antag_spawner/synd_borg/medical
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/support/reinforcement/saboteur_borg
	name = "InteQ Saboteur Cyborg"
	desc = "Обтекаемый инженерный киборг с модулями для скрытных операций. Также не способен забыть сварочник в шаттле. \
			Помимо стандартного инженерного оборудования оснащён специальным тегером назначения для перемещения по мусоропроводам. \
			Хамелеон-проектор позволяет маскироваться под киборга Nanotrasen, а ещё у него есть термальное зрение и пинпоинтер."
	item = /obj/item/antag_spawner/nuke_ops/borg_tele/saboteur
	refundable = TRUE
	cost = 35
	restricted = TRUE

/datum/uplink_item/support/reinforcement/saboteur_borg/syndicate
	name = "Syndicate Saboteur Cyborg"
	item = /obj/item/antag_spawner/synd_borg/saboteur
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/support/hermes
	name = "MIB-01 Hermes Exosuit"
	desc = "Лёгкий экзоскелет в тёмной окраске. Скорость и подбор вооружения делают его идеальным \
			для тактики 'ударил-убежал'. Оснащён зажигательным карабином, светошумовой пусковой установкой, \
			телепортером, ионными двигателями и энергомассивом Тесла. \
			Выглядит как мех SolFed, перекрашенный в коричневый. Sol поставляет их InteQ тайно и почти задаром."
	item = /obj/vehicle/sealed/mecha/combat/gygax/dark/loaded/hermes
	cost = 80

/datum/uplink_item/support/honker
	name = "Dark H.O.N.K."
	desc = "Клоунский боевой мех с пусковыми установками для банановых шкурок и слезогранат, а также незаменимым HoNkER BlAsT 5000."
	item = /obj/vehicle/sealed/mecha/combat/honker/dark/loaded
	cost = 80
	purchasable_from = UPLINK_CLOWN_OPS

/datum/uplink_item/support/ares
	name = "MIB-02 Ares Exosuit"
	desc = "Массивный и невероятно смертоносный экзоскелет военного класса. Дальнобойное наведение, управление вектором тяги \
			и развёртываемая дымовая завеса. Оснащён пулемётом, дробовой винтовкой, ракетной установкой, \
			противоснарядным усилителем брони и энергомассивом Тесла. \
			Выглядит как мех SolFed, перекрашенный в коричневый. Sol поставляет их InteQ тайно и почти задаром."
	item = /obj/vehicle/sealed/mecha/combat/marauder/mauler/loaded/ares
	cost = 140
