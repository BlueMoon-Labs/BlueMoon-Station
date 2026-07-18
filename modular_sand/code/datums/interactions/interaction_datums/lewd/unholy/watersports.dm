/*
 ███  █   █ ████   ████ █████     ███  ████     ████  █     █████  ████  ████ ███ █   █  ███
█ ░░░ █░  █░█░░░█ █ ░░░░█░░░░░   █ ░░█ █░░░█    █░░░█ █░    █░░░░░█ ░░░░█ ░░░░ █░░██  █░█ ░░░
█░ ░░░█░░ █░████░░ ███░░████░░░  █░ ░█░████░░   ████░░█░░   ████░░░███░░░███░░░█░░█░█ █░█░ ██░
█░░   █░░ █░█░░█░ ░ ░░█ █░░░░    █░░ █░█░░█░ ░  █░░░█ █░░   █░░░░   ░░█   ░░█  █░░█░░██░█░░ █░
 ███   ███ ░█░░░█░████░░█████░    ███ ░█░░░█░   ████░░█████ █████░████░░████░░███░█░░ █░░███ ░░
  ░░░   ░░░ ░░░  ░ ░░░░ ░░░░░░     ░░░ ░░░  ░    ░░░░ ░░░░░░ ░░░░░ ░░░░ ░░░░░ ░░░░ ░░  ░░ ░░░ ░
   ░░░   ░░░  ░   ░ ░░░░  ░░░░░     ░░░  ░   ░    ░░░░  ░░░░░ ░░░░░ ░░░░  ░░░░  ░░░ ░   ░  ░░░

 　　/　　 /　　/　 /
　　＿n＿
　／//|ヾ＼　/　/
　⌒⌒|⌒⌒
/　　 |∧_∧　/　 /
　　　|･ω･`)
　/　 Oと　 )　/　/
　　　 しーＪ｡｡｡｡｡


*/

/datum/interaction/lewd/unholy/piss
	description = null
	max_distance = 1
	interaction_sound = list(
		'modular_bluemoon/sound/interactions/watering1.ogg',
		'modular_bluemoon/sound/interactions/watering2.ogg',
		'modular_bluemoon/sound/interactions/watering3.ogg',
		)
	interaction_sound_volume = 50
	// Что использует user для интеракции
	var/user_organ
	// Что использует partner для интеракции
	var/target_organ
	// Куда должен кончить user
	var/user_cum_in
	// Куда должен кончить partner
	var/target_cum_in


/datum/interaction/lewd/unholy/piss/proc/format_message(message, mob/living/user, mob/living/partner)
	if(!istext(message))
		return ""

	. = message
	if(user)
		. = replacetext(., "USER", "<b>\The [user]</b>")
	if(partner)
		. = replacetext(., "TARGET", "<b>\The [partner]</b>")
	. += "."
	. = span_lewd(.)

// Выбор сообщения текста интеракции
/datum/interaction/lewd/unholy/piss/proc/pick_message(mob/living/user, mob/living/partner, is_fucking = TRUE)
	return

// Выбор сообщения реакции партнера
/datum/interaction/lewd/unholy/piss/proc/pick_partner_message(mob/living/user, mob/living/partner, is_fucking = TRUE)
	return

/datum/interaction/lewd/unholy/piss/proc/get_user_lust_level(mob/living/user, mob/living/partner, is_fucking = TRUE)
	return is_fucking ? LOW_LUST : NORMAL_LUST

/datum/interaction/lewd/unholy/piss/proc/get_partner_lust_level(mob/living/user, mob/living/partner, is_fucking = TRUE)
	return 0

/datum/interaction/lewd/unholy/piss/proc/user_lust_grant(mob/living/user, mob/living/partner, is_fucking = TRUE)
	return user.handle_post_sex(get_user_lust_level(user, partner, is_fucking), user_cum_in, partner, user_organ)

/datum/interaction/lewd/unholy/piss/proc/partner_lust_grant(mob/living/user, mob/living/partner, is_fucking = TRUE)
	return partner.handle_post_sex(get_partner_lust_level(user, partner, is_fucking), target_cum_in, user, target_organ)

// Для доп. звуков интеракций
/datum/interaction/lewd/unholy/piss/proc/audio_effects(mob/living/user, mob/living/partner, is_fucking = TRUE, is_hidden = FALSE)
	return

// Для дополнительных эффектов интеракций
/datum/interaction/lewd/unholy/piss/proc/post_reaction(mob/living/user, mob/living/partner, is_fucking = TRUE, is_hidden = FALSE)
	return

