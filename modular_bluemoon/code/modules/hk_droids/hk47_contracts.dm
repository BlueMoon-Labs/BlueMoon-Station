/// pickweight берёт целые веса, а «Больше убийств» умножает вес ликвидации на 1.5.
#define HK47_TASK_WEIGHT_SCALE 10

GLOBAL_LIST_INIT(hk_contract_clients, list(
	HK_CLIENT_SYNDICATE = list(
		"name" = "Синдикат",
		"flavor" = "Платит за кровь и сорванную работу станции и доплачивает сверху. Вся его работа грязная.",
		"bonus" = HK47_SYNDICATE_BONUS_POINTS,
		"tasks" = list(
			/datum/hk_contract_task/kill = 3,
			/datum/hk_contract_task/sabotage = 2,
			/datum/hk_contract_task/theft = 1,
			/datum/hk_contract_task/theft/relic = 1,
			/datum/hk_contract_task/hunt = 1,
		),
	),
	HK_CLIENT_CORP = list(
		"name" = "Корпорация-конкурент",
		"flavor" = "Конкурентам Nanotrasen нужны чужие секреты, люди и простой станции. Часть оплаты присылают снаряжением.",
		"perk" = "капсула со снаряжением от корпорации",
		"tasks" = list(
			/datum/hk_contract_task/theft = 2,
			/datum/hk_contract_task/theft/relic = 2,
			/datum/hk_contract_task/capture = 2,
			/datum/hk_contract_task/sabotage = 1,
		),
	),
	HK_CLIENT_PRIVATE = list(
		"name" = "Частное лицо",
		"flavor" = "Анонимный заказчик с личными счётами. Платит без премий, зато охрана у него - чистая работа.",
		"tasks" = list(
			/datum/hk_contract_task/capture = 3,
			/datum/hk_contract_task/protect = 2,
			/datum/hk_contract_task/kill = 1,
			/datum/hk_contract_task/hunt = 1,
		),
	),
	HK_CLIENT_CENTCOM = list(
		"name" = "Центральное командование",
		"flavor" = "ЦК нанимает HK, когда на станции орудует враг. Премий не платит, но прикрывает подрядчика перед станцией.",
		"perk" = "ЦК закроет одно дело: отзыв лицензии или раскрытие, а без дел снимет розыск",
		"tasks" = list(
			/datum/hk_contract_task/hunt = 3,
			/datum/hk_contract_task/protect/head = 1,
		),
	),
))

/proc/hk_contract_singletons(base_type)
	var/list/singletons = list()
	for(var/singleton_type in subtypesof(base_type))
		singletons[singleton_type] = new singleton_type
	return singletons

/// Контракт HK-47: заказчик, задача, необязательный модификатор и цель (разум, машина или вещь).
/datum/hk_contract
	var/static/last_id = 0
	/// Порядковый номер: REF удалённого контракта может достаться новому, номер - нет.
	var/id
	/// Снимок цели в base64, делается один раз на контракт.
	var/photo
	var/photo_taken = FALSE
	var/client_id
	var/datum/hk_contract_task/task
	var/datum/hk_contract_modifier/modifier
	var/datum/weakref/target_ref
	var/target_name
	var/target_job
	/// Кража ценности: годится любой экземпляр этого типа, даже если оригинал уничтожен.
	var/target_type
	var/datum/antagonist/hk47/hunter
	var/accepted_at = 0
	var/state = HK_CONTRACT_OFFERED
	/// Охоту можно закрыть убийством; при стиле «Без убийств» - только захватом.
	var/lethal = FALSE
	var/modifier_held = FALSE
	/// Видел ли кто-то, кроме цели и слуг HK, хоть один решающий момент: удар по цели, её смерть, взятие добычи, вызов капсулы, выполнение.
	var/witnessed = FALSE
	var/closed_by_kill = FALSE
	var/capture_called = FALSE
	var/target_died = FALSE
	var/death_was_accident = FALSE
	var/collateral = FALSE
	var/protect_timer
	var/protect_sample_timer
	var/protect_samples = 0
	var/protect_near_samples = 0
	var/rival_timer
	var/list/datum/weakref/rival_refs
	/// Тело HK, которому придёт сигнал о выполнении: по нему заказчик платит своей монетой.
	var/datum/weakref/completion_body_ref
	/// Охота: имя цели скрыто, пока HK не опознает её вблизи.
	var/identified = FALSE
	var/trace_area
	var/trace_time
	var/datum/weakref/watched_body_ref

/datum/hk_contract/New(datum/antagonist/hk47/hunter, client_id, datum/hk_contract_task/task, datum/target)
	. = ..()
	id = ++last_id
	src.hunter = hunter
	src.client_id = client_id
	src.task = task
	target_ref = WEAKREF(target)
	lethal = task.lethal_for(hunter, client_id, target)
	task.snapshot_target(src, target)
	RegisterSignal(hunter, COMSIG_PARENT_QDELETING, PROC_REF(on_hunter_deleted))

/datum/hk_contract/Destroy()
	stop()
	if(hunter)
		UnregisterSignal(hunter, COMSIG_PARENT_QDELETING)
	hunter = null
	return ..()

/datum/hk_contract/proc/on_hunter_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/hk_contract/proc/get_target()
	return target_ref?.resolve()

/datum/hk_contract/proc/target_mind()
	var/datum/mind/target_mind = get_target()
	return istype(target_mind) ? target_mind : null

/datum/hk_contract/proc/target_body()
	var/datum/mind/target_mind = target_mind()
	return target_mind?.current

/datum/hk_contract/proc/client_name()
	return GLOB.hk_contract_clients[client_id]["name"]

/datum/hk_contract/proc/client_info(key)
	return GLOB.hk_contract_clients[client_id][key]

/datum/hk_contract/proc/client_bonus()
	return client_info("bonus") || 0

/// Сколько контракт может принести: задача, премия заказчика и бонус модификатора.
/datum/hk_contract/proc/points()
	return task.points + client_bonus() + (modifier ? HK47_MODIFIER_POINTS : 0)

/datum/hk_contract/proc/earned_points()
	return task.points + client_bonus() + (modifier_held ? HK47_MODIFIER_POINTS : 0)

/datum/hk_contract/proc/is_hunt()
	return istype(task, /datum/hk_contract_task/hunt)

/// Неопознанную цель охоты нельзя ни назвать, ни вести стрелкой.
/datum/hk_contract/proc/trackable()
	return !is_hunt() || identified

/datum/hk_contract/proc/display_target()
	if(!trackable())
		return "личность не установлена"
	return target_job ? "[target_name] ([target_job])" : target_name

/datum/hk_contract/proc/describe()
	var/text = "[client_name()]: [task.name] - [display_target()]"
	if(modifier)
		text += ", условие «[modifier.name]»"
	return text

