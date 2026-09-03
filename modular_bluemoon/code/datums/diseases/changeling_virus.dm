/// Синтетическая «болезнь» для отображения на мед. ХУДах и анализаторах (реальная механика — /datum/component/changeling_zombie_infection).
/datum/disease/changeling_virus
	form = "Virus"
	name = "Cryptogenic polymorph strain"
	desc = "Aberrant tissue markers consistent with xenomorphic enzyme exposure — possibly changeling-adjacent."
	agent = "Cryptogenic xenomorph-linked prions"
	spread_text = "Non-contagious; associated with polymorph-class tissue contact"
	cure_text = "High-dose spaceacillin with sufficient blood toxin load, or aggressive toxin purge once the infection window is open (medical protocol)."
	max_stages = 1
	stage = 1
	stage_prob = 0
	severity = DISEASE_SEVERITY_DANGEROUS
	disease_flags = CAN_CARRY | CAN_RESIST
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	infectivity = 0
	viable_mobtypes = list(/mob/living/carbon/human)
	bypasses_immunity = TRUE
	infectable_biotypes = MOB_ORGANIC

/datum/disease/changeling_virus/stage_act()
	// Симптомы и прогресс инфекции обрабатываются компонентом changeling_zombie_infection.
	return
