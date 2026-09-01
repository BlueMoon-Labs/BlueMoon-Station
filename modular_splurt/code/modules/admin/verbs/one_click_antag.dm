//Slave stuff
/datum/admins/proc/makeSlaverTeam()
	. = FALSE
	var/const/minimum_required = 1
	var/const/max_required = 4
	var/list/mob/candidates = pollGhostCandidates("Do you wish to be considered for the slave trader crew?", ROLE_SLAVER, minimum_required = max_required)
	var/list/mob/chosen = list()
	var/mob/theghost = null

	if(!candidates.len)
		return
	var/slavercount = 0

	for(var/i = 0, i < max_required,i++)
		shuffle_inplace(candidates) //More shuffles means more randoms
		for(var/mob/j  in candidates)
			if(!j || !j.client || QDELETED(j) || jobban_isbanned(j, ROLE_SLAVER) || jobban_isbanned(j, ROLE_INTEQ))
				candidates.Remove(j)
				continue

			theghost = j
			candidates.Remove(theghost)
			chosen += theghost
			slavercount++
			break
	//Making sure we have atleast 1 slaver
	if(slavercount < minimum_required)
		return 
		
	//Let's find the spawn locations
	var/leader_chosen = FALSE
	var/datum/team/slavers/slaver_team
	for(var/mob/c in chosen)
		var/mob/living/carbon/human/new_character=makeBody(c)
		if(!leader_chosen && !GLOB.slavers_spawned) // If we have no leader, pick one. Second check means only pick a leader if no previous slaver team has spawned, avoiding multiple leaders.
			leader_chosen = TRUE
			new_character.mind.add_antag_datum(/datum/antagonist/slaver/leader)
		else
			new_character.mind.add_antag_datum(/datum/antagonist/slaver, slaver_team)

	GLOB.slavers_spawned = TRUE
	return TRUE