/// world.time, к которому надо успеть: срок «срочно» или конец охраны; 0 - без срока.
/datum/hk_contract/proc/deadline()
	if(state != HK_CONTRACT_ACTIVE)
		return 0
	if(istype(task, /datum/hk_contract_task/protect))
		return accepted_at + HK47_PROTECT_TIME
	if(istype(modifier, /datum/hk_contract_modifier/urgent))
		return accepted_at + HK47_URGENT_TIME
	return 0

/datum/hk_contract/proc/target_unavailable_reason()
	return task.unavailable_reason(src)

/// Предложение перед принятием: к недоступности добавляется сверка согласия и того, что цель жива.
/datum/hk_contract/proc/offer_unavailable_reason()
	. = target_unavailable_reason()
	if(.)
		return
	var/datum/mind/target_mind = target_mind()
	if(target_mind && !hunter.valid_target(target_mind, task.required_level(hunter)))
		return "цель больше не подходит: погибла или сменила согласие на роль цели."

/// Причина недоступности для HK: у неопознанной цели охоты она не называется, иначе по ней вычисляют скрытую цель.
/datum/hk_contract/proc/shown_unavailable_reason(reason)
	if(reason && !trackable())
		return "заказчик потерял след цели."
	return reason

/datum/hk_contract/proc/roll_modifier()
	if(!prob(HK47_MODIFIER_CHANCE))
		return
	var/list/options = list()
	for(var/modifier_type in GLOB.hk_contract_modifiers)
		var/datum/hk_contract_modifier/option = GLOB.hk_contract_modifiers[modifier_type]
		if(option.compatible(src))
			options += option
	if(length(options))
		modifier = pick(options)

/datum/hk_contract/proc/start()
	state = HK_CONTRACT_ACTIVE
	accepted_at = world.time
	var/datum/mind/target_mind = target_mind()
	if(target_mind)
		RegisterSignal(target_mind, COMSIG_MIND_TRANSFER, PROC_REF(on_target_transferred))
		watch_body(target_mind.current)
	if(is_hunt())
		RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_any_death))
	var/mob/living/droid = hunter.owner?.current
	if(droid)
		completion_body_ref = WEAKREF(droid)
		RegisterSignal(droid, COMSIG_HK47_CONTRACT_COMPLETED, PROC_REF(on_completed))
	task.on_accept(src)

/datum/hk_contract/proc/stop()
	if(protect_timer)
		deltimer(protect_timer)
		protect_timer = null
	deltimer(protect_sample_timer)
	protect_sample_timer = null
	deltimer(rival_timer)
	rival_timer = null
	dismiss_rivals()
	var/mob/living/completion_body = completion_body_ref?.resolve()
	if(completion_body)
		UnregisterSignal(completion_body, COMSIG_HK47_CONTRACT_COMPLETED)
	completion_body_ref = null
	var/datum/mind/target_mind = target_mind()
	if(target_mind)
		UnregisterSignal(target_mind, COMSIG_MIND_TRANSFER)
	var/obj/machinery/machine = get_target()
	if(istype(machine))
		UnregisterSignal(machine, list(COMSIG_PARENT_QDELETING, COMSIG_MACHINERY_BROKEN))
	unwatch_body()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)

/// Тело цели: удары и выстрелы по ней ловятся до урона, поэтому смертельное попадание успевает попасть в учёт.
/datum/hk_contract/proc/watch_body(mob/living/body)
	unwatch_body()
	if(!isliving(body))
		return
	watched_body_ref = WEAKREF(body)
	RegisterSignal(body, COMSIG_LIVING_DEATH, PROC_REF(on_target_death))
	RegisterSignal(body, COMSIG_LIVING_ATTACKER_SET, PROC_REF(on_target_attacked))
	RegisterSignal(body, COMSIG_LIVING_HIT_BY_PROJECTILE, PROC_REF(on_target_shot))
	if(is_hunt())
		RegisterSignal(body, COMSIG_LIVING_SET_AS_ATTACKER, PROC_REF(on_target_struck))
		RegisterSignal(body, COMSIG_LIVING_GUN_PROCESS_FIRE, PROC_REF(on_target_fired))
	if(is_hunt() && identified && client_id == HK_CLIENT_CENTCOM)
		RegisterSignal(body, COMSIG_ENTER_AREA, PROC_REF(on_target_entered_area))

/datum/hk_contract/proc/unwatch_body()
	var/mob/living/body = watched_body_ref?.resolve()
	if(body)
		UnregisterSignal(body, list(COMSIG_LIVING_DEATH, COMSIG_LIVING_ATTACKER_SET, COMSIG_LIVING_HIT_BY_PROJECTILE, COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_ENTER_AREA))
	watched_body_ref = null

/datum/hk_contract/proc/on_target_transferred(datum/mind/source, mob/new_character, mob/old_character)
	SIGNAL_HANDLER
	watch_body(new_character)

/datum/hk_contract/proc/on_target_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	target_died = TRUE
	death_was_accident = !hunter.recent_side_hit(source)
	// До закрытия контракта: закрытый контракт гасит лицензию раньше, чем дойдёт глобальный сигнал смерти.
	if(!death_was_accident)
		hunter.on_side_kill(source)
	if(!hunter.counts_as_player(source))
		hunter.drop_contract(src, "Утверждение: цель погибла без игрока в теле. За такое заказчик не платит, контракт снят без штрафа.")
		return
	if(!death_was_accident)
		note_witnesses()
	task.on_target_death(src)

/datum/hk_contract/proc/on_target_attacked(mob/living/source, mob/living/attacker)
	SIGNAL_HANDLER
	note_target_attacker(source, attacker)

/datum/hk_contract/proc/on_target_shot(mob/living/source, obj/item/projectile/projectile)
	SIGNAL_HANDLER
	note_target_attacker(source, projectile.firer)

/// Удар HK или слуги по цели идёт в учёт попаданий; чужой удар по охраняемому делает напавшего законной целью.
/datum/hk_contract/proc/note_target_attacker(mob/living/target, mob/living/attacker)
	if(hunter.is_hk_side(attacker))
		hunter.note_side_hit(target)
	else if(istype(task, /datum/hk_contract_task/protect))
		hunter.note_aggressor(attacker)

/// Свидетели копятся по решающим моментам: убийство при толпе не спрятать, отнеся тело в техи.
/datum/hk_contract/proc/note_witnesses()
	if(!witnessed && length(hunter.witnesses(src)))
		witnessed = TRUE

/datum/hk_contract/proc/on_hunter_took(obj/item/taken)
	var/datum/hk_contract_task/theft/theft = task
	if(istype(theft) && theft.loot_of(src, taken))
		note_witnesses()

