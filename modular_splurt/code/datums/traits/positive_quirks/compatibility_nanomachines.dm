/datum/quirk/compatible_with_nanomachines
	name = "Совместимость с наномашинами"
	desc = "Ваше тело по той или иной причине приспособлено к использованию наномашин, даже если другие представители вашего вида не приспособлены"
	value = 2
	mob_trait = TRAIT_COMPATIBLE_WITH_NANOMACHINES
	gain_text = span_notice("Вы чувствуете что наномашины могут взаимодействовать с вами")
	lose_text = span_notice("Вы чувствуете что наномашины инертны к вам")

/datum/quirk/compatible_with_nanomachines/remove()
	var/mob/living/carbon/human/H = quirk_holder
	SEND_SIGNAL(H, COMSIG_NANITE_DELETE)


