/datum/team/brother_team
	/// Схрон крови: общий карман команды
	var/obj/item/storage/blood_stash/stash
	var/oath_timer

/// Голосует и скрепляет только живой брат, не ушедший и не разорвавший клятву
/datum/team/brother_team/proc/is_active_brother(datum/mind/member)
	if(!member || !(member in members) || (member in departed_minds) || (member in severed_minds))
		return FALSE
	var/mob/living/body = member.current
	return !QDELETED(body) && body.stat != DEAD

/datum/team/brother_team/proc/offer_oaths()
	if(oath || abandoned)
		return FALSE
	if(!fill_offers())
		ensure_oath_objectives()
		log_game("Blood brothers [name] got no oath to offer, only the escape remains.")
		notify("Клятвы для вас не нашлось. Держитесь вместе и уходите со станции свободными.")
		refresh_brother_uis(static_data = TRUE)
		return FALSE
	oath_deadline = world.time + BROTHER_OATH_CHOICE_TIME
	deltimer(oath_timer)
	oath_timer = addtimer(CALLBACK(src, PROC_REF(oath_timeout)), BROTHER_OATH_CHOICE_TIME, TIMER_STOPPABLE)
	log_game("Blood brothers [name] offered oaths: [offered_keys_text()].")
	notify("Пора дать клятву: откройте окно «Кровная клятва». На выбор [BROTHER_OATH_CHOICE_TIME / (1 MINUTES)] минут, потом клятвой станет первая из предложенных.")
	refresh_brother_uis(static_data = TRUE)
	return TRUE

/// После исполненной клятвы - новые на выбор, без срока и со старым обетом
/datum/team/brother_team/proc/offer_next_oaths()
	if(!oath || oath.current_step() || abandoned || training)
		return FALSE
	var/list/sworn_keys = list(oath.key)
	for(var/datum/blood_oath/fulfilled as anything in fulfilled_oaths)
		sworn_keys |= fulfilled.key
	if(!fill_offers(sworn_keys, vow?.type))
		return FALSE
	oath_deadline = 0
	log_game("Blood brothers [name] offered next oaths: [offered_keys_text()].")
	notify("Можно дать ещё одну клятву в окне «Кровная клятва»: её венец добавится к прежним, обет останется тот же. Можно и не давать - тогда осталось уйти вместе.")
	refresh_brother_uis(static_data = TRUE)
	return TRUE

/datum/team/brother_team/proc/clear_offers()
	QDEL_LIST(offered)
	proposed = null
	proposed_by = null
	signed.Cut()

/// До BROTHER_OATH_OFFER_COUNT клятв, кроме excluded_keys; vow_type - один обет на все, иначе случайный каждой
/datum/team/brother_team/proc/fill_offers(list/excluded_keys, vow_type)
	clear_offers()
	var/list/weighted = list()
	for(var/datum/blood_oath/oath_type as anything in GLOB.blood_oath_types)
		if(initial(oath_type.key) in excluded_keys)
			continue
		var/datum/blood_oath/candidate = new oath_type
		if(!candidate.available(src) || !candidate.prepare(src))
			qdel(candidate)
			continue
		weighted[candidate] = candidate.get_weight(src)
	while(length(weighted) && length(offered) < BROTHER_OATH_OFFER_COUNT)
		var/datum/blood_oath/picked = pickweight(weighted)
		if(!picked)
			break
		weighted -= picked
		picked.vow_type = vow_type || pick(GLOB.blood_vow_types)
		picked.vow = new picked.vow_type
		offered += picked
	for(var/datum/blood_oath/leftover as anything in weighted)
		qdel(leftover)
	return length(offered)

/datum/team/brother_team/proc/offered_keys_text()
	var/list/offered_keys = list()
	for(var/datum/blood_oath/candidate as anything in offered)
		offered_keys += candidate.key
	return offered_keys.Join(", ")

