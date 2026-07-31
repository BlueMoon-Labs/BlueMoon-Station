/datum/round_event_control/vox_scavengers
	name = "Vox Scavengers"
	typepath = /datum/round_event/vox_scavengers
	admin_only = FALSE
	// Вес против беглецов (10) в гост-пуле Light: воксы примерно каждый третий гост-бит.
	weight = 4
	max_occurrences = 1
	min_players = 30
	// Рейд-корабль не должен падать на 15-й минуте лёгкого раунда: тот же порог, что у беглецов.
	earliest_start = 30 MINUTES
	category = EVENT_CATEGORY_INVASION
	// Гост-команда со своего корабля: считается антаг-нагрузкой GHOST-пула,
	// а не MAJOR по дефолту категории INVASION (ср. devil).
	severity = DIRECTOR_SEVERITY_GHOST
	// Дороже беглецов (8): гост-кошелёк Light копит ~0.27 очка в минуту, так что мягкий
	// гост-конфликт обычно успевает первым, а рейд остаётся поздней дорогой покупкой.
	cost = 12
	intensity = 15
	director_ghost_jobban = ROLE_TRAITOR
	director_ghost_preference = ROLE_TRAITOR
	family = "vox_scavengers"
	// Решение геймдизайна: воксы живут только в лёгком профиле (ср. df50afe95d).
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT)
	description = "A vox scavengers heist."
	var/ship_template

/datum/round_event_control/vox_scavengers/preRunEvent(admin_window = TRUE)
	if (!SSmapping.empty_space)
		return EVENT_CANT_RUN

	return ..()

/datum/round_event/vox_scavengers/start()
	spawn_vox_scavengers(source_action = control, refund_cost = triggered_randomly ? control.cost : 0)

/// Спавн не состоялся: возвращаем директору бюджет и паузы, чтобы он подобрал замену.
/proc/fail_vox_scavengers_spawn(datum/director_action/source_action, refund_cost, reason)
	message_admins("Vox Scavengers event failed: [reason]")
	if(!source_action)
		return
	// Бюджет списывался только на естественный запуск через бит (админ-форс идёт мимо кошельков),
	// и ровно это отражает ненулевой refund_cost.
	var/budget_backed = refund_cost > 0
	SSdirector.note_failed_action(source_action, refund_budget = budget_backed, retry_replacement = budget_backed)
	SSdirector.director_log_beat(SSdirector.collect_signals(), source_action, DIRECTOR_BEAT_FAILED,
		detail = "[reason]; [budget_backed ? "бюджет и паузы возвращены, запрошена замена" : "ручной запуск, бюджет не списывался; паузы возвращены"]")

/proc/spawn_vox_scavengers(datum/director_action/source_action, refund_cost = 0)
	var/ship_template = /datum/map_template/shuttle/vox_raiders

	var/datum/map_template/shuttle/ship = new ship_template
	var/x = rand(TRANSITIONEDGE,world.maxx - TRANSITIONEDGE - ship.width)
	var/y = rand(TRANSITIONEDGE,world.maxy - TRANSITIONEDGE - ship.height)
	var/z = SSmapping.empty_space?.z_value
	if(!z)
		fail_vox_scavengers_spawn(source_action, refund_cost, "нет подходящего Z-уровня для корабля")
		return

	var/turf/T = locate(x,y,z)
	if(!T || !ship.load(T))
		fail_vox_scavengers_spawn(source_action, refund_cost, "корабль не удалось загрузить на карту")
		return

	var/list/spawners_list = list()
	for(var/turf/A in ship.get_affected_turfs(T))
		for(var/obj/effect/mob_spawn/human/vox_scavenger/spawner in A)
			spawners_list += spawner

	var/list/candidates = pollGhostCandidates("Do you wish to be considered for Vox Scavengers?", ROLE_TRAITOR, minimum_required = spawners_list.len)
	var/list/spawned_scavengers = list()
	var/spawner_count = length(spawners_list)
	var/intensity_share = source_action && spawner_count ? source_action.intensity / spawner_count : 0
	var/refund_share = spawner_count ? refund_cost / spawner_count : 0

	for(var/obj/effect/mob_spawn/human/spawner in spawners_list)
		if(LAZYLEN(candidates))
			var/mob/our_candidate = pick_n_take(candidates)
			var/mob/living/spawned_scavenger = spawner.create(our_candidate.ckey)
			if(spawned_scavenger)
				spawned_scavengers += spawned_scavenger
			notify_ghosts("Skipjack has an object of interest: [our_candidate]!", source=our_candidate, action=NOTIFY_ORBIT, header="Something's Interesting!")
		else
			spawner.director_source_action = source_action
			spawner.director_intensity = intensity_share
			spawner.director_refund_cost = refund_share
			notify_ghosts("Skipjack ship has an object of interest: [spawner]!", source=spawner, action=NOTIFY_ORBIT, header="Something's Interesting!")
	if(source_action && length(spawned_scavengers))
		var/spawned_fraction = length(spawned_scavengers) / max(1, spawner_count)
		SSdirector.track_ghost_role_spawn(
			source_action,
			spawned_scavengers,
			budget_backed = refund_cost > 0,
			intensity_override = source_action.intensity * spawned_fraction,
			refund_cost_override = refund_cost * spawned_fraction,
		)
	else if(source_action)
		SSdirector.director_log_beat(SSdirector.collect_signals(), source_action, DIRECTOR_BEAT_EXECUTED,
			detail = "корабль создан; сразу назначено ролей: 0, свободные спавнеры оставлены призракам")

/// Dynamic ruleset additions
/datum/dynamic_ruleset/midround/vox_scavengers
	name = "Vox Scavengers"
	admin_only = TRUE
	severity = DIRECTOR_SEVERITY_GHOST // событие поллит призраков, экипаж не тратится
	antag_flag = "Vox Scavengers"
	required_type = /mob/dead/observer
	enemy_roles = list("Security Officer", "Detective", "Head of Security","Bridge Officer", "Captain")
	// Тот же профиль, что у прямого события: рулсет admin_only и естественным выбором не участвует,
	// но панель директора и админ-форс не должны показывать противоречивую доступность.
	required_round_type = list(ROUNDTYPE_DYNAMIC_LIGHT)
	required_enemies = list(0,0,0,0,0,0,0,0,0,0)
	required_candidates = 0
	weight = 3
	cost = 12
	intensity = 15
	family = "vox_scavengers"
	requirements = list(101,101,101,40,30,20,10,10,10,10)
	repeatable = FALSE

/datum/dynamic_ruleset/midround/vox_scavengers/acceptable(population=0, threat=0)
	if (!SSmapping.empty_space)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/vox_scavengers/execute()
	spawn_vox_scavengers(source_action = src, refund_cost = director_pending_cost)
	return ..()

// name совпадает с /datum/round_event_control/vox_scavengers ("Vox Scavengers"), который этот
// рулсет сам же и запускает через spawn_vox_scavengers() - без суффикса они делили бы
// ключ конфига/intensity_ledger.
/datum/dynamic_ruleset/midround/vox_scavengers/action_name()
	return "[name] (Ruleset)"
