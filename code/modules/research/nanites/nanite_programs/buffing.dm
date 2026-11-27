//Programs that buff the host in generally passive ways.

/datum/nanite_program/nervous
	name = "Nerve Support"
	desc = "Наниты работают как вторичная нервная система, сокращая время оглушения носителя."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/nervous/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		H.physiology.stun_mod *= 0.5

/datum/nanite_program/nervous/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		//носитель уничтожается: human/Destroy удаляет physiology раньше содержимого,
		//где умирают наниты - возвращать модификаторы некому
		if(isnull(H.physiology))
			return
		H.physiology.stun_mod *= 2

/datum/nanite_program/adrenaline
	name = "Adrenaline Burst"
	desc = "При срабатывании наниты выбрасывают порцию адреналина, выводя носителя из оглушения и временно увеличивая его скорость."
	can_trigger = TRUE
	trigger_cost = 25
	trigger_cooldown = 1200
	rogue_types = list(/datum/nanite_program/toxic, /datum/nanite_program/nerve_decay)

/datum/nanite_program/adrenaline/on_trigger()
	host_mob.do_adrenaline(50, TRUE, TRUE, FALSE, TRUE, list(), "<span class='notice'>You feel a sudden surge of energy!</span>", 25)

/datum/nanite_program/hardening
	name = "Dermal Hardening"
	desc = "Наниты формируют сетку под кожей носителя, защищая его от ударов в ближнем бою и пуль."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/skin_decay)

//TODO on_hit effect that turns skin grey for a moment

/datum/nanite_program/hardening/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		H.physiology.armor.melee += 35
		H.physiology.armor.bullet += 35

/datum/nanite_program/hardening/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		if(isnull(H.physiology)) //см. nervous - "Cannot read null.armor" при смерти носителя
			return
		H.physiology.armor.melee -= 35
		H.physiology.armor.bullet -= 35

/datum/nanite_program/refractive
	name = "Dermal Refractive Surface"
	desc = "Наниты образуют мембрану над кожей носителя, снижая эффект лазерных и энергетических атак."
	use_rate = 0.50
	rogue_types = list(/datum/nanite_program/skin_decay)

/datum/nanite_program/refractive/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		H.physiology.armor.laser += 35
		H.physiology.armor.energy += 35

/datum/nanite_program/refractive/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		if(isnull(H.physiology)) //см. nervous - тот же путь смерти носителя
			return
		H.physiology.armor.laser -= 35
		H.physiology.armor.energy -= 35

/datum/nanite_program/coagulating
	name = "Rapid Coagulation"
	desc = "При ранении носителя наниты вызывают быстрое свёртывание крови, резко снижая скорость кровотечения."
	use_rate = 0.10
	rogue_types = list(/datum/nanite_program/suffocating)

/datum/nanite_program/coagulating/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		H.physiology.bleed_mod *= 0.1

/datum/nanite_program/coagulating/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		if(isnull(H.physiology)) //см. nervous - тот же путь смерти носителя
			return
		H.physiology.bleed_mod *= 10

/datum/nanite_program/conductive
	name = "Electric Conduction"
	desc = "Наниты работают как заземляющий стержень для электрических разрядов, защищая носителя. Разряды всё ещё могут повредить сами наниты."
	use_rate = 0.20
	program_flags = NANITE_SHOCK_IMMUNE
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/conductive/enable_passive_effect()
	. = ..()
	ADD_TRAIT(host_mob, TRAIT_SHOCKIMMUNE, "nanites")

/datum/nanite_program/conductive/disable_passive_effect()
	. = ..()
	REMOVE_TRAIT(host_mob, TRAIT_SHOCKIMMUNE, "nanites")

/datum/nanite_program/mindshield
	name = "Mental Barrier"
	desc = "Наниты образуют защитную мембрану вокруг мозга носителя, ограждая его от аномальных воздействий, пока активны."
	use_rate = 0.40
	rogue_types = list(/datum/nanite_program/brain_decay, /datum/nanite_program/brain_misfire)

/datum/nanite_program/mindshield/enable_passive_effect()
	. = ..()
	if(!host_mob.mind?.has_antag_datum(/datum/antagonist/rev, TRUE)) //won't work if on a rev, to avoid having implanted revs.
		ADD_TRAIT(host_mob, TRAIT_MINDSHIELD, "nanites")
		host_mob.sec_hud_set_implants()

/datum/nanite_program/mindshield/disable_passive_effect()
	. = ..()
	REMOVE_TRAIT(host_mob, TRAIT_MINDSHIELD, "nanites")
	host_mob.sec_hud_set_implants()
