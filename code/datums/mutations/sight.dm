//Nearsightedness restricts your vision by several tiles.
/datum/mutation/human/nearsight
	name = "Near Sightness"
	desc = "Носитель этой мутации плохо видит."
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
	desc = "Делает носителя полностью слепым."
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
	desc = "Носитель этого генома может визуально различать уникальную тепловую сигнатуру человека."
	quality = POSITIVE
	mutator_security_level = THERMAL_PRINT_CODE
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
	desc = "Нестабильный бывший рентгеновский геном, теперь просто дающий носителю тепловое зрение." //actual x-ray would mean you'd constantly be blasting rads, wich might be fun for later //hmb
	mutator_security_level = XRAY_PRINT_CODE
	text_gain_indication = "<span class='notice'>The walls suddenly disappear!</span>"
	instability = 50
	locked = TRUE
	visionflag = TRAIT_XRAY_VISION


//Laser Eyes lets you shoot lasers from your eyes!
// Скорострельность фиксированная: /mob/living/LaserEyes() проверяет КД с ignore_mod = TRUE,
// поэтому ускорение атаки (например, берсеркер) на ген не влияет.
/datum/mutation/human/laser_eyes
	name = "Laser Eyes"
	desc = "Отражает концентрированный свет от глаз."
	quality = POSITIVE
	mutator_security_level = LASEREYES_PRINT_CODE
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
		if(HAS_TRAIT(owner, TRAIT_PACIFISM))
			to_chat(owner, span_notice("Это может обжечь других! Вы не хотите рисковать навредить кому-либо..."))
			return
		owner.LaserEyes(target, mouseparams)

/// Только реальный выстрел лазерных глаз снимает модификаторы скорости с общего гейта клика.
/mob/living/carbon/human/laser_eyes_click(atom/A)
	if(a_intent != INTENT_HARM || throw_mode || restrained() || get_active_held_item() || !dna || HAS_TRAIT(src, TRAIT_PACIFISM))
		return FALSE
	var/carries_laser_eyes = FALSE
	for(var/datum/mutation/human/laser_eyes/LE in dna.mutations)
		carries_laser_eyes = TRUE
		break
	// Должен быть тот же путь, что ведёт в RangedAttack(), иначе гейт меняется для других действий.
	if(!carries_laser_eyes || in_direct_access(A) || !loc || !loc.AllowClick() || CanReach(A, null))
		return FALSE
	return TRUE

/// Flash Protection — immune to handheld flashes and flashbangs (not welding arcs).
/datum/mutation/human/flash_protection
	name = "Flash Protection"
	desc = "Глаза носителя устойчивы к слепящему свету вспышек и светошумовых гранат."
	quality = POSITIVE
	mutator_security_level = FLASHPROTECT_PRINT_CODE
	difficulty = 12
	instability = 25
	locked = TRUE
	limb_req = BODY_ZONE_HEAD
	text_gain_indication = "<span class='notice'>You stop noticing the glare from bright lights...</span>"
	text_lose_indication = "<span class='danger'>Bright lights sting your eyes again.</span>"

/datum/mutation/human/flash_protection/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	ADD_TRAIT(owner, TRAIT_NOFLASH, GENETIC_MUTATION)

/datum/mutation/human/flash_protection/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	REMOVE_TRAIT(owner, TRAIT_NOFLASH, GENETIC_MUTATION)
