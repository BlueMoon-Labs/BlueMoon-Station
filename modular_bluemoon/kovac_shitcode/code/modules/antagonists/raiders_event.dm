/datum/round_event_control/raiders
	name = "InteQ Raiders"
	typepath = /datum/round_event/raiders
	weight = 4
	max_occurrences = 1
	min_players = 30
	earliest_start = 45 MINUTES
	category = EVENT_CATEGORY_INVASION
	severity = DIRECTOR_SEVERITY_GHOST // антаги из призраков - гост-пул, а не общий MAJOR
	cost = 15
	intensity = 45
	intensity_linger = 45 MINUTES // штурм живёт заметно дольше спавнера
	antag_heavy = TRUE // командный асолт: мягкие профили такое выключают
	family = "raiders" // с рулсетом-двойником динамика (он запускает это же событие): не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // не экста и не лайт
	description = "The crew will face a PMC assault."

/datum/round_event_control/raiders/preRunEvent(admin_window = TRUE)
	if(!SSmapping.empty_space && !length(SSmapping.levels_by_trait(ZTRAIT_SPACE_RUINS)) && !SSmapping.station_start)
		return EVENT_CANT_RUN

	return ..()

/datum/round_event/raiders
	var/raiders_spawned = FALSE
	var/spawn_timer_id

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
	ship_template = /datum/map_template/shuttle/inteq_collosus
	threat_msg.title = "Сомнительное Заявление"
	threat_msg.possible_answers = list("Мы заплатим.","Мы заплатим, но на самом деле нет.")
	var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(D)
		payoff = max(payoff_min, FLOOR(D.account_balance * 0.9, 1000))
	else
		payoff = payoff_min
	threat_msg.content = "Джамбо, уроды. Мы тут пролетали неподалеку, и заметили красно-синих голубков. Расклад прост. Гоните [payoff] кредитов, в противном случае мы не поленимся проложить курс нашего крейсера напрямую через вашу станцию."

	threat_msg.answer_callback = CALLBACK(src, PROC_REF(raiders_answered), threat_msg, payoff, ship_name, initial_send_time, response_max_time, ship_template)
	SScommunications.send_message(threat_msg,unique = TRUE)
	spawn_timer_id = addtimer(CALLBACK(src, PROC_REF(spawn_raiders), threat_msg, ship_template), response_max_time, TIMER_STOPPABLE)

