/datum/preferences
	var/list/custom_interactions
	var/custom_verb_consent = TRUE

	var/show_heart_over_self = TRUE
	var/interaction_effect = INTERACTION_EFFECT_HEART
	var/block_partner_pixel_shift = FALSE
	var/panel_tab_toggles = ALL_INTERACTION_MENU_TABS
	var/dynamic_window_size = TRUE
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

	"asscrap1" = list("label" = "Хлопок 1", "group" = CUSTOM_SOUND_GROUP_SPECIAL, "file" = 'modular_bluemoon/sound/interactions/asscrap1.ogg'),
	"asscrap2" = list("label" = "Хлопок 2", "group" = CUSTOM_SOUND_GROUP_SPECIAL, "file" = 'modular_bluemoon/sound/interactions/asscrap2.ogg'),
	"asscrap3" = list("label" = "Хлопок 3", "group" = CUSTOM_SOUND_GROUP_SPECIAL, "file" = 'modular_bluemoon/sound/interactions/asscrap3.ogg'),
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
	"champ_fingering" = list("label" = "Чавканье (пальцы)", "group" = CUSTOM_SOUND_GROUP_SMACKING, "file" = 'modular_sand/sound/lewd/champ_fingering.ogg'),

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
	"kiss1" = list("label" = "Поцелуй 1", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_splurt/sound/interactions/kiss/kiss1.ogg'),
	"kiss2" = list("label" = "Поцелуй 2", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_splurt/sound/interactions/kiss/kiss2.ogg'),
	"kiss3" = list("label" = "Поцелуй 3", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_splurt/sound/interactions/kiss/kiss3.ogg'),
	"kiss4" = list("label" = "Поцелуй 4", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_splurt/sound/interactions/kiss/kiss4.ogg'),
	"kiss5" = list("label" = "Поцелуй 5", "group" = CUSTOM_SOUND_GROUP_AFFECTION, "file" = 'modular_sand/sound/interactions/kiss5.ogg'),

	"moan_f1" = list("label" = "Стон (ж) 1", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f1.ogg'),
	"moan_f2" = list("label" = "Стон (ж) 2", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f2.ogg'),
	"moan_f3" = list("label" = "Стон (ж) 3", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f3.ogg'),
	"moan_f4" = list("label" = "Стон (ж) 4", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f4.ogg'),
	"moan_f5" = list("label" = "Стон (ж) 5", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f5.ogg'),
	"moan_f6" = list("label" = "Стон (ж) 6", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f6.ogg'),
	"moan_f7" = list("label" = "Стон (ж) 7", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/moan_f7.ogg'),
	"moan_m1" = list("label" = "Стон (м) 1", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_m1.ogg'),
	"moan_m2" = list("label" = "Стон (м) 2", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_m2.ogg'),
	"moan_m3" = list("label" = "Стон (м) 3", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_m3.ogg'),
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
	"final_m4" = list("label" = "Финал (м) 4", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_m2.ogg'),
	"final_m5" = list("label" = "Финал (м) 5", "group" = CUSTOM_SOUND_GROUP_MOANS, "file" = 'modular_sand/sound/interactions/final_m3.ogg'),

	"purr1" = list("label" = "Мурлыканье 1", "group" = CUSTOM_SOUND_GROUP_PURRS, "file" = 'modular_sand/sound/interactions/purr1.ogg'),
	"purr2" = list("label" = "Мурлыканье 2", "group" = CUSTOM_SOUND_GROUP_PURRS, "file" = 'modular_sand/sound/interactions/purr2.ogg'),
	"purr3" = list("label" = "Мурлыканье 3", "group" = CUSTOM_SOUND_GROUP_PURRS, "file" = 'modular_sand/sound/interactions/purr3.ogg'),

	"slap" = list("label" = "Шлепок", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'sound/effects/snap.ogg'),
	"tail_slap" = list("label" = "Шлепок хвостом", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'sound/effects/tail_slap.ogg'),
	"whistle" = list("label" = "Свист", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'modular_bluemoon/sound/emotes/svist.ogg'),
	"applause" = list("label" = "Салютование", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'sound/voice/salute.ogg'),
	"clawcum1" = list("label" = "Коготь 1", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'modular_splurt/sound/lewd/deathclaw1.ogg'),
	"clawcum2" = list("label" = "Коготь 2", "group" = CUSTOM_SOUND_GROUP_MISC, "file" = 'modular_splurt/sound/lewd/deathclaw2.ogg'),
))

GLOBAL_LIST_INIT(custom_interaction_body_parts, list(
	"[INTERACTION_REQUIRE_ANUS]" = "Анус",
	"[INTERACTION_REQUIRE_BALLS]" = "Яички",
	"[INTERACTION_REQUIRE_BREASTS]" = "Грудь",
	"[INTERACTION_REQUIRE_BELLY]" = "Живот",
	"[INTERACTION_REQUIRE_EARS]" = "Уши",
	"[INTERACTION_REQUIRE_EYES]" = "Глаза",
	"[INTERACTION_REQUIRE_FEET]" = "Стопы",
	"[INTERACTION_REQUIRE_PENIS]" = "Член",
	"[INTERACTION_REQUIRE_VAGINA]" = "Влагалище",
	"[INTERACTION_REQUIRE_TAIL]" = "Хвост",
	"[INTERACTION_REQUIRE_HANDS]" = "Руки",
	"[INTERACTION_REQUIRE_MOUTH]" = "Рот",
))

GLOBAL_LIST_INIT(custom_interaction_arousal_organs, list(
	CUSTOM_INTERACTION_AROUSAL_GENERAL = NONE,
	ORGAN_SLOT_ANUS = INTERACTION_REQUIRE_ANUS,
	ORGAN_SLOT_TESTICLES = INTERACTION_REQUIRE_BALLS,
	ORGAN_SLOT_BREASTS = INTERACTION_REQUIRE_BREASTS,
	ORGAN_SLOT_BELLY = INTERACTION_REQUIRE_BELLY,
	ORGAN_SLOT_PENIS = INTERACTION_REQUIRE_PENIS,
	ORGAN_SLOT_VAGINA = INTERACTION_REQUIRE_VAGINA,
))

GLOBAL_LIST_INIT(custom_interaction_orgasm_organs, list(
	CUSTOM_INTERACTION_ORGASM_AUTO = NONE,
	ORGAN_SLOT_PENIS = INTERACTION_REQUIRE_PENIS,
	ORGAN_SLOT_VAGINA = INTERACTION_REQUIRE_VAGINA,
))

GLOBAL_LIST_INIT(custom_interaction_orgasm_targets, list(
	CUSTOM_INTERACTION_ORGASM_FLOOR = list("label" = "На пол", "flag" = NONE),
	CUM_TARGET_MOUTH = list("label" = "В рот", "flag" = INTERACTION_REQUIRE_MOUTH),
	CUM_TARGET_THROAT = list("label" = "В горло", "flag" = INTERACTION_REQUIRE_MOUTH),
	CUM_TARGET_HAND = list("label" = "На руки", "flag" = INTERACTION_REQUIRE_HANDS),
	CUM_TARGET_FEET = list("label" = "На стопы", "flag" = INTERACTION_REQUIRE_FEET),
	CUM_TARGET_BREASTS = list("label" = "На грудь", "flag" = INTERACTION_REQUIRE_BREASTS),
	CUM_TARGET_BELLY = list("label" = "На живот", "flag" = INTERACTION_REQUIRE_BELLY),
	CUM_TARGET_PENIS = list("label" = "На член", "flag" = INTERACTION_REQUIRE_PENIS),
	CUM_TARGET_VAGINA = list("label" = "Во влагалище", "flag" = INTERACTION_REQUIRE_VAGINA),
	CUM_TARGET_ANUS = list("label" = "В анус", "flag" = INTERACTION_REQUIRE_ANUS),
	CUM_TARGET_EARS = list("label" = "На уши", "flag" = INTERACTION_REQUIRE_EARS),
	CUM_TARGET_EYES = list("label" = "На глаза", "flag" = INTERACTION_REQUIRE_EYES),
	CUM_TARGET_TAIL = list("label" = "На хвост", "flag" = INTERACTION_REQUIRE_TAIL),
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
	var/list/sound_keys = list()
	var/self_required_body_parts = NONE
	var/partner_required_body_parts = NONE
	var/self_arousal_organ = CUSTOM_INTERACTION_AROUSAL_GENERAL
	var/partner_arousal_organ = CUSTOM_INTERACTION_AROUSAL_GENERAL
	var/self_orgasm_target = CUSTOM_INTERACTION_ORGASM_FLOOR
	var/partner_orgasm_target = CUSTOM_INTERACTION_ORGASM_FLOOR
	var/self_orgasm_organ = CUSTOM_INTERACTION_ORGASM_AUTO
	var/partner_orgasm_organ = CUSTOM_INTERACTION_ORGASM_AUTO
	var/self_requires_tail = FALSE
	var/partner_requires_tail = FALSE
	var/self_requires_telekinesis = FALSE
	var/partner_requires_telekinesis = FALSE
	var/requires_review = FALSE

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
		if(INTERACTION_REQUIRE_HANDS)
			return M.has_hand() == HAS_EXPOSED_GENITAL
		if(INTERACTION_REQUIRE_MOUTH)
			return M.has_mouth() && M.mouth_is_free()
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
	return FALSE

/datum/interaction/custom/proc/get_required_body_parts(for_partner = FALSE)
	var/arousal_organ = for_partner ? partner_arousal_organ : self_arousal_organ
	var/orgasm_organ = for_partner ? partner_orgasm_organ : self_orgasm_organ
	var/orgasm_target = for_partner ? self_orgasm_target : partner_orgasm_target
	var/list/target_info = GLOB.custom_interaction_orgasm_targets[orgasm_target]
	var/requirements = for_partner ? partner_required_body_parts : self_required_body_parts
	return requirements | GLOB.custom_interaction_arousal_organs[arousal_organ] | GLOB.custom_interaction_orgasm_organs[orgasm_organ] | target_info["flag"]

/datum/interaction/custom/proc/get_body_parts_label(requirements)
	var/list/labels = list()
	for(var/flag in GLOB.custom_interaction_body_parts)
		if(requirements & text2num(flag))
			labels += lowertext(GLOB.custom_interaction_body_parts[flag])
	return jointext(labels, ", ")

/datum/interaction/custom/proc/sanitize_values()
	name = copytext(strip_html(name), 1, MAX_CUSTOM_INTERACTION_NAME_LENGTH + 1)
	message = copytext(strip_html(message), 1, MAX_CUSTOM_INTERACTION_MESSAGE_LENGTH + 1)
	sanitize_settings()

/datum/interaction/custom/proc/sanitize_settings()
	interaction_type = sanitize_inlist(interaction_type, CUSTOM_INTERACTION_TYPES, CUSTOM_INTERACTION_TYPE_NORMAL)
	arousal_level = sanitize_integer(arousal_level, CUSTOM_AROUSAL_NONE, CUSTOM_AROUSAL_MAX, CUSTOM_AROUSAL_NONE)
	partner_arousal_level = sanitize_integer(partner_arousal_level, CUSTOM_AROUSAL_NONE, CUSTOM_AROUSAL_MAX, CUSTOM_AROUSAL_NONE)
	self_orgasm = arousal_level > CUSTOM_AROUSAL_NONE && !!self_orgasm
	partner_orgasm = partner_arousal_level > CUSTOM_AROUSAL_NONE && !!partner_orgasm
	scope = sanitize_inlist(scope, CUSTOM_INTERACTION_SCOPES, CUSTOM_INTERACTION_SCOPE_BOTH)
	self_required_body_parts = sanitize_integer(self_required_body_parts, 0, CUSTOM_INTERACTION_BODY_PART_MASK, 0) & CUSTOM_INTERACTION_BODY_PART_MASK
	partner_required_body_parts = sanitize_integer(partner_required_body_parts, 0, CUSTOM_INTERACTION_BODY_PART_MASK, 0) & CUSTOM_INTERACTION_BODY_PART_MASK
	self_arousal_organ = sanitize_inlist(arousal_level ? self_arousal_organ : null, GLOB.custom_interaction_arousal_organs, CUSTOM_INTERACTION_AROUSAL_GENERAL)
	partner_arousal_organ = sanitize_inlist(partner_arousal_level ? partner_arousal_organ : null, GLOB.custom_interaction_arousal_organs, CUSTOM_INTERACTION_AROUSAL_GENERAL)
	self_orgasm_target = sanitize_inlist(self_orgasm ? self_orgasm_target : null, GLOB.custom_interaction_orgasm_targets, CUSTOM_INTERACTION_ORGASM_FLOOR)
	partner_orgasm_target = sanitize_inlist(partner_orgasm ? partner_orgasm_target : null, GLOB.custom_interaction_orgasm_targets, CUSTOM_INTERACTION_ORGASM_FLOOR)
	self_orgasm_organ = sanitize_inlist(self_orgasm ? self_orgasm_organ : null, GLOB.custom_interaction_orgasm_organs, CUSTOM_INTERACTION_ORGASM_AUTO)
	partner_orgasm_organ = sanitize_inlist(partner_orgasm ? partner_orgasm_organ : null, GLOB.custom_interaction_orgasm_organs, CUSTOM_INTERACTION_ORGASM_AUTO)
	self_requires_tail = !!self_requires_tail
	self_requires_telekinesis = !!self_requires_telekinesis
	partner_requires_tail = !!partner_requires_tail
	partner_requires_telekinesis = !!partner_requires_telekinesis
	max_distance = (self_requires_telekinesis || partner_requires_telekinesis) ? sanitize_integer(max_distance, 1, 3, 1) : 1
	sanitize_sound_keys()

/datum/interaction/custom/proc/update_from_editor(new_name, new_message, list/params)
	name = new_name
	message = new_message
	interaction_type = params["interaction_type"]
	arousal_level = text2num(params["arousal_level"])
	partner_arousal_level = text2num(params["partner_arousal_level"])
	self_orgasm = text2num(params["self_orgasm"])
	partner_orgasm = text2num(params["partner_orgasm"])
	scope = sanitize_inlist(params["scope"], CUSTOM_INTERACTION_SCOPES, scope)
	self_required_body_parts = text2num(params["self_required_body_parts"])
	partner_required_body_parts = text2num(params["partner_required_body_parts"])
	self_arousal_organ = params["self_arousal_organ"]
	partner_arousal_organ = params["partner_arousal_organ"]
	self_orgasm_target = params["self_orgasm_target"]
	partner_orgasm_target = params["partner_orgasm_target"]
	self_orgasm_organ = params["self_orgasm_organ"]
	partner_orgasm_organ = params["partner_orgasm_organ"]
	self_requires_tail = text2num(params["self_requires_tail"])
	partner_requires_tail = text2num(params["partner_requires_tail"])
	self_requires_telekinesis = text2num(params["self_requires_telekinesis"])
	partner_requires_telekinesis = text2num(params["partner_requires_telekinesis"])
	max_distance = text2num(params["max_distance"])
	sound_keys = params["sound_keys"]
	sanitize_settings()

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

/datum/interaction/custom/proc/check_exposed_parts(mob/living/participant, requirements)
	for(var/flag = INTERACTION_REQUIRE_HANDS; flag <= requirements; flag <<= 1)
		if((requirements & flag) && !is_body_part_exposed(participant, flag))
			return FALSE
	return TRUE

/datum/interaction/custom/proc/pass_requirement_gate(mob/living/user, mob/living/target, mob/living/custom_owner, silent = TRUE)
	if(requires_review)
		return FALSE
	if(scope == CUSTOM_INTERACTION_SCOPE_SELF && custom_owner != target)
		if(!silent)
			to_chat(user, span_warning("Это действие доступно только на себе."))
		return FALSE
	if(scope == CUSTOM_INTERACTION_SCOPE_OTHERS && custom_owner == target)
		if(!silent)
			to_chat(user, span_warning("Это действие доступно только на других."))
		return FALSE
	if(self_requires_tail && !user.has_tail())
		if(!silent)
			to_chat(user, span_warning("У тебя должен быть хвост."))
		return FALSE
	if(partner_requires_tail && !target.has_tail())
		if(!silent)
			to_chat(user, span_warning("У партнёра должен быть хвост."))
		return FALSE
	if(self_requires_telekinesis && !has_telekinesis(user))
		if(!silent)
			to_chat(user, span_warning("У тебя должен быть телекинез."))
		return FALSE
	if(partner_requires_telekinesis && !has_telekinesis(target))
		if(!silent)
			to_chat(user, span_warning("У партнёра должен быть телекинез."))
		return FALSE
	var/self_parts = get_required_body_parts()
	if(!check_exposed_parts(user, self_parts))
		if(!silent)
			to_chat(user, span_warning("У тебя должны быть оголены: [get_body_parts_label(self_parts)]."))
		return FALSE
	var/partner_parts = get_required_body_parts(for_partner = TRUE)
	if(!check_exposed_parts(target, partner_parts))
		if(!silent)
			to_chat(user, span_warning("У цели должны быть оголены: [get_body_parts_label(partner_parts)]."))
		return FALSE
	return TRUE

/proc/custom_interaction_allows_distance(mob/living/user, mob/living/target, distance)
	return distance <= 1 || ((user.client?.prefs.toggles & RANGED_VERBS_CONSENT) && (!target.client || (target.client.prefs.toggles & RANGED_VERBS_CONSENT)))

/datum/interaction/custom/proc/check_requirements(mob/living/user, mob/living/target, silent = TRUE)
	var/mob/living/custom_owner = SSinteractions.get_custom_interaction_owner(user, target, custom_interaction_key)
	if(!custom_owner || !pass_requirement_gate(user, target, custom_owner, silent))
		return FALSE
	if(user.client && !user.client.prefs.custom_verb_consent)
		if(!silent)
			to_chat(user, span_warning("Ты отключил кастомные интеракты."))
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

/datum/interaction/custom/proc/get_random_message_variant()
	var/list/variants = list()
	for(var/variant in splittext(message, "/"))
		var/trimmed = trim(variant)
		if(trimmed)
			variants += trimmed
	return length(variants) ? pick(variants) : message

/datum/interaction/custom/proc/apply_effect(mob/living/recipient, mob/living/other, level, arousal_organ, allow_orgasm, orgasm_organ, orgasm_target)
	if(QDELETED(recipient))
		return
	var/amount = get_lust_amount(level)
	if(!amount)
		return
	var/organ = arousal_organ == CUSTOM_INTERACTION_AROUSAL_GENERAL ? null : arousal_organ
	if(allow_orgasm)
		var/orifice = orgasm_target == CUSTOM_INTERACTION_ORGASM_FLOOR ? null : orgasm_target
		var/mob/living/partner = QDELETED(other) || (!orifice && recipient == other) ? null : other
		if(orgasm_organ != CUSTOM_INTERACTION_ORGASM_AUTO || orifice)
			var/obj/item/organ/genital/source_organ
			if(orgasm_organ != CUSTOM_INTERACTION_ORGASM_AUTO)
				source_organ = recipient.getorganslot(orgasm_organ)
			else
				source_organ = recipient.getorganslot(ORGAN_SLOT_PENIS) || recipient.getorganslot(ORGAN_SLOT_VAGINA)
			if(orifice == CUM_TARGET_FEET && !source_organ)
				orifice = null
			if(recipient.last_lewd_datum || recipient.last_partner != partner || recipient.last_orifice != orifice || recipient.last_genital != source_organ)
				// Участники могут выбрать разные органы и цели.
				recipient.last_lewd_datum = null
				recipient.set_is_fucking(partner, orifice, source_organ, sub_set = TRUE)
		recipient.handle_post_sex(amount, orifice, partner, organ)
	else
		var/mob/living/carbon/carbon_recipient = recipient
		if(organ && istype(carbon_recipient))
			amount = carbon_recipient.check_stimulation(amount, organ)
		if(amount)
			recipient.add_lust(amount)
			try_moan(recipient)

/datum/interaction/custom/do_action(mob/living/user, mob/living/target, apply_cooldown = TRUE, is_hidden = FALSE)
	if(QDELETED(user) || QDELETED(target) || !name || !message)
		return FALSE
	if(!check_requirements(user, target, silent = FALSE))
		return FALSE
	var/distance = get_dist(user, target)
	if(distance > max_distance)
		to_chat(user, span_warning("Слишком далеко."))
		return FALSE
	if(!custom_interaction_allows_distance(user, target, distance))
		to_chat(user, span_warning("Для кастомной интеракции на расстоянии нужно согласие обоих участников."))
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
	var/display_message = "[hidden_message][capitalize(use_message)]"
	user.visible_message(
		is_lewd ? span_lewd(display_message) : span_notice(display_message),
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
	apply_effect(user, target, arousal_level, self_arousal_organ, self_orgasm, self_orgasm_organ, self_orgasm_target)
	if(user != target)
		apply_effect(target, user, partner_arousal_level, partner_arousal_organ, partner_orgasm, partner_orgasm_organ, partner_orgasm_target)
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

/datum/controller/subsystem/processing/interactions/proc/get_custom_interaction_owner(mob/living/user, mob/living/target, key)
	if(!istext(key) || findtext(key, CUSTOM_INTERACTION_PREFIX) != 1)
		return
	if(user?.ckey && findtext(key, "[CUSTOM_INTERACTION_PREFIX][user.ckey]:") == 1)
		return user
	if(target?.ckey && findtext(key, "[CUSTOM_INTERACTION_PREFIX][target.ckey]:") == 1)
		return target

/datum/controller/subsystem/processing/interactions/proc/get_custom_interaction(mob/living/user, mob/living/target, key)
	var/mob/living/custom_owner = get_custom_interaction_owner(user, target, key)
	if(!custom_owner?.client?.prefs)
		return
	var/index = text2num(copytext(key, findlasttext(key, ":") + 1))
	var/list/customs = custom_owner.client.prefs.custom_interactions
	if(!ISINTEGER(index) || index < 1 || index > length(customs))
		return
	var/datum/interaction/custom/custom = customs[index]
	if(!custom?.name || !custom.message || custom.requires_review)
		return
	custom.custom_interaction_key = key
	return custom
