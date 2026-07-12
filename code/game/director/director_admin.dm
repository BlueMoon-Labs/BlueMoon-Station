/// TGUI-обёртка панели директора; создаётся на клик, живёт на клиенте
/datum/director_panel

/datum/director_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/director_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DirectorPanel")
		ui.open()

/// Справочник профилей для вкладки "Профили": меняется только на перезагрузке конфига,
/// поэтому static. Активный профиль отдаётся живым объектом (видны VV-правки и применённый
/// конфиг), остальные - свежими экземплярами с наложенной их секцией director.json:
/// "каким профиль станет, если выбрать его тип раунда".
/datum/director_panel/ui_static_data(mob/user)
	var/datum/controller/subsystem/director/D = SSdirector
	var/list/profiles_conf = islist(D.cached_config) ? D.cached_config["profiles"] : null
	var/list/profiles_out = list()
	for(var/datum/director_profile/path as anything in subtypesof(/datum/director_profile))
		var/round_type = initial(path.round_type)
		var/is_active = D.profile && (D.profile.round_type == round_type)
		var/list/row
		if(is_active)
			row = D.profile.panel_snapshot()
		else
			var/datum/director_profile/preview = new path
			if(islist(profiles_conf) && islist(profiles_conf[round_type]))
				D.apply_profile_config(preview, profiles_conf[round_type], quiet = TRUE)
			row = preview.panel_snapshot()
			qdel(preview)
		row["active"] = is_active
		profiles_out += list(row)
	return list("profiles" = profiles_out)

/datum/director_panel/ui_data(mob/user)
	var/datum/controller/subsystem/director/D = SSdirector
	// Итог считаем до сборки таблицы: get_active_intensity() заодно выкидывает истёкшие записи
	// и мосты исполненных рулсетов, иначе мост и его же динамическая строка задвоились бы в таблице.
	var/list/ruleset_rows = list()
	var/active_intensity = D.get_active_intensity(ruleset_rows)
	var/list/ledger_out = list()
	for(var/list/ruleset_row in ruleset_rows)
		ledger_out += list(list("name" = ruleset_row[1], "intensity" = round(ruleset_row[2], 0.1),
			"living" = ruleset_row[3], "assigned" = ruleset_row[4]))
	for(var/list/entry in D.intensity_ledger)
		ledger_out += list(list("name" = entry[1], "intensity" = entry[2],
			"expires_in" = entry[3] ? max(0, round((entry[3] - D.now()) / 600)) : null))
	var/list/beats_out = list()
	var/from_index = max(1, length(D.beat_log) - 19)
	for(var/i in from_index to length(D.beat_log))
		beats_out += list(D.beat_log[i])
	// Кошельки со всей экономикой ступени: пауза, счётчик запусков, поправка веса.
	var/list/wallets_out = list()
	var/total_fired = 0
	for(var/sev in D.fired_counts)
		total_fired += D.fired_counts[sev]
	for(var/sev in D.budgets)
		var/list/row = list(
			"severity" = sev,
			"points" = round(D.budgets[sev], 0.1),
			"share" = D.profile ? D.profile.pool_shares[sev] : 0,
			"spacingLeft" = D.profile ? max(0, CEILING(D.spacing_remaining(sev) / (1 MINUTES), 1)) : 0,
			"fired" = D.fired_counts[sev] || 0,
			"correction" = (D.profile && total_fired) ? round(D.share_correction(sev), 0.01) : 1,
		)
		if(DIRECTOR_IS_ANTAG_POOL(sev) && D.profile)
			row["heavySpacingLeft"] = max(0, CEILING(D.spacing_remaining(sev, TRUE) / (1 MINUTES), 1))
			var/datum/director_action/saving_for = D.pool_saving[sev]
			if(saving_for)
				row["savingFor"] = saving_for.action_name()
				row["savingCost"] = saving_for.cost
		wallets_out += list(row)
	// Текущая капля с разложением по множителям профиля.
	var/drip_rate = 0
	var/time_mult = 1
	var/pop_mult = 1
	var/dead_halved = FALSE
	var/antag_drip_rate = 0
	var/antag_load_now = 0
	var/antag_target_now = 0
	if(D.profile && SSticker.HasRoundStarted())
		var/minutes = (D.now() - SSticker.round_start_time) / (1 MINUTES)
		time_mult = piecewise_eval(D.profile.time_curve, minutes)
		pop_mult = piecewise_eval(D.profile.pop_curve, D.last_signals ? D.last_signals.effective_crew : 0)
		dead_halved = D.last_signals && (D.last_signals.dead_fraction > D.profile.dead_fraction_threshold)
		drip_rate = D.profile.base_drip * time_mult * pop_mult * (dead_halved ? 0.5 : 1)
		antag_drip_rate = D.profile.antag_drip * D.last_antag_deficit * (dead_halved ? 0.5 : 1)
		antag_load_now = D.antag_load()
		antag_target_now = D.antag_target(D.last_signals ? D.last_signals.effective_crew : 0)
	return list(
		"paused" = D.paused,
		"budget" = round(D.total_budget(), 0.1),
		"profileName" = D.profile ? GLOB.round_type : null,
		"intensity" = active_intensity,
		"intensityCap" = D.profile ? D.profile.intensity_cap : 0,
		"crew" = D.last_signals ? D.last_signals.effective_crew : 0,
		"deadFraction" = D.last_signals ? round(D.last_signals.dead_fraction * 100) : 0,
		"staffing" = D.last_signals ? D.last_signals.staffing : list(),
		"configError" = D.config_error,
		"pending" = D.pending_action ? D.pending_action.action_name() : null,
		"pendingSeverity" = D.pending_action ? D.pending_action.severity : null,
		"pendingLeft" = (D.pending_action && D.pending_timer_id) ? max(0, round(timeleft(D.pending_timer_id) / 10)) : null,
		"ledger" = ledger_out,
		"beats" = beats_out,
		"blockedSeverities" = D.blocked_severities,
		"lastRejects" = D.last_reject_stats,
		"wallets" = wallets_out,
		"dripRate" = round(drip_rate, 0.01),
		"dripTimeMult" = round(time_mult, 0.01),
		"dripPopMult" = round(pop_mult, 0.01),
		"dripDeadHalved" = dead_halved,
		"antagDripRate" = round(antag_drip_rate, 0.01),
		"antagDeficit" = round(D.last_antag_deficit * 100),
		"antagLoad" = round(antag_load_now, 0.1),
		"antagTarget" = round(antag_target_now, 0.1),
		"quietFor" = SSticker.HasRoundStarted() ? round((D.now() - D.last_any_fired_at) / (1 MINUTES)) : 0,
		"maxQuiet" = D.profile ? D.profile.max_quiet_time / (1 MINUTES) : 0,
		"quietThreshold" = D.profile ? D.profile.quiet_intensity_threshold : 0,
		"maxActiveMajor" = D.profile ? D.profile.max_active_major : 0,
		"pool" = D.evaluate_pool(),
	)

