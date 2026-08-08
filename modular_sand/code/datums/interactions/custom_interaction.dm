/datum/preferences
	var/list/custom_interactions
	var/custom_verb_consent = TRUE

/datum/preferences/proc/get_custom_interaction_limit()
	var/user_ckey = parent?.ckey
	if(user_ckey && is_donator_group(user_ckey, DONATOR_GROUP_TIER_2))
		return MAX_CUSTOM_INTERACTIONS_SPONSOR
	if(user_ckey && is_donator_group(user_ckey, DONATOR_GROUP_TIER_1))
		return MAX_CUSTOM_INTERACTIONS_SUBSCRIBER
	return MAX_CUSTOM_INTERACTIONS

/datum/interaction/custom
	max_distance = 1
	var/name
	var/message
	var/interaction_type = CUSTOM_INTERACTION_TYPE_NORMAL
	var/arousal_level = CUSTOM_AROUSAL_NONE
	var/partner_arousal_level = CUSTOM_AROUSAL_NONE
	var/self_orgasm = FALSE
	var/partner_orgasm = FALSE
	var/scope = CUSTOM_INTERACTION_SCOPE_BOTH
	var/required_body_parts = NONE
	var/requires_tail = FALSE
	var/requires_telekinesis = FALSE

/datum/interaction/custom/proc/get_lust_amount(level = arousal_level)
	switch(level)
		if(CUSTOM_AROUSAL_LIGHT)
			return 6
		if(CUSTOM_AROUSAL_MEDIUM)
			return 14
		if(CUSTOM_AROUSAL_STRONG)
			return 28
	return 0

/datum/interaction/custom/proc/try_moan(mob/living/M)
	var/datum/preferences/prefs = M.client?.prefs
	if(!prefs || !prefs.use_moaning_multiplier || !prob(prefs.moaning_multiplier))
		return
	M.moan()

/datum/interaction/custom/proc/get_type_label()
	switch(interaction_type)
		if(CUSTOM_INTERACTION_TYPE_LEWD)
			return "Эротика"
		if(CUSTOM_INTERACTION_TYPE_EXTREME)
			return "Тяжёлое"
		if(CUSTOM_INTERACTION_TYPE_UNHOLY)
			return "Грязное"
	return "Действие"

/datum/interaction/custom/proc/get_arousal_label(level = arousal_level)
	switch(level)
		if(CUSTOM_AROUSAL_LIGHT)
			return "Малое"
		if(CUSTOM_AROUSAL_MEDIUM)
			return "Среднее"
		if(CUSTOM_AROUSAL_STRONG)
			return "Сильное"
	return "Нет"

/datum/interaction/custom/proc/get_scope_label()
	switch(scope)
		if(CUSTOM_INTERACTION_SCOPE_SELF)
			return "На себе"
		if(CUSTOM_INTERACTION_SCOPE_OTHERS)
			return "Только на других"
	return "На обоих"

/datum/interaction/custom/proc/is_body_part_exposed(mob/living/M, requirement)
	switch(requirement)
		if(INTERACTION_REQUIRE_ANUS)
			return M.has_anus() == HAS_EXPOSED_GENITAL
		if(INTERACTION_REQUIRE_BALLS)
			return M.has_balls() == HAS_EXPOSED_GENITAL
		if(INTERACTION_REQUIRE_BELLY)
			return M.has_belly() == HAS_EXPOSED_GENITAL
		if(INTERACTION_REQUIRE_BREASTS)
			return M.has_breasts() == HAS_EXPOSED_GENITAL
		if(INTERACTION_REQUIRE_EARS)
			if(M.getorganslot(ORGAN_SLOT_EARS))
				return M.has_ears() == HAS_EXPOSED_GENITAL
			return FALSE
		if(INTERACTION_REQUIRE_EYES)
			if(M.getorganslot(ORGAN_SLOT_EYES))
				return M.has_eyes() == HAS_EXPOSED_GENITAL
			return FALSE
		if(INTERACTION_REQUIRE_FEET)
			return M.has_feet() == HAS_EXPOSED_GENITAL
		if(INTERACTION_REQUIRE_PENIS)
			return M.has_penis(TRUE) == HAS_EXPOSED_GENITAL
		if(INTERACTION_REQUIRE_VAGINA)
			return M.has_vagina() == HAS_EXPOSED_GENITAL
		if(INTERACTION_REQUIRE_TAIL)
			return M.has_tail()
	return TRUE

/datum/interaction/custom/proc/get_body_parts_label()
	var/list/labels = list()
	for(var/requirement in CUSTOM_INTERACTION_BODY_PART_REQUIREMENTS)
		if(!(required_body_parts & requirement))
			continue
		switch(requirement)
			if(INTERACTION_REQUIRE_ANUS)
				labels += "анус"
			if(INTERACTION_REQUIRE_BALLS)
				labels += "яйца"
			if(INTERACTION_REQUIRE_BELLY)
				labels += "живот"
			if(INTERACTION_REQUIRE_BREASTS)
				labels += "грудь"
			if(INTERACTION_REQUIRE_EARS)
				labels += "уши"
			if(INTERACTION_REQUIRE_EYES)
				labels += "глаза"
			if(INTERACTION_REQUIRE_FEET)
				labels += "ноги"
			if(INTERACTION_REQUIRE_PENIS)
				labels += "член"
			if(INTERACTION_REQUIRE_VAGINA)
				labels += "вагина"
			if(INTERACTION_REQUIRE_TAIL)
				labels += "хвост"
	return length(labels) ? "оголено: [english_list(labels, nothing_text = "", and_text = ", ")]" : "всегда доступно"

