//Programs that heal the host in some way.

/datum/nanite_program/regenerative
	name = "Accelerated Regeneration"
	desc = "Наниты усиливают естественную регенерацию носителя, ускоряя заживление. Не расходуют наниты, пока носитель невредим."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/regenerative/check_conditions()
	if(!host_mob.getBruteLoss() && !host_mob.getFireLoss())
		return FALSE
	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		var/list/parts = C.get_damaged_bodyparts(TRUE,TRUE, status = list(BODYPART_ORGANIC, BODYPART_NANITES))
		if(!parts.len)
			return FALSE
	return ..()

/datum/nanite_program/regenerative/active_effect()
	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		var/list/parts = C.get_damaged_bodyparts(TRUE,TRUE, status = list(BODYPART_ORGANIC, BODYPART_NANITES))
		if(!parts.len)
			return
		// Heal every limb first and recompute health once — letting each limb run
		// its own updatehealth() made this program cost milliseconds per tick.
		var/update = FALSE
		for(var/obj/item/bodypart/L in parts)
			if(L.heal_damage(0.5/parts.len, 0.5/parts.len, updating_health = FALSE))
				update = TRUE
		host_mob.updatehealth()
		if(update)
			host_mob.update_damage_overlays()
	else
		host_mob.adjustBruteLoss(-0.5, TRUE)
		host_mob.adjustFireLoss(-0.5, TRUE)

/datum/nanite_program/temperature
	name = "Temperature Adjustment"
	desc = "Наниты поддерживают внутреннюю температуру носителя на идеальном уровне. Не расходуют наниты при нормальной температуре тела."
	use_rate = 3.5
	rogue_types = list(/datum/nanite_program/skin_decay)

/datum/nanite_program/temperature/check_conditions()
	if(host_mob.bodytemperature > (BODYTEMP_NORMAL - 30) && host_mob.bodytemperature < (BODYTEMP_NORMAL + 30))
		return FALSE
	return ..()

/datum/nanite_program/temperature/active_effect()
	if(host_mob.bodytemperature > BODYTEMP_NORMAL)
		host_mob.adjust_bodytemperature(-40 * TEMPERATURE_DAMAGE_COEFFICIENT, BODYTEMP_NORMAL)
	else if(host_mob.bodytemperature < (BODYTEMP_NORMAL + 1))
		host_mob.adjust_bodytemperature(40 * TEMPERATURE_DAMAGE_COEFFICIENT, 0, BODYTEMP_NORMAL)

/datum/nanite_program/purging
	name = "Blood Purification"
	desc = "Наниты выводят токсины и химикаты из крови носителя, однако из-за неточности это опасно для биологии слизней."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/suffocating, /datum/nanite_program/necrotic)

/datum/nanite_program/purging/check_conditions()
	. = ..()
	if(!. || !host_mob.reagents)
		return FALSE // No trying to purge simple mobs
	var/foreign_reagent = length(host_mob.reagents?.reagent_list)
	if(!host_mob.getToxLoss() && !foreign_reagent)
		return FALSE

/datum/nanite_program/purging/active_effect()
	host_mob.adjustToxLoss(-1)
	for(var/datum/reagent/R in host_mob.reagents.reagent_list)
		if(R.type == /datum/reagent/fermi/nanite_b_gone)
			host_mob.adjustToxLoss(4)
			continue
		host_mob.reagents.remove_reagent(R.type,1)

/datum/nanite_program/purging_synth
	name = "Purge Corruption"
	desc = "Наниты очищают схемы позитронного мозга носителя от коррозии."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/suffocating, /datum/nanite_program/necrotic)

/datum/nanite_program/purging_synth/check_conditions()
	. = ..()
	if(!. || !host_mob.getToxLoss(TOX_SYSCORRUPT))
		return FALSE

/datum/nanite_program/purging_synth/active_effect()
	host_mob.adjustToxLoss(-1, toxins_type = TOX_SYSCORRUPT)

/datum/nanite_program/brain_heal
	name = "Neural Regeneration"
	desc = "Наниты восстанавливают нейронные связи в мозге носителя, устраняя повреждения мозга и лёгкие травмы. Не расходуют наниты, если эффект невозможен."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/brain_decay)

/datum/nanite_program/brain_heal/check_conditions()
	var/problems = FALSE
	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		var/obj/item/organ/brain/B = C.getorganslot(ORGAN_SLOT_BRAIN)
		if(length(B?.get_traumas_type(TRAUMA_RESILIENCE_BASIC)))
			problems = TRUE
	if(host_mob.getOrganLoss(ORGAN_SLOT_BRAIN) > 0)
		problems = TRUE
	return problems ? ..() : FALSE

/datum/nanite_program/brain_heal/active_effect()
	host_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, -1)
	if(iscarbon(host_mob) && prob(10))
		var/mob/living/carbon/C = host_mob
		C.cure_trauma_type(resilience = TRAUMA_RESILIENCE_BASIC)

