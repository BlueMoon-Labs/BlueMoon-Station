/datum/interaction/cheekkiss
	description = "Поцеловать в щёчку."
	required_from_user = INTERACTION_REQUIRE_MOUTH
	simple_message = "USER целует TARGET в щёчку."
	simple_style = "lewd"
	write_log_user = "kissed"
	write_log_target = "was kissed by"
	interaction_sound = null

	p13user_emote = PLUG13_EMOTE_BASIC
	p13target_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_LOW
	p13target_strength = PLUG13_STRENGTH_LOW

	hearts_effect = TRUE

/datum/interaction/cheekkiss/post_interaction(mob/living/user, mob/living/target, apply_cooldown, is_hidden)
	. = ..()
	if(user.get_lust() < 100)
		user.add_lust(3)
	if(target.get_lust() < 100)
		target.add_lust(3)

/datum/interaction/cheekkiss/display_interaction(mob/living/user, mob/living/target, is_hidden)
	var/distance = 7
	var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
	var/const/volume = 70
	if(is_hidden)
		distance = 1
	var/static/list/possible_messages = list(
		"<b>USER</b> вытянув губы бантиком, целует <b>TARGET</b> в щеку.",
		"<b>USER</b> делает легкое, почти невесомое прикосновение губ к щеке <b>TARGET</b>.",
		"<b>USER</b> губы касаются щеки <b>TARGET</b> и тут же отстраняются.",
		"<b>USER</b> громко с причмокиванием целует <b>TARGET</b> в щеку.",
		"<b>USER</b> тычет губами в щеку <b>TARGET</b> одаривая легким поцелуем.",
	)
	var/use_message = replacetext(pick(possible_messages), "USER", "\the [user]")
	use_message = replacetext(use_message, "TARGET", "\the [target]")
	user.visible_message("<span class='[simple_style]'>[is_hidden ? pick(hidden_additional) : null] [capitalize(use_message)]</span>", vision_distance = distance)

	playlewdinteractionsound(get_turf(target), pick(
		'modular_splurt/sound/interactions/kiss/kiss1.ogg',
		'modular_splurt/sound/interactions/kiss/kiss2.ogg',
		'modular_splurt/sound/interactions/kiss/kiss3.ogg',
		'modular_splurt/sound/interactions/kiss/kiss4.ogg',
		'modular_splurt/sound/interactions/kiss/kiss5.ogg'), volume, 1, extrarange, ignored_mobs = user.get_unconsenting())


////////////////////// LEWD //////////////////////


/datum/interaction/lewd/kiss
	description = "Поцеловать."
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_target = INTERACTION_REQUIRE_MOUTH
	write_log_user = "kissed"
	write_log_target = "was kissed by"
	interaction_sound = null
	p13user_emote = PLUG13_EMOTE_BASIC
	p13target_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_LOW
	p13target_strength = PLUG13_STRENGTH_LOW
	additional_details = list(
		list(
			"info" = "Приносит удовольствие, если у вас есть соответственный квирк",
			"icon" = "heart",
			"color" = "red"
		)
	)

