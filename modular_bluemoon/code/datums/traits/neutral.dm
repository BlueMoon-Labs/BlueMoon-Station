// TRAIT_AWOO BEGIN
/datum/quirk/awoo
	name = "Неконтролируемый вой"
	desc = "Вам иногда нравиться завывать, есть ли на то причиниа или нет. Также вы не можете удержаться перед воем других."
	value = 0
	gain_text = "<span class='notice'>Иногда так хочется повыть...</span>"
	lose_text = "<span class='notice'>Я больше не хочу выть.</span>"
	mob_trait = TRAIT_AWOO
	flavor_quirk = TRUE
	var/timer
	var/timer_trigger
	var/min_trigger_time = 6000		//10 minutes
	var/max_trigger_time = 12000	//20 minutes
	var/last_awoo
	mood_quirk = TRUE

/datum/quirk/awoo/add()
	timer_trigger = rand(min_trigger_time, max_trigger_time)
	timer = addtimer(CALLBACK(src, PROC_REF(do_awoo)), timer_trigger, TIMER_STOPPABLE)
	last_awoo = world.time
	RegisterSignal(quirk_holder, COMSIG_MOB_EMOTE, PROC_REF(awoo_emote))

/datum/quirk/awoo/remove()
	deltimer(timer)
	UnregisterSignal(quirk_holder, COMSIG_MOB_EMOTE)

/datum/quirk/awoo/proc/awoo_emote(datum/source, datum/emote/emote)
	SIGNAL_HANDLER
	if(findtext(emote.key, "awoo") || findtext(emote.key, "howl"))
		last_awoo = world.time
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "to_awoo", /datum/mood_event/to_awoo)

/** Triggers on timer and when certain audio file has been heard by this mob.
 * Audio file is being checked in sound.dm in the middle of /playsound_local(). Not convenient but necessary.
 * If do_awoo() is no longer being triggered by external source (other mobs), check audio file paths for "awoo" and "howl" emotes and make proper corrections in /playsound_local().
*/
/datum/quirk/awoo/proc/do_awoo()
	if((last_awoo + 10 SECONDS) < world.time)
		if(quirk_holder.stat == CONSCIOUS)
			last_awoo = world.time	//let the cycle be discontinued.
			quirk_holder.nextsoundemote = world.time - 10
			addtimer(CALLBACK(quirk_holder, TYPE_PROC_REF(/mob, emote), pick("awoo", "howl")), rand(10,30))
	//We don't care if mob has awoo'ed or not. It either did it right now or it can't do it anytime soon. We update timer anyway.
	deltimer(timer)
	timer = null
	timer_trigger = rand(min_trigger_time, max_trigger_time)
	timer = addtimer(CALLBACK(src, PROC_REF(do_awoo)), timer_trigger, TIMER_STOPPABLE)

/datum/emote/sound/human/awoo
	emote_volume = 100
	emote_range = MEDIUM_RANGE_SOUND_EXTRARANGE
	emote_falloff_exponent = 1
	emote_distance_multiplier_min_range = 12
	emote_ignore_walls = TRUE

/datum/emote/sound/human/howl
	emote_volume = 100
	emote_range = MEDIUM_RANGE_SOUND_EXTRARANGE
	emote_falloff_exponent = 1
	emote_distance_multiplier_min_range = 12
	emote_ignore_walls = TRUE
// TRAITT_AWOO END

/datum/quirk/clearly_audible
	name = "Хорошо слышимый"
	desc = "Объясняя вашу маленькость вас уж точно услышат (позволяет при маленьком размере иметь хорошо слышимую речь)"
	value = 0
	mob_trait = TRAIT_BLUEMOON_CLEARLY_AUDIBLE
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Ваш голос звучит ещё более звонко!</span>"
	lose_text = "<span class='danger'>Кхе-кхе...</span>"

/datum/quirk/clearly_audible/add()
	quirk_holder.RemoveElement(/datum/element/smalltalk)

/datum/quirk/clearly_audible/remove()
	quirk_holder.adjust_mobsize() //ленивое добавление /datum/element/smalltalk если нужно