/datum/interaction/lewd/unholy/piss/display_interaction(mob/living/user, mob/living/partner, is_hidden)
	var/distance = is_hidden ? 1 : 7
	var/is_fucking = user.is_fucking(partner, target_organ)
	var/message = "[is_hidden ? (pick(hidden_additional)) : null]" + pick_message(user, partner, is_fucking)
	if(!is_fucking)
		user.set_is_fucking(partner, target_organ, user.getorganslot(user_organ))

	user.visible_message(format_message(message, user, partner), ignored_mobs = user.get_unconsenting(unholy = TRUE), vision_distance = distance)
	audio_effects(user, partner, is_fucking, is_hidden)
	user_lust_grant(user, partner, is_fucking)
	if(user != partner)
		partner_lust_grant(user, partner, is_fucking)

	var/partner_message = pick_partner_message(user, partner, is_fucking)
	if(partner_message)
		partner.visible_message(format_message(partner_message, user, partner), ignored_mobs = user.get_unconsenting(unholy = TRUE), vision_distance = distance)

	post_reaction(user, partner, is_fucking, is_hidden)

/datum/interaction/lewd/unholy/piss/vagina
	required_from_user_exposed = INTERACTION_REQUIRE_VAGINA
	user_organ = CUM_TARGET_VAGINA
	p13user_emote = PLUG13_EMOTE_VAGINA

/datum/interaction/lewd/unholy/piss/penis
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS // Возможность интерактов через страпон оставлена намеренно, не баг
	user_organ = CUM_TARGET_PENIS
	p13user_emote = PLUG13_EMOTE_PENIS

//////////////////////// 	OVER BODY	///////////////////////////


#define MAIN_MESSAGES \
	"USER опустошает свой мочевой пузырь на тело TARGET покрывая [partner.ru_ego()] тёплой мочёй", \
	"USER покрывает тело TARGET золотым дождём", \
	"USER наслаждается, наблюдая как золотой дождь проливается на тело TARGET", \
	"USER направляет струю мочи на тело TARGET, покрывая [partner.ru_ego()] с ног до головы", \
	"USER щедро обливает TARGET своей мочой"

#define PARTNER_MESSAGES \
	"TARGET тяжело дышит, пока тёплые струи медленно стекают по [partner.ru_ego()] телу", \
    "TARGET вздрагивает, когда тёплая жидкость касается [partner.ru_ego()] тела", \
    "TARGET молча принимает поток тёплой мочи на своём теле", \
    "TARGET слегка дрожит под потоком мочи", \
	"TARGET закрывает глаза, ощущая, как моча USER течёт по н[partner.ru_emu()]"

#define PARTNER_MESSAGES_CHANSE 20

/datum/interaction/lewd/unholy/piss/vagina/over_body
	description = "Вагина. Обоссать."
	p13target_emote = PLUG13_EMOTE_CHEST
	p13target_strength = PLUG13_STRENGTH_LOW
	write_log_user = "piss over"
	write_log_target = "get golden rain from"

