GLOBAL_LIST_INIT(hk_contract_tasks, hk_contract_singletons(/datum/hk_contract_task))

/// Задача контракта HK-47; синглтон, состояние держит сам контракт.
/datum/hk_contract_task
	var/name
	var/points = 1
	var/required_opt_in = ANTAG_OPT_IN_NOT_TARGET
	/// Закрывается убийством цели.
	var/lethal = FALSE
	var/capturable = FALSE

/datum/hk_contract_task/proc/is_available(datum/antagonist/hk47/hunter)
	return TRUE

/datum/hk_contract_task/proc/required_level(datum/antagonist/hk47/hunter)
	return required_opt_in

/datum/hk_contract_task/proc/lethal_for(datum/antagonist/hk47/hunter, client_id, datum/target)
	return lethal && hunter.allows_kill_contracts()

/datum/hk_contract_task/proc/candidate_targets(datum/antagonist/hk47/hunter)
	return hunter.target_candidates(required_level(hunter))

/// Цель из подходящих, кроме занятых и закрытых прошлыми контрактами: из role_group, если такие есть, иначе любая.
/datum/hk_contract_task/proc/pick_target(datum/antagonist/hk47/hunter, list/role_group, list/exclude)
	var/list/candidates = candidate_targets(hunter)
	candidates -= hunter.excluded_targets(exclude)
	if(!length(candidates))
		return null
	if(role_group)
		for(var/datum/mind/candidate as anything in candidates)
			if(candidate.assigned_role in role_group)
				return candidate
	return pick(candidates)

/datum/hk_contract_task/proc/snapshot_target(datum/hk_contract/contract, datum/mind/target_mind)
	contract.target_name = target_mind.current?.real_name || target_mind.name
	contract.target_job = target_mind.assigned_role

/datum/hk_contract_task/proc/rules_text(datum/hk_contract/contract)
	return ""

/datum/hk_contract_task/proc/on_accept(datum/hk_contract/contract)
	return

/datum/hk_contract_task/proc/on_target_death(datum/hk_contract/contract)
	return

/datum/hk_contract_task/proc/unavailable_reason(datum/hk_contract/contract)
	var/datum/mind/target_mind = contract.target_mind()
	if(QDELETED(target_mind))
		return "цель покинула смену."
	var/mob/living/body = target_mind.current
	if(QDELETED(body) || body.mind != target_mind)
		return "тела цели больше нет: криосон или полная потеря тела."
	if(!contract.hunter.counts_as_crew(target_mind))
		return "цель больше не в экипаже."
	if(body.stat == DEAD)
		return capturable && !contract.lethal ? "цель погибла, а заказчику нужна живая." : null
	if(!contract.hunter.counts_as_player(body))
		return "игрок цели покинул тело."
	if(!contract.hunter.in_contract_zone(body))
		return "цель покинула станцию."
	if(capturable && !contract.lethal && !ishuman(body))
		return "цель больше не в человеческом теле, капсула её не примет."
	return null

/datum/hk_contract_task/proc/scannable(datum/hk_contract/contract)
	return FALSE

/datum/hk_contract_task/proc/scan_target(datum/hk_contract/contract, mob/living/droid)
	return contract.target_body()

/datum/hk_contract_task/proc/scan_refusal(datum/hk_contract/contract, mob/living/droid, atom/target)
	return "этот контракт закрывается не сканом."

/datum/hk_contract_task/proc/on_scanned(datum/hk_contract/contract, atom/target)
	return

/datum/hk_contract_task/proc/corpse_scan_refusal(datum/hk_contract/contract, mob/living/droid, mob/living/corpse)
	if(!istype(corpse) || !contract.target_mind() || corpse.mind != contract.target_mind())
		return "это не цель контракта."
	if(corpse.stat != DEAD)
		return "цель ещё жива, терминал засчитывает только труп."
	if(corpse.z != droid.z || get_dist(droid, corpse) > HK47_SCAN_RANGE)
		return "подойдите к телу вплотную."
	return null

