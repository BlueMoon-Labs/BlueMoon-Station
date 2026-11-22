/// Расходники каталогов: сотрудник отдела заказывает их из бюджета сам, без одобрения, до staple_self_order_cap_hour за час. Оружия и снаряжения СБ здесь нет.
GLOBAL_LIST_INIT(econ_staple_packs, typecacheof(list(
	/datum/supply_pack/materials/cardboard50,
	/datum/supply_pack/materials/glass50,
	/datum/supply_pack/materials/metal50,
	/datum/supply_pack/materials/plasteel20,
	/datum/supply_pack/materials/plastic20,
	/datum/supply_pack/materials/sandstone30,
	/datum/supply_pack/materials/wood20,
	/datum/supply_pack/materials/rcdammo,
	/datum/supply_pack/materials/oxygen,
	/datum/supply_pack/materials/nitrogen,
	/datum/supply_pack/materials/carbon_dio,
	/datum/supply_pack/materials/water_vapor,
	/datum/supply_pack/materials/fueltank,
	/datum/supply_pack/materials/hightankfuel,
	/datum/supply_pack/materials/watertank,
	/datum/supply_pack/materials/hightank,
	/datum/supply_pack/materials/foamtank,
	/datum/supply_pack/engineering/power,
	/datum/supply_pack/medical/supplies,
	/datum/supply_pack/medical/bloodpacks,
	/datum/supply_pack/medical/oilblood,
	/datum/supply_pack/medical/iv_drip,
	/datum/supply_pack/medical/bodybags,
	/datum/supply_pack/medical/surgery,
	/datum/supply_pack/medical/sprays,
	/datum/supply_pack/medical/medipen_variety,
	/datum/supply_pack/medical/chemical,
	/datum/supply_pack/science/beakers,
	/datum/supply_pack/science/monkey,
	/datum/supply_pack/science/nitrilegloves,
	/datum/supply_pack/science/robotics,
	/datum/supply_pack/organic/food,
	/datum/supply_pack/organic/randomized/fruits,
	/datum/supply_pack/organic/randomized/vegetables,
	/datum/supply_pack/organic/fakemeat,
	/datum/supply_pack/organic/mixedboxes,
	/datum/supply_pack/organic/seeds,
	/datum/supply_pack/service/janitor/starter,
	/datum/supply_pack/service/lightbulbs,
	/datum/supply_pack/service/grillfuel,
), only_root_path = TRUE))

/proc/econ_pack_staple(datum/supply_pack/pack)
	return pack && GLOB.econ_staple_packs[pack.type] && econ_pack_department(pack) != ACCOUNT_SEC

/// ИИ станции решает заявки сотрудников, как глава, кроме заявок СБ; сам ничего не заказывает и деньгами не распоряжается. Учебный ИИ полигона - нет.
/proc/econ_ai_decider(mob/user)
	return isAI(user) && user.stat != DEAD && !istype(user, /mob/living/silicon/ai/training)

/// Живой ИИ станции с игроком на смене.
/proc/econ_ai_on_shift()
	for(var/mob/living/silicon/ai/ai in GLOB.player_list)
		if(econ_ai_decider(ai))
			return TRUE
	return FALSE

/datum/econ_request
	/// Заявка ждала дольше request_handoff_minutes: решить её может и начальник снабжения
	var/handed_off = FALSE

/datum/econ_request/proc/waited_minutes()
	return round((world.time - created) / (1 MINUTES))

/datum/economy_department
	/// "номер счёта" -> list(начало часа, сколько заказано расходников без одобрения)
	var/list/staple_spent = list()
	COOLDOWN_DECLARE(handoff_announce_cooldown)

/// Заявки отдела решает ИИ: у всех, кроме СБ.
/datum/economy_department/proc/ai_decides()
	return id != ACCOUNT_SEC

/// Зависшие заявки передаются начальнику снабжения: у всех, кроме самого снабжения.
/datum/economy_department/proc/hands_off_requests()
	return id != ACCOUNT_CAR

/// Кто может одобрить или отклонить заявку: начальство отдела; ИИ, кроме СБ; начальник снабжения - переданную ему.
/datum/economy_department/proc/can_decide(datum/econ_request/request, mob/living/user)
	if(can_manage(user))
		return TRUE
	if(ai_decides() && econ_ai_decider(user))
		return TRUE
	if(!request?.handed_off)
		return FALSE
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	return !!cargo?.can_manage(user)

/// На смене есть кому решить заявку отдела: начальство или ИИ. Автоодобрение недорогих смотрит только на начальство.
/datum/economy_department/proc/has_decider_on_shift()
	return has_approver_on_shift() || (ai_decides() && econ_ai_on_shift())

/// Сколько расходников сотрудник ещё может заказать без одобрения в этом часе.
/datum/economy_department/proc/staple_left(account_id)
	var/list/window = staple_spent["[account_id]"]
	if(!window || world.time - window[1] >= 1 HOURS)
		return SSeconomy.settings.staple_self_order_cap_hour
	return max(SSeconomy.settings.staple_self_order_cap_hour - window[2], 0)

