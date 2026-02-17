/datum/interaction/lewd/tentacle
	var/require_user_tentacles
	p13user_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_NORMAL

/datum/interaction/lewd/tentacle/evaluate_user(mob/living/user, silent = TRUE, action_check = TRUE, apply_cooldown = TRUE)
	. = ..()
	if(!.)
		return FALSE

	if(require_user_tentacles && !user.has_tentacles())
		if(!silent)
			to_chat(user, "<span class='warning'>У тебя нет тентаклей!</span>")
		return FALSE

	return FALSE

/datum/interaction/lewd/tentacle/female
	required_from_user_exposed = INTERACTION_REQUIRE_VAGINA
	require_user_tentacles = TRUE
	write_log_user = "tentacled"
	write_log_target = "was tentacled by"
	interaction_sound = null
	max_distance = 1
	p13target_emote = PLUG13_EMOTE_VAGINA

/datum/interaction/lewd/tentacle/female/display_interaction(mob/living/user, mob/living/partner)
	var/message
	if(user.is_fucking(partner, CUM_TARGET_VAGINA))
		message = "[pick(
			"долбятся в дырочку <b>[partner]</b>.",
			"проникают в киску <b>[partner]</b>, стимулируя её!",
			"глубоко вводят свои тентакли в лоно <b>[partner]</b>.",
			"движутся внутри промежности <b>[partner]</b>, лаская её изнутри!",
			"безжалостно долбят промежность <b>[partner]</b>!",
			"с силой загоняют свои гениталии в дырочку <b>[partner]</b> и яростно извиваются!")]"
	else
		message = "вводят свои тентакли в промежность <b>[partner]</b>."
		user.set_is_fucking(partner, CUM_TARGET_VAGINA, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), "modular_sand/sound/interactions/bang[rand(1, 6)].ogg", 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_VAGINA, partner)
	partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, user)
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)

/datum/interaction/lewd/tentacle/female_double
	required_from_user_exposed = INTERACTION_REQUIRE_VAGINA | INTERACTION_REQUIRE_ANUS
	require_user_tentacles = TRUE
	write_log_user = "tentacled"
	write_log_target = "was tentacled by"
	interaction_sound = null
	max_distance = 1

/datum/interaction/lewd/tentacle/female_double/post_interaction(mob/living/user, mob/living/target)
	. = ..()
	target.client?.plug13.send_emote(PLUG13_EMOTE_VAGINA, min(p13target_strength + get_lust_modifier(target), 100), p13target_duration)
	target.client?.plug13.send_emote(PLUG13_EMOTE_ANUS,   min(p13target_strength + get_lust_modifier(target), 100), p13target_duration)

/datum/interaction/lewd/tentacle/female_double/display_interaction(mob/living/user, mob/living/partner)
	var/message
	if(user.is_fucking(partner, CUM_TARGET_VAGINA))
		message = "[pick(
			"долбятся в дырочки <b>[partner]</b>.",
			"проникают в обе дырки <b>[partner]</b>, стимулируя их!",
			"глубоко вводят свои тентакли в отвертсия <b>[partner]</b>.",
			"движутся внутри <b>[partner]</b>, лаская её изнутри!",
			"безжалостно долбят <b>[partner]</b>!",
			"с силой загоняют свои гениталии в дырочки <b>[partner]</b> и яростно извиваются!")]"
	else
		message = "вводят свои тентакли в отверстия <b>[partner]</b>."
		user.set_is_fucking(partner, CUM_TARGET_VAGINA, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), "modular_sand/sound/interactions/bang[rand(1, 6)].ogg", 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_VAGINA, partner)
	partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, user)
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)

/datum/interaction/lewd/tentacle/male
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	require_user_tentacles = TRUE
	write_log_user = "tentacled"
	write_log_target = "was tentacled by"
	interaction_sound = null
	max_distance = 1
	p13target_emote = PLUG13_EMOTE_PENIS

/datum/interaction/lewd/tentacle/male/display_interaction(mob/living/user, mob/living/partner)
	var/message
	if(user.is_fucking(partner, CUM_TARGET_PENIS))
		message = "[pick(
			"потирают член <b>[partner]</b>.",
			"обвиваюь член <b>[partner]</b>.",
			"наяривают пенис <b>[partner]</b>!",
			"смазывают пенис <b>[partner]</b> выделениями и наяривают его!")]"
	else
		message = "[pick(
			"грубо надрачивают \the <b>[partner]</b> .",
			"обволакивают \the <b>[partner]</b> и начинают стимулировать гениталии!",
			"сильно извиваются вокруг \the <b>[partner]</b>, стимулируя член.")]"
		user.set_is_fucking(partner, CUM_TARGET_PENIS, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), "modular_sand/sound/interactions/bang[rand(1, 6)].ogg", 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, partner)
	partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, user)
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)

/datum/interaction/lewd/tentacle/male_double
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS | INTERACTION_REQUIRE_PENIS
	require_user_tentacles = TRUE
	write_log_user = "tentacled"
	write_log_target = "was tentacled by"
	interaction_sound = null
	max_distance = 1

