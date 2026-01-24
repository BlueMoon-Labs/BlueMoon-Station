/obj/item/organ/zombie_infection
	name = "Festering Ooze"
	desc = "A black web of pus and viscera."
	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_ZOMBIE
	icon_state = "blacktumor"
	var/causes_damage = TRUE
	var/datum/species/old_species = /datum/species/human
	var/living_transformation_time = 30
	var/converts_living = FALSE

	var/revive_time_min = 450
	var/revive_time_max = 700
	var/timer_id

/obj/item/organ/zombie_infection/Initialize(mapload)
	. = ..()
	if(iscarbon(loc))
		Insert(loc)
	GLOB.zombie_infection_list += src

/obj/item/organ/zombie_infection/Destroy()
	GLOB.zombie_infection_list -= src
	. = ..()

/obj/item/organ/zombie_infection/Insert(mob/living/carbon/organ_owner, special, drop_if_replaced)
	. = ..()

	if(organ_owner)
		RegisterSignal(organ_owner, COMSIG_LIVING_DEATH, PROC_REF(organ_owner_died))
	START_PROCESSING(SSobj, src)

/obj/item/organ/zombie_infection/Remove(special = FALSE)
	. = ..()
	if(owner)
		UnregisterSignal(owner, COMSIG_LIVING_DEATH)
	STOP_PROCESSING(SSobj, src)
	if(!QDELETED(owner) && iszombie(owner) && old_species && !special)
		owner.set_species(old_species)
	if(timer_id)
		deltimer(timer_id)

/obj/item/organ/zombie_infection/proc/organ_owner_died(mob/living/carbon/source, gibbed)
	SIGNAL_HANDLER
	if(iszombie(source))
		qdel(src) // Congrats you somehow died so hard you stopped being a zombie

/obj/item/organ/zombie_infection/on_find(mob/living/finder)
	to_chat(finder, span_warning("Inside the head is a disgusting black \
		web of pus and viscera, bound tightly around the brain like some \
		biological harness."))

/obj/item/organ/zombie_infection/process(seconds_per_tick, times_fired)
	if(!owner)
		return
	if(!(src in owner.internal_organs))
		INVOKE_ASYNC(src, PROC_REF(Remove), owner)
	if(owner.mob_biotypes & MOB_MINERAL)//does not process in inorganic things
		return
	if (causes_damage && !iszombie(owner) && owner.stat != DEAD)
		owner.adjustToxLoss(1 * seconds_per_tick)
		owner.adjustOrganLoss(ORGAN_SLOT_HEART, 10)
		owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10)
		if (SPT_PROB(5, seconds_per_tick))
			to_chat(owner, span_danger("Мне плоховато..."))
	if(timer_id || !owner.getorgan(/obj/item/organ/brain))
		return
	if(owner.stat != DEAD && !converts_living)
		return
	if(!iszombie(owner))
		to_chat(owner, "<span class='cultlarge'>Кажется, ваше сердце остановилось... однако что-то здесь не так! \
		Жизнь не желает покидать вашу оболочку... что-то поддерживает вашу жизнь и это что-то вызывает у вас непреодолимый голод. \
		Ничего, даже смерть, не сможет убить вас!</span>")
	var/revive_time = rand(revive_time_min, revive_time_max)
	var/flags = TIMER_STOPPABLE
	timer_id = addtimer(CALLBACK(src, PROC_REF(zombify), owner), revive_time, flags)

/obj/item/organ/zombie_infection/proc/zombify(mob/living/carbon/target)
	timer_id = null

	if(!converts_living && owner.stat != DEAD)
		return

	if(!iszombie(owner))
		old_species = owner.dna.species.type
		target.set_species(/datum/species/zombie/infectious)

	var/stand_up = (target.stat == DEAD) || (target.stat == UNCONSCIOUS)

	//Fully heal the zombie's damage the first time they rise
	owner.setToxLoss(0, 0)
	owner.setOxyLoss(0, 0)
	owner.heal_overall_damage(INFINITY, INFINITY, INFINITY, FALSE, FALSE, TRUE)

	if(!owner.revive())
		return

	owner.visible_message("<span class='danger'>[owner] suddenly convulses, as [owner.p_they()][stand_up ? " stagger to [owner.p_their()] feet and" : ""] gain a ravenous hunger in [owner.p_their()] eyes!</span>", "<span class='alien'>You HUNGER!</span>")

	to_chat(target, span_alien("You HUNGER!"))
	to_chat(target, span_alertalien("You are now a zombie! Do not seek to be cured, do not help any non-zombies in any way, do not harm your zombie brethren and spread the disease by killing others. You are a creature of hunger and violence."))
	playsound(target, 'sound/hallucinations/far_noise.ogg', 50, 1)
	target.do_jitter_animation(living_transformation_time)
	target.Stun(living_transformation_time)

/obj/item/organ/zombie_infection/nodamage
	causes_damage = FALSE