/datum/hk_contract/proc/on_any_death(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	if(died == target_body())
		return
	var/killer_ckey = hk47_recent_attacker(died)
	var/datum/mind/target_mind = target_mind()
	if(killer_ckey && target_mind?.key && ckey(target_mind.key) == killer_ckey)
		update_trace(get_area_name(died, TRUE))

/datum/hk_contract/proc/on_target_struck(mob/living/source, mob/living/victim)
	SIGNAL_HANDLER
	update_trace(get_area_name(source, TRUE))

/datum/hk_contract/proc/on_target_fired(mob/living/source, atom/target, params, zone_override)
	SIGNAL_HANDLER
	update_trace(get_area_name(source, TRUE))

/// След охоты: где цель последний раз проявила себя. Обновляется только её действиями.
/datum/hk_contract/proc/update_trace(area_name)
	trace_area = area_name
	trace_time = world.time

/datum/hk_contract/proc/trace_age()
	return isnull(trace_time) ? null : world.time - trace_time

/datum/hk_contract/proc/trace_cold()
	return isnull(trace_time) || world.time - trace_time > HK47_TRACE_COLD_TIME

/// Цель в нескольких клетках от HK, без направления.
/datum/hk_contract/proc/target_near(range = HK47_HUNT_NEAR_RANGE)
	var/mob/living/body = target_body()
	var/mob/living/droid = hunter.owner?.current
	if(!body || !droid)
		return FALSE
	var/turf/body_turf = get_turf(body)
	var/turf/droid_turf = get_turf(droid)
	return body_turf && droid_turf && body_turf.z == droid_turf.z && get_dist(body_turf, droid_turf) <= range

/datum/hk_contract/proc/identify()
	identified = TRUE
	watch_body(target_body())
	check_brig_delivery()

/datum/hk_contract/proc/on_target_entered_area(mob/living/source, area/new_area)
	SIGNAL_HANDLER
	check_brig_delivery()

/// Охота ЦК на задержание закрывается и доставкой опознанной обездвиженной цели в камеру брига, если её привёл сам HK.
/datum/hk_contract/proc/check_brig_delivery()
	if(!is_hunt() || !identified || client_id != HK_CLIENT_CENTCOM || state != HK_CONTRACT_ACTIVE)
		return FALSE
	var/mob/living/body = target_body()
	if(!body || !hk47_capture_ready(body) || !hunter.counts_as_player(body) || !hunter.in_brig(body))
		return FALSE
	var/mob/living/droid = hunter.owner?.current
	if(!droid || (droid.pulling != body && !target_near(HK47_BRIG_ESCORT_RANGE)))
		return FALSE
	return hunter.complete(src)

/datum/hk_contract/proc/note_collateral(mob/living/victim)
	if(victim == target_body() || hunter.is_hk_side(victim))
		return
	if(victim.mind || ishuman(victim))
		collateral = TRUE

/datum/hk_contract/proc/watch_machine(obj/machinery/machine)
	RegisterSignals(machine, list(COMSIG_PARENT_QDELETING, COMSIG_MACHINERY_BROKEN), PROC_REF(on_machine_destroyed))

/datum/hk_contract/proc/on_machine_destroyed(obj/machinery/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_PARENT_QDELETING, COMSIG_MACHINERY_BROKEN))
	hunter.complete(src)

/datum/hk_contract/proc/protect_time_up()
	protect_timer = null
	var/mob/living/body = target_body()
	if(body?.stat == DEAD)
		hunter.fail(src, "VIP не дожил до конца охраны.")
		return
	var/reason = target_unavailable_reason()
	if(reason)
		hunter.drop_contract(src, "Утверждение: охрана снята без штрафа, [reason]")
		return
	var/presence = presence_percent()
	if(presence < HK47_PROTECT_PRESENCE_PERCENT)
		hunter.fail(src, "VIP жив, но вы были рядом с ним [presence]% срока, а заказчик платит от [HK47_PROTECT_PRESENCE_PERCENT]%.")
		return
	hunter.complete(src)

/datum/hk_contract/proc/sample_protection()
	protect_samples++
	if(target_near(HK47_PROTECT_RANGE))
		protect_near_samples++

/// Доля срока охраны, которую HK провёл рядом с подопечным; без замеров - по тому, где он сейчас.
/datum/hk_contract/proc/presence_percent()
	if(!protect_samples)
		return target_near(HK47_PROTECT_RANGE) ? 100 : 0
	return round(protect_near_samples * 100 / protect_samples)

/// Сколько секунд ещё нужно провести рядом с подопечным, чтобы набрать норму присутствия за весь срок.
/datum/hk_contract/proc/presence_seconds_left()
	var/needed_samples = CEILING(HK47_PROTECT_TIME / HK47_PROTECT_SAMPLE * HK47_PROTECT_PRESENCE_PERCENT / 100, 1)
	return max(0, needed_samples - protect_near_samples) * HK47_PROTECT_SAMPLE / (1 SECONDS)

/// Середина охраны: конкурент шлёт пару HK-50, когда HK рядом с подопечным на станции. Без согласия подопечного на убийство они идут за самим HK.
/datum/hk_contract/proc/send_rivals()
	deltimer(rival_timer)
	rival_timer = null
	var/mob/living/vip = target_body()
	var/mob/living/droid = hunter.owner?.current
	if(!vip || vip.stat == DEAD || !droid || droid.stat == DEAD)
		return FALSE
	if(!target_near(HK47_PROTECT_RANGE) || !hunter.in_contract_zone(vip))
		if(deadline() - world.time > HK47_PROTECT_SAMPLE)
			rival_timer = addtimer(CALLBACK(src, PROC_REF(send_rivals)), HK47_PROTECT_SAMPLE, TIMER_STOPPABLE)
		return FALSE
	var/vip_marked = antag_opt_in_allows(target_mind(), ANTAG_OPT_IN_KILL)
	var/mob/living/mark = vip_marked ? vip : droid
	var/turf/landing = hk47_rival_landing(mark)
	if(!landing)
		return FALSE
	var/obj/structure/closet/supplypod/hk47/reinforcement/pod = new
	pod.effectQuiet = FALSE
	pod.on_open = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(hk47_rivals_landed), WEAKREF(src), WEAKREF(mark))
	hunter.send_pod(pod, landing)
	var/landing_area = get_area_name(landing, TRUE)
	if(vip_marked)
		to_chat(droid, span_userdanger("Утверждение: перехвачен заказ конкурента. Пара HK-50 летит за подопечным, посадка - [landing_area]."))
		hunter.notify_vip(vip, "Анонимный доброжелатель предупреждает: за вами летят дроиды-убийцы HK-50. Держитесь рядом с [HK47_NAME].")
	else
		to_chat(droid, span_userdanger("Утверждение: перехвачен заказ конкурента на телохранителя. Пара HK-50 летит за вами, посадка - [landing_area]."))
		hunter.notify_vip(vip, "Анонимный доброжелатель предупреждает: конкурент прислал дроидов HK-50 за вашим телохранителем [HK47_NAME]. Вы им не нужны, но держитесь подальше от перестрелки.")
	SEND_SOUND(droid, sound('sound/machines/warning-buzzer.ogg'))
	SEND_SOUND(vip, sound('sound/machines/warning-buzzer.ogg'))
	log_game("[key_name(hunter.owner)]: конкурент шлёт пару HK-50 за [vip_marked ? "подопечным [key_name(vip)]" : "самим HK-47"].")
	return TRUE

