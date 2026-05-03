#define VOTE_WEIGHT_NONE   0
#define VOTE_WEIGHT_LOW    0.5
#define VOTE_WEIGHT_NORMAL 1
#define VOTE_WEIGHT_HIGH   2
#define MINIMUM_VOTE_LIFETIME 5 MINUTES

/datum/controller/subsystem/vote
	/**
	 * Players' power during votes is determined on their role: mob, antag or ghost.
	 * Right now it is working only with PLURALITY_VOTING and APPROVAL_VOTING.
	 *  */
	var/use_vote_power = FALSE
	var/vote_power = VOTE_WEIGHT_NORMAL
	/**
	 * Users' ckeys and their current vote power will be stored here to prevent messing with vote powers when user is ghosting or changing roles.
	 * Resets every vote reset.
	 *  */
	var/list/users_vote_power = list()

/datum/controller/subsystem/vote/initiate_vote(vote_type, initiator_key, display, votesystem, forced, vote_time, UseVotePower = FALSE, roundtype_runoff_second_ballot = FALSE)
	use_vote_power = UseVotePower
	. = ..()

/datum/controller/subsystem/vote/reset()
	. = ..()
	vote_power = initial(vote_power)
	users_vote_power = list()

/datum/controller/subsystem/vote/proc/get_vote_power_by_role(client/C) //taken from TauCetiClassic
	if(!istype(C))
		return VOTE_WEIGHT_NONE //Shouldnt be possible, but safety

	if(C.holder) //is admin
		return VOTE_WEIGHT_NORMAL

	var/mob/M = C.mob
	if(!M || M.stat == DEAD || isobserver(M) || isnewplayer(M) || ismouse(M) || isdrone(M))
		return VOTE_WEIGHT_LOW

	if((world.time - M.creation_time) <= MINIMUM_VOTE_LIFETIME)
		//If you just spawned for the vote, your weight is still low
		return VOTE_WEIGHT_LOW

	//Antags control the story of the round, they should be able to delay evac in order to enact their
	//fun and interesting plans
	if(is_special_character(M))
		//all ghost roles are considered as antags for some reason.
		if(M.mind?.has_antag_datum(/datum/antagonist/ghost_role))
			return VOTE_WEIGHT_NORMAL
		return VOTE_WEIGHT_HIGH

	//How long has this player been alive
	//This comes after the antag check because that's more important
	// var/lifetime = world.time - M.mind.creation_time
	// if(lifetime <= MINIMUM_VOTE_LIFETIME)
	// 	//If you just spawned for the vote, your weight is still low
	// 	return VOTE_WEIGHT_LOW

	//Heads of staff are in a better position to understand the state of the ship and round,
	//their vote is more important.
	//This is after the lifetime check to prevent exploits of instaspawning as a head when a vote is called
	if(M.mind?.assigned_role in GLOB.command_positions)
		return VOTE_WEIGHT_HIGH

	return VOTE_WEIGHT_NORMAL

#undef VOTE_WEIGHT_NONE
#undef VOTE_WEIGHT_LOW
#undef VOTE_WEIGHT_NORMAL
#undef VOTE_WEIGHT_HIGH
#undef MINIMUM_VOTE_LIFETIME
