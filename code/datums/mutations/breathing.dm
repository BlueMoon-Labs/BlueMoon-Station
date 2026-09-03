/// No Breathing — holder does not need an atmosphere (still vulnerable to toxins, vacuum pressure without adaptation, etc.)
/datum/mutation/human/no_breathing
	name = "No Breathing"
	desc = "The host no longer needs to breathe. CPR and similar resuscitation will not work on them."
	quality = POSITIVE
	difficulty = 32
	instability = 40
	locked = TRUE
	text_gain_indication = "<span class='notice'>You feel no need to breathe.</span>"
	text_lose_indication = "<span class='danger'>You need to breathe again...</span>"

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

/datum/mutation/human/no_breathing/on_life()
	if(!owner)
		return
	// Defibrillation can stack oxyloss on mobs that do not breathe; bleed it off slowly.
	if(owner.oxyloss > 0)
		owner.adjustOxyLoss(-3)
