/// Голова декапитированного авангарда (с мозгом и сознанием) и его тело улетают на приёмный маяк, когда задание закрывается.
/datum/unit_test/vanguard_mission_decapitated_remains
	var/list/saved_beacons
	var/obj/item/bodypart/head/head

/datum/unit_test/vanguard_mission_decapitated_remains/Run()
	saved_beacons = GLOB.expedition_body_beacons.Copy()
	GLOB.expedition_body_beacons.Cut()
	allocate(/obj/structure/fulton_beacon, run_loc_floor_top_right)
	var/datum/orbital_objective/probe = new
	probe.objective_z_level = run_loc_floor_bottom_left.z
	TEST_ASSERT_NULL(probe.get_expedition_body_beacon(), "Маяк на стираемом уровне задания выбран приёмным")
	qdel(probe)
	var/obj/structure/fulton_beacon/beacon = allocate(/obj/structure/fulton_beacon, vanguard_home_beacon_spot())

	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.mind_initialize()
	var/datum/mind/victim_mind = victim.mind
	victim_mind.assigned_role = "Vanguard Operative"

	head = victim.get_bodypart(BODY_ZONE_HEAD)
	head.dismember()
	head.throwing?.finalize(FALSE)
	TEST_ASSERT_EQUAL(head.brainmob?.mind, victim_mind, "После декапитации сознание не ушло в голову")
	TEST_ASSERT(get_dist(head, beacon) > 1, "Голова с самого начала лежит у маяка")

	var/datum/orbital_objective/objective = new
	objective.objective_z_level = run_loc_floor_bottom_left.z
	qdel(objective)

	TEST_ASSERT(get_dist(head, beacon) <= 1, "Голова авангарда не доставлена на маяк при закрытии задания")
	TEST_ASSERT_EQUAL(head.brainmob?.mind, victim_mind, "Голова доставлена без сознания")
	TEST_ASSERT(head.brain in head, "Голова доставлена без мозга")
	TEST_ASSERT(get_dist(victim, beacon) <= 1, "Безголовое тело авангарда не доставлено на маяк вместе с головой")

/datum/unit_test/vanguard_mission_decapitated_remains/Destroy()
	QDEL_NULL(head)
	if(saved_beacons)
		GLOB.expedition_body_beacons = saved_beacons
	return ..()

/// Извлечённый мозг авангарда в чужой руке и его тело без мозга тоже возвращаются на маяк.
/datum/unit_test/vanguard_mission_held_brain
	var/list/saved_beacons
	var/obj/item/organ/brain/brain

/datum/unit_test/vanguard_mission_held_brain/Run()
	saved_beacons = GLOB.expedition_body_beacons.Copy()
	GLOB.expedition_body_beacons.Cut()
	var/obj/structure/fulton_beacon/beacon = allocate(/obj/structure/fulton_beacon, vanguard_home_beacon_spot())

	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.mind_initialize()
	var/datum/mind/victim_mind = victim.mind
	victim_mind.assigned_role = "Vanguard Operative"
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)

	brain = victim.getorganslot(ORGAN_SLOT_BRAIN)
	brain.Remove()
	TEST_ASSERT(bystander.put_in_hands(brain), "Мозг не взять в руку")
	TEST_ASSERT_EQUAL(brain.brainmob?.mind, victim_mind, "После извлечения сознание не ушло в мозг")

	var/datum/orbital_objective/objective = new
	objective.objective_z_level = run_loc_floor_bottom_left.z
	qdel(objective)

	TEST_ASSERT(!bystander.is_holding(brain), "Доставленный мозг остался числиться в руке")
	TEST_ASSERT(isturf(brain.loc) && get_dist(brain, beacon) <= 1, "Мозг авангарда не доставлен на маяк")
	TEST_ASSERT_EQUAL(brain.brainmob?.mind, victim_mind, "Мозг доставлен без сознания")
	TEST_ASSERT(get_dist(victim, beacon) <= 1, "Тело авангарда без мозга не доставлено на маяк")
	TEST_ASSERT(get_dist(bystander, beacon) > 1, "Живой посторонний улетел на маяк")

/datum/unit_test/vanguard_mission_held_brain/Destroy()
	QDEL_NULL(brain)
	if(saved_beacons)
		GLOB.expedition_body_beacons = saved_beacons
	return ..()

/// Труп авангардца после ghost'а (нет ни mind, ни ckey) возвращается домой по ДНК из снимка.
/datum/unit_test/vanguard_mission_ghosted_remains
	var/list/saved_beacons
	var/mob/living/carbon/human/victim
	var/mob/living/carbon/human/lookalike
	var/mob/living/carbon/human/bystander

/datum/unit_test/vanguard_mission_ghosted_remains/Run()
	saved_beacons = GLOB.expedition_body_beacons.Copy()
	GLOB.expedition_body_beacons.Cut()
	var/obj/structure/fulton_beacon/beacon = allocate(/obj/structure/fulton_beacon, vanguard_home_beacon_spot())

	victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/enzymes = victim.dna.unique_enzymes
	//Имитируем ghostize(): у тела больше нет ни сознания, ни ckey.
	victim.stat = DEAD
	TEST_ASSERT(get_dist(victim, beacon) > 1, "Труп с самого начала лежит у маяка")

	//Живой человек с той же ДНК не должен улететь вместе с трупом.
	lookalike = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	lookalike.dna.unique_enzymes = enzymes
	//Посторонний труп с чужой ДНК тоже остаётся на руине.
	bystander = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	bystander.dna.unique_enzymes = "NOT_EXPEDITION_CREW"
	bystander.stat = DEAD

	var/datum/orbital_objective/objective = new
	objective.objective_z_level = run_loc_floor_bottom_left.z
	objective.expedition_crew_ckeys = null
	objective.expedition_crew_enzymes = list(enzymes)
	qdel(objective)

	TEST_ASSERT(isturf(victim.loc) && get_dist(victim, beacon) <= 1, "Труп авангардца без mind не доставлен на маяк")
	TEST_ASSERT(get_dist(lookalike, beacon) > 1, "Живой клон авангардца улетел на маяк")
	TEST_ASSERT(get_dist(bystander, beacon) > 1, "Посторонний труп улетел на маяк")

/datum/unit_test/vanguard_mission_ghosted_remains/Destroy()
	QDEL_NULL(victim)
	QDEL_NULL(lookalike)
	QDEL_NULL(bystander)
	if(saved_beacons)
		GLOB.expedition_body_beacons = saved_beacons
	return ..()

/// Приёмный маяк стоит на станции: маяк на уровне задания стирается вместе с руиной.
/datum/unit_test/proc/vanguard_home_beacon_spot()
	return locate(run_loc_floor_top_right.x, run_loc_floor_top_right.y, SSmapping.levels_by_trait(ZTRAIT_STATION)[1])