/datum/round_event/raiders/proc/raiders_answered(datum/comm_message/threat_msg, payoff, ship_name, initial_send_time, response_max_time, ship_template)
	if(world.time > initial_send_time + response_max_time)
		priority_announce("Поговорим на языке силы.", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
		spawn_raiders(threat_msg, ship_template, TRUE)
		return
	if(threat_msg && threat_msg.answered == 1)
		var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
		if(D && D.adjust_money(-payoff))
			priority_announce("Удачного дня, рабы пакта.", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_yespeacedecision.ogg', "Priority")
			SSdirector.complete_deferred_action_without_roles(control, "угроза снята выкупом; назначено ролей: 0")
			return
		priority_announce("Здесь не хватает кредитов, козлы. Молитесь.", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
		spawn_raiders(threat_msg, ship_template, TRUE)
		return
	else
		priority_announce("Здесь не хватает кредитов, козлы. Молитесь.", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
		spawn_raiders(threat_msg, ship_template, TRUE)

/datum/round_event/raiders/proc/get_spawn_z()
	if(SSmapping.empty_space)
		return SSmapping.empty_space.z_value
	var/list/space_zlevels = SSmapping.levels_by_trait(ZTRAIT_SPACE_RUINS)
	if(length(space_zlevels))
		return pick(space_zlevels)
	return SSmapping.station_start

/// Спавн не состоялся: возвращаем директору бюджет и паузы, чтобы он подобрал замену.
/// Провал терминален - иначе оставшийся таймер или ответ станции зашли бы сюда второй раз
/// и вернули бы бюджет дважды.
/datum/round_event/raiders/proc/fail_spawn(reason)
	raiders_spawned = TRUE
	if(spawn_timer_id)
		deltimer(spawn_timer_id)
		spawn_timer_id = null
	message_admins("InteQ Raiders event failed: [reason]")
	if(!control)
		return
	// Бюджет тратился только на естественный запуск через бит (админ-форс идёт мимо кошельков).
	SSdirector.note_failed_action(control, refund_budget = triggered_randomly, retry_replacement = triggered_randomly)
	SSdirector.director_log_beat(SSdirector.collect_signals(), control, DIRECTOR_BEAT_FAILED,
		detail = "[reason]; [triggered_randomly ? "бюджет и паузы возвращены, запрошена замена" : "ручной запуск, бюджет не списывался; паузы возвращены"]")

/datum/round_event/raiders/proc/spawn_raiders(datum/comm_message/threat_msg, ship_template, skip_answer_check)
	if(raiders_spawned)
		return
	if(!skip_answer_check && threat_msg?.answered == 1)
		return
	if(!ship_template)
		fail_spawn("не задан шаблон корабля")
		return

	var/z = get_spawn_z()
	if(!z)
		fail_spawn("нет подходящего Z-уровня для корабля")
		return

	// Флаг ставится до загрузки: ship.load() спит (CHECK_TICK в парсере карты), и без него
	// сработавший за это время таймер или ответ станции загрузили бы второй корабль.
	raiders_spawned = TRUE
	if(spawn_timer_id)
		deltimer(spawn_timer_id)
		spawn_timer_id = null

	var/datum/map_template/shuttle/ship = new ship_template
	var/x = rand(TRANSITIONEDGE,world.maxx - TRANSITIONEDGE - ship.width)
	var/y = rand(TRANSITIONEDGE,world.maxy - TRANSITIONEDGE - ship.height)
	var/turf/T = locate(x,y,z)
	if(!T || !ship.load(T))
		fail_spawn("корабль не удалось загрузить на карту")
		return

	var/list/spawners_list = list()
	for(var/turf/A in ship.get_affected_turfs(T))
		for(var/obj/effect/mob_spawn/human/raider/spawner in A)
			spawners_list += spawner

	var/list/candidates = pollGhostCandidates("Вы желаете стать рейдером InteQ?", ROLE_TRAITOR, minimum_required = spawners_list.len)
	var/list/spawned_raiders = list()
	var/spawner_count = length(spawners_list)
	var/intensity_share = spawner_count ? control.intensity / spawner_count : 0
	var/refund_share = triggered_randomly && spawner_count ? control.cost / spawner_count : 0

	for(var/obj/effect/mob_spawn/human/spawner in spawners_list)
		if(LAZYLEN(candidates))
			var/mob/our_candidate = pick_n_take(candidates)
			var/mob/living/spawned_raider = spawner.create(our_candidate.ckey)
			if(spawned_raider)
				spawned_raiders += spawned_raider
			notify_ghosts("The InteQ ship has an object of interest: [our_candidate]!", source=our_candidate, action=NOTIFY_ORBIT, header="Something's Interesting!")
		else
			spawner.director_source_action = control
			spawner.director_intensity = intensity_share
			spawner.director_refund_cost = refund_share
			notify_ghosts("The InteQ ship has an object of interest: [spawner]!", source=spawner, action=NOTIFY_ORBIT, header="Something's Interesting!")
	if(length(spawned_raiders))
		var/spawned_fraction = length(spawned_raiders) / max(1, spawner_count)
		SSdirector.track_ghost_role_spawn(
			control,
			spawned_raiders,
			budget_backed = triggered_randomly,
			intensity_override = control.intensity * spawned_fraction,
			refund_cost_override = triggered_randomly ? control.cost * spawned_fraction : 0,
		)
	else
		SSdirector.director_log_beat(SSdirector.collect_signals(), control, DIRECTOR_BEAT_EXECUTED,
			detail = "корабль создан; сразу назначено ролей: 0, свободные спавнеры оставлены призракам")

	priority_announce("В секторе обнаружен вооружённный корабль.", "Отдел ССО ПАКТа Синих Лун", 'modular_bluemoon/phenyamomota/sound/announcer/pirate_incoming.ogg')
