/// Inspection jurisdiction includes station space, mining and xenoarchaeology expeditions.
/proc/sol_inspection_allowed_level(level)
	return is_station_level(level) || is_mining_level(level) || SSmapping.level_trait(level, ZTRAIT_SPACE_RUINS)

/// Unlike a purchase, an assessed fine remains payable even when the cargo account is empty.
/datum/bank_account/proc/assess_sol_inspection_fine(amount, datum/bank_account/recipient, reason)
	if(amount <= 0 || QDELETED(recipient) || recipient == src)
		return FALSE
	allow_debt = TRUE
	_adjust_money(-amount)
	recipient._adjust_money(amount)
	add_log_to_history(-amount, reason)
	recipient.add_log_to_history(amount, reason)
	log_econ("Sol inspection fine: [account_holder] paid [amount] to [recipient.account_holder]: [reason]; balance [account_balance].")
	return TRUE

/datum/team/sol_inspection
	name = "Всеобщее Бюро Контроля"
	member_name = "инспектор"
	var/datum/bank_account/account
	var/obj/docking_port/mobile/sol_inspection/shuttle
	var/obj/item/radio/inspection_radio
	var/visited_station = FALSE
	var/returned_home = FALSE
	var/return_available_at
	/// Откуп, выплаченный станцией вместо инспекции.
	var/bribe_paid = 0
	/// Snapshot of the inspectors who actually returned aboard the vessel.
	var/list/returned_members = list()

/datum/team/sol_inspection/New()
	. = ..()
	account = new("Всеобщее Бюро Контроля")
	account.setup_unique_account_id()

/datum/team/sol_inspection/Destroy()
	QDEL_NULL(inspection_radio)
	// Cards retain the shared account for as long as they remain in the round.
	account = null
	shuttle = null
	returned_members.Cut()
	return ..()

/// Unlike a fine, a bribe is an ordinary purchase: the station has to actually own the credits.
/datum/team/sol_inspection/proc/pay_bribe(datum/bank_account/payer, amount, reason = "откуп от инспекции Всеобщего Бюро Контроля")
	if(amount <= 0 || QDELETED(payer) || QDELETED(account) || account == payer)
		return FALSE
	if(!payer.adjust_money(-amount, reason))
		return FALSE
	account._adjust_money(amount)
	account.add_log_to_history(amount, reason)
	bribe_paid += amount
	log_econ("Sol inspection bribe: [payer.account_holder] paid [amount] to [account.account_holder]: [reason]; balance [account.account_balance].")
	return TRUE

/datum/team/sol_inspection/proc/report_violation(message)
	if(!inspection_radio && !QDELETED(shuttle))
		inspection_radio = new(shuttle)
		inspection_radio.name = "Всеобщее Бюро Контроля"
		inspection_radio.keyslot = new /obj/item/encryptionkey/heads/qm(inspection_radio)
		inspection_radio.subspace_transmission = TRUE
		inspection_radio.canhear_range = 0
		inspection_radio.listening = FALSE
		inspection_radio.recalculateChannels()
	if(inspection_radio && !QDELETED(shuttle))
		inspection_radio.talk_into(shuttle, message, RADIO_CHANNEL_COMMAND)
		inspection_radio.talk_into(shuttle, message, RADIO_CHANNEL_SUPPLY)
	log_game("Sol inspection: [message]")

/datum/team/sol_inspection/proc/is_returned_inspector(datum/mind/inspector)
	return returned_home && visited_station && (inspector in returned_members) && inspector.current && inspector.current.stat != DEAD

/datum/team/sol_inspection/roundend_report()
	var/list/report = list("<b>Всеобщее Бюро Контроля</b>", printplayerlist(members))
	if(bribe_paid)
		report += "Инспекция отменена: станция выплатила откуп [bribe_paid] кредитов."
	else
		report += "Инспекция станции [visited_station ? "состоялась" : "не состоялась"]. Возвращение на ЦК: [returned_home ? "выполнено" : "не выполнено"]."
	report += "Вернулись живыми: [length(returned_members)]. Остаток общего счёта: [account?.account_balance] кредитов."
	return "<div class='panel'>[report.Join("<br>")]</div>"

