/datum/quirk/quirk_shy
	name = "Застенчивый"
	desc = "Вам становится неловко когда на вас смотрят. А если вас увидят без одежды - вы сгорите от стыда!"
	value = 0
	mob_trait = TRAIT_SHY
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Мне неловко от чужих взглядов.</span>"
	lose_text = "<span class='notice'>Я больше не чувствую неловкость от чужих взглядов.</span>"

/datum/quirk/quirk_shy/add()
	. = ..()
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))

/datum/quirk/quirk_shy/remove()
	. = ..()
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)
	UnregisterSignal(quirk_holder, COMSIG_MOB_EMOTE)

/// Одни условия для описания смущения и реакции на чужой взгляд.
/datum/quirk/quirk_shy/proc/can_react_to_examine(mob/user)
	if(!iscarbon(user) || user == quirk_holder || !ishuman(quirk_holder))
		return FALSE
	var/mob/living/carbon/human/quirk_mob = quirk_holder
	if(quirk_mob.stat >= UNCONSCIOUS)
		return FALSE
	var/list/viewlist = quirk_mob.client ? getviewsize(quirk_mob.client.view) : getviewsize(world.view)
	var/mob_view_distance = min(viewlist[1], viewlist[2]) / 2
	return can_see(quirk_mob, user, mob_view_distance)

/datum/quirk/quirk_shy/proc/on_examine_holder(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(!can_react_to_examine(user))
		return
	var/mob/living/carbon/human/quirk_mob = quirk_holder
	if(quirk_mob.is_chest_exposed() && quirk_mob.is_groin_exposed())
		if(quirk_holder.restrained())
			to_chat(quirk_holder, span_notice("Вы сгораете от стыда, чувствуя чужой взгляд!"))
		else
			to_chat(quirk_holder, span_notice("Вы сгораете от стыда, чувствуя чужой взгляд и пытаетесь прикрыться руками!"))
			quirk_holder.dir = turn(get_dir(quirk_holder, user), pick(-90, 90))
	else
		to_chat(quirk_holder, span_notice("Вы замечаете чужой взгляд и сильно смущаетесь!"))
	quirk_holder.emote("blush")