/datum/hk_contract/proc/spawn_rivals(turf/landing, mob/living/mark)
	var/list/spots = hk50_servant_spots(landing, mark)
	var/lifetime = max(deadline() - world.time, HK47_PROTECT_SAMPLE)
	var/mob/living/simple_animal/hostile/hk50/lead
	for(var/index in 1 to HK50_SERVANT_PAIR_SIZE)
		var/mob/living/simple_animal/hostile/hk50/rival = new(index <= length(spots) ? spots[index] : landing)
		rival.AddComponent(/datum/component/hk50_rival, mark, lifetime)
		LAZYADD(rival_refs, WEAKREF(rival))
		lead = lead || rival
	lead.hk50_say("Мы здесь. Мы существуем, и нас становится больше.", forced = TRUE, voice = "hk50_numbers_grow")

/datum/hk_contract/proc/dismiss_rivals()
	for(var/datum/weakref/rival_ref as anything in rival_refs)
		var/mob/living/rival = rival_ref.resolve()
		var/datum/component/hk50_rival/hired = rival?.GetComponent(/datum/component/hk50_rival)
		hired?.depart()
	rival_refs = null

/datum/hk_contract/proc/on_completed(mob/living/source, datum/hk_contract/completed, witnessed)
	SIGNAL_HANDLER
	if(completed == src)
		INVOKE_ASYNC(hunter, TYPE_PROC_REF(/datum/antagonist/hk47, pay_client_perk), client_id)

/proc/hk47_rivals_landed(datum/weakref/contract_ref, datum/weakref/mark_ref, turf/landing)
	var/datum/hk_contract/contract = contract_ref?.resolve()
	var/mob/living/mark = mark_ref?.resolve()
	if(!contract || contract.state != HK_CONTRACT_ACTIVE || !mark || mark.stat == DEAD || !landing)
		return
	contract.spawn_rivals(landing, mark)

/// Свободный пол в паре клеток от цели конкурента и в её поле зрения, чтобы капсула не села ей на голову.
/proc/hk47_rival_landing(mob/living/mark)
	var/turf/center = get_turf(mark)
	if(!center)
		return null
	for(var/turf/open/spot in shuffle(RANGE_TURFS(HK47_RIVAL_LANDING_RANGE, center)))
		if(get_dist(spot, center) < 2 || isspaceturf(spot) || spot.is_blocked_turf() || (locate(/mob/living) in spot) || !can_see(center, spot, HK47_RIVAL_LANDING_RANGE))
			continue
		return spot
	return hk47_reinforcement_turf(mark)

/datum/antagonist/hk47
	var/datum/hk_contract/active_contract
	var/list/offers = list()
	/// Записи list("contract", "outcome", "task", "points", "killed", "target_name") для журнала терминала и отчёта раунда.
	var/list/contract_history = list()
	/// Цели выполненных контрактов: второй раз их не предлагают.
	var/list/datum/weakref/completed_targets
	var/list/datum/weakref/relic_cache
	var/relic_cache_time
	var/relic_refresh_queued = FALSE
	var/scanning = FALSE
	COOLDOWN_DECLARE(reroll_cooldown)
	COOLDOWN_DECLARE(offer_retry_cooldown)
	COOLDOWN_DECLARE(identify_cooldown)

/datum/antagonist/hk47/proc/apply_contract_effects(mob/living/body)
	if(!body)
		return
	var/datum/atom_hud/opt_in_hud = GLOB.huds[DATA_HUD_ANTAG_OPT_IN]
	opt_in_hud.add_hud_to(body)
	grant_terminal(body)

/datum/antagonist/hk47/proc/remove_contract_effects(mob/living/body)
	if(!body)
		return
	var/datum/atom_hud/opt_in_hud = GLOB.huds[DATA_HUD_ANTAG_OPT_IN]
	opt_in_hud.remove_hud_from(body)
	revoke_terminal(body)

/datum/antagonist/hk47/proc/objective_style()
	return owner.get_antag_objective_style()

/datum/antagonist/hk47/proc/allows_kill_contracts()
	return objective_style() != ANTAG_OBJECTIVE_STYLE_QUIET

/datum/antagonist/hk47/proc/crew_minds()
	var/list/minds = list()
	for(var/datum/data/record/record as anything in GLOB.data_core.locked)
		var/datum/mind/crew_mind = record.fields["mindref"]
		if(crew_mind)
			minds |= crew_mind
	return minds

/datum/antagonist/hk47/proc/counts_as_player(mob/living/someone)
	return !isnull(someone?.client)

/datum/antagonist/hk47/proc/counts_as_crew(datum/mind/candidate)
	return !candidate.is_ghost_role()

/datum/antagonist/hk47/proc/in_contract_zone(atom/thing)
	var/turf/location = get_turf(thing)
	return location && is_station_level(location.z)

/datum/antagonist/hk47/proc/is_hk_side(mob/living/someone)
	if(!istype(someone) || !owner)
		return FALSE
	if(someone == owner.current)
		return TRUE
	var/datum/component/hk_loyalty/loyalty = someone.GetComponent(/datum/component/hk_loyalty)
	return loyalty?.get_master() == owner

/datum/antagonist/hk47/proc/is_antag_mind(datum/mind/candidate)
	return hk47_is_antag_mind(candidate)

/// Охота видит не всех антагов: только тех, кто убил игрока, в розыске СБ или объявлен станции.
/datum/antagonist/hk47/proc/antag_exposed(datum/mind/candidate)
	if(!isnull(candidate.hk47_kill_time))
		return TRUE
	var/static/list/overt_types = typecacheof(HK47_OVERT_ANTAG_TYPES)
	for(var/datum/antagonist/antag as anything in candidate.antag_datums)
		if(is_type_in_typecache(antag, overt_types))
			return TRUE
	return hk47_wanted_by_security(candidate)

/// Пул охоты шире экипажа: волшебники, оперативники и ниндзя в записях не числятся.
/datum/antagonist/hk47/proc/hunt_pool()
	return SSticker.minds

/datum/antagonist/hk47/proc/in_brig(atom/thing)
	var/static/list/brig_areas = typecacheof(HK47_BRIG_AREAS)
	var/area/location = get_area(thing)
	return is_type_in_typecache(location, brig_areas)

/datum/antagonist/hk47/proc/warn_hunted(datum/hk_contract/contract)
	var/datum/mind/target_mind = contract.target_mind()
	if(!target_mind?.current)
		return FALSE
	deliver_hunt_warning(target_mind.current, "[hk47_hunt_channel(target_mind)]: на ваш след вышел дроид-ассасин серии HK.")
	return TRUE

