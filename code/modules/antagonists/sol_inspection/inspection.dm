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
	/// Set once the berth opens, so the grace period before the unattended departure runs only once.
	var/departure_scheduled_at
	/// Откуп, выплаченный станцией вместо инспекции.
	var/bribe_paid = 0
	/// Накопленная сумма взысканных штрафов (без откупа): за каждые 100 000 кредитов инспекция получает метадоллары.
	var/fines_total = 0
	/// Уже начисленные части по 100 000 кредитов, чтобы не платить дважды.
	var/metadollars_awarded = 0
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

#define SOL_INSPECTION_EARLY_RETURN_FINE 100000
#define SOL_INSPECTION_MINIMUM_STAY 60 MINUTES
#define SOL_INSPECTION_RETURN_POLL 30 SECONDS
/// Opening the berth does not pull the ship out from under the inspectors: they get a short grace
/// period to finish the last scan or walk back aboard before the vessel leaves on its own.
#define SOL_INSPECTION_DEPARTURE_DELAY 3 MINUTES

/// World time at which the CentCom berth opens, or 0 when fines already bought early return.
/datum/team/sol_inspection/proc/return_unlock_at()
	if(fines_total >= SOL_INSPECTION_EARLY_RETURN_FINE)
		return 0
	return return_available_at

/datum/team/sol_inspection/proc/return_time_left()
	if(!return_available_at)
		return 0
	return max(0, return_available_at - world.time)

/datum/team/sol_inspection/proc/return_unlocked()
	return visited_station && return_time_left() <= 0

/// По окончании инспекции живые инспекторы отправляются обратно на ЦК со взрывами искр; мертвые остаются как есть.
/datum/team/sol_inspection/proc/end_inspection()
	for(var/datum/mind/member as anything in members)
		var/mob/m = member.current
		if(m && !QDELETED(m) && m.stat != DEAD)
			do_fake_sparks(5, FALSE, get_turf(m))
			qdel(m)

/// За каждые 100 000 кредитов взысканных штрафов каждый член инспекции получает по одному метадоллару.
/datum/team/sol_inspection/proc/award_inspector_metadollars()
	if(!SSmetadollars)
		return
	var/chunks = floor(fines_total / 100000)
	var/new_chunks = chunks - metadollars_awarded
	if(new_chunks <= 0)
		return
	metadollars_awarded = chunks
	for(var/datum/mind/member as anything in members)
		if(member.current && !QDELETED(member.current) && member.current.stat != DEAD)
			SSmetadollars.metadollar_adjust(new_chunks, ckey(member.key))

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
	priority_announce("Внимание, экипаж. Транс-Солнечная Федерация направляет на вашу станцию инспекцию Всеобщего Бюро Контроля. Проверке подлежат БС-майнеры, криптомайнеры, боевые мехи, а также слиперы с управлением внутри капсулы. Подготовьте оборудование и обеспечьте инспекторам доступ в помещения.", "Всеобщее Бюро Контроля", sound = 'modular_bluemoon/kovac_shitcode/sound/lambda_code.ogg')
	print_command_report("Внимание, экипаж. Транс-Солнечная Федерация направляет на вашу станцию инспекцию Всеобщего Бюро Контроля. Проверке подлежат БС-майнеры, криптомайнеры, боевые мехи, а также слиперы с управлением внутри капсулы. Подготовьте оборудование и обеспечьте инспекторам доступ в помещения.", "Всеобщее Бюро Контроля", FALSE)
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
	/// Polls until the CentCom berth opens, then flies the vessel home unattended.
	var/return_timer_id
	/// Удаляет шаттл с искрами через три минуты после окончания инспекции.
	var/end_timer_id

/obj/docking_port/mobile/sol_inspection/Destroy(force)
	if(return_timer_id)
		deltimer(return_timer_id)
		return_timer_id = null
	if(end_timer_id)
		deltimer(end_timer_id)
		end_timer_id = null
	if(force)
		if(inspection_team?.shuttle == src)
			inspection_team.shuttle = null
		inspection_team = null
		home_dock = null
	return ..()