/datum/nanite_program/blood_restoring
	name = "Blood Regeneration"
	desc = "Наниты стимулируют и ускоряют выработку клеток крови у носителя. Не расходуют наниты, пока уровень крови в норме."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/suffocating)

/datum/nanite_program/blood_restoring/check_conditions()
	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		if(C.blood_volume >= (BLOOD_VOLUME_SAFE*C.blood_ratio) || (HAS_TRAIT(C, TRAIT_NOMARROW)))
			return FALSE
	else
		return FALSE
	return ..()

/datum/nanite_program/blood_restoring/active_effect()
	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		C.adjust_integration_blood(2, 2)

/datum/nanite_program/repairing
	name = "Mechanical Repair"
	desc = "Наниты ремонтируют повреждения механических конечностей носителя. Не расходуют наниты, если механические конечности не повреждены или их нет."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/repairing/check_conditions()
	if(!host_mob.getBruteLoss() && !host_mob.getFireLoss())
		return FALSE

	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		var/list/parts = C.get_damaged_bodyparts(TRUE, TRUE, status = list(BODYPART_ROBOTIC, BODYPART_HYBRID, BODYPART_NANITES))
		if(!parts.len)
			return FALSE
	else
		if(!(host_mob.mob_biotypes & MOB_ROBOTIC))
			return FALSE
	return ..()

/datum/nanite_program/repairing/active_effect(mob/living/M)
	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		var/list/parts = C.get_damaged_bodyparts(TRUE, TRUE, status = list(BODYPART_ROBOTIC, BODYPART_HYBRID, BODYPART_NANITES))
		if(!parts.len)
			return
		var/update = FALSE
		for(var/obj/item/bodypart/L in parts)
			if(L.heal_damage(1.5/parts.len, 1.5/parts.len, null, TRUE, FALSE, updating_health = FALSE)) //much faster than organic healing
				update = TRUE
		host_mob.updatehealth()
		if(update)
			host_mob.update_damage_overlays()
	else
		host_mob.adjustBruteLoss(-1.5, TRUE)
		host_mob.adjustFireLoss(-1.5, TRUE)

/datum/nanite_program/purging_advanced
	name = "Selective Blood Purification"
	desc = "Наниты выводят токсины и опасные химикаты из крови носителя, не трогая полезные вещества. Дополнительные вычисления, требуемые для анализа химикатов, значительно увеличивают расход нанитов. Благодаря повышенной точности программа безопасна для биологии слизней."
	use_rate = 2
	rogue_types = list(/datum/nanite_program/suffocating, /datum/nanite_program/necrotic)

/datum/nanite_program/purging_advanced/check_conditions()
	. = ..()
	if(!. || !host_mob.reagents)
		return FALSE
	var/foreign_reagent = FALSE
	for(var/datum/reagent/toxin/R in host_mob.reagents.reagent_list)
		foreign_reagent = TRUE
		break
	if(!host_mob.getToxLoss() && !foreign_reagent)
		return FALSE

/datum/nanite_program/purging_advanced/active_effect()
	host_mob.adjustToxLoss(-1, forced = TRUE)
	for(var/datum/reagent/toxin/R in host_mob.reagents.reagent_list)
		host_mob.reagents.remove_reagent(R.type,1)

/datum/nanite_program/regenerative_advanced
	name = "Bio-Reconstruction"
	desc = "Наниты вручную восстанавливают и заменяют органические клетки, действуя намного быстрее обычной регенерации. Однако программа не различает повреждённые и неповреждённые клетки и расходует наниты, даже если эффекта нет."
	use_rate = 5.5
	rogue_types = list(/datum/nanite_program/suffocating, /datum/nanite_program/necrotic)

/datum/nanite_program/regenerative_advanced/active_effect()
	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		var/list/parts = C.get_damaged_bodyparts(TRUE,TRUE, status = list(BODYPART_ORGANIC, BODYPART_NANITES))
		if(!parts.len)
			return
		var/update = FALSE
		for(var/obj/item/bodypart/L in parts)
			if(L.heal_damage(3/parts.len, 3/parts.len, 0, updating_health = FALSE))
				update = TRUE
		host_mob.updatehealth()
		if(update)
			host_mob.update_damage_overlays()
	else
		host_mob.adjustBruteLoss(-3, TRUE)
		host_mob.adjustFireLoss(-3, TRUE)

/datum/nanite_program/brain_heal_advanced
	name = "Neural Reimaging"
	desc = "Наниты способны создавать резервные копии и восстанавливать нейронные связи носителя, потенциально заменяя целые участки утраченного или повреждённого вещества мозга."
	use_rate = 3
	rogue_types = list(/datum/nanite_program/brain_decay, /datum/nanite_program/brain_misfire)

/datum/nanite_program/brain_heal_advanced/check_conditions()
	var/problems = FALSE
	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		var/obj/item/organ/brain/B = C.getorganslot(ORGAN_SLOT_BRAIN)
		if(length(B?.get_traumas_type(TRAUMA_RESILIENCE_SURGERY)))
			problems = TRUE
	if(host_mob.getOrganLoss(ORGAN_SLOT_BRAIN) > 0)
		problems = TRUE
	return problems ? ..() : FALSE

