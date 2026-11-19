/datum/lazy_template/virtual_domain/abductor_ship
	name = "Abductor Ship"
	cost = BITRUNNER_COST_MEDIUM
	desc = "Проникните на корабль абдукторов и заберите их добро."
	difficulty = BITRUNNER_DIFFICULTY_MEDIUM
	completion_loot = list(/obj/item/toy/plush/nukeplushie = 1)
	help_text = "Материнский корабль абдукторов по незнанию вошёл во враждебную среду. Сейчас они готовятся покинуть район вместе со своим снаряжением и добычей, включая ящик. Осторожно: они известны своим продвинутым вооружением."
	is_modular = TRUE
	key = "abductor_ship"
	map_name = "abductor_ship"
	mob_modules = list(/datum/modular_mob_segment/abductor_agents)
	reward_points = BITRUNNER_REWARD_MEDIUM
	forced_outfit = /datum/outfit/bitductor

// Маяк снаряжения

/obj/item/choice_beacon/ancient_milsim
	name = "early access equipment beacon"
	desc = "Призывает шкаф со снаряжением за ваш вклад в раннее тестирование. Синхронизируется с текущей версией игры, чтобы выдать самое актуальное классовое снаряжение."

/obj/item/choice_beacon/ancient_milsim/generate_display_names()
	var/static/list/gear_options
	if(!gear_options)
		gear_options = list()
		for(var/obj/structure/closet/crate/secure/weapon/milsim/crate as anything in subtypesof(/obj/structure/closet/crate/secure/weapon/milsim))
			gear_options[initial(crate.name)] = crate
	return gear_options

/obj/structure/closet/crate/secure/weapon/milsim
	desc = "(Награда тестировщика ToV 2) Набор отряда противодействия мятежникам UNIF."

/obj/structure/closet/crate/secure/weapon/milsim/PopulateContents()
	. = ..()
	new /obj/item/kitchen/knife/combat(src)
	new /obj/item/gun/energy/e_gun(src)
	new /obj/item/radio/headset/headset_cargo(src)

/obj/structure/closet/crate/secure/weapon/milsim/mechanic
	name = "mechanic (инструменты/моток кабеля/инженерное снаряжение)"

/obj/structure/closet/crate/secure/weapon/milsim/mechanic/PopulateContents()
	. = ..()
	new /obj/item/storage/belt/utility/full(src)
	new /obj/item/clothing/glasses/welding(src)
	new /obj/item/stack/cable_coil(src, 30)

/obj/structure/closet/crate/secure/weapon/milsim/marksman
	name = "marksman (лазерная винтовка/запасные батареи/оптика)"

/obj/structure/closet/crate/secure/weapon/milsim/marksman/PopulateContents()
	. = ..()
	new /obj/item/gun/energy/laser(src)
	new /obj/item/clothing/glasses/thermal(src)
	new /obj/item/stock_parts/cell(src)
	new /obj/item/stock_parts/cell(src)

/obj/structure/closet/crate/secure/weapon/milsim/medic
	name = "medic (гипоспрей/медприпасы/медHUD)"

/obj/structure/closet/crate/secure/weapon/milsim/medic/PopulateContents()
	. = ..()
	new /obj/item/reagent_containers/hypospray/medipen(src)
	new /obj/item/reagent_containers/hypospray/medipen(src)
	new /obj/item/storage/firstaid/regular(src)
	new /obj/item/clothing/glasses/hud/health(src)

/obj/structure/closet/crate/secure/weapon/milsim/trapper
	name = "trapper (проектор-хамелеон/мины)"

/obj/structure/closet/crate/secure/weapon/milsim/trapper/PopulateContents()
	. = ..()
	new /obj/item/chameleon(src)
	new /obj/item/minespawner/ancient_milsim(src)
	new /obj/item/minespawner/ancient_milsim(src)

/obj/structure/closet/crate/secure/weapon/milsim/saboteur
	name = "saboteur (ЭМИ-гранаты/сканер материалов)"

/obj/structure/closet/crate/secure/weapon/milsim/saboteur/PopulateContents()
	. = ..()
	new /obj/item/grenade/empgrenade(src)
	new /obj/item/grenade/empgrenade(src)
	new /obj/item/analyzer(src)

/obj/structure/closet/crate/secure/weapon/milsim/sentinel
	name = "sentinel (тяжёлое оружие/броня)"

/obj/structure/closet/crate/secure/weapon/milsim/sentinel/PopulateContents()
	. = ..()
	new /obj/item/gun/ballistic/shotgun/automatic/combat(src)
	new /obj/item/storage/box/lethalshot(src)
	new /obj/item/clothing/suit/armor/vest(src)

/obj/structure/closet/crate/secure/weapon/milsim/trooper
	name = "trooper (штурмовая винтовка/патроны)"

/obj/structure/closet/crate/secure/weapon/milsim/trooper/PopulateContents()
	. = ..()
	new /obj/item/gun/ballistic/automatic/pistol(src)
	new /obj/item/ammo_box/magazine/m10mm(src)

// Туман войны / ворота встречи

/obj/machinery/button/door/indestructible
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/machinery/button/door/indestructible/ancient_milsim
	name = "SNPC Zone Entry Control"
	desc = "Особая кнопка, которая при нажатии удаляет сама себя. Надеемся, это предотвратит случайные или злонамеренные софтлоки, а также уравняет встречу, скрытую за туманом."
	id = "engagement_control"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/machinery/button/door/indestructible/ancient_milsim/screwdriver_act()
	return

/obj/machinery/button/door/indestructible/ancient_milsim/attackby()
	return

/obj/machinery/button/door/indestructible/ancient_milsim/emag_act()
	return

/obj/machinery/button/door/indestructible/ancient_milsim/on_attack_hand(mob/user)
	. = ..()
	if(.)
		return
	qdel(src)

/obj/machinery/door/poddoor/ancient_milsim
	name = "fog of war"
	desc = "«Лучшая» игровая механика всех времён. По крайней мере, она вас защищает, знаете ли? Удаляет себя при нажатии кнопки."
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/machinery/door/poddoor/ancient_milsim/Initialize(mapload)
	AddElement(/datum/element/update_icon_blocker)
	return ..()

/obj/machinery/door/poddoor/ancient_milsim/screwdriver_act()
	return

/obj/machinery/door/poddoor/ancient_milsim/welder_act()
	return

/obj/machinery/door/poddoor/ancient_milsim/open()
	qdel(src)

// Мины

/obj/item/minespawner
	name = "deactivated landmine"
	desc = "При активации развернёт взрывную мину."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "grenade"
	var/mine_type = /obj/effect/mine/explosive

/obj/item/minespawner/attack_self(mob/user, modifiers)
	. = ..()
	new mine_type(get_turf(user))
	user.visible_message(span_notice("[user] взводит [src]."), span_notice("Вы взводите [src]."))
	qdel(src)

/obj/effect/mine/explosive/light/ancient_milsim
	name = "low-yield landmine"
	range_devastation = 0
	range_heavy = 0
	range_light = 1
	range_flash = 2