/datum/interaction/custom/proc/sanitize_values()
	name = copytext(strip_html(name), 1, MAX_CUSTOM_INTERACTION_NAME_LENGTH + 1)
	message = copytext(strip_html(message), 1, MAX_CUSTOM_INTERACTION_MESSAGE_LENGTH + 1)
	interaction_type = sanitize_inlist(interaction_type, CUSTOM_INTERACTION_TYPES, CUSTOM_INTERACTION_TYPE_NORMAL)
	arousal_level = sanitize_integer(arousal_level, CUSTOM_AROUSAL_NONE, CUSTOM_AROUSAL_MAX, CUSTOM_AROUSAL_NONE)
	partner_arousal_level = sanitize_integer(partner_arousal_level, CUSTOM_AROUSAL_NONE, CUSTOM_AROUSAL_MAX, CUSTOM_AROUSAL_NONE)
	self_orgasm = !!self_orgasm
	partner_orgasm = !!partner_orgasm
	scope = sanitize_inlist(scope, CUSTOM_INTERACTION_SCOPES, CUSTOM_INTERACTION_SCOPE_BOTH)
	var/allowed_body_parts = NONE
	for(var/requirement in CUSTOM_INTERACTION_BODY_PART_REQUIREMENTS)
		allowed_body_parts |= requirement
	required_body_parts = sanitize_integer(required_body_parts, 0, allowed_body_parts, 0) & allowed_body_parts
	requires_tail = !!requires_tail
	requires_telekinesis = !!requires_telekinesis
	max_distance = sanitize_integer(max_distance, 1, 3, 1)

/datum/interaction/custom/proc/get_interaction_type_num()
	switch(interaction_type)
		if(CUSTOM_INTERACTION_TYPE_LEWD)
			return INTERACTION_LEWD
		if(CUSTOM_INTERACTION_TYPE_EXTREME)
			return INTERACTION_EXTREME
		if(CUSTOM_INTERACTION_TYPE_UNHOLY)
			return 3
	return INTERACTION_NORMAL

/datum/interaction/custom/proc/get_interaction_flags()
	. = INTERACTION_FLAG_ADJACENT
	switch(interaction_type)
		if(CUSTOM_INTERACTION_TYPE_LEWD, CUSTOM_INTERACTION_TYPE_EXTREME, CUSTOM_INTERACTION_TYPE_UNHOLY)
			. |= INTERACTION_FLAG_OOC_CONSENT
		if(CUSTOM_INTERACTION_TYPE_EXTREME, CUSTOM_INTERACTION_TYPE_UNHOLY)
			. |= INTERACTION_FLAG_EXTREME_CONTENT
		if(CUSTOM_INTERACTION_TYPE_UNHOLY)
			. |= INTERACTION_FLAG_UNHOLY_CONTENT

/datum/interaction/custom/proc/has_telekinesis(mob/living/M)
	return M.check_mutation(TK) || HAS_TRAIT(M, TRAIT_TK_POTENTIAL)

/datum/interaction/custom/proc/pass_requirement_gate(mob/living/user, mob/living/target)
	if(requires_tail && !(user.has_tail() || target.has_tail()))
		return FALSE
	if(requires_telekinesis && !(has_telekinesis(user) || has_telekinesis(target)))
		return FALSE
	for(var/requirement in CUSTOM_INTERACTION_BODY_PART_REQUIREMENTS)
		if(!(required_body_parts & requirement))
			continue
		if(!is_body_part_exposed(user, requirement) && !is_body_part_exposed(target, requirement))
			return FALSE
	if(scope == CUSTOM_INTERACTION_SCOPE_SELF && user != target)
		return FALSE
	if(scope == CUSTOM_INTERACTION_SCOPE_OTHERS && user == target)
		return FALSE
	return TRUE

