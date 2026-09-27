/datum/round_event_control/wizard/race //Lizard Wizard? Lizard Wizard.
	name = "Race Swap"
	weight = 2
	typepath = /datum/round_event/wizard/race
	max_occurrences = 5
	earliest_start = 0 MINUTES
	can_be_midround_wizard = FALSE
	description = "Gives everyone a random race."

/datum/round_event/wizard/race
	/// Weakref to a swapped human -> list(real_name, species, unique_enzymes)
	var/list/originals

/datum/round_event/wizard/race/setup()
	originals = list()
	end_when = rand(600,1200) //10 to 20 minutes
	..()

/datum/round_event/wizard/race/start()

	var/all_the_same = 0
	var/all_species = list()

	for(var/speciestype in subtypesof(/datum/species))
		var/datum/species/S = new speciestype()
		if(!S.dangerous_existence && !S.blacklisted && !S.nojumpsuit) //Dangerous Species, Blacklisted Species, and Species who can't wear jumpsuits are blacklisted.
			all_species += speciestype

	var/datum/species/new_species = pick(all_species)

	if(prob(75))
		all_the_same = 1

	var/list/carbons = GLOB.carbon_list.Copy()
	for(var/mob/living/carbon/human/H in carbons)
		CHECK_TICK
		if(QDELETED(H))
			continue
		var/turf/T = get_turf(H)
		if(!T)
			continue
		if(!is_station_level(T.z))
			continue
		remember_original(H)
		H.set_species(new_species)
		H.real_name = H.dna.species.random_name(H.gender,1)
		H.dna.unique_enzymes = H.dna.generate_unique_enzymes()
		to_chat(H, "<span class='notice'>You feel somehow... different?</span>")
		if(!all_the_same)
			new_species = pick(all_species)

/datum/round_event/wizard/race/proc/remember_original(mob/living/carbon/human/H)
	originals[WEAKREF(H)] = list(H.real_name, H.dna.species, H.dna.unique_enzymes)

/datum/round_event/wizard/race/end()
	for(var/datum/weakref/human_ref as anything in originals)
		CHECK_TICK
		var/mob/living/carbon/human/H = human_ref.resolve()
		var/list/original = originals[human_ref]
		if(!H || !(original[1] && original[2] && original[3]))
			continue
		H.set_species(original[2])
		H.real_name = original[1]
		H.dna.unique_enzymes = original[3]
		to_chat(H, "<span class='notice'>You feel back to your normal self again.</span>")
	originals = null
