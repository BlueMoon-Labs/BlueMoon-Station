/mob/living/carbon/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()

	if (!ishuman(user))
		return .

	if (!isnull(held_item))
		if(user != src && held_item.can_give())
			LAZYSET(context[SCREENTIP_CONTEXT_RMB], INTENT_HELP, "Передать")
			return CONTEXTUAL_SCREENTIP_SET
		return .

	if(user == src)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_HELP, "Осмотреть раны")
	else if(!lying)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_HELP, "Утешить")
	else if (health >= 0 && !HAS_TRAIT(src, TRAIT_FAKEDEATH))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_HELP, "Растормошить")
	else
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_HELP, "Сделать СЛР")

	LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_DISARM, "Обезоружить")
	if(src != user)
		LAZYSET(context[SCREENTIP_CONTEXT_RMB], INTENT_DISARM, "Толкнуть")

	if(src != user)
		if (pulledby == user)
			switch (user.grab_state)
				if (GRAB_PASSIVE)
					LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_GRAB, "Схватить крепче")
				if (GRAB_AGGRESSIVE)
					LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_GRAB, "Взять за шею")
				if (GRAB_NECK)
					LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_GRAB, "Душить")
				else
					return .
		else
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_GRAB, "Схватить")

	LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_HARM, "Ударить")

	// Monkeys cannot be grabbed harder using ctrl-click, don't ask.
	if((pulledby != user) && (src != user))
		LAZYSET(context[SCREENTIP_CONTEXT_CTRL_LMB], INTENT_ANY, "Потянуть")
	if((user == src) && lying)
		LAZYSET(context[SCREENTIP_CONTEXT_RMB], INTENT_ANY, "Подняться")

	return CONTEXTUAL_SCREENTIP_SET