/datum/quirk/anti_normalizer
	name = "Невосприимчивость к нормалайзеру"
	desc = "Syntech производит устройства-нормалайзеры, подводящие параметры размера существ к человеческим. \
	По тем или иным причинам, на вас эта технология почти не работает, как и их size tool. Однако модифицированная под вас версия \
	нормализатора (из loadout) способна создать нужный эффект."
	value = 0
	mob_trait = TRAIT_BLUEMOON_ANTI_NORMALIZER
	gain_text = "<span class='notice'>В последний раз, когда вы пытались надеть нормалайзер, он не работал.</span>"
	lose_text = "<span class='notice'>Может быть стоит попробовать надеть нормалайзер и теперь он будет работать?</span>"
	medical_record_text = "Пациент обладает параметрами, которые делают его неподходящим кандидатом для нормалайзеров и части других девайсов от Syntech."

/datum/quirk/spiky
	name = "Колючий"
	desc = "Ваше тело частично или полностью покрыто острыми иглами. Любой, кто попытается вас потрогать, рискует пораниться."
	value = 0
	flavor_quirk = TRUE
	mob_trait = TRAIT_SPIKY

/datum/quirk/nt_employee
	name = "Сотрудник НаноТрейзен"
	desc = "Вы обычный сотрудник НаноТрейзен. В начале смены вы получаете корпоративный бейдж и знание корпоративного языка."
	value = 0
	flavor_quirk = TRUE
	mood_quirk = FALSE
	processing_quirk = FALSE

/datum/quirk/nt_employee/on_spawn()
	. = ..()

	quirk_holder.grant_language(/datum/language/corpspeak, source = LANGUAGE_MIND)
	give_item(/obj/item/clothing/accessory/badge_nt, quirk_holder)

/datum/quirk/syndi_employee
	name = "Сотрудник Синдиката"
	desc = "Вы обычный сотрудник Синдиката. В начале смены вы получаете корпоративный бейдж и знание кодового языка."
	value = 0
	flavor_quirk = TRUE
	mood_quirk = FALSE
	processing_quirk = FALSE

/datum/quirk/syndi_employee/on_spawn()
	. = ..()

	quirk_holder.grant_language(/datum/language/codespeak, source = LANGUAGE_MIND)
	give_item(/obj/item/clothing/accessory/badge_syndi, quirk_holder)

/datum/quirk/lewdjob
	name = "Секс это работа"
	desc = "Ничего личного, просто бизнес. В моменты интимной близости у вас над головой не будут появляться сердечки."
	flavor_quirk = TRUE
	mob_trait = TRAIT_LEWD_JOB

/datum/quirk/common_pregnancy
	name = "Обычная беременность"
	desc = "Ваша беременность протекает как у нормального млекопитающего и вы не откладываете яйца! Залетев, вы не скоро родите ребёнка!"
	value = 0
	mob_trait = TRAIT_COMMON_PREGNANCY
	flavor_quirk = TRUE
	gain_text = span_notice("Ваша беременность будет протекать нормально.")
	lose_text = span_notice("Теперь вы будете откладывать яйца.")
	medical_record_text = "Беременность у пациента протекает как у нормальных млекопитающих."

/datum/quirk/bondage_lover
	name = "Любитель бондажа"
	desc = "Вы обожаете быть связанным! Вам нравится в этом всё, особенно беспомощность!"
	value = 0
	mob_trait = TRAIT_BONDAGED
	flavor_quirk = TRUE
	gain_text = span_notice("Вы чувствуете что вам хотелось бы быть связанным.")
	lose_text = span_notice("Вы больше не чувствуете что вам хотелось бы быть связанным.")
	medical_record_text = "Пациент возможно имеет Стокгольмский синдром."

/datum/quirk/bondage_lover/remove()
	// Remove mood event
	SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, QMOOD_BONDAGE)

/datum/quirk/imaginary_friend
	name = "Воображаемый друг"
	desc = "У вас появился друг в голове. Кто знает, поможет он вам, или нет... Только не соглашайтесь на его предложение сделать клуб!"
	value = 0
	mob_trait = TRAIT_IMAGINARYFRIEND
	//gain_text handled be trauma
	//lose_text handled be trauma
	medical_record_text = "У пациента присутсвует \"Воображаемый Друг\"."
	on_spawn_immediate = FALSE

/datum/quirk/imaginary_friend/add()
	var/mob/living/carbon/human/H = quirk_holder
	H.gain_trauma(/datum/brain_trauma/special/imaginary_friend, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/imaginary_friend/remove()
	var/mob/living/carbon/human/H = quirk_holder
	H.cure_trauma_type(/datum/brain_trauma/special/imaginary_friend, TRAUMA_RESILIENCE_ABSOLUTE)