/datum/antagonist/hk47/proc/deliver_hunt_warning(mob/living/body, text)
	to_chat(body, span_userdanger(text))

/// Опознание цели охоты: подозреваемый в паре клеток; ошибка ставит опознание на паузу.
/datum/antagonist/hk47/proc/try_identify(mob/living/suspect)
	var/mob/living/droid = owner?.current
	var/datum/hk_contract/contract = active_contract
	if(!droid || !contract)
		return FALSE
	var/refusal
	if(!contract.is_hunt())
		refusal = "опознание нужно только в охоте на охотника."
	else if(contract.identified)
		refusal = "цель уже опознана."
	else if(!COOLDOWN_FINISHED(src, identify_cooldown))
		refusal = "опознание перезаряжается, ещё [DisplayTimeText(COOLDOWN_TIMELEFT(src, identify_cooldown))]."
	else if(!isliving(suspect) || suspect == droid || suspect.z != droid.z || get_dist(droid, suspect) > HK47_IDENTIFY_RANGE)
		refusal = "подозреваемый должен быть не дальше [HK47_IDENTIFY_RANGE] клеток."
	else if(!can_identify(droid, suspect))
		refusal = "подозреваемого не видно."
	if(refusal)
		to_chat(droid, span_warning("Утверждение: [refusal]"))
		return FALSE
	if(suspect.mind != contract.target_mind())
		COOLDOWN_START(src, identify_cooldown, HK47_IDENTIFY_COOLDOWN)
		to_chat(droid, span_warning("Утверждение: сигнатура не совпадает. Следующее опознание - через [DisplayTimeText(HK47_IDENTIFY_COOLDOWN)]."))
		return FALSE
	contract.identify()
	if(contract.state == HK_CONTRACT_ACTIVE)
		to_chat(droid, span_notice("Утверждение: цель опознана - [contract.display_target()]."))
	log_game("[key_name(owner)] опознаёт цель охоты HK-47: [key_name(suspect)].")
	return TRUE

/// Сверять сигнатуру можно только с тем, кого HK видит: не через стену, не невидимку и не цель в стелсе.
/datum/antagonist/hk47/proc/can_identify(mob/living/droid, mob/living/suspect)
	return suspect.invisibility <= droid.see_invisible && suspect.alpha > HK47_STEALTH_ALPHA && can_see(droid, suspect, HK47_IDENTIFY_RANGE)

/datum/antagonist/hk47/proc/valid_target(datum/mind/candidate, required_level)
	if(QDELETED(candidate) || candidate == owner || !counts_as_crew(candidate))
		return FALSE
	var/mob/living/carbon/human/body = candidate.current
	if(!ishuman(body) || QDELETED(body) || body.mind != candidate || body.stat == DEAD || is_hk_side(body))
		return FALSE
	if(!counts_as_player(body) || !in_contract_zone(body))
		return FALSE
	return antag_opt_in_allows(candidate, required_level)

/// Подходящие цели экипажа: сначала командование, затем СБ, затем остальные, внутри групп - вперемешку.
/datum/antagonist/hk47/proc/target_candidates(required_level)
	var/list/command = list()
	var/list/security = list()
	var/list/others = list()
	for(var/datum/mind/candidate as anything in crew_minds())
		if(!valid_target(candidate, required_level))
			continue
		if(candidate.assigned_role in GLOB.command_positions)
			command += candidate
		else if(candidate.assigned_role in GLOB.security_positions)
			security += candidate
		else
			others += candidate
	return shuffle(command) + shuffle(security) + shuffle(others)

/datum/antagonist/hk47/proc/client_available(client_id)
	if(client_id == HK_CLIENT_CENTCOM)
		var/datum/hk_contract_task/hunt = GLOB.hk_contract_tasks[/datum/hk_contract_task/hunt]
		return length(hunt.candidate_targets(src)) > 0
	return TRUE

/datum/antagonist/hk47/proc/sabotage_pool()
	return GLOB.machines

/datum/antagonist/hk47/proc/sabotage_targets()
	var/static/list/sabotage_types = typecacheof(HK47_SABOTAGE_TYPES)
	var/list/targets = list()
	for(var/obj/machinery/machine as anything in sabotage_pool())
		if(!is_type_in_typecache(machine, sabotage_types) || QDELETED(machine) || (machine.machine_stat & BROKEN))
			continue
		if(in_contract_zone(machine))
			targets += machine
	return targets

/// Фирменные вещи отделов на станции, кроме тех, что уже у HK.
/datum/antagonist/hk47/proc/theft_relics()
	var/static/list/relic_types = typecacheof(HK47_THEFT_RELICS)
	var/mob/living/droid = owner?.current
	var/list/relics = list()
	for(var/obj/item/relic as anything in relic_pool())
		if(QDELETED(relic) || !is_type_in_typecache(relic, relic_types) || get(relic, /mob) == droid)
			continue
		if(in_contract_zone(relic))
			relics += relic
	return relics

/// Вещи из кэша. Сюда приходят из обработчиков сигналов и ui_data, поэтому устаревший кэш обновляется таймером, а не обходом мира на месте.
/datum/antagonist/hk47/proc/relic_pool()
	if(!relic_refresh_queued && (isnull(relic_cache_time) || world.time - relic_cache_time > HK47_RELIC_CACHE_TIME))
		relic_refresh_queued = TRUE
		addtimer(CALLBACK(src, PROC_REF(refresh_relic_cache)), 0)
	var/list/pool = list()
	for(var/datum/weakref/relic_ref as anything in relic_cache)
		var/obj/item/relic = relic_ref.resolve()
		if(relic)
			pool += relic
	return pool

/datum/antagonist/hk47/proc/refresh_relic_cache()
	var/static/list/relic_types = typecacheof(HK47_THEFT_RELICS)
	var/list/found = list()
	for(var/obj/item/thing in world)
		if(is_type_in_typecache(thing, relic_types))
			found += WEAKREF(thing)
		CHECK_TICK
	if(QDELETED(src))
		return
	relic_cache = found
	relic_cache_time = world.time
	relic_refresh_queued = FALSE

/// Веса задач заказчика с учётом стиля игрока: «Без убийств» убирает ликвидацию, «Больше убийств» поднимает её вес.
/datum/antagonist/hk47/proc/task_weights(client_id)
	var/list/weights = list()
	var/list/client_tasks = GLOB.hk_contract_clients[client_id]["tasks"]
	var/violent = objective_style() == ANTAG_OBJECTIVE_STYLE_VIOLENT
	for(var/task_type in client_tasks)
		var/datum/hk_contract_task/task = GLOB.hk_contract_tasks[task_type]
		if(!task.is_available(src))
			continue
		var/weight = client_tasks[task_type] * HK47_TASK_WEIGHT_SCALE
		if(violent && istype(task, /datum/hk_contract_task/kill))
			weight = round(weight * ANTAG_OBJECTIVE_VIOLENT_KILL_MULT)
		weights[task_type] = weight
	return weights