/obj/docking_port/mobile/sol_inspection/canDock(obj/docking_port/stationary/dock)
	reconcile_station_visit()
	if(inspection_team)
		if(inspection_team.returned_home)
			return SHUTTLE_NOT_A_DOCKING_PORT
		if(dock == home_dock && !inspection_team.return_unlocked())
			return SHUTTLE_NOT_A_DOCKING_PORT
	return ..()

/obj/docking_port/mobile/sol_inspection/initiate_docking(obj/docking_port/stationary/new_dock, movement_direction, force = FALSE)
	. = ..()
	if(. != DOCKING_SUCCESS || !inspection_team || istype(new_dock, /obj/docking_port/stationary/transit))
		return
	reconcile_station_visit()
	if(new_dock == home_dock && inspection_team.visited_station)
		inspection_team.returned_home = TRUE
		if(return_timer_id)
			deltimer(return_timer_id)
			return_timer_id = null
		for(var/datum/mind/member as anything in inspection_team.members)
			if(member.current && member.current.stat != DEAD && (get_area(member.current) in shuttle_areas))
				inspection_team.returned_members |= member
		inspection_team.end_inspection()
		src.schedule_end_deletion()
		priority_announce("Инспекция Всеобщего Бюро Контроля завершена. Инспекционный шаттл покидает [GLOB.station_name].", "Транс-Солнечная Федерация")

/// The mandatory stay used to be armed by initiate_docking alone, so a single missed call stranded
/// the inspection on the station forever. Derive it from where the port actually is instead, and
/// let the return check re-check on a timer, since the haul can unlock the berth at any moment.
/obj/docking_port/mobile/sol_inspection/proc/reconcile_station_visit()
	if(!inspection_team || inspection_team.visited_station || !is_station_level(z))
		return
	inspection_team.visited_station = TRUE
	inspection_team.return_available_at = world.time + SOL_INSPECTION_MINIMUM_STAY
	inspection_team.report_violation("Инспекция прибыла в сектор станции.")
	schedule_return_check()

/obj/docking_port/mobile/sol_inspection/proc/schedule_return_check(delay = SOL_INSPECTION_RETURN_POLL)
	if(return_timer_id)
		deltimer(return_timer_id)
	return_timer_id = addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/docking_port/mobile/sol_inspection, check_return)), max(1, delay), TIMER_STOPPABLE)

/// The vessel leaves on its own once the berth opens, so an abandoned inspection still wraps up
/// and stops blocking every later one. Досрочная разблокировка штрафом позволяет улететь вручную
/// с консоли, но не инициирует автовылет — только истечение обязательного срока пребывания.
/obj/docking_port/mobile/sol_inspection/proc/check_return()
	return_timer_id = null
	if(QDELETED(src) || !inspection_team || !home_dock || inspection_team.returned_home)
		return

	// Only a vessel parked and idle at a station berth can be sent home. A shuttle already under
	// way is left alone, but the poll keeps running: the next stop may still be the station.
	if(mode != SHUTTLE_IDLE || !is_station_level(z) || !istype(get_docked(), /obj/docking_port/stationary))
		schedule_return_check()
		return

	// Автоотправка только по истечении обязательного срока пребывания. Досрочная разблокировка
	// штрафом открывает причал для ручного отлёта с консоли, но не выкидывает шаттл сам.
	if(!inspection_team.return_available_at || world.time < inspection_team.return_available_at)
		schedule_return_check()
		return

	if(!canDock(home_dock))
		schedule_return_check()
		return

	if(!inspection_team.departure_scheduled_at)
		inspection_team.departure_scheduled_at = world.time + SOL_INSPECTION_DEPARTURE_DELAY
		inspection_team.report_violation("Срок инспекции истёк. Шаттл снимется со стоянки и вернётся на ЦК через [DisplayTimeText(SOL_INSPECTION_DEPARTURE_DELAY, 1)].")
	else if(world.time >= inspection_team.departure_scheduled_at)
		request(home_dock)
		return

	schedule_return_check(inspection_team.departure_scheduled_at - world.time)