/obj/item/minespawner/ancient_milsim
	name = "deactivated low-yield landmine"
	desc = "При активации через короткую задержку развернёт маломощную взрывную мину — идеально для ловушек в узких коридорах."
	mine_type = /obj/effect/mine/explosive/light/ancient_milsim

// Спавнеры добычи

/obj/effect/spawner/lootdrop/ancient_milsim
	name = "ancient milsim loot spawner"
	lootcount = 2
	loot = list(
		/obj/item/coin/silver = 25,
		/obj/item/coin/gold = 15,
		/obj/item/ammo_box/magazine/m10mm = 10,
		/obj/item/ammo_box/magazine/uzim9mm = 10,
		/obj/item/grenade/empgrenade = 5,
		/obj/item/reagent_containers/hypospray/medipen = 5,
		/obj/item/storage/box/survival = 4,
	)

/obj/effect/spawner/lootdrop/ancient_milsim/melee
	loot = list(
		/obj/item/coin/silver = 25,
		/obj/item/coin/gold = 15,
		/obj/item/kitchen/knife/combat = 10,
		/obj/item/melee/classic_baton = 10,
		/obj/item/shield/riot = 5,
		/obj/item/reagent_containers/hypospray/medipen = 5,
		/obj/item/storage/box/survival = 4,
	)

// Солдаты CIN

/mob/living/simple_animal/hostile/cin_soldier
	parent_type = /mob/living/simple_animal/hostile/syndicate/ranged
	name = "Coalition Operative"
	desc = "Смерть SolFed!"
	faction = list(ROLE_SYNDICATE)
	maxHealth = 100
	health = 100
	loot = list(/obj/effect/spawner/lootdrop/ancient_milsim)

/mob/living/simple_animal/hostile/cin_soldier/melee
	parent_type = /mob/living/simple_animal/hostile/syndicate/melee
	name = "Coalition Operative"
	desc = "Смерть SolFed!"
	faction = list(ROLE_SYNDICATE)
	maxHealth = 100
	health = 100
	loot = list(/obj/effect/spawner/lootdrop/ancient_milsim/melee)

/obj/effect/mob_spawn/human/virtual_domain/ancient_milsim
	name = "Bitrunning SNPC CIN Operative"
	mob_name = "a weird compound operative"
	short_desc = "Вы — умный NPC, охраняющий выход из симулированного боевого домена."
	flavour_text = "Вы — умный NPC, загруженный в домен, чтобы замедлить продвижение участников битраннинга."
	important_info = "В целом играйте честно. Допустимый вид — только люди."
	outfit = /datum/outfit/cin_soldier_player
	can_load_appearance = TRUE

/datum/outfit/cin_soldier_player
	name = "Coalition Operative SNPC"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	ears = /obj/item/radio/headset/syndicate
	mask = /obj/item/clothing/mask/balaclava
	head = /obj/item/clothing/head/helmet/swat
	back = /obj/item/storage/backpack/security
	id = /obj/item/card/id/advanced

/datum/modular_mob_segment/cin_mobs
	max = 3
	mobs = list(
		/mob/living/simple_animal/hostile/cin_soldier,
		/mob/living/simple_animal/hostile/cin_soldier/melee,
	)

// Диск DLC

/obj/item/disk/bitrunning/item/ancient_milsim
	name = "compiled bitrunning gear: ancient milsim"
	desc = "Диск с контентом раннего доступа. Его можно использовать для предзагрузки предметов в виртуальный домен."
	selectable_items = list(
		/obj/item/choice_beacon/ancient_milsim,
	)

/obj/item/tape/ruins
	parent_type = /obj/item/tape

/obj/item/tape/ruins/ancient_milsim
	icon_state = "tape_blue"
	name = "Developer Commentary"
	desc = "Магнитофонная запись, сделанная, предположительно, где-то в двадцать третьем веке — по крайней мере, так гласят размытые надписи. Почему они размыты? Вероятно, для достоверности."

/obj/item/tape/ruins/ancient_milsim/devlog_one
	name = "Developer Commentary, Log 1: Setting"
	used_capacity = 160

	storedinfo = list(
		"<span class='game say'><span class='name'>The universal recorder</span> <span class='message'>говорит, \"<span class='tape_recorder '>Запись начата.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Unknown person</span> <span class='message'>вещает, \"<span class=' '>Приветствую, меня зовут Леон Гарднер. Добро пожаловать на бета-тест долгожданного продолжения 'Time Of Valor: Border Rescue' — 'Time Of Valor 2'.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Leon Gardner</span> <span class='message'>заявляет, \"<span class=' '>После трёх лет разработки надеюсь, что ожидание того стоило.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Leon Gardner</span> <span class='message'>уточняет, \"<span class=' '>В этом предрелизном бета-тесте вы пройдёте вступительный уровень игры, рассказывающий о ранних этапах Пограничной войны, и познакомитесь с новыми механиками — умными NPC и полной молекулярной симуляцией.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Leon Gardner</span> <span class='message'>вторит, \"<span class=' '>Действие выбрано настолько ранним этапом Пограничной войны, потому что это дополняло историю приквела. Некоторые детали лора не были должным образом объяснены и не всегда были понятны игрокам, поэтому мы приложили дополнительные усилия, чтобы новому игроку было проще следить за сюжетом.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Leon Gardner</span> <span class='message'>заявляет, \"<span class=' '>Поэтому большинство NPC и предметов было сверено с их реальными аналогами по открытым документам, интервью с ветеранами войны и другим источникам.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Leon Gardner</span> <span class='message'>предупреждает, \"<span class=' '>Эта конкретная карта, 'intro-underscore-two', — сокращённое изображение множества тайных операций TerraGov, проведённых в первые месяцы войны.</span>\"</span></span>",
		"<span class='game say'><span class='name'>The universal recorder</span> <span class='message'>говорит, \"<span class='tape_recorder '>Запись остановлена.</span>\"</span></span>",
	)

	timestamp = list(
		0,
		20,
		40,
		80,
		100,
		120,
		140,
		160,
	)

/obj/item/tape/ruins/ancient_milsim/devlog_two
	name = "Developer Commentary, Log 2: Mechanics"
	used_capacity = 160

	storedinfo = list(
		"<span class='game say'><span class='name'>The universal recorder</span> <span class='message'>говорит, \"<span class='tape_recorder '>Запись начата.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Unknown person</span> <span class='message'>вещает, \"<span class=' '>Привет, меня зовут Ванесса Паркер, главный разработчик механик готовящейся игры 'Time Of Valor 2'.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Vanessa Parker</span> <span class='message'>заявляет, \"<span class=' '>По сравнению с предыдущей частью новые программные и аппаратные улучшения позволили нам создать глубокую симуляцию молекул и реалистичный расчёт урона для игроков и SNPC.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Vanessa Parker</span> <span class='message'>уточняет, \"<span class=' '>Из-за этого на ранних этапах тестирования игроки и SNPC истекали кровью или умирали от болевого шока в первых же столкновениях, что портило впечатление.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Vanessa Parker</span> <span class='message'>вторит, \"<span class=' '>Мы решили эту проблему, добавив самодельные технологии, подходящие сеттингу, — например, станции здоровья. Размещённые в важных точках, они позволяют игрокам и их умным противникам восстанавливать здоровье и останавливать кровотечения, которые были обычным делом.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Vanessa Parker</span> <span class='message'>заявляет, \"<span class=' '>Ещё одна частая проблема: со временем SNPC всё больше изучали уровень и начинали бросаться на игроков ещё до того, как те успевали экипироваться, и убивали их.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Vanessa Parker</span> <span class='message'>предупреждает, \"<span class=' '>Это исправили, разместив «туман войны» на границе между зонами NPC и SNPC. Для этого поставили силовую стену из ионизированного газа с периодом полураспада в несколько десятков лет, чтобы поле не исчезало случайно.</span>\"</span></span>",
		"<span class='game say'><span class='name'>The universal recorder</span> <span class='message'>говорит, \"<span class='tape_recorder '>Запись остановлена.</span>\"</span></span>",
	)
	timestamp = list(
		0,
		20,
		40,
		80,
		100,
		120,
		140,
		160,
	)

