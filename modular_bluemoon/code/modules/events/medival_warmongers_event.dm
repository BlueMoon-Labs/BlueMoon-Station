/datum/round_event_control/medieval_warmongers
	name = "Medieval Warmongers"
	typepath = /datum/round_event/medieval_warmongers
	weight = 15
	max_occurrences = 1
	min_players = 35
	earliest_start = 40 MINUTES
	category = EVENT_CATEGORY_INVASION
	severity = DIRECTOR_SEVERITY_GHOST // антаги из призраков - гост-пул, а не общий MAJOR
	cost = 15
	intensity = 45
	intensity_linger = 45 MINUTES // штурм живёт заметно дольше спавнера
	antag_heavy = TRUE // командный асолт: мягкие профили такое выключают
	family = "warmongers" // с рулсетом-двойником динамика (он запускает это же событие): не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // не экста и не лайт
	description = "Medieval space pirates will demand homage or assault the station."

/datum/round_event_control/medieval_warmongers/preRunEvent(admin_window = TRUE)
	if(!SSmapping.empty_space && !length(SSmapping.levels_by_trait(ZTRAIT_SPACE_RUINS)) && !SSmapping.station_start)
		return EVENT_CANT_RUN

/datum/round_event/medieval_warmongers
	var/warmongers_spawned = FALSE
	var/spawn_timer_id

/datum/round_event/medieval_warmongers/start()
	send_warmonger_threat()

/datum/round_event/medieval_warmongers/proc/send_warmonger_threat()
	var/datum/comm_message/threat_msg = new
	var/payoff = 0
	var/payoff_min = 30000
	var/ship_template
	var/ship_name = "Medieval Warmongers"
	var/initial_send_time = world.time
	var/response_max_time = 5 MINUTES

	ship_name = pick(strings(PIRATE_NAMES_FILE, "medieval_names"))

	priority_announce("Входящая подпространственная передача данных. Открыт защищенный канал связи на всех коммуникационных консолях.", "Запрос Дани", SSstation.announcer.get_rand_report_sound(), has_important_message = TRUE)
	ship_template = /datum/map_template/shuttle/medieval
	threat_msg.title = "ЗАПРОС ДАНИ"
	threat_msg.possible_answers = list("Ладно, я не хочу заклеивать череп изолентой.","Вы придурки, поищите лохов в другом месте.")
	var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(D)
		payoff = max(payoff_min, FLOOR(D.account_balance * 0.85, 1000))
	else
		payoff = payoff_min
	threat_msg.content = "ПРИВЕТСТВУЮ ВАС, ЭТО [ship_name] И МЫ СОБИРАЕМ ДЕНЬГИ ИЗ ВАССАЛОВ НА НАШЕЙ ТЕРРИТОРИИ, ТАК УЖ СЛУЧИЛОСЬ, ЧТО ВЫ ТОЖЕ ТАМ ОКАЗАЛИСЬ!! ОБЫЧНО МЫ УБИВАЕМ ТАКИХ СЛАБАКОВ, КАК ВЫ, ЗА ТО, ЧТО ОНИ ВТОРГЛИСЬ НА НАШУ ЗЕМЛЮ, НО МЫ ГОТОВЫ ПРИВЕТСТВОВАТЬ ВАС В НАШЕМ ПРОСТРАНСТВЕ, ЕСЛИ ВЫ ЗАПЛАТИТЕ [payoff] В ЗНАК УВАЖЕНИЯ К НАШЕМУ ЗАКОНУ. БУДЬТЕ МУДРЫ В СВОЕМ ВЫБОРЕ!! (отправить сообщение. отправить сообщение. почему сообщение не отправлено?)."

	threat_msg.answer_callback = CALLBACK(src, PROC_REF(warmongers_answered), threat_msg, payoff, ship_name, initial_send_time, response_max_time, ship_template)
	SScommunications.send_message(threat_msg, unique = TRUE)
	spawn_timer_id = addtimer(CALLBACK(src, PROC_REF(spawn_warmongers), threat_msg, ship_template), response_max_time, TIMER_STOPPABLE)