/// Луч сканера прожигает на трупе метку, которую найдёт внимательный осмотр.
/datum/hk_contract_task/proc/mark_scanned_corpse(atom/corpse)
	if(isliving(corpse))
		corpse.AddElement(/datum/element/hk47_scan_mark)

/datum/hk_contract_task/kill
	name = "ликвидация"
	required_opt_in = ANTAG_OPT_IN_KILL
	lethal = TRUE

/datum/hk_contract_task/kill/is_available(datum/antagonist/hk47/hunter)
	return hunter.allows_kill_contracts()

/datum/hk_contract_task/kill/rules_text(datum/hk_contract/contract)
	return "Цель должна умереть. Встаньте рядом с телом и просканируйте его терминалом: [DisplayTimeText(HK47_SCAN_TIME)] на месте, луч скана видят все. Оживление после скана контракт не отменяет."

/datum/hk_contract_task/kill/scannable(datum/hk_contract/contract)
	return TRUE

/datum/hk_contract_task/kill/scan_refusal(datum/hk_contract/contract, mob/living/droid, atom/target)
	return corpse_scan_refusal(contract, droid, target)

/datum/hk_contract_task/kill/on_scanned(datum/hk_contract/contract, atom/target)
	mark_scanned_corpse(target)

/datum/hk_contract_task/capture
	name = "захват"
	points = 2
	required_opt_in = ANTAG_OPT_IN_TEMPORARY
	capturable = TRUE

/datum/hk_contract_task/capture/rules_text(datum/hk_contract/contract)
	return "Обездвижьте цель живой (наручники, оглушение, сон или крит), встаньте рядом и вызовите капсулу. Если цель сдвинется с места посадки, перетащите её мышью на капсулу. Труп и тело без игрока заказчик не примет. Контракт засчитывается, когда цель окажется внутри; через [DisplayTimeText(HK47_CAPTURE_RETURN_TIME)] её вернут на станцию. Пустая капсула улетает через [DisplayTimeText(HK47_CAPTURE_POD_WAIT)]."

/datum/hk_contract_task/theft
	name = "кража"
	required_opt_in = ANTAG_OPT_IN_TEMPORARY

/datum/hk_contract_task/theft/rules_text(datum/hk_contract/contract)
	return "Возьмите в руку ID-карту цели или печать главы её отдела ([hk47_stamp_name(contract.target_job)]) и просканируйте терминалом. Предмет уйдёт заказчику."

/datum/hk_contract_task/theft/scannable(datum/hk_contract/contract)
	return TRUE

/datum/hk_contract_task/theft/scan_target(datum/hk_contract/contract, mob/living/droid)
	var/list/hands = list(droid.get_active_held_item()) | droid.held_items
	for(var/obj/item/held in hands)
		var/obj/item/loot = loot_of(contract, held)
		if(loot)
			return loot
	return null

/datum/hk_contract_task/theft/scan_refusal(datum/hk_contract/contract, mob/living/droid, atom/target)
	var/obj/item/loot = target
	if(!istype(loot) || !loot_of(contract, loot) || get(loot, /mob) != droid)
		return "возьмите в руку ID-карту цели или печать главы её отдела."
	return null

/// Добыча кражи: ID-карта цели (в том числе внутри КПК) или печать главы её отдела.
/datum/hk_contract_task/theft/proc/loot_of(datum/hk_contract/contract, obj/item/held)
	if(!istype(held))
		return null
	var/obj/item/card/id/card = held.GetID()
	if(card && card.registered_name == contract.target_name)
		return card
	var/stamp_type = hk47_department_stamp(contract.target_job)
	if(istype(held, stamp_type))
		return held
	return null

/datum/hk_contract_task/theft/on_scanned(datum/hk_contract/contract, atom/target)
	do_sparks(3, FALSE, get_turf(target))
	qdel(target)