/datum/round_event_control/sol_inspection
	name = "Проверка от Солнечной Федерации"
	typepath = /datum/round_event/sol_inspection
	weight = 8
	max_occurrences = 1
	min_players = 2
	earliest_start = 1 HOURS
	category = EVENT_CATEGORY_BUREAUCRATIC
	severity = DIRECTOR_SEVERITY_GHOST
	cost = 10
	intensity = 10
	family = "sol_inspection"
	required_round_type = list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT)
	description = "Инспекция Всеобщего Бюро Контроля проверяет станцию и выписывает штрафы за нелегальное оборудование. Станция может откупиться от визита."

/datum/round_event_control/sol_inspection/can_fire(datum/director_signals/signals)
	if(!..() || (locate(/obj/docking_port/mobile/sol_inspection) in SSshuttle.mobile))
		return FALSE
	var/cargo_workers = 0
	for(var/mob/living/carbon/human/worker as anything in GLOB.alive_mob_list)
		if(!istype(worker) || !worker.client || !worker.mind || worker.stat == DEAD)
			continue
		if(worker.mind.assigned_role in list("Cargo Technician", "Quartermaster"))
			cargo_workers++
		if(cargo_workers >= 2)
			return TRUE
	return FALSE

#define SOL_INSPECTION_DEMAND_MIN 25000
#define SOL_INSPECTION_DEMAND_CARGO_SHARE 0.8
#define SOL_INSPECTION_DEMAND_TIME 5 MINUTES

/datum/round_event/sol_inspection
	var/datum/team/sol_inspection/inspection_team
	/// The vessel launched or the crew bought the inspection off: both end the event for good.
	var/inspection_launched = FALSE
	var/spawn_timer_id

/// Find an entirely empty block rather than overwriting any CentCom facilities.
/datum/round_event/sol_inspection/proc/find_home_turf(datum/map_template/shuttle/template)
	for(var/level in SSmapping.levels_by_trait(ZTRAIT_CENTCOM))
		for(var/attempt in 1 to 100)
			var/start_x = rand(TRANSITIONEDGE + 1, world.maxx - TRANSITIONEDGE - template.width)
			var/start_y = rand(TRANSITIONEDGE + 1, world.maxy - TRANSITIONEDGE - template.height)
			var/turf/bottom_left = locate(start_x, start_y, level)
			var/clear = TRUE
			for(var/turf/place as anything in block(bottom_left, locate(start_x + template.width - 1, start_y + template.height - 1, level)))
				if(!istype(place, /turf/open/space) || length(place.contents) || (place.flags_1 & NO_RUINS_1))
					clear = FALSE
					break
			if(clear)
				return bottom_left
	return null

/datum/round_event/sol_inspection/proc/fail_inspection(reason)
	message_admins("SOL inspection failed: [reason]")
	// A crewless team without a vessel would only litter the roundend report; the director gets
	// the budget back and picks a replacement event.
	if(inspection_team && !length(inspection_team.members) && !inspection_team.shuttle)
		qdel(inspection_team)
		inspection_team = null
	if(control)
		SSdirector.note_failed_action(control, refund_budget = triggered_randomly, retry_replacement = triggered_randomly)

/datum/round_event/sol_inspection/start()
	if(inspection_launched || spawn_timer_id)
		// The demand is still open: leave it alone instead of refunding the director for it.
		message_admins("SOL inspection is already under way; ignoring the duplicate start.")
		return
	if(locate(/obj/docking_port/mobile/sol_inspection) in SSshuttle.mobile)
		fail_inspection("an inspection vessel already exists")
		return
	// The team exists before the demand: its shared account is where a bribe ends up.
	if(!inspection_team)
		inspection_team = new
	send_inspection_demand()

