/obj/effect/mob_spawn/human/ftu_crew
	name = "Trade ship worker"
	desc = "A cryo-sleep cell made with unknown materials."
	anchored = TRUE
	density = FALSE
	job_description = "FTU worker"
	random = TRUE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "oldpod"
	mob_name = "a trader"
	outfit = /datum/outfit/ftu/crew
	can_load_appearance = TRUE
	loadout_enabled = FALSE
	roundstart = FALSE
	death = FALSE
	short_desc = "You are a Trader."
	flavour_text = "Вы член экипажа торгового корабля и по совместительству член Свободного Торгового Объединения (FTU). Бюрократический отдел наконец то уладил все формальности и корабли полные груза на продажу хлынули в этот сектор. Заработай как можно больше денег на продаже груза. Не нарушайте законы сектора, мы должны держать репутацию предельно чистой, но всегда держите заработок в приоретете. Если есть возможность провести сделку в обход законов, не стесняйтесь воспользоваться ей. Ты подчиняешься квартирмейстеру судна."
	important_info = "Вам запрещено использовать товар или присваивать товар корабля себе. Не нападайте и не грабьте станцию, вы здесь для ведения торговли. Если на вас совершили нападение или украли товар, то вы можете применить силу в ответ."
	assignedrole = "FTU worker"
	antagonist_type = /datum/antagonist/ghost_role/traders
	category = "midround"

/obj/effect/mob_spawn/human/ftu_crew/qm
	name = "Trade ship QM"
	job_description = "FTU QM"
	mob_name = "a QM"
	outfit = /datum/outfit/ftu/qm
	short_desc = "You are a QM."
	flavour_text = "Вы член экипажа торгового корабля и по совместительству член Свободного Торгового Объединения (FTU). Бюрократический отдел наконец то уладил все формальности и корабли полные груза на продажу хлынули в этот сектор. Заработай как можно больше денег на продаже груза. Не нарушайте законы сектора, мы должны держать репутацию предельно чистой, но всегда держите заработок в приоретете. Вы являетесь ответственным лицом за груз судна. Остальные работники находятся у вас в подчинении. Станьте богатым."
	important_info = "Вам запрещено использовать товар или присваивать товар корабля себе. Не нападайте и не грабьте станцию, вы здесь для ведения торговли. Если на вас совершили нападение или украли товар, то вы можете применить силу в ответ."
	assignedrole = "FTU QM"

/obj/effect/mob_spawn/human/ftu_crew/sec
	name = "Trade ship security"
	job_description = "FTU security officer"
	mob_name = "a security"
	outfit = /datum/outfit/ftu/solder
	short_desc = "You are a security."
	flavour_text = "Вы член экипажа торгового корабля и по совместительству член Свободного Торгового Объединения (FTU). Бюрократический отдел наконец то уладил все формальности и корабли полные груза на продажу хлынули в этот сектор. Заработай как можно больше денег на продаже груза. Не нарушайте законы сектора, мы должны держать репутацию предельно чистой, но всегда держите заработок в приоретете. Вы наняты для охраны груза от пиратов и неблагоприятных клиентов. Ты подчиняешься квартирмейстеру судна."
	important_info = "Вам запрещено использовать товар или присваивать товар корабля себе. Не нападайте и не грабьте станцию, вы здесь для ведения торговли. Если на вас совершили нападение или украли товар, то вы можете применить силу в ответ."
	assignedrole = "FTU security officer"

/obj/machinery/suit_storage_unit/ftu_combat
	suit_type = /obj/item/clothing/suit/space/hardsuit/security/ftu

/obj/machinery/suit_storage_unit/ftu_work
	suit_type = /obj/item/clothing/suit/space/hardsuit/engine/ftu

/obj/item/paper/fluff/traid_ship/qm
	name = "Отчёт о мисии"

/obj/structure/sign/ftu_display
	name = "Ship display"
	desc = "Дисплей с логотипом Объединения Свободных Торговцев."
	icon = 'modular_bluemoon/Ren/Icons/Obj/decale.dmi'
	icon_state = "ftu_display"

