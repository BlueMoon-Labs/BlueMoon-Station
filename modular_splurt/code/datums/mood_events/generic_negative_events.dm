/datum/mood_event/masked_mook_incomplete
	description = span_warning("Без противогаза я ощущаю себя неполноценно...\n")
	mood_change = -4

/datum/mood_event/creampie/cheesed
	description = span_warning("Меня обдало сыром!\n") // Честно говоря, не совсем продумал варианты перевода для фразы "I've been cheesed". Возможно вернусь к ней позже.

/datum/mood_event/creampie/cheesed/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/actual_owner = owner_mob()

	if(!ishuman(actual_owner))
		return .
	if(iscatperson(actual_owner))
		description = span_warning("<b>СЫЫЫЫР!!! УААААААААААААААААААААА!!!</b>\n")
		mood_change = -5
		timeout = 5 MINUTES

/datum/mood_event/nudist_negative
	description = span_warning("Мне не очень комфортно носить это.\n")
	mood_change = -4

/datum/mood_event/dorsualiphobic_mood_negative
	description = span_warning("Не могу позволить окружающим узнать, ношу я рюкзак или нет!\n")
	mood_change = -4

// Matches drinking synth blood (drankblood_synth)
/datum/mood_event/drankblood_slime
	description = span_boldwarning("Пить жидкого слайма...а что со мной не так?\n")
	mood_change = -7
	timeout = 15 MINUTES

/datum/mood_event/drank_cursed_bad
	description = span_warning("Ощущаю, что кровь, выпитая мной, была проклятой...\n")
	mood_change = -1
	timeout = 2 MINUTES

// Matches drinking shared exotic blood
/datum/mood_event/drankblood_insect
	description = span_boldwarning("Пить гемолимфу насекомых...да что со мной не так?\n")
	mood_change = -2
	timeout = 2 MINUTES

/datum/mood_event/drankblood_xeno
	description = span_boldwarning("Пить ксенобиологическую кровь...да что со мной не так?\n")
	mood_change = -2
	timeout = 2 MINUTES