/datum/nanite_program/brain_heal_advanced/active_effect()
	host_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, -2)
	if(iscarbon(host_mob) && prob(10))
		var/mob/living/carbon/C = host_mob
		C.cure_trauma_type(resilience = TRAUMA_RESILIENCE_SURGERY)

/datum/nanite_program/defib
	name = "Defibrillation"
	desc = "При срабатывании наниты бьют током по сердцу носителя, возвращая его к жизни, если организм это выдержит."
	can_trigger = TRUE
	trigger_cost = 25
	trigger_cooldown = 120
	rogue_types = list(/datum/nanite_program/shocking)

/datum/nanite_program/defib/on_trigger(comm_message)
	host_mob.notify_ghost_cloning("Your heart is being defibrillated by nanites. Re-enter your corpse if you want to be revived!")
	addtimer(CALLBACK(src, PROC_REF(zap)), 50)

/datum/nanite_program/defib/proc/check_revivable()
	if(!iscarbon(host_mob)) //nonstandard biology
		return FALSE
	var/mob/living/carbon/C = host_mob
	if(!C.client)
		return FALSE
	return C.can_revive()

/datum/nanite_program/defib/proc/zap()
	var/mob/living/carbon/C = host_mob
	playsound(C, 'sound/machines/defib_charge.ogg', 50, FALSE)
	sleep(30)
	playsound(C, 'sound/machines/defib_zap.ogg', 50, FALSE)
	if(check_revivable())
		var/breathless = HAS_TRAIT(C, TRAIT_NOBREATH)
		playsound(C, 'sound/machines/defib_success.ogg', 50, FALSE)
		C.set_heartattack(FALSE)
		var/oxydamage = C.getOxyLoss()
		if(C.health < HEALTH_THRESHOLD_FULLCRIT && oxydamage)
			var/diff = C.health - HEALTH_THRESHOLD_FULLCRIT
			C.adjustOxyLoss(diff)	//Heal their oxydamage up to hardcrit (or if less, as much as they have, since the proc has sanity)
		C.revive(full_heal = FALSE, admin_revive = FALSE, post_revive_effects = TRUE, medical_revive = TRUE)
		if(breathless)
			C.emote("twitch")
		else
			C.emote("gasp")
		C.Jitter(100)
		SEND_SIGNAL(C, COMSIG_LIVING_MINOR_SHOCK)
		// BLUEMOON EDIT START - изменение памяти после смерти
		C.mind?.revival_handle_memory("nanite defibrillation")
		// BLUEMOON EDIT END
	else
		playsound(C, 'sound/machines/defib_failed.ogg', 50, FALSE)

/datum/nanite_program/hard_reboot
	name = "Hard Reboot Protocol"
	desc = "Наномашины хранят протоколы перезагрузки позитронного мозга носителя."
	can_trigger = TRUE
	trigger_cost = 25
	trigger_cooldown = 120
	rogue_types = list(/datum/nanite_program/shocking)

/datum/nanite_program/hard_reboot/check_conditions()
	. = ..()
	if(!. || !(host_mob.mob_biotypes & MOB_ROBOTIC))
		return FALSE

/datum/nanite_program/hard_reboot/on_trigger(comm_message)
	host_mob.notify_ghost_cloning("Nanites is trying to reboot you! Re-enter your corpse if you want to be revived!")
	addtimer(CALLBACK(src, PROC_REF(reboot)), 50)

/datum/nanite_program/hard_reboot/proc/reboot()
	var/mob/living/carbon/target = host_mob
	target.adjustOxyLoss(-50, 0)
	target.updatehealth()
	if(target.revive(medical_revive = TRUE))
		target.visible_message("...[target]'s posibrain flickers to life once again!")
		target.emote("ping")
		// BLUEMOON EDIT START - изменение памяти после смерти
		target.mind?.revival_handle_memory("force reboot")
		// BLUEMOON EDIT END
		return TRUE
	else
		target.visible_message("...[target]'s posibrain flickers a few times, before the lights fade yet again...")
		return FALSE

/datum/nanite_program/heal_wounds
	name = "Recovery Wounds"
	desc = "Наниты расходуют себя для восстановления тела, заменяя повреждения и тем самым заживляя раны."
	use_rate = 10
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/heal_wounds/check_conditions()
	. = ..()
	if(!. || !iscarbon(host_mob))
		return FALSE

	var/mob/living/carbon/host_carbon = host_mob
	if(!host_carbon.all_wounds?.len)
		return FALSE

	return TRUE

/datum/nanite_program/heal_wounds/active_effect()
	var/mob/living/carbon/host_carbon = host_mob
	var/datum/wound/heal_wound = pick(host_carbon.all_wounds)
	if(!heal_wound)
		return FALSE
	heal_wound.on_xadone(5)
