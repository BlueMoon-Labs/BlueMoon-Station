/*
	Click code cleanup
	~Sayu
*/

// 1 decisecond click delay (above and beyond mob/next_move)
//This is mainly modified by click code, to modify click delays elsewhere, use next_move and changeNext_move()
/mob/var/next_click	= 0

// THESE DO NOT EFFECT THE BASE 1 DECISECOND DELAY OF NEXT_CLICK
/mob/var/next_move_adjust = 0 //Amount to adjust action/click delays by, + or -
/mob/var/next_move_modifier = 1 //Value to multiply action/click delays by


//Delays the mob's next click/action by num deciseconds
// eg: 10-3 = 7 deciseconds of delay
// eg: 10*0.5 = 5 deciseconds of delay
// DOES NOT EFFECT THE BASE 1 DECISECOND DELAY OF NEXT_CLICK

/mob/proc/timeToNextMove()
	return max(0, next_move - world.time)

/mob/proc/changeNext_move(num)
	next_move = world.time + ((num+next_move_adjust)*next_move_modifier)

/mob/living/changeNext_move(num)
	last_click_move = next_move
	var/mod = next_move_modifier
	var/adj = next_move_adjust
	for(var/i in status_effects)
		var/datum/status_effect/S = i
		mod *= S.nextmove_modifier()
		adj += S.nextmove_adjust()
	next_move = world.time + ((num + adj)*mod)

/mob/proc/altclick_listed_turf(atom/A)
	var/turf/T = get_turf(A)
	if(T == A.loc || T == A)
		if(T == listed_turf)
			if(client)
				client.clear_listed_turf()
			else
				listed_turf = null
		else if(TurfAdjacent(T))
			if(client)
				client.open_listed_turf(T)
				client.statpanel = T.name
			else
				listed_turf = T
