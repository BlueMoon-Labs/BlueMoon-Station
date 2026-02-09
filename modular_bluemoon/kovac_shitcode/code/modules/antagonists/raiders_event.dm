/datum/round_event_control/raiders
	name = "InteQ Raiders"
	typepath = /datum/round_event/raiders
	weight = 20
	max_occurrences = 1
	min_players = 30
	earliest_start = 45 MINUTES
	dynamic_should_hijack = TRUE
	category = EVENT_CATEGORY_INVASION
	description = "The crew will face a PMC assault."

/datum/round_event_control/raiders/preRunEvent()
	if (!SSmapping.empty_space)
		return EVENT_CANT_RUN

	return ..()

/datum/round_event/raiders/start()
	send_raider_threat()

/datum/round_event/raiders/proc/send_raider_threat()
	var/datum/comm_message/threat_msg = new
	var/payoff = 0
	var/payoff_min = 25000 //documented this time
	var/ship_template
	var/ship_name = "Admiral Brown's fleet battlecruiser"
	var/initial_send_time = world.time
	var/response_max_time = 5 MINUTES

	ship_name = pick(strings(PIRATE_NAMES_FILE, "rogue_names"))

	priority_announce("Входящая подпространственная передача данных. Открыт защищенный канал связи на всех коммуникационных консолях.", "Сомнительное Заявление", SSstation.announcer.get_rand_report_sound(), has_important_message = TRUE)
	var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(D)
		payoff = max(payoff_min, FLOOR(D.account_balance * 0.9, 1000))

		ship_template = /datum/map_template/shuttle/inteq_collosus

		threat_msg.title = "Сомнительное Заявление"
		threat_msg.content = "Джамбо, уроды. Мы тут пролетали неподалеку, и заметили красно-синих голубков. Расклад прост. Гоните [payoff] кредитов, в противном случае мы не поленимся проложить курс нашего крейсера напрямую через вашу станцию."
		threat_msg.possible_answers = list("Мы заплатим.","Мы заплатим, но на самом деле нет.")

	threat_msg.answer_callback = CALLBACK(src, PROC_REF(raiders_answered), threat_msg, payoff, ship_name, initial_send_time, response_max_time, ship_template)
	SScommunications.send_message(threat_msg,unique = TRUE)
	addtimer(CALLBACK(src, PROC_REF(spawn_raiders), threat_msg, ship_template), response_max_time)

/datum/round_event/raiders/proc/raiders_answered(datum/comm_message/threat_msg, payoff, ship_name, initial_send_time, response_max_time, ship_template)
	if(world.time > initial_send_time + response_max_time)
		priority_announce("Поговорим на языке силы.", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
		spawn_raiders(threat_msg, ship_template, TRUE)
		return
	if(threat_msg && threat_msg.answered == 1)
		var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
		if(D)
			if(D.adjust_money(-payoff))
				priority_announce("Удачного дня, рабы пакта.", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_yespeacedecision.ogg', "Priority")
			else
				priority_announce("Здесь не хватает кредитов, козлы. Молитесь.", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
				spawn_raiders(threat_msg, ship_template, TRUE)
				return
	else
		priority_announce("Здесь не хватает кредитов, козлы. Молитесь.", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
		spawn_raiders(threat_msg, ship_template, TRUE)

/datum/round_event/raiders/proc/spawn_raiders(datum/comm_message/threat_msg, ship_template, skip_answer_check)
	if(!skip_answer_check && threat_msg?.answered == 1)
		return

	var/list/candidates = pollGhostCandidates("Вы желаете стать рейдером InteQ?", ROLE_TRAITOR)
	shuffle_inplace(candidates)

	var/datum/map_template/shuttle/ship = new ship_template
	var/x = rand(TRANSITIONEDGE,world.maxx - TRANSITIONEDGE - ship.width)
	var/y = rand(TRANSITIONEDGE,world.maxy - TRANSITIONEDGE - ship.height)
	var/z = SSmapping.empty_space.z_value
	var/turf/T = locate(x,y,z)
	if(!T)
		CRASH("Raiders event found no turf to load in")

	if(!ship.load(T))
		CRASH("Loading InteQ Raiders ship failed!")

	for(var/turf/A in ship.get_affected_turfs(T))
		for(var/obj/effect/mob_spawn/human/raider/spawner in A)
			if(candidates.len > 0)
				var/mob/our_candidate = candidates[1]
				spawner.create(our_candidate.ckey)
				candidates -= our_candidate
				notify_ghosts("The InteQ ship has an object of interest: [our_candidate]!", source=our_candidate, action=NOTIFY_ORBIT, header="Something's Interesting!")
			else
				notify_ghosts("The InteQ ship has an object of interest: [spawner]!", source=spawner, action=NOTIFY_ORBIT, header="Something's Interesting!")

	priority_announce("В секторе обнаружен вооружённный корабль.", "Отдел ССО ПАКТа Синих Лун", 'modular_bluemoon/phenyamomota/sound/announcer/pirate_incoming.ogg')