/datum/interaction/lewd/tentacle/male_double/post_interaction(mob/living/user, mob/living/target)
	. = ..()
	target.client?.plug13.send_emote(PLUG13_EMOTE_PENIS, min(p13target_strength + get_lust_modifier(target), 100), p13target_duration)
	target.client?.plug13.send_emote(PLUG13_EMOTE_ANUS,  min(p13target_strength + get_lust_modifier(target), 100), p13target_duration)

/datum/interaction/lewd/tentacle/male_double/display_interaction(mob/living/user, mob/living/partner)
	var/message
	if(user.is_fucking(partner, CUM_TARGET_PENIS))
		message = "[pick(
			"долбятся в задницу и потирает член <b>[partner]</b>.",
			"проникают в попку, обвивая член <b>[partner]</b>.",
			"глубоко вводят свои тентакли в анальное колечко <b>[partner]</b> и обвивают член.",
			"с силой загоняют свои тентакли в анальное отверстие <b>[partner]</b> и скользят ими по члену.")]"
	else
		message = "[pick(
			"грубо трахают \the <b>[partner]</b> в задницу с громким чавкающим звуком, надрачивая член.",
			"обволакивают \the <b>[partner]</b> и начинают тянуть к самому основанию своих конечностей.",
			"сильно извиваются и погружаются внутрь сфинктера \the <b>[partner]</b>, стимулируя член.")]"
		user.set_is_fucking(partner, CUM_TARGET_PENIS, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), "modular_sand/sound/interactions/bang[rand(1, 6)].ogg", 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, partner)
	partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, user)
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)

/datum/interaction/lewd/tentacle/anus
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	require_user_tentacles = TRUE
	write_log_user = "tentacled"
	write_log_target = "was tentacled by"
	interaction_sound = null
	max_distance = 1
	p13target_emote = PLUG13_EMOTE_ANUS

/datum/interaction/lewd/tentacle/anus/display_interaction(mob/living/user, mob/living/partner)
	var/message
	if(user.is_fucking(partner, CUM_TARGET_ANUS))
		message = "[pick(
			"долбятся в задницу <b>[partner]</b>.",
			"проникают в попу <b>[partner]</b>, стимулируя её!",
			"глубоко вводят свои тентакли в задний проход <b>[partner]</b>.",
			"движутся внутри задницы <b>[partner]</b>, лаская её изнутри!",
			"безжалостно долбят <b>[partner]</b> в зад!",
			"с силой загоняют свои гениталии в колечко <b>[partner]</b> и яростно извиваются!")]"
	else
		message = "вводят свои тентакли в заднее отверстие <b>[partner]</b>."
		user.set_is_fucking(partner, CUM_TARGET_ANUS, user.getorganslot(ORGAN_SLOT_PENIS))

// ⠄⠄⢀⡋⣡⣴⣶⣶⡀⠄⠄⠙⢿⣿⣿⣿⣿⣿⣴⣿⣿⣿⢃⣤⣄⣀⣥⣿⣿⠄
// ⠄⠄⢸⣇⠻⣿⣿⣿⣧⣀⢀⣠⡌⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⣿⣿⣿⠄
// ⠄⢀⢸⣿⣷⣤⣤⣤⣬⣙⣛⢿⣿⣿⣿⣿⣿⣿⡿⣿⣿⡍⠄⠄⢀⣤⣄⠉⠋⣰
// ⠄⣼⣖⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⢇⣿⣿⡷⠶⠶⢿⣿⣿⠇⢀⣤
// ⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣽⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣷⣶⣥⣴⣿⡗
// ⢀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠄
// ⢸⣿⣦⣌⣛⣻⣿⣿⣧⠙⠛⠛⡭⠅⠒⠦⠭⣭⡻⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠄
// ⠘⣿⣿⣿⣿⣿⣿⣿⣿⡆⠄⠄⠄⠄⠄⠄⠄⠄⠹⠈⢋⣽⣿⣿⣿⣿⣵⣾⠃⠄
// ⠄⠘⣿⣿⣿⣿⣿⣿⣿⣿⠄⣴⣿⣶⣄⠄⣴⣶⠄⢀⣾⣿⣿⣿⣿⣿⣿⠃⠄
// ⠄⠄⠈⠻⣿⣿⣿⣿⣿⣿⡄⢻⣿⣿⣿⠄⣿⣿⡀⣾⣿⣿⣿⣿⣛⠛⠁⠄⠄
// ⠄⠄⠄⠄⠈⠛⢿⣿⣿⣿⠁⠞⢿⣿⣿⡄⢿⣿⡇⣸⣿⣿⠿⠛⠁⠄⠄

	playlewdinteractionsound(get_turf(user), "modular_sand/sound/interactions/bang[rand(1, 6)].ogg", 70, 1, -1)
	user.visible_message(span_lewd("<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting())
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, CUM_TARGET_ANUS, partner)
	partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_PENIS, user)
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(partner, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(partner.loc)
