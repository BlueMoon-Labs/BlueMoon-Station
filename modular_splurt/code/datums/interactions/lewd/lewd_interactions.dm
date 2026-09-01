//help
/datum/interaction/lewd

	var/unholy = FALSE //То же самое что и эстрим вербы, но гораздо хуже.

	var/require_user_legs
	var/require_user_num_legs

	var/require_target_legs
	var/require_target_num_legs

/datum/interaction/lewd/evaluate_user(mob/living/user, silent = TRUE, apply_cooldown = TRUE)

	var/user_require_belly_exposed = !!(required_from_user_exposed & INTERACTION_REQUIRE_BELLY)
	var/user_require_belly_unexposed = !!(required_from_user_unexposed & INTERACTION_REQUIRE_BELLY)
	if(user_require_belly_exposed || user_require_belly_unexposed)
		var/has_belly = user.has_belly()
		if(!has_belly)
			if(!silent)
				to_chat(user, span_warning("У тебя нет живота."))
			return FALSE

		if(!(has_belly == TRUE) || !(user_require_belly_exposed && user_require_belly_unexposed))
			if(user_require_belly_exposed && has_belly == HAS_UNEXPOSED_GENITAL)
				if(!silent)
					to_chat(user, span_warning("Твой живот должен быть спрятан."))
				return FALSE
			if(user_require_belly_unexposed && has_belly == HAS_EXPOSED_GENITAL)
				if(!silent)
					to_chat(user, span_warning("Твой живот должен быть обнажён."))
				return FALSE

	if(require_user_legs)
		switch(require_user_legs)
			if(REQUIRE_EXPOSED)
				if(!user.has_legs(REQUIRE_EXPOSED))
					if(!silent)
						to_chat(user, "<span class='warning'>Твои ноги должны быть обнажены.</span>")
					return FALSE
			if(REQUIRE_UNEXPOSED)
				if(!user.has_legs(REQUIRE_UNEXPOSED))
					if(!silent)
						to_chat(user, "<span class='warning'>Твои ноги должны быть спрятаны.</span>")
					return FALSE
			if(REQUIRE_ANY)
				if(!user.has_legs(REQUIRE_ANY))
					if(!silent)
						to_chat(user, "<span class='warning'>У тебя не хватает ног для этого.</span>")
					return FALSE

	if(require_user_num_legs && (user.has_legs() < require_user_num_legs))
		if(!silent)
			to_chat(user, "<span class='warning'>У тебя не хватает ног для этого.</span>")
		return FALSE


	if(interaction_flags & INTERACTION_FLAG_UNHOLY_CONTENT)
		var/client/cli = user.client
		if(cli)
			if(cli.prefs.unholypref == "No")
				if(!silent)
					to_chat(user, "<span class='warning'>Для тебя это слишком.</span>")
				return FALSE

	if(interaction_flags & INTERACTION_FLAG_UNHOLY_HARD)
		var/client/cli = user.client
		if(cli)
			if(cli.prefs.unholyhardpref == "No")
				if(!silent)
					to_chat(user, "<span class='warning'>Ты не готов к такому уровню грязи.</span>")
				return FALSE

	var/user_require_penis_exposed = !!(required_from_user_exposed & INTERACTION_REQUIRE_PENIS)
	var/user_require_penis_unexposed = !!(required_from_user_unexposed & INTERACTION_REQUIRE_PENIS)
	if((user_require_penis_exposed || user_require_penis_unexposed) && !user.has_strapon())
		var/obj/item/organ/genital/penis/penor = user.getorganslot(ORGAN_SLOT_PENIS)
		if(CHECK_BITFIELD(penor?.genital_flags, GENITAL_CHASTENED))
			if(!silent)
				to_chat(user, span_warning("You can't do anything with your [pick(GLOB.dick_nouns)] like this!"))
			return FALSE

	var/user_require_vagina_exposed = !!(required_from_user_exposed & INTERACTION_REQUIRE_VAGINA)
	var/user_require_vagina_unexposed = !!(required_from_user_unexposed & INTERACTION_REQUIRE_VAGINA)
	if(user_require_vagina_exposed || user_require_vagina_unexposed)
		var/obj/item/organ/genital/vagina/puss = user.getorganslot(ORGAN_SLOT_VAGINA)
		if(CHECK_BITFIELD(puss?.genital_flags, GENITAL_CHASTENED))
			if(!silent)
				to_chat(user, span_warning("You can't do anything with your vagina like this!"))
			return FALSE

	var/user_require_anus_exposed = !!(required_from_user_exposed & INTERACTION_REQUIRE_ANUS)
	var/user_require_anus_unexposed = !!(required_from_user_unexposed & INTERACTION_REQUIRE_ANUS)
	if(user_require_anus_exposed || user_require_anus_unexposed)
		var/obj/item/organ/genital/anus/holi = user.getorganslot(ORGAN_SLOT_ANUS)
		if(holi)
			if(CHECK_BITFIELD(holi?.genital_flags, GENITAL_CHASTENED))
				if(!silent)
					to_chat(user, span_warning("You can't do anything with your [pick(GLOB.butt_nouns)] like this!"))
				return FALSE
		else
			if(HAS_TRAIT(user, TRAIT_CHASTENED_ANUS))
				if(!silent)
					to_chat(user, span_warning("You can't do anything with your [pick(GLOB.butt_nouns)] like this!"))
				return FALSE
	. = ..()

