/datum/interaction/handshake
	description = "Пожать руку."
	simple_message = "USER пожимает руку TARGET."
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

/datum/interaction/pat
	description = "Похлопать по плечу."
	simple_message = "USER хлопает TARGET по плечу."
	required_from_user = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

/datum/interaction/cheer
	description = "Подбодрить посвистыванием!"
	required_from_user = INTERACTION_REQUIRE_MOUTH
	simple_message = "USER подбадривает TARGET радостным посвистыванием!"
	interaction_sound = 'modular_bluemoon/sound/emotes/svist.ogg'
	max_distance = 25
	interaction_flags = NONE

/datum/interaction/highfive
	description = "Дать пять!"
	simple_message = "USER даёт пять TARGET!"
	interaction_sound = 'modular_sand/sound/interactions/slap.ogg'
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target = INTERACTION_REQUIRE_HANDS

/datum/interaction/headpat
	description = "Погладить по голове"
	simple_message = "USER гладит TARGET по голове." //BLUEMOON EDIT
	required_from_user = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

	p13target_emote = PLUG13_EMOTE_BASIC
	p13target_strength = PLUG13_STRENGTH_LOW_PLUS
	p13target_duration = PLUG13_DURATION_SHORT

//BLUEMOON ADD START
/datum/interaction/headpat/post_interaction(mob/living/user, mob/living/target)
	. = ..()

	if(HAS_TRAIT(target, TRAIT_DISTANT))
		to_chat(user, span_warning("[capitalize(target.name)] отстраняется от тебя, не желая таких прикосновений."))
		to_chat(target, span_warning("Ты чувствуешь раздражение, когда [user] трогает тебя за голову."))

		if(prob(20) && !HAS_TRAIT(target, TRAIT_PACIFISM) && !HAS_TRAIT(user, TRAIT_PACIFISM))
			user.visible_message(
				span_warning("<b>[target]</b> внезапно выкручивает руку <b>[user]</b>!"),
				span_boldwarning("Ты чувствуешь, как <b>[target]</b> резко выкручивает тебе руку! Лучше не трогать его!"),
				target_message = span_warning("Ты ловко выкручиваешь руку <b>[user]</b> за попытку прикоснуться к тебе.")
			)
			user.emote("realagony")
			user.dropItemToGround(user.get_active_held_item())

			var/hand = pick(BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			user.apply_damage(50, STAMINA, hand)
			user.apply_damage(5, BRUTE, hand)
			user.Knockdown(60) // STOP TOUCHING ME!

		return

	if(HAS_TRAIT(target, TRAIT_HEADPAT_SLUT))
		SEND_SIGNAL(target, COMSIG_ADD_MOOD_EVENT, "lewd_headpat", /datum/mood_event/lewd_headpat)
		target.handle_post_sex(5, null, target)
	else
		SEND_SIGNAL(target, COMSIG_ADD_MOOD_EVENT, "headpat", /datum/mood_event/headpat)


/datum/interaction/headpat/display_interaction(mob/living/user, mob/living/target)
	. = ..()

	if(HAS_TRAIT(target, TRAIT_DISTANT))
		user.visible_message(
			span_warning("<b>[user]</b> тянется, чтобы погладить <b>[target]</b> по голове, но тот раздражённо отстраняется."),
			span_warning("Ты пытаешься погладить <b>[target]</b> по голове, но он отстраняется и выглядит недовольным."),
			target_message = span_warning("<b>[user]</b> тянется к твоей голове, но ты раздражённо отстраняешься.")
		)
		return

	if(HAS_TRAIT(target, TRAIT_HEADPAT_SLUT))
		new /obj/effect/temp_visual/heart(target.loc)

//BLUEMOON ADD END

/datum/interaction/fistbump
	description = "Удариться кулачками!"
	simple_message = "USER бьётся кулачком о кулачком TARGET! О да!"
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target = INTERACTION_REQUIRE_HANDS

/datum/interaction/pinkypromise
	description = "Пообещать что-то на мизинчиках."
	simple_message = "USER хватается своим мизинчиком за мизинчик TARGET! Клятва Мизинчиками! Давно пора!"
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target = INTERACTION_REQUIRE_HANDS

/datum/interaction/holdhand
	description = "Взяться за руку."
	simple_message = "USER хватается за руку TARGET."
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

/datum/interaction/salute
	description = "Исполнить Воинское Приветствие!"
	simple_message = "USER исполняет воинское приветствие при виде TARGET!"
	required_from_user = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'sound/voice/salute.ogg'
	max_distance = 25
	interaction_flags = NONE

/datum/interaction/handwave
	description = "Помахать рукой."
	simple_message = "USER приветливо машет TARGET."
	required_from_user = INTERACTION_REQUIRE_HANDS
	max_distance = 25
	interaction_flags = NONE

/datum/interaction/bird
	description = "Показать Средний Палец"
	simple_message = "USER демонстрирует TARGET средний палец!"
	required_from_user = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'modular_splurt/sound/voice/vineboom.ogg'
	max_distance = 25
	interaction_flags = NONE
