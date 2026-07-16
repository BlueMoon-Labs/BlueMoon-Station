PROCESSING_SUBSYSTEM_DEF(interactions)
	name = "Interactions"
	wait = 0.5 SECONDS
	stat_tag = "ACT"
	init_order = INIT_ORDER_INTERACTIONS
	flags = SS_BACKGROUND|SS_POST_FIRE_TIMING
	VAR_PROTECTED/list/blacklisted_mobs = list(
		/mob/dead,
		/mob/dview,
		/mob/camera, // Although it would be funny to fuck the sentient disease or AI hologram
		/mob/living/carbon/monkey,
		/mob/living/simple_animal/pet,
		/mob/living/simple_animal/cockroach,
		/mob/living/simple_animal/babyKiwi,
		/mob/living/simple_animal/butterfly,
		/mob/living/simple_animal/chick,
		/mob/living/simple_animal/chicken,
		/mob/living/simple_animal/cow,
		/mob/living/simple_animal/crab,
		/mob/living/simple_animal/kiwi,
		/mob/living/simple_animal/parrot,
		/mob/living/simple_animal/sloth,
		/mob/living/simple_animal/pickle,
		/mob/living/simple_animal/mouse,
		/mob/living/simple_animal/hostile/retaliate/goat,
		/mob/living/simple_animal/hostile/retaliate/frog,
		/mob/living/simple_animal/hostile/retaliate/poison/snake,
	)
	VAR_PROTECTED/initialized_blacklist
	var/list/interactions = list()

/datum/controller/subsystem/processing/interactions/Initialize(timeofday)
	prepare_interactions()
	prepare_blacklisted_mobs()
	. = ..()
	var/extra_info = "<font style='transform: translate(0%, -25%);'>↳</font> Loaded [LAZYLEN(interactions)] interactions!"
	to_chat(world, span_boldannounce(extra_info))
	log_subsystem(src, extra_info)

/datum/controller/subsystem/processing/interactions/stat_entry(msg)
	msg += "|🖐:[LAZYLEN(interactions)]|"
	msg += "🚫👨:[LAZYLEN(blacklisted_mobs)]"
	return ..()

/// Makes the interactions, they're also a global list because having it as a list and just hanging around there is stupid
/datum/controller/subsystem/processing/interactions/proc/prepare_interactions()
	QDEL_NULL_LIST(interactions)
	interactions = list()
	for(var/datum/interaction/interaction as anything in subtypesof(/datum/interaction))
		// Basetype, do not create
		if(!initial(interaction.description))
			continue
		interaction = new interaction()
		interactions["[interaction.type]"] = interaction

/// Blacklisting!
/datum/controller/subsystem/processing/interactions/proc/prepare_blacklisted_mobs()
	blacklisted_mobs = typecacheof(blacklisted_mobs)
	initialized_blacklist = TRUE

/*
 * Lewd interactions have a blacklist for certain mobs. When we evalute the user and target, both of
 * their requirements must be satisfied, and the mob must not be of a blacklisted type.
*/
/datum/controller/subsystem/processing/interactions/proc/is_blacklisted(mob/living/creature)
	if(isliving(creature) && creature.client)
		return FALSE
	if(!creature || !initialized_blacklist)
		return TRUE
	if(is_type_in_typecache(creature, blacklisted_mobs))
		return TRUE
