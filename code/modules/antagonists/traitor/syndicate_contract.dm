/datum/syndicate_contract
	var/id = 0
	var/status = CONTRACT_STATUS_INACTIVE
	var/datum/objective/contract/contract = new()
	var/target_rank
	var/ransom = 0
	var/payout_type
	var/wanted_message
	var/datum/ransom_extraction/active_ransom

/datum/syndicate_contract/New(contract_owner, blacklist, type=CONTRACT_PAYOUT_SMALL)
	contract.owner = contract_owner
	payout_type = type

	generate(blacklist)

/datum/syndicate_contract/proc/generate(blacklist)
	contract.find_target(null, blacklist)

	var/datum/data/record/record
	if (contract.target)
		record = GLOB.data_core.general_by_name[contract.target.name]

	if (record)
		target_rank = record.fields["rank"]
	else
		target_rank = "Unknown"

	if (payout_type == CONTRACT_PAYOUT_LARGE)
		contract.payout_bonus = rand(9,13)
	else if (payout_type == CONTRACT_PAYOUT_MEDIUM)
		contract.payout_bonus = rand(6,8)
	else
		contract.payout_bonus = rand(2,4)

	contract.payout = rand(0, 2)
	contract.generate_dropoff()

	ransom = 100 * rand(18, 45)

	var/base = pick_list(WANTED_FILE, "basemessage")
	var/verb_string = pick_list(WANTED_FILE, "verb")
	var/noun = pick_list_weighted(WANTED_FILE, "noun")
	var/location = pick_list_weighted(WANTED_FILE, "location")
	wanted_message = "[base] [verb_string] [noun] [location]."

/datum/syndicate_contract/proc/handle_extraction(var/mob/living/user)
	if (contract.target && contract.dropoff_check(user, contract.target.current))

		var/turf/free_location = find_obstruction_free_location(3, user, contract.dropoff)

		if (free_location)
			// We've got a valid location, launch.
			launch_extraction_pod(free_location)
			return TRUE

	return FALSE

// Launch the pod to collect our victim.
/datum/syndicate_contract/proc/launch_extraction_pod(turf/empty_pod_turf)
	var/datum/ransom_extraction/sequence = new
	sequence.start_for_contract(src, empty_pod_turf)