/proc/hk47_department_stamp(role)
	if(role in GLOB.security_positions)
		return /obj/item/stamp/hos
	if(role in GLOB.engineering_positions)
		return /obj/item/stamp/ce
	if(role in GLOB.medical_positions)
		return /obj/item/stamp/cmo
	if(role in GLOB.science_positions)
		return /obj/item/stamp/rd
	if(role in GLOB.supply_positions)
		return /obj/item/stamp/qm
	if(role in GLOB.law_positions)
		return /obj/item/stamp/ntr
	if(role in GLOB.civilian_positions)
		return /obj/item/stamp/hop
	return /obj/item/stamp/captain

/proc/hk47_stamp_name(role)
	var/obj/item/stamp/stamp_type = hk47_department_stamp(role)
	return initial(stamp_type.name)

/// Кража ценности: фирменная вещь отдела из целей кражи предателя, где бы она ни лежала на станции.
/datum/hk_contract_task/theft/relic
	name = "кража ценности"
	required_opt_in = ANTAG_OPT_IN_NOT_TARGET

/datum/hk_contract_task/theft/relic/candidate_targets(datum/antagonist/hk47/hunter)
	return hunter.theft_relics()

/datum/hk_contract_task/theft/relic/pick_target(datum/antagonist/hk47/hunter, list/role_group, list/exclude)
	var/list/relics = candidate_targets(hunter)
	relics -= hunter.excluded_targets(exclude)
	return length(relics) ? pick(relics) : null

/datum/hk_contract_task/theft/relic/snapshot_target(datum/hk_contract/contract, obj/item/relic)
	contract.target_name = relic.name
	contract.target_job = get_area_name(relic, TRUE)
	contract.target_type = relic.type

/datum/hk_contract_task/theft/relic/rules_text(datum/hk_contract/contract)
	return "Найдите [contract.target_name] - целеуказатель ведёт к самой вещи. Возьмите её в руку и просканируйте терминалом: вещь уйдёт заказчику. Годится и другой экземпляр той же вещи, даже если оригинал уничтожен."

/datum/hk_contract_task/theft/relic/unavailable_reason(datum/hk_contract/contract)
	var/obj/item/relic = contract.get_target()
	if(QDELETED(relic))
		return held_copy(contract) ? null : "вещь уничтожена."
	if(!contract.hunter.in_contract_zone(relic) && get(relic, /mob) != contract.hunter.owner?.current)
		return "вещь покинула станцию."
	return null

/datum/hk_contract_task/theft/relic/proc/held_copy(datum/hk_contract/contract)
	var/mob/living/droid = contract.hunter.owner?.current
	for(var/obj/item/held in droid?.held_items)
		if(loot_of(contract, held))
			return held
	return null

/datum/hk_contract_task/theft/relic/scan_refusal(datum/hk_contract/contract, mob/living/droid, atom/target)
	var/obj/item/loot = target
	if(!istype(loot) || !loot_of(contract, loot) || get(loot, /mob) != droid)
		return "возьмите в руку [contract.target_name]."
	return null

/datum/hk_contract_task/theft/relic/loot_of(datum/hk_contract/contract, obj/item/held)
	if(!contract.target_type || !istype(held))
		return null
	return held.type == contract.target_type ? held : null

/datum/hk_contract_task/sabotage
	name = "саботаж"

/datum/hk_contract_task/sabotage/is_available(datum/antagonist/hk47/hunter)
	return length(hunter.sabotage_targets())

/datum/hk_contract_task/sabotage/candidate_targets(datum/antagonist/hk47/hunter)
	return hunter.sabotage_targets()