/// The inspection buys itself a delay first: the crew may settle the whole thing from a comms console,
/// the same bargain pirates offer. Only silence or a refusal launches the vessel.
/datum/round_event/sol_inspection/proc/send_inspection_demand()
	var/datum/comm_message/demand_msg = new
	var/payoff = SOL_INSPECTION_DEMAND_MIN
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(cargo)
		payoff = max(SOL_INSPECTION_DEMAND_MIN, FLOOR(cargo.account_balance * SOL_INSPECTION_DEMAND_CARGO_SHARE, 1000))
	var/initial_send_time = world.time

	priority_announce("Входящая подпространственная передача данных. Открыт защищенный канал связи на всех коммуникационных консолях.", "Требование Всеобщего Бюро Контроля", SSstation.announcer.get_rand_report_sound(), has_important_message = TRUE, sound = 'modular_bluemoon/kovac_shitcode/sound/lambda_code.ogg')
	demand_msg.title = "Требование об откупе от инспекции"
	demand_msg.content = "Внимание, экипаж станции. Всеобщее Бюро Контроля Транс-Солнечной Федерации составило предварительный список нарушений и готовит инспекционный рейд. Если вы перечислите [payoff] кредитов на счёт Бюро, инспекция будет отменена и останется в секторе ЦК. Средства списываются с отделения Карго. У вас ровно пять минут с момента получения сообщения."
	demand_msg.possible_answers = list("Мы заплатим.", "Мы заплатим, но на самом деле нет.")
	demand_msg.answer_callback = CALLBACK(src, PROC_REF(demand_answered), demand_msg, payoff, initial_send_time)
	SScommunications.send_message(demand_msg, unique = TRUE)
	spawn_timer_id = addtimer(CALLBACK(src, PROC_REF(launch_inspection), demand_msg), SOL_INSPECTION_DEMAND_TIME, TIMER_STOPPABLE)

/datum/round_event/sol_inspection/proc/demand_answered(datum/comm_message/demand_msg, payoff, initial_send_time)
	if(inspection_launched)
		return
	if(world.time >= initial_send_time + SOL_INSPECTION_DEMAND_TIME)
		priority_announce("Слишком поздно. Инспекционный шаттл уже приближается к [GLOB.station_name].", "Всеобщее Бюро Контроля", sound = 'modular_bluemoon/kovac_shitcode/sound/lambda_code.ogg')
		launch_inspection(demand_msg, TRUE)
		return
	if(demand_msg?.answered == 1)
		var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
		if(inspection_team?.pay_bribe(cargo, payoff))
			resolve_demand_peacefully()
			priority_announce("Реквизиты приняты. Инспекция отменена: Всеобщее Бюро Контроля остаётся в секторе ЦК. Поступление [payoff] кредитов подтверждено.", "Всеобщее Бюро Контроля")
			SSdirector.complete_deferred_action_without_roles(control, "инспекция отменена откупом; назначено ролей: 0")
			return
		priority_announce("Заявленная сумма не поступила на счёт Бюро. Инспекционный шаттл покидает сектор ЦК.", "Всеобщее Бюро Контроля")
		launch_inspection(demand_msg, TRUE)
		return
	priority_announce("Откуп отклонён. Инспекционный шаттл приближается к [GLOB.station_name].", "Всеобщее Бюро Контроля", sound = 'modular_bluemoon/kovac_shitcode/sound/lambda_code.ogg')
	launch_inspection(demand_msg, TRUE)

/// The crew bought the inspection off: no vessel is ever loaded, the money stays on the team account.
/datum/round_event/sol_inspection/proc/resolve_demand_peacefully()
	inspection_launched = TRUE
	if(spawn_timer_id)
		deltimer(spawn_timer_id)
		spawn_timer_id = null