/// Исполненные клятвы вместе с данной, если все её печати стоят
/datum/team/brother_team/proc/all_fulfilled_oaths()
	. = fulfilled_oaths.Copy()
	if(oath && length(oath.steps) && !oath.current_step())
		. += oath

/// Клятву выбирают, пока данной нет или данная исполнена
/datum/team/brother_team/proc/choosing_oath()
	return length(offered) && (!oath || !oath.current_step())

/// TRUE или причина, почему брат сейчас не голосует за клятву; наручники голосу не мешают
/datum/team/brother_team/proc/vote_refusal(datum/mind/voter)
	if(!is_active_brother(voter))
		return "голосует только живой брат"
	var/datum/antagonist/brother/voter_brother = voter.has_antag_datum(/datum/antagonist/brother)
	if(!voter_brother || voter_brother.is_muted())
		return "связь заглушена"
	if(voter.current.stat != CONSCIOUS)
		return "нужно быть в сознании"
	return TRUE

/// Заглушённых не ждут: они не голосуют
/datum/team/brother_team/proc/all_signed()
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		var/datum/mind/member = brother.owner
		if(is_active_brother(member) && !brother.is_muted() && !(member in signed))
			return FALSE
	return TRUE

/datum/team/brother_team/proc/propose_oath(datum/mind/proposer, oath_key)
	if(!choosing_oath() || vote_refusal(proposer) != TRUE)
		return FALSE
	var/datum/blood_oath/choice
	for(var/datum/blood_oath/candidate as anything in offered)
		if(candidate.key == oath_key)
			choice = candidate
			break
	if(!choice)
		return FALSE
	if(proposed == choice)
		return proposed_by == proposer || sign_oath(proposer)
	proposed = choice
	proposed_by = proposer
	signed = list(proposer)
	log_game("Blood brothers [name]: [key_name(proposer)] proposed oath [choice.key].")
	if(all_signed())
		return swear_oath(choice)
	notify("[proposer.name] предлагает клятву «[choice.name]». Подпишите её кровью в окне «Кровная клятва».")
	refresh_brother_uis()
	return TRUE

/datum/team/brother_team/proc/sign_oath(datum/mind/signer)
	if(!choosing_oath() || !proposed || signer == proposed_by || (signer in signed) || vote_refusal(signer) != TRUE)
		return FALSE
	signed += signer
	log_game("Blood brothers [name]: [key_name(signer)] signed oath [proposed.key].")
	if(all_signed())
		return swear_oath(proposed)
	notify("[signer.name] подписывает клятву «[proposed.name]» кровью.")
	refresh_brother_uis()
	return TRUE

/datum/team/brother_team/proc/oath_timeout()
	oath_timer = null
	if(oath || abandoned || QDELETED(src))
		return
	var/datum/blood_oath/fallback = proposed || (length(offered) ? offered[1] : null)
	if(!swear_oath(fallback, allow_fallback = TRUE))
		offer_oaths()