/obj/item/paper/fluff/traid_ship/qm/Initialize(mapload)
	. = ..()
	var/report_text = "<h2>Отчёт о миссии</h2><p>Бюрократический отдел торгового флота закончил оформление всех разрешений и лицензий в данном секторе.<br />Вы отправляетесь в числе первых для ведения торговли с местными обитателями. Вы являетесь материально ответственным лицом за груз, находящийся в трюме.</p><p>Стоимость груза превышает 100 тысяч кредитов и ваша цель заработать как можно больше с его продажи. После вычета всех коммисий и отчислений, остаток будет передан вам. В вашем подчинении находятся два техника и два сотрудника охраны.</p><p>Вернитесь богатым или мы отдадим ваше место кому нибудь более способному.</p>"
	icon_state = "paper_words"
	item_state = "paper"
	add_raw_text(report_text)
	update_appearance()
	update_icon()

/obj/item/paper/fluff/traid_ship/old/Initialize(mapload)
	. = ..()
	var/report_text = "<p>Держи шкафы закрытыми и прикручеными к полу. Не выставляй весь товар сразу.<br />Эти ёбаные пидарасы с телепортами только и ждут момента, что бы всё украсть.&nbsp;<br />Если что то пропало, сразу иди искать их и отстрели им анус.</p>"
	icon_state = "paper_words"
	item_state = "paper"
	add_raw_text(report_text)
	update_appearance()
	update_icon()

/datum/round_event_control/ftu_trader
	name = "Trade ship"
	typepath = /datum/round_event/ftu_trader
	weight = 10
	max_occurrences = 1
	min_players = 15
	category = EVENT_CATEGORY_FRIENDLY
	description = "A trader ship full of goodys."
	var/ship_template

/datum/round_event/ftu_trader
	announce_when = 1
	start_when = 1

/datum/round_event/ftu_trader/announce(fake)
	priority_announce("Корабль Свободного торгового объединения получил разрешение на стыковку и пересёк границы сектора. Можете потратить свои честно заработанные деньги на их товары.","Бюрократический отдел ЦК", 'sound/announcer/classic/traider_announce.ogg')

/datum/round_event_control/ftu_trader/preRunEvent()
	if (!SSmapping.empty_space)
		return EVENT_CANT_RUN

	return ..()

/datum/round_event/ftu_trader/start()
	spawn_ftu_trader()

/proc/spawn_ftu_trader(ship_template)
	ship_template = /datum/map_template/shuttle/ftu_tradeship

	var/datum/map_template/shuttle/ship = new ship_template
	var/x = rand(TRANSITIONEDGE,world.maxx - TRANSITIONEDGE - ship.width)
	var/y = rand(TRANSITIONEDGE,world.maxy - TRANSITIONEDGE - ship.height)
	var/z = SSmapping.empty_space.z_value
	var/turf/T = locate(x,y,z)
	if(!T)
		CRASH("Skipjack found no turf to load in")

	if(!ship.load(T))
		CRASH("Loading Skipjack ship failed!")

	var/list/spawners_list = list()
	for(var/turf/A in ship.get_affected_turfs(T))
		for(var/obj/effect/mob_spawn/human/spawner in A)
			if(!istype(spawner, /obj/effect/mob_spawn/human/ftu_crew))
				continue
			spawners_list += spawner

	var/list/candidates = pollGhostCandidates("Do you wish to be considered for Free trader?", ROLE_GHOSTROLE, minimum_required = spawners_list.len)

	for(var/obj/effect/mob_spawn/human/spawner in spawners_list)
		if(LAZYLEN(candidates))
			var/mob/our_candidate = pick_n_take(candidates)
			spawner.create(our_candidate.ckey)
			notify_ghosts("Skipjack has an object of interest: [our_candidate]!", source=our_candidate, action=NOTIFY_ORBIT, header="Something's Interesting!")
		else
			notify_ghosts("Skipjack ship has an object of interest: [spawner]!", source=spawner, action=NOTIFY_ORBIT, header="Something's Interesting!")

