/datum/interaction/lewd/belly_riding
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_HIDE_IN_PANEL
	write_log_user = "fucked in belly ride"
	write_log_target = "was fucked in belly ride by"
	simple_message = null
	var/target_organ

/datum/interaction/lewd/belly_riding/proc/format_message(message, mob/living/user, mob/living/partner)
	if(!istext(message))
		return ""

	. = message
	if(user && findtext(., "USER"))
		. = replacetext(., "USER", "<b>\The [user]</b>")
	if(partner && findtext(., "TARGET"))
		. = replacetext(., "TARGET", "<b>\The [partner]</b>")
	. += "."
	. = span_lewd(.)

/datum/interaction/lewd/belly_riding/proc/pick_message(mob/living/user, mob/living/partner, is_fucking = TRUE)
	return

/datum/interaction/lewd/belly_riding/special_check(mob/living/user, mob/living/target)
	. = ..()
	if(!. || !target_organ)
		return FALSE

/datum/interaction/lewd/belly_riding/display_interaction(mob/living/user, mob/living/partner)
	var/is_fucking = user.is_fucking(partner, target_organ)
	var/message = pick_message(user, partner, is_fucking)
	var/const/message_distance = 4
	if(!is_fucking)
		user.set_is_fucking(partner, target_organ, user.getorganslot(ORGAN_SLOT_PENIS))

	user.visible_message(format_message(message, user, partner), ignored_mobs = user.get_unconsenting(), vision_distance = message_distance)
	if(user.can_penetrating_genital_cum())
		user.handle_post_sex(NORMAL_LUST, target_organ, partner, ORGAN_SLOT_PENIS)

	if(user.has_strapon())
		var/obj/item/clothing/underwear/briefs/strapon/user_strapon = user.get_strapon()
		user_strapon.attached_dildo.target_reaction(partner, user, 0, target_organ, CUM_TARGET_PENIS, user.a_intent == INTENT_HARM)
	else
		partner.handle_post_sex(NORMAL_LUST, (target_organ == CUM_TARGET_VAGINA ? CUM_TARGET_PENIS : null), user, target_organ)
		try_apply_knot(user, partner, target_organ) // Проверка на узлирование.

	if(!prob(partner.get_lust() / partner.get_climax_threshold() * 50)) // 50%
		return

	var/static/list/partner_reactions = list(
		INTENT_HELP = list(
			"TARGET дрожит от удовольствия",
			"TARGET стонет, покачиваясь в ремнях",
			"TARGET слабо постанывает, чувствуя каждое движени",
		),
		INTENT_HARM = list(
			"TARGET дергается в ремниях USER, с гневом на лице",
			"TARGET злится, тщетно пытаясь вырваться",
		),
		"else" = list(
			"TARGET извивается от удовольствия, на животе USER",
			"TARGET издает стон и дергается, сильнее насаживает себя",
		)
	)

	var/list/reactions = partner_reactions[partner.a_intent] || partner_reactions["else"]
	message = pick(reactions)


	partner.visible_message(format_message(message, user, partner), ignored_mobs = user.get_unconsenting(), vision_distance = message_distance)


/datum/interaction/lewd/belly_riding/vagina
	description = "Belly riding. Проникнуть в вагину." // В панельке нету, но описание нужно для инициализации в подсистеме интеракторв
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA
	interaction_sound = list(
		'modular_sand/sound/interactions/champ1.ogg',
		'modular_sand/sound/interactions/champ2.ogg')
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_VAGINA
	additional_details = list(
		INTERACTION_MAY_CAUSE_PREGNANCY
	)
	target_organ = CUM_TARGET_VAGINA

/datum/interaction/lewd/belly_riding/vagina/pick_message(mob/living/user, mob/living/partner, is_fucking = TRUE)
	var/shape_desc = get_penis_shape_desc(user)
	if(is_fucking)
		return pick(
			"При движении, USER долбится в киску TARGET, заставляя скрепеть ремни",
			"USER глубоко вводит свой [shape_desc] во влагалище TARGET",
			"В движении, TARGET с силой насаживается киской на [shape_desc] USER",
			"[user.has_balls() ? "Яйца" : "Бедра"] USER шлепаются о TARGET, пока [partner.ru_who()] извивается, насаженная на [shape_desc]",
			"USER ритмично двигается, заставляя TARGET дрожать при каждом толчке",
			"TARGET покачивается в ремнях, насаженная киской на [shape_desc] USER")
	else
		return pick(
			"USER медленно вводит свой [shape_desc] в лоно TARGET, надежно фиксируя",
			"USER плотно прижимает TARGET к себе и проталкивает в киску [shape_desc]",
			"USER с силой загоняет [shape_desc] во влагалище TARGET, оставляя висеть на нем",
			"USER мощным толчком погружает свой [shape_desc] внутрь киски TARGET")

/datum/interaction/lewd/belly_riding/anal
	description = "Член. Проникнуть в задницу."
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	interaction_sound = list(
		'modular_sand/sound/interactions/bang1.ogg',
		'modular_sand/sound/interactions/bang2.ogg',
		'modular_sand/sound/interactions/bang3.ogg')
	p13user_emote = PLUG13_EMOTE_PENIS
	p13target_emote = PLUG13_EMOTE_BREASTS
	target_organ = CUM_TARGET_ANUS

/datum/interaction/lewd/belly_riding/anal/pick_message(mob/living/user, mob/living/partner, is_fucking = TRUE)
	var/shape_desc = get_penis_shape_desc(user)
	if(is_fucking)
		return pick(
			"При движении, USER долбится в попку TARGET, заставляя скрепеть ремни",
			"USER глубоко вводит свой [shape_desc] в анус TARGET",
			"В движении, TARGET с силой насаживается [pick("попкой", "задницей")] на [shape_desc] USER",
			"[user.has_balls() ? "Яйца" : "Бедра"] USER шлепаются о TARGET, пока [partner.ru_who()] извивается, насаженная на [shape_desc]",
			"USER ритмично двигается, глубже загоняя свой [shape_desc] в анус TARGET",
			"TARGET покачивается в ремнях, насаженная [pick("попкой", "задницей")] на [shape_desc] USER")
	else
		return pick(
			"USER медленно вводит свой [shape_desc] в анус TARGET, надежно фиксируя",
			"USER хватает TARGET и начинает насаживать попкой на свой [shape_desc]",
			"USER мощным толчком погружает свой [shape_desc] внутрь сфинктера TARGET",
			"USER с силой загоняет [shape_desc] в анальное колечко TARGET, заставляя повиснуть на нем")