/obj/item/tape/ruins/ancient_milsim/devlog_three
	name = "Developer Commentary, Log 3: SNPCs"
	used_capacity = 160

	storedinfo = list(
		"<span class='game say'><span class='name'>The universal recorder</span> <span class='message'>говорит, \"<span class='tape_recorder '>Запись начата.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Unknown person</span> <span class='message'>вещает, \"<span class=' '>Здорово, я Марк Маршалл, программист нейросетей SNPC в 'Time Of Valor 2'.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Mark Marshall</span> <span class='message'>заявляет, \"<span class=' '>Новую систему умных NPC ненадолго использовали в боссфайле первой игры для главного врага, чтобы бой ощущался более стоящим и переигрываемым.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Mark Marshall</span> <span class='message'>уточняет, \"<span class=' '>Однако в новой игре технология SNPC улучшилась кардинально, и мы решили увеличить количество «умных» боевых эпизодов по сюжету.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Mark Marshall</span> <span class='message'>вторит, \"<span class=' '>Они дышат, едят и видят, как обычный игрок, и полностью симулируют нервную и когнитивную модели, в отличие от упрощённых обычных мобов без нервов, мыслей и страха.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Mark Marshall</span> <span class='message'>заявляет, \"<span class=' '>Благодаря умной кривой обучения они адаптируются и учатся на опыте взаимодействия с другими игроками, поэтому каждый бой должен ощущаться уникальным.</span>\"</span></span>",
		"<span class='game say'><span class='name'>Mark Marshall</span> <span class='message'>предупреждает, \"<span class=' '>Их модели также сильно переработали, чтобы другие люди могли предлагать собственную внешность персонажей, так что ни один из них не будет выглядеть одинаково.</span>\"</span></span>",
		"<span class='game say'><span class='name'>The universal recorder</span> <span class='message'>говорит, \"<span class='tape_recorder '>Запись остановлена.</span>\"</span></span>",
	)
	timestamp = list(
		0,
		20,
		40,
		80,
		100,
		120,
		140,
		160,
	)

/datum/lazy_template/virtual_domain/ash_drake
	name = "Ashen Inferno"
	cost = BITRUNNER_COST_MEDIUM
	desc = "Дом пепельного дрейка — могучего дракона, что бороздит просторы Лаваленда."
	difficulty = BITRUNNER_DIFFICULTY_MEDIUM
	forced_outfit = /datum/outfit/job/miner
	key = "ash_drake"
	map_name = "ash_drake"
	reward_points = BITRUNNER_REWARD_MEDIUM

/datum/lazy_template/virtual_domain/beach_bar
	name = "Beach Bar"
	desc = "Весёлый прибрежный рай, где дружелюбные бармены подают напитки. Может стоит напиться тут?"
	completion_loot = list(/obj/item/toy/beach_ball = 1)
	help_text = "Заведение держится на доходах с бара, и они не слишком охотно делятся подробностями. Может, пара порций жидкого обаяния поднимет им настроение. Как говорится, если не можешь победить — присоединяйся."
	key = "beach_bar"
	map_name = "beach_bar"
	domain_flags = DOMAIN_NO_NOHIT_BONUS

	var/list/bar_drinks = list()

/datum/lazy_template/virtual_domain/beach_bar/setup_domain(list/created_atoms)
	. = ..()

	bar_drinks = list()

	for(var/obj/item/reagent_containers/food/drinks/drink in created_atoms)
		if(!drink.reagents || drink.reagents.total_volume <= 0)
			continue
		if(!isturf(drink.loc) && !istype(drink.loc, /obj/structure/table))
			continue
		bar_drinks += drink
		RegisterSignal(drink, COMSIG_GLASS_DRANK, PROC_REF(on_drink_drank))

// Награда за выпитое: полный стакан 50u даёт 2.5 очка.
/datum/lazy_template/virtual_domain/beach_bar/proc/on_drink_drank(datum/source, mob/living/drinker, mob/user, gulp_amount = 0)
	SIGNAL_HANDLER

	add_points(gulp_amount / 20)

/datum/lazy_template/virtual_domain/blood_drunk_miner
	name = "Sanguine Excavation"
	cost = BITRUNNER_COST_MEDIUM
	desc = "Немногие покидают поверхность Лаваленда без шрамов. Некоторые остаются, обезумев от охоты."
	difficulty = BITRUNNER_DIFFICULTY_MEDIUM
	forced_outfit = /datum/outfit/job/miner
	key = "blood_drunk_miner"
	map_name = "blood_drunk_miner"
	reward_points = BITRUNNER_REWARD_MEDIUM

/datum/lazy_template/virtual_domain/breeze_bay
	name = "Breeze Bay"
	desc = "Прибрежный городок, к северу от которого раскинулся большой лес."
	help_text = "Всё просто! Наслаждайтесь солнцем, ловите рыбу и хорошо проводите время! Только не давайте крабам себя укусить."
	key = "breeze_bay"
	map_name = "breeze_bay"
	reward_points = BITRUNNER_REWARD_LOW
	domain_flags = DOMAIN_NO_NOHIT_BONUS

/datum/lazy_template/virtual_domain/breeze_bay/setup_domain(list/created_atoms)
	. = ..()

	for(var/obj/item/fishing_rod/rod in created_atoms)
		RegisterSignal(rod, COMSIG_FISHING_ROD_CAUGHT_FISH, PROC_REF(on_fish_caught))

	// Добавляем перила вдоль деревянного пирса, чтобы он выглядел как нормальный док.
	var/datum/turf_reservation/current_reservation = reservations[length(reservations)]
	if(current_reservation)
		for(var/turf/pier as anything in current_reservation.reserved_turfs)
			if(!istype(pier, /turf/open/floor/wood/large))
				continue
			if(locate(/obj/structure/railing) in pier)
				continue
			for(var/direction in GLOB.cardinals)
				var/turf/adjacent = get_step(pier, direction)
				if(!istype(adjacent, /turf/open/water/beach))
					continue
				var/obj/structure/railing/railing = new(pier)
				railing.dir = direction
				railing.ini_dir = direction
				break

