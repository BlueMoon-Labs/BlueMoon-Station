/datum/blood_oath/blood_debt
	name = "Долг крови"
	key = "blood_debt"
	summary = "добыть подарок спасителю, вручить его и отдать спасителю свою кровь"
	weight = 8
	capstone_type = /datum/action/cooldown/blood_bond/capstone/bulwark
	kit_items = list(BROTHER_KIT_BREAKIN)
	target_opt_in_level = ANTAG_OPT_IN_TEMPORARY
	var/gift_type
	var/gift_name
	var/datum/objective_item/gift_info
	/// Брат отдал цели кровь Кровью за кровь после вручения подарка
	var/blood_given = FALSE

/datum/blood_oath/blood_debt/Destroy()
	if(team)
		UnregisterSignal(team, COMSIG_BROTHER_BLOOD_GIVEN)
	gift_info = null
	return ..()

/datum/blood_oath/blood_debt/prepare(datum/team/brother_team/for_team)
	. = ..()
	gift_info = null
	var/datum/mind/found = find_target(for_team)
	if(!found)
		return FALSE
	set_target(found)
	gift_info = brother_steal_pick(for_team, recipient = target_mind)
	if(!gift_info)
		return FALSE
	gift_type = gift_info.targetitem
	gift_name = brother_item_name(gift_info)
	add_step(new /datum/blood_oath_step/blood_debt_take)
	add_step(new /datum/blood_oath_step/blood_debt_gift)
	add_step(new /datum/blood_oath_step/blood_debt_blood)
	update_story()
	return TRUE

/datum/blood_oath/blood_debt/find_target(datum/team/brother_team/for_team)
	return brother_pick_target(for_team, target_opt_in_level, list(), src)

/datum/blood_oath/blood_debt/set_target(datum/mind/new_target)
	. = ..()
	blood_given = FALSE

/datum/blood_oath/blood_debt/update_story()
	var/mob/living/savior = target_mind.current
	story = "Однажды [target_mind.name] вытащил[savior?.ru_a()] вас обоих с того света и ничего не попросил[savior?.ru_a()] взамен. Пора вернуть долг: вручите [savior?.ru_emu()] [gift_name] и отдайте свою кровь."

/datum/blood_oath/blood_debt/on_sworn()
	. = ..()
	RegisterSignal(team, COMSIG_BROTHER_BLOOD_GIVEN, PROC_REF(on_blood_given))

/datum/blood_oath/blood_debt/proc/on_blood_given(datum/source, mob/living/donor, mob/living/recipient)
	SIGNAL_HANDLER
	if(blood_given || !target_mind || recipient?.mind != target_mind || length(steps) < 2)
		return
	var/datum/blood_oath_step/gift_step = steps[2]
	if(!gift_step.sealed)
		return
	blood_given = TRUE
	log_game("Blood brothers [team.name]: [key_name(donor)] paid the blood debt to [key_name(target_mind)].")
	team.refresh_brother_uis()

/datum/blood_oath/blood_debt/allows_blood_for_blood(mob/living/target)
	return target_mind && target?.mind == target_mind

/datum/blood_oath/blood_debt/finale_extra_complete()
	return considered_alive(target_mind)

/datum/blood_oath/blood_debt/finale_extra_text()
	var/mob/living/savior = target_mind?.current
	return "[target_mind?.name] жив[savior?.ru_a()]"

/datum/blood_oath_step/blood_debt_take
	name = "Взять подарок"

/datum/blood_oath_step/blood_debt_take/describe()
	var/datum/blood_oath/blood_debt/debt = oath
	name = "Взять: [debt.gift_name]"
	desc = "Добудьте [debt.gift_name] и держите при себе."

/datum/blood_oath_step/blood_debt_take/can_seal(mob/living/sealer)
	var/datum/blood_oath/blood_debt/debt = oath
	if(brother_team_holds(debt.team, debt.gift_type, debt.gift_info))
		return TRUE
	return "никто из братьев не несёт [debt.gift_name]"

/datum/blood_oath_step/blood_debt_take/condition_text(mob/living/viewer, sealable)
	return "на брате: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/blood_debt_gift
	name = "Вручить подарок"

/datum/blood_oath_step/blood_debt_gift/describe()
	var/datum/blood_oath/blood_debt/debt = oath
	name = "Вручить: [debt.target_mind.name]"
	desc = "Вручите [debt.target_mind.name] [debt.gift_name]: в руки, в карман или в сумку."

/datum/blood_oath_step/blood_debt_gift/can_seal(mob/living/sealer)
	var/datum/blood_oath/blood_debt/debt = oath
	var/mob/living/savior = debt.target_mind?.current
	if(isliving(savior) && savior.stat != DEAD && brother_holder_has(savior, debt.gift_info))
		return TRUE
	return "у [debt.target_mind?.name] нет подарка"

/datum/blood_oath_step/blood_debt_gift/condition_text(mob/living/viewer, sealable)
	return "у цели: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/blood_debt_blood
	name = "Кровь за кровь"

/datum/blood_oath_step/blood_debt_blood/describe()
	var/mob/living/savior = oath.target_mind.current
	name = "Кровь за кровь: [oath.target_mind.name]"
	desc = "Отдайте [oath.target_mind.name] свою кровь способностью «Кровь за кровь»: по этой клятве она работает и на [savior?.ru_nego()]. Кровь засчитывается только после того, как подарок вручён."

/datum/blood_oath_step/blood_debt_blood/can_seal(mob/living/sealer)
	var/datum/blood_oath/blood_debt/debt = oath
	if(debt.blood_given)
		return TRUE
	return "кровь [debt.target_mind?.name] ещё не отдана"

/datum/blood_oath_step/blood_debt_blood/condition_text(mob/living/viewer, sealable)
	return "кровь отдана: [sealable_now(viewer, sealable) ? "да" : "нет"]"