/datum/interaction/lewd/unholy/piss/vagina/over_body/post_reaction(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	partner.apply_external_stink()

/datum/interaction/lewd/unholy/piss/vagina/over_body/pick_message(mob/living/user, mob/living/partner, is_fucking)
	return pick(
		MAIN_MESSAGES,
		"USER выставляет свою киску и медленно поливает тело TARGET струёй горячей мочи",
		"USER со стоном наслаждения, выпускает из своей киски поток горячей мочи, обливая TARGET",
		"USER направляет свою вагину на TARGET, заставляя обтекать под напором мочи")

/datum/interaction/lewd/unholy/piss/vagina/over_body/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	return prob(PARTNER_MESSAGES_CHANSE) && pick(
		PARTNER_MESSAGES,
		"TARGET смотрит на киску USER обливающую [partner.ru_ego()] потоком мочи",
		"TARGET подрагивает, пока киска USER заливает [partner.ru_ego()] мочёй")

/datum/interaction/lewd/unholy/piss/penis/over_body
	description = "Член. Обоссать."
	p13target_emote = PLUG13_EMOTE_CHEST
	p13target_strength = PLUG13_STRENGTH_LOW
	write_log_user = "piss over"
	write_log_target = "get golden rain from"

/datum/interaction/lewd/unholy/piss/penis/over_body/post_reaction(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	partner.apply_external_stink()

/datum/interaction/lewd/unholy/piss/penis/over_body/pick_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	return pick(
		MAIN_MESSAGES,
		"USER направляет свой [shape_desc] на TARGET и медленно водит им, обдавая струёй горячей мочи",
		"USER со стоном наслаждения, выпускает из своего [shape_desc]а поток горячей мочи, обливая TARGET",
		"USER направляет свой [shape_desc] на TARGET, заставляя обтекать под напором мочи",
		"USER расслабляется и из [user.ru_ego()] [shape_desc]а, прямо на TARGET вырывается поток мочи")

/datum/interaction/lewd/unholy/piss/penis/over_body/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	return prob(PARTNER_MESSAGES_CHANSE) && pick(
		PARTNER_MESSAGES,
		"TARGET смотрит на [shape_desc] USER обливающий [partner.ru_ego()] потоком мочи",
		"TARGET подрагивает, пока [shape_desc] USER обливает [partner.ru_ego()] мочёй")

#undef MAIN_MESSAGES
#undef PARTNER_MESSAGES
#undef PARTNER_MESSAGES_CHANSE


//////////////////////// 	OVER BODY SELF	///////////////////////////


#define SELF_MAIN_MESSAGES \
	"USER расслабляется и выпускает струю мочи, обливая себя", \
	"USER облегчённо вздыхает и мочится на себя", \
	"USER мочится, не пытаясь это скрыть", \
	"USER издаёт вздох облегчения, мочась на себя", \
	"USER щедро обливает себя собственной мочой"

/datum/interaction/lewd/unholy/piss/vagina/over_body/self
	description = "Вагина. Обоссать себя."
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_UNHOLY_CONTENT | INTERACTION_FLAG_USER_IS_TARGET
	write_log_user = "piss over self"
	write_log_target = null

/datum/interaction/lewd/unholy/piss/vagina/over_body/self/post_reaction(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	user.apply_external_stink()

/datum/interaction/lewd/unholy/piss/vagina/over_body/self/pick_message(mob/living/user, mob/living/partner, is_fucking)
	user.apply_external_stink()
	return pick(
		SELF_MAIN_MESSAGES,
		"USER выставляет свою киску и демонстративно мочится на себя",
		"USER со стоном наслаждения, выпускает из своей киски поток горячей мочи, обливая себя",
		"USER направляет струю из киски на собственное тело и обтекает под напором горячей жидкости")

/datum/interaction/lewd/unholy/piss/vagina/over_body/self/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	return

/datum/interaction/lewd/unholy/piss/penis/over_body/self
	description = "Член. Обоссать себя."
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_UNHOLY_CONTENT | INTERACTION_FLAG_USER_IS_TARGET
	write_log_user = "piss over self"
	write_log_target = null

/datum/interaction/lewd/unholy/piss/penis/over_body/self/post_reaction(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	user.apply_external_stink()

/datum/interaction/lewd/unholy/piss/penis/over_body/self/pick_message(mob/living/user, mob/living/partner, is_fucking)
	user.apply_external_stink()
	var/shape_desc = get_penis_shape_desc(user)
	return pick(
		SELF_MAIN_MESSAGES,
		"USER направляет на себя, [shape_desc] и медленно водит им, обдавая струёй горячей мочи",
		"USER со стоном наслаждения, выпускает из своего [shape_desc]а поток горячей мочи, обливая своё тело",
		"USER направляет себе на грудь [shape_desc] и выпускает поток горячей мочи",
		"USER расслабляется и из [shape_desc]а, на [user.ru_ego()] тело, вырывается поток мочи, обдавая горячей струёй")

/datum/interaction/lewd/unholy/piss/penis/over_body/self/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	return

#undef SELF_MAIN_MESSAGES

//////////////////////// 	ON MOUTH	///////////////////////////


#define MAIN_MESSAGES \
	"USER опустошает свой мочевой пузырь целясь в рот TARGET, наполняя его тёплой мочёй", \
	"USER издаёт стоны наслаждения, наблюдая как жёлтая жидкость проливается на губы TARGET", \
	"USER без стеснения мочится на лицо TARGET, покрывая [partner.ru_ego()] липкой влагой", \
	"Жёлтая жидкость разбрызгивается по лицу TARGET пока USER справляет свою нужду", \
	"USER мочится на лицо TARGET и с ухмылкой наблюдает как моча капает с [partner.ru_ego()] подбородка"

#define PARTNER_MESSAGES \
	"TARGET слегка кашляет пока USER продолжает мочиться [partner.ru_emu()] в рот", \
    "TARGET вздрагивает ощущая как тёплая жидкость заполняет [partner.ru_ego()] рот", \
    "TARGET судорожно сглатывает пытаясь проглотить льющуюся мочу", \
    "TARGET дрожит пока тёплая моча растекается по [partner.ru_ego()] лицу", \
	"TARGET облизывает губы, ощущая терпкий вкус мочи"

#define PARTNER_MESSAGES_CHANSE 20

/datum/interaction/lewd/unholy/piss/vagina/on_mouth
	description = "Вагина. Нассать на рот и лицо."
	required_from_target = INTERACTION_REQUIRE_MOUTH
	target_organ = CUM_TARGET_MOUTH
	p13target_emote = PLUG13_EMOTE_MOUTH
	p13target_strength = PLUG13_STRENGTH_LOW
	write_log_user = "pissed on face and mouth"
	write_log_target = "was pissed in the face and mouth by"

/datum/interaction/lewd/unholy/piss/vagina/on_mouth/pick_message(mob/living/user, mob/living/partner, is_fucking)
	return pick(
		MAIN_MESSAGES,
		"USER нависает своей киской над лицом TARGET и медленно поливает [partner.ru_ego()] губы струёй горячей мочи",
		"USER со стоном наслаждения, выпускает из своей киски поток горячей мочи, обливая личико и губы TARGET",
		"USER направляет прямо на лицо TARGET свою вагину и выпускает поток мочи целясь в рот")

/datum/interaction/lewd/unholy/piss/vagina/on_mouth/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	return prob(PARTNER_MESSAGES_CHANSE) && pick(
		PARTNER_MESSAGES,
		"TARGET пытается смотреть на киску USER обливающую [partner.ru_ego()] лицо потоком мочи",
		"TARGET подрагивает, пока киска USER заливает [partner.ru_ego()] рот мочёй",
		"TARGET почти касается носом, щели USER пока та обливает [partner.ru_ego()] губы струёй мочи")

/datum/interaction/lewd/unholy/piss/vagina/on_mouth/audio_effects(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	play_interaction_sound(partner, 'modular_sand/sound/interactions/swallow.ogg', is_hidden)

/datum/interaction/lewd/unholy/piss/vagina/on_mouth/get_partner_lust_level(mob/living/user, mob/living/partner, is_fucking)
	return HAS_TRAIT(partner, TRAIT_KISS_SLUT) ? LOW_LUST : 0

/datum/interaction/lewd/unholy/piss/penis/on_mouth
	description = "Член. Нассать на рот и лицо."
	required_from_target = INTERACTION_REQUIRE_MOUTH
	target_organ = CUM_TARGET_MOUTH
	p13target_emote = PLUG13_EMOTE_MOUTH
	p13target_strength = PLUG13_STRENGTH_LOW
	write_log_user = "pissed on face and mouth"
	write_log_target = "was pissed in the face and mouth by"

/datum/interaction/lewd/unholy/piss/penis/on_mouth/pick_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	return pick(
		MAIN_MESSAGES,
		"USER направляет свой [shape_desc] прямо на лицо TARGET и медленно водит им, обдавая струёй горячей мочи",
		"USER со стоном наслаждения, выпускает из своего [shape_desc]а поток горячей мочи, целясь в рот TARGET",
		"USER направляет свой [shape_desc] на лицо TARGET, пытаясь струей мочи попасть в рот",
		"USER расслабляется и из [user.ru_ego()] [shape_desc]а, прямо на губы TARGET вырывается поток мочи")

/datum/interaction/lewd/unholy/piss/penis/on_mouth/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	return prob(PARTNER_MESSAGES_CHANSE) && pick(
		PARTNER_MESSAGES,
		"TARGET пытается смотреть на [shape_desc] USER заливающий [partner.ru_ego()] лицо потоком мочи",
		"TARGET подрагивает, пока [shape_desc] USER заливает [partner.ru_ego()] рот мочёй",
		"TARGET почти касается носом, головки члена USER пока та обливает [partner.ru_ego()] губы струёй мочи")

/datum/interaction/lewd/unholy/piss/penis/on_mouth/audio_effects(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	play_interaction_sound(partner, 'modular_sand/sound/interactions/swallow.ogg', is_hidden)

/datum/interaction/lewd/unholy/piss/penis/on_mouth/get_partner_lust_level(mob/living/user, mob/living/partner, is_fucking)
	return HAS_TRAIT(partner, TRAIT_KISS_SLUT) ? LOW_LUST : 0

#undef MAIN_MESSAGES
#undef PARTNER_MESSAGES
#undef PARTNER_MESSAGES_CHANSE


//////////////////////// 	IN MOUTH	///////////////////////////


#define IN_MOUTH_MAIN_MESSAGES \
	"USER опустошает свой мочевой пузырь, орошая горло TARGET тёплой мочёй", \
	"USER издаёт стоны наслаждения, чувствуя как жёлтая жидкость проливается в рот и горло TARGET", \
	"USER крепко удерживает TARGET, заливая [partner.ru_emu()] в рот горячую мочу", \
	"USER заставляет TARGET проглатывать поток своей мочи", \
	"USER продолжает мочиться в глотку TARGET, не давая [partner.ru_emu()] отвернуться"

#define IN_MOUTH_PARTNER_MESSAGES \
	"TARGET молча принимает поток мочи USER, лишь тяжело сглатывая", \
    "TARGET вздрагивает ощущая как тёплая жидкость орошает [partner.ru_emu()] горло", \
    "TARGET судорожно сглатывает неостанавливающийся поток мочи", \
	"TARGET дрожит и тяжело дышит между глотками мочи", \
	"TARGET задыхается на мгновение, начиная глотать горячую жидкость", \
	"TARGET громко сглатывает, пытаясь проглотить всю струю мочи"

#define IN_MOUTH_PARTNER_MESSAGES_CHANSE 20

/datum/interaction/lewd/unholy/piss/vagina/in_mouth
	description = "Вагина. Прижать ко рту и помочиться."
	required_from_target = INTERACTION_REQUIRE_MOUTH
	target_organ = CUM_TARGET_MOUTH
	user_cum_in = CUM_TARGET_MOUTH
	p13target_emote = PLUG13_EMOTE_MOUTH
	p13target_strength = PLUG13_STRENGTH_LOW
	write_log_user = "pissed in throat"
	write_log_target = "got their throat filled with piss by"

/datum/interaction/lewd/unholy/piss/vagina/in_mouth/pick_message(mob/living/user, mob/living/partner, is_fucking)
	if(is_fucking)
		return pick(
			IN_MOUTH_MAIN_MESSAGES,
			"USER крепко удерживает голову TARGET прижатой к своей киске и выпуская поток мочи внутрь [partner.ru_ego()] рта",
			"USER со стоном наслаждения, выпускает из своей киски поток горячей мочи, пытаясь залить глотку TARGET",
			"USER елозит своей киской по губам TARGET, выпуская в приоткрытый рот поток мочи")
	else
		return pick(
			"USER обхватывает голову TARGET своими бедрами и прижимает киску к [partner.ru_ego()] губам, выпуская поток мочи в рот",
			"USER вцепившись в голову TARGET, плотно прижимает её к своей киске, начиная мочиться",
			"USER заставляет TARGET, прижаться к своей киске, пока сам[user.ru_a()] начинет мочиться")

/datum/interaction/lewd/unholy/piss/vagina/in_mouth/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	return prob(IN_MOUTH_PARTNER_MESSAGES_CHANSE) && pick(
		IN_MOUTH_PARTNER_MESSAGES,
		"TARGET подрагивает, когда горячая струя мочи из киски USER проносится по горлу",
		"TARGET ощущает горячую киску USER на своих губах, пока струя мочи из неё орошает рот",
		"TARGET плотно прижат[partner.ru_aya()] к USER, упирается в [user.ru_nego()] носом, ощущая, как киска заливает рот потоком мочи")

/datum/interaction/lewd/unholy/piss/vagina/in_mouth/audio_effects(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	play_interaction_sound(partner, 'modular_sand/sound/interactions/swallow.ogg', is_hidden)
	play_interaction_sound(partner, pick('modular_sand/sound/interactions/oral1.ogg', 'modular_sand/sound/interactions/oral2.ogg'), is_hidden)

/datum/interaction/lewd/unholy/piss/vagina/in_mouth/get_partner_lust_level(mob/living/user, mob/living/partner, is_fucking)
	return HAS_TRAIT(partner, TRAIT_KISS_SLUT) ? NORMAL_LUST : 0

/datum/interaction/lewd/unholy/piss/vagina/in_mouth/get_user_lust_level(mob/living/user, mob/living/partner, is_fucking)
	return is_fucking ? NORMAL_LUST : HIGH_LUST


//////////////////////// 	IN MOUTH SELF	///////////////////////////


#define SELF_IN_MOUTH_MAIN_MESSAGES \
	"USER продолжает мочиться в собственную глотку", \
	"USER издаёт стоны наслаждения, чувствуя как жёлтая жидкость проливается [partner.ru_emu()] в рот"


/datum/interaction/lewd/unholy/piss/vagina/in_mouth/self
	description = "Вагина. Отлизать свою киску и помочиться."
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_UNHOLY_CONTENT | INTERACTION_FLAG_USER_IS_TARGET
	write_log_user = "suck and pissed in self throat"
	write_log_target = null

/datum/interaction/lewd/unholy/piss/vagina/in_mouth/self/pick_message(mob/living/user, mob/living/partner, is_fucking)
	return pick(
		SELF_IN_MOUTH_MAIN_MESSAGES,
		"USER облизывается и зарывается своим лицом в свою же киску и выпуская поток мочи внутрь собственного рта",
		"USER толкается языком к своей киске и проводит по клитору кончиком языка, мочась на него",
		"USER пробует свою киску и мочу на вкус",
		"USER целует свои нежные лепестки и выпускает поток горячей мочи себе в рот")

/datum/interaction/lewd/unholy/piss/vagina/in_mouth/self/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	return

/datum/interaction/lewd/unholy/piss/vagina/in_mouth/audio_effects(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	play_interaction_sound(partner, 'modular_sand/sound/interactions/swallow.ogg', is_hidden)
	play_interaction_sound(partner, pick('modular_sand/sound/interactions/bj1.ogg',
									'modular_sand/sound/interactions/bj2.ogg',
									'modular_sand/sound/interactions/bj3.ogg',
									'modular_sand/sound/interactions/bj4.ogg',
									'modular_sand/sound/interactions/bj5.ogg',
									'modular_sand/sound/interactions/bj6.ogg',
									'modular_sand/sound/interactions/bj7.ogg',
									'modular_sand/sound/interactions/bj8.ogg',
									'modular_sand/sound/interactions/bj9.ogg',
									'modular_sand/sound/interactions/bj10.ogg',
									'modular_sand/sound/interactions/bj11.ogg'), is_hidden)


////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////								PENIS INSIDE SOMETHING								   /////////
////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/interaction/lewd/unholy/piss/penis/inside
	description = null

/datum/interaction/lewd/unholy/piss/penis/inside/special_check(mob/living/user, mob/living/target)
	. = ..()
	return !!(. && user_organ && target_organ)

/datum/interaction/lewd/unholy/piss/penis/inside/get_partner_lust_level(mob/living/user, mob/living/partner, is_fucking)
	return is_fucking ? NORMAL_LUST : HIGH_LUST

/datum/interaction/lewd/unholy/piss/penis/inside/get_user_lust_level(mob/living/user, mob/living/partner, is_fucking)
	if(user.has_penis())
		return is_fucking ? NORMAL_LUST : HIGH_LUST
	else // Если у user страпон, он получает только эстетическое удовлетворение
		return ..()

/datum/interaction/lewd/unholy/piss/penis/inside/partner_lust_grant(mob/living/user, mob/living/partner, is_fucking)
	if(user.has_strapon())
		var/obj/item/clothing/underwear/briefs/strapon/user_strapon = user.get_strapon()
		user_strapon.attached_dildo.target_reaction(partner, user, 0, target_organ, target_cum_in, user.a_intent == INTENT_HARM)
	else
		..()
		try_apply_knot(user, partner, target_organ)

//////////////////////// 	IN MOUTH	///////////////////////////

/datum/interaction/lewd/unholy/piss/penis/inside/mouth
	description = "Член. Протолкнуть в горло и мочиться."
	required_from_target = INTERACTION_REQUIRE_MOUTH
	target_organ = CUM_TARGET_THROAT
	user_cum_in = CUM_TARGET_THROAT
	p13target_emote = PLUG13_EMOTE_MOUTH
	write_log_user = "pissed in throat"
	write_log_target = "got their throat filled with piss by"

/datum/interaction/lewd/unholy/piss/penis/inside/mouth/pick_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	if(is_fucking)
		return pick(
			IN_MOUTH_MAIN_MESSAGES,
			"USER крепко удерживает голову TARGET насаженной на свой [shape_desc], выпуская поток мочи внутрь горла",
			"USER со стоном наслаждения, проталкивает [shape_desc] глубже и выпускает поток горячей мочи, пытаясь залить глотку TARGET",
			"USER вталкивает [shape_desc] глубже, выпуская прямо в горло TARGET поток мочи",
			"USER крепко держит TARGET за затылок, пока [user.ru_ego()] [shape_desc] глубоко в горле, изливается горячей жидкостью",
			"USER двигает своим [shape_desc]ом внутри горла TARGET, не переставая мочиться")
	else
		return pick(
			"USER проталкивает свой [shape_desc] глубоко в горло TARGET, начиная мочиться",
			"USER заставляет открыть рот TARGET и просовывает внутрь свой [shape_desc], выпуская поток мочи",
			"USER обхватывает голову TARGET и надавив на [partner.ru_ego()] губы своим [shape_desc] вталкивает его внутрь, изливаясь горячей мочей",
			"USER вцепившись в голову TARGET, резко впихивает свой [shape_desc] внутрь, со стоном выпуская поток мочи")

/datum/interaction/lewd/unholy/piss/penis/inside/mouth/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	return prob(IN_MOUTH_PARTNER_MESSAGES_CHANSE) && pick(
		IN_MOUTH_PARTNER_MESSAGES,
		"TARGET подрагивает, пока [shape_desc] USER заполняет [partner.ru_ego()] горло, а горячая струя мочи проносится внутри",
		"TARGET тяжело дышит с [shape_desc]ом USER внутри своего горла, судорожно сглатывая мочу",
		"TARGET ощущает горячий [shape_desc] USER в своём горле, пока струя мочи из него орошает рот",
		"TARGET плотно прижат[partner.ru_aya()] к USER, упирается в [user.ru_nego()] носом, ощущая, как [partner.ru_emu()] в глотку горячей мочей изливается [shape_desc]")

/datum/interaction/lewd/unholy/piss/penis/inside/mouth/audio_effects(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	play_interaction_sound(partner, 'modular_sand/sound/interactions/swallow.ogg', is_hidden)
	play_interaction_sound(partner, pick('modular_sand/sound/interactions/oral1.ogg', 'modular_sand/sound/interactions/oral2.ogg'), is_hidden)

/datum/interaction/lewd/unholy/piss/penis/inside/mouth/get_partner_lust_level(mob/living/user, mob/living/partner, is_fucking)
	return HAS_TRAIT(partner, TRAIT_KISS_SLUT) ? NORMAL_LUST : LOW_LUST

#undef IN_MOUTH_MAIN_MESSAGES
#undef IN_MOUTH_PARTNER_MESSAGES
#undef IN_MOUTH_PARTNER_MESSAGES_CHANSE


//////////////////////// 	IN MOUTH SELF	///////////////////////////


/datum/interaction/lewd/unholy/piss/penis/inside/mouth/self
	description = "Член. Отсосать себе и помочиться."
	interaction_flags = INTERACTION_FLAG_ADJACENT | INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_UNHOLY_CONTENT | INTERACTION_FLAG_USER_IS_TARGET
	write_log_user = "suck and pissed in self throat"
	write_log_target = null

/datum/interaction/lewd/unholy/piss/penis/inside/mouth/self/pick_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	return pick(
		SELF_IN_MOUTH_MAIN_MESSAGES,
		"USER обводит языком свой [shape_desc] и мочится прямо в рот",
		"USER водит языком вокруг головки своего [shape_desc]а, слизывая капли жёлтой жидкости",
		"USER медленно заглатывает свой [shape_desc], орошая собственное горло горячей мочой",
		"USER поглубже заглатывает свой [shape_desc], выпивая свою мочу",
		"USER отсасывает свой [shape_desc], вытягивая капли тёплой жидкости себе в рот")

/datum/interaction/lewd/unholy/piss/penis/inside/mouth/self/user_lust_grant(mob/living/user, mob/living/partner, is_fucking)
	if(user.has_strapon())
		var/obj/item/clothing/underwear/briefs/strapon/user_strapon = user.get_strapon()
		user_strapon.attached_dildo.target_reaction(partner, user, 0, target_organ, target_cum_in, user.a_intent == INTENT_HARM)
	else
		..()
		try_apply_knot(user, partner, target_organ)

/datum/interaction/lewd/unholy/piss/penis/inside/mouth/self/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	return

/datum/interaction/lewd/unholy/piss/penis/inside/mouth/self/audio_effects(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	play_interaction_sound(partner, 'modular_sand/sound/interactions/swallow.ogg', is_hidden)
	play_interaction_sound(partner, pick('modular_sand/sound/interactions/bj1.ogg',
									'modular_sand/sound/interactions/bj2.ogg',
									'modular_sand/sound/interactions/bj3.ogg',
									'modular_sand/sound/interactions/bj4.ogg',
									'modular_sand/sound/interactions/bj5.ogg',
									'modular_sand/sound/interactions/bj6.ogg',
									'modular_sand/sound/interactions/bj7.ogg',
									'modular_sand/sound/interactions/bj8.ogg',
									'modular_sand/sound/interactions/bj9.ogg',
									'modular_sand/sound/interactions/bj10.ogg',
									'modular_sand/sound/interactions/bj11.ogg'), is_hidden)

#undef SELF_IN_MOUTH_MAIN_MESSAGES


//////////////////////// 	IN VAGINA	///////////////////////////


#define INSIDE_MAIN_MESSAGES \
	"USER выпускает горячую мочу во внутрь TARGET", \
	"USER медленно заливает внутренности TARGET тёплой струёй мочи", \
	"USER без стеснения справляет нужду прямо внутрь TARGET", \
	"USER продолжает мочиться внутрь TARGET, не останавливая поток", \
	"USER глубоко выдыхает, выпуская мочу внутрь TARGET", \
	"USER бесцеремонно мочится прямо внутрь TARGET"

#define INSIDE_PARTNER_MESSAGES \
	"TARGET молча принимает поток мочи USER, ощущая теплоту внутри", \
	"TARGET судорожно выдыхает, ощущая как USER продолжает мочиться внутрь", \
	"TARGET слегка изгибается, принимая горячий поток мочи от USER", \
	"TARGET слабо дрожит, пока внутри [partner.ru_nego()] растекается моча USER", \
	"TARGET тихо постанывает, пока USER продолжает мочиться внутрь", \
	"TARGET слегка изгибается от ощущения горячей мочи внутри"

#define INSIDE_PARTNER_MESSAGES_CHANSE 10

/datum/interaction/lewd/unholy/piss/penis/inside/vagina
	description = "Член. Протолкнуть в вагину и мочиться."
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA
	target_organ = CUM_TARGET_VAGINA
	user_cum_in = CUM_TARGET_VAGINA
	target_cum_in = CUM_TARGET_PENIS
	p13target_emote = PLUG13_EMOTE_VAGINA
	write_log_user = "pissed in vagina"
	write_log_target = "got their vagina filled with piss by"

/datum/interaction/lewd/unholy/piss/penis/inside/vagina/pick_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	if(is_fucking)
		return pick(
			INSIDE_MAIN_MESSAGES,
			"USER ритмично двигает своим [shape_desc]ом, одновременно выпуская поток мочи внутрь киски TARGET",
			"[capitalize(shape_desc)] USER долбится в киску TARGET, пока горячая струя мочи устремляется внутрь",
			"USER без остановки проталкивает свой [shape_desc] и выпускает мочу внутрь вагины TARGET",
			"Из [shape_desc]а USER вырывается поток мочи прямо в киску TARGET",
			"USER с силой загоняет свой [shape_desc] в вагину TARGET, продолжая мочиться внутрь",
			"USER крепко прижимает TARGET к своему паху, горячей мочей помечая [partner.ru_ego()] киску изнутри",
			"USER крепко удерживает киску TARGET насаженной на свой [shape_desc], выпуская поток мочи внутрь")

	else
		return pick(
			"USER проникает своим [shape_desc]ом внутрь киски TARGET и со стоном выпускает струю мочи",
			"USER плотно прижимается к TARGET и погружает свой [shape_desc] внутрь [partner.ru_ego()] киски, начиная мочиться",
			"USER проталкивает свой [shape_desc] глубоко в киску TARGET, выпуская внутрь поток мочи")

/datum/interaction/lewd/unholy/piss/penis/inside/vagina/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	return prob(INSIDE_PARTNER_MESSAGES_CHANSE) && pick(
		INSIDE_PARTNER_MESSAGES,
		"TARGET подрагивает, пока [shape_desc] USER заполняет [partner.ru_ego()] киску, а горячая струя мочи проносится внутри",
		"TARGET тяжело дышит с [shape_desc] USER внутри, ощущая тёплую жидкость текущую внутри",
		"TARGET ощущает горячий [shape_desc] USER в своей киске, пока струя мочи вырывается из него",
		"TARGET тихо стонет и прижимается ближе, пока USER мочится внутрь своим [shape_desc]")

/datum/interaction/lewd/unholy/piss/penis/inside/vagina/audio_effects(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	play_interaction_sound(partner, pick('modular_sand/sound/interactions/champ1.ogg', 'modular_sand/sound/interactions/champ2.ogg'), is_hidden)


//////////////////////// 	IN ANUS		///////////////////////////


/datum/interaction/lewd/unholy/piss/penis/inside/anus
	description = "Член. Протолкнуть в задницу и мочиться."
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	target_organ = CUM_TARGET_ANUS
	user_cum_in = CUM_TARGET_ANUS
	p13target_emote = PLUG13_EMOTE_ANUS
	write_log_user = "pissed in anus"
	write_log_target = "got their anus filled with piss by"

/datum/interaction/lewd/unholy/piss/penis/inside/anus/pick_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	if(is_fucking)
		return pick(
			INSIDE_MAIN_MESSAGES,
			"USER ритмично двигает своим [shape_desc]ом, одновременно выпуская поток мочи внутрь попки TARGET",
			"[shape_desc] USER долбится в анус TARGET, пока горячая струя мочи устремляется внутрь",
			"USER без остановки проталкивает свой [shape_desc] в узкое колечко TARGET и выпускает мочу внутрь",
			"Из [shape_desc]а USER вырывается поток мочи прямо в попку TARGET",
			"USER с силой загоняет свой [shape_desc] в попку TARGET, продолжая мочиться внутрь",
			"USER крепко прижимает TARGET к своему паху, изливаясь горячей мочей внутрь [partner.ru_ego()] заднего прохода",
			"USER крепко удерживает задницу TARGET насаженной на свой [shape_desc], выпуская поток мочи внутрь")

	else
		return pick(
			"USER проникает своим [shape_desc]ом внутрь ануса TARGET и со стоном выпускает струю мочи",
			"USER плотно прижимается к TARGET и погружает свой [shape_desc] внутрь [partner.ru_ego()] попки, начиная мочиться",
			"USER проталкивает свой [shape_desc] глубоко в задницу TARGET, выпуская поток мочи")

/datum/interaction/lewd/unholy/piss/penis/inside/anus/pick_partner_message(mob/living/user, mob/living/partner, is_fucking)
	var/shape_desc = get_penis_shape_desc(user)
	return prob(INSIDE_PARTNER_MESSAGES_CHANSE) && pick(
		INSIDE_PARTNER_MESSAGES,
		"TARGET подрагивает, пока [shape_desc] USER заполняет [partner.ru_ego()] попку, а горячая струя мочи проносится внутри",
		"TARGET тяжело дышит с [shape_desc] USER внутри задницы, ощущая тёплую жидкость текущую внутри",
		"TARGET ощущает горячий [shape_desc] USER в своём заднем проходе, пока струя мочи вырывается из него",
		"TARGET тихо стонет и прижимается ближе, пока USER мочится внутрь попки своим [shape_desc]")

/datum/interaction/lewd/unholy/piss/penis/inside/anus/audio_effects(mob/living/user, mob/living/partner, is_fucking, is_hidden)
	play_interaction_sound(partner, pick('modular_sand/sound/interactions/bang1.ogg',
						'modular_sand/sound/interactions/bang2.ogg',
						'modular_sand/sound/interactions/bang3.ogg'), is_hidden)

#undef INSIDE_MAIN_MESSAGES
#undef INSIDE_PARTNER_MESSAGES
#undef INSIDE_PARTNER_MESSAGES_CHANSE
