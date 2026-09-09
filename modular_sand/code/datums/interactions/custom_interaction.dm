/datum/preferences
	var/list/custom_interactions
	var/custom_verb_consent = TRUE

	var/show_heart_over_self = TRUE
	var/interaction_effect = INTERACTION_EFFECT_HEART
	var/block_partner_pixel_shift = FALSE
	var/panel_tab_toggles = ALL_INTERACTION_MENU_TABS
	var/dynamic_window_size = FALSE
	var/compact_custom_tab = FALSE

/datum/preferences/proc/get_custom_interaction_limit()
	var/user_ckey = parent?.ckey
	if(user_ckey && is_donator_group(user_ckey, DONATOR_GROUP_TIER_2))
		return MAX_CUSTOM_INTERACTIONS_SPONSOR
	if(user_ckey && is_donator_group(user_ckey, DONATOR_GROUP_TIER_1))
		return MAX_CUSTOM_INTERACTIONS_SUBSCRIBER
	return MAX_CUSTOM_INTERACTIONS

#define CUSTOM_SOUND_GROUP_NONE "Без звука"
#define CUSTOM_SOUND_GROUP_SPECIAL "Unholy"
#define CUSTOM_SOUND_GROUP_THRUSTS "Толчки"
#define CUSTOM_SOUND_GROUP_BLOWJOB "Минет"
#define CUSTOM_SOUND_GROUP_SMACKING "Чавканье"
#define CUSTOM_SOUND_GROUP_WET "Влажные звуки"
#define CUSTOM_SOUND_GROUP_FEET "Ноги"
#define CUSTOM_SOUND_GROUP_AFFECTION "Объятия и поцелуи"
#define CUSTOM_SOUND_GROUP_MOANS "Стоны"
#define CUSTOM_SOUND_GROUP_PURRS "Мурлыканье"
#define CUSTOM_SOUND_GROUP_MISC "Прочее"

#define CUSTOM_SOUND_GROUPS_NORMAL list(CUSTOM_SOUND_GROUP_MISC, CUSTOM_SOUND_GROUP_AFFECTION, CUSTOM_SOUND_GROUP_PURRS)

