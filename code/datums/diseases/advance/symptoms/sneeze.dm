/*
//////////////////////////////////////

Sneezing

	Very Noticable.
	Increases resistance.
	Doesn't increase stage speed.
	Very transmissible.
	Low Level.

Bonus
	Forces a spread type of AIRBORNE
	with extra range!
	At the final disease stage, a sneeze knocks the host backward slightly.
	Sneezing briefly disrupts the host's actions.

//////////////////////////////////////
*/

/datum/symptom/sneeze
	name = "Sneezing"
	desc = "The virus causes irritation of the nasal cavity, making the host sneeze occasionally, briefly disrupting movement and actions. At the final stage of the disease, sneezing can knock the host backward."
	stealth = -2
	resistance = 3
	stage_speed = 0
	transmittable = 4
	level = 1
	severity = 1
	symptom_delay_min = 5
	symptom_delay_max = 35
	threshold_desc = list(
		"Transmission 9" = "Increases sneezing range, spreading the virus over 6 meter cone instead of over a 4 meter cone.",
		"Stealth 4" = "The symptom remains hidden until active.",
	)

/datum/symptom/sneeze/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["transmittable"] >= 9) //longer spread range
		power = 2
	if(A.properties["stealth"] >= 4)
		suppress_warning = TRUE

/datum/symptom/sneeze/Activate(datum/disease/advance/A)
	if(!..() || HAS_TRAIT(A.affected_mob,TRAIT_NOBREATH))
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(1, 2, 3)
			if(!suppress_warning)
				M.emote("snuffle") //BLUEMOON EDIT
		else
			M.emote("sneeze")
			M.Stun(20)
			if(A.stage >= A.max_stages && !M.buckled && M.move_resist < INFINITY)
				var/atom/throw_target = get_edge_target_turf(M, REVERSE_DIR(M.dir))
				M.safe_throw_at(throw_target, 1, 1, force = MOVE_FORCE_STRONG, gentle = TRUE)
			if(M.CanSpreadAirborneDisease()) //don't spread germs if they covered their mouth
				A.spread(4 + power)