/obj/docking_port/mobile/sol_inspection/proc/schedule_end_deletion()
	if(end_timer_id)
		deltimer(end_timer_id)
	end_timer_id = addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/docking_port/mobile/sol_inspection, end_delete)), SOL_INSPECTION_DEPARTURE_DELAY, TIMER_STOPPABLE)

/obj/docking_port/mobile/sol_inspection/proc/end_delete()
	end_timer_id = null
	if(QDELETED(src))
		return
	if(src.inspection_team)
		src.inspection_team.shuttle = null
	do_fake_sparks(5, FALSE, get_turf(src))
	qdel(src)

/obj/machinery/computer/shuttle/sol_inspection
	desc = "Консоль полётов Всеобщего Бюро Контроля. Возврат на ЦК разрешён через 60 минут после прибытия в сектор станции. По истечении срока шаттл уходит автоматически через 3 минуты."
	shuttleId = "sol_inspection"
	possible_destinations = "sol_inspection_custom;sol_inspection_home"
	no_destination_swap = TRUE

/// A "Locked" console with no explanation reads as a bug to the crew, so spell the reason out.
/obj/machinery/computer/shuttle/sol_inspection/ui_data(mob/user)
	. = ..()
	var/obj/docking_port/mobile/sol_inspection/vessel = SSshuttle.getShuttle(shuttleId)
	var/datum/team/sol_inspection/team = istype(vessel) ? vessel.inspection_team : null
	.["status_note"] = null
	if(!.["locked"] || !team)
		return
	if(team.returned_home)
		.["status_note"] = "Инспекция завершена."
	else if(!team.visited_station)
		.["status_note"] = "Инспекция ещё не прибыла в сектор станции."
	else if(team.fines_total >= SOL_INSPECTION_EARLY_RETURN_FINE)
		.["status_note"] = "Доступен досрочный вылет на ЦК (взыскано [team.fines_total] кредитов)."
	else
		.["status_note"] = "Возврат на ЦК через [DisplayTimeText(team.return_time_left())], затем шаттл уйдёт автоматически ещё через [DisplayTimeText(SOL_INSPECTION_DEPARTURE_DELAY, 1)]."
	return

/obj/machinery/computer/shuttle/sol_inspection/ui_act(action, params)
	if(!usr?.mind?.has_antag_datum(/datum/antagonist/sol_inspector))
		to_chat(usr, span_warning("Управление доступно только членам инспекции."))
		return TRUE
	return ..()

/obj/machinery/computer/shuttle/sol_inspection/examine(mob/user)
	. = ..()
	var/obj/docking_port/mobile/sol_inspection/vessel = SSshuttle.getShuttle(shuttleId)
	var/datum/team/sol_inspection/team = vessel?.inspection_team
	if(!team || team.returned_home)
		return
	if(!team.visited_station)
		. += span_notice("Инспекция ещё не прибыла в сектор станции: таймер возврата на ЦК не запущен.")
		return
	. += span_notice("До разрешения вернуться на ЦК: [DisplayTimeText(team.return_time_left())], по истечении срока шаттл уйдёт автоматически ещё через [DisplayTimeText(SOL_INSPECTION_DEPARTURE_DELAY, 1)]. Досрочный вылет доступен при взыскании [SOL_INSPECTION_EARLY_RETURN_FINE] кредитов.")

/obj/machinery/computer/camera_advanced/shuttle_docker/sol_inspection
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

#undef SOL_INSPECTION_EARLY_RETURN_FINE
#undef SOL_INSPECTION_MINIMUM_STAY
#undef SOL_INSPECTION_RETURN_POLL
#undef SOL_INSPECTION_DEPARTURE_DELAY
