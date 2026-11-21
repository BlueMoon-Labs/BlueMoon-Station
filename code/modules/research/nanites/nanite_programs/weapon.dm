//Programs specifically engineered to cause harm to either the user or its surroundings (as opposed to ones that only do it due to broken programming)
//Very dangerous!

/datum/nanite_program/flesh_eating
	name = "Cellular Breakdown"
	desc = "Наниты разрушают клеточные структуры в организме носителя, нанося дробящий урон."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/flesh_eating/active_effect()
	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		C.take_bodypart_damage(1, 0, 0)
	else
		host_mob.adjustBruteLoss(1, TRUE)
	if(prob(3))
		to_chat(host_mob, "<span class='warning'>You feel a stab of pain from somewhere inside you.</span>")

/datum/nanite_program/poison
	name = "Poisoning"
	desc = "Наниты доставляют ядовитые химикаты к внутренним органам носителя, вызывая токсический урон и рвоту."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/poison/active_effect()
	host_mob.adjustToxLoss(1)
	if(prob(2))
		to_chat(host_mob, "<span class='warning'>You feel nauseous.</span>")
		if(iscarbon(host_mob))
			var/mob/living/carbon/C = host_mob
			C.vomit(20)

/datum/nanite_program/memory_leak
	name = "Memory Leak"
	desc = "Эта программа вторгается в область памяти, используемую другими программами, вызывая частые повреждения и ошибки."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/memory_leak/active_effect()
	if(prob(6))
		var/datum/nanite_program/target = pick(nanites.programs)
		if(target == src)
			return
		target.software_error()

/datum/nanite_program/aggressive_replication
	name = "Aggressive Replication"
	desc = "Наниты поглощают органическую материю для ускорения размножения, нанося носителю дробящий урон. Прирост скорости производства составляет 0,1 на каждые 50 единиц объёма нанитов (4,0 при 200 единицах, 4,4 при 220); сами наниты не расходуются."
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/aggressive_replication/active_effect()
	var/extra_regen = round(nanites.nanite_volume / 50, 0.1)
	nanites.adjust_nanites(src, extra_regen)
	host_mob.adjustBruteLoss(extra_regen / 3, TRUE)

/datum/nanite_program/meltdown
	name = "Meltdown"
	desc = "Вызывает внутренний расплав внутри нанитов, нанося внутренние ожоги носителю и быстро уничтожая популяцию нанитов. При активации устанавливает порог безопасности нанитов на 0."
	use_rate = 10
	rogue_types = list(/datum/nanite_program/glitch)

/datum/nanite_program/meltdown/active_effect()
	host_mob.adjustFireLoss(3.5)

/datum/nanite_program/meltdown/enable_passive_effect()
	. = ..()
	to_chat(host_mob, "<span class='userdanger'>Your blood is burning!</span>")
	nanites.safety_threshold = 0

/datum/nanite_program/meltdown/disable_passive_effect()
	. = ..()
	to_chat(host_mob, "<span class='warning'>Your blood cools down, and the pain gradually fades.</span>")

/datum/nanite_program/explosive
	name = "Chain Detonation"
	desc = "При срабатывании взрывает все наниты внутри носителя цепной реакцией."
	can_trigger = TRUE
	trigger_cost = 25 //plus every idle nanite left afterwards
	trigger_cooldown = 100 //Just to avoid double-triggering
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/explosive/on_trigger(comm_message)
	host_mob.visible_message("<span class='warning'>[host_mob] starts emitting a high-pitched buzzing, and [host_mob.ru_ego()] skin begins to glow...</span>",\
							"<span class='userdanger'>You start emitting a high-pitched buzzing, and your skin begins to glow...</span>")
	addtimer(CALLBACK(src, PROC_REF(boom)), clamp((nanites.nanite_volume * 0.35), 25, 150))

/datum/nanite_program/explosive/proc/boom()
	var/nanite_amount = nanites.nanite_volume
	var/heavy_range = FLOOR(nanite_amount/100, 1) - 1
	var/light_range = FLOOR(nanite_amount/50, 1) - 1
	explosion(host_mob, 0, heavy_range, light_range)
	nanites.adjust_nanites(null, -nanite_amount)
	nanites.nanites_depleted()

