/datum/quirk/thirsty
	name = "Жаждущий"
	desc = "Вам необычайно хочется пить. Приходится пить в два раза больше, чем обычно."
	value = 0
	flavor_quirk = TRUE
	gain_text = span_danger("Вы начинаете испытывать жажду гораздо быстрее.")
	lose_text = span_notice("Ваша повышенная тяга к воде начинает угасать.")
	medical_record_text = "Пациент сообщает, что пьет в два раза больше жидкости в день, чем обычно для его вида."

/datum/quirk/thirsty/add()
	var/mob/living/carbon/human/H = quirk_holder
	var/datum/physiology/P = H.physiology
	P.thirst_mod *= 2

/datum/quirk/thirsty/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		var/datum/physiology/P = H.physiology
		if(P)
			P.thirst_mod /= 2
