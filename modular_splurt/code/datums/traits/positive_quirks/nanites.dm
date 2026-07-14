/datum/quirk/compatible_with_nanites
	name = "Совместимость с нанитами"
	desc = "Ваше тело по той или иной причине приспособлено к использованию нанитов, даже если другие представители вашего вида не приспособлены"
	value = 2
	mob_trait = TRAIT_COMPATIBLE_WITH_NANITES
	gain_text = span_notice("Вы чувствуете что наниты могут взаимодействовать с вами.")
	lose_text = span_notice("Вы чувствуете что наниты инертны к вам.")

/datum/quirk/compatible_with_nanites/remove()
	SEND_SIGNAL(quirk_holder, COMSIG_NANITE_DELETE)

/datum/quirk/nanites_immunity
	name = "Непереносимость нанитов"
	desc = "Ваше тело отвергает наниты, вы не сможете установить или получить их случайно."
	value = 1
	mob_trait = TRAIT_NANITES_IMMUNITY
	gain_text = span_notice("Вы чувствуете что ваши клетки противятся нанитам.")
	lose_text = span_notice("Вы чувствуете что наниты вновь могут взаимодействовать с вами.")

/datum/quirk/nanites_immunity/add()
	SEND_SIGNAL(quirk_holder, COMSIG_NANITE_DELETE)