/// allow_fallback - только по таймеру: отпавшая клятва подбирается заново или уступает следующей.
/// keep_vow - нынешний обет команды остаётся со своей историей. Исполненная клятва уходит в fulfilled_oaths
/datum/team/brother_team/proc/swear_oath(datum/blood_oath/chosen, allow_fallback = FALSE, keep_vow = FALSE)
	if(!chosen || oath?.current_step() || QDELETED(src))
		return FALSE
	if(!allow_fallback)
		chosen.team = src
		if(!chosen.revalidate())
			log_game("Blood brothers [name]: oath [chosen.key] lost its target at signing.")
			if(!(chosen in offered))
				return FALSE
			offered -= chosen
			if(proposed == chosen)
				proposed = null
				proposed_by = null
				signed.Cut()
			notify("Клятва «[chosen.name]» больше невозможна: её цель недоступна. Выберите другую.")
			qdel(chosen)
			if(length(offered))
				refresh_brother_uis()
			else if(oath)
				offer_next_oaths()
			else
				offer_oaths()
			return FALSE
	var/datum/blood_oath/sworn
	for(var/datum/blood_oath/candidate as anything in list(chosen) + (allow_fallback ? offered - chosen : list()))
		candidate.team = src
		if(candidate.revalidate() || candidate.prepare(src))
			sworn = candidate
			break
		log_game("Blood brothers [name]: oath [candidate.key] lost its targets.")
		if(!(candidate in offered))
			continue
		offered -= candidate
		if(proposed == candidate)
			proposed = null
			proposed_by = null
			signed.Cut()
		qdel(candidate)
	if(!sworn)
		refresh_brother_uis()
		return FALSE
	offered -= sworn
	clear_offers()
	deltimer(oath_timer)
	oath_timer = null
	if(oath)
		fulfilled_oaths += oath
		keep_vow = TRUE
	oath = sworn
	if(keep_vow && vow)
		QDEL_NULL(sworn.vow)
		sworn.vow_type = vow.type
	else
		if(!sworn.vow_type)
			sworn.vow_type = pick(GLOB.blood_vow_types)
		var/datum/blood_vow/new_vow = sworn.vow
		sworn.vow = null
		if(new_vow?.type != sworn.vow_type)
			qdel(new_vow)
			new_vow = new sworn.vow_type
		QDEL_NULL(vow)
		vow = new_vow
		vow.attach(src)
	sworn.on_sworn()
	ensure_oath_objectives()
	SEND_SIGNAL(src, COMSIG_BROTHER_TEAM_OATH_SWORN, sworn)
	notify("[length(fulfilled_oaths) ? "Новая клятва дана" : "Клятва дана"]: [sworn.name]. Обет: [vow.name].", 'modular_bluemoon/sound/blood_brothers/brother_sworn.ogg', BROTHER_SWORN_VOLUME)
	log_game("Blood brothers [name] swore oath [sworn.key][sworn.target_mind ? " against [key_name(sworn.target_mind)]" : ""] with vow [vow.key].")
	give_oath_kit(sworn)
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		brother.refresh_bond_actions()
	refresh_brother_uis(static_data = TRUE)
	return TRUE

/// Каждому живому брату - бумажный узелок с вещами клятвы: в рюкзак или под ноги
/datum/team/brother_team/proc/give_oath_kit(datum/blood_oath/sworn)
	if(!length(sworn.kit_items))
		return
	var/kit_text = sworn.kit_text()
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		var/datum/mind/member = brother.owner
		if(!is_active_brother(member))
			continue
		var/mob/living/body = member.current
		var/obj/item/storage/box/papersack/kit = new(body.drop_location())
		for(var/item_type in sworn.kit_items)
			new item_type(kit)
		kit.update_appearance()
		var/where = "под ногами"
		if(iscarbon(body))
			var/mob/living/carbon/carbon_body = body
			where = carbon_body.equip_in_one_of_slots(kit, list("в рюкзаке" = ITEM_SLOT_BACKPACK), qdel_on_fail = FALSE) || where
		to_chat(body, span_notice("Узелок под клятву [where], в бумажном пакете: [kit_text]."))

/datum/team/brother_team/proc/ensure_oath_objectives()
	if(oath && !(locate(/datum/objective/blood_oath) in objectives))
		var/datum/objective/blood_oath/oath_objective = new
		oath_objective.team = src
		objectives.Insert(1, oath_objective)
	if(!(locate(/datum/objective/blood_oath_escape) in objectives))
		var/datum/objective/blood_oath_escape/escape_objective = new
		escape_objective.team = src
		objectives += escape_objective
	for(var/datum/objective/objective as anything in objectives)
		objective.update_explanation_text()