/datum/lazy_template/virtual_domain/breeze_bay/proc/on_fish_caught(datum/source, reward)
	SIGNAL_HANDLER

	if(isnull(reward))
		return

	add_points(10)

/datum/lazy_template/virtual_domain/bubblegum
	name = "Blood-Soaked Lair"
	cost = BITRUNNER_COST_HIGH
	desc = "Король демонов резни. Бубльгум — огромное, массивное чудовище, склонное к насилию."
	difficulty = BITRUNNER_DIFFICULTY_HIGH
	completion_loot = list(/obj/item/toy/plush/bubbleplush = 1)
	forced_outfit = /datum/outfit/job/miner
	key = "bubblegum"
	map_name = "bubblegum"
	reward_points = BITRUNNER_REWARD_HIGH

/datum/lazy_template/virtual_domain/clown_planet
	name = "Clown Planet"
	cost = BITRUNNER_COST_LOW
	desc = "В глубоких тёмных просторах космоса есть только Хонк."
	difficulty = BITRUNNER_DIFFICULTY_LOW
	completion_loot = list(/obj/item/bikehorn = 1)
	forced_outfit = /datum/outfit/job/clown
	help_text = "Проберитесь через фабрику, найдите зашифрованный ящик и доставьте его в сейфхаус. Ящик можно отправить по трубам через приёмный жёлоб — он появится у выхода рядом с безопасной комнатой."
	key = "clown_planet"
	map_name = "clown_planet"
	reward_points = BITRUNNER_REWARD_LOW

/datum/lazy_template/virtual_domain/colossus
	name = "Celestial Trial"
	cost = BITRUNNER_COST_HIGH
	desc = "Огромный древний зверь по имени Колосс. Судный день близок."
	difficulty = BITRUNNER_DIFFICULTY_HIGH
	forced_outfit = /datum/outfit/job/miner
	key = "colossus"
	map_name = "colossus"
	reward_points = BITRUNNER_REWARD_HIGH

/obj/item/reagent_containers/food/snacks/pizzaslice/meat/pizzeria
	name = "pizzeria meatpizza slice"
	desc = "На вид съедобный кусок мясной пиццы из давно закрытой пиццерии."
	list_reagents = null
	bonus_reagents = list()
	tastes = list("корочка" = 1, "кетчуп" = 1, "«сыр»" = 1, "мясо неизвестного происхождения" = 1, "клей" = 1)
	foodtype = null

/datum/lazy_template/virtual_domain/fredingtonfastingbear
	name = "Pizza Party"
	cost = BITRUNNER_COST_MEDIUM
	desc = "Знаменитая пиццерия, погубленная тем, что она предлагала."
	completion_loot = list(/obj/item/reagent_containers/food/snacks/pizzaslice/meat/pizzeria = 1)
	difficulty = BITRUNNER_DIFFICULTY_MEDIUM
	help_text = "Возьмите фонарик и отправляйтесь. Ваш любимый медведь ждал вас..."
	key = "fredingtonfastingbear"
	map_name = "fredingtonfastingbear"
	reward_points = BITRUNNER_REWARD_MEDIUM

/datum/lazy_template/virtual_domain/gondola_asteroid
	name = "Gondola Asteroid"
	desc = "Астероид, на котором растёт обильный лес гондол. Безмятежно."
	help_text = "Какой прекрасный лес. Здесь, в середине карты, стоит ящик с добычей. Хм... он не сдвигается с места. Похоже, гондолам не составляет труда его двигать. Наверняка есть способ сдвинуть его и самому."
	key = "gondola_asteroid"
	map_name = "gondola_asteroid"
	domain_flags = DOMAIN_NO_NOHIT_BONUS

// Ящик выглядит тяжёлым, но его можно тащить к цели.
/obj/structure/closet/crate/secure/bitrunning/encrypted/gondola
	move_resist = MOVE_FORCE_NORMAL

/mob/living/simple_animal/pet/gondola/virtual_domain
	health = 50
	loot = list(
		/obj/effect/decal/cleanable/blood/gibs = 1,
		/obj/item/stack/sheet/animalhide/gondola = 1,
		/obj/item/reagent_containers/food/snacks/meat/slab/gondola/virtual_domain = 1,
	)
	maxHealth = 50
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_STRONG

/obj/item/reagent_containers/food/snacks/meat/slab/gondola/virtual_domain
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 4,
		/datum/reagent/gondola_mutation_toxin/virtual_domain = 5,
	)

/datum/reagent/gondola_mutation_toxin
	name = "Tranquility"
	color = "#c8a2c8"

/datum/reagent/gondola_mutation_toxin/virtual_domain
	name = "Advanced Tranquility"

/datum/disease/transformation/gondola/virtual_domain
	stage_prob = 9
	new_form = /mob/living/simple_animal/pet/gondola/virtual_domain

/datum/lazy_template/virtual_domain/grasslands_hunt
	name = "Grasslands Hunt"
	desc = "Мирная охота в дикой природе."
	help_text = "Как охотник, вы должны уметь выслеживать и убивать свою добычу. Докажите себя."
	is_modular = TRUE
	key = "grasslands_hunt"
	map_name = "grasslands_hunt"
	mob_modules = list(/datum/modular_mob_segment/deer)
	domain_flags = DOMAIN_NO_NOHIT_BONUS

/datum/lazy_template/virtual_domain/grasslands_hunt/setup_domain(list/created_atoms)
	for(var/obj/effect/landmark/bitrunning/mob_segment/landmark in created_atoms)
		RegisterSignal(landmark, COMSIG_BITRUNNING_MOB_SEGMENT_SPAWNED, PROC_REF(on_spawned))

/datum/lazy_template/virtual_domain/grasslands_hunt/proc/on_spawned(datum/source, list/mobs)
	SIGNAL_HANDLER

	for(var/mob/living/fauna as anything in mobs)
		RegisterSignal(fauna, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/lazy_template/virtual_domain/grasslands_hunt/proc/on_death(datum/source)
	SIGNAL_HANDLER

	add_points(3.5)

/datum/lazy_template/virtual_domain/heretic_hunt
	name = "Heretical Hunt"
	cost = BITRUNNER_COST_LOW
	desc = "Предайте своих товарищей, чтобы достичь высшей силы."
	difficulty = BITRUNNER_DIFFICULTY_LOW
	help_text = "Убивайте экипаж, чтобы набрать очки для ритуала. Когда ритуал завершится, у руны появится зашифрованный ящик — затащите его в сейфхаус и положите на цельную площадку."
	forced_outfit = /datum/outfit/virtual_domain_heretic
	key = "heretic_hunt"
	map_name = "heretic_hunt"
	reward_points = BITRUNNER_REWARD_LOW

// В Heretical Hunt очки начисляются за убийства: старые простые мобы не таскают трупы на руну.
/datum/lazy_template/virtual_domain/heretic_hunt/setup_domain(list/created_atoms)
	for(var/mob/living/simple_animal/hostile/target in created_atoms)
		if(istype(target, /mob/living/simple_animal/hostile/fake_crewman) || \
			istype(target, /mob/living/simple_animal/hostile/nanotrasen) || \
			istype(target, /mob/living/simple_animal/hostile/syndicate))
			target.maxHealth = min(target.maxHealth, 60)
			target.health = target.maxHealth
			target.melee_damage_lower = min(target.melee_damage_lower, 5)
			target.melee_damage_upper = min(target.melee_damage_upper, 8)
			target.faction = list("vdom_fake_crew")
			RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_crew_death))

	var/obj/effect/heretic_rune/big/rune = locate() in created_atoms
	if(rune)
		rune.set_greyscale("#b04a4a")

	for(var/mob/living/simple_animal/hostile/eldritch/raw_prophet/prophet in created_atoms)
		prophet.maxHealth = 30
		prophet.health = 30
		prophet.melee_damage_lower = 3
		prophet.melee_damage_upper = 6