/datum/interaction/custom/proc/check_requirements(mob/living/user, mob/living/target, silent = TRUE)
	if(!pass_requirement_gate(user, target))
		if(!silent)
			to_chat(user, span_warning("Требования для этого действия не выполнены: [get_body_parts_label()] у кого-то из вас."))
		return FALSE
	if(target.client && !target.client.prefs.custom_verb_consent)
		if(!silent)
			to_chat(user, span_warning("[target] не принимает кастомные интеракты."))
		return FALSE
	switch(interaction_type)
		if(CUSTOM_INTERACTION_TYPE_LEWD, CUSTOM_INTERACTION_TYPE_EXTREME, CUSTOM_INTERACTION_TYPE_UNHOLY)
			if(user.ckey && user.client && !(user.client.prefs.toggles & VERB_CONSENT))
				if(!silent)
					to_chat(user, span_warning("Ты отключил согласие на левд-интеракты."))
				return FALSE
			if(target.client && !(target.client.prefs.toggles & VERB_CONSENT))
				if(!silent)
					to_chat(user, span_warning("[target] не даёт согласие на левд-интеракты."))
				return FALSE
		if(CUSTOM_INTERACTION_TYPE_EXTREME, CUSTOM_INTERACTION_TYPE_UNHOLY)
			if(user.client && user.client.prefs.extremepref == "No")
				if(!silent)
					to_chat(user, span_warning("Это слишком жёстко для тебя."))
				return FALSE
			if(target.client && target.client.prefs.extremepref == "No")
				if(!silent)
					to_chat(user, span_warning("Это слишком жёстко для [target]."))
				return FALSE
		if(CUSTOM_INTERACTION_TYPE_UNHOLY)
			if(user.client && user.client.prefs.unholypref == "No")
				if(!silent)
					to_chat(user, span_warning("Ты не даёшь согласие на такое."))
				return FALSE
			if(target.client && target.client.prefs.unholypref == "No")
				if(!silent)
					to_chat(user, span_warning("[target] не даёт согласие на такое."))
				return FALSE
	return TRUE

/datum/interaction/custom/proc/get_message_style()
	switch(interaction_type)
		if(CUSTOM_INTERACTION_TYPE_LEWD, CUSTOM_INTERACTION_TYPE_EXTREME, CUSTOM_INTERACTION_TYPE_UNHOLY)
			return "lewd"
	return "notice"

/datum/interaction/custom/proc/get_random_message_variant()
	var/list/variants = list()
	for(var/variant in splittext(message, "/"))
		var/trimmed = trim(variant)
		if(trimmed)
			variants += trimmed
	return length(variants) ? pick(variants) : message

/datum/interaction/custom/do_action(mob/living/user, mob/living/target, apply_cooldown = TRUE, is_hidden = FALSE)
	if(QDELETED(user) || QDELETED(target) || !name || !message)
		return FALSE
	if(!check_requirements(user, target, silent = FALSE))
		return FALSE
	if(get_dist(user, target) > max_distance)
		to_chat(user, span_warning("Слишком далеко."))
		return FALSE
	if(max_distance == 1 && !(user.Adjacent(target) && target.Adjacent(user)))
		to_chat(user, span_warning("Ты не достаёшь."))
		return FALSE
	var/vision_distance = 7
	var/hidden_message
	if(is_hidden)
		vision_distance = 1
		hidden_message = pick(hidden_additional)
	var/use_message = get_random_message_variant()
	use_message = replacetext(use_message, "USER", "<b>\the [user]</b>")
	use_message = replacetext(use_message, "TARGET", "<b>\the [target]</b>")
	var/is_lewd = interaction_type != CUSTOM_INTERACTION_TYPE_NORMAL
	user.visible_message(
		"<span class='[get_message_style()]'>[hidden_message][capitalize(use_message)]</span>",
		vision_distance = vision_distance,
		ignored_mobs = is_lewd ? user.get_unconsenting(get_interaction_flags()) : null
	)
	if(is_lewd)
		if(!HAS_TRAIT(user, TRAIT_LEWD_JOB) && !is_hidden)
			new /obj/effect/temp_visual/heart(user.loc)
		if(user != target && !HAS_TRAIT(target, TRAIT_LEWD_JOB) && !is_hidden)
			new /obj/effect/temp_visual/heart(target.loc)
	var/lust_amount = get_lust_amount()
	if(lust_amount && !QDELETED(user))
		if(self_orgasm)
			user.handle_post_sex(lust_amount, null, user == target ? null : target)
		else
			user.add_lust(lust_amount)
			try_moan(user)
	var/partner_lust_amount = get_lust_amount(partner_arousal_level)
	if(partner_lust_amount && !QDELETED(target))
		if(partner_orgasm)
			target.handle_post_sex(partner_lust_amount, null, target == user ? null : user)
		else
			target.add_lust(partner_lust_amount)
			try_moan(target)
	if(apply_cooldown)
		COOLDOWN_START(user, last_interaction_time, 0.5 SECONDS)
	if(user != target)
		SEND_SIGNAL(user, COMSIG_INTERACTION_ADJACENT, target)
		SEND_SIGNAL(target, COMSIG_INTERACTION_ADJACENT, user)
	return TRUE

/datum/controller/subsystem/processing/interactions/proc/get_custom_interaction(mob/living/owner_mob, key)
	if(!owner_mob?.client?.prefs || findtext(key, CUSTOM_INTERACTION_PREFIX) != 1)
		return null
	var/index = text2num(copytext(key, findlasttext(key, ":") + 1))
	var/list/customs = owner_mob.client.prefs.custom_interactions
	if(!length(customs) || !index || index > length(customs))
		return null
	var/datum/interaction/custom/custom = customs[index]
	if(!custom?.name || !custom.message)
		return null
	custom.custom_interaction_key = key
	return custom
