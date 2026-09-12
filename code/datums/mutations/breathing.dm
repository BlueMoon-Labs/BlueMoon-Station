/// No Breathing — holder does not need an atmosphere (still vulnerable to toxins, vacuum pressure without adaptation, etc.)
/datum/mutation/human/no_breathing
	name = "Недышащий"
	desc = "У носителя больше нет потребности в дыхании. СЛР и схожие виды реанимаций не сработают для него."
	quality = POSITIVE
	difficulty = 32
	instability = 40
	locked = TRUE
	text_gain_indication = "<span class='notice'>Вам больше не нужно дышать.</span>"
	text_lose_indication = "<span class='danger'>Вам снова нужен кислород для жизни...</span>"

/datum/mutation/human/no_breathing/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	if(HAS_TRAIT(owner, TRAIT_NOBREATH))
		instability = 0
		return
	ADD_TRAIT(owner, TRAIT_NOBREATH, GENETIC_MUTATION)

/datum/mutation/human/no_breathing/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	REMOVE_TRAIT(owner, TRAIT_NOBREATH, GENETIC_MUTATION)