/datum/antagonist/hk47/proc/build_offer(list/role_group, list/used_targets)
	var/list/clients = list()
	for(var/client_id in GLOB.hk_contract_clients)
		if(client_available(client_id))
			clients += client_id
	for(var/client_id in shuffle(clients))
		var/list/weights = task_weights(client_id)
		while(length(weights))
			var/task_type = pickweight(weights)
			weights -= task_type
			var/datum/hk_contract_task/task = GLOB.hk_contract_tasks[task_type]
			var/datum/target = task.pick_target(src, role_group, used_targets)
			if(!target)
				continue
			var/datum/hk_contract/offer = new(src, client_id, task, target)
			offer.roll_modifier()
			return offer
	return null

/// Цели, которых нет смысла предлагать: уже занятые в партии и закрытые прошлыми контрактами.
/datum/antagonist/hk47/proc/excluded_targets(list/used_targets)
	. = used_targets ? used_targets.Copy() : list()
	for(var/datum/weakref/done_ref as anything in completed_targets)
		var/datum/done = done_ref.resolve()
		if(done)
			. += done

/// Три новых предложения с разными целями; в половине партий первое идёт по командованию, второе - по СБ.
/datum/antagonist/hk47/proc/generate_offers()
	QDEL_LIST(offers)
	if(extracted)
		return offers
	var/list/role_priority = prob(HK47_ROLE_PRIORITY_CHANCE) ? list(GLOB.command_positions, GLOB.security_positions) : list()
	var/list/used_targets = list()
	for(var/index in 1 to HK47_CONTRACT_OFFERS)
		var/datum/hk_contract/offer = build_offer(index <= length(role_priority) ? role_priority[index] : null, used_targets)
		if(!offer)
			continue
		offers += offer
		used_targets += offer.get_target()
	add_rival_offer()
	if(length(offers))
		hk_voice("hk47_offer")
	else
		COOLDOWN_START(src, offer_retry_cooldown, HK47_OFFER_RETRY_COOLDOWN)
	return offers

/// Бесплатная замена: недоступные предложения уступают место новым, доступные остаются.
/datum/antagonist/hk47/proc/replace_unavailable_offers()
	var/list/kept = list()
	var/list/stale = list()
	for(var/datum/hk_contract/offer as anything in offers)
		if(offer.offer_unavailable_reason())
			stale += offer
		else
			kept += offer.get_target()
	if(!length(stale))
		return FALSE
	for(var/datum/hk_contract/offer as anything in stale)
		var/datum/hk_contract/replacement = build_offer(null, kept)
		var/index = offers.Find(offer)
		if(replacement)
			offers[index] = replacement
			kept += replacement.get_target()
		else
			offers.Cut(index, index + 1)
		qdel(offer)
	to_chat(owner.current, span_notice("Утверждение: недоступные заказы заменены, остальные предложения на месте."))
	return TRUE

/// Для терминала: предложения появляются сами, пока нет активного контракта и работа на станции не закрыта.
/datum/antagonist/hk47/proc/ensure_offers()
	if(extracted || active_contract || length(offers) || !COOLDOWN_FINISHED(src, offer_retry_cooldown))
		return offers
	return generate_offers()

/// Готовый контракт без случайного выбора; без forced_target цель подбирается по тем же правилам, что у предложений.
/datum/antagonist/hk47/proc/make_contract(client_id, task_type, modifier_type, datum/forced_target)
	var/datum/hk_contract_task/task = GLOB.hk_contract_tasks[task_type]
	if(!task || !GLOB.hk_contract_clients[client_id])
		return null
	var/datum/target = forced_target || task.pick_target(src)
	if(!target)
		return null
	var/datum/hk_contract/contract = new(src, client_id, task, target)
	if(modifier_type)
		contract.modifier = GLOB.hk_contract_modifiers[modifier_type]
	return contract

/// Принимает предложение из offers или контракт из make_contract(); остальные предложения сгорают.
/datum/antagonist/hk47/proc/accept(datum/hk_contract/contract)
	if(extracted || active_contract || contract?.hunter != src || contract.state != HK_CONTRACT_OFFERED)
		return FALSE
	var/reason = contract.offer_unavailable_reason()
	if(reason)
		to_chat(owner.current, span_warning("Утверждение: контракт недоступен, [contract.shown_unavailable_reason(reason)] Замена недоступных заказов бесплатная."))
		return FALSE
	contract.lethal = contract.task.lethal_for(src, contract.client_id, contract.get_target())
	var/datum/hk_contract_modifier/dropped_modifier
	if(contract.modifier && !contract.modifier.compatible(contract))
		dropped_modifier = contract.modifier
		contract.modifier = null
	offers -= contract
	QDEL_LIST(offers)
	active_contract = contract
	contract.start()
	to_chat(owner.current, span_notice("Утверждение: контракт принят. [contract.describe()]."))
	if(dropped_modifier)
		to_chat(owner.current, span_warning("Условие «[dropped_modifier.name]» снято: заказ теперь без убийства, бонуса за условие не будет."))
	if(!contract.trackable())
		to_chat(owner.current, span_notice("Имя цели скрыто. Терминал показывает её след; опознайте подозреваемого вблизи, и цель откроется."))
	hk_voice("hk47_accept")
	log_game("[key_name(owner)] принимает контракт HK-47: [contract.describe()], цель [contract.target_name].")
	return TRUE

/datum/antagonist/hk47/proc/complete(datum/hk_contract/contract)
	if(!contract || contract != active_contract)
		return FALSE
	contract.note_witnesses()
	contract.modifier_held = !!contract.modifier?.holds(contract)
	contract.state = HK_CONTRACT_DONE
	active_contract = null
	contracts_done++
	note_history(contract, HK_CONTRACT_DONE, contract.earned_points())
	var/report = "Утверждение: контракт выполнен. [contract.describe()]."
	if(contract.modifier)
		report += contract.modifier_held ? " Условие «[contract.modifier.name]» соблюдено." : " Условие «[contract.modifier.name]» нарушено, бонуса нет."
	to_chat(owner.current, span_notice(report))
	award(contract.earned_points())
	if(contract.closed_by_kill)
		hk_voice("hk47_meatbags")
	log_game("[key_name(owner)] выполняет контракт HK-47: [contract.describe()], условие [contract.modifier_held ? "соблюдено" : "нет"].")
	if(owner.current)
		SEND_SIGNAL(owner.current, COMSIG_HK47_CONTRACT_COMPLETED, contract, contract.witnessed)
	qdel(contract)
	generate_offers()
	return TRUE

/datum/antagonist/hk47/proc/fail(datum/hk_contract/contract, reason)
	if(!contract || contract != active_contract)
		return FALSE
	contract.state = HK_CONTRACT_FAILED
	active_contract = null
	note_history(contract, HK_CONTRACT_FAILED)
	to_chat(owner.current, span_warning("Утверждение: контракт провален. [reason]"))
	log_game("[key_name(owner)] проваливает контракт HK-47: [contract.describe()].")
	qdel(contract)
	generate_offers()
	return TRUE