/datum/round_event/sol_inspection/proc/launch_inspection(datum/comm_message/demand_msg, skip_answer_check = FALSE)
	if(inspection_launched)
		return
	if(!skip_answer_check && demand_msg?.answered == 1)
		return
	// The flag goes up before the map load: template.load() sleeps (CHECK_TICK in the map parser),
	// and without it the crew's answer or the pending timer would load a second vessel and refund
	// the director twice.
	inspection_launched = TRUE
	if(spawn_timer_id)
		deltimer(spawn_timer_id)
		spawn_timer_id = null
	if(!inspection_team)
		inspection_team = new
	if(locate(/obj/docking_port/mobile/sol_inspection) in SSshuttle.mobile)
		fail_inspection("an inspection vessel already exists")
		return
	var/datum/map_template/shuttle/sol_inspection/template = new
	var/turf/home_turf = find_home_turf(template)
	if(!home_turf || !template.load(home_turf))
		qdel(template)
		fail_inspection("no empty CentCom berth or map load failed")
		return
	var/obj/docking_port/mobile/sol_inspection/vessel = SSshuttle.getShuttle("sol_inspection")
	if(!istype(vessel))
		qdel(template)
		fail_inspection("the vessel has no registered mobile port")
		return
	inspection_team.shuttle = vessel
	vessel.inspection_team = inspection_team
	var/obj/docking_port/stationary/home_dock = new(get_turf(vessel))
	home_dock.unregister()
	home_dock.shuttle_id = "sol_inspection_home"
	home_dock.name = "ЦК: причал Всеобщего Бюро Контроля"
	home_dock.setDir(vessel.dir)
	home_dock.width = vessel.width
	home_dock.height = vessel.height
	home_dock.dwidth = vessel.dwidth
	home_dock.dheight = vessel.dheight
	home_dock.area_type = /area/space
	home_dock.register()
	vessel.home_dock = home_dock
	template.post_load(vessel)
	qdel(template)
	var/list/spawners = list()
	for(var/area/shuttle_area as anything in vessel.shuttle_areas)
		for(var/obj/effect/mob_spawn/human/sol_inspector/spawner in shuttle_area)
			spawner.inspection_team = inspection_team
			spawners += spawner
		for(var/obj/machinery/computer/camera_advanced/shuttle_docker/sol_inspection/navigation in shuttle_area)
			navigation.configure_station_navigation()
	if(!length(spawners))
		fail_inspection("the vessel has no crew spawners")
		return
	priority_announce("Внимание, экипаж. Транс-Солнечная Федерация направляет на вашу станцию инспекцию Всеобщего Бюро Контроля. Проверке подлежат БС-майнеры, криптомайнеры, а также боевые мехи. Подготовьте оборудование и обеспечьте инспекторам доступ в помещения.", "Всеобщее Бюро Контроля", sound = 'modular_bluemoon/kovac_shitcode/sound/lambda_code.ogg')
	print_command_report("Внимание, экипаж. Транс-Солнечная Федерация направляет на вашу станцию инспекцию Всеобщего Бюро Контроля. Проверке подлежат БС-майнеры, криптомайнеры, а также боевые мехи. Подготовьте оборудование и обеспечьте инспекторам доступ в помещения.", "Всеобщее Бюро Контроля", FALSE)
	for(var/obj/effect/mob_spawn/human/sol_inspector/spawner as anything in spawners)
		spawner.director_source_action = control
		spawner.director_intensity = control ? control.intensity / length(spawners) : 0
		spawner.director_refund_cost = triggered_randomly && control ? control.cost / length(spawners) : 0
		notify_ghosts("Доступна [spawner.name]. Чтобы присоединиться к инспекции, найдите её в Spawners Menu.", source = spawner, action = NOTIFY_ORBIT, header = "Всеобщее Бюро Контроля")

#undef SOL_INSPECTION_DEMAND_MIN
#undef SOL_INSPECTION_DEMAND_CARGO_SHARE
#undef SOL_INSPECTION_DEMAND_TIME

/area/shuttle/sol_inspection
	name = "Шаттл Всеобщего Бюро Контроля"

/datum/map_template/shuttle/sol_inspection
	port_id = "sol_inspection"
	suffix = "default"
	name = "Шаттл инспекции Солнечной Федерации"
	can_be_bought = FALSE

/datum/map_template/shuttle/sol_inspection/post_load(obj/docking_port/mobile/vessel)
	// Template loading assigns dimensions after Initialize(); discover the full hull now.
	vessel.shuttle_areas.Cut()
	for(var/turf/place as anything in vessel.return_turfs())
		var/area/shuttle_area = get_area(place)
		if(istype(shuttle_area, vessel.area_type))
			vessel.shuttle_areas[shuttle_area] = TRUE
	vessel.initial_engines = vessel.count_engines()
	vessel.current_engines = vessel.initial_engines
	return ..()

/obj/docking_port/mobile/sol_inspection
	name = "Шаттл Всеобщего Бюро Контроля"
	shuttle_id = "sol_inspection"
	area_type = /area/shuttle/sol_inspection
	callTime = 1 MINUTES
	ignitionTime = 10 SECONDS
	launch_status = NOLAUNCH
	var/datum/team/sol_inspection/inspection_team
	var/obj/docking_port/stationary/home_dock