/datum/director_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(!check_rights(R_ADMIN))
		return
	var/datum/controller/subsystem/director/D = SSdirector
	switch(action)
		if("toggle_pause")
			D.paused = !D.paused
			message_admins("[key_name_admin(usr)] [D.paused ? "поставил директора на паузу" : "снял директора с паузы"].")
			log_admin("[key_name(usr)] [D.paused ? "поставил директора на паузу" : "снял директора с паузы"].")
			return TRUE
		if("force_beat")
			// Живое окно отмены уже ждёт решения - молчаливый DIRECTOR_BEAT_IDLE запутал бы админа,
			// дадим внятный ответ вместо тихого no-op.
			if(D.pending_action)
				to_chat(usr, "Уже есть ожидающее действие - сначала отмените или дождитесь его")
				return TRUE
			var/datum/director_signals/signals = D.collect_signals()
			D.run_beat(signals, forced = TRUE)
			message_admins("[key_name_admin(usr)] форсировал бит директора.")
			log_admin("[key_name(usr)] форсировал бит директора.")
			return TRUE
		if("adjust_budget")
			var/amount = text2num(params["amount"])
			if(isnull(amount))
				return
			// Дельту раскладываем по кошелькам ступеней (как донат), а не в один общий счёт.
			D.distribute_to_budgets(amount)
			message_admins("[key_name_admin(usr)] изменил бюджет директора на [amount] (итого [round(D.total_budget(), 0.1)]).")
			log_admin("[key_name(usr)] изменил бюджет директора на [amount] (итого [round(D.total_budget(), 0.1)]).")
			return TRUE
		if("reload_config")
			D.load_config()
			// Вкладка "Профили" сидит на static-данных - без пинка она показывала бы старый конфиг
			update_static_data(usr, ui)
			message_admins("[key_name_admin(usr)] перезагрузил director.json.")
			log_admin("[key_name(usr)] перезагрузил director.json.")
			return TRUE
		if("cancel_pending")
			D.Topic(null, list("cancel_pending" = "1"))
			return TRUE
		if("reroll_pending")
			D.Topic(null, list("reroll_pending" = "1"))
			return TRUE
		if("toggle_severity_block")
			var/sev = params["severity"]
			// Не верим клиенту: VV/модифицированный клиент мог бы засорить blocked_severities мусорными строками.
			if(!(sev in list(DIRECTOR_SEVERITY_FLAVOR, DIRECTOR_SEVERITY_MINOR, DIRECTOR_SEVERITY_MODERATE, DIRECTOR_SEVERITY_MAJOR, DIRECTOR_SEVERITY_ANTAG, DIRECTOR_SEVERITY_GHOST)))
				return
			if(sev in D.blocked_severities)
				D.blocked_severities -= sev
			else
				D.blocked_severities += sev
			message_admins("[key_name_admin(usr)] переключил блокировку ступени [sev] у директора.")
			log_admin("[key_name(usr)] переключил блокировку ступени [sev] у директора.")
			return TRUE

/client/proc/director_panel_verb()
	set category = "Admin.Events"
	set name = "Director Panel"
	if(!check_rights(R_ADMIN))
		return
	var/datum/director_panel/panel = new
	panel.ui_interact(mob)