/// outcome_text заменяет в отчёте раунда стандартное название исхода.
/datum/antagonist/hk47/proc/note_history(datum/hk_contract/contract, outcome, earned = 0, outcome_text)
	contract_history += list(list("contract" = contract.describe(), "outcome" = outcome, "task" = contract.task.type, "points" = earned, "killed" = contract.closed_by_kill, "target_name" = contract.target_name, "outcome_text" = outcome_text))
	if(outcome == HK_CONTRACT_DONE && contract.target_ref)
		LAZYADD(completed_targets, contract.target_ref)

/// Работа на станции закрыта целиком: активный контракт уходит в журнал без штрафа, предложения сгорают. Лицензия при этом не истекает отдельно.
/datum/antagonist/hk47/proc/close_all_work(outcome_text)
	if(active_contract)
		var/datum/hk_contract/closed = active_contract
		active_contract = null
		UnregisterSignal(closed, COMSIG_PARENT_QDELETING)
		note_history(closed, HK_CONTRACT_DROPPED, 0, outcome_text)
		qdel(closed)
	QDEL_LIST(offers)

/// Снять активный контракт без штрафа и без очков: цель ушла из игры не по вине HK.
/datum/antagonist/hk47/proc/drop_contract(datum/hk_contract/contract, notice)
	if(!contract || contract != active_contract)
		return FALSE
	active_contract = null
	note_history(contract, HK_CONTRACT_DROPPED)
	to_chat(owner.current, span_notice(notice))
	log_game("[key_name(owner)]: контракт HK-47 снят без штрафа: [contract.describe()].")
	qdel(contract)
	generate_offers()
	return TRUE

/// Новые предложения. Недоступный активный контракт снимается бесплатно; среди предложений бесплатно меняются только недоступные,
/// а отказ от всех - по своей воле с кулдауном.
/datum/antagonist/hk47/proc/reroll(voluntary = FALSE)
	var/free = FALSE
	if(active_contract)
		free = !!active_contract.target_unavailable_reason()
	else if(!length(offers))
		free = COOLDOWN_FINISHED(src, offer_retry_cooldown)
	else if(!voluntary)
		return replace_unavailable_offers()
	if(!free)
		if(!voluntary)
			return FALSE
		if(!COOLDOWN_FINISHED(src, reroll_cooldown))
			to_chat(owner.current, span_warning("Утверждение: заказчики не примут новый отказ ещё [DisplayTimeText(COOLDOWN_TIMELEFT(src, reroll_cooldown))]."))
			return FALSE
		COOLDOWN_START(src, reroll_cooldown, HK47_REROLL_COOLDOWN)
	if(active_contract && free)
		return drop_contract(active_contract, "Утверждение: цель недоступна, контракт снят без штрафа.")
	if(active_contract)
		var/datum/hk_contract/dropped = active_contract
		active_contract = null
		note_history(dropped, HK_CONTRACT_REFUSED)
		to_chat(owner.current, span_notice("Утверждение: контракт отклонён. Следующий отказ - через [DisplayTimeText(HK47_REROLL_COOLDOWN)]."))
		qdel(dropped)
	generate_offers()
	return TRUE

/datum/antagonist/hk47/proc/scan_refusal(datum/hk_contract/contract, mob/living/droid, atom/target)
	if(droid.incapacitated())
		return "сканирование невозможно в текущем состоянии."
	return contract.task.scan_refusal(contract, droid, target)

/// Скан терминалом: труп цели ликвидации или охоты, украденный предмет. target = null - терминал ищет сам.
/datum/antagonist/hk47/proc/try_scan(atom/target)
	var/mob/living/droid = owner?.current
	var/datum/hk_contract/contract = active_contract
	if(!droid || !contract || scanning)
		return FALSE
	if(!contract.task.scannable(contract))
		to_chat(droid, span_warning("Утверждение: этот контракт закрывается не сканом."))
		return FALSE
	target = target || contract.task.scan_target(contract, droid)
	var/refusal = scan_refusal(contract, droid, target)
	if(refusal)
		to_chat(droid, span_warning("Утверждение: [refusal]"))
		return FALSE
	scanning = TRUE
	var/scanned = channel_scan(droid, target)
	scanning = FALSE
	if(!scanned || QDELETED(contract) || contract != active_contract)
		return FALSE
	refusal = scan_refusal(contract, droid, target)
	if(refusal)
		to_chat(droid, span_warning("Утверждение: [refusal]"))
		return FALSE
	contract.closed_by_kill = contract.task.lethal
	contract.task.on_scanned(contract, target)
	return complete(contract)

/datum/antagonist/hk47/proc/channel_scan(mob/living/droid, atom/target)
	var/datum/beam/scan_beam
	if(target.loc != droid)
		scan_beam = droid.Beam(target, icon_state = "r_beam", time = HK47_SCAN_TIME)
	droid.visible_message(span_danger("[droid] водит по [target] красным лучом сканера."), span_notice("Сканирование: не двигайтесь [DisplayTimeText(HK47_SCAN_TIME)]."))
	. = do_after(droid, HK47_SCAN_TIME, target)
	QDEL_NULL(scan_beam)

/// Вызов капсулы для захвата или охоты: цель обездвижена и стоит рядом.
/datum/antagonist/hk47/proc/try_capture(mob/living/victim)
	var/mob/living/droid = owner?.current
	var/datum/hk_contract/contract = active_contract
	if(!droid || !contract)
		return FALSE
	var/refusal
	if(!contract.task.capturable)
		refusal = "этот контракт не требует захвата."
	else if(contract.capture_called)
		refusal = "капсула уже вызвана."
	else if(!contract.trackable())
		refusal = "цель не опознана: подойдите к подозреваемому и опознайте его."
	else if(!ishuman(victim) || victim != contract.target_body())
		refusal = "это не цель контракта."
	else if(victim.stat == DEAD)
		refusal = "заказчику нужна живая цель."
	else if(!counts_as_player(victim))
		refusal = "в теле цели нет игрока, такой груз заказчик не примет. Контракт можно снять без штрафа."
	else if(get_dist(droid, victim) > HK47_SCAN_RANGE || droid.z != victim.z)
		refusal = "подойдите к цели вплотную."
	else if(!hk47_capture_ready(victim))
		refusal = "цель сопротивляется: нужны наручники, оглушение, истощение выносливости, сон или крит."
	else if(droid.incapacitated())
		refusal = "вызов невозможен в текущем состоянии."
	if(refusal)
		to_chat(droid, span_warning("Утверждение: [refusal]"))
		return FALSE
	if(!start_capture_extraction(contract, victim))
		return FALSE
	contract.capture_called = TRUE
	contract.note_witnesses()
	to_chat(droid, span_notice("Утверждение: капсула вызвана и сядет на место цели. Если цель сдвинется, перетащите её мышью на капсулу. Пустая капсула улетит через [DisplayTimeText(HK47_CAPTURE_POD_WAIT)]."))
	return TRUE