/datum/interaction/lewd/evaluate_target(mob/living/user, mob/living/target, silent = TRUE)
	var/target_require_belly_exposed = !!(required_from_target_exposed & INTERACTION_REQUIRE_BELLY)
	var/target_require_belly_unexposed = !!(required_from_target_unexposed & INTERACTION_REQUIRE_BELLY)
	if(target_require_belly_exposed || target_require_belly_unexposed)
		var/has_belly = target.has_belly()
		if(!has_belly)
			if(!silent)
				to_chat(target, span_warning("У партнёра нет живота."))
			return FALSE

		if(!(has_belly == TRUE) || !(target_require_belly_exposed && target_require_belly_unexposed))
			if(target_require_belly_exposed && has_belly == HAS_UNEXPOSED_GENITAL)
				if(!silent)
					to_chat(target, span_warning("Живот партнёра должен быть спрятан."))
				return FALSE
			if(target_require_belly_unexposed && has_belly == HAS_EXPOSED_GENITAL)
				if(!silent)
					to_chat(target, span_warning("Живот партнёра должен быть обнажёнлы."))
				return FALSE

	if(require_target_legs)
		switch(require_target_legs)
			if(REQUIRE_EXPOSED)
				if(!target.has_legs(REQUIRE_EXPOSED))
					if(!silent)
						to_chat(user, "<span class='warning'>Ноги партнёра должны быть обнажены.</span>")
					return FALSE
			if(REQUIRE_UNEXPOSED)
				if(!target.has_legs(REQUIRE_UNEXPOSED))
					if(!silent)
						to_chat(user, "<span class='warning'>Ноги партнёра должны быть спрятаны.</span>")
					return FALSE
			if(REQUIRE_ANY)
				if(!target.has_legs(REQUIRE_ANY))
					if(!silent)
						to_chat(user, "<span class='warning'>У твоего партнёра не хватает ног.</span>")
					return FALSE

	if(require_target_num_legs && (target.has_legs() < require_target_num_legs))
		if(!silent)
			to_chat(user, "<span class='warning'>Кажется, здесь не хватает ног.</span>")
		return FALSE

	if(interaction_flags & INTERACTION_FLAG_UNHOLY_CONTENT)
		var/client/cli = target.client
		if(cli)
			if(target.client.prefs.unholypref == "No")
				if(!silent)
					to_chat(user, "<span class='warning'>По какой-то причине ты передумал это делать с <b>[target]</b>.</span>")
				return FALSE

	if(interaction_flags & INTERACTION_FLAG_UNHOLY_HARD)
		var/client/cli = target.client
		if(cli)
			if(target.client.prefs.unholyhardpref == "No")
				if(!silent)
					to_chat(user, "<span class='warning'>Они не оценят такой уровень грязи.</span>")
				return FALSE

	var/target_require_penis_exposed = !!(required_from_target_exposed & INTERACTION_REQUIRE_PENIS)
	var/target_require_penis_unexposed = !!(required_from_target_unexposed & INTERACTION_REQUIRE_PENIS)
	if((target_require_penis_exposed || target_require_penis_unexposed) && !target.has_strapon())
		var/obj/item/organ/genital/penis/penor = target.getorganslot(ORGAN_SLOT_PENIS)
		if(CHECK_MULTIPLE_BITFIELDS(penor?.genital_flags, GENITAL_CHASTENED))
			if(!silent)
				to_chat(user, span_warning("You can't do anything with their [pick(GLOB.dick_nouns)] like that!"))
			return FALSE

	var/target_require_vagina_exposed = !!(required_from_target_exposed & INTERACTION_REQUIRE_VAGINA)
	var/target_require_vagina_unexposed = !!(required_from_target_unexposed & INTERACTION_REQUIRE_VAGINA)
	if(target_require_vagina_exposed || target_require_vagina_unexposed)
		var/obj/item/organ/genital/vagina/puss = target.getorganslot(ORGAN_SLOT_VAGINA)
		if(CHECK_BITFIELD(puss?.genital_flags, GENITAL_CHASTENED))
			if(!silent)
				to_chat(user, span_warning("You can't do anything with their vagina like this!"))
			return FALSE

	var/target_require_anus_exposed = !!(required_from_target_exposed & INTERACTION_REQUIRE_ANUS)
	var/target_require_anus_unexposed = !!(required_from_target_unexposed & INTERACTION_REQUIRE_ANUS)
	if(target_require_anus_exposed || target_require_anus_unexposed)
		if(HAS_TRAIT(target, TRAIT_CHASTENED_ANUS))
			if(!silent)
				to_chat(user, span_warning("You can't do anything with their [pick(GLOB.butt_nouns)] like this!"))
			return FALSE
	. = ..()

/mob/living/list_interaction_attributes(mob/living/LM)
	. = ..()
	if(has_belly() == HAS_EXPOSED_GENITAL)
		. += "...обладает выпуклым животом."
