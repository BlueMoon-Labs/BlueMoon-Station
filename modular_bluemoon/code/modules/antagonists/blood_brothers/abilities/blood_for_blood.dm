/datum/action/cooldown/blood_bond/blood_for_blood
	name = "Кровь за кровь"
	desc = "Отдать брату 15% своей крови: часть ран затянется сразу, а всего за несколько секунд уйдёт 20 ушибов и 20 ожогов. Брату без сознания станет легче дышать. Нельзя, если после этого у вас останется слишком мало крови; мёртвому не поможет. Получив чужую кровь, свою нельзя отдавать 3 минуты. Под вами обоими останутся капли крови. По клятве «Долг крови» кровь можно отдать и её цели."
	bond_how = "Встать вплотную к брату или к цели клятвы «Долг крови», нажать кнопку и 3 секунды держать порезанную ладонь у руки."
	button_icon_state = "blood_for_blood"
	beam_state = "blood_thread"
	min_tier = 1
	cooldown_time = 2 MINUTES

/datum/action/cooldown/blood_bond/blood_for_blood/Activate(atom/target)
	var/list/candidates = list()
	for(var/mob/living/carbon/human/neighbour in orange(1, owner))
		if(neighbour.stat != DEAD && brother.blood_for_blood_allows(neighbour))
			candidates += neighbour
	if(!length(candidates))
		owner.balloon_alert(owner, "рядом некому отдать кровь")
		return FALSE
	var/refusal = donor_refusal()
	if(refusal)
		owner.balloon_alert(owner, refusal)
		return FALSE
	var/mob/living/carbon/human/chosen = candidates[1]
	if(length(candidates) > 1)
		chosen = tgui_input_list(owner, "Кому отдать кровь?", name, candidates)
		if(!chosen || QDELETED(src) || !IsAvailable())
			return FALSE
	owner.visible_message(span_warning("[owner] надрезает ладонь и тянется к [chosen]."), span_notice("Вы надрезаете ладонь и тянетесь к [chosen]."))
	if(!bond_do_after(chosen, BROTHER_TRANSFUSION_TIME) || QDELETED(src) || !IsAvailable())
		return FALSE
	if(!owner.Adjacent(chosen) || !brother.blood_for_blood_allows(chosen) || !transfer(chosen))
		owner.balloon_alert(owner, "кровь не пошла")
		return FALSE
	StartCooldown(bond_cooldown())
	return TRUE

/// Почему донор не может отдать кровь, или null
/datum/action/cooldown/blood_bond/blood_for_blood/proc/donor_refusal()
	var/mob/living/carbon/donor = owner
	if(!iscarbon(donor) || !donor.get_blood_id())
		return "в жилах нет крови"
	if(donor.blood_volume - BROTHER_TRANSFUSION_AMOUNT < BLOOD_VOLUME_SAFE)
		return "крови слишком мало"
	if(donor.has_status_effect(/datum/status_effect/brother_blood_received))
		return "чужая кровь ещё не прижилась"
	return null

/// Отдать кровь сразу, без ожидания; TRUE, если кровь ушла
/datum/action/cooldown/blood_bond/blood_for_blood/proc/transfer(mob/living/carbon/human/recipient)
	var/mob/living/carbon/donor = owner
	if(!brother?.team || !istype(recipient) || recipient == donor || recipient.stat == DEAD || donor_refusal())
		return FALSE
	donor.blood_volume -= BROTHER_TRANSFUSION_AMOUNT
	if(recipient.blood_volume < BLOOD_VOLUME_NORMAL)
		recipient.blood_volume = min(recipient.blood_volume + BROTHER_TRANSFUSION_AMOUNT, BLOOD_VOLUME_NORMAL)
	var/heal_share = BROTHER_TRANSFUSION_HEAL / (BROTHER_TRANSFUSION_TICKS + 1)
	recipient.heal_overall_damage(heal_share, heal_share)
	recipient.apply_status_effect(/datum/status_effect/brother_transfusion)
	recipient.apply_status_effect(/datum/status_effect/brother_blood_received)
	if(recipient.stat != CONSCIOUS)
		recipient.adjustOxyLoss(-BROTHER_TRANSFUSION_OXY_HEAL)
	donor.add_splatter_floor(get_turf(donor), TRUE)
	donor.add_splatter_floor(get_turf(recipient), TRUE)
	new /obj/effect/temp_visual/blood_brothers/transfuse_drop(get_turf(recipient))
	donor.visible_message(span_warning("[donor] прижимает порезанную ладонь к руке [recipient]."), span_notice("Вы прижимаете порезанную ладонь к руке [recipient] и чувствуете, как уходит кровь."))
	to_chat(recipient, span_notice("Чужая кровь разливается по жилам теплом."))
	playsound(donor, 'modular_bluemoon/sound/blood_brothers/brother_transfusion.ogg', BROTHER_TRANSFUSION_VOLUME, TRUE, SILENCED_SOUND_EXTRARANGE)
	log_game("[key_name(donor)] gave blood for blood to [key_name(recipient)] ([brother.team.name]).")
	SEND_SIGNAL(brother.team, COMSIG_BROTHER_BLOOD_GIVEN, donor, recipient)
	return TRUE

/// Остаток лечения Крови за кровь, по равной доле за тик
/datum/status_effect/brother_transfusion
	id = "brother_transfusion"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null
	tick_interval = 1 SECONDS
	var/ticks_left = BROTHER_TRANSFUSION_TICKS

/datum/status_effect/brother_transfusion/tick()
	if(owner.stat == DEAD)
		qdel(src)
		return
	var/heal_share = BROTHER_TRANSFUSION_HEAL / (BROTHER_TRANSFUSION_TICKS + 1)
	owner.heal_overall_damage(heal_share, heal_share)
	ticks_left--
	if(ticks_left <= 0)
		qdel(src)

/// Чужая кровь приживается: пока висит, свою отдавать нельзя
/datum/status_effect/brother_blood_received
	id = "brother_blood_received"
	duration = BROTHER_TRANSFUSION_RECEIVE_LOCK
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = -1
	alert_type = null