/// Сначала вид машины, потом машина: серверов телекомов и СМЕСов много, но выпадают они не чаще консоли связи.
/datum/hk_contract_task/sabotage/pick_target(datum/antagonist/hk47/hunter, list/role_group, list/exclude)
	var/list/machines = candidate_targets(hunter)
	machines -= hunter.excluded_targets(exclude)
	var/list/kinds = list()
	for(var/obj/machinery/machine as anything in machines)
		var/kind = machine.type
		for(var/listed_kind in HK47_SABOTAGE_TYPES)
			if(istype(machine, listed_kind))
				kind = listed_kind
				break
		var/list/same_kind = kinds[kind]
		if(!same_kind)
			same_kind = list()
			kinds[kind] = same_kind
		same_kind += machine
	if(!length(kinds))
		return null
	return pick(kinds[pick(kinds)])

/datum/hk_contract_task/sabotage/snapshot_target(datum/hk_contract/contract, obj/machinery/machine)
	contract.target_name = machine.name
	contract.target_job = get_area_name(machine, TRUE)

/datum/hk_contract_task/sabotage/rules_text(datum/hk_contract/contract)
	return "Выведите назначенную машину из строя любым способом. Контракт засчитывается в момент поломки."

/datum/hk_contract_task/sabotage/on_accept(datum/hk_contract/contract)
	contract.watch_machine(contract.get_target())

/datum/hk_contract_task/sabotage/unavailable_reason(datum/hk_contract/contract)
	var/obj/machinery/machine = contract.get_target()
	if(QDELETED(machine) || (machine.machine_stat & BROKEN))
		return "машину уже вывели из строя."
	return null

/datum/hk_contract_task/protect
	name = "охрана"
	points = 2

/datum/hk_contract_task/protect/rules_text(datum/hk_contract/contract)
	return "Цель должна прожить [DisplayTimeText(HK47_PROTECT_TIME)] после принятия контракта, а вы - провести рядом с ней (не дальше [HK47_PROTECT_RANGE] клеток) хотя бы [HK47_PROTECT_PRESENCE_PERCENT]% срока: заказчик сверяет пеленги. С середины срока, как только вы рядом с ней на станции, конкурент пришлёт капсулой пару HK-50: за ней, если она согласна быть целью убийства, иначе - за вами. Цель получает личное сообщение, что охрану ей анонимно оплатили, но заказчика не знает. Если она уйдёт из игры, охрана снимается без штрафа."

/datum/hk_contract_task/protect/on_accept(datum/hk_contract/contract)
	contract.protect_timer = addtimer(CALLBACK(contract, TYPE_PROC_REF(/datum/hk_contract, protect_time_up)), HK47_PROTECT_TIME, TIMER_STOPPABLE)
	contract.protect_sample_timer = addtimer(CALLBACK(contract, TYPE_PROC_REF(/datum/hk_contract, sample_protection)), HK47_PROTECT_SAMPLE, TIMER_STOPPABLE | TIMER_LOOP)
	contract.rival_timer = addtimer(CALLBACK(contract, TYPE_PROC_REF(/datum/hk_contract, send_rivals)), HK47_PROTECT_TIME / 2, TIMER_STOPPABLE)
	var/mob/living/vip = contract.target_body()
	if(!vip)
		return
	var/text = "Анонимный доброжелатель оплатил вашу охрану: дроид [HK47_NAME] будет защищать вас [DisplayTimeText(HK47_PROTECT_TIME)]."
	if(contract.hunter.is_licensed())
		text += " Если СБ спросит о нём, вы можете за него поручиться."
	contract.hunter.notify_vip(vip, text)

/datum/hk_contract_task/protect/on_target_death(datum/hk_contract/contract)
	contract.hunter.fail(contract, "VIP погиб.")

/datum/hk_contract_task/protect/head
	name = "охрана главы"

/datum/hk_contract_task/protect/head/candidate_targets(datum/antagonist/hk47/hunter)
	var/list/heads = list()
	for(var/datum/mind/candidate as anything in ..())
		if(candidate.assigned_role in GLOB.command_positions)
			heads += candidate
	return heads

/datum/hk_contract_task/hunt
	name = "охота на охотника"
	points = 2
	required_opt_in = ANTAG_OPT_IN_TEMPORARY
	lethal = TRUE
	capturable = TRUE