/obj/docking_port/mobile/sol_inspection/Destroy(force)
	if(force)
		if(inspection_team?.shuttle == src)
			inspection_team.shuttle = null
		inspection_team = null
		home_dock = null
	return ..()

/obj/docking_port/mobile/sol_inspection/canDock(obj/docking_port/stationary/dock)
	if(inspection_team)
		if(inspection_team.returned_home)
			return SHUTTLE_NOT_A_DOCKING_PORT
		if(dock == home_dock && (!inspection_team.visited_station || world.time < inspection_team.return_available_at))
			return SHUTTLE_NOT_A_DOCKING_PORT
	return ..()

/obj/docking_port/mobile/sol_inspection/initiate_docking(obj/docking_port/stationary/new_dock, movement_direction, force = FALSE)
	. = ..()
	if(. != DOCKING_SUCCESS || !inspection_team || istype(new_dock, /obj/docking_port/stationary/transit))
		return
	if(!inspection_team.visited_station && is_station_level(z))
		inspection_team.visited_station = TRUE
		inspection_team.return_available_at = world.time + 90 MINUTES
		inspection_team.report_violation("Инспекция прибыла в сектор станции.")
	if(new_dock == home_dock && inspection_team.visited_station)
		inspection_team.returned_home = TRUE
		for(var/datum/mind/member as anything in inspection_team.members)
			if(member.current && member.current.stat != DEAD && (get_area(member.current) in shuttle_areas))
				inspection_team.returned_members |= member
		priority_announce("Инспекция Всеобщего Бюро Контроля завершена. Инспекционный шаттл вернулся в сектор ЦК.", "Транс-Солнечная Федерация")

/obj/machinery/computer/shuttle/sol_inspection
	name = "управление инспекционным шаттлом"
	desc = "Консоль полётов Всеобщего Бюро Контроля. Возврат на ЦК разрешён через 90 минут после прибытия в сектор станции."
	shuttleId = "sol_inspection"
	possible_destinations = "sol_inspection_custom;sol_inspection_home"
	no_destination_swap = TRUE

/obj/machinery/computer/shuttle/sol_inspection/ui_act(action, params)
	if(!usr?.mind?.has_antag_datum(/datum/antagonist/sol_inspector))
		to_chat(usr, span_warning("Управление доступно только членам инспекции."))
		return TRUE
	return ..()

/obj/machinery/computer/shuttle/sol_inspection/examine(mob/user)
	. = ..()
	var/obj/docking_port/mobile/sol_inspection/vessel = SSshuttle.getShuttle(shuttleId)
	var/datum/team/sol_inspection/team = vessel?.inspection_team
	if(team?.visited_station && !team.returned_home)
		. += span_notice("До разрешения вернуться на ЦК: [DisplayTimeText(max(0, team.return_available_at - world.time))].")

/obj/machinery/computer/camera_advanced/shuttle_docker/sol_inspection
	name = "навигация инспекционного шаттла"
	desc = "Выбирает безопасную точку посадки в секторе станции."
	shuttleId = "sol_inspection"
	shuttlePortId = "sol_inspection_custom"
	shuttlePortName = "место инспекции"
	view_range = 10
	space_turfs_only = FALSE
	lock_override = NONE

/obj/machinery/computer/camera_advanced/shuttle_docker/sol_inspection/proc/configure_station_navigation()
	z_lock = SSmapping.levels_by_trait(ZTRAIT_STATION)
	for(var/obj/docking_port/stationary/dock as anything in SSshuttle.stationary)
		if(is_station_level(dock.z))
			add_jumpable_port(dock.shuttle_id)

/obj/machinery/computer/camera_advanced/shuttle_docker/sol_inspection/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!user.mind?.has_antag_datum(/datum/antagonist/sol_inspector))
		to_chat(user, span_warning("Навигация доступна только членам инспекции."))
		return
	return ..()

/obj/machinery/computer/camera_advanced/shuttle_docker/sol_inspection/checkLandingSpot()
	if(!eyeobj || !is_station_level(eyeobj.z))
		return SHUTTLE_DOCKER_BLOCKED
	return ..()
