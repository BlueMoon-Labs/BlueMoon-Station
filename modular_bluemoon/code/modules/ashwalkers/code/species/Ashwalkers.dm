/datum/species/lizard/ashwalker/on_species_gain(mob/living/carbon/carbon_target, datum/species/old_species, regenerate_icons)
	. = ..()
	carbon_target.AddComponent(/datum/component/ash_age)
	carbon_target.faction |= FACTION_ASHWALKER

/datum/species/lizard/ashwalker/on_species_loss(mob/living/carbon/carbon_target)
	. = ..()
	UnregisterSignal(carbon_target, COMSIG_MOB_ITEM_ATTACK)
	carbon_target.faction &= FACTION_ASHWALKER

/**
 * 20 minutes = ash storm immunity
 * 40 minutes = armor
 * 60 minutes = base punch
 * 80 minutes = lavaproof
 * 100 minutes = firebreath
 */

/datum/component/ash_age
	/// the amount of minutes after each upgrade
	var/stage_time = 20 MINUTES
	/// the current stage of the ash
	var/current_stage = 0
	/// the time when upgraded/attached
	var/evo_time = 0
	/// the human target the element is attached to
	var/mob/living/carbon/human/human_target
	COOLDOWN_DECLARE(ash_regen)

/datum/component/ash_age/process()
	var/bruteheal = human_target.getBruteLoss()
	var/burnheal = human_target.getFireLoss()
	if(burnheal+bruteheal>0 && human_target.health >= human_target.crit_threshold)
		human_target.heal_overall_damage(1, 1)
	COOLDOWN_START(src, ash_regen, 10 SECONDS)

/datum/component/ash_age/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	// set the target for the element so we can reference in other parts
	human_target = parent
	// set the time that it was attached then we will compare current world time versus the evo_time plus stage_time
	evo_time = world.time
	// when the rune successfully completes the age ritual, it will send the signal... do the proc when we receive the signal
	RegisterSignal(human_target, COMSIG_RUNE_EVOLUTION, PROC_REF(check_evolution))
	RegisterSignal(human_target, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/ash_age/proc/check_evolution(mob/living/carbon/human/user)
	SIGNAL_HANDLER
	// if the world time hasn't yet passed the time required for evolution
	if(world.time < (evo_time + stage_time))
		to_chat(human_target, span_warning("Для эволюции необходимо больше времени — двадцать минут между каждой эволюцией..."))
		return
	// since it was time, go up a stage and now we check what to add
	current_stage++
	// since we went up a stage, we need to update the evo_time for the next comparison
	evo_time = world.time
	var/datum/species/species_target = human_target.dna.species
	switch(current_stage)
		if(1)
			to_chat(human_target, "<span class='notice'>Ты чувствуешь, как твои раны затягиваются</span>")
			START_PROCESSING(SSprocessing, src)
		if(2)
			to_chat(human_target, "<span class='notice'>Вы чувствуете себя более крепким.</span>")
			species_target.brutemod *= 0.9
			species_target.burnmod *= 0.9
			species_target.coldmod *= 0.9
		if(3)
			ADD_TRAIT(human_target, TRAIT_LAVA_IMMUNE, REF(src))
			to_chat(human_target, span_notice("Ты чувствуешь, как тело становится горячее..."))
		if(4)
			if(human_target.mind)
				to_chat(human_target, "<span class='notice'>Вы чувствуете, будто были избраны Некрополисом для его охраны.</span>")
				var/obj/effect/proc_holder/spell/targeted/shapeshift/dragon/D = new
				human_target.mind.AddSpell(D)
		if(5)
			// кидание огненных шаров
			if(human_target.mind)
				var/obj/effect/proc_holder/spell/aimed/fireball/F = new
				human_target.mind.AddSpell(F)
		if(6 to INFINITY)
			to_chat(human_target, span_warning("Вы уже достигли вершины своего нынешнего тела!"))


/datum/component/ash_age/proc/on_examine(atom/target_atom, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(world.time < (evo_time + stage_time))
		examine_list += span_notice("[human_target] еще не достиг возраста для развития.")
		return
	examine_list += span_warning("[human_target] достиг возраста для развития!")