/datum/hk_contract_task/hunt/lethal_for(datum/antagonist/hk47/hunter, client_id, datum/mind/target_mind)
	return client_id != HK_CLIENT_CENTCOM && hunter.allows_kill_contracts() && antag_opt_in_allows(target_mind, ANTAG_OPT_IN_KILL)

/// Только засветившиеся антаги, на которых ещё не было охоты: тихого антага HK не выдаёт и не травит.
/datum/hk_contract_task/hunt/candidate_targets(datum/antagonist/hk47/hunter)
	var/list/antags = list()
	for(var/datum/mind/candidate as anything in hunter.hunt_pool())
		if(!candidate.hk47_hunted && hunter.is_antag_mind(candidate) && hunter.antag_exposed(candidate) && hunter.valid_target(candidate, required_opt_in))
			antags += candidate
	return antags

/datum/hk_contract_task/hunt/unavailable_reason(datum/hk_contract/contract)
	. = ..()
	if(!. && !contract.hunter.is_antag_mind(contract.target_mind()))
		return "цель больше не антагонист, заказ отозван."

/datum/hk_contract_task/hunt/rules_text(datum/hk_contract/contract)
	var/finish = contract.lethal ? "ликвидируйте и просканируйте труп или захватите живой капсулой" : "обездвижьте живой и вызовите капсулу"
	if(contract.client_id == HK_CLIENT_CENTCOM)
		finish += " либо сами доставьте в наручниках в камеру брига: тащите цель или держитесь не дальше [HK47_BRIG_ESCORT_RANGE] клеток от неё"
	return "Цель - засветившийся антагонист, имя скрыто, а по своим каналам он узнает, что за ним идёт дроид HK. Идите по следу, опознайте подозреваемого не дальше [HK47_IDENTIFY_RANGE] клеток и в прямой видимости (ошибка - пауза [DisplayTimeText(HK47_IDENTIFY_COOLDOWN)]), затем [finish]."

/datum/hk_contract_task/hunt/on_accept(datum/hk_contract/contract)
	var/datum/mind/target_mind = contract.target_mind()
	target_mind.hk47_hunted = TRUE
	if(!isnull(target_mind.hk47_kill_time))
		contract.trace_area = target_mind.hk47_kill_area
		contract.trace_time = target_mind.hk47_kill_time
	contract.hunter.warn_hunted(contract)

/datum/hk_contract_task/hunt/scannable(datum/hk_contract/contract)
	return contract.lethal

/datum/hk_contract_task/hunt/scan_refusal(datum/hk_contract/contract, mob/living/droid, atom/target)
	if(!contract.lethal)
		return "этот контракт закрывается только захватом."
	if(!contract.identified)
		return "цель не опознана: подойдите к подозреваемому и опознайте его."
	return corpse_scan_refusal(contract, droid, target)

/datum/hk_contract_task/hunt/on_scanned(datum/hk_contract/contract, atom/target)
	mark_scanned_corpse(target)

/// Выжженная сканером HK метка на трупе: видна, если осматривать тело вплотную.
/datum/element/hk47_scan_mark
	element_flags = ELEMENT_DETACH

/datum/element/hk47_scan_mark/Attach(datum/target)
	. = ..()
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/element/hk47_scan_mark/Detach(datum/source, ...)
	UnregisterSignal(source, COMSIG_PARENT_EXAMINE)
	return ..()

/datum/element/hk47_scan_mark/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(get_dist(user, source) <= 1)
		examine_list += span_warning("На теле выжжена ровная метка - след сканера дроида серии HK.")

/// HK-50 конкурента: охотится на подопечного HK-47 или на самого HK и улетает, когда охрана кончилась или цель мертва.
/datum/component/hk50_rival
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/mark_ref
	var/departure_timer