/datum/lazy_template/virtual_domain/heretic_hunt/proc/on_crew_death(datum/source)
	SIGNAL_HANDLER

	var/mob/living/simple_animal/hostile/dead_crewman = source
	var/points = 1
	if(istype(dead_crewman, /mob/living/simple_animal/hostile/fake_crewman))
		var/mob/living/simple_animal/hostile/fake_crewman/fake = dead_crewman
		points = fake.points_value
	else if(istype(dead_crewman, /mob/living/simple_animal/hostile/nanotrasen/ranged/smg) || \
		istype(dead_crewman, /mob/living/simple_animal/hostile/syndicate/ranged/smg))
		points = 2
	add_points(points)

/datum/outfit/virtual_domain_heretic
	name = "Virtual Domain Heretic"

	uniform = /obj/item/clothing/under/color/black
	shoes = /obj/item/clothing/shoes/jackboots
	neck = /obj/item/clothing/neck/stethoscope

/datum/outfit/virtual_domain_heretic/pre_equip(mob/living/carbon/human/user, visuals_only)
	ADD_TRAIT(user, TRAIT_ACT_AS_HERETIC, INNATE_TRAIT)
	ADD_TRAIT(user, TRAIT_NO_TELEPORT, INNATE_TRAIT)
	user.add_faction(FACTION_HERETIC)

/obj/effect/heretic_rune/big
	name = "ritual rune"
	desc = "Кровавый ритуальный круг."
	icon = 'icons/effects/blood.dmi'
	icon_state = "floor1"
	anchored = TRUE
	layer = LOW_OBJ_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/heretic_rune/big/proc/set_greyscale(color)
	color = color

/mob/living/simple_animal/hostile/fake_crewman
	name = "crewmember"
	desc = "Как поживаете, коллеги?"
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "nanotrasen"
	icon_living = "nanotrasen"
	icon_dead = null
	icon_gib = "syndicate_gib"
	gender = MALE
	faction = list(FACTION_HOSTILE, "vdom_fake_crew")
	maxHealth = 40
	health = 40
	melee_damage_lower = 5
	melee_damage_upper = 8
	obj_damage = 8
	attack_sound = 'sound/weapons/tap.ogg'
	loot = list(/obj/item/storage/toolbox)
	del_on_death = TRUE
	var/points_value = 1

/mob/living/simple_animal/hostile/fake_crewman/md
	name = "medical doctor"
	loot = list(/obj/item/circular_saw)
	points_value = 1

/mob/living/simple_animal/hostile/fake_crewman/sec
	name = "security officer"
	icon_state = "nanotrasenranged"
	icon_living = "nanotrasenranged"
	maxHealth = 50
	health = 50
	melee_damage_lower = 6
	melee_damage_upper = 10
	loot = list(/obj/item/melee/baton)
	points_value = 2

/mob/living/simple_animal/hostile/fake_crewman/engi
	name = "engineer"
	loot = list(/obj/item/weldingtool)
	points_value = 1

/mob/living/simple_animal/hostile/fake_crewman/engi/mod
	points_value = 2

/mob/living/simple_animal/hostile/fake_crewman/assistant
	name = "assistant"
	loot = list(/obj/item/kitchen/knife)
	points_value = 1

/mob/living/simple_animal/hostile/fake_crewman/assistant/alt
	loot = list(/obj/item/storage/toolbox/mechanical)

/mob/living/simple_animal/hostile/fake_crewman/boss
	name = "senior crewmember"
	maxHealth = 70
	health = 70
	melee_damage_lower = 8
	melee_damage_upper = 12
	points_value = 3

/mob/living/simple_animal/hostile/fake_crewman/boss/cmo
	name = "chief medical officer"
	loot = list(/obj/item/surgicaldrill)

/mob/living/simple_animal/hostile/fake_crewman/boss/ce
	name = "chief engineer"
	loot = list(/obj/item/gun/energy/e_gun)

/mob/living/simple_animal/hostile/fake_crewman/boss/hos
	name = "head of security"
	icon_state = "nanotrasenrangedsmg"
	icon_living = "nanotrasenrangedsmg"
	maxHealth = 90
	health = 90
	loot = list(/obj/item/gun/energy/e_gun/hos)

/datum/lazy_template/virtual_domain/hierophant
	name = "Zealot Arena"
	cost = BITRUNNER_COST_HIGH
	desc = "Танцуйте, марионетки, танцуйте!"
	difficulty = BITRUNNER_DIFFICULTY_HIGH
	forced_outfit = /datum/outfit/job/miner
	key = "hierophant"
	map_name = "hierophant"
	reward_points = BITRUNNER_REWARD_HIGH

/datum/lazy_template/virtual_domain/hierophant/setup_domain(list/created_atoms)
	for(var/mob/living/simple_animal/hostile/megafauna/hierophant/zealot in created_atoms)
		zealot.maxHealth = 1500
		zealot.health = 1500

/datum/lazy_template/virtual_domain/island_brawl
	name = "Island Brawl"
	announce_to_ghosts = TRUE
	cost = BITRUNNER_COST_HIGH
	desc = "«Мирный» остров, затерянный посреди ниоткуда. Карта завершится автоматически после определённого числа смертей."
	difficulty = BITRUNNER_DIFFICULTY_HIGH
	forced_outfit = /datum/outfit/beachbum_combat
	help_text = "По острову могут быть разбросаны награды, но главная цель — выжить. Смерти на острове пойдут в итоговый счёт."
	key = "island_brawl"
	map_name = "island_brawl"
	reward_points = BITRUNNER_REWARD_HIGH
	domain_flags = DOMAIN_NO_LINKED_DAMAGE
	secondary_loot = list(
		/obj/item/toy/beach_ball = 2,
		/obj/item/clothing/shoes/sandal = 1,
		/obj/item/clothing/glasses/sunglasses = 1,
		/obj/item/gun/energy/laser/chameleon = 1,
		/obj/item/disk/bitrunning/item/mini_uzi = 1,
	)

/datum/lazy_template/virtual_domain/island_brawl/setup_domain(list/created_atoms)
	for(var/obj/effect/mob_spawn/human/virtual_domain/islander/spawner in created_atoms)
		custom_spawns += spawner

		RegisterSignal(spawner, COMSIG_QDELETING, PROC_REF(on_spawner_qdeleted))
		RegisterSignals(spawner, list(COMSIG_GHOSTROLE_SPAWNED, COMSIG_BITRUNNER_SPAWNED), PROC_REF(on_spawn))

