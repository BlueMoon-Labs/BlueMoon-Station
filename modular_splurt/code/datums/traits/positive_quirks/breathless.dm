/datum/quirk/breathless
	name = "Недышащий"
	desc = "Благодаря генной инженерии, технологиям или магии блюспейса вам больше не нужен воздух для жизнедеятельности. Это также означает, что проведение таких жизненно важных манипуляций, как искусственное дыхание, станет невозможным."
	value = 3
	medical_record_text = "Биологические показатели пациента свидетельствуют об отсутствии необходимости в дыхании."
	gain_text = span_notice("Вам больше не нужно дышать.")
	lose_text = span_notice("Вам нужно снова дышать...")

/datum/quirk/breathless/add()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	ADD_TRAIT(H,TRAIT_NOBREATH,ROUNDSTART_TRAIT)

/datum/quirk/breathless/remove()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	// BLUEMOON EDIT START - sanity check
	if(!H)
		return
	// BLUEMOON EDIT END
	REMOVE_TRAIT(H,TRAIT_NOBREATH, ROUNDSTART_TRAIT)
