/*
* Changeling midround spawn event. Takes a ghost volunteer and stuffs them into a changeling with their own identity and a flesh space suit.
* They arrive via a meateor, which collides with the station. They are expected to find their own way into the station by whatever means necessary.
* The midround changeling experience is, by nature, more difficult than playing as a roundstart crew changeling.
*
*/

/datum/round_event_control/changeling
	name = "Changeling Meteor"
	typepath = /datum/round_event/ghost_role/changeling
	weight = 8
	max_occurrences = 3
	// Раннее разнообразие гост-пула (см. Spawn Sentient Disease): доступен с 20-й минуты,
	// чтобы Devil не был единственным гост-антагом первые полчаса.
	earliest_start = 20 MINUTES
	min_players = 20
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_GHOST // антаги из призраков - гост-пул, а не общий MAJOR
	cost = 10
	intensity = 15
	family = "changeling"
	director_ghost_jobban = ROLE_CHANGELING
	director_ghost_preference = ROLE_CHANGELING_MIDROUND
	required_round_type = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED) // не экста и не лайт
	description = "A meteor containing a changeling is summoned and thrown at the exterior of the station."

/datum/round_event/ghost_role/changeling
	minimum_required = 1
	role_name = "space changeling"
	fakeable = FALSE

/datum/round_event/ghost_role/changeling/spawn_role()
	var/list/mob/dead/observer/candidate = get_candidates(ROLE_CHANGELING, null, ROLE_CHANGELING_MIDROUND)

	if(!candidate.len)
		return NOT_ENOUGH_PLAYERS

	spawned_mobs += generate_changeling_meteor(pick_n_take(candidate))

	if(spawned_mobs)
		return SUCCESSFUL_SPAWN