//TODO make it defuse if triggered again

/datum/nanite_program/heart_stop
	name = "Heart-Stopper"
	desc = "При срабатывании останавливает сердце носителя; повторное срабатывание запускает его снова."
	can_trigger = TRUE
	trigger_cost = 12
	trigger_cooldown = 10
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/heart_stop/on_trigger(comm_message)
	if(iscarbon(host_mob))
		var/mob/living/carbon/C = host_mob
		var/obj/item/organ/heart/heart = C.getorganslot(ORGAN_SLOT_HEART)
		if(heart)
			if(heart.beating)
				heart.Stop()
			else
				heart.Restart()

/datum/nanite_program/emp
	name = "Electromagnetic Resonance"
	desc = "При срабатывании наниты создают электромагнитный импульс вокруг носителя. Повредит другие программы нанитов!"
	can_trigger = TRUE
	trigger_cost = 10
	trigger_cooldown = 50
	program_flags = NANITE_EMP_IMMUNE
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/emp/on_trigger(comm_message)
	empulse_using_range(host_mob, 3)

/datum/nanite_program/pyro/active_effect()
	host_mob.fire_stacks += 1
	host_mob.IgniteMob()

/datum/nanite_program/pyro
	name = "Sub-Dermal Combustion"
	desc = "Наниты накапливают горючие жидкости под кожей носителя, а затем поджигают их."
	use_rate = 4
	rogue_types = list(/datum/nanite_program/skin_decay, /datum/nanite_program/cryo)

/datum/nanite_program/pyro/check_conditions()
	if(host_mob.fire_stacks >= 10 && host_mob.on_fire)
		return FALSE
	return ..()

/datum/nanite_program/pyro/active_effect()
	host_mob.fire_stacks += 1
	host_mob.IgniteMob()

/datum/nanite_program/cryo
	name = "Cryogenic Treatment"
	desc = "Наниты быстро отводят тепло через кожу носителя, снижая его температуру."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/skin_decay, /datum/nanite_program/pyro)

/datum/nanite_program/cryo/check_conditions()
	if(host_mob.bodytemperature <= 70)
		return FALSE
	return ..()

/datum/nanite_program/cryo/active_effect()
	host_mob.adjust_bodytemperature(-rand(15,25), 50)

/datum/nanite_program/comm/mind_control
	name = "Mind Control"
	desc = "При срабатывании наниты впечатывают абсолютную директиву в мозг носителя на одну минуту."
	trigger_cost = 30
	trigger_cooldown = 1800
	rogue_types = list(/datum/nanite_program/brain_decay, /datum/nanite_program/brain_misfire)

/datum/nanite_program/comm/mind_control/register_extra_settings()
	. = ..()
	extra_settings[NES_DIRECTIVE] = new /datum/nanite_extra_setting/text("...")

/datum/nanite_program/comm/mind_control/on_trigger(comm_message)
	if(host_mob.stat == DEAD)
		return
	if(HAS_TRAIT(host_mob, TRAIT_MINDSHIELD))
		return
	var/sent_directive = comm_message
	if(!comm_message)
		var/datum/nanite_extra_setting/ES = extra_settings[NES_DIRECTIVE]
		sent_directive = ES.get_value()
	brainwash(host_mob, sent_directive)
	log_game("A mind control nanite program brainwashed [key_name(host_mob)] with the objective '[sent_directive]'.")
	addtimer(CALLBACK(src, PROC_REF(end_brainwashing)), 600)

/datum/nanite_program/comm/mind_control/proc/end_brainwashing()
	if(host_mob.mind && host_mob.mind.has_antag_datum(/datum/antagonist/brainwashed))
		host_mob.mind.remove_antag_datum(/datum/antagonist/brainwashed)
	log_game("[key_name(host_mob)] is no longer brainwashed by nanites.")

/datum/nanite_program/comm/mind_control/disable_passive_effect()
	. = ..()
	end_brainwashing()