/datum/lazy_template/virtual_domain/island_brawl/proc/on_spawner_qdeleted(obj/effect/mob_spawn/human/virtual_domain/islander/source)
	SIGNAL_HANDLER

	custom_spawns -= source
	UnregisterSignal(source, COMSIG_QDELETING)

/datum/lazy_template/virtual_domain/island_brawl/proc/on_spawn(datum/source, mob/living/spawned_mob)
	SIGNAL_HANDLER

	RegisterSignals(spawned_mob, list(COMSIG_LIVING_DEATH), PROC_REF(on_death))

/datum/lazy_template/virtual_domain/island_brawl/proc/on_death(datum/source, gibbed)
	SIGNAL_HANDLER

	add_points(1)

/obj/effect/mob_spawn/human/virtual_domain/islander
	name = "Islander"
	outfit = /datum/outfit/beachbum_combat
	mob_name = "a combat beach bum"
	short_desc = "Вы — виртуальный островитянин."
	flavour_text = "Не позволяйте никому испортить ваш идиллический курорт. Договаривайтесь с другими... или не договаривайтесь!"
	can_load_appearance = TRUE

/datum/lazy_template/virtual_domain/meta_central
	name = "Meta Central"
	cost = BITRUNNER_COST_LOW
	desc = "Время от времени рабочие требуют у Nanotrasen прав. Это невыгодно."
	difficulty = BITRUNNER_DIFFICULTY_LOW
	forced_outfit = /datum/outfit/job/security
	help_text = "Ответьте на требования рабочих санкционированным насилием. Соберите ценные материалы, которые могут быть разбросаны вокруг. И помните свою подготовку: всегда исходите из того, что они виновны, — в медбее они могут во всём признаться... Или что-то в этом роде."
	is_modular = TRUE
	key = "meta_central"
	map_name = "meta_central"
	mob_modules = list(/datum/modular_mob_segment/revolutionary)
	reward_points = BITRUNNER_REWARD_LOW
	announce_to_ghosts = TRUE

/datum/lazy_template/virtual_domain/pipedream
	name = "Disposal Pipe Factory"
	cost = BITRUNNER_COST_LOW
	desc = "Заброшенная и заражённая фабрика по производству труб для утилизации."
	difficulty = BITRUNNER_DIFFICULTY_LOW
	completion_loot = list(/obj/item/stack/rods = 1)
	help_text = "Ещё недавно это место кипело жизнью. Похоже, рабочие ушли в спешке, и теперь производительность на нуле. Что-то должно было разгромить это место, но что?"
	is_modular = TRUE
	key = "pipedream"
	map_name = "pipedream"
	mob_modules = list(
		/datum/modular_mob_segment/hivebots,
		/datum/modular_mob_segment/hivebots_strong
	)
	reward_points = BITRUNNER_REWARD_LOW

/datum/id_trim/factory
	assignment = "Factory Worker"
	trim_state = "trim_cargotechnician"
	department_color = COLOR_CARGO_BROWN
	subdepartment_color = COLOR_CARGO_BROWN
	sechud_icon_state = SECHUD_CARGO_TECHNICIAN
	access = list(
		ACCESS_AWAY_SUPPLY
		)

/datum/id_trim/factory/qm
	assignment = "Factory Quartermaster"
	trim_state = "trim_quartermaster"
	department_color = COLOR_COMMAND_BLUE
	subdepartment_color = COLOR_CARGO_BROWN
	department_state = "departmenthead"
	sechud_icon_state = SECHUD_QUARTERMASTER
	access = list(
		ACCESS_AWAY_SUPPLY,
		ACCESS_AWAY_COMMAND
		)

/obj/item/card/id/advanced/factory
	name = "factory worker ID"

/obj/item/card/id/advanced/factory/qm
	name = "factory quartermaster ID"

// Экипировка
/datum/outfit/factory
	name = "Factory Worker"

	id_
	id = /obj/item/card/id/advanced/
	uniform = /obj/item/clothing/under/rank/cargo/tech
	suit = /obj/item/clothing/suit/hazardvest
	belt = /obj/item/radio
	gloves = /obj/item/clothing/gloves/color/black
	head = /obj/item/clothing/head/soft/yellow
	shoes = /obj/item/clothing/shoes/workboots
	l_pocket = /obj/item/flashlight/seclite

/datum/outfit/factory/guard
	name = "Factory Guard"

	uniform = /obj/item/clothing/under/rank/security/officer/grey
	suit = /obj/item/clothing/suit/armor/vest/alt
	belt = /obj/item/radio
	gloves = /obj/item/clothing/gloves/color/black
	head = /obj/item/clothing/head/soft/sec
	shoes = /obj/item/clothing/shoes/jackboots/sec
	l_pocket = /obj/item/restraints/handcuffs
	r_pocket = /obj/item/assembly/flash/handheld

/datum/outfit/factory/qm
	name = "Factory Quartermaster"

	id_
	id = /obj/item/card/id/advanced
	uniform = /obj/item/clothing/under/rank/cargo/qm
	belt = /obj/item/radio
	gloves = /obj/item/clothing/gloves/color/black
	head = /obj/item/clothing/head/soft/yellow
	shoes = /obj/item/clothing/shoes/jackboots/sec
	l_pocket = /obj/item/melee/classic_baton
	r_pocket = /obj/item/stamp/qm

// Трупы
/obj/effect/mob_spawn/human/corpse/factory
	name = "Factory Worker"
	outfit = /datum/outfit/factory
	icon_state = "corpsecargotech"

/obj/effect/mob_spawn/human/corpse/factory/guard
	name = "Factory Guard"
	outfit = /datum/outfit/factory/guard
	icon_state = "corpsecargotech"

/obj/effect/mob_spawn/human/corpse/factory/qm
	name = "Factory Quartermaster"
	outfit = /datum/outfit/factory/qm
	icon_state = "corpsecargotech"

/datum/lazy_template/virtual_domain/pirates
	name = "Corsair Cove"
	announce_to_ghosts = TRUE
	cost = BITRUNNER_COST_MEDIUM
	desc = "Пробивайтесь к спрятанному сокровищу, забирайте добычу и уходите, пока пираты не переломили ход боя."
	difficulty = BITRUNNER_DIFFICULTY_MEDIUM
	help_text = "Наденьте предложенную одежду, чтобы слиться с толпой, затем прорубитесь через враждебных пиратов. Хватайте сокровище и уходите, пока вас не задавили числом!"
	key = "pirates"
	map_name = "pirates"
	reward_points = BITRUNNER_REWARD_MEDIUM