/datum/antagonist/hk47/proc/start_capture_extraction(datum/hk_contract/contract, mob/living/carbon/human/victim)
	var/datum/ransom_extraction/hk47/extraction = new
	return extraction.start_for_hk47(src, contract, victim, get_turf(victim))

/// Почему капсула не примет груз: заказчику нужна живая цель с игроком в теле; null - примет.
/datum/antagonist/hk47/proc/capture_cargo_refusal(mob/living/victim)
	if(victim.stat == DEAD)
		return "заказчику нужна живая цель, труп капсула не примет."
	if(!counts_as_player(victim))
		return "в теле цели нет игрока, такой груз заказчик не примет."
	return null

/datum/antagonist/hk47/proc/capture_loaded(datum/hk_contract/contract, mob/living/victim)
	if(!contract || contract != active_contract || victim?.mind != contract.target_mind())
		return FALSE
	var/refusal = capture_cargo_refusal(victim)
	if(refusal)
		to_chat(owner.current, span_warning("Утверждение: [refusal]"))
		return FALSE
	return complete(contract)

/// Капсула захвата пропала, не забрав цель: можно вызывать новую.
/datum/antagonist/hk47/proc/capture_pod_lost(datum/hk_contract/contract, notice)
	if(!contract || contract != active_contract || !contract.capture_called)
		return FALSE
	contract.capture_called = FALSE
	to_chat(owner.current, span_warning("Утверждение: [notice] Вызовите новую капсулу, когда цель будет готова."))
	return TRUE

/// Плата заказчика сверх очков: корпорация шлёт снаряжение, ЦК прикрывает подрядчика.
/datum/antagonist/hk47/proc/pay_client_perk(client_id)
	switch(client_id)
		if(HK_CLIENT_CORP)
			return send_corp_reward()
		if(HK_CLIENT_CENTCOM)
			return centcom_pardon()
	return FALSE

/datum/antagonist/hk47/proc/send_corp_reward()
	var/mob/living/droid = owner?.current
	if(!droid)
		return FALSE
	var/obj/structure/closet/supplypod/hk47/reinforcement/pod = new
	pod.on_open = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(hk47_corp_reward_landed), pick(HK47_CORP_REWARD_ITEMS))
	send_pod(pod, hk47_reinforcement_turf(droid))
	to_chat(droid, span_notice("Утверждение: корпорация доплачивает снаряжением, капсула садится рядом."))
	return TRUE

/proc/hk47_corp_reward_landed(reward_type, turf/landing)
	if(landing)
		new reward_type(landing)

/// Плата ЦК: закрывает одно дело - сначала отзыв лицензии, затем раскрытие. Приказ СБ сразу следует за оставшимися делами, без дел розыск снимается.
/datum/antagonist/hk47/proc/centcom_pardon()
	var/closed
	if(license_revoked)
		license_revoked = FALSE
		closed = "дело об отзыве лицензии № [license_number]"
	else if(reveals > 0)
		reveals--
		closed = "одно дело о раскрытии"
	else
		to_chat(owner.current, span_notice("Утверждение: ЦК доволен работой. Прикрывать пока нечего."))
		return FALSE
	log_game("[key_name(owner)]: ЦК закрывает [closed] HK-47, открытых раскрытий [reveals].")
	var/datum/data/record/record = security_record()
	var/wanted = wanted_record_status()
	if(wanted == SEC_RECORD_STATUS_NONE)
		lift_wanted()
	else if(record?.fields["criminal"] == SEC_RECORD_STATUS_EXECUTE && wanted != SEC_RECORD_STATUS_EXECUTE)
		note_security_record("ЦК отменил приказ на уничтожение дроида HK-47. Задержать.", wanted)
		station_announce("ЦК отменил приказ на уничтожение дроида-ассасина HK-47. Дроид по-прежнему вне закона: службе безопасности задержать его.", "Центральное командование")
		to_chat(owner.current, span_boldnotice("Утверждение: ЦК закрыл [closed] и отменил приказ на уничтожение. Вы по-прежнему вне закона, открытых раскрытий: [reveals]."))
	else
		note_security_record("ЦК закрыл [closed]. Розыск остаётся.")
		to_chat(owner.current, span_boldnotice("Утверждение: ЦК закрыл [closed], но розыск остаётся: [license_revoked ? "лицензия отозвана" : "открытых раскрытий - [reveals]"]."))
	return TRUE

/// Открытых дел не осталось: розыск снят, карта лицензии закрыта, пеленгатор СБ теряет сигнал.
/datum/antagonist/hk47/proc/lift_wanted()
	var/obj/item/card/id/hk47_license/license = license_ref?.resolve()
	if(license)
		license.revoked = FALSE
		license.expired = TRUE
	set_status(license_number ? HK47_STATUS_EXPIRED : HK47_STATUS_PARDONED)
	var/license_note = license_number ? " Лицензия № [license_number] закрыта и больше не действует." : ""
	note_security_record("ЦК снял розыск: подрядчик выполнил контракт ЦК.[license_note]", SEC_RECORD_STATUS_NONE)
	station_announce("Розыск дроида HK-47 снят: подрядчик выполнил контракт ЦК.[license_note]", "Центральное командование")
	to_chat(owner.current, span_boldnotice("Утверждение: ЦК снял с вас розыск[license_number ? ", лицензия № [license_number] закрыта" : ""]. Прикрытия нет, но и приказа на арест тоже, пеленгатор СБ вас больше не ведёт. Новое раскрытие снова объявит вас вне закона."))
	log_game("[key_name(owner)]: ЦК снимает розыск с HK-47 за выполненный контракт.")

/// Игроки в радиусе с прямой видимостью до HK, кроме цели, самого HK и его слуг.
/datum/antagonist/hk47/proc/witnesses(datum/hk_contract/contract)
	var/list/seen_by = list()
	var/mob/living/droid = owner?.current
	var/turf/center = get_turf(droid)
	if(!center)
		return seen_by
	var/mob/living/target_body = contract?.target_body()
	for(var/mob/living/onlooker in witness_pool(center))
		if(onlooker == target_body || onlooker.stat != CONSCIOUS || is_hk_side(onlooker) || !counts_as_player(onlooker))
			continue
		if(get_dist(center, onlooker) > HK47_WITNESS_RANGE || !can_see(onlooker, center, HK47_WITNESS_RANGE))
			continue
		seen_by += onlooker
	return seen_by

/datum/antagonist/hk47/proc/witness_pool(turf/center)
	return SSspatial_grid.orthogonal_range_search(center, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, HK47_WITNESS_RANGE)

#undef HK47_TASK_WEIGHT_SCALE