/datum/component/hk50_rival/Initialize(mob/living/mark, lifetime)
	if(!istype(parent, /mob/living/simple_animal/hostile/hk50) || !istype(mark))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/simple_animal/hostile/hk50/rival = parent
	mark_ref = WEAKREF(mark)
	rival.faction = list(HK47_RIVAL_FACTION)
	if(rival.ai_controller)
		new /datum/ai_controller/hostile_adapter/ranged_skirmisher/hk50_rival(rival)
	RegisterSignals(mark, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(on_mark_lost))
	departure_timer = addtimer(CALLBACK(src, PROC_REF(depart)), lifetime, TIMER_STOPPABLE)

/datum/component/hk50_rival/Destroy(force, silent)
	var/mob/living/mark = mark_ref?.resolve()
	if(mark)
		UnregisterSignal(mark, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	deltimer(departure_timer)
	return ..()

/datum/component/hk50_rival/proc/on_mark_lost(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	deltimer(departure_timer)
	departure_timer = addtimer(CALLBACK(src, PROC_REF(depart)), HK47_RIVAL_DEPART_DELAY, TIMER_STOPPABLE)

/datum/component/hk50_rival/proc/depart()
	departure_timer = null
	var/mob/living/simple_animal/hostile/hk50/rival = parent
	if(QDELETED(rival))
		return
	if(rival.stat != DEAD)
		rival.visible_message(span_warning("[rival] вспыхивает и исчезает: конкурент отозвал дроида."))
		do_sparks(3, FALSE, rival)
	qdel(rival)

/datum/ai_controller/hostile_adapter/ranged_skirmisher/hk50_rival
	blackboard = list(BB_AI_TARGET_SCORER = /datum/target_scorer/hk50_rival)

/// Цель конкурента важнее любой другой.
/datum/target_scorer/hk50_rival

/datum/target_scorer/hk50_rival/score(datum/ai_controller/controller, atom/candidate, atom/current_target, candidate_distance)
	. = ..()
	var/datum/component/hk50_rival/hired = controller.pawn.GetComponent(/datum/component/hk50_rival)
	if(hired && candidate == hired.mark_ref?.resolve())
		. += HK47_RIVAL_MARK_SCORE

/proc/hk47_is_antag_mind(datum/mind/candidate)
	for(var/datum/antagonist/antag as anything in candidate?.antag_datums)
		if(!istype(antag, /datum/antagonist/hk47) && !istype(antag, /datum/antagonist/ghost_role))
			return TRUE
	return FALSE

/proc/hk47_wanted_by_security(datum/mind/candidate)
	var/datum/data/record/record = GLOB.data_core.security_by_name[candidate.current?.real_name || candidate.name]
	var/status = record?.fields["criminal"]
	return status == SEC_RECORD_STATUS_ARREST || status == SEC_RECORD_STATUS_EXECUTE

/proc/hk47_mind_by_ckey(target_ckey)
	var/client/target_client = GLOB.directory[target_ckey]
	if(target_client?.mob?.mind)
		return target_client.mob.mind
	for(var/datum/mind/candidate as anything in SSticker.minds)
		if(candidate.key && ckey(candidate.key) == target_ckey)
			return candidate
	return null

/// Предупреждение цели охоты голосом её собственных каналов, без имени заказчика.
/proc/hk47_hunt_channel(datum/mind/target_mind)
	var/static/list/channels = list(
		/datum/antagonist/changeling = "Улей шепчет",
		/datum/antagonist/heretic = "Мансус шепчет",
		/datum/antagonist/cult = "Геометр предупреждает",
		/datum/antagonist/wizard = "Федерация магов предупреждает",
		/datum/antagonist/nukeop = "Штаб Синдиката сообщает",
		/datum/antagonist/ninja = "Клан паука сообщает",
		/datum/antagonist/traitor = "По каналам Синдиката",
	)
	for(var/datum/antagonist/antag as anything in target_mind.antag_datums)
		for(var/antag_type in channels)
			if(istype(antag, antag_type))
				return channels[antag_type]
	return "По вашим каналам"