/datum/lazy_template/virtual_domain/psyker_shuffle
	name = "Crate Chaos"
	cost = BITRUNNER_COST_LOW
	desc = "Проберитесь в заброшенный уголок виртуального мира, где хранятся все ящики. Внимание — виртуальный домен не поддерживает визуализацию. Задание нужно выполнять с помощью эхолокации."
	difficulty = BITRUNNER_DIFFICULTY_MEDIUM
	forced_outfit = /datum/outfit/echolocator
	help_text = "Привыкнуть к эхолокации может быть трудно. Не забывайте двигаться медленно и внимательно осматривать каждый ящик."
	key = "psyker_shuffle"
	map_name = "psyker_shuffle"
	reward_points = BITRUNNER_REWARD_HIGH

/datum/lazy_template/virtual_domain/psyker_shuffle/setup_domain(list/created_atoms)
	. = ..()

	for(var/obj/structure/closet/crate/crate in created_atoms)
		if(crate.GetComponent(/datum/component/bitrunning_crate_identify))
			continue
		crate.AddComponent(/datum/component/bitrunning_crate_identify)

/datum/component/bitrunning_crate_identify
	var/identifying = FALSE

/datum/component/bitrunning_crate_identify/Initialize()
	if(!istype(parent, /obj/structure/closet/crate))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/datum/component/bitrunning_crate_identify/proc/on_examine(datum/source, mob/examiner, list/examine_text)
	SIGNAL_HANDLER

	if(!ishuman(examiner) || identifying || get_dist(parent, examiner) > 1)
		return
	identifying = TRUE
	examine_text += span_notice("Можно на миг сосредоточиться на ящике, чтобы опознать его.")
	INVOKE_ASYNC(src, PROC_REF(identify_crate), examiner)

/datum/component/bitrunning_crate_identify/proc/identify_crate(mob/living/user)
	if(!do_after(user, 2 SECONDS, target = parent))
		identifying = FALSE
		return
	if(QDELETED(parent) || get_dist(parent, user) > 1)
		identifying = FALSE
		return

	var/obj/structure/closet/crate/crate = parent
	if(istype(crate, /obj/structure/closet/crate/secure/bitrunning/encrypted))
		to_chat(user, span_notice("Замок ящика совпадает с замком целевого кэша."))
	else
		to_chat(user, span_warning("Это обычный ящик."))
	identifying = FALSE

/obj/structure/closet/crate/secure/weapon/psyker_zombies
	desc = "Оружейный ящик, забитый снаряжением для зачистки заражённого домена."

/obj/structure/closet/crate/secure/weapon/psyker_zombies/PopulateContents()
	. = ..()
	new /obj/item/clothing/suit/space/hardsuit/security/hos(src)
	new /obj/item/gun/energy/laser(src)
	new /obj/item/stock_parts/cell/high(src)
	new /obj/item/stock_parts/cell/high(src)

/datum/lazy_template/virtual_domain/psyker_zombies
	name = "Infected Domain"
	cost = BITRUNNER_COST_MEDIUM
	desc = "Ещё один заброшенный уголок виртуального мира. Этот пришлось оставить из-за зомби-вируса. Внимание — виртуальный домен не поддерживает визуализацию. Задание нужно выполнять с помощью эхолокации."
	difficulty = BITRUNNER_DIFFICULTY_MEDIUM
	completion_loot = list(/obj/item/radio/headset = 1)
	forced_outfit = /datum/outfit/echolocator
	help_text = "Этот некогда любимый виртуальный домен был испорчен вирусом, из-за чего стал нестабильным, полным дыр и ЗОМБИ! Где-то рядом должен быть таинственный ящик, который поможет вам вооружиться. Вооружайтесь и закончите то, что начала киберполиция!"
	key = "psyker_zombies"
	map_name = "psyker_zombies"
	reward_points = BITRUNNER_REWARD_HIGH

// Адаптация Ancient Military Simulator под старую базу: используются существующие прототипы.
/datum/lazy_template/virtual_domain/ancient_milsim
	name = "Ancient Military Simulator"
	announce_to_ghosts = TRUE
	cost = BITRUNNER_COST_HIGH
	desc = "Воссоздайте события давно минувшей «горячей» части Пограничной войны в роли ударной группы Солариан, зачищающей базы CIN; при поддержке энтузиастов-реконструкторов SolFed. Многопользовательское прохождение и тщательная подготовка настоятельно рекомендуются."
	completion_loot = list(
		/obj/item/stack/spacecash/c500 = 4,
		/obj/item/storage/firstaid/regular = 2,
		/obj/item/clothing/suit/armor/vest = 2,
		/obj/item/gun/ballistic/automatic/pistol = 2,
	)
	difficulty = BITRUNNER_DIFFICULTY_HIGH
	help_text = "Последняя часть домена может оказаться весьма PvP-ориентированной. Лучше не ходить одному и пронести с собой диски способностей и снаряжения."
	forced_outfit = /datum/outfit/solfed_bitrun
	key = "ancient_milsim"
	map_name = "skyrat_ancientmilsim"
	reward_points = BITRUNNER_REWARD_HIGH
	mob_modules = list(/datum/modular_mob_segment/cin_mobs)
	secondary_loot = list(
		/obj/item/stack/spacecash/c500 = 3,
		/obj/item/disk/bitrunning/item/ancient_milsim = 3,
		/obj/item/choice_beacon/ancient_milsim = 2,
		/obj/item/gun/ballistic/automatic/pistol = 2,
		/obj/item/storage/firstaid/regular = 2,
		/obj/item/grenade/empgrenade = 2,
		/obj/item/clothing/suit/armor/vest = 2,
	)

/datum/outfit/solfed_bitrun
	name = "Bitrunning SolFed Marine"

	uniform = /obj/item/clothing/under/syndicate
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	back = /obj/item/storage/backpack/security
	mask = /obj/item/clothing/mask/balaclava
	id = /obj/item/card/id/advanced

/datum/outfit/solfed_bitrun/post_equip(mob/living/carbon/human/user, visuals_only)
	. = ..()
	var/obj/item/card/id/id_card = user.wear_id
	if(istype(id_card))
		id_card.registered_name = user.real_name
		id_card.update_label()
/area/virtual_domain/ancient_milsim
	name = "intro_2"
	icon_state = "unknown"

/area/virtual_domain/ancient_milsim/entrance
	name = "'Time Of Valor 2' Entrance Area"
	icon_state = "awaycontent1"

/area/virtual_domain/ancient_milsim/janitor
	name = "'Time Of Valor 2' Janitor's Closet"
	icon_state = "awaycontent2"

/area/virtual_domain/ancient_milsim/medbay
	name = "'Time Of Valor 2' Medbay"
	icon_state = "awaycontent3"

/area/virtual_domain/ancient_milsim/atrium
	name = "'Time Of Valor 2' Atrium"
	icon_state = "awaycontent4"

/area/virtual_domain/ancient_milsim/hallway
	name = "'Time Of Valor 2' Hallway"
	icon_state = "awaycontent5"

/area/virtual_domain/ancient_milsim/maintenance
	name = "'Time Of Valor 2' Maintenance Tunnel"
	icon_state = "awaycontent7"

/area/virtual_domain/ancient_milsim/loot_camp
	name = "'Time Of Valor 2' CIN Encampment"
	icon_state = "awaycontent7"