/// Сотрудник user может заказать pack без одобрения: расходник его отдела в пределах часового лимита.
/datum/economy_department/proc/staple_allowed(mob/living/user, datum/supply_pack/pack)
	if(!econ_pack_staple(pack) || !accepts_request(user))
		return FALSE
	var/datum/bank_account/account = econ_account_of(user)
	return account && round(econ_pack_price(pack)) <= staple_left(account.account_id)

/// Одобряет ждущую заявку на расходник, если сотруднику хватает часового лимита и бюджету денег.
/datum/economy_department/proc/approve_staple(datum/econ_request/request)
	if(!request.requester_account_id || !econ_pack_staple(request.pack))
		return FALSE
	var/price = round(econ_pack_price(request.pack))
	if(price > staple_left(request.requester_account_id))
		return FALSE
	if(!approve(request, null, TRUE))
		return FALSE
	var/key = "[request.requester_account_id]"
	var/list/window = staple_spent[key]
	if(!window || world.time - window[1] >= 1 HOURS)
		window = list(world.time, 0)
		staple_spent[key] = window
	window[2] += price
	return TRUE

/datum/economy_department
	/// Паки "нужно сейчас" для окна бюджета: тип пака -> почему; пересчитываются не чаще ECON_NEEDS_REFRESH
	var/list/needs_cache
	var/needs_cache_until = 0

/// На что отделу тратить бюджет: две-три строки для окна бюджета.
/datum/economy_department/proc/spending_advice()
	return list()

/// Паки под то, что сейчас происходит на станции, самые нужные первыми: тип пака -> почему.
/datum/economy_department/proc/situational_needs()
	return list()

/// Паки на каждый день, которыми окно добирает "нужно сейчас" до ECON_NEEDS_MIN: тип пака -> почему.
/datum/economy_department/proc/everyday_needs()
	return list()

/// До ECON_NEEDS_MAX паков каталога в наличии: сначала под то, что происходит на станции, затем на каждый день.
/datum/economy_department/proc/needs_now()
	if(needs_cache && world.time < needs_cache_until)
		return needs_cache
	needs_cache_until = world.time + ECON_NEEDS_REFRESH
	needs_cache = list()
	var/list/packs = catalog()
	var/list/situational = situational_needs()
	for(var/list/source as anything in list(situational, everyday_needs()))
		var/limit = source == situational ? ECON_NEEDS_MAX : ECON_NEEDS_MIN
		for(var/pack_type in source)
			if(length(needs_cache) >= limit)
				break
			var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
			if(!pack || needs_cache[pack_type] || !(pack in packs) || econ_pack_unavailable(pack))
				continue
			needs_cache[pack_type] = source[pack_type]
	return needs_cache

