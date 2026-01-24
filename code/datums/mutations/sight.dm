//Nearsightedness restricts your vision by several tiles.
/datum/mutation/human/nearsight
	name = "Near Sightness"
	desc = "The holder of this mutation has poor eyesight."
	quality = MINOR_NEGATIVE
	text_gain_indication = "<span class='danger'>You can't see very well.</span>"

/datum/mutation/human/nearsight/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	owner.become_nearsighted(GENETIC_MUTATION)

/datum/mutation/human/nearsight/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	owner.cure_nearsighted(GENETIC_MUTATION)


//Blind makes you blind. Who knew?
/datum/mutation/human/blind
	name = "Blindness"
	desc = "Renders the subject completely blind."
	quality = NEGATIVE
	text_gain_indication = "<span class='danger'>You can't seem to see anything.</span>"

/datum/mutation/human/blind/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	owner.become_blind(GENETIC_MUTATION)
	RegisterSignal(owner, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))

/datum/mutation/human/blind/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	owner.cure_blind(GENETIC_MUTATION)
	UnregisterSignal(owner, COMSIG_PARENT_EXAMINE)

/datum/mutation/human/blind/proc/on_examine_holder(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list)
	examine_list += "<span class='warning'>[owner.ru_ego(TRUE)] глаза мутные и остекленелые...</span>"

///Thermal Vision lets you see mobs through walls
/datum/mutation/human/thermal
	name = "Thermal Vision"
	desc = "The user of this genome can visually percieve the unique human thermal signature."
	quality = POSITIVE
	difficulty = 18
	text_gain_indication = "<span class='notice'>You can see the heat rising off of your skin...</span>"
	time_coeff = 2
	instability = 40
	locked = TRUE
	var/visionflag = TRAIT_THERMAL_VISION

/datum/mutation/human/thermal/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return

	ADD_TRAIT(owner, visionflag, GENETIC_MUTATION)
	owner.update_sight()

/datum/mutation/human/thermal/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	REMOVE_TRAIT(owner, visionflag, GENETIC_MUTATION)
	owner.update_sight()

///X-ray Vision lets you see through walls. BlueMoon 03.07-23 - removed prior the rework
/datum/mutation/human/thermal/x_ray
	name = "X-Ray Vision"
	desc = "An unstable former X-Ray genome, now simply applying the thermal vision for user." //actual x-ray would mean you'd constantly be blasting rads, wich might be fun for later //hmb
	text_gain_indication = "<span class='notice'>The walls suddenly disappear!</span>"
	instability = 50
	locked = TRUE
	visionflag = TRAIT_XRAY_VISION // BLUEMOON CHANGE


//Laser Eyes lets you shoot lasers from your eyes!
/datum/mutation/human/laser_eyes
	name = "Laser Eyes"
	desc = "Reflects concentrated light back from the eyes."
	quality = POSITIVE
	locked = TRUE
	difficulty = 16
	text_gain_indication = "<span class='notice'>You feel pressure building up behind your eyes.</span>"
	layer_used = FRONT_MUTATIONS_LAYER
	limb_req = BODY_ZONE_HEAD

/datum/mutation/human/laser_eyes/New(class_ = MUT_OTHER, timer, datum/mutation/human/copymut)
	..()
	visual_indicators |= mutable_appearance('icons/effects/genetics.dmi', "lasereyes", -FRONT_MUTATIONS_LAYER)

/datum/mutation/human/laser_eyes/get_visual_indicator()
	return visual_indicators[1]

/datum/mutation/human/laser_eyes/on_ranged_attack(atom/target, mouseparams)
	if(owner.a_intent == INTENT_HARM)
		owner.LaserEyes(target, mouseparams)
