/datum/quirk/storage_concealment
	name = "Имплант Для Дорсуалифоба"
	desc = "У вас вызывает отвращение сама идея быть увиденным с любой ёмкостью для переноски, закрепленной на спине! Новая технология скрывает объект за вашей спиной, таким образом защищая вас от безмерного стыда."
	// UNUSED: Enable by setting these values to TRUE
	// The shame is unbearable
	mood_quirk = FALSE
	processing_quirk = FALSE

/datum/quirk/storage_concealment/on_spawn()
	. = ..()
	if(locate(/obj/item/implant/hide_backpack) in quirk_holder.implants)
		return

	// Восстанавливаем встроенный имплант, только если его ещё нет в теле.
	var/obj/item/implant/hide_backpack/put_in = new

	if(!put_in.implant(quirk_holder, null, TRUE, TRUE))
		qdel(put_in)

/datum/quirk/storage_concealment/on_process()
	// This trait should only be applied by the augment
	// Check the quirk holder for the trait
	if(HAS_TRAIT(quirk_holder, TRAIT_HIDE_BACKPACK))
		// When found: Mood bonus
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, QMOOD_HIDE_BAG, /datum/mood_event/dorsualiphobic_mood_positive)
	else
		// When not found: Mood penalty
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, QMOOD_HIDE_BAG, /datum/mood_event/dorsualiphobic_mood_negative)