GLOBAL_LIST_INIT(custom_interaction_sounds, list(
	CUSTOM_INTERACTION_SOUND_NONE = list("label" = "Без звука", "group" = CUSTOM_SOUND_GROUP_NONE, "file" = null),

	"asscrap1" = list("label" = "Хлопок 1", "group" = CUSTOM_SOUND_GROUP_SPECIAL, "file" = 'modular_sand/sound/interactions/asscrap1.ogg'),
	"asscrap2" = list("label" = "Хлопок 2", "group" = CUSTOM_SOUND_GROUP_SPECIAL, "file" = 'modular_sand/sound/interactions/asscrap2.ogg'),
	"asscrap3" = list("label" = "Хлопок 3", "group" = CUSTOM_SOUND_GROUP_SPECIAL, "file" = 'modular_sand/sound/interactions/asscrap3.ogg'),
	"squelch3" = list("label" = "Хлюп 3", "group" = CUSTOM_SOUND_GROUP_SPECIAL, "file" = 'modular_sand/sound/interactions/squelch3.ogg'),

	"bang1" = list("label" = "Толчок 1", "group" = CUSTOM_SOUND_GROUP_THRUSTS, "file" = 'modular_sand/sound/interactions/bang1.ogg'),
	"bang2" = list("label" = "Толчок 2", "group" = CUSTOM_SOUND_GROUP_THRUSTS, "file" = 'modular_sand/sound/interactions/bang2.ogg'),
	"bang3" = list("label" = "Толчок 3", "group" = CUSTOM_SOUND_GROUP_THRUSTS, "file" = 'modular_sand/sound/interactions/bang3.ogg'),
	"bang4" = list("label" = "Толчок 4", "group" = CUSTOM_SOUND_GROUP_THRUSTS, "file" = 'modular_sand/sound/interactions/bang4.ogg'),
	"bang5" = list("label" = "Толчок 5", "group" = CUSTOM_SOUND_GROUP_THRUSTS, "file" = 'modular_sand/sound/interactions/bang5.ogg'),
	"bang6" = list("label" = "Толчок 6", "group" = CUSTOM_SOUND_GROUP_THRUSTS, "file" = 'modular_sand/sound/interactions/bang6.ogg'),

	"bj1" = list("label" = "Минет 1", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj1.ogg'),
	"bj2" = list("label" = "Минет 2", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj2.ogg'),
	"bj3" = list("label" = "Минет 3", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj3.ogg'),
	"bj4" = list("label" = "Минет 4", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj4.ogg'),
	"bj5" = list("label" = "Минет 5", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj5.ogg'),
	"bj6" = list("label" = "Минет 6", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj6.ogg'),
	"bj7" = list("label" = "Минет 7", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj7.ogg'),
	"bj8" = list("label" = "Минет 8", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj8.ogg'),
	"bj9" = list("label" = "Минет 9", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj9.ogg'),
	"bj10" = list("label" = "Минет 10", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj10.ogg'),
	"bj11" = list("label" = "Минет 11", "group" = CUSTOM_SOUND_GROUP_BLOWJOB, "file" = 'modular_sand/sound/interactions/bj11.ogg'),

	"champ1" = list("label" = "Чавканье 1", "group" = CUSTOM_SOUND_GROUP_SMACKING, "file" = 'modular_sand/sound/interactions/champ1.ogg'),
	"champ2" = list("label" = "Чавканье 2", "group" = CUSTOM_SOUND_GROUP_SMACKING, "file" = 'modular_sand/sound/interactions/champ2.ogg'),
	"champ_fingering" = list("label" = "Чавканье (пальцы)", "group" = CUSTOM_SOUND_GROUP_SMACKING, "file" = 'modular_sand/sound/interactions/champ_fingering.ogg'),

	"squelch1" = list("label" = "Хлюп 1", "group" = CUSTOM_SOUND_GROUP_WET, "file" = 'modular_sand/sound/interactions/squelch1.ogg'),
	"squelch2" = list("label" = "Хлюп 2", "group" = CUSTOM_SOUND_GROUP_WET, "file" = 'modular_sand/sound/interactions/squelch2.ogg'),
	"oral1" = list("label" = "Влажный 1", "group" = CUSTOM_SOUND_GROUP_WET, "file" = 'modular_sand/sound/interactions/oral1.ogg'),
	"oral2" = list("label" = "Влажный 2", "group" = CUSTOM_SOUND_GROUP_WET, "file" = 'modular_sand/sound/interactions/oral2.ogg'),
	"swallow" = list("label" = "Глотание", "group" = CUSTOM_SOUND_GROUP_WET, "file" = 'modular_sand/sound/interactions/swallow.ogg'),

	"foot_dry1" = list("label" = "Сухие ноги 1", "group" = CUSTOM_SOUND_GROUP_FEET, "file" = 'modular_sand/sound/interactions/foot_dry1.ogg'),
	"foot_dry2" = list("label" = "Сухие ноги 2", "group" = CUSTOM_SOUND_GROUP_FEET, "file" = 'modular_sand/sound/interactions/foot_dry2.ogg'),
	"foot_dry3" = list("label" = "Сухие ноги 3", "group" = CUSTOM_SOUND_GROUP_FEET, "file" = 'modular_sand/sound/interactions/foot_dry3.ogg'),
	"foot_dry4" = list("label" = "Сухие ноги 4", "group" = CUSTOM_SOUND_GROUP_FEET, "file" = 'modular_sand/sound/interactions/foot_dry4.ogg'),
	"foot_wet1" = list("label" = "Мокрые ноги 1", "group" = CUSTOM_SOUND_GROUP_FEET, "file" = 'modular_sand/sound/interactions/foot_wet1.ogg'),
	"foot_wet2" = list("label" = "Мокрые ноги 2", "group" = CUSTOM_SOUND_GROUP_FEET, "file" = 'modular_sand/sound/interactions/foot_wet2.ogg'),
	"foot_wet3" = list("label" = "Мокрые ноги 3", "group" = CUSTOM_SOUND_GROUP_FEET, "file" = 'modular_sand/sound/interactions/foot_wet3.ogg'),

	"hug" = list("label" = "Объятия", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_sand/sound/interactions/hug.ogg'),
	"kiss1" = list("label" = "Поцелуй 1", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_sand/sound/interactions/kiss1.ogg'),
	"kiss2" = list("label" = "Поцелуй 2", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_sand/sound/interactions/kiss2.ogg'),
	"kiss3" = list("label" = "Поцелуй 3", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_sand/sound/interactions/kiss3.ogg'),
	"kiss4" = list("label" = "Поцелуй 4", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_sand/sound/interactions/kiss4.ogg'),
	"kiss5" = list("label" = "Поцелуй 5", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_sand/sound/interactions/kiss5.ogg'),

	"moan_f1" = list("label" = "Стон (ж) 1", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f1.ogg'),
	"moan_f2" = list("label" = "Стон (ж) 2", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f2.ogg'),
	"moan_f3" = list("label" = "Стон (ж) 3", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f3.ogg'),
	"moan_f4" = list("label" = "Стон (ж) 4", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f4.ogg'),
	"moan_f5" = list("label" = "Стон (ж) 5", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f5.ogg'),
	"moan_f6" = list("label" = "Стон (ж) 6", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f6.ogg'),
	"moan_f7" = list("label" = "Стон (ж) 7", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f7.ogg'),
	"moan_m1" = list("label" = "Стон (м) 1", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_m1.ogg'),
	"moan_m2" = list("label" = "Стон (м) 2", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_m2.ogg'),
	"moan_m3" = list("label" = "Стон (м) 3", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_m3.ogg'),
	"under_moan_f1" = list("label" = "Приглушённый стон (ж) 1", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/under_moan_f1.ogg'),
	"under_moan_f2" = list("label" = "Приглушённый стон (ж) 2", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/under_moan_f2.ogg'),
	"under_moan_f3" = list("label" = "Приглушённый стон (ж) 3", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/under_moan_f3.ogg'),
	"under_moan_f4" = list("label" = "Приглушённый стон (ж) 4", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/under_moan_f4.ogg'),
	"final_f1" = list("label" = "Финал (ж) 1", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_f1.ogg'),
	"final_f2" = list("label" = "Финал (ж) 2", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_f2.ogg'),
	"final_f3" = list("label" = "Финал (ж) 3", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_f3.ogg'),
	"final_m1" = list("label" = "Финал (м) 1", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_m1.ogg'),
	"final_m2" = list("label" = "Финал (м) 2", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_m2.ogg'),
	"final_m3" = list("label" = "Финал (м) 3", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_m3.ogg'),
	"final_m4" = list("label" = "Финал (м) 4", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_m4.ogg'),
	"final_m5" = list("label" = "Финал (м) 5", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_m5.ogg'),

	"purr1" = list("label" = "Мурлыканье 1", "group" = CUSTOM_SOUND_GROUP_PURRS, "file" = 'modular_sand/sound/interactions/purr1.ogg'),
	"purr2" = list("label" = "Мурлыканье 2", "group" = CUSTOM_SOUND_GROUP_PURRS, "file" = 'modular_sand/sound/interactions/purr2.ogg'),
	"purr3" = list("label" = "Мурлыканье 3", "group" = CUSTOM_SOUND_GROUP_PURRS, "file" = 'modular_sand/sound/interactions/purr3.ogg'),

	"slap" = list("label" = "Шлепок", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'modular_sand/sound/interactions/slap.ogg'),
	"whistle" = list("label" = "Свист", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'modular_bluemoon/sound/emotes/svist.ogg'),
	"applause" = list("label" = "Салютование", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'sound/voice/salute.ogg'),
	"clawcum1" = list("label" = "Коготь 1", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'modular_sand/sound/interactions/clawcum1.ogg'),
	"clawcum2" = list("label" = "Коготь 2", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'modular_sand/sound/interactions/clawcum2.ogg'),
))

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
	var/list/sound_keys = list()

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

/datum/interaction/custom/proc/get_sound_labels()
	var/list/labels = list()
	for(var/key in sound_keys)
		var/list/sound_data = GLOB.custom_interaction_sounds[key]
		if(sound_data)
			labels += sound_data["label"]
	return labels

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
	required_body_parts = sanitize_integer(required_body_parts, 0, CUSTOM_INTERACTION_BODY_PART_MASK, 0) & CUSTOM_INTERACTION_BODY_PART_MASK
	requires_tail = !!requires_tail
	requires_telekinesis = !!requires_telekinesis
	max_distance = sanitize_integer(max_distance, 1, 3, 1)
	sanitize_sound_keys()

/datum/interaction/custom/proc/sanitize_sound_keys()
	sound_keys = SANITIZE_LIST(sound_keys)
	for(var/i in length(sound_keys) to 1 step -1)
		var/key = sound_keys[i]
		var/list/sound_data = GLOB.custom_interaction_sounds[key]
		if(!sound_data || key == CUSTOM_INTERACTION_SOUND_NONE)
			sound_keys.Cut(i, i + 1)
			continue
		var/sound_group = sound_data["group"]
		if(sound_group == CUSTOM_SOUND_GROUP_SPECIAL && interaction_type != CUSTOM_INTERACTION_TYPE_UNHOLY)
			sound_keys.Cut(i, i + 1)
			continue
		if(interaction_type == CUSTOM_INTERACTION_TYPE_NORMAL && !(sound_group in CUSTOM_SOUND_GROUPS_NORMAL))
			sound_keys.Cut(i, i + 1)

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

/datum/interaction/custom/proc/pass_requirement_gate(mob/living/custom_owner, mob/living/target)
	if(requires_tail && !(custom_owner.has_tail() || (target && target.has_tail())))
		return FALSE
	if(requires_telekinesis && !(has_telekinesis(custom_owner) || (target && has_telekinesis(target))))
		return FALSE
	for(var/requirement in CUSTOM_INTERACTION_BODY_PART_REQUIREMENTS)
		if(!(required_body_parts & requirement))
			continue
		if(!is_body_part_exposed(custom_owner, requirement) && !(target && is_body_part_exposed(target, requirement)))
			return FALSE
	switch(scope)
		if(CUSTOM_INTERACTION_SCOPE_SELF)
			return custom_owner == target
		if(CUSTOM_INTERACTION_SCOPE_OTHERS)
			return custom_owner != target
		else
			return TRUE

/datum/interaction/custom/proc/check_requirements(mob/living/user, mob/living/target, silent = TRUE)
	if(requires_tail && !(user.has_tail() || (target && target.has_tail())))
		if(!silent)
			to_chat(user, span_warning("Требования для этого действия не выполнены: нужен хвост у кого-то из вас."))
		return FALSE
	if(requires_telekinesis && !(has_telekinesis(user) || (target && has_telekinesis(target))))
		if(!silent)
			to_chat(user, span_warning("Требования для этого действия не выполнены: нужен телекинез у кого-то из вас."))
		return FALSE
	if(required_body_parts)
		var/all_parts_missing = TRUE
		for(var/requirement in CUSTOM_INTERACTION_BODY_PART_REQUIREMENTS)
			if(!(required_body_parts & requirement))
				continue
			if(is_body_part_exposed(user, requirement) || (target && is_body_part_exposed(target, requirement)))
				all_parts_missing = FALSE
				break
		if(all_parts_missing)
			if(!silent)
				to_chat(user, span_warning("Требования для этого действия не выполнены: [get_body_parts_label()] у кого-то из вас."))
			return FALSE
	var/mob/living/custom_owner
	if(findtext(custom_interaction_key, user?.ckey))
		custom_owner = user
	else if(findtext(custom_interaction_key, target?.ckey))
		custom_owner = target

	if(!custom_owner)
		return FALSE
	if(scope == CUSTOM_INTERACTION_SCOPE_SELF && custom_owner != target)
		if(!silent)
			to_chat(user, span_warning("Это действие доступно только на себе."))
		return FALSE
	if(scope == CUSTOM_INTERACTION_SCOPE_OTHERS && custom_owner == target)
		if(!silent)
			to_chat(user, span_warning("Это действие доступно только на других."))
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
					to_chat(user, span_warning("Ты не даёшь согласие на сексуальное насилие."))
				return FALSE
			if(target.client && target.client.prefs.unholypref == "No")
				if(!silent)
					to_chat(user, span_warning("[target] не даёт согласие на сексуальное насилие."))
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
		user.try_play_interaction_effect(is_hidden)
		if(user != target)
			target.try_play_interaction_effect(is_hidden)
	if(length(sound_keys))
		var/chosen_sound_key = pick(sound_keys)
		var/list/sound_data = GLOB.custom_interaction_sounds[chosen_sound_key]
		var/soundfile = sound_data?["file"]
		if(soundfile)
			var/turf/sound_turf = get_turf(user)
			if(sound_turf)
				var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
				if(is_lewd)
					playlewdinteractionsound(sound_turf, soundfile, interaction_sound_volume, 1, extrarange, ignored_mobs = user.get_unconsenting(get_interaction_flags()))
				else
					playsound(sound_turf, soundfile, interaction_sound_volume, 1, extrarange)
	var/lust_amount = get_lust_amount()
	if(!QDELETED(user))
		if(self_orgasm)
			user.handle_post_sex(lust_amount, null, user == target ? null : target)
		else if(lust_amount)
			user.add_lust(lust_amount)
			try_moan(user)
	var/partner_lust_amount = get_lust_amount(partner_arousal_level)
	if(!QDELETED(target))
		if(partner_orgasm)
			target.handle_post_sex(partner_lust_amount, null, target == user ? null : user)
		else if(partner_lust_amount)
			target.add_lust(partner_lust_amount)
			try_moan(target)
	if(apply_cooldown)
		COOLDOWN_START(user, last_interaction_time, 0.5 SECONDS)
	if(user != target)
		SEND_SIGNAL(user, COMSIG_INTERACTION_ADJACENT, target)
		SEND_SIGNAL(target, COMSIG_INTERACTION_ADJACENT, user)

	// logs
	user.log_message("Применяет[is_hidden ? " (скрытно)" : null] Custom интеракцию к [user == target ? "себе" : target]: «[use_message]»", LOG_ATTACK)
	if(user != target)
		target.log_message("Подвергся[is_hidden ? " (скрытно)" : null] Custom интеракции от [user]: «[use_message]»", LOG_VICTIM, log_globally = FALSE)
	return TRUE

/datum/controller/subsystem/processing/interactions/proc/get_custom_interaction(mob/living/user, mob/living/target, key)
	if(!findtext(key, CUSTOM_INTERACTION_PREFIX))
		return

	var/mob/living/custom_owner
	if(findtext(key, user?.ckey))
		custom_owner = user
	else if(findtext(key, target?.ckey))
		custom_owner = target

	if(!custom_owner?.client?.prefs)
		return
	var/index = text2num(copytext(key, findlasttext(key, ":") + 1))
	var/list/customs = custom_owner.client.prefs.custom_interactions
	if(!length(customs) || !index || index > length(customs))
		return
	var/datum/interaction/custom/custom = customs[index]
	if(!custom?.name || !custom.message)
		return
	custom.custom_interaction_key = key
	return custom