/// "Нужно сейчас" для окна: тип, имя пака и почему он нужен.
/datum/economy_department/proc/needs_ui()
	. = list()
	var/list/needs = needs_now()
	for(var/pack_type in needs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(pack)
			. += list(list("type" = "[pack_type]", "name" = pack.name, "why" = needs[pack_type]))

/// Тела экипажа на станции, живые и мёртвые, только с разумом: для "нужно сейчас".
/proc/econ_station_crew_bodies()
	. = list()
	for(var/mob/living/carbon/human/body as anything in GLOB.human_list)
		var/turf/body_turf = get_turf(body)
		if(body.mind && body_turf && is_station_level(body_turf.z))
			. += body

/// Что о теле видит монитор экипажа: режим датчиков костюма SENSOR_*, у нанитов - всё, без датчиков - SENSOR_OFF.
/proc/econ_sensor_level(mob/living/carbon/human/body)
	if(body in SSnanites.nanite_monitored_mobs)
		return SENSOR_COORDS
	var/obj/item/clothing/under/uniform = body.w_uniform
	if(!istype(uniform) || uniform.has_sensor <= 0)
		return SENSOR_OFF
	return uniform.sensor_mode

/datum/economy_department
	/// Паки "нужно сейчас" по датчикам, о которых канал отдела уже слышал; нужда прошла - пак уходит из списка
	var/list/alerted_needs = list()
	COOLDOWN_DECLARE(needs_alert_cooldown)

/// Нужды по датчикам станции, тип пака -> почему: о новых канал отдела слышит на тике экономики.
/datum/economy_department/proc/sensor_needs()
	return list()

/// Новая нужда по датчикам - строка в канал отдела, не чаще ECON_NEEDS_ALERT_COOLDOWN и только если в отделе кто-то на смене. Возвращает сообщение или null.
/datum/economy_department/proc/announce_new_needs(list/stats)
	var/list/sensed = sensor_needs()
	if(!length(sensed))
		alerted_needs.Cut()
		return null
	var/list/packs = catalog()
	var/list/current = list()
	for(var/pack_type in sensed)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(pack && (pack in packs))
			current[pack_type] = sensed[pack_type]
	for(var/pack_type in alerted_needs.Copy())
		if(!current[pack_type])
			alerted_needs -= pack_type
	var/list/fresh = list()
	for(var/pack_type in current)
		if(!(pack_type in alerted_needs))
			fresh += pack_type
	var/channel = radio_channel()
	if(!length(fresh) || !channel || !COOLDOWN_FINISHED(src, needs_alert_cooldown) || !staff_on_shift(stats))
		return null
	COOLDOWN_START(src, needs_alert_cooldown, ECON_NEEDS_ALERT_COOLDOWN)
	alerted_needs |= fresh
	var/list/lines = list()
	for(var/pack_type in fresh)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		lines += "[pack.name] ([current[pack_type]])"
	. = "Отдел \"[name]\", нужно сейчас: [jointext(lines, "; ")]. Заказать - в \"Бюджете отдела\" на КПК."
	paperwork_radio(., channel)

/// Заявки без решения дольше request_handoff_minutes передаются начальнику снабжения: оповещаются подавший, канал снабжения и карты тех, кто решит.
/datum/economy_department/proc/hand_off_stale_requests()
	var/minutes = SSeconomy.settings.request_handoff_minutes
	if(minutes <= 0 || !hands_off_requests())
		return
	var/list/fresh = list()
	for(var/datum/econ_request/request as anything in requests)
		if(request.status != ECON_REQUEST_PENDING || request.handed_off || world.time - request.created < minutes MINUTES)
			continue
		request.handed_off = TRUE
		fresh += request
		log_econ("Заявка [request.uid] отдела [name] ([request.pack.name]) ждёт дольше [minutes] мин. и передана снабжению")
		request.notify_requester("Заявка №[request.uid] на \"[request.pack.name]\" ждёт решения дольше [minutes] мин.: решить её теперь может и начальник снабжения, оплатит бюджет отдела.")
	if(!length(fresh) || !COOLDOWN_FINISHED(src, handoff_announce_cooldown))
		return
	COOLDOWN_START(src, handoff_announce_cooldown, ECON_CARGO_REQUEST_RADIO_COOLDOWN)
	var/datum/econ_request/first = fresh[1]
	var/what = "[first.pack.name][length(fresh) > 1 ? " и ещё [length(fresh) - 1]" : ""]"
	var/message = "Отдел \"[name]\": заявка №[first.uid] ([what]) ждёт решения дольше [minutes] мин. Решить за бюджет отдела можно в \"Бюджете отдела\" снабжения."
	paperwork_radio(message, RADIO_CHANNEL_SUPPLY)
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/list/told = list()
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player.stat == DEAD || !cargo?.can_manage(player))
			continue
		var/datum/bank_account/manager_account = econ_account_of(player)
		if(!manager_account || (manager_account in told))
			continue
		told += manager_account
		manager_account.bank_card_talk(message)

/// Кто сейчас может решить заявку, для окна: "глава отдела, ГП или капитан", ИИ, начальник снабжения.
/datum/economy_department/proc/deciders_text(datum/econ_request/request)
	var/list/who = list()
	if(has_approver_on_shift())
		who += "глава отдела, ГП или капитан"
	if(ai_decides() && econ_ai_on_shift())
		who += "ИИ"
	if(request?.handed_off && econ_quartermaster_on_shift())
		who += "начальник снабжения"
	return length(who) ? jointext(who, ", ") : null

/// Живой игрок с доступом начальника снабжения на ID.
/proc/econ_quartermaster_on_shift()
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player.stat == DEAD)
			continue
		var/obj/item/card/id/card = player.get_idcard(TRUE)
		if(card && (ACCESS_QM in card.GetAccess()))
			return TRUE
	return FALSE

/// Что будет с ждущей заявкой дальше: кто решит, одобрится ли сама и когда перейдёт снабжению.
/datum/economy_department/proc/request_outlook(datum/econ_request/request)
	if(request.status != ECON_REQUEST_PENDING)
		return null
	var/datum/economy_settings/settings = SSeconomy.settings
	var/price = round(econ_pack_price(request.pack))
	var/list/parts = list()
	if(account.account_balance < price)
		parts += "в бюджете [account.account_balance] кр. из [price]"
	else if(!keeps_wage_reserve(request.pack))
		parts += "сама не закажется: [owed_to_staff()] кр. бюджета отложено на зарплату сотрудникам"
	if(econ_pack_staple(request.pack) && request.requester_account_id && price <= staple_left(request.requester_account_id))
		parts += "расходник: закажется сам, когда хватит денег"
		return capitalize(jointext(parts, "; ")) + "."
	var/who = deciders_text(request)
	parts += who ? "решает [who]" : "сейчас решить некому: на смене нет начальства отдела[ai_decides() ? " и ИИ" : ""]"
	if(auto_approvable(request.pack) && settings.auto_approve_wait_minutes > 0 && instant_approval())
		var/left = settings.auto_approve_wait_minutes - request.waited_minutes()
		parts += left > 0 ? "без ответа одобрится сама через [left] мин." : "одобрится сама на ближайшем цикле экономики"
	else if(request.handed_off)
		parts += "передана снабжению: решить может и его начальник"
	else if(hands_off_requests() && settings.request_handoff_minutes > 0)
		parts += "через [max(settings.request_handoff_minutes - request.waited_minutes(), 1)] мин. без решения перейдёт и начальнику снабжения"
	return capitalize(jointext(parts, "; ")) + "."