/area/virtual_domain/ancient_milsim/snpc_ground
	name = "'Time Of Valor 2' SNPC Fighting Ground"
	icon_state = "awaycontent8"

/area/virtual_domain/ancient_milsim/carrier
	name = "'Time Of Valor 2' Ruined APC"
	icon_state = "awaycontent9"

/area/virtual_domain/ancient_milsim/snpc_hallway
	name = "'Time Of Valor 2' SNPC Base Hallway"
	icon_state = "awaycontent10"

/area/virtual_domain/ancient_milsim/snpc_bar
	name = "'Time Of Valor 2' SNPC Base Bar"
	icon_state = "awaycontent11"

/area/virtual_domain/ancient_milsim/snpc_garage
	name = "'Time Of Valor 2' SNPC Base Garage"
	icon_state = "awaycontent12"

/area/virtual_domain/ancient_milsim/snpc_cafe
	name = "'Time Of Valor 2' SNPC Base Cafeteria"
	icon_state = "awaycontent13"

/area/virtual_domain/ancient_milsim/snpc_toilet
	name = "'Time Of Valor 2' SNPC Base Restroom"
	icon_state = "awaycontent14"

/area/virtual_domain/ancient_milsim/snpc_cave
	name = "'Time Of Valor 2' SNPC Base Maintenance Cave"
	icon_state = "awaycontent15"

/area/virtual_domain/ancient_milsim/snpc_reward
	name = "'Time Of Valor 2' SNPC Base Reward Room"
	icon_state = "awaycontent16"

/area/virtual_domain/ancient_milsim/snpc_exit
	name = "'Time Of Valor 2' SNPC Base Exit Tunnel"
	icon_state = "awaycontent17"

/area/virtual_domain/protected_space/ancient_milsim
	name = "'Time Of Valor 2' Secret Encounter"
	icon_state = "awaycontent18"

/datum/lazy_template/virtual_domain/stairs_and_cliffs
	name = "Glacier Grind"
	cost = BITRUNNER_COST_LOW
	desc = "Предательский подъём, который переживут немногие смельчаки. Зато отличная кардиотренировка."
	help_text = "Слышали о «Змейках и лестницах»? Всё то же самое, только вместо лестниц — ступени, а вместо змей — крутой обрыв вниз, на острые камни или жидкую плазму."
	difficulty = BITRUNNER_DIFFICULTY_LOW
	completion_loot = list(/obj/item/clothing/suit/snowman = 2)
	secondary_loot = list(/obj/item/clothing/shoes/wheelys = 2, /obj/item/clothing/head/ushanka = 1)
	forced_outfit = /datum/outfit/job/virtual_domain_iceclimber
	key = "stairs_and_cliffs"
	map_name = "stairs_and_cliffs"
	reward_points = BITRUNNER_REWARD_MEDIUM
	domain_flags = DOMAIN_NO_NOHIT_BONUS

/turf/open/cliff/snowrock/virtual_domain
	name = "icy cliff"
	initial_gas_mix = FROZEN_ATMOS

/turf/open/lava/plasma/virtual_domain
	name = "plasma lake"
	initial_gas_mix = FROZEN_ATMOS

/datum/outfit/job/virtual_domain_iceclimber
	name = "Ice Climber"

	uniform = /obj/item/clothing/under/color/grey
	backpack = /obj/item/storage/backpack/duffelbag
	shoes = /obj/item/clothing/shoes/winterboots
	suit = /obj/item/clothing/suit/hooded/wintercoat
	l_pocket = /obj/item/flashlight/flare/torch

/datum/lazy_template/virtual_domain/syndicate_assault
	name = "Syndicate Assault"
	announce_to_ghosts = TRUE
	cost = BITRUNNER_COST_MEDIUM
	desc = "Проникните на вражеский корабль и верните украденный груз."
	difficulty = BITRUNNER_DIFFICULTY_MEDIUM
	completion_loot = list(/obj/item/toy/plush/nukeplushie = 1)
	help_text = "Группа оперативников Синдиката украла ценный груз со станции. Они поднялись на свой корабль и пытаются скрыться. Проникните на их корабль и верните ящик. Осторожно: они очень хорошо вооружены."
	is_modular = TRUE
	key = "syndicate_assault"
	map_name = "syndicate_assault"
	mob_modules = list(/datum/modular_mob_segment/syndicate_team)
	reward_points = BITRUNNER_REWARD_MEDIUM

/datum/lazy_template/virtual_domain/test_only
	name = "Test Only"
	key = "test_only"
	map_name = "test_only"
	domain_flags = DOMAIN_TEST_ONLY

/datum/lazy_template/virtual_domain/test_only/expensive
	key = "test_only_expensive"
	cost = 3

/datum/lazy_template/virtual_domain/vaporwave
	name = "Cosmic Vestige"
	cost = BITRUNNER_COST_EXTREME
	desc = "Подвешенная в безмолвной пустоте космоса, Неоновая Реликвия — жутковатое эхо ретро-футуристической эпохи. Расслабьтесь, полюбуйтесь видом."
	difficulty = BITRUNNER_DIFFICULTY_NONE
	completion_loot = list(/obj/item/stack/spacecash/c500 = 4)
	key = "vaporwave"
	map_name = "vaporwave"
	reward_points = BITRUNNER_REWARD_EXTREME
	domain_flags = DOMAIN_NO_NOHIT_BONUS

/datum/lazy_template/virtual_domain/wendigo
	name = "Glacial Devourer"
	cost = BITRUNNER_COST_HIGH
	desc = "Легенды гласят о прожорливом Вендиго, скрывающемся глубоко в пещерах Айсмуна."
	difficulty = BITRUNNER_DIFFICULTY_HIGH
	forced_outfit = /datum/outfit/job/miner
	key = "wendigo"
	map_name = "wendigo"
	reward_points = BITRUNNER_REWARD_HIGH

/datum/status_effect/gutted
	id = "gutted"
	duration = -1
	alert_type = null

/obj/effect/mob_spawn/human/corpse/bitrunner/special(mob/living/spawned_mob)
	. = ..()
	spawned_mob.apply_status_effect(/datum/status_effect/gutted)

/obj/effect/mob_spawn/human/corpse/cyber_police/special(mob/living/spawned_mob)
	. = ..()
	spawned_mob.apply_status_effect(/datum/status_effect/gutted)

/datum/lazy_template/virtual_domain/xeno_nest
	name = "Xeno Infestation"
	cost = BITRUNNER_COST_LOW
	desc = "Сканеры нашего корабля обнаружили формы жизни неизвестного происхождения. Попытки дружественного контакта с ними провалились."
	difficulty = BITRUNNER_DIFFICULTY_LOW
	completion_loot = list(/obj/item/toy/plush/lizardplushie = 1)
	help_text = "Вы на бесплодной планете, кишащей враждебными существами. Здесь есть ящик, он не спрятан — просто охраняется. Ожидайте сопротивления."
	is_modular = TRUE
	key = "xeno_nest"
	map_name = "xeno_nest"
	mob_modules = list(/datum/modular_mob_segment/xenos)
	reward_points = BITRUNNER_REWARD_LOW