/// TRUE или строка-причина; без побочных эффектов. step_verdict - уже посчитанный can_seal текущего шага
/datum/team/brother_team/proc/seal_refusal(datum/mind/sealer, step_verdict)
	if(!oath)
		return "клятвы ещё нет"
	if(!is_active_brother(sealer))
		return "скрепляет только живой брат"
	var/datum/antagonist/brother/sealer_brother = sealer.has_antag_datum(/datum/antagonist/brother)
	if(!sealer_brother || sealer_brother.is_muted())
		return "связь заглушена"
	var/mob/living/sealer_body = sealer.current
	if(sealer_body.stat != CONSCIOUS)
		return "нужно быть в сознании"
	if(iscarbon(sealer_body))
		var/mob/living/carbon/carbon_sealer = sealer_body
		if(carbon_sealer.handcuffed)
			return "в наручниках печать не поставить"
	var/datum/blood_oath_step/next_step = oath.current_step()
	if(!next_step)
		return "всё скреплено"
	return isnull(step_verdict) ? next_step.can_seal(sealer.current) : step_verdict

/datum/team/brother_team/proc/try_seal(datum/mind/sealer)
	var/refusal = seal_refusal(sealer)
	if(refusal != TRUE)
		return refusal
	var/datum/blood_oath_step/sealed_step = oath.current_step()
	sealed_step.sealed = TRUE
	sealed_step.sealed_by = sealer.name
	sealed_step.on_sealed(sealer)
	SEND_SIGNAL(src, COMSIG_BROTHER_TEAM_STEP_SEALED, sealed_step, sealer)
	set_bond_tier(bond_tier + 1)
	var/all_sealed = !oath.current_step()
	if(all_sealed && vow?.holds())
		cooldown_multiplier = BROTHER_FLAWLESS_COOLDOWN_MULT
	notify("[sealer.name] скрепляет кровью шаг «[sealed_step.name]».[all_sealed ? " Все печати на месте: клятва исполнена." : ""]", 'modular_bluemoon/sound/blood_brothers/brother_seal.ogg', BROTHER_SEAL_VOLUME)
	flash_seal(sealer.current)
	log_game("Blood brothers [name]: [key_name(sealer)] sealed step [oath.steps.Find(sealed_step)] of oath [oath.key].")
	refresh_brother_uis()
	if(all_sealed)
		oath_fulfilled()
	return TRUE

/// Все печати клятвы стоят: её венец остаётся за командой, дальше можно дать следующую
/datum/team/brother_team/proc/oath_fulfilled()
	log_game("Blood brothers [name] fulfilled oath [oath.key].")
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		brother.refresh_bond_actions()
	if(offer_next_oaths())
		return
	notify("Осталось уйти вместе: всем живым братьям - до ЦК, без наручников.")
	refresh_brother_uis(static_data = TRUE)

/// Вспышка печати над скрепившим; видят только незаглушённые живые братья
/datum/team/brother_team/proc/flash_seal(mob/living/sealer)
	if(!isliving(sealer))
		return
	var/list/viewers = list()
	for(var/mob/living/body as anything in living_brothers())
		var/datum/antagonist/brother/body_brother = body.mind?.has_antag_datum(/datum/antagonist/brother)
		if(body.client && body_brother && !body_brother.is_muted())
			viewers += body.client
	if(!length(viewers))
		return
	var/image/flash = image('modular_bluemoon/icons/effects/blood_brothers.dmi', sealer, "seal_flash", ABOVE_MOB_LAYER)
	flash.pixel_y = BROTHER_EFFECT_RAISE
	flick_overlay(flash, viewers, BROTHER_SEAL_FLASH_TIME)

/// Тексты целей и окна; не спит
/datum/team/brother_team/proc/refresh_brother_uis(static_data = FALSE)
	for(var/datum/objective/objective as anything in objectives)
		objective.update_explanation_text()
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		if(static_data)
			brother.update_static_data_for_all_viewers()
		else
			SStgui.update_uis(brother)

/datum/team/brother_team/proc/on_roster_changed(datum/source, datum/mind/member)
	SIGNAL_HANDLER
	refresh_brother_uis(static_data = TRUE)