/datum/round_event/medieval_warmongers/proc/warmongers_answered(datum/comm_message/threat_msg, payoff, ship_name, initial_send_time, response_max_time, ship_template)
	if(world.time > initial_send_time + response_max_time)
		priority_announce("ВЫ УЖЕ ПОД ОСАДОЙ ОСТОЛОПЫ, ВЫ ЛИБО ТУПЫЕ ЛИБО НЕВЕЖЕСТВЕННЫЕ?!!", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
		spawn_warmongers(threat_msg, ship_template, TRUE)
		return
	if(threat_msg && threat_msg.answered == 1)
		var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
		if(D)
			if(D.adjust_money(-payoff))
				priority_announce("ЭТОГО БУДЕТ ДОСТАТОЧНО, ПОМНИ, КОМУ ТЫ ПРИНАДЛЕЖИШЬ!!", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_yespeacedecision.ogg', "Priority")
			else
				priority_announce("ТЫ СЧИТАЕШЬ МЕНЯ ШУТОМ? ТЕБЕ КОНЕЦ!!", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
				spawn_warmongers(threat_msg, ship_template, TRUE)
				return
	else
		priority_announce("ГЛУПОЕ РЕШЕНИЕ, ВАШИ ТРУПЫ ПОСЛУЖАТ ПРИМЕРОМ!!", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
		spawn_warmongers(threat_msg, ship_template, TRUE)

/datum/round_event/medieval_warmongers/proc/get_spawn_z()
	if(SSmapping.empty_space)
		return SSmapping.empty_space.z_value
	var/list/space_zlevels = SSmapping.levels_by_trait(ZTRAIT_SPACE_RUINS)
	if(length(space_zlevels))
		return pick(space_zlevels)
	return SSmapping.station_start

/datum/round_event/medieval_warmongers/proc/spawn_warmongers(datum/comm_message/threat_msg, ship_template, skip_answer_check)
	if(warmongers_spawned)
		return
	if(!skip_answer_check && threat_msg?.answered == 1)
		return
	if(!ship_template)
		message_admins("Medieval Warmongers event failed: no ship template configured.")
		return

	var/z = get_spawn_z()
	if(!z)
		message_admins("Medieval Warmongers event failed: no valid Z-level for ship spawn.")
		return

	warmongers_spawned = TRUE
	if(spawn_timer_id)
		deltimer(spawn_timer_id)
		spawn_timer_id = null

	var/datum/map_template/shuttle/ship = new ship_template
	var/x = rand(TRANSITIONEDGE, world.maxx - TRANSITIONEDGE - ship.width)
	var/y = rand(TRANSITIONEDGE, world.maxy - TRANSITIONEDGE - ship.height)
	var/turf/T = locate(x, y, z)
	if(!T)
		CRASH("Medieval Warmongers event found no turf to load in")

	if(!ship.load(T))
		CRASH("Loading Medieval Warmongers ship failed!")

	var/list/spawners_list = list()
	for(var/turf/A in ship.get_affected_turfs(T))
		for(var/obj/effect/mob_spawn/human/medieval/spawner in A)
			spawners_list += spawner

	var/list/candidates = pollGhostCandidates("Вы желаете стать средневековым пиратом?", ROLE_TRAITOR, minimum_required = spawners_list.len)

	for(var/obj/effect/mob_spawn/human/spawner in spawners_list)
		if(LAZYLEN(candidates))
			var/mob/our_candidate = pick_n_take(candidates)
			spawner.create(our_candidate.ckey)
			notify_ghosts("The Medieval Warmongers ship has an object of interest: [our_candidate]!", source = our_candidate, action = NOTIFY_ORBIT, header = "Something's Interesting!")
		else
			notify_ghosts("The Medieval Warmongers ship has an object of interest: [spawner]!", source = spawner, action = NOTIFY_ORBIT, header = "Something's Interesting!")

	priority_announce("Я РАЗОБРАЛСЯ, КАК УПРАВЛЯТЬ ЭТОЙ ШТУКОЙ, И ЧЕРЕЗ МИНУТУ МЫ ПРИЧАЛИМ РЯДОМ С ВАМИ!!", "Сборщики дани", 'modular_bluemoon/phenyamomota/sound/announcer/pirate_incoming.ogg')

// Medieval Pirate Spawners

/obj/effect/mob_spawn/human/medieval
	name = "\improper Improvised sleeper"
	desc = "A body bag poked with holes, currently being used as a sleeping bag. Someone seems to be sleeping inside of it."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "bodybag"
	mob_name = "a medieval warmonger"
	job_description = "Medieval Warmonger"
	mob_species = /datum/species/human
	outfit = /datum/outfit/medieval
	roundstart = FALSE
	death = FALSE
	anchored = TRUE
	density = FALSE
	show_flavour = FALSE
	short_desc = "You are a medieval warmonger."
	flavour_text = "Raiding some cretins while engaging in bloodsport and violence? What a deal. Stay together and pillage everything! Remember: Speak in ALL CAPS, be confused by technology, and demand tribute!"
	assignedrole = "Medieval Warmonger"
	can_load_appearance = FALSE
	loadout_enabled = FALSE
	category = "midround"

/obj/effect/mob_spawn/human/medieval/special(mob/living/new_spawn)
	. = ..()
	if(ishuman(new_spawn))
		var/mob/living/carbon/human/H = new_spawn
		ADD_TRAIT(H, TRAIT_NOGUNS, INNATE_TRAIT)
		to_chat(H, "<span class='notice'>You feel robust.</span>")
		var/datum/species/S = H.dna.species
		S.brutemod *= 0.5
		S.burnmod *= 0.5
		S.coldmod *= 0.5
	new_spawn.mind.add_antag_datum(/datum/antagonist/warmonger)

/obj/effect/mob_spawn/human/medieval/Destroy()
	return ..()

/obj/effect/mob_spawn/human/medieval/warlord
	name = "\improper Warlord's throne"
	desc = "A makeshift throne constructed from scrap metal and bones. It looks imposing and dangerous."
	icon = 'icons/obj/chairs.dmi'
	icon_state = "brass_chair"
	roundstart = FALSE
	death = FALSE
	loadout_enabled = FALSE
	mob_name = "the medieval warlord"
	job_description = "Medieval Warlord"
	outfit = /datum/outfit/medieval/warlord
	short_desc = "You are the MEDIEVAL WARLORD!"
	flavour_text = "You command the Medieval Warmongers! You are the supreme leader of this pirate crew. Your goal is to collect homage from the station crew. Lead your warriors and intimidate the weak!"

/obj/effect/mob_spawn/human/medieval/warlord/special(mob/living/new_spawn)
	. = ..()
	if(ishuman(new_spawn))
		var/mob/living/carbon/human/H = new_spawn
		REMOVE_TRAIT(H, TRAIT_NOGUNS, INNATE_TRAIT)
		H.dna.add_mutation(/datum/mutation/human/hulk/superhuman)
		H.dna.add_mutation(/datum/mutation/human/gigantism)
	new_spawn.mind.add_antag_datum(/datum/antagonist/warmonger)

/obj/effect/mob_spawn/human/medieval/warlord/Destroy()
	return ..()

// Medieval Pirate Equipment

/obj/structure/fermenting_barrel/black_powder
	name = "gunpowder barrel"
	desc = "A large wooden barrel for holding gunpowder. You'll need to take from this to load the cannons."

/obj/structure/fermenting_barrel/black_powder/Initialize(mapload)
	. = ..()
	reagents.add_reagent(/datum/reagent/blackpowder, 500)

/obj/structure/fermenting_barrel/thermite
	name = "thermite barrel"
	desc = "A large wooden barrel for holding thermite. Use this to make a big flipping hole on walls."

/obj/structure/fermenting_barrel/thermite/Initialize(mapload)
	. = ..()
	reagents.add_reagent(/datum/reagent/thermite, 500)

// Medieval Outfits

/datum/outfit/medieval
	name = "Medieval Warmonger"
	id = null
	glasses = null

	uniform = /obj/item/clothing/under/costume/gamberson/military
	suit = /obj/item/clothing/suit/armor/vest/military
	suit_store = /obj/item/spear/military
	back = /obj/item/storage/backpack/satchel/leather
	gloves = /obj/item/clothing/gloves/color/brown
	head = /obj/item/clothing/head/helmet/military
	mask = /obj/item/clothing/mask/balaclava
	shoes = /obj/item/clothing/shoes/workboots/mining
	belt = /obj/item/storage/belt/iron_tasset
	l_hand = /obj/item/claymore/cerberus
	l_pocket = /obj/item/flashlight/flare/torch
	r_pocket = /obj/item/gun/energy/taser/bolestrel/censor
	backpack_contents = list(/obj/item/stack/sheet/cloth, /obj/item/feather)


/datum/outfit/medieval/warlord
	name = "Medieval Warlord"
	neck = /obj/item/bedsheet/pirate
	suit = /obj/item/clothing/suit/armor/riot/knight/warlord
	suit_store = /obj/item/gun/magic/hook
	back = /obj/item/fireaxe/boardingaxe
	gloves = /obj/item/clothing/gloves/combat
	head = /obj/item/clothing/head/helmet/knight/warlord
	mask = /obj/item/clothing/mask/breath
	shoes = /obj/item/clothing/shoes/bronze
	belt = /obj/item/storage/belt/gold_tasset
	l_pocket = /obj/item/flashlight/flare/torch
	r_pocket = /obj/item/gun/energy/taser/bolestrel/censor

// Medieval Belts

/obj/item/storage/belt/iron_tasset
	name = "tasseted iron belt"
	desc = "A fine leather belt that's been sleeved within many segments of iron, and further reinforced with the tassets of a fluted cuirass."
	icon_state = "irontasset"
	item_state = "irontasset"
	mob_overlay_icon = 'icons/mob/clothing/belt.dmi'
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/storage/belt/iron_tasset/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 5
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.can_hold = typecacheof(list(/obj/item/restraints/legcuffs))

/obj/item/storage/belt/iron_tasset/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/restraints/legcuffs/bola/tactical(src)

/obj/item/storage/belt/gold_tasset
	name = "tasseted gold belt"
	desc = "A fine leather belt that's been sleeved within many segments of steel, and further reinforced with the tassets of a fluted cuirass."
	icon_state = "steeltasset"
	item_state = "steeltasset"
	mob_overlay_icon = 'icons/mob/clothing/belt.dmi'
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/storage/belt/gold_tasset/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 5
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.can_hold = typecacheof(list(/obj/item/restraints/legcuffs))

/obj/item/storage/belt/gold_tasset/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/restraints/legcuffs/bola/tactical(src)
