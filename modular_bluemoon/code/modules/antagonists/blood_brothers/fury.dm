/datum/blood_bond_passive/fury
	name = "Ярость за брата"
	desc = "Когда брат падает без сознания или на него надевают наручники, вы на 20 секунд становитесь быстрее, устойчивее к оглушению и вдвое меньше устаёте от ударов. Смерть брата будит Ярость сразу, без перезарядки и даже до второй печати. Пока Ярость горит, у ваших ног видна кровавая аура."
	bond_how = "Работает само, пока связь не заглушена."
	cooldown_time = BROTHER_FURY_COOLDOWN

/datum/movespeed_modifier/brother_fury
	multiplicative_slowdown = -0.5
	blacklisted_movetypes = (FLYING|FLOATING)

/datum/status_effect/brother_fury
	id = "brother_fury"
	duration = BROTHER_FURY_DURATION
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/brother_fury
	/// Множители физиологии поставлены этим эффектом и снимаются им же
	var/physiology_applied = FALSE
	var/mutable_appearance/aura

/datum/status_effect/brother_fury/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/brother_fury)
	aura = mutable_appearance('modular_bluemoon/icons/effects/blood_brothers.dmi', "fury_aura", BELOW_MOB_LAYER)
	aura.appearance_flags |= RESET_TRANSFORM | KEEP_APART
	owner.add_overlay(aura)
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.physiology.stun_mod *= BROTHER_FURY_RESIST_MULT
		human_owner.physiology.stamina_mod *= BROTHER_FURY_RESIST_MULT
		physiology_applied = TRUE

/datum/status_effect/brother_fury/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/brother_fury)
	owner.cut_overlay(aura)
	aura = null
	if(physiology_applied && ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.physiology.stun_mod /= BROTHER_FURY_RESIST_MULT
		human_owner.physiology.stamina_mod /= BROTHER_FURY_RESIST_MULT
	physiology_applied = FALSE
	return ..()

/atom/movable/screen/alert/status_effect/brother_fury
	name = "Ярость за брата"
	desc = "Кровь брата стучит в висках: вы быстрее и устойчивее к оглушению и усталости. Аура у ног видна всем."
	icon = 'modular_bluemoon/icons/mob/blood_brothers/alerts.dmi'
	icon_state = "fury"

/// Снять с тела то, что связь держит дольше кнопок: Ярость, Заслон, Метку и взгляд через знак
/datum/antagonist/brother/proc/end_bond_effects(mob/living/body = owner.current)
	if(!isliving(body))
		return
	body.remove_status_effect(/datum/status_effect/brother_fury)
	body.remove_status_effect(/datum/status_effect/brother_bulwark)
	body.remove_status_effect(/datum/status_effect/brother_sense/blood_mark)
	var/datum/action/cooldown/blood_bond/capstone/sign_eyes/eyes = bond_actions[/datum/action/cooldown/blood_bond/capstone/sign_eyes]
	if(eyes?.owner == body)
		eyes.end_view()
	team?.active_mark?.remove_hud_from(body, TRUE)

/// Брат упал без сознания или скован: Ярость у остальных, если связь дошла до второй ступени
/datum/team/brother_team/proc/fury_for(datum/mind/endangered)
	if(bond_tier < BROTHER_FURY_TIER)
		return
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		if(brother.owner == endangered || (brother.owner in departed_minds))
			continue
		if(brother.trigger_fury())
			to_chat(brother.owner.current, span_warning("[endangered.name] в беде, и кровь закипает."))

/// Переходы состояний братьев: падение в крит или наручники будят Ярость, жизнь в новом теле снимает горе
/datum/team/brother_team/proc/check_brother_states()
	for(var/datum/mind/fallen as anything in fallen_minds)
		var/mob/living/body = fallen.current
		if(isliving(body) && body.stat != DEAD)
			on_brother_revived(fallen)
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		var/datum/mind/member = brother.owner
		if(member in departed_minds)
			continue
		var/state = brother.brother_state()
		var/mob/living/body = member.current
		// Сон кончается чуть позже окна добровольности: интервал Чутья не даёт принять его за обморок
		if(state == BROTHER_STATE_CRIT && isliving(body) && world.time < body.voluntary_sleep_until + BROTHER_SENSE_INTERVAL)
			continue
		var/old_state = last_states[member]
		last_states[member] = state
		if(isnull(old_state) || state == old_state || (state != BROTHER_STATE_CRIT && state != BROTHER_STATE_CUFFED))
			continue
		if(old_state == BROTHER_STATE_DEAD || old_state == BROTHER_STATE_MUTED || old_state == BROTHER_STATE_GONE)
			continue
		fury_for(member)

/// Под Яростью Чутьё называет зону брата в беде
/datum/antagonist/brother/proc/fury_area_hint(state, turf/there)
	if(!there || !owner.current?.has_status_effect(/datum/status_effect/brother_fury))
		return ""
	if(!(state in list(BROTHER_STATE_CRIT, BROTHER_STATE_CUFFED, BROTHER_STATE_DEAD)))
		return ""
	return "<br>Зона: [get_area_name(there, TRUE)]."
