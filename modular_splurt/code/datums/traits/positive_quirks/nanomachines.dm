/datum/quirk/compatible_with_nanomachines
	name = "Совместимость с наномашинами"
	desc = "Ваше тело по той или иной причине приспособлено к использованию наномашин, даже если другие представители вашего вида не приспособлены"
	value = 2
	mob_trait = TRAIT_COMPATIBLE_WITH_NANOMACHINES
	gain_text = span_notice("Вы чувствуете что наномашины могут взаимодействовать с вами.")
	lose_text = span_notice("Вы чувствуете что наномашины инертны к вам.")

/datum/quirk/compatible_with_nanomachines/remove()
	SEND_SIGNAL(quirk_holder, COMSIG_NANITE_DELETE)

/datum/quirk/nanomachines_immunity
	name = "Непереносимость наномашин"
	desc = "Ваше тело отвергает наномашины, вы не сможете установить или получить их случайно."
	value = 0
	mob_trait = NANOMACHINES_IMMUNITY
	gain_text = span_notice("Вы чувствуете что ваши клетки противятся наномашинам.")
	lose_text = span_notice("Вы чувствуете что наномашины вновь могут взаимодействовать с вами.")

/datum/quirk/nanomachines_immunity/add()
	SEND_SIGNAL(quirk_holder, COMSIG_NANITE_DELETE)