/datum/interaction/lewd/kiss/display_interaction(mob/living/user, mob/living/partner, is_hidden)
	var/distance = 7
	if(is_hidden)
		distance = 1
	var/picked_hidden = pick(hidden_additional)
	if(user.a_intent == INTENT_HELP)
		user.visible_message(
			pick(span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> смотрит прямо в глаза \the <b>[partner]</b>, одаривая нежными прикосновениями губ."),
			span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> с трепетом касается губ \the <b>[partner]</b>."),
			span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> почти не прижимаясь к губам \the <b>[partner]</b>, дарит нежный поцелуй.")), vision_distance = distance)
	if(user.a_intent == INTENT_DISARM)
		user.visible_message(
			pick(span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> прижимается к губкам \the <b>[partner]</b>, даря смущенный поцелуй."),
			span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> осторожно касается губ \the <b>[partner]</b> своими."),
			span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> неловко прижимается к губкам \the <b>[partner]</b>.")), vision_distance = distance)
	if(user.a_intent == INTENT_GRAB)
		user.visible_message(
			pick(span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> настойчиво целует \the <b>[partner]</b>, заводя руку за шею и прижимая к себе."),
			span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> хватается руками за щёки \the <b>[partner]</b> и прижимает к своим губам."),
			span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> хватает за талию \the <b>[partner]</b> и прижимает к себе заключая в долгом поцелуе.")), vision_distance = distance)
	if(user.a_intent == INTENT_HARM)
		user.visible_message(
			pick(span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> облизывает губы \the <b>[partner]</b>, проникая языком сквозь сжатые зубы."),
			span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> бъёт по щеке \the <b>[partner]</b>, и заглушает любой звук из рта своим поцелуем."),
			span_lewd("[is_hidden ? (picked_hidden) : null]\The <b>[user]</b> душит \the <b>[partner]</b>, целуя в распухшие губы.")), vision_distance = distance)
		if(HAS_TRAIT(user, TRAIT_KISS_OF_DEATH))
			partner.reagents.add_reagent(/datum/reagent/toxin/amanitin , 4)
			user.reagents.add_reagent(/datum/reagent/toxin/amanitin , 0.5)
		else if(HAS_TRAIT(user, TRAIT_KISS_CROCIN))
			partner.reagents.add_reagent(/datum/reagent/drug/aphrodisiac, rand(5, 10))
		else if(HAS_TRAIT(user, TRAIT_KISS_SPACE_DRUGS))
			partner.reagents.add_reagent(/datum/reagent/drug/space_drugs, rand(1, 3))
		else if(HAS_TRAIT(user, TRAIT_KISS_HONK))
			partner.emote("flip")
			playsound(partner, 'sound/items/bikehorn.ogg', 50, TRUE)
		else if(HAS_TRAIT(user, TRAIT_KISS_BLOODSUCKER))
			if(iscarbon(partner))
				var/mob/living/carbon/C = partner
				if(C.blood_volume > 0)
					C.blood_volume = max(C.blood_volume - 15, 0)
		else if(HAS_TRAIT(user, TRAIT_KISS_MIME))
			partner.reagents.add_reagent(/datum/reagent/toxin/mutetoxin, rand(1, 2))
		else if(HAS_TRAIT(user, TRAIT_KISS_DRAGQUEEN))
			var/list/drugs = list(
				/datum/reagent/drug/space_drugs,
				/datum/reagent/toxin/mindbreaker,
				/datum/reagent/drug/mdma,
				/datum/reagent/drug/zvezdochka,
				/datum/reagent/drug/pendosovka
			)
			partner.reagents.add_reagent(pick(drugs), 1)
		else if(HAS_TRAIT(user, TRAIT_KISS_HEARTBOOM))
			partner.reagents.add_reagent(/datum/reagent/drug/aphrodisiac, rand(1, 5))
			new /obj/effect/temp_visual/heart(get_turf(partner))
			var/obj/effect/particle_effect/smoke/cigsmoke/puff = new(get_turf(partner))
			puff.color = "#9400D3"
			puff.alpha = 64
			puff.lifetime = 1
			var/static/list/heartboom_emotes = list(
				list("gasp", "Ты чувствуешь как леденеют твои вены и сердце на секунду замирает..."),
				list("sneeze", "Ты чихаешь от попавших тебе в нос блёсток..."),
				list("dance", "Жизнь прекрасна! Твои ноги пускаются в пляс!"),
				list("blush", "Внутри так... тепло..."),
				list("moan", "Мне так... хорошо..."),
				list("realagony", "БОЖЕ! ВНУТРИ ВСЁ ПЫЛАЕТ! ОСТАНОВИТЕ ЭТО!"),
				list("laugh", "Что-то щекочет тебя"),
				list("laugh", "Ты не можешь перестать смеяться"),
				list("pain", "Твое сердце словно пронзили иголки, а по телу распространяется холод")
			)
			var/list/chosen = pick(heartboom_emotes)
			to_chat(partner, span_love("[chosen[2]]"))
			partner.emote(chosen[1])

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.use_kiss()

/datum/interaction/lewd/kiss/proc/remove_mime_mute(mob/living/partner, mob/living/user)
	REMOVE_TRAIT(partner, TRAIT_MUTE, REF(user))


/datum/interaction/lewd/neckkiss
	description = "Поцеловать шею."
	required_from_user = INTERACTION_REQUIRE_MOUTH
	simple_message = "USER целует шею TARGET."
	simple_style = "lewd"
	write_log_user = "kissed"
	write_log_target = "was kissed by"
	interaction_sound = null

	p13user_emote = PLUG13_EMOTE_BASIC
	p13target_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_LOW
	p13target_strength = PLUG13_STRENGTH_LOW

/datum/interaction/lewd/neckkiss/post_interaction(mob/living/user, mob/living/target, apply_cooldown, is_hidden)
	. = ..()
	if(user.get_lust() < 100)
		user.add_lust(20)
	if(target.get_lust() < 100)
		target.add_lust(20)

/datum/interaction/lewd/neckkiss/display_interaction(mob/living/user, mob/living/target, is_hidden)
	var/distance = 7
	var/const/volume = 50 // Громкость меньше, т.к. pressure_affected = FALSE добавляет громкости
	var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
	if(is_hidden)
		distance = 1
	var/picked_hidden = pick(hidden_additional)
	var/static/list/possible_messages = list(
		"<b>USER</b> подтягивая к себе за плечи, прижимается к <b>TARGET</b> и целует в шею.",
		"<b>USER</b> смочив губы языком, целует шею <b>TARGET</b> прикусив её зубами.",
		"<b>USER</b> водит носом по шее, медленно целуя <b>TARGET</b> возле уха.",
		"<b>USER</b> медленно посасывает шею <b>TARGET</b> оставляя синяк от засоса.",
		"<b>USER</b> нежно прикусывает кожу на шее <b>TARGET</b> оттягивая её зубами.",
		"<b>USER</b> страстно прижимается губами к шее <b>TARGET</b> оставляя синяк от засоса.",
	)
	var/use_message = replacetext(pick(possible_messages), "USER", "\the [user]")
	use_message = replacetext(use_message, "TARGET", "\the [target]")
	user.visible_message("<span class='[simple_style]'>[is_hidden ? (picked_hidden) : null][capitalize(use_message)]</span>", vision_distance = distance)

	playlewdinteractionsound(get_turf(target), pick(
		'modular_splurt/sound/interactions/kiss/kiss1.ogg',
		'modular_splurt/sound/interactions/kiss/kiss2.ogg',
		'modular_splurt/sound/interactions/kiss/kiss3.ogg',
		'modular_splurt/sound/interactions/kiss/kiss4.ogg',
		'modular_splurt/sound/interactions/kiss/kiss5.ogg'), volume, 1, extrarange, ignored_mobs = user.get_unconsenting(), pressure_affected = FALSE)
