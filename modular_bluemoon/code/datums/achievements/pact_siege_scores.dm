/// Tracks PACT siege wins (increment with give_award(..., value = PACT_SIEGE_REWARD_PACT_WIN))
/datum/award/score/pact_siege_pact
	name = "PACT: InteQ sweep victories"
	desc = "Wins in formalized PACT assaults on InteQ positions."
	database_id = "PsgPactV1"
	icon = "featofstrength"

/// Tracks InteQ defense wins
/datum/award/score/pact_siege_inteq
	name = "InteQ: last-stand defenses"
	desc = "Successful defenses during PACT siege protocol."
	database_id = "PsgInteqV1"
	icon = "basemisc"