/area/shuttle/ftu_trade
	name = "Iron Turtle"
	ambientsounds = HIGHSEC

/datum/map_template/shuttle/ftu_tradeship
	prefix = "_maps/shuttles/bluemoon/"
	port_id = "ftu"
	suffix = "tradeship"
	name = "Iron Turtle Shuttle"
	description = "Стандартный корабль объеденённого торгового флота для совершения мелких сделок"

/obj/machinery/computer/shuttle/ftu_tradeship
	name = "Iron Turtle Control"
	desc = "Used to control the Iron Turtle."
	icon_keyboard = "inteq_key"
	icon_screen = "inteqshuttle"
	light_color = LIGHT_COLOR_ORANGE
	circuit = /obj/item/circuitboard/computer/ftu_tradeship
	shuttleId = "ftu"
	possible_destinations = "ftu_tradeship_custom;ftu_tradeship_home;whiteship_home"

/obj/item/circuitboard/computer/ftu_tradeship
	name = "Iron Turtle Console (Computer Board)"
	build_path = /obj/machinery/computer/shuttle/ftu_tradeship

/obj/machinery/computer/camera_advanced/shuttle_docker/ftu_tradeship
	name = "Iron Turtle Computer"
	desc = "The Navigation console for the Iron Turtle."
	icon_keyboard = "inteq_key"
	icon_screen = "inteqshuttle"
	light_color = LIGHT_COLOR_ORANGE
	shuttleId = "ftu"
	lock_override = NONE
	shuttlePortId = "ftu_tradeship_custom"
	jump_to_ports = list("whiteship_away" = 1, "whiteship_home" = 1, "whiteship_z4" = 1)
	view_range = 14
	x_offset = 7
	y_offset = 1

/area/ruin/space/has_grav/ftu_cargo
	name = "FTU Cargo ship"

/area/ruin/space/has_grav/powered/infestedship
	name = "Warbringer"

/area/ruin/space/has_grav/droneship
	name = "NT drone ship"

/area/ruin/space/has_grav/powered/drugpost
	name = "Pirat secret post"

/area/ruin/space/has_grav/powered/fisherstore
	name = "Fishing store"

/area/ruin/space/has_grav/powered/clockworkhaven
	name = "Ratvar citadel"

/datum/map_template/ruin/space/ftuship
	name = "Cargo ship"
	description = "Захваченый пиратами корабль."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "cargodiselost.dmm"
	id = "cargodiselost"

datum/map_template/ruin/space/vaulttango
	name = "Vault Tango"
	description = "Малый пункт базирования интека"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "vaulttango.dmm"
	id = "vaulttango"

/datum/map_template/ruin/space/rusprison
	name = "Russuan prison ship"
	description = "Корабль русских, перевозящщий заключёных"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "rusprison.dmm"
	id = "rusprison"

/datum/map_template/ruin/space/infested_frigate
	name = "Infested frigate"
	description = "Корабль русских, перевозящщий заключёных"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "infested_frigate.dmm"
	id = "infested_frigate"

/datum/map_template/ruin/space/shuttle8532
	name = "Shuttle 8532"
	description = "Обломки корабля"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "shuttle8532.dmm"
	id = "shuttle8532"

/datum/map_template/ruin/space/droneship
	name = "Droneship"
	description = "Рядовой корабль Нанотранзен, вооружённый боевыми дронами"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "droneship.dmm"
	id = "droneship"

/datum/map_template/ruin/space/drugpost
	name = "Drugpost"
	description = "Небольшой пост пиратов по производству наркотиков"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "drugpost.dmm"
	id = "drugpost"

/datum/map_template/ruin/space/clockworkhaven
	name = "Clockworkhaven"
	description = "Цитадель ратвара посреди космоса"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "clockworkhaven.dmm"
	id = "clockworkhaven"

/datum/map_template/ruin/space/fisherstore
	name = "Fishing store"
	description = "Рыболовный магазин"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "fisher_store.dmm"
	id = "fisher_store"
